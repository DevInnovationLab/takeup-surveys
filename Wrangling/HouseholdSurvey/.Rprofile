path_box <- file.path(Sys.getenv("BOX"),"i-h2o-takeup")
path_git <- file.path(Sys.getenv("GITHUB"),"i-h2o-takeup")

library(purrr)

map(
  list.files(
    file.path(path_git, "code/funs"),
    full.names = T
  ), 
  source
)


library(kableExtra)

kable_format <-
  list(decimal.mark = ".", big.mark = ",")

library(ggplot2)

theme <-
  theme_minimal() +
  theme(
    strip.background = element_rect(
      fill = "gray90",
      color = "gray90"
    ),
    plot.title = element_text(hjust = 0.5),
    text = element_text(size = 11, family = "Times"),
    plot.caption = element_text(
      hjust = 0,
      size = 10,
      color = "gray40"
    ),
    legend.position = "bottom"
  )
