#' Run the Xpress solver through the OMPR interface.
#'
#' @param control a list of options passed to \code{xpress::xprs_optimize()}.
#' A complete list of control parameters
#'
#' @ import ompr
#' @ import xpress
#'
#'# To Do List
#'
#' Pre Model Run
#' Convert Upper And Lower Bounds Passing Into Algorithm
#' Create Conversion For All Model Parameter Settings
#'      Check Whether Parameter
#'      Create Function To Create Call To Xpress Model
#'
#' Post Model
#' Extract All Model Parameters
#' Return All Parameters In List
#' Ensure Parameters Are Available in OMPR model functions
#'
#' @details
#' The Xpress solver offers a extraordinarily wide range of control settings. The full list of
#' controls available can be found within the links below. While the control are broken out
#' into integer, double, and string controls, there's no need to delineate this in your function
#' call as that will be handled internally.
#'
#' General Control Parameter Discussion With List of Controls
#' https://www.fico.com/fico-xpress-optimization/docs/latest/solver/optimizer/HTML/chapter7.html
#'
#' Integer Control Parameters
#' https://www.fico.com/fico-xpress-optimization/docs/latest/solver/optimizer/HTML/XPRSsetintcontrol.html#'
#'
#' Double Control Parameters
#' https://www.fico.com/fico-xpress-optimization/docs/latest/solver/optimizer/HTML/XPRSsetdblcontrol.html
#'
#' String Control Parameters
#' https://www.fico.com/fico-xpress-optimization/docs/latest/solver/optimizer/HTML/XPRSsetstrcontrol.html
#'
#'
#' @return A list returning all the results and parameters from the Xpress optimization run.
#' @export
#'
#' @examples
#' #' \dontrun{
#'
#'
#'
#' }
xpress_optimizer <- function(control = list()){

  # Create Model Run Function
  function(model){

    # Extract Values From OMPR Model Object
    obj <- ompr::objective_function(model)
    constraints <- ompr::extract_constraints(model)
    var_names <- ompr::variable_keys(model)

    # Create Xpress List For Problem Data
    xpress_list <- list()

    # Create Objective Function
    xpress_list$objcoef <- obj$solution |> as.numeric()

    # Get Row Coefficients
    xpress_list$A <- constraints$matrix




  }

}

#' Solve {ompr} models using HiGHS
#'
#'
#'
#' The solver uses {highs} internally to solve MIP models.
#'
#' @param control a list of options passed to \code{highs::highs_solve}. For
#' a complete list see \code{highs::highs_available_solver_options()}.
#'
#' @return a function: Model -> Solution that can be used
#' together with \code{\link[ompr]{solve_model}}.
#'
#' @examples
#' \dontrun{
#' library(magrittr)
#' library(ompr)
#' library(ROI)
#' library(ROI.plugin.glpk)
#' add_variable(MIPModel(), x, type = "continuous") %>%
#'     set_objective(x, sense = "max") %>%
#'     add_constraint(x <= 5) %>%
#'     solve_model(highs_optimizer())
#' }
#' @import ompr
#' @import highs
#' @importFrom stats setNames
#' @export
highs_optimizer <- function(control = list()) {

  function(model) {
    variable_names <- variable_keys(model)

    obj <- objective_function(model)
    obj_constant <- obj$constant

    constraints <- extract_constraints(model)

    rhs <- rep.int(Inf, nconstraints(model))
    leq <- constraints$sense %in% c("<=", "==")
    rhs[leq] <- constraints$rhs[leq]

    lhs <- rep.int(-Inf, nconstraints(model))
    geq <- constraints$sense %in% c(">=", "==")
    lhs[geq] <- constraints$rhs[geq]

    var_types <- as.character(variable_types(model))
    var_types[var_types %in% c("binary", "integer")] <- "I"
    var_types[var_types %in% "continuous"] <- "C"

    bounds <- variable_bounds(model)

    highs_sol <- highs_solve(
      L = as.numeric(obj$solution),
      A = constraints$matrix,
      lower = bounds$lower,
      upper = bounds$upper,
      types = var_types,
      lhs = lhs,
      rhs = rhs,
      offset = obj$constant,
      dry_run = FALSE,
      maximum = model$objective$sense == "max",
      control = control
    )

    status <- switch(as.character(highs_sol$status),
                     "7" = "optimal",
                     "8" = "infeasible",
                     "9" = "infeasible",
                     "10" = "unbounded",
                     "13" = "userlimit",
                     "14" = "userlimit",
                     "error"
    )

    solution <- new_solution(
      status = status,
      model = model,
      objective_value = highs_sol$objective_value,
      solution = setNames(highs_sol$primal_solution, variable_names),
      solution_column_duals = function() {
        if (!highs_sol$solver_msg$dual_valid) {
          return(NA_real_)
        }
        highs_sol$solver_msg$col_dual
      },
      solution_row_duals = function() {
        if (!highs_sol$solver_msg$dual_valid) {
          return(NA_real_)
        }
        highs_sol$solver_msg$row_dual
      },
      additional_solver_output = highs_sol
    )
    solution
  }
}
