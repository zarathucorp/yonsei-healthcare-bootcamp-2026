library(data.table);library(magrittr);library(ggpubr)
set.seed(222)

## T-test
data.t <- data.frame(sex = sample(c("Male", "Female"), 30, replace = T), tChol = round(rnorm(30, mean = 150, sd = 30)))
rownames(data.t) <- paste("person", 1:30)
data.t

nev.ttest <- t.test(tChol ~ sex, data = data.t, var.equal = F);nev.ttest
ev.ttest <- t.test(tChol ~ sex, data = data.t, var.equal = T);ev.ttest

ggarrange(
  ggboxplot(data.t, "sex", "tChol", fill = "sex"),
  ggbarplot(data.t, "sex", "tChol", fill = "sex", add = "mean_sd")
)

ggboxplot(data.t, "sex", "tChol", fill = "sex", add = "dotplot") + 
  stat_compare_means(method = "t.test", method.args = list(var.equal = F))


ggviolin(data.t, "sex", "tChol", fill = "sex", add = "boxplot") + 
  stat_compare_means(method = "t.test", method.args = list(var.equal = T), label.y = 250)


## Wilcox
res.wilcox <- wilcox.test(tChol ~ sex, data = data.t);res.wilcox

ggboxplot(data.t, "sex", "tChol", fill = "sex") + 
  stat_compare_means(method = "wilcox.test")



## ANOVA
data.aov <- data.frame(group = sample(c("A", "B", "C"), 30, replace = T), tChol = round(rnorm(30, mean = 150, sd = 30)))
rownames(data.aov) <- paste("person", 1:30)
data.aov

res.aov1 <- oneway.test(tChol ~ group, data = data.aov, var.equal = F);res.aov1
res.aov2 <- oneway.test(tChol ~ group, data = data.aov, var.equal = T);res.aov2

ggboxplot(data.aov, "group", "tChol", fill = "group", order = c("A", "B", "C")) + 
  stat_compare_means(method = "anova")


ggboxplot(data.aov, "group", "tChol", fill = "group", order = c("A", "B", "C")) + 
  stat_compare_means(method = "anova", label.y = 250) + 
  stat_compare_means(method = "t.test", comparisons = list(c("A", "B"), c("B", "C"), c("C", "A")))

## Kruskal test
res.kruskal <- kruskal.test(tChol ~ group, data = data.aov);res.kruskal

ggboxplot(data.aov, "group", "tChol", fill = "group", order = c("A", "B", "C")) + 
  stat_compare_means(method = "kruskal.test")


## Categorical: Chisq test
data.chi <- data.frame(HTN_medi = round(rbinom(50, 1, 0.4)), DM_medi = round(rbinom(50, 1, 0.4)))
rownames(data.chi) <- paste("person", 1:50)
data.chi

tb.chi <- table(data.chi);tb.chi
res.chi <- chisq.test(tb.chi);res.chi

## Fisher
data.fisher <- data.frame(HTN_medi = round(rbinom(50, 1, 0.2)), DM_medi = round(rbinom(50, 1, 0.2)))
rownames(data.fisher) <- paste("person", 1:50)

tb.fisher <- table(data.fisher);tb.fisher
chisq.test(tb.fisher)
res.fisher <- fisher.test(tb.fisher);res.fisher


## Paired test: continuous
data.pt <- data.frame(SBP_hand = round(rnorm(30, mean = 125, sd = 5)), SBP_machine = round(rnorm(30, mean = 125, sd = 5)))
rownames(data.pt) <- paste("person", 1:30)

pt.ttest <- t.test(data.pt$SBP_hand, data.pt$SBP_machine);pt.ttest
pt.ttest.pair <- t.test(data.pt$SBP_hand, data.pt$SBP_machine, paired = T);pt.ttest.pair

ggpaired(data.pt, cond1 = "SBP_hand", cond2 = "SBP_machine", fill = "condition", palette = "jco") + 
  stat_compare_means(method = "t.test", paired = T)

pt.wilcox.pair <- wilcox.test(data.pt$SBP_hand, data.pt$SBP_machine, paired = T);pt.wilcox.pair

ggpaired(data.pt, cond1 = "SBP_hand", cond2 = "SBP_machine", fill = "condition", palette = "jco") + 
  stat_compare_means(method = "wilcox.test", paired = T)


## Paired test: categorical
data.mc <- data.frame(Pain_before = round(rbinom(30, 1, 0.5)), Pain_after = round(rbinom(30, 1, 0.5)))
rownames(data.mc) <- paste("person", 1:30)

table.mc <- table(data.mc);table.mc
mc.chi <- chisq.test(table.mc);mc.chi
mc.mcnemar <- mcnemar.test(table.mc);mc.mcnemar


## Paired test: >= 3 category
#install.packages("rcompanion")
library(rcompanion)
data(AndersonRainGarden)  # Example data
AndersonRainGarden
nominalSymmetryTest(AndersonRainGarden)




## Regression and survival analysis -----------------------------------------

library(survival);library(broom);library(writexl)

data(colon, package = "survival")
colon.analysis <- na.omit(colon)

## Linear regression
cor.result <- cor.test(colon.analysis$age, colon.analysis$nodes)
cor.result

linear.simple <- lm(nodes ~ age, data = colon.analysis)
summary(linear.simple)$coefficients

t.test(time ~ sex, data = colon.analysis, var.equal = T)
linear.ttest.like <- lm(time ~ sex, data = colon.analysis)
summary(linear.ttest.like)$coefficients

levels(colon.analysis$rx)
tail(model.matrix(time ~ rx, data = colon.analysis))

linear.categorical <- lm(time ~ rx, data = colon.analysis)
summary(linear.categorical)$coefficients
anova(linear.categorical)

linear.multiple <- lm(time ~ sex + age + rx, data = colon.analysis)
summary(linear.multiple)$coefficients

## Logistic regression
logistic.model <- glm(status ~ sex + age + rx, data = colon.analysis, family = binomial)
summary(logistic.model)
logistic.or <- broom::tidy(logistic.model, exponentiate = TRUE, conf.int = TRUE)
logistic.or

## Survival analysis
survival.object <- with(colon.analysis, Surv(time, status))
head(survival.object)

km.fit <- survfit(survival.object ~ rx, data = colon.analysis)
plot(km.fit, col = 1:3, lty = 1:3, xlab = "Time", ylab = "Survival probability")
legend("bottomleft", legend = levels(colon.analysis$rx), col = 1:3, lty = 1:3)

logrank.result <- survdiff(survival.object ~ rx, data = colon.analysis)
logrank.result

cox.model <- coxph(survival.object ~ sex + age + rx, data = colon.analysis)
summary(cox.model)
cox.hr <- broom::tidy(cox.model, exponentiate = TRUE, conf.int = TRUE)
cox.hr

## Time-split Cox example
data(veteran, package = "survival")
veteran.split <- survSplit(Surv(time, status) ~ ., data = veteran, cut = c(90, 180), episode = "tgroup", id = "id")

cox.time.split <- coxph(Surv(tstart, time, status) ~ trt + prior + karno:strata(tgroup), data = veteran.split)
summary(cox.time.split)

model.tables <- list(
  logistic_or = logistic.or,
  cox_hr = cox.hr
)

dir.create("results", showWarnings = FALSE)
dir.create("figures", showWarnings = FALSE)

writexl::write_xlsx(model.tables, "results/2026-07-20-1030-basic-statistics-regression-survival-models.xlsx")

png("figures/2026-07-20-1030-kaplan-meier-rx.png", width = 1200, height = 900, res = 150)
plot(km.fit, col = 1:3, lty = 1:3, xlab = "Time", ylab = "Survival probability")
legend("bottomleft", legend = levels(colon.analysis$rx), col = 1:3, lty = 1:3)
dev.off()
