class_name MinionCatSpeciesDatabase
extends RefCounted

const PORTRAIT_PATH := "res://assets/characters/bbiyong/bbiyong_lab_sheet.png"
const PORTRAIT_FRAME_SIZE := Vector2(320, 330)

const STAGES := {
	1: {"label": "MAIN", "region": "고양이 모양 섬"},
	2: {"label": "STAGE 2", "region": "숲·공원"},
	3: {"label": "STAGE 3", "region": "도심·병원"},
	4: {"label": "STAGE 4", "region": "해변"},
	5: {"label": "STAGE 5", "region": "사막"},
	6: {"label": "STAGE 6", "region": "열대 정글"},
	7: {"label": "STAGE 7", "region": "고대 유적·초원"},
	8: {"label": "STAGE 8", "region": "얼음 섬"},
}

const ROLE_PROFILES := {
	"balanced": {"name": "균형", "combat": 2, "agility": 2, "stamina": 2, "friendliness": 2, "dexterity": 2, "health": 6},
	"scout": {"name": "정찰", "combat": 1, "agility": 4, "stamina": 2, "friendliness": 3, "dexterity": 2, "health": 5},
	"thief": {"name": "탐색", "combat": 2, "agility": 4, "stamina": 2, "friendliness": 1, "dexterity": 4, "health": 6},
	"fisher": {"name": "채집", "combat": 1, "agility": 2, "stamina": 4, "friendliness": 3, "dexterity": 5, "health": 7},
	"fighter": {"name": "전투", "combat": 5, "agility": 2, "stamina": 4, "friendliness": 1, "dexterity": 1, "health": 10},
	"guardian": {"name": "수호", "combat": 3, "agility": 1, "stamina": 5, "friendliness": 2, "dexterity": 1, "health": 12},
	"support": {"name": "지원", "combat": 1, "agility": 2, "stamina": 3, "friendliness": 5, "dexterity": 3, "health": 7},
}

const SPECIES_ORDER := [
	"korean_shorthair", "american_shorthair", "american_ringtail", "oriental_shorthair",
	"norwegian_forest", "siberian", "scottish_fold",
	"siamese", "abyssinian", "russian_blue", "burmese",
	"maine_coon", "turkish_van", "japanese_bobtail", "manx", "ragamuffin",
	"savannah", "sphynx", "egyptian_mau", "arabian_mau",
	"bengal", "ocicat", "toyger", "somali", "pixiebob",
	"caracal", "serengeti", "khao_manee", "korat",
	"snow_leopard", "turkish_angora", "manul", "pallas_cat",
]

const SPECIES := {
	"korean_shorthair": {"name": "코숏", "stage": 1, "role_id": "balanced", "description": "고양이 모양 섬에서 흔히 만나는 적응력 좋은 고양이."},
	"american_shorthair": {"name": "아메리칸 숏헤어", "stage": 1, "role_id": "guardian", "description": "튼튼한 체력으로 동료를 지키는 데 능하다."},
	"american_ringtail": {"name": "아메리칸 링테일", "stage": 1, "role_id": "scout", "description": "민첩하게 주변을 살피는 정찰형 고양이."},
	"oriental_shorthair": {"name": "오리엔탈 숏헤어", "stage": 1, "role_id": "support", "description": "친화력이 높고 동료와 빠르게 가까워진다."},
	"norwegian_forest": {"name": "노르웨이 숲", "stage": 2, "role_id": "guardian", "description": "숲의 험한 지형을 견디는 수호형 고양이."},
	"siberian": {"name": "시베리안", "stage": 2, "role_id": "fighter", "description": "강한 체력과 공격력을 가진 숲의 전투원."},
	"scottish_fold": {"name": "스코티시폴드", "stage": 2, "role_id": "support", "description": "온화한 성격으로 동료를 돕는다."},
	"siamese": {"name": "샴", "stage": 3, "role_id": "scout", "description": "빠른 움직임으로 도심을 누비는 고양이."},
	"abyssinian": {"name": "아비시니안", "stage": 3, "role_id": "thief", "description": "호기심과 탐색 능력이 뛰어나다."},
	"russian_blue": {"name": "러시안 블루", "stage": 3, "role_id": "balanced", "description": "침착하고 균형 잡힌 능력을 지녔다."},
	"burmese": {"name": "버미즈", "stage": 3, "role_id": "support", "description": "높은 친화력으로 관계 형성에 강하다."},
	"maine_coon": {"name": "메인쿤", "stage": 4, "role_id": "guardian", "featured": true, "description": "거대한 체격과 높은 생존력을 가진 해변의 대표 고양이."},
	"turkish_van": {"name": "터키시반", "stage": 4, "role_id": "fisher", "description": "물을 두려워하지 않아 낚시와 채집에 능하다."},
	"japanese_bobtail": {"name": "재패니즈 밥테일", "stage": 4, "role_id": "scout", "description": "가볍고 민첩하게 해변을 돌아다닌다."},
	"manx": {"name": "맹크스", "stage": 4, "role_id": "fighter", "description": "단단한 체격으로 정면 전투에 강하다."},
	"ragamuffin": {"name": "라가머핀", "stage": 4, "role_id": "support", "description": "온순하고 친화적인 지원형 고양이."},
	"savannah": {"name": "사바나캣", "stage": 5, "role_id": "fighter", "featured": true, "description": "사막에서 빠르고 강하게 적을 추격한다."},
	"sphynx": {"name": "스핑크스", "stage": 5, "role_id": "support", "description": "독특한 감각과 높은 친화력을 지녔다."},
	"egyptian_mau": {"name": "이집션마우", "stage": 5, "role_id": "scout", "description": "사막을 빠르게 달리는 정찰형 고양이."},
	"arabian_mau": {"name": "아라비안 마우", "stage": 5, "role_id": "balanced", "description": "사막 환경에 적응한 균형형 고양이."},
	"bengal": {"name": "벵갈", "stage": 6, "role_id": "fighter", "featured": true, "description": "정글에서 강한 공격성을 보이는 대표 고양이."},
	"ocicat": {"name": "오시캣", "stage": 6, "role_id": "thief", "description": "정글의 숨은 자원을 빠르게 찾아낸다."},
	"toyger": {"name": "토이거", "stage": 6, "role_id": "guardian", "description": "위압적인 모습과 튼튼한 체력을 지녔다."},
	"somali": {"name": "소말리", "stage": 6, "role_id": "scout", "description": "긴 털과 빠른 몸놀림을 가진 정찰형 고양이."},
	"pixiebob": {"name": "픽시밥", "stage": 6, "role_id": "balanced", "description": "야성적인 외모와 균형 잡힌 능력을 지녔다."},
	"caracal": {"name": "카라캣", "stage": 7, "role_id": "fighter", "featured": true, "description": "고대 유적을 지키는 강력한 특수 고양이."},
	"serengeti": {"name": "세렝게티", "stage": 7, "role_id": "scout", "description": "넓은 초원을 빠르게 정찰한다."},
	"khao_manee": {"name": "카오마니", "stage": 7, "role_id": "support", "description": "신비로운 분위기와 높은 친화력을 지녔다."},
	"korat": {"name": "코랏", "stage": 7, "role_id": "guardian", "description": "행운과 끈기를 상징하는 수호형 고양이."},
	"snow_leopard": {"name": "스노우 레오파드", "stage": 8, "role_id": "fighter", "featured": true, "description": "얼음 섬의 최상위 전투력을 가진 전설종."},
	"turkish_angora": {"name": "터키시앙고라", "stage": 8, "role_id": "support", "description": "추운 지역에서도 우아하게 동료를 지원한다."},
	"manul": {"name": "마눌", "stage": 8, "role_id": "guardian", "description": "두꺼운 털과 높은 생존력을 가진 고양이."},
	"pallas_cat": {"name": "팔라스", "stage": 8, "role_id": "balanced", "description": "기획상 별도 슬롯으로 유지한 얼음 섬 고양이."},
}

const LEGACY_ALIASES := {
	"basic_cat": {"species_id": "korean_shorthair", "role_id": "balanced"},
	"scout_cat": {"species_id": "american_ringtail", "role_id": "scout"},
	"thief_cat": {"species_id": "oriental_shorthair", "role_id": "thief"},
	"fisher_cat": {"species_id": "american_shorthair", "role_id": "fisher"},
	"fighter_cat": {"species_id": "korean_shorthair", "role_id": "fighter"},
}


static func normalize_species_id(value: String) -> String:
	var key := value.strip_edges().to_lower()
	if LEGACY_ALIASES.has(key):
		return String(LEGACY_ALIASES[key].species_id)
	return key


static func legacy_role_id(value: String) -> String:
	var key := value.strip_edges().to_lower()
	if LEGACY_ALIASES.has(key):
		return String(LEGACY_ALIASES[key].role_id)
	return ""


static func has_species(species_id: String) -> bool:
	return SPECIES.has(normalize_species_id(species_id))


static func get_definition(species_id: String) -> Dictionary:
	var normalized := normalize_species_id(species_id)
	if not SPECIES.has(normalized):
		return {}
	var definition: Dictionary = SPECIES[normalized].duplicate(true)
	definition["id"] = normalized
	var role_id := String(definition.get("role_id", "balanced"))
	var profile: Dictionary = ROLE_PROFILES.get(role_id, ROLE_PROFILES["balanced"])
	for key in profile:
		if not definition.has(key):
			definition[key] = profile[key]
	var index := SPECIES_ORDER.find(normalized)
	definition["portrait"] = PORTRAIT_PATH
	definition["portrait_region"] = Rect2(
		float(index % 4) * PORTRAIT_FRAME_SIZE.x,
		float(floori(float(index) / 4.0) % 4) * PORTRAIT_FRAME_SIZE.y,
		PORTRAIT_FRAME_SIZE.x,
		PORTRAIT_FRAME_SIZE.y
	)
	return definition


static func get_species_ids_for_stage(stage_id: int) -> Array[String]:
	var result: Array[String] = []
	for species_id in SPECIES_ORDER:
		if int(SPECIES[species_id].stage) == stage_id:
			result.append(species_id)
	return result


static func get_stage_definition(stage_id: int) -> Dictionary:
	var definition: Dictionary = STAGES.get(stage_id, {})
	return definition.duplicate(true)


static func get_display_name(species_id: String) -> String:
	var definition := get_definition(species_id)
	return String(definition.get("name", species_id))


static func get_role_name(role_id: String) -> String:
	var profile: Dictionary = ROLE_PROFILES.get(role_id, {})
	return String(profile.get("name", role_id))
