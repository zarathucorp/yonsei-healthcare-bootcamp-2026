# 2026 여름 디지털 헬스케어 부트캠프

연세의료원 2026 여름 디지털 헬스케어 부트캠프 강의자료 페이지입니다. 수업 중에는 이 페이지에서 일정과 강의자료를 확인하면 됩니다. 링크가 있는 항목을 누르면 해당 강의자료로 이동합니다.

## 수업 전 준비

1. [Posit Cloud](https://posit.cloud)에 가입하거나 개인 노트북에 RStudio를 설치합니다.
2. R 데이터분석 참고자료: [r-skku-biohrs](https://github.com/jinseob2kim/r-skku-biohrs)
3. CDM 참고자료: [The Book of OHDSI Korea](https://ohdsi-korea.github.io/TheBookOfOhdsiKorea/)

## 기본반 1일차: 7/20

| 시간 | 교육주제 | 교육세부내용 | 강사 |
|---|---|---|---|
| 09:30 ~ 10:30 | OT 및 목표 설정 | 과정 전반 소개 | 김진섭 |
| 10:30 ~ 11:30 | 통계이론 | [가능도/정규분포](https://zarathucorp.github.io/yonsei-healthcare-bootcamp-2026/2026-07-20-1030-likelihood-normal/index.html), [의학연구 위한 기초통계(Table 1)](https://zarathucorp.github.io/yonsei-healthcare-bootcamp-2026/2026-07-20-1030-basic-statistics-table1/index.html), [code](https://github.com/zarathucorp/yonsei-healthcare-bootcamp-2026/blob/main/code/2026-07-20-1030-basic-statistics-regression-survival.R) | 김진섭 |
| 11:30 ~ 12:30 | 점심시간 |  |  |
| 12:30 ~ 13:30 | AI agent로 R분석하기 | [AI agent 설치 및 기초실습](https://zarathucorp.github.io/yonsei-healthcare-bootcamp-2026/2026-07-20-1230-r-ai-agent-install/index.html) | 김진섭 |
| 13:30 ~ 14:30 | R 데이터매니지먼트 | [R 기본 스타일](https://zarathucorp.github.io/yonsei-healthcare-bootcamp-2026/2026-07-20-1330-r-basic-style/index.html), [code](https://github.com/zarathucorp/yonsei-healthcare-bootcamp-2026/blob/main/code/2026-07-20-1330-r-basic-style.R) | 김진섭 |
| 14:30 ~ 15:00 | R 데이터매니지먼트 | [tidyverse 스타일](https://zarathucorp.github.io/yonsei-healthcare-bootcamp-2026/2026-07-20-1430-tidyverse-style/index.html), [code](https://github.com/zarathucorp/yonsei-healthcare-bootcamp-2026/blob/main/code/2026-07-20-1430-tidyverse-style.R) | 김진섭 |
| 15:30 ~ 16:00 | R 데이터매니지먼트 | [data.table 스타일](https://zarathucorp.github.io/yonsei-healthcare-bootcamp-2026/2026-07-20-1530-data-table-style/index.html), [code](https://github.com/zarathucorp/yonsei-healthcare-bootcamp-2026/blob/main/code/2026-07-20-1530-data-table-style.R) | 김진섭 |

## 기본반 2일차: 7/21

| 시간 | 교육주제 | 교육세부내용 | 강사 |
|---|---|---|---|
| 09:30 ~ 10:30 | 통계이론2 | [회귀/생존분석](https://zarathucorp.github.io/yonsei-healthcare-bootcamp-2026/2026-07-21-0930-regression-survival/index.html), [code](https://github.com/zarathucorp/yonsei-healthcare-bootcamp-2026/blob/main/code/2026-07-21-0930-regression-survival.R) | 김진섭 |
| 10:30 ~ 11:30 | RCT 이해 | [RCT란?, RACING trial로 배우는 RCT](https://zarathucorp.github.io/yonsei-healthcare-bootcamp-2026/2026-07-20-0930-orientation/index.html), [NEJM/Lancet/JAMA 논문으로 배우는 RCT 개념과 통계](https://jinseob2kim.github.io/lecture-general/yonsei_conf/) | 김진섭 |
| 11:30 ~ 12:30 | 점심시간 |  |  |
| 12:30 ~ 13:30 | AGENT.md 만들기 | [의학연구위한 AGENT.md 만들기](https://zarathucorp.github.io/yonsei-healthcare-bootcamp-2026/2026-07-21-1230-medical-research-agent-md/index.html) | 김진섭 |
| 13:30 ~ 14:30 | RCT 실습 | [RCT 예시데이터 분석결과 재현](https://zarathucorp.github.io/yonsei-healthcare-bootcamp-2026/2026-07-21-1330-rct-reproduction-project/index.html) | 김진섭 |
| 14:30 ~ 15:30 | 연사 특강 | [의사의 길: 나만의 특이점을 찾아서](https://zarathucorp.github.io/yonsei-healthcare-bootcamp-2026/2026-07-21-1430-physician-path/index.html) | 김진섭 |
| 15:30 ~ 16:00 | 기본반 수료식 | [수료증 및 기념품 전달](https://zarathucorp.github.io/yonsei-healthcare-bootcamp-2026/2026-07-21-1530-completion/index.html) | 김진섭 |

## 심화반 1일차: 7/22

| 시간 | 교육주제 | 교육세부내용 | 강사 |
|---|---|---|---|
| 09:30 ~ 10:30 | SCRAP 설명 및 시연 | CDW 소개, EMR 원자료와 CDW 차이, CDW 데이터 구조, 검색 조건, JOIN 개념 | 박이주 |
| 10:30 ~ 11:30 | SCRAP 실습 | SCRAP 화면과 기능 소개, 조건 검색 및 코호트 추출 실습 | 박이주 |
| 11:30 ~ 12:30 | 점심시간 |  |  |
| 12:30 ~ 13:30 | RWD(Real World Data) 이해 | [RWD 소개 및 RCT와의 비교](https://zarathucorp.github.io/yonsei-healthcare-bootcamp-2026/2026-07-22-1230-cdm-intro/index.html) | 김진섭 |
| 13:30 ~ 14:30 | CDM(Common Data Model) 이해 | [CDM 개념](https://zarathucorp.github.io/yonsei-healthcare-bootcamp-2026/2026-07-22-1230-cdm-intro/index.html) | 김진섭 |
| 14:30 ~ 15:30 | CDM 로 RCT재현(1) | [CDM estimation 패키지 만들기 in ATLAS](https://zarathucorp.github.io/yonsei-healthcare-bootcamp-2026/2026-07-22-1430-cdm-estimation-atlas/index.html) | 김진섭 |
| 15:30 ~ 16:00 | CDM 로 RCT재현(2) | [R패키지 실행 및 결과 확인](https://zarathucorp.github.io/yonsei-healthcare-bootcamp-2026/2026-07-22-1530-r-package-results/index.html), [code](shttps://github.com/zarathucorp/yonsei-healthcare-bootcamp-2026/blob/main/code/2026-07-22-1530-cdm-rpackage-run.R) | 김진섭 |

## 심화반 2일차: 7/23

| 시간 | 교육주제 | 교육세부내용 | 강사 |
|---|---|---|---|
| 09:30 ~ 10:00 | OMOP CDM 의료영상 확장(MI-CDM) | 정형 데이터와 영상 데이터의 연계와 활용, DICOM 이해, OMOP CDM 연결 구조와 사용 가이드 | 전규리 |
| 10:00 ~ 10:30 | ECG 데이터 특성, 전처리 및 MIMIC-IV-ECG 소개 | ECG 데이터 이해, 전처리, AFib 라벨링, 1D-CNN 모델과 주요 평가지표 | 김민성 |
| 10:30 ~ 11:00 | DICOM 및 MIMIC-CXR 소개 | DICOM 구조, 영상 데이터 전처리, MIMIC-CXR 구조와 라벨링 확인 | 김규섭 |
| 11:00 ~ 11:30 | 의료 데이터 전처리부터 머신러닝/딥러닝 모델 개발-검증까지 | 머신러닝/딥러닝 모델과 문제정의, 모델 학습의 패러다임과 데이터 전처리, 모델 평가 및 검증 | 기연우 |
| 11:30 ~ 12:30 | 점심시간 |  |  |
| 12:30 ~ 13:00 | RStudio 환경에서 CDM 연결 후 이미지 경로 추출하기 | CDM 연결, 환자 코호트 구성, Jupyter 환경에서 이미지 로드 | 김민성 |
| 13:00 ~ 14:30 | MIMIC-IV-ECG로 AFib 탐지 모델 개발 및 평가 | ECG 데이터 로드·시각화, 코호트 구성, 1D-CNN AFib 예측 모델 학습과 성능 해석 | 김민성 |
| 14:30 ~ 16:00 | MIMIC-CXR로 이미지 분류 모델 개발 및 평가 | DICOM 파일과 메타데이터, 흉부 X-ray 전처리, DataLoader 구성, 분류 모델 학습과 결과 확인 | 김규섭 |
| 시간 협의 중 | 프로젝트 작업 | 프로젝트 멘토링 | 김민성, 김규섭, 기연우 |

## 심화반 3일차: 7/24

| 시간 | 교육주제 | 교육세부내용 | 강사 |
|---|---|---|---|
| 09:30 ~ 10:30 | 프로젝트 작업 | 팀별 Mimic CDM 프로젝트 수행 및 분석 방향 멘토링 | 김진섭 |
| 10:30 ~ 11:30 | 프로젝트 작업 | 분석 결과 정리 및 발표 자료 제작 | 김진섭 |
| 11:30 ~ 12:30 | 점심시간 |  |  |
| 12:30 ~ 13:30 | 발표회 | 발표회 | 김진섭 |
| 13:30 ~ 14:30 | 발표회 | 발표회 | 김진섭 |
| 14:30 ~ 15:00 | 발표회 및 시상 | 발표회 및 시상 | 김진섭 |
