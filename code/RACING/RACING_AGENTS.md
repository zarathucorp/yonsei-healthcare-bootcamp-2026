# RACING_AGENTS.md

이 문서는 RACING trial 강의자료용 분석 산출물을 만들기 위한 전용 지침이다. 사용자는 실제 RACING 원자료가 아니라 **실제 자료처럼 만든 3,780명 synthetic patient-level data**를 제공할 수 있다. 이 경우 목표는 원 논문 값을 정확히 복제하는 것이 아니라, RACING trial의 구조에 맞춰 `global.R`부터 정리하고 같은 방식의 표와 그림을 재현하는 것이다.

목표 산출물은 `docs/2026-07-21-RCT-RACING/` 안의 다음 7개 파일이다.

- `RACING_Figure1.png`: participant flow / study design
- `RACING_Table1.png`: baseline characteristics
- `RACING_Table2.png`: 3-year clinical endpoints
- `RACING_Figure2.png`: Kaplan-Meier cumulative incidence curve
- `RACING_Table3.png`: LDL-C goal achievement / lipid outcomes
- `RACING_Table4.png`: safety endpoints
- `RACING_Figure3.png`: subgroup forest plot

기본 코딩 스타일은 `general_AGENTS.md`를 따른다. 이 파일은 RACING synthetic patient-level data 분석에 필요한 변수 구조, `global.R`, `analysis.R`, 산출물 저장 규칙만 적는다.

현재 구현 파일은 저장소 루트의 `global.R`과 `analysis.R`이다. 지침과 코드가 다르면 두 파일을 함께 수정한다.

### RACING 적용 예외

- 표 계산 결과는 `ft_list`의 `flextable` 객체로 만들고, 원본 표는 Excel에 저장한다.
- 현재 환경에는 `flexxlsx`가 없고 사용자가 다른 방식을 지시했으므로 Excel은 `openxlsx`로 저장한다. `openxlsx2`도 사용하지 않는다.
- 논문 표 이미지를 슬라이드에 직접 사용하므로 Table 1–4 PNG도 함께 만든다.
- 그림 원본은 `officer`와 `rvg`를 사용한 PPT 벡터그래픽이며, 슬라이드용 PNG도 함께 만든다.
- primary endpoint 비열등성 차이는 연구 계획에 따라 90% CI를 사용한다. 이는 일반적인 95% CI 원칙의 RACING 고유 예외다.
- primary Cox HR과 subgroup HR, 나머지 absolute difference에는 95% CI를 붙인다.
- Table 1의 baseline 요약값과 Table 3의 LDL-C median (IQR)은 분포를 설명하는 값이므로 별도 CI나 군간 검정을 붙이지 않는다.

## 가장 중요한 원칙

- 사용자가 3,780명 synthetic data를 주면 **항상 `global.R`부터 만든다**.
- `global.R`에서 데이터 읽기, 변수명 정리, 파생변수 생성, `varlist`, `out`, `out.label`, 반복측정용 `out.long`, `out.long.label`까지 끝낸다.
- `analysis.R`에서는 `global.R`에서 만든 `out`, `out.label`, `out.long`, `out.long.label`을 그대로 사용한다.
- `out` 생성 이후에는 `out`에 분석용 파생변수를 새로 만들지 않는다. 필요하면 `copy(out)`로 만든 `dd` 안에서만 임시 변수를 만든다.
- 논문 PDF의 숫자는 synthetic data의 방향성과 분석 구조를 확인하는 reference로만 사용한다. synthetic data 결과가 논문과 정확히 같을 필요는 없다.
- 표와 그림에는 synthetic data 분석임을 footer 또는 caption에 명시한다.
- `analysis.R`은 `ft_list`와 `plot_list`를 만든다.
- Figure 1–3은 `figures/RACING_Figures.pptx`에 편집 가능한 벡터그래픽으로 저장한다.
- primary Cox model은 `cox.zph(fit, transform = "identity")`로 PH 가정을 검증한다.

## RACING 논문 기준 구조

RACING trial은 documented ASCVD 환자 3,780명을 1:1 배정한 randomised, open-label, non-inferiority trial이다.

- Combination therapy: rosuvastatin 10 mg + ezetimibe 10 mg, n=1894
- Monotherapy: rosuvastatin 20 mg, n=1886
- Primary endpoint: 3-year composite of cardiovascular death, major cardiovascular events, or non-fatal stroke
- Non-inferiority margin: absolute difference 2.0%p
- Key LDL endpoint: LDL-C <70 mg/dL at 1, 2, and 3 years
- Main safety endpoint: discontinuation or dose reduction due to intolerance

Synthetic data는 최소한 아래 방향성을 확인한다.

- 전체 N = 3,780
- 치료군 N이 1,894명과 1,886명 구조와 맞는지 확인
- primary endpoint rate는 약 9%대 범위인지 확인
- LDL-C <70 mg/dL 달성률은 combination therapy군이 더 높게 나오는지 확인
- 현재 synthetic data에 포함된 safety event가 치료군별로 합리적인 범위인지 확인

## 현재 synthetic data 구조

분석 입력 파일은 저장소 루트의 `RACING_synthetic_data.csv` 또는 `RACING_synthetic_data.xlsx`다. 두 파일은 같은 3,780명, 57개 변수 구조를 가져야 한다.

- 시간 단위는 연도가 아니라 정수 개월이다.
- 생존분석 시간 변수는 `primary_time_mo` 하나만 사용한다.
- `primary_time_mo`는 primary event 발생자에게만 값이 있고, 미발생자는 `NA`다.
- `admend_mo`는 대상자의 관찰 종료 또는 검열 시점이며 1–36개월 정수다.
- 생존분석 시간은 event 발생자에서는 `primary_time_mo`, 미발생자에서는 `admend_mo`를 사용한다.
- `secondary_event` 이하 임상 endpoint는 3년 누적 발생 여부만 제공되므로 Cox 또는 Kaplan–Meier 분석에 사용하지 않는다.
- `LDL_y1`, `LDL_y2`, `LDL_y3` 결측은 추적 종료와 검사 누락을 반영한다. 임의 대치하지 않고 시점별 non-missing N을 분모로 사용한다.

## RACING 핵심 변수

원자료 컬럼명이 다르면 `global.R` 맨 앞에서 `setnames()`로 먼저 정리한다. 아래 변수명은 분석 코드에서 사용할 표준 이름이다.

### ID / 치료군

- `ID`: 대상자 ID
- `group`: 치료군. `Combination` 또는 `Monotherapy`로 정리한 뒤 factor label을 붙인다.

### Baseline 변수

- `Age`, `Sex`, `Height`, `Weight`, `BMI`
- `Prior_MI`, `Prior_PCI`, `Prior_CABG`, `ACS`, `Prior_stroke`, `CKD`, `ESRD_dialysis`, `PAD`
- `Hypertension`, `Diabetes`, `Diabetes_insulin`, `Smoking`
- `Baseline_LDL`
- `Pre_HI_statin`, `Pre_HI_statin_ezetimibe`, `Pre_MI_statin`, `Pre_MI_statin_ezetimibe`, `Pre_LI_statin`, `Pre_none`

### 생존분석 변수

- `admend_mo`: 관찰 종료 또는 검열 시점, 1–36개월
- `primary_time_mo`: primary endpoint 발생 월. 미발생자는 `NA`
- `primary_event`: primary endpoint 발생 여부

생존분석용 관찰 시간은 아래처럼 구성한다.

```r
dd[, .event := as.integer(as.character(primary_event))]
dd[, .time := fifelse(.event == 1L,
                      as.numeric(primary_time_mo),
                      as.numeric(admend_mo))]
```

### 3년 임상 endpoint 변수

아래 변수는 3년 동안의 발생 여부를 비교한다. 별도 시간 변수를 만들거나 Cox model을 적용하지 않는다.

- `primary_event`, `secondary_event`
- `cv_death_event`, `allcause_death_event`, `mace_event`
- `coronary_revasc_event`, `peripheral_revasc_event`
- `cv_hosp_event`, `hf_hosp_event`
- `nonfatal_stroke_event`, `ischemic_stroke_event`, `hemorrhagic_stroke_event`

### LDL-C 반복측정 변수

- `LDL_y1`, `LDL_y2`, `LDL_y3`
- `LDL70_y1`, `LDL70_y2`, `LDL70_y3`: LDL-C <70 mg/dL
- `LDL55_y1`, `LDL55_y2`, `LDL55_y3`: LDL-C <55 mg/dL

### Safety 변수

- `new_diabetes`, `new_diabetes_med`
- `muscle_ae`, `myalgia`, `myopathy`, `myonecrosis`
- `hepatic_ae`, `ck_elevation`, `fasting_glucose_elevation`
- `gallbladder_ae`, `major_bleeding`, `cancer`
- `neurocognitive_disorder`, `cataract_surgery`

현재 synthetic data에는 `safety_population`과 `intolerance_stop_reduce`가 없다. 다른 변수로 대신 만들거나 논문 수치를 합성하지 않는다.

### Subgroup 변수

Subgroup 변수도 `global.R`에서 미리 만든다.

- `Age60`: Age <60 vs ≥60
- `BMI25`: BMI <25 vs ≥25 kg/m²
- `Baseline_LDL_lt100`: baseline LDL-C <100 mg/dL
- 그 외 `Sex`, `Diabetes`, `Hypertension`, `CKD`, `Prior_MI`, `Prior_stroke`, `PAD`

## global.R 작성 순서

`global.R`은 아래 순서로 작성한다.

1. 패키지 로드와 입력·출력 경로 설정
2. synthetic data 읽기
3. 컬럼명 표준화
4. 치료군 factor 정리
5. RACING 구조와 개월 단위 시간·검열 정보 검증
6. 필요한 파생변수 생성
7. `varlist` 생성
8. `out` 생성
9. factor/numeric 지정
10. `out.label` 생성과 라벨 입력
11. 반복측정 자료 `out.long`, `out.long.label` 생성

## global.R 기본 구조

실제 구현은 저장소 루트의 `global.R`을 기준으로 한다.

`global.R`은 다음 순서로 작성한다.

1. 패키지와 입력·출력 경로 설정
2. synthetic data 읽기
3. 치료군과 원자료 변수 형식 정리
4. 시간·사건 구조 검증
5. LDL 목표와 subgroup 파생변수 생성
6. `varlist` 생성
7. `varlist`에 등록된 변수로 `out` 생성
8. factor와 numeric 지정
9. 0/1 factor level을 `c("0", "1")`로 고정
10. `out.label` 생성과 라벨 입력
11. `out` 기반 `out.long` 생성
12. `out.long.label` 생성

```r
varlist <- list(
  ID = "ID",
  Base = c(),
  Followup = "admend_mo",
  Time = "primary_time_mo",
  Event = "primary_event",
  Clinical = c(),
  LDL = c(),
  Safety = c(),
  Subgroup = c()
)

varlist <- lapply(varlist, function(v) intersect(v, names(a)))

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
```

Subgroup 변수는 `out` 생성 전에 만든다.

- `Age60`
- `Sex_f`
- `BMI25`
- `Diabetes_f`
- `Hypertension_f`
- `CKD_f`
- `Prior_MI_f`
- `Prior_stroke_f`
- `PAD_f`
- `Baseline_LDL_100`

반복측정 자료는 `out`에서 만든다.

```r
out.long <- rbindlist(lapply(seq_len(3L), function(yr) {
  out[, .(
    ID,
    group,
    timepoint = factor(
      paste0(yr, if (yr == 1L) " year" else " years"),
      levels = c("1 year", "2 years", "3 years")
    ),
    LDL = get(paste0("LDL_y", yr)),
    LDL70 = factor(
      as.character(get(paste0("LDL70_y", yr))),
      levels = c("0", "1")
    ),
    LDL55 = factor(
      as.character(get(paste0("LDL55_y", yr))),
      levels = c("0", "1")
    )
  )]
}))

out.long.label <- jstable::mk.lev(out.long)
```

## analysis.R 작성 원칙

`analysis.R`은 `source("global.R")`로 시작한다. 분석 중 필요한 임시 변수는 `dd <- copy(out)` 또는 `dd <- copy(out.long)` 안에서만 만든다. `out` 자체에는 새 변수를 추가하지 않는다.

```r
source("global.R")

library(data.table);library(magrittr)
library(survival);library(jskm);library(jstable)
library(ggplot2);library(forestploter);library(grid)
library(flextable);library(openxlsx);library(gridExtra);library(ragg)
library(officer);library(rvg)

asset_dir <- "docs/2026-07-21-RCT-RACING"
dir.create("results", showWarnings = FALSE)
dir.create("figures", showWarnings = FALSE)

synthetic_footer <- "This table was generated from synthetic example data, not original RACING patient-level data."
synthetic_note <- "Synthetic example data; not original RACING patient-level data."

ft_list <- list()
plot_list <- list()
```

## RACING_Table1.png: baseline characteristics

- intention-to-treat population의 baseline characteristics를 제시한다.
- 원 논문 형식에 맞춰 군간 P value는 표시하지 않는다.
- 연속형 변수는 mean (SD) 또는 median (IQR)로 표시한다.
- 범주형 변수는 n (%)로 표시한다.
- `ID`는 제외한다.
- raw 변수명 대신 `out.label`의 사람이 읽는 라벨을 사용한다.
- 약물 사용력은 section row 아래에 들여쓴다.
- `ft_list[["Table 1"]]`에는 `set_caption()`과 `add_footer_lines()`를 적용한다.
- footer에는 descriptive summary이며 군간 가설검정을 하지 않았다고 적는다.

## RACING_Table2.png: 3-year clinical endpoints

- `varlist$Clinical`의 binary event 변수를 사용한다.
- 치료군별 event n (%)를 표시한다.
- absolute difference는 Combination minus Monotherapy다.
- primary endpoint difference는 사전 정의한 90% CI를 사용한다.
- 나머지 difference는 95% CI를 사용한다.
- difference CI는 continuity correction을 쓰지 않은 two-sample score method로 계산한다.
- primary endpoint에는 Cox HR과 95% CI를 표시한다.
- primary endpoint P value는 Cox model에서 계산한다.
- primary endpoint 이외의 임상 endpoint에는 시간 변수가 없으므로 Cox model이나 HR을 적용하지 않는다.
- 나머지 P value는 기대도수에 따라 chi-squared 또는 Fisher exact test를 사용한다.
- 비열등성 margin 2.0%p와 CI 수준, 검정법을 footer에 적는다.
- primary endpoint의 Kaplan–Meier 결과는 Figure 2에서 제시한다.

## RACING_Figure2.png: Kaplan-Meier cumulative incidence

- 생존분석은 primary endpoint에만 적용한다.
- event 발생자는 `primary_time_mo`, 미발생자는 `admend_mo`를 관찰 시간으로 사용한다.
- `primary_time_mo`가 `NA`라는 이유로 미발생자를 분석에서 제외하면 안 된다.
- 시간축 단위는 months로 표시한다.
- `jskm()`에는 반드시 `data = dd`를 넣고 cumulative incidence로 표시한다.

```r
dd <- copy(out)
dd <- dd[!is.na(primary_event) & !is.na(admend_mo)]
dd[, .event := as.integer(as.character(primary_event))]
dd[, .time := fifelse(
  .event == 1L,
  as.numeric(primary_time_mo),
  as.numeric(admend_mo)
)]
stopifnot(!anyNA(dd$.time))

fmla <- Surv(.time, .event) ~ group
fit <- eval(substitute(survfit(f, data = dd), list(f = fmla)))

plot_list[["Figure 2"]] <- jskm(
  fit, data = dd, pval = TRUE, marks = FALSE,
  table = TRUE, cumhaz = TRUE,
  xlab = "Months", ylab = "Cumulative incidence"
)
```

## RACING_Table3.png: LDL-C outcomes

- `out.long`을 기준으로 1년, 2년, 3년 결과를 한 표에 정리한다.
- 각 시점의 observed N을 표시한다.
- LDL-C <70 mg/dL과 <55 mg/dL은 n/non-missing N (%)로 표시한다.
- 목표 달성률의 absolute difference에는 95% CI를 표시한다.
- difference CI는 continuity correction을 쓰지 않은 two-sample score method로 계산한다.
- LDL-C는 median (IQR)로 표시한다.
- 결측은 0이나 목표 미달로 바꾸지 않는다.
- 결측 처리와 CI 산출법을 footer에 적는다.
- 시점이 연속 행에서 반복되는 형식이면 `merge_v()`, top/left 정렬을 적용한다.

## RACING_Table4.png: safety endpoints

- 별도의 safety population 변수가 없으므로 전체 무작위배정 대상자를 분모로 사용한다.
- `varlist$Safety`의 binary outcome을 n (%)로 표시한다.
- absolute difference와 95% CI를 표시한다.
- difference CI는 continuity correction을 쓰지 않은 two-sample score method로 계산한다.
- 현재 자료에 없는 `safety_population`과 `intolerance_stop_reduce`를 만들지 않는다.
- P value를 표시할 경우 기대도수에 따라 chi-squared 또는 Fisher exact test를 사용한다.
- 분모, CI 산출법과 synthetic data 문구를 footer에 적는다.

## RACING_Figure3.png: subgroup forest plot

- primary endpoint의 subgroup별 치료군 event/total (%)를 표시한다.
- 효과척도는 Combination minus Monotherapy absolute difference다.
- 각 subgroup의 absolute difference와 90% CI를 표시한다.
- 0%p를 기준선으로, 2.0%p 비열등성 margin을 점선으로 표시한다.
- subgroup level은 들여쓴다.
- CI를 그리는 열은 공백 열로 둔다.
- x축은 percentage-point 선형 척도를 사용한다.
- 추정 불가 값은 점과 선을 그리지 않는다.
- 원 논문처럼 왼쪽에는 치료군별 event/total, 오른쪽에는 estimate와 CI를 배치한다.

## RACING_Figure1.png: participant flow / study design

- 3,780명 synthetic patient-level data에서 allocation count를 계산한다.
- 현재 data에는 별도의 flow population 변수가 없으므로 randomized/allocation 중심의 간단한 flow로 만든다.
- 약제 불내성으로 인한 allocated therapy 중단은 published RACING Table 4 요약값인 Combination 88/1,846명(4.8%), Monotherapy 150/1,832명(8.2%)을 사용할 수 있다.
- 이 중단 수치는 synthetic patient-level data에서 계산한 값이 아니므로 Figure 1 각주에 출처와 한계를 명시한다.
- 논문 숫자를 하드코딩할 때는 `summary numbers from Lancet RACING paper`라고 주석을 남긴다.

```r
flow_dt <- out[, .(N = .N), by = group]
flow_dt[, Step := as.character(group)]
flow_dt <- rbind(
  data.table(Step = "Randomised", N = nrow(out)),
  flow_dt[, .(Step, N)],
  fill = TRUE
)
```

## 산출물 저장

표 계산 결과는 `table1`–`table4`에 저장하고, 같은 자료로 `ft_list`, Excel, PNG를 만든다.

### Flextable

모든 표는 `flextable` 객체를 `ft_list`에 보관한다.

- `set_caption()`으로 표 제목을 넣는다.
- `add_footer_lines()`으로 실제 통계방법과 synthetic data 문구를 넣는다.
- 같은 grouping 값이 연속 행에서 반복되면 `merge_v()`를 적용한다.
- 병합한 열은 top/left 정렬한다.
- raw 변수명을 노출하지 않는다.

### Excel

현재 환경에서는 `flexxlsx`와 `openxlsx2`를 사용하지 않는다. `openxlsx`로 `results/RACING_Tables.xlsx`를 만든다.

각 시트에는 다음을 포함한다.

Excel 시트 형식은 저장소 루트의 `Tables_example.xlsx`를 기준으로 한다.

- 1행: 표 제목을 전체 열에 병합
- 2행: 열 제목, DejaVu Sans 9pt, 위·아래 thick 회색 경계선, 가운데·위 정렬
- 본문: DejaVu Sans 9pt, 왼쪽·위 정렬, 줄바꿈
- 마지막 본문 행: 아래 thick 회색 경계선
- 마지막 행: 통계방법 footer를 전체 열에 병합
- 배경색, 자동 필터, 고정창을 사용하지 않음
- 제목과 footer 외에는 셀 병합을 사용하지 않음


- 표 제목
- 표 본문
- 실제 분석법과 CI 산출법을 적은 footer
- 열 너비와 행 높이는 별도로 강제하지 않고 Excel 기본값을 사용
- 고정 header row

### PPT

Figure 1–3은 `officer`와 `rvg`로 `figures/RACING_Figures.pptx`에 저장한다.

```r
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

print(ppt, target = "figures/RACING_Figures.pptx")
```

PPT에는 표를 넣지 않는다.

### PNG

슬라이드용 Table 1–4와 Figure 1–3 PNG를 `docs/2026-07-21-RCT-RACING/`에 저장한다.

표 PNG는 원 RACING 논문 형식을 따른다.

- 옅은 분홍색 배경과 흰색 교차 행
- 세로선 없이 얇은 가로선
- 긴 치료군 이름과 N을 열 머리글에 표시
- endpoint 또는 연도 section row를 굵게 표시
- 각주와 표 제목을 표 아래에 배치
- synthetic data 문구 표시

### 추가 검증 파일

Primary Cox model은 아래 방식으로 PH 가정을 검증한다.

```r
primary_ph <- cox.zph(primary_cox, transform = "identity")
```

결과는 `results/RACING_primary_PH_assumption.xlsx`에 저장한다.

## 최종 확인

- `global.R`에서 `varlist`, `out`, `out.label`, `out.long`, `out.long.label`이 모두 만들어졌는지 확인한다.
- `out`이 전체 원자료 복사본이 아니라 `varlist` 변수로 구성됐는지 확인한다.
- `analysis.R`에서 `out`과 `out.long`을 직접 수정하지 않았는지 확인한다.
- `ft_list`에 Table 1–4가 있는지 확인한다.
- `plot_list`에 Figure 1–3이 있는지 확인한다.
- synthetic data가 3,780명, 57개 변수인지 확인한다.
- 치료군 N이 1,894명과 1,886명인지 확인한다.
- `admend_mo`가 1–36개월 정수인지 확인한다.
- `primary_event == 0`이면 `primary_time_mo`가 `NA`인지 확인한다.
- primary endpoint 미발생자의 생존분석 시간이 `admend_mo`인지 확인한다.
- primary endpoint 이외의 clinical endpoint에 Cox model이나 HR을 적용하지 않았는지 확인한다.
- primary absolute difference가 90% CI인지 확인한다.
- primary HR과 subgroup HR에 95% CI가 있는지 확인한다.
- 나머지 absolute difference에 95% CI가 있는지 확인한다.
- 모든 footer가 실제 검정, 모델, CI 수준과 산출법에 맞는지 확인한다.
- LDL 결측을 0이나 목표 미달로 바꾸지 않았는지 확인한다.
- Table 3 분모가 시점별 non-missing N인지 확인한다.
- 현재 자료에 없는 safety 변수를 만들지 않았는지 확인한다.
- Table 1–4가 원 논문의 분홍색 배경, section row, 하단 각주·제목 형식을 따르는지 확인한다.
- Figure 2가 months 단위의 `Cumulative incidence`인지 확인한다.
- Figure 3이 primary endpoint의 `Surv(.time, .event)`를 사용하는지 확인한다.
- `cox.zph(..., transform = "identity")` 결과가 저장되는지 확인한다.
- `results/RACING_Tables.xlsx`에 Table 1–4 시트가 있는지 확인한다.
- `figures/RACING_Figures.pptx`에 Figure 1–3 슬라이드가 있는지 확인한다.
- 7개 PNG가 모두 생성되고 0바이트가 아닌지 확인한다.
- 모든 산출물에 synthetic data 문구가 있는지 확인한다.

```r
expected_png <- file.path(
  "docs/2026-07-21-RCT-RACING",
  c(
    "RACING_Figure1.png",
    "RACING_Table1.png",
    "RACING_Table2.png",
    "RACING_Figure2.png",
    "RACING_Table3.png",
    "RACING_Table4.png",
    "RACING_Figure3.png"
  )
)

stopifnot(all(file.exists(expected_png)))
stopifnot(all(file.info(expected_png)$size > 0))
stopifnot(file.exists("results/RACING_Tables.xlsx"))
stopifnot(file.exists("figures/RACING_Figures.pptx"))
stopifnot(file.exists("results/RACING_primary_PH_assumption.xlsx"))
```
