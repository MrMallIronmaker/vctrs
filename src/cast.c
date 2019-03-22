#include "vctrs.h"
#include "utils.h"

// Initialised at load time
static SEXP syms_vec_cast_dispatch = NULL;
static SEXP fns_vec_cast_dispatch = NULL;


static SEXP int_as_logical(SEXP x, bool* lossy) {
  int* data = INTEGER(x);
  R_len_t n = Rf_length(x);

  SEXP out = PROTECT(Rf_allocVector(LGLSXP, n));
  int* out_data = LOGICAL(out);

  for (R_len_t i = 0; i < n; ++i, ++data, ++out_data) {
    int elt = *data;

    if (elt != 0 && elt != 1) {
      *lossy = true;
      UNPROTECT(1);
      return R_NilValue;
    }

    *out_data = elt;
  }

  UNPROTECT(1);
  return out;
}

static SEXP dbl_as_logical(SEXP x, bool* lossy) {
  double* data = REAL(x);
  R_len_t n = Rf_length(x);

  SEXP out = PROTECT(Rf_allocVector(LGLSXP, n));
  int* out_data = LOGICAL(out);

  for (R_len_t i = 0; i < n; ++i, ++data, ++out_data) {
    double elt = *data;

    if (elt != 0 && elt != 1) {
      *lossy = true;
      UNPROTECT(1);
      return R_NilValue;
    }

    *out_data = isnan(elt) ? NA_LOGICAL : (int) elt;
  }

  UNPROTECT(1);
  return out;
}

static SEXP chr_as_logical(SEXP x, bool* lossy) {
  SEXP* data = STRING_PTR(x);
  R_len_t n = Rf_length(x);

  SEXP out = PROTECT(Rf_allocVector(LGLSXP, n));
  int* out_data = LOGICAL(out);

  for (R_len_t i = 0; i < n; ++i, ++data, ++out_data) {
    const char* elt = CHAR(*data);
    switch (elt[0]) {
    case 'T':
      if (elt[1] == '\0' || strcmp(elt, "TRUE") == 0) {
        *out_data = 1;
        continue;
      }
      break;
    case 'F':
      if (elt[1] == '\0' || strcmp(elt, "FALSE") == 0) {
        *out_data = 0;
        continue;
      }
      break;
    case 't':
      if (strcmp(elt, "true") == 0) {
        *out_data = 1;
        continue;
      }
      break;
    case 'f':
      if (strcmp(elt, "false") == 0) {
        *out_data = 0;
        continue;
      }
      break;
    default:
      break;
    }

    *lossy = true;
    UNPROTECT(1);
    return R_NilValue;
  }

  UNPROTECT(1);
  return out;
}

static SEXP lgl_as_integer(SEXP x, bool* lossy) {
  return Rf_coerceVector(x, INTSXP);
}

static SEXP dbl_as_integer(SEXP x, bool* lossy) {
  double* data = REAL(x);
  R_len_t n = Rf_length(x);

  SEXP out = PROTECT(Rf_allocVector(INTSXP, n));
  int* out_data = INTEGER(out);

  for (R_len_t i = 0; i < n; ++i, ++data, ++out_data) {
    double elt = *data;

    if (elt <= INT_MIN || elt >= INT_MAX + 1.0) {
      *lossy = true;
      UNPROTECT(1);
      return R_NilValue;
    }

    if (isnan(elt)) {
      *out_data = NA_INTEGER;
      continue;
    }

    int value = (int) elt;

    if (value != elt) {
      *lossy = true;
      UNPROTECT(1);
      return R_NilValue;
    }

    *out_data = value;
  }

  UNPROTECT(1);
  return out;
}

static SEXP lgl_as_double(SEXP x, bool* lossy) {
  int* data = LOGICAL(x);
  R_len_t n = Rf_length(x);

  SEXP out = PROTECT(Rf_allocVector(REALSXP, n));
  double* out_data = REAL(out);

  for (R_len_t i = 0; i < n; ++i, ++data, ++out_data) {
    int elt = *data;
    *out_data = (elt == NA_LOGICAL) ? NA_REAL : elt;
  }

  UNPROTECT(1);
  return out;
}

static SEXP int_as_double(SEXP x, bool* lossy) {
  int* data = INTEGER(x);
  R_len_t n = Rf_length(x);

  SEXP out = PROTECT(Rf_allocVector(REALSXP, n));
  double* out_data = REAL(out);

  for (R_len_t i = 0; i < n; ++i, ++data, ++out_data) {
    int elt = *data;
    *out_data = (elt == NA_INTEGER) ? NA_REAL : elt;
  }

  UNPROTECT(1);
  return out;
}

static SEXP vec_cast_switch(SEXP x, SEXP to, bool* lossy) {
  switch (vec_typeof(to)) {
  case vctrs_type_logical:
    switch (vec_typeof(x)) {
    case vctrs_type_logical:
      return x;
    case vctrs_type_integer:
      return int_as_logical(x, lossy);
    case vctrs_type_double:
      return dbl_as_logical(x, lossy);
    case vctrs_type_character:
      return chr_as_logical(x, lossy);
    default:
      break;
    }
    break;

  case vctrs_type_integer:
    switch (vec_typeof(x)) {
    case vctrs_type_logical:
      return lgl_as_integer(x, lossy);
    case vctrs_type_integer:
      return x;
    case vctrs_type_double:
      return dbl_as_integer(x, lossy);
    case vctrs_type_character:
      // TODO: Implement with `R_strtod()` from R_ext/utils.h
      break;
    default:
      break;
    }
    break;

  case vctrs_type_double:
    switch (vec_typeof(x)) {
    case vctrs_type_logical:
      return lgl_as_double(x, lossy);
    case vctrs_type_integer:
      return int_as_double(x, lossy);
    case vctrs_type_double:
      return x;
    case vctrs_type_character:
      // TODO: Implement with `R_strtod()` from R_ext/utils.h
      break;
    default:
      break;
    }
    break;

  case vctrs_type_character:
    switch (vec_typeof(x)) {
    case vctrs_type_logical:
    case vctrs_type_integer:
    case vctrs_type_double:
      return Rf_coerceVector(x, STRSXP);
    case vctrs_type_character:
      return x;
    default:
      break;
    }
    break;

  default:
    break;
  }

  return R_NilValue;
}

SEXP vec_cast(SEXP x, SEXP to) {
  if (x == R_NilValue || to == R_NilValue) {
    return x;
  }

  bool lossy = false;
  SEXP out = R_NilValue;

  if (!has_dim(x) && !has_dim(to)) {
    out = vec_cast_switch(x, to, &lossy);
  }

  if (lossy || out == R_NilValue) {
    return vctrs_dispatch2(syms_vec_cast_dispatch, fns_vec_cast_dispatch,
                           syms_x, x,
                           syms_to, to);
  }

  return out;
}

void vctrs_init_cast(SEXP ns) {
  syms_vec_cast_dispatch = Rf_install("vec_cast_dispatch");
  fns_vec_cast_dispatch = Rf_findVar(syms_vec_cast_dispatch, ns);
}