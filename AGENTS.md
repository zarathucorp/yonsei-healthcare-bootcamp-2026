# AGENTS.md

이 저장소는 연세의료원 `2026 여름 디지털 헬스케어 부트캠프` 강의자료를 정리하는 작업 공간이다. 앞으로 새 슬라이드, 코드, 문서를 만들 때는 아래 기준을 따른다.

## 기본 원칙

- 모든 문서는 수강생이 바로 읽는 자료라고 보고 쓴다. 디자인 설명, 내부 작업 메모, 변환 사유 같은 말은 수강생용 문서에 넣지 않는다.
- 한국어 문장은 자연스럽게 다듬는다. 번역투, 과한 접속사, 기계적인 병렬 문장, 불필요한 강조를 줄이고, 사실·숫자·날짜·고유명사는 바꾸지 않는다.
- 확실하지 않은 원본, 일정, 강의 제목, 링크가 있으면 임의로 만들지 말고 사용자에게 확인한다.
- 엑셀 일정표가 바뀌었다는 말이 있으면 `2026 부트캠프 커리큘럼 및 일정표.xlsx`를 다시 읽고 작업한다.
- 임시 스크립트나 중간 산출물은 작업 후 정리한다. `docs/`, `code/`, `README.md`, `docs/index.qmd`에 필요한 최종 산출물만 남긴다.

## 주요 자료

- `2026 부트캠프 커리큘럼 및 일정표.xlsx`: 일정과 강의 제목의 기준 파일이다.
- `quarto-style/`: revealjs 슬라이드 디자인 기준이다. 새 슬라이드를 만들 때 먼저 확인한다.
- `docs/slides_assets/`: 실제 강의 슬라이드에서 쓰는 공용 CSS, 배경, 로고 자산이다.
- `R-skku-biohrs/`, `lecture-general/`: 기존 강의자료 원본이다. 변환 요청이 있으면 이 안에서 원본을 찾는다.
- `docs/`: 차시별 `index.qmd`와 렌더링된 `index.html`을 둔다.
- `code/`: 차시별 실습용 R 코드를 둔다.

## 폴더와 파일 규칙

- 강의자료는 `docs/<차시-slug>/index.qmd`와 `docs/<차시-slug>/index.html`로 만든다.
- 실습 코드는 `code/<차시-slug>.R`로 만든다.
- 비어 있는 파일을 남기지 않는다. 아직 본문이 없어도 `quarto-style`에 맞춘 시작 템플릿을 넣는다.
- 심화반 3일차인 `2026-07-24-*` 자료는 만들지 않는다. README와 수강생용 목차에서도 링크 없이 평문으로 둔다.
- `docs/index.qmd`는 수강생용 목차다. `README.md`도 같은 수강생용 내용으로 맞춘다.

## GitHub Pages 링크

- GitHub Pages 기준 URL은 `https://zarathucorp.github.io/yonsei-healthcare-bootcamp-2026/`이다.
- README와 `docs/index.qmd`의 강의 바로가기는 상대 경로가 아니라 GitHub Pages의 HTML 절대 URL을 쓴다.
- 예: `https://zarathucorp.github.io/yonsei-healthcare-bootcamp-2026/2026-07-20-1230-r-ai-agent-install/index.html`
- GitHub Pages는 `docs/`를 공개 루트로 쓰는 전제다. 따라서 Pages URL에는 `docs/`를 넣지 않는다.
- 김진섭 강의는 링크를 둔다. 김진섭 강의가 아니거나 사용자가 링크를 빼라고 한 차시는 평문으로 둔다.

## README와 수강생용 목차

- `docs/index.qmd`는 Quarto YAML을 유지한다.
- `README.md`는 `docs/index.qmd`의 본문과 같은 내용을 담되, 맨 위는 Markdown H1 제목으로 시작한다.
- 수강생용 목차에는 디자인 지침, 내부 폴더 설명, 변환 작업 내역을 넣지 않는다.
- 7/24 심화반 3일차는 일정만 보이고 링크는 없다.

## Quarto revealjs 양식

새 `index.qmd`는 다음 구조를 기본으로 한다.

- `format: revealjs`
- `theme: ../slides_assets/zarathu_theme.scss`
- CSS:
  - `../slides_assets/custom-style.css`
  - `../slides_assets/custom-style-fullbg.css`
  - `../slides_assets/custom-xaringan-compat.css`
- `include-after-body: ../slides_assets/header-inject-fullbg.html`
- `self-contained: false`
- `slide-number: c/t`
- `width: 1600`
- `height: 900`
- `execute.eval: false`

템플릿은 `quarto-style/base_slides_fullbg.qmd`의 톤과 구성 요소를 따른다. 자주 쓰는 구성은 다음과 같다.

- `::: {.large}`: 큰 본문 목록
- `::: {.highlight-box}`: 핵심 안내
- `::: {.highlight-box-blue}`: 흐름 또는 실습 안내
- `::: {.highlight-box-gray}`: 참고, 주의, 원본 이미지 누락 안내
- `::: columns`와 `.column`: 좌우 배치
- `.intro-slide`, `.conclusion-slide`: 도입과 마무리 슬라이드

## 기존 변환 상태

이미 변환한 자료는 원본을 다시 덮어쓰지 말고, 필요한 경우 현재 qmd를 기준으로 수정한다.

- `docs/2026-07-20-1230-r-ai-agent-install/`: 기존 Claude Code R 자료를 Codex와 터미널 설치 중심으로 바꾼 자료다. Mac, Windows, WSL2를 함께 다룬다. API key는 실제 값을 넣지 않는다.
- `docs/2026-07-21-1430-physician-path/`: `lecture-general/docs/ishs2025`를 원본으로 변환한 특강 자료다.
- `docs/2026-07-22-1230-cdm-intro/`: `lecture-general/docs/cdm-intro`를 변환한 자료다. 만료된 Oopy/Notion 이미지는 안내 박스로 바꿨다.
- `docs/2026-07-22-1330-cdm-practice/`: `lecture-general/docs/cdm-practice`를 변환한 자료다.
- `docs/2026-07-22-1430-cdm-rct-atlas/`, `docs/2026-07-22-1530-cdm-r-package/`: 시작 템플릿만 둔 상태다. 실제 내용을 넣으려면 사용자 지시를 기다린다.

## 기존 자료 변환 규칙

- 엑셀에 `->`와 URL이 있거나 기존 강의 링크가 적혀 있으면 그 자료를 원본 후보로 본다.
- 로컬 원본이 확실하면 revealjs qmd로 변환하고, 필요한 이미지와 자산을 같은 `docs/<slug>/` 폴더로 복사한다.
- 원본이 불확실하면 사용자에게 먼저 묻는다. 제목이 비슷하다는 이유만으로 변환하지 않는다.
- xaringan Rmd를 변환할 때는 `class: center, middle`, `.large[...]`, `.center[...]`, `---` 슬라이드 구분을 Quarto 문법으로 바꾼다.
- 제목 없는 이미지 슬라이드는 빈 슬라이드가 되지 않게 `## 자료 {.center}` 같은 제목을 넣는다.
- 만료된 외부 이미지 링크, 특히 `oopy.lazyrockets.com`이나 `secure.notion` 계열은 그대로 두지 않는다. 이미지 복구가 어렵다면 `highlight-box-gray`로 짧게 설명하고 논문·분석 링크를 남긴다.

## R 코드 파일

- 각 차시의 `code/<slug>.R`은 바로 실행을 시작할 수 있는 템플릿을 둔다.
- 기본 패키지 후보는 `tidyverse`, `readxl`, `janitor`, `gtsummary`, `writexl`이다.
- 결과 저장용으로 `results/`, `figures/` 폴더를 만들도록 둔다.
- 실제 강의 내용이 들어가기 전에는 예시 데이터 경로와 분석 코드는 주석으로 남긴다.

## 렌더링과 검증

qmd를 수정하거나 새로 만들면 HTML도 함께 렌더링한다.

```bash
quarto render docs/<차시-slug>/index.qmd
quarto render docs/index.qmd
```

렌더링 후에는 최소한 다음을 확인한다.

- `docs/`와 `code/`에 0바이트 파일이 없는가
- revealjs HTML에 빈 section이 없는가
- 로컬 이미지가 누락되지 않았는가
- README와 `docs/index.qmd`의 강의 링크가 GitHub Pages URL인가
- `2026-07-24` 강의자료 링크나 파일이 다시 생기지 않았는가
- `oopy.lazyrockets.com`, `secure.notion`, 오래된 `lecture-general` 바로가기 링크가 남지 않았는가

이 환경에서는 Quarto가 macOS `sysctl` 조회 문제로 sandbox에서 실패할 수 있다. 그런 경우 사용자 승인을 받아 같은 렌더링 명령을 다시 실행한다.

## 작성 톤

- 수강생에게는 짧고 분명하게 쓴다.
- "이를 통해", "결론적으로", "핵심적으로", "할 수 있다" 같은 문구를 습관적으로 반복하지 않는다.
- 불릿은 필요한 만큼만 쓴다. 목록을 남발하지 말고, 슬라이드 한 장에는 한 가지 역할만 둔다.
- API key, 개인정보, 접근 토큰은 절대 문서에 적지 않는다.
