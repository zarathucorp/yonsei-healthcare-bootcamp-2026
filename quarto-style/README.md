# Quarto Slide Template

Zarathu 공용 Quarto `revealjs` slide template입니다. 현재 배포본은 전체 슬라이드에 은은한 full-background를 적용한 `base_slides_fullbg.html`입니다.

현재 구성:
- `base_slides_fullbg.html`: 최종 렌더 산출물
- `base_slides_fullbg.qmd`: 새 보고서를 시작할 때 복사해서 쓰는 skeleton
- `_metadata_fullbg.yml`: full-background revealjs 설정
- `base_slides_fullbg_files/`: 최종 HTML 렌더 의존 파일
- `slides_assets/zarathu_theme.scss`: reveal 기본 테마 변수
- `slides_assets/custom-style.css`: box, 표, 여백, 슬라이드별 기본 레이아웃
- `slides_assets/custom-style-fullbg.css`: 전체 슬라이드 배경 overlay 설정
- `slides_assets/header-inject-fullbg.html`: header/footer 및 background 주입
- `slides_assets/bg.png`, `slides_assets/Zarathu Circle Clipping Mask2.png`: 표지/브랜딩 자산

사용 방법:
1. 이 폴더를 새 프로젝트로 복사합니다.
2. `base_slides_fullbg.qmd`를 복사해 새 보고서용 qmd를 만듭니다.
3. 같은 폴더에서 `quarto preview <새파일>.qmd` 또는 `quarto render <새파일>.qmd`를 실행합니다.

디자인 수정 위치:
- 색, heading 기본값: `slides_assets/zarathu_theme.scss`
- 박스, 표, 공통 여백, 슬라이드별 클래스: `slides_assets/custom-style.css`
- 전체 배경 overlay: `slides_assets/custom-style-fullbg.css`
- 로고, 하단 문구, 공통 DOM 삽입: `slides_assets/header-inject-fullbg.html`
- 표지 및 전체 배경 이미지: `slides_assets/bg.png`

자주 쓰는 클래스 목록은 `COMPONENTS.md`에 정리되어 있습니다.
