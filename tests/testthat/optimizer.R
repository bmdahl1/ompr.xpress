
# Create Simple Example
model_results <- MIPModel() |>
  add_variable(x, type = "integer") |>
  add_variable(y, type = "continuous", lb = 0) |>
  set_bounds(x, lb = 0) |>
  set_objective(x + y, "max") |>
  add_constraint(x + y <= 11.25) |>
  solve_model(xpress_optimizer())

# Check Results
test_that("simple model", {
  expect_equal(model_results$objective_value, 11.25)
})
load_all()
