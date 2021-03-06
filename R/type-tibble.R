#' @rdname df_ptype2
#' @export
tib_ptype2 <- function(x, y, ..., x_arg = "", y_arg = "") {
  .Call(
    vctrs_tib_ptype2,
    x = x,
    y = y,
    x_arg = x_arg,
    y_arg = y_arg
  )
}
#' @rdname df_ptype2
#' @export
tib_cast <- function(x, to, ..., x_arg = "", to_arg = "") {
  .Call(
    vctrs_tib_cast,
    x = x,
    to = to,
    x_arg = x_arg,
    to_arg = to_arg
  )
}

df_as_tibble <- function(df) {
  class(df) <- c("tbl_df", "tbl", "data.frame")
  df
}

# Conditionally registered in .onLoad()
vec_ptype2.tbl_df <- function(x, y, ...) {
  UseMethod("vec_ptype2.tbl_df")
}

vec_ptype2.tbl_df.data.frame <- function(x, y, ...) {
  tib_ptype2(x, y, ...)
}
vec_ptype2.data.frame.tbl_df <- function(x, y, ...) {
  tib_ptype2(x, y, ...)
}


# Conditionally registered in .onLoad()
vec_cast.tbl_df <- function(x, to, ..., x_arg = "", to_arg = "") {
  UseMethod("vec_cast.tbl_df")
}
vec_cast.tbl_df.tbl_df <- function(x, to, ..., x_arg = "", to_arg = "") {
  tib_cast(x, to, x_arg = x_arg, to_arg = to_arg)
}

vec_cast.data.frame.tbl_df <- function(x, to, ..., x_arg = "", to_arg = "") {
  tib_cast(x, to, x_arg = x_arg, to_arg = to_arg)
}
vec_cast.tbl_df.data.frame <- function(x, to, ..., x_arg = "", to_arg = "") {
  df_cast(x, to, x_arg = x_arg, to_arg = to_arg)
}
