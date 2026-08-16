# 대냥시대 Godot 프로젝트 작업 지침

## Registry 향후 개편 결정

- 현재 `GamepieceRegistry`는 `등록 = 위치 추적 = 셀 점유 = 이동 차단` 구조를 유지한다.
- Fish, Coin, Effect처럼 격자 셀을 점유하지 않는 객체는 당분간 `Gamepiece`가 아닌 `Area2D` 또는 `Node2D` 계층으로 구현한다.
- 객체별 `registry`/`nonregistry` 그룹 두 개나 단순 `use_registry` 플래그는 지금 도입하지 않는다.
- 동일 셀에 여러 추적 객체가 필요하거나, 위치는 추적하지만 이동을 막지 않는 객체가 실제로 필요해지면 Registry 개편 시점으로 판단한다.
- 개편 시 `RegistryMode { NONE, BLOCKING, TRACKED }` enum을 우선 설계안으로 사용한다.
- `TRACKED` 도입 시 셀 차단 저장소와 객체 위치 추적 저장소를 분리하고, Pathfinder는 `BLOCKING` 객체에만 반응하도록 함께 수정한다.

이 저장소는 GDQuest Godot Open RPG 데모를 기반으로 제작 중인 탑뷰 RPG/전략 게임 **대냥시대**다. 주인공 고양이 삐용이 고양이 마을에서 다른 고양이들을 포섭하고 세력을 확장해 마을의 1짱이 되는 게임을 목표로 한다.

## 실행 환경

- Godot 4.7, GL Compatibility
- 메인 씬: `res://src/main.tscn`
- 프로젝트 설정: `project.godot`
- 개발자 테스트 씬: `res://src/dev/dev_test_lab.tscn`

## 중요한 보존 규칙

- 사용자 요청 없이 기존 오버월드 캐릭터나 오버월드 구조를 교체하지 않는다.
- 새 고양이 삐용 캐릭터는 현재 `GRLAB` 개발자 테스트 공간에서만 사용한다.
- 삐용 스프라이트는 원본 픽셀을 확대·축소·재보간하지 않는다. GRLAB 카메라 줌은 현재 `Vector2.ONE`이다.
- 개발자 공간에서도 카메라를 직접 조작하지 않는다. 캐릭터가 이동하고 카메라가 캐릭터를 추적한다.
- 기존 프로젝트 내용을 삭제하거나 대규모로 재구성하기 전에 사용자에게 범위를 확인한다.
- `.godot/`은 생성 캐시다. 구현 판단은 원본 `.gd`, `.tscn`, `.tres`, 애셋 파일을 기준으로 한다.

## 현재 커스텀 기능

### 개발자 콘솔

- Autoload: `DeveloperConsole`
- 파일: `src/dev/developer_console.gd`, `src/dev/developer_console.tscn`
- `\` 키로 콘솔을 연다.
- `GRLAB`: 개발자 테스트 공간으로 이동
- `MAIN` 또는 `RETURN`: 기존 게임으로 복귀
- `HELP`, `CLEAR` 지원

### GRLAB

- 파일: `src/dev/dev_test_lab.gd`, `src/dev/dev_test_lab.tscn`
- 맵: `assets/maps/my_map_compact.json`
- 맵 크기: 158×154, 셀 크기 16×16
- 기존 오버월드와 동일하게 `Gamepiece`, `PlayerController`, `Gameboard.pathfinder`, `GamepieceRegistry`를 사용한다.
- WASD/방향키 및 지도 클릭 이동을 지원한다.
- 물, 오브젝트, 명시적 충돌 셀은 경로 탐색에서 제외한다.
- `RemoteTransform2D`를 통해 카메라가 이동 애니메이션을 추적한다.
- 프로젝트 오브젝트 미리보기 갤러리가 함께 표시된다.

### 삐용 GRLAB 전용 캐릭터

- 원본 보존: `assets/characters/bbiyong/bbiyong_source.png`
- 정리된 시트: `assets/characters/bbiyong/bbiyong_lab_sheet.png`
- 전용 장면: `assets/characters/bbiyong/bbiyong_lab_gfx.tscn`
- 전용 애니메이션 스크립트: `assets/characters/bbiyong/bbiyong_lab_animation.gd`
- 프레임 크기: 320×330, 4열×4행
- 행 방향: 남, 서, 북, 동
- 애니메이션: `idle_s/w/n/e`, `run_s/w/n/e`
- `src/main.tscn`의 기존 플레이어는 계속 `overworld/characters/gobot_gfx.tscn`을 사용한다.

## 주요 코드 구조

- `src/common/`: 방향, 인벤토리, 플레이어 전역 상태, 음악, 화면 전환
- `src/field/`: 필드, 맵, 카메라, 이동, 경로 탐색, 컷신, 상호작용, 필드 UI
- `src/combat/`: 턴제 전투, 배틀러, 행동, 전투 AI와 UI
- `src/dev/`: 개발자 콘솔과 GRLAB
- `overworld/`: 기존 오버월드 캐릭터, 맵, 타일셋, Dialogic 데이터
- `combat/`: 실제 전투 리소스와 배틀러 애셋
- `assets/`: 공용 UI, 아이템, 음악, 효과음, 테스트 맵, 삐용 애셋
- `addons/dialogic/`: Dialogic 플러그인

## 핵심 이동 흐름

`PlayerController`가 입력을 받는다 → `Gameboard.pathfinder`가 셀 경로를 계산한다 → `GamepieceController`가 웨이포인트를 실행한다 → `Gamepiece`가 `Path2D/PathFollow2D`로 이동한다 → `GamepieceRegistry`가 셀 점유를 갱신한다.

관련 파일:

- `src/field/gamepieces/gamepiece.gd`
- `src/field/gamepieces/controllers/player_controller.gd`
- `src/field/gamepieces/controllers/gamepiece_controller.gd`
- `src/field/gamepieces/gamepiece_registry.gd`
- `src/field/gameboard/gameboard.gd`
- `src/field/gameboard/pathfinder.gd`
- `src/field/field_camera.gd`

## 작업 방법

1. 변경 전에 관련 씬과 스크립트의 호출 관계를 확인한다.
2. 씬 파일의 `ext_resource`와 노드 경로까지 함께 점검한다.
3. 기존 오버월드와 GRLAB의 범위를 혼동하지 않는다.
4. 가능하면 Godot 4.7로 대상 씬을 실행해 파싱과 실제 동작을 검증한다.
5. 새 변경은 Git diff로 검토하고 사용자 작업을 임의로 되돌리지 않는다.

## 알려진 주의 사항

- 원본 `README.md`에는 Godot 4.6.2 안내가 있으나 현재 `project.godot` 기능 태그는 4.7이다.
- 에디터 헤드리스 로딩 과정에서 Dialogic `PortraitContainers` 관련 오류가 관찰된 적이 있다. GRLAB 커스텀 코드의 파싱 오류와 구분해서 진단한다.
- `src/dev/dev_test_lab.gd`의 테스트 공간 안내 문구는 현재 작업 중인 상태일 수 있으므로 사용자 확인 없이 기획 문구로 단정하지 않는다.
