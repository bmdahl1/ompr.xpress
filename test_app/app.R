#
# This is a Shiny web application. You can run the application by clicking
# the 'Run App' button above.
#
# Find out more about building applications with Shiny here:
#
#    https://shiny.posit.co/
#

library(shiny)
library(bslib)

# Define UI for application that draws a histogram
ui <- page_navbar(
  sidebar = sidebar("Sidebar"),
  nav_panel("Page 1", "Page 1 content"),
  nav_panel("Page 2", "Page 2 content")
)


# Define server logic required to draw a histogram
server <- function(input, output) {


}

# Run the application
shinyApp(ui = ui, server = server)
