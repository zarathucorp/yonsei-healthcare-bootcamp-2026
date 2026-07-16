## RACING 합성 데이터 분석
## Lancet 논문의 주요 표와 그림 구조를 재현한다.

command_args <- commandArgs(trailingOnly = FALSE)
file_arg <- sub("^--file=", "", grep("^--file=", command_args, value = TRUE))
project_dir <- if (length(file_arg) == 1L) {
  dirname(normalizePath(file_arg, winslash = "/", mustWork = TRUE))
} else {
  normalizePath(getwd(), winslash = "/", mustWork = TRUE)
}

source(file.path(project_dir, "global.R"))

g1 <- group_levels[1]
g2 <- group_levels[2]

## p값과 신뢰구간을 논문 표 형식으로 표시한다.
fmt_p <- function(p) {
  ifelse(
    is.na(p),
    "",
    ifelse(p < 0.001, "<0.001", sprintf("%.3f", p))
  )
}

prop_ci <- function(events, total, conf.level = 0.95) {
  if (total == 0L) return(c(NA_real_, NA_real_))
  ci <- suppressWarnings(prop.test(
    events,
    total,
    conf.level = conf.level,
    correct = FALSE
  )$conf.int)
  pmax(0, pmin(1, ci))
}

risk_difference_ci <- function(
  events1,
  total1,
  events2,
  total2,
  conf.level = 0.95
) {
  fit <- suppressWarnings(prop.test(
    c(events1, events2),
    c(total1, total2),
    conf.level = conf.level,
    correct = FALSE
  ))

  c(
    estimate = events1 / total1 - events2 / total2,
    lower = unname(fit$conf.int[1]),
    upper = unname(fit$conf.int[2])
  )
}

risk_ratio_ci <- function(
  events1,
  total1,
  events2,
  total2,
  conf.level = 0.95
) {
  cells <- c(
    events1,
    total1 - events1,
    events2,
    total2 - events2
  )

  if (any(cells == 0L)) cells <- cells + 0.5

  a1 <- cells[1]
  b1 <- cells[2]
  a2 <- cells[3]
  b2 <- cells[4]

  rr <- (a1 / (a1 + b1)) / (a2 / (a2 + b2))
  se <- sqrt(
    1 / a1 - 1 / (a1 + b1) +
      1 / a2 - 1 / (a2 + b2)
  )
  z <- qnorm(1 - (1 - conf.level) / 2)

  c(
    estimate = rr,
    lower = exp(log(rr) - z * se),
    upper = exp(log(rr) + z * se)
  )
}

binary_p <- function(x, g) {
  ok <- !is.na(x) & !is.na(g)
  tb <- table(x[ok], g[ok])
  if (nrow(tb) < 2L || ncol(tb) < 2L) return(NA_real_)

  expected <- suppressWarnings(
    chisq.test(tb, correct = FALSE)$expected
  )

  if (any(expected < 5)) {
    fisher.test(tb)$p.value
  } else {
    suppressWarnings(chisq.test(tb, correct = FALSE)$p.value)
  }
}

mean_ci <- function(x, conf.level = 0.95) {
  x <- x[!is.na(x)]
  n <- length(x)
  m <- mean(x)
  s <- sd(x)
  z <- qt(1 - (1 - conf.level) / 2, df = n - 1L)

  c(
    estimate = m,
    sd = s,
    lower = m - z * s / sqrt(n),
    upper = m + z * s / sqrt(n)
  )
}

median_ci <- function(x, conf.level = 0.95) {
  x <- sort(x[!is.na(x)])
  n <- length(x)
  k <- qbinom((1 - conf.level) / 2, n, 0.5)
  lower_index <- max(1L, as.integer(k))
  upper_index <- min(n, as.integer(n - k + 1L))

  c(
    estimate = median(x),
    q1 = unname(quantile(x, 0.25, type = 2)),
    q3 = unname(quantile(x, 0.75, type = 2)),
    lower = x[lower_index],
    upper = x[upper_index]
  )
}

format_prop <- function(events, total, conf.level = 0.95) {
  ci <- prop_ci(events, total, conf.level)
  sprintf(
    "%d/%d (%.1f%%; %.1f–%.1f)",
    events,
    total,
    events / total * 100,
    ci[1] * 100,
    ci[2] * 100
  )
}

format_mean <- function(x) {
  s <- mean_ci(x)
  sprintf(
    "%.1f (%.1f); 95%% CI %.1f–%.1f",
    s["estimate"],
    s["sd"],
    s["lower"],
    s["upper"]
  )
}

format_median <- function(x) {
  s <- median_ci(x)
  sprintf(
    "%.1f [%.1f–%.1f]; 95%% CI %.1f–%.1f",
    s["estimate"],
    s["q1"],
    s["q3"],
    s["lower"],
    s["upper"]
  )
}

format_difference <- function(x, digits = 2L) {
  sprintf(
    paste0("%.", digits, "f (%.", digits, "f to %.", digits, "f)"),
    x["estimate"] * 100,
    x["lower"] * 100,
    x["upper"] * 100
  )
}

format_ratio <- function(x) {
  sprintf(
    "%.2f (%.2f to %.2f)",
    x["estimate"],
    x["lower"],
    x["upper"]
  )
}

## Table 1: 기저 특성

## 변수별 요약 방식과 출력 순서를 정한다.
baseline_items <- list(
  list(variable = "Age", type = "mean", level = NA_character_, label = "Age, years"),
  list(variable = "Sex", type = "factor", level = "Female", label = "Female sex"),
  list(variable = "Sex", type = "factor", level = "Male", label = "Male sex"),
  list(variable = "Height", type = "mean", level = NA_character_, label = "Height, cm"),
  list(variable = "Weight", type = "mean", level = NA_character_, label = "Weight, kg"),
  list(variable = "BMI", type = "mean", level = NA_character_, label = "Body-mass index, kg/m²"),
  list(variable = "Prior_MI", type = "factor", level = "1", label = "Previous myocardial infarction"),
  list(variable = "Prior_PCI", type = "factor", level = "1", label = "Previous percutaneous coronary intervention"),
  list(variable = "Prior_CABG", type = "factor", level = "1", label = "Previous coronary bypass graft surgery"),
  list(variable = "ACS", type = "factor", level = "1", label = "Acute coronary syndrome"),
  list(variable = "Prior_stroke", type = "factor", level = "1", label = "Previous ischaemic stroke"),
  list(variable = "CKD", type = "factor", level = "1", label = "Chronic kidney disease"),
  list(variable = "ESRD_dialysis", type = "factor", level = "1", label = "End-stage kidney disease on dialysis"),
  list(variable = "PAD", type = "factor", level = "1", label = "Peripheral artery disease"),
  list(variable = "Hypertension", type = "factor", level = "1", label = "Hypertension"),
  list(variable = "Diabetes", type = "factor", level = "1", label = "Diabetes"),
  list(variable = "Diabetes_insulin", type = "factor", level = "1", label = "Diabetes with insulin treatment"),
  list(variable = "Smoking", type = "factor", level = "1", label = "Current smoker"),
  list(variable = NA_character_, type = "section", level = NA_character_, label = "Medication for dyslipidaemia before randomisation"),
  list(variable = "Pre_HI_statin", type = "factor", level = "1", label = "High-intensity statin"),
  list(variable = "Pre_HI_statin_ezetimibe", type = "factor", level = "1", label = "High-intensity statin + ezetimibe"),
  list(variable = "Pre_MI_statin", type = "factor", level = "1", label = "Moderate-intensity statin"),
  list(variable = "Pre_MI_statin_ezetimibe", type = "factor", level = "1", label = "Moderate-intensity statin + ezetimibe"),
  list(variable = "Pre_LI_statin", type = "factor", level = "1", label = "Low-intensity statin"),
  list(variable = "Pre_none", type = "factor", level = "1", label = "None"),
  list(variable = "Baseline_LDL", type = "median", level = NA_character_, label = "Serum LDL-C, mg/dL"),
  list(variable = "Baseline_LDL70", type = "factor", level = "Yes", label = "LDL-C <70 mg/dL")
)

table1 <- rbindlist(lapply(baseline_items, function(item) {
  if (item$type == "section") {
    ans <- data.table(
      Variable = item$label
    )
    ans[, (g1) := ""]
    ans[, (g2) := ""]
    return(ans)
  }

  values <- lapply(group_levels, function(grp) {
    x <- out[group == grp][[item$variable]]

    if (item$type == "mean") {
      format_mean(x)
    } else if (item$type == "median") {
      format_median(x)
    } else {
      ok <- !is.na(x)
      events <- sum(as.character(x[ok]) == item$level)
      format_prop(events, sum(ok))
    }
  })

  ans <- data.table(
    Variable = item$label
  )
  ans[, (g1) := values[[1]]]
  ans[, (g2) := values[[2]]]
  ans
}), use.names = TRUE, fill = TRUE)

setcolorder(table1, c("Variable", g1, g2))

table1_footer <- paste(
  "Data are mean (SD) with 95% t confidence interval,",
  "median [IQR] with distribution-free 95% confidence interval,",
  "or n/N (%, Wilson 95% confidence interval).",
  synthetic_note
)

## Table 2: 3년 임상 평가변수

## 각 평가변수의 치료군별 발생률과 치료효과를 계산한다.
table2 <- rbindlist(lapply(varlist$Clinical, function(v) {
  x <- as.integer(as.character(out[[v]]))
  g <- out$group

  total1 <- sum(g == g1 & !is.na(x))
  total2 <- sum(g == g2 & !is.na(x))
  events1 <- sum(g == g1 & x == 1L, na.rm = TRUE)
  events2 <- sum(g == g2 & x == 1L, na.rm = TRUE)

  rd <- risk_difference_ci(
    events1,
    total1,
    events2,
    total2,
    conf.level = 0.90
  )
  rr <- risk_ratio_ci(events1, total1, events2, total2)

  ans <- data.table(
    Endpoint = unname(clinical_labels[v]),
    `Absolute difference, % (90% CI)` = format_difference(rd),
    `Risk ratio (95% CI)` = format_ratio(rr),
    `P value` = fmt_p(binary_p(x, g))
  )
  ans[, (g1) := format_prop(events1, total1)]
  ans[, (g2) := format_prop(events2, total2)]
  ans
}), use.names = TRUE, fill = TRUE)

setcolorder(
  table2,
  c(
    "Endpoint", g1, g2,
    "Absolute difference, % (90% CI)",
    "Risk ratio (95% CI)", "P value"
  )
)

primary_rd <- risk_difference_ci(
  sum(out$group == g1 & as.character(out$primary_event) == "1"),
  sum(out$group == g1),
  sum(out$group == g2 & as.character(out$primary_event) == "1"),
  sum(out$group == g2),
  conf.level = 0.90
)
noninferior <- unname(primary_rd["upper"]) < 0.02

## 일차 평가변수는 Kaplan–Meier, Cox 모형, PH 가정까지 확인한다.
primary_survival_data <- out[, .(
  group,
  primary_followup_mo,
  primary_event = as.integer(as.character(primary_event))
)]
primary_survival_data[, group_cox := relevel(group, ref = g2)]

primary_cox <- coxph(
  Surv(primary_followup_mo, primary_event) ~ group_cox,
  data = primary_survival_data
)
primary_cox_summary <- summary(primary_cox)
primary_hr <- c(
  estimate = unname(primary_cox_summary$conf.int[1, "exp(coef)"]),
  lower = unname(primary_cox_summary$conf.int[1, "lower .95"]),
  upper = unname(primary_cox_summary$conf.int[1, "upper .95"]),
  p = unname(primary_cox_summary$coefficients[1, "Pr(>|z|)"])
)

primary_ph <- cox.zph(
  primary_cox,
  transform = "identity"
)
primary_ph_table <- as.data.table(
  primary_ph$table,
  keep.rownames = "Term"
)
setnames(
  primary_ph_table,
  c("Term", "Chi-square", "df", "P value")
)

primary_logrank <- survdiff(
  Surv(primary_followup_mo, primary_event) ~ group,
  data = primary_survival_data
)
primary_logrank_p <- pchisq(
  primary_logrank$chisq,
  df = length(primary_logrank$n) - 1L,
  lower.tail = FALSE
)

table2_footer <- paste(
  "Group-specific proportions use Wilson 95% confidence intervals.",
  "Absolute differences use score-based 90% confidence intervals without continuity correction.",
  "Risk ratios use log-scale 95% confidence intervals.",
  "P values use Pearson's chi-squared test or Fisher's exact test when expected counts are below 5.",
  "Endpoint-specific event times were unavailable in the synthetic data; therefore risk ratios, not endpoint-specific hazard ratios, are reported in this table.",
  synthetic_note
)

## Table 3: LDL-C 결과

## 각 시점의 측정 가능한 환자만 사용하며 결측값은 대체하지 않는다.
build_ldl_table <- function(target) {
  target_var <- paste0("LDL", target)

  rbindlist(lapply(levels(out.long$timepoint), function(tp) {
    dd <- out.long[timepoint == tp]

    stats <- lapply(group_levels, function(grp) {
      z <- dd[group == grp]
      ok <- !is.na(z$LDL)
      n <- sum(ok)
      events <- sum(as.character(z[[target_var]][ok]) == "1")

      list(
        n = n,
        events = events,
        prop = format_prop(events, n),
        median = format_median(z$LDL[ok])
      )
    })

    rd <- risk_difference_ci(
      stats[[1]]$events,
      stats[[1]]$n,
      stats[[2]]$events,
      stats[[2]]$n
    )

    p_goal <- binary_p(
      dd[[target_var]],
      dd$group
    )
    p_ldl <- suppressWarnings(
      wilcox.test(LDL ~ group, data = dd, exact = FALSE)$p.value
    )

    rows <- data.table(
      Timepoint = c(tp, "", ""),
      Outcome = c(
        "Participants with LDL-C measurement",
        paste0("LDL-C <", target, " mg/dL"),
        "LDL-C, mg/dL"
      ),
      `Absolute difference, % (95% CI)` = c(
        "",
        format_difference(rd),
        ""
      ),
      `P value` = c("", fmt_p(p_goal), fmt_p(p_ldl))
    )

    rows[, (g1) := c(
      as.character(stats[[1]]$n),
      stats[[1]]$prop,
      stats[[1]]$median
    )]
    rows[, (g2) := c(
      as.character(stats[[2]]$n),
      stats[[2]]$prop,
      stats[[2]]$median
    )]
    rows
  }), use.names = TRUE, fill = TRUE)
}

table3_ldl70 <- build_ldl_table(70)
table3_ldl55 <- build_ldl_table(55)

setcolorder(
  table3_ldl70,
  c(
    "Timepoint", "Outcome", g1, g2,
    "Absolute difference, % (95% CI)", "P value"
  )
)
setcolorder(table3_ldl55, names(table3_ldl70))

table3_footer <- paste(
  "LDL-C analyses use participants with an available measurement at each timepoint; missing values were not imputed.",
  "Proportions use Wilson 95% confidence intervals and score-based confidence intervals for absolute differences.",
  "LDL-C values are median [IQR] with distribution-free 95% confidence intervals.",
  "P values use Pearson's chi-squared test or Fisher's exact test for proportions and the Wilcoxon rank-sum test for LDL-C values.",
  synthetic_note
)

## Table 4: 안전성 평가변수

## safety population을 만들 수 없어 무작위 배정 환자 전체를 분모로 사용한다.
safety_order <- c(
  "intolerance_stop_reduce",
  setdiff(varlist$Safety, "intolerance_stop_reduce")
)

table4 <- rbindlist(lapply(safety_order, function(v) {
  x <- as.integer(as.character(out[[v]]))
  g <- out$group

  total1 <- sum(g == g1 & !is.na(x))
  total2 <- sum(g == g2 & !is.na(x))
  events1 <- sum(g == g1 & x == 1L, na.rm = TRUE)
  events2 <- sum(g == g2 & x == 1L, na.rm = TRUE)

  rd <- risk_difference_ci(events1, total1, events2, total2)

  ans <- data.table(
    Endpoint = unname(safety_labels[v]),
    `Absolute difference, % (95% CI)` = format_difference(rd),
    `P value` = fmt_p(binary_p(x, g))
  )
  ans[, (g1) := format_prop(events1, total1)]
  ans[, (g2) := format_prop(events2, total2)]
  ans
}), use.names = TRUE, fill = TRUE)

setcolorder(
  table4,
  c(
    "Endpoint", g1, g2,
    "Absolute difference, % (95% CI)", "P value"
  )
)

table4_footer <- paste(
  "Group-specific proportions use Wilson 95% confidence intervals.",
  "Absolute differences use score-based 95% confidence intervals without continuity correction.",
  "P values use Pearson's chi-squared test or Fisher's exact test when expected counts are below 5.",
  safety_population_note,
  intolerance_note,
  synthetic_note
)

## Figure 1: 연구 대상자 흐름

## 추적 중단 사유를 만들지 않고 조기 중도절단으로만 표시한다.
trial_counts <- a[, .(
  Assigned = .N,
  Deaths = sum(allcause_death_event == 1L),
  Early_censored = sum(
    primary_event == 0L &
      admend_mo < 36L &
      allcause_death_event == 0L
  ),
  ITT = .N
), by = group]

figure1 <- ggplot() +
  annotate(
    "rect",
    xmin = -2.5, xmax = 2.5, ymin = 9.1, ymax = 10.3,
    fill = "#F2D7D9", colour = "#7A5558"
  ) +
  annotate(
    "text",
    x = 0, y = 9.7,
    label = sprintf("%d participants underwent random assignment", nrow(a)),
    size = 5.3, fontface = "bold"
  ) +
  annotate("segment", x = 0, xend = -3.2, y = 9.1, yend = 8.1, colour = "#7A5558") +
  annotate("segment", x = 0, xend = 3.2, y = 9.1, yend = 8.1, colour = "#7A5558") +
  annotate(
    "rect",
    xmin = -5.4, xmax = -1.0, ymin = 6.9, ymax = 8.1,
    fill = "#F7E7E8", colour = "#7A5558"
  ) +
  annotate(
    "rect",
    xmin = 1.0, xmax = 5.4, ymin = 6.9, ymax = 8.1,
    fill = "#F7E7E8", colour = "#7A5558"
  ) +
  annotate(
    "text",
    x = -3.2, y = 7.5,
    label = sprintf(
      "%d assigned to\n%s",
      trial_counts[group == g1, Assigned],
      g1
    ),
    size = 4.4
  ) +
  annotate(
    "text",
    x = 3.2, y = 7.5,
    label = sprintf(
      "%d assigned to\n%s",
      trial_counts[group == g2, Assigned],
      g2
    ),
    size = 4.4
  ) +
  annotate("segment", x = -3.2, xend = -3.2, y = 6.9, yend = 5.8, colour = "#7A5558") +
  annotate("segment", x = 3.2, xend = 3.2, y = 6.9, yend = 5.8, colour = "#7A5558") +
  annotate(
    "text",
    x = -3.2, y = 5.1,
    label = sprintf(
      "%d died\n%d censored before 3 years,\nreason unavailable",
      trial_counts[group == g1, Deaths],
      trial_counts[group == g1, Early_censored]
    ),
    size = 4.1
  ) +
  annotate(
    "text",
    x = 3.2, y = 5.1,
    label = sprintf(
      "%d died\n%d censored before 3 years,\nreason unavailable",
      trial_counts[group == g2, Deaths],
      trial_counts[group == g2, Early_censored]
    ),
    size = 4.1
  ) +
  annotate("segment", x = -3.2, xend = -3.2, y = 4.2, yend = 3.2, colour = "#7A5558") +
  annotate("segment", x = 3.2, xend = 3.2, y = 4.2, yend = 3.2, colour = "#7A5558") +
  annotate(
    "rect",
    xmin = -5.1, xmax = -1.3, ymin = 2.0, ymax = 3.2,
    fill = "#F2D7D9", colour = "#7A5558"
  ) +
  annotate(
    "rect",
    xmin = 1.3, xmax = 5.1, ymin = 2.0, ymax = 3.2,
    fill = "#F2D7D9", colour = "#7A5558"
  ) +
  annotate(
    "text",
    x = -3.2, y = 2.6,
    label = sprintf(
      "%d included in\nintention-to-treat analysis",
      trial_counts[group == g1, ITT]
    ),
    size = 4.4
  ) +
  annotate(
    "text",
    x = 3.2, y = 2.6,
    label = sprintf(
      "%d included in\nintention-to-treat analysis",
      trial_counts[group == g2, ITT]
    ),
    size = 4.4
  ) +
  annotate(
    "text",
    x = 0, y = 0.8,
    label = paste(
      "Allocated-treatment receipt, safety-population status,",
      "withdrawal, and loss-to-follow-up reasons were unavailable.",
      "LDL-C laboratory missingness was not treated as trial discontinuation."
    ),
    size = 3.5, colour = "#444444"
  ) +
  coord_cartesian(xlim = c(-6, 6), ylim = c(0.2, 10.7), clip = "off") +
  theme_void() +
  labs(title = "Figure 1. Trial profile")

## Figure 2: 일차 평가변수 누적발생률

## 생존확률을 1-S(t)로 변환해 누적발생률을 그린다.
primary_fit <- survfit(
  Surv(primary_followup_mo, primary_event) ~ group,
  data = primary_survival_data
)

primary_summary <- summary(primary_fit)
curve_data <- data.table(
  time = primary_summary$time / 12,
  cumulative_incidence = 1 - primary_summary$surv,
  group = sub("^group=", "", primary_summary$strata)
)

curve_data <- rbind(
  data.table(
    time = 0,
    cumulative_incidence = 0,
    group = group_levels
  ),
  curve_data,
  use.names = TRUE
)
curve_data[, group := factor(group, levels = group_levels)]

risk_times <- c(0, 12, 24, 36)
risk_summary <- summary(primary_fit, times = risk_times, extend = TRUE)
risk_data <- data.table(
  time = risk_summary$time / 12,
  n_risk = risk_summary$n.risk,
  group = factor(
    sub("^group=", "", risk_summary$strata),
    levels = group_levels
  )
)

primary_annotation <- sprintf(
  "Absolute difference %.2f%% (90%% CI %.2f to %.2f)\nHR %.2f (95%% CI %.2f to %.2f); log-rank p=%s",
  primary_rd["estimate"] * 100,
  primary_rd["lower"] * 100,
  primary_rd["upper"] * 100,
  primary_hr["estimate"],
  primary_hr["lower"],
  primary_hr["upper"],
  fmt_p(primary_logrank_p)
)

figure2_curve <- ggplot(
  curve_data,
  aes(
    x = time,
    y = cumulative_incidence,
    colour = group
  )
) +
  geom_step(linewidth = 1.1) +
  annotate(
    "text",
    x = 1.8,
    y = 0.145,
    label = primary_annotation,
    hjust = 0,
    size = 3.7
  ) +
  scale_x_continuous(breaks = 0:3, limits = c(0, 3)) +
  scale_y_continuous(
    limits = c(0, 0.17),
    labels = scales::percent_format(accuracy = 1)
  ) +
  scale_colour_manual(
    values = setNames(c("#A63D40", "#314E89"), group_levels)
  ) +
  labs(
    title = "Figure 2. Cumulative incidence of the primary endpoint",
    x = "Time since randomisation, years",
    y = "Cumulative incidence",
    colour = NULL
  ) +
  theme_minimal(base_size = 12) +
  theme(
    legend.position = "top",
    panel.grid.minor = element_blank()
  )

figure2_risk <- ggplot(
  risk_data,
  aes(x = time, y = group, label = n_risk, colour = group)
) +
  geom_text(size = 4) +
  scale_x_continuous(breaks = 0:3, limits = c(0, 3)) +
  scale_colour_manual(
    values = setNames(c("#A63D40", "#314E89"), group_levels),
    guide = "none"
  ) +
  labs(x = NULL, y = "Number at risk") +
  theme_minimal(base_size = 10) +
  theme(
    panel.grid = element_blank(),
    axis.text.x = element_blank(),
    axis.ticks.x = element_blank()
  )

figure2 <- figure2_curve / figure2_risk +
  plot_layout(heights = c(4, 1))

## Figure 3: 하위 집단 분석

## 하위 집단별 절대위험도 차이와 상호작용 p값을 계산한다.
subgroup_results <- rbindlist(lapply(varlist$Subgroup, function(v) {
  dd_all <- out[!is.na(get(v))]
  subgroup_value <- droplevels(dd_all[[v]])
  event_value <- as.integer(as.character(dd_all$primary_event))

  interaction_p <- tryCatch({
    interaction_data <- data.frame(
      event = event_value,
      group = dd_all$group,
      subgroup = subgroup_value
    )
    reduced <- glm(
      event ~ group + subgroup,
      family = binomial(),
      data = interaction_data
    )
    full <- glm(
      event ~ group * subgroup,
      family = binomial(),
      data = interaction_data
    )
    anova(reduced, full, test = "LRT")$'Pr(>Chi)'[2]
  }, error = function(e) NA_real_)

  rbindlist(lapply(levels(subgroup_value), function(level_value) {
    dd <- dd_all[as.character(get(v)) == level_value]
    event <- as.integer(as.character(dd$primary_event))

    total1 <- sum(dd$group == g1)
    total2 <- sum(dd$group == g2)
    events1 <- sum(dd$group == g1 & event == 1L)
    events2 <- sum(dd$group == g2 & event == 1L)
    rd <- risk_difference_ci(
      events1,
      total1,
      events2,
      total2,
      conf.level = 0.90
    )

    data.table(
      Subgroup = unname(subgroup_labels[v]),
      Level = level_value,
      Combination = sprintf("%d/%d", events1, total1),
      Monotherapy = sprintf("%d/%d", events2, total2),
      estimate = unname(rd["estimate"]) * 100,
      lower = unname(rd["lower"]) * 100,
      upper = unname(rd["upper"]) * 100,
      `P interaction` = interaction_p
    )
  }))
}), use.names = TRUE, fill = TRUE)

subgroup_results[, `Absolute difference (90% CI)` := sprintf(
  "%.2f (%.2f to %.2f)",
  estimate,
  lower,
  upper
)]
subgroup_results[, `P interaction` := fmt_p(`P interaction`)]

subgroup_plot_data <- copy(subgroup_results)
subgroup_plot_data[, plot_label := paste0(
  Subgroup,
  ": ",
  Level,
  "   ",
  Combination,
  " vs ",
  Monotherapy
)]
subgroup_plot_data[, plot_order := .I]

figure3 <- ggplot(
  subgroup_plot_data,
  aes(
    x = estimate,
    y = reorder(plot_label, -plot_order)
  )
) +
  geom_vline(xintercept = 0, colour = "#555555", linewidth = 0.6) +
  geom_vline(
    xintercept = 2,
    colour = "#A63D40",
    linetype = "dashed",
    linewidth = 0.8
  ) +
  geom_errorbar(
    aes(xmin = lower, xmax = upper),
    orientation = "y",
    width = 0.16,
    colour = "#314E89"
  ) +
  geom_point(size = 2.5, colour = "#314E89") +
  scale_x_continuous(
    limits = c(
      min(-12, floor(min(subgroup_plot_data$lower, na.rm = TRUE))),
      max(12, ceiling(max(subgroup_plot_data$upper, na.rm = TRUE)))
    )
  ) +
  labs(
    title = "Figure 3. Subgroup analyses for the primary endpoint",
    subtitle = "Dashed line: prespecified 2.0 percentage-point non-inferiority margin",
    x = "Absolute difference, percentage points (90% CI)",
    y = NULL,
    caption = "Negative values favour combination therapy; positive values favour monotherapy."
  ) +
  theme_minimal(base_size = 10) +
  theme(
    panel.grid.minor = element_blank(),
    panel.grid.major.y = element_blank()
  )

## 표를 Excel로 저장

## 표와 footer를 시트별로 묶은 뒤 반복 저장한다.
table_outputs <- list(
  Table1_Baseline = table1,
  Table2_Clinical = table2,
  Table3_LDL70 = table3_ldl70,
  Table3_LDL55 = table3_ldl55,
  Table4_Safety = table4,
  Figure3_Subgroup_data = subgroup_results,
  Cox_PH_assumption = primary_ph_table
)

table_titles <- c(
  Table1_Baseline = "Table 1. Baseline characteristics of the intention-to-treat population",
  Table2_Clinical = "Table 2. Three-year clinical endpoints in the intention-to-treat population",
  Table3_LDL70 = "Table 3. LDL-C <70 mg/dL outcomes in the intention-to-treat population",
  Table3_LDL55 = "Post-hoc table. LDL-C <55 mg/dL outcomes in the intention-to-treat population",
  Table4_Safety = "Table 4. Safety endpoints among all randomised participants",
  Figure3_Subgroup_data = "Subgroup analyses for the primary endpoint",
  Cox_PH_assumption = "Proportional-hazards assumption for the primary Cox model"
)

table_footers <- c(
  Table1_Baseline = table1_footer,
  Table2_Clinical = table2_footer,
  Table3_LDL70 = table3_footer,
  Table3_LDL55 = table3_footer,
  Table4_Safety = table4_footer,
  Figure3_Subgroup_data = paste(
    "Absolute differences use score-based 90% confidence intervals.",
    "Interaction p values use likelihood-ratio tests from logistic regression models.",
    synthetic_note
  ),
  Cox_PH_assumption = paste(
    "The proportional-hazards assumption was assessed using cox.zph with transform = 'identity'.",
    synthetic_note
  )
)

wb <- createWorkbook()

title_style <- createStyle(
  fontName = "DejaVu Sans",
  fontSize = 11,
  textDecoration = "bold",
  halign = "left",
  wrapText = TRUE,
  valign = "top"
)
header_style <- createStyle(
  fontName = "DejaVu Sans",
  fontSize = 9,
  textDecoration = "bold",
  border = c("top", "bottom"),
  borderStyle = "thick",
  halign = "center",
  valign = "top",
  wrapText = TRUE
)
body_style <- createStyle(
  fontName = "DejaVu Sans",
  fontSize = 9,
  valign = "top",
  wrapText = TRUE
)
footer_style <- createStyle(
  fontName = "DejaVu Sans",
  fontSize = 8,
  textDecoration = "italic",
  halign = "left",
  valign = "top",
  wrapText = TRUE
)

for (nm in names(table_outputs)) {
  df <- as.data.frame(table_outputs[[nm]], check.names = FALSE)
  addWorksheet(wb, nm, gridLines = TRUE)

  writeData(
    wb,
    nm,
    table_titles[[nm]],
    startRow = 1,
    startCol = 1,
    colNames = FALSE
  )
  mergeCells(wb, nm, cols = seq_len(ncol(df)), rows = 1)

  writeData(
    wb,
    nm,
    df,
    startRow = 3,
    startCol = 1,
    rowNames = FALSE
  )

  footer_row <- nrow(df) + 5L
  writeData(
    wb,
    nm,
    table_footers[[nm]],
    startRow = footer_row,
    startCol = 1,
    colNames = FALSE
  )
  mergeCells(wb, nm, cols = seq_len(ncol(df)), rows = footer_row)

  addStyle(
    wb, nm, title_style,
    rows = 1, cols = seq_len(ncol(df)),
    gridExpand = TRUE
  )
  addStyle(
    wb, nm, header_style,
    rows = 3, cols = seq_len(ncol(df)),
    gridExpand = TRUE
  )
  addStyle(
    wb, nm, body_style,
    rows = 4:(nrow(df) + 3L), cols = seq_len(ncol(df)),
    gridExpand = TRUE
  )
  addStyle(
    wb, nm, footer_style,
    rows = footer_row, cols = seq_len(ncol(df)),
    gridExpand = TRUE
  )

  setColWidths(wb, nm, cols = seq_len(ncol(df)), widths = "auto")
  freezePane(wb, nm, firstActiveRow = 4)
}

saveWorkbook(
  wb,
  file.path(results_dir, "RACING_analysis_tables.xlsx"),
  overwrite = TRUE
)

## 그림 객체와 슬라이드 크기 설정

plot_names <- c(
  "Figure1_trial_profile",
  "Figure2_primary_endpoint",
  "Figure3_subgroup"
)
plot_list <- setNames(
  lapply(c("figure1", "figure2", "figure3"), get),
  plot_names
)

plot_sizes <- list(
  Figure1_trial_profile = c(13.33, 7.5),
  Figure2_primary_endpoint = c(13.33, 8.5),
  Figure3_subgroup = c(13.33, 10.0)
)

## 그림을 PowerPoint로 저장

## 그림 비율을 유지하면서 빈 슬라이드 안에 맞춰 배치한다.
figure_pptx <- read_pptx()
ppt_size <- slide_size(figure_pptx)
ppt_margin <- 0.25
ppt_available_width <- ppt_size$width - 2 * ppt_margin
ppt_available_height <- ppt_size$height - 2 * ppt_margin

for (nm in names(plot_list)) {
  plot_aspect <- plot_sizes[[nm]][1] / plot_sizes[[nm]][2]
  available_aspect <- ppt_available_width / ppt_available_height

  if (available_aspect > plot_aspect) {
    plot_height <- ppt_available_height
    plot_width <- plot_height * plot_aspect
  } else {
    plot_width <- ppt_available_width
    plot_height <- plot_width / plot_aspect
  }

  plot_left <- (ppt_size$width - plot_width) / 2
  plot_top <- (ppt_size$height - plot_height) / 2

  figure_pptx <- add_slide(
    figure_pptx,
    layout = "Blank",
    master = "Office Theme"
  )
  figure_pptx <- ph_with(
    figure_pptx,
    value = rvg::dml(ggobj = plot_list[[nm]]),
    location = ph_location(
      left = plot_left,
      top = plot_top,
      width = plot_width,
      height = plot_height
    )
  )
}

print(
  figure_pptx,
  target = file.path(results_dir, "RACING_figures.pptx")
)

cat(
  "Analysis complete\n",
  "Tables:", file.path(results_dir, "RACING_analysis_tables.xlsx"), "\n",
  "Figures:", file.path(results_dir, "RACING_figures.pptx"), "\n",
  "Primary non-inferiority:", noninferior, "\n"
)
