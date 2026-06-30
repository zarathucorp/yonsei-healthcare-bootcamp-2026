# 2026 여름 디지털 헬스케어 부트캠프
# 차시: 의학연구 위한 기초통계(Table 1), 회귀/생존분석
# 날짜: 2026.07.20 10:30 ~ 11:30
# 강사: 김진섭

packages <- c(
  "data.table",
  "tidyverse",
  "readxl",
  "janitor",
  "gtsummary",
  "writexl",
  "ggpubr",
  "magrittr",
  "rcompanion",
  "survival",
  "broom"
)

missing_packages <- packages[!vapply(packages, requireNamespace, logical(1), quietly = TRUE)]
if (length(missing_packages) > 0) {
  message("설치가 필요한 패키지: ", paste(missing_packages, collapse = ", "))
  # install.packages(missing_packages)
}

invisible(lapply(packages, library, character.only = TRUE))

dir.create("results", showWarnings = FALSE)
dir.create("figures", showWarnings = FALSE)

# 1. Table 1에 필요한 기본 검정 -------------------------------------------
# 참고: R-skku-biohrs/code/descriptive.R

set.seed(222)

# T-test
data.t <- data.frame(
  sex = sample(c("Male", "Female"), 30, replace = TRUE),
  tChol = round(rnorm(30, mean = 150, sd = 30))
)
rownames(data.t) <- paste("person", 1:30)
data.t

nev.ttest <- t.test(tChol ~ sex, data = data.t, var.equal = FALSE)
nev.ttest

ev.ttest <- t.test(tChol ~ sex, data = data.t, var.equal = TRUE)
ev.ttest

ggarrange(
  ggboxplot(data.t, "sex", "tChol", fill = "sex"),
  ggbarplot(data.t, "sex", "tChol", fill = "sex", add = "mean_sd")
)

ggboxplot(data.t, "sex", "tChol", fill = "sex", add = "dotplot") +
  stat_compare_means(method = "t.test", method.args = list(var.equal = FALSE))

ggviolin(data.t, "sex", "tChol", fill = "sex", add = "boxplot") +
  stat_compare_means(method = "t.test", method.args = list(var.equal = TRUE), label.y = 250)

# Wilcox
res.wilcox <- wilcox.test(tChol ~ sex, data = data.t)
res.wilcox

ggboxplot(data.t, "sex", "tChol", fill = "sex") +
  stat_compare_means(method = "wilcox.test")

# ANOVA
data.aov <- data.frame(
  group = sample(c("A", "B", "C"), 30, replace = TRUE),
  tChol = round(rnorm(30, mean = 150, sd = 30))
)
rownames(data.aov) <- paste("person", 1:30)
data.aov

res.aov1 <- oneway.test(tChol ~ group, data = data.aov, var.equal = FALSE)
res.aov1

res.aov2 <- oneway.test(tChol ~ group, data = data.aov, var.equal = TRUE)
res.aov2

ggboxplot(data.aov, "group", "tChol", fill = "group", order = c("A", "B", "C")) +
  stat_compare_means(method = "anova")

ggboxplot(data.aov, "group", "tChol", fill = "group", order = c("A", "B", "C")) +
  stat_compare_means(method = "anova", label.y = 250) +
  stat_compare_means(method = "t.test", comparisons = list(c("A", "B"), c("B", "C"), c("C", "A")))

# Kruskal test
res.kruskal <- kruskal.test(tChol ~ group, data = data.aov)
res.kruskal

ggboxplot(data.aov, "group", "tChol", fill = "group", order = c("A", "B", "C")) +
  stat_compare_means(method = "kruskal.test")

# Categorical: Chisq test
data.chi <- data.frame(
  HTN_medi = round(rbinom(50, 1, 0.4)),
  DM_medi = round(rbinom(50, 1, 0.4))
)
rownames(data.chi) <- paste("person", 1:50)
data.chi

tb.chi <- table(data.chi)
tb.chi

res.chi <- chisq.test(tb.chi)
res.chi

# Fisher
data.fisher <- data.frame(
  HTN_medi = round(rbinom(50, 1, 0.2)),
  DM_medi = round(rbinom(50, 1, 0.2))
)
rownames(data.fisher) <- paste("person", 1:50)

tb.fisher <- table(data.fisher)
tb.fisher

chisq.test(tb.fisher)

res.fisher <- fisher.test(tb.fisher)
res.fisher

# Paired test: continuous
data.pt <- data.frame(
  SBP_hand = round(rnorm(30, mean = 125, sd = 5)),
  SBP_machine = round(rnorm(30, mean = 125, sd = 5))
)
rownames(data.pt) <- paste("person", 1:30)

pt.ttest <- t.test(data.pt$SBP_hand, data.pt$SBP_machine)
pt.ttest

pt.ttest.pair <- t.test(data.pt$SBP_hand, data.pt$SBP_machine, paired = TRUE)
pt.ttest.pair

ggpaired(data.pt, cond1 = "SBP_hand", cond2 = "SBP_machine", fill = "condition", palette = "jco") +
  stat_compare_means(method = "t.test", paired = TRUE)

pt.wilcox.pair <- wilcox.test(data.pt$SBP_hand, data.pt$SBP_machine, paired = TRUE)
pt.wilcox.pair

ggpaired(data.pt, cond1 = "SBP_hand", cond2 = "SBP_machine", fill = "condition", palette = "jco") +
  stat_compare_means(method = "wilcox.test", paired = TRUE)

# Paired test: categorical
data.mc <- data.frame(
  Pain_before = round(rbinom(30, 1, 0.5)),
  Pain_after = round(rbinom(30, 1, 0.5))
)
rownames(data.mc) <- paste("person", 1:30)

table.mc <- table(data.mc)
table.mc

mc.chi <- chisq.test(table.mc)
mc.chi

mc.mcnemar <- mcnemar.test(table.mc)
mc.mcnemar

# Paired test: >= 3 category
# install.packages("rcompanion")
data(AndersonRainGarden)
AndersonRainGarden
nominalSymmetryTest(AndersonRainGarden)

# 2. 회귀분석 ---------------------------------------------------------------

data(colon, package = "survival")
colon_analysis <- colon |>
  tidyr::drop_na()

# 선형회귀
cor_result <- cor.test(colon_analysis$age, colon_analysis$nodes)
linear_simple <- lm(nodes ~ age, data = colon_analysis)
linear_ttest_like <- lm(time ~ sex, data = colon_analysis)
linear_categorical <- lm(time ~ rx, data = colon_analysis)
linear_multiple <- lm(time ~ sex + age + rx, data = colon_analysis)

# 로지스틱 회귀
logistic_model <- glm(
  status ~ sex + age + rx,
  data = colon_analysis,
  family = binomial
)

logistic_or <- broom::tidy(logistic_model, exponentiate = TRUE, conf.int = TRUE)

# 3. 생존분석 ---------------------------------------------------------------

survival_object <- with(colon_analysis, Surv(time, status))

km_fit <- survfit(survival_object ~ rx, data = colon_analysis)
logrank_result <- survdiff(survival_object ~ rx, data = colon_analysis)
cox_model <- coxph(survival_object ~ sex + age + rx, data = colon_analysis)
cox_hr <- broom::tidy(cox_model, exponentiate = TRUE, conf.int = TRUE)

# 시간 구간을 나누는 Cox 예시
data(veteran, package = "survival")
veteran_split <- survSplit(
  Surv(time, status) ~ .,
  data = veteran,
  cut = c(90, 180),
  episode = "tgroup",
  id = "id"
)

cox_time_split <- coxph(
  Surv(tstart, time, status) ~ trt + prior + karno:strata(tgroup),
  data = veteran_split
)

# 4. 결과 저장 ---------------------------------------------------------------

model_tables <- list(
  logistic_or = logistic_or,
  cox_hr = cox_hr
)

writexl::write_xlsx(
  model_tables,
  "results/2026-07-20-1030-basic-statistics-regression-survival-models.xlsx"
)

png("figures/2026-07-20-1030-kaplan-meier-rx.png", width = 1200, height = 900, res = 150)
plot(km_fit, col = 1:3, lty = 1:3, xlab = "Time", ylab = "Survival probability")
legend("bottomleft", legend = levels(colon_analysis$rx), col = 1:3, lty = 1:3)
dev.off()
