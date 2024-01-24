#' Get Xpress Optimized Model Status
#'
#' @param x an integer value representing the status of the optimized model
#'
get_xpress_status <- function(x){

  # Calculate Status
  temp_status <- switch(as.character(x),
                        "0" = "XPRS_MIP_NOT_LOADED",
                        "1" = "XPRS_MIP_LP_NOT_OPTIMAL",
                        "2" = "XPRS_MIP_LP_OPTIMAL",
                        "3" = "XPRS_MIP_NO_SOL_FOUND",
                        "4" = "XPRS_MIP_SOLUTION",
                        "5" = "XPRS_MIP_INFEAS",
                        "6" = "XPRS_MIP_OPTIMAL",
                        "7" = "XPRS_MIP_UNBOUNDED",
                        "error")

  # Return Status
  return(temp_status)

}
#' Get OMPR Optimized Model Status
#'
#' @param x an integer value representing the staut of the optimized model
#'
get_ompr_status <- function(x){

  # Calculate Status
  temp_status <- switch(as.character(x),
                        "0" = "error",
                        "1" = "infeasible",
                        "2" = "optimal",
                        "3" = "infeasible",
                        "4" = "optimal",
                        "5" = "infeasible",
                        "6" = "optimal",
                        "7" = "unbounded",
                        "error")

  # Return Status
  return(temp_status)

}
#' Get Row Type Conversion
#'
#' @param sense the math symbol representing the row constraint type
#'
xpress_sense_conversion <- function(sense){

  # Create Conversion Library
  conversion_list <- list("<=" = "L",
                          "==" = "E",
                          ">=" = "G")

  # Convert Sense
  if (sense %in% names(conversion_list)){

    # Convert Symbol
    temp_sense <- conversion_list[[sense]]

    # Close Function
    return(temp_sense)

  } else {

    # Notify user
    paste0("The sense type ", sense,
           ' is not a valid option. Check Xpress/OMPR documentation for assitance') |>
      print()

  }

}
#'
#' OMPR Column Type Conversion
#'
#' @param col_type a string representing the column type
#'
#'
xpress_col_type_conversion <- function(col_type){

  # Create Conversion Library
  # Semi-Continuous not available in OMPR package, but included regardless
  conversion_list <- list('continuous' = 'C',
                          'binary' = 'B',
                          'integer' = 'I',
                          'semi-continuous' = 'S')

  # Convert Column Type
  if (col_type %in% names(conversion_list)){

    # Convert
    temp_col_type <- conversion_list[[col_type]]

    # Close Function
    return(temp_col_type)

  } else {

    # Notify user
    print(paste0('Column type ', col_type,
                 '  does not exist. Explore OMPR/Xpress documentation for help troubleshooting'))

  }

}
#'
#' Xpress Column Type Fill
#'
#' @param x a string representing the column type description
#' @param conversion_list a list of the conversion parameters
#'
xpress_col_type_fill <- function(x, conversion_list){

  # Extract Data
  key <- sub(pattern = "\\[.*", "", x)

  # Check List
  if (key %in% names(conversion_list)){

    # Get Type
    temp_type <- conversion_list[[key]]
    return(temp_type)
  }

  # Print
  paste0('The column type ', key,
         ' is not a valid option. Please explore Xpress/OMPR documentation for assistance') |>
    print()

}
#'
#' Apply Xpress Control Parameters
#'
#' @param prob the Xpress problem object
#' @param control_params the list of control paramters to pass to the solver
#'
xpress_apply_control_params <- function(prob, control_params){

  # Get list of all control params
  xpress_control_params <- c(lapply(X = xprs_getintcontrols(), FUN = \(x) x <- 'integer'),
                             lapply(X = xprs_getdoublecontrols(), FUN = \(x) x <- 'double'),
                             lapply(X = xprs_getstringcontrols(), FUN = \(x) x <- 'string'))

  # Filter Control List
  filtered_x <- control_params[names(control_params) %in% names(xpress_control_params)]

  # Apply Controls
  if (length(filtered_x > 0)){

    # Classify Controls
    for (r in 1:length(filtered_x)){

      # Get Control Type, Parameter, Value
      control_type <- xpress_control_params[[filtered_x[r] |> names()]]
      control_parameter <- filtered_x[r] |> names()
      control_value <- filtered_x[r] |> unlist() |> unname()

      # Set Parameter
      if (control_type=='integer'){

        # Set Integer Parameter
        xpress::setintcontrol(prob = prob,
                              control = utils::getFromNamespace(control_parameter, "xpress"),
                              control_value |> as.integer())

      } else if(control_type == 'double'){

        # Set Double Parameter
        xpress::setdblcontrol(prob = prob,
                              control = utils::getFromNamespace(control_parameter, "xpress"),
                              control_value |> as.double())

      } else if(control_type == 'string'){

        # Set String Parameter
        xpress::setstrcontrol(prob = prob,
                              control = utils::getFromNamespace(control_parameter, "xpress"),
                              control_value |> as.character())

      }

    }

  }

}

#'
#' Get Xpress Problem Parameters
#'
#' @param prob the Xpress problem object
#'
xpress_get_params <- function(prob){

  # Get Double Attributes
  dbl_attributes <- lapply(xprs_getdoubleattributes(),
                           function(x) { getdblattrib(prob, x) })

  # Get Integer Attritubes
  int_attributes <- lapply(xprs_getintattributes(),
                           function(x) { getintattrib(prob, x) })

  # Get String Attributes
  str_attributes <- lapply(xprs_getstringattributes(),
                           function(x) { getstringattrib(prob, x) })

  # Get Integer Controls
  int_controls <- lapply(xprs_getintcontrols(),
                         function(x) { getintcontrol(prob, x) })

  # Get Double Controls
  dbl_controls <- lapply(xprs_getdoublecontrols(),
                         function(x) { getdblcontrol(prob, x) })

  # String Control
  str_controls <- lapply(xprs_getstringcontrols(),
                         function(x) { getstringcontrol(prob, x) })

  # Create List
  param_list <- list(dbl_attributes = dbl_attributes,
                     int_attributes = int_attributes,
                     str_attributes = str_attributes,
                     int_controls = int_controls,
                     dbl_controls = dbl_controls,
                     str_controls = str_controls)

  return(param_list)

}
#'
#' Run Xpress Infeasibility Analysis
#'
#' @param prob the Xpress problem object
#'
run_inf_analysis <- function(prob){

  # Get Integer Attributes from Presolve INdex
  get_inf_index <- xpress::getintattrib(prob = prob, attrib = xpress:::PRESOLVEINDEX)

  # Get Infeasible Row Data
  inf_row <- xpress::getrows(prob = prob, first = get_inf_index, last = get_inf_index)

  # Get Column Names
  inf_col_names <- sapply(X = inf_row$colind,
                          FUN = \(x) xpress::getnamelist(prob = prob, first = x, last = x, type = 2))

  # Get Right Hand Side
  inf_row_rhs <- xpress::getrhs(prob = prob, first = get_inf_index, last = get_inf_index)

  # Set Initial Equation
  row_equation <- ''

  # Construct Equation
  for (w in 1:length(inf_col_names)){

    if (w == 1){

      # Build Column Variable
      col_var <- switch(inf_row$colcoef[w] |> as.character(),
                        '1' = inf_col_names[w],
                        '-1' = paste0(' - ', inf_col_names[w]),
                        paste0(inf_col_names[w]))

    } else {

      # Build Column Variable
      col_var <- switch(inf_row$colcoef[w] |> as.character(),
                        '1' = paste0(' + ', inf_col_names[w]),
                        '-1' = paste0(' - ', inf_col_names[w]),
                        paste0(inf_col_names[w]))

    }

    # Build Equation
    row_equation <- paste0(row_equation, col_var)

  }

  # Finish Equation
  row_equation <- paste0(row_equation, ' = ', inf_row_rhs)

  # Build List
  inf_list <- list(inf_index = get_inf_index,
                   inf_row = inf_row,
                   inf_col_names = inf_col_names,
                   inf_row_rhs = inf_row_rhs,
                   row_equation = row_equation)

  return(inf_list)

}


#'
#' Run the Xpress solver through the OMPR interface.
#'
#' @param control a list of options passed to \code{xpress::xprs_optimize()}.
#' A complete list of control parameters are available in the details section.
#'
#' @import ompr
#' @import xpress
#' @import utils
#'
#' @details
#' The Xpress solver offers an extraordinarily wide range of control settings. The full list of
#' controls available can be found within the links below. While the controls are broken out
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
#' Infeasibility Analysis
#' https://www.fico.com/fico-xpress-optimization/docs/latest/solver/optimizer/HTML/chapter3.html
#'
#' @return A list returning all the results and parameters from the Xpress optimization run.
#' @export
#'
#' @examples
#' \dontrun{
#'
#'
#'
#' }
xpress_optimizer <- function(control = list(problem_name = 'Xpress Problem', verbose = TRUE,
                                            inf_analysis = TRUE), ...){

  # Check For Xpress Package
  if (!requireNamespace("xpress", quietly = TRUE)){

    # Notify IUser
    stop('You dont have the Xpress package installed')

  }

  # Create Model Run Function
  function(model){

    # Get All Control Parameters
    control <- c(control, ...)

    # Extract values from Model using OMPR functions
    obj <- ompr::objective_function(model)
    constraints <- ompr::extract_constraints(model)
    var_names <- ompr::variable_keys(model)
    upper_bounds <- ompr::variable_bounds(model)[['upper']]
    lower_bounds <- ompr::variable_bounds(model)[['lower']]
    col_types <- ompr::variable_types(model) |> as.character()
    obj_sense <- switch(model$objective$sense, 'max' = -1L, 'min' = 1L,
                        stop('Objective sense not valid'))

    # Create List For Xpress Problem Data
    problemdata <- list()

    # Create Objective Function
    problemdata$objcoef <- obj$solution |> as.numeric()

    # Get Row Coefficients
    problemdata$A <- constraints$matrix

    # Get Variable Types
    problemdata$columntypes <- sapply(col_types, xpress_col_type_conversion) |> unname()

    # Get problemdata Types
    problemdata$rowtype <- (lapply(X = constraints$sense, FUN = xpress_sense_conversion) |> unlist())

    # Get Right-Hand Side
    problemdata$rhs <- constraints$rhs |> as.numeric()

    # specify lower bounds and upper bounds for the columns
    problemdata$lb <- lower_bounds
    problemdata$ub <- upper_bounds

    # Add Variable Names
    problemdata$colname <- var_names

    # Name Problem
    problemdata$probname <- control$problem_name

    # Load Problem Into Xpress Prob Object
    p <- xpress::xprs_loadproblemdata(problemdata = problemdata)

    # Apply All Control Parameters
    xpress_apply_control_params(prob = p, control_params = control)

    # Set Problem Sense
    chgobjsense(p, obj_sense)

    # Set Output to Console
    if (control$verbose){setoutput(p)}

    # Run Xpress Optimization
    summary(xpress::xprs_optimize(p))

    # Get Solution Status
    sol_status <- getintattrib(p, xpress:::MIPSTATUS) |> get_ompr_status()

    # Run If Feasible
    if (sol_status=='optimal'){

      # Extract Xpress Results
      xpress_results <- data.frame(Variable = problemdata$colname, Value = xprs_getsolution(p))

      # Get All Controls
      model_attributes <- xpress_get_params(prob = p)

      # Fix Global Variables
      xpress_verison <- packageVersion('xpress') |> as.character()
      if (compareVersion(xpress_verison |> as.character(),'9.2.5') >= 0){
        xpress::fixmipentities(prob = p, options = 0)
      } else {
        xpress::fixglobals(prob = p, options = 0)
      }

      # Rerun Problem As Linear Model For Sensitivity Analysis
      xpress::lpoptimize(p)

      # Extract LP Solution
      lp_solution <- xpress::getlpsol(prob = p)

      # Extract Sensitivity Ranges
      obj_sensitivity <- xpress::objsa(p, 0:(model_attributes$int_attributes$COLS-1))
      bnd_sensitivity <- xpress::bndsa(p, 0:(model_attributes$int_attributes$COLS-1))
      rhs_sensitivy <- xpress::rhssa(prob = p, rowind = 0:((constraints$rhs |> length())-1))

      # Add Variable Names to Sensitivity Ranges
      obj_sensitivity_df <- data.frame(Variable = xpress::getnamelist(p,2,0,(obj_sensitivity$lower |> length()-1)),
                                       lower = obj_sensitivity$lower,
                                       upper = obj_sensitivity$upper)
      bnd_sensitivity_df <- data.frame(Variable = xpress::getnamelist(p,2,0,(obj_sensitivity$lower |> length()-1)),
                                       lblower = bnd_sensitivity$lblower,
                                       lbupper = bnd_sensitivity$lbupper,
                                       ublower = bnd_sensitivity$ublower,
                                       ubupper = bnd_sensitivity$ubupper)

      # Get Reduced Costs
      reduced_costs <- data.frame(Variable = problemdata$colname,
                                  value = lp_solution$djs[1:(problemdata$colname |> length())])


      # Get Xpress Status
      xpress_status <- model_attributes$int_attributes$MIPSTATUS |> get_xpress_status()

    } else if (sol_status == 'infeasible' & control$inf_analysis){

      # Get All Controls
      model_attributes <- xpress_get_params(prob = p)

      # Perform Infeasibility Analysis
      inf_analysis <- run_inf_analysis(prob = p)
    }

    #__________________________________________________________________________________
    # Build Solution List

    if (sol_status == 'optimal'){

      # Create Solution List
      xpress_solution <- ompr::new_solution(model = model,
                                            objective_value = model_attributes$dbl_attributes$MIPOBJVAL,
                                            status = (model_attributes$int_attributes$MIPSTATUS |> get_ompr_status()),
                                            solution = xpress_results,
                                            additional_solver_output = list(obj_sensitivity = obj_sensitivity_df,
                                                                            bnd_sensitivity = bnd_sensitivity_df,
                                                                            rhs_sensitivity = rhs_sensitivy,
                                                                            reduced_costs = reduced_costs,
                                                                            model_attributes = model_attributes,
                                                                            lp_solution = lp_solution,
                                                                            xpress_status = xpress_status,
                                                                            xpress_problem = p))

    } else {

      # Create Empty Solution Set
      xpress_results <- data.frame(Variable = var_names,
                                   Value = 0)

      # Create Solution List
      xpress_solution <- ompr::new_solution(model = model,
                                            objective_value = Inf,
                                            status = xpress::getintattrib(p,xpress:::MIPSTATUS) |> get_ompr_status(),
                                            solution = xpress_results,
                                            additional_solver_output = list(inf_analysis = inf_analysis,
                                                                            model_attributes = model_attributes,
                                                                            xpress_problem = p))


    }

    return(xpress_solution)

  }

}
