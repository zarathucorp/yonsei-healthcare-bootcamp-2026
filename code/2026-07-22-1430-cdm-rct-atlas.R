# 2026 여름 디지털 헬스케어 부트캠프
# 차시: ATLAS 활용하여 concept 및 실험군/대조군 코호트 만들기
# 날짜: 2026.07.22 14:30 ~ 15:30
# 강사: 김진섭

# 이 파일은 수업 중 실행할 R 코드를 모아 두는 시작 템플릿입니다.
# 필요한 패키지와 데이터 경로는 차시 내용에 맞춰 바꿉니다.

packages <- c(
  "tidyverse",
  "readxl",
  "janitor",
  "gtsummary",
  "writexl"
)

missing_packages <- packages[!vapply(packages, requireNamespace, logical(1), quietly = TRUE)]
if (length(missing_packages) > 0) {
  message("설치가 필요한 패키지: ", paste(missing_packages, collapse = ", "))
  # install.packages(missing_packages)
}

invisible(lapply(packages, library, character.only = TRUE))

dir.create("results", showWarnings = FALSE)
dir.create("figures", showWarnings = FALSE)

# 1. 데이터 불러오기 ---------------------------------------------------------
# data <- readr::read_csv("data/example.csv")

# 2. 데이터 정리 -------------------------------------------------------------
# analysis_data <- data |> janitor::clean_names()

# 3. 분석 -------------------------------------------------------------------
# result <- analysis_data |> dplyr::count()

# 4. 결과 저장 ---------------------------------------------------------------
# writexl::write_xlsx(list(result = result), "results/2026-07-22-1430-cdm-rct-atlas-result.xlsx")
