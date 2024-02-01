
# IMport Libraries
suppressWarnings(library(ompr.xpress))

##### Models ####
#___________________________________________________________
# Create Simple Example
model_results <- MIPModel() |>
  add_variable(x, type = "integer") |>
  add_variable(y, type = "continuous", lb = 0) |>
  set_bounds(x, lb = 0) |>
  set_objective(x + y, "max") |>
  add_constraint(x + y <= 11.25) |>
  solve_model(xpress_optimizer()) |>
  suppressMessages()

# Check Results
test_that("simple model", {
  expect_equal(model_results$objective_value, 11.25)
})

#___________________________________________________________
# Create Scheduling Model
# Create Time Vector
shift_time <- c('0700 - 0900',
                '0900 - 1100',
                '1100 - 1300',
                '1300 - 1500',
                '1500 - 1700',
                '1700 - 1900',
                '1900 - 2100')

# Shift Average Calls
shift_avg_calls <- c(40,85,70,95,80,35,10)

# Shift Pay
shift_rate <- c(rep(30,5),rep(45,2))

# Call Language
call_language <- c('English' = .80,
                   'Spanish' = .20)

# Set Model Params
n_periods <- 7
n_shift_starts <- 7
hourly_avg_calls <- 6

# Create Shift Parametes DataFrame
df_shift_params <- data.frame(TIME = shift_time,
                              SHIFT_NUM = 1:7,
                              AVG_CALLS = shift_avg_calls,
                              SHIFT_RATE = shift_rate)

df_shift_params$CALLS_ENGLISH <- df_shift_params$AVG_CALLS*call_language[['English']]
df_shift_params$CALLS_SPANISH <- df_shift_params$AVG_CALLS*call_language[['Spanish']]


model <- ompr::MIPModel() |>
  # Create Decision Variables
  # Create English Full Time Decision Variables
  add_variable(ft_english_start[p], type = 'integer', p = 1:n_periods, lb = 0) |>
  add_variable(ft_english_on_calls[p,s], type = 'integer', p = 1:n_periods, s = 1:n_shift_starts, lb = 0) |>
  add_variable(ft_english_call_max[p], type = 'continuous', p = 1:n_periods, lb = 0) |>
  add_variable(ft_english_tot_on_call[p], type = 'continuous', p = 1:n_periods, lb = 0) |>
  # Create English Part Time Decision Variables
  add_variable(pt_english_start[p], type = 'integer', p = 1:n_periods, lb = 0) |>
  add_variable(pt_english_on_calls[p,s], type = 'integer', p = 1:n_periods, s = 1:n_shift_starts, lb = 0) |>
  add_variable(pt_english_call_max[p], type = 'continuous', p = 1:n_periods, lb = 0) |>
  add_variable(pt_english_tot_on_call[p], type = 'continuous', p = 1:n_periods, lb = 0) |>
  # Create Spanish Full Time Decision Variables
  add_variable(ft_spanish_start[p], type = 'integer', p = 1:n_periods, lb = 0) |>
  add_variable(ft_spanish_on_calls[p,s], type = 'integer', p = 1:n_periods, s = 1:n_shift_starts, lb = 0) |>
  add_variable(ft_spanish_call_max[p], type = 'continuous', p = 1:n_periods, lb = 0) |>
  add_variable(ft_spanish_tot_on_call[p], type = 'continuous', p = 1:n_periods, lb = 0) |>
# Add English Full Time Constraints
  # Add Two-Hour Constraints For Shifts 1-5
  add_constraint(ft_english_start[p] == sum_over(ft_english_on_calls[p,s], p = 1:2, s = 1), p = 1) |>
  add_constraint(ft_english_start[p] == sum_over(ft_english_on_calls[p,s], p = 2:3, s = 2), p = 2) |>
  add_constraint(ft_english_start[p] == sum_over(ft_english_on_calls[p,s], p = 3:4, s = 3), p = 3) |>
  add_constraint(ft_english_start[p] == sum_over(ft_english_on_calls[p,s], p = 4:5, s = 4), p = 4) |>
  add_constraint(ft_english_start[p] == sum_over(ft_english_on_calls[p,s], p = 5:6, s = 5), p = 5) |>
  # Add Constraints For Shift On-Call Max and Mins
  # Add Constraints For First Shift Starters
  add_constraint(ft_english_on_calls[p,s] <= ft_english_start[p], p = 1, s = 1) |>
  add_constraint(ft_english_on_calls[p,s] <= ft_english_start[p-1], p = 2, s = 1) |>
  add_constraint(ft_english_on_calls[p,s] == ft_english_on_calls[p-2,s], p = 3, s = 1) |>
  add_constraint(ft_english_on_calls[p,s] == ft_english_on_calls[p-2,s], p = 4, s = 1) |>
  add_constraint(ft_english_on_calls[p,s] == 0, p = 5:7, s = 1) |>
  # Add Constraints For Second Shift Starters
  add_constraint(ft_english_on_calls[p,s] == 0, p = 1, s = 2) |>
  add_constraint(ft_english_on_calls[p,s] <= ft_english_start[p], p = 2, s = 2) |>
  add_constraint(ft_english_on_calls[p,s] <= ft_english_start[p-1], p = 3, s = 2) |>
  add_constraint(ft_english_on_calls[p,s] == ft_english_on_calls[p-2,s], p = 4, s = 2) |>
  add_constraint(ft_english_on_calls[p,s] == ft_english_on_calls[p-2,s], p = 5, s = 2) |>
  add_constraint(ft_english_on_calls[p,s] == 0, p = 6:7, s = 2) |>
  # Add Constraints For Third Shift Starters
  add_constraint(ft_english_on_calls[p,s] == 0, p = 1:2, s = 3) |>
  add_constraint(ft_english_on_calls[p,s] <= ft_english_start[p], p = 3, s = 3) |>
  add_constraint(ft_english_on_calls[p,s] <= ft_english_start[p-1], p = 4, s = 3) |>
  add_constraint(ft_english_on_calls[p,s] == ft_english_on_calls[p-2,s], p = 5, s = 3) |>
  add_constraint(ft_english_on_calls[p,s] == ft_english_on_calls[p-2,s], p = 6, s = 3) |>
  add_constraint(ft_english_on_calls[p,s] == 0, p = 7, s = 3) |>
  # Add Constraints For Fourth Shift Starters
  add_constraint(ft_english_on_calls[p,s] == 0, p = 1:3, s = 4) |>
  add_constraint(ft_english_on_calls[p,s] <= ft_english_start[p], p = 4, s = 4) |>
  add_constraint(ft_english_on_calls[p,s] <= ft_english_start[p-1], p = 5, s = 4) |>
  add_constraint(ft_english_on_calls[p,s] == ft_english_on_calls[p-2,s], p = 6, s = 4) |>
  add_constraint(ft_english_on_calls[p,s] == ft_english_on_calls[p-2,s], p = 7, s = 4) |>
  # Add Constraints For Fifth Shift Starters
  add_constraint(ft_english_on_calls[p,s] == 0, p = 1:4, s = 5) |>
  add_constraint(ft_english_on_calls[p,s] <= ft_english_start[p], p = 5, s = 5) |>
  add_constraint(ft_english_on_calls[p,s] <= ft_english_start[p-1], p = 6, s = 5) |>
  add_constraint(ft_english_on_calls[p,s] == ft_english_on_calls[p-2,s], p = 7, s = 5) |>
  # Add Constraints For Shifts Six - Seven (No Allowed Starts For Full Time Employees)
  add_constraint(ft_english_on_calls[p,s] == 0, p = 1:7, s = 6:7) |>
  # Add Constraints To Calculate All On-Shift Callers, and Call Max Levels
  add_constraint(ft_english_tot_on_call[p] == sum_over(ft_english_on_calls[p,s],
                                                       s = 1:n_shift_starts), p = 1:n_periods) |>
  add_constraint(ft_english_call_max[p] == ft_english_tot_on_call[p]*hourly_avg_calls, p = 1:n_periods) |>
# Add English Part-Time Constraints
  # Add Constraints For Shift On-Call Max and Mins
  # Add Constraints For Shifts 1-4, and 7
  add_constraint(pt_english_on_calls[p,s] == 0, p = 1:7, s = 1:4) |>
  add_constraint(pt_english_on_calls[p,s] == 0, p = 1:7, s = 7) |>
  # Add Constraints For Fifth Shift Starters
  add_constraint(pt_english_on_calls[p,s] == 0, p = 1:4, s = 5) |>
  add_constraint(pt_english_on_calls[p,s] == pt_english_start[p], p = 5, s = 5) |>
  add_constraint(pt_english_on_calls[p,s] == pt_english_start[p-1], p = 6, s = 5) |>
  add_constraint(pt_english_on_calls[p,s] == 0, p = 7, s = 5) |>
  # Add Constraints For Sixth Shift Starters
  add_constraint(pt_english_on_calls[p,s] == 0, p = 1:5, s = 6) |>
  add_constraint(pt_english_on_calls[p,s] == pt_english_start[p], p = 6, s = 6) |>
  add_constraint(pt_english_on_calls[p,s] == pt_english_start[p-1], p = 7, s = 6) |>
  # Add Constraint to Calclate All On-Shift Callers, and Max Levels
  add_constraint(pt_english_tot_on_call[p] == sum_over(pt_english_on_calls[p,s],
                                                       s = 1:n_shift_starts), p = 1:n_periods) |>
  add_constraint(pt_english_call_max[p] == pt_english_tot_on_call[p]*hourly_avg_calls, p = 1:n_periods) |>
# Add Spanish Full Time Constraints
  # Add Two-Hour Constraints For Shifts 1-5
  add_constraint(ft_spanish_start[p] == sum_over(ft_spanish_on_calls[p,s], p = 1:2, s = 1), p = 1) |>
  add_constraint(ft_spanish_start[p] == sum_over(ft_spanish_on_calls[p,s], p = 2:3, s = 2), p = 2) |>
  add_constraint(ft_spanish_start[p] == sum_over(ft_spanish_on_calls[p,s], p = 3:4, s = 3), p = 3) |>
  add_constraint(ft_spanish_start[p] == sum_over(ft_spanish_on_calls[p,s], p = 4:5, s = 4), p = 4) |>
  add_constraint(ft_spanish_start[p] == sum_over(ft_spanish_on_calls[p,s], p = 5:6, s = 5), p = 5) |>
  # Add Constraints For Shift On-Call Max and Mins
  # Add Constraints For First Shift Starters
  add_constraint(ft_spanish_on_calls[p,s] <= ft_spanish_start[p], p = 1, s = 1) |>
  add_constraint(ft_spanish_on_calls[p,s] <= ft_spanish_start[p-1], p = 2, s = 1) |>
  add_constraint(ft_spanish_on_calls[p,s] == ft_spanish_on_calls[p-2,s], p = 3, s = 1) |>
  add_constraint(ft_spanish_on_calls[p,s] == ft_spanish_on_calls[p-2,s], p = 4, s = 1) |>
  add_constraint(ft_spanish_on_calls[p,s] == 0, p = 5:7, s = 1) |>
  # Add Constraints For Second Shift Starters
  add_constraint(ft_spanish_on_calls[p,s] == 0, p = 1, s = 2) |>
  add_constraint(ft_spanish_on_calls[p,s] <= ft_spanish_start[p], p = 2, s = 2) |>
  add_constraint(ft_spanish_on_calls[p,s] <= ft_spanish_start[p-1], p = 3, s = 2) |>
  add_constraint(ft_spanish_on_calls[p,s] == ft_spanish_on_calls[p-2,s], p = 4, s = 2) |>
  add_constraint(ft_spanish_on_calls[p,s] == ft_spanish_on_calls[p-2,s], p = 5, s = 2) |>
  add_constraint(ft_spanish_on_calls[p,s] == 0, p = 6:7, s = 2) |>
  # Add Constraints For Third Shift Starters
  add_constraint(ft_spanish_on_calls[p,s] == 0, p = 1:2, s = 3) |>
  add_constraint(ft_spanish_on_calls[p,s] <= ft_spanish_start[p], p = 3, s = 3) |>
  add_constraint(ft_spanish_on_calls[p,s] <= ft_spanish_start[p-1], p = 4, s = 3) |>
  add_constraint(ft_spanish_on_calls[p,s] == ft_spanish_on_calls[p-2,s], p = 5, s = 3) |>
  add_constraint(ft_spanish_on_calls[p,s] == ft_spanish_on_calls[p-2,s], p = 6, s = 3) |>
  add_constraint(ft_spanish_on_calls[p,s] == 0, p = 7, s = 3) |>
  # Add Constraints For Fourth Shift Starters
  add_constraint(ft_spanish_on_calls[p,s] == 0, p = 1:3, s = 4) |>
  add_constraint(ft_spanish_on_calls[p,s] <= ft_spanish_start[p], p = 4, s = 4) |>
  add_constraint(ft_spanish_on_calls[p,s] <= ft_spanish_start[p-1], p = 5, s = 4) |>
  add_constraint(ft_spanish_on_calls[p,s] == ft_spanish_on_calls[p-2,s], p = 6, s = 4) |>
  add_constraint(ft_spanish_on_calls[p,s] == ft_spanish_on_calls[p-2,s], p = 7, s = 4) |>
  # Add Constraints For Fifth Shift Starters
  add_constraint(ft_spanish_on_calls[p,s] == 0, p = 1:4, s = 5) |>
  add_constraint(ft_spanish_on_calls[p,s] <= ft_spanish_start[p], p = 5, s = 5) |>
  add_constraint(ft_spanish_on_calls[p,s] <= ft_spanish_start[p-1], p = 6, s = 5) |>
  add_constraint(ft_spanish_on_calls[p,s] == ft_spanish_on_calls[p-2,s], p = 7, s = 5) |>
  # Add Constraints For Shifts Five - Seven (No Allowed Starts For Full Time Employees)
  add_constraint(ft_spanish_on_calls[p,s] == 0, p = 1:7, s = 6:7) |>
  # Add Constraints To Calculate All On-Shift Callers, and Call Max Levels
  add_constraint(ft_spanish_tot_on_call[p] == sum_over(ft_spanish_on_calls[p,s],
                                                       s = 1:n_shift_starts), p = 1:n_periods) |>
  add_constraint(ft_spanish_call_max[p] == ft_spanish_tot_on_call[p]*hourly_avg_calls, p = 1:n_periods) |>
# Set All Calls Covered Constraint For English & Spanish Calls
  add_constraint((ft_english_call_max[p] + pt_english_call_max[p])
                 >= df_shift_params$CALLS_ENGLISH[p], p = 1:n_periods) |>
  add_constraint(ft_spanish_call_max[p] >= df_shift_params$CALLS_SPANISH[p], p = 1:n_periods) |>
# Create Objective Function
  ompr::set_objective(sum_over(ft_english_tot_on_call[p]*df_shift_params$SHIFT_RATE[p]*2 +
                           pt_english_tot_on_call[p]*df_shift_params$SHIFT_RATE[p]*2 +
                           ft_spanish_tot_on_call[p]*df_shift_params$SHIFT_RATE[p]*2,
                         p = 1:n_periods), sense = 'min')

  # Run Optimizer
model_results_scheduling <- model |> ompr::solve_model(xpress_optimizer())

# Check Results
test_that("shift schedule model", {
  expect_equal(model_results_scheduling$objective_value, 5040)
})

#___________________________________________________________
# Add Heusistic Solution

# Extract Results
opt_heur_sol <- model_results_scheduling$solution

# Run Optimizer
model_results_heur <- model |>
  ompr::solve_model(xpress_optimizer(heur_sol = opt_heur_sol))

# Check Results
test_that("heuristic solution", {
  expect_equal(model_results_heur$objective_value, 5040)
})

#___________________________________________________________
# Update Model To Enure Infeasiblity

# Add Model Constraint
model <- model |>
  add_constraint(ft_english_start[p] <= 0, p = 1:2)

# Run Model
model_inf <- model |>
  ompr::solve_model(xpress_optimizer())

# Check Infeasibility
test_that("infeasibility analysis", {
  expect_equal(model_inf$additional_solver_output$inf_analysis$inf_equation,
               "ft_english_call_max[1] + pt_english_call_max[1] >= 32")
})



