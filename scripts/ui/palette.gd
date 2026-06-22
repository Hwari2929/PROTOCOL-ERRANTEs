class_name Palette
extends RefCounted
## BINDER 디자인 시스템 토큰 단일 출처. 색·라운드·보더·폰트 + 시그니처 청키 키섀도
## StyleBox 팩토리. 모든 UI 스크립트는 색/스타일을 하드코딩하지 말고 여기서 가져온다.
## (DESIGN_BINDER.md §1~5 참조)

# ── 색 토큰 (BINDER 정밀값) ─────────────────────────────────────────────
const PAPER0 := Color(0.972, 0.953, 0.914)  # #f8f3e9 카드면
const PAPER1 := Color(0.937, 0.914, 0.867)  # #efe9dd 데스크
const PAPER2 := Color(0.906, 0.878, 0.816)  # #e7e0d0 침강
const PAPER3 := Color(0.867, 0.831, 0.753)  # #ddd4c0 깊은 침강
const KRAFT  := Color(0.804, 0.733, 0.596)  # #cdbb98

const INK0 := Color(0.184, 0.165, 0.141)    # #2f2a24 본문·두꺼운 선
const INK1 := Color(0.290, 0.255, 0.220)    # #4a4138
const INK2 := Color(0.420, 0.373, 0.318)    # #6b5f51
const INK3 := Color(0.549, 0.498, 0.431)    # #8c7f6e
const INK4 := Color(0.659, 0.612, 0.537)    # #a89c89 연한 구분선

const ACCENT      := Color(0.698, 0.227, 0.180)  # #b23a2e archive red
const ACCENT_DEEP := Color(0.561, 0.173, 0.133)  # #8f2c22 press
const ACCENT_SOFT := Color(0.914, 0.788, 0.757)  # #e9c9c1 tint

const SUCCESS := Color(0.227, 0.353, 0.251)  # #3a5a40
const WARNING := Color(0.788, 0.541, 0.169)  # #c98a2b
const INFO    := Color(0.180, 0.290, 0.420)  # #2e4a6b

const SHADOW := Color(0.184, 0.165, 0.141, 0.40)  # 키섀도 톤

# ── 라운드/보더 ────────────────────────────────────────────────────────
const R_XS := 3
const R_SM := 5
const R_MD := 8
const BW := 2          # 기본 선
const BW_BOLD := 3     # 카드/컨트롤 바깥선(2.5px 반올림)

# ── 폰트 경로 ──────────────────────────────────────────────────────────
const F_BODY := "res://assets/fonts/KoPubBatang-Medium.ttf"      # 본문 명조
const F_HEAD := "res://assets/fonts/Paperlogy-8ExtraBold.ttf"    # 제목 강조
const F_MONO := "res://assets/fonts/JetBrainsMono-Medium.ttf"    # 라벨/카탈로그
const F_MONO_BOLD := "res://assets/fonts/JetBrainsMono-Bold.ttf"


static func font(path: String) -> FontFile:
	return load(path) if ResourceLoader.exists(path) else null


## 청키 45° 키섀도를 StyleBoxFlat에 입힌다(블러 없는 단색 오프셋 → "톡톡" 물리감).
static func with_key_shadow(sb: StyleBoxFlat, off := Vector2(3, 3)) -> StyleBoxFlat:
	sb.shadow_color = SHADOW
	sb.shadow_size = 0
	sb.shadow_offset = off
	return sb


## 종이 카드면(가장 밝은 면 + 두꺼운 잉크 외곽선 + 소량 라운드 + 키섀도).
static func card_face(radius: int = R_SM, shadow := Vector2(3, 3)) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = PAPER0
	sb.set_border_width_all(BW_BOLD)
	sb.border_color = INK0
	sb.set_corner_radius_all(radius)
	return with_key_shadow(sb, shadow)


## 일반 패널(데스크 톤 + 잉크 선 + md 라운드).
static func panel_box(radius: int = R_MD, shadow := Vector2(3, 3)) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = PAPER1
	sb.set_border_width_all(BW)
	sb.border_color = INK0
	sb.set_corner_radius_all(radius)
	sb.content_margin_left = 14
	sb.content_margin_right = 14
	sb.content_margin_top = 12
	sb.content_margin_bottom = 12
	return with_key_shadow(sb, shadow)


## 침강(헤더/메타) 칩 — 라벨 배경 등.
static func chip_box(bg: Color = PAPER2, radius: int = R_XS) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	sb.set_border_width_all(BW)
	sb.border_color = INK0
	sb.set_corner_radius_all(radius)
	sb.content_margin_left = 8
	sb.content_margin_right = 8
	sb.content_margin_top = 3
	sb.content_margin_bottom = 3
	return sb
