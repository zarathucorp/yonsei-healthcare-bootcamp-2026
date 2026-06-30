# 2026 여름 디지털 헬스케어 부트캠프
# 차시: 가능도와 정규분포
# 날짜: 2026.07.21 10:30 ~ 11:30
# 강사: 김진섭

# 이 파일은 수업 중 가능도와 정규분포 예제를 실행할 때 쓰는 시작 템플릿입니다.

packages <- c(
  "tidyverse",
  "ggplot2",
  "gridExtra"
)

missing_packages <- packages[!vapply(packages, requireNamespace, logical(1), quietly = TRUE)]
if (length(missing_packages) > 0) {
  message("설치가 필요한 패키지: ", paste(missing_packages, collapse = ", "))
  # install.packages(missing_packages)
}

invisible(lapply(packages, library, character.only = TRUE))

dir.create("figures", showWarnings = FALSE)

# 1. 이산사건: 동전 10번 던지기 ---------------------------------------------
# n <- 0:10
# coin_prob <- tibble(
#   heads = n,
#   probability = dbinom(n, size = 10, prob = 0.5)
# )

# ggplot(coin_prob, aes(heads, probability)) +
#   geom_col(width = 0.7) +
#   scale_x_continuous(breaks = 0:10) +
#   labs(x = "앞면 횟수", y = "확률")

# 2. 연속사건: 표준정규분포 PDF ---------------------------------------------
# z <- seq(-4, 4, length.out = 200)
# normal_density <- tibble(z = z, density = dnorm(z))

# ggplot(normal_density, aes(z, density)) +
#   geom_line() +
#   labs(x = "z", y = "Density")

# 3. MLE 예시: 일그러진 동전 -------------------------------------------------
# p <- seq(0.2, 0.6, by = 0.001)
# likelihood <- choose(1000, 400) * p^400 * (1 - p)^600
# mle_coin <- tibble(p = p, likelihood = likelihood)

# ggplot(mle_coin, aes(p, likelihood)) +
#   geom_line() +
#   labs(x = "p", y = "L")

# 4. 중심극한정리 예시 --------------------------------------------------------
# sample_mean <- function(n = 30) {
#   mean(rbinom(n, size = 1, prob = 0.4))
# }

# set.seed(20260721)
# means <- tibble(mean_value = replicate(10000, sample_mean(30)))

# ggplot(means, aes(mean_value)) +
#   geom_histogram(aes(y = after_stat(density)), bins = 40) +
#   geom_density() +
#   labs(x = "표본평균", y = "Density")
