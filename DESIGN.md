# PROTOCOL ERRANTES — 디자인 시스템

> 매너: **세피아 빈티지 · DIY 펑크 · 종이/영수증 감성 · 그레인 텍스처.**
> 깨끗한 인쇄물/등사 전단지/현장 서류철처럼. 광택·3D·네온 금지.
> **2026-06-22: BINDER 소프트 브루탈리즘 토큰 채택.** 정밀 사양은 `DESIGN_BINDER.md`,
> 코드 단일 출처는 **`scripts/ui/palette.gd` (`class_name Palette`)** — 색·라운드·보더·폰트·
> 청키 키섀도 StyleBox 팩토리. 새 UI는 색/스타일을 하드코딩하지 말고 `Palette`에서 가져온다.

## 1. 팔레트 (BINDER — `Palette` 상수가 단일 출처)

| 역할 | 토큰 | HEX |
|------|-----|-----|
| 카드면(가장 밝음) | `Palette.PAPER0` | `#f8f3e9` |
| 데스크/배경(clear_color) | `Palette.PAPER1` | `#efe9dd` |
| 침강/일러스트박스 | `Palette.PAPER2` / `PAPER3` | `#e7e0d0` / `#ddd4c0` |
| 잉크(본문·두꺼운 선) | `Palette.INK0` | `#2f2a24` |
| 잉크 보조 | `Palette.INK1~INK3` | `#4a4138`~`#8c7f6e` |
| 연한 구분선 | `Palette.INK4` | `#a89c89` |
| 아카이브 레드(강조/위험) | `Palette.ACCENT` / `ACCENT_DEEP` | `#b23a2e` / `#8f2c22` |
| 성공/경고/정보 | `Palette.SUCCESS`/`WARNING`/`INFO` | `#3a5a40`/`#c98a2b`/`#2e4a6b` |
| 키섀도 톤 | `Palette.SHADOW` | `rgba(47,42,36,.40)` |

본문 텍스트는 **항상 짙은 잉크색**(`INK0`). 그라데이션 금지(예외: vignette 1종).

## 2. 타이포그래피

- **본문**: `KoPubBatang-Medium` (명조/세리프 — 인쇄물 느낌). 테마 default_font. `Palette.F_BODY`.
- **헤더/강조(펑크 포스터)**: `Paperlogy-8ExtraBold` / `9Black`. 아카이브 레드. `Palette.F_HEAD`.
- **라벨/카탈로그/수치(★ 신규)**: `JetBrains Mono` Medium/Bold — **대문자 + 자간**.
  코스트·TP·DECK·기록 라인 등 영문/숫자 메타라벨에. `Palette.F_MONO` / `F_MONO_BOLD`.
  (한글은 모노 미지원 → 한글 라벨엔 쓰지 말 것.)

## 3. 패널·버튼 매너 (BINDER 소프트 브루탈리즘)

- **소량 라운드**: `R_XS 3 / R_SM 5 / R_MD 8`(0 아님). 버튼=5, 패널=8, 일러스트박스=3.
- 테두리: **잉크색 2px**(기본) / **3px**(카드·컨트롤 바깥선, `BW_BOLD`).
- **★ 청키 45° 키섀도(시그니처)**: 블러 없는 단색 오프셋 `shadow_offset (3,3)`, `shadow_size 0`,
  톤 `Palette.SHADOW`. 눌림 시 `(1,1)`로 붕괴 + 콘텐츠 2px 하강 → "톡톡" 물리감.
- 버튼 눌림: **잉크 채움 + 종이색 글씨**(스탬프 반전) + 키섀도 붕괴.
- 호버: 종이 약간 어둡게(`PAPER2`) + 테두리 아카이브 레드 + 키섀도 약간 커짐.
- 이 규칙은 `assets/theme/main_theme.tres`에 박혀 있어 모든 Control이 상속.
  코드에서 패널이 필요하면 **`Panel` 노드 + `Palette.panel_box()`/`card_face()`** 사용.
  raw ColorRect는 단색 면(`Palette.PAPER*`)에만.

## 4. 텍스처 처리

- 배경: `scripts/ui/background.gd` (CanvasLayer −10) = **크림 `clear_color`(0.82,0.76,0.64)
  위에 절차적 필름 그레인(FastNoiseLite, 낮은 불투명도)만**. 배경 이미지 없음.
- **전투 배경 그래픽은 전면 제거** (2026-06-20). 종이 텍스처/지도/3D 모두 미사용
  (`assets/ui/paper.png`, `assets/bg/*`는 카드·생성용으로만 잔존, 화면 배경엔 안 씀).
  분위기는 크림 톤 + 그레인으로만.

## 5. 새 UI를 추가할 때

1. 색은 위 팔레트에서만 고른다. 임의 색 금지.
2. 버튼/패널은 `Button`/`Panel` 노드 → 테마 자동. 폰트 사이즈만 오버라이드.
3. 직접 그리는 요소(_draw)는 잉크/세피아/스탬프 레드로. 종이 위 어두운 잉크 원칙.
4. RichTextLabel은 `default_color`를 잉크로 오버라이드 후 bbcode `[color=#5c4d39]`(세피아)/`#8a662a`(골드)/`#4d6a30`(올리브)/스탬프 레드만 사용.

## 6. 모션 & 게임 필 (Tween 기반, 절대 정적 금지)

- **카드** (`card_bar.gd`, BINDER §7): 종이 페이스 + 우하단 **다층 덱 더미**(6층, 좌상 2.5px
  오프셋). **팬(부채꼴)**=손패를 중앙 기준 완만한 호로 펼침(중앙↑, 가장자리↓+회전 `FAN_STEP`).
  **딜+플립**=덱에서 엣지온(scale.x≈0)으로 날아와 팬 위치에서 펼쳐지는 2D 가짜 Y플립(BACK, 스태거).
  **호버**=들어올림+똑바로 펴짐+확대.
  **리플 셔플**=두 더미로 갈라졌다 호를 그리며 맞물려 복귀(좌/우 교대, `shuffled` 시그널).
  **사용 대기 큐**: 클릭=즉시 사용 아닌 큐 등록(재클릭=취소), 등록 시 똑바로 펴지며 들리고
  아카이브 레드 외곽선+'출격 대기' 탭; `전투 시작` 시 `commit_pending()`으로 일괄 사용.
  카드 누른 채 드래그=포인터 방향 틸트(`vis` Node2D skew/scale/rotation).
- **배치 모션**: 전투 진입 시 `unit.play_deploy(delay)` — 작게 시작해 팝업(BACK), 좌→우 스태거.
- **상태이상 그래픽**: `unit._draw`가 체력바 위에 색 점 배지(잉크 테두리) — 상태별 색
  (출혈 적/연소 주황/중독 녹/강조 스탬프레드/취약 보라/검흔 회/심판 금/초과체력 청/기절 노/제압 갈).
  `_status_badges()`가 활성 상태 색 목록 반환. 매 프레임 queue_redraw.
- **기술 범위 표시**: `RangeFX.spawn(host, center, radius, color)` — 잉크 링이 퍼지며 소멸.
  `unit.show_skill_text`에서 기술 시전 시 자동 호출(반경=사거리).
- **에셋 생성 규칙**: 새 카드/아이콘/스프라이트는 **종이 질감 + 잉크/DIY 테두리** 유지
  (Flux 프롬프트에 "aged sepia paper, hand-drawn DIY ink border, grunge, flat scan" 포함).
  배경 3D/네온 금지.

## 7. 카드 레이아웃 & 기물/지도 (확립됨)

- **카드** (슬더슬식, `card_bar.gd`): 상단=카테고리 색 띠 + 이름 + 코스트 원형 스탬프,
  중앙=일러스트(카테고리별 `assets/ui/cards/<cat>.png`, 평면 벡터+그레인), 하단=효과.
  종이 텍스처는 alpha 0.22 은은한 오버레이. 카테고리: fire/melee/vitality/armor/speed/
  range/skill/tactic (CARD_CAT 매핑 + CAT_COLOR 액센트). 새 카드 추가 시 CARD_CAT에 매핑.
- **기물 스프라이트**: 손그림 두들(볼펜+마커) 스타일, 모던~근미래 전술 요원, 경장비/개성 위주
  (중장갑 금지). 스페이스 오페라 크루 감성. magenta 배경 생성 후 **flood-fill 제거**
  (`agent_harness/reprocess_art.py` — 코너 키 방식은 Flux가 종이 테두리를 그려 실패하므로
  가장자리 연결된 마젠타+크림을 BFS 제거, 중앙 도형 보존). 생성: `agent_harness/gen_art2.py`.
- **기물 접지**: 유닛은 `unit._draw_ground_shadow()`로 **바닥 그림자만** 그린다(압정/핀 제거됨, 2026-06-23).
  배경 지도도 제거 — §4 참고. 평평한 크림 종이 위 그림자로 접지감만 유지.
- **재질 사물** (`scripts/ui/decor.gd`, `class_name Decor`): BINDER 물리 사물(emoji 아닌 _draw).
  `Decor.tape(w,h,각도)` 마스킹 테이프(반투명, 모서리), `Decor.clip()` 종이 클립(잉크 이중 루프,
  상단 걸침), `Decor.stamp(text,각도)` 고무 도장(이중 테두리+대문자 모노 아카이브 레드).
  적용: 팀편성/서브클래스/유닛정보 패널 모서리 테이프, 팀카드·덱 더미 클립, 타이틀 도장. **압정 미사용.**
- **적(군체) 디자인**: 웨이브 유형별 스프라이트 분리 — swarm/spitter/swarmling + boss(1.5배).
  `battle_field._spawn_normal_wave`가 유형별 sprite_id 전달, 동일 디자인 금지.
