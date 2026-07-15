
## RACING synthetic data analysis setup
## Synthetic example data; not original RACING patient-level data.

suppressPackageStartupMessages({
  library(data.table)
  library(magrittr)
  library(jstable)
  library(survival)
  library(ggplot2)
  library(flextable)
  library(openxlsx)
  library(officer)
  library(rvg)
  library(grid)
  library(gridExtra)
  library(ragg)
  library(scales)
  library(patchwork)
  library(forestploter)
})
project_dir <- normalizePath(getwd(), winslash = "/", mustWork = TRUE)
data_path <- file.path(project_dir, "RACING_synthetic_data.csv")
asset_dir <- file.path(project_dir, "docs", "2026-07-21-RCT-RACING")
results_dir <- file.path(project_dir, "results")
figures_dir <- file.path(project_dir, "figures")

stopifnot(file.exists(data_path), dir.exists(asset_dir))
dir.create(results_dir, showWarnings = FALSE, recursive = TRUE)
dir.create(figures_dir, showWarnings = FALSE, recursive = TRUE)

a <- fread(data_path, na.strings = c("", "NA", "N/A"))
stopifnot(nrow(a) == 3780L, ncol(a) == 57L)

a[, group := factor(group, levels = c("Combination", "Monotherapy"))]

event_vars <- grep("_event$", names(a), value = TRUE)
for (v in event_vars) set(a, j = v, value = as.integer(a[[v]]))
a[, admend_mo := as.integer(admend_mo)]
a[, primary_time_mo := as.integer(primary_time_mo)]

stopifnot(
  all(a$admend_mo >= 1L & a$admend_mo <= 36L),
  all(is.na(a$primary_time_mo) == (a$primary_event == 0L)),
  all(a[primary_event == 1L, primary_time_mo] <=
        a[primary_event == 1L, admend_mo])
)

for (tp in c("y1", "y2", "y3")) {
  v <- paste0("LDL_", tp)
  a[, (paste0("LDL70_", tp)) := fifelse(
    is.na(get(v)), NA_integer_, as.integer(get(v) < 70)
  )]
  a[, (paste0("LDL55_", tp)) := fifelse(
    is.na(get(v)), NA_integer_, as.integer(get(v) < 55)
  )]
}

a[, Age60 := factor(ifelse(Age < 60, "<60", "≥60"), levels = c("<60", "≥60"))]
a[, BMI25 := factor(ifelse(BMI < 25, "<25", "≥25"), levels = c("<25", "≥25"))]
a[, Baseline_LDL_100 := factor(
  ifelse(Baseline_LDL < 100, "<100", "≥100"),
  levels = c("<100", "≥100")
)]

binary_label <- function(x) {
  factor(ifelse(x == 1, "Yes", "No"), levels = c("No", "Yes"))
}
for (v in c("Diabetes", "Hypertension", "CKD", "Prior_MI",
            "Prior_stroke", "PAD")) {
  a[, (paste0(v, "_f")) := binary_label(get(v))]
}
a[, Sex_f := factor(Sex, levels = c("Female", "Male"))]

varlist <- list(
  ID = "ID",
  Base = c(
    "group", "Age", "Sex", "Height", "Weight", "BMI", "Prior_MI", "Prior_PCI",
    "Prior_CABG", "ACS", "Prior_stroke", "CKD", "ESRD_dialysis", "PAD",
    "Hypertension", "Diabetes", "Diabetes_insulin", "Smoking",
    "Baseline_LDL", "Pre_HI_statin", "Pre_HI_statin_ezetimibe",
    "Pre_MI_statin", "Pre_MI_statin_ezetimibe", "Pre_LI_statin", "Pre_none"
  ),
  Followup = "admend_mo",
  Time = "primary_time_mo",
  Event = "primary_event",
  Clinical = c(
    "primary_event", "secondary_event", "cv_death_event",
    "allcause_death_event", "mace_event", "coronary_revasc_event",
    "peripheral_revasc_event", "cv_hosp_event", "hf_hosp_event",
    "nonfatal_stroke_event", "ischemic_stroke_event",
    "hemorrhagic_stroke_event"
  ),
  LDL = c(
    "LDL_y1", "LDL_y2", "LDL_y3",
    "LDL70_y1", "LDL70_y2", "LDL70_y3",
    "LDL55_y1", "LDL55_y2", "LDL55_y3"
  ),
  Safety = c(
    "new_diabetes", "new_diabetes_med", "muscle_ae", "myalgia",
    "myopathy", "myonecrosis", "hepatic_ae", "ck_elevation",
    "fasting_glucose_elevation", "gallbladder_ae", "major_bleeding",
    "cancer", "neurocognitive_disorder", "cataract_surgery"
  ),
  Subgroup = c(
    "Age60", "Sex_f", "BMI25", "Diabetes_f", "Hypertension_f", "CKD_f",
    "Prior_MI_f", "Prior_stroke_f", "PAD_f", "Baseline_LDL_100"
  )
)

varlist <- lapply(varlist, function(v) intersect(v, names(a)))
stopifnot(
  identical(varlist$Time, "primary_time_mo"),
  identical(varlist$Event, "primary_event")
)

out <- a[, .SD, .SDcols = unique(unlist(varlist))]

factor_vars <- names(out)[vapply(
  out,
  function(z) length(unique(na.omit(z))) <= 6L,
  logical(1)
)]
factor_vars <- setdiff(
  factor_vars,
  c(varlist$ID, varlist$Time, varlist$Followup)
)
out[, (factor_vars) := lapply(.SD, factor), .SDcols = factor_vars]

vars01 <- vapply(factor_vars, function(v) {
  lv <- sort(unique(na.omit(as.character(out[[v]]))))
  length(lv) > 0L && all(lv %in% c("0", "1"))
}, logical(1))
for (v in names(vars01)[vars01]) {
  out[, (v) := factor(as.character(get(v)), levels = c("0", "1"))]
}

conti_vars <- setdiff(names(out), c(factor_vars, varlist$ID))
out[, (conti_vars) := lapply(.SD, as.numeric), .SDcols = conti_vars]

out.label <- jstable::mk.lev(out)
for (v in names(vars01)[vars01]) {
  out.label[variable == v, val_label := c("No", "Yes")]
}

variable_labels <- c(
  group = "Treatment group",
  Age = "Age, years",
  Sex = "Sex",
  Height = "Height, cm",
  Weight = "Weight, kg",
  BMI = "Body-mass index, kg/m²",
  Prior_MI = "Previous myocardial infarction",
  Prior_PCI = "Previous percutaneous coronary intervention",
  Prior_CABG = "Previous coronary bypass graft surgery",
  ACS = "Acute coronary syndrome",
  Prior_stroke = "Previous ischaemic stroke",
  CKD = "Chronic kidney disease",
  ESRD_dialysis = "End-stage kidney disease on dialysis",
  PAD = "Peripheral artery disease",
  Hypertension = "Hypertension",
  Diabetes = "Diabetes",
  Diabetes_insulin = "Diabetes with insulin treatment",
  Smoking = "Current smoker",
  Baseline_LDL = "Serum LDL-C, mg/dL",
  admend_mo = "Administrative end of follow-up, months",
  primary_time_mo = "Time to primary endpoint, months",
  primary_event = "Primary endpoint",
  LDL_y1 = "LDL-C at 1 year, mg/dL",
  LDL_y2 = "LDL-C at 2 years, mg/dL",
  LDL_y3 = "LDL-C at 3 years, mg/dL"
)
for (v in intersect(names(variable_labels), out.label$variable)) {
  out.label[variable == v, var_label := unname(variable_labels[v])]
}

out.long <- rbindlist(lapply(seq_len(3L), function(yr) {
  ldl <- paste0("LDL_y", yr)
  ldl70 <- paste0("LDL70_y", yr)
  ldl55 <- paste0("LDL55_y", yr)

  out[, .(
    ID,
    group,
    timepoint = factor(
      paste0(yr, if (yr == 1L) " year" else " years"),
      levels = c("1 year", "2 years", "3 years")
    ),
    LDL = get(ldl),
    LDL70 = factor(as.character(get(ldl70)), levels = c("0", "1")),
    LDL55 = factor(as.character(get(ldl55)), levels = c("0", "1"))
  )]
}))

out.long.label <- jstable::mk.lev(out.long)
out.long.label[variable == "group", var_label := "Treatment group"]
out.long.label[variable == "timepoint", var_label := "Timepoint"]
out.long.label[variable == "LDL", var_label := "LDL-C, mg/dL"]
out.long.label[variable == "LDL70", var_label := "LDL-C <70 mg/dL"]
out.long.label[variable == "LDL55", var_label := "LDL-C <55 mg/dL"]
out.long.label[variable == "LDL70", val_label := c("No", "Yes")]
out.long.label[variable == "LDL55", val_label := c("No", "Yes")]

group_levels <- levels(out$group)

base_labels <- c(
  Age = "Age, years",
  Sex = "Male sex",
  Height = "Height, cm",
  Weight = "Weight, kg",
  BMI = "Body-mass index, kg/m²",
  Prior_MI = "Previous myocardial infarction",
  Prior_PCI = "Previous percutaneous coronary intervention",
  Prior_CABG = "Previous coronary bypass graft surgery",
  ACS = "Acute coronary syndrome",
  Prior_stroke = "Previous ischaemic stroke",
  CKD = "Chronic kidney disease",
  ESRD_dialysis = "End-stage kidney disease on dialysis",
  PAD = "Peripheral artery disease",
  Hypertension = "Hypertension",
  Diabetes = "Diabetes",
  Diabetes_insulin = "Diabetes with insulin treatment",
  Smoking = "Current smoker",
  Baseline_LDL = "Serum LDL-C, mg/dL",
  Pre_HI_statin = "High-intensity statin",
  Pre_HI_statin_ezetimibe = "High-intensity statin + ezetimibe",
  Pre_MI_statin = "Moderate-intensity statin",
  Pre_MI_statin_ezetimibe = "Moderate-intensity statin + ezetimibe",
  Pre_LI_statin = "Low-intensity statin",
  Pre_none = "No lipid-lowering treatment"
)

clinical_labels <- c(
  primary_event = "Primary endpoint",
  secondary_event = "All-cause death, major cardiovascular event, or non-fatal stroke",
  cv_death_event = "Cardiovascular death",
  allcause_death_event = "All-cause death",
  mace_event = "Major cardiovascular events",
  coronary_revasc_event = "Coronary artery revascularisation",
  peripheral_revasc_event = "Peripheral artery revascularisation",
  cv_hosp_event = "Hospitalisation for cardiovascular events",
  hf_hosp_event = "Hospitalisation for heart failure",
  nonfatal_stroke_event = "Non-fatal stroke",
  ischemic_stroke_event = "Ischaemic stroke",
  hemorrhagic_stroke_event = "Haemorrhagic stroke"
)

safety_labels <- c(
  new_diabetes = "New-onset diabetes",
  new_diabetes_med = "New-onset diabetes with medication initiation",
  muscle_ae = "Muscle-related adverse events",
  myalgia = "Myalgia",
  myopathy = "Myopathy",
  myonecrosis = "Myonecrosis",
  hepatic_ae = "Hepatic-related adverse events",
  ck_elevation = "Creatine kinase elevation",
  fasting_glucose_elevation = "Fasting glucose elevation",
  gallbladder_ae = "Gallbladder-related adverse events",
  major_bleeding = "Major bleeding",
  cancer = "Cancer diagnosis",
  neurocognitive_disorder = "New-onset neurocognitive disorder",
  cataract_surgery = "Cataract surgery"
)

subgroup_labels <- c(
  Age60 = "Age, years",
  Sex_f = "Sex",
  BMI25 = "BMI, kg/m²",
  Diabetes_f = "Diabetes",
  Hypertension_f = "Hypertension",
  CKD_f = "Chronic kidney disease",
  Prior_MI_f = "Previous myocardial infarction",
  Prior_stroke_f = "Previous ischaemic stroke",
  PAD_f = "Peripheral artery disease",
  Baseline_LDL_100 = "Baseline LDL-C, mg/dL"
)

synthetic_note <- "Synthetic example data; not original RACING patient-level data."

fmt_p <- function(p) {
  ans <- rep("", length(p))
  ans[!is.na(p) & p < 0.001] <- "<0.001"
  idx <- !is.na(p) & p >= 0.001
  ans[idx] <- sprintf("%.3f", p[idx])
  ans
}

binary_p <- function(x, g) {
  ok <- !is.na(x) & !is.na(g)
  tb <- table(x[ok], g[ok])
  if (nrow(tb) < 2L || ncol(tb) < 2L) return(NA_real_)
  expected <- suppressWarnings(chisq.test(tb, correct = FALSE)$expected)
  if (any(expected < 5)) fisher.test(tb)$p.value else
    suppressWarnings(chisq.test(tb, correct = FALSE)$p.value)
}

continuous_p <- function(x, g) {
  ok <- !is.na(x) & !is.na(g)
  if (length(unique(g[ok])) != 2L) return(NA_real_)
  suppressWarnings(wilcox.test(x[ok] ~ g[ok], exact = FALSE)$p.value)
}

event_summary <- function(data, variable) {
  z <- copy(data[!is.na(get(variable))])
  z[, .event := as.integer(as.character(get(variable)))]
  z <- z[, .(
    N = .N,
    Events = sum(.event == 1L)
  ), by = group][order(group)]
  stopifnot(nrow(z) == 2L)
  z
}

risk_difference <- function(events, totals, conf.level = 0.95) {
  fit <- suppressWarnings(prop.test(events, totals, conf.level = conf.level, correct = FALSE))
  c(
    estimate = events[1] / totals[1] - events[2] / totals[2],
    lower = unname(fit$conf.int[1]),
    upper = unname(fit$conf.int[2]),
    p = fit$p.value
  )
}

save_paper_table_png <- function(df, filename, caption, note = synthetic_note,
                                 row_type = rep("data", nrow(df)),
                                 col_widths = NULL,
                                 width = 2400, height = 1500,
                                 font_size = 13) {
  df <- as.data.frame(df, check.names = FALSE)
  df[] <- lapply(df, as.character)
  stopifnot(length(row_type) == nrow(df))

  wrap_text <- function(z, width) {
    vapply(z, function(s) {
      if (is.na(s) || !nzchar(s)) return("")
      paste(strwrap(s, width = width), collapse = "\n")
    }, character(1))
  }

  df[[1]] <- wrap_text(df[[1]], 58)
  if (ncol(df) > 1L) {
    for (j in 2:ncol(df)) df[[j]] <- wrap_text(df[[j]], 27)
  }
  names(df) <- vapply(names(df), function(s) {
    paste(strwrap(s, width = 22), collapse = "\n")
  }, character(1))

  data_index <- cumsum(row_type != "section")
  row_fill <- ifelse(
    row_type == "section",
    "#F2D7D9",
    ifelse(data_index %% 2L == 1L, "#FFFFFF", "#F7E7E8")
  )

  paper_theme <- ttheme_minimal(
    base_size = font_size,
    padding = unit(c(5, 7), "pt"),
    core = list(
      fg_params = list(col = "#111111", hjust = 0, x = 0.02),
      bg_params = list(fill = row_fill, col = NA)
    ),
    colhead = list(
      fg_params = list(col = "#111111", fontface = "bold", hjust = 0.5, x = 0.5),
      bg_params = list(fill = "#F2D7D9", col = NA)
    )
  )

  tg <- tableGrob(df, rows = NULL, theme = paper_theme)

  core_idx <- which(tg$layout$name == "core-fg")
  for (idx in core_idx) {
    r <- tg$layout$t[idx] - 1L
    c <- tg$layout$l[idx]
    if (r >= 1L && r <= nrow(df)) {
      tg$grobs[[idx]]$gp$font <- NULL
      tg$grobs[[idx]]$gp$fontface <- if (row_type[r] == "section") "bold" else "plain"
      if (c == 1L) {
        tg$grobs[[idx]]$x <- unit(0.02, "npc")
        tg$grobs[[idx]]$hjust <- 0
      } else {
        tg$grobs[[idx]]$x <- unit(0.5, "npc")
        tg$grobs[[idx]]$hjust <- 0.5
      }
    }
  }

  head_idx <- which(tg$layout$name == "colhead-fg")
  for (idx in head_idx) {
    c <- tg$layout$l[idx]
    if (c == 1L) {
      tg$grobs[[idx]]$x <- unit(0.02, "npc")
      tg$grobs[[idx]]$hjust <- 0
    }
  }

  if (is.null(col_widths)) {
    col_widths <- c(3.2, rep(1.3, ncol(df) - 1L))
  }
  stopifnot(length(col_widths) == ncol(df))
  tg$widths <- unit(col_widths, "null")

  line_count <- apply(df, 1, function(z) max(lengths(regmatches(z, gregexpr("\n", z, fixed = TRUE))) + 1L))
  header_lines <- max(lengths(regmatches(names(df), gregexpr("\n", names(df), fixed = TRUE))) + 1L)
  tg$heights <- unit(c(max(2.4, header_lines * 1.15), pmax(1.3, line_count * 1.08)), "null")

  top_line <- segmentsGrob(
    x0 = unit(0, "npc"), x1 = unit(1, "npc"),
    y0 = unit(1, "npc"), y1 = unit(1, "npc"),
    gp = gpar(col = "#7A5558", lwd = 1.1)
  )
  bottom_line <- segmentsGrob(
    x0 = unit(0, "npc"), x1 = unit(1, "npc"),
    y0 = unit(0, "npc"), y1 = unit(0, "npc"),
    gp = gpar(col = "#7A5558", lwd = 1.1)
  )
  tg <- gtable::gtable_add_grob(tg, top_line, t = 1, l = 1, r = ncol(df), z = Inf)
  tg <- gtable::gtable_add_grob(tg, bottom_line, t = nrow(df) + 1L, l = 1, r = ncol(df), z = Inf)

  note_grob <- textGrob(
    note, x = 0, hjust = 0,
    gp = gpar(fontsize = max(9, font_size - 2), col = "#333333")
  )
  caption_grob <- textGrob(
    caption, x = 0, hjust = 0,
    gp = gpar(fontsize = font_size + 1, fontface = "bold.italic", col = "#111111")
  )
  rule_grob <- segmentsGrob(
    x0 = unit(0, "npc"), x1 = unit(1, "npc"),
    y0 = unit(0.5, "npc"), y1 = unit(0.5, "npc"),
    gp = gpar(col = "#7A5558", lwd = 1)
  )

  full <- arrangeGrob(
    tg, note_grob, rule_grob, caption_grob,
    ncol = 1, heights = c(0.88, 0.055, 0.012, 0.053),
    padding = unit(4, "pt")
  )

  ragg::agg_png(filename, width = width, height = height, units = "px", res = 180,
                background = "#F2D7D9")
  grid.newpage()
  grid.draw(full)
  dev.off()
  invisible(filename)
}

save_plot_png <- function(plot, filename, width = 13.33, height = 7.5, dpi = 220) {
  ggsave(
    filename, plot = plot, width = width, height = height,
    units = "in", dpi = dpi, bg = "white", device = ragg::agg_png
  )
  invisible(filename)
}

save_grid_png <- function(grob, filename, width = 2400, height = 1500, res = 180) {
  ragg::agg_png(filename, width = width, height = height, units = "px", res = res)
  grid.newpage()
  grid.draw(grob)
  dev.off()
  invisible(filename)
}

write_sheet <- function(wb, sheet, df, title, footer) {
  df <- as.data.frame(df, check.names = FALSE)
  df[] <- lapply(df, as.character)

  n_cols <- ncol(df)
  n_rows <- nrow(df)
  header_row <- 2L
  first_data_row <- 3L
  last_data_row <- first_data_row + n_rows - 1L
  footer_row <- last_data_row + 1L

  addWorksheet(wb, sheet, gridLines = TRUE)

  writeData(
    wb, sheet, title,
    startRow = 1L, startCol = 1L,
    colNames = FALSE, rowNames = FALSE
  )
  mergeCells(wb, sheet, cols = seq_len(n_cols), rows = 1L)

  writeData(
    wb, sheet, t(names(df)),
    startRow = header_row, startCol = 1L,
    colNames = FALSE, rowNames = FALSE
  )

  writeData(
    wb, sheet, df,
    startRow = first_data_row, startCol = 1L,
    colNames = FALSE, rowNames = FALSE,
    keepNA = FALSE
  )

  writeData(
    wb, sheet, footer,
    startRow = footer_row, startCol = 1L,
    colNames = FALSE, rowNames = FALSE
  )
  mergeCells(wb, sheet, cols = seq_len(n_cols), rows = footer_row)

  title_style <- createStyle(wrapText = TRUE)

  header_style <- createStyle(
    fontName = "DejaVu Sans",
    fontSize = 9,
    fontColour = "#000000",
    border = c("top", "bottom"),
    borderStyle = "thick",
    borderColour = "#666666",
    halign = "center",
    valign = "top",
    wrapText = TRUE
  )

  body_style <- createStyle(
    fontName = "DejaVu Sans",
    fontSize = 9,
    fontColour = "#000000",
    halign = "left",
    valign = "top",
    wrapText = TRUE
  )

  last_row_style <- createStyle(
    fontName = "DejaVu Sans",
    fontSize = 9,
    fontColour = "#000000",
    border = "bottom",
    borderStyle = "thick",
    borderColour = "#666666",
    halign = "left",
    valign = "top",
    wrapText = TRUE
  )

  footer_style <- createStyle(
    fontName = "DejaVu Sans",
    fontSize = 9,
    fontColour = "#000000",
    halign = "left",
    valign = "top",
    wrapText = TRUE
  )

  addStyle(
    wb, sheet, title_style,
    rows = 1L, cols = seq_len(n_cols),
    gridExpand = TRUE, stack = TRUE
  )
  addStyle(
    wb, sheet, header_style,
    rows = header_row, cols = seq_len(n_cols),
    gridExpand = TRUE, stack = TRUE
  )
  if (n_rows > 1L) {
    addStyle(
      wb, sheet, body_style,
      rows = first_data_row:(last_data_row - 1L),
      cols = seq_len(n_cols),
      gridExpand = TRUE, stack = TRUE
    )
  }
  addStyle(
    wb, sheet, last_row_style,
    rows = last_data_row, cols = seq_len(n_cols),
    gridExpand = TRUE, stack = TRUE
  )
  addStyle(
    wb, sheet, footer_style,
    rows = footer_row, cols = seq_len(n_cols),
    gridExpand = TRUE, stack = TRUE
  )
}
