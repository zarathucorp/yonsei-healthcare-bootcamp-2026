## RACING synthetic data: global.R
## Inputs: general_AGENTS.md, RACING Lancet PDF structure, RACING_synthetic_data.xlsx
## Output objects: a, varlist, out, out.label, out.long, out.long.label

library(data.table);library(magrittr);library(jstable);library(openxlsx)

script_file <- tryCatch(normalizePath(sys.frame(1)$ofile, winslash = "/", mustWork = TRUE), error = function(e) NA_character_)
if (is.na(script_file)) {
  cmd_file <- grep("^--file=", commandArgs(FALSE), value = TRUE)
  if (length(cmd_file) > 0) script_file <- normalizePath(sub("^--file=", "", cmd_file[1]), winslash = "/", mustWork = TRUE)
}
if (is.na(script_file)) script_file <- normalizePath("code/RACING/global.R", winslash = "/", mustWork = TRUE)
code_dir <- dirname(script_file)
project_dir <- normalizePath(file.path(code_dir, "..", ".."), winslash = "/", mustWork = TRUE)
results_dir <- code_dir
figures_dir <- code_dir

input_file <- file.path(code_dir, "RACING_synthetic_data.xlsx")
if (!file.exists(input_file)) stop("RACING_synthetic_data.xlsx not found in code/RACING")

a <- openxlsx::read.xlsx(input_file, sheet = 1, check.names = TRUE) %>% data.table(check.names = TRUE)
stopifnot(nrow(a) == 3780L)

## Clean source variables before varlist/out
a[, ID := as.integer(ID)]
a[, group := factor(group, levels = c("Combination", "Monotherapy"))]
a[, Age := as.integer(Age)]
a[, admend_mo := as.numeric(admend_mo)]
a[, primary_time_mo := as.numeric(primary_time_mo)]

binary_vars <- intersect(c(
  grep("_event$", names(a), value = TRUE),
  "Prior_MI", "Prior_PCI", "Prior_CABG", "ACS", "Prior_stroke", "CKD", "ESRD_dialysis", "PAD",
  "Hypertension", "Diabetes", "Diabetes_insulin", "Smoking",
  "Pre_HI_statin", "Pre_HI_statin_ezetimibe", "Pre_MI_statin", "Pre_MI_statin_ezetimibe", "Pre_LI_statin", "Pre_none",
  "new_diabetes", "new_diabetes_med", "muscle_ae", "myalgia", "myopathy", "myonecrosis", "hepatic_ae",
  "ck_elevation", "fasting_glucose_elevation", "gallbladder_ae", "major_bleeding", "cancer",
  "neurocognitive_disorder", "cataract_surgery"
), names(a))
for (v in binary_vars) set(a, j = v, value = as.integer(a[[v]]))

stopifnot(anyDuplicated(a$ID) == 0L, all(!is.na(a$group)))
stopifnot(all(is.na(a$primary_time_mo) == (a$primary_event == 0L)))
stopifnot(all(a[primary_event == 1L, primary_time_mo] <= a[primary_event == 1L, admend_mo]))

## Derived variables before varlist/out
for (yr in 1:3) {
  ldl <- paste0("LDL_y", yr)
  a[, (paste0("LDL70_y", yr)) := fifelse(is.na(get(ldl)), NA_integer_, as.integer(get(ldl) < 70))]
  a[, (paste0("LDL55_y", yr)) := fifelse(is.na(get(ldl)), NA_integer_, as.integer(get(ldl) < 55))]
}

a[, Age60 := factor(fifelse(Age < 60, "<60", "≥60"), levels = c("<60", "≥60"))]
a[, BMI25 := factor(fifelse(BMI < 25, "<25", "≥25"), levels = c("<25", "≥25"))]
a[, Baseline_LDL_100 := factor(fifelse(Baseline_LDL < 100, "<100", "≥100"), levels = c("<100", "≥100"))]
a[, Sex_subgroup := factor(fifelse(Sex == "Male", "Men", "Women"), levels = c("Men", "Women"))]
for (v in c("Diabetes", "Hypertension", "CKD", "Prior_MI", "Prior_stroke", "PAD")) {
  a[, (paste0(v, "_subgroup")) := factor(fifelse(get(v) == 1L, "Yes", "No"), levels = c("Yes", "No"))]
}

intolerance_vars <- c("muscle_ae", "myalgia", "myopathy", "myonecrosis", "hepatic_ae", "ck_elevation", "fasting_glucose_elevation")
a[, intolerance_stop_reduce := as.integer(rowSums(.SD == 1, na.rm = TRUE) > 0), .SDcols = intolerance_vars]

varlist <- list(
  ID = "ID",
  Base = c("group", "Age", "Sex", "Height", "Weight", "BMI", "Prior_MI", "Prior_PCI", "Prior_CABG", "ACS",
           "Prior_stroke", "CKD", "ESRD_dialysis", "PAD", "Hypertension", "Diabetes", "Diabetes_insulin",
           "Smoking", "Pre_HI_statin", "Pre_HI_statin_ezetimibe", "Pre_MI_statin", "Pre_MI_statin_ezetimibe",
           "Pre_LI_statin", "Pre_none", "Baseline_LDL"),
  Event = "primary_event",
  Time = "primary_time_mo",
  Followup = "admend_mo",
  Clinical = c("primary_event", "secondary_event", "cv_death_event", "allcause_death_event", "mace_event",
               "coronary_revasc_event", "peripheral_revasc_event", "cv_hosp_event", "hf_hosp_event",
               "nonfatal_stroke_event", "ischemic_stroke_event", "hemorrhagic_stroke_event"),
  LDL = c("LDL_y1", "LDL_y2", "LDL_y3", "LDL70_y1", "LDL70_y2", "LDL70_y3", "LDL55_y1", "LDL55_y2", "LDL55_y3"),
  Safety = c("intolerance_stop_reduce", "new_diabetes", "new_diabetes_med", "muscle_ae", "myalgia", "myopathy", "myonecrosis", "hepatic_ae",
             "ck_elevation", "fasting_glucose_elevation", "gallbladder_ae", "major_bleeding", "cancer",
             "neurocognitive_disorder", "cataract_surgery"),
  Subgroup = c("Age60", "Sex_subgroup", "BMI25", "Diabetes_subgroup", "Hypertension_subgroup", "CKD_subgroup",
               "Prior_MI_subgroup", "Prior_stroke_subgroup", "PAD_subgroup", "Baseline_LDL_100")
)
varlist <- lapply(varlist, function(x) intersect(x, names(a)))
stopifnot(identical(varlist$Event, "primary_event"), identical(varlist$Time, "primary_time_mo"))

out <- a[, .SD, .SDcols = unique(unlist(varlist))]

factor_vars <- names(out)[sapply(out, function(x) length(table(x)) <= 6)]
factor_vars <- setdiff(factor_vars, c(varlist$ID, varlist$Time, varlist$Followup))
out[, (factor_vars) := lapply(.SD, factor), .SDcols = factor_vars]

conti_vars <- setdiff(names(out), c(factor_vars, varlist$ID))
out[, (conti_vars) := lapply(.SD, as.numeric), .SDcols = conti_vars]

out.label <- jstable::mk.lev(out)

vars01 <- sapply(factor_vars, function(v) {
  lv <- sort(unique(na.omit(as.character(out[[v]]))))
  length(lv) > 0 && all(lv %in% c("0", "1"))
})
for (v in names(vars01)[vars01 == TRUE]) {
  out[, (v) := factor(as.character(get(v)), levels = c("0", "1"))]
}
for (v in names(vars01)[vars01 == TRUE]) {
  out.label[variable == v, val_label := c("No", "Yes")]
}

label_map <- c(
  group = "Treatment group", Age = "Age, years", Sex = "Sex", Height = "Height, cm", Weight = "Weight, kg",
  BMI = "Body-mass index, kg/m²", Prior_MI = "Previous myocardial infarction",
  Prior_PCI = "Previous percutaneous coronary intervention", Prior_CABG = "Previous coronary bypass graft surgery",
  ACS = "Acute coronary syndrome", Prior_stroke = "Previous ischaemic stroke", CKD = "Chronic kidney disease",
  ESRD_dialysis = "End-stage kidney disease on dialysis", PAD = "Peripheral artery disease",
  Hypertension = "Hypertension", Diabetes = "Diabetes", Diabetes_insulin = "Diabetes with insulin treatment",
  Smoking = "Current smoker", Pre_HI_statin = "High-intensity statin",
  Pre_HI_statin_ezetimibe = "High-intensity statin with ezetimibe", Pre_MI_statin = "Moderate-intensity statin",
  Pre_MI_statin_ezetimibe = "Moderate-intensity statin with ezetimibe", Pre_LI_statin = "Low-intensity statin",
  Pre_none = "None", Baseline_LDL = "Serum LDL cholesterol concentration, mg/dL",
  primary_event = "Primary endpoint", intolerance_stop_reduce = "Discontinuation or dose reduction of study drug due to intolerance", primary_time_mo = "Time to primary endpoint, months", admend_mo = "Follow-up time, months"
)
for (v in intersect(names(label_map), out.label$variable)) out.label[variable == v, var_label := unname(label_map[v])]

out.long <- rbindlist(lapply(1:3, function(yr) {
  out[, .(
    ID = ID,
    group = group,
    timepoint = factor(paste0(yr, ifelse(yr == 1, " year", " years")), levels = c("1 year", "2 years", "3 years")),
    LDL = get(paste0("LDL_y", yr)),
    LDL70 = factor(as.character(get(paste0("LDL70_y", yr))), levels = c("0", "1")),
    LDL55 = factor(as.character(get(paste0("LDL55_y", yr))), levels = c("0", "1"))
  )]
}))
out.long.label <- jstable::mk.lev(out.long)
out.long.label[variable == "group", var_label := "Treatment group"]
out.long.label[variable == "timepoint", var_label := "Timepoint"]
out.long.label[variable == "LDL", var_label := "LDL-C, mg/dL"]
for (v in c("LDL70", "LDL55")) out.long.label[variable == v, val_label := c("No", "Yes")]

synthetic_note <- "Synthetic example data; not original RACING patient-level data."
group_labels <- c(Combination = "Moderate-intensity statin with ezetimibe combination therapy", Monotherapy = "High-intensity statin monotherapy")
clinical_labels <- c(
  primary_event = "Composite of cardiovascular death, major cardiovascular event, or non-fatal stroke",
  secondary_event = "Composite of all-cause death, major cardiovascular event, or non-fatal stroke",
  cv_death_event = "Cardiovascular death", allcause_death_event = "All-cause death",
  mace_event = "Major cardiovascular events", coronary_revasc_event = "Coronary artery revascularisation",
  peripheral_revasc_event = "Peripheral artery revascularisation", cv_hosp_event = "Hospitalisation for cardiovascular events",
  hf_hosp_event = "Hospitalisation for heart failure", nonfatal_stroke_event = "Non-fatal stroke",
  ischemic_stroke_event = "Ischaemic stroke", hemorrhagic_stroke_event = "Haemorrhagic stroke"
)
safety_labels <- c(
  intolerance_stop_reduce = "Discontinuation or dose reduction of study drug due to intolerance",
  new_diabetes = "New-onset diabetes", new_diabetes_med = "New-onset diabetes with anti-diabetic medication initiation",
  muscle_ae = "Muscle-related adverse events", myalgia = "   Myalgia", myopathy = "   Myopathy", myonecrosis = "   Myonecrosis",
  hepatic_ae = "Hepatic-related adverse events", ck_elevation = "   Creatine kinase elevation",
  fasting_glucose_elevation = "   Fasting glucose concentration elevation", gallbladder_ae = "Gallbladder-related adverse events",
  major_bleeding = "Major bleeding", cancer = "Cancer diagnosis", neurocognitive_disorder = "New-onset neurocognitive disorder",
  cataract_surgery = "Cataract surgery"
)
subgroup_labels <- c(
  Age60 = "Age, years", Sex_subgroup = "Sex", BMI25 = "Body-mass index, kg/m²", Diabetes_subgroup = "Diabetes",
  Hypertension_subgroup = "Hypertension", CKD_subgroup = "Chronic kidney disease", Prior_MI_subgroup = "Previous myocardial infarction",
  Prior_stroke_subgroup = "Previous stroke", PAD_subgroup = "Previous peripheral artery disease", Baseline_LDL_100 = "Baseline LDL cholesterol, mg/dL"
)
