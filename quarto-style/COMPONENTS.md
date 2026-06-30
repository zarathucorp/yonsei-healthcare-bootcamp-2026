# Template Components

공용 클래스 카탈로그입니다. 시각 예시는 `base_slides_fullbg.qmd`(렌더 결과 `base_slides_fullbg.html`)에서 확인할 수 있습니다. 프로젝트 deck 전용 클래스는 이 템플릿에서 제거되어 있으니, 프로젝트별로 필요한 스타일은 로컬 `custom-style.css`에 추가하세요.

## 색상 팔레트 (Approved Palette C)

뮤트 톤 4색(green / blue / teal / purple) + gray. 파일 하단 `/* ===== Approved Palette C ===== */` 블록이 cascade 최상위 override. 색을 바꾸려면 해당 블록만 수정하면 됩니다.

## 박스 / 강조

| 클래스 | 용도 |
|---|---|
| `.highlight-box` | 녹색 왼쪽 테두리 기본 박스 |
| `.highlight-box-blue` / `-teal` / `-purple` / `-gray` | 4색 변형 + 회색 변형 |
| `.accent-box` | 녹색 그라디언트 배경 강조 |
| `.accent-box-emerald` | 연한 에메랄드 강조 |
| `.key-message-bar` | 슬라이드 하단 핵심 메시지 bar |

## 섹션 / 레이아웃

| 클래스 | 용도 |
|---|---|
| `.section-title` | 섹션 제목 (heading 아닌 텍스트 강조) |
| `.spacer-xs` (6px) / `.spacer-sm` (12px) / `.spacer-md` (24px) | 수직 여백 |
| `.compact-columns` | `::: columns` 래퍼로 폰트/line-height 축소 |
| `.reveal .columns` | 2단 컬럼 gap 30px |

## 그리드 / 카드

| 클래스 | 용도 |
|---|---|
| `.card`, `.card-grid` | 2열 기본 카드 |
| `.summary-grid`(3열) / `.summary-grid-4`(4열) / `.summary-grid-tight` | 요약 카드 |
| `.summary-item` + `.si-green / -blue / -teal / -purple / -gray` | 요약 카드 색상 변형 |
| `.step-grid-2` / `.step-grid-3` | 2·3 단계 카드 배치 |
| `.stat-grid`, `.stat-item`, `.mini-stat-grid`, `.stat-item .stat-number` | 통계 숫자 그리드 |

## 이유·근거·지표

| 클래스 | 용도 |
|---|---|
| `.reason-chip-grid`, `.reason-chip` + `.rc-green / -blue / -teal / -purple` | 2×2 이유 칩 |
| `.evidence-panel` + `.ep-blue / -gray / -purple` | 근거 패널 |
| `.metric-card`, `.scenario-card` + `.mc-purple / -teal`, `.sc-gray / -green / -purple` | 지표 카드 |
| `.metric-note`, `.metric-main`, `.metric-sub` | 지표 카드 내부 구성 |
| `.design-principle-grid`, `.design-principle` + `.dp-green / -teal / -gray` | 설계 원칙 |

## 프로세스 · 수식 플로우

| 클래스 | 용도 |
|---|---|
| `.process-flow`, `.pstep` + `.pstep-1 ... -5`, `.process-arrow`, `.step-label`, `.step-title`, `.step-desc` | 가로 5단계 프로세스 |
| `.formula-ladder`, `.ladder-item` + `.li-gray / -purple / -green`, `.ladder-arrow` | 세로 수식 사다리 |
| `.formula-flow`, `.flow-chip` + `.fc-green / -blue / -teal / -purple`, `.flow-sep` | 가로 수식 플로우 |
| `.formula-result` | 최종 결과 강조 (녹색 배경) |

## 표

| 클래스 | 용도 |
|---|---|
| `.proposal-table` | 헤더 진한 녹색 + 줄무늬 강조 테이블 (`.proposal-row`로 행 강조) |
| `.compact-table table` | 소형 우측정렬 테이블 |

## 회사소개 / 협력기관

| 클래스 | 용도 |
|---|---|
| `.service-grid`, `.service-box`, `.service-box-right` | 2열 서비스 소개 |
| `.contract-grid`, `.contract-card`, `.cc-title`, `.cc-badge`, `.cc-badge-blue` | 협력기관 카드 |
| `.synergy-grid`, `.synergy-box`, `.synergy-rd`, `.synergy-hospital`, `.syn-title` | R&D · Hospital 시너지 |
| `.client-grid`, `.client-item` | 6열 고객사/로고 나열 |
| `.hospital-simple`, `.hospital-simple-item` | 참여 병원 리스트 |
| `.mission-text` | 미션 선언문 (큰 line-height) |

## 결론 · 종료

| 클래스 | 용도 |
|---|---|
| `.conclusion-layout`, `.conclusion-hero`, `.conclusion-kicker`, `.conclusion-big`, `.conclusion-formula`, `.conclusion-sidegrid`, `.conclusion-card` + `.cc-gray / -purple / -green` | 왼쪽 hero + 오른쪽 근거 3장 구조 |
| `section[data-background-color="#2A3D21"] h1` | 감사합니다 슬라이드 (H1 흰색) |

## Slide-level modifiers

| 클래스 | 용도 |
|---|---|
| `.intro-slide` | 첫 도입 슬라이드 여백/폰트 축소 |
| `.conclusion-slide` | 결론 슬라이드 여백/폰트 축소 |
| `.thankyou-slide` | 마지막 감사 슬라이드 (보통 `background-color="#2A3D21"`) |

## 팁

- 특정 슬라이드만 스타일 조정: `.reveal .slides section.<slide-class> .<component>` 로 override
- 4색 구분감이 약하면 Palette C 블록에서 각 border 색의 채도를 올리거나 `border-bottom` 두께를 4px → 5px로 조정
- 새 컴포넌트를 추가하면 반드시 `base_slides_fullbg.qmd`에도 샘플을 추가해 렌더 결과를 확인
