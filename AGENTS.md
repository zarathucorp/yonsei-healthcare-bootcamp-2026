# general_AGENTS.md

# 분석 스타일

## Core Rules

- `data.table`을 메인 패키지로 사용한다.
- `dplyr` 스타일은 거의 사용하지 않는다.
- pipe operator는 `%>%`만 사용한다.
- `global.R`은 데이터 읽기, 전처리, 파생변수 생성, `varlist`, `out`, `out.label` 구성을 담당한다.
- 실제 분석은 `analysis.R` 등 별도 R 파일로 확실히 분리한다.
- **중요: `varlist`와 `out`이 나오기 전에 필요한 파생변수를 모두 만들어놓는다. `out` 이후에는 새 분석 변수를 만들지 않는다.**
- `global.R`에서 만든 `out`, `out.label`은 `analysis.R`에서 그대로 사용한다.
- 불필요한 함수 래핑을 피하고, 분석 흐름이 보이도록 스크립트로 쭉 작성한다.

## Standard global.R Workflow

1. 패키지를 로드하고 작업 경로 또는 데이터 소스를 설정한다.
2. 데이터를 읽고 `data.table`로 변환한다.
3. 변수명을 정리하고 필요한 파생변수를 모두 만든다.
4. 사용할 변수를 `varlist`에 저장한다.
5. 생존분석이면 `varlist$Event`, `varlist$Time`에 순서를 맞춰 저장한다.
6. `out <- a[, .SD, .SDcols = c(unlist(varlist))]` 형태로 분석 데이터를 만든다.
7. factor/numeric 변수를 지정한다.
8. `out.label <- jstable::mk.lev(out)`로 label 정보를 만든다.
9. `out.label`의 `var_label`, `val_label`을 채운다.
10. 이후 분석하거나, `out`과 `out.label`로 Shiny 앱을 만든다.

반복측정데이터일 때는 `out` 기반으로 long form `out.long`, `out.long.label`을 추가로 만들고 `out`과 동일하게 작업한다.


## global.R Example (DM_dxa)

```r
library(data.table);library(magrittr);library(jstable);library(openxlsx)
setwd("~/ShinyApps/kangnam_hallym/wchong23/DM_dxa")

a <- readxl::read_excel("OS졸국논문kanghyuna_250818.xlsx", skip = 1)[, 1:33] %>% data.table

setnames(a, "연령", "Age")

a[, DM := as.integer(DM == "1")]

a[, lumbar_qc_bad := as.integer(
  (!is.na(L1-L2) & abs(L1 - L2) > 1) | (!is.na(L2-L3) & abs(L2 - L3) > 1) | (!is.na(L3-L4) & abs(L3 - L4) > 1))]

a[, osteoporosis := fifelse(pmin(Femur, L1.L4, na.rm = T) <= -2.5, 1, 0)]


varlist <- list(
  Base = c("DM", "Femur", "L1.L4", "HbA1c", "Age", "BMI", "lumbar_qc_bad", "osteoporosis")
)


out <- a[, .SD, .SDcols = c(unlist(varlist))]

factor_vars <- c(names(out)[sapply(out, function(x){length(table(x))}) <= 6])
out[, (factor_vars) := lapply(.SD, factor), .SDcols = factor_vars]
conti_vars <- setdiff(names(out), c(factor_vars))
out[, (conti_vars) := lapply(.SD, as.numeric), .SDcols = conti_vars]

out.label <- jstable::mk.lev(out)

vars01 <- sapply(factor_vars, function(v) {
  lv <- sort(unique(na.omit(as.character(out[[v]]))))
  length(lv) > 0 && all(lv %in% c("0", "1"))
})

for (v in names(vars01)[vars01 == TRUE]) {
  out.label[variable == v, val_label := c("No", "Yes")]
}

out.label[variable == "DM", var_label := "DM_status"]
out.label[variable == "L1.L4", var_label := "L1_4"]
```

## 테이블 저장
- flextable으로 포맷팅 (논문에 바로 쓸 수 있는 형태)
- flexlsx + openxlsx2로 Excel 여러 시트에 저장


## 그림 저장
- 기본은 ppt (rvg::dml + officer 패키지)
- 벡터 그래픽, fullsize

## 주요 패키지
- jstable: CreateTableOneJS, cox2.display, glmshow.display
- jskm: Kaplan-Meier plot (jskm, svyjskm)
- 라벨 적용: LabeljsCox, LabeljsTable 등

## 주의사항
- survfit/coxph는 eval(substitute()) 패턴 필수
- 테이블 부등호: >= → ≥, <= → ≤ (유니코드)
- Table 1 footer는 실제 사용된 검정과 일치시키기


## 논문용 테이블 필수 규칙

- 같은 그룹명/변수명은 반복 표기하지 않는다.
- 병합한 컬럼에는 `valign(j = ..., valign = "top")`과 `align(j = ..., align = "left")`를 적용한다.
- 변수명은 raw 코드명이 아니라 사람이 읽는 라벨로 표시한다.
- 컬럼명/변수명 그대로 노출하지 않는다. 예: `dose_mg`, `ANC_bl`, `var123`.
- 라벨은 named character vector, `jstable::mk.lev()`, `out.label`을 활용한다.
- 숫자 점추정에는 반드시 95% CI를 함께 제시한다.
- AUC, HR, OR, RR, Mean, Median, proportion 등 모든 estimate에는 CI를 붙인다.
- CI 산출 방법은 footer에 명시한다.
- Footer에는 통계방법을 한 줄로 요약한다.
- reviewer가 footer만 읽어도 어떤 검정, 모델, CI 산출법을 썼는지 알 수 있어야 한다.

## 코딩 스타일 원칙

- 리스트나 데이터를 만들 때는 `lapply`와 `rbindlist` 등으로 한 번에 저장한다.
- 파일 저장, PPT 슬라이드 추가, Excel write 같은 side-effect 작업은 `for`문을 사용한다.
- 그림은 `lapply`로 `plot_list`에 ggplot 객체 리스트를 먼저 저장한 뒤, `for`문으로 PPT에 저장한다.
- 불필요한 함수 래핑을 만들지 말고 스크립트로 쭉 흐르게 작성한다.

## jstable 패키지

- `CreateTableOneJS(..., labeldata = out.label, Labels = T)` 옵션으로 라벨을 적용한다.
- `CreateTableOneJS(...)$table %>% cbind(Variable = rownames(.), .)`로 변수명 컬럼을 추가한다.
- 3군 이상 비교 시 `pairwise = T` 옵션으로 pairwise p-value를 한 번에 출력한다.
- `test` 컬럼은 제거하고 저장한다. 예: `$table[, -which(colnames($table) == "test")]`.
- `TableSubgroupMultiCox/GLM`: subgroup analysis에 사용한다.
- `LabeljsCox()`: Cox model 레이블 적용에 사용한다.
- `labelepidisplay`는 사용하지 않는다.
- `mk.lev()`: 레이블 데이터프레임 생성에 사용한다.


## 분석 코드 주의사항

### KM / Cox 관련 (jskm)

- `jskm(fit, pval = TRUE)`를 쓸 때 반드시 `data = dd`를 넣는다.
- `data = dd`를 빠뜨리면 `"pval option requires data object"` 에러가 난다.
- `survfit()` 객체 생성 시 formula를 변수로 넘기면 `jskm`이 `fit$call$formula`를 파싱하지 못한다.
- formula 객체를 사용할 때는 `eval(substitute())` 패턴을 사용한다.

```r
# 틀림
fit <- survfit(fmla, data = dd)

# 맞음
fit <- eval(substitute(survfit(f, data = dd), list(f = fmla)))
```


### 부등호/특수문자 표기

- 테이블, 그림, 라벨 등 사용자에게 보이는 텍스트에서 `>=`는 `≥`, `<=`는 `≤`로 표기한다.
- R 코드 문자열에서도 동일하게 쓴다. 예: `labels = c("≥35")` 또는 `labels = c("\u226535")`.
- `kg/m^2`는 `kg/m²`로 표기한다.
- 범위 하이픈은 en dash(`–`) 사용을 고려한다.
- 코드 로직 조건문의 `>=`, `<=`는 R 문법이므로 그대로 유지한다.
- `\uXXXX` 유니코드 이스케이프는 백틱 안에서 사용할 수 없다.
- 한글/특수문자가 포함된 컬럼명은 `setnames()`로 영문명으로 바꾼 뒤 사용한다.
- 리스트 이름에 특수문자가 필요하면 `setNames()` 또는 `[[ ]]` 할당을 사용한다.

```r
# 틀림
list(`Albumin \u2264 3.5` = dd)

# 맞음
setNames(list(dd), "Albumin \u2264 3.5")
strata_list[["Albumin \u2264 3.5"]] <- dd
```

### Table 주석

- footer는 실제 사용된 검정과 반드시 일치시킨다.

### 테이블 footer 재검토

- 제출하거나 답변하기 전에 모든 테이블의 footer가 실제 사용된 통계와 일치하는지 재검토한다.
- 수치가 맞아도 방법 기술이 틀리면 재작업 대상이다.

### 0/1 factor level 강제

- 한쪽 값만 존재하는 0/1 변수도 `levels = c("0", "1")`를 강제한다.
- Table 1에서 `"Yes: 0 (0%)"`가 표시되도록 한다.

```r
vars01 <- sapply(factor_vars, function(v) {
  lv <- sort(unique(na.omit(as.character(out[[v]]))))
  length(lv) > 0 && all(lv %in% c("0", "1"))
})
for (v in names(vars01)[vars01 == TRUE]) {
  out[, (v) := factor(as.character(get(v)), levels = c("0", "1"))]
}
```

### forestploter 관련

- `TableSubgroupMultiCox/GLM()` 결과는 data.frame에서 data.table로 변환한 뒤 `:=`를 사용한다.
- CI를 그리는 열은 빈 공백 열로 확보한다.
- 텍스트 열에 `ci_column`을 지정하면 선이 글자와 겹친다.
- 서브그룹 하위 레벨은 들여쓴다. 예: `df$Variable <- ifelse(is.na(df$Count), df$Variable, paste0("   ", df$Variable))`.
- `Count`, `P value` 등 표시용 컬럼의 NA는 `""`로 변환한 뒤 `forest()`에 전달한다.
- 극단값(OR > 100 또는 Inf)은 `est`, `low`, `high`를 NA로 설정해서 점과 선을 그리지 않는다.
- 극단값 행의 P value도 빈칸으로 둔다.
- `sizes`에는 스칼라를 넣어 모든 점의 크기를 동일하게 둔다. 예: `sizes = 0.4`.
- `x_trans = "log"`로 x축 로그 스케일을 사용한다.
- `forest_theme()`에서는 `refline_gp = gpar(col = ...)`, `footnote_gp = gpar(col = ...)`를 사용한다.
- `refline_col`, `footnote_col`은 deprecated이므로 쓰지 않는다.
- `library(grid)`가 필요하다.
- `forest()`에 넘기는 data.frame은 표시할 열만 선택한다.
- Event는 `Events/N (%)` 형식으로 표시한다.
- header row의 P value는 `""`로 처리한다.
- level 라벨은 `0/1` 대신 `No/Yes` 등 의미 있는 라벨로 변환한다.

```r
df$Variable <- ifelse(is.na(df$Count), df$Variable, paste0("   ", df$Variable))
df$Count <- ifelse(is.na(df$Count), "", df$Count)
df$` ` <- paste(rep(" ", 20), collapse = " ")
df$`OR (95% CI)` <- ifelse(is.na(df$est), "",
                            sprintf("%.2f (%.2f-%.2f)", df$est, df$low, df$high))
df[is.na(`P value`), `P value` := ""]

p <- forest(
  df[, c("Variable", "Count", " ", "OR (95% CI)", "P value", "P interaction")],
  est = df$est, lower = df$low, upper = df$high,
  sizes = 0.4, ci_column = 3, ref_line = 1,
  x_trans = "log", xlim = c(0.1, 10), ticks_at = c(0.25, 0.5, 1, 2, 4),
  theme = forest_theme(base_size = 10, refline_gp = gpar(col = "grey50"))
)
```

```r
df[, Event := paste0(Events, "/", N, " (", sprintf("%.1f", Events / N * 100), "%)")]
```

### PH 가정 검증

- `cox.zph(fit, transform = "identity")`로 변수별 PH 위반 p-value를 확인한다.


### 심장학 연구 KM curve

- `cumhaz = TRUE`를 사용하여 cumulative incidence, 즉 1-S(t) 형태로 표시한다.
- y축 라벨은 `"Cumulative incidence"`로 둔다.
- ylims는 연구 event rate에 맞춰 설정한다. 예: `ylims = c(0, 0.3)`.

## 한글 문체 / 표현 규칙

- `"견고하다"` 표현은 쓰지 않는다.
- 영어 `robust`는 `robust하다`, `일관되다`, `일관된 결과`, `모든 분석에서 일치` 등으로 쓴다.
- `"권합니다"`, `"권장합니다"`, `"권고합니다"`, `"권장"` 표현은 쓰지 않는다.
- 대신 `~하는 게 좋겠습니다`로 쓴다.
- 어색한 영어 번역투를 줄인다.
- 부자연스러운 수동태, `~에 대해`, `~를 가진다` 식 직역을 피한다.
- 사용자에게 보이는 모든 한글 텍스트에 적용한다.

## 분석시 유의사항

- **Statistical Analysis는 반드시 영어로** 작성 (논문 methods 스타일)
- 마지막에 `All analyses were performed using R 4.6.1 (R Foundation for Statistical Computing, Vienna, Austria).` 포함
- R 패키지 버전(lmerTest, emmeans 등)은 넣지 않음

## PPT 슬라이드 작업 시 유의사항
  - 모든 글자는 한 페이지 안에 배치
  - 글자 자림과 화면 밖 넘침 방지
  - 그림, 도형, 화살표가 글자를 가리지 않도록 배치
  - 랜더링된 HTML에서 겹침과 가독성까지 확인

## RACING Synthetic data 해석시 주의사항

### Safety population

- RACING PDF의 safety population은 safety event가 있었는지가 아니라 allocated therapy를 실제로 받았는지를 기준으로 정의된다.
- 현재 `RACING_synthetic_data.xlsx`에는 allocated therapy 수령 여부, allocated therapy 미수령 사유, per-protocol 포함 여부 변수가 없다.
- 따라서 safety population은 synthetic data에서 재구성하지 않는다.
- Table 4의 denominator는 randomised participants로 사용하고, footer에 다음과 같이 명시한다.
  ```text
  Safety endpoints were summarised among all randomised participants because allocated-treatment receipt and safety population variables were unavailable in the synthetic data.
  ```

### 약제 불내성 중단/감량 변수

- synthetic data에는 약제 불내성 때문에 약을 중단하거나 감량한 사람들 변수가 존재하지 않는다.
- 따라서 safety endpoint들을 묶어 새로운 변수 intolerance_stop_reduce를 만든다.
- 기준 safety endpoint는 muscle_ae, myalgia, myopathy, myonecrosis, hepatic_ae, ck_elevation, fasting_glucose_elevation를 사용한다.
- 위 변수들 중 하나라도 1이면 intolerance_stop_reduce = 1, 전부 0이면 intolerance_stop_reduce = 0으로 둔다.
- 이 변수는 반드시 global.R에서 out 만들기 전에 생성한다.
- 이 값은 실제 원자료의 치료 중단/감량 변수가 아니라 safety endpoint 기반 composite이므로, Table 4 footer에 이를 명시한다.
  ```text
  The intolerance-discontinuation row was derived from intolerance-related safety endpoints in the synthetic data.
  ```
- Table 4에서 intolerance_stop_reduce를 별도 행으로 추가했다면, 이후 varlist$Safety 반복 출력에서는 이 변수를 제외한다. (같은 row가 두 번 생기는 것 방지하기 위해)
  ```
  for (v in setdiff(varlist$Safety, "intolerance_stop_reduce")) {
    add_t4_event(v, safety_labels[[v]])
  }
  ```
  
### Figure 1 trial profile

  - LDL_y1, LDL_y2, LDL_y3 결측은 LDL laboratory follow-up missing이다.
  - LDL 결측을 trial follow-up 중단으로 해석하지 않는다.
  - 따라서 LDL 결측은 Figure 1 trial profile에 넣지 않는다.
  - death는 allcause_death_event로 표시한다.
  - lost to follow-up, withdrawal consent 변수가 없으면 임의로 만들지 않는다.
  - primary_event == 0 & admend_mo < 36은 lost to follow-up으로 단정하지 않는다.
  - 이 경우에는 "censored before 3 years, reason unavailable"로 표시한다.
