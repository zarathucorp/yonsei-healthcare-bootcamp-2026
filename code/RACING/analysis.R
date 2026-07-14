## RACING synthetic analysis: analysis.R
## Tables are saved only to Excel. Figures are saved only to PPT.

analysis_file <- tryCatch(normalizePath(sys.frame(1)$ofile, winslash = "/", mustWork = TRUE), error = function(e) NA_character_)
if (is.na(analysis_file)) {
  cmd_file <- grep("^--file=", commandArgs(FALSE), value = TRUE)
  if (length(cmd_file) > 0) analysis_file <- normalizePath(sub("^--file=", "", cmd_file[1]), winslash = "/", mustWork = TRUE)
}
if (is.na(analysis_file)) analysis_file <- normalizePath("code/RACING/analysis.R", winslash = "/", mustWork = TRUE)
source(file.path(dirname(analysis_file), "global.R"))

library(survival);library(ggplot2);library(flextable);library(officer);library(rvg)
library(grid);library(scales);library(patchwork)

ft_list <- list()
plot_list <- list()

fmt_p <- function(p) ifelse(is.na(p), "", ifelse(p < 0.001, "<0.001", sprintf("%.3f", p)))
fmt_n_pct <- function(n, d, digits = 1) ifelse(is.na(n) | is.na(d) | d == 0, "", sprintf(paste0("%d (%.", digits, "f%%)"), as.integer(n), 100 * n / d))
fmt_mean_sd <- function(x) sprintf("%.1f (%.1f)", mean(x, na.rm = TRUE), sd(x, na.rm = TRUE))
fmt_median_iqr <- function(x) sprintf("%.1f (%.1f–%.1f)", median(x, na.rm = TRUE), quantile(x, 0.25, na.rm = TRUE), quantile(x, 0.75, na.rm = TRUE))
fmt_diff <- function(x, digits = 2) sprintf(paste0("%.", digits, "f (%." , digits, "f to %." , digits, "f)"), unname(x["estimate"]), unname(x["lower"]), unname(x["upper"]))

risk_difference <- function(events, totals, conf.level = 0.95) {
  fit <- suppressWarnings(prop.test(events, totals, conf.level = conf.level, correct = FALSE))
  c(estimate = events[1] / totals[1] - events[2] / totals[2], lower = fit$conf.int[1], upper = fit$conf.int[2], p = fit$p.value)
}

binary_p <- function(x, g) {
  ok <- !is.na(x) & !is.na(g)
  tb <- table(x[ok], g[ok])
  if (nrow(tb) < 2 || ncol(tb) < 2) return(NA_real_)
  expected <- suppressWarnings(chisq.test(tb, correct = FALSE)$expected)
  if (any(expected < 5)) fisher.test(tb)$p.value else suppressWarnings(chisq.test(tb, correct = FALSE)$p.value)
}

event_summary <- function(dd, event_var) {
  z <- copy(dd[!is.na(get(event_var))])
  z[, .event := as.integer(as.character(get(event_var)))]
  z[, .(N = .N, Events = sum(.event == 1L, na.rm = TRUE)), by = group][order(group)]
}

make_ft <- function(df, caption, footer, row_type, merge_cols = character()) {
  ft <- flextable(as.data.frame(df, check.names = FALSE)) %>%
    set_caption(caption) %>%
    add_footer_lines(footer) %>%
    align(align = "left", part = "all") %>%
    valign(valign = "top", part = "all") %>%
    fontsize(size = 9, part = "all") %>%
    autofit()
  for (mc in intersect(merge_cols, names(df))) {
    ft <- ft %>% merge_v(j = mc) %>% valign(j = mc, valign = "top") %>% align(j = mc, align = "left")
  }
  section_rows <- which(row_type == "section")
  if (length(section_rows) > 0) ft <- ft %>% bold(i = section_rows, bold = TRUE, part = "body") %>% bg(i = section_rows, bg = "#F3DADC", part = "body")
  ft
}

write_table_sheet <- function(wb, sheet, df, title, footer, row_type, widths, merge_cols = character()) {
  dd <- as.data.frame(df, check.names = FALSE)
  dd[] <- lapply(dd, as.character)
  addWorksheet(wb, sheet, gridLines = FALSE, zoom = 90)
  n_cols <- ncol(dd); n_rows <- nrow(dd)
  header_row <- 3L; first_row <- 4L; last_row <- first_row + n_rows - 1L; footer_row <- last_row + 2L
  writeData(wb, sheet, title, startRow = 1, startCol = 1, colNames = FALSE)
  mergeCells(wb, sheet, cols = seq_len(n_cols), rows = 1)
  writeData(wb, sheet, t(names(dd)), startRow = header_row, startCol = 1, colNames = FALSE)
  writeData(wb, sheet, dd, startRow = first_row, startCol = 1, colNames = FALSE, keepNA = FALSE)
  writeData(wb, sheet, footer, startRow = footer_row, startCol = 1, colNames = FALSE)
  mergeCells(wb, sheet, cols = seq_len(n_cols), rows = footer_row)
  setColWidths(wb, sheet, cols = seq_len(n_cols), widths = widths)
  title_style <- createStyle(fontName = "DejaVu Sans", fontSize = 12, textDecoration = "bold", halign = "left")
  header_style <- createStyle(fontName = "DejaVu Sans", fontSize = 9, textDecoration = "bold", fgFill = "#F3DADC", border = c("top", "bottom"), borderStyle = "thick", borderColour = "#666666", halign = "center", valign = "center", wrapText = TRUE)
  left_style <- createStyle(fontName = "DejaVu Sans", fontSize = 9, halign = "left", valign = "top", wrapText = TRUE)
  center_style <- createStyle(fontName = "DejaVu Sans", fontSize = 9, halign = "center", valign = "top", wrapText = TRUE)
  section_style <- createStyle(fontName = "DejaVu Sans", fontSize = 9, textDecoration = "bold", fgFill = "#F3DADC", halign = "left", valign = "top", wrapText = TRUE)
  footer_style <- createStyle(fontName = "DejaVu Sans", fontSize = 8, fontColour = "#333333", halign = "left", valign = "top", wrapText = TRUE)
  addStyle(wb, sheet, title_style, rows = 1, cols = seq_len(n_cols), gridExpand = TRUE, stack = TRUE)
  addStyle(wb, sheet, header_style, rows = header_row, cols = seq_len(n_cols), gridExpand = TRUE, stack = TRUE)
  addStyle(wb, sheet, left_style, rows = first_row:last_row, cols = 1, gridExpand = TRUE, stack = TRUE)
  if (n_cols > 1) addStyle(wb, sheet, center_style, rows = first_row:last_row, cols = 2:n_cols, gridExpand = TRUE, stack = TRUE)
  section_rows <- (first_row:last_row)[row_type == "section"]
  if (length(section_rows) > 0) addStyle(wb, sheet, section_style, rows = section_rows, cols = seq_len(n_cols), gridExpand = TRUE, stack = TRUE)
  addStyle(wb, sheet, createStyle(border = "bottom", borderStyle = "thick", borderColour = "#666666"), rows = last_row, cols = seq_len(n_cols), gridExpand = TRUE, stack = TRUE)
  addStyle(wb, sheet, footer_style, rows = footer_row, cols = seq_len(n_cols), gridExpand = TRUE, stack = TRUE)
  setRowHeights(wb, sheet, rows = 1, heights = 24)
  setRowHeights(wb, sheet, rows = header_row, heights = 44)
  setRowHeights(wb, sheet, rows = first_row:last_row, heights = ifelse(row_type == "section", 24, 22))
  setRowHeights(wb, sheet, rows = footer_row, heights = 58)
  freezePane(wb, sheet, firstActiveRow = first_row, firstActiveCol = 2)
  addFilter(wb, sheet, rows = header_row, cols = seq_len(n_cols))
  for (mc in intersect(merge_cols, names(dd))) {
    j <- match(mc, names(dd))
    rr <- rle(dd[[j]])
    ends <- cumsum(rr$lengths)
    starts <- ends - rr$lengths + 1L
    for (i in seq_along(rr$lengths)) {
      if (rr$lengths[i] > 1 && rr$values[i] != "") mergeCells(wb, sheet, cols = j, rows = (first_row + starts[i] - 1L):(first_row + ends[i] - 1L))
    }
  }
}

col_combo <- paste0(group_labels[["Combination"]], "\n(n=", out[group == "Combination", .N], ")")
col_mono <- paste0(group_labels[["Monotherapy"]], "\n(n=", out[group == "Monotherapy", .N], ")")

## Table 1
rows <- list()
add_t1 <- function(label, combo = "", mono = "", type = "data") rows[[length(rows) + 1L]] <<- data.table(Characteristic = label, Combination = combo, Monotherapy = mono, row_type = type)
for (v in c("Age", "Height", "Weight", "BMI")) add_t1(label_map[[v]], fmt_mean_sd(out[group == "Combination", get(v)]), fmt_mean_sd(out[group == "Monotherapy", get(v)]))
add_t1("Female sex", fmt_n_pct(out[group == "Combination" & Sex == "Female", .N], out[group == "Combination", .N], 0), fmt_n_pct(out[group == "Monotherapy" & Sex == "Female", .N], out[group == "Monotherapy", .N], 0))
add_t1("Male sex", fmt_n_pct(out[group == "Combination" & Sex == "Male", .N], out[group == "Combination", .N], 0), fmt_n_pct(out[group == "Monotherapy" & Sex == "Male", .N], out[group == "Monotherapy", .N], 0))
for (v in c("Prior_MI", "Prior_PCI", "Prior_CABG", "ACS", "Prior_stroke", "CKD", "ESRD_dialysis", "PAD", "Hypertension", "Diabetes", "Diabetes_insulin", "Smoking")) {
  add_t1(label_map[[v]], fmt_n_pct(out[group == "Combination" & as.character(get(v)) == "1", .N], out[group == "Combination", .N], 0), fmt_n_pct(out[group == "Monotherapy" & as.character(get(v)) == "1", .N], out[group == "Monotherapy", .N], 0))
}
add_t1("Medication for dyslipidaemia before randomisation", type = "section")
for (v in c("Pre_HI_statin", "Pre_HI_statin_ezetimibe", "Pre_MI_statin", "Pre_MI_statin_ezetimibe", "Pre_LI_statin", "Pre_none")) {
  add_t1(paste0("   ", label_map[[v]]), fmt_n_pct(out[group == "Combination" & as.character(get(v)) == "1", .N], out[group == "Combination", .N], 0), fmt_n_pct(out[group == "Monotherapy" & as.character(get(v)) == "1", .N], out[group == "Monotherapy", .N], 0))
}
add_t1(label_map[["Baseline_LDL"]], fmt_median_iqr(out[group == "Combination", Baseline_LDL]), fmt_median_iqr(out[group == "Monotherapy", Baseline_LDL]))
add_t1("Number of patients with LDL cholesterol concentrations <70 mg/dL", fmt_n_pct(out[group == "Combination" & Baseline_LDL < 70, .N], out[group == "Combination", .N], 0), fmt_n_pct(out[group == "Monotherapy" & Baseline_LDL < 70, .N], out[group == "Monotherapy", .N], 0))
table1_full <- rbindlist(rows); table1_type <- table1_full$row_type; table1 <- table1_full[, !"row_type"]
setnames(table1, c("Combination", "Monotherapy"), c(col_combo, col_mono))

## Cox model and Table 2
primary_dd <- copy(out[!is.na(admend_mo) & !is.na(primary_event)])
primary_dd[, .event := as.integer(as.character(primary_event))]
primary_dd[, .time := fifelse(.event == 1L, primary_time_mo, admend_mo)]
primary_dd[, trt_combo := as.integer(group == "Combination")]
fmla <- as.formula("Surv(.time, .event) ~ trt_combo")
primary_cox <- eval(substitute(coxph(f, data = primary_dd), list(f = fmla)))
primary_ph <- cox.zph(primary_cox, transform = "identity")
primary_ph_dt <- data.table(Term = rownames(primary_ph$table), Chisq = primary_ph$table[, "chisq"], df = primary_ph$table[, "df"], `P value` = primary_ph$table[, "p"])
hr_ci <- suppressWarnings(confint(primary_cox))
primary_hr <- sprintf("%.2f (%.2f to %.2f)", exp(coef(primary_cox)[["trt_combo"]]), exp(hr_ci["trt_combo", 1]), exp(hr_ci["trt_combo", 2]))
primary_p <- summary(primary_cox)$coefficients["trt_combo", "Pr(>|z|)"]

rows <- list()
add_t2_section <- function(label) rows[[length(rows) + 1L]] <<- data.table(Outcome = label, Combination = "", Monotherapy = "", Difference = "", HR = "", P = "", row_type = "section")
add_t2_event <- function(v, label, primary = FALSE) {
  sm <- event_summary(out, v)
  rd <- risk_difference(sm$Events, sm$N, conf.level = if (primary) 0.90 else 0.95)
  rows[[length(rows) + 1L]] <<- data.table(
    Outcome = label,
    Combination = fmt_n_pct(sm[group == "Combination", Events], sm[group == "Combination", N], 1),
    Monotherapy = fmt_n_pct(sm[group == "Monotherapy", Events], sm[group == "Monotherapy", N], 1),
    Difference = fmt_diff(100 * rd, 2),
    HR = if (primary) primary_hr else "—",
    P = fmt_p(if (primary) primary_p else binary_p(out[[v]], out$group)),
    row_type = "data"
  )
}
add_t2_section("Primary endpoint")
add_t2_event("primary_event", clinical_labels[["primary_event"]], TRUE)
add_t2_section("Secondary efficacy endpoint")
add_t2_event("secondary_event", clinical_labels[["secondary_event"]])
add_t2_section("Individual clinical endpoint")
for (v in setdiff(varlist$Clinical, c("primary_event", "secondary_event"))) add_t2_event(v, clinical_labels[[v]])
table2_full <- rbindlist(rows); table2_type <- table2_full$row_type; table2 <- table2_full[, !"row_type"]
setnames(table2, c("Combination", "Monotherapy", "Difference", "HR", "P"), c(col_combo, col_mono, "Absolute difference, %p (CI)", "Hazard ratio (95% CI)", "P value"))

## Table 3
rows <- list()
add_t3 <- function(timepoint, outcome, combo = "", mono = "", diff = "", type = "data") rows[[length(rows) + 1L]] <<- data.table(Timepoint = timepoint, Outcome = outcome, Combination = combo, Monotherapy = mono, Difference = diff, row_type = type)
for (yr in 1:3) {
  tp <- paste0(yr, ifelse(yr == 1, " year", " years"))
  ldl <- paste0("LDL_y", yr); ldl70 <- paste0("LDL70_y", yr)
  obs <- out[!is.na(get(ldl)), .(N = .N), by = group][order(group)]
  add_t3(tp, "Number of patients", format(obs[group == "Combination", N], big.mark = ","), format(obs[group == "Monotherapy", N], big.mark = ","), "—", "section")
  sm <- out[!is.na(get(ldl)), .(N = .N, Events = sum(as.integer(as.character(get(ldl70))) == 1L, na.rm = TRUE)), by = group][order(group)]
  rd <- risk_difference(sm$Events, sm$N, 0.95)
  add_t3(tp, "Number of patients with LDL cholesterol concentrations <70 mg/dL", fmt_n_pct(sm[group == "Combination", Events], sm[group == "Combination", N], 1), fmt_n_pct(sm[group == "Monotherapy", Events], sm[group == "Monotherapy", N], 1), fmt_diff(100 * rd, 1))
  med <- out[!is.na(get(ldl)), .(med = median(get(ldl)), q1 = quantile(get(ldl), 0.25), q3 = quantile(get(ldl), 0.75)), by = group][order(group)]
  add_t3(tp, "LDL cholesterol concentration, mg/dL", sprintf("%.1f (%.1f–%.1f)", med[group == "Combination", med], med[group == "Combination", q1], med[group == "Combination", q3]), sprintf("%.1f (%.1f–%.1f)", med[group == "Monotherapy", med], med[group == "Monotherapy", q1], med[group == "Monotherapy", q3]), "—")
}
table3_full <- rbindlist(rows); table3_type <- table3_full$row_type; table3 <- table3_full[, !"row_type"]
setnames(table3, c("Combination", "Monotherapy", "Difference"), c(col_combo, col_mono, "Absolute difference, %p (95% CI)"))

## Table 4
rows <- list()
add_t4_section <- function(label) rows[[length(rows) + 1L]] <<- data.table(Endpoint = label, Combination = "", Monotherapy = "", Difference = "", row_type = "section")
add_t4_event <- function(v, label) {
  sm <- event_summary(out, v)
  rd <- risk_difference(sm$Events, sm$N, 0.95)
  rows[[length(rows) + 1L]] <<- data.table(Endpoint = label, Combination = fmt_n_pct(sm[group == "Combination", Events], sm[group == "Combination", N], 1), Monotherapy = fmt_n_pct(sm[group == "Monotherapy", Events], sm[group == "Monotherapy", N], 1), Difference = fmt_diff(100 * rd, 2), row_type = "data")
}
add_t4_section("Serious adverse events")
add_t4_event("allcause_death_event", "Death")
add_t4_section("Adverse events")
add_t4_event("intolerance_stop_reduce", "Discontinuation or dose reduction of study drug due to intolerance")
for (v in setdiff(varlist$Safety, "intolerance_stop_reduce")) add_t4_event(v, safety_labels[[v]])
table4_full <- rbindlist(rows); table4_type <- table4_full$row_type; table4 <- table4_full[, !"row_type"]
setnames(table4, c("Combination", "Monotherapy", "Difference"), c(col_combo, col_mono, "Absolute difference, %p (95% CI)"))

## Excel tables
footer1 <- paste("Data are mean (SD), median (IQR), or n (%). Baseline characteristics are descriptive; no between-group tests were added.", synthetic_note)
footer2 <- paste("Data are number of events (%). Absolute differences are combination minus monotherapy. The primary endpoint difference uses a 90% CI; other differences use 95% CIs from score tests without continuity correction. The primary HR is from Cox regression; event-specific HRs are not estimated because only primary event time is available.", synthetic_note)
footer3 <- paste("Data are observed N, n (%), or median (IQR). Difference CIs are 95% CIs from score tests without continuity correction. Missing LDL-C values were not imputed.", synthetic_note)
footer4 <- paste("Data are n (%) among randomised participants. Difference CIs are 95% CIs from score tests without continuity correction. The safety population variable is unavailable; the intolerance-discontinuation row is derived from intolerance-related safety endpoints in the synthetic data.", synthetic_note)

ft_list[["Table 1"]] <- make_ft(table1, "Table 1. Baseline characteristics", footer1, table1_type)
ft_list[["Table 2"]] <- make_ft(table2, "Table 2. Three-year clinical endpoints", footer2, table2_type)
ft_list[["Table 3"]] <- make_ft(table3, "Table 3. LDL cholesterol outcomes", footer3, table3_type, merge_cols = "Timepoint")
ft_list[["Table 4"]] <- make_ft(table4, "Table 4. Safety endpoints", footer4, table4_type)

wb <- createWorkbook()
write_table_sheet(wb, "Table 1", table1, "Table 1. Baseline characteristics", footer1, table1_type, c(54, 36, 36))
write_table_sheet(wb, "Table 2", table2, "Table 2. Three-year clinical endpoints", footer2, table2_type, c(66, 28, 28, 32, 26, 13))
write_table_sheet(wb, "Table 3", table3, "Table 3. LDL cholesterol outcomes", footer3, table3_type, c(16, 60, 28, 28, 36), merge_cols = "Timepoint")
write_table_sheet(wb, "Table 4", table4, "Table 4. Safety endpoints", footer4, table4_type, c(64, 28, 28, 36))
write_table_sheet(wb, "PH check", primary_ph_dt, "Proportional hazards assumption check", "P values are from cox.zph(fit, transform = \"identity\") for the primary Cox model.", rep("data", nrow(primary_ph_dt)), c(24, 16, 10, 14))
saveWorkbook(wb, file.path(results_dir, "RACING_Tables.xlsx"), overwrite = TRUE)

## Figure 1
flow <- out[, .(
  N = .N,
  Intolerance = sum(as.integer(as.character(intolerance_stop_reduce)) == 1L, na.rm = TRUE),
  Deaths = sum(as.integer(as.character(allcause_death_event)) == 1L, na.rm = TRUE),
  EarlyCensor = sum(as.integer(as.character(primary_event)) == 0L & admend_mo < 36, na.rm = TRUE),
  PrimaryEvents = sum(as.integer(as.character(primary_event)) == 1L, na.rm = TRUE)
), by = group][order(group)]
flow[, NoIntolerance := N - Intolerance]
box_dt <- data.table(
  xmin = c(3.05, 0.35, 6.55, 0.35, 6.55, 0.35, 6.55),
  xmax = c(6.95, 3.75, 9.75, 3.75, 9.75, 3.75, 9.75),
  ymin = c(6.75, 5.15, 5.15, 3.55, 3.55, 1.75, 1.75),
  ymax = c(7.22, 6.2, 6.2, 4.55, 4.55, 2.7, 2.7),
  label = c(
    "3780 patients underwent random assignment",
    paste0(flow[group == "Combination", N], " assigned to receive\nmoderate-intensity statin with\nezetimibe combination therapy"),
    paste0(flow[group == "Monotherapy", N], " assigned to receive\nhigh-intensity statin monotherapy"),
    paste0(flow[group == "Combination", Intolerance], " discontinued or reduced study drug\nowing to intolerance-related safety endpoints\n", flow[group == "Combination", NoIntolerance], " without this event"),
    paste0(flow[group == "Monotherapy", Intolerance], " discontinued or reduced study drug\nowing to intolerance-related safety endpoints\n", flow[group == "Monotherapy", NoIntolerance], " without this event"),
    paste0(flow[group == "Combination", N], " included in intention-to-treat analysis\n", flow[group == "Combination", PrimaryEvents], " primary endpoint events; ", flow[group == "Combination", Deaths], " deaths\n", flow[group == "Combination", EarlyCensor], " censored before 3 years, reason unavailable"),
    paste0(flow[group == "Monotherapy", N], " included in intention-to-treat analysis\n", flow[group == "Monotherapy", PrimaryEvents], " primary endpoint events; ", flow[group == "Monotherapy", Deaths], " deaths\n", flow[group == "Monotherapy", EarlyCensor], " censored before 3 years, reason unavailable")
  )
)
figure1 <- ggplot() +
  geom_rect(data = box_dt, aes(xmin = xmin, xmax = xmax, ymin = ymin, ymax = ymax), fill = "white", colour = "black", linewidth = 0.65) +
  geom_text(data = box_dt, aes(x = (xmin + xmax) / 2, y = (ymin + ymax) / 2, label = label), size = 3.08, lineheight = 1.02) +
  geom_segment(aes(x = 5, y = 6.75, xend = 5, yend = 6.43), linewidth = 0.55) +
  geom_segment(aes(x = 2.05, y = 6.43, xend = 8.15, yend = 6.43), linewidth = 0.55) +
  geom_segment(aes(x = 2.05, y = 6.43, xend = 2.05, yend = 6.2), arrow = arrow(length = unit(0.1, "inches"), type = "closed"), linewidth = 0.55) +
  geom_segment(aes(x = 8.15, y = 6.43, xend = 8.15, yend = 6.2), arrow = arrow(length = unit(0.1, "inches"), type = "closed"), linewidth = 0.55) +
  geom_segment(aes(x = 2.05, y = 5.15, xend = 2.05, yend = 2.7), arrow = arrow(length = unit(0.1, "inches"), type = "closed"), linewidth = 0.55) +
  geom_segment(aes(x = 8.15, y = 5.15, xend = 8.15, yend = 2.7), arrow = arrow(length = unit(0.1, "inches"), type = "closed"), linewidth = 0.55) +
  annotate("text", x = 0.2, y = 0.55, label = paste("Figure 1: Trial profile. Intolerance row is derived from intolerance-related safety endpoints; explicit lost-to-follow-up and withdrawal reasons are not available.", synthetic_note), hjust = 0, fontface = "bold", size = 3.0) +
  coord_cartesian(xlim = c(0, 10), ylim = c(0, 7.45), expand = FALSE, clip = "off") + theme_void() + theme(plot.margin = margin(8, 10, 8, 10))
plot_list[["Figure 1"]] <- figure1

## Figure 2
km_dd <- copy(primary_dd)
km_dd[, time_year := pmin(.time / 12, 3)]
fit_fmla <- as.formula("Surv(time_year, .event) ~ group")
fit <- eval(substitute(survfit(f, data = km_dd), list(f = fit_fmla)))
km_s <- summary(fit)
km_dt <- data.table(time = km_s$time, incidence = 1 - km_s$surv, strata = sub("^group=", "", km_s$strata))
km_dt <- rbind(data.table(time = 0, incidence = 0, strata = c("Combination", "Monotherapy")), km_dt, fill = TRUE)
km_dt[, strata := factor(strata, levels = c("Monotherapy", "Combination"), labels = c(group_labels[["Monotherapy"]], group_labels[["Combination"]]))]
logrank <- survdiff(Surv(time_year, .event) ~ group, data = km_dd)
logrank_p <- pchisq(logrank$chisq, length(logrank$n) - 1, lower.tail = FALSE)
rs <- summary(fit, times = c(0, 1, 2, 3), extend = TRUE)
risk_dt <- data.table(time = rs$time, n.risk = rs$n.risk, strata = sub("^group=", "", rs$strata))
risk_dt[, strata := factor(strata, levels = c("Monotherapy", "Combination"), labels = c("Monotherapy", "Combination therapy"))]
risk_dt[, y := fifelse(strata == "Monotherapy", 1, 2)]
rd_primary <- risk_difference(event_summary(out, "primary_event")$Events, event_summary(out, "primary_event")$N, 0.90)
ymax <- max(0.12, ceiling(max(km_dt$incidence, na.rm = TRUE) * 100 / 5) * 0.05)
km_plot <- ggplot(km_dt, aes(time, incidence, colour = strata)) +
  geom_step(linewidth = 0.9) +
  scale_colour_manual(values = setNames(c("#0099B5", "#A50034"), c(group_labels[["Monotherapy"]], group_labels[["Combination"]])), name = NULL) +
  scale_x_continuous(breaks = c(0, 1, 2, 3), limits = c(0, 3), expand = expansion(mult = c(0.02, 0.02))) +
  scale_y_continuous(labels = percent_format(accuracy = 1), limits = c(0, ymax), expand = c(0, 0)) +
  annotate("text", x = 1.55, y = ymax * 0.74, label = sprintf("Absolute difference %.2f%% (90%% CI %.2f to %.2f)", 100 * rd_primary["estimate"], 100 * rd_primary["lower"], 100 * rd_primary["upper"]), size = 3.45) +
  annotate("text", x = 1.55, y = ymax * 0.62, label = paste0("Log-rank P = ", fmt_p(logrank_p)), size = 3.25) +
  labs(x = NULL, y = "Cumulative incidence (%)") + theme_classic(base_size = 12) +
  theme(legend.position = c(0.47, 0.94), legend.justification = c(0, 1), legend.text = element_text(size = 9.2), legend.background = element_rect(fill = "white", colour = NA), plot.margin = margin(8, 15, 0, 15))
risk_plot <- ggplot(risk_dt, aes(time, y)) +
  geom_text(aes(label = n.risk), size = 3.8) +
  annotate("text", x = -0.18, y = 2.55, label = "Number at risk", hjust = 0, fontface = "bold", size = 3.4) +
  scale_x_continuous(breaks = c(0, 1, 2, 3), labels = c(0, 1, 2, 3), limits = c(-0.2, 3), expand = c(0, 0)) +
  scale_y_continuous(breaks = c(1, 2), labels = c("Monotherapy", "Combination therapy"), limits = c(0.5, 2.75), expand = c(0, 0)) +
  labs(x = "Time since randomisation (years)", y = NULL) + theme_void(base_size = 11) +
  theme(axis.text.x = element_text(size = 9), axis.title.x = element_text(size = 10), plot.margin = margin(0, 15, 6, 15))
figure2 <- km_plot / risk_plot + plot_layout(heights = c(4.35, 1.2)) + plot_annotation(caption = paste("Figure 2: Kaplan-Meier curves of the primary endpoint of the intention-to-treat population.", synthetic_note), theme = theme(plot.caption = element_text(hjust = 0, face = "bold", size = 9.7)))
plot_list[["Figure 2"]] <- figure2

## Figure 3
subgroup_summary <- function(dd) {
  z <- copy(dd[!is.na(primary_event)])
  z[, .event := as.integer(as.character(primary_event))]
  sm <- z[, .(N = .N, Events = sum(.event == 1L, na.rm = TRUE)), by = group][order(group)]
  if (nrow(sm) < 2 || any(sm$N == 0)) return(c(ce = NA_real_, cn = NA_real_, me = NA_real_, mn = NA_real_, est = NA_real_, lo = NA_real_, hi = NA_real_))
  rd <- risk_difference(sm$Events, sm$N, 0.90)
  c(ce = sm[group == "Combination", Events], cn = sm[group == "Combination", N], me = sm[group == "Monotherapy", Events], mn = sm[group == "Monotherapy", N], est = unname(100 * rd["estimate"]), lo = unname(100 * rd["lower"]), hi = unname(100 * rd["upper"]))
}
frows <- list()
overall <- subgroup_summary(out)
frows[[1]] <- data.table(Subgroup = "All patients", Combination = sprintf("%d/%d (%.1f)", overall["ce"], overall["cn"], 100 * overall["ce"] / overall["cn"]), Monotherapy = sprintf("%d/%d (%.1f)", overall["me"], overall["mn"], 100 * overall["me"] / overall["mn"]), est = overall["est"], lo = overall["lo"], hi = overall["hi"], header = FALSE, overall = TRUE)
for (v in varlist$Subgroup) {
  frows[[length(frows) + 1L]] <- data.table(Subgroup = subgroup_labels[[v]], Combination = "", Monotherapy = "", est = NA_real_, lo = NA_real_, hi = NA_real_, header = TRUE, overall = FALSE)
  for (lv in levels(droplevels(out[[v]]))) {
    s <- subgroup_summary(out[as.character(get(v)) == lv])
    frows[[length(frows) + 1L]] <- data.table(Subgroup = paste0("   ", lv), Combination = sprintf("%d/%d (%.1f)", s["ce"], s["cn"], 100 * s["ce"] / s["cn"]), Monotherapy = sprintf("%d/%d (%.1f)", s["me"], s["mn"], 100 * s["me"] / s["mn"]), est = s["est"], lo = s["lo"], hi = s["hi"], header = FALSE, overall = FALSE)
  }
}
forest_dt <- rbindlist(frows, fill = TRUE)
forest_dt[, y := .N:1]
forest_dt[, fontface := ifelse(header | overall, "bold", "plain")]
forest_dt[, ci_text := ifelse(is.na(est), "", sprintf("%.2f (%.2f to %.2f)", est, lo, hi))]
left_plot <- ggplot(forest_dt, aes(y = y)) +
  geom_text(aes(x = 0, label = Subgroup, fontface = fontface), hjust = 0, size = 2.45) +
  geom_text(aes(x = 3.95, label = Combination), size = 2.25) +
  geom_text(aes(x = 5.75, label = Monotherapy), size = 2.25) +
  annotate("text", x = 0, y = max(forest_dt$y) + 1.2, label = "Number/total (%)\n\nSubgroup", hjust = 0, fontface = "bold", size = 2.55) +
  annotate("text", x = 3.95, y = max(forest_dt$y) + 1.2, label = "Combination therapy", fontface = "bold", size = 2.35) +
  annotate("text", x = 5.75, y = max(forest_dt$y) + 1.2, label = "Monotherapy", fontface = "bold", size = 2.35) +
  scale_x_continuous(limits = c(0, 6.6), expand = c(0, 0)) + scale_y_continuous(limits = c(0.2, max(forest_dt$y) + 1.8), expand = c(0, 0)) + theme_void() + theme(plot.margin = margin(4, 0, 8, 4))
right_plot <- ggplot(forest_dt[header == FALSE], aes(est, y)) +
  geom_vline(xintercept = 0, linewidth = 0.45) + geom_vline(xintercept = 2, linetype = "dashed", linewidth = 0.45) +
  geom_errorbar(aes(xmin = lo, xmax = hi), orientation = "y", width = 0, linewidth = 0.45) + geom_point(shape = 15, size = 1.8) +
  geom_text(aes(x = 10.8, label = ci_text), hjust = 1, size = 2.25) +
  annotate("text", x = 10.8, y = max(forest_dt$y) + 1.2, label = "Absolute differences (90% CI)", hjust = 1, fontface = "bold", size = 2.45) +
  annotate("text", x = -10.5, y = 0.65, label = "Favours combination therapy", hjust = 0, size = 2.2) +
  annotate("text", x = 2.3, y = 0.65, label = "Favours monotherapy", hjust = 0, size = 2.2) +
  scale_x_continuous(limits = c(-11, 11), breaks = c(-10, -5, 0, 2, 5, 10)) + scale_y_continuous(limits = c(0.2, max(forest_dt$y) + 1.8), expand = c(0, 0)) + labs(x = NULL, y = NULL) +
  theme_minimal(base_size = 9) + theme(panel.grid.major.y = element_blank(), panel.grid.minor = element_blank(), axis.text.y = element_blank(), plot.margin = margin(4, 8, 8, 0))
figure3 <- left_plot + right_plot + plot_layout(widths = c(1.1, 1.35)) + plot_annotation(caption = paste("Figure 3: Subgroup analyses for the primary endpoint of the intention-to-treat population. The dashed line indicates the 2.0%p non-inferiority margin.", synthetic_note), theme = theme(plot.caption = element_text(hjust = 0, face = "bold", size = 9.5)))
plot_list[["Figure 3"]] <- figure3

## PPT figures only
ppt <- read_pptx()
for (nm in names(plot_list)) {
  ppt <- add_slide(ppt, layout = "Blank", master = "Office Theme")
  ppt <- ph_with(ppt, rvg::dml(ggobj = plot_list[[nm]]), location = ph_location_fullsize())
}
print(ppt, target = file.path(figures_dir, "RACING_Figures.pptx"))

expected <- file.path(code_dir, c("RACING_Tables.xlsx", "RACING_Figures.pptx"))
stopifnot(all(file.exists(expected)))
cat("Generated files\n")
cat(expected, sep = "\n")
cat("\n")
