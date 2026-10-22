# Make thumbnail.png for the Projects card. Run from the repo root after build_data.R.
library(ggplot2)
source("R/theme_joydada.R")
d <- read.csv("projects/mh-facility-trends-2026-10/trends.csv")
d <- d[d$variable %in% c("MHSUICIDE", "TREATTELEMEDINCE", "SPECGRPEATING"), ]
d$label <- c(MHSUICIDE = "Suicide prevention", TREATTELEMEDINCE = "Telehealth", SPECGRPEATING = "Eating disorder program")[d$variable]
p <- ggplot(d, aes(year, share, group = label)) +
  geom_line(aes(colour = label), linewidth = 1.3) + geom_point(aes(colour = label), size = 2) +
  scale_colour_manual(values = c("#B51D5A", "#343A8F", "#F978AE"), name = NULL) +
  scale_y_continuous(labels = scales::percent, limits = c(0, 0.85)) +
  scale_x_continuous(breaks = 2015:2024) +
  labs(x = NULL, y = NULL, title = "Share of mental health facilities offering...") +
  theme_joydada() + theme(legend.position = "bottom")
ggsave("projects/mh-facility-trends-2026-10/thumbnail.png", p, width = 6, height = 4, dpi = 150, bg = "white")
