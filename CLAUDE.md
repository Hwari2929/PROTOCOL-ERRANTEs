# CLAUDE.md — 프로젝트 컨텍스트

## 프로젝트 개요
바 경영 시뮬레이터 + TFT식 오토배틀러 하이브리드 게임.
Godot 4.4+, GDScript, 2D 탑다운, iPad(Xogot) 개발, 완전 오프라인 대응.

## 핵심 구조
- **바 경영 모드**: 손님 응대, 메뉴 제작/판매, 캐릭터 호감도, 알바생 관리
- **전투 모드**: TFT식 라운드제 오토배틀 (배치 → 전투 → 상점 → 반복)
- **경제 순환**: 바 자원(골드) → 장비/유물, 전투 자원(토큰) → 캐릭터 가챠
- **캐릭터 이중 역할**: 전투 유닛 + 바 NPC (호감도/선물/알바)

## 아키텍처 원칙
1. **컴포넌트 기반**: 기능별 분리, 재사용 가능하게
2. **Resource 기반 데이터**: 모든 게임 데이터는 .tres (CharacterData, ItemData 등)
3. **시그널 기반 통신**: EventBus 글로벌 시그널, 노드 간 직접 참조 최소화
4. **상태 머신 패턴**: GameManager, BattleManager, NPC AI 모두 상태 머신

## 코드 컨벤션
- 클래스명: PascalCase (CharacterData, BattleManager)
- 변수/함수: snake_case (base_hp, calculate_damage)
- 시그널: past_tense (damage_dealt, round_ended, gold_changed)
- 상수: UPPER_SNAKE_CASE (MAX_BOARD_SIZE, PREP_TIMER)
- private: _prefix (_calculate_internal)
- 커밋: Conventional Commits (feat:, fix:, refactor:, docs:)

## 디렉토리 구조
- scenes/ — .tscn 씬 파일 (bar/, battle/, characters/, ui/)
- scripts/ — .gd 스크립트 (core/, data/, bar/, battle/, gacha/, ai_chat/)
- resources/ — .tres 데이터 (characters/, items/, menus/, stages/, gacha_pools/)
- assets/ — 스프라이트, 오디오, 폰트

## 작업 규칙
- .tscn/.tres 파일: **자율 하네스가 생성/수정 가능** (전투 슬라이스 자율 빌드 위해 컨벤션 갱신, 2026-06-16). 하네스 생성분은 Xogot에서 받아 검수/미세조정.
- .gd 파일: Claude Code/하네스에서 작성/수정 가능. PR 단위로 작게.
- 새 스크립트 작성 시: class_name 필수, 적절한 디렉토리에 배치.
- 모든 public 함수에 타입 힌트 필수.
- 복잡한 로직은 별도 함수로 분리, 한 함수 50줄 이하 지향.

## 주요 싱글톤 (Autoload)
- GameManager: 게임 상태 머신 (BAR_OPEN, BATTLE 등)
- EventBus: 글로벌 시그널 버스
- ResourceManager: 골드/토큰 관리
- SaveManager: 세이브/로드

## 전투 시스템 요약
- 그리드 보드 (직사각형, 크기 미정)
- 페이즈: PREP(배치/상점) → COMBAT(오토배틀) → RESULT(정산)
- 유닛은 CharacterData 기반, 시너지 태그로 조합 효과
- 오토배틀: 가까운 적 탐색 → 이동 → 사거리 내 공격 → 마나 차면 스킬

## AI 잡담 시스템
- 무료 AI API (온라인 시), 오프라인 폴백 대사
- 분위기용 1~2문장 짧은 응답
- 캐릭터별 personality_prompt로 개성 부여

## 참고
- GDD.md: 전체 게임 디자인 문서
- 이 프로젝트는 iPad(Xogot)에서 개발되며 Working Copy로 Git 관리
