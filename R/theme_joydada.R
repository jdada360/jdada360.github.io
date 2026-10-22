# joydada palette + ggplot theme, so figures match the site
jd_pink   <- c("#3D1020","#7D0F3C","#B51D5A","#F81E78","#FC4D8F","#F978AE","#FBA3C6","#FDD3E2")
jd_indigo <- c("#11102E","#1F1A52","#2B2A70","#343A8F","#5350A0","#7A73B3","#A8A2CF","#D4D2E7")
jd_seq    <- c("#FDD3E2","#F978AE","#B51D5A","#7D0F3C","#3D1020")
jd_div    <- c("#343A8F","#7A73B3","#F5F3FA","#F978AE","#B51D5A")

theme_joydada <- function(base_size = 13) {
  ggplot2::theme_minimal(base_size = base_size) +
    ggplot2::theme(
      text = ggplot2::element_text(colour = "#1F1A52"),
      plot.title = ggplot2::element_text(face = "bold", colour = "#2B2A70"),
      plot.title.position = "plot",
      panel.grid.minor = ggplot2::element_blank(),
      panel.grid.major = ggplot2::element_line(colour = "#EDE6F0"),
      plot.background = ggplot2::element_rect(fill = "transparent", colour = NA)
    )
}
