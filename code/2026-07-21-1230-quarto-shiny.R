# 2026 여름 디지털 헬스케어 부트캠프
# 차시: Quarto Markdown과 Shiny 활용
# 날짜: 2026.07.21 12:30 ~ 13:30
# 강사: 김진섭

packages <- c(
  "tidyverse",
  "readxl",
  "janitor",
  "gtsummary",
  "writexl",
  "shiny",
  "bslib"
)

missing_packages <- packages[!vapply(packages, requireNamespace, logical(1), quietly = TRUE)]
if (length(missing_packages) > 0) {
  message("설치가 필요한 패키지: ", paste(missing_packages, collapse = ", "))
  # install.packages(missing_packages)
}

invisible(lapply(packages, library, character.only = TRUE))

dir.create("results", showWarnings = FALSE)
dir.create("figures", showWarnings = FALSE)

# 1. 예시 데이터 준비 --------------------------------------------------------
analysis_data <- mtcars |>
  tibble::rownames_to_column("car") |>
  janitor::clean_names() |>
  mutate(
    cyl = factor(cyl),
    am = factor(am, levels = c(0, 1), labels = c("Automatic", "Manual"))
  )

# 2. 요약표 만들기 -----------------------------------------------------------
summary_table <- analysis_data |>
  group_by(cyl) |>
  summarise(
    n = n(),
    mean_mpg = mean(mpg),
    mean_wt = mean(wt),
    .groups = "drop"
  )

writexl::write_xlsx(
  list(summary = summary_table),
  "results/2026-07-21-1230-quarto-shiny-summary.xlsx"
)

# 3. 슬라이드에 넣을 그림 저장 ----------------------------------------------
mpg_plot <- ggplot(analysis_data, aes(x = wt, y = mpg, color = cyl)) +
  geom_point(size = 3) +
  labs(
    x = "Weight",
    y = "Miles per gallon",
    color = "Cylinders"
  ) +
  theme_minimal(base_size = 14)

ggsave(
  "figures/2026-07-21-1230-quarto-shiny-mpg.png",
  mpg_plot,
  width = 8,
  height = 5,
  dpi = 150
)

# 4. Quarto 렌더링 예시 ------------------------------------------------------
# quarto::quarto_render("docs/2026-07-21-1230-quarto-shiny/index.qmd")

# 5. Shiny 분석웹 예시 -------------------------------------------------------
# 아래 코드를 app.R에 옮기거나 콘솔에서 실행하면 간단한 분석웹을 볼 수 있습니다.
#
# ui <- fluidPage(
#   theme = bslib::bs_theme(version = 5),
#   titlePanel("mtcars 탐색"),
#   sidebarLayout(
#     sidebarPanel(
#       selectInput("cyl", "실린더 수", choices = sort(unique(analysis_data$cyl)))
#     ),
#     mainPanel(
#       plotOutput("scatter"),
#       tableOutput("summary")
#     )
#   )
# )
#
# server <- function(input, output, session) {
#   filtered <- reactive({
#     analysis_data |> filter(cyl == input$cyl)
#   })
#
#   output$scatter <- renderPlot({
#     ggplot(filtered(), aes(x = wt, y = mpg, color = am)) +
#       geom_point(size = 3) +
#       labs(x = "Weight", y = "Miles per gallon", color = "Transmission") +
#       theme_minimal(base_size = 14)
#   })
#
#   output$summary <- renderTable({
#     filtered() |>
#       summarise(
#         n = n(),
#         mean_mpg = mean(mpg),
#         mean_wt = mean(wt)
#       )
#   })
# }
#
# shinyApp(ui, server)
