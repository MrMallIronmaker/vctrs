
new_ctor <- function(class) {
  function(x = list(), ...) {
    if (inherits(x, "tbl_df")) {
      tibble::new_tibble(x, class = class, nrow = nrow(x))
    } else if (is.data.frame(x)) {
      structure(x, class = c(class, "data.frame"), ...)
    } else {
      structure(x, class = class, ...)
    }
  }
}

foobar <- new_ctor("vctrs_foobar")
foobaz <- new_ctor("vctrs_foobaz")
quux <- new_ctor("vctrs_quux")

expect_foobar <- function(x) expect_is({{ x }}, "vctrs_foobar")
expect_foobaz <- function(x) expect_is({{ x }}, "vctrs_foobaz")
expect_quux <- function(x) expect_is({{ x }}, "vctrs_quux")

with_c_foobar <- function(expr) {
  with_methods(
    expr,
    c.vctrs_foobar = function(...) foobar(NextMethod())
  )
}

unrownames <- function(x) {
  row.names(x) <- NULL
  x
}

local_methods <- function(..., .frame = caller_env()) {
  local_bindings(..., .env = global_env(), .frame = .frame)
}
with_methods <- function(.expr, ...) {
  local_methods(...)
  .expr
}

local_proxy <- function(frame = caller_env()) {
  local_methods(.frame = frame,
    vec_proxy.vctrs_proxy = function(x, ...) proxy_deref(x),
    vec_restore.vctrs_proxy = function(x, to, ...) new_proxy(x),

    vec_ptype2.vctrs_proxy = function(x, y, ...) UseMethod("vec_ptype2.vctrs_proxy"),
    vec_ptype2.vctrs_proxy.vctrs_proxy = function(x, y, ...) new_proxy(vec_ptype(proxy_deref(x))),

    vec_cast.vctrs_proxy = function(x, to, ...) UseMethod("vec_cast.vctrs_proxy"),
    vec_cast.vctrs_proxy.vctrs_proxy = function(x, to, ...) x
  )
}

new_proxy <- function(x) {
  structure(list(env(x = x)), class = "vctrs_proxy")
}
proxy_deref <- function(x) {
  x[[1]]$x
}
local_env_proxy <- function(frame = caller_env()) {
  local_methods(.frame = frame,
    vec_proxy.vctrs_proxy = proxy_deref,
    vec_restore.vctrs_proxy = function(x, ...) new_proxy(x),
    vec_cast.vctrs_proxy = function(x, to, ...) UseMethod("vec_cast.vctrs_proxy"),
    vec_cast.vctrs_proxy.vctrs_proxy = function(x, to, ...) x,
    vec_ptype2.vctrs_proxy = function(x, y, ...) UseMethod("vec_ptype2.vctrs_proxy"),
    vec_ptype2.vctrs_proxy.vctrs_proxy = function(x, y, ...) new_proxy(proxy_deref(x)[0])
  )
}

local_no_stringsAsFactors <- function(frame = caller_env()) {
  local_options(.frame = frame, stringsAsFactors = FALSE)
}

tibble <- function(...) {
  tibble::tibble(...)
}

local_foobar_proxy <- function(frame = caller_env()) {
  local_methods(.frame = frame, vec_proxy.vctrs_foobar = identity)
}

subclass <- function(x) {
  class(x) <- c("vctrs_foo", "vctrs_foobar", class(x))
  x
}


# Subclass promoted to logical
new_lgl_subtype <- function(x) {
  stopifnot(is_logical(x))
  structure(x, class = "vctrs_lgl_subtype")
}
local_lgl_subtype <- function(frame = caller_env()) {
  local_methods(.frame = frame,
    vec_ptype2.vctrs_lgl_subtype = function(x, y, ...) UseMethod("vec_ptype2.vctrs_lgl_subtype"),
    vec_ptype2.vctrs_lgl_subtype.vctrs_lgl_subtype = function(x, y, ...) x,
    vec_ptype2.vctrs_lgl_subtype.logical = function(x, y, ...) y,
    vec_ptype2.logical.vctrs_lgl_subtype = function(x, y, ...) x,

    vec_cast.vctrs_lgl_subtype = function(x, to, ...) UseMethod("vec_cast.vctrs_lgl_subtype"),
    vec_cast.vctrs_lgl_subtype.vctrs_lgl_subtype = function(x, to, ...) x,
    vec_cast.vctrs_lgl_subtype.logical = function(x, to, ...) new_lgl_subtype(x),
    vec_cast.logical.vctrs_lgl_subtype = function(x, to, ...) unstructure(x)
  )
}
with_lgl_subtype <- function(expr) {
  local_lgl_subtype()
  expr
}

# Logical promoted to subclass
new_lgl_supertype <- function(x) {
  stopifnot(is_logical(x))
  structure(x, class = "vctrs_lgl_supertype")
}
local_lgl_supertype <- function(frame = caller_env()) {
  local_methods(.frame = frame,
    vec_ptype2.vctrs_lgl_supertype = function(x, y, ...) UseMethod("vec_ptype2.vctrs_lgl_supertype"),
    vec_ptype2.vctrs_lgl_supertype.vctrs_lgl_supertype = function(x, y, ...) x,
    vec_ptype2.vctrs_lgl_supertype.logical = function(x, y, ...) x,
    vec_ptype2.logical.vctrs_lgl_supertype = function(x, y, ...) y,

    vec_cast.vctrs_lgl_supertype = function(x, to, ...) UseMethod("vec_cast.vctrs_lgl_supertype"),
    vec_cast.vctrs_lgl_supertype.vctrs_lgl_supertype = function(x, to, ...) x,
    vec_cast.vctrs_lgl_supertype.logical = function(x, to, ...) new_lgl_subtype(x),
    vec_cast.logical.vctrs_lgl_supertype = function(x, to, ...) unstructure(x)
  )
}
with_lgl_supertype <- function(expr) {
  local_lgl_supertype()
  expr
}
