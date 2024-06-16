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
#' Convert Row From Alpha-Numeric to Symbol
#'
#' @param sense the Alpha-Numeric Row Type
#'
xpress_convert_row <- function(row_type){

  # Get Conversion
  row_conversion <- switch(row_type,
                           'N' = 'is free',
                           'L' = '<=',
                           'E' = '=',
                           'G' = '>=',
                           'R' = 'Range',
                           'Error')

  return(row_conversion)

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
      control_type <- xpress_control_params[[names(filtered_x[r])]]
      control_parameter <- names(filtered_x[r])
      control_value <- unname(unlist(filtered_x[r]))

      # Set Parameter
      if (control_type=='integer'){

        # Set Integer Parameter
        xpress::setintcontrol(prob = prob,
                              control = utils::getFromNamespace(control_parameter, "xpress"),
                              as.integer(control_value))

      } else if(control_type == 'double'){

        # Set Double Parameter
        xpress::setdblcontrol(prob = prob,
                              control = utils::getFromNamespace(control_parameter, "xpress"),
                              as.double(control_value))

      } else if(control_type == 'string'){

        # Set String Parameter
        xpress::setstrcontrol(prob = prob,
                              control = utils::getFromNamespace(control_parameter, "xpress"),
                              as.character(control_value))

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

  # Create Infeasability List
  inf_analysis <- list()

  # Get Integer Attributes from Presolve Index
  get_inf_index <- xpress::getintattrib(prob = prob, attrib = xpress:::PRESOLVEINDEX)

  # Get Total Size of Problem
  tot_rows <- xpress::getintattrib(prob = prob, attrib = xpress:::ROWS)
  tot_spare_rows <- xpress::getintattrib(prob = prob, attrib = xpress:::SPAREROWS)
  tot_cols <- xpress::getintattrib(prob = prob, attrib = xpress:::COLS)

  # Check For Row or Columm Indice
  row_index_bool <- get_inf_index <= (tot_rows + tot_spare_rows)
  row_bool <- get_inf_index >= 1

  # Perform Presolve Infeasability Analysis
  if (all(row_index_bool,row_bool)){

    # Get Row Equation Data Frame
    inf_equation_df <- get_row_equations(prob = prob, rows = get_inf_index+1)

    # Extract Only Equation
    inf_equation <- inf_equation_df$ROW_EQUATION

    # Return Analysis
    inf_analysis <- list(inf_equation = inf_equation,
                         inf_analysis = NA_character_)

  } else if(row_bool){

    # Get Column Index
    inf_col_index <- get_inf_index - (tot_rows + tot_spare_rows) - 1

    # Get Column Name
    inf_equation <- xpress::getnamelist(prob = prob, first = inf_col_index, last = inf_col_index, type = 2)

    # Create List
    inf_analysis <- list(inf_col_index = inf_col_index)

  } else {

    # Set Null Data
    inf_analysis <- NA_character_
    inf_equation <- NA_character_

  }

  # Build List
  inf_list <- list(inf_index = get_inf_index,
                   inf_analysis = inf_analysis,
                   inf_equation = inf_equation)

  return(inf_list)

}
#'
#' Add MIP Solution
#'
#' @param prob the Xpress problem object
#' @param heur_sol A dataframe containing column variable names, and solutions
#'
add_mip_sol <- function(prob, heur_sol){

  # Get Column Count
  col_count <- xpress::getintattrib(prob, xpress:::COLS)

  # Get Column Names + Index
  name_index <- data.frame(COL_NAME = xpress::getnamelist(prob,2,0,col_count-1))

  # Add Column Number Index
  name_index['COL_INDEX'] <- (rownames(name_index) |> as.integer()) - 1

  # Add Index to Heuristic Solution DataFrame
  heur_sol_tot <- merge(x = heur_sol,
                        y = name_index,
                        by.x = 'Variable',
                        by.y = 'COL_NAME',
                        all = FALSE,
                        all.x = FALSE,
                        all.y = FALSE)

  # Extract Vectors
  solval <- as.double(heur_sol_tot$Value)
  col_index <- as.integer(heur_sol_tot$COL_INDEX)

  # Set Name
  name <- 'Heur_Sol'

  # Add MIP Solution
  if (length(col_index) > 0){

    xpress::addmipsol(prob = prob,
                      solval = solval,
                      colind = col_index,
                      name = name)

  }

}
#' Build Row Constraint Equation From Parts
#'
#' @param row_data The Xpress problem row information from xpress::getrows for a single row
#' @param row_col_names A vector of all Xpress problem column names from xpress::getnamelist (will be filtered in function)
#' @param row_types The Xpress problem row type from xpress::getrowtype that has been convereted
#' from alpha-numeric to math symbols for a single row
#' @param row_rhs  The Xpress problem row right-hand side from xpress::getrhs for a single row
#'
#' @description
#' This function constructs the row constraint equation from passing in all the various parts.
#'
#'
build_row_equation_from_parts <- function(row_data, row_col_names, row_types, row_rhs){

  # Filter Row Column Names By Index
  row_col_names_filtered <- row_col_names[(row_data$colind+1)]

  # Convert Row Type
  row_type_converted <- xpress_convert_row(row_type = row_types)

  # Set Initial Equation
  row_equation <- ''

  # Construct Equation
  for (w in 1:length(row_col_names_filtered)){

    if (w == 1){

      # Build Column Variable
      col_var <- switch(as.character(row_data$colcoef[w]),
                        '1' = row_col_names_filtered[w],
                        '-1' = paste0(' - ', row_col_names_filtered[w]),
                        paste0(' ',
                               row_data$colcoef[w],'*', row_col_names_filtered[w]))

    } else {

      # Build Column Variable
      col_var <- switch(as.character(row_data$colcoef[w]),
                        '1' = paste0(' + ', row_col_names_filtered[w]),
                        '-1' = paste0(' - ', row_col_names_filtered[w]),
                        paste0(' ',
                               row_data$colcoef[w],'*', row_col_names_filtered[w]))

    }

    # Build Equation
    row_equation <- paste0(row_equation, col_var)

  }

  # Finish Equation
  row_equation <- paste0(row_equation,' ',row_type_converted,' ', row_rhs)

  return(row_equation)

}

#' Get Row Constraint Equations
#'
#' @param prob the Xpress problem object
#' @param row an integer vector of rows to retreive data for.
#'
get_row_equations <- function(prob, rows){

  # Get Row Count From Problem
  row_count <- xpress::getintattrib(prob = prob, attrib = xpress:::ROWS)

  # Filter Rows
  rows_filtered <- rows[rows <= row_count]

  # Get Problem Size
  rows <- 1:(xpress::getintattrib(prob = prob, xpress:::ROWS)) - 1
  cols <- 1:(xpress::getintattrib(prob = prob, xpress:::COLS)) - 1

  # Get All Row Data
  row_data_list <- lapply(X = rows,
                          FUN = \(x) xpress::getrows(prob = prob, first = x, last = x))

  # Get All Column Names
  row_colnames <- xpress::getnamelist(prob = prob,
                                      first = cols[1],
                                      last = cols[length(cols)], type = 2)

  # Get All Row Types
  row_types <- xpress::getrowtype(prob = prob,
                                  first = rows[1],
                                  last = rows[length(rows)])

  # Convert All Row Types
  row_types_converted <- unname(sapply(X = row_types,
                                       FUN = xpress_convert_row))

  # Get All Row RHS
  row_rhs <- xpress::getrhs(prob = prob,
                            first = rows[1],
                            last = rows[length(rows)])

  # Compile List
  row_equation_vector <- sapply(X = rows_filtered,
                                FUN = \(x) build_row_equation_from_parts(row_data = row_data_list[[x]],
                                                                         row_col_names = row_colnames,
                                                                         row_types = row_types[[x]],
                                                                         row_rhs = row_rhs[[x]]))

  # Add to DataFrame
  row_equation_df <- data.frame(ROW = rows_filtered-1,
                                ROW_EQUATION = row_equation_vector)

  # Return
  return(row_equation_df)

}

#'
#' Run the Xpress solver through the OMPR interface.
#'
#' @param control a list of options passed to \code{xpress::xprs_optimize()}.
#' @param problem_name An optional string parameter to name the Xpress problem.
#' It's a required field so a default name is provided.
#' @param verbose A boolean to set optimizer output to the R console.
#' @param inf_analysis A boolean set whether to Xpress optimizer should report presolve
#' infeasibility resutls (if found). Further details can be found in the
#' details section under "Infeasibility Analysis"
#' @param heur_solution An optional dataframe of model variables ("Variable") and their solutions ("Value") to
#'  for the Xpress solver to perform a local search on for MIP solutions.
#' @param add_row_constraints A boolean to indicate whether row constraint equations should be included in the LP solution.
#'
#' A complete list of control parameters are available in the details section.
#'
#' @import ompr
#' @import xpress
#' @import utils
#'
#' @details
#' The Xpress solver offers an extraordinarily wide range of control settings and feathers. The full list of
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
#' MIP Solution
#' https://www.fico.com/fico-xpress-optimization/docs/latest/mosel/mosel_lang/dhtml/addmipsol.html
#'
#' Sensitivity Analysis
#' Sensitivity analysis will be performed on LP and MIP problems. For MIP problems the integer varabiables be fixed
#' after the mixed integer optimization run, and the problem will be rerun as a LP. Details on the Xpress functions
#' used to perform sensitivity analysis are shown below:
#'
#' Sensitivity Analysis of the objective (objsa):
#' https://www.fico.com/fico-xpress-optimization/docs/latest/solver/optimizer/R/HTML/objsa.html
#'
#' Sensitivity Analysis of the lower and upper bounds (bndsa):
#' https://www.fico.com/fico-xpress-optimization/docs/latest/solver/optimizer/R/HTML/bndsa.html
#'
#' Sensitivity Analysis of the right-hand side (rhssa):
#' https://www.fico.com/fico-xpress-optimization/docs/latest/solver/optimizer/R/HTML/rhssa.html
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
                                            inf_analysis = TRUE, add_row_contraints = TRUE), ...){

  # Check For Xpress Package
  if (!requireNamespace("xpress", quietly = TRUE)){

    # Notify IUser
    stop('You dont have the Xpress package installed')

  }

  # Create Model Run Function
  function(model){

    # Get All Control Parameters
    control <- c(control, list(...))

    # Add Heursitc Solution
    if (!('heur_sol' %in% names(control))){
      control$heur_sol <- data.frame()
    }

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
    problemdata$objcoef <- as.numeric(obj$solution)

    # Get Row Coefficients
    problemdata$A <- constraints$matrix

    # Get Variable Types
    problemdata$columntypes <- unname(sapply(col_types, xpress_col_type_conversion))

    # Get problemdata Types
    problemdata$rowtype <- unlist(lapply(X = constraints$sense, FUN = xpress_sense_conversion))

    # Get Right-Hand Side
    problemdata$rhs <- as.numeric(constraints$rhs)

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

    # Add Presolution
    if (nrow(control$heur_sol) > 0){

      # Create MIP Soluiton
      add_mip_sol(prob = p,
                  heur_sol = control$heur_sol)

    }

    # Run Xpress Optimization
    summary(xpress::xprs_optimize(p))

    # Get Solution Status
    sol_status <- get_ompr_status(getintattrib(p, xpress:::MIPSTATUS))

    # Run If Feasible
    if (sol_status=='optimal'){

      # Extract Xpress Results
      xpress_results <- data.frame(Variable = problemdata$colname, Value = xprs_getsolution(p))

      # Get All Controls
      model_attributes <- xpress_get_params(prob = p)

      # Fix Global Variables
      xpress_verison <- as.character(packageVersion('xpress'))
      if (compareVersion(as.character(xpress_verison),'9.2.5') >= 0){
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
      rhs_sensitivy <- xpress::rhssa(prob = p, rowind = 0:((length(constraints$rhs))-1))

      # Add Variable Names to Sensitivity Ranges
      obj_sensitivity_df <- data.frame(Variable = xpress::getnamelist(p,2,0,(length(obj_sensitivity$lower)-1)),
                                       lower = obj_sensitivity$lower,
                                       upper = obj_sensitivity$upper)
      bnd_sensitivity_df <- data.frame(Variable = xpress::getnamelist(p,2,0,(length(obj_sensitivity$lower)-1)),
                                       lblower = bnd_sensitivity$lblower,
                                       lbupper = bnd_sensitivity$lbupper,
                                       ublower = bnd_sensitivity$ublower,
                                       ubupper = bnd_sensitivity$ubupper)

      # Get Reduced Costs
      reduced_costs <- data.frame(Variable = problemdata$colname,
                                  value = lp_solution$djs[1:(length(problemdata$colname))])

      # Get Row Constraints
      if(control$add_row_contraints){
        row_constraints <- get_row_equations(prob = p, rows = 1:(length(lp_solution$duals)))
        lp_solution$row_constraints <- row_constraints
      }

      # Get Xpress Status
      xpress_status <- get_xpress_status(model_attributes$int_attributes$MIPSTATUS)

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
                                            status = get_ompr_status(model_attributes$int_attributes$MIPSTATUS),
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
                                            status = get_ompr_status(xpress::getintattrib(p,xpress:::MIPSTATUS)),
                                            solution = xpress_results,
                                            additional_solver_output = list(inf_analysis = inf_analysis,
                                                                            model_attributes = model_attributes,
                                                                            xpress_problem = p))


    }

    return(xpress_solution)

  }

}
