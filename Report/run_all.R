
runAllChunks <- function(rmd_file){
  # Create a temporary R script file
  tempR <- tempfile(fileext = ".R")
  # Ensure the temporary file is deleted when the function exits
  on.exit(unlink(tempR)) 
  
  # Extract R code chunks to the temporary file
  knitr::purl(rmd_file, output = tempR)
  
  # Source the temporary R script into the specified environment
  source(tempR)
}


map(
  c(
    "1-input-data.Rmd",
    "2-sample-sizes.Rmd",
    "3-headlines-village.Rmd",
    "4-headlines-wp.Rmd",
    "5-headlines-monitoring.Rmd",
    "6-dsw-functionality.Rmd",
    "7-ilc-functionality.Rmd",
    "8-cl-measurement.Rmd",
    "9-reach.Rmd",
    "10-adoption.Rmd"
  ),
  ~ runAllChunks(.)
)
