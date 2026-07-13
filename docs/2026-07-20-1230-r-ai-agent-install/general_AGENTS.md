# general_AGENTS.MD

이 문서는 RACING trial 자료처럼 논문 표와 그림을 R 코드로 재현할 때 따르는 기본 분석 스타일이다. 

## global.R 작성 원칙

- `data.table`을 메인 패키지로 사용한다.
- `dplyr` 스타일은 거의 쓰지 않는다.
- pipe operator는 `%>%`만 사용한다.
- 데이터 읽기, 전처리, 사용할 변수 정리는 `global.R`에서 한다.
- 실제 분석은 `analysis.R` 등 별도 R 파일로 분리한다.
- 데이터를 읽고 전처리한 뒤, 사용할 변수를 `varlist`에 저장한다.
- 생존분석을 할 경우 `varlist$Event`, `varlist$Time`에 event/time 변수를 순서에 맞춰 저장한다.
- `out`을 만들고 factor/numeric을 지정한 뒤, `out.label`을 만든다.
- `out.label`에 label 정보를 채운 뒤 분석하거나, `out`과 `out.label`로 Shiny를 만든다.
- `varlist`와 `out`이 나오기 전에 필요한 파생변수를 모두 만든다.
- `out` 이후에는 새 분석용 변수를 만들지 않는다.
- 반복측정데이터일 때는 `out` 기반으로 long form `out.long`, `out.long.label`을 추가로 만들고 `out`과 동일하게 작업한다.

## 산출물 저장 원칙

- 그림으로 저장할 경우 기본은 PPT다.
- `rvg::dml`과 `officer`를 사용해 벡터그래픽으로 저장한다.
- 그림 크기는 기본적으로 fullsize로 둔다.
- 테이블은 `flextable`로 포맷팅하고, 논문에 바로 쓸 수 있는 형태로 만든다.
- 테이블명은 `set_caption()`으로 넣는다.
- 통계방법 주석은 `add_footer_lines()`로 넣는다.
- 테이블은 Excel로만 저장한다. PPT에는 그림만 넣는다.
- PPT 안에 `flextable` 슬라이드를 만들지 않는다. 별도 요청이 있을 때만 PPT 표를 추가한다.
- Excel 저장은 `flexlsx`와 `openxlsx2`를 사용해 여러 시트로 저장한다.

```r
library(flextable);library(flexlsx);library(openxlsx2)
wb <- wb_workbook()
for (sn in names(ft_list)) {
  wb$add_worksheet(sn)
  wb <- wb_add_flextable(wb, sn, ft_list[[sn]])
}
wb$save("Tables.xlsx")
```

## 논문용 테이블 필수 규칙

- 같은 그룹명/변수명은 반복 표기하지 않는다.
- grouping 컬럼(`group`, `strata`, `outcome`, `model` 등)의 같은 값이 연속 행에 반복되면 `merge_v(j = ...)`로 세로 병합한다.
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
- 별도 2군 테이블을 만들지 않는다.
- `test` 컬럼은 제거하고 저장한다. 예: `$table[, -which(colnames($table) == "test")]`.
- `cox2.display()`: Cox model 테이블에 사용한다.
- `TableSubgroupMultiCox/GLM`: subgroup analysis에 사용한다.
- `LabeljsCox()`: Cox model 레이블 적용에 사용한다.
- `labelepidisplay`는 사용하지 않는다.
- `mk.lev()`: 레이블 데이터프레임 생성에 사용한다.

## global.R 기본 구조

```r
library(data.table);library(magrittr);library(jstable);library(openxlsx)
setwd("~/파일 경로")

# a <- readxl::read_excel("data.xlsx", skip = 1) %>% data.table(check.names = T)

varlist <- list(
  Base = c()
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
  out[, (v) := factor(as.character(get(v)), levels = c("0", "1"))]
}
for (v in names(vars01)[vars01 == TRUE]) {
  out.label[variable == v, val_label := c("No", "Yes")]
}
```

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

- `coxph()`도 동일하다.
- formula를 변수로 넘기면 `cox2.display()`가 `fit$call$formula`를 파싱할 때 `"object of type 'symbol' is not subsettable"` 에러가 날 수 있다.
- `update(model, ...)` 내부 호출도 실패할 수 있으므로 `eval(substitute())`를 사용한다.

```r
# 틀림
fit <- coxph(fmla, data = df)

# 맞음
fit <- eval(substitute(coxph(f, data = df), list(f = fmla)))
```

### cox2.display / LabeljsCox 관련

- `LabeljsCox()` 적용 후 rownames가 variable name에서 label로 치환된다.
- table 결과에서 variable name 기준 매칭이 필요하면 유의 마커나 P value 추출은 별도 `coxph()` 결과에서 직접 계산한다.
- `data_for_univariate = dd`: multivariate 모델에서 univariate 결과도 같이 출력할 때 사용한다.
- `.$table[, 1:2]`는 univariate 결과(HR, P)다.
- `.$table[, 3:4]`는 multivariate 결과(adj.HR, P)다.

### out 변수 관리

- `global.R`에서 `out`, `out.label`을 만든다.
- `analysis.R`에서는 `out`, `out.label`을 그대로 사용한다.
- `out`에 분석용 임시 파생변수를 만들지 않는다.

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
- 일반 데이터에서 `CreateTableOneJS`를 사용할 때 mean ± SD는 `"P by t-test / Chi-squared or Fisher's exact test"`로 적는다.
- median (IQR)는 `"P by Wilcoxon rank-sum test / Chi-squared or Fisher's exact test"`로 적는다.
- `nonnormal` 옵션을 바꾸면 footer 문구도 같이 바꾼다.
- 2그룹 비교에서 `nonnormal`을 쓸 때는 `testNonNormal = wilcox.test`를 지정한다.
- 기본값은 Kruskal-Wallis이므로 2그룹 nonnormal 분석에서는 특히 주의한다.
- 기대빈도 <5라 Fisher's exact test가 자동 선택될 수 있으면 footer에 `"or Fisher's exact test"`를 포함한다.

### 테이블 footer 재검토

- 제출하거나 답변하기 전에 모든 테이블의 footer가 실제 사용된 통계와 일치하는지 재검토한다.
- 수치가 맞아도 방법 기술이 틀리면 재작업 대상이다.
- `nonnormal` 옵션을 바꿨는지, 2군+nonnormal에서 `testNonNormal = wilcox.test`를 적용했는지 확인한다.

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

### 1/2 factor level 강제

- 1/2 코딩 변수도 한쪽 값만 있어도 `levels = c("1", "2")`를 강제한다.
- 1=없음, 2=있음 구조에서 `"No: 100%"`만 보이지 않게 하고 `"Yes: 0 (0%)"`를 표시한다.

```r
vars12 <- sapply(factor_vars, function(v) {
  lv <- sort(unique(na.omit(as.character(out[[v]]))))
  length(lv) > 0 && all(lv %in% c("1", "2"))
})
for (v in names(vars12)[vars12 == TRUE]) {
  out[, (v) := factor(as.character(get(v)), levels = c("1", "2"))]
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

### 반복측정 RCT 분석

- 기본 모델은 `outcome ~ group * time + (1|ID)`로 둔다.
- baseline 시점을 포함한 uLDA 형태를 기본으로 쓴다.
- Primary test는 `group × time interaction`이다.
- Post-hoc은 `emmeans`로 시점별 군간 비교와 baseline 대비 군내 변화를 계산한다.
- 결과표는 LMM ANOVA를 별도 테이블로 빼지 않는다.
- 메인 결과 테이블 하나에 시점별 mean±SD, within-group P(V0 대비), between-group P, interaction P를 통합한다.

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
