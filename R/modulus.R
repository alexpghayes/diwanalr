#' This function is used internally for calculating modulus, converting temperature in Celsius to absolute (Kelvin)
#'
#' @param temp A numnber
#' @return A number
#' @examples
#' celsius_to_kelvin(20)
celsius_to_kelvin <- function(temp) {
    return(temp + 273.15)
}

#' This function is used internally for calculating the viscoelastic modulus.
#' @param x A vector
#' @param y A vector (same length as x)
#' @return A vector
#' @examples
#' calc_slope(time, msd)
calc_slope <- function(x, y) {
    ## x and y must be of same length
    slope <- NULL
    slope[1] <- NA
    for (i in 2:(length(x) - 1)) {
        j <- seq(i - 1, i + 1, 1)
        slope <- cbind(slope, stats::lm(log(y[j]) ~ log(x[j]))$coef[2])
    }
    slope[i + 1] <- NA
    return(slope)
}

#' This function is used to calculate the viscoelastic modulus.
#' @param temp A number (temperature, in Celsius)
#' @param radius A number
#' @param msd A vector
#' @param slope A vector
#' @return A vector
#' @examples
#' visco_mod(temp, radius, msd, slope)
visco_mod <- function(temp, radius, msd, slope) {
    # TODO: why are there NAs here? is this expected? how are they
    # generated?
    slope <- stats::na.omit(slope)
    kBoltzmann <- 1.38064852/1e+23
    lo <- 2
    high <- length(msd) - 1
    return((kBoltzmann * celsius_to_kelvin(temp))/(pi * radius * msd[(lo:high)] * (gamma(1 + slope))))
}

#' This function is used to calculate the frequency as inverse of time
#' @param t A vector
#' @return A vector
#' @examples
#' calc_freq(time)
calc_freq <- function(t) {
    # t[1] and t[length] are removed
    lo <- 2
    high <- length(t) - 1
    return(1/(t[(lo:high)]))
}

#' This function is used to calculate the storage modulus
#' @param visco_mod A vector (viscoelastic modulus)
#' @param slope A vector
#' @return A vector
#' @examples
#' Storage <- visco_mod(G, slope)
storage_mod <- function(visco_mod, slope) {
    # TODO: why are there NAs here? is this expected? how are they
    # generated?
    slope <- stats::na.omit(slope)
    return(visco_mod * cos(pi * slope/2))
}

#' This function is used to calculate the loss modulus
#' @param visco_mod A vector (viscoelastic modulus)
#' @param slope A vector
#' @return A vector
#' @examples
#' Loss <- loss_mod(visco_mod, slope)
loss_mod <- function(visco_mod, slope) {
    # TODO: why is it appropriate to remove NA values here? how are they
    # being generated? are they expected?
    slope <- stats::na.omit(slope)
    return(visco_mod * sin(pi * slope/2))
}

#' This function produces a tibble consisting of frequency, the storage and loss modulus
#' @param msd_t A tibble consisting of correlation time and related mean square displacement
#' @param temp (optional) temperature in Celsius, default = 20
#' @param radius (optional) particle radius size, default = 5e-7
#' @return A tibble consisting of frequency with related storage and loss modulii
#' @examples
#' mods <- form_modulus(d, 20, 5e-7)
#' @importFrom tibble tibble
#' @export
form_modulus <- function(msd_t, temp = NULL, radius = NULL) {
  temp <- ifelse(is.null(temp), 20, temp)
  radius <- ifelse(is.null(radius), 5e-7, radius)
  slope <- with(msd_t, calc_slope(time, msd))
  visco_m <- with(msd_t, visco_mod(temp, radius, msd, slope))  #radius <- 5e-7, radius = a & temperature = 20 deg C
  mods <- tibble::tibble(freq = with(msd_t, calc_freq(time)),
                      `Storage (G')` = storage_mod(visco_m, slope),
                      `Loss (G'')` = loss_mod(visco_m, slope))
  return(mods)
}

#' Plots storage and loss modulus against the measured frequency
#' @param mod_t A tibble consisting of frequency and the related storage and loss modulusA
#' @param x_max (optional) Maximum 'x' scale value, default = 10000
#' @param y_max (optional) Maximum 'y' scale value, default = 10000
#' @examples
#' plot_modulus(mod_t)
#' @export
#' @importFrom tidyr gather
#' @importFrom ggplot2 ggplot aes geom_point scale_x_log10 scale_y_log10 labs
plot_modulus <- function(mod_t, x_max = NULL, y_max = NULL) {
  x_max <- ifelse(is.null(x_max), 10000, x_max)
  y_max <- ifelse(is.null(y_max), 300, y_max)  
  mod_t <- tidyr::gather(mod_t, key = Modulus, val, -freq)
  mod_p <- ggplot2::ggplot(mod_t, ggplot2::aes(freq, val, color = Modulus)) + 
      ggplot2::geom_point() + 
      ggplot2::scale_x_log10(limits = c(1, 10000)) + 
      ggplot2::scale_y_log10(limits = c(1, 300)) + 
      ggplot2::labs(x = "Frequency", y = "Modulus")
  
  # TODO: add a comment here documenting what the warnings are,
  # how they are generated, and why they are okay
  suppressWarnings(print(mod_p))
}