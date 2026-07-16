## RACING 합성 데이터 분석 준비
## 원자료를 불러오고 분석 변수와 라벨을 만든다.

suppressPackageStartupMessages({
  library(data.table)
  library(jstable)
  library(survival)
  library(ggplot2)
  library(openxlsx)
  library(officer)
  library(rvg)
  library(patchwork)
})

command_args <- commandArgs(trailingOnly = FALSE)
file_arg <- sub("^--file=", "", grep("^--file=", command_args, value = TRUE))

## 실행 위치를 기준으로 데이터와 결과 폴더 경로를 잡는다.
project_dir <- if (length(file_arg) == 1L) {
  dirname(normalizePath(file_arg, winslash = "/", mustWork = TRUE))
} else {
  normalizePath(getwd(), winslash = "/", mustWork = TRUE)
}

data_path <- file.path(project_dir, "RACING_synthetic_data.csv")
results_dir <- file.path(project_dir, "results")

stopifnot(file.exists(data_path))
dir.create(results_dir, showWarnings = FALSE, recursive = TRUE)

a <- fread(data_path, na.strings = c("", "NA", "N/A"))
stopifnot(nrow(a) == 3780L, ncol(a) == 57L)

## 기본 변수 형식 정리
## 치료군 순서를 논문 표와 그림에서 사용할 순서로 고정한다.
a[, group := factor(
  group,
  levels = c("Combination", "Monotherapy"),
  labels = c(
    "Moderate-intensity statin + ezetimibe",
    "High-intensity statin monotherapy"
  )
)]

event_vars <- grep("_event$", names(a), value = TRUE)
for (v in event_vars) {
  set(a, j = v, value = as.integer(a[[v]]))
}

## 사건이 없으면 행정 추적 종료 시점을 관찰시간으로 사용한다.
a[, admend_mo := as.integer(admend_mo)]
a[, primary_time_mo := as.integer(primary_time_mo)]

a[, primary_followup_mo := fifelse(
  primary_event == 1L,
  primary_time_mo,
  admend_mo
)]

## LDL-C 목표 달성과 하위 집단 변수 생성
## 1·2·3년 LDL-C가 70 또는 55 mg/dL 미만인지 표시한다.
for (tp in c("y1", "y2", "y3")) {
  ldl_var <- paste0("LDL_", tp)

  a[, (paste0("LDL70_", tp)) := fifelse(
    is.na(get(ldl_var)),
    NA_integer_,
    as.integer(get(ldl_var) < 70)
  )]

  a[, (paste0("LDL55_", tp)) := fifelse(
    is.na(get(ldl_var)),
    NA_integer_,
    as.integer(get(ldl_var) < 55)
  )]
}

a[, Baseline_LDL70 := factor(
  fifelse(Baseline_LDL < 70, "Yes", "No"),
  levels = c("No", "Yes")
)]

a[, Age60 := factor(
  fifelse(Age < 60, "<60", "≥60"),
  levels = c("<60", "≥60")
)]

a[, Sex_f := factor(
  Sex,
  levels = c("Male", "Female"),
  labels = c("Men", "Women")
)]

a[, BMI25 := factor(
  fifelse(BMI < 25, "<25", "≥25"),
  levels = c("<25", "≥25")
)]

for (v in c(
  "Diabetes", "Hypertension", "CKD",
  "Prior_MI", "Prior_stroke", "PAD"
)) {
  a[, (paste0(v, "_f")) := factor(
    fifelse(get(v) == 1L, "Yes", "No"),
    levels = c("No", "Yes")
  )]
}

a[, Baseline_LDL_100 := factor(
  fifelse(Baseline_LDL < 100, "<100", "≥100"),
  levels = c("<100", "≥100")
)]

intolerance_vars <- c(
  "muscle_ae", "myalgia", "myopathy", "myonecrosis",
  "hepatic_ae", "ck_elevation", "fasting_glucose_elevation"
)

## 불내성 관련 안전성 사건이 하나라도 있으면 1로 둔다.
a[, intolerance_stop_reduce := as.integer(
  rowSums(.SD == 1L, na.rm = TRUE) > 0L
), .SDcols = intolerance_vars]

## 분석 목적별 변수 목록
varlist <- list(
  Base = c(
    "group", "Age", "Sex", "Height", "Weight", "BMI",
    "Prior_MI", "Prior_PCI", "Prior_CABG", "ACS",
    "Prior_stroke", "CKD", "ESRD_dialysis", "PAD",
    "Hypertension", "Diabetes", "Diabetes_insulin", "Smoking",
    "Baseline_LDL", "Baseline_LDL70",
    "Pre_HI_statin", "Pre_HI_statin_ezetimibe",
    "Pre_MI_statin", "Pre_MI_statin_ezetimibe",
    "Pre_LI_statin", "Pre_none"
  ),
  Followup = "admend_mo",
  Time = c("primary_time_mo", "primary_followup_mo"),
  Event = "primary_event",
  Clinical = c(
    "primary_event", "secondary_event", "cv_death_event",
    "allcause_death_event", "mace_event",
    "coronary_revasc_event", "peripheral_revasc_event",
    "cv_hosp_event", "hf_hosp_event",
    "nonfatal_stroke_event", "ischemic_stroke_event",
    "hemorrhagic_stroke_event"
  ),
  LDL = c(
    "LDL_y1", "LDL_y2", "LDL_y3",
    "LDL70_y1", "LDL70_y2", "LDL70_y3",
    "LDL55_y1", "LDL55_y2", "LDL55_y3"
  ),
  Safety = c(
    "intolerance_stop_reduce",
    "new_diabetes", "new_diabetes_med",
    "muscle_ae", "myalgia", "myopathy", "myonecrosis",
    "hepatic_ae", "ck_elevation", "fasting_glucose_elevation",
    "gallbladder_ae", "major_bleeding", "cancer",
    "neurocognitive_disorder", "cataract_surgery"
  ),
  Subgroup = c(
    "Age60", "Sex_f", "BMI25", "Diabetes_f",
    "Hypertension_f", "CKD_f", "Prior_MI_f",
    "Prior_stroke_f", "PAD_f", "Baseline_LDL_100"
  )
)

analysis_vars <- unique(unlist(varlist, use.names = FALSE))

## ID를 제외하고 실제 분석에 사용할 변수만 모은다.
out <- copy(a[, .SD, .SDcols = analysis_vars])

## 분석용 자료형 정리
binary_base_vars <- c(
  "Prior_MI", "Prior_PCI", "Prior_CABG", "ACS",
  "Prior_stroke", "CKD", "ESRD_dialysis", "PAD",
  "Hypertension", "Diabetes", "Diabetes_insulin", "Smoking",
  "Pre_HI_statin", "Pre_HI_statin_ezetimibe",
  "Pre_MI_statin", "Pre_MI_statin_ezetimibe",
  "Pre_LI_statin", "Pre_none"
)

binary_vars <- unique(c(
  binary_base_vars,
  event_vars,
  grep("^LDL(70|55)_", names(out), value = TRUE),
  varlist$Safety
))

## 0/1 변수는 한쪽 값이 없어도 No/Yes 두 수준을 유지한다.
for (v in intersect(binary_vars, names(out))) {
  out[, (v) := factor(
    as.character(get(v)),
    levels = c("0", "1")
  )]
}

out[, Sex := factor(Sex, levels = c("Female", "Male"))]

continuous_vars <- c(
  "Age", "Height", "Weight", "BMI", "Baseline_LDL",
  "admend_mo", "primary_time_mo", "primary_followup_mo",
  "LDL_y1", "LDL_y2", "LDL_y3"
)

for (v in intersect(continuous_vars, names(out))) {
  set(out, j = v, value = as.numeric(out[[v]]))
}

## 결과표에 사용할 변수 라벨
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
  Baseline_LDL70 = "Baseline LDL-C <70 mg/dL",
  Pre_HI_statin = "High-intensity statin",
  Pre_HI_statin_ezetimibe = "High-intensity statin + ezetimibe",
  Pre_MI_statin = "Moderate-intensity statin",
  Pre_MI_statin_ezetimibe = "Moderate-intensity statin + ezetimibe",
  Pre_LI_statin = "Low-intensity statin",
  Pre_none = "No lipid-lowering treatment",
  admend_mo = "Administrative end of follow-up, months",
  primary_time_mo = "Observed primary-event time, months",
  primary_followup_mo = "Primary endpoint follow-up, months",
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
  hemorrhagic_stroke_event = "Haemorrhagic stroke",
  LDL_y1 = "LDL-C at 1 year, mg/dL",
  LDL_y2 = "LDL-C at 2 years, mg/dL",
  LDL_y3 = "LDL-C at 3 years, mg/dL",
  LDL70_y1 = "LDL-C <70 mg/dL at 1 year",
  LDL70_y2 = "LDL-C <70 mg/dL at 2 years",
  LDL70_y3 = "LDL-C <70 mg/dL at 3 years",
  LDL55_y1 = "LDL-C <55 mg/dL at 1 year",
  LDL55_y2 = "LDL-C <55 mg/dL at 2 years",
  LDL55_y3 = "LDL-C <55 mg/dL at 3 years",
  intolerance_stop_reduce = "Intolerance-related discontinuation or dose reduction (derived)",
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
  cataract_surgery = "Cataract surgery",
  Age60 = "Age, years",
  Sex_f = "Sex",
  BMI25 = "Body-mass index, kg/m²",
  Diabetes_f = "Diabetes",
  Hypertension_f = "Hypertension",
  CKD_f = "Chronic kidney disease",
  Prior_MI_f = "Previous myocardial infarction",
  Prior_stroke_f = "Previous ischaemic stroke",
  PAD_f = "Previous peripheral artery disease",
  Baseline_LDL_100 = "Baseline LDL-C, mg/dL"
)

out.label <- jstable::mk.lev(out)

## 결과표에 원시 변수명 대신 읽기 쉬운 라벨을 적용한다.
for (v in names(out)) {
  out.label[
    variable == v,
    var_label := unname(variable_labels[v])
  ]
}

for (v in intersect(binary_vars, names(out))) {
  out.label[
    variable == v,
    val_label := c("No", "Yes")
  ]
}

## 반복 측정 LDL-C 분석용 장기형 데이터
## 연도별 LDL-C 열을 한 행씩 쌓아 장기형 자료로 바꾼다.
out.long <- rbindlist(lapply(seq_len(3L), function(yr) {
  ldl_var <- paste0("LDL_y", yr)
  ldl70_var <- paste0("LDL70_y", yr)
  ldl55_var <- paste0("LDL55_y", yr)

  a[, .(
    ID,
    group,
    timepoint = factor(
      paste0(yr, if (yr == 1L) " year" else " years"),
      levels = c("1 year", "2 years", "3 years")
    ),
    LDL = get(ldl_var),
    LDL70 = factor(
      as.character(get(ldl70_var)),
      levels = c("0", "1")
    ),
    LDL55 = factor(
      as.character(get(ldl55_var)),
      levels = c("0", "1")
    )
  )]
}))

out.long.label <- jstable::mk.lev(out.long)
long_labels <- c(
  ID = "Participant ID",
  group = "Treatment group",
  timepoint = "Timepoint",
  LDL = "LDL-C, mg/dL",
  LDL70 = "LDL-C <70 mg/dL",
  LDL55 = "LDL-C <55 mg/dL"
)

for (v in names(long_labels)) {
  out.long.label[
    variable == v,
    var_label := unname(long_labels[v])
  ]
}

for (v in c("LDL70", "LDL55")) {
  out.long.label[
    variable == v,
    val_label := c("No", "Yes")
  ]
}

group_levels <- levels(out$group)

base_labels <- variable_labels[varlist$Base]
clinical_labels <- variable_labels[varlist$Clinical]
safety_labels <- variable_labels[varlist$Safety]
subgroup_labels <- variable_labels[varlist$Subgroup]

synthetic_note <- "Synthetic example data; not original RACING patient-level data."
safety_population_note <- paste(
  "Safety endpoints were summarised among all randomised participants",
  "because allocated-treatment receipt and safety population variables",
  "were unavailable in the synthetic data."
)
intolerance_note <- paste(
  "The intolerance-discontinuation row was derived from",
  "intolerance-related safety endpoints in the synthetic data."
)
