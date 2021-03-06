# SQLTransformer

#' Feature Transformation -- SQLTransformer
#'
#' Implements the transformations which are defined by SQL statement. Currently we
#'   only support SQL syntax like 'SELECT ... FROM __THIS__ ...' where '__THIS__' represents
#'   the underlying table of the input dataset. The select clause specifies the
#'   fields, constants, and expressions to display in the output, it can be any
#'   select clause that Spark SQL supports. Users can also use Spark SQL built-in
#'   function and UDFs to operate on these selected columns.
#'
#' @template roxlate-ml-feature-transformer
#' @param statement A SQL statement.
#'
#' @rdname sql-transformer
#' @export
ft_sql_transformer <- function(x, statement,
                               uid = random_string("sql_transformer_"), ...) {
  UseMethod("ft_sql_transformer")
}

#' @export
ft_sql_transformer.spark_connection <- function(
  x, statement,
  uid = random_string("sql_transformer_"), ...) {

  ml_ratify_args()
  jobj <- invoke_new(x, "org.apache.spark.ml.feature.SQLTransformer", uid) %>%
    invoke("setStatement", statement)

  new_ml_sql_transformer(jobj)
}

#' @export
ft_sql_transformer.ml_pipeline <- function(
  x, statement,
  uid = random_string("sql_transformer_"), ...) {

  transformer <- ml_new_stage_modified_args()
  ml_add_stage(x, transformer)
}

#' @export
ft_sql_transformer.tbl_spark <- function(
  x, statement,
  uid = random_string("sql_transformer_"), ...) {
  transformer <- ml_new_stage_modified_args()
  ml_transform(transformer, x)
}

new_ml_sql_transformer <- function(jobj) {
  new_ml_transformer(jobj, subclass = "ml_sql_transformer")
}

# dplyr transformer

ft_extract_sql <- function(x) {
  table_name <- paste0("`",
                       x[["ops"]][["x"]][1],
                       "`")
  dbplyr::sql_render(x) %>%
    gsub(table_name, "__THIS__", .)
}

#' @rdname sql-transformer
#'
#' @details \code{ft_dplyr_transformer()} is a wrapper around \code{ft_sql_transformer()} that
#'   takes a \code{tbl_spark} instead of a SQL statement. Internally, the \code{ft_dplyr_transformer()}
#'   extracts the \code{dplyr} transformations used to generate \code{tbl} as a SQL statement
#'   then passes it on to \code{ft_sql_transformer()}. Note that only single-table \code{dplyr} verbs
#'   are supported and that the \code{sdf_} family of functions are not.
#'
#' @param tbl A \code{tbl_spark} generated using \code{dplyr} transformations.
#' @export
ft_dplyr_transformer <- function(
  x, tbl,
  uid = random_string("dplyr_transformer_"), ...) {
  UseMethod("ft_dplyr_transformer")
}

#' @export
ft_dplyr_transformer.spark_connection <- function(
  x, tbl,
  uid = random_string("dplyr_transformer_"), ...) {

  if (!identical(class(tbl)[1], "tbl_spark")) stop("'tbl' must be a Spark table")
  ft_sql_transformer(x, ft_extract_sql(tbl), uid = uid)
}

#' @export
ft_dplyr_transformer.ml_pipeline <- function(
  x, tbl,
  uid = random_string("dplyr_transformer_"), ...) {

  transformer <- ml_new_stage_modified_args()
  ml_add_stage(x, transformer)
}

#' @export
ft_dplyr_transformer.tbl_spark <- function(
  x, tbl,
  uid = random_string("dplyr_transformer_"), ...) {

  transformer <- ml_new_stage_modified_args()
  ml_transform(transformer, x)
}
