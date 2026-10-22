# Build trends.csv for the mental health facility trends post.
#
# Reads the N-MHSS (2015-2020) and N-SUMHSS (2021-2024) public-use files from
# outside the repo and writes two small summary files next to this script:
# trends.csv (shares by item and year) and sample.csv (facilities per year).
# Raw data never enters the repo. Point NSUMHSS_RAW at your copy if it lives
# somewhere else:
#   NSUMHSS_RAW=/path/to/raw Rscript build_data.R

raw_dir <- Sys.getenv("NSUMHSS_RAW", "/Users/jdada/Desktop/gambling/data/raw")
out_dir <- if (requireNamespace("here", quietly = TRUE)) {
  here::here("projects/mh-facility-trends-2026-10")
} else "."

# 2014 (n-mhss/N-MHSS-2014-DS0001-data-r.rda) is left out on purpose: it asked
# each service as a separate Yes/No question, while 2015 onward uses "mark all
# that apply", which gives much lower yes rates for the same item.
files <- c(
  `2015` = "n-mhss/2015.rda",   `2016` = "n-mhss/2016.Rdata",
  `2017` = "n-mhss/2017.rda",   `2018` = "n-mhss/2018.Rdata",
  `2019` = "n-mhss/2019.RData", `2020` = "n-mhss/2020.rdata",
  `2021` = "n-sumhss/2021.rds", `2022` = "n-sumhss/2022.rds",
  `2023` = "n-sumhss/2023.rds", `2024` = "n-sumhss/2024.rds"
)

read_any <- function(f) {
  if (grepl("\\.rds$", f)) return(readRDS(f))
  e <- new.env()
  nm <- load(f, envir = e)
  e[[nm[1]]]
}

label_of <- function(d, v) {
  l <- attr(d[[v]], "label")
  if (is.null(l)) l <- attr(d, "variable.labels")[v]
  if (is.null(l) || is.na(l)) NA_character_ else unname(l)
}

# Mental health items asked in every year, 2015-2024, with 0/1 coding. Found by
# intersecting variable names across all eight files and keeping those whose
# valid values are only 0 and 1. Funding, licensing, and "none/other"
# catch-all items are left out. The accepted-payment items are the one
# renaming: N-SUMHSS added an _MH suffix (REVCHK5 became REVCHK5_MH), so they
# are listed under their 2021+ names and looked up without the suffix before.
items <- list(
  "Treatment setting" = c("SETTINGIP", "SETTINGRC", "SETTINGDTPH", "SETTINGOP"),
  "Treatment approach" = c(
    "TREATPSYCHOTHRPY", "TREATFAMTHRPY", "TREATGRPTHRPY", "TREATCOGTHRPY",
    "TREATDIALTHRPY", "TREATDUALMHSA", "TREATACTVTYTHRPY", "TREATELECTRO",
    "TREATTELEMEDINCE"
  ),
  "Services and practices" = c(
    "ASSERTCOMM", "MHINTCASEMGMT", "MHCASEMGMT", "MHCOURTORDERED", "MHCHRONIC",
    "ILLNESSMGMT", "PRIMARYCARE", "DIETEXERCOUNSEL", "FAMPSYCHED",
    "MHEDUCATION", "MHHOUSING", "SUPPHOUSING", "MHPSYCHREHAB", "MHVOCREHAB",
    "SUPPEMPLOY", "FOSTERCARE", "MHLEGAL", "MHEMGCY", "MHSUICIDE",
    "MHCONSUMER", "MHTOBACCOUSE", "MHTOBACCOCESS", "MHNICOTINEREP",
    "SMOKINGCESSATION", "CRISISTEAM2"
  ),
  "Special programs" = c(
    "SED", "TAYOUNGADULTS", "SPMI", "ALZHDEMENTIA", "SPECGRPEATING",
    "POSTTRAUM", "TRAUMATICBRAIN"
  ),
  "Payment" = c(
    "REVCHK5_MH", "REVCHK8_MH", "REVCHK2_MH", "REVCHK1_MH", "REVCHK10_MH",
    "REVCHK15_MH", "REVCHK17_MH", "FEESCALE", "PAYASST"
  )
)
chart_of <- function(g) ifelse(g %in% c("Treatment setting", "Payment"),
                               "Settings and payment", "Services")
group_of <- setNames(rep(names(items), lengths(items)), unlist(items))
vars <- unlist(items, use.names = FALSE)

# Column name for item v in data d, allowing for the _MH suffix.
col_in <- function(d, v) {
  if (v %in% names(d)) return(v)
  old <- sub("_MH$", "", v)
  if (old %in% names(d)) return(old)
  stop("Item ", v, " not found")
}

trends <- list()
labels <- list()
sample <- list()
for (y in names(files)) {
  d <- read_any(file.path(raw_dir, files[[y]]))
  # Row subsetting drops column label attributes, so read labels first.
  cols <- vapply(vars, function(v) col_in(d, v), character(1))
  labs <- vapply(vars, function(v) label_of(d, cols[[v]]), character(1))
  # 2021+: N-SUMHSS covers both SU and MH facilities. Keep the facilities that
  # completed the MH module (MH items non-missing), the closest match to the
  # N-MHSS universe of earlier years.
  if (as.integer(y) >= 2021) d <- d[!is.na(d$MHSUICIDE), ]
  for (v in vars) {
    x <- d[[cols[[v]]]]
    # 2015 stores answers as Yes/No factors; later years use 0/1.
    x <- if (is.factor(x)) c(No = 0, Yes = 1)[as.character(x)] else as.numeric(x)
    # Denominator is facilities that answered this item: skip, missing,
    # don't know, and refused codes and blanks are dropped, per item and year.
    ok <- !is.na(x) & x %in% c(0, 1)
    trends[[length(trends) + 1]] <- data.frame(
      year = as.integer(y), variable = v, group = group_of[[v]],
      share = round(mean(x[ok]), 4), n_facilities = sum(ok)
    )
  }
  if (y == "2024") labels <- labs
  sample[[y]] <- data.frame(year = as.integer(y), facilities = nrow(d))
  rm(d); gc()
}
trends <- do.call(rbind, trends)

# Display labels: the 2024 codebook wording, minus the question number and
# the "Facility provides" boilerplate.
clean <- sub("\\s*\\(Q\\.[^)]*\\)$", "", labels)
prog <- grepl("^Specially designed program/group for ", clean)
clean <- sub("^(Facility provides|Specially designed program/group for) ", "", clean)
clean[prog] <- paste("Program for", sub("^([A-Z])([a-z])", "\\L\\1\\2", clean[prog], perl = TRUE))
clean <- sub("for alzheimer", "for Alzheimer", clean)
clean <- paste0(toupper(substr(clean, 1, 1)), substr(clean, 2, nchar(clean)))
trends$label <- setNames(clean, names(labels))[trends$variable]
trends$chart <- chart_of(trends$group)
trends <- trends[, c("year", "variable", "label", "group", "chart", "share", "n_facilities")]

write.csv(trends, file.path(out_dir, "trends.csv"), row.names = FALSE)
write.csv(do.call(rbind, sample), file.path(out_dir, "sample.csv"), row.names = FALSE)
message("Wrote ", nrow(trends), " rows to trends.csv")
