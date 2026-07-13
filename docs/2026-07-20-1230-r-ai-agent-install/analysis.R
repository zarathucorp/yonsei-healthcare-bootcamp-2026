
source("global.R")

ft_list <- list()
plot_list <- list()

table1_footer <- paste(
  "Data are mean (SD), median (IQR), or n (%).",
  "Baseline characteristics are descriptive and no between-group hypothesis tests were performed.",
  synthetic_note
)
table2_footer <- paste(
  "Data are number of events (%). Absolute differences are combination minus monotherapy.",
  "Difference CIs use the two-sample score method without continuity correction.",
  "The primary endpoint uses the prespecified 90% CI for non-inferiority; other differences use 95% CIs.",
  "The primary HR and 95% CI use a Cox proportional hazards model; other endpoints have no event-time analysis.",
  "P values use the Cox model for the primary endpoint and chi-squared or Fisher exact tests for other endpoints.",
  synthetic_note
)
table3_footer <- paste(
  "Data are observed N, n (%), or median (IQR).",
  "Absolute-difference 95% CIs use the two-sample score method without continuity correction.",
  "Missing LDL-C values are not imputed or counted as goal failure.",
  synthetic_note
)
table4_footer <- paste(
  "Data are n (%) among all randomised participants.",
  "Absolute-difference 95% CIs use the two-sample score method without continuity correction.",
  "A separate safety-population indicator was unavailable.",
  synthetic_note
)

## ------------------------------------------------------------------
## Table 1. Baseline characteristics
## ------------------------------------------------------------------

group_header <- c(
  Combination = "Moderate-intensity statin with ezetimibe combination therapy\n(n=1894)",
  Monotherapy = "High-intensity statin monotherapy\n(n=1886)"
)

mean_sd <- function(v, g) {
  z <- out[group == g, get(v)]
  sprintf("%.1f (%.1f)", mean(z, na.rm = TRUE), sd(z, na.rm = TRUE))
}
median_iqr <- function(v, g) {
  z <- out[group == g, get(v)]
  sprintf("%.1f (%.1f–%.1f)", median(z, na.rm = TRUE),
          quantile(z, 0.25, na.rm = TRUE), quantile(z, 0.75, na.rm = TRUE))
}
n_pct <- function(v, g, value = 1L) {
  z <- as.character(out[group == g, get(v)])
  target <- as.character(value)
  sprintf("%d (%.1f%%)", sum(z == target, na.rm = TRUE),
          100 * mean(z == target, na.rm = TRUE))
}

table1_rows <- list()
add_t1 <- function(label, combo = "", mono = "", type = "data") {
  table1_rows[[length(table1_rows) + 1L]] <<- data.table(
    Characteristic = label,
    Combination = combo,
    Monotherapy = mono,
    row_type = type
  )
}

add_t1("Age, years", mean_sd("Age", "Combination"), mean_sd("Age", "Monotherapy"))
add_t1("Female sex", n_pct("Sex", "Combination", "Female"), n_pct("Sex", "Monotherapy", "Female"))
add_t1("Male sex", n_pct("Sex", "Combination", "Male"), n_pct("Sex", "Monotherapy", "Male"))
add_t1("Height, cm", mean_sd("Height", "Combination"), mean_sd("Height", "Monotherapy"))
add_t1("Weight, kg", mean_sd("Weight", "Combination"), mean_sd("Weight", "Monotherapy"))
add_t1("Body-mass index, kg/m²", mean_sd("BMI", "Combination"), mean_sd("BMI", "Monotherapy"))
add_t1("Previous myocardial infarction", n_pct("Prior_MI", "Combination"), n_pct("Prior_MI", "Monotherapy"))
add_t1("Previous percutaneous coronary intervention", n_pct("Prior_PCI", "Combination"), n_pct("Prior_PCI", "Monotherapy"))
add_t1("Previous coronary bypass graft surgery", n_pct("Prior_CABG", "Combination"), n_pct("Prior_CABG", "Monotherapy"))
add_t1("Acute coronary syndrome", n_pct("ACS", "Combination"), n_pct("ACS", "Monotherapy"))
add_t1("Previous ischaemic stroke", n_pct("Prior_stroke", "Combination"), n_pct("Prior_stroke", "Monotherapy"))
add_t1("Chronic kidney disease", n_pct("CKD", "Combination"), n_pct("CKD", "Monotherapy"))
add_t1("End-stage kidney disease on dialysis", n_pct("ESRD_dialysis", "Combination"), n_pct("ESRD_dialysis", "Monotherapy"))
add_t1("Peripheral artery disease", n_pct("PAD", "Combination"), n_pct("PAD", "Monotherapy"))
add_t1("Hypertension", n_pct("Hypertension", "Combination"), n_pct("Hypertension", "Monotherapy"))
add_t1("Diabetes", n_pct("Diabetes", "Combination"), n_pct("Diabetes", "Monotherapy"))
add_t1("Diabetes with insulin treatment", n_pct("Diabetes_insulin", "Combination"), n_pct("Diabetes_insulin", "Monotherapy"))
add_t1("Current smoker", n_pct("Smoking", "Combination"), n_pct("Smoking", "Monotherapy"))
add_t1("Medication for dyslipidaemia before randomisation", type = "section")
add_t1("   High-intensity statin", n_pct("Pre_HI_statin", "Combination"), n_pct("Pre_HI_statin", "Monotherapy"))
add_t1("   High-intensity statin with ezetimibe", n_pct("Pre_HI_statin_ezetimibe", "Combination"), n_pct("Pre_HI_statin_ezetimibe", "Monotherapy"))
add_t1("   Moderate-intensity statin", n_pct("Pre_MI_statin", "Combination"), n_pct("Pre_MI_statin", "Monotherapy"))
add_t1("   Moderate-intensity statin with ezetimibe", n_pct("Pre_MI_statin_ezetimibe", "Combination"), n_pct("Pre_MI_statin_ezetimibe", "Monotherapy"))
add_t1("   Low-intensity statin", n_pct("Pre_LI_statin", "Combination"), n_pct("Pre_LI_statin", "Monotherapy"))
add_t1("   None", n_pct("Pre_none", "Combination"), n_pct("Pre_none", "Monotherapy"))
add_t1("Serum LDL cholesterol concentration, mg/dL", median_iqr("Baseline_LDL", "Combination"), median_iqr("Baseline_LDL", "Monotherapy"))

baseline_ldl70 <- function(g) {
  z <- out[group == g, Baseline_LDL]
  sprintf("%d (%.1f%%)", sum(z < 70, na.rm = TRUE), 100 * mean(z < 70, na.rm = TRUE))
}
add_t1("Number of patients with LDL cholesterol concentrations <70 mg/dL",
       baseline_ldl70("Combination"), baseline_ldl70("Monotherapy"))

table1_full <- rbindlist(table1_rows)
table1_type <- table1_full$row_type
table1 <- table1_full[, !"row_type"]
setnames(table1, c("Combination", "Monotherapy"), unname(group_header))

save_paper_table_png(
  table1,
  file.path(asset_dir, "RACING_Table1.png"),
  "Table 1: Baseline characteristics of the intention-to-treat population",
  table1_footer,
  row_type = table1_type,
  col_widths = c(3.8, 1.45, 1.45),
  width = 1700, height = 2250, font_size = 12
)

## ------------------------------------------------------------------
## Table 2. Three-year clinical endpoints
## ------------------------------------------------------------------

primary_surv <- out[!is.na(primary_event) & !is.na(admend_mo)]
primary_surv[, .event := as.integer(as.character(primary_event))]
primary_surv[, .time := fifelse(
  .event == 1L, as.numeric(primary_time_mo), as.numeric(admend_mo)
)]
primary_surv[, trt_combo := as.integer(group == "Combination")]
primary_cox <- coxph(Surv(.time, .event) ~ trt_combo, data = primary_surv)
primary_ph <- cox.zph(primary_cox, transform = "identity")
primary_ph_dt <- data.table(
  Term = rownames(primary_ph$table),
  Chisq = primary_ph$table[, "chisq"],
  df = primary_ph$table[, "df"],
  `P value` = primary_ph$table[, "p"]
)
primary_ci <- suppressWarnings(confint(primary_cox))
primary_hr_text <- sprintf(
  "%.2f (%.2f to %.2f)",
  exp(coef(primary_cox)[["trt_combo"]]),
  exp(primary_ci["trt_combo", 1]),
  exp(primary_ci["trt_combo", 2])
)
primary_cox_p <- summary(primary_cox)$coefficients["trt_combo", "Pr(>|z|)"]

table2_rows <- list()
add_t2_section <- function(label) {
  table2_rows[[length(table2_rows) + 1L]] <<- data.table(
    Outcome = label, Combination = "", Monotherapy = "",
    Difference = "", HR = "", P = "", row_type = "section"
  )
}
add_t2_event <- function(v, label, primary = FALSE) {
  sm <- event_summary(out, v)
  rd <- risk_difference(sm$Events, sm$N, conf.level = if (primary) 0.90 else 0.95)
  p <- if (primary) primary_cox_p else binary_p(out[[v]], out$group)
  table2_rows[[length(table2_rows) + 1L]] <<- data.table(
    Outcome = label,
    Combination = sprintf("%d (%.1f%%)", sm$Events[1], 100 * sm$Events[1] / sm$N[1]),
    Monotherapy = sprintf("%d (%.1f%%)", sm$Events[2], 100 * sm$Events[2] / sm$N[2]),
    Difference = sprintf("%.2f (%.2f to %.2f)",
                         100 * rd["estimate"], 100 * rd["lower"], 100 * rd["upper"]),
    HR = if (primary) primary_hr_text else "—",
    P = fmt_p(p),
    row_type = "data"
  )
}

add_t2_section("Primary endpoint")
add_t2_event(
  "primary_event",
  "Composite of cardiovascular death, major cardiovascular event, or non-fatal stroke",
  primary = TRUE
)
add_t2_section("Secondary efficacy endpoint")
add_t2_event(
  "secondary_event",
  "Composite of all-cause death, major cardiovascular event, or non-fatal stroke"
)
add_t2_section("Individual clinical endpoint")
for (v in setdiff(varlist$Clinical, c("primary_event", "secondary_event"))) {
  add_t2_event(v, unname(clinical_labels[v]))
}

table2_full <- rbindlist(table2_rows)
table2_type <- table2_full$row_type
table2 <- table2_full[, !"row_type"]
setnames(
  table2,
  c("Combination", "Monotherapy", "Difference", "HR", "P"),
  c(
    group_header[["Combination"]],
    group_header[["Monotherapy"]],
    "Absolute difference, %p (CI)",
    "Hazard ratio (95% CI)",
    "P value"
  )
)

save_paper_table_png(
  table2,
  file.path(asset_dir, "RACING_Table2.png"),
  "Table 2: Three-year clinical endpoints in the intention-to-treat population",
  table2_footer,
  row_type = table2_type,
  col_widths = c(4.2, 1.5, 1.5, 1.7, 1.4, 0.75),
  width = 2500, height = 1450, font_size = 11
)

## ------------------------------------------------------------------
## Table 3. LDL-C outcomes
## ------------------------------------------------------------------

table3_rows <- list()
add_t3 <- function(label, combo = "", mono = "", difference = "", type = "data") {
  table3_rows[[length(table3_rows) + 1L]] <<- data.table(
    Outcome = label,
    Combination = combo,
    Monotherapy = mono,
    Difference = difference,
    row_type = type
  )
}

for (yr in 1:3) {
  ldl_v <- paste0("LDL_y", yr)
  ldl70_v <- paste0("LDL70_y", yr)
  ldl55_v <- paste0("LDL55_y", yr)

  add_t3(paste0(yr, if (yr == 1) " year" else " years"), type = "section")

  observed <- out[!is.na(get(ldl_v)), .N, by = group][order(group)]
  add_t3(
    "Number of patients",
    format(observed$N[1], big.mark = ","),
    format(observed$N[2], big.mark = ","),
    "—"
  )

  for (target in c(ldl70_v, ldl55_v)) {
    label <- if (target == ldl70_v) {
      "Number of patients with LDL cholesterol concentrations <70 mg/dL"
    } else {
      "Number of patients with LDL cholesterol concentrations <55 mg/dL"
    }
    sm <- out[!is.na(get(ldl_v)), .(
      N = .N,
      Events = sum(as.integer(as.character(get(target))) == 1L, na.rm = TRUE)
    ), by = group][order(group)]
    rd <- risk_difference(sm$Events, sm$N, conf.level = 0.95)

    add_t3(
      label,
      sprintf("%d (%.1f%%)", sm$Events[1], 100 * sm$Events[1] / sm$N[1]),
      sprintf("%d (%.1f%%)", sm$Events[2], 100 * sm$Events[2] / sm$N[2]),
      sprintf("%.1f (%.1f to %.1f)",
              100 * rd["estimate"], 100 * rd["lower"], 100 * rd["upper"])
    )
  }

  sm_ldl <- out[!is.na(get(ldl_v)), .(
    med = median(get(ldl_v)),
    q1 = quantile(get(ldl_v), 0.25),
    q3 = quantile(get(ldl_v), 0.75)
  ), by = group][order(group)]

  add_t3(
    "LDL cholesterol concentration, mg/dL",
    sprintf("%.1f (%.1f–%.1f)", sm_ldl$med[1], sm_ldl$q1[1], sm_ldl$q3[1]),
    sprintf("%.1f (%.1f–%.1f)", sm_ldl$med[2], sm_ldl$q1[2], sm_ldl$q3[2]),
    "—"
  )
}

table3_full <- rbindlist(table3_rows)
table3_type <- table3_full$row_type
table3 <- table3_full[, !"row_type"]
setnames(
  table3,
  c("Combination", "Monotherapy", "Difference"),
  c(
    group_header[["Combination"]],
    group_header[["Monotherapy"]],
    "Absolute difference in proportions, %p (95% CI)"
  )
)

save_paper_table_png(
  table3,
  file.path(asset_dir, "RACING_Table3.png"),
  "Table 3: LDL cholesterol outcomes in the intention-to-treat population",
  table3_footer,
  row_type = table3_type,
  col_widths = c(4.4, 1.55, 1.55, 2.0),
  width = 2200, height = 1150, font_size = 12
)

## ------------------------------------------------------------------
## Table 4. Safety endpoints
## ------------------------------------------------------------------

table4_rows <- list()
add_t4_section <- function(label) {
  table4_rows[[length(table4_rows) + 1L]] <<- data.table(
    Outcome = label, Combination = "", Monotherapy = "",
    Difference = "", row_type = "section"
  )
}
add_t4_event <- function(v, label) {
  sm <- event_summary(out, v)
  rd <- risk_difference(sm$Events, sm$N, conf.level = 0.95)
  table4_rows[[length(table4_rows) + 1L]] <<- data.table(
    Outcome = label,
    Combination = sprintf("%d (%.1f%%)", sm$Events[1], 100 * sm$Events[1] / sm$N[1]),
    Monotherapy = sprintf("%d (%.1f%%)", sm$Events[2], 100 * sm$Events[2] / sm$N[2]),
    Difference = sprintf("%.2f (%.2f to %.2f)",
                         100 * rd["estimate"], 100 * rd["lower"], 100 * rd["upper"]),
    row_type = "data"
  )
}

add_t4_section("Serious adverse events")
add_t4_event("allcause_death_event", "Death")
add_t4_section("Adverse events")

safety_display <- c(
  new_diabetes = "New-onset diabetes",
  new_diabetes_med = "New-onset diabetes with anti-diabetic medication initiation",
  muscle_ae = "Muscle-related adverse events",
  myalgia = "   Myalgia",
  myopathy = "   Myopathy",
  myonecrosis = "   Myonecrosis",
  hepatic_ae = "Hepatic-related adverse events",
  ck_elevation = "   Creatine kinase elevation",
  fasting_glucose_elevation = "   Fasting glucose concentration elevation",
  gallbladder_ae = "Gallbladder-related adverse events",
  major_bleeding = "Major bleeding",
  cancer = "Cancer diagnosis",
  neurocognitive_disorder = "New-onset neurocognitive disorder",
  cataract_surgery = "Cataract surgery"
)
for (v in names(safety_display)) add_t4_event(v, safety_display[[v]])

table4_full <- rbindlist(table4_rows)
table4_type <- table4_full$row_type
table4 <- table4_full[, !"row_type"]
setnames(
  table4,
  c("Combination", "Monotherapy", "Difference"),
  c(
    group_header[["Combination"]],
    group_header[["Monotherapy"]],
    "Absolute difference, %p (95% CI)"
  )
)

save_paper_table_png(
  table4,
  file.path(asset_dir, "RACING_Table4.png"),
  "Table 4: Safety endpoints in the randomised population",
  table4_footer,
  row_type = table4_type,
  col_widths = c(4.4, 1.55, 1.55, 2.0),
  width = 2150, height = 1550, font_size = 12
)

## ------------------------------------------------------------------
make_ft <- function(df, caption, footer, row_type) {
  ft <- flextable(as.data.frame(df, check.names = FALSE)) %>%
    set_caption(caption) %>%
    add_footer_lines(footer) %>%
    align(align = "left", part = "all") %>%
    valign(valign = "top", part = "all") %>%
    autofit()

  section_rows <- which(row_type == "section")
  if (length(section_rows)) {
    ft <- ft %>%
      bold(i = section_rows, bold = TRUE, part = "body") %>%
      bg(i = section_rows, bg = "#F2D7D9", part = "body")
  }
  ft
}

ft_list[["Table 1"]] <- make_ft(
  table1,
  "Table 1. Baseline characteristics of the intention-to-treat population",
  table1_footer,
  table1_type
)
ft_list[["Table 2"]] <- make_ft(
  table2,
  "Table 2. Three-year clinical endpoints in the intention-to-treat population",
  table2_footer,
  table2_type
)
ft_list[["Table 3"]] <- make_ft(
  table3,
  "Table 3. LDL cholesterol outcomes in the intention-to-treat population",
  table3_footer,
  table3_type
)
ft_list[["Table 4"]] <- make_ft(
  table4,
  "Table 4. Safety endpoints in the randomised population",
  table4_footer,
  table4_type
)

## Save all tables to one Excel workbook using openxlsx
## ------------------------------------------------------------------

wb <- createWorkbook()
write_sheet(wb, "Table 1", table1, "Table 1. Baseline characteristics", table1_footer)
write_sheet(wb, "Table 2", table2, "Table 2. Three-year clinical endpoints", table2_footer)
write_sheet(wb, "Table 3", table3, "Table 3. LDL-C outcomes", table3_footer)
write_sheet(wb, "Table 4", table4, "Table 4. Safety endpoints", table4_footer)
saveWorkbook(wb, file.path(results_dir, "RACING_Tables.xlsx"), overwrite = TRUE)

## ------------------------------------------------------------------
## Figure 1. Participant flow / study design
## ------------------------------------------------------------------

flow_counts <- out[, .(
  N = .N,
  Primary_events = sum(as.integer(as.character(primary_event)))
), by = group][order(group)]

## Summary values from the published RACING Table 4.
## These variables are not available in the synthetic patient-level data.
paper_intolerance <- data.table(
  group = factor(
    c("Combination", "Monotherapy"),
    levels = c("Combination", "Monotherapy")
  ),
  safety_n = c(1846L, 1832L),
  discontinue_n = c(88L, 150L)
)

flow_boxes <- data.table(
  xmin = c(3.05, 0.30, 6.55, 2.15, 5.15, 0.30, 6.55),
  xmax = c(6.95, 3.70, 9.70, 4.85, 7.85, 3.70, 9.70),
  ymin = c(6.65, 4.95, 4.95, 3.30, 3.30, 1.45, 1.45),
  ymax = c(7.20, 6.10, 6.10, 4.15, 4.15, 2.45, 2.45),
  box_type = c(
    "randomised", "assigned", "assigned",
    "discontinued", "discontinued",
    "analysis", "analysis"
  ),
  font_size = c(3.85, 3.55, 3.55, 2.95, 2.95, 3.45, 3.45),
  label = c(
    "3780 patients underwent random assignment",
    paste0(
      flow_counts$N[1],
      " assigned to moderate-intensity statin\n",
      "with ezetimibe combination therapy"
    ),
    paste0(
      flow_counts$N[2],
      " assigned to high-intensity statin\n",
      "monotherapy"
    ),
    paste0(
      paper_intolerance$discontinue_n[1],
      " discontinued allocated therapy\n",
      "owing to adverse events or intolerance\n",
      sprintf(
        "%.1f%% (%d/%d)",
        100 * paper_intolerance$discontinue_n[1] /
          paper_intolerance$safety_n[1],
        paper_intolerance$discontinue_n[1],
        paper_intolerance$safety_n[1]
      )
    ),
    paste0(
      paper_intolerance$discontinue_n[2],
      " discontinued allocated therapy\n",
      "owing to adverse events or intolerance\n",
      sprintf(
        "%.1f%% (%d/%d)",
        100 * paper_intolerance$discontinue_n[2] /
          paper_intolerance$safety_n[2],
        paper_intolerance$discontinue_n[2],
        paper_intolerance$safety_n[2]
      )
    ),
    paste0(
      flow_counts$N[1],
      " included in intention-to-treat analysis\n",
      flow_counts$Primary_events[1],
      " primary endpoint events"
    ),
    paste0(
      flow_counts$N[2],
      " included in intention-to-treat analysis\n",
      flow_counts$Primary_events[2],
      " primary endpoint events"
    )
  )
)

figure1 <- ggplot() +
  geom_rect(
    data = flow_boxes,
    aes(xmin = xmin, xmax = xmax, ymin = ymin, ymax = ymax),
    fill = "white",
    colour = "black",
    linewidth = 0.65
  ) +
  geom_text(
    data = flow_boxes,
    aes(
      x = (xmin + xmax) / 2,
      y = (ymin + ymax) / 2,
      label = label,
      size = font_size
    ),
    family = "sans",
    lineheight = 1.02,
    colour = "#111111"
  ) +
  scale_size_identity() +
  geom_segment(
    aes(x = 5, y = 6.65, xend = 5, yend = 6.38),
    linewidth = 0.55,
    colour = "black"
  ) +
  geom_segment(
    aes(x = 2, y = 6.38, xend = 8.12, yend = 6.38),
    linewidth = 0.55,
    colour = "black"
  ) +
  geom_segment(
    aes(x = 2, y = 6.38, xend = 2, yend = 6.10),
    linewidth = 0.55,
    colour = "black",
    arrow = arrow(length = unit(0.11, "inches"), type = "closed")
  ) +
  geom_segment(
    aes(x = 8.12, y = 6.38, xend = 8.12, yend = 6.10),
    linewidth = 0.55,
    colour = "black",
    arrow = arrow(length = unit(0.11, "inches"), type = "closed")
  ) +
  geom_segment(
    aes(x = 2, y = 4.95, xend = 2, yend = 2.45),
    linewidth = 0.55,
    colour = "black",
    arrow = arrow(length = unit(0.11, "inches"), type = "closed")
  ) +
  geom_segment(
    aes(x = 8.12, y = 4.95, xend = 8.12, yend = 2.45),
    linewidth = 0.55,
    colour = "black",
    arrow = arrow(length = unit(0.11, "inches"), type = "closed")
  ) +
  geom_segment(
    aes(x = 2, y = 3.72, xend = 2.15, yend = 3.72),
    linewidth = 0.55,
    colour = "black",
    arrow = arrow(length = unit(0.10, "inches"), type = "closed")
  ) +
  geom_segment(
    aes(x = 8.12, y = 3.72, xend = 7.85, yend = 3.72),
    linewidth = 0.55,
    colour = "black",
    arrow = arrow(length = unit(0.10, "inches"), type = "closed")
  ) +
  annotate(
    "text",
    x = 0.18, y = 0.92,
    label = "Figure 1: Trial profile",
    hjust = 0,
    family = "sans",
    fontface = "bold",
    size = 3.65
  ) +
  annotate(
    "text",
    x = 0.18, y = 0.42,
    label = paste0(
      "*Discontinuation and safety-population values are summary numbers from ",
      "published RACING Table 4;\n",
      "they were not derived from the synthetic patient-level data. ",
      synthetic_note
    ),
    hjust = 0,
    family = "sans",
    size = 2.65,
    lineheight = 1.05
  ) +
  coord_cartesian(
    xlim = c(0, 10),
    ylim = c(0, 7.5),
    expand = FALSE,
    clip = "off"
  ) +
  theme_void() +
  theme(plot.margin = margin(8, 12, 8, 12))

plot_list[["Figure 1"]] <- figure1
save_plot_png(
  figure1,
  file.path(asset_dir, "RACING_Figure1.png"),
  width = 10,
  height = 7.5,
  dpi = 220
)

## ------------------------------------------------------------------
## Figure 2. Kaplan-Meier cumulative incidence
## ------------------------------------------------------------------

surv_data <- copy(out[!is.na(primary_event) & !is.na(admend_mo)])
surv_data[, .event := as.integer(as.character(primary_event))]
surv_data[, .time := fifelse(
  .event == 1L,
  as.numeric(primary_time_mo),
  as.numeric(admend_mo)
)]
stopifnot(!anyNA(surv_data$.time))

fit_km <- survfit(Surv(.time, .event) ~ group, data = surv_data)
km_s <- summary(fit_km)
km_dt <- data.table(
  time = km_s$time,
  incidence = 1 - km_s$surv,
  strata = sub("^group=", "", as.character(km_s$strata))
)
km_dt <- rbind(
  data.table(time = 0, incidence = 0, strata = group_levels),
  km_dt
)
km_dt[, strata := factor(
  strata,
  levels = c("Monotherapy", "Combination"),
  labels = c(
    "High-intensity statin monotherapy",
    "Moderate-intensity statin with\nezetimibe combination therapy"
  )
)]

logrank <- survdiff(Surv(.time, .event) ~ group, data = surv_data)
logrank_p <- pchisq(
  logrank$chisq,
  df = length(logrank$n) - 1L,
  lower.tail = FALSE
)

risk_times <- c(0, 12, 24, 36)
risk_s <- summary(fit_km, times = risk_times, extend = TRUE)
risk_dt <- data.table(
  time = risk_s$time,
  n.risk = risk_s$n.risk,
  strata = sub("^group=", "", as.character(risk_s$strata))
)
risk_dt[, strata := factor(
  strata,
  levels = c("Combination", "Monotherapy"),
  labels = c("Combination therapy", "Monotherapy")
)]

primary_sm <- event_summary(out, "primary_event")
primary_rd90 <- risk_difference(
  primary_sm$Events,
  primary_sm$N,
  conf.level = 0.90
)
difference_label <- sprintf(
  "Absolute difference %.2f%% (90%% CI %.2f to %.2f)",
  100 * primary_rd90["estimate"],
  100 * primary_rd90["lower"],
  100 * primary_rd90["upper"]
)

km_plot <- ggplot(
  km_dt,
  aes(x = time, y = incidence, colour = strata)
) +
  geom_step(linewidth = 0.9) +
  scale_colour_manual(
    values = c(
      "High-intensity statin monotherapy" = "#0099B5",
      "Moderate-intensity statin with\nezetimibe combination therapy" = "#A50034"
    ),
    breaks = c(
      "High-intensity statin monotherapy",
      "Moderate-intensity statin with\nezetimibe combination therapy"
    ),
    name = NULL
  ) +
  scale_x_continuous(
    breaks = risk_times,
    limits = c(0, 36),
    expand = expansion(mult = c(0.025, 0.025))
  ) +
  scale_y_continuous(
    labels = percent_format(accuracy = 1),
    limits = c(0, 0.15),
    breaks = seq(0, 0.15, 0.05),
    expand = c(0, 0)
  ) +
  annotate(
    "text",
    x = 17, y = 0.108,
    label = difference_label,
    family = "sans",
    size = 4.2
  ) +
  annotate(
    "text",
    x = 17, y = 0.094,
    label = paste0("Log-rank P = ", fmt_p(logrank_p)),
    family = "sans",
    size = 3.6
  ) +
  labs(
    x = "Time since randomisation (months)",
    y = "Cumulative incidence (%)"
  ) +
  theme_classic(base_family = "sans", base_size = 13) +
  theme(
    legend.position = c(0.62, 0.92),
    legend.justification = c(0, 1),
    legend.text = element_text(size = 11),
    legend.key.width = unit(1.0, "cm"),
    axis.line = element_line(linewidth = 0.65, colour = "black"),
    axis.ticks = element_line(linewidth = 0.55, colour = "black"),
    axis.title = element_text(size = 13),
    plot.margin = margin(10, 20, 0, 20)
  )

risk_plot <- ggplot(risk_dt, aes(x = time, y = strata)) +
  geom_text(
    aes(label = n.risk),
    family = "sans",
    size = 4.0
  ) +
  scale_x_continuous(
    breaks = risk_times,
    limits = c(0, 36),
    expand = expansion(mult = c(0.025, 0.025))
  ) +
  scale_y_discrete(limits = c("Combination therapy", "Monotherapy")) +
  labs(
    x = NULL,
    y = NULL,
    title = "Number at risk"
  ) +
  theme_void(base_family = "sans") +
  theme(
    plot.title = element_text(
      hjust = 0,
      size = 11,
      face = "bold",
      margin = margin(b = 3)
    ),
    axis.text.y = element_text(size = 10, hjust = 1),
    axis.text.x = element_text(size = 10),
    plot.margin = margin(0, 20, 0, 20)
  )

figure2_caption <- ggplot() +
  annotate(
    "text",
    x = 0, y = 1,
    label = paste0(
      "Figure 2: Kaplan–Meier curves of the primary endpoint in the ",
      "intention-to-treat population\n",
      synthetic_note
    ),
    hjust = 0,
    vjust = 1,
    family = "sans",
    fontface = "bold",
    size = 3.8
  ) +
  xlim(0, 1) +
  ylim(0, 1) +
  theme_void()

figure2 <- km_plot / risk_plot / figure2_caption +
  plot_layout(heights = c(4.6, 1.0, 0.55))

plot_list[["Figure 2"]] <- figure2
save_plot_png(
  figure2,
  file.path(asset_dir, "RACING_Figure2.png"),
  width = 13.0,
  height = 9.0,
  dpi = 220
)

## ------------------------------------------------------------------
## Figure 3. Primary endpoint subgroup forest plot
## ------------------------------------------------------------------

subgroup_rows <- list()

subgroup_summary <- function(dd) {
  dd <- copy(dd[!is.na(primary_event)])
  dd[, .event := as.integer(as.character(primary_event))]

  sm <- dd[, .(
    N = .N,
    Events = sum(.event)
  ), by = group][order(group)]

  if (nrow(sm) < 2L || any(sm$N == 0L)) {
    return(c(
      combination_n = NA, combination_events = NA,
      mono_n = NA, mono_events = NA,
      estimate = NA, lower = NA, upper = NA
    ))
  }

  rd <- risk_difference(sm$Events, sm$N, conf.level = 0.90)

  c(
    combination_n = sm$N[1],
    combination_events = sm$Events[1],
    mono_n = sm$N[2],
    mono_events = sm$Events[2],
    estimate = 100 * unname(rd["estimate"]),
    lower = 100 * unname(rd["lower"]),
    upper = 100 * unname(rd["upper"])
  )
}

overall <- subgroup_summary(out)
subgroup_rows[[1]] <- data.table(
  Subgroup = "All patients",
  Combination = sprintf(
    "%d/%d (%.1f)",
    overall["combination_events"],
    overall["combination_n"],
    100 * overall["combination_events"] / overall["combination_n"]
  ),
  Monotherapy = sprintf(
    "%d/%d (%.1f)",
    overall["mono_events"],
    overall["mono_n"],
    100 * overall["mono_events"] / overall["mono_n"]
  ),
  estimate = overall["estimate"],
  lower = overall["lower"],
  upper = overall["upper"],
  is_header = FALSE,
  is_overall = TRUE
)

for (v in varlist$Subgroup) {
  subgroup_rows[[length(subgroup_rows) + 1L]] <- data.table(
    Subgroup = unname(subgroup_labels[v]),
    Combination = "",
    Monotherapy = "",
    estimate = NA_real_,
    lower = NA_real_,
    upper = NA_real_,
    is_header = TRUE,
    is_overall = FALSE
  )

  lvls <- levels(droplevels(factor(out[[v]])))
  for (lv in lvls) {
    est <- subgroup_summary(out[as.character(get(v)) == lv])

    subgroup_rows[[length(subgroup_rows) + 1L]] <- data.table(
      Subgroup = paste0("   ", lv),
      Combination = sprintf(
        "%d/%d (%.1f)",
        est["combination_events"],
        est["combination_n"],
        100 * est["combination_events"] / est["combination_n"]
      ),
      Monotherapy = sprintf(
        "%d/%d (%.1f)",
        est["mono_events"],
        est["mono_n"],
        100 * est["mono_events"] / est["mono_n"]
      ),
      estimate = est["estimate"],
      lower = est["lower"],
      upper = est["upper"],
      is_header = FALSE,
      is_overall = FALSE
    )
  }
}

forest_dt <- rbindlist(subgroup_rows, fill = TRUE)
forest_dt[, `Absolute difference (90% CI)` := ifelse(
  is.na(estimate),
  "",
  sprintf("%.2f (%.2f to %.2f)", estimate, lower, upper)
)]
forest_dt[, ` ` := strrep(" ", 24)]

forest_display <- forest_dt[, .(
  Subgroup,
  `Combination therapy\nNumber/total (%)` = Combination,
  `Monotherapy\nNumber/total (%)` = Monotherapy,
  ` `,
  `Absolute difference (90% CI)`
)]

forest_theme_obj <- forest_theme(
  base_size = 10,
  base_family = "sans",
  ci_pch = 15,
  ci_col = "#222222",
  ci_fill = "#222222",
  ci_lwd = 1.2,
  ci_Theight = 0,
  refline_gp = gpar(col = "#222222", lwd = 0.9),
  vertline_lwd = 0.9,
  vertline_lty = "dashed",
  vertline_col = "#666666",
  xaxis_gp = gpar(fontfamily = "sans", fontsize = 9),
  footnote_gp = gpar(
    fontfamily = "sans",
    fontsize = 8,
    col = "#333333"
  ),
  arrow_gp = gpar(col = "#222222", lwd = 0.8)
)

forest_grob <- forest(
  forest_display,
  est = forest_dt$estimate,
  lower = forest_dt$lower,
  upper = forest_dt$upper,
  sizes = 0.35,
  ci_column = 4,
  is_summary = forest_dt$is_header,
  ref_line = 0,
  vert_line = 2,
  x_trans = "none",
  xlim = c(-10, 10),
  ticks_at = c(-10, -5, 0, 2, 5, 10),
  arrow_lab = c(
    "Favours combination therapy",
    "Favours monotherapy"
  ),
  theme = forest_theme_obj,
  footnote = paste0(
    "The vertical dashed line indicates the prespecified absolute-difference ",
    "2.0%p non-inferiority margin. ",
    synthetic_note
  )
)

figure3_caption <- textGrob(
  paste0(
    "Figure 3: Subgroup analysis for the primary endpoint of the ",
    "intention-to-treat population"
  ),
  x = 0,
  hjust = 0,
  gp = gpar(
    fontfamily = "sans",
    fontsize = 13,
    fontface = "bold",
    col = "#111111"
  )
)

figure3_grob <- arrangeGrob(
  forest_grob,
  figure3_caption,
  ncol = 1,
  heights = c(0.95, 0.05)
)

figure3 <- patchwork::wrap_elements(full = figure3_grob)
plot_list[["Figure 3"]] <- figure3

save_grid_png(
  figure3_grob,
  file.path(asset_dir, "RACING_Figure3.png"),
  width = 2800,
  height = 1800,
  res = 190
)

## ------------------------------------------------------------------
## Save figures as editable vector graphics in PowerPoint
## ------------------------------------------------------------------

ppt <- read_pptx()
for (nm in c("Figure 1", "Figure 2")) {
  ppt <- add_slide(ppt, layout = "Blank", master = "Office Theme")
  ppt <- ph_with(
    ppt,
    value = rvg::dml(ggobj = plot_list[[nm]]),
    location = ph_location_fullsize()
  )
}
ppt <- add_slide(ppt, layout = "Blank", master = "Office Theme")
ppt <- ph_with(
  ppt,
  value = rvg::dml(code = grid::grid.draw(figure3_grob)),
  location = ph_location_fullsize()
)
print(ppt, target = file.path(figures_dir, "RACING_Figures.pptx"))

openxlsx::write.xlsx(
  primary_ph_dt,
  file.path(results_dir, "RACING_primary_PH_assumption.xlsx"),
  overwrite = TRUE
)

## ------------------------------------------------------------------
## Analysis summary and completion checks
## ------------------------------------------------------------------

summary_lines <- c(
  synthetic_note,
  "",
  "Group counts",
  capture.output(print(out[, .N, by = group])),
  "",
  "Primary endpoint",
  capture.output(print(out[, .(
    N = .N,
    Events = sum(as.integer(as.character(primary_event))),
    Rate = round(mean(as.integer(as.character(primary_event))) * 100, 1)
  ), by = group])),
  "",
  "LDL missing counts",
  capture.output(print(colSums(is.na(out[, .(LDL_y1, LDL_y2, LDL_y3)]))))
)
writeLines(summary_lines, file.path(results_dir, "RACING_analysis_summary.txt"))

expected_assets <- file.path(
  asset_dir,
  c(
    "RACING_Figure1.png", "RACING_Table1.png", "RACING_Table2.png",
    "RACING_Figure2.png", "RACING_Table3.png", "RACING_Table4.png",
    "RACING_Figure3.png"
  )
)
stopifnot(all(file.exists(expected_assets)))
stopifnot(file.exists(file.path(results_dir, "RACING_Tables.xlsx")))
stopifnot(file.exists(file.path(figures_dir, "RACING_Figures.pptx")))
stopifnot(file.exists(file.path(results_dir, "RACING_primary_PH_assumption.xlsx")))

cat("Generated files:\n")
cat(expected_assets, sep = "\n")
cat("\n", file.path(results_dir, "RACING_Tables.xlsx"), "\n", sep = "")
