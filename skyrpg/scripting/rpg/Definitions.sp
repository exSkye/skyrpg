#define NICK_MODEL						"models/survivors/survivor_gambler.mdl"
#define ROCHELLE_MODEL					"models/survivors/survivor_producer.mdl"
#define COACH_MODEL						"models/survivors/survivor_coach.mdl"
#define ELLIS_MODEL						"models/survivors/survivor_mechanic.mdl"
#define ZOEY_MODEL						"models/survivors/survivor_teenangst.mdl"
#define FRANCIS_MODEL					"models/survivors/survivor_biker.mdl"
#define LOUIS_MODEL						"models/survivors/survivor_manager.mdl"
#define BILL_MODEL						"models/survivors/survivor_namvet.mdl"
#define TEAM_SPECTATOR					1
#define TEAM_SURVIVOR					2
#define TEAM_INFECTED					3
#define MAX_ENTITIES					2048
#define MAX_CHAT_LENGTH					1024
#define COOPRECORD_DB					"db_season_coop"
#define SURVRECORD_DB					"db_season_surv"
#define PLUGIN_VERSION					"v4.0"
#define PROFILE_VERSION					"v1.5"
#define PLUGIN_CONTACT					"github.com/exSkye/"
#define PLUGIN_NAME						"RPG Construction Set"
#define PLUGIN_DESCRIPTION				"Fully-customizable and modular RPG, like the one for Atari."
#define CONFIG_EVENTS					"rpg/events.cfg"
#define CONFIG_MAINMENU					"rpg/mainmenu.cfg"
#define CONFIG_SURVIVORTALENTS			"rpg/talentmenu.cfg"
#define CONFIG_POINTS					"rpg/points.cfg"
#define CONFIG_MAPRECORDS				"rpg/maprecords.cfg"
#define CONFIG_STORE					"rpg/store.cfg"
#define CONFIG_TRAILS					"rpg/trails.cfg"
#define CONFIG_WEAPONS					"rpg/weapondamages.cfg"
#define CONFIG_COMMONAFFIXES			"rpg/commonaffixes.cfg"
#define CONFIG_CLASSNAMES				"rpg/classnames.cfg"
#define CONFIG_HANDICAP					"rpg/handicap.cfg"
#define LOGFILE							"rum_rpg.txt"
#define JETPACK_AUDIO					"ambient/gas/steam2.wav"
#define MODIFIER_HEALING				0
#define MODIFIER_TANKING				1
#define MODIFIER_DAMAGE					2	// not really used...
#define SURVIVOR_STATE_IGNORE			0
#define SURVIVOR_STATE_ENSNARED			1
#define SURVIVOR_STATE_INCAPACITATED	2
#define SURVIVOR_STATE_DEAD				3
#define FALLEN_SURVIVOR_MODEL			"models/infected/common_male_fallen_survivor.mdl"
#define HEALING_CONTRIBUTION			1
#define BUFFING_CONTRIBUTION			2
#define HEXING_CONTRIBUTION				3
// "multiply type?" bit values
#define MULTIPLY_COMMON					1
#define MULTIPLY_SUPER					2
#define MULTIPLY_WITCH					4
#define MULTIPLY_SURVIVOR				8
#define MULTIPLY_SPECIAL				16
//	================================
#define DEBUG     					false
//	================================
#define CVAR_SHOW								FCVAR_NOTIFY
#define DMG_HEADSHOT							2147483648
#define ZOMBIECLASS_SMOKER						1
#define ZOMBIECLASS_BOOMER						2
#define ZOMBIECLASS_HUNTER						3
#define ZOMBIECLASS_SPITTER						4
#define ZOMBIECLASS_JOCKEY						5
#define ZOMBIECLASS_CHARGER						6
#define ZOMBIECLASS_WITCH						7
#define ZOMBIECLASS_TANK						8
#define ZOMBIECLASS_SURVIVOR					0
#define TANKSTATE_TIRED							0
#define TANKSTATE_REFLECT						1
#define TANKSTATE_FIRE							2
#define TANKSTATE_DEATH							3
#define TANKSTATE_TELEPORT						4
#define TANKSTATE_HULK							5
#define EFFECTOVERTIME_ACTIVATETALENT			0
#define EFFECTOVERTIME_GETACTIVETIME			1
#define EFFECTOVERTIME_GETCOOLDOWN				2
#define DMG_SPITTERACID1						263168
#define DMG_SPITTERACID2						265216
#define CONTRIBUTION_TRACKER_HEALING			0
#define CONTRIBUTION_TRACKER_DAMAGE				1
#define CONTRIBUTION_TRACKER_TANKING			2
#define CLIENT_SPECIAL_INFECTED 0
#define CLIENT_WITCH 1
#define CLIENT_SUPER_COMMON 2
#define CLIENT_COMMON 3
// weapondamages.cfg
#define WEAPONINFO_DAMAGE						0
#define WEAPONINFO_OFFSET						1
#define WEAPONINFO_AMMO							2
#define WEAPONINFO_RANGE						3
#define WEAPONINFO_EFFECTIVE_RANGE				4
// for the talentmenu.cfg
#define ABILITY_TYPE							0
#define COMPOUNDING_TALENT						1
#define COMPOUND_WITH							2
#define ACTIVATOR_ABILITY_EFFECTS				3
#define TARGET_ABILITY_EFFECTS					4
#define SECONDARY_EFFECTS						5
#define WEAPONS_PERMITTED						6
#define HEALTH_PERCENTAGE_REQ					7
#define COHERENCY_RANGE							8
#define COHERENCY_MAX							9
#define COHERENCY_REQ							10
#define HEALTH_PERCENTAGE_REQ_TAR_REMAINING		11
#define HEALTH_PERCENTAGE_REQ_TAR_MISSING		12
#define ACTIVATOR_CLASS_REQ						13
#define REQUIRES_ZOOM							14
#define COMBAT_STATE_REQ						15
#define PLAYER_STATE_REQ						16
#define PASSIVE_ABILITY							17
#define REQUIRES_HEADSHOT						18
#define REQUIRES_LIMBSHOT						19
#define ACTIVATOR_STAGGER_REQ					20
#define TARGET_STAGGER_REQ						21
#define CANNOT_TARGET_SELF						22
#define TARGET_CLASS_REQ						23
#define REQ_CONSECUTIVE_HITS					24
#define BACKGROUND_TALENT						25
#define STATUS_EFFECT_MULTIPLIER				26
#define MULTIPLY_RANGE							27
#define MULTIPLY_TYPE							28
#define STRENGTH_INCREASE_ZOOMED				29
#define STRENGTH_INCREASE_TIME_CAP				30
#define STRENGTH_INCREASE_TIME_REQ				31
#define ZOOM_TIME_HAS_MINIMUM_REQ				32
#define HOLDING_FIRE_STRENGTH_INCREASE			33
#define DAMAGE_TIME_HAS_MINIMUM_REQ				34
#define HEALTH_PERCENTAGE_REQ_MISSING			35
#define HEALTH_PERCENTAGE_REQ_MISSING_MAX		36
#define SECONDARY_ABILITY_TRIGGER				37
#define TARGET_IS_SELF							38
#define PRIMARY_AOE								39
#define SECONDARY_AOE							40
#define GET_TALENT_NAME							41
#define GET_TRANSLATION							42
#define GOVERNING_ATTRIBUTE						43
#define TALENT_TREE_CATEGORY					44
#define PART_OF_MENU_NAMED						45
#define GET_TALENT_LAYER						46
#define IS_TALENT_ABILITY						47
#define ACTION_BAR_NAME							48
#define NUM_TALENTS_REQ							49
#define TALENT_UPGRADE_STRENGTH_VALUE			50
#define TALENT_COOLDOWN_STRENGTH_VALUE			51
#define TALENT_ACTIVE_STRENGTH_VALUE			52
#define COOLDOWN_GOVERNOR_OF_TALENT				53
#define TALENT_STRENGTH_HARD_LIMIT				54
#define TALENT_IS_EFFECT_OVER_TIME				55
#define SPECIAL_AMMO_TALENT_STRENGTH			56
#define LAYER_COUNTING_IS_IGNORED				57
#define IS_ATTRIBUTE							58
#define HIDE_TRANSLATION						59
#define TALENT_ROLL_CHANCE						60
// spells
#define SPELL_INTERVAL_PER_POINT				61
#define SPELL_INTERVAL_FIRST_POINT				62
#define SPELL_RANGE_PER_POINT					63
#define SPELL_RANGE_FIRST_POINT					64
#define SPELL_STAMINA_PER_POINT					65
#define SPELL_BASE_STAMINA_REQ					66
#define SPELL_COOLDOWN_PER_POINT				67
#define SPELL_COOLDOWN_FIRST_POINT				68
#define SPELL_COOLDOWN_START					69
#define SPELL_ACTIVE_TIME_PER_POINT				70
#define SPELL_ACTIVE_TIME_FIRST_POINT			71
#define SPELL_AMMO_EFFECT						72
#define SPELL_EFFECT_MULTIPLIER					73
// abilities
#define ABILITY_ACTIVE_EFFECT					74
#define ABILITY_PASSIVE_EFFECT					75
#define ABILITY_COOLDOWN_EFFECT					76
#define ABILITY_IS_REACTIVE						77
#define ABILITY_TEAMS_ALLOWED					78
#define ABILITY_COOLDOWN_STRENGTH				79
#define ABILITY_MAXIMUM_PASSIVE_MULTIPLIER		80
#define ABILITY_MAXIMUM_ACTIVE_MULTIPLIER		81
#define ABILITY_ACTIVE_STATE_ENSNARE_REQ		82
#define ABILITY_ACTIVE_STRENGTH					83
#define ABILITY_PASSIVE_IGNORES_COOLDOWN		84
#define ABILITY_PASSIVE_STATE_ENSNARE_REQ		85
#define ABILITY_PASSIVE_STRENGTH				86
#define ABILITY_PASSIVE_ONLY					87
#define ABILITY_IS_SINGLE_TARGET				88
#define ABILITY_DRAW_DELAY						89
#define ABILITY_ACTIVE_DRAW_DELAY				90
#define ABILITY_PASSIVE_DRAW_DELAY				91
#define ATTRIBUTE_MULTIPLIER					92
#define ATTRIBUTE_USE_THESE_MULTIPLIERS			93
#define ATTRIBUTE_BASE_MULTIPLIER				94
#define ATTRIBUTE_DIMINISHING_MULTIPLIER		95
#define ATTRIBUTE_DIMINISHING_RETURNS			96
#define HUD_TEXT_BUFF_EFFECT_OVER_TIME			97
#define IS_SUB_MENU_OF_TALENTCONFIG				98
#define IS_AURA_INSTEAD							99
#define EFFECT_COOLDOWN_TRIGGER					100
#define EFFECT_INACTIVE_TRIGGER					101
#define ABILITY_REACTIVE_TYPE					102
#define ABILITY_ACTIVE_TIME						103
#define ABILITY_REQ_NO_ENSNARE					104
#define ABILITY_TOGGLE_EFFECT					105
#define ABILITY_COOLDOWN						106
#define EFFECT_ACTIVATE_PER_TICK				107
#define EFFECT_SECONDARY_EPT_ONLY				108
#define ABILITY_ACTIVE_END_ABILITY_TRIGGER		109
#define ABILITY_COOLDOWN_END_TRIGGER			110
#define ABILITY_DOES_DAMAGE						111
#define TALENT_IS_SPELL							112
#define ABILITY_TOGGLE_STRENGTH					113
#define TARGET_AND_LAST_TARGET_CLASS_MATCH		114
#define TARGET_RANGE_REQUIRED					115
#define TARGET_RANGE_REQUIRED_OUTSIDE			116
#define TARGET_MUST_BE_LAST_TARGET				117
#define ACTIVATOR_MUST_HAVE_HIGH_GROUND			118
#define TARGET_MUST_HAVE_HIGH_GROUND			119
#define ACTIVATOR_TARGET_MUST_EVEN_GROUND		120
#define ABILITY_EVENT_TYPE						121
#define LAST_KILL_MUST_BE_HEADSHOT				122
#define MULT_STR_CONSECUTIVE_HITS				123
#define MULT_STR_CONSECUTIVE_MAX				124
#define MULT_STR_CONSECUTIVE_DIV				125
#define CONTRIBUTION_TYPE_CATEGORY				126
#define CONTRIBUTION_COST						127
#define ITEM_NAME_TO_GIVE_PLAYER				128
#define HIDE_TALENT_STRENGTH_DISPLAY			129
#define ACTIVATOR_CALL_ABILITY_TRIGGER			130
#define TALENT_WEAPON_SLOT_REQUIRED				131
#define REQ_CONSECUTIVE_HEADSHOTS				132
#define MULT_STR_CONSECUTIVE_HEADSHOTS			133
#define MULT_STR_CONSECUTIVE_HEADSHOTS_MAX		134
#define MULT_STR_CONSECUTIVE_HEADSHOTS_DIV		135
#define IF_EOT_ACTIVE_ALLOW_ALL_WEAPONS			136
#define IF_EOT_ACTIVE_ALLOW_ALL_HITGROUPS		137
#define IF_EOT_ACTIVE_ALLOW_ALL_ENEMIES			138
#define ACTIVATOR_STATUS_EFFECT_REQUIRED		139
#define HEALTH_PERCENTAGE_REQ_ACT_REMAINING 	140
#define HEALTH_PERCENTAGE_ACTIVATION_COST		141
#define MULT_STR_NEARBY_DOWN_ALLIES				142
#define MULT_STR_NEARBY_ENSNARED_ALLIES			143
#define TALENT_NO_AUGMENT_MODIFIERS				144
#define TARGET_CALL_ABILITY_TRIGGER				145
#define COHERENCY_TALENT_NEARBY_REQUIRED		146
#define UNHURT_BY_SPECIALINFECTED_OR_WITCH		147
#define SKIP_TALENT_FOR_AUGMENT_ROLL			148
#define REQUIRE_ALLY_WITH_ADRENALINE			149
#define REQUIRE_ALLY_BELOW_HEALTH_PERCENTAGE	150
#define REQUIRE_ENSNARED_ALLY					151
#define REQUIRE_TARGET_HAS_ENSNARED_ALLY		152
#define REQUIRE_ENEMY_IN_COHERENCY_RANGE		153
#define ENEMY_IN_COHERENCY_IS_TARGET			154
#define REQUIRE_ALLY_ON_FIRE					155
#define TALENT_MINIMUM_COOLDOWN_TIME			156
#define ABILITY_CATEGORY						157
#define TARGET_STATUS_EFFECT_REQUIRED			158
#define ACTIVATOR_MUST_BE_IN_AMMO				159
#define TARGET_MUST_BE_IN_AMMO					160
#define TIME_SINCE_LAST_ACTIVATOR_ATTACK		161
#define WEAPON_NAME_REQUIRED					162
#define REQUIRE_SAME_HITBOX						163
#define MULTIPLY_LIMIT							164
#define ACTIVE_EFFECT_INTERVAL					165
#define TALENT_ACTIVE_ABILITY_TRIGGER			166
#define TALENT_ABILITY_TRIGGER					167
// because this value changes when we increase the static list of key positions
// we should create a reference for the IsAbilityFound method, so that it doesn't waste time checking keys that we know aren't equal.
#define TALENT_FIRST_RANDOM_KEY_POSITION		168

#define SUPER_COMMON_MAX_ALLOWED				0
#define SUPER_COMMON_AURA_EFFECT				1
#define SUPER_COMMON_RANGE_MIN					2
#define SUPER_COMMON_RANGE_PLAYER_LEVEL			3
#define SUPER_COMMON_RANGE_MAX					4
#define SUPER_COMMON_COOLDOWN					5
#define SUPER_COMMON_AURA_STRENGTH				6
#define SUPER_COMMON_STRENGTH_TARGET			7
#define SUPER_COMMON_LEVEL_STRENGTH				8
#define SUPER_COMMON_SPAWN_CHANCE				9
#define SUPER_COMMON_DRAW_TYPE					10
#define SUPER_COMMON_FIRE_IMMUNITY				11
#define SUPER_COMMON_MODEL_SIZE					12
#define SUPER_COMMON_GLOW						13
#define SUPER_COMMON_GLOW_RANGE					14
#define SUPER_COMMON_GLOW_COLOUR				15
#define SUPER_COMMON_BASE_HEALTH				16
#define SUPER_COMMON_HEALTH_PER_LEVEL			17
#define SUPER_COMMON_NAME						18
#define SUPER_COMMON_CHAIN_REACTION				19
#define SUPER_COMMON_DEATH_EFFECT				20
#define SUPER_COMMON_DEATH_BASE_TIME			21
#define SUPER_COMMON_DEATH_MAX_TIME				22
#define SUPER_COMMON_DEATH_INTERVAL				23
#define SUPER_COMMON_DEATH_MULTIPLIER			24
#define SUPER_COMMON_LEVEL_REQ					25
#define SUPER_COMMON_FORCE_MODEL				26
#define SUPER_COMMON_DAMAGE_EFFECT				27
#define SUPER_COMMON_ENEMY_MULTIPLICATION		28
#define SUPER_COMMON_ONFIRE_BASE_TIME			29
#define SUPER_COMMON_ONFIRE_LEVEL				30
#define SUPER_COMMON_ONFIRE_MAX_TIME			31
#define SUPER_COMMON_ONFIRE_INTERVAL			32
#define SUPER_COMMON_STRENGTH_SPECIAL			33
#define SUPER_COMMON_RAW_STRENGTH				34
#define SUPER_COMMON_RAW_COMMON_STRENGTH		35
#define SUPER_COMMON_RAW_PLAYER_STRENGTH		36
#define SUPER_COMMON_REQ_BILED_SURVIVORS		37
#define SUPER_COMMON_FIRST_RANDOM_KEY_POS		38
// for the events.cfg
#define EVENT_PERPETRATOR						0
#define EVENT_VICTIM							1
#define EVENT_SAMETEAM_TRIGGER					2
#define EVENT_PERPETRATOR_TEAM_REQ				3
#define EVENT_PERPETRATOR_ABILITY_TRIGGER		4
#define EVENT_VICTIM_TEAM_REQ					5
#define EVENT_VICTIM_ABILITY_TRIGGER			6
#define EVENT_DAMAGE_TYPE						7
#define EVENT_GET_HEALTH						8
#define EVENT_DAMAGE_AWARD						9
#define EVENT_GET_ABILITIES						10
#define EVENT_IS_PLAYER_NOW_IT					11
#define EVENT_IS_ORIGIN							12
#define EVENT_IS_DISTANCE						13
#define EVENT_MULTIPLIER_POINTS					14
#define EVENT_MULTIPLIER_EXPERIENCE				15
#define EVENT_IS_SHOVED							16
#define EVENT_IS_BULLET_IMPACT					17
#define EVENT_ENTERED_SAFEROOM					18
// for handicap.cfg
#define HANDICAP_TRANSLATION					0
#define HANDICAP_DAMAGE							1
#define HANDICAP_HEALTH							2
#define HANDICAP_LOOTFIND						3
#define HANDICAP_SCORE_REQUIRED					4
#define HANDICAP_SCORE_MULTIPLIER				5
// for easier tracking of hitgroups and insurance against inverting values while coding
#define HITGROUP_LIMB		2
#define HITGROUP_HEAD		1
#define HITGROUP_OTHER		0
// for easier tracking of contribution types
#define CONTRIBUTION_AWARD_DAMAGE				0
#define CONTRIBUTION_AWARD_TANKING				1
#define CONTRIBUTION_AWARD_BUFFING				2
#define CONTRIBUTION_AWARD_HEALING				3

// so GetAbilityStrengthByTrigger doesn't have to do strcmp for every result
#define RESULT_VAMPIRE 0
#define RESULT_CREATEMINE 1
#define RESULT_AOEHEAL 2
#define RESULT_FFEXPLODE 3
#define RESULT_POISONCLAW 4
#define RESULT_BURNCLAW 5
#define RESULT_MAGHALFEMPTY 6
#define RESULT_PARRY 7
#define RESULT_a 8
#define RESULT_A 9
#define RESULT_b 10
#define RESULT_c 11
#define RESULT_acidburn 12
#define RESULT_f 13
#define RESULT_E 14
#define RESULT_e 15
#define RESULT_g 16
#define RESULT_h 17
#define RESULT_u 18
#define RESULT_U 19
#define RESULT_i 20
#define RESULT_j 21
#define RESULT_l 22
#define RESULT_m 23
#define RESULT_r1bullet 24
#define RESULT_rrbullet 25
#define RESULT_rrbulletaoe 26
#define RESULT_rpbullet 27
#define RESULT_rpbulletaoe 28
#define RESULT_aoedamage 29
#define RESULT_R 30
#define RESULT_s 31
#define RESULT_speed 32
#define RESULT_S 33
#define RESULT_t 34
#define RESULT_T 35
#define RESULT_z 36
#define RESULT_revive 37
#define RESULT_giveitem 38
#define RESULT_activetime 39
#define RESULT_cooldown 40
#define RESULT_staminacost 41
#define RESULT_range 42
#define RESULT_strengthup 43
#define RESULT_flightcost 44
#define RESULT_stamina 45
#define RESULT_ammoreserve 46
#define RESULT_d 47
#define RESULT_o 48
#define RESULT_H 49

// Ability Triggers
#define TRIGGER_R 0
#define TRIGGER_r 1
#define TRIGGER_d 2
#define TRIGGER_l 3
#define TRIGGER_H 4
#define TRIGGER_infected_abilityuse 5
#define TRIGGER_Q 6
#define TRIGGER_A 7
#define TRIGGER_q 8
#define TRIGGER_pounced 9
#define TRIGGER_distance 10
#define TRIGGER_v 11
#define TRIGGER_spellbuff 12
#define TRIGGER_aamRNG 13
#define TRIGGER_progbarspeed 14
#define TRIGGER_didStagger 15
#define TRIGGER_wasStagger 16
#define TRIGGER_usepainpills 17
#define TRIGGER_healsuccess 18
#define TRIGGER_usefirstaid 19
#define TRIGGER_jetpack 20
#define TRIGGER_specialkill 21
#define TRIGGER_assist 22
#define TRIGGER_U 23
#define TRIGGER_u 24
#define TRIGGER_L 25
#define TRIGGER_p 26
#define TRIGGER_lessTankyMoreDamage 27
#define TRIGGER_lessDamageMoreTanky 28
#define TRIGGER_lessHealsMoreTanky 29
#define TRIGGER_lessDamageMoreHeals 30
#define TRIGGER_lessTankyMoreHeals 31
#define TRIGGER_lessHealsMoreDamage 32
#define TRIGGER_dropitem 33
#define TRIGGER_h 34
#define TRIGGER_pacifist 35
#define TRIGGER_D 36
#define TRIGGER_hB 37
#define TRIGGER_hM 38
#define TRIGGER_S 39
#define TRIGGER_explosion 40
#define TRIGGER_Y 41
#define TRIGGER_T 42
#define TRIGGER_claw 43
#define TRIGGER_s 44
#define TRIGGER_V 45
#define TRIGGER_t 46
#define TRIGGER_a 47
#define TRIGGER_ammoreserve 48
#define TRIGGER_e 49
#define TRIGGER_E 50
#define TRIGGER_witchkill 51
#define TRIGGER_superkill 52
#define TRIGGER_C 53
#define TRIGGER_enterammo 54
#define TRIGGER_exitammo 55
#define TRIGGER_getstam 56
#define TRIGGER_N 57
#define TRIGGER_n 58
#define TRIGGER_m 59
#define TRIGGER_limbshot 60
#define TRIGGER_headshot 61
#define TRIGGER_wasHealed 62
#define TRIGGER_healself 63

int iMenuCommandsToDisplay;
bool mainConfigLoaded = false;
float fDoTInterval;
float fDoTMaxTime;
int iFireBaseDamage;
int iDisplayEnrageCountdown;
float fDebuffTickrate;
float fCategoryStrengthPenaltyAugmentTier;
float lootPickupCooldownTime[MAXPLAYERS + 1];
char CommandText[64];
bool bHasChainsaw[MAXPLAYERS + 1];
int medItem[MAXPLAYERS + 1];
int myLastHitbox[MAXPLAYERS + 1];
Handle MyUnlockedTalents[MAXPLAYERS + 1];
int weaponProficiencyType[MAXPLAYERS + 1];
int myCurrentWeaponId[MAXPLAYERS + 1];
int myCurrentWeaponPos[MAXPLAYERS + 1];
int myPrimaryWeaponPos[MAXPLAYERS + 1];
int maximumReserves[MAXPLAYERS + 1];
int iTotalCampaignTime;
int numberOfCommonsKilledThisRound;
int numberOfCommonsKilledThisCampaign;
int numberOfSupersKilledThisRound;
int numberOfSupersKilledThisCampaign;
int numberOfWitchesKilledThisRound;
int numberOfWitchesKilledThisCampaign;
int numberOfSpecialsKilledThisRound;
int numberOfSpecialsKilledThisCampaign;
int numberOfTanksKilledThisRound;
int numberOfTanksKilledThisCampaign;
int iNumAdvertisements = 0;
int iAdvertisementCounter = 0;
int clientDeathTime[MAXPLAYERS + 1];
float fPainPillsHealAmount;
char customProfileKey[MAXPLAYERS + 1][64];
int augmentLoadPos[MAXPLAYERS + 1];
bool bIsLoadingCustomProfile[MAXPLAYERS + 1];
int iAugmentCategoryUpgradeCost;
int iAugmentActivatorUpgradeCost;
int iAugmentTargetUpgradeCost;
Handle augmentInventoryPosition[MAXPLAYERS + 1];
char currentClientSteamID[MAXPLAYERS + 1][64];
float fFallenSurvivorDefibChance;
float fFallenSurvivorDefibChanceLuck;
float fRewardPenaltyIfSurvivorBot;
int myCurrentTeam[MAXPLAYERS + 1];
Handle GetCoherencyValues[MAXPLAYERS + 1];
bool bClientIsInAnyAmmo[MAXPLAYERS + 1];
float fUpdateClientInterval;
float fAugmentLevelDifferenceForStolen;
int playerCurrentAugmentAverageLevel[MAXPLAYERS + 1];
int iDontAllowLootStealing[MAXPLAYERS + 1];
int iLootDropsForUnlockedTalentsOnly[MAXPLAYERS + 1];
int clientEffectState[MAXPLAYERS + 1];
int iExperimentalMode;
float fTankingContribution;
float fDamageContribution;
float fHealingContribution;
float fBuffingContribution;
Handle GetValueFloatArray[MAXPLAYERS + 1];
int iStuckDelayTime;
int lastStuckTime[MAXPLAYERS + 1];
float fIncapHealthStartPercentage;
Handle tempStorage;
int iCurrentIncapCount[MAXPLAYERS + 1];
Handle ListOfWitchesWhoHaveBeenShot;
Handle ClientsPermittedToLoad;
bool b_IsIdle[MAXPLAYERS + 1];
Handle OnDeathHandicapValues[MAXPLAYERS + 1];
Handle EquipAugmentPanel[MAXPLAYERS + 1];
int iAugmentsAffectCooldowns;
int augmentRerollBuffPos[MAXPLAYERS + 1];
int augmentRerollBuffPosToSkip[MAXPLAYERS + 1];
int augmentRerollBuffType[MAXPLAYERS + 1];
int iAugmentCategoryRerollCost;
int iAugmentActivatorRerollCost;
int iAugmentTargetRerollCost;
int augmentSlotToEquipOn[MAXPLAYERS + 1];
int iMaximumCommonsPerPlayer;
bool hasMeleeWeaponEquipped[MAXPLAYERS + 1];
int iMaximumTanksPerPlayer;
Handle ModelsToPrecache;
Handle TalentMenuConfigs;
Handle TalentKey;
Handle TalentValue;
Handle TalentSection;
Handle TalentKeys;
Handle TalentValues;
Handle TalentSections;
//Handle TalentTriggers;
Handle GetStrengthFloat[MAXPLAYERS + 1];
Handle TalentPositionsWithEffectName[MAXPLAYERS + 1];
Handle PlayerBuffVals[MAXPLAYERS + 1];
Handle AbilityTriggerValues[MAXPLAYERS + 1];
float fNoHandicapScoreMultiplier;
int iplayerDismantleMinorAugments[MAXPLAYERS + 1];
int iplayerSettingAutoDismantleScore[MAXPLAYERS + 1];
Handle SetHandicapValues[MAXPLAYERS + 1];
Handle HandicapSelectedValues[MAXPLAYERS + 1];
Handle HandicapValues[MAXPLAYERS + 1];
int iLevelRequiredToEarnScore;
int handicapLevel[MAXPLAYERS + 1];
int lastHealthDamage[MAXPLAYERS + 1][MAXPLAYERS + 1];
int iClientTypeToDisplayOnKill;
char MyCurrentWeapon[MAXPLAYERS + 1][64];
int takeDamageEvent[MAXPLAYERS + 1][2];
Handle possibleLootPool[MAXPLAYERS + 1];
Handle unlockedLootPool[MAXPLAYERS + 1];
Handle myUnlockedLootDropCategoriesAllowed[MAXPLAYERS + 1];
Handle myUnlockedUnlockedCategories[MAXPLAYERS + 1];
Handle myUnlockedLootDropActivatorEffectsAllowed[MAXPLAYERS + 1];
Handle myUnlockedUnlockedActivators[MAXPLAYERS + 1];
Handle myUnlockedLootDropTargetEffectsAllowed[MAXPLAYERS + 1];
Handle myUnlockedUnlockedTargets[MAXPLAYERS + 1];
int iSurvivorBotsAreImmuneToFireDamage;
int showNumLivingSurvivorsInHostname;
int iHideEnrageTimerUntilSecondsLeft;
float fTeleportTankHeightDistance;
//char playerChatClassName[MAXPLAYERS+1][64];
bool bWeaknessAssigned[MAXPLAYERS + 1];
int LastTargetClass[MAXPLAYERS + 1];
int iHealingPlayerInCombatPutInCombat;
Handle TimeOfEffectOverTime;
Handle EffectOverTime;
Handle currentEquippedWeapon[MAXPLAYERS + 1];	// bullets fired from current weapon; variable needs to be renamed.
Handle GetCategoryStrengthValues[MAXPLAYERS + 1];
bool bIsDebugEnabled = false;
int pistolXP[MAXPLAYERS + 1];
int meleeXP[MAXPLAYERS + 1];
int uziXP[MAXPLAYERS + 1];
int shotgunXP[MAXPLAYERS + 1];
int sniperXP[MAXPLAYERS + 1];
int assaultXP[MAXPLAYERS + 1];
int medicXP[MAXPLAYERS + 1];
int grenadeXP[MAXPLAYERS + 1];
float fProficiencyExperienceMultiplier;
float fProficiencyExperienceEarned;
//new iProficiencyMaxLevel;
int iProficiencyStart;
int iMaxIncap;
int iTanksPreset;
int ProgressEntity[MAXPLAYERS + 1];
//new Float:fScoutBonus;
//new Float:fTotemRating;
int iSurvivorRespawnRestrict;
bool bIsDefenderTank[MAXPLAYERS + 1];
float fOnFireDebuffDelay;
float fOnFireDebuff[MAXPLAYERS + 1];
//new iOnFireDebuffLimit;
int iSkyLevelMax;
int SkyLevel[MAXPLAYERS + 1];
int iIsSpecialFire;
Handle hThreatSort;
bool bIsHideThreat[MAXPLAYERS + 1];
//new Float:fTankThreatBonus;
int iTopThreat;
int iThreatLevel[MAXPLAYERS + 1];
int iThreatLevel_temp[MAXPLAYERS + 1];
Handle hThreatMeter;
int forceProfileOnNewPlayers;
bool bEquipSpells[MAXPLAYERS + 1];
Handle LoadoutConfigKeys[MAXPLAYERS + 1];
Handle LoadoutConfigValues[MAXPLAYERS + 1];
Handle LoadoutConfigSection[MAXPLAYERS + 1];
bool bIsGiveProfileItems[MAXPLAYERS + 1];
char sProfileLoadoutConfig[64];
int iIsWeaponLoadout[MAXPLAYERS + 1];
int iAwardBroadcast;
int iSurvivalCounter;
int iRestedDonator;
int iRestedRegular;
int iRestedSecondsRequired;
int iRestedMaximum;
int iFriendlyFire;
char sDonatorFlags[10];
float fDeathPenalty;
int iHardcoreMode;
int iDeathPenaltyPlayers;
bool bRushingNotified[MAXPLAYERS + 1];
bool bHasTeleported[MAXPLAYERS + 1];
bool IsAirborne[MAXPLAYERS + 1];
Handle RandomSurvivorClient;
int eBackpack[MAXPLAYERS + 1];
bool b_IsFinaleTanks;
char RatingType[64];
bool bJumpTime[MAXPLAYERS + 1];
float JumpTime[MAXPLAYERS + 1];
Handle AbilityConfigValues[MAXPLAYERS + 1];
bool IsGroupMember[MAXPLAYERS + 1];
int IsGroupMemberTime[MAXPLAYERS + 1];
Handle IsAbilityValues[MAXPLAYERS + 1];
Handle CheckAbilityKeys[MAXPLAYERS + 1];
Handle CheckAbilityValues[MAXPLAYERS + 1];
int StrugglePower[MAXPLAYERS + 1];
Handle CastValues[MAXPLAYERS + 1];
int ActionBarSlot[MAXPLAYERS + 1];
Handle ActionBarMenuPos[MAXPLAYERS + 1];
Handle ActionBar[MAXPLAYERS + 1];
bool DisplayActionBar[MAXPLAYERS + 1];
int ConsecutiveHits[MAXPLAYERS + 1];
int MyVomitChase[MAXPLAYERS + 1];
float JetpackRecoveryTime[MAXPLAYERS + 1];
bool b_IsHooked[MAXPLAYERS + 1];
int IsPvP[MAXPLAYERS + 1];
bool bJetpack[MAXPLAYERS + 1];
//new ServerLevelRequirement;
Handle TalentsAssignedValues[MAXPLAYERS + 1];
Handle CartelValueValues[MAXPLAYERS + 1];
int ReadyUpGameMode;
bool b_IsLoaded[MAXPLAYERS + 1];
bool LoadDelay[MAXPLAYERS + 1];
int LoadTarget[MAXPLAYERS + 1];
char CompanionNameQueue[MAXPLAYERS + 1][64];
bool HealImmunity[MAXPLAYERS + 1];
char Hostname[64];
char ProfileLoadQueue[MAXPLAYERS + 1][64];
bool bIsSettingsCheck;
Handle SuperCommonQueue;
bool bIsCrushCooldown[MAXPLAYERS + 1];
bool bIsBurnCooldown[MAXPLAYERS + 1];
bool ISBILED[MAXPLAYERS + 1];
int Rating[MAXPLAYERS + 1];
float RoundExperienceMultiplier[MAXPLAYERS + 1];
int BonusContainer[MAXPLAYERS + 1];
int CurrentMapPosition;
int DoomTimer;
bool b_IsRescueVehicleArrived;
int CleanseStack[MAXPLAYERS + 1];
float CounterStack[MAXPLAYERS + 1];
int MultiplierStack[MAXPLAYERS + 1];
char BuildingStack[MAXPLAYERS + 1];
Handle TempAttributes[MAXPLAYERS + 1];
Handle TempTalents[MAXPLAYERS + 1];
Handle PlayerProfiles[MAXPLAYERS + 1];
char LoadoutName[MAXPLAYERS + 1][64];
bool b_IsSurvivalIntermission;
float ISDAZED[MAXPLAYERS + 1];
//new Float:ExplodeTankTimer[MAXPLAYERS + 1];
int TankState[MAXPLAYERS + 1];
//new LastAttacker[MAXPLAYERS + 1];
bool b_IsFloating[MAXPLAYERS + 1];
//new Float:JumpPosition[MAXPLAYERS + 1][2][3];
float LastDeathTime[MAXPLAYERS + 1];
float SurvivorEnrage[MAXPLAYERS + 1][2];
int bHasWeakness[MAXPLAYERS + 1];
bool bForcedWeakness[MAXPLAYERS + 1];
int HexingContribution[MAXPLAYERS + 1];
int BuffingContribution[MAXPLAYERS + 1];
int HealingContribution[MAXPLAYERS + 1];
int TankingContribution[MAXPLAYERS + 1];
int CleansingContribution[MAXPLAYERS + 1];
float PointsContribution[MAXPLAYERS + 1];
int DamageContribution[MAXPLAYERS + 1];
float ExplosionCounter[MAXPLAYERS + 1][2];
Handle CoveredInVomit;
bool AmmoTriggerCooldown[MAXPLAYERS + 1];
Handle SpecialAmmoEffectValues[MAXPLAYERS + 1];
Handle ActiveAmmoCooldownValues[MAXPLAYERS + 1];
Handle PlayActiveAbilities[MAXPLAYERS + 1];
Handle PlayerActiveAmmo[MAXPLAYERS + 1];
Handle DrawSpecialAmmoKeys[MAXPLAYERS + 1];
Handle DrawSpecialAmmoValues[MAXPLAYERS + 1];
Handle SpecialAmmoStrengthValues[MAXPLAYERS + 1];
Handle WeaponLevel[MAXPLAYERS + 1];
Handle ExperienceBank[MAXPLAYERS + 1];
Handle MenuPosition[MAXPLAYERS + 1];
Handle IsClientInRangeSAValues[MAXPLAYERS + 1];
Handle SpecialAmmoData;
Handle SpecialAmmoSave;
float MovementSpeed[MAXPLAYERS + 1];
int IsPlayerDebugMode[MAXPLAYERS + 1];
char ActiveSpecialAmmo[MAXPLAYERS + 1][64];
float IsSpecialAmmoEnabled[MAXPLAYERS + 1][4];
bool bIsInCombat[MAXPLAYERS + 1];
float CombatTime[MAXPLAYERS + 1];
bool bIsSurvivorFatigue[MAXPLAYERS + 1];
int SurvivorStamina[MAXPLAYERS + 1];
float SurvivorConsumptionTime[MAXPLAYERS + 1];
float SurvivorStaminaTime[MAXPLAYERS + 1];
bool ISSLOW[MAXPLAYERS + 1];
float fSlowSpeed[MAXPLAYERS + 1];
Handle ISFROZEN[MAXPLAYERS + 1];
float ISEXPLODETIME[MAXPLAYERS + 1];
Handle ISEXPLODE[MAXPLAYERS + 1];
Handle ISBLIND[MAXPLAYERS + 1];
Handle EntityOnFire;
Handle EntityOnFireName;
Handle CommonInfected[MAXPLAYERS + 1];
Handle RCAffixes[MAXPLAYERS + 1];
Handle h_CommonKeys;
Handle h_CommonValues;
Handle SearchKey_Section;
Handle h_CAKeys;
Handle h_CAValues;
Handle CommonAffixes;// the array holding the common entity id and the affix associated with the common infected. If multiple affixes, multiple keyvalues for the entity id will be created instead of multiple entries.
Handle a_CommonAffixes;			// the array holding the config data
Handle a_HandicapLevels;		// handicap levels so we can customize them at any time in a config file and nothing has to be hard-coded.
int UpgradesAwarded[MAXPLAYERS + 1];
int UpgradesAvailable[MAXPLAYERS + 1];
bool b_IsDead[MAXPLAYERS + 1];
int ExperienceDebt[MAXPLAYERS + 1];
Handle damageOfSpecialInfected;
Handle damageOfWitch;
Handle damageOfCommonInfected;
Handle InfectedHealth[MAXPLAYERS + 1];
Handle SpecialCommon[MAXPLAYERS + 1];
Handle WitchList;
Handle WitchDamage[MAXPLAYERS + 1];
Handle Give_Store_Keys;
Handle Give_Store_Values;
Handle Give_Store_Section;
bool bIsMeleeCooldown[MAXPLAYERS + 1];
Handle a_WeaponDamages;
char Public_LastChatUser[64];
char Infected_LastChatUser[64];
char Survivor_LastChatUser[64];
char Spectator_LastChatUser[64];
char currentCampaignName[64];
Handle h_KilledPosition_X[MAXPLAYERS + 1];
Handle h_KilledPosition_Y[MAXPLAYERS + 1];
Handle h_KilledPosition_Z[MAXPLAYERS + 1];
bool bIsEligibleMapAward[MAXPLAYERS + 1];
bool b_FirstLoad = false;
bool b_MapStart = false;
bool b_HardcoreMode[MAXPLAYERS + 1];
int PreviousRoundIncaps[MAXPLAYERS + 1];
int RoundIncaps[MAXPLAYERS + 1];
char CONFIG_MAIN[64];
bool b_IsCampaignComplete;
bool b_IsRoundIsOver;
bool b_IsCheckpointDoorStartOpened;
int resr[MAXPLAYERS + 1];
int LastPlayLength[MAXPLAYERS + 1];
int RestedExperience[MAXPLAYERS + 1];
int MapRoundsPlayed;
char LastSpoken[MAXPLAYERS + 1][512];
Handle RPGMenuPosition[MAXPLAYERS + 1];
bool b_IsInSaferoom[MAXPLAYERS + 1];
Handle hDatabase												=	INVALID_HANDLE;
char ConfigPathDirectory[64];
char LogPathDirectory[64];
char PurchaseTalentName[MAXPLAYERS + 1][64];
int PurchaseTalentPoints[MAXPLAYERS + 1];
Handle a_Trails;
Handle TrailsKeys[MAXPLAYERS + 1];
Handle TrailsValues[MAXPLAYERS + 1];
bool b_IsFinaleActive;
int RoundDamage[MAXPLAYERS + 1];
//int RoundDamageTotal;
Handle MOTValues[MAXPLAYERS + 1];
Handle DamageValues[MAXPLAYERS + 1];
Handle DamageSection[MAXPLAYERS + 1];
Handle BoosterKeys[MAXPLAYERS + 1];
Handle BoosterValues[MAXPLAYERS + 1];
char PathSetting[64];
int OriginalHealth[MAXPLAYERS + 1];
bool b_IsLoadingStore[MAXPLAYERS + 1];
int FreeUpgrades[MAXPLAYERS + 1];
Handle StoreTimeKeys[MAXPLAYERS + 1];
Handle StoreTimeValues[MAXPLAYERS + 1];
Handle StoreKeys[MAXPLAYERS + 1];
Handle StoreValues[MAXPLAYERS + 1];
Handle StoreMultiplierKeys[MAXPLAYERS + 1];
Handle StoreMultiplierValues[MAXPLAYERS + 1];
Handle a_Store_Player[MAXPLAYERS + 1];
bool b_IsLoadingTrees[MAXPLAYERS + 1];
bool b_IsArraysCreated[MAXPLAYERS + 1];
Handle a_Store;
int PlayerUpgradesTotal[MAXPLAYERS + 1];
float f_TankCooldown;
float DeathLocation[MAXPLAYERS + 1][3];
int TimePlayed[MAXPLAYERS + 1];
bool b_IsLoading[MAXPLAYERS + 1];
int LastLivingSurvivor;
float f_OriginStart[MAXPLAYERS + 1][3];
float f_OriginEnd[MAXPLAYERS + 1][3];
int t_Distance[MAXPLAYERS + 1];
int t_Healing[MAXPLAYERS + 1];
bool b_IsActiveRound;
bool b_IsFirstPluginLoad;
char s_rup[32];
Handle MainKeys;
Handle MainValues;
Handle a_Menu_Talents;
Handle a_Menu_Main;
Handle a_Events;
Handle a_Points;
Handle a_Pets;
Handle a_Database_Talents;
Handle a_Database_Talents_Defaults;
Handle a_Database_Talents_Defaults_Name;
Handle ActiveEffectKeys[MAXPLAYERS + 1];
Handle ActiveEffectValues[MAXPLAYERS + 1];
Handle MenuKeys[MAXPLAYERS + 1];
Handle MenuValues[MAXPLAYERS + 1];
Handle AbilityMultiplierCalculator[MAXPLAYERS + 1];
Handle MenuSection[MAXPLAYERS + 1];
Handle FiredTalentHandle[MAXPLAYERS + 1];
Handle TriggerValues[MAXPLAYERS + 1];
Handle PreloadTalentValues[MAXPLAYERS + 1];
Handle MyTalentStrengths[MAXPLAYERS + 1];
Handle MyTalentStrength[MAXPLAYERS + 1];
Handle AbilityKeys[MAXPLAYERS + 1];
Handle PurchaseKeys[MAXPLAYERS + 1];
Handle PurchaseValues[MAXPLAYERS + 1];
Handle EventSection;
Handle HookSection;
Handle CallKeys;
Handle CallValues;
Handle DirectorKeys;
Handle DirectorValues;
Handle DatabaseKeys;
Handle DatabaseValues;
Handle DatabaseSection;
Handle a_Database_PlayerTalents_Bots;
Handle PlayerAbilitiesCooldown_Bots;
Handle PlayerAbilitiesImmune_Bots;
Handle LoadDirectorSection;
Handle QueryDirectorKeys;
Handle QueryDirectorValues;
Handle QueryDirectorSection;
Handle FirstDirectorKeys;
Handle FirstDirectorValues;
Handle FirstDirectorSection;
Handle a_Database_PlayerTalents[MAXPLAYERS + 1];
Handle a_Database_PlayerTalents_Experience[MAXPLAYERS + 1];
Handle PlayerAbilitiesName;
Handle PlayerAbilitiesCooldown[MAXPLAYERS + 1];
Handle PlayerActiveAbilitiesCooldown[MAXPLAYERS + 1];
Handle a_DirectorActions;
Handle a_DirectorActions_Cooldown;
int PlayerLevel[MAXPLAYERS + 1];
int PlayerLevelUpgrades[MAXPLAYERS + 1];
int TotalTalentPoints[MAXPLAYERS + 1];
int ExperienceLevel[MAXPLAYERS + 1];
int SkyPoints[MAXPLAYERS + 1];
char MenuSelection[MAXPLAYERS + 1][PLATFORM_MAX_PATH];
char MenuSelection_p[MAXPLAYERS + 1][PLATFORM_MAX_PATH];
char MenuName_c[MAXPLAYERS + 1][PLATFORM_MAX_PATH];
float Points[MAXPLAYERS + 1];
int DamageAward[MAXPLAYERS + 1][MAXPLAYERS + 1];
int DefaultHealth[MAXPLAYERS + 1];
char white[4];
char green[4];
char blue[4];
char orange[4];
bool b_IsBlind[MAXPLAYERS + 1];
bool b_IsImmune[MAXPLAYERS + 1];
float SpeedMultiplier[MAXPLAYERS + 1];
float SpeedMultiplierBase[MAXPLAYERS + 1];
bool b_IsJumping[MAXPLAYERS + 1];
Handle g_hEffectAdrenaline = INVALID_HANDLE;
Handle g_hCallVomitOnPlayer = INVALID_HANDLE;
Handle hRoundRespawn = INVALID_HANDLE;
Handle g_hCreateAcid = INVALID_HANDLE;
float GravityBase[MAXPLAYERS + 1];
bool b_GroundRequired[MAXPLAYERS + 1];
int CoveredInBile[MAXPLAYERS + 1][MAXPLAYERS + 1];
int CommonKills[MAXPLAYERS + 1];
int CommonKillsHeadshot[MAXPLAYERS + 1];
char OpenedMenu_p[MAXPLAYERS + 1][512];
char OpenedMenu[MAXPLAYERS + 1][512];
int ExperienceOverall[MAXPLAYERS + 1];
int ExperienceLevel_Bots;
int PlayerLevel_Bots;
float Points_Director;
Handle CommonInfectedQueue;
int g_oAbility = 0;
Handle g_hIsStaggering = INVALID_HANDLE;
Handle g_hSetClass = INVALID_HANDLE;
Handle g_hCreateAbility = INVALID_HANDLE;
Handle gd = INVALID_HANDLE;
bool b_IsDirectorTalents[MAXPLAYERS + 1];
int LoadPos[MAXPLAYERS + 1];
int LoadPos_Director;
ConVar g_Steamgroup;
ConVar g_svCheats;
ConVar g_Gamemode;
int RoundTime;
int g_iSprite = 0;
int g_BeaconSprite = 0;
int iNoSpecials;
bool b_HasDeathLocation[MAXPLAYERS + 1];
bool b_IsMissionFailed;
Handle CCASection;
Handle CCAKeys;
Handle CCAValues;
int LastWeaponDamage[MAXPLAYERS + 1];
float UseItemTime[MAXPLAYERS + 1];
Handle NewUsersRound;
Handle MenuStructure[MAXPLAYERS + 1];
Handle TankState_Array[MAXPLAYERS + 1];
bool bIsGiveIncapHealth[MAXPLAYERS + 1];
Handle TheLeaderboards[MAXPLAYERS + 1];
Handle TheLeaderboardsDataFirst[MAXPLAYERS + 1];
Handle TheLeaderboardsDataSecond[MAXPLAYERS + 1];
int TheLeaderboardsPage[MAXPLAYERS + 1];// 10 entries at a time, until the end of time.
bool bIsMyRanking[MAXPLAYERS + 1];
int TheLeaderboardsPageSize[MAXPLAYERS + 1];
int CurrentRPGMode;
bool IsSurvivalMode = false;
int BestRating[MAXPLAYERS + 1];
int MyRespawnTarget[MAXPLAYERS + 1];
bool RespawnImmunity[MAXPLAYERS + 1];
char TheDBPrefix[64];
int LastAttackedUser[MAXPLAYERS + 1];
Handle LoggedUsers;
Handle TalentTreeValues[MAXPLAYERS + 1];
Handle TalentExperienceValues[MAXPLAYERS + 1];
Handle TalentActionValues[MAXPLAYERS + 1];
bool bIsTalentTwo[MAXPLAYERS + 1];
Handle CommonDrawKeys;
Handle CommonDrawValues;
bool bAutoRevive[MAXPLAYERS + 1];
bool bIsClassAbilities[MAXPLAYERS + 1];
bool bIsDisconnecting[MAXPLAYERS + 1];
int LoadProfileRequestName[MAXPLAYERS + 1];
char TheCurrentMap[64];
bool IsEnrageNotified;
int ClientActiveStance[MAXPLAYERS + 1];
Handle SurvivorsIgnored[MAXPLAYERS + 1];
bool HasSeenCombat[MAXPLAYERS + 1];
int MyBirthday[MAXPLAYERS + 1];
//======================================
//Main config static variables.
//======================================
float fSuperCommonLimit;
float fBurnPercentage;
int iTankRush;
int iTanksAlways;
float fSprintSpeed;
int iRPGMode;
int DirectorWitchLimit;
float fCommonQueueLimit;
float fDirectorThoughtDelay;
float fDirectorThoughtHandicap;
float fDirectorThoughtProcessMinimum;
int iSurvivalRoundTime;
float fDazedDebuffEffect;
int ConsumptionInt;
float fStamJetpackInterval;
float fStamSprintInterval;
float fStamRegenTime;
float fStamRegenTimeAdren;
float fBaseMovementSpeed;
//float fFatigueMovementSpeed;
int iPlayerStartingLevel;
int iBotPlayerStartingLevel;
float fOutOfCombatTime;
int iWitchDamageInitial;
float fWitchDamageScaleLevel;
float fSurvivorDamageBonus;
float fSurvivorHealthBonus;
int iEnrageTime;
float fWitchDirectorPoints;
float fEnrageDirectorPoints;
float fCommonDamageLevel;
int iBotLevelType;
float fCommonDirectorPoints;
int iDisplayHealthBars;
float fDamagePlayerLevel[7];
float fHealthPlayerLevel[7];
int iBaseSpecialDamage[7];
int iBaseSpecialInfectedHealth[7];
float fPointsMultiplierInfected;
float fPointsMultiplier;
float fHealingMultiplier;
float fBuffingMultiplier;
float fHexingMultiplier;
float TanksNearbyRange;
int iCommonAffixes;
int BroadcastType;
int iDoomTimer;
int iSurvivorStaminaMax;
float fRatingMultSpecials;
float fRatingMultSupers;
float fRatingMultCommons;
float fRatingMultTank;
float fRatingMultWitch;
float fTeamworkExperience;
float fItemMultiplierLuck;
float fItemMultiplierTeam;
char sQuickBindHelp[64];
float fPointsCostLevel;
int PointPurchaseType;
int iTankLimitVersus;
float fHealRequirementTeam;
int iSurvivorBaseHealth;
int iSurvivorBotBaseHealth;
char spmn[64];
float fHealthSurvivorRevive;
char RestrictedWeapons[1024];
int iMaxLevel;
int iMaxLevelBots;
int iExperienceStart;
float fExperienceMultiplier;
float fExperienceMultiplierHardcore;
char sBotTeam[64];
int iNumAugments;
int iActionBarSlots;
char MenuCommand[64];
int HostNameTime;
int DoomSUrvivorsRequired;
int DoomKillTimer;
float fVersusTankNotice;
int AllowedCommons;
int AllowedMegaMob;
int AllowedMobSpawn;
int AllowedMobSpawnFinale;
//new AllowedPanicInterval;
int RespawnQueue;
int MaximumPriority;
float fUpgradeExpCost;
int iWitchHealthBase;
float fWitchHealthMult;
int RatingPerLevel;
int RatingPerAugmentLevel;
int RatingPerLevelSurvivorBots;
int iCommonBaseHealth;
float fCommonLevelHealthMult;
int iServerLevelRequirement;
float GroupMemberBonus;
float FinSurvBon;
int RaidLevMult;
int iIgnoredRating;
int iIgnoredRatingMax;
int iInfectedLimit;
float SurvivorExperienceMult;
float SurvivorExperienceMultTank;
float TheScorchMult;
float TheInfernoMult;
float fAdrenProgressMult;
float DirectorTankCooldown;
int DisplayType;
char sDirectorTeam[64];
float fRestedExpMult;
float fSurvivorExpMult;
int iDebuffLimit;
int iRatingSpecialsRequired;
int iRatingTanksRequired;
char sDbLeaderboards[64];
int iIsLifelink;
char sItemModel[512];
int iSurvivorGroupMinimum;
Handle PreloadKeys;
Handle PreloadValues;
Handle persistentCirculation;
int iEnrageAdvertisement;
int iJoinGroupAdvertisement;
int iNotifyEnrage;
char sBackpackModel[64];
bool bIsNewPlayer[MAXPLAYERS + 1];
Handle MyGroup[MAXPLAYERS + 1];
int iCommonsLimitUpper;
bool bIsInCheckpoint[MAXPLAYERS + 1];
float fCoopSurvBon;
int iMinSurvivors;
int PassiveEffectDisplay[MAXPLAYERS + 1];
char sServerDifficulty[64];
int iSpecialsAllowed;
char sSpecialsAllowed[64];
int iSurvivorModifierRequired;
float fEnrageMultiplier;
bool bHealthIsSet[MAXPLAYERS + 1];
int iIsLevelingPaused[MAXPLAYERS + 1];
int iIsBulletTrails[MAXPLAYERS + 1];
Handle ActiveStatuses[MAXPLAYERS + 1];
int InfectedTalentLevel;
float LastAttackTime[MAXPLAYERS + 1];
Handle hWeaponList[MAXPLAYERS + 1];
int MyStatusEffects[MAXPLAYERS + 1];
int iShowLockedTalents;
Handle PassiveStrengthValues[MAXPLAYERS + 1];
Handle PassiveTalentName[MAXPLAYERS + 1];
int iChaseEnt[MAXPLAYERS + 1];
int iTeamRatingRequired;
float fTeamRatingBonus;
float fRatingPercentLostOnDeath;
int PlayerCurrentMenuLayer[MAXPLAYERS + 1];
int iMaxLayers;
Handle TranslationOTNValues[MAXPLAYERS + 1];
Handle acdrValues[MAXPLAYERS + 1];
Handle GetLayerStrengthValues[MAXPLAYERS + 1];
int iCommonInfectedBaseDamage;
int playerPageOfCharacterSheet[MAXPLAYERS + 1];
int nodesInExistence;
int iShowTotalNodesOnTalentTree;
Handle PlayerEffectOverTime[MAXPLAYERS + 1];
float fSpecialAmmoInterval;
Handle CooldownEffectTriggerValues[MAXPLAYERS + 1];
Handle IsSpellAnAuraValues[MAXPLAYERS + 1];
float fStaggerTickrate;
float fSuperCommonTickrate;
Handle StaggeredTargets;
Handle staggerBuffer;
bool staggerCooldownOnTriggers[MAXPLAYERS + 1];
Handle CallAbilityCooldownTriggerValues[MAXPLAYERS + 1];
Handle GetIfTriggerRequirementsMetValues[MAXPLAYERS + 1];
bool ShowPlayerLayerInformation[MAXPLAYERS + 1];
Handle GAMValues[MAXPLAYERS + 1];
char RPGMenuCommand[64];
int RPGMenuCommandExplode;
//new PrestigeLevel[MAXPLAYERS + 1];
char DefaultProfileName[64];
char DefaultBotProfileName[64];
char DefaultInfectedProfileName[64];
Handle GetGoverningAttributeValues[MAXPLAYERS + 1];
int iTanksAlwaysEnforceCooldown;
Handle WeaponResultValues[MAXPLAYERS + 1];
Handle WeaponResultSection[MAXPLAYERS + 1];
bool shotgunCooldown[MAXPLAYERS + 1];
float fRatingFloor;
char negativeStatusEffects[MAXPLAYERS + 1][64];
char positiveStatusEffects[MAXPLAYERS + 1][64];
char clientTrueHealthDisplay[MAXPLAYERS + 1][64];
char clientContributionHealthDisplay[MAXPLAYERS + 1][64];
int iExperienceDebtLevel;
int iExperienceDebtEnabled;
float fExperienceDebtPenalty;
int iShowDamageOnActionBar;
int iDefaultIncapHealth;
Handle GetTalentValueSearchValues[MAXPLAYERS + 1];
Handle GetTalentStrengthSearchValues[MAXPLAYERS + 1];
int iSkyLevelNodeUnlocks;
Handle GetTalentKeyValueValues[MAXPLAYERS + 1];
Handle ApplyDebuffCooldowns[MAXPLAYERS + 1];
int iCanSurvivorBotsBurn;
char defaultLoadoutWeaponPrimary[64];
char defaultLoadoutWeaponSecondary[64];
//int iDeleteCommonsFromExistenceOnDeath;
int iShowDetailedDisplayAlways;
int iCanJetpackWhenInCombat;
Handle ZoomcheckDelayer[MAXPLAYERS + 1];
Handle zoomCheckList;
float fquickScopeTime;
Handle holdingFireList;
int iEnsnareLevelMultiplier;
int lastBaseDamage[MAXPLAYERS + 1];
int lastTarget[MAXPLAYERS + 1];
int iSurvivorBotsBonusLimit;
float fSurvivorBotsNoneBonus;
bool bTimersRunning[MAXPLAYERS + 1];
int iShowAdvertToNonSteamgroupMembers;
int displayBuffOrDebuff[MAXPLAYERS + 1];
int iStrengthOnSpawnIsStrength;
Handle SetNodesKeys;
Handle SetNodesValues;
float fDrawHudInterval;
bool ImmuneToAllDamage[MAXPLAYERS + 1];
int iPlayersLeaveCombatDuringFinales;
int iAllowPauseLeveling;
//new iDropAcidOnLastDebuffDrop;
float fMaxDamageResistance;
float fStaminaPerPlayerLevel;
int LastBulletCheck[MAXPLAYERS + 1];
int iSpecialInfectedMinimum;
int iEndRoundIfNoHealthySurvivors;
int iEndRoundIfNoLivingHumanSurvivors;
float fAcidDamagePlayerLevel;
float fAcidDamageSupersPlayerLevel;
char ClientStatusEffects[MAXPLAYERS + 1][2][64];
float fTankMovementSpeed_Burning;
float fTankMovementSpeed_Hulk;
float fTankMovementSpeed_Death;
int iResetPlayerLevelOnDeath;
int iStartingPlayerUpgrades;
char serverKey[64];
bool playerHasAdrenaline[MAXPLAYERS + 1];
bool playerInSlowAmmo[MAXPLAYERS + 1];
int leaderboardPageCount;
float fForceTankJumpHeight;
float fForceTankJumpRange;
int iResetDirectorPointsOnNewRound;
int iMaxServerUpgrades;
bool LastHitWasHeadshot[MAXPLAYERS + 1];
char acmd[20];
char abcmd[20];
//int iDeleteSupersOnDeath;
//int iShoveStaminaCost;
float fLootChanceTank;
float fLootChanceWitch;
float fLootChanceSpecials;
float fLootChanceSupers;
float fLootChanceCommons;
int iLootEnabled;
float fUpgradesRequiredPerLayer;
int iEnsnareRestrictions;
int levelToSet[MAXPLAYERS+1];
char steamIdSearch[MAXPLAYERS+1][64];
char baseName[MAXPLAYERS+1][64];
float fSurvivorBufferBonus;
int iCommonInfectedSpawnDelayOnNewRound;
int scoreRequiredForLeaderboard;
bool bIsClientCurrentlyStaggered[MAXPLAYERS +1];
char loadProfileOverrideFlags[64];
int iUpgradesRequiredForLoot;
Handle playerContributionTracker[MAXPLAYERS + 1];
Handle playerCustomEntitiesCreated;
int lastEntityDropped[MAXPLAYERS + 1];
int ConsecutiveHeadshots[MAXPLAYERS + 1];
int iUseLinearLeveling;
int currentWeaponCategory[MAXPLAYERS + 1];
int iUniqueServerCode;
int lootDropCounter;
Handle myUnlockedCategories[MAXPLAYERS + 1];
Handle myUnlockedActivators[MAXPLAYERS + 1];
Handle myUnlockedTargets[MAXPLAYERS + 1];
Handle myLootDropCategoriesAllowed[MAXPLAYERS + 1];
Handle myLootDropTargetEffectsAllowed[MAXPLAYERS + 1];
Handle myLootDropActivatorEffectsAllowed[MAXPLAYERS + 1];
Handle LootDropCategoryToBuffValues[MAXPLAYERS + 1];
Handle myAugmentSavedProfiles[MAXPLAYERS + 1];
Handle myAugmentIDCodes[MAXPLAYERS + 1];
Handle myAugmentCategories[MAXPLAYERS + 1];
Handle myAugmentOwners[MAXPLAYERS + 1];
Handle myAugmentOwnersName[MAXPLAYERS + 1];
Handle myAugmentInfo[MAXPLAYERS + 1];
int iAugmentLevelDivisor;
float fAugmentRatingMultiplier;
float fAugmentActivatorRatingMultiplier;
float fAugmentTargetRatingMultiplier;
Handle equippedAugments[MAXPLAYERS + 1];
Handle equippedAugmentsCategory[MAXPLAYERS + 1];
int iRatingRequiredForAugmentLootDrops;
Handle GetAugmentTranslationKeys[MAXPLAYERS + 1];
Handle GetAugmentTranslationVals[MAXPLAYERS + 1];
float fAugmentTierChance;
Handle equippedAugmentsActivator[MAXPLAYERS + 1];
Handle equippedAugmentsTarget[MAXPLAYERS + 1];
Handle myAugmentActivatorEffects[MAXPLAYERS + 1];
Handle myAugmentTargetEffects[MAXPLAYERS + 1];
Handle equippedAugmentsIDCodes[MAXPLAYERS + 1];
int AugmentClientIsInspecting[MAXPLAYERS + 1];
int augmentParts[MAXPLAYERS + 1];
int itemToDisassemble[MAXPLAYERS + 1];
char sCategoriesToIgnore[512];
float fAntiFarmDistance;
int iAntiFarmMax;
Handle lootRollData[MAXPLAYERS + 1];
float fLootBagExpirationTimeInSeconds;
Handle playerLootOnGround[MAXPLAYERS + 1];
Handle playerLootOnGroundId[MAXPLAYERS + 1];
int iExplosionBaseDamagePipe;
int iExplosionBaseDamage;
float fProficiencyLevelDamageIncrease;
int playerCurrentAugmentLevel[MAXPLAYERS + 1];
Handle possibleLootPoolTarget[MAXPLAYERS + 1];
Handle possibleLootPoolActivator[MAXPLAYERS + 1];
Handle unlockedLootPoolTarget[MAXPLAYERS + 1];
Handle unlockedLootPoolActivator[MAXPLAYERS + 1];
int iJetpackEnabled;
float fJumpTimeToActivateJetpack;
int iNumLootDropChancesPerPlayer[5];
char lastPlayerGrab[64];
int iInventoryLimit;
char sDeleteBotFlags[64];
int iMultiplierForAugmentLootDrops;

stock CreateAllArrays() {
	if (b_FirstLoad) return;
	LogMessage("=====\t\tRunning first-time load of RPG.\t\t=====");
	if (ModelsToPrecache == INVALID_HANDLE) ModelsToPrecache = CreateArray(16);
	if (TalentMenuConfigs == INVALID_HANDLE) TalentMenuConfigs = CreateArray(32);
	if (holdingFireList == INVALID_HANDLE) holdingFireList = CreateArray(16);
	if (zoomCheckList == INVALID_HANDLE) zoomCheckList = CreateArray(16);
	if (hThreatSort == INVALID_HANDLE) hThreatSort = CreateArray(16);
	if (hThreatMeter == INVALID_HANDLE) hThreatMeter = CreateArray(16);
	if (LoggedUsers == INVALID_HANDLE) LoggedUsers = CreateArray(16);
	if (SuperCommonQueue == INVALID_HANDLE) SuperCommonQueue = CreateArray(16);
	if (CommonInfectedQueue == INVALID_HANDLE) CommonInfectedQueue = CreateArray(16);
	if (CoveredInVomit == INVALID_HANDLE) CoveredInVomit = CreateArray(16);
	if (NewUsersRound == INVALID_HANDLE) NewUsersRound = CreateArray(16);
	if (SpecialAmmoData == INVALID_HANDLE) SpecialAmmoData = CreateArray(16);
	if (SpecialAmmoSave == INVALID_HANDLE) SpecialAmmoSave = CreateArray(16);
	if (MainKeys == INVALID_HANDLE) MainKeys = CreateArray(16);
	if (MainValues == INVALID_HANDLE) MainValues = CreateArray(16);
	if (a_Menu_Talents == INVALID_HANDLE) a_Menu_Talents = CreateArray(4);
	if (a_Menu_Main == INVALID_HANDLE) a_Menu_Main = CreateArray(3);
	if (a_Events == INVALID_HANDLE) a_Events = CreateArray(3);
	if (a_Points == INVALID_HANDLE) a_Points = CreateArray(3);
	if (a_Pets == INVALID_HANDLE) a_Pets = CreateArray(3);
	if (a_Store == INVALID_HANDLE) a_Store = CreateArray(3);
	if (a_Trails == INVALID_HANDLE) a_Trails = CreateArray(3);
	if (a_Database_Talents == INVALID_HANDLE) a_Database_Talents = CreateArray(16);
	if (a_Database_Talents_Defaults == INVALID_HANDLE) a_Database_Talents_Defaults 	= CreateArray(16);
	if (a_Database_Talents_Defaults_Name == INVALID_HANDLE) a_Database_Talents_Defaults_Name				= CreateArray(16);
	if (EventSection == INVALID_HANDLE) EventSection									= CreateArray(16);
	if (HookSection == INVALID_HANDLE) HookSection										= CreateArray(16);
	if (CallKeys == INVALID_HANDLE) CallKeys										= CreateArray(16);
	if (CallValues == INVALID_HANDLE) CallValues										= CreateArray(16);
	if (DirectorKeys == INVALID_HANDLE) DirectorKeys									= CreateArray(16);
	if (DirectorValues == INVALID_HANDLE) DirectorValues									= CreateArray(16);
	if (DatabaseKeys == INVALID_HANDLE) DatabaseKeys									= CreateArray(16);
	if (DatabaseValues == INVALID_HANDLE) DatabaseValues									= CreateArray(16);
	if (DatabaseSection == INVALID_HANDLE) DatabaseSection									= CreateArray(16);
	if (a_Database_PlayerTalents_Bots == INVALID_HANDLE) a_Database_PlayerTalents_Bots					= CreateArray(16);
	if (PlayerAbilitiesCooldown_Bots == INVALID_HANDLE) PlayerAbilitiesCooldown_Bots					= CreateArray(16);
	if (PlayerAbilitiesImmune_Bots == INVALID_HANDLE) PlayerAbilitiesImmune_Bots						= CreateArray(16);
	if (LoadDirectorSection == INVALID_HANDLE) LoadDirectorSection								= CreateArray(16);
	if (QueryDirectorKeys == INVALID_HANDLE) QueryDirectorKeys								= CreateArray(16);
	if (QueryDirectorValues == INVALID_HANDLE) QueryDirectorValues								= CreateArray(16);
	if (QueryDirectorSection == INVALID_HANDLE) QueryDirectorSection							= CreateArray(16);
	if (FirstDirectorKeys == INVALID_HANDLE) FirstDirectorKeys								= CreateArray(16);
	if (FirstDirectorValues == INVALID_HANDLE) FirstDirectorValues								= CreateArray(16);
	if (FirstDirectorSection == INVALID_HANDLE) FirstDirectorSection							= CreateArray(16);
	if (PlayerAbilitiesName == INVALID_HANDLE) PlayerAbilitiesName								= CreateArray(16);
	if (a_DirectorActions == INVALID_HANDLE) a_DirectorActions								= CreateArray(3);
	if (a_DirectorActions_Cooldown == INVALID_HANDLE) a_DirectorActions_Cooldown						= CreateArray(16);
	if (Give_Store_Keys == INVALID_HANDLE) Give_Store_Keys							= CreateArray(16);
	if (Give_Store_Values == INVALID_HANDLE) Give_Store_Values							= CreateArray(16);
	if (Give_Store_Section == INVALID_HANDLE) Give_Store_Section							= CreateArray(16);
	if (a_WeaponDamages == INVALID_HANDLE) a_WeaponDamages = CreateArray(16);
	if (a_CommonAffixes == INVALID_HANDLE) a_CommonAffixes = CreateArray(16);
	if (a_HandicapLevels == INVALID_HANDLE) a_HandicapLevels = CreateArray(16);
	if (WitchList == INVALID_HANDLE) WitchList				= CreateArray(16);
	if (CommonAffixes == INVALID_HANDLE) CommonAffixes	= CreateArray(32);
	if (h_CAKeys == INVALID_HANDLE) h_CAKeys = CreateArray(16);
	if (h_CAValues == INVALID_HANDLE) h_CAValues = CreateArray(16);
	if (SearchKey_Section == INVALID_HANDLE) SearchKey_Section = CreateArray(16);
	if (CCASection == INVALID_HANDLE) CCASection = CreateArray(16);
	if (CCAKeys == INVALID_HANDLE) CCAKeys = CreateArray(16);
	if (CCAValues == INVALID_HANDLE) CCAValues = CreateArray(16);
	if (h_CommonKeys == INVALID_HANDLE) h_CommonKeys = CreateArray(16);
	if (h_CommonValues == INVALID_HANDLE) h_CommonValues = CreateArray(16);
	//if (CommonInfected == INVALID_HANDLE) CommonInfected = CreateArray(16);
	if (EntityOnFire == INVALID_HANDLE) EntityOnFire = CreateArray(32);
	if (EntityOnFireName == INVALID_HANDLE) EntityOnFireName = CreateArray(32);
	if (CommonDrawKeys == INVALID_HANDLE) CommonDrawKeys = CreateArray(16);
	if (CommonDrawValues == INVALID_HANDLE) CommonDrawValues = CreateArray(16);
	if (PreloadKeys == INVALID_HANDLE) PreloadKeys = CreateArray(16);
	if (PreloadValues == INVALID_HANDLE) PreloadValues = CreateArray(16);
	if (persistentCirculation == INVALID_HANDLE) persistentCirculation = CreateArray(16);
	if (RandomSurvivorClient == INVALID_HANDLE) RandomSurvivorClient = CreateArray(16);
	if (EffectOverTime == INVALID_HANDLE) EffectOverTime = CreateArray(16);
	if (TimeOfEffectOverTime == INVALID_HANDLE) TimeOfEffectOverTime = CreateArray(16);
	if (StaggeredTargets == INVALID_HANDLE) StaggeredTargets = CreateArray(16);
	if (SetNodesKeys == INVALID_HANDLE) SetNodesKeys = CreateArray(16);
	if (SetNodesValues == INVALID_HANDLE) SetNodesValues = CreateArray(16);
	if (playerCustomEntitiesCreated == INVALID_HANDLE) playerCustomEntitiesCreated = CreateArray(16);
	if (ClientsPermittedToLoad == INVALID_HANDLE) ClientsPermittedToLoad = CreateArray(16);
	if (ListOfWitchesWhoHaveBeenShot == INVALID_HANDLE) ListOfWitchesWhoHaveBeenShot = CreateArray(8);
	if (tempStorage == INVALID_HANDLE) tempStorage = CreateArray(16);
	if (damageOfSpecialInfected == INVALID_HANDLE) damageOfSpecialInfected = CreateArray(4);
	if (damageOfWitch == INVALID_HANDLE) damageOfWitch = CreateArray(4);
	if (damageOfCommonInfected == INVALID_HANDLE) damageOfCommonInfected = CreateArray(4);
	
	ResizeArray(tempStorage, MAXPLAYERS + 1);
	for (int i = 1; i <= MAXPLAYERS; i++) {
		BuildArraysOnClientFirstLoad(i);
	}
	CreateTimer(1.0, Timer_ExecuteConfig, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
	b_FirstLoad = true;
}

stock BuildArraysOnClientFirstLoad(int client) {
	weaponProficiencyType[client] = -1;
	myCurrentWeaponPos[client] = -1;
	myPrimaryWeaponPos[client] = -1;
	itemToDisassemble[client] = -1;
	augmentParts[client] = 0;
	LastDeathTime[client] = 0.0;
	MyVomitChase[client] = -1;
	b_IsFloating[client] = false;
	DisplayActionBar[client] = false;
	ActionBarSlot[client] = -1;
	b_IsIdle[client] = false;
	if (ActiveEffectKeys[client] == INVALID_HANDLE) ActiveEffectKeys[client] = CreateArray(16);
	if (ActiveEffectValues[client] == INVALID_HANDLE) ActiveEffectValues[client] = CreateArray(16);
	if (MyUnlockedTalents[client] == INVALID_HANDLE) MyUnlockedTalents[client] = CreateArray(16);
	if (GetCoherencyValues[client] == INVALID_HANDLE) GetCoherencyValues[client] = CreateArray(16);
	if (GetValueFloatArray[client] == INVALID_HANDLE) GetValueFloatArray[client] = CreateArray(8);
	if (CommonInfected[client] == INVALID_HANDLE) CommonInfected[client] = CreateArray(16);
	if (possibleLootPool[client] == INVALID_HANDLE) possibleLootPool[client] = CreateArray(16);
	if (unlockedLootPool[client] == INVALID_HANDLE) unlockedLootPool[client] = CreateArray(16);
	if (myUnlockedLootDropCategoriesAllowed[client] == INVALID_HANDLE) myUnlockedLootDropCategoriesAllowed[client] = CreateArray(16);
	if (myUnlockedUnlockedCategories[client] == INVALID_HANDLE) myUnlockedUnlockedCategories[client] = CreateArray(16);
	if (myUnlockedLootDropActivatorEffectsAllowed[client] == INVALID_HANDLE) myUnlockedLootDropActivatorEffectsAllowed[client] = CreateArray(16);
	if (myUnlockedUnlockedActivators[client] == INVALID_HANDLE) myUnlockedUnlockedActivators[client] = CreateArray(16);
	if (myUnlockedLootDropTargetEffectsAllowed[client] == INVALID_HANDLE) myUnlockedLootDropTargetEffectsAllowed[client] = CreateArray(16);
	if (myUnlockedUnlockedTargets[client] == INVALID_HANDLE) myUnlockedUnlockedTargets[client] = CreateArray(16);
	if (currentEquippedWeapon[client] == INVALID_HANDLE) currentEquippedWeapon[client] = CreateTrie();
	if (GetCategoryStrengthValues[client] == INVALID_HANDLE) GetCategoryStrengthValues[client] = CreateArray(16);
	if (PassiveStrengthValues[client] == INVALID_HANDLE) PassiveStrengthValues[client] = CreateArray(16);
	if (PassiveTalentName[client] == INVALID_HANDLE) PassiveTalentName[client] = CreateArray(16);
	if (TranslationOTNValues[client] == INVALID_HANDLE) TranslationOTNValues[client] = CreateArray(16);
	if (hWeaponList[client] == INVALID_HANDLE) hWeaponList[client] = CreateArray(16);
	if (LoadoutConfigKeys[client] == INVALID_HANDLE) LoadoutConfigKeys[client] = CreateArray(16);
	if (LoadoutConfigValues[client] == INVALID_HANDLE) LoadoutConfigValues[client] = CreateArray(16);
	if (LoadoutConfigSection[client] == INVALID_HANDLE) LoadoutConfigSection[client] = CreateArray(16);
	if (ActiveStatuses[client] == INVALID_HANDLE) ActiveStatuses[client] = CreateArray(16);
	if (AbilityConfigValues[client] == INVALID_HANDLE) AbilityConfigValues[client] = CreateArray(16);
	if (IsAbilityValues[client] == INVALID_HANDLE) IsAbilityValues[client] = CreateArray(16);
	if (CheckAbilityKeys[client] == INVALID_HANDLE) CheckAbilityKeys[client] = CreateArray(16);
	if (CheckAbilityValues[client] == INVALID_HANDLE) CheckAbilityValues[client] = CreateArray(16);
	if (CastValues[client] == INVALID_HANDLE) CastValues[client] = CreateArray(16);
	if (ActionBar[client] == INVALID_HANDLE) ActionBar[client] = CreateArray(8);
	if (ActionBarMenuPos[client] == INVALID_HANDLE) ActionBarMenuPos[client] = CreateArray(16);
	if (TalentsAssignedValues[client] == INVALID_HANDLE) TalentsAssignedValues[client] = CreateArray(16);
	if (CartelValueValues[client] == INVALID_HANDLE) CartelValueValues[client] = CreateArray(16);
	if (TalentActionValues[client] == INVALID_HANDLE) TalentActionValues[client] = CreateArray(16);
	if (TalentExperienceValues[client] == INVALID_HANDLE) TalentExperienceValues[client] = CreateArray(16);
	if (TalentTreeValues[client] == INVALID_HANDLE) TalentTreeValues[client] = CreateArray(16);
	if (TheLeaderboards[client] == INVALID_HANDLE) TheLeaderboards[client] = CreateArray(16);
	if (TheLeaderboardsDataFirst[client] == INVALID_HANDLE) TheLeaderboardsDataFirst[client] = CreateArray(8);
	if (TheLeaderboardsDataSecond[client] == INVALID_HANDLE) TheLeaderboardsDataSecond[client] = CreateArray(8);
	if (TankState_Array[client] == INVALID_HANDLE) TankState_Array[client] = CreateArray(16);
	if (MenuStructure[client] == INVALID_HANDLE) MenuStructure[client] = CreateArray(16);
	if (TempAttributes[client] == INVALID_HANDLE) TempAttributes[client] = CreateArray(16);
	if (TempTalents[client] == INVALID_HANDLE) TempTalents[client] = CreateArray(16);
	if (PlayerProfiles[client] == INVALID_HANDLE) PlayerProfiles[client] = CreateArray(32);
	if (SpecialAmmoEffectValues[client] == INVALID_HANDLE) SpecialAmmoEffectValues[client] = CreateArray(16);
	if (ActiveAmmoCooldownValues[client] == INVALID_HANDLE) ActiveAmmoCooldownValues[client] = CreateArray(16);
	if (PlayActiveAbilities[client] == INVALID_HANDLE) PlayActiveAbilities[client] = CreateArray(16);
	if (PlayerActiveAmmo[client] == INVALID_HANDLE) PlayerActiveAmmo[client] = CreateArray(16);
	if (DrawSpecialAmmoKeys[client] == INVALID_HANDLE) DrawSpecialAmmoKeys[client] = CreateArray(16);
	if (DrawSpecialAmmoValues[client] == INVALID_HANDLE) DrawSpecialAmmoValues[client] = CreateArray(16);
	if (SpecialAmmoStrengthValues[client] == INVALID_HANDLE) SpecialAmmoStrengthValues[client] = CreateArray(16);
	if (WeaponLevel[client] == INVALID_HANDLE) WeaponLevel[client] = CreateArray(16);
	if (ExperienceBank[client] == INVALID_HANDLE) ExperienceBank[client] = CreateArray(16);
	if (MenuPosition[client] == INVALID_HANDLE) MenuPosition[client] = CreateArray(16);
	if (IsClientInRangeSAValues[client] == INVALID_HANDLE) IsClientInRangeSAValues[client] = CreateArray(16);
	if (InfectedHealth[client] == INVALID_HANDLE) InfectedHealth[client] = CreateArray(16);
	if (WitchDamage[client] == INVALID_HANDLE) WitchDamage[client]	= CreateArray(16);
	if (SpecialCommon[client] == INVALID_HANDLE) SpecialCommon[client] = CreateArray(16);
	if (MenuKeys[client] == INVALID_HANDLE) MenuKeys[client]								= CreateArray(16);
	if (MenuValues[client] == INVALID_HANDLE) MenuValues[client]							= CreateArray(16);
	if (AbilityMultiplierCalculator[client] == INVALID_HANDLE) AbilityMultiplierCalculator[client] = CreateArray(16);
	if (MenuSection[client] == INVALID_HANDLE) MenuSection[client]							= CreateArray(16);
	if (TriggerValues[client] == INVALID_HANDLE) TriggerValues[client]						= CreateArray(16);
	if (FiredTalentHandle[client] == INVALID_HANDLE) FiredTalentHandle[client]				= CreateArray(16);
	if (PreloadTalentValues[client] == INVALID_HANDLE) PreloadTalentValues[client]			= CreateArray(16);
	if (MyTalentStrengths[client] == INVALID_HANDLE) MyTalentStrengths[client]				= CreateArray(16);
	if (MyTalentStrength[client] == INVALID_HANDLE) MyTalentStrength[client]					= CreateArray(16);
	if (AbilityKeys[client] == INVALID_HANDLE) AbilityKeys[client]							= CreateArray(16);
	if (PurchaseKeys[client] == INVALID_HANDLE) PurchaseKeys[client]						= CreateArray(16);
	if (PurchaseValues[client] == INVALID_HANDLE) PurchaseValues[client]						= CreateArray(16);
	if (a_Database_PlayerTalents[client] == INVALID_HANDLE) a_Database_PlayerTalents[client]				= CreateArray(16);
	if (a_Database_PlayerTalents_Experience[client] == INVALID_HANDLE) a_Database_PlayerTalents_Experience[client] = CreateArray(16);
	if (PlayerAbilitiesCooldown[client] == INVALID_HANDLE) PlayerAbilitiesCooldown[client]				= CreateArray(8);
	if (PlayerActiveAbilitiesCooldown[client] == INVALID_HANDLE) PlayerActiveAbilitiesCooldown[client] = CreateArray(8);
	if (acdrValues[client] == INVALID_HANDLE) acdrValues[client] = CreateArray(16);
	if (GetLayerStrengthValues[client] == INVALID_HANDLE) GetLayerStrengthValues[client] = CreateArray(16);
	if (a_Store_Player[client] == INVALID_HANDLE) a_Store_Player[client]						= CreateArray(16);
	if (StoreKeys[client] == INVALID_HANDLE) StoreKeys[client]							= CreateArray(16);
	if (StoreValues[client] == INVALID_HANDLE) StoreValues[client]							= CreateArray(16);
	if (StoreMultiplierKeys[client] == INVALID_HANDLE) StoreMultiplierKeys[client]					= CreateArray(16);
	if (StoreMultiplierValues[client] == INVALID_HANDLE) StoreMultiplierValues[client]				= CreateArray(16);
	if (StoreTimeKeys[client] == INVALID_HANDLE) StoreTimeKeys[client]						= CreateArray(16);
	if (StoreTimeValues[client] == INVALID_HANDLE) StoreTimeValues[client]						= CreateArray(16);
	if (TrailsKeys[client] == INVALID_HANDLE) TrailsKeys[client]							= CreateArray(16);
	if (TrailsValues[client] == INVALID_HANDLE) TrailsValues[client]							= CreateArray(16);
	if (DamageValues[client] == INVALID_HANDLE) DamageValues[client]					= CreateArray(16);
	if (DamageSection[client] == INVALID_HANDLE) DamageSection[client]				= CreateArray(16);
	if (MOTValues[client] == INVALID_HANDLE) MOTValues[client] = CreateArray(16);
	if (BoosterKeys[client] == INVALID_HANDLE) BoosterKeys[client]							= CreateArray(16);
	if (BoosterValues[client] == INVALID_HANDLE) BoosterValues[client]						= CreateArray(16);
	if (RPGMenuPosition[client] == INVALID_HANDLE) RPGMenuPosition[client]						= CreateArray(16);
	if (h_KilledPosition_X[client] == INVALID_HANDLE) h_KilledPosition_X[client]				= CreateArray(16);
	if (h_KilledPosition_Y[client] == INVALID_HANDLE) h_KilledPosition_Y[client]				= CreateArray(16);
	if (h_KilledPosition_Z[client] == INVALID_HANDLE) h_KilledPosition_Z[client]				= CreateArray(16);
	if (RCAffixes[client] == INVALID_HANDLE) RCAffixes[client] = CreateArray(16);
	if (SurvivorsIgnored[client] == INVALID_HANDLE) SurvivorsIgnored[client] = CreateArray(16);
	if (MyGroup[client] == INVALID_HANDLE) MyGroup[client] = CreateArray(16);
	if (PlayerEffectOverTime[client] == INVALID_HANDLE) PlayerEffectOverTime[client] = CreateArray(8);
	if (CooldownEffectTriggerValues[client] == INVALID_HANDLE) CooldownEffectTriggerValues[client] = CreateArray(16);
	if (IsSpellAnAuraValues[client] == INVALID_HANDLE) IsSpellAnAuraValues[client] = CreateArray(16);
	if (CallAbilityCooldownTriggerValues[client] == INVALID_HANDLE) CallAbilityCooldownTriggerValues[client] = CreateArray(16);
	if (GetIfTriggerRequirementsMetValues[client] == INVALID_HANDLE) GetIfTriggerRequirementsMetValues[client] = CreateArray(16);
	if (GAMValues[client] == INVALID_HANDLE) GAMValues[client] = CreateArray(16);
	if (GetGoverningAttributeValues[client] == INVALID_HANDLE) GetGoverningAttributeValues[client] = CreateArray(16);
	if (WeaponResultValues[client] == INVALID_HANDLE) WeaponResultValues[client] = CreateArray(4);
	if (WeaponResultSection[client] == INVALID_HANDLE) WeaponResultSection[client] = CreateArray(16);
	if (GetTalentValueSearchValues[client] == INVALID_HANDLE) GetTalentValueSearchValues[client] = CreateArray(16);
	if (GetTalentStrengthSearchValues[client] == INVALID_HANDLE) GetTalentStrengthSearchValues[client] = CreateArray(16);
	if (GetTalentKeyValueValues[client] == INVALID_HANDLE) GetTalentKeyValueValues[client] = CreateArray(16);
	if (ApplyDebuffCooldowns[client] == INVALID_HANDLE) ApplyDebuffCooldowns[client] = CreateArray(8);
	if (playerContributionTracker[client] == INVALID_HANDLE) {
		playerContributionTracker[client] = CreateArray(6);
		ResizeArray(playerContributionTracker[client], 4);
	}

	if (myLootDropCategoriesAllowed[client] == INVALID_HANDLE) myLootDropCategoriesAllowed[client] = CreateArray(16);
	if (LootDropCategoryToBuffValues[client] == INVALID_HANDLE) LootDropCategoryToBuffValues[client] = CreateArray(16);
	if (myAugmentIDCodes[client] == INVALID_HANDLE) myAugmentIDCodes[client] = CreateArray(16);
	if (myAugmentSavedProfiles[client] == INVALID_HANDLE) myAugmentSavedProfiles[client] = CreateArray(16);
	if (myAugmentCategories[client] == INVALID_HANDLE) myAugmentCategories[client] = CreateArray(16);
	if (myAugmentOwners[client] == INVALID_HANDLE) myAugmentOwners[client] = CreateArray(16);
	if (myAugmentOwnersName[client] == INVALID_HANDLE) myAugmentOwnersName[client] = CreateArray(16);
	if (myAugmentInfo[client] == INVALID_HANDLE) myAugmentInfo[client] = CreateArray(16);
	if (equippedAugments[client] == INVALID_HANDLE) equippedAugments[client] = CreateArray(16);
	if (equippedAugmentsCategory[client] == INVALID_HANDLE) equippedAugmentsCategory[client] = CreateArray(16);
	if (GetAugmentTranslationKeys[client] == INVALID_HANDLE) GetAugmentTranslationKeys[client] = CreateArray(16);
	if (GetAugmentTranslationVals[client] == INVALID_HANDLE) GetAugmentTranslationVals[client] = CreateArray(16);
	if (myLootDropTargetEffectsAllowed[client] == INVALID_HANDLE) myLootDropTargetEffectsAllowed[client] = CreateArray(16);
	if (myLootDropActivatorEffectsAllowed[client] == INVALID_HANDLE) myLootDropActivatorEffectsAllowed[client] = CreateArray(16);
	if (equippedAugmentsActivator[client] == INVALID_HANDLE) equippedAugmentsActivator[client] = CreateArray(16);
	if (equippedAugmentsTarget[client] == INVALID_HANDLE) equippedAugmentsTarget[client] = CreateArray(16);
	if (myAugmentActivatorEffects[client] == INVALID_HANDLE) myAugmentActivatorEffects[client] = CreateArray(16);
	if (myAugmentTargetEffects[client] == INVALID_HANDLE) myAugmentTargetEffects[client] = CreateArray(16);
	if (equippedAugmentsIDCodes[client] == INVALID_HANDLE) equippedAugmentsIDCodes[client] = CreateArray(16);
	if (lootRollData[client] == INVALID_HANDLE) lootRollData[client] = CreateArray(16);
	if (playerLootOnGround[client] == INVALID_HANDLE) playerLootOnGround[client] = CreateArray(32);
	if (playerLootOnGroundId[client] == INVALID_HANDLE) playerLootOnGroundId[client] = CreateArray(32);
	if (possibleLootPoolTarget[client] == INVALID_HANDLE) possibleLootPoolTarget[client] = CreateArray(16);
	if (possibleLootPoolActivator[client] == INVALID_HANDLE) possibleLootPoolActivator[client] = CreateArray(16);
	if (unlockedLootPoolTarget[client] == INVALID_HANDLE) unlockedLootPoolTarget[client] = CreateArray(16);
	if (unlockedLootPoolActivator[client] == INVALID_HANDLE) unlockedLootPoolActivator[client] = CreateArray(16);
	if (HandicapValues[client] == INVALID_HANDLE) HandicapValues[client] = CreateArray(8);
	if (HandicapSelectedValues[client] == INVALID_HANDLE) HandicapSelectedValues[client] = CreateArray(6);
	if (SetHandicapValues[client] == INVALID_HANDLE) SetHandicapValues[client] = CreateArray(8);
	if (AbilityTriggerValues[client] == INVALID_HANDLE) AbilityTriggerValues[client] = CreateArray(16);
	if (TalentPositionsWithEffectName[client] == INVALID_HANDLE) TalentPositionsWithEffectName[client] = CreateArray(16);
	if (PlayerBuffVals[client] == INVALID_HANDLE) PlayerBuffVals[client] = CreateArray(16);
	if (GetStrengthFloat[client] == INVALID_HANDLE) GetStrengthFloat[client] = CreateArray(16);
	if (myUnlockedCategories[client] == INVALID_HANDLE) myUnlockedCategories[client] = CreateArray(16);
	if (myUnlockedActivators[client] == INVALID_HANDLE) myUnlockedActivators[client] = CreateArray(16);
	if (myUnlockedTargets[client] == INVALID_HANDLE) myUnlockedTargets[client] = CreateArray(16);
	if (EquipAugmentPanel[client] == INVALID_HANDLE) EquipAugmentPanel[client] = CreateArray(16);
	if (OnDeathHandicapValues[client] == INVALID_HANDLE) OnDeathHandicapValues[client] = CreateArray(8);
	if (augmentInventoryPosition[client] == INVALID_HANDLE) augmentInventoryPosition[client] = CreateArray(4);

	int ASize = GetArraySize(a_Menu_Talents);
	ResizeArray(MyTalentStrength[client], ASize);
	ResizeArray(MyTalentStrengths[client], ASize);
	for (int i = 0; i < ASize; i++) {
		// preset all talents to being unclaimed.
		SetArrayCell(MyTalentStrengths[client], i, 0.0);
		SetArrayCell(MyTalentStrengths[client], i, 0.0, 1);
		SetArrayCell(MyTalentStrengths[client], i, 0.0, 2);
		SetArrayCell(MyTalentStrength[client], i, 0);
	}
}