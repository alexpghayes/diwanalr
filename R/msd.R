#--------------
# Functions for the calculation of the MSD for transmission 
# Credit and acknowledgement to W.N. (Bill) Venables who
# provided this code/solution

# Used internally for calculating mean square displacement for transmission geometry
#
# TODO: is the call to local() necessary here? or can you just define
# lamdba, L, etc in the body of the function
msd_g1_diff <- local({
    lambda <- 6.32/1e+07
    L <- 0.01
    lstar <- z0 <- 0.000661
    k0 <- 2 * pi/lambda
    function(x, y) {
        ((((((L/lstar) + 4/3)/((z0/lstar) + 2/3)) * (sinh((z0/lstar) * x) + (2/3) * x * cosh((z0/lstar) * x)))/((1 +
            (4/9) * x^2) * sinh((L/lstar) * x) + (4/3) * x * cosh((L/lstar) * x))) - y)
    }
})

# Used internally for calculating mean square displacement for transmission geometry
#
findX <- function(y) {
    tst <- msd_g1_diff(c(.Machine$double.eps, 1), y)
    if (prod(tst) < 0) {
        ## opposite signs
        stats::uniroot(msd_g1_diff, c(.Machine$double.eps, 1), y = y)$root
    } else NA
}

# Used internally for calculating mean square displacement for transmission geometry
FindX <- Vectorize(findX)


#' Calculate the mean square displacement
#'
#' @param t_g1 A tibble consisting of correlation time, observed and scaled g1(t) values
#' @return A tibble consisting of correlation time and related mean square displacement
#' @examples
#' msd <- form_msd(g1)
#' @importFrom dplyr select
#' @export
form_msd <- function(t_g1) {
    lambda <- 6.32/1e+07
    k0 <- 2 * pi/lambda
    g1_msd <- within(t_g1, msd <- FindX(Scaled)/(10^8 * k0))
    g1_msd <- dplyr::select(g1_msd, -`Observed`, -`Scaled`)
    
    # TODO: why is it appropriate to remove NA values here? why are
    # NA values being generated? is this expected?
    g1_msd <- stats::na.omit(g1_msd)
    return(g1_msd)
}
#' Plots the mean square displacement against the correlation time
#' @param g1_msd A tibble consisting of correlation time and related mean square displacement
#' @examples
#' plot_msd(g1_msd)
#' @export
#' @importFrom ggplot2 ggplot aes geom_point scale_x_log10 scale_x_log10 labs
plot_msd <- function(g1_msd) {
    msd_p <- ggplot2::ggplot(g1_msd, ggplot2::aes(time, msd)) + 
      ggplot2::geom_point() + 
      ggplot2::scale_x_log10() + 
      ggplot2::scale_y_log10() + 
      ggplot2::labs(x = "Correlation time (s)",
        y = "Mean square displacement")
    print(msd_p)
}
