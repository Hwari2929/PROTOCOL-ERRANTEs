# DESIGN_BINDER — BINDER 디자인 시스템 분석 & 에란테스 적용 사양

> 출처: 첨부 `BINDER — Curation Archive Design System`(soft brutalism + 세피아 종이 문구류).
> 이 문서는 BINDER를 에란테스(pe_game)에 이식하기 위한 분석 + 정확한 파라미터 + Godot 매핑.
> 기존 `DESIGN.md`(현 구현)와 함께 본다. BINDER는 그 방향의 "완성형 사양"이다.

## 0. 한 줄 요약
세피아 종이 책상 위에 물리적 사물(카드·클립·테이프·도장)을 올린 느낌. 두꺼운 잉크선 +
청키한 45° 오프셋 그림자(누르면 톡 붕괴) + 은은한 그레인 + 무라운드에 가까운 소량 라운드.

## 1. 색 토큰 (정밀값 — 현 구현 교체 대상)
```
paper-0 #f8f3e9 (카드면)  paper-1 #efe9dd (데스크)  paper-2 #e7e0d0 (침강)
paper-3 #ddd4c0 (깊은 침강) kraft #cdbb98
ink-0 #2f2a24 (본문·두꺼운 선) ink-1 #4a4138 ink-2 #6b5f51 ink-3 #8c7f6e ink-4 #a89c89(연한 구분선)
accent #b23a2e (archive red) accent-deep #8f2c22 (press) accent-soft #e9c9c1 (tint)
metal #b7b2a6 / wood #a87f4f / tape #e3dcc4cc(반투명)
success #3a5a40 warning #c98a2b danger #b23a2e info #2e4a6b
```
원칙: 저채도·웜. 그라데이션 금지(예외: vignette 1종, hero 컨테이너 집중용).

## 2. 타이포 (3역할 고정)
- **Paperlogy** (강조/디스플레이, ExtraBold 800·Black 900) — 제목·숫자·표지. *(보유)*
- **KoPubWorld Batang** (본문 명조 serif, 400/700) — 설명·캡션·긴 글. *(보유)*
- **JetBrains Mono** (라벨/카탈로그/코드, **UPPERCASE + letter-spacing 0.06~0.14em**) — `CAT-No. 2026-0317`, `ADDED 03·17`, 스탬프 메타라벨. **★ 미보유 → 번들 추가 필요.**
- 스케일: display 56/40/30/22, title 19, body 18/16/14, caption 13, mono 13/11. lh: display 1.1 / body(serif) 1.62 / mono 1.45.
- 캐주얼 규칙: UI 라벨=UPPERCASE 모노, 제목=문장형 Paperlogy, 본문=문장형 명조. 구분자=중점 `·`. **emoji 금지**(재질이 개성).

## 3. 보더 위계 (시그니처)
- `bw-hair 1.5px` 구분선/사진테두리(연한 ink-3/ink-4) · `bw 2px` 기본 · **`bw-bold 2.5px` 카드/컨트롤 바깥선(ink-0)** · `bw-heavy 3.5px` 강조/눌림판.
- **두꺼운 잉크선은 사물의 최외곽에만.** 구분선/내부경계는 더 얇고 연하게(구조가 먼저, 디테일 나중).
- divider-stitch = 1.5px **dashed** ink-4 (수공예 박음질 느낌).

## 4. 그림자 (★ 물리감의 핵심)
- 규칙 1개: **모든 그림자는 잉크선보다 연하고 우하향(≈45°)**. 직하/풀잉크 금지.
- `shadow-ink = rgba(47,42,36,0.40)` (키섀도 톤).
- 청키 키섀도: 버튼 평시 `shadow-pop = 3px 3px 0 shadow-ink` → 누르면 `1px 1px 0`로 **붕괴(톡톡)** + 객체가 `translateY(+2~4px)` 내려감. 들어올림 hover `translateY(-1~2px)` + 그림자 약간 커짐.
- 침강 입력: `shadow-inset = inset 0 2px 4px`.

## 5. 라운드/간격/모션
- radius: **xs 3 / sm 5 / md 8** (소프트 브루탈 = 거의 직각이나 0은 아님; 카드·사진 3~5px). pill은 토글만.
- 간격 4px 베이스(4/8/12/16/24/32/48/64/96).
- 모션: **ease-pop `cubic-bezier(.34,1.56,.64,1)`(오버슈트)**, ease-soft `(.2,.8,.2,1)`. dur-fast 120ms / dur 200ms. "톡톡 튀는 물리감". 긴 페이드·패럴랙스 금지.
- 그레인: 프랙탈 노이즈 SVG, opacity ~0.045. (Godot: FastNoiseLite로 대체 — 현재 사용 중)

## 6. 재질 사물 (CSS/그리기로, emoji 아님)
클립(=pinned, Lucide paperclip) · 인덱스 탭 · 마스킹 테이프(반투명) · 도장(stamp) · 카탈로그 라벨.
→ **에란테스의 압정(map-pin)이 이 어휘에 정확히 해당.** Lucide(stroke 1.75~2px, ink-0)는 기능 아이콘용.

## 7. 덱 애니메이션 체계 (tarot_deck — 정확한 파라미터)
흐름: **SHUFFLE → FAN/DRAW → DEAL → FLIP** (+ reversals/auto-flip).
- **덱 더미(face-down)**: 최대 7레이어, 각 `depth*2.5px` 좌상 오프셋.
- **셔플(리플)**: `tRiffleL/R` 1.1s `cubic-bezier(.34,1.3,.5,1)`, stagger `i*60ms`.
  L: 0→30% `translate(-74,-26) rot(-13°)` →60% `translate(-30,8) rot(-4°)` →100% 복귀. (R 좌우반전)
- **팬(fan)**: 총 **64°**, `angle = -32 + t*64` (t=i/(n-1)), `origin: bottom center`,
  `x = (t-0.5)*min(560, n*46)`px. 호버 **lift -46px**, zIndex 최상. transition `200ms ease-pop`.
  등장 `tFanIn .4s` stagger `i*28ms`: `translateY(40) scale(.8) opacity0 → opacity1`.
- **딜(슬롯 안착)**: `tDeal .52s ease-pop`: `translateY(-46) rot(-9°) scale(.62) opacity0 → 정상`.
- **플립(3D)**: perspective 1400, `preserve-3d`, `rotateY(faceUp?0:180)`, transition **560ms `cubic-bezier(.34,1.2,.5,1)`**, 앞/뒷면 `backface-visibility:hidden`. raised: `drop-shadow(5px 7px 0)` ↔ 평시 `3px 4px 0`.
- **reversed**: 앞면 내용 `rotate(180°)` + REVERSED 도장. 확률 38%.
- **카드 비율**: `h = w * 1.52`.

## 8. Godot 이식 매핑
- CSS transform → `Control.position/rotation/scale + pivot_offset` + `Tween`.
- ease-pop 오버슈트 → `Tween.TRANS_BACK + EASE_OUT` (정확일치 필요시 커스텀 Curve).
- `@keyframes`(tDeal/tFanIn/tRiffle) → 다단계 `Tween` 체인.
- 3D 플립 → 2D엔 rotateY 없음 → `scale.x` 1→0→-1 가짜 Y플립 + 중간에 앞/뒤 텍스처 교체.
- `box-shadow 3px3px0` → 카드 뒤 오프셋 그림자 노드(잉크색) → press시 1px로 tween.
- `--texture-paper` → `FastNoiseLite` 그레인.

## 9. 카드 기울임(틸트) 인터랙션 — BINDER 미수록, 에란테스 추가 사양
**의도**: 카드를 누른/터치한 채 **초기 지점에서 멀어질수록 그 방향으로 카드가 기우는** 입체 모션
(포인터를 따라 기우는 "3D tilt card").

**판단(2D vs 3D)**: **3D(Node3D/SubViewport+카메라)는 과함** — 2D UI 파이프라인을 깨고 입력/레이어가
복잡해진다.

**1차 시도(폐기): `canvas_item` 퍼스펙티브 셰이더 + `CanvasGroup`.** CanvasGroup으로 카드 복합 자식을
한 버퍼로 합성 후 `tilt: vec2` uniform 원근 왜곡을 입히려 했으나 — **CanvasGroup 버퍼가 프리멀티플라이드
알파라 카드가 흰색으로 뭉개짐.** `render_mode blend_premul_alpha`로도 해결 안 됨(틸트 0에서도, 틸트
중에도 흰색). 머티리얼 제거 시 정상 렌더 → 셰이더 합성 경로가 원인. **이 경로 폐기, 셰이더 삭제.**

→ **채택(구현 완료): Node2D 래퍼 + Control inner의 어파인(rotation + skew + scale).** 셰이더/CanvasGroup
없음. **핵심 통찰: 전단(skew/shear)이 깊이감의 결정적 단서** — 순수 회전만이면 평면 회전이지만, 회전 +
전단 + 약한 비대칭 축소를 조합하면 BINDER 톤 안에서 충분히 "기우는 입체"로 읽힘(검증 스크린샷 확인).

**구현(`scripts/ui/card_bar.gd`, 셰이더 없음)**:
- 카드 비주얼 8개 자식을 `Node2D vis`(카드 중앙 배치) 아래 `Control inner`(offset -중앙)에 담음 →
  vis의 rotation/skew/scale이 카드 중심 기준으로 회전. 클릭용 Button은 root 직속(형제, 비주얼 위).
- press(`button_down`)→`_begin_tilt(vis)`: vis 기록 + 시작 글로벌 좌표 기록.
- `_process`: 누르고 있는 동안 `off = 포인터-시작`으로 `vis.rotation = off.x*TILT_ROT`(좌우 회전),
  `vis.skew = off.y*TILT_SKEW`(상하 전단), `vis.scale`은 |off| 비례 약한 포어쇼트닝. 각 clamp.
- release(`button_up`)→`_end_tilt`: rotation/skew/scale → 0/1 으로 ease-pop(`TRANS_BACK/EASE_OUT 0.28s`) 복귀.
- 파라미터(card_bar 상수): `TILT_ROT 0.00095`, `TILT_SKEW 0.0016`, `TILT_SCALE 0.00065`,
  `TILT_ROT_MAX 0.17`, `TILT_SKEW_MAX 0.32`. 터치는 `emulate_mouse_from_touch`(Godot 기본 on) 커버.
- 부수효과: 멀리 끌고 카드 밖에서 손을 떼면 Button.pressed 미발동 → **자연스러운 사용 취소**.
- 교훈: **2D UI 카드 변형엔 CanvasGroup+셰이더보다 Node2D 어파인이 단순·견고.** 셰이더 합성은 premul
  알파 함정이 있고, skew만으로도 깊이감이 난다.

## 10. 적용 현황 (2026-06-23 기준 — 전부 구현 완료)
1. **JetBrains Mono 번들 추가** — ✅ (`Palette.F_MONO/F_MONO_BOLD`, 코스트·TP·DECK·기록·도장).
2. **색 토큰 전면 교체** — ✅ (`scripts/ui/palette.gd` 단일 출처 + `main_theme.tres`).
3. **radius 3~8px + 2.5px 보더 위계 + 톡톡 키섀도** — ✅ (테마 + Palette 팩토리).
4. **덱 팬/리플/딜** — ✅ (`card_bar.gd`: 팬 호, 리플 3단계, 다층 더미, 딜).
5. **드로우 플립** — ✅ (2D 가짜 Y플립, scale.x 엣지온→정면, 드로우 시에만).
6. **재질 사물(클립/테이프/도장)** — ✅ (`scripts/ui/decor.gd`). **압정은 제거**(유닛은 바닥 그림자만).

### 추가 구현(BINDER 미수록)
- **카드 틸트**(§9): 누른 채 드래그 시 포인터 방향 기욺(Node2D skew/scale/rotation).
- **사용 대기 큐**: 카드 클릭=즉시 사용 아닌 큐 토글, 전투 시작 시 일괄 사용(강조 UI 포함).
