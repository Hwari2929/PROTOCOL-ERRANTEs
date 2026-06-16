# 🍸 [프로젝트명 미정] — Game Design Document

> **장르**: 바 경영 시뮬레이터 + TFT식 오토배틀러 하이브리드
> **시점**: 2D 탑다운
> **플랫폼**: iPad (Xogot/Godot 4.x), 오프라인 완전 대응
> **엔진**: Godot 4.4+ (GDScript)

---

## 1. 게임 콘셉트 요약

플레이어는 **바(Bar)**를 운영하며 자원을 축적하고, 바 문을 닫으면 **전투 지휘소**로 전환되어 TFT식 오토배틀을 진행한다. 두 모드는 **양방향 순환 경제**로 연결된다.

### 핵심 루프

```
┌─────────────────────────────────────────────────────────┐
│                    메인 게임 루프                         │
│                                                         │
│   ┌──────────┐    바 닫기     ┌──────────────┐          │
│   │  바 경영  │ ───────────▶ │  전투 세션    │          │
│   │  (낮/영업) │ ◀─────────── │  (밤/전투)    │          │
│   └──────────┘    전투 종료    └──────────────┘          │
│        │                            │                    │
│        ▼                            ▼                    │
│   바 자원 (골드)              전투 자원 (토큰)            │
│   → 장비 가챠/강화             → 캐릭터 가챠              │
│   → 유물 구매                  → 모집된 캐릭터             │
│   → 바 업그레이드                  ↓                     │
│                              바에 등장하여:               │
│                              - 호감도 관리               │
│                              - 선물 주고받기              │
│                              - 알바생으로 고용            │
└─────────────────────────────────────────────────────────┘
```

---

## 2. 게임 상태 머신 (Game State Machine)

```
               ┌──────────┐
               │  TITLE   │
               └────┬─────┘
                    ▼
               ┌──────────┐
               │   MENU   │ ← 세이브/로드, 설정
               └────┬─────┘
                    ▼
         ┌──────────────────┐
         │    GAME_WORLD    │ ← 상위 상태
         │  ┌─────────────┐ │
         │  │  BAR_OPEN   │ │ ← 바 영업 중 (경영 모드)
         │  └──────┬──────┘ │
         │         ▼        │
         │  ┌─────────────┐ │
         │  │ BAR_CLOSING │ │ ← 전환 연출 (바→전투)
         │  └──────┬──────┘ │
         │         ▼        │
         │  ┌─────────────┐ │
         │  │   BATTLE    │ │ ← 전투 세션 (라운드제)
         │  │  ┌────────┐ │ │
         │  │  │PREP    │ │ │ ← 배치/상점 페이즈
         │  │  ├────────┤ │ │
         │  │  │COMBAT  │ │ │ ← 오토배틀 진행
         │  │  ├────────┤ │ │
         │  │  │RESULT  │ │ │ ← 라운드 결과
         │  │  └────────┘ │ │
         │  └──────┬──────┘ │
         │         ▼        │
         │  ┌─────────────┐ │
         │  │BATTLE_END   │ │ ← 전투 종료, 보상 정산
         │  └──────┬──────┘ │
         │         ▼        │
         │  ┌─────────────┐ │
         │  │ BAR_OPENING │ │ ← 전환 연출 (전투→바)
         │  └──────┬──────┘ │
         │         ▼        │
         │  (다시 BAR_OPEN) │
         └──────────────────┘
```

---

## 3. 씬 구조 (Scene Tree)

```
project/
├── scenes/
│   ├── main/
│   │   ├── Main.tscn                 # 루트 씬 (상태 머신 관리)
│   │   ├── TitleScreen.tscn
│   │   └── GameWorld.tscn            # BAR + BATTLE 을 모두 포함하는 상위 씬
│   │
│   ├── bar/
│   │   ├── Bar.tscn                  # 바 경영 메인 씬
│   │   ├── BarInterior.tscn          # 바 내부 환경 (탑다운 맵)
│   │   ├── Counter.tscn              # 카운터 (주문/제조 인터랙션)
│   │   ├── CustomerSpawner.tscn      # 손님 생성/관리
│   │   └── MenuBoard.tscn            # 메뉴판 UI
│   │
│   ├── battle/
│   │   ├── BattleSession.tscn        # 전투 세션 메인
│   │   ├── BattleBoard.tscn          # TFT식 그리드 보드
│   │   ├── UnitSlot.tscn             # 그리드 칸 하나
│   │   ├── BattleShop.tscn           # 라운드 간 상점
│   │   └── BattleHUD.tscn            # 전투 UI (HP, 라운드, 타이머)
│   │
│   ├── characters/
│   │   ├── CharacterBase.tscn        # 캐릭터 공통 베이스
│   │   ├── BarNPC.tscn               # 바에서의 NPC 표현
│   │   ├── BattleUnit.tscn           # 전투에서의 유닛 표현
│   │   └── CustomerNPC.tscn          # 일반 손님 (가챠 캐릭터와 별도)
│   │
│   └── ui/
│       ├── GachaScreen.tscn          # 가챠 화면
│       ├── InventoryScreen.tscn      # 인벤토리/장비 관리
│       ├── CharacterProfile.tscn     # 캐릭터 상세 (호감도 등)
│       ├── ChatBubble.tscn           # AI 잡담용 말풍선
│       └── SettingsMenu.tscn
│
├── scripts/
│   ├── core/
│   │   ├── GameManager.gd            # 전역 상태 머신
│   │   ├── SaveManager.gd            # 세이브/로드
│   │   ├── ResourceManager.gd        # 자원(골드/토큰) 관리
│   │   └── EventBus.gd               # 글로벌 시그널 버스
│   │
│   ├── data/
│   │   ├── CharacterData.gd          # Resource: 캐릭터 스탯/정보
│   │   ├── ItemData.gd               # Resource: 장비/유물 데이터
│   │   ├── MenuItemData.gd           # Resource: 바 메뉴 아이템
│   │   ├── GachaPoolData.gd          # Resource: 가챠 풀 설정
│   │   └── BattleStageData.gd        # Resource: 스테이지/라운드 구성
│   │
│   ├── bar/
│   │   ├── BarManager.gd             # 바 경영 로직 총괄
│   │   ├── CustomerAI.gd             # 손님 행동 패턴
│   │   ├── MenuSystem.gd             # 메뉴 제작/판매
│   │   ├── RelationshipManager.gd    # 호감도 시스템
│   │   └── WorkerSystem.gd           # 알바생 관리
│   │
│   ├── battle/
│   │   ├── BattleManager.gd          # 전투 세션 총괄
│   │   ├── BoardManager.gd           # 그리드 배치 관리
│   │   ├── CombatResolver.gd         # 오토배틀 전투 로직
│   │   ├── UnitController.gd         # 유닛 AI/행동
│   │   ├── ShopManager.gd            # 전투 상점
│   │   └── SynergySystem.gd          # 시너지/조합 효과
│   │
│   ├── gacha/
│   │   ├── GachaSystem.gd            # 가챠 로직 (확률, 천장)
│   │   ├── EquipmentGacha.gd         # 장비 가챠 (바 자원)
│   │   └── CharacterGacha.gd         # 캐릭터 가챠 (전투 자원)
│   │
│   └── ai_chat/
│       ├── ChatManager.gd            # AI 잡담 총괄
│       ├── APIClient.gd              # HTTP 요청 (무료 API)
│       ├── OfflineFallback.gd        # 오프라인 폴백 대사
│       └── PersonalityData.gd        # NPC 성격 프롬프트
│
├── resources/
│   ├── characters/                   # .tres 캐릭터 데이터
│   ├── items/                        # .tres 장비/유물 데이터
│   ├── menus/                        # .tres 메뉴 아이템
│   ├── stages/                       # .tres 전투 스테이지
│   └── gacha_pools/                  # .tres 가챠 풀
│
├── assets/
│   ├── sprites/
│   │   ├── characters/
│   │   ├── bar/
│   │   ├── battle/
│   │   ├── items/
│   │   └── ui/
│   ├── audio/
│   └── fonts/
│
├── CLAUDE.md                         # Claude Code 프로젝트 컨텍스트
└── project.godot
```

---

## 4. 핵심 데이터 모델

### 4.1 캐릭터 (이중 역할: 바 NPC + 전투 유닛)

```gdscript
# scripts/data/CharacterData.gd
class_name CharacterData
extends Resource

# === 기본 정보 ===
@export var id: StringName
@export var display_name: String
@export var rarity: int             # 1~5성
@export var portrait: Texture2D
@export var bar_sprite: SpriteFrames  # 바에서의 애니메이션
@export var battle_sprite: SpriteFrames  # 전투에서의 애니메이션

# === 전투 스탯 ===
@export var base_hp: int
@export var base_atk: int
@export var base_def: int
@export var base_spd: float
@export var attack_range: int       # 그리드 칸 수
@export var synergy_tags: Array[StringName]  # 시너지 태그 (예: "마법사", "전사")
@export var skill: SkillData        # 스킬 리소스

# === 바 정보 ===
@export var personality_prompt: String  # AI 잡담용 성격 프롬프트
@export var favorite_menu: StringName   # 좋아하는 메뉴
@export var offline_dialogues: Array[String]  # 오프라인 폴백 대사

# === 런타임 상태 (세이브 대상) ===
var level: int = 1
var experience: int = 0
var affection: int = 0            # 호감도 (0~100)
var is_worker: bool = false       # 알바생 여부
var equipped_items: Array[StringName] = []
```

### 4.2 장비/유물

```gdscript
# scripts/data/ItemData.gd
class_name ItemData
extends Resource

enum ItemType { WEAPON, ARMOR, ACCESSORY, RELIC }
enum ItemSource { BAR_GACHA, BATTLE_SHOP, CRAFT }

@export var id: StringName
@export var display_name: String
@export var type: ItemType
@export var source: ItemSource
@export var rarity: int
@export var icon: Texture2D

# 스탯 보정
@export var stat_modifiers: Dictionary  # {"atk": 10, "hp": 50, ...}

# 유물 전용: 전투 중 특수 효과
@export var relic_effect: StringName    # 효과 ID
@export var relic_description: String
```

### 4.3 메뉴 아이템

```gdscript
# scripts/data/MenuItemData.gd
class_name MenuItemData
extends Resource

@export var id: StringName
@export var display_name: String
@export var icon: Texture2D
@export var base_price: int         # 판매 가격 (골드)
@export var craft_time: float       # 제작 시간 (초)
@export var ingredients: Dictionary  # {"재료ID": 수량, ...}
@export var satisfaction: int       # 손님 만족도 기여
@export var unlock_level: int       # 해금 조건
```

### 4.4 자원 시스템

```gdscript
# scripts/core/ResourceManager.gd
class_name ResourceManager
extends Node

signal gold_changed(new_amount: int)
signal tokens_changed(new_amount: int)

var gold: int = 0        # 바 경영 자원 → 장비 가챠, 유물, 바 업그레이드
var tokens: int = 0      # 전투 자원 → 캐릭터 가챠

func add_gold(amount: int) -> void:
    gold += amount
    gold_changed.emit(gold)

func spend_gold(amount: int) -> bool:
    if gold >= amount:
        gold -= amount
        gold_changed.emit(gold)
        return true
    return false

func add_tokens(amount: int) -> void:
    tokens += amount
    tokens_changed.emit(tokens)

func spend_tokens(amount: int) -> bool:
    if tokens >= amount:
        tokens -= amount
        tokens_changed.emit(tokens)
        return true
    return false
```

---

## 5. 전투 시스템 상세

### 5.1 보드 구조

```
TFT식 헥스 또는 직사각 그리드 (예: 4x7 또는 6x6)

┌───┬───┬───┬───┬───┬───┐
│   │   │   │ E │ E │ E │  ← 적 배치 영역
├───┼───┼───┼───┼───┼───┤
│   │   │   │   │   │   │  ← 중립 지대
├───┼───┼───┼───┼───┼───┤
│ P │ P │   │   │   │   │  ← 플레이어 배치 영역
├───┼───┼───┼───┼───┼───┤
│   │ P │   │   │   │   │
└───┴───┴───┴───┴───┴───┘

P = 플레이어 유닛, E = 적 유닛
```

### 5.2 라운드 흐름

```
라운드 N 시작
    │
    ▼
┌──────────────┐
│ PREP 페이즈  │  30초 타이머
│ - 유닛 배치   │  드래그 앤 드롭
│ - 장비 장착   │
│ - 상점 이용   │  유닛 구매/판매, 유물 구매
│ - 시너지 확인  │
└──────┬───────┘
       ▼
┌──────────────┐
│ COMBAT 페이즈 │  자동 진행
│ - 유닛 이동   │  가까운 적 탐색
│ - 일반 공격   │  사거리 내 적 공격
│ - 스킬 발동   │  마나 차면 자동 사용
│ - 시너지 효과  │  조건 충족 시 버프
└──────┬───────┘
       ▼
┌──────────────┐
│ RESULT 페이즈 │
│ - 승/패 판정  │  남은 유닛 수 기반
│ - 피해 계산   │  패배 시 HP 감소
│ - 보상 지급   │  골드/아이템 드롭
└──────┬───────┘
       ▼
  라운드 N+1 (또는 세션 종료)
```

### 5.3 시너지 시스템

```gdscript
# scripts/battle/SynergySystem.gd
class_name SynergySystem
extends Node

# 시너지 정의 예시
# { "태그": { 필요수: { "효과": 값 } } }
const SYNERGIES := {
    "전사": {
        2: {"def_bonus": 15},
        4: {"def_bonus": 35, "thorns": 10},
    },
    "마법사": {
        2: {"spell_power": 20},
        4: {"spell_power": 45, "mana_regen": 5},
    },
    "암살자": {
        2: {"crit_chance": 15},
        4: {"crit_chance": 30, "crit_damage": 25},
    },
}

func calculate_active_synergies(units: Array[CharacterData]) -> Dictionary:
    var tag_counts: Dictionary = {}
    var active_effects: Dictionary = {}

    # 태그 카운트
    for unit in units:
        for tag in unit.synergy_tags:
            tag_counts[tag] = tag_counts.get(tag, 0) + 1

    # 활성 시너지 판별
    for tag in tag_counts:
        if tag in SYNERGIES:
            var count = tag_counts[tag]
            var best_tier = {}
            for threshold in SYNERGIES[tag]:
                if count >= threshold:
                    best_tier = SYNERGIES[tag][threshold]
            if best_tier.size() > 0:
                active_effects[tag] = best_tier

    return active_effects
```

---

## 6. 바 경영 시스템 상세

### 6.1 영업 흐름

```
바 영업 시작
    │
    ▼
손님 입장 (CustomerSpawner)
    │
    ├── 일반 손님 (랜덤 생성)
    │   └── 주문 → 제작 → 서빙 → 결제 (골드 획득)
    │
    ├── 가챠 캐릭터 (보유 캐릭터가 방문)
    │   ├── 주문 + 잡담 (AI / 오프라인 폴백)
    │   ├── 선물 주기 → 호감도 상승
    │   └── 좋아하는 메뉴 서빙 → 호감도 보너스
    │
    └── 알바생 (고용된 캐릭터)
        └── 자동 서빙/제작 보조 → 효율 상승

영업 종료 시:
    - 일일 정산 (수입/지출)
    - 바 닫기 → 전투 세션 진입 가능
```

### 6.2 AI 잡담 시스템

```gdscript
# scripts/ai_chat/ChatManager.gd
class_name ChatManager
extends Node

@export var api_endpoint: String = ""  # 무료 AI API
@export var timeout: float = 10.0

func request_chat(character: CharacterData, player_message: String) -> String:
    if not _is_online():
        return _get_offline_dialogue(character)

    var prompt := _build_prompt(character, player_message)
    var response := await _call_api(prompt)

    if response.is_empty():
        return _get_offline_dialogue(character)

    return response

func _build_prompt(character: CharacterData, message: String) -> String:
    return """당신은 바의 손님입니다.
이름: %s
성격: %s
상황: 플레이어가 운영하는 바에서 음료를 마시며 대화 중입니다.
짧고 자연스럽게 답하세요 (1~2문장).

플레이어: %s""" % [character.display_name, character.personality_prompt, message]

func _get_offline_dialogue(character: CharacterData) -> String:
    return character.offline_dialogues.pick_random()

func _is_online() -> bool:
    # 네트워크 상태 확인
    return OS.has_feature("web") or _ping_check()
```

---

## 7. 세이브 시스템

```gdscript
# scripts/core/SaveManager.gd
class_name SaveManager
extends Node

const SAVE_PATH := "user://save_data.json"

func save_game() -> void:
    var data := {
        "version": "0.1.0",
        "timestamp": Time.get_datetime_string_from_system(),

        # 자원
        "gold": ResourceManager.gold,
        "tokens": ResourceManager.tokens,

        # 보유 캐릭터 (런타임 상태)
        "characters": _serialize_characters(),

        # 인벤토리
        "inventory": _serialize_inventory(),

        # 바 상태
        "bar_level": BarManager.bar_level,
        "unlocked_menus": BarManager.unlocked_menus,

        # 진행도
        "highest_battle_stage": BattleManager.highest_stage,
        "total_days": GameManager.total_days,
    }

    var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
    file.store_string(JSON.stringify(data, "\t"))
    file.close()

func load_game() -> bool:
    if not FileAccess.file_exists(SAVE_PATH):
        return false
    var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
    var data = JSON.parse_string(file.get_as_text())
    file.close()
    if data == null:
        return false
    _apply_save_data(data)
    return true
```

---

## 8. 개발 로드맵 (MVP 우선순위)

### Phase 1: 코어 프레임워크
- [ ] 프로젝트 초기 설정 + 씬 구조 생성
- [ ] GameManager 상태 머신
- [ ] EventBus (글로벌 시그널)
- [ ] ResourceManager (골드/토큰)
- [ ] 기본 세이브/로드

### Phase 2: 바 경영 MVP
- [ ] 탑다운 바 내부 맵
- [ ] 손님 생성 + 이동 AI
- [ ] 기본 메뉴 제작/서빙
- [ ] 골드 수입 시스템

### Phase 3: 전투 MVP
- [ ] 그리드 보드 + 유닛 배치 (드래그 앤 드롭)
- [ ] 기본 오토배틀 (이동 → 공격)
- [ ] 라운드 흐름 (PREP → COMBAT → RESULT)
- [ ] 전투 상점 (유닛 구매/판매)

### Phase 4: 경제 순환
- [ ] 장비 가챠 (바 자원)
- [ ] 캐릭터 가챠 (전투 자원)
- [ ] 캐릭터 바 NPC화 (방문 + 호감도)
- [ ] 장비 장착/강화

### Phase 5: 시너지 + 깊이
- [ ] 시너지 시스템
- [ ] 유물 시스템
- [ ] 알바생 시스템
- [ ] 스테이지 진행 + 난이도

### Phase 6: AI 잡담 + 폴리시
- [ ] AI API 연동 (무료 API)
- [ ] 오프라인 폴백 대사
- [ ] 연출 (전환 애니메이션, 이펙트)
- [ ] 사운드/BGM

---

## 9. 기술 원칙

### 아키텍처 원칙
- **컴포넌트 기반**: 재사용 가능한 컴포넌트로 기능 분리
- **Resource 기반 데이터**: 모든 게임 데이터는 Godot Resource(.tres)로 관리
- **시그널 기반 통신**: 노드 간 직접 참조 최소화, EventBus 활용
- **상태 머신 패턴**: 게임 흐름, 전투, NPC 행동 모두 상태 머신

### 코드 컨벤션
- 클래스명: PascalCase (CharacterData, BattleManager)
- 변수/함수: snake_case (base_hp, calculate_damage)
- 시그널: past_tense (damage_dealt, round_ended)
- 상수: UPPER_SNAKE_CASE (MAX_BOARD_SIZE, PREP_TIMER)
- private 함수: _prefix (_calculate_internal)

### Claude Code 협업 규칙
- 씬 파일(.tscn/.tres)은 자율 하네스가 생성/수정 가능 (2026-06-16 갱신). 생성분은 Xogot에서 검수
- GDScript 파일은 Claude Code/하네스에서 작성/수정 가능
- PR 단위는 기능 단위로 작게 유지
- 커밋 메시지는 Conventional Commits (feat:, fix:, refactor:)
