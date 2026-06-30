set.seed(2026)
n <- 600
rct <- data.frame(
  id = 1:n,
  trt = factor(sample(c("Control", "Treatment"), n, replace = TRUE)),
  age = round(rnorm(n, 64, 9)),
  sex = factor(sample(c("Female", "Male"), n, replace = TRUE)),
  diabetes = rbinom(n, 1, 0.28)
)

rct$risk <- -3.0 + 0.45 * (rct$trt == "Control") + 0.03 * (rct$age - 64) + 0.5 * rct$diabetes
rct$event <- rbinom(n, 1, plogis(rct$risk))
rct$time <- round(rexp(n, rate = ifelse(rct$event == 1, 1 / 420, 1 / 900)))
rct$time <- pmin(rct$time, 730)
rct$status <- ifelse(rct$time < 730 & rct$event == 1, 1, 0)

head(rct)
table(rct$trt)
library(tableone)
vars <- c("age", "sex", "diabetes")
tb1 <- CreateTableOne(vars = vars, strata = "trt", data = rct)
print(tb1, showAllLevels = TRUE)
event_table <- with(rct, table(trt, event))
event_table
prop.table(event_table, margin = 1)
risk_by_group <- aggregate(event ~ trt, data = rct, mean)
risk_by_group

rd <- diff(risk_by_group$event)
rr <- risk_by_group$event[2] / risk_by_group$event[1]
c(risk_difference = rd, risk_ratio = rr)
fit_logit <- glm(event ~ trt + age + sex + diabetes, data = rct, family = binomial)
round(exp(cbind(OR = coef(fit_logit), confint.default(fit_logit))), 2)
library(survival)
km <- survfit(Surv(time, status) ~ trt, data = rct)
summary(km, times = c(180, 365, 730), extend = TRUE)
fit_cox <- coxph(Surv(time, status) ~ trt + age + sex + diabetes, data = rct)
summary(fit_cox)$coefficients[, c("exp(coef)", "Pr(>|z|)")]
library(ggplot2)

dir.create("results", showWarnings = FALSE)
dir.create("figures", showWarnings = FALSE)

event_plot <- ggplot(risk_by_group, aes(x = trt, y = event, fill = trt)) +
  geom_col(width = 0.5) +
  scale_y_continuous(labels = function(x) paste0(round(x * 100), "%")) +
  labs(x = NULL, y = "Event rate") +
  theme_minimal(base_size = 14) +
  theme(legend.position = "none")

event_plot

ggsave(
  filename = "figures/2026-07-21-1330-rct-reproduction-project-event-rate.png",
  plot = event_plot,
  width = 7,
  height = 5,
  dpi = 300
)

writexl::write_xlsx(
  list(
    rct = rct,
    event_table = as.data.frame.matrix(event_table),
    risk_by_group = risk_by_group
  ),
  "results/2026-07-21-1330-rct-reproduction-project-results.xlsx"
)
