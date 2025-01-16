#' Set up [radian](https://github.com/randy3k/radian)
#' @family editor functions
#' @export
use_radian <- function() {
  usethis::use_build_ignore(".radian_history")
  usethis::use_git_ignore(".radian_history")
}

