#define NICK_MODEL				"models/survivors/survivor_gambler.mdl"
#define ROCHELLE_MODEL			"models/survivors/survivor_producer.mdl"
#define COACH_MODEL				"models/survivors/survivor_coach.mdl"
#define ELLIS_MODEL				"models/survivors/survivor_mechanic.mdl"
#define ZOEY_MODEL				"models/survivors/survivor_teenangst.mdl"
#define FRANCIS_MODEL			"models/survivors/survivor_biker.mdl"
#define LOUIS_MODEL				"models/survivors/survivor_manager.mdl"
#define BILL_MODEL				"models/survivors/survivor_namvet.mdl"
#define TEAM_SPECTATOR		1
#define TEAM_SURVIVOR		2
#define TEAM_INFECTED		3
#define MAX_ENTITIES		2048
#define MAX_CHAT_LENGTH		1024
#define COOPRECORD_DB				"db_season_coop"
#define SURVRECORD_DB				"db_season_surv"

#define PLUGIN_VERSION				"v3.4.5.3c"
#define PROFILE_VERSION				"v1.5"
#define PLUGIN_CONTACT				"github.com/exskye/"

#define PLUGIN_NAME					"RPG Construction Set"
#define PLUGIN_DESCRIPTION			"Fully-customizable and modular RPG, like the one for Atari."
#define CONFIG_EVENTS				"rpg/events.cfg"
#define CONFIG_MAINMENU				"rpg/mainmenu.cfg"
#define CONFIG_MENUTALENTS			"rpg/talentmenu.cfg"
#define CONFIG_POINTS				"rpg/points.cfg"
#define CONFIG_MAPRECORDS			"rpg/maprecords.cfg"
#define CONFIG_STORE				"rpg/store.cfg"
#define CONFIG_TRAILS				"rpg/trails.cfg"
#define CONFIG_PETS					"rpg/pets.cfg"
#define CONFIG_WEAPONS				"rpg/weapondamages.cfg"
#define CONFIG_COMMONAFFIXES		"rpg/commonaffixes.cfg"
#define CONFIG_CLASSNAMES			"rpg/classnames.cfg"
#define LOGFILE						"rum_rpg.txt"
#define JETPACK_AUDIO				"ambient/gas/steam2.wav"

#define MODIFIER_HEALING			0
#define MODIFIER_TANKING			1
#define MODIFIER_DAMAGE				2	// not really used...
//	================================
#define DEBUG     					false
//	================================

/*
 Version 3.4.5.3c
 - Added additional guard statements and checks to ensure that all players and infected are hooked; unhooked players/infected cannot deal/receive damage.
 - Players who are hit by or suffering from bomber explosions [Ex] debuff will be now placed in combat.
 - Refactored the RollLoot method and associated functions.

 Version 3.4.5.3b
 - Fixed a logic error in OnCommonInfectedCreated which didn't initialize common infected into players data pools on spawn
		causing common infected to not take environmental damage until either damaging a survivor or being damaged by a survivor.
 - Bomber explosion debuff will now affect common infected caught in the blast for both the super common death and when players explode.

 Version 3.4.5.3
 - Fixed a bug in Timer_DeleteLootBag in rpg_wrappers.sp that could occasionally cause a server crash.
 - Common infected will no longer be deleted in OnCommonInfectedCreated (also in rpg_wrappers.sp) during inactive rounds, as this could also occasionally cause a server crash.
 - Fixed a bug that could cause a crash when generating new loot for a player.

 Version 3.4.5.2
 - Added the option to specify how many roll attempts are made per player on kills. Note on common kills only the player who killed it gets the rolls.
	"roll attempts on common kill?"
	"roll attempts on supers kill?"
	"roll attempts on specials kill?"
	"roll attempts on witch kill?"
	"roll attempts on tank kill?"

	- These all default to 1, so specify in the config.cfg what the values should be.
	- Added a check when picking up bags to see if it's the same player looting multiple bags in succession. If it is, it'll only display the "x is searching a bag..." notice once every 3 seconds.
	- Refactored the GetBulletOrMeleeHealAmount(healer, target, damage, damagetype, bool isMelee) function in events.sp

 Version 3.4.5.1 Rebalance/redesign
 - Added 6 new ability triggers for new talents designed to stop magetanking (super strong with no drawbacks in all 3 areas) without limiting player agency:
	lessDamageMoreHeals
	lessDamageMoreTanky
	lessTankyMoreHeals
	lessTankyMoreDamage
	lessHealsMoreDamage
	lessHealsMoreTanky
 - Players with no augments equipped (or new players) will now have the proper levels of 0 applied to empty augment slots.
 - Fixed talent active time incorrectly being set to 0.0s for any applicable talent; talents in the menu should now also show the correct value for this.
 - Added wider potential force and potential physics impact ranges to loot bags on spawn.
 - MoreHeals does not apply to self-health regen
 - Fixed CLERIC visual effect not showing
	
	these talents ignore "activator ability effects?" and "target ability effects?" and "activator / target required?" fields should be set to -1 or omitted.
 Version 3.4.4.9a hotfix
 - Fixed an issue where talents reducing incoming damage would reduce the efficacy of talents based on incoming damage, such as thorns.
 - Added rating multiplier for augment levels to balance augments.
 - Fixed a bug where common infected receiving fatal damage would not die from that attack if it was from a bullet.
 - When a client leaves the game, their augment/inventory data is now properly cleared.

 Version 3.4.4.9
 - Fixed visual bugs on talent info screen for abilities with consecutive hit multipliers that were showing -100% instead of the correct value previously.
 - physics objects that can be interacted with can now be generated for loot, to give players a sense of loot being 'physical' objects.
   If loot bags are disabled and the loot system is enabled, loot will be auto-rolled in text chat and given to players automatically if the infected drops anything.
 	- Added new variables associated with this feature:
		"generate interactable loot bags?"						"1"
		"loot bags disappear after this many seconds?"			"10"
		"item drop model?"										"models/props_collectables/backpack.mdl"
 - FINALLY added support for pipe bombs & other explosives dealing variable damage against common infected.
	- values can be increased by talents triggered by "S"
 - Proficiency levels now affect your damage! By default, it's 1% per proficiency level.

 Version 3.4.4.8b
 - Misc bug fixes, performance optimizations.

 Version 3.4.4.8a
 - Second attempt to fix the lag issue.
 - Second attempt to fix certain super commons having a bunch of health.
 - Laying the groundwork for a new augment feature.
 - Added support for end of map loot rolls similar to the end of map rolls in the RPG that Patriot-Games used, this time for augments instead of SLATE/CARTEL.
 - Fixed some entity oob errors resulting from refactoring.
 - Fixed void return type for OnMapStart and OnMapEnd
 - Added a new native to ReadyUp 8.3 so RPG can let ReadyUp know when the round is failed/restarted by a vote of some sorts, either artificial or real.
	- native added: ReadyUp_RoundRestartedByVote();
 - Corrected bug causing end of map loot rolls to not reward to players who were under the augment roll required score.
		  Now, all living players will receive a guaranteed ( by default in my server settings, no idea for other server operators)
		  loot roll, even if they don't meet the requirements to roll augments under normal circumstances.
 + TO DO: Make commons take damage from pipebombs
 + TO DO: Make biled special/common infected be able to take damage from other infected - right now infected have no FF of any kind but this is because
		  It has been a low-priority fix.

 Version 3.4.4.7
 - Redesigned how augments are rolled to be friendlier to player time investment/reward and to bring minor augments in line with major/perfect and major in line with perfect.
   Augments from the augment beta test have been destroyed for all players - I'll be adding a variable to the database to give out free rolls soon, to reward the beta testers.
 - First attempt to fix the massive lag that is caused when a survivor swaps to spectator and back.

 Version 3.4.4.6
 - Added support for anti-camping, so that players too close to "last kill" spots won't earn experience.
   This can be used to enforce varying kinds of 'forward progression'

 Version 3.4.4.5
 - Removed datapack timer while I figure out some stuff.
 - scenario_end should now properly call when the variables are met.

 Version 3.4.4.4
 - Added SetClientTalentStrength(client) to call when an augment is equipped or unequipped.
 + To do: Add a comparator/confirmation screen when selecting an augment slot currently occupied by another augment.
 + Add support for survivor bots to use augments.
*/

#define CVAR_SHOW					FCVAR_NOTIFY
#define DMG_HEADSHOT				2147483648
#define ZOMBIECLASS_SMOKER											1
#define ZOMBIECLASS_BOOMER											2
#define ZOMBIECLASS_HUNTER											3
#define ZOMBIECLASS_SPITTER											4
#define ZOMBIECLASS_JOCKEY											5
#define ZOMBIECLASS_CHARGER											6
#define ZOMBIECLASS_WITCH											7
#define ZOMBIECLASS_TANK											8
#define ZOMBIECLASS_SURVIVOR										0
#define TANKSTATE_TIRED												0
#define TANKSTATE_REFLECT											1
#define TANKSTATE_FIRE												2
#define TANKSTATE_DEATH												3
#define TANKSTATE_TELEPORT											4
#define TANKSTATE_HULK												5
#define EFFECTOVERTIME_ACTIVATETALENT	0
#define EFFECTOVERTIME_GETACTIVETIME	1
#define EFFECTOVERTIME_GETCOOLDOWN		2
#define DMG_SPITTERACID1 263168
#define DMG_SPITTERACID2 265216
#define CONTRIBUTION_TRACKER_HEALING	0
#define CONTRIBUTION_TRACKER_DAMAGE		1
#define CONTRIBUTION_TRACKER_TANKING	2
#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <smlib>
#include <left4dhooks>
#include "l4d_stocks.inc"
#undef REQUIRE_PLUGIN
#include <readyup>
#define REQUIRE_PLUGIN
public Plugin myinfo = {
	name = PLUGIN_NAME,
	author = PLUGIN_CONTACT,
	description = PLUGIN_DESCRIPTION,
	version = PLUGIN_VERSION,
	url = "",
};

// from n^3 to n^2
// weapondamages.cfg
#define WEAPONINFO_DAMAGE					0
#define WEAPONINFO_OFFSET					1
#define WEAPONINFO_AMMO						2
#define WEAPONINFO_RANGE					3
#define WEAPONINFO_RANGE_REQUIRED			4

// for the talentmenu.cfg
#define ABILITY_TYPE						0
#define COMPOUNDING_TALENT					1
#define COMPOUND_WITH						2
#define ACTIVATOR_ABILITY_EFFECTS			3
#define TARGET_ABILITY_EFFECTS				4
#define SECONDARY_EFFECTS					5
#define WEAPONS_PERMITTED					6
#define HEALTH_PERCENTAGE_REQ				7
#define COHERENCY_RANGE						8
#define COHERENCY_MAX						9
#define COHERENCY_REQ						10
#define HEALTH_PERCENTAGE_REQ_TAR_REMAINING	11
#define HEALTH_PERCENTAGE_REQ_TAR_MISSING	12
#define ACTIVATOR_TEAM_REQ					13
#define ACTIVATOR_CLASS_REQ					14
#define REQUIRES_ZOOM						15
#define COMBAT_STATE_REQ					16
#define PLAYER_STATE_REQ					17
#define PASSIVE_ABILITY						18
#define REQUIRES_HEADSHOT					19
#define REQUIRES_LIMBSHOT					20
#define REQUIRES_CROUCHING					21
#define ACTIVATOR_STAGGER_REQ				22
#define TARGET_STAGGER_REQ					23
#define CANNOT_TARGET_SELF					24
#define MUST_BE_JUMPING_OR_FLYING			25
#define VOMIT_STATE_REQ_ACTIVATOR			26
#define VOMIT_STATE_REQ_TARGET				27
#define REQ_ADRENALINE_EFFECT				28
#define DISABLE_IF_WEAKNESS					29
#define REQ_WEAKNESS						30
#define TARGET_CLASS_REQ					31
#define CLEANSE_TRIGGER						32
#define REQ_CONSECUTIVE_HITS				33
#define BACKGROUND_TALENT					34
#define STATUS_EFFECT_MULTIPLIER			35
#define MULTIPLY_RANGE						36
#define MULTIPLY_COMMONS					37
#define MULTIPLY_SUPERS						38
#define MULTIPLY_WITCHES					39
#define MULTIPLY_SURVIVORS					40
#define MULTIPLY_SPECIALS					41
#define STRENGTH_INCREASE_ZOOMED			42
#define STRENGTH_INCREASE_TIME_CAP			43
#define STRENGTH_INCREASE_TIME_REQ			44
#define ZOOM_TIME_HAS_MINIMUM_REQ			45
#define HOLDING_FIRE_STRENGTH_INCREASE		46
#define DAMAGE_TIME_HAS_MINIMUM_REQ			47
#define HEALTH_PERCENTAGE_REQ_MISSING		48
#define HEALTH_PERCENTAGE_REQ_MISSING_MAX	49
#define IS_OWN_TALENT						50
#define SECONDARY_ABILITY_TRIGGER			51
#define TARGET_IS_SELF						52
#define PRIMARY_AOE							53
#define SECONDARY_AOE						54
#define GET_TALENT_NAME						55
#define GET_TRANSLATION						56
#define GOVERNING_ATTRIBUTE					57
#define TALENT_TREE_CATEGORY				58
#define PART_OF_MENU_NAMED					59
#define GET_TALENT_LAYER					60
#define IS_TALENT_ABILITY					61
#define ACTION_BAR_NAME						62
#define NUM_TALENTS_REQ						63
#define TALENT_UPGRADE_STRENGTH_VALUE		64
#define TALENT_UPGRADE_SCALE				65
#define TALENT_COOLDOWN_STRENGTH_VALUE		66
#define TALENT_COOLDOWN_SCALE				67
#define TALENT_ACTIVE_STRENGTH_VALUE		68
#define TALENT_ACTIVE_SCALE					69
#define COOLDOWN_GOVERNOR_OF_TALENT			70
#define TALENT_STRENGTH_HARD_LIMIT			71
#define TALENT_IS_EFFECT_OVER_TIME			72
#define SPECIAL_AMMO_TALENT_STRENGTH		73
#define LAYER_COUNTING_IS_IGNORED			74
#define IS_ATTRIBUTE						75
#define HIDE_TRANSLATION					76
#define TALENT_ROLL_CHANCE					77
// spells
#define SPELL_INTERVAL_PER_POINT			78
#define SPELL_INTERVAL_FIRST_POINT			79
#define SPELL_RANGE_PER_POINT				80
#define SPELL_RANGE_FIRST_POINT				81
#define SPELL_STAMINA_PER_POINT				82
#define SPELL_BASE_STAMINA_REQ				83
#define SPELL_COOLDOWN_PER_POINT			84
#define SPELL_COOLDOWN_FIRST_POINT			85
#define SPELL_COOLDOWN_START				86
#define SPELL_ACTIVE_TIME_PER_POINT			87
#define SPELL_ACTIVE_TIME_FIRST_POINT		88
#define SPELL_AMMO_EFFECT					89
#define SPELL_EFFECT_MULTIPLIER				90
// abilities
#define ABILITY_ACTIVE_EFFECT				91
#define ABILITY_PASSIVE_EFFECT				92
#define ABILITY_COOLDOWN_EFFECT				93
#define ABILITY_IS_REACTIVE					94
#define ABILITY_TEAMS_ALLOWED				95
#define ABILITY_COOLDOWN_STRENGTH			96
#define ABILITY_MAXIMUM_PASSIVE_MULTIPLIER	97
#define ABILITY_MAXIMUM_ACTIVE_MULTIPLIER	98
#define ABILITY_ACTIVE_STATE_ENSNARE_REQ	99
#define ABILITY_ACTIVE_STRENGTH				100
#define ABILITY_PASSIVE_IGNORES_COOLDOWN	101
#define ABILITY_PASSIVE_STATE_ENSNARE_REQ	102
#define ABILITY_PASSIVE_STRENGTH			103
#define ABILITY_PASSIVE_ONLY				104
#define ABILITY_IS_SINGLE_TARGET			105
#define ABILITY_DRAW_DELAY					106
#define ABILITY_ACTIVE_DRAW_DELAY			107
#define ABILITY_PASSIVE_DRAW_DELAY			108
#define ATTRIBUTE_MULTIPLIER				109
#define ATTRIBUTE_USE_THESE_MULTIPLIERS		110
#define ATTRIBUTE_BASE_MULTIPLIER			111
#define ATTRIBUTE_DIMINISHING_MULTIPLIER	112
#define ATTRIBUTE_DIMINISHING_RETURNS		113
#define HUD_TEXT_BUFF_EFFECT_OVER_TIME		114
#define IS_SUB_MENU_OF_TALENTCONFIG			115
#define IS_TALENT_TYPE						116
#define ITEM_ITEM_ID						117
#define ITEM_RARITY							118
#define OLD_ATTRIBUTE_EXPERIENCE_START		119
#define OLD_ATTRIBUTE_EXPERIENCE_MULTIPLIER	120
#define IS_AURA_INSTEAD						121
#define EFFECT_COOLDOWN_TRIGGER				122
#define EFFECT_INACTIVE_TRIGGER				123
#define ABILITY_REACTIVE_TYPE				124
#define ABILITY_ACTIVE_TIME					125
#define ABILITY_REQ_NO_ENSNARE				126
#define ABILITY_SKY_LEVEL_REQ				127
#define ABILITY_TOGGLE_EFFECT				128
#define SPELL_HUMANOID_ONLY					129
#define SPELL_INANIMATE_ONLY				130
#define SPELL_ALLOW_COMMONS					131
#define SPELL_ALLOW_SPECIALS				132
#define SPELL_ALLOW_SURVIVORS				133
#define ABILITY_COOLDOWN					134
#define EFFECT_ACTIVATE_PER_TICK			135
#define EFFECT_SECONDARY_EPT_ONLY			136
#define ABILITY_ACTIVE_END_ABILITY_TRIGGER	137
#define ABILITY_COOLDOWN_END_TRIGGER		138
#define ABILITY_DOES_DAMAGE					139
#define TALENT_IS_SPELL						140
#define TALENT_MINIMUM_LEVEL_REQ			141
#define ABILITY_TOGGLE_STRENGTH				142
#define TARGET_AND_LAST_TARGET_CLASS_MATCH	143
#define TARGET_RANGE_REQUIRED				144
#define TARGET_RANGE_REQUIRED_OUTSIDE		145
#define TARGET_MUST_BE_LAST_TARGET			146
#define ACTIVATOR_MUST_BE_ON_FIRE			147
#define ACTIVATOR_MUST_SUFFER_ACID_BURN		148
#define ACTIVATOR_MUST_BE_EXPLODING			149
#define ACTIVATOR_MUST_BE_SLOW				150
#define ACTIVATOR_MUST_BE_FROZEN			151
#define ACTIVATOR_MUST_BE_SCORCHED			152
#define ACTIVATOR_MUST_BE_STEAMING			153
#define ACTIVATOR_MUST_BE_DROWNING			154
#define ACTIVATOR_MUST_HAVE_HIGH_GROUND		155
#define TARGET_MUST_HAVE_HIGH_GROUND		156
#define ACTIVATOR_TARGET_MUST_EVEN_GROUND	157
#define TARGET_MUST_BE_IN_THE_AIR			158
#define ABILITY_EVENT_TYPE					159
#define LAST_KILL_MUST_BE_HEADSHOT			160
#define MULT_STR_CONSECUTIVE_HITS			161
#define MULT_STR_CONSECUTIVE_MAX			162
#define MULT_STR_CONSECUTIVE_DIV			163
#define CONTRIBUTION_TYPE_CATEGORY			164
#define CONTRIBUTION_COST					165
#define ITEM_NAME_TO_GIVE_PLAYER			166
#define HIDE_TALENT_STRENGTH_DISPLAY		167
#define TALENT_CALL_ABILITY_TRIGGER			168
#define TALENT_WEAPON_SLOT_REQUIRED			169
#define REQ_CONSECUTIVE_HEADSHOTS			170
#define MULT_STR_CONSECUTIVE_HEADSHOTS		171
#define MULT_STR_CONSECUTIVE_HEADSHOTS_MAX	172
#define MULT_STR_CONSECUTIVE_HEADSHOTS_DIV	173
#define IF_EOT_ACTIVE_ALLOW_ALL_WEAPONS		174
#define IF_EOT_ACTIVE_ALLOW_ALL_HITGROUPS	175
#define IF_EOT_ACTIVE_ALLOW_ALL_ENEMIES		176
#define ACTIVATOR_STATUS_EFFECT_REQUIRED	177
// because this value changes when we increase the static list of key positions
// we should create a reference for the IsAbilityFound method, so that it doesn't waste time checking keys that we know aren't equal.
#define TALENT_FIRST_RANDOM_KEY_POSITION	178
#define SUPER_COMMON_MAX_ALLOWED			0
#define SUPER_COMMON_AURA_EFFECT			1
#define SUPER_COMMON_RANGE_MIN				2
#define SUPER_COMMON_RANGE_PLAYER_LEVEL		3
#define SUPER_COMMON_RANGE_MAX				4
#define SUPER_COMMON_COOLDOWN				5
#define SUPER_COMMON_AURA_STRENGTH			6
#define SUPER_COMMON_STRENGTH_TARGET		7
#define SUPER_COMMON_LEVEL_STRENGTH			8
#define SUPER_COMMON_SPAWN_CHANCE			9
#define SUPER_COMMON_DRAW_TYPE				10
#define SUPER_COMMON_FIRE_IMMUNITY			11
#define SUPER_COMMON_MODEL_SIZE				12
#define SUPER_COMMON_GLOW					13
#define SUPER_COMMON_GLOW_RANGE				14
#define SUPER_COMMON_GLOW_COLOUR			15
#define SUPER_COMMON_BASE_HEALTH			16
#define SUPER_COMMON_HEALTH_PER_LEVEL		17
#define SUPER_COMMON_NAME					18
#define SUPER_COMMON_CHAIN_REACTION			19
#define SUPER_COMMON_DEATH_EFFECT			20
#define SUPER_COMMON_DEATH_BASE_TIME		21
#define SUPER_COMMON_DEATH_MAX_TIME			22
#define SUPER_COMMON_DEATH_INTERVAL			23
#define SUPER_COMMON_DEATH_MULTIPLIER		24
#define SUPER_COMMON_LEVEL_REQ				25
#define SUPER_COMMON_FORCE_MODEL			26
#define SUPER_COMMON_DAMAGE_EFFECT			27
#define SUPER_COMMON_ENEMY_MULTIPLICATION	28
#define SUPER_COMMON_ONFIRE_BASE_TIME		29
#define SUPER_COMMON_ONFIRE_LEVEL			30
#define SUPER_COMMON_ONFIRE_MAX_TIME		31
#define SUPER_COMMON_ONFIRE_INTERVAL		32
#define SUPER_COMMON_STRENGTH_SPECIAL		33
#define SUPER_COMMON_RAW_STRENGTH			34
#define SUPER_COMMON_RAW_COMMON_STRENGTH	35
#define SUPER_COMMON_RAW_PLAYER_STRENGTH	36
#define SUPER_COMMON_REQ_BILED_SURVIVORS	37
#define SUPER_COMMON_FIRST_RANDOM_KEY_POS	38

// for the events.cfg
#define EVENT_PERPETRATOR					0
#define EVENT_VICTIM						1
#define EVENT_SAMETEAM_TRIGGER				2
#define EVENT_PERPETRATOR_TEAM_REQ			3
#define EVENT_PERPETRATOR_ABILITY_TRIGGER	4
#define EVENT_VICTIM_TEAM_REQ				5
#define EVENT_VICTIM_ABILITY_TRIGGER		6
#define EVENT_DAMAGE_TYPE					7
#define EVENT_GET_HEALTH					8
#define EVENT_DAMAGE_AWARD					9
#define EVENT_GET_ABILITIES					10
#define EVENT_IS_PLAYER_NOW_IT				11
#define EVENT_IS_ORIGIN						12
#define EVENT_IS_DISTANCE					13
#define EVENT_MULTIPLIER_POINTS				14
#define EVENT_MULTIPLIER_EXPERIENCE			15
#define EVENT_IS_SHOVED						16
#define EVENT_IS_BULLET_IMPACT				17
#define EVENT_ENTERED_SAFEROOM				18

int iClientTypeToDisplayOnKill;
char MyCurrentWeapon[MAXPLAYERS + 1][64];
int takeDamageEvent[MAXPLAYERS + 1][2];
Handle possibleLootPool[MAXPLAYERS + 1];
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
Handle GetCategoryStrengthKeys[MAXPLAYERS + 1];
Handle GetCategoryStrengthValues[MAXPLAYERS + 1];
Handle GetCategoryStrengthSection[MAXPLAYERS + 1];
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
int iIsRatingEnabled;
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
Handle RoundStatistics;
bool bRushingNotified[MAXPLAYERS + 1];
bool bHasTeleported[MAXPLAYERS + 1];
bool IsAirborne[MAXPLAYERS + 1];
Handle RandomSurvivorClient;
int eBackpack[MAXPLAYERS + 1];
bool b_IsFinaleTanks;
char RatingType[64];
bool bJumpTime[MAXPLAYERS + 1];
float JumpTime[MAXPLAYERS + 1];
Handle AbilityConfigKeys[MAXPLAYERS + 1];
Handle AbilityConfigValues[MAXPLAYERS + 1];
Handle AbilityConfigSection[MAXPLAYERS + 1];
bool IsGroupMember[MAXPLAYERS + 1];
int IsGroupMemberTime[MAXPLAYERS + 1];
Handle GetAbilityKeys[MAXPLAYERS + 1];
Handle GetAbilityValues[MAXPLAYERS + 1];
Handle GetAbilitySection[MAXPLAYERS + 1];
Handle IsAbilityKeys[MAXPLAYERS + 1];
Handle IsAbilityValues[MAXPLAYERS + 1];
Handle IsAbilitySection[MAXPLAYERS + 1];
Handle CheckAbilityKeys[MAXPLAYERS + 1];
Handle CheckAbilityValues[MAXPLAYERS + 1];
Handle CheckAbilitySection[MAXPLAYERS + 1];
int StrugglePower[MAXPLAYERS + 1];
Handle GetTalentStrengthKeys[MAXPLAYERS + 1];
Handle GetTalentStrengthValues[MAXPLAYERS + 1];
Handle CastKeys[MAXPLAYERS + 1];
Handle CastValues[MAXPLAYERS + 1];
Handle CastSection[MAXPLAYERS + 1];
int ActionBarSlot[MAXPLAYERS + 1];
Handle ActionBar[MAXPLAYERS + 1];
bool DisplayActionBar[MAXPLAYERS + 1];
int ConsecutiveHits[MAXPLAYERS + 1];
int MyVomitChase[MAXPLAYERS + 1];
float JetpackRecoveryTime[MAXPLAYERS + 1];
bool b_IsHooked[MAXPLAYERS + 1];
int IsPvP[MAXPLAYERS + 1];
bool bJetpack[MAXPLAYERS + 1];
//new ServerLevelRequirement;
Handle TalentsAssignedKeys[MAXPLAYERS + 1];
Handle TalentsAssignedValues[MAXPLAYERS + 1];
Handle CartelValueKeys[MAXPLAYERS + 1];
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
bool bHasWeakness[MAXPLAYERS + 1];
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
Handle SpecialAmmoEffectKeys[MAXPLAYERS + 1];
Handle SpecialAmmoEffectValues[MAXPLAYERS + 1];
Handle ActiveAmmoCooldownKeys[MAXPLAYERS +1];
Handle ActiveAmmoCooldownValues[MAXPLAYERS + 1];
Handle PlayActiveAbilities[MAXPLAYERS + 1];
Handle PlayerActiveAmmo[MAXPLAYERS + 1];
Handle SpecialAmmoKeys[MAXPLAYERS + 1];
Handle SpecialAmmoValues[MAXPLAYERS + 1];
Handle SpecialAmmoSection[MAXPLAYERS + 1];
Handle DrawSpecialAmmoKeys[MAXPLAYERS + 1];
Handle DrawSpecialAmmoValues[MAXPLAYERS + 1];
Handle SpecialAmmoStrengthKeys[MAXPLAYERS + 1];
Handle SpecialAmmoStrengthValues[MAXPLAYERS + 1];
Handle WeaponLevel[MAXPLAYERS + 1];
Handle ExperienceBank[MAXPLAYERS + 1];
Handle MenuPosition[MAXPLAYERS + 1];
Handle IsClientInRangeSAKeys[MAXPLAYERS + 1];
Handle IsClientInRangeSAValues[MAXPLAYERS + 1];
Handle SpecialAmmoData;
Handle SpecialAmmoSave;
float MovementSpeed[MAXPLAYERS + 1];
int IsPlayerDebugMode[MAXPLAYERS + 1];
char ActiveSpecialAmmo[MAXPLAYERS + 1][64];
float IsSpecialAmmoEnabled[MAXPLAYERS + 1][4];
bool bIsInCombat[MAXPLAYERS + 1];
float CombatTime[MAXPLAYERS + 1];
Handle AKKeys[MAXPLAYERS + 1];
Handle AKValues[MAXPLAYERS + 1];
Handle AKSection[MAXPLAYERS + 1];
bool bIsSurvivorFatigue[MAXPLAYERS + 1];
int SurvivorStamina[MAXPLAYERS + 1];
float SurvivorConsumptionTime[MAXPLAYERS + 1];
float SurvivorStaminaTime[MAXPLAYERS + 1];
Handle ISSLOW[MAXPLAYERS + 1];
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
Handle CommonList;
Handle CommonAffixes;// the array holding the common entity id and the affix associated with the common infected. If multiple affixes, multiple keyvalues for the entity id will be created instead of multiple entries.
Handle a_CommonAffixes;			// the array holding the config data
int UpgradesAwarded[MAXPLAYERS + 1];
int UpgradesAvailable[MAXPLAYERS + 1];
Handle InfectedAuraKeys[MAXPLAYERS + 1];
Handle InfectedAuraValues[MAXPLAYERS + 1];
Handle InfectedAuraSection[MAXPLAYERS + 1];
bool b_IsDead[MAXPLAYERS + 1];
int ExperienceDebt[MAXPLAYERS + 1];
Handle TalentUpgradeKeys[MAXPLAYERS + 1];
Handle TalentUpgradeValues[MAXPLAYERS + 1];
Handle TalentUpgradeSection[MAXPLAYERS + 1];
Handle InfectedHealth[MAXPLAYERS + 1];
Handle SpecialCommon[MAXPLAYERS + 1];
Handle WitchList;
Handle WitchDamage[MAXPLAYERS + 1];
Handle Give_Store_Keys;
Handle Give_Store_Values;
Handle Give_Store_Section;
bool bIsMeleeCooldown[MAXPLAYERS + 1];
//Handle a_Classnames;
Handle a_WeaponDamages;
Handle MeleeKeys[MAXPLAYERS + 1];
Handle MeleeValues[MAXPLAYERS + 1];
Handle MeleeSection[MAXPLAYERS + 1];
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
int RatingHandicap[MAXPLAYERS + 1];
bool bIsHandicapLocked[MAXPLAYERS + 1];
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
int SpecialsKilled;
Handle LockedTalentKeys;
Handle LockedTalentValues;
Handle LockedTalentSection;
Handle MOTKeys[MAXPLAYERS + 1];
Handle MOTValues[MAXPLAYERS + 1];
Handle MOTSection[MAXPLAYERS + 1];
Handle DamageKeys[MAXPLAYERS + 1];
Handle DamageValues[MAXPLAYERS + 1];
Handle DamageSection[MAXPLAYERS + 1];
Handle BoosterKeys[MAXPLAYERS + 1];
Handle BoosterValues[MAXPLAYERS + 1];
Handle StoreChanceKeys[MAXPLAYERS + 1];
Handle StoreChanceValues[MAXPLAYERS + 1];
Handle StoreItemNameSection[MAXPLAYERS + 1];
Handle StoreItemSection[MAXPLAYERS + 1];
char PathSetting[64];
Handle SaveSection[MAXPLAYERS + 1];
int OriginalHealth[MAXPLAYERS + 1];
bool b_IsLoadingStore[MAXPLAYERS + 1];
Handle LoadStoreSection[MAXPLAYERS + 1];
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
Handle MenuKeys[MAXPLAYERS + 1];
Handle MenuValues[MAXPLAYERS + 1];
Handle MenuSection[MAXPLAYERS + 1];
Handle TriggerKeys[MAXPLAYERS + 1];
Handle TriggerValues[MAXPLAYERS + 1];
Handle TriggerSection[MAXPLAYERS + 1];
Handle PreloadTalentValues[MAXPLAYERS + 1];
Handle PreloadTalentSection[MAXPLAYERS + 1];
Handle MyTalentStrengths[MAXPLAYERS + 1];
Handle MyTalentStrength[MAXPLAYERS + 1];
Handle AbilityKeys[MAXPLAYERS + 1];
Handle AbilityValues[MAXPLAYERS + 1];
Handle AbilitySection[MAXPLAYERS + 1];
Handle ChanceKeys[MAXPLAYERS + 1];
Handle ChanceValues[MAXPLAYERS + 1];
Handle ChanceSection[MAXPLAYERS + 1];
Handle PurchaseKeys[MAXPLAYERS + 1];
Handle PurchaseValues[MAXPLAYERS + 1];
Handle EventSection;
Handle HookSection;
Handle CallKeys;
Handle CallValues;
//new Handle:CallSection;
Handle DirectorKeys;
Handle DirectorValues;
//new Handle:DirectorSection;
Handle DatabaseKeys;
Handle DatabaseValues;
Handle DatabaseSection;
Handle a_Database_PlayerTalents_Bots;
Handle PlayerAbilitiesCooldown_Bots;
Handle PlayerAbilitiesImmune_Bots;
Handle BotSaveKeys;
Handle BotSaveValues;
Handle BotSaveSection;
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
//new Handle:PlayerAbilitiesImmune[MAXPLAYERS + 1][MAXPLAYERS + 1];
Handle PlayerInventory[MAXPLAYERS + 1];
Handle PlayerEquipped[MAXPLAYERS + 1];
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
//new String:CurrentTalentLoading_Bots[128];
//new Handle:a_Database_PlayerTalents_Bots;
//new Handle:PlayerAbilitiesCooldown_Bots;				// Because [designation] = ZombieclassID
int ExperienceLevel_Bots;
//new ExperienceOverall_Bots;
//new PlayerLevelUpgrades_Bots;
int PlayerLevel_Bots;
//new TotalTalentPoints_Bots;
float Points_Director;
Handle CommonInfectedQueue;
int g_oAbility = 0;
Handle g_hIsStaggering = INVALID_HANDLE;
Handle g_hSetClass = INVALID_HANDLE;
Handle g_hCreateAbility = INVALID_HANDLE;
Handle gd = INVALID_HANDLE;
//new Handle:DirectorPurchaseTimer = INVALID_HANDLE;
bool b_IsDirectorTalents[MAXPLAYERS + 1];
//new LoadPos_Bots;
int LoadPos[MAXPLAYERS + 1];
int LoadPos_Director;
ConVar g_Steamgroup;
ConVar g_svCheats;
ConVar g_Tags;
ConVar g_Gamemode;
int RoundTime;
int g_iSprite = 0;
int g_BeaconSprite = 0;
int iNoSpecials;
//new bool:b_FirstClientLoaded;
bool b_HasDeathLocation[MAXPLAYERS + 1];
bool b_IsMissionFailed;
Handle CCASection;
Handle CCAKeys;
Handle CCAValues;
int LastWeaponDamage[MAXPLAYERS + 1];
float UseItemTime[MAXPLAYERS + 1];
Handle NewUsersRound;
bool bIsSoloHandicap;
Handle MenuStructure[MAXPLAYERS + 1];
Handle TankState_Array[MAXPLAYERS + 1];
bool bIsGiveIncapHealth[MAXPLAYERS + 1];
Handle TheLeaderboards[MAXPLAYERS + 1];
Handle TheLeaderboardsData[MAXPLAYERS + 1];
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
Handle TalentTreeKeys[MAXPLAYERS + 1];
Handle TalentTreeValues[MAXPLAYERS + 1];
Handle TalentExperienceKeys[MAXPLAYERS + 1];
Handle TalentExperienceValues[MAXPLAYERS + 1];
Handle TalentActionKeys[MAXPLAYERS + 1];
Handle TalentActionValues[MAXPLAYERS + 1];
Handle TalentActionSection[MAXPLAYERS + 1];
bool bIsTalentTwo[MAXPLAYERS + 1];
Handle CommonDrawKeys;
Handle CommonDrawValues;
bool bAutoRevive[MAXPLAYERS + 1];
bool bIsClassAbilities[MAXPLAYERS + 1];
bool bIsDisconnecting[MAXPLAYERS + 1];
Handle LegitClassSection[MAXPLAYERS + 1];
int LoadProfileRequestName[MAXPLAYERS + 1];
//new String:LoadProfileRequest[MAXPLAYERS + 1];
char TheCurrentMap[64];
bool IsEnrageNotified;
//new bool:bIsNewClass[MAXPLAYERS + 1];
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
int iMaxDifficultyLevel;
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
int iExperienceStart;
float fExperienceMultiplier;
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
int iHandicapLevelDifference;
int iWitchHealthBase;
float fWitchHealthMult;
int RatingPerLevel;
int RatingPerAugmentLevel;
int RatingPerLevelSurvivorBots;
int iCommonBaseHealth;
float fCommonLevelHealthMult;
int iServerLevelRequirement;
int iRoundStartWeakness;
float GroupMemberBonus;
float FinSurvBon;
int RaidLevMult;
int iIgnoredRating;
int iIgnoredRatingMax;
int iInfectedLimit;
float SurvivorExperienceMult;
float SurvivorExperienceMultTank;
//new Float:SurvivorExperienceMultHeal;
float TheScorchMult;
float TheInfernoMult;
float fAmmoHighlightTime;
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
int RatingPerHandicap;
Handle ItemDropArray;
char sItemModel[512];
int iSurvivorGroupMinimum;
/*new Float:fDropChanceSpecial;
new Float:fDropChanceCommon;
new Float:fDropChanceWitch;
new Float:fDropChanceTank;
new Float:fDropChanceInfected;*/
Handle PreloadKeys;
Handle PreloadValues;
Handle ItemDropKeys;
Handle ItemDropValues;
Handle ItemDropSection;
Handle persistentCirculation;
int iRarityMax;
int iEnrageAdvertisement;
int iJoinGroupAdvertisement;
int iNotifyEnrage;
char sBackpackModel[64];
char ItemDropArraySize[64];
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
int OverHealth[MAXPLAYERS + 1];
bool bHealthIsSet[MAXPLAYERS + 1];
int iIsLevelingPaused[MAXPLAYERS + 1];
int iIsBulletTrails[MAXPLAYERS + 1];
Handle ActiveStatuses[MAXPLAYERS + 1];
int InfectedTalentLevel;
float fEnrageModifier;
float LastAttackTime[MAXPLAYERS + 1];
Handle hWeaponList[MAXPLAYERS + 1];
Handle GCVKeys[MAXPLAYERS + 1];
Handle GCVValues[MAXPLAYERS + 1];
Handle GCVSection[MAXPLAYERS + 1];
int MyStatusEffects[MAXPLAYERS + 1];
int iShowLockedTalents;
//new Handle:GCMKeys[MAXPLAYERS + 1];
//new Handle:GCMValues[MAXPLAYERS + 1];
Handle PassiveStrengthKeys[MAXPLAYERS + 1];
Handle PassiveStrengthValues[MAXPLAYERS + 1];
Handle PassiveTalentName[MAXPLAYERS + 1];
Handle UpgradeCategoryKeys[MAXPLAYERS + 1];
Handle UpgradeCategoryValues[MAXPLAYERS + 1];
Handle UpgradeCategoryName[MAXPLAYERS + 1];
int iChaseEnt[MAXPLAYERS + 1];
int iTeamRatingRequired;
float fTeamRatingBonus;
float fRatingPercentLostOnDeath;
int PlayerCurrentMenuLayer[MAXPLAYERS + 1];
int iMaxLayers;
Handle TranslationOTNKeys[MAXPLAYERS + 1];
Handle TranslationOTNValues[MAXPLAYERS + 1];
Handle TranslationOTNSection[MAXPLAYERS + 1];
Handle acdrKeys[MAXPLAYERS + 1];
Handle acdrValues[MAXPLAYERS + 1];
Handle acdrSection[MAXPLAYERS + 1];
Handle GetLayerStrengthKeys[MAXPLAYERS + 1];
Handle GetLayerStrengthValues[MAXPLAYERS + 1];
Handle GetLayerStrengthSection[MAXPLAYERS + 1];
int iCommonInfectedBaseDamage;
int playerPageOfCharacterSheet[MAXPLAYERS + 1];
int nodesInExistence;
int iShowTotalNodesOnTalentTree;
Handle PlayerEffectOverTime[MAXPLAYERS + 1];
Handle PlayerEffectOverTimeEffects[MAXPLAYERS + 1];
Handle CheckEffectOverTimeKeys[MAXPLAYERS + 1];
Handle CheckEffectOverTimeValues[MAXPLAYERS + 1];
float fSpecialAmmoInterval;
//float fEffectOverTimeInterval;
Handle FormatEffectOverTimeKeys[MAXPLAYERS + 1];
Handle FormatEffectOverTimeValues[MAXPLAYERS + 1];
Handle FormatEffectOverTimeSection[MAXPLAYERS + 1];
Handle CooldownEffectTriggerKeys[MAXPLAYERS + 1];
Handle CooldownEffectTriggerValues[MAXPLAYERS + 1];
Handle IsSpellAnAuraKeys[MAXPLAYERS + 1];
Handle IsSpellAnAuraValues[MAXPLAYERS + 1];
float fStaggerTickrate;
Handle StaggeredTargets;
Handle staggerBuffer;
bool staggerCooldownOnTriggers[MAXPLAYERS + 1];
Handle CallAbilityCooldownTriggerKeys[MAXPLAYERS + 1];
Handle CallAbilityCooldownTriggerValues[MAXPLAYERS + 1];
Handle CallAbilityCooldownTriggerSection[MAXPLAYERS + 1];
Handle GetIfTriggerRequirementsMetKeys[MAXPLAYERS + 1];
Handle GetIfTriggerRequirementsMetValues[MAXPLAYERS + 1];
Handle GetIfTriggerRequirementsMetSection[MAXPLAYERS + 1];
bool ShowPlayerLayerInformation[MAXPLAYERS + 1];
Handle GAMKeys[MAXPLAYERS + 1];
Handle GAMValues[MAXPLAYERS + 1];
Handle GAMSection[MAXPLAYERS + 1];
char RPGMenuCommand[64];
int RPGMenuCommandExplode;
//new PrestigeLevel[MAXPLAYERS + 1];
char DefaultProfileName[64];
char DefaultBotProfileName[64];
char DefaultInfectedProfileName[64];
Handle GetGoverningAttributeKeys[MAXPLAYERS + 1];
Handle GetGoverningAttributeValues[MAXPLAYERS + 1];
Handle GetGoverningAttributeSection[MAXPLAYERS + 1];
int iTanksAlwaysEnforceCooldown;
Handle WeaponResultKeys[MAXPLAYERS + 1];
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
Handle GetAbilityCooldownKeys[MAXPLAYERS + 1];
Handle GetAbilityCooldownValues[MAXPLAYERS + 1];
Handle GetAbilityCooldownSection[MAXPLAYERS + 1];
Handle GetTalentValueSearchKeys[MAXPLAYERS + 1];
Handle GetTalentValueSearchValues[MAXPLAYERS + 1];
Handle GetTalentValueSearchSection[MAXPLAYERS + 1];
Handle GetTalentStrengthSearchValues[MAXPLAYERS + 1];
Handle GetTalentStrengthSearchSection[MAXPLAYERS + 1];
int iSkyLevelNodeUnlocks;
Handle GetTalentKeyValueKeys[MAXPLAYERS + 1];
Handle GetTalentKeyValueValues[MAXPLAYERS + 1];
Handle GetTalentKeyValueSection[MAXPLAYERS + 1];
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
Handle TalentAtMenuPositionSection[MAXPLAYERS + 1];
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
float fStaminaPerSkyLevel;
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
int iExperienceLevelCap;
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
int iDontStoreInfectedInArray;
int iUniqueServerCode;
int lootDropCounter;
Handle myLootDropCategoriesAllowed[MAXPLAYERS + 1];
Handle myLootDropTargetEffectsAllowed[MAXPLAYERS + 1];
Handle myLootDropActivatorEffectsAllowed[MAXPLAYERS + 1];
Handle LootDropCategoryToBuffValues[MAXPLAYERS + 1];
Handle myAugmentIDCodes[MAXPLAYERS + 1];
Handle myAugmentCategories[MAXPLAYERS + 1];
Handle myAugmentOwners[MAXPLAYERS + 1];
Handle myAugmentInfo[MAXPLAYERS + 1];
int iAugmentLevelDivisor;
float fAugmentRatingMultiplier;
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
int iNumOfEndMapLootRolls;
int iAllPlayersEndMapLootRolls;
float fEndMapLootRollsChance;
int iLootBagsAreGenerated;
float fLootBagExpirationTimeInSeconds;
Handle playerLootOnGround[MAXPLAYERS + 1];
int iExplosionBaseDamagePipe;
int iExplosionBaseDamage;
float fProficiencyLevelDamageIncrease;
int playerCurrentAugmentLevel[MAXPLAYERS + 1];
Handle possibleLootPoolTarget[MAXPLAYERS + 1];
Handle possibleLootPoolActivator[MAXPLAYERS + 1];
int iJetpackEnabled;
float fJumpTimeToActivateJetpack;
int iNumLootDropChancesPerPlayer[5];
int lastItemTime;
char lastPlayerGrab[64];

public Action CMD_DropWeapon(int client, int args) {
	int CurrentEntity			=	GetEntPropEnt(client, Prop_Data, "m_hActiveWeapon");
	if (!IsValidEntity(CurrentEntity) || CurrentEntity < 1) return Plugin_Handled;
	char EntityName[64];
	GetEdictClassname(CurrentEntity, EntityName, sizeof(EntityName));
	if (StrContains(EntityName, "melee", false) != -1) return Plugin_Handled;
	int Entity					=	CreateEntityByName(EntityName);
	DispatchSpawn(Entity);
	lastEntityDropped[client] = Entity;
	GetAbilityStrengthByTrigger(client, client, "dropitem", _, _, _, _, _, _, _, _, _, _, _, _, _, Entity);
	float Origin[3];
	GetClientAbsOrigin(client, Origin);
	Origin[2] += 64.0;
	TeleportEntity(Entity, Origin, NULL_VECTOR, NULL_VECTOR);
	SetEntityMoveType(Entity, MOVETYPE_VPHYSICS);
	if (GetWeaponSlot(Entity) < 2) SetEntProp(Entity, Prop_Send, "m_iClip1", GetEntProp(CurrentEntity, Prop_Send, "m_iClip1"));
	AcceptEntityInput(CurrentEntity, "Kill");
	return Plugin_Handled;
}

public Action CMD_IAmStuck(int client, int args) {
	if (L4D2_GetInfectedAttacker(client) == -1 && !AnyTanksNearby(client, 512.0)) {
		int target = FindAnyRandomClient(true, client);
		if (target > 0) {
			GetClientAbsOrigin(target, DeathLocation[client]);
			TeleportEntity(client, DeathLocation[client], NULL_VECTOR, NULL_VECTOR);
			SetEntityMoveType(client, MOVETYPE_WALK);
		}
	}
	return Plugin_Handled;
}

stock void DoGunStuff(int client) {
	int targetgun = GetPlayerWeaponSlot(client, 0); //get the players primary weapon
	if (!IsValidEdict(targetgun)) return; //check for validity
	int iAmmoOffset = FindDataMapInfo(client, "m_iAmmo"); //get the iAmmo Offset
	iAmmoOffset = GetEntData(client, (iAmmoOffset + GetWeaponResult(client, 1)));
	PrintToChat(client, "reserve remaining: %d | reserve cap: %d", iAmmoOffset, GetWeaponResult(client, 2));
	return;
}

stock void CMD_OpenRPGMenu(int client) {
	ClearArray(MenuStructure[client]);	// keeps track of the open menus.
	//VerifyAllActionBars(client);	// Because.
	if (LoadProfileRequestName[client] != -1) {
		if (!IsLegitimateClient(LoadProfileRequestName[client])) LoadProfileRequestName[client] = -1;
	}
	iIsWeaponLoadout[client] = 0;
	bEquipSpells[client] = false;
	PlayerCurrentMenuLayer[client] = 1;
	ShowPlayerLayerInformation[client] = false;
	if (iAllowPauseLeveling != 1 && iIsLevelingPaused[client] == 1) iIsLevelingPaused[client] = 0;
	BuildMenu(client, "main");
	/*new count = GetEntProp(client, Prop_Send, "m_iShovePenalty", 4);
	PrintToChat(client, "shove penalty: %d", count);
	if (count < 1) {
		SetEntProp(client, Prop_Send, "m_iShovePenalty", 10);
		SetEntPropFloat(client, Prop_Send, "m_flNextShoveTime", 900.0);
	}
	else {
		SetEntProp(client, Prop_Send, "m_iShovePenalty", 0);
		SetEntPropFloat(client, Prop_Send, "m_flNextShoveTime", 1.0);
	}*/
	//PrintToChat(client, "penalty soon: %d", count);
}

public void OnPluginStart() {
	OnMapStartFunc(); // The very first thing that must happen before anything else happens.
	CreateConVar("skyrpg_version", PLUGIN_VERSION, "version header", CVAR_SHOW);
	SetConVarString(FindConVar("skyrpg_version"), PLUGIN_VERSION);
	g_Steamgroup = FindConVar("sv_steamgroup");
	SetConVarFlags(g_Steamgroup, GetConVarFlags(g_Steamgroup) & ~FCVAR_NOTIFY);
	g_svCheats = FindConVar("sv_cheats");
	SetConVarFlags(g_svCheats, GetConVarFlags(g_svCheats) & ~FCVAR_NOTIFY);
	g_Tags = FindConVar("sv_tags");
	SetConVarFlags(g_Tags, GetConVarFlags(g_Tags) & ~FCVAR_NOTIFY);
	g_Gamemode = FindConVar("mp_gamemode");
	LoadTranslations("skyrpg.phrases");
	BuildPath(Path_SM, ConfigPathDirectory, sizeof(ConfigPathDirectory), "configs/readyup/");
	if (!DirExists(ConfigPathDirectory)) CreateDirectory(ConfigPathDirectory, 777);
	BuildPath(Path_SM, LogPathDirectory, sizeof(LogPathDirectory), "logs/readyup/rpg/");
	if (!DirExists(LogPathDirectory)) CreateDirectory(LogPathDirectory, 777);
	BuildPath(Path_SM, LogPathDirectory, sizeof(LogPathDirectory), "logs/readyup/rpg/%s", LOGFILE);
	//if (!FileExists(LogPathDirectory)) SetFailState("[SKYRPG LOGGING] please create file at %s", LogPathDirectory);
	RegAdminCmd("debugrpg", Cmd_debugrpg, ADMFLAG_KICK);
	RegAdminCmd("resettpl", Cmd_ResetTPL, ADMFLAG_KICK);
	RegAdminCmd("origin", Cmd_GetOrigin, ADMFLAG_KICK);
	RegAdminCmd("deleteprofiles", CMD_DeleteProfiles, ADMFLAG_ROOT);
	// These are mandatory because of quick commands, so I hardcode the entries.
	RegConsoleCmd("rollloot", CMD_RollLoot);
	RegConsoleCmd("loaddata", CMD_LoadData);
	RegConsoleCmd("price", CMD_SetAugmentPrice);
	RegConsoleCmd("say", CMD_ChatCommand);
	RegConsoleCmd("say_team", CMD_TeamChatCommand);
	RegConsoleCmd("callvote", CMD_BlockVotes);
	RegConsoleCmd("votemap", CMD_BlockIfReadyUpIsActive);
	RegConsoleCmd("vote", CMD_BlockVotes);
	//RegConsoleCmd("talentupgrade", CMD_TalentUpgrade);
	RegConsoleCmd("loadoutname", CMD_LoadoutName);
	RegConsoleCmd("stuck", CMD_IAmStuck);
	RegConsoleCmd("ff", CMD_TogglePvP);
	//RegConsoleCmd("revive", CMD_RespawnYumYum);
	//RegConsoleCmd("abar", CMD_ActionBar);
	RegConsoleCmd("handicap", CMD_Handicap);
	RegAdminCmd("firesword", CMD_FireSword, ADMFLAG_KICK);
	RegAdminCmd("fbegin", CMD_FBEGIN, ADMFLAG_KICK);
	RegAdminCmd("witches", CMD_WITCHESCOUNT, ADMFLAG_KICK);
	//RegAdminCmd("staggertest", CMD_STAGGERTEST, ADMFLAG_KICK);
	Format(white, sizeof(white), "\x01");
	Format(orange, sizeof(orange), "\x04");
	Format(green, sizeof(green), "\x05");
	Format(blue, sizeof(blue), "\x03");
	HookUserMessage(GetUserMessageId("SayText2"), TextMsg, true);
	gd = LoadGameConfigFile("rum_rpg");
	if (gd != INVALID_HANDLE) {
		StartPrepSDKCall(SDKCall_Player);
		PrepSDKCall_SetFromConf(gd, SDKConf_Signature, "SetClass");
		PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
		g_hSetClass = EndPrepSDKCall();
		StartPrepSDKCall(SDKCall_Static);
		PrepSDKCall_SetFromConf(gd, SDKConf_Signature, "CreateAbility");
		PrepSDKCall_AddParameter(SDKType_CBasePlayer, SDKPass_Pointer);
		PrepSDKCall_SetReturnInfo(SDKType_CBaseEntity, SDKPass_Pointer);
		g_hCreateAbility = EndPrepSDKCall();
		g_oAbility = GameConfGetOffset(gd, "oAbility");
		StartPrepSDKCall(SDKCall_Entity);
		PrepSDKCall_SetFromConf(gd, SDKConf_Signature, "CSpitterProjectile_Detonate");
		g_hCreateAcid = EndPrepSDKCall();
		StartPrepSDKCall(SDKCall_Player);
		PrepSDKCall_SetFromConf(gd, SDKConf_Signature, "CTerrorPlayer_OnAdrenalineUsed");
		PrepSDKCall_AddParameter(SDKType_Float, SDKPass_Plain);
		g_hEffectAdrenaline = EndPrepSDKCall();
		StartPrepSDKCall(SDKCall_Player);
		PrepSDKCall_SetFromConf(gd, SDKConf_Signature, "CTerrorPlayer_OnVomitedUpon");
		PrepSDKCall_AddParameter(SDKType_CBasePlayer, SDKPass_Pointer);
		PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
		g_hCallVomitOnPlayer = EndPrepSDKCall();
		StartPrepSDKCall(SDKCall_Player);
		PrepSDKCall_SetFromConf(gd, SDKConf_Signature, "RoundRespawn");
		hRoundRespawn = EndPrepSDKCall();
		StartPrepSDKCall(SDKCall_Player);
		PrepSDKCall_SetFromConf(gd, SDKConf_Signature, "IsStaggering");
		PrepSDKCall_SetReturnInfo(SDKType_PlainOldData, SDKPass_Plain);
		g_hIsStaggering = EndPrepSDKCall();
	}
	else {
		SetFailState("Error: Unable to load Gamedata rum_rpg.txt");
	}
	staggerBuffer = CreateConVar("sm_vscript_res", "", "returns results from vscript check on stagger");
}

public Action CMD_LoadData(int client, int args) {

	ClearAndLoad(client, true);
	return Plugin_Handled;
}

public Action CMD_WITCHESCOUNT(int client, int args) {
	PrintToChat(client, "Witches: %d", GetArraySize(WitchList));
	return Plugin_Handled;
}

public Action CMD_FBEGIN(int client, int args) {
	ReadyUpEnd_Complete();
	return Plugin_Handled;
}

public Action Cmd_GetOrigin(int client, int args) {
	float OriginP[3];
	char sMelee[64];
	GetMeleeWeapon(client, sMelee, sizeof(sMelee));
	GetClientAbsOrigin(client, OriginP);
	PrintToChat(client, "[0] %3.3f [1] %3.3f [2] %3.3f\n%s", OriginP[0], OriginP[1], OriginP[2], sMelee);
	return Plugin_Handled;
}

public Action CMD_DeleteProfiles(int client, int args) {
	if (DeleteAllProfiles(client)) PrintToChat(client, "all saved profiles are deleted.");
	return Plugin_Handled;
}
public Action CMD_BlockVotes(int client, int args) {
	return Plugin_Handled;
}

public Action CMD_BlockIfReadyUpIsActive(int client, int args) {
	if (!b_IsRoundIsOver) return Plugin_Continue;
	return Plugin_Handled;
}

public int ReadyUp_SetSurvivorMinimum(int minSurvs) {
	iMinSurvivors = minSurvs;
}

public void ReadyUp_GetMaxSurvivorCount(int count) {
	if (count <= 1) bIsSoloHandicap = true;
	else bIsSoloHandicap = false;
}

stock void UnhookAll() {
	for (int i = 1; i <= MaxClients; i++) {
		if (IsLegitimateClient(i)) {
			SDKUnhook(i, SDKHook_OnTakeDamage, OnTakeDamage);
			SDKUnhook(i, SDKHook_TraceAttack, OnTraceAttack);
			SDKUnhook(i, SDKHook_WeaponSwitch, OnWeaponSwitch);
			b_IsHooked[i] = false;
		}
	}
}

public int ReadyUp_TrueDisconnect(int client) {
	if (bIsInCombat[client]) IncapacitateOrKill(client, _, _, true, true, true);
	bTimersRunning[client] = false;
	//ChangeHook(client);
	staggerCooldownOnTriggers[client] = false;
	ISBILED[client] = false;
	DisplayActionBar[client] = false;
	IsPvP[client] = 0;
	b_IsFloating[client] = false;
	b_IsLoading[client] = false;
	b_HardcoreMode[client] = false;
	//WipeDebuffs(_, client, true);
	if (b_IsLoaded[client]) SavePlayerData(client, true);
	IsPlayerDebugMode[client] = 0;
	CleanseStack[client] = 0;
	CounterStack[client] = 0.0;
	MultiplierStack[client] = 0;
	LoadTarget[client] = -1;
	ImmuneToAllDamage[client] = false;
	b_IsLoaded[client] = false;		// only set to false if a REAL player leaves - this way bots don't repeatedly load their data.
	// Format(ProfileLoadQueue[client], sizeof(ProfileLoadQueue[]), "none");
	// Format(BuildingStack[client], sizeof(BuildingStack[]), "none");
	// Format(LoadoutName[client], sizeof(LoadoutName[]), "none");
	//CreateTimer(1.0, Timer_RemoveSaveSafety, client, TIMER_FLAG_NO_MAPCHANGE);
	bIsSettingsCheck = true;
	// if (b_IsActiveRound && ScenarioEndConditionsMet()) {	// If the disconnecting player was the last living human survivor, if the round is live, we end the round.
	// 	b_IsMissionFailed = true;
	// 	ForceServerCommand("scenario_end");
	// 	CallRoundIsOver();
	// }
}

//stock LoadConfigValues() {
//}

// public OnAllPluginsLoaded() {
// 	//OnMapStartFunc();
// 	CheckDifficulty();
// }

stock CreateAllArrays() {
	if (b_FirstLoad) return;
	LogMessage("=====\t\tRunning first-time load of RPG.\t\t=====");
	if (holdingFireList == INVALID_HANDLE) holdingFireList = CreateArray(32);
	if (zoomCheckList == INVALID_HANDLE) zoomCheckList = CreateArray(32);
	if (hThreatSort == INVALID_HANDLE) hThreatSort = CreateArray(32);
	if (hThreatMeter == INVALID_HANDLE) hThreatMeter = CreateArray(32);
	if (LoggedUsers == INVALID_HANDLE) LoggedUsers = CreateArray(32);
	if (SuperCommonQueue == INVALID_HANDLE) SuperCommonQueue = CreateArray(32);
	if (CommonInfectedQueue == INVALID_HANDLE) CommonInfectedQueue = CreateArray(32);
	if (CoveredInVomit == INVALID_HANDLE) CoveredInVomit = CreateArray(32);
	if (NewUsersRound == INVALID_HANDLE) NewUsersRound = CreateArray(32);
	if (SpecialAmmoData == INVALID_HANDLE) SpecialAmmoData = CreateArray(32);
	if (SpecialAmmoSave == INVALID_HANDLE) SpecialAmmoSave = CreateArray(32);
	if (MainKeys == INVALID_HANDLE) MainKeys = CreateArray(32);
	if (MainValues == INVALID_HANDLE) MainValues = CreateArray(32);
	if (a_Menu_Talents == INVALID_HANDLE) a_Menu_Talents = CreateArray(3);
	if (a_Menu_Main == INVALID_HANDLE) a_Menu_Main = CreateArray(3);
	if (a_Events == INVALID_HANDLE) a_Events = CreateArray(3);
	if (a_Points == INVALID_HANDLE) a_Points = CreateArray(3);
	if (a_Pets == INVALID_HANDLE) a_Pets = CreateArray(3);
	if (a_Store == INVALID_HANDLE) a_Store = CreateArray(3);
	if (a_Trails == INVALID_HANDLE) a_Trails = CreateArray(3);
	if (a_Database_Talents == INVALID_HANDLE) a_Database_Talents = CreateArray(32);
	if (a_Database_Talents_Defaults == INVALID_HANDLE) a_Database_Talents_Defaults 	= CreateArray(32);
	if (a_Database_Talents_Defaults_Name == INVALID_HANDLE) a_Database_Talents_Defaults_Name				= CreateArray(32);
	if (EventSection == INVALID_HANDLE) EventSection									= CreateArray(32);
	if (HookSection == INVALID_HANDLE) HookSection										= CreateArray(32);
	if (CallKeys == INVALID_HANDLE) CallKeys										= CreateArray(32);
	if (CallValues == INVALID_HANDLE) CallValues										= CreateArray(32);
	if (DirectorKeys == INVALID_HANDLE) DirectorKeys									= CreateArray(32);
	if (DirectorValues == INVALID_HANDLE) DirectorValues									= CreateArray(32);
	if (DatabaseKeys == INVALID_HANDLE) DatabaseKeys									= CreateArray(32);
	if (DatabaseValues == INVALID_HANDLE) DatabaseValues									= CreateArray(32);
	if (DatabaseSection == INVALID_HANDLE) DatabaseSection									= CreateArray(32);
	if (a_Database_PlayerTalents_Bots == INVALID_HANDLE) a_Database_PlayerTalents_Bots					= CreateArray(32);
	if (PlayerAbilitiesCooldown_Bots == INVALID_HANDLE) PlayerAbilitiesCooldown_Bots					= CreateArray(32);
	if (PlayerAbilitiesImmune_Bots == INVALID_HANDLE) PlayerAbilitiesImmune_Bots						= CreateArray(32);
	if (BotSaveKeys == INVALID_HANDLE) BotSaveKeys										= CreateArray(32);
	if (BotSaveValues == INVALID_HANDLE) BotSaveValues									= CreateArray(32);
	if (BotSaveSection == INVALID_HANDLE) BotSaveSection									= CreateArray(32);
	if (LoadDirectorSection == INVALID_HANDLE) LoadDirectorSection								= CreateArray(32);
	if (QueryDirectorKeys == INVALID_HANDLE) QueryDirectorKeys								= CreateArray(32);
	if (QueryDirectorValues == INVALID_HANDLE) QueryDirectorValues								= CreateArray(32);
	if (QueryDirectorSection == INVALID_HANDLE) QueryDirectorSection							= CreateArray(32);
	if (FirstDirectorKeys == INVALID_HANDLE) FirstDirectorKeys								= CreateArray(32);
	if (FirstDirectorValues == INVALID_HANDLE) FirstDirectorValues								= CreateArray(32);
	if (FirstDirectorSection == INVALID_HANDLE) FirstDirectorSection							= CreateArray(32);
	if (PlayerAbilitiesName == INVALID_HANDLE) PlayerAbilitiesName								= CreateArray(32);
	if (a_DirectorActions == INVALID_HANDLE) a_DirectorActions								= CreateArray(3);
	if (a_DirectorActions_Cooldown == INVALID_HANDLE) a_DirectorActions_Cooldown						= CreateArray(32);
	if (LockedTalentKeys == INVALID_HANDLE) LockedTalentKeys							= CreateArray(32);
	if (LockedTalentValues == INVALID_HANDLE) LockedTalentValues						= CreateArray(32);
	if (LockedTalentSection == INVALID_HANDLE) LockedTalentSection						= CreateArray(32);
	if (Give_Store_Keys == INVALID_HANDLE) Give_Store_Keys							= CreateArray(32);
	if (Give_Store_Values == INVALID_HANDLE) Give_Store_Values							= CreateArray(32);
	if (Give_Store_Section == INVALID_HANDLE) Give_Store_Section							= CreateArray(32);
	if (a_WeaponDamages == INVALID_HANDLE) a_WeaponDamages = CreateArray(32);
	if (a_CommonAffixes == INVALID_HANDLE) a_CommonAffixes = CreateArray(32);
	if (CommonList == INVALID_HANDLE) CommonList = CreateArray(32);
	if (WitchList == INVALID_HANDLE) WitchList				= CreateArray(32);
	if (CommonAffixes == INVALID_HANDLE) CommonAffixes	= CreateArray(32);
	if (h_CAKeys == INVALID_HANDLE) h_CAKeys = CreateArray(32);
	if (h_CAValues == INVALID_HANDLE) h_CAValues = CreateArray(32);
	if (SearchKey_Section == INVALID_HANDLE) SearchKey_Section = CreateArray(32);
	if (CCASection == INVALID_HANDLE) CCASection = CreateArray(32);
	if (CCAKeys == INVALID_HANDLE) CCAKeys = CreateArray(32);
	if (CCAValues == INVALID_HANDLE) CCAValues = CreateArray(32);
	if (h_CommonKeys == INVALID_HANDLE) h_CommonKeys = CreateArray(32);
	if (h_CommonValues == INVALID_HANDLE) h_CommonValues = CreateArray(32);
	//if (CommonInfected == INVALID_HANDLE) CommonInfected = CreateArray(32);
	if (EntityOnFire == INVALID_HANDLE) EntityOnFire = CreateArray(32);
	if (EntityOnFireName == INVALID_HANDLE) EntityOnFireName = CreateArray(32);
	if (CommonDrawKeys == INVALID_HANDLE) CommonDrawKeys = CreateArray(32);
	if (CommonDrawValues == INVALID_HANDLE) CommonDrawValues = CreateArray(32);
	if (ItemDropArray == INVALID_HANDLE) ItemDropArray = CreateArray(32);
	if (PreloadKeys == INVALID_HANDLE) PreloadKeys = CreateArray(32);
	if (PreloadValues == INVALID_HANDLE) PreloadValues = CreateArray(32);
	if (ItemDropKeys == INVALID_HANDLE) ItemDropKeys = CreateArray(32);
	if (ItemDropValues == INVALID_HANDLE) ItemDropValues = CreateArray(32);
	if (ItemDropSection == INVALID_HANDLE) ItemDropSection = CreateArray(32);
	if (persistentCirculation == INVALID_HANDLE) persistentCirculation = CreateArray(32);
	if (RandomSurvivorClient == INVALID_HANDLE) RandomSurvivorClient = CreateArray(32);
	if (RoundStatistics == INVALID_HANDLE) RoundStatistics = CreateArray(16);
	if (EffectOverTime == INVALID_HANDLE) EffectOverTime = CreateArray(32);
	if (TimeOfEffectOverTime == INVALID_HANDLE) TimeOfEffectOverTime = CreateArray(32);
	if (StaggeredTargets == INVALID_HANDLE) StaggeredTargets = CreateArray(32);
	if (SetNodesKeys == INVALID_HANDLE) SetNodesKeys = CreateArray(32);
	if (SetNodesValues == INVALID_HANDLE) SetNodesValues = CreateArray(32);
	if (playerCustomEntitiesCreated == INVALID_HANDLE) playerCustomEntitiesCreated = CreateArray(32);
	for (int i = 1; i <= MAXPLAYERS; i++) {
		itemToDisassemble[i] = -1;
		augmentParts[i] = 0;
		LastDeathTime[i] = 0.0;
		MyVomitChase[i] = -1;
		b_IsFloating[i] = false;
		DisplayActionBar[i] = false;
		ActionBarSlot[i] = -1;
		if (CommonInfected[i] == INVALID_HANDLE) CommonInfected[i] = CreateArray(8);
		if (possibleLootPool[i] == INVALID_HANDLE) possibleLootPool[i] = CreateArray(32);
		if (currentEquippedWeapon[i] == INVALID_HANDLE) currentEquippedWeapon[i] = CreateTrie();
		if (GetCategoryStrengthKeys[i] == INVALID_HANDLE) GetCategoryStrengthKeys[i] = CreateArray(32);
		if (GetCategoryStrengthValues[i] == INVALID_HANDLE) GetCategoryStrengthValues[i] = CreateArray(32);
		if (GetCategoryStrengthSection[i] == INVALID_HANDLE) GetCategoryStrengthSection[i] = CreateArray(32);
		//if (GCMKeys[i] == INVALID_HANDLE) GCMKeys[i] = CreateArray(32);
		//if (GCMValues[i] == INVALID_HANDLE) GCMValues[i] = CreateArray(32);
		if (PassiveStrengthKeys[i] == INVALID_HANDLE) PassiveStrengthKeys[i] = CreateArray(32);
		if (PassiveStrengthValues[i] == INVALID_HANDLE) PassiveStrengthValues[i] = CreateArray(32);
		if (PassiveTalentName[i] == INVALID_HANDLE) PassiveTalentName[i] = CreateArray(32);
		if (UpgradeCategoryKeys[i] == INVALID_HANDLE) UpgradeCategoryKeys[i] = CreateArray(32);
		if (UpgradeCategoryValues[i] == INVALID_HANDLE) UpgradeCategoryValues[i] = CreateArray(32);
		if (UpgradeCategoryName[i] == INVALID_HANDLE) UpgradeCategoryName[i] = CreateArray(32);
		if (TranslationOTNKeys[i] == INVALID_HANDLE) TranslationOTNKeys[i] = CreateArray(32);
		if (TranslationOTNValues[i] == INVALID_HANDLE) TranslationOTNValues[i] = CreateArray(32);
		if (TranslationOTNSection[i] == INVALID_HANDLE) TranslationOTNSection[i] = CreateArray(32);
		if (GCVKeys[i] == INVALID_HANDLE) GCVKeys[i] = CreateArray(32);
		if (GCVValues[i] == INVALID_HANDLE) GCVValues[i] = CreateArray(32);
		if (GCVSection[i] == INVALID_HANDLE) GCVSection[i] = CreateArray(32);
		if (hWeaponList[i] == INVALID_HANDLE) hWeaponList[i] = CreateArray(32);
		if (LoadoutConfigKeys[i] == INVALID_HANDLE) LoadoutConfigKeys[i] = CreateArray(32);
		if (LoadoutConfigValues[i] == INVALID_HANDLE) LoadoutConfigValues[i] = CreateArray(32);
		if (LoadoutConfigSection[i] == INVALID_HANDLE) LoadoutConfigSection[i] = CreateArray(32);
		if (ActiveStatuses[i] == INVALID_HANDLE) ActiveStatuses[i] = CreateArray(32);
		if (AbilityConfigKeys[i] == INVALID_HANDLE) AbilityConfigKeys[i] = CreateArray(32);
		if (AbilityConfigValues[i] == INVALID_HANDLE) AbilityConfigValues[i] = CreateArray(32);
		if (AbilityConfigSection[i] == INVALID_HANDLE) AbilityConfigSection[i] = CreateArray(32);
		if (GetAbilityKeys[i] == INVALID_HANDLE) GetAbilityKeys[i] = CreateArray(32);
		if (GetAbilityValues[i] == INVALID_HANDLE) GetAbilityValues[i] = CreateArray(32);
		if (GetAbilitySection[i] == INVALID_HANDLE) GetAbilitySection[i] = CreateArray(32);
		if (IsAbilityKeys[i] == INVALID_HANDLE) IsAbilityKeys[i] = CreateArray(32);
		if (IsAbilityValues[i] == INVALID_HANDLE) IsAbilityValues[i] = CreateArray(32);
		if (IsAbilitySection[i] == INVALID_HANDLE) IsAbilitySection[i] = CreateArray(32);
		if (CheckAbilityKeys[i] == INVALID_HANDLE) CheckAbilityKeys[i] = CreateArray(32);
		if (CheckAbilityValues[i] == INVALID_HANDLE) CheckAbilityValues[i] = CreateArray(32);
		if (CheckAbilitySection[i] == INVALID_HANDLE) CheckAbilitySection[i] = CreateArray(32);
		if (GetTalentStrengthKeys[i] == INVALID_HANDLE) GetTalentStrengthKeys[i] = CreateArray(32);
		if (GetTalentStrengthValues[i] == INVALID_HANDLE) GetTalentStrengthValues[i] = CreateArray(32);
		if (CastKeys[i] == INVALID_HANDLE) CastKeys[i] = CreateArray(32);
		if (CastValues[i] == INVALID_HANDLE) CastValues[i] = CreateArray(32);
		if (CastSection[i] == INVALID_HANDLE) CastSection[i] = CreateArray(32);
		if (ActionBar[i] == INVALID_HANDLE) ActionBar[i] = CreateArray(32);
		if (TalentsAssignedKeys[i] == INVALID_HANDLE) TalentsAssignedKeys[i] = CreateArray(32);
		if (TalentsAssignedValues[i] == INVALID_HANDLE) TalentsAssignedValues[i] = CreateArray(32);
		if (CartelValueKeys[i] == INVALID_HANDLE) CartelValueKeys[i] = CreateArray(32);
		if (CartelValueValues[i] == INVALID_HANDLE) CartelValueValues[i] = CreateArray(32);
		if (LegitClassSection[i] == INVALID_HANDLE) LegitClassSection[i] = CreateArray(32);
		if (TalentActionKeys[i] == INVALID_HANDLE) TalentActionKeys[i] = CreateArray(32);
		if (TalentActionValues[i] == INVALID_HANDLE) TalentActionValues[i] = CreateArray(32);
		if (TalentActionSection[i] == INVALID_HANDLE) TalentActionSection[i] = CreateArray(32);
		if (TalentExperienceKeys[i] == INVALID_HANDLE) TalentExperienceKeys[i] = CreateArray(32);
		if (TalentExperienceValues[i] == INVALID_HANDLE) TalentExperienceValues[i] = CreateArray(32);
		if (TalentTreeKeys[i] == INVALID_HANDLE) TalentTreeKeys[i] = CreateArray(32);
		if (TalentTreeValues[i] == INVALID_HANDLE) TalentTreeValues[i] = CreateArray(32);
		if (TheLeaderboards[i] == INVALID_HANDLE) TheLeaderboards[i] = CreateArray(32);
		if (TheLeaderboardsData[i] == INVALID_HANDLE) TheLeaderboardsData[i] = CreateArray(32);
		if (TankState_Array[i] == INVALID_HANDLE) TankState_Array[i] = CreateArray(32);
		if (PlayerInventory[i] == INVALID_HANDLE) PlayerInventory[i] = CreateArray(32);
		if (PlayerEquipped[i] == INVALID_HANDLE) PlayerEquipped[i] = CreateArray(32);
		if (MenuStructure[i] == INVALID_HANDLE) MenuStructure[i] = CreateArray(32);
		if (TempAttributes[i] == INVALID_HANDLE) TempAttributes[i] = CreateArray(32);
		if (TempTalents[i] == INVALID_HANDLE) TempTalents[i] = CreateArray(32);
		if (PlayerProfiles[i] == INVALID_HANDLE) PlayerProfiles[i] = CreateArray(32);
		if (SpecialAmmoEffectKeys[i] == INVALID_HANDLE) SpecialAmmoEffectKeys[i] = CreateArray(32);
		if (SpecialAmmoEffectValues[i] == INVALID_HANDLE) SpecialAmmoEffectValues[i] = CreateArray(32);
		if (ActiveAmmoCooldownKeys[i] == INVALID_HANDLE) ActiveAmmoCooldownKeys[i] = CreateArray(32);
		if (ActiveAmmoCooldownValues[i] == INVALID_HANDLE) ActiveAmmoCooldownValues[i] = CreateArray(32);
		if (PlayActiveAbilities[i] == INVALID_HANDLE) PlayActiveAbilities[i] = CreateArray(32);
		if (PlayerActiveAmmo[i] == INVALID_HANDLE) PlayerActiveAmmo[i] = CreateArray(32);
		if (SpecialAmmoKeys[i] == INVALID_HANDLE) SpecialAmmoKeys[i] = CreateArray(32);
		if (SpecialAmmoValues[i] == INVALID_HANDLE) SpecialAmmoValues[i] = CreateArray(32);
		if (SpecialAmmoSection[i] == INVALID_HANDLE) SpecialAmmoSection[i] = CreateArray(32);
		if (DrawSpecialAmmoKeys[i] == INVALID_HANDLE) DrawSpecialAmmoKeys[i] = CreateArray(32);
		if (DrawSpecialAmmoValues[i] == INVALID_HANDLE) DrawSpecialAmmoValues[i] = CreateArray(32);
		if (SpecialAmmoStrengthKeys[i] == INVALID_HANDLE) SpecialAmmoStrengthKeys[i] = CreateArray(32);
		if (SpecialAmmoStrengthValues[i] == INVALID_HANDLE) SpecialAmmoStrengthValues[i] = CreateArray(32);
		if (WeaponLevel[i] == INVALID_HANDLE) WeaponLevel[i] = CreateArray(32);
		if (ExperienceBank[i] == INVALID_HANDLE) ExperienceBank[i] = CreateArray(32);
		if (MenuPosition[i] == INVALID_HANDLE) MenuPosition[i] = CreateArray(32);
		if (IsClientInRangeSAKeys[i] == INVALID_HANDLE) IsClientInRangeSAKeys[i] = CreateArray(32);
		if (IsClientInRangeSAValues[i] == INVALID_HANDLE) IsClientInRangeSAValues[i] = CreateArray(32);
		if (InfectedAuraKeys[i] == INVALID_HANDLE) InfectedAuraKeys[i] = CreateArray(32);
		if (InfectedAuraValues[i] == INVALID_HANDLE) InfectedAuraValues[i] = CreateArray(32);
		if (InfectedAuraSection[i] == INVALID_HANDLE) InfectedAuraSection[i] = CreateArray(32);
		if (TalentUpgradeKeys[i] == INVALID_HANDLE) TalentUpgradeKeys[i] = CreateArray(32);
		if (TalentUpgradeValues[i] == INVALID_HANDLE) TalentUpgradeValues[i] = CreateArray(32);
		if (TalentUpgradeSection[i] == INVALID_HANDLE) TalentUpgradeSection[i] = CreateArray(32);
		if (InfectedHealth[i] == INVALID_HANDLE) InfectedHealth[i] = CreateArray(32);
		if (WitchDamage[i] == INVALID_HANDLE) WitchDamage[i]	= CreateArray(32);
		if (SpecialCommon[i] == INVALID_HANDLE) SpecialCommon[i] = CreateArray(32);
		if (MenuKeys[i] == INVALID_HANDLE) MenuKeys[i]								= CreateArray(32);
		if (MenuValues[i] == INVALID_HANDLE) MenuValues[i]							= CreateArray(32);
		if (MenuSection[i] == INVALID_HANDLE) MenuSection[i]							= CreateArray(32);
		if (TriggerKeys[i] == INVALID_HANDLE) TriggerKeys[i]							= CreateArray(32);
		if (TriggerValues[i] == INVALID_HANDLE) TriggerValues[i]						= CreateArray(32);
		if (TriggerSection[i] == INVALID_HANDLE) TriggerSection[i]						= CreateArray(32);
		if (PreloadTalentValues[i] == INVALID_HANDLE) PreloadTalentValues[i]			= CreateArray(32);
		if (PreloadTalentSection[i] == INVALID_HANDLE) PreloadTalentSection[i]			= CreateArray(32);
		if (MyTalentStrengths[i] == INVALID_HANDLE) MyTalentStrengths[i]				= CreateArray(32);
		if (MyTalentStrength[i] == INVALID_HANDLE) MyTalentStrength[i]					= CreateArray(32);
		if (AbilityKeys[i] == INVALID_HANDLE) AbilityKeys[i]							= CreateArray(32);
		if (AbilityValues[i] == INVALID_HANDLE) AbilityValues[i]						= CreateArray(32);
		if (AbilitySection[i] == INVALID_HANDLE) AbilitySection[i]						= CreateArray(32);
		if (ChanceKeys[i] == INVALID_HANDLE) ChanceKeys[i]							= CreateArray(32);
		if (ChanceValues[i] == INVALID_HANDLE) ChanceValues[i]							= CreateArray(32);
		if (PurchaseKeys[i] == INVALID_HANDLE) PurchaseKeys[i]						= CreateArray(32);
		if (PurchaseValues[i] == INVALID_HANDLE) PurchaseValues[i]						= CreateArray(32);
		if (ChanceSection[i] == INVALID_HANDLE) ChanceSection[i]						= CreateArray(32);
		if (a_Database_PlayerTalents[i] == INVALID_HANDLE) a_Database_PlayerTalents[i]				= CreateArray(32);
		if (a_Database_PlayerTalents_Experience[i] == INVALID_HANDLE) a_Database_PlayerTalents_Experience[i] = CreateArray(32);
		if (PlayerAbilitiesCooldown[i] == INVALID_HANDLE) PlayerAbilitiesCooldown[i]				= CreateArray(32);
		if (acdrKeys[i] == INVALID_HANDLE) acdrKeys[i] = CreateArray(32);
		if (acdrValues[i] == INVALID_HANDLE) acdrValues[i] = CreateArray(32);
		if (acdrSection[i] == INVALID_HANDLE) acdrSection[i] = CreateArray(32);
		if (GetLayerStrengthKeys[i] == INVALID_HANDLE) GetLayerStrengthKeys[i] = CreateArray(32);
		if (GetLayerStrengthValues[i] == INVALID_HANDLE) GetLayerStrengthValues[i] = CreateArray(32);
		if (GetLayerStrengthSection[i] == INVALID_HANDLE) GetLayerStrengthSection[i] = CreateArray(32);
		if (a_Store_Player[i] == INVALID_HANDLE) a_Store_Player[i]						= CreateArray(32);
		if (StoreKeys[i] == INVALID_HANDLE) StoreKeys[i]							= CreateArray(32);
		if (StoreValues[i] == INVALID_HANDLE) StoreValues[i]							= CreateArray(32);
		if (StoreMultiplierKeys[i] == INVALID_HANDLE) StoreMultiplierKeys[i]					= CreateArray(32);
		if (StoreMultiplierValues[i] == INVALID_HANDLE) StoreMultiplierValues[i]				= CreateArray(32);
		if (StoreTimeKeys[i] == INVALID_HANDLE) StoreTimeKeys[i]						= CreateArray(32);
		if (StoreTimeValues[i] == INVALID_HANDLE) StoreTimeValues[i]						= CreateArray(32);
		if (LoadStoreSection[i] == INVALID_HANDLE) LoadStoreSection[i]						= CreateArray(32);
		if (SaveSection[i] == INVALID_HANDLE) SaveSection[i]							= CreateArray(32);
		if (StoreChanceKeys[i] == INVALID_HANDLE) StoreChanceKeys[i]						= CreateArray(32);
		if (StoreChanceValues[i] == INVALID_HANDLE) StoreChanceValues[i]					= CreateArray(32);
		if (StoreItemNameSection[i] == INVALID_HANDLE) StoreItemNameSection[i]					= CreateArray(32);
		if (StoreItemSection[i] == INVALID_HANDLE) StoreItemSection[i]						= CreateArray(32);
		if (TrailsKeys[i] == INVALID_HANDLE) TrailsKeys[i]							= CreateArray(32);
		if (TrailsValues[i] == INVALID_HANDLE) TrailsValues[i]							= CreateArray(32);
		if (DamageKeys[i] == INVALID_HANDLE) DamageKeys[i]						= CreateArray(32);
		if (DamageValues[i] == INVALID_HANDLE) DamageValues[i]					= CreateArray(32);
		if (DamageSection[i] == INVALID_HANDLE) DamageSection[i]				= CreateArray(32);
		if (MOTKeys[i] == INVALID_HANDLE) MOTKeys[i] = CreateArray(32);
		if (MOTValues[i] == INVALID_HANDLE) MOTValues[i] = CreateArray(32);
		if (MOTSection[i] == INVALID_HANDLE) MOTSection[i] = CreateArray(32);
		if (BoosterKeys[i] == INVALID_HANDLE) BoosterKeys[i]							= CreateArray(32);
		if (BoosterValues[i] == INVALID_HANDLE) BoosterValues[i]						= CreateArray(32);
		if (RPGMenuPosition[i] == INVALID_HANDLE) RPGMenuPosition[i]						= CreateArray(32);
		if (h_KilledPosition_X[i] == INVALID_HANDLE) h_KilledPosition_X[i]				= CreateArray(32);
		if (h_KilledPosition_Y[i] == INVALID_HANDLE) h_KilledPosition_Y[i]				= CreateArray(32);
		if (h_KilledPosition_Z[i] == INVALID_HANDLE) h_KilledPosition_Z[i]				= CreateArray(32);
		if (MeleeKeys[i] == INVALID_HANDLE) MeleeKeys[i]						= CreateArray(32);
		if (MeleeValues[i] == INVALID_HANDLE) MeleeValues[i]					= CreateArray(32);
		if (MeleeSection[i] == INVALID_HANDLE) MeleeSection[i]					= CreateArray(32);
		if (RCAffixes[i] == INVALID_HANDLE) RCAffixes[i] = CreateArray(32);
		if (AKKeys[i] == INVALID_HANDLE) AKKeys[i]						= CreateArray(32);
		if (AKValues[i] == INVALID_HANDLE) AKValues[i]					= CreateArray(32);
		if (AKSection[i] == INVALID_HANDLE) AKSection[i]					= CreateArray(32);
		if (SurvivorsIgnored[i] == INVALID_HANDLE) SurvivorsIgnored[i] = CreateArray(32);
		if (MyGroup[i] == INVALID_HANDLE) MyGroup[i] = CreateArray(32);
		if (PlayerEffectOverTime[i] == INVALID_HANDLE) PlayerEffectOverTime[i] = CreateArray(32);
		if (PlayerEffectOverTimeEffects[i] == INVALID_HANDLE) PlayerEffectOverTimeEffects[i] = CreateArray(32);
		if (CheckEffectOverTimeKeys[i] == INVALID_HANDLE) CheckEffectOverTimeKeys[i] = CreateArray(32);
		if (CheckEffectOverTimeValues[i] == INVALID_HANDLE) CheckEffectOverTimeValues[i] = CreateArray(32);
		if (FormatEffectOverTimeKeys[i] == INVALID_HANDLE) FormatEffectOverTimeKeys[i] = CreateArray(32);
		if (FormatEffectOverTimeValues[i] == INVALID_HANDLE) FormatEffectOverTimeValues[i] = CreateArray(32);
		if (FormatEffectOverTimeSection[i] == INVALID_HANDLE) FormatEffectOverTimeSection[i] = CreateArray(32);
		if (CooldownEffectTriggerKeys[i] == INVALID_HANDLE) CooldownEffectTriggerKeys[i] = CreateArray(32);
		if (CooldownEffectTriggerValues[i] == INVALID_HANDLE) CooldownEffectTriggerValues[i] = CreateArray(32);
		if (IsSpellAnAuraKeys[i] == INVALID_HANDLE) IsSpellAnAuraKeys[i] = CreateArray(32);
		if (IsSpellAnAuraValues[i] == INVALID_HANDLE) IsSpellAnAuraValues[i] = CreateArray(32);
		if (CallAbilityCooldownTriggerKeys[i] == INVALID_HANDLE) CallAbilityCooldownTriggerKeys[i] = CreateArray(32);
		if (CallAbilityCooldownTriggerValues[i] == INVALID_HANDLE) CallAbilityCooldownTriggerValues[i] = CreateArray(32);
		if (CallAbilityCooldownTriggerSection[i] == INVALID_HANDLE) CallAbilityCooldownTriggerSection[i] = CreateArray(32);
		if (GetIfTriggerRequirementsMetKeys[i] == INVALID_HANDLE) GetIfTriggerRequirementsMetKeys[i] = CreateArray(32);
		if (GetIfTriggerRequirementsMetValues[i] == INVALID_HANDLE) GetIfTriggerRequirementsMetValues[i] = CreateArray(32);
		if (GetIfTriggerRequirementsMetSection[i] == INVALID_HANDLE) GetIfTriggerRequirementsMetSection[i] = CreateArray(32);
		if (GAMKeys[i] == INVALID_HANDLE) GAMKeys[i] = CreateArray(32);
		if (GAMValues[i] == INVALID_HANDLE) GAMValues[i] = CreateArray(32);
		if (GAMSection[i] == INVALID_HANDLE) GAMSection[i] = CreateArray(32);
		if (GetGoverningAttributeKeys[i] == INVALID_HANDLE) GetGoverningAttributeKeys[i] = CreateArray(32);
		if (GetGoverningAttributeValues[i] == INVALID_HANDLE) GetGoverningAttributeValues[i] = CreateArray(32);
		if (GetGoverningAttributeSection[i] == INVALID_HANDLE) GetGoverningAttributeSection[i] = CreateArray(32);
		if (WeaponResultKeys[i] == INVALID_HANDLE) WeaponResultKeys[i] = CreateArray(32);
		if (WeaponResultValues[i] == INVALID_HANDLE) WeaponResultValues[i] = CreateArray(32);
		if (WeaponResultSection[i] == INVALID_HANDLE) WeaponResultSection[i] = CreateArray(32);
		if (GetAbilityCooldownKeys[i] == INVALID_HANDLE) GetAbilityCooldownKeys[i] = CreateArray(32);
		if (GetAbilityCooldownValues[i] == INVALID_HANDLE) GetAbilityCooldownValues[i] = CreateArray(32);
		if (GetAbilityCooldownSection[i] == INVALID_HANDLE) GetAbilityCooldownSection[i] = CreateArray(32);
		if (GetTalentValueSearchKeys[i] == INVALID_HANDLE) GetTalentValueSearchKeys[i] = CreateArray(32);
		if (GetTalentValueSearchValues[i] == INVALID_HANDLE) GetTalentValueSearchValues[i] = CreateArray(32);
		if (GetTalentValueSearchSection[i] == INVALID_HANDLE) GetTalentValueSearchSection[i] = CreateArray(32);
		if (GetTalentStrengthSearchValues[i] == INVALID_HANDLE) GetTalentStrengthSearchValues[i] = CreateArray(32);
		if (GetTalentStrengthSearchSection[i] == INVALID_HANDLE) GetTalentStrengthSearchSection[i] = CreateArray(32);
		if (GetTalentKeyValueKeys[i] == INVALID_HANDLE) GetTalentKeyValueKeys[i] = CreateArray(32);
		if (GetTalentKeyValueValues[i] == INVALID_HANDLE) GetTalentKeyValueValues[i] = CreateArray(32);
		if (GetTalentKeyValueSection[i] == INVALID_HANDLE) GetTalentKeyValueSection[i] = CreateArray(32);
		if (ApplyDebuffCooldowns[i] == INVALID_HANDLE) ApplyDebuffCooldowns[i] = CreateArray(32);
		if (TalentAtMenuPositionSection[i] == INVALID_HANDLE) TalentAtMenuPositionSection[i] = CreateArray(32);
		if (playerContributionTracker[i] == INVALID_HANDLE) playerContributionTracker[i] = CreateArray(8);
		if (myLootDropCategoriesAllowed[i] == INVALID_HANDLE) myLootDropCategoriesAllowed[i] = CreateArray(32);
		if (LootDropCategoryToBuffValues[i] == INVALID_HANDLE) LootDropCategoryToBuffValues[i] = CreateArray(32);
		if (myAugmentIDCodes[i] == INVALID_HANDLE) myAugmentIDCodes[i] = CreateArray(32);
		if (myAugmentCategories[i] == INVALID_HANDLE) myAugmentCategories[i] = CreateArray(32);
		if (myAugmentOwners[i] == INVALID_HANDLE) myAugmentOwners[i] = CreateArray(32);
		if (myAugmentInfo[i] == INVALID_HANDLE) myAugmentInfo[i] = CreateArray(32);
		if (equippedAugments[i] == INVALID_HANDLE) equippedAugments[i] = CreateArray(32);
		if (equippedAugmentsCategory[i] == INVALID_HANDLE) equippedAugmentsCategory[i] = CreateArray(32);
		if (GetAugmentTranslationKeys[i] == INVALID_HANDLE) GetAugmentTranslationKeys[i] = CreateArray(32);
		if (GetAugmentTranslationVals[i] == INVALID_HANDLE) GetAugmentTranslationVals[i] = CreateArray(32);
		if (myLootDropTargetEffectsAllowed[i] == INVALID_HANDLE) myLootDropTargetEffectsAllowed[i] = CreateArray(32);
		if (myLootDropActivatorEffectsAllowed[i] == INVALID_HANDLE) myLootDropActivatorEffectsAllowed[i] = CreateArray(32);
		if (equippedAugmentsActivator[i] == INVALID_HANDLE) equippedAugmentsActivator[i] = CreateArray(32);
		if (equippedAugmentsTarget[i] == INVALID_HANDLE) equippedAugmentsTarget[i] = CreateArray(32);
		if (myAugmentActivatorEffects[i] == INVALID_HANDLE) myAugmentActivatorEffects[i] = CreateArray(32);
		if (myAugmentTargetEffects[i] == INVALID_HANDLE) myAugmentTargetEffects[i] = CreateArray(32);
		if (equippedAugmentsIDCodes[i] == INVALID_HANDLE) equippedAugmentsIDCodes[i] = CreateArray(32);
		if (lootRollData[i] == INVALID_HANDLE) lootRollData[i] = CreateArray(32);
		if (playerLootOnGround[i] == INVALID_HANDLE) playerLootOnGround[i] = CreateArray(32);
		if (possibleLootPoolTarget[i] == INVALID_HANDLE) possibleLootPoolTarget[i] = CreateArray(32);
		if (possibleLootPoolActivator[i] == INVALID_HANDLE) possibleLootPoolActivator[i] = CreateArray(32);
	}
	CreateTimer(1.0, Timer_ExecuteConfig, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
	b_FirstLoad = true;
}

stock OnMapStartFunc() {
	if (!b_MapStart) {
		b_MapStart								= true;

		if (!b_FirstLoad) CreateAllArrays();
		CreateTimer(10.0, Timer_GetCampaignName, _, TIMER_FLAG_NO_MAPCHANGE);
	}
	SetSurvivorsAliveHostname();
}

public void OnAllPluginsLoaded() {
	//ReadyUp_NtvIsCampaignFinale();
	//CheckDifficulty();
}

public ReadyUp_GetCampaignStatus(mapposition) {
	CurrentMapPosition = mapposition;
}

public void OnMapStart() {
	SetConVarInt(FindConVar("director_no_death_check"), 0);	// leave 0 until figure out why scenario_end doesn't work anymore.
	SetConVarInt(FindConVar("sv_rescue_disabled"), 0);
	SetConVarInt(FindConVar("z_common_limit"), 0);	// there are no commons until the round starts in all game modes to give players a chance to move.
	iTopThreat = 0;
	// When the server restarts, for any reason, RPG will properly load.
	//if (!b_FirstLoad) OnMapStartFunc();
	// This can call more than once, and we only want it to fire once.
	// The variable resets to false when a map ends.
	PrecacheModel("models/infected/common_male_clown.mdl", true);
	PrecacheModel("models/infected/common_male_ceda.mdl", true);
	PrecacheModel("models/infected/common_male_fallen_survivor.mdl", true);
	PrecacheModel("models/infected/common_male_riot.mdl", true);
	PrecacheModel("models/infected/common_male_mud.mdl", true);
	PrecacheModel("models/infected/common_male_jimmy.mdl", true);
	PrecacheModel("models/infected/common_male_roadcrew.mdl", true);
	PrecacheModel("models/infected/witch_bride.mdl", true);
	PrecacheModel("models/infected/witch.mdl", true);
	PrecacheModel("models/props_interiors/toaster.mdl", true);
	PrecacheSound(JETPACK_AUDIO, true);
	g_iSprite = PrecacheModel("materials/sprites/laserbeam.vmt");
	g_BeaconSprite = PrecacheModel("materials/sprites/halo01.vmt");
	b_IsActiveRound = false;
	MapRoundsPlayed = 0;
	b_IsCampaignComplete			= false;
	b_IsRoundIsOver					= true;
	b_IsCheckpointDoorStartOpened	= false;
	b_IsMissionFailed				= false;
	ClearArray(SpecialAmmoData);
	ClearArray(CommonAffixes);
	ClearArray(WitchList);
	ClearArray(EffectOverTime);
	ClearArray(TimeOfEffectOverTime);
	ClearArray(StaggeredTargets);
	GetCurrentMap(TheCurrentMap, sizeof(TheCurrentMap));
	Format(CONFIG_MAIN, sizeof(CONFIG_MAIN), "%srpg/%s.cfg", ConfigPathDirectory, TheCurrentMap);
	//LogMessage("CONFIG_MAIN DEFAULT: %s", CONFIG_MAIN);
	if (!FileExists(CONFIG_MAIN)) Format(CONFIG_MAIN, sizeof(CONFIG_MAIN), "rpg/config.cfg");
	else Format(CONFIG_MAIN, sizeof(CONFIG_MAIN), "rpg/%s.cfg", TheCurrentMap);
	UnhookAll();
	SetSurvivorsAliveHostname();
	CheckGamemode();
}

stock ResetValues(client) {

	// Yep, gotta do this *properly*
	b_HasDeathLocation[client] = false;
}

public void OnMapEnd() {
	if (b_MapStart) b_MapStart = false;
	if (b_IsActiveRound) b_IsActiveRound = false;
	for (int i = 1; i <= MaxClients; i++) {
		if (ISEXPLODE[i] != INVALID_HANDLE) {
			KillTimer(ISEXPLODE[i]);
			ISEXPLODE[i] = INVALID_HANDLE;
		}
		ClearArray(CommonInfected[i]);
	}
	ClearArray(NewUsersRound);
}

public Action Timer_GetCampaignName(Handle timer) {
	ReadyUp_NtvGetCampaignName();
	ReadyUp_NtvIsCampaignFinale();
	return Plugin_Stop;
}

stock CheckGamemode() {
	char TheGamemode[64];
	GetConVarString(g_Gamemode, TheGamemode, sizeof(TheGamemode));
	char TheRequiredGamemode[64];
	GetConfigValue(TheRequiredGamemode, sizeof(TheRequiredGamemode), "gametype?");
	if (!StrEqual(TheRequiredGamemode, "-1") && !StrEqual(TheGamemode, TheRequiredGamemode, false)) {
		LogMessage("Gamemode did not match, changing to %s", TheRequiredGamemode);
		PrintToChatAll("Gamemode did not match, changing to %s", TheRequiredGamemode);
		SetConVarString(g_Gamemode, TheRequiredGamemode);
		char TheMapname[64];
		GetCurrentMap(TheMapname, sizeof(TheMapname));
		ServerCommand("changelevel %s", TheMapname);
	}
}

public Action Timer_ExecuteConfig(Handle timer) {
	if (ReadyUp_NtvConfigProcessing() == 0) {
		// These are processed one-by-one in a defined-by-dependencies order, but you can place them here in any order you want.
		// I've placed them here in the order they load for uniformality.
		ReadyUp_ParseConfig(CONFIG_MAIN);
		ReadyUp_ParseConfig(CONFIG_EVENTS);
		ReadyUp_ParseConfig(CONFIG_MENUTALENTS);
		ReadyUp_ParseConfig(CONFIG_POINTS);
		ReadyUp_ParseConfig(CONFIG_STORE);
		ReadyUp_ParseConfig(CONFIG_TRAILS);
		ReadyUp_ParseConfig(CONFIG_MAINMENU);
		ReadyUp_ParseConfig(CONFIG_WEAPONS);
		ReadyUp_ParseConfig(CONFIG_PETS);
		ReadyUp_ParseConfig(CONFIG_COMMONAFFIXES);
		//ReadyUp_ParseConfig(CONFIG_CLASSNAMES);
		return Plugin_Stop;
	}
	return Plugin_Continue;
}

public Action Timer_AutoRes(Handle timer) {
	if (b_IsCheckpointDoorStartOpened) return Plugin_Stop;
	for (int i = 1; i <= MaxClients; i++) {
		if (IsLegitimateClient(i) && GetClientTeam(i) == TEAM_SURVIVOR) {
			if (!IsPlayerAlive(i)) SDKCall(hRoundRespawn, i);
			else if (IsIncapacitated(i)) ExecCheatCommand(i, "give", "health");
		}
	}
	return Plugin_Continue;
}

stock bool AnyHumans() {
	for (int i = 1; i <= MaxClients; i++) {
		if (IsLegitimateClient(i) && !IsFakeClient(i)) return true;
	}
	return false;
}

public ReadyUp_ReadyUpStart() {
	lootDropCounter = 0;	// reset the loot drop counter.
	CheckDifficulty();
	RoundTime = 0;
	b_IsRoundIsOver = true;
	iTopThreat = 0;
	SetSurvivorsAliveHostname();
	CreateTimer(1.0, Timer_AutoRes, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
	/*
	When a new round starts, we want to forget who was the last person to speak on different teams.
	*/
	Format(Public_LastChatUser, sizeof(Public_LastChatUser), "none");
	Format(Spectator_LastChatUser, sizeof(Spectator_LastChatUser), "none");
	Format(Survivor_LastChatUser, sizeof(Survivor_LastChatUser), "none");
	Format(Infected_LastChatUser, sizeof(Infected_LastChatUser), "none");
	bool TeleportPlayers = false;
	float teleportIntoSaferoom[3];
	if (StrEqual(TheCurrentMap, "zerowarn_1r", false)) {
		teleportIntoSaferoom[0] = 4087.998291;
		teleportIntoSaferoom[1] = 11974.557617;
		teleportIntoSaferoom[2] = -300.968750;
		TeleportPlayers = true;
	}
	for (int i = 1; i <= MaxClients; i++) {
		if (IsLegitimateClient(i)) {
			if (CurrentMapPosition == 0 && b_IsLoaded[i] && GetClientTeam(i) == TEAM_SURVIVOR) GiveProfileItems(i);
			//if (GetClientTeam(i) == TEAM_SURVIVOR) GiveProfileItems(i);
			if (TeleportPlayers) TeleportEntity(i, teleportIntoSaferoom, NULL_VECTOR, NULL_VECTOR);
			//if (GetClientTeam(i) == TEAM_SURVIVOR && !b_IsLoaded[i]) IsClientLoadedEx(i);
			staggerCooldownOnTriggers[i] = false;
			ISBILED[i] = false;
			iThreatLevel[i] = 0;
			bIsEligibleMapAward[i] = true;
			HealingContribution[i] = 0;
			TankingContribution[i] = 0;
			DamageContribution[i] = 0;
			PointsContribution[i] = 0.0;
			HexingContribution[i] = 0;
			BuffingContribution[i] = 0;
			b_IsFloating[i] = false;
			ISDAZED[i] = 0.0;
			bIsInCombat[i] = false;
			b_IsInSaferoom[i] = true;
			// Anti-Farm/Anti-Camping system stuff.
			ClearArray(h_KilledPosition_X[i]);		// We clear all positions from the array.
			ClearArray(h_KilledPosition_Y[i]);
			ClearArray(h_KilledPosition_Z[i]);
			/*if (b_IsMissionFailed && GetClientTeam(i) == TEAM_SURVIVOR && IsFakeClient(i)) {

				if (!b_IsLoading[i]) {

					b_IsLoaded[i] = false;
					OnClientLoaded(i);
				}
			}*/
		}
	}
	RefreshSurvivorBots();
}

public ReadyUp_ReadyUpEnd() {
	ReadyUpEnd_Complete();
}

public Action Timer_Defibrillator(Handle timer, any client) {
	if (IsLegitimateClient(client) && !IsPlayerAlive(client)) Defibrillator(0, client);
	return Plugin_Stop;
}

public ReadyUpEnd_Complete() {
	//PrintToChatAll("DOor opened");
	//b_IsCheckpointDoorStartOpened = true;
	//b_IsActiveRound = true;
	if (b_IsRoundIsOver) {
		b_IsRoundIsOver = false;
		CreateTimer(30.0, Timer_CheckDifficulty, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
		CheckDifficulty();
		b_IsMissionFailed = false;
		//if (ReadyUp_GetGameMode() == 3) {
		ClearArray(CommonAffixes);
			//b_IsSurvivalIntermission = true;
			//CreateTimer(5.0, Timer_AutoRes, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
		//}
		//RoundTime					=	GetTime();
		b_IsCheckpointDoorStartOpened = false;
		for (int i = 1; i <= MaxClients; i++) {
			if (IsLegitimateClient(i) && IsFakeClient(i) && !b_IsLoaded[i]) IsClientLoadedEx(i);
		}
		if (iRoundStartWeakness == 1) {
			for (int i = 1; i <= MaxClients; i++) {
				if (IsLegitimateClient(i) && GetClientTeam(i) == TEAM_SURVIVOR) {
					staggerCooldownOnTriggers[i] = false;
					ISBILED[i] = false;
					bHasWeakness[i] = true;
					SurvivorEnrage[i][0] = 0.0;
					SurvivorEnrage[i][1] = 0.0;
					ISDAZED[i] = 0.0;
					if (b_IsLoaded[i]) {
						SurvivorStamina[i] = GetPlayerStamina(i) - 1;
						SetMaximumHealth(i);
					}
					else if (!b_IsLoading[i]) OnClientLoaded(i);
					bIsSurvivorFatigue[i] = false;
					LastWeaponDamage[i] = 1;
					HealingContribution[i] = 0;
					TankingContribution[i] = 0;
					DamageContribution[i] = 0;
					PointsContribution[i] = 0.0;
					HexingContribution[i] = 0;
					BuffingContribution[i] = 0;
					b_IsFloating[i] = false;
					bIsHandicapLocked[i] = false;
				}
			}
		}
	}
}

stock TimeUntilEnrage(char[] TheText, TheSize) {
	if (!IsEnrageActive()) {
		int Seconds = (iEnrageTime * 60) - (GetTime() - RoundTime);
		int Minutes = 0;
		while (Seconds >= 60) {
			Seconds -= 60;
			Minutes++;
		}
		if (Seconds == 0) {
			Format(TheText, TheSize, "%d minute", Minutes);
			if (Minutes > 1) Format(TheText, TheSize, "%ss", TheText);
		}
		else if (Minutes == 0) Format(TheText, TheSize, "%d seconds", Seconds);
		else {
			if (Minutes > 1) Format(TheText, TheSize, "%d minutes, %d seconds", Minutes, Seconds);
			else Format(TheText, TheSize, "%d minute, %d seconds", Minutes, Seconds);
		}
	}
	else Format(TheText, TheSize, "ACTIVE");
}

stock GetSecondsUntilEnrage() {
	int secondsLeftUntilEnrage = (iEnrageTime * 60) - (GetTime() - RoundTime);
	return secondsLeftUntilEnrage;
}

stock RPGRoundTime(bool IsSeconds = false) {
	int Seconds = GetTime() - RoundTime;
	if (IsSeconds) return Seconds;
	int Minutes = 0;
	while (Seconds >= 60) {
		Minutes++;
		Seconds -= 60;
	}
	return Minutes;
}

stock bool IsEnrageActive() {
	if (!b_IsActiveRound || IsSurvivalMode || iEnrageTime < 1) return false;
	if (RPGRoundTime() < iEnrageTime) return false;
	if (!IsEnrageNotified && iNotifyEnrage == 1) {
		IsEnrageNotified = true;
		PrintToChatAll("%t", "enrage period", orange, blue, orange);
	}
	return true;
}

bool ForcedWeakness(client) {
	if (GetTalentPointsByKeyValue(client, ACTIVATOR_ABILITY_EFFECTS, "weakness") > 0 ||
		GetTalentPointsByKeyValue(client, SECONDARY_EFFECTS, "weakness") > 0) return true;
	return false;
}

stock bool PlayerHasWeakness(client) {
	if (!IsLegitimateClientAlive(client) || !b_IsLoaded[client]) return false;
	if (IsSpecialCommonInRange(client, 'w')) return true;
	// if (IsClientInRangeSpecialAmmo(client, "W", true) == -2.0) return true;	// the player is not weak if inside cleansing ammo.*
	if (ForcedWeakness(client)) return true;
	if (GetIncapCount(client) >= iMaxIncap) return true;
	return false;
}

public ReadyUp_CheckpointDoorStartOpened() {
	if (!b_IsCheckpointDoorStartOpened) {
		b_IsCheckpointDoorStartOpened		= true;
		b_IsActiveRound = true;
		bIsSettingsCheck = true;
		IsEnrageNotified = false;
		b_IsFinaleTanks = false;

		for (int i = 1; i <= MaxClients; i++) {
			if (!IsLegitimateClient(i) || GetClientTeam(i) == TEAM_SPECTATOR) continue;
			ChangeHook(i, true);
		}
		ClearArray(persistentCirculation);
		ClearArray(CoveredInVomit);
		ClearArray(RoundStatistics);
		ResizeArray(RoundStatistics, 5);
		for (int i = 0; i < 5; i++) {

			SetArrayCell(RoundStatistics, i, 0);
			if (CurrentMapPosition == 0) SetArrayCell(RoundStatistics, i, 0, 1);	// first map of campaign, reset the total.
		}
		char pct[4];
		Format(pct, sizeof(pct), "%");
		int iMaxHandicap = 0;
		int iMinHandicap = RatingPerLevel;
		char text[64];
		int survivorCounter = TotalHumanSurvivors();
		bool AnyBotsOnSurvivorTeam = BotsOnSurvivorTeam();
		for (int i = 1; i <= MaxClients; i++) {
			if (IsLegitimateClient(i)) {
				bIsMeleeCooldown[i] = false;
				if (!IsFakeClient(i)) {
					if (iTankRush == 1) RatingHandicap[i] = RatingPerLevel;
					else {
						iMaxHandicap = GetMaxHandicap(i);
						if (RatingHandicap[i] < iMinHandicap) RatingHandicap[i] = iMinHandicap;
						else if (RatingHandicap[i] > iMaxHandicap) RatingHandicap[i] = iMaxHandicap;
					}
					if (GroupMemberBonus > 0.0) {
						if (IsGroupMember[i]) PrintToChat(i, "%T", "group member bonus", i, blue, GroupMemberBonus * 100.0, pct, green, orange);
						else PrintToChat(i, "%T", "group member benefit", i, orange, blue, GroupMemberBonus * 100.0, pct, green, blue);
					}
					if (!AnyBotsOnSurvivorTeam && fSurvivorBotsNoneBonus > 0.0 && survivorCounter <= iSurvivorBotsBonusLimit) {
						PrintToChat(i, "%T", "group no survivor bots bonus", i, blue, fSurvivorBotsNoneBonus * 100.0, pct, green, orange);
					}
					if (RoundExperienceMultiplier[i] > 0.0) {
						PrintToChat(i, "%T", "survivalist bonus experience", i, blue, orange, green, RoundExperienceMultiplier[i] * 100.0, white, pct);
					}
				}
				else SetBotHandicap(i);
			}
		}
		if (CurrentMapPosition != 0 || ReadyUpGameMode == 3) CheckDifficulty();
		RoundTime					=	GetTime();
		int ent = -1;
		if (ReadyUpGameMode != 3) {
			while ((ent = FindEntityByClassname(ent, "witch")) != -1) {
				// Some maps, like Hard Rain pre-spawn a ton of witches - we want to add them to the witch table.
				OnWitchCreated(ent);
			}
		}
		else {
			IsSurvivalMode = true;
			for (int i = 1; i <= MaxClients; i++) {
				if (IsLegitimateClientAlive(i) && GetClientTeam(i) == TEAM_SURVIVOR) {
					VerifyMinimumRating(i, true);
					RespawnImmunity[i] = false;
				}
			}
			decl String:TheCurr[64];
			GetCurrentMap(TheCurr, sizeof(TheCurr));
			if (StrContains(TheCurr, "helms_deep", false) != -1) {
				// the bot has to be teleported to the machine gun, because samurai blocks the teleportation in the actual map scripting
				new Float:TeleportBots[3];
				TeleportBots[0] = 1572.749146;
				TeleportBots[1] = -871.468811;
				TeleportBots[2] = 62.031250;
				decl String:TheModel[64];
				for (new i = 1; i <= MaxClients; i++) {
					if (IsLegitimateClientAlive(i) && IsFakeClient(i)) {
						GetClientModel(i, TheModel, sizeof(TheModel));
						if (StrEqual(TheModel, LOUIS_MODEL)) TeleportEntity(i, TeleportBots, NULL_VECTOR, NULL_VECTOR);
					}
				}
				PrintToChatAll("\x04Man the gun, Louis!");
			}
		}
		b_IsCampaignComplete				= false;
		if (ReadyUpGameMode != 3) b_IsRoundIsOver						= false;
		if (ReadyUpGameMode == 2) MapRoundsPlayed = 0;	// Difficulty leniency does not occur in versus.
		SpecialsKilled				=	0;
		//RoundDamageTotal			=	0;
		b_IsFinaleActive			=	false;
		char thetext[64];
		GetConfigValue(thetext, sizeof(thetext), "path setting?");
		if (ReadyUpGameMode != 3 && !StrEqual(thetext, "none")) {
			if (!StrEqual(thetext, "random")) ServerCommand("sm_forcepath %s", thetext);
			else {
				if (StrEqual(PathSetting, "none")) {
					int random = GetRandomInt(1, 100);
					if (random <= 33) Format(PathSetting, sizeof(PathSetting), "easy");
					else if (random <= 66) Format(PathSetting, sizeof(PathSetting), "medium");
					else Format(PathSetting, sizeof(PathSetting), "hard");
				}
				ServerCommand("sm_forcepath %s", PathSetting);
			}
		}
		for (int i = 1; i <= MaxClients; i++) {
			if (IsLegitimateClient(i) && GetClientTeam(i) == TEAM_SURVIVOR) {
				if (!IsPlayerAlive(i)) SDKCall(hRoundRespawn, i);
				VerifyMinimumRating(i);
				HealImmunity[i] = false;
				if (b_IsLoaded[i]) GiveMaximumHealth(i);
				else if (!b_IsLoading[i]) OnClientLoaded(i);
			}
		}
		f_TankCooldown				=	-1.0;
		ResetCDImmunity(-1);
		DoomTimer = 0;
		if (ReadyUpGameMode != 2 && fDirectorThoughtDelay > 0.0) CreateTimer(1.0, Timer_DirectorPurchaseTimer, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
		if (!bIsSoloHandicap && RespawnQueue > 0) CreateTimer(1.0, Timer_RespawnQueue, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
		RaidInfectedBotLimit();
		CreateTimer(1.0, Timer_StartPlayerTimers, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
		CreateTimer(1.0, Timer_CheckIfHooked, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
		CreateTimer(GetConfigValueFloat("settings check interval?"), Timer_SettingsCheck, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
		if (DoomSUrvivorsRequired != 0) CreateTimer(1.0, Timer_Doom, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
		CreateTimer(0.5, Timer_EntityOnFire, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);		// Fire status effect
		CreateTimer(1.0, Timer_ThreatSystem, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);		// threat system modulator
		CreateTimer(fStaggerTickrate, Timer_StaggerTimer, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
		//CreateTimer(fDrawHudInterval, Timer_ShowHUD, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
		//CreateTimer(fSpecialAmmoInterval, Timer_ShowActionBar, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
		if (iCommonAffixes > 0) {
			ClearArray(CommonAffixes);
			CreateTimer(2.0, Timer_CommonAffixes, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
		}
		ClearRelevantData();
		LastLivingSurvivor = 1;
		int size = GetArraySize(a_DirectorActions);
		ResizeArray(a_DirectorActions_Cooldown, size);
		for (int i = 0; i < size; i++) SetArrayString(a_DirectorActions_Cooldown, i, "0");
		int theCount = LivingSurvivorCount();
		if (iSurvivorModifierRequired > 0 && fSurvivorExpMult > 0.0 && theCount >= iSurvivorModifierRequired) {
			PrintToChatAll("%t", "teammate bonus experience", blue, green, ((theCount - (iSurvivorModifierRequired - 1)) * fSurvivorExpMult) * 100.0, pct);
		}
		RefreshSurvivorBots();
		if (iResetDirectorPointsOnNewRound == 1) Points_Director = 0.0;
		if (iEnrageTime > 0) {
			TimeUntilEnrage(text, sizeof(text));
			PrintToChatAll("%t", "time until things get bad", orange, green, text, orange);
		}
	}
}

stock RefreshSurvivorBots() {
	for (int i = 1; i <= MaxClients; i++) {
		if (IsLegitimateClient(i) && IsFakeClient(i)) RefreshSurvivor(i);
	}
}

stock SetClientMovementSpeed(client) {
	if (IsValidEntity(client)) SetEntPropFloat(client, Prop_Send, "m_flLaggedMovementValue", fBaseMovementSpeed);
}

stock ResetCoveredInBile(client) {
	for (int i = 1; i <= MaxClients; i++) {
		if (IsLegitimateClient(i)) {
			CoveredInBile[client][i] = -1;
			CoveredInBile[i][client] = -1;
		}
	}
}

stock FindTargetClient(client, char[] arg) {
	char target_name[MAX_TARGET_LENGTH];
	int target_list[MAXPLAYERS], target_count;
	bool tn_is_ml;
	int targetclient;
	if ((target_count = ProcessTargetString(
		arg,
		client,
		target_list,
		MAXPLAYERS,
		COMMAND_FILTER_CONNECTED,
		target_name,
		sizeof(target_name),
		tn_is_ml)) > 0) {
		for (int i = 0; i < target_count; i++) targetclient = target_list[i];
	}
	return targetclient;
}

stock CMD_CastAction(client, args) {
	char actionpos[64];
	GetCmdArg(1, actionpos, sizeof(actionpos));
	if (StrContains(actionpos, acmd, false) != -1 && !StrEqual(abcmd, actionpos[1], false)) {
		CastActionEx(client, actionpos, sizeof(actionpos));
	}
}

stock CastActionEx(client, char[] t_actionpos = "none", TheSize, pos = -1) {
	int ActionSlots = iActionBarSlots;
	char actionpos[64];
	if (pos == -1) pos = StringToInt(t_actionpos[strlen(t_actionpos) - 1]) - 1;//StringToInt(actionpos[strlen(actionpos) - 1]);
	if (pos >= 0 && pos < ActionSlots) {
		//pos--;	// shift down 1 for the array.
		GetArrayString(ActionBar[client], pos, actionpos, sizeof(actionpos));
		if (IsTalentExists(actionpos)) { //PrintToChat(client, "%T", "Action Slot Empty", client, white, orange, blue, pos+1);
			int size =	GetArraySize(a_Menu_Talents);
			int RequiresTarget = 0;
			int AbilityTalent = 0;
			float TargetPos[3];
			char TalentName[64];
			float visualDelayTime = 0.0;
			for (int i = 0; i < size; i++) {
				CastKeys[client]			= GetArrayCell(a_Menu_Talents, i, 0);
				CastValues[client]			= GetArrayCell(a_Menu_Talents, i, 1);
				CastSection[client]			= GetArrayCell(a_Menu_Talents, i, 2);
				GetArrayString(CastSection[client], 0, TalentName, sizeof(TalentName));
				if (!StrEqual(TalentName, actionpos)) continue;
				AbilityTalent = GetArrayCell(CastValues[client], IS_TALENT_ABILITY);
				if (GetArrayCell(CastValues[client], ABILITY_PASSIVE_ONLY) == 1) continue;
				//if (AbilityTalent != 1 && GetTalentStrength(client, actionpos) < 1) {
				if (AbilityTalent != 1 && GetArrayCell(MyTalentStrength[client], i) < 1) {
					// talent exists but user has no points in it from a respec or whatever so we remove it.
					// we don't tell them either, next time they use it they'll find out.
					Format(actionpos, TheSize, "none");
					SetArrayString(ActionBar[client], pos, actionpos);
				}
				else {
					RequiresTarget = GetArrayCell(CastValues[client], ABILITY_IS_SINGLE_TARGET);
					visualDelayTime = GetArrayCell(CastValues[client], ABILITY_DRAW_DELAY);
					if (visualDelayTime < 1.0) visualDelayTime = 1.0;
					if (RequiresTarget > 0) {
						//GetClientAimTargetEx(client, actionpos, TheSize, true);
						RequiresTarget = GetAimTargetPosition(client, TargetPos);//StringToInt(actionpos);
						if (IsLegitimateClientAlive(RequiresTarget)) {
							if (AbilityTalent != 1) CastSpell(client, RequiresTarget, TalentName, TargetPos, visualDelayTime);
							else UseAbility(client, RequiresTarget, TalentName, CastKeys[client], CastValues[client], TargetPos);
						}
					}
					else {
						GetAimTargetPosition(client, TargetPos);
						/*GetClientAimTargetEx(client, actionpos, TheSize);
						ExplodeString(actionpos, " ", tTargetPos, 3, 64);
						TargetPos[0] = StringToFloat(tTargetPos[0]);
						TargetPos[1] = StringToFloat(tTargetPos[1]);
						TargetPos[2] = StringToFloat(tTargetPos[2]);*/
						if (AbilityTalent != 1) CastSpell(client, _, TalentName, TargetPos, visualDelayTime);
						else {
							CheckActiveAbility(client, pos, _, _, true, true);
							UseAbility(client, _, TalentName, CastKeys[client], CastValues[client], TargetPos);
						}
					}
				}
				break;
			}
		}
	}
	else {
		PrintToChat(client, "%T", "Action Slot Range", client, white, blue, ActionSlots, white);
	}
}

public Action CMD_GetWeapon(client, args) {
	char s[64];
	GetClientWeapon(client, s, sizeof(s));
	if (StrEqual(s, "weapon_melee")) {
		int iWeapon = FindSendPropInfo("CTerrorPlayer", "m_hActiveWeapon");
		iWeapon = GetEntDataEnt2(client, iWeapon);
		GetEntityClassname(iWeapon, s, sizeof(s));
		GetEntPropString(iWeapon, Prop_Data, "m_strMapSetScriptName", s, sizeof(s));
	}
	PrintToChat(client, "%s", s);
	return Plugin_Handled;
}

stock MySurvivorCompanion(client) {

	char SteamId[64];
	char CompanionSteamId[64];
	GetClientAuthId(client, AuthId_Steam2, SteamId, sizeof(SteamId));

	for (int i = 1; i <= MaxClients; i++) {

		if (IsLegitimateClient(i) && GetClientTeam(i) == TEAM_SURVIVOR && IsFakeClient(i)) {

			GetEntPropString(i, Prop_Data, "m_iName", CompanionSteamId, sizeof(CompanionSteamId));
			if (StrEqual(CompanionSteamId, SteamId, false)) return i;
		}
	}
	return -1;
}

public Action CMD_CompanionOptions(client, args) {

	/*if (GetClientTeam(client) != TEAM_SURVIVOR) return Plugin_Handled;
	decl String:TheCommand[64], String:TheName[64], String:tquery[512], String:thetext[64], String:SteamId[64];
	GetCmdArg(1, TheCommand, sizeof(TheCommand));
	if (args > 1) {

		new companion = MySurvivorCompanion(client);

		if (companion == -1) {	// no companion active.

			if (StrEqual(TheCommand, "create", false)) {	// creates a companion.

				if (args == 2) {

					GetCmdArg(2, TheName, sizeof(TheName));
					ReplaceString(TheName, sizeof(TheName), "+", " ");

					Format(CompanionNameQueue[client], sizeof(CompanionNameQueue[]), "%s", TheName);
					GetClientAuthString(client, SteamId, sizeof(SteamId));

					Format(tquery, sizeof(tquery), "SELECT COUNT(*) FROM `%s` WHERE `companionowner` = '%s';", TheDBPrefix, SteamId);
					SQL_TQuery(hDatabase, Query_CheckCompanionCount, tquery, client);
				}
				else {

					GetConfigValue(thetext, sizeof(thetext), "companion command?");
					PrintToChat(client, "!%s create <name>", thetext);
				}
			}
			else if (StrEqual(TheCommand, "load", false)) {	// opens the comapnion load menu.

			}
		}
		else {	// player has a companion active.

			if (StrEqual(TheCommand, "delete", false)) {	// we delete the companion.

			}
			else if (StrEqual(TheCommand, "edit", false)) {	// opens the talent menu for the companion.

			}
			else if (StrEqual(TheCommand, "save", false)) {	// saves the companion, you should always do this before loading a new one.

			}
		}
	}
	else {

		// display the available commands to the user.
	}*/
	return Plugin_Handled;
}

public Action CMD_TogglePvP(client, args) {
	int TheTime = RoundToCeil(GetEngineTime());
	if (IsPvP[client] != 0) {
		if (IsPvP[client] + 30 <= TheTime) {
			IsPvP[client] = 0;
			PrintToChat(client, "%T", "PvP Disabled", client, white, orange);
		}
	}
	else {
		IsPvP[client] = TheTime + 30;
		PrintToChat(client, "%T", "PvP Enabled", client, white, blue);
	}
	return Plugin_Handled;
}

public Action CMD_SetAugmentPrice(client, args) {
	if (args < 2) {
		PrintToChat(client, "\x04!price <augmentId> <price>");
		return Plugin_Handled;
	}
	int size = GetArraySize(myAugmentIDCodes[client]);
	char arg[512];
	char arg2[64];
	GetCmdArg(1, arg, sizeof(arg));
	GetCmdArg(2, arg2, sizeof(arg2));
	int augmentSlotToModify = StringToInt(arg);
	if (augmentSlotToModify >= 0 && augmentSlotToModify < size) {
		int augmentPrice = StringToInt(arg2);
		if (augmentPrice > 10000) augmentPrice = 10000;
		if (augmentPrice < 0) augmentPrice = 0;
		SetArrayCell(myAugmentInfo[client], augmentSlotToModify, augmentPrice, 1);
		PrintToChat(client, "\x04augment price set: \x03%d", augmentPrice);
	}
	else PrintToChat(client, "\x04augment id could not be found. \x03no price adjustments were made.");
	return Plugin_Handled;
}

public Action CMD_GiveLevel(client, args) {
	char thetext[64];
	GetConfigValue(thetext, sizeof(thetext), "give player level flags?");
	if ((HasCommandAccess(client, thetext) || client == 0) && args > 1) {
		char arg[512];
		char arg2[64];
		char arg3[64];
		GetCmdArg(1, arg, sizeof(arg));
		GetCmdArg(2, arg2, sizeof(arg2));
		GetCmdArg(3, arg3, sizeof(arg3));
		int targetclient = 0;
		bool hasSTEAM = (StrContains(arg, "STEAM", true) != -1) ? true : false;
		if (!hasSTEAM) targetclient = FindTargetClient(client, arg);
		if (args < 3 || hasSTEAM) {
			if (hasSTEAM) {
				char tquery[512];
				Format(steamIdSearch[client], 64, "%s%s", serverKey, arg);
				PrintToChat(client, "looking up %s to see if it exists...", steamIdSearch[client]);
				Format(tquery, sizeof(tquery), "SELECT COUNT(*) FROM `%s` WHERE (`steam_id` = '%s');", TheDBPrefix, steamIdSearch[client]);
				//Format(steamIdSearch[client], 64, "%s", arg2);
				levelToSet[client] = StringToInt(arg2);
				if (levelToSet[client] > iMaxLevel) levelToSet[client] = iMaxLevel;
				SQL_TQuery(hDatabase, Query_FindDataAndApplyChange, tquery, client);
			}
			else {
				if (IsLegitimateClient(targetclient) && PlayerLevel[targetclient] != StringToInt(arg2)) {
					SetTotalExperienceByLevel(targetclient, StringToInt(arg2));
					char Name[64];
					GetClientName(targetclient, Name, sizeof(Name));
					PrintToChatAll("%t", "client level set", Name, green, white, blue, PlayerLevel[targetclient]);
					FormatPlayerName(targetclient);
				}
			}
		}
		else {
			if (IsLegitimateClient(targetclient)) {
				if (StrContains(arg3, "rating", false) != -1) {
					Rating[targetclient] = StringToInt(arg2);
					BestRating[targetclient] = StringToInt(arg2);
				}
				//else ModifyCartelValue(targetclient, arg3, StringToInt(arg2));
			}
		}
	}
	return Plugin_Handled;
}

stock GetExperienceRequirement(newlevel) {
	float fExpMult = fExperienceMultiplier * (newlevel - 1);
	return iExperienceStart + RoundToCeil(iExperienceStart * fExpMult);
}

stock CheckExperienceRequirement(client, bool bot = false, iLevel = 0, previousLevelRequirement = 0) {
	int experienceRequirement = 0;
	if (IsLegitimateClient(client)) {
		int levelToCalculateFor = (iLevel == 0) ? PlayerLevel[client] : iLevel;

		experienceRequirement			=	iExperienceStart;
		float experienceMultiplier	=	0.0;
		if (iUseLinearLeveling == 1) {
			experienceMultiplier 			=	fExperienceMultiplier * (levelToCalculateFor - 1);
			experienceRequirement			=	iExperienceStart + RoundToCeil(iExperienceStart * experienceMultiplier);
		}
		else if (previousLevelRequirement != 0) {
			experienceRequirement			=	previousLevelRequirement + RoundToCeil(previousLevelRequirement * fExperienceMultiplier);
		}
		else if (levelToCalculateFor > 1) {
			for (int i = 1; i < levelToCalculateFor; i++) experienceRequirement		+=	RoundToCeil(experienceRequirement * fExperienceMultiplier);
		}
	}
	return experienceRequirement;
}

stock GetPlayerLevel(client) {
	int iExperienceOverall = ExperienceOverall[client];
	int iLevel = 1;
	int ExperienceRequirement = CheckExperienceRequirement(client, false, iLevel);
	while (iExperienceOverall >= ExperienceRequirement && iLevel < iMaxLevel) {
		if (iIsLevelingPaused[client] == 1 && iExperienceOverall == ExperienceRequirement) break;
		iExperienceOverall -= ExperienceRequirement;
		iLevel++;
		ExperienceRequirement = CheckExperienceRequirement(client, false, iLevel, ExperienceRequirement);
	}
	return iLevel;
}

stock GetTotalExperienceByLevel(newlevel) {
	int experienceTotal = 0;
	if (newlevel > iMaxLevel) newlevel = iMaxLevel;
	for (int i = 1; i <= newlevel; i++) {
		if (newlevel == i) break;
		experienceTotal += GetExperienceRequirement(i);
	}
	experienceTotal++;
	return experienceTotal;
}

stock SetTotalExperienceByLevel(client, newlevel, bool giveMaxXP = false) {

	int oldlevel = PlayerLevel[client];
	ExperienceOverall[client] = 0;
	ExperienceLevel[client] = 0;
	if (newlevel > iMaxLevel) newlevel = iMaxLevel;
	PlayerLevel[client] = newlevel;
	for (int i = 1; i <= newlevel; i++) {

		if (newlevel == i) break;
		ExperienceOverall[client] += CheckExperienceRequirement(client, false, i);
	}

	ExperienceOverall[client]++;
	ExperienceLevel[client]++;	// i don't like 0 / level, so i always do 1 / level as the minimum.
	if (giveMaxXP) ExperienceOverall[client] = CheckExperienceRequirement(client, false, iMaxLevel);
	if (oldlevel > PlayerLevel[client]) ChallengeEverything(client);
	else if (PlayerLevel[client] > oldlevel) {
		FreeUpgrades[client] += (PlayerLevel[client] - oldlevel);
	}
}

public Action CMD_ReloadConfigs(client, args) {

	char thetext[64];
	GetConfigValue(thetext, sizeof(thetext), "reload configs flags?");

	if (HasCommandAccess(client, thetext)) {
		CreateTimer(1.0, Timer_ExecuteConfig, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
		PrintToChat(client, "Reloading Config.");
	}
	return Plugin_Handled;
}

public ReadyUp_FirstClientLoaded() {

	//CreateTimer(1.0, Timer_ShowHUD, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
	RefreshSurvivorBots();
	ReadyUpGameMode = ReadyUp_GetGameMode();
}

public Action CMD_SharePoints(client, args) {

	if (args < 2) {

		char thetext[64];
		GetConfigValue(thetext, sizeof(thetext), "reload configs flags?");

		PrintToChat(client, "%T", "Share Points Syntax", client, orange, white, thetext);
		return Plugin_Handled;
	}

	char arg[MAX_NAME_LENGTH];
	char arg2[10];
	GetCmdArg(1, arg, sizeof(arg));
	GetCmdArg(2, arg2, sizeof(arg2));
	float SharePoints = 0.0;
	if (StrContains(arg2, ".", false) == -1) SharePoints = StringToInt(arg2) * 1.0;
	else SharePoints = StringToFloat(arg2);

	if (SharePoints > Points[client]) return Plugin_Handled;

	int targetclient = FindTargetClient(client, arg);
	if (!IsLegitimateClient(targetclient)) return Plugin_Handled;

	char Name[MAX_NAME_LENGTH];
	GetClientName(targetclient, Name, sizeof(Name));
	char GiftName[MAX_NAME_LENGTH];
	GetClientName(client, GiftName, sizeof(GiftName));

	Points[client] -= SharePoints;
	Points[targetclient] += SharePoints;

	PrintToChatAll("%t", "Share Points Given", blue, GiftName, white, green, SharePoints, white, blue, Name); 
	return Plugin_Handled;
}

stock GetMaxHandicap(client) {

	int iMaxHandicap = RatingPerHandicap;
	iMaxHandicap *= CartelLevel(client);
	iMaxHandicap += RatingPerLevel;

	return iMaxHandicap;
}

stock VerifyHandicap(client) {

	int iMaxHandicap = GetMaxHandicap(client);
	int iMinHandicap = RatingPerLevel;

	if (RatingHandicap[client] < iMinHandicap) RatingHandicap[client] = iMinHandicap;
	if (RatingHandicap[client] > iMaxHandicap) RatingHandicap[client] = iMaxHandicap;
}

public Action CMD_Handicap(client, args) {

	if (iIsRatingEnabled != 1) return Plugin_Handled;
	int iMaxHandicap = GetMaxHandicap(client);
	int iMinHandicap = RatingPerLevel;
	if (RatingHandicap[client] < iMinHandicap) RatingHandicap[client] = iMinHandicap;
	if (RatingHandicap[client] > iMaxHandicap) RatingHandicap[client] = iMaxHandicap;
	if (args < 1) {

		PrintToChat(client, "%T", "handicap range", client, white, orange, iMinHandicap, white, orange, iMaxHandicap);
	}
	else {
		if (!bIsHandicapLocked[client]) {
			char arg[10];
			GetCmdArg(1, arg, sizeof(arg));
			int iSetHandicap = StringToInt(arg);
			if (iSetHandicap >= iMinHandicap && iSetHandicap <= iMaxHandicap) {
				RatingHandicap[client] = iSetHandicap;
			}
			else if (iSetHandicap < iMinHandicap) RatingHandicap[client] = iMinHandicap;
			else if (iSetHandicap > iMaxHandicap) RatingHandicap[client] = iMaxHandicap;
		}
		else {
			PrintToChat(client, "%T", "player handicap locked", client, orange);
		}
	}

	PrintToChat(client, "%T", "player handicap", client, blue, orange, green, RatingHandicap[client]);
	return Plugin_Handled;
}

stock SetBotHandicap(client) {
	if (IsLegitimateClient(client) && IsFakeClient(client)) {
		int iLowHandicap = RatingPerLevelSurvivorBots;
		for (int i = 1; i <= MaxClients; i++) {
			if (!IsLegitimateClient(i) || GetClientTeam(i) != TEAM_SURVIVOR) continue;
			if (RatingHandicap[i] > iLowHandicap) iLowHandicap = RatingHandicap[i];
		}
		RatingHandicap[client] = iLowHandicap;
	}
	return RatingHandicap[client];
}

public Action CMD_ActionBar(client, args) {
	if (!DisplayActionBar[client]) {
		PrintToChat(client, "%T", "action bar displayed", client, white, blue);
		DisplayActionBar[client] = true;
	}
	else {
		PrintToChat(client, "%T", "action bar hidden", client, white, orange);
		DisplayActionBar[client] = false;
		ActionBarSlot[client] = -1;
	}
	return Plugin_Handled;
}

public Action CMD_GiveStorePoints(client, args) {
	char thetext[64];
	GetConfigValue(thetext, sizeof(thetext), "give store points flags?");
	if (!HasCommandAccess(client, thetext)) { PrintToChat(client, "You don't have access."); return Plugin_Handled; }
	if (args < 2) {
		PrintToChat(client, "%T", "Give Store Points Syntax", client, orange, white);
		return Plugin_Handled;
	}
	char arg[MAX_NAME_LENGTH];
	char arg2[4];
	GetCmdArg(1, arg, sizeof(arg));
	if (args > 1) {
		GetCmdArg(2, arg2, sizeof(arg2));
	}
	int targetclient = FindTargetClient(client, arg);
	char Name[MAX_NAME_LENGTH];
	GetClientName(targetclient, Name, sizeof(Name));
	SkyPoints[targetclient] += StringToInt(arg2);
	PrintToChat(client, "%T", "Store Points Award Given", client, white, green, arg2, white, orange, Name);
	PrintToChat(targetclient, "%T", "Store Points Award Received", client, white, green, arg2, white);
	return Plugin_Handled;
}

public ReadyUp_CampaignComplete() {
	if (!b_IsCampaignComplete) {
		b_IsCampaignComplete			= true;
		CallRoundIsOver();
		WipeDebuffs(true);
	}
}

public Action CMD_MyWeapon(client, args){
	char myWeapon[64];
	GetWeaponName(client, myWeapon, sizeof(myWeapon));
	PrintToChat(client, "%s", myWeapon);
	return Plugin_Handled;
}
public Action CMD_CollectBonusExperience(client, args) {
	/*if (CurrentMapPosition != 0 && RoundExperienceMultiplier[client] > 0.0 && BonusContainer[client] > 0 && !b_IsActiveRound) {
		new RewardWaiting = RoundToCeil(BonusContainer[client] * RoundExperienceMultiplier[client]);
		ExperienceLevel[client] += RewardWaiting;
		ExperienceOverall[client] += RewardWaiting;
		decl String:Name[64];
		GetClientName(client, Name, sizeof(Name));
		PrintToChatAll("%t", "collected bonus container", blue, Name, white, green, blue, AddCommasToString(RewardWaiting));
		BonusContainer[client] = 0;
		RoundExperienceMultiplier[client] = 0.0;
		ConfirmExperienceAction(client);
	}*/

	return Plugin_Handled;
}

public ReadyUp_RoundIsOver(gamemode) {
	CallRoundIsOver();
}

/*public Action:Timer_SaveAndClear(Handle:timer) {
	new LivingSurvs = TotalHumanSurvivors();
	for (new i = 1; i <= MaxClients; i++) {
		if (!IsLegitimateClient(i)) continue;
		if (GetClientTeam(i) == TEAM_INFECTED && IsFakeClient(i)) continue;	// infected bots are skipped.
		//ToggleTank(i, true);
		if (b_IsMissionFailed && LivingSurvs > 0 && GetClientTeam(i) == TEAM_SURVIVOR) {
			RoundExperienceMultiplier[i] = 0.0;
			// So, the round ends due a failed mission, whether it's coop or survival, and we reset all players ratings.
			VerifyMinimumRating(i, true);
		}
		if(iChaseEnt[i] && EntRefToEntIndex(iChaseEnt[i]) != INVALID_ENT_REFERENCE) AcceptEntityInput(iChaseEnt[i], "Kill");
		iChaseEnt[i] = -1;
		SaveAndClear(i);
	}
	return Plugin_Stop;
}*/

stock CallRoundIsOver() {
	if (!b_IsRoundIsOver) {
		for (int i = 0; i < 5; i++) {
			SetArrayCell(RoundStatistics, i, GetArrayCell(RoundStatistics, i) + GetArrayCell(RoundStatistics, i, 1), 1);
		}
		int pEnt = -1;
		char pText[2][64];
		char text[64];
		int pSize = GetArraySize(persistentCirculation);
		for (int i = 0; i < pSize; i++) {
			GetArrayString(persistentCirculation, i, text, sizeof(text));
			ExplodeString(text, ":", pText, 2, 64);
			pEnt = StringToInt(pText[0]);
			if (IsValidEntity(pEnt)) AcceptEntityInput(pEnt, "Kill");
		}
		ClearArray(persistentCirculation);
		b_IsRoundIsOver					= true;
		for (int i = 1; i <= MaxClients; i++) {
			if (!IsLegitimateClient(i)) continue;
			bTimersRunning[i] = false;
			ClearArray(playerLootOnGround[i]);
			ClearArray(CommonInfected[i]);
		}
		if (b_IsActiveRound) b_IsActiveRound = false;
		SetSurvivorsAliveHostname();
		int Seconds			= GetTime() - RoundTime;
		int Minutes			= 0;
		while (Seconds >= 60) {
			Minutes++;
			Seconds -= 60;
		}
		//common is 0
		//super is 1
		//witch is 2
		//si is 3
		//tank is 4
		char roundStatisticsText[6][64];
		PrintToChatAll("%t", "Round Time", orange, blue, Minutes, white, blue, Seconds, white);
		if (CurrentMapPosition != 1 || ReadyUp_GetGameMode() == 3) {
			AddCommasToString(GetArrayCell(RoundStatistics, 0), roundStatisticsText[0], sizeof(roundStatisticsText[]));
			AddCommasToString(GetArrayCell(RoundStatistics, 1), roundStatisticsText[1], sizeof(roundStatisticsText[]));
			AddCommasToString(GetArrayCell(RoundStatistics, 2), roundStatisticsText[2], sizeof(roundStatisticsText[]));
			AddCommasToString(GetArrayCell(RoundStatistics, 3), roundStatisticsText[3], sizeof(roundStatisticsText[]));
			AddCommasToString(GetArrayCell(RoundStatistics, 4), roundStatisticsText[4], sizeof(roundStatisticsText[]));
			AddCommasToString(GetArrayCell(RoundStatistics, 0) + GetArrayCell(RoundStatistics, 1) + GetArrayCell(RoundStatistics, 2) + GetArrayCell(RoundStatistics, 3) + GetArrayCell(RoundStatistics, 4), roundStatisticsText[5], sizeof(roundStatisticsText[]));

			PrintToChatAll("%t", "round statistics", orange, orange, blue,
							roundStatisticsText[0], orange, blue,
							roundStatisticsText[1], orange, blue,
							roundStatisticsText[2], orange, blue,
							roundStatisticsText[3], orange, blue,
							roundStatisticsText[4], orange, green,
							roundStatisticsText[5], green, green);
		}
		else {
			AddCommasToString(GetArrayCell(RoundStatistics, 0, 1), roundStatisticsText[0], sizeof(roundStatisticsText[]));
			AddCommasToString(GetArrayCell(RoundStatistics, 1, 1), roundStatisticsText[1], sizeof(roundStatisticsText[]));
			AddCommasToString(GetArrayCell(RoundStatistics, 2, 1), roundStatisticsText[2], sizeof(roundStatisticsText[]));
			AddCommasToString(GetArrayCell(RoundStatistics, 3, 1), roundStatisticsText[3], sizeof(roundStatisticsText[]));
			AddCommasToString(GetArrayCell(RoundStatistics, 4, 1), roundStatisticsText[4], sizeof(roundStatisticsText[]));
			AddCommasToString(GetArrayCell(RoundStatistics, 0, 1) + GetArrayCell(RoundStatistics, 1, 1) + GetArrayCell(RoundStatistics, 2, 1) + GetArrayCell(RoundStatistics, 3, 1) + GetArrayCell(RoundStatistics, 4, 1), roundStatisticsText[5], sizeof(roundStatisticsText[]));

			PrintToChatAll("%t", "campaign statistics", orange, orange, blue,
							roundStatisticsText[0], orange, blue,
							roundStatisticsText[1], orange, blue,
							roundStatisticsText[2], orange, blue,
							roundStatisticsText[3], orange, blue,
							roundStatisticsText[4], orange, green,
							roundStatisticsText[5], green, green);
		}
		if (!b_IsMissionFailed) {
			//InfectedLevel = HumanSurvivorLevels();
			if (!IsSurvivalMode) {
				int livingSurvs = LivingSurvivors() - 1;
				float fRoundExperienceBonus = (livingSurvs > 0) ? fCoopSurvBon * livingSurvs : 0.0;
				char pct[4];
				Format(pct, sizeof(pct), "%");
				if (fRoundExperienceBonus > 0.0) PrintToChatAll("%t", "living survivors experience bonus", orange, blue, orange, white, blue, fRoundExperienceBonus * 100.0, white, pct, orange);
				for (int i = 1; i <= MaxClients; i++) {
					if (IsLegitimateClient(i)) {
						ClearArray(WitchDamage[i]);
						ClearArray(InfectedHealth[i]);
						ClearArray(SpecialCommon[i]);
						ImmuneToAllDamage[i] = false;
						iThreatLevel[i] = 0;
						bIsInCombat[i] = false;
						fSlowSpeed[i] = 1.0;
						if (GetClientTeam(i) != TEAM_SURVIVOR) continue;
						if (IsPlayerAlive(i)) {
							if (Rating[i] < 0 && CurrentMapPosition != 1) VerifyMinimumRating(i);
							if (RoundExperienceMultiplier[i] < 0.0) RoundExperienceMultiplier[i] = 0.0;
							if (CurrentMapPosition != 1) {

								if (fRoundExperienceBonus > 0.0) RoundExperienceMultiplier[i] += fRoundExperienceBonus;
								//PrintToChat(i, "xp bonus of %3.3f added : %3.3f bonus", fCoopSurvBon, RoundExperienceMultiplier[i]);
 							}
							//else PrintToChat(i, "no round bonus applied.");
							AwardExperience(i, _, _, true);
						}
					}
				}
				EndOfMapRollLoot();
			}
		}
		int humanSurvivorsInGame = TotalHumanSurvivors();
		// only save data on round end if there is at least 1 human on the survivor team.
		// rounds will constantly loop if the survivor team is all bots.
		if (humanSurvivorsInGame > 0) {
			for (int i = 1; i <= MaxClients; i++) {
				if (!IsLegitimateClient(i)) continue;
				if (GetClientTeam(i) == TEAM_INFECTED && IsFakeClient(i)) continue;	// infected bots are skipped.
				//ToggleTank(i, true);
				if (b_IsMissionFailed) {
					if (GetClientTeam(i) == TEAM_SURVIVOR) {
						RoundExperienceMultiplier[i] = 0.0;
						// So, the round ends due a failed mission, whether it's coop or survival, and we reset all players ratings.
						//VerifyMinimumRating(i, true);
						// reduce player ratings by the amount it would go down if they died, when they lose the round.
						//Rating[i] = RoundToCeil(Rating[i] * (1.0 - fRatingPercentLostOnDeath)) + 1;
					}
					//if(IsValidEntity(iChaseEnt[i]) && iChaseEnt[i] > 0 && EntRefToEntIndex(iChaseEnt[i]) != INVALID_ENT_REFERENCE) AcceptEntityInput(iChaseEnt[i], "Kill");
					//iChaseEnt[i] = -1;
				}
				/*if (iChaseEnt[i] > 0 && IsValidEntity(iChaseEnt[i])) {
					AcceptEntityInput(iChaseEnt[i], "Kill");
					iChaseEnt[i] = -1;
				}*/
				SavePlayerData(i);
			}
		}
		//CreateTimer(1.0, Timer_SaveAndClear, _, TIMER_FLAG_NO_MAPCHANGE);
		b_IsCheckpointDoorStartOpened	= false;
		RemoveImmunities(-1);
		ClearArray(LoggedUsers);		// when a round ends, logged users are removed.
		b_IsActiveRound = false;
		MapRoundsPlayed++;
		ClearArray(WitchList);
		ClearArray(CommonList);
		ClearArray(EntityOnFire);
		ClearArray(EntityOnFireName);
		ClearArray(CommonInfectedQueue);
		ClearArray(SuperCommonQueue);
		ClearArray(StaggeredTargets);
		ClearArray(SpecialAmmoData);
		ClearArray(CommonAffixes);
		ClearArray(EffectOverTime);
		ClearArray(TimeOfEffectOverTime);
		if (b_IsMissionFailed && StrContains(TheCurrentMap, "zerowarn", false) != -1) {
			PrintToChatAll("\x04Due to VScripts issue, this map must be restarted to prevent a server crash.");
			LogMessage("Restarting %s map to avoid VScripts crash.", TheCurrentMap);
			// need to force-teleport players here on new spawn: 4087.998291 11974.557617 -269.968750
			CreateTimer(5.0, Timer_ResetMap, _, TIMER_FLAG_NO_MAPCHANGE);
		}
		else if (StrContains(TheCurrentMap, "helms", false) != -1) {
			PrintToChatAll("\x04Due to VScripts issue, this map must be restarted to prevent a server crash...");
			CreateTimer(3.0, Timer_ResetMap, _, TIMER_FLAG_NO_MAPCHANGE);
		}
	}
}

// we need to check the zombie class since the way I create special infected, they have the same team as survivors.
// bool IsValidZombieClass(client) {	// 9 for survivor
// 	int zombieclass = GetEntProp(client, Prop_Send, "m_zombieClass");
// 	if (zombieclass >= 1 && zombieclass <= 8) return true;
// 	return false;
// }

public Action Timer_ResetMap(Handle timer) {
	//if (StrContains(TheCurrentMap, "helms", false) != -1) L4D_RestartScenarioFromVote(TheCurrentMap);
	if (StrContains(TheCurrentMap, "helms", false) != -1) ServerCommand("changelevel %s", TheCurrentMap);
	return Plugin_Stop;
}

stock ResetArray(Handle TheArray) {

	ClearArray(TheArray);
}

public ReadyUp_ParseConfigFailed(char[] config, char[] error) {

	if (StrEqual(config, CONFIG_MAIN) ||
		StrEqual(config, CONFIG_EVENTS) ||
		StrEqual(config, CONFIG_MENUTALENTS) ||
		StrEqual(config, CONFIG_MAINMENU) ||
		StrEqual(config, CONFIG_POINTS) ||
		StrEqual(config, CONFIG_STORE) ||
		StrEqual(config, CONFIG_TRAILS) ||
		StrEqual(config, CONFIG_WEAPONS) ||
		StrEqual(config, CONFIG_PETS) ||
		StrEqual(config, CONFIG_COMMONAFFIXES)) {// ||
		//StrEqual(config, CONFIG_CLASSNAMES)) {

		SetFailState("%s , %s", config, error);
	}
}

stock RegisterConsoleCommands() {
	char thetext[64];
	if (!b_IsFirstPluginLoad) {
		b_IsFirstPluginLoad = true;
		LoadMainConfig();
		if (hDatabase == INVALID_HANDLE) {
			MySQL_Init();
		}
		
		RegConsoleCmd("getwep", CMD_GetWeapon);
		GetConfigValue(RPGMenuCommand, sizeof(RPGMenuCommand), "rpg menu command?");
		RPGMenuCommandExplode = GetDelimiterCount(RPGMenuCommand, ",") + 1;
		GetConfigValue(thetext, sizeof(thetext), "drop weapon command?");
		RegConsoleCmd(thetext, CMD_DropWeapon);
		GetConfigValue(thetext, sizeof(thetext), "director talent command?");
		RegConsoleCmd(thetext, CMD_DirectorTalentToggle);
		GetConfigValue(thetext, sizeof(thetext), "rpg data erase?");
		RegConsoleCmd(thetext, CMD_DataErase);
		GetConfigValue(thetext, sizeof(thetext), "rpg bot data erase?");
		RegConsoleCmd(thetext, CMD_DataEraseBot);
		//GetConfigValue(thetext, sizeof(thetext), "give store points command?");
		//RegConsoleCmd(thetext, CMD_GiveStorePoints);
		GetConfigValue(thetext, sizeof(thetext), "give level command?");
		RegConsoleCmd(thetext, CMD_GiveLevel);
		GetConfigValue(thetext, sizeof(thetext), "share points command?");
		RegConsoleCmd(thetext, CMD_SharePoints);
		GetConfigValue(thetext, sizeof(thetext), "buy menu command?");
		RegConsoleCmd(thetext, CMD_BuyMenu);
		GetConfigValue(thetext, sizeof(thetext), "abilitybar menu command?");
		RegConsoleCmd(thetext, CMD_ActionBar);
		//RegConsoleCmd("collect", CMD_CollectBonusExperience);
		RegConsoleCmd("myweapon", CMD_MyWeapon);
		GetConfigValue(thetext, sizeof(thetext), "companion command?");
		RegConsoleCmd(thetext, CMD_CompanionOptions);
		GetConfigValue(thetext, sizeof(thetext), "load profile command?");
		RegConsoleCmd(thetext, CMD_LoadProfileEx);
		//RegConsoleCmd("backpack", CMD_Backpack);
		//etConfigValue(thetext, sizeof(thetext), "rpg data force save?");
		//RegConsoleCmd(thetext, CMD_SaveData);
	}
	ReadyUp_NtvGetHeader();
	GetConfigValue(thetext, sizeof(thetext), "item drop model?");
	PrecacheModel(thetext, true);
	GetConfigValue(thetext, sizeof(thetext), "backpack model?");
	PrecacheModel(thetext, true);
}

public ReadyUp_LoadFromConfigEx(Handle key, Handle value, Handle section, char[] configname, keyCount) {
	//PrintToChatAll("Size: %d config: %s", GetArraySize(Handle:key), configname);
	if (!StrEqual(configname, CONFIG_MAIN) &&
		!StrEqual(configname, CONFIG_EVENTS) &&
		!StrEqual(configname, CONFIG_MENUTALENTS) &&
		!StrEqual(configname, CONFIG_MAINMENU) &&
		!StrEqual(configname, CONFIG_POINTS) &&
		!StrEqual(configname, CONFIG_STORE) &&
		!StrEqual(configname, CONFIG_TRAILS) &&
		!StrEqual(configname, CONFIG_WEAPONS) &&
		!StrEqual(configname, CONFIG_PETS) &&
		!StrEqual(configname, CONFIG_COMMONAFFIXES)) return;// &&
		//!StrEqual(configname, CONFIG_CLASSNAMES)) return;
	char s_key[64];
	char s_value[64];
	char s_section[64];
	if (StrEqual(configname, CONFIG_MAIN)) {
		int a_Size						= GetArraySize(key);
		for (int i = 0; i < a_Size; i++) {
			GetArrayString(key, i, s_key, sizeof(s_key));
			GetArrayString(value, i, s_value, sizeof(s_value));
			//LogMessage("\"%s\"\t\t\t\"%s\"", s_key, s_value);
			PushArrayString(MainKeys, s_key);
			PushArrayString(MainValues, s_value);
			//LogMessage("\"%s\"\t\t\t\t\"%s\"", s_key, s_value);
			if (StrEqual(s_key, "rpg mode?")) {
				CurrentRPGMode = StringToInt(s_value);
				LogMessage("=====\t\tRPG MODE SET TO %d\t\t=====", CurrentRPGMode);
			}
		}
		RegisterConsoleCommands();
		return;
	}
	Handle TalentKeys		=					CreateArray(32);
	Handle TalentValues		=					CreateArray(32);
	Handle TalentSection	=					CreateArray(32);
	int lastPosition = 0;
	int counter = 0;
	if (keyCount > 0) {
		if (StrEqual(configname, CONFIG_MENUTALENTS)) ResizeArray(a_Menu_Talents, keyCount);
		else if (StrEqual(configname, CONFIG_MAINMENU)) ResizeArray(a_Menu_Main, keyCount);
		else if (StrEqual(configname, CONFIG_EVENTS)) ResizeArray(a_Events, keyCount);
		else if (StrEqual(configname, CONFIG_POINTS)) ResizeArray(a_Points, keyCount);
		else if (StrEqual(configname, CONFIG_PETS)) ResizeArray(a_Pets, keyCount);
		else if (StrEqual(configname, CONFIG_STORE)) ResizeArray(a_Store, keyCount);
		else if (StrEqual(configname, CONFIG_TRAILS)) ResizeArray(a_Trails, keyCount);
		else if (StrEqual(configname, CONFIG_WEAPONS)) ResizeArray(a_WeaponDamages, keyCount);
		else if (StrEqual(configname, CONFIG_COMMONAFFIXES)) ResizeArray(a_CommonAffixes, keyCount);
		//else if (StrEqual(configname, CONFIG_CLASSNAMES)) ResizeArray(a_Classnames, keyCount);
	}
	int a_Size						= GetArraySize(key);
	for (int i = 0; i < a_Size; i++) {
		GetArrayString(key, i, s_key, sizeof(s_key));
		GetArrayString(value, i, s_value, sizeof(s_value));
		//LogMessage("\"%s\"\t\t\t\"%s\"", s_key, s_value);
		PushArrayString(TalentKeys, s_key);
		PushArrayString(TalentValues, s_value);
		if (StrEqual(s_key, "EOM")) {

			GetArrayString(section, i, s_section, sizeof(s_section));
			PushArrayString(TalentSection, s_section);

			if (StrEqual(configname, CONFIG_MENUTALENTS)) SetConfigArrays(configname, a_Menu_Talents, TalentKeys, TalentValues, TalentSection, GetArraySize(a_Menu_Talents), lastPosition - counter);
			else if (StrEqual(configname, CONFIG_MAINMENU)) SetConfigArrays(configname, a_Menu_Main, TalentKeys, TalentValues, TalentSection, GetArraySize(a_Menu_Main), lastPosition - counter);
			else if (StrEqual(configname, CONFIG_EVENTS)) SetConfigArrays(configname, a_Events, TalentKeys, TalentValues, TalentSection, GetArraySize(a_Events), lastPosition - counter);
			else if (StrEqual(configname, CONFIG_POINTS)) SetConfigArrays(configname, a_Points, TalentKeys, TalentValues, TalentSection, GetArraySize(a_Points), lastPosition - counter);
			else if (StrEqual(configname, CONFIG_PETS)) SetConfigArrays(configname, a_Pets, TalentKeys, TalentValues, TalentSection, GetArraySize(a_Pets), lastPosition - counter);
			else if (StrEqual(configname, CONFIG_STORE)) SetConfigArrays(configname, a_Store, TalentKeys, TalentValues, TalentSection, GetArraySize(a_Store), lastPosition - counter);
			else if (StrEqual(configname, CONFIG_TRAILS)) SetConfigArrays(configname, a_Trails, TalentKeys, TalentValues, TalentSection, GetArraySize(a_Trails), lastPosition - counter);
			else if (StrEqual(configname, CONFIG_WEAPONS)) SetConfigArrays(configname, a_WeaponDamages, TalentKeys, TalentValues, TalentSection, GetArraySize(a_WeaponDamages), lastPosition - counter);
			else if (StrEqual(configname, CONFIG_COMMONAFFIXES)) SetConfigArrays(configname, a_CommonAffixes, TalentKeys, TalentValues, TalentSection, GetArraySize(a_CommonAffixes), lastPosition - counter);
			//else if (StrEqual(configname, CONFIG_CLASSNAMES)) SetConfigArrays(configname, a_Classnames, TalentKeys, TalentValues, TalentSection, GetArraySize(a_Classnames), lastPosition - counter);
			
			lastPosition = i + 1;
		}
	}
	//CloseHandle(TalentKeys);
	//CloseHandle(TalentValues);
	//CloseHandle(TalentSection);

	if (StrEqual(configname, CONFIG_POINTS)) {
		if (a_DirectorActions != INVALID_HANDLE) ClearArray(a_DirectorActions);
		a_DirectorActions			=	CreateArray(3);
		if (a_DirectorActions_Cooldown != INVALID_HANDLE) ClearArray(a_DirectorActions_Cooldown);
		a_DirectorActions_Cooldown	=	CreateArray(32);
		int size						=	GetArraySize(a_Points);
		Handle Keys					=	CreateArray(32);
		Handle Values				=	CreateArray(32);
		Handle Section				=	CreateArray(32);
		int sizer						=	0;
		for (int i = 0; i < size; i++) {
			Keys						=	GetArrayCell(a_Points, i, 0);
			Values						=	GetArrayCell(a_Points, i, 1);
			Section						=	GetArrayCell(a_Points, i, 2);
			int size2					=	GetArraySize(Keys);
			for (int ii = 0; ii < size2; ii++) {
				GetArrayString(Keys, ii, s_key, sizeof(s_key));
				GetArrayString(Values, ii, s_value, sizeof(s_value));
				if (StrEqual(s_key, "model?")) PrecacheModel(s_value, false);
				else if (StrEqual(s_key, "director option?") && StrEqual(s_value, "1")) {
					sizer				=	GetArraySize(a_DirectorActions);
					ResizeArray(a_DirectorActions, sizer + 1);
					SetArrayCell(a_DirectorActions, sizer, Keys, 0);
					SetArrayCell(a_DirectorActions, sizer, Values, 1);
					SetArrayCell(a_DirectorActions, sizer, Section, 2);
					ResizeArray(a_DirectorActions_Cooldown, sizer + 1);
					SetArrayString(a_DirectorActions_Cooldown, sizer, "0");						// 0 means not on cooldown. 1 means on cooldown. This resets every map.
				}
			}
		}
		/*
		CloseHandle(Keys);
		CloseHandle(Values);
		CloseHandle(Section);*/
		// We only attempt connection to the database in the instance that there are no open connections.
		//if (hDatabase == INVALID_HANDLE) {
		//	MySQL_Init();
		//}
	}
	if (StrEqual(configname, CONFIG_EVENTS)) SubmitEventHooks(1);
	ReadyUp_NtvGetHeader();
	/*

		We need to preload an array full of all the positions of item drops.
		Faster than searching every time.
	*/
	if (StrEqual(configname, CONFIG_MENUTALENTS)) {
		ClearArray(ItemDropArray);
		int mySize = GetArraySize(a_Menu_Talents);
		int curSize= -1;
		int pos = 0;
		for (int i = 0; i <= iRarityMax; i++) {
			for (int j = 0; j < mySize; j++) {
				//PreloadKeys				= GetArrayCell(a_Menu_Talents, j, 0);
				PreloadValues			= GetArrayCell(a_Menu_Talents, j, 1);
				if (GetArrayCell(PreloadValues, ITEM_ITEM_ID) != 1) continue;
				//PushArrayCell(ItemDropArray, i);
				if (GetArrayCell(PreloadValues, ITEM_RARITY) != i) continue;
				curSize = GetArraySize(ItemDropArray);
				if (pos == curSize) ResizeArray(ItemDropArray, curSize + 1);
				SetArrayCell(ItemDropArray, pos, j, i);
				pos++;
			}
			if (i == 0) Format(ItemDropArraySize, sizeof(ItemDropArraySize), "%d", pos);
			else Format(ItemDropArraySize, sizeof(ItemDropArraySize), "%s,%d", ItemDropArraySize, pos);
			pos = 0;
		}
	}
}
/*
	These specific variables can be called the same way, every time, so we declare them globally.
	These are all from the config.cfg (main config file)
	We don't load other variables in this way because they are dynamically loaded and unloaded.
*/
stock LoadMainConfig() {
	GetConfigValue(sServerDifficulty, sizeof(sServerDifficulty), "server difficulty?");
	CheckDifficulty();
	iClientTypeToDisplayOnKill			= GetConfigValueInt("infected kill messages to display?", 0);
	fProficiencyExperienceMultiplier 	= GetConfigValueFloat("proficiency requirement multiplier?");
	fProficiencyExperienceEarned 		= GetConfigValueFloat("experience multiplier proficiency?");
	fRatingPercentLostOnDeath			= GetConfigValueFloat("rating percentage lost on death?");
	//iProficiencyMaxLevel				= GetConfigValueInt("proficience level max?");
	iProficiencyStart					= GetConfigValueInt("proficiency level start?");
	iTeamRatingRequired					= GetConfigValueInt("team count rating bonus?");
	fTeamRatingBonus					= GetConfigValueFloat("team player rating bonus?");
	iTanksPreset						= GetConfigValueInt("preset tank type on spawn?");
	iSurvivorRespawnRestrict			= GetConfigValueInt("respawn queue players ignored?");
	iIsRatingEnabled					= GetConfigValueInt("handicap enabled?");
	iIsSpecialFire						= GetConfigValueInt("special infected fire?");
	iSkyLevelMax						= GetConfigValueInt("max sky level?");
	//iOnFireDebuffLimit				= GetConfigValueInt("standing in fire debuff limit?");
	fOnFireDebuffDelay					= GetConfigValueFloat("standing in fire debuff delay?");
	//fTankThreatBonus					= GetConfigValueFloat("tank threat bonus?");
	forceProfileOnNewPlayers			= GetConfigValueInt("Force Profile On New Player?");
	iShowLockedTalents					= GetConfigValueInt("show locked talents?");
	iAwardBroadcast						= GetConfigValueInt("award broadcast?");
	GetConfigValue(loadProfileOverrideFlags, sizeof(loadProfileOverrideFlags), "profile override flags?");
	GetConfigValue(sSpecialsAllowed, sizeof(sSpecialsAllowed), "special infected classes?");
	iSpecialsAllowed					= GetConfigValueInt("special infected allowed?");
	iSpecialInfectedMinimum				= GetConfigValueInt("special infected minimum?");
	fEnrageMultiplier					= GetConfigValueFloat("enrage multiplier?");
	iRestedDonator						= GetConfigValueInt("rested experience earned donator?");
	iRestedRegular						= GetConfigValueInt("rested experience earned non-donator?");
	iRestedSecondsRequired				= GetConfigValueInt("rested experience required seconds?");
	iRestedMaximum						= GetConfigValueInt("rested experience maximum?");
	iFriendlyFire						= GetConfigValueInt("friendly fire enabled?");
	GetConfigValue(sDonatorFlags, sizeof(sDonatorFlags), "donator package flag?");
	GetConfigValue(sProfileLoadoutConfig, sizeof(sProfileLoadoutConfig), "profile loadout config?");
	iHardcoreMode						= GetConfigValueInt("hardcore mode?");
	fDeathPenalty						= GetConfigValueFloat("death penalty?");
	iDeathPenaltyPlayers				= GetConfigValueInt("death penalty players required?");
	iTankRush							= GetConfigValueInt("tank rush?");
	iTanksAlways						= GetConfigValueInt("tanks always active?");
	iTanksAlwaysEnforceCooldown 		= GetConfigValueInt("tanks always enforce cooldown?");
	fSprintSpeed						= GetConfigValueFloat("sprint speed?");
	iRPGMode							= GetConfigValueInt("rpg mode?");
	DirectorWitchLimit					= GetConfigValueInt("director witch limit?");
	fCommonQueueLimit					= GetConfigValueFloat("common queue limit?");
	fDirectorThoughtDelay				= GetConfigValueFloat("director thought process delay?");
	fDirectorThoughtHandicap			= GetConfigValueFloat("director thought process handicap?");
	fDirectorThoughtProcessMinimum		= GetConfigValueFloat("director thought process minimum?");
	iSurvivalRoundTime					= GetConfigValueInt("survival round time?");
	fDazedDebuffEffect					= GetConfigValueFloat("dazed debuff effect?");
	ConsumptionInt						= GetConfigValueInt("stamina consumption interval?");
	fStamSprintInterval					= GetConfigValueFloat("stamina sprint interval?");
	fStamRegenTime						= GetConfigValueFloat("stamina regeneration time?");
	fStamRegenTimeAdren					= GetConfigValueFloat("stamina regeneration time adren?");
	fBaseMovementSpeed					= GetConfigValueFloat("base movement speed?");
	//fFatigueMovementSpeed				= GetConfigValueFloat("fatigue movement speed?");
	iPlayerStartingLevel				= GetConfigValueInt("new player starting level?");
	iBotPlayerStartingLevel				= GetConfigValueInt("new bot player starting level?");
	fOutOfCombatTime					= GetConfigValueFloat("out of combat time?");
	iWitchDamageInitial					= GetConfigValueInt("witch damage initial?");
	fWitchDamageScaleLevel				= GetConfigValueFloat("witch damage scale level?");
	fSurvivorDamageBonus				= GetConfigValueFloat("survivor damage bonus?");
	fSurvivorHealthBonus				= GetConfigValueFloat("survivor health bonus?");
	iSurvivorModifierRequired			= GetConfigValueInt("survivor modifier requirement?");
	iEnrageTime							= GetConfigValueInt("enrage time?");
	fWitchDirectorPoints				= GetConfigValueFloat("witch director points?");
	fEnrageDirectorPoints				= GetConfigValueFloat("enrage director points?");
	fCommonDamageLevel					= GetConfigValueFloat("common damage scale level?");
	iBotLevelType						= GetConfigValueInt("infected bot level type?");
	fCommonDirectorPoints				= GetConfigValueFloat("common infected director points?");
	iDisplayHealthBars					= GetConfigValueInt("display health bars?");
	iMaxDifficultyLevel					= GetConfigValueInt("max difficulty level?");
	scoreRequiredForLeaderboard			= GetConfigValueInt("player score required for leaderboard?");
	char text[64];
	char text2[64];
	char text3[64];
	char text4[64];
	for (int i = 0; i < 7; i++) {
		if (i == 6) {
			Format(text, sizeof(text), "(%d) damage player level?", i + 2);
			Format(text2, sizeof(text2), "(%d) infected health bonus", i + 2);
			Format(text3, sizeof(text3), "(%d) base damage?", i + 2);
			Format(text4, sizeof(text4), "(%d) base infected health?", i + 2);
		}
		else {
			Format(text, sizeof(text), "(%d) damage player level?", i + 1);
			Format(text2, sizeof(text2), "(%d) infected health bonus", i + 1);
			Format(text3, sizeof(text3), "(%d) base damage?", i + 1);
			Format(text4, sizeof(text4), "(%d) base infected health?", i + 1);
		}
		fDamagePlayerLevel[i]			= GetConfigValueFloat(text);
		fHealthPlayerLevel[i]			= GetConfigValueFloat(text2);
		iBaseSpecialDamage[i]			= GetConfigValueInt(text3);
		iBaseSpecialInfectedHealth[i]	= GetConfigValueInt(text4);
	}
	fAcidDamagePlayerLevel				= GetConfigValueFloat("acid damage spitter player level?");
	fAcidDamageSupersPlayerLevel		= GetConfigValueFloat("acid damage supers player level?");
	fPointsMultiplierInfected			= GetConfigValueFloat("points multiplier infected?");
	fPointsMultiplier					= GetConfigValueFloat("points multiplier survivor?");
	SurvivorExperienceMult				= GetConfigValueFloat("experience multiplier survivor?");
	SurvivorExperienceMultTank			= GetConfigValueFloat("experience multiplier tanking?");
	fHealingMultiplier					= GetConfigValueFloat("experience multiplier healing?");
	fBuffingMultiplier					= GetConfigValueFloat("experience multiplier buffing?");
	fHexingMultiplier					= GetConfigValueFloat("experience multiplier hexing?");
	TanksNearbyRange					= GetConfigValueFloat("tank nearby ability deactivate?");
	iCommonAffixes						= GetConfigValueInt("common affixes?");
	BroadcastType						= GetConfigValueInt("hint text type?");
	iDoomTimer							= GetConfigValueInt("doom kill timer?");
	iSurvivorStaminaMax					= GetConfigValueInt("survivor stamina?");
	fRatingMultSpecials					= GetConfigValueFloat("rating multiplier specials?");
	fRatingMultSupers					= GetConfigValueFloat("rating multiplier supers?");
	fRatingMultCommons					= GetConfigValueFloat("rating multiplier commons?");
	fRatingMultTank						= GetConfigValueFloat("rating multiplier tank?");
	fRatingMultWitch					= GetConfigValueFloat("rating multiplier witch?");
	fTeamworkExperience					= GetConfigValueInt("maximum teamwork experience?") * 1.0;
	fItemMultiplierLuck					= GetConfigValueFloat("buy item luck multiplier?");
	fItemMultiplierTeam					= GetConfigValueInt("buy teammate item multiplier?") * 1.0;
	GetConfigValue(sQuickBindHelp, sizeof(sQuickBindHelp), "quick bind help?");
	fPointsCostLevel					= GetConfigValueFloat("points cost increase per level?");
	PointPurchaseType					= GetConfigValueInt("points purchase type?");
	iTankLimitVersus					= GetConfigValueInt("versus tank limit?");
	fHealRequirementTeam				= GetConfigValueFloat("teammate heal health requirement?");
	iSurvivorBaseHealth					= GetConfigValueInt("survivor health?");
	iSurvivorBotBaseHealth				= GetConfigValueInt("survivor bot health?");
	GetConfigValue(spmn, sizeof(spmn), "sky points menu name?");
	fHealthSurvivorRevive				= GetConfigValueFloat("survivor revive health?");
	GetConfigValue(RestrictedWeapons, sizeof(RestrictedWeapons), "restricted weapons?");
	iMaxLevel							= GetConfigValueInt("max level?");
	iExperienceStart					= GetConfigValueInt("experience start?");
	fExperienceMultiplier				= GetConfigValueFloat("requirement multiplier?");
	GetConfigValue(sBotTeam, sizeof(sBotTeam), "survivor team?");
	iActionBarSlots						= GetConfigValueInt("action bar slots?");
	iNumAugments						= GetConfigValueInt("augment slots?", 3);
	GetConfigValue(MenuCommand, sizeof(MenuCommand), "rpg menu command?");
	ReplaceString(MenuCommand, sizeof(MenuCommand), ",", " or ", true);
	HostNameTime						= GetConfigValueInt("display server name time?");
	DoomSUrvivorsRequired				= GetConfigValueInt("doom survivors ignored?");
	DoomKillTimer						= GetConfigValueInt("doom kill timer?");
	fVersusTankNotice					= GetConfigValueFloat("versus tank notice?");
	AllowedCommons						= GetConfigValueInt("common limit base?");
	AllowedMegaMob						= GetConfigValueInt("mega mob limit base?");
	AllowedMobSpawn						= GetConfigValueInt("mob limit base?");
	AllowedMobSpawnFinale				= GetConfigValueInt("mob finale limit base?");
	//AllowedPanicInterval				= GetConfigValueInt("mega mob max interval base?");
	RespawnQueue						= GetConfigValueInt("survivor respawn queue?");
	MaximumPriority						= GetConfigValueInt("director priority maximum?");
	fUpgradeExpCost						= GetConfigValueFloat("upgrade experience cost?");
	iHandicapLevelDifference			= GetConfigValueInt("handicap level difference required?");
	iWitchHealthBase					= GetConfigValueInt("base witch health?");
	fWitchHealthMult					= GetConfigValueFloat("level witch multiplier?");
	iCommonBaseHealth					= GetConfigValueInt("common base health?");
	fCommonLevelHealthMult				= GetConfigValueFloat("common level health?");
	iRoundStartWeakness					= GetConfigValueInt("weakness on round start?");
	GroupMemberBonus					= GetConfigValueFloat("steamgroup bonus?");
	RaidLevMult							= GetConfigValueInt("raid level multiplier?");
	iIgnoredRating						= GetConfigValueInt("rating to ignore?");
	iIgnoredRatingMax					= GetConfigValueInt("max rating to ignore?");
	iInfectedLimit						= GetConfigValueInt("ensnare infected limit?");
	TheScorchMult						= GetConfigValueFloat("scorch multiplier?");
	TheInfernoMult						= GetConfigValueFloat("inferno multiplier?");
	fAmmoHighlightTime					= GetConfigValueFloat("special ammo highlight time?");
	fAdrenProgressMult					= GetConfigValueFloat("adrenaline progress multiplier?");
	DirectorTankCooldown				= GetConfigValueFloat("director tank cooldown?");
	DisplayType							= GetConfigValueInt("survivor reward display?");
	GetConfigValue(sDirectorTeam, sizeof(sDirectorTeam), "director team name?");
	fRestedExpMult						= GetConfigValueFloat("rested experience multiplier?");
	fSurvivorExpMult					= GetConfigValueFloat("survivor experience bonus?");
	iDebuffLimit						= GetConfigValueInt("debuff limit?");
	iRatingSpecialsRequired				= GetConfigValueInt("specials rating required?");
	iRatingTanksRequired				= GetConfigValueInt("tank rating required?");
	GetConfigValue(sDbLeaderboards, sizeof(sDbLeaderboards), "db record?");
	iIsLifelink							= GetConfigValueInt("lifelink enabled?");
	RatingPerHandicap					= GetConfigValueInt("rating level handicap?");
	GetConfigValue(sItemModel, sizeof(sItemModel), "item drop model?");
	iRarityMax							= GetConfigValueInt("item rarity max?");
	iEnrageAdvertisement				= GetConfigValueInt("enrage advertise time?");
	iNotifyEnrage						= GetConfigValueInt("enrage notification?");
	iJoinGroupAdvertisement				= GetConfigValueInt("join group advertise time?");
	GetConfigValue(sBackpackModel, sizeof(sBackpackModel), "backpack model?");
	GetConfigValue(sCategoriesToIgnore, sizeof(sCategoriesToIgnore), "talent categories to skip for loot?");
	iSurvivorGroupMinimum				= GetConfigValueInt("group member minimum?");
	fBurnPercentage						= GetConfigValueFloat("burn debuff percentage?");
	fSuperCommonLimit					= GetConfigValueFloat("super common limit?");
	iCommonsLimitUpper					= GetConfigValueInt("commons limit max?");
	FinSurvBon							= GetConfigValueFloat("finale survival bonus?");
	fCoopSurvBon 						= GetConfigValueFloat("coop round survival bonus?");
	iMaxIncap							= GetConfigValueInt("survivor max incap?");
	iMaxLayers							= GetConfigValueInt("max talent layers?");
	iCommonInfectedBaseDamage			= GetConfigValueInt("common infected base damage?");
	iShowTotalNodesOnTalentTree			= GetConfigValueInt("show upgrade maximum by nodes?");
	fDrawHudInterval					= GetConfigValueFloat("hud display tick rate?");
	fSpecialAmmoInterval				= GetConfigValueFloat("special ammo tick rate?");
	//fEffectOverTimeInterval				= GetConfigValueFloat("effect over time tick rate?");
	//fStaggerTime						= GetConfigValueFloat("stagger debuff time?");
	fStaggerTickrate					= GetConfigValueFloat("stagger tickrate?");
	fRatingFloor						= GetConfigValueFloat("rating floor?");
	iExperienceDebtLevel				= GetConfigValueInt("experience debt level?");
	iExperienceDebtEnabled				= GetConfigValueInt("experience debt enabled?");
	fExperienceDebtPenalty				= GetConfigValueFloat("experience debt penalty?");
	iShowDamageOnActionBar				= GetConfigValueInt("show damage on action bar?");
	iDefaultIncapHealth					= GetConfigValueInt("default incap health?");
	iSkyLevelNodeUnlocks				= GetConfigValueInt("sky level default node unlocks?");
	iCanSurvivorBotsBurn				= GetConfigValueInt("survivor bots debuffs allowed?");
	iSurvivorBotsAreImmuneToFireDamage	= GetConfigValueInt("survivor bots immune to fire damage?", 1);	// we make survivor bots immune to fire damage by default.
	//iDeleteCommonsFromExistenceOnDeath	= GetConfigValueInt("delete commons from existence on death?");
	iShowDetailedDisplayAlways			= GetConfigValueInt("show detailed display to survivors always?");
	iCanJetpackWhenInCombat				= GetConfigValueInt("can players jetpack when in combat?");
	fquickScopeTime						= GetConfigValueFloat("delay after zoom for quick scope kill?");
	iEnsnareLevelMultiplier				= GetConfigValueInt("ensnare level multiplier?");
	iNoSpecials							= GetConfigValueInt("disable non boss special infected?");
	fSurvivorBotsNoneBonus				= GetConfigValueFloat("group bonus if no survivor bots?");
	iSurvivorBotsBonusLimit				= GetConfigValueInt("no survivor bots group bonus requirement?");
	iShowAdvertToNonSteamgroupMembers	= GetConfigValueInt("show advertisement to non-steamgroup members?");
	iStrengthOnSpawnIsStrength			= GetConfigValueInt("spells,auras,ammos strength set on spawn?");
	iHealingPlayerInCombatPutInCombat	= GetConfigValueInt("healing a player in combat places you in combat?");
	iPlayersLeaveCombatDuringFinales	= GetConfigValueInt("do players leave combat during finales?");
	iAllowPauseLeveling					= GetConfigValueInt("let players pause their leveling?");
	fMaxDamageResistance				= GetConfigValueFloat("max damage resistance?", 0.99);
	fStaminaPerPlayerLevel				= GetConfigValueFloat("stamina increase per player level?");
	fStaminaPerSkyLevel					= GetConfigValueFloat("stamina increase per prestige level?");
	iEndRoundIfNoHealthySurvivors		= GetConfigValueInt("end round if all survivors are incapped?");
	iEndRoundIfNoLivingHumanSurvivors	= GetConfigValueInt("end round if no living human survivors?", 1);
	fTankMovementSpeed_Burning			= GetConfigValueFloat("fire tank movement speed?", 1.0);	// if this key is omitted, a default value is set. these MUST be > 0.0, so the default is hard-coded.
	fTankMovementSpeed_Hulk				= GetConfigValueFloat("hulk tank movement speed?", 0.75);
	fTankMovementSpeed_Death			= GetConfigValueFloat("death tank movement speed?", 0.5);
	iResetPlayerLevelOnDeath			= GetConfigValueInt("reset player level on death?");
	iStartingPlayerUpgrades				= GetConfigValueInt("new player starting upgrades?", 0);
	leaderboardPageCount				= GetConfigValueInt("leaderboard players per page?", 5);
	fForceTankJumpHeight				= GetConfigValueFloat("force tank to jump power?", 500.0);
	fForceTankJumpRange					= GetConfigValueFloat("force tank to jump range?", 256.0);
	iResetDirectorPointsOnNewRound		= GetConfigValueInt("reset director points every round?", 1);
	iMaxServerUpgrades					= GetConfigValueInt("max upgrades allowed?");
	iExperienceLevelCap					= GetConfigValueInt("player level to stop earning experience?", 0);
	//iDeleteSupersOnDeath				= GetConfigValueInt("delete super commons on death?", 1);
	//iShoveStaminaCost					= GetConfigValueInt("shove stamina cost?", 10);
	iLootEnabled						= GetConfigValueInt("loot system enabled?", 1);
	fLootChanceTank						= GetConfigValueFloat("loot chance tank?", 1.0);
	fLootChanceWitch					= GetConfigValueFloat("loot chance witch?", 0.5);
	fLootChanceSpecials					= GetConfigValueFloat("loot chance specials?", 0.1);
	fLootChanceSupers					= GetConfigValueFloat("loot chance supers?", 0.01);
	fLootChanceCommons					= GetConfigValueFloat("loot chance commons?", 0.001);
	fUpgradesRequiredPerLayer			= GetConfigValueFloat("layer upgrades required?", 0.3);
	iEnsnareRestrictions				= GetConfigValueInt("ensnare restrictions?", 1);
	iDontStoreInfectedInArray			= GetConfigValueInt("dont store infected in array?", 1);
	fTeleportTankHeightDistance			= GetConfigValueFloat("teleport tank height distance?", 512.0);
	fSurvivorBufferBonus				= GetConfigValueFloat("common buffers survivors effect?", 2.0);
	iCommonInfectedSpawnDelayOnNewRound	= GetConfigValueInt("new round spawn common delay?", 30);
	iHideEnrageTimerUntilSecondsLeft	= GetConfigValueInt("hide enrage timer until seconds left?", iEnrageTime/3);
	showNumLivingSurvivorsInHostname	= GetConfigValueInt("show living survivors in hostname?", 0);
	iUpgradesRequiredForLoot			= GetConfigValueInt("assigned upgrades required for loot?", 5);
	iUseLinearLeveling					= GetConfigValueInt("experience requirements are linear?", 0);
	iUniqueServerCode					= GetConfigValueInt("unique server code?", 10);
	iAugmentLevelDivisor				= GetConfigValueInt("augment level divisor?", 1000);
	fAugmentRatingMultiplier			= GetConfigValueFloat("augment bonus rating multiplier?", 0.00001);
	iRatingRequiredForAugmentLootDrops	= GetConfigValueInt("rating required for augment drops?", 30000);
	fAugmentTierChance					= GetConfigValueFloat("augment tier chance?", 0.5);
	fAntiFarmDistance					= GetConfigValueFloat("anti farm kill distance?");
	iAntiFarmMax						= GetConfigValueInt("anti farm kill max locations?");
	iNumOfEndMapLootRolls				= GetConfigValueInt("number of end of map rolls?", 1);
	iAllPlayersEndMapLootRolls			= GetConfigValueInt("all players end of map rolls?", 0);
	fEndMapLootRollsChance				= GetConfigValueFloat("end of map roll chance?", 1.0);
	iLootBagsAreGenerated				= GetConfigValueInt("generate interactable loot bags?", 1);
	fLootBagExpirationTimeInSeconds		= GetConfigValueFloat("loot bags disappear after this many seconds?", 10.0);
	iExplosionBaseDamagePipe			= GetConfigValueInt("base pipebomb damage?", 500);
	iExplosionBaseDamage				= GetConfigValueInt("base explosion damage for non pipebomb sources?", 500);
	fProficiencyLevelDamageIncrease		= GetConfigValueFloat("weapon proficiency level bonus damage?", 0.01);
	iJetpackEnabled						= GetConfigValueInt("jetpack enabled?", 1);
	fJumpTimeToActivateJetpack			= GetConfigValueFloat("jump press time to activate jetpack?", 0.4);
	iNumLootDropChancesPerPlayer[0]		= GetConfigValueInt("roll attempts on common kill?", 1);
	iNumLootDropChancesPerPlayer[1]		= GetConfigValueInt("roll attempts on supers kill?", 1);
	iNumLootDropChancesPerPlayer[2]		= GetConfigValueInt("roll attempts on specials kill?", 1);
	iNumLootDropChancesPerPlayer[3]		= GetConfigValueInt("roll attempts on witch kill?", 1);
	iNumLootDropChancesPerPlayer[4]		= GetConfigValueInt("roll attempts on tank kill?", 1);

	GetConfigValue(acmd, sizeof(acmd), "action slot command?");
	GetConfigValue(abcmd, sizeof(abcmd), "abilitybar menu command?");
	GetConfigValue(DefaultProfileName, sizeof(DefaultProfileName), "new player profile?");
	GetConfigValue(DefaultBotProfileName, sizeof(DefaultBotProfileName), "new bot player profile?");
	GetConfigValue(DefaultInfectedProfileName, sizeof(DefaultInfectedProfileName), "new infected player profile?");
	GetConfigValue(defaultLoadoutWeaponPrimary, sizeof(defaultLoadoutWeaponPrimary), "default loadout primary weapon?");
	GetConfigValue(defaultLoadoutWeaponSecondary, sizeof(defaultLoadoutWeaponSecondary), "default loadout secondary weapon?");
	GetConfigValue(serverKey, sizeof(serverKey), "server steam key?");
	LogMessage("Main Config Loaded.");
}

public Action CMD_RollLoot(client, args) {
	//GenerateAndGivePlayerAugment(client);
	return Plugin_Handled;
}

stock EndOfMapRollLoot() {
	if (iNumOfEndMapLootRolls < 1) return;
	char sWhichPlayersToRollNotice[32];
	if (iAllPlayersEndMapLootRolls == 1) Format(sWhichPlayersToRollNotice, 32, "survivors");
	else Format(sWhichPlayersToRollNotice, 32, "living survivors");
	PrintToChatAll("%t", "end of map augment rolls", blue, green, iNumOfEndMapLootRolls, blue, sWhichPlayersToRollNotice);
	for (int i = 1; i <= MaxClients; i++) {
		if (!IsLegitimateClient(i) || GetClientTeam(i) != TEAM_SURVIVOR) continue;
		if (iAllPlayersEndMapLootRolls != 1 && !IsPlayerAlive(i)) continue;
		int numRollsRemainingThisPlayer = (GetArraySize(possibleLootPool[i]) < iPlayerStartingLevel) ? 0 : iNumOfEndMapLootRolls;
		while (numRollsRemainingThisPlayer > 0) {
			numRollsRemainingThisPlayer--;
			if (fEndMapLootRollsChance < 1.0 && GetRandomInt(1, RoundToCeil(1.0 / fEndMapLootRollsChance)) > 1) continue;

			// int min = (Rating[i] < iRatingRequiredForAugmentLootDrops) ? iRatingRequiredForAugmentLootDrops : Rating[i];
			// int max = (BestRating[i] > min) ? BestRating[i] : min+1;
			GenerateAndGivePlayerAugment(i);
		}
	}
}

stock RollLoot(client, enemyClient) {
	if (iLootEnabled == 0 || IsFakeClient(client)) return;
	int lootPoolSize = GetArraySize(possibleLootPool[client]);
	if (lootPoolSize < iUpgradesRequiredForLoot) return;
	int zombieclass = FindZombieClass(enemyClient);
	float fLootChance = (zombieclass == 10) ? fLootChanceCommons :					// common
						(zombieclass == 9) ? fLootChanceSupers :					// super
						(zombieclass == 7) ? fLootChanceWitch :						// witch
						(zombieclass == 8) ? fLootChanceTank :						// tank
						(zombieclass > 0) ? fLootChanceSpecials : 0.0;				// special infected
	if (fLootChance == 0.0) return;
	// in borderlands you have a low chance of getting loot, so they throw a ton of roll attempts at you.
	// sometimes you get an overwhelming amount, sometimes you get one item, sometimes you get nothing.
	int numOfRollsToAttempt = (zombieclass == 10) ? iNumLootDropChancesPerPlayer[0] :
							  (zombieclass == 9) ? iNumLootDropChancesPerPlayer[1] :
							  (zombieclass == 7) ? iNumLootDropChancesPerPlayer[3] :
							  (zombieclass == 8) ? iNumLootDropChancesPerPlayer[4] : iNumLootDropChancesPerPlayer[2];
	for (int i = numOfRollsToAttempt; i > 0; i--) {
		int roll = GetRandomInt(1, RoundToCeil(1.0 / fLootChance));
		if (roll != 1) continue;
		if (iLootBagsAreGenerated != 1) GenerateAndGivePlayerAugment(client);
		else {
			int min = (Rating[client] < iRatingRequiredForAugmentLootDrops) ? iRatingRequiredForAugmentLootDrops : Rating[client];
			int max = (min + iRatingRequiredForAugmentLootDrops > BestRating[client]) ? min + iRatingRequiredForAugmentLootDrops : BestRating[client];
			PushArrayCell(playerLootOnGround[client], GetRandomInt(min,max));
			CreateItemDrop(client, enemyClient);
		}
	}
	// int talentSelectedPos = GetArrayCell(possibleLootPool[client], GetRandomInt(0, lootPoolSize-1), 0);
	// char text[128];
	// GetArrayString(a_Database_Talents, talentSelectedPos, text, sizeof(text));
	// GetTranslationOfTalentName(client, text, text, sizeof(text), true);
	// Format(text, sizeof(text), "%t", text);
	// char name[64];
	// GetClientName(client, name, sizeof(name));
	// Format(text, sizeof(text), "{B}%s {N}obtains an {B}%s {N}augment", name, text);
	// for (int i = 1; i <= MaxClients; i++) {
	// 	if (!IsLegitimateClient(i)) continue;
	// 	Client_PrintToChat(i, true, text);
	// }
}

stock void GenerateAndGivePlayerAugment(client, int forceAugmentItemLevel = 0, bool isALootBag = false) {
	if (IsFakeClient(client)) return;
	int min = (Rating[client] < iRatingRequiredForAugmentLootDrops) ? iRatingRequiredForAugmentLootDrops : Rating[client];
	int max = (BestRating[client] > min + iRatingRequiredForAugmentLootDrops) ? BestRating[client] : min + iRatingRequiredForAugmentLootDrops;
	int potentialItemRatingOverride = (forceAugmentItemLevel > 0) ? forceAugmentItemLevel : GetRandomInt(min, max);
	//if (potentialItemRatingOverride == 0 && Rating[client] < iRatingRequiredForAugmentLootDrops) return;
	int size = GetArraySize(myAugmentIDCodes[client]);
	char buffedCategory[64];
	int lootSize = GetArraySize(myLootDropCategoriesAllowed[client]);
	if (lootSize < 1) return;
	ResizeArray(myAugmentIDCodes[client], size+1);
	ResizeArray(myAugmentCategories[client], size+1);
	ResizeArray(myAugmentOwners[client], size+1);
	ResizeArray(myAugmentInfo[client], size+1);
	ResizeArray(myAugmentActivatorEffects[client], size+1);
	ResizeArray(myAugmentTargetEffects[client], size+1);

	char sItemCode[64];
	FormatTime(sItemCode, 64, "%y%m%d%H%M%S", GetTime());
	lootDropCounter++;
	Format(sItemCode, 64, "%d%s%d", iUniqueServerCode, sItemCode, lootDropCounter);
	SetArrayString(myAugmentIDCodes[client], size, sItemCode);

	int pos = GetRandomInt(0, lootSize-1);
	GetArrayString(myLootDropCategoriesAllowed[client], pos, buffedCategory, 64);

	char menuText[64];
	int len = GetAugmentTranslation(client, buffedCategory, menuText);

	char name[64];
	char text[512];
	GetClientName(client, name, sizeof(name));

	int potentialItemRating = (potentialItemRatingOverride == 0) ? Rating[client] : potentialItemRatingOverride;
	int count = 1;
	while (count < 3 && potentialItemRating > (count*2) * iRatingRequiredForAugmentLootDrops) count++;
	if (count == 3) count = 4;
	int thisAugmentRatingRequiredForNextTier = count * iRatingRequiredForAugmentLootDrops;
	char augmentStrengthText[64];
	int lootrolls[3];
	int roll = GetRandomInt(thisAugmentRatingRequiredForNextTier, potentialItemRating);
	potentialItemRating -= roll;
	//potentialItemRating -= iRatingRequiredForAugmentLootDrops;
	thisAugmentRatingRequiredForNextTier /= 2;
	lootrolls[0] = roll;
	int lootsize = 0;
	while (potentialItemRating > thisAugmentRatingRequiredForNextTier) {
		if (lootsize == 0) lootsize++;
		roll = GetRandomInt(thisAugmentRatingRequiredForNextTier, potentialItemRating);
		potentialItemRating -= roll;
		//potentialItemRating -= iRatingRequiredForAugmentLootDrops;
		thisAugmentRatingRequiredForNextTier /= 2;
		lootrolls[lootsize] = roll;
		if (lootsize < 2 && thisAugmentRatingRequiredForNextTier > iRatingRequiredForAugmentLootDrops && potentialItemRating > thisAugmentRatingRequiredForNextTier) lootsize++;
		else break;
	}

	SetArrayString(myAugmentCategories[client], size, buffedCategory);
	SetArrayString(myAugmentOwners[client], size, baseName[client]);
	SetArrayCell(myAugmentInfo[client], size, lootrolls[0]);	// item rating
	SetArrayCell(myAugmentInfo[client], size, 0, 1);			// item cost
	SetArrayCell(myAugmentInfo[client], size, 0, 2);			// is item for sale
	SetArrayCell(myAugmentInfo[client], size, -1, 3);			// which augment slot the item is equipped in - -1 for no slot.

	int possibilities = RoundToCeil(1.0 / fAugmentTierChance);
	int type = GetRandomInt(1, possibilities);
	int augmentActivatorRating = -1;
	int augmentTargetRating = -1;
	char activatorEffects[64];
	char targetEffects[64];

	if (type == 1 && lootsize > 0) {
		pos = GetRandomInt(0, GetArraySize(possibleLootPoolActivator[client]));
		//pos = GetArrayCell(possibleLootPoolActivator[client], pos);
		GetArrayString(myLootDropActivatorEffectsAllowed[client], pos, activatorEffects, 64);
		SetArrayString(myAugmentActivatorEffects[client], size, activatorEffects);
		if (!StrEqual(activatorEffects, "-1")) {
			augmentActivatorRating = lootrolls[1];
			lootrolls[1] = lootrolls[2];
		}
	}
	else {
		augmentActivatorRating = -1;
		Format(activatorEffects, 64, "-1");
		SetArrayString(myAugmentActivatorEffects[client], size, "-1");
		if (lootsize > 1 && lootrolls[1] < lootrolls[2]) lootrolls[1] = lootrolls[2];
	}
	SetArrayCell(myAugmentInfo[client], size, augmentActivatorRating, 4);
	type = GetRandomInt(1, possibilities);
	if (type == 1 && lootsize > 1) {
		pos = GetRandomInt(0, GetArraySize(possibleLootPoolTarget[client]));
		//pos = GetArrayCell(possibleLootPoolTarget[client], pos);
		GetArrayString(myLootDropTargetEffectsAllowed[client], pos, targetEffects, 64);
		SetArrayString(myAugmentTargetEffects[client], size, targetEffects);
		if (!StrEqual(targetEffects, "-1")) augmentTargetRating = lootrolls[1];
	}
	else {
		augmentTargetRating = -1;
		Format(targetEffects, 64, "-1");
		SetArrayString(myAugmentTargetEffects[client], size, "-1");
		SetArrayCell(myAugmentInfo[client], size, -1, 5);
	}
	SetArrayCell(myAugmentInfo[client], size, augmentTargetRating, 5);

	char key[64];
	GetClientAuthId(client, AuthId_Steam2, key, sizeof(key));
	if (!StrEqual(serverKey, "-1")) Format(key, sizeof(key), "%s%s", serverKey, key);
	char tquery[512];
	Format(tquery, sizeof(tquery), "INSERT INTO `%s_loot` (`steam_id`, `itemid`, `rating`, `category`, `price`, `isforsale`, `isequipped`, `acteffects`, `actrating`, `tareffects`, `tarrating`) VALUES ('%s', '%s', '%d', '%s', '%d', '%d', '%d', '%s', '%d', '%s', '%d');", TheDBPrefix, key, sItemCode, lootrolls[0], buffedCategory, 0, 0, -1, activatorEffects, augmentActivatorRating, targetEffects, augmentTargetRating);
	SQL_TQuery(hDatabase, QueryResults, tquery);

	if (augmentActivatorRating == -1 && augmentTargetRating == -1) Format(augmentStrengthText, 10, "minor");
	else if (augmentActivatorRating == -1 || augmentTargetRating == -1) Format(augmentStrengthText, 10, "major");
	else Format(augmentStrengthText, 10, "perfect");
	Format(text, sizeof(text), "{B}%s {N}found a {B}+{OG}%3.3f{B}PCT {O}%s {B}%s %s {O}augment", name, (lootrolls[0] * fAugmentRatingMultiplier) * 100.0, augmentStrengthText, menuText, buffedCategory[len]);
	if (forceAugmentItemLevel < 1) Format(text, sizeof(text), "%s {N}on a corpse.", text);
	else if (isALootBag) Format(text, sizeof(text), "%s {N}in the bag.", text);
	else {
		if (iAllPlayersEndMapLootRolls != 1) Format(text, sizeof(text), "%s {N}in the safe room.", text);
		else Format(text, sizeof(text), "%s {N}as a participation reward.", text);
	}
	ReplaceString(text, sizeof(text), "PCT", "%%", true);
	for (int i = 1; i <= MaxClients; i++) {
		if (!IsLegitimateClient(i) || IsFakeClient(i)) continue;
		Client_PrintToChat(i, true, text);
	}
	//if (forceAugmentItemLevel > 0) PrintToChatAll("%t", "player end of map roll award", blue, name, white, blue, (lootrolls[0] * fAugmentRatingMultiplier) * 100.0, pct, augmentStrengthText, menuText, buffedCategory[len], green, white);
	//else PrintToChatAll("%t", "player loot award", blue, name, white, blue, (lootrolls[0] * fAugmentRatingMultiplier) * 100.0, pct, augmentStrengthText, menuText, buffedCategory[len], green, white);
	// test
	// char t1[64];
	// char t2[64];
	// char t3[64];
	// GetArrayString(myAugmentCategories[client], size, t1, 64);
	// GetArrayString(myAugmentOwners[client], size, t2, 64);
	// GetArrayString(myAugmentIDCodes[client], size, t3, 64);
	// LogMessage("---------------------------\nID: %s\nOwner: %s\nCategory: %s\nRating: %d\nItem Value: %d\nIs for Sale: %d", t3, t2, t1,
	// GetArrayCell(myAugmentInfo[client], size), GetArrayCell(myAugmentInfo[client], size, 1), GetArrayCell(myAugmentInfo[client], size, 2));
}

stock void GetUniqueAugmentLootDropItemCode(char[] sTime) {
	FormatTime(sTime, 64, "%y%m%d%H%M%S", GetTime());
	lootDropCounter++;
	Format(sTime, 64, "%d%s%d", iUniqueServerCode, sTime, lootDropCounter);
	LogMessage("itemcode is %s", sTime);
}

stock void SetLootDropCategories(client) {
	ClearArray(possibleLootPool[client]);
	ClearArray(possibleLootPoolActivator[client]);
	ClearArray(possibleLootPoolTarget[client]);
	ClearArray(myLootDropCategoriesAllowed[client]);
	ClearArray(myLootDropTargetEffectsAllowed[client]);
	ClearArray(myLootDropActivatorEffectsAllowed[client]);
	int size = GetArraySize(a_Menu_Talents);
	if (GetArraySize(MyTalentStrength[client]) != size) ResizeArray(MyTalentStrength[client], size);
	int explodeCount = GetDelimiterCount(sCategoriesToIgnore, ",") + 1;

	char[][] categoriesToSkip = new char[explodeCount][64];
	ExplodeString(sCategoriesToIgnore, ",", categoriesToSkip, explodeCount, 64);
	char talentName[64];
	for (int i = 0; i < size; i++) {
		//LootDropCategoryToBuffValues[client]			= GetArrayCell(a_Menu_Talents, i, 2);
		//GetArrayString(LootDropCategoryToBuffValues[client], 0, talentName, sizeof(talentName));
		//if (GetTalentStrength(client, talentName) < 1) continue;
		if (GetArrayCell(MyTalentStrength[client], i) < 1) continue;
		LootDropCategoryToBuffValues[client]			= GetArrayCell(a_Menu_Talents, i, 1);
		GetArrayString(LootDropCategoryToBuffValues[client], PART_OF_MENU_NAMED, talentName, sizeof(talentName));
		bool bSkipThisTalent = false;
		for (int ii = 0; ii < explodeCount; ii++) {
			if (StrContains(talentName, categoriesToSkip[ii]) == -1) continue;
			bSkipThisTalent = true;
			break;
		}
		if (bSkipThisTalent) continue;
		PushArrayCell(possibleLootPool[client], i);
		GetArrayString(LootDropCategoryToBuffValues[client], TALENT_TREE_CATEGORY, talentName, sizeof(talentName));
		PushArrayString(myLootDropCategoriesAllowed[client], talentName);
		GetArrayString(LootDropCategoryToBuffValues[client], ACTIVATOR_ABILITY_EFFECTS, talentName, sizeof(talentName));
		if (!StrEqual(talentName, "-1") && !StrEqual(talentName, "0")) {
			PushArrayString(myLootDropActivatorEffectsAllowed[client], talentName);
			PushArrayCell(possibleLootPoolActivator[client], i);
		}

		GetArrayString(LootDropCategoryToBuffValues[client], TARGET_ABILITY_EFFECTS, talentName, sizeof(talentName));
		if (!StrEqual(talentName, "-1") && !StrEqual(talentName, "0")) {
			PushArrayString(myLootDropTargetEffectsAllowed[client], talentName);
			PushArrayCell(possibleLootPoolTarget[client], i);
		}
	}
}

//public Action:CMD_Backpack(client, args) { EquipBackpack(client); return Plugin_Handled; }
public Action CMD_BuyMenu(client, args) {
	if (iRPGMode < 0 || iRPGMode == 1 && b_IsActiveRound) return Plugin_Handled;
	//if (StringToInt(GetConfigValue("rpg mode?")) != 1) 
	BuildPointsMenu(client, "Buy Menu", "rpg/points.cfg");
	return Plugin_Handled;
}

public Action CMD_DataErase(client, args) {
	char arg[MAX_NAME_LENGTH];
	char thetext[64];
	GetConfigValue(thetext, sizeof(thetext), "delete bot flags?");
	if (args > 0 && HasCommandAccess(client, thetext)) {
		GetCmdArg(1, arg, sizeof(arg));
		int targetclient = FindTargetClient(client, arg);
		if (IsLegitimateClient(targetclient) && GetClientTeam(targetclient) != TEAM_INFECTED) DeleteAndCreateNewData(targetclient);
	}
	else DeleteAndCreateNewData(client);
	return Plugin_Handled;
}

public Action CMD_DataEraseBot(client, args) {
	DeleteAndCreateNewData(client, true);
	return Plugin_Handled;
}

stock DeleteAndCreateNewData(client, bool IsBot = false) {
	char key[64];
	char tquery[1024];
	char text[64];
	char pct[4];
	Format(pct, sizeof(pct), "%");
	if (!IsBot) {
		GetClientAuthId(client, AuthId_Steam2, key, sizeof(key));
		if (!StrEqual(serverKey, "-1")) Format(key, sizeof(key), "%s%s", serverKey, key);
		Format(tquery, sizeof(tquery), "DELETE FROM `%s` WHERE `steam_id` = '%s';", TheDBPrefix, key);
		SQL_TQuery(hDatabase, QueryResults, tquery, client);
		ResetData(client);
		CreateNewPlayerEx(client);
		PrintToChat(client, "data erased, new data created.");	// not bothering with a translation here, since it's a debugging command.
	}
	else {
		GetConfigValue(text, sizeof(text), "delete bot flags?");
		if (HasCommandAccess(client, text)) {
			for (int i = 1; i <= MaxClients; i++) {
				if (IsLegitimateClient(i) && IsFakeClient(i)) KickClient(i);
			}
			Format(tquery, sizeof(tquery), "DELETE FROM `%s` WHERE `steam_id` LIKE '%s%s%s';", TheDBPrefix, pct, sBotTeam, pct);
			//Format(tquery, sizeof(tquery), "DELETE FROM `%s` WHERE `steam_id` LIKE 'STEAM';", TheDBPrefix);
			SQL_TQuery(hDatabase, QueryResults, tquery, client);
			PrintToChatAll("%t", "bot data deleted", orange, blue);
		}
	}
}

public Action CMD_DirectorTalentToggle(client, args) {
	char thetext[64];
	GetConfigValue(thetext, sizeof(thetext), "director talent flags?");
	if (HasCommandAccess(client, thetext)) {
		if (b_IsDirectorTalents[client]) {
			b_IsDirectorTalents[client]			= false;
			PrintToChat(client, "%T", "Director Talents Disabled", client, white, green);
		}
		else {

			b_IsDirectorTalents[client]			= true;
			PrintToChat(client, "%T", "Director Talents Enabled", client, white, green);
		}
	}
	return Plugin_Handled;
}

stock SetConfigArrays(char[] Config, Handle Main, Handle Keys, Handle Values, Handle Section, size, last, bool setConfigArraysDebugger = false) {
	char text[64];
	Handle TalentKey = CreateArray(16);
	Handle TalentValue = CreateArray(16);
	Handle TalentSection = CreateArray(16);
	char key[64];
	char value[64];
	int a_Size = GetArraySize(Keys);
	if (setConfigArraysDebugger) LogMessage("Config array size is %d", a_Size);
	for (int i = last; i < a_Size; i++) {

		GetArrayString(Keys, i, key, sizeof(key));
		GetArrayString(Values, i, value, sizeof(value));
		//if (StrEqual(key, "EOM")) continue;	// we don't care about the EOM key at this point.
		if (setConfigArraysDebugger && StrEqual(Config, CONFIG_MENUTALENTS)) LogMessage("\"%s\"\t\t\"%s\"", key, value);
		PushArrayString(TalentKey, key);
		PushArrayString(TalentValue, value);
	}
	if (setConfigArraysDebugger && StrEqual(Config, CONFIG_MENUTALENTS)) LogMessage("------------------------------------------------------------");
	char talentName[64];
	GetArrayString(Section, 0, talentName, sizeof(talentName));
	int pos = 0;
	int sortSize = 0;
	// Sort the keys/values for TALENTS ONLY /w.
	if (StrEqual(Config, CONFIG_MENUTALENTS)) {
		if (FindStringInArray(TalentKey, "activator status effect required?") == -1) {
			PushArrayString(TalentKey, "activator status effect required?");
			PushArrayString(TalentValue, "-1");
		}
		if (FindStringInArray(TalentKey, "active effect allows all classes?") == -1) {
			PushArrayString(TalentKey, "active effect allows all classes?");
			PushArrayString(TalentValue, "-1");
		}
		if (FindStringInArray(TalentKey, "active effect allows all hitgroups?") == -1) {
			PushArrayString(TalentKey, "active effect allows all hitgroups?");
			PushArrayString(TalentValue, "-1");
		}
		if (FindStringInArray(TalentKey, "active effect allows all weapons?") == -1) {
			PushArrayString(TalentKey, "active effect allows all weapons?");
			PushArrayString(TalentValue, "-1");
		}
		if (FindStringInArray(TalentKey, "mult str div same headshots?") == -1) {
			PushArrayString(TalentKey, "mult str div same headshots?");
			PushArrayString(TalentValue, "-1");
		}
		if (FindStringInArray(TalentKey, "mult str max same headshots?") == -1) {
			PushArrayString(TalentKey, "mult str max same headshots?");
			PushArrayString(TalentValue, "-1");
		}
		if (FindStringInArray(TalentKey, "mult str by same headshots?") == -1) {
			PushArrayString(TalentKey, "mult str by same headshots?");
			PushArrayString(TalentValue, "-1");
		}
		if (FindStringInArray(TalentKey, "require consecutive headshots?") == -1) {
			PushArrayString(TalentKey, "require consecutive headshots?");
			PushArrayString(TalentValue, "-1");
		}
		if (FindStringInArray(TalentKey, "weapon slot required?") == -1) {
			PushArrayString(TalentKey, "weapon slot required?");
			PushArrayString(TalentValue, "-1");
		}
		if (FindStringInArray(TalentKey, "ability trigger to call?") == -1) {
			PushArrayString(TalentKey, "ability trigger to call?");
			PushArrayString(TalentValue, "-1");
		}
		if (FindStringInArray(TalentKey, "hide talent strength display?") == -1) {
			PushArrayString(TalentKey, "hide talent strength display?");
			PushArrayString(TalentValue, "-1.0");
		}
		if (FindStringInArray(TalentKey, "give player this item on trigger?") == -1) {
			PushArrayString(TalentKey, "give player this item on trigger?");
			PushArrayString(TalentValue, "-1");
		}
		if (FindStringInArray(TalentKey, "contribution cost required?") == -1) {
			PushArrayString(TalentKey, "contribution cost required?");
			PushArrayString(TalentValue, "-1");
		}
		if (FindStringInArray(TalentKey, "contribution category required?") == -1) {
			PushArrayString(TalentKey, "contribution category required?");
			PushArrayString(TalentValue, "-1");
		}
		if (FindStringInArray(TalentKey, "mult str div same hits?") == -1) {
			PushArrayString(TalentKey, "mult str div same hits?");
			PushArrayString(TalentValue, "-1");
		}
		if (FindStringInArray(TalentKey, "mult str max same hits?") == -1) {
			PushArrayString(TalentKey, "mult str max same hits?");
			PushArrayString(TalentValue, "-1");
		}
		if (FindStringInArray(TalentKey, "mult str by same hits?") == -1) {
			PushArrayString(TalentKey, "mult str by same hits?");
			PushArrayString(TalentValue, "-1");
		}
		if (FindStringInArray(TalentKey, "last hit must be headshot?") == -1) {
			PushArrayString(TalentKey, "last hit must be headshot?");
			PushArrayString(TalentValue, "-1");
		}
		if (FindStringInArray(TalentKey, "event type?") == -1) {
			PushArrayString(TalentKey, "event type?");
			PushArrayString(TalentValue, "-1");
		}
		if (FindStringInArray(TalentKey, "target must be in the air?") == -1) {
			PushArrayString(TalentKey, "target must be in the air?");
			PushArrayString(TalentValue, "-1");
		}
		if (FindStringInArray(TalentKey, "activator neither high or low ground?") == -1) {
			PushArrayString(TalentKey, "activator neither high or low ground?");
			PushArrayString(TalentValue, "-1");
		}
		if (FindStringInArray(TalentKey, "target high ground?") == -1) {
			PushArrayString(TalentKey, "target high ground?");
			PushArrayString(TalentValue, "-1");
		}
		if (FindStringInArray(TalentKey, "activator high ground?") == -1) {
			PushArrayString(TalentKey, "activator high ground?");
			PushArrayString(TalentValue, "-1");
		}
		if (FindStringInArray(TalentKey, "requires activator drowning?") == -1) {
			PushArrayString(TalentKey, "requires activator drowning?");
			PushArrayString(TalentValue, "-1");
		}
		if (FindStringInArray(TalentKey, "requires activator steaming?") == -1) {
			PushArrayString(TalentKey, "requires activator steaming?");
			PushArrayString(TalentValue, "-1");
		}
		if (FindStringInArray(TalentKey, "requires activator scorched?") == -1) {
			PushArrayString(TalentKey, "requires activator scorched?");
			PushArrayString(TalentValue, "-1");
		}
		if (FindStringInArray(TalentKey, "requires activator frozen?") == -1) {
			PushArrayString(TalentKey, "requires activator frozen?");
			PushArrayString(TalentValue, "-1");
		}
		if (FindStringInArray(TalentKey, "requires activator slowed?") == -1) {
			PushArrayString(TalentKey, "requires activator slowed?");
			PushArrayString(TalentValue, "-1");
		}
		if (FindStringInArray(TalentKey, "requires activator exploding?") == -1) {
			PushArrayString(TalentKey, "requires activator exploding?");
			PushArrayString(TalentValue, "-1");
		}
		if (FindStringInArray(TalentKey, "requires activator acid burn?") == -1) {
			PushArrayString(TalentKey, "requires activator acid burn?");
			PushArrayString(TalentValue, "-1");
		}
		if (FindStringInArray(TalentKey, "requires activator on fire?") == -1) {
			PushArrayString(TalentKey, "requires activator on fire?");
			PushArrayString(TalentValue, "-1");
		}
		if (FindStringInArray(TalentKey, "target must be last target?") == -1) {
			PushArrayString(TalentKey, "target must be last target?");
			PushArrayString(TalentValue, "-1");
		}
		if (FindStringInArray(TalentKey, "target must be outside range required?") == -1) {
			PushArrayString(TalentKey, "target must be outside range required?");
			PushArrayString(TalentValue, "-1");
		}
		if (FindStringInArray(TalentKey, "target range required?") == -1) {
			PushArrayString(TalentKey, "target range required?");
			PushArrayString(TalentValue, "-1.0");
		}
		if (FindStringInArray(TalentKey, "target class must be last target class?") == -1) {
			PushArrayString(TalentKey, "target class must be last target class?");
			PushArrayString(TalentValue, "-1");
		}
		if (FindStringInArray(TalentKey, "toggle strength?") == -1) {
			PushArrayString(TalentKey, "toggle strength?");
			PushArrayString(TalentValue, "-1.0");
		}
		if (FindStringInArray(TalentKey, "minimum level required?") == -1) {
			PushArrayString(TalentKey, "minimum level required?");
			PushArrayString(TalentValue, "-1");
		}
		if (FindStringInArray(TalentKey, "special ammo?") == -1) {
			PushArrayString(TalentKey, "special ammo?");
			PushArrayString(TalentValue, "-1");
		}
		if (FindStringInArray(TalentKey, "does damage?") == -1) {
			PushArrayString(TalentKey, "does damage?");
			PushArrayString(TalentValue, "-1");
		}
		if (FindStringInArray(TalentKey, "cooldown end ability trigger?") == -1) {
			PushArrayString(TalentKey, "cooldown end ability trigger?");
			PushArrayString(TalentValue, "-1");
		}
		if (FindStringInArray(TalentKey, "active end ability trigger?") == -1) {
			PushArrayString(TalentKey, "active end ability trigger?");
			PushArrayString(TalentValue, "-1");
		}
		if (FindStringInArray(TalentKey, "secondary ept only?") == -1) {
			PushArrayString(TalentKey, "secondary ept only?");
			PushArrayString(TalentValue, "-1");
		}
		if (FindStringInArray(TalentKey, "activate effect per tick?") == -1) {
			PushArrayString(TalentKey, "activate effect per tick?");
			PushArrayString(TalentValue, "-1");
		}
		if (FindStringInArray(TalentKey, "cooldown?") == -1) {
			PushArrayString(TalentKey, "cooldown?");
			PushArrayString(TalentValue, "-1.0");
		}
		if (FindStringInArray(TalentKey, "allow survivors?") == -1) {
			PushArrayString(TalentKey, "allow survivors?");
			PushArrayString(TalentValue, "-1");
		}
		if (FindStringInArray(TalentKey, "allow specials?") == -1) {
			PushArrayString(TalentKey, "allow specials?");
			PushArrayString(TalentValue, "-1");
		}
		if (FindStringInArray(TalentKey, "allow commons?") == -1) {
			PushArrayString(TalentKey, "allow commons?");
			PushArrayString(TalentValue, "-1");
		}
		if (FindStringInArray(TalentKey, "inanimate only?") == -1) {
			PushArrayString(TalentKey, "inanimate only?");
			PushArrayString(TalentValue, "-1");
		}
		if (FindStringInArray(TalentKey, "humanoid only?") == -1) {
			PushArrayString(TalentKey, "humanoid only?");
			PushArrayString(TalentValue, "-1");
		}
		if (FindStringInArray(TalentKey, "toggle effect?") == -1) {
			PushArrayString(TalentKey, "toggle effect?");
			PushArrayString(TalentValue, "-1");
		}
		if (FindStringInArray(TalentKey, "sky level requirement?") == -1) {
			PushArrayString(TalentKey, "sky level requirement?");
			PushArrayString(TalentValue, "-1");
		}
		if (FindStringInArray(TalentKey, "cannot be ensnared?") == -1) {
			PushArrayString(TalentKey, "cannot be ensnared?");
			PushArrayString(TalentValue, "-1");
		}
		if (FindStringInArray(TalentKey, "active time?") == -1) {
			PushArrayString(TalentKey, "active time?");
			PushArrayString(TalentValue, "-1.0");
		}
		if (FindStringInArray(TalentKey, "reactive type?") == -1) {
			PushArrayString(TalentKey, "reactive type?");
			PushArrayString(TalentValue, "-1");
		}
		if (FindStringInArray(TalentKey, "inactive trigger?") == -1) {
			PushArrayString(TalentKey, "inactive trigger?");
			PushArrayString(TalentValue, "-1");
		}
		if (FindStringInArray(TalentKey, "cooldown trigger?") == -1) {
			PushArrayString(TalentKey, "cooldown trigger?");
			PushArrayString(TalentValue, "-1");
		}
		if (FindStringInArray(TalentKey, "is aura instead?") == -1) {
			PushArrayString(TalentKey, "is aura instead?");
			PushArrayString(TalentValue, "-1");
		}
		if (FindStringInArray(TalentKey, "requirement multiplier?") == -1) {
			PushArrayString(TalentKey, "requirement multiplier?");
			PushArrayString(TalentValue, "-1.0");
		}
		if (FindStringInArray(TalentKey, "experience start?") == -1) {
			PushArrayString(TalentKey, "experience start?");
			PushArrayString(TalentValue, "-1");
		}
		if (FindStringInArray(TalentKey, "rarity?") == -1) {
			PushArrayString(TalentKey, "rarity?");
			PushArrayString(TalentValue, "-1");
		}
		if (FindStringInArray(TalentKey, "is item?") == -1) {
			PushArrayString(TalentKey, "is item?");
			PushArrayString(TalentValue, "-1");
		}
		if (FindStringInArray(TalentKey, "talent type?") == -1) {
			PushArrayString(TalentKey, "talent type?");
			PushArrayString(TalentValue, "-1");
		}
		if (FindStringInArray(TalentKey, "is sub menu?") == -1) {
			PushArrayString(TalentKey, "is sub menu?");
			PushArrayString(TalentValue, "-1");
		}
		if (FindStringInArray(TalentKey, "buff bar text?") == -1) {
			PushArrayString(TalentKey, "buff bar text?");
			PushArrayString(TalentValue, "-1");
		}
		if (FindStringInArray(TalentKey, "diminishing returns?") == -1) {
			PushArrayString(TalentKey, "diminishing returns?");
			PushArrayString(TalentValue, "-1");
		}
		if (FindStringInArray(TalentKey, "diminishing multiplier?") == -1) {
			PushArrayString(TalentKey, "diminishing multiplier?");
			PushArrayString(TalentValue, "-1.0");
		}
		if (FindStringInArray(TalentKey, "base multiplier?") == -1) {
			PushArrayString(TalentKey, "base multiplier?");
			PushArrayString(TalentValue, "-1.0");
		}
		if (FindStringInArray(TalentKey, "use these multipliers?") == -1) {
			PushArrayString(TalentKey, "use these multipliers?");
			PushArrayString(TalentValue, "-1");
		}
		if (FindStringInArray(TalentKey, "attribute?") == -1) {
			PushArrayString(TalentKey, "attribute?");
			PushArrayString(TalentValue, "-1");
		}
		if (FindStringInArray(TalentKey, "passive draw delay?") == -1) {
			PushArrayString(TalentKey, "passive draw delay?");
			PushArrayString(TalentValue, "-1.0");
		}
		if (FindStringInArray(TalentKey, "draw effect delay?") == -1) {
			PushArrayString(TalentKey, "draw effect delay?");
			PushArrayString(TalentValue, "-1.0");
		}
		if (FindStringInArray(TalentKey, "draw delay?") == -1) {
			PushArrayString(TalentKey, "draw delay?");
			PushArrayString(TalentValue, "-1.0");
		}
		if (FindStringInArray(TalentKey, "is single target?") == -1) {
			PushArrayString(TalentKey, "is single target?");
			PushArrayString(TalentValue, "-1");
		}
		if (FindStringInArray(TalentKey, "passive only?") == -1) {
			PushArrayString(TalentKey, "passive only?");
			PushArrayString(TalentValue, "-1");
		}
		if (FindStringInArray(TalentKey, "passive strength?") == -1) {
			PushArrayString(TalentKey, "passive strength?");
			PushArrayString(TalentValue, "-1.0");
		}
		if (FindStringInArray(TalentKey, "passive requires ensnare?") == -1) {
			PushArrayString(TalentKey, "passive requires ensnare?");
			PushArrayString(TalentValue, "-1");
		}
		if (FindStringInArray(TalentKey, "passive ignores cooldown?") == -1) {
			PushArrayString(TalentKey, "passive ignores cooldown?");
			PushArrayString(TalentValue, "-1");
		}
		if (FindStringInArray(TalentKey, "active strength?") == -1) {
			PushArrayString(TalentKey, "active strength?");
			PushArrayString(TalentValue, "-1.0");
		}
		if (FindStringInArray(TalentKey, "active requires ensnare?") == -1) {
			PushArrayString(TalentKey, "active requires ensnare?");
			PushArrayString(TalentValue, "-1");
		}
		if (FindStringInArray(TalentKey, "maximum active multiplier?") == -1) {
			PushArrayString(TalentKey, "maximum active multiplier?");
			PushArrayString(TalentValue, "-1.0");
		}
		if (FindStringInArray(TalentKey, "maximum passive multiplier?") == -1) {
			PushArrayString(TalentKey, "maximum passive multiplier?");
			PushArrayString(TalentValue, "-1.0");
		}
		if (FindStringInArray(TalentKey, "cooldown strength?") == -1) {
			PushArrayString(TalentKey, "cooldown strength?");
			PushArrayString(TalentValue, "-1.0");
		}
		if (FindStringInArray(TalentKey, "teams allowed?") == -1) {
			PushArrayString(TalentKey, "teams allowed?");
			PushArrayString(TalentValue, "-1");
		}
		if (FindStringInArray(TalentKey, "reactive ability?") == -1) {
			PushArrayString(TalentKey, "reactive ability?");
			PushArrayString(TalentValue, "-1");
		}
		if (FindStringInArray(TalentKey, "cooldown effect?") == -1) {
			PushArrayString(TalentKey, "cooldown effect?");
			PushArrayString(TalentValue, "-1");
		}
		if (FindStringInArray(TalentKey, "passive effect?") == -1) {
			PushArrayString(TalentKey, "passive effect?");
			PushArrayString(TalentValue, "-1");
		}
		if (FindStringInArray(TalentKey, "active effect?") == -1) {
			PushArrayString(TalentKey, "active effect?");
			PushArrayString(TalentValue, "-1");
		}
		if (FindStringInArray(TalentKey, "effect multiplier?") == -1) {
			PushArrayString(TalentKey, "effect multiplier?");
			PushArrayString(TalentValue, "-1.0");
		}
		if (FindStringInArray(TalentKey, "ammo effect?") == -1) {
			PushArrayString(TalentKey, "ammo effect?");
			PushArrayString(TalentValue, "-1");
		}
		if (FindStringInArray(TalentKey, "interval per point?") == -1) {
			PushArrayString(TalentKey, "interval per point?");
			PushArrayString(TalentValue, "-1.0");
		}
		if (FindStringInArray(TalentKey, "interval first point?") == -1) {
			PushArrayString(TalentKey, "interval first point?");
			PushArrayString(TalentValue, "-1.0");
		}
		if (FindStringInArray(TalentKey, "range per point?") == -1) {
			PushArrayString(TalentKey, "range per point?");
			PushArrayString(TalentValue, "-1.0");
		}
		if (FindStringInArray(TalentKey, "range first point value?") == -1) {
			PushArrayString(TalentKey, "range first point value?");
			PushArrayString(TalentValue, "-1.0");
		}
		if (FindStringInArray(TalentKey, "stamina per point?") == -1) {
			PushArrayString(TalentKey, "stamina per point?");
			PushArrayString(TalentValue, "-1");
		}
		if (FindStringInArray(TalentKey, "base stamina required?") == -1) {
			PushArrayString(TalentKey, "base stamina required?");
			PushArrayString(TalentValue, "-1");
		}
		if (FindStringInArray(TalentKey, "cooldown per point?") == -1) {
			PushArrayString(TalentKey, "cooldown per point?");
			PushArrayString(TalentValue, "-1");
		}
		if (FindStringInArray(TalentKey, "cooldown first point?") == -1) {
			PushArrayString(TalentKey, "cooldown first point?");
			PushArrayString(TalentValue, "-1");
		}
		if (FindStringInArray(TalentKey, "cooldown start?") == -1) {
			PushArrayString(TalentKey, "cooldown start?");
			PushArrayString(TalentValue, "-1");
		}
		if (FindStringInArray(TalentKey, "active time per point?") == -1) {
			PushArrayString(TalentKey, "active time per point?");
			PushArrayString(TalentValue, "-1");
		}
		if (FindStringInArray(TalentKey, "active time first point?") == -1) {
			PushArrayString(TalentKey, "active time first point?");
			PushArrayString(TalentValue, "-1");
		}
		if (FindStringInArray(TalentKey, "roll chance?") == -1) {
			PushArrayString(TalentKey, "roll chance?");
			PushArrayString(TalentValue, "-1");
		}
		if (FindStringInArray(TalentKey, "hide translation?") == -1) {
			PushArrayString(TalentKey, "hide translation?");
			PushArrayString(TalentValue, "-1");
		}
		if (FindStringInArray(TalentKey, "is attribute?") == -1) {
			PushArrayString(TalentKey, "is attribute?");
			PushArrayString(TalentValue, "-1");
		}
		if (FindStringInArray(TalentKey, "ignore for layer count?") == -1) {
			PushArrayString(TalentKey, "ignore for layer count?");
			PushArrayString(TalentValue, "-1");
		}
		if (FindStringInArray(TalentKey, "effect strength?") == -1) {
			PushArrayString(TalentKey, "effect strength?");
			PushArrayString(TalentValue, "-1.0");
		}
		if (FindStringInArray(TalentKey, "is effect over time?") == -1) {
			PushArrayString(TalentKey, "is effect over time?");
			PushArrayString(TalentValue, "-1");
		}
		if (FindStringInArray(TalentKey, "talent hard limit?") == -1) {
			PushArrayString(TalentKey, "talent hard limit?");
			PushArrayString(TalentValue, "-1.0");
		}
		if (FindStringInArray(TalentKey, "governs cooldown of talent named?") == -1) {
			PushArrayString(TalentKey, "governs cooldown of talent named?");
			PushArrayString(TalentValue, "-1");
		}
		if (FindStringInArray(TalentKey, "talent active time scale?") == -1) {
			PushArrayString(TalentKey, "talent active time scale?");
			PushArrayString(TalentValue, "-1.0");
		}
		if (FindStringInArray(TalentKey, "talent active time strength value?") == -1) {
			PushArrayString(TalentKey, "talent active time strength value?");
			PushArrayString(TalentValue, "-1.0");
		}
		if (FindStringInArray(TalentKey, "talent cooldown scale?") == -1) {
			PushArrayString(TalentKey, "talent cooldown scale?");
			PushArrayString(TalentValue, "-1.0");
		}
		if (FindStringInArray(TalentKey, "talent cooldown strength value?") == -1) {
			PushArrayString(TalentKey, "talent cooldown strength value?");
			PushArrayString(TalentValue, "-1.0");
		}
		if (FindStringInArray(TalentKey, "talent upgrade scale?") == -1) {
			PushArrayString(TalentKey, "talent upgrade scale?");
			PushArrayString(TalentValue, "-1.0");
		}
		if (FindStringInArray(TalentKey, "talent upgrade strength value?") == -1) {
			PushArrayString(TalentKey, "talent upgrade strength value?");
			PushArrayString(TalentValue, "-1.0");
		}
		if (FindStringInArray(TalentKey, "required talents required?") == -1) {
			PushArrayString(TalentKey, "required talents required?");
			PushArrayString(TalentValue, "-1");
		}
		if (FindStringInArray(TalentKey, "action bar name?") == -1) {
			PushArrayString(TalentKey, "action bar name?");
			PushArrayString(TalentValue, "-1");
		}
		if (FindStringInArray(TalentKey, "is ability?") == -1) {
			PushArrayString(TalentKey, "is ability?");
			PushArrayString(TalentValue, "-1");
		}
		if (FindStringInArray(TalentKey, "layer?") == -1) {
			PushArrayString(TalentKey, "layer?");
			PushArrayString(TalentValue, "-1");
		}
		if (FindStringInArray(TalentKey, "part of menu named?") == -1) {
			PushArrayString(TalentKey, "part of menu named?");
			PushArrayString(TalentValue, "-1");
		}
		if (FindStringInArray(TalentKey, "talent tree category?") == -1) {
			PushArrayString(TalentKey, "talent tree category?");
			PushArrayString(TalentValue, "-1");
		}
		if (FindStringInArray(TalentKey, "governing attribute?") == -1) {
			PushArrayString(TalentKey, "governing attribute?");
			PushArrayString(TalentValue, "-1");
		}
		if (FindStringInArray(TalentKey, "translation?") == -1) {
			PushArrayString(TalentKey, "translation?");
			PushArrayString(TalentValue, "-1");
		}
		if (FindStringInArray(TalentKey, "talent name?") == -1) {
			PushArrayString(TalentKey, "talent name?");
			PushArrayString(TalentValue, "-1");
		}
		if (FindStringInArray(TalentKey, "secondary aoe?") == -1) {
			PushArrayString(TalentKey, "secondary aoe?");
			PushArrayString(TalentValue, "-1.0");
		}
		if (FindStringInArray(TalentKey, "primary aoe?") == -1) {
			PushArrayString(TalentKey, "primary aoe?");
			PushArrayString(TalentValue, "-1.0");
		}
		if (FindStringInArray(TalentKey, "target is self?") == -1) {
			PushArrayString(TalentKey, "target is self?");
			PushArrayString(TalentValue, "-1");
		}
		if (FindStringInArray(TalentKey, "secondary ability trigger?") == -1) {
			PushArrayString(TalentKey, "secondary ability trigger?");
			PushArrayString(TalentValue, "-1");
		}
		if (FindStringInArray(TalentKey, "is own talent?") == -1) {
			PushArrayString(TalentKey, "is own talent?");
			PushArrayString(TalentValue, "-1");
		}
		if (FindStringInArray(TalentKey, "health percentage required missing max?") == -1) {
			PushArrayString(TalentKey, "health percentage required missing max?");
			PushArrayString(TalentValue, "-1.0");
		}
		if (FindStringInArray(TalentKey, "health percentage required missing?") == -1) {
			PushArrayString(TalentKey, "health percentage required missing?");
			PushArrayString(TalentValue, "-1.0");
		}
		if (FindStringInArray(TalentKey, "no effect if damage time is not met?") == -1) {
			PushArrayString(TalentKey, "no effect if damage time is not met?");
			PushArrayString(TalentValue, "-1.0");
		}
		if (FindStringInArray(TalentKey, "strength increase while holding fire?") == -1) {
			PushArrayString(TalentKey, "strength increase while holding fire?");
			PushArrayString(TalentValue, "-1.0");
		}
		if (FindStringInArray(TalentKey, "no effect if zoom time is not met?") == -1) {
			PushArrayString(TalentKey, "no effect if zoom time is not met?");
			PushArrayString(TalentValue, "-1");
		}
		if (FindStringInArray(TalentKey, "strength increase time required?") == -1) {
			PushArrayString(TalentKey, "strength increase time required?");
			PushArrayString(TalentValue, "-1.0");
		}
		if (FindStringInArray(TalentKey, "strength increase time cap?") == -1) {
			PushArrayString(TalentKey, "strength increase time cap?");
			PushArrayString(TalentValue, "-1.0");
		}
		if (FindStringInArray(TalentKey, "strength increase while zoomed?") == -1) {
			PushArrayString(TalentKey, "strength increase while zoomed?");
			PushArrayString(TalentValue, "-1.0");
		}
		if (FindStringInArray(TalentKey, "multiply specials?") == -1) {
			PushArrayString(TalentKey, "multiply specials?");
			PushArrayString(TalentValue, "-1");
		}
		if (FindStringInArray(TalentKey, "multiply survivors?") == -1) {
			PushArrayString(TalentKey, "multiply survivors?");
			PushArrayString(TalentValue, "-1");
		}
		if (FindStringInArray(TalentKey, "multiply witches?") == -1) {
			PushArrayString(TalentKey, "multiply witches?");
			PushArrayString(TalentValue, "-1");
		}
		if (FindStringInArray(TalentKey, "multiply supers?") == -1) {
			PushArrayString(TalentKey, "multiply supers?");
			PushArrayString(TalentValue, "-1");
		}
		if (FindStringInArray(TalentKey, "multiply commons?") == -1) {
			PushArrayString(TalentKey, "multiply commons?");
			PushArrayString(TalentValue, "-1");
		}
		if (FindStringInArray(TalentKey, "multiply range?") == -1) {
			PushArrayString(TalentKey, "multiply range?");
			PushArrayString(TalentValue, "-1.0");
		}
		if (FindStringInArray(TalentKey, "status effect multiplier?") == -1) {
			PushArrayString(TalentKey, "status effect multiplier?");
			PushArrayString(TalentValue, "-1");
		}
		if (FindStringInArray(TalentKey, "background talent?") == -1) {
			PushArrayString(TalentKey, "background talent?");
			PushArrayString(TalentValue, "-1");
		}
		if (FindStringInArray(TalentKey, "require consecutive hits?") == -1) {
			PushArrayString(TalentKey, "require consecutive hits?");
			PushArrayString(TalentValue, "-1");
		}
		if (FindStringInArray(TalentKey, "cleanse trigger?") == -1) {
			PushArrayString(TalentKey, "cleanse trigger?");
			PushArrayString(TalentValue, "-1");
		}
		if (FindStringInArray(TalentKey, "target class required?") == -1) {
			PushArrayString(TalentKey, "target class required?");
			PushArrayString(TalentValue, "-1");
		}
		if (FindStringInArray(TalentKey, "require weakness?") == -1) {
			PushArrayString(TalentKey, "require weakness?");
			PushArrayString(TalentValue, "-1");
		}
		if (FindStringInArray(TalentKey, "disabled if weakness?") == -1) {
			PushArrayString(TalentKey, "disabled if weakness?");
			PushArrayString(TalentValue, "-1");
		}
		if (FindStringInArray(TalentKey, "require adrenaline effect?") == -1) {
			PushArrayString(TalentKey, "require adrenaline effect?");
			PushArrayString(TalentValue, "-1");
		}
		if (FindStringInArray(TalentKey, "target vomit state required?") == -1) {
			PushArrayString(TalentKey, "target vomit state required?");
			PushArrayString(TalentValue, "-1");
		}
		if (FindStringInArray(TalentKey, "vomit state required?") == -1) {
			PushArrayString(TalentKey, "vomit state required?");
			PushArrayString(TalentValue, "-1");
		}
		if (FindStringInArray(TalentKey, "cannot be touching earth?") == -1) {
			PushArrayString(TalentKey, "cannot be touching earth?");
			PushArrayString(TalentValue, "-1");
		}
		if (FindStringInArray(TalentKey, "cannot target self?") == -1) {
			PushArrayString(TalentKey, "cannot target self?");
			PushArrayString(TalentValue, "-1");
		}
		if (FindStringInArray(TalentKey, "target stagger required?") == -1) {
			PushArrayString(TalentKey, "target stagger required?");
			PushArrayString(TalentValue, "-1");
		}
		if (FindStringInArray(TalentKey, "activator stagger required?") == -1) {
			PushArrayString(TalentKey, "activator stagger required?");
			PushArrayString(TalentValue, "-1");
		}
		if (FindStringInArray(TalentKey, "requires crouching?") == -1) {
			PushArrayString(TalentKey, "requires crouching?");
			PushArrayString(TalentValue, "-1");
		}
		if (FindStringInArray(TalentKey, "requires limbshot?") == -1) {
			PushArrayString(TalentKey, "requires limbshot?");
			PushArrayString(TalentValue, "-1");
		}
		if (FindStringInArray(TalentKey, "requires headshot?") == -1) {
			PushArrayString(TalentKey, "requires headshot?");
			PushArrayString(TalentValue, "-1");
		}
		if (FindStringInArray(TalentKey, "passive ability?") == -1) {
			PushArrayString(TalentKey, "passive ability?");
			PushArrayString(TalentValue, "-1");
		}
		if (FindStringInArray(TalentKey, "player state required?") == -1) {
			PushArrayString(TalentKey, "player state required?");
			PushArrayString(TalentValue, "-1");
		}
		if (FindStringInArray(TalentKey, "combat state required?") == -1) {
			PushArrayString(TalentKey, "combat state required?");
			PushArrayString(TalentValue, "-1");
		}
		if (FindStringInArray(TalentKey, "requires zoom?") == -1) {
			PushArrayString(TalentKey, "requires zoom?");
			PushArrayString(TalentValue, "-1");
		}
		if (FindStringInArray(TalentKey, "activator class required?") == -1) {
			PushArrayString(TalentKey, "activator class required?");
			PushArrayString(TalentValue, "-1");
		}
		if (FindStringInArray(TalentKey, "activator team required?") == -1) {
			PushArrayString(TalentKey, "activator team required?");
			PushArrayString(TalentValue, "-1");
		}
		if (FindStringInArray(TalentKey, "health percentage missing required target?") == -1) {
			PushArrayString(TalentKey, "health percentage missing required target?");
			PushArrayString(TalentValue, "-1.0");
		}
		if (FindStringInArray(TalentKey, "health percentage remaining required target?") == -1) {
			PushArrayString(TalentKey, "health percentage remaining required target?");
			PushArrayString(TalentValue, "-1.0");
		}
		if (FindStringInArray(TalentKey, "coherency required?") == -1) {
			PushArrayString(TalentKey, "coherency required?");
			PushArrayString(TalentValue, "-1");
		}
		if (FindStringInArray(TalentKey, "coherency max?") == -1) {
			PushArrayString(TalentKey, "coherency max?");
			PushArrayString(TalentValue, "-1");
		}
		if (FindStringInArray(TalentKey, "coherency range?") == -1) {
			PushArrayString(TalentKey, "coherency range?");
			PushArrayString(TalentValue, "-1.0");
		}
		if (FindStringInArray(TalentKey, "health percentage required?") == -1) {
			PushArrayString(TalentKey, "health percentage required?");
			PushArrayString(TalentValue, "-1.0");
		}
		if (FindStringInArray(TalentKey, "weapons permitted?") == -1) {
			PushArrayString(TalentKey, "weapons permitted?");
			PushArrayString(TalentValue, "-1");
		}
		if (FindStringInArray(TalentKey, "secondary effects?") == -1) {
			PushArrayString(TalentKey, "secondary effects?");
			PushArrayString(TalentValue, "-1");
		}
		if (FindStringInArray(TalentKey, "target ability effects?") == -1) {
			PushArrayString(TalentKey, "target ability effects?");
			PushArrayString(TalentValue, "-1");
		}
		if (FindStringInArray(TalentKey, "activator ability effects?") == -1) {
			PushArrayString(TalentKey, "activator ability effects?");
			PushArrayString(TalentValue, "-1");
		}
		if (FindStringInArray(TalentKey, "compound with?") == -1) {
			PushArrayString(TalentKey, "compound with?");
			PushArrayString(TalentValue, "-1");
		}
		if (FindStringInArray(TalentKey, "compounding talent?") == -1) {
			PushArrayString(TalentKey, "compounding talent?");
			PushArrayString(TalentValue, "-1");
		}
		if (FindStringInArray(TalentKey, "ability type?") == -1) {
			PushArrayString(TalentKey, "ability type?");
			PushArrayString(TalentValue, "-1");
		}
		sortSize = GetArraySize(TalentKey);
		pos = 0;
		while (pos < sortSize) {
			GetArrayString(TalentKey, pos, text, sizeof(text));
			if (
			pos == 0 && !StrEqual(text, "ability type?") ||
			pos == 1 && !StrEqual(text, "compounding talent?") ||
			pos == 2 && !StrEqual(text, "compound with?") ||
			pos == 3 && !StrEqual(text, "activator ability effects?") ||
			pos == 4 && !StrEqual(text, "target ability effects?") ||
			pos == 5 && !StrEqual(text, "secondary effects?") ||
			pos == 6 && !StrEqual(text, "weapons permitted?") ||
			pos == 7 && !StrEqual(text, "health percentage required?") ||
			pos == 8 && !StrEqual(text, "coherency range?") ||
			pos == 9 && !StrEqual(text, "coherency max?") ||
			pos == 10 && !StrEqual(text, "coherency required?") ||
			pos == 11 && !StrEqual(text, "health percentage remaining required target?") ||
			pos == 12 && !StrEqual(text, "health percentage missing required target?") ||
			pos == 13 && !StrEqual(text, "activator team required?") ||
			pos == 14 && !StrEqual(text, "activator class required?") ||
			pos == 15 && !StrEqual(text, "requires zoom?") ||
			pos == 16 && !StrEqual(text, "combat state required?") ||
			pos == 17 && !StrEqual(text, "player state required?") ||
			pos == 18 && !StrEqual(text, "passive ability?") ||
			pos == 19 && !StrEqual(text, "requires headshot?") ||
			pos == 20 && !StrEqual(text, "requires limbshot?") ||
			pos == 21 && !StrEqual(text, "requires crouching?") ||
			pos == 22 && !StrEqual(text, "activator stagger required?") ||
			pos == 23 && !StrEqual(text, "target stagger required?") ||
			pos == 24 && !StrEqual(text, "cannot target self?") ||
			pos == 25 && !StrEqual(text, "cannot be touching earth?") ||
			pos == 26 && !StrEqual(text, "vomit state required?") ||
			pos == 27 && !StrEqual(text, "target vomit state required?") ||
			pos == 28 && !StrEqual(text, "require adrenaline effect?") ||
			pos == 29 && !StrEqual(text, "disabled if weakness?") ||
			pos == 30 && !StrEqual(text, "require weakness?") ||
			pos == 31 && !StrEqual(text, "target class required?") ||
			pos == 32 && !StrEqual(text, "cleanse trigger?") ||
			pos == 33 && !StrEqual(text, "require consecutive hits?") ||
			pos == 34 && !StrEqual(text, "background talent?") ||
			pos == 35 && !StrEqual(text, "status effect multiplier?") ||
			pos == 36 && !StrEqual(text, "multiply range?") ||
			pos == 37 && !StrEqual(text, "multiply commons?") ||
			pos == 38 && !StrEqual(text, "multiply supers?") ||
			pos == 39 && !StrEqual(text, "multiply witches?") ||
			pos == 40 && !StrEqual(text, "multiply survivors?") ||
			pos == 41 && !StrEqual(text, "multiply specials?") ||
			pos == 42 && !StrEqual(text, "strength increase while zoomed?") ||
			pos == 43 && !StrEqual(text, "strength increase time cap?") ||
			pos == 44 && !StrEqual(text, "strength increase time required?") ||
			pos == 45 && !StrEqual(text, "no effect if zoom time is not met?") ||
			pos == 46 && !StrEqual(text, "strength increase while holding fire?") ||
			pos == 47 && !StrEqual(text, "no effect if damage time is not met?") ||
			pos == 48 && !StrEqual(text, "health percentage required missing?") ||
			pos == 49 && !StrEqual(text, "health percentage required missing max?") ||
			pos == 50 && !StrEqual(text, "is own talent?") ||
			pos == 51 && !StrEqual(text, "secondary ability trigger?") ||
			pos == 52 && !StrEqual(text, "target is self?") ||
			pos == 53 && !StrEqual(text, "primary aoe?") ||
			pos == 54 && !StrEqual(text, "secondary aoe?") ||
			pos == 55 && !StrEqual(text, "talent name?") ||
			pos == 56 && !StrEqual(text, "translation?") ||
			pos == 57 && !StrEqual(text, "governing attribute?") ||
			pos == 58 && !StrEqual(text, "talent tree category?") ||
			pos == 59 && !StrEqual(text, "part of menu named?") ||
			pos == 60 && !StrEqual(text, "layer?") ||
			pos == 61 && !StrEqual(text, "is ability?") ||
			pos == 62 && !StrEqual(text, "action bar name?") ||
			pos == 63 && !StrEqual(text, "required talents required?") ||
			pos == 64 && !StrEqual(text, "talent upgrade strength value?") ||
			pos == 65 && !StrEqual(text, "talent upgrade scale?") ||
			pos == 66 && !StrEqual(text, "talent cooldown strength value?") ||
			pos == 67 && !StrEqual(text, "talent cooldown scale?") ||
			pos == 68 && !StrEqual(text, "talent active time strength value?") ||
			pos == 69 && !StrEqual(text, "talent active time scale?") ||
			pos == 70 && !StrEqual(text, "governs cooldown of talent named?") ||
			pos == 71 && !StrEqual(text, "talent hard limit?") ||
			pos == 72 && !StrEqual(text, "is effect over time?") ||
			pos == 73 && !StrEqual(text, "effect strength?") ||
			pos == 74 && !StrEqual(text, "ignore for layer count?") ||
			pos == 75 && !StrEqual(text, "is attribute?") ||
			pos == 76 && !StrEqual(text, "hide translation?") ||
			pos == 77 && !StrEqual(text, "roll chance?")) {
				ResizeArray(TalentKey, sortSize+1);
				ResizeArray(TalentValue, sortSize+1);
				SetArrayString(TalentKey, sortSize, text);
				GetArrayString(TalentValue, pos, text, sizeof(text));
				SetArrayString(TalentValue, sortSize, text);
				RemoveFromArray(TalentKey, pos);
				RemoveFromArray(TalentValue, pos);
				continue;
			}	// had to split this argument up due to internal compiler error on arguments exceeding 80
			else if (
			pos == 78 && !StrEqual(text, "interval per point?") ||
			pos == 79 && !StrEqual(text, "interval first point?") ||
			pos == 80 && !StrEqual(text, "range per point?") ||
			pos == 81 && !StrEqual(text, "range first point value?") ||
			pos == 82 && !StrEqual(text, "stamina per point?") ||
			pos == 83 && !StrEqual(text, "base stamina required?") ||
			pos == 84 && !StrEqual(text, "cooldown per point?") ||
			pos == 85 && !StrEqual(text, "cooldown first point?") ||
			pos == 86 && !StrEqual(text, "cooldown start?") ||
			pos == 87 && !StrEqual(text, "active time per point?") ||
			pos == 88 && !StrEqual(text, "active time first point?") ||
			pos == 89 && !StrEqual(text, "ammo effect?") ||
			pos == 90 && !StrEqual(text, "effect multiplier?") ||
			pos == 91 && !StrEqual(text, "active effect?") ||
			pos == 92 && !StrEqual(text, "passive effect?") ||
			pos == 93 && !StrEqual(text, "cooldown effect?") ||
			pos == 94 && !StrEqual(text, "reactive ability?") ||
			pos == 95 && !StrEqual(text, "teams allowed?") ||
			pos == 96 && !StrEqual(text, "cooldown strength?") ||
			pos == 97 && !StrEqual(text, "maximum passive multiplier?") ||
			pos == 98 && !StrEqual(text, "maximum active multiplier?") ||
			pos == 99 && !StrEqual(text, "active requires ensnare?") ||
			pos == 100 && !StrEqual(text, "active strength?") ||
			pos == 101 && !StrEqual(text, "passive ignores cooldown?") ||
			pos == 102 && !StrEqual(text, "passive requires ensnare?") ||
			pos == 103 && !StrEqual(text, "passive strength?") ||
			pos == 104 && !StrEqual(text, "passive only?") ||
			pos == 105 && !StrEqual(text, "is single target?") ||
			pos == 106 && !StrEqual(text, "draw delay?") ||
			pos == 107 && !StrEqual(text, "draw effect delay?") ||
			pos == 108 && !StrEqual(text, "passive draw delay?") ||
			pos == 109 && !StrEqual(text, "attribute?") ||
			pos == 110 && !StrEqual(text, "use these multipliers?") ||
			pos == 111 && !StrEqual(text, "base multiplier?") ||
			pos == 112 && !StrEqual(text, "diminishing multiplier?") ||
			pos == 113 && !StrEqual(text, "diminishing returns?") ||
			pos == 114 && !StrEqual(text, "buff bar text?") ||
			pos == 115 && !StrEqual(text, "is sub menu?") ||
			pos == 116 && !StrEqual(text, "talent type?") ||
			pos == 117 && !StrEqual(text, "is item?") ||
			pos == 118 && !StrEqual(text, "rarity?") ||
			pos == 119 && !StrEqual(text, "experience start?") ||
			pos == 120 && !StrEqual(text, "requirement multiplier?") ||
			pos == 121 && !StrEqual(text, "is aura instead?") ||
			pos == 122 && !StrEqual(text, "cooldown trigger?") ||
			pos == 123 && !StrEqual(text, "inactive trigger?") ||
			pos == 124 && !StrEqual(text, "reactive type?") ||
			pos == 125 && !StrEqual(text, "active time?") ||
			pos == 126 && !StrEqual(text, "cannot be ensnared?") ||
			pos == 127 && !StrEqual(text, "sky level requirement?") ||
			pos == 128 && !StrEqual(text, "toggle effect?") ||
			pos == 129 && !StrEqual(text, "humanoid only?") ||
			pos == 130 && !StrEqual(text, "inanimate only?") ||
			pos == 131 && !StrEqual(text, "allow commons?") ||
			pos == 132 && !StrEqual(text, "allow specials?") ||
			pos == 133 && !StrEqual(text, "allow survivors?") ||
			pos == 134 && !StrEqual(text, "cooldown?") ||
			pos == 135 && !StrEqual(text, "activate effect per tick?") ||
			pos == 136 && !StrEqual(text, "secondary ept only?") ||
			pos == 137 && !StrEqual(text, "active end ability trigger?") ||
			pos == 138 && !StrEqual(text, "cooldown end ability trigger?") ||
			pos == 139 && !StrEqual(text, "does damage?") ||
			pos == 140 && !StrEqual(text, "special ammo?")) {
				ResizeArray(TalentKey, sortSize+1);
				ResizeArray(TalentValue, sortSize+1);
				SetArrayString(TalentKey, sortSize, text);
				GetArrayString(TalentValue, pos, text, sizeof(text));
				SetArrayString(TalentValue, sortSize, text);
				RemoveFromArray(TalentKey, pos);
				RemoveFromArray(TalentValue, pos);
				continue;
			}
			else if (
			pos == 141 && !StrEqual(text, "minimum level required?") ||
			pos == 142 && !StrEqual(text, "toggle strength?") ||
			pos == 143 && !StrEqual(text, "target class must be last target class?") ||
			pos == 144 && !StrEqual(text, "target range required?") ||
			pos == 145 && !StrEqual(text, "target must be outside range required?") ||
			pos == 146 && !StrEqual(text, "target must be last target?") ||
			pos == 147 && !StrEqual(text, "requires activator on fire?") ||			// [Bu]
			pos == 148 && !StrEqual(text, "requires activator acid burn?") ||		// [Ab]
			pos == 149 && !StrEqual(text, "requires activator exploding?") ||		// [Ex]
			pos == 150 && !StrEqual(text, "requires activator slowed?") ||			// [Sl]
			pos == 151 && !StrEqual(text, "requires activator frozen?") ||			// [Fr]
			pos == 152 && !StrEqual(text, "requires activator scorched?") ||		// [Sc]
			pos == 153 && !StrEqual(text, "requires activator steaming?") ||		// [St]
			pos == 154 && !StrEqual(text, "requires activator drowning?") ||		// [Wa]
			pos == 155 && !StrEqual(text, "activator high ground?") ||
			pos == 156 && !StrEqual(text, "target high ground?") ||
			pos == 157 && !StrEqual(text, "activator neither high or low ground?") ||
			pos == 158 && !StrEqual(text, "target must be in the air?") ||
			pos == 159 && !StrEqual(text, "event type?") ||
			pos == 160 && !StrEqual(text, "last hit must be headshot?") ||
			pos == 161 && !StrEqual(text, "mult str by same hits?") ||
			pos == 162 && !StrEqual(text, "mult str max same hits?") ||
			pos == 163 && !StrEqual(text, "mult str div same hits?") ||
			pos == 164 && !StrEqual(text, "contribution category required?") ||
			pos == 165 && !StrEqual(text, "contribution cost required?") ||
			pos == 166 && !StrEqual(text, "give player this item on trigger?") ||
			pos == 167 && !StrEqual(text, "hide talent strength display?") ||
			pos == 168 && !StrEqual(text, "ability trigger to call?") ||
			pos == 169 && !StrEqual(text, "weapon slot required?") ||
			pos == 170 && !StrEqual(text, "require consecutive headshots?") ||
			pos == 171 && !StrEqual(text, "mult str by same headshots?") ||
			pos == 172 && !StrEqual(text, "mult str max same headshots?") ||
			pos == 173 && !StrEqual(text, "mult str div same headshots?") ||
			pos == 174 && !StrEqual(text, "active effect allows all weapons?") ||
			pos == 175 && !StrEqual(text, "active effect allows all hitgroups?") ||
			pos == 176 && !StrEqual(text, "active effect allows all classes?") ||
			pos == 177 && !StrEqual(text, "activator status effect required?")) {
				ResizeArray(TalentKey, sortSize+1);
				ResizeArray(TalentValue, sortSize+1);
				SetArrayString(TalentKey, sortSize, text);
				GetArrayString(TalentValue, pos, text, sizeof(text));
				SetArrayString(TalentValue, sortSize, text);
				RemoveFromArray(TalentKey, pos);
				RemoveFromArray(TalentValue, pos);
				continue;
			}
			pos++;
		}
		for (int i = 0; i < sortSize; i++) {
			if (i == TALENT_IS_EFFECT_OVER_TIME || i == TARGET_CLASS_REQ || i == ABILITY_TYPE ||
			i == IF_EOT_ACTIVE_ALLOW_ALL_ENEMIES || i == COMBAT_STATE_REQ || i == CONTRIBUTION_TYPE_CATEGORY ||
			i == CONTRIBUTION_COST || i == TALENT_WEAPON_SLOT_REQUIRED || i == LAST_KILL_MUST_BE_HEADSHOT ||
			i == TARGET_AND_LAST_TARGET_CLASS_MATCH || i == TARGET_RANGE_REQUIRED || i == TARGET_RANGE_REQUIRED_OUTSIDE ||
			i == TARGET_MUST_BE_LAST_TARGET || i == TARGET_MUST_BE_IN_THE_AIR || i == TARGET_IS_SELF ||
			i == ACTIVATOR_STATUS_EFFECT_REQUIRED || i == ACTIVATOR_MUST_BE_ON_FIRE || i == ACTIVATOR_MUST_SUFFER_ACID_BURN ||
			i == ACTIVATOR_MUST_BE_EXPLODING || i == ACTIVATOR_MUST_BE_SLOW || i == ACTIVATOR_MUST_BE_FROZEN ||
			i == ACTIVATOR_MUST_BE_SCORCHED || i == ACTIVATOR_MUST_BE_STEAMING || i == ACTIVATOR_MUST_BE_DROWNING ||
			i == ACTIVATOR_MUST_HAVE_HIGH_GROUND || i == TARGET_MUST_HAVE_HIGH_GROUND || i == ACTIVATOR_TARGET_MUST_EVEN_GROUND ||
			i == IF_EOT_ACTIVE_ALLOW_ALL_WEAPONS || i == WEAPONS_PERMITTED || i == HEALTH_PERCENTAGE_REQ ||
			i == COHERENCY_RANGE || i == COHERENCY_MAX || i == COHERENCY_REQ ||
			i == HEALTH_PERCENTAGE_REQ_TAR_REMAINING || i == HEALTH_PERCENTAGE_REQ_TAR_MISSING ||
			i == REQUIRES_ZOOM || i == IF_EOT_ACTIVE_ALLOW_ALL_HITGROUPS || i == REQUIRES_HEADSHOT ||
			i == REQUIRES_LIMBSHOT) {
				GetArrayString(TalentValue, i, text, sizeof(text));
				if (StrContains(text, ".") != -1) SetArrayCell(TalentValue, i, StringToFloat(text));	//float
				else SetArrayCell(TalentValue, i, StringToInt(text));	//int
			}
			else if (i == REQUIRES_CROUCHING || i == ACTIVATOR_STAGGER_REQ || i == TARGET_STAGGER_REQ ||
			i == CANNOT_TARGET_SELF || i == MUST_BE_JUMPING_OR_FLYING || i == VOMIT_STATE_REQ_ACTIVATOR ||
			i == VOMIT_STATE_REQ_TARGET || i == REQ_ADRENALINE_EFFECT || i == DISABLE_IF_WEAKNESS ||
			i == REQ_WEAKNESS || i == CLEANSE_TRIGGER || i == REQ_CONSECUTIVE_HITS ||
			i == REQ_CONSECUTIVE_HEADSHOTS || i == MULT_STR_CONSECUTIVE_HITS || i == MULT_STR_CONSECUTIVE_MAX ||
			i == MULT_STR_CONSECUTIVE_DIV || i == MULT_STR_CONSECUTIVE_HEADSHOTS ||
			i == MULT_STR_CONSECUTIVE_HEADSHOTS_MAX || i == MULT_STR_CONSECUTIVE_HEADSHOTS_DIV ||
			i == BACKGROUND_TALENT || i == STATUS_EFFECT_MULTIPLIER || i == MULTIPLY_RANGE ||
			i == MULTIPLY_COMMONS || i == MULTIPLY_SUPERS || i == MULTIPLY_WITCHES || i == MULTIPLY_SURVIVORS ||
			i == MULTIPLY_SPECIALS || i == STRENGTH_INCREASE_ZOOMED || i == STRENGTH_INCREASE_TIME_CAP ||
			i == STRENGTH_INCREASE_TIME_REQ || i == ZOOM_TIME_HAS_MINIMUM_REQ ||
			i == HOLDING_FIRE_STRENGTH_INCREASE || i == STRENGTH_INCREASE_TIME_CAP || i == STRENGTH_INCREASE_TIME_REQ ||
			i == DAMAGE_TIME_HAS_MINIMUM_REQ || i == HEALTH_PERCENTAGE_REQ_MISSING ||
			i == HEALTH_PERCENTAGE_REQ_MISSING_MAX || i == CLEANSE_TRIGGER || i == IS_OWN_TALENT ||
			i == TALENT_ACTIVE_STRENGTH_VALUE || i == PRIMARY_AOE || i == SECONDARY_AOE) {
				GetArrayString(TalentValue, i, text, sizeof(text));
				if (StrContains(text, ".") != -1) SetArrayCell(TalentValue, i, StringToFloat(text));	//float
				else SetArrayCell(TalentValue, i, StringToInt(text));	//int
			}
			else if (i == GET_TALENT_LAYER || i == IS_ATTRIBUTE || i == LAYER_COUNTING_IS_IGNORED ||
			i == ATTRIBUTE_BASE_MULTIPLIER || i == IS_SUB_MENU_OF_TALENTCONFIG || i == IS_TALENT_TYPE ||
			i == OLD_ATTRIBUTE_EXPERIENCE_START || i == OLD_ATTRIBUTE_EXPERIENCE_MULTIPLIER || i == IS_AURA_INSTEAD ||
			i == ABILITY_IS_REACTIVE || i == IS_TALENT_ABILITY || i == ABILITY_COOLDOWN_STRENGTH ||
			i == ABILITY_MAXIMUM_PASSIVE_MULTIPLIER || i == ABILITY_MAXIMUM_ACTIVE_MULTIPLIER ||
			i == ABILITY_ACTIVE_STATE_ENSNARE_REQ || i == ABILITY_ACTIVE_STRENGTH || i == ABILITY_PASSIVE_IGNORES_COOLDOWN ||
			i == ABILITY_PASSIVE_STATE_ENSNARE_REQ || i == ABILITY_PASSIVE_STRENGTH || i == SPELL_ACTIVE_TIME_FIRST_POINT ||
			i == SPELL_ACTIVE_TIME_PER_POINT || i == SPELL_COOLDOWN_START || i == SPELL_COOLDOWN_FIRST_POINT ||
			i == SPELL_COOLDOWN_PER_POINT || i == SPELL_BASE_STAMINA_REQ || i == SPELL_STAMINA_PER_POINT ||
			i == SPELL_RANGE_FIRST_POINT || i == SPELL_RANGE_PER_POINT || i == SPELL_INTERVAL_FIRST_POINT ||
			i == SPELL_INTERVAL_PER_POINT || i == ABILITY_REQ_NO_ENSNARE || i == ABILITY_SKY_LEVEL_REQ || i == ABILITY_ACTIVE_TIME ||
			i == ABILITY_REACTIVE_TYPE || i == SPELL_HUMANOID_ONLY || i == SPELL_INANIMATE_ONLY || i == SPELL_ALLOW_COMMONS ||
			i == SPELL_ALLOW_SPECIALS || i == SPELL_ALLOW_SURVIVORS || i == ABILITY_DRAW_DELAY || i == ABILITY_IS_SINGLE_TARGET ||
			i == ABILITY_PASSIVE_ONLY || i == ITEM_ITEM_ID || i == ITEM_RARITY) {
				GetArrayString(TalentValue, i, text, sizeof(text));
				if (StrContains(text, ".") != -1) SetArrayCell(TalentValue, i, StringToFloat(text));	//float
				else SetArrayCell(TalentValue, i, StringToInt(text));	//int
			}
			else if (i == ABILITY_EVENT_TYPE || i == TALENT_IS_SPELL || i == TALENT_MINIMUM_LEVEL_REQ || i == NUM_TALENTS_REQ ||
			i == HIDE_TALENT_STRENGTH_DISPLAY || i == HIDE_TRANSLATION || i == ABILITY_ACTIVE_DRAW_DELAY ||
			i == ABILITY_PASSIVE_DRAW_DELAY || i == TALENT_ROLL_CHANCE || i == SPECIAL_AMMO_TALENT_STRENGTH ||
			i == ABILITY_TOGGLE_STRENGTH || i == ABILITY_COOLDOWN || i == SPELL_EFFECT_MULTIPLIER || i == COMPOUNDING_TALENT) {
				GetArrayString(TalentValue, i, text, sizeof(text));
				if (StrContains(text, ".") != -1) SetArrayCell(TalentValue, i, StringToFloat(text));	//float
				else SetArrayCell(TalentValue, i, StringToInt(text));	//int
			}
		}
		if (setConfigArraysDebugger) {
			LogMessage("--------------------------------------------------------------");
			LogMessage("%s loaded successfully.", talentName);
			LogMessage("# of keyvalues is %d", GetArraySize(TalentKey));
			for (int i = 0; i < GetArraySize(TalentKey); i++) {
				char text1[64];
				char text2[64];
				GetArrayString(TalentKey, i, text1, sizeof(text1));
				GetArrayString(TalentValue, i, text2, sizeof(text2));
				LogMessage("\"%s\"\t\t\t\t\"%s\"", text1, text2);
			}
		}
	}
	else if (StrEqual(Config, CONFIG_EVENTS)) {
		if (FindStringInArray(TalentKey, "entered saferoom?") == -1) {
			PushArrayString(TalentKey, "entered saferoom?");
			PushArrayString(TalentValue, "-1");
		}
		if (FindStringInArray(TalentKey, "bulletimpact?") == -1) {
			PushArrayString(TalentKey, "bulletimpact?");
			PushArrayString(TalentValue, "-1");
		}
		if (FindStringInArray(TalentKey, "shoved?") == -1) {
			PushArrayString(TalentKey, "shoved?");
			PushArrayString(TalentValue, "-1");
		}
		if (FindStringInArray(TalentKey, "multiplier exp?") == -1) {
			PushArrayString(TalentKey, "multiplier exp?");
			PushArrayString(TalentValue, "-1");
		}
		if (FindStringInArray(TalentKey, "multiplier points?") == -1) {
			PushArrayString(TalentKey, "multiplier points?");
			PushArrayString(TalentValue, "-1");
		}
		if (FindStringInArray(TalentKey, "distance?") == -1) {
			PushArrayString(TalentKey, "distance?");
			PushArrayString(TalentValue, "-1");
		}
		if (FindStringInArray(TalentKey, "origin?") == -1) {
			PushArrayString(TalentKey, "origin?");
			PushArrayString(TalentValue, "-1");
		}
		if (FindStringInArray(TalentKey, "tag ability?") == -1) {
			PushArrayString(TalentKey, "tag ability?");
			PushArrayString(TalentValue, "-1");
		}
		if (FindStringInArray(TalentKey, "abilities?") == -1) {
			PushArrayString(TalentKey, "abilities?");
			PushArrayString(TalentValue, "-1");
		}
		if (FindStringInArray(TalentKey, "damage award?") == -1) {
			PushArrayString(TalentKey, "damage award?");
			PushArrayString(TalentValue, "-1");
		}
		if (FindStringInArray(TalentKey, "health?") == -1) {
			PushArrayString(TalentKey, "health?");
			PushArrayString(TalentValue, "-1");
		}
		if (FindStringInArray(TalentKey, "damage type?") == -1) {
			PushArrayString(TalentKey, "damage type?");
			PushArrayString(TalentValue, "-1");
		}
		if (FindStringInArray(TalentKey, "victim ability trigger?") == -1) {
			PushArrayString(TalentKey, "victim ability trigger?");
			PushArrayString(TalentValue, "-1");
		}
		if (FindStringInArray(TalentKey, "victim team required?") == -1) {
			PushArrayString(TalentKey, "victim team required?");
			PushArrayString(TalentValue, "-1");
		}
		if (FindStringInArray(TalentKey, "perpetrator ability trigger?") == -1) {
			PushArrayString(TalentKey, "perpetrator ability trigger?");
			PushArrayString(TalentValue, "-1");
		}
		if (FindStringInArray(TalentKey, "perpetrator team required?") == -1) {
			PushArrayString(TalentKey, "perpetrator team required?");
			PushArrayString(TalentValue, "-1");
		}
		if (FindStringInArray(TalentKey, "same team event trigger?") == -1) {
			PushArrayString(TalentKey, "same team event trigger?");
			PushArrayString(TalentValue, "-1");
		}
		if (FindStringInArray(TalentKey, "victim?") == -1) {
			PushArrayString(TalentKey, "victim?");
			PushArrayString(TalentValue, "-1");
		}
		if (FindStringInArray(TalentKey, "perpetrator?") == -1) {
			PushArrayString(TalentKey, "perpetrator?");
			PushArrayString(TalentValue, "-1");
		}
		sortSize = GetArraySize(TalentKey);
		pos = 0;
		while (pos < sortSize) {
			GetArrayString(TalentKey, pos, text, sizeof(text));
			if (
			pos == 0 && !StrEqual(text, "perpetrator?") ||
			pos == 1 && !StrEqual(text, "victim?") ||
			pos == 2 && !StrEqual(text, "same team event trigger?") ||
			pos == 3 && !StrEqual(text, "perpetrator team required?") ||
			pos == 4 && !StrEqual(text, "perpetrator ability trigger?") ||
			pos == 5 && !StrEqual(text, "victim team required?") ||
			pos == 6 && !StrEqual(text, "victim ability trigger?") ||
			pos == 7 && !StrEqual(text, "damage type?") ||
			pos == 8 && !StrEqual(text, "health?") ||
			pos == 9 && !StrEqual(text, "damage award?") ||
			pos == 10 && !StrEqual(text, "abilities?") ||
			pos == 11 && !StrEqual(text, "tag ability?") ||
			pos == 12 && !StrEqual(text, "origin?") ||
			pos == 13 && !StrEqual(text, "distance?") ||
			pos == 14 && !StrEqual(text, "multiplier points?") ||
			pos == 15 && !StrEqual(text, "multiplier exp?") ||
			pos == 16 && !StrEqual(text, "shoved?") ||
			pos == 17 && !StrEqual(text, "bulletimpact?") ||
			pos == 18 && !StrEqual(text, "entered saferoom?")) {
				ResizeArray(TalentKey, sortSize+1);
				ResizeArray(TalentValue, sortSize+1);
				SetArrayString(TalentKey, sortSize, text);
				GetArrayString(TalentValue, pos, text, sizeof(text));
				SetArrayString(TalentValue, sortSize, text);
				RemoveFromArray(TalentKey, pos);
				RemoveFromArray(TalentValue, pos);
				continue;
			}
			pos++;
		}
		for (int i = 0; i < sortSize; i++) {
			if (i == EVENT_DAMAGE_AWARD || i == EVENT_IS_PLAYER_NOW_IT || i == EVENT_IS_ORIGIN ||
			i == EVENT_IS_DISTANCE || i == EVENT_MULTIPLIER_POINTS || i == EVENT_MULTIPLIER_EXPERIENCE ||
			i == EVENT_IS_SHOVED || i == EVENT_IS_BULLET_IMPACT || i == EVENT_ENTERED_SAFEROOM ||
			i == EVENT_SAMETEAM_TRIGGER) {
				GetArrayString(TalentValue, i, text, sizeof(text));
				if (StrContains(text, ".") != -1) SetArrayCell(TalentValue, i, StringToFloat(text));	//float
				else SetArrayCell(TalentValue, i, StringToInt(text));	//int
			}
		}
	}
	else if (StrEqual(Config, CONFIG_COMMONAFFIXES)) {
		if (FindStringInArray(TalentKey, "require bile?") == -1) {
			PushArrayString(TalentKey, "require bile?");
			PushArrayString(TalentValue, "-1");
		}
		if (FindStringInArray(TalentKey, "raw player strength?") == -1) {
			PushArrayString(TalentKey, "raw player strength?");
			PushArrayString(TalentValue, "-1");
		}
		if (FindStringInArray(TalentKey, "raw common strength?") == -1) {
			PushArrayString(TalentKey, "raw common strength?");
			PushArrayString(TalentValue, "-1");
		}
		if (FindStringInArray(TalentKey, "raw strength?") == -1) {
			PushArrayString(TalentKey, "raw strength?");
			PushArrayString(TalentValue, "-1");
		}
		if (FindStringInArray(TalentKey, "strength special?") == -1) {
			PushArrayString(TalentKey, "strength special?");
			PushArrayString(TalentValue, "-1.0");
		}
		if (FindStringInArray(TalentKey, "onfire interval?") == -1) {
			PushArrayString(TalentKey, "onfire interval?");
			PushArrayString(TalentValue, "-1.0");
		}
		if (FindStringInArray(TalentKey, "onfire max time?") == -1) {
			PushArrayString(TalentKey, "onfire max time?");
			PushArrayString(TalentValue, "-1.0");
		}
		if (FindStringInArray(TalentKey, "onfire level?") == -1) {
			PushArrayString(TalentKey, "onfire level?");
			PushArrayString(TalentValue, "-1.0");
		}
		if (FindStringInArray(TalentKey, "onfire base time?") == -1) {
			PushArrayString(TalentKey, "onfire base time?");
			PushArrayString(TalentValue, "-1.0");
		}
		if (FindStringInArray(TalentKey, "enemy multiplication?") == -1) {
			PushArrayString(TalentKey, "enemy multiplication?");
			PushArrayString(TalentValue, "-1");
		}
		if (FindStringInArray(TalentKey, "damage effect?") == -1) {
			PushArrayString(TalentKey, "damage effect?");
			PushArrayString(TalentValue, "-1");
		}
		if (FindStringInArray(TalentKey, "force model?") == -1) {
			PushArrayString(TalentKey, "force model?");
			PushArrayString(TalentValue, "-1");
		}
		if (FindStringInArray(TalentKey, "level required?") == -1) {
			PushArrayString(TalentKey, "level required?");
			PushArrayString(TalentValue, "-1");
		}
		if (FindStringInArray(TalentKey, "death multiplier?") == -1) {
			PushArrayString(TalentKey, "death multiplier?");
			PushArrayString(TalentValue, "-1.0");
		}
		if (FindStringInArray(TalentKey, "death interval?") == -1) {
			PushArrayString(TalentKey, "death interval?");
			PushArrayString(TalentValue, "-1.0");
		}
		if (FindStringInArray(TalentKey, "death max time?") == -1) {
			PushArrayString(TalentKey, "death max time?");
			PushArrayString(TalentValue, "-1.0");
		}
		if (FindStringInArray(TalentKey, "death base time?") == -1) {
			PushArrayString(TalentKey, "death base time?");
			PushArrayString(TalentValue, "-1.0");
		}
		if (FindStringInArray(TalentKey, "death effect?") == -1) {
			PushArrayString(TalentKey, "death effect?");
			PushArrayString(TalentValue, "-1");
		}
		if (FindStringInArray(TalentKey, "chain reaction?") == -1) {
			PushArrayString(TalentKey, "chain reaction?");
			PushArrayString(TalentValue, "-1");
		}
		if (FindStringInArray(TalentKey, "name?") == -1) {
			PushArrayString(TalentKey, "name?");
			PushArrayString(TalentValue, "-1");
		}
		if (FindStringInArray(TalentKey, "health per level?") == -1) {
			PushArrayString(TalentKey, "health per level?");
			PushArrayString(TalentValue, "-1.0");
		}
		if (FindStringInArray(TalentKey, "base health?") == -1) {
			PushArrayString(TalentKey, "base health?");
			PushArrayString(TalentValue, "-1");
		}
		if (FindStringInArray(TalentKey, "glow colour?") == -1) {
			PushArrayString(TalentKey, "glow colour?");
			PushArrayString(TalentValue, "-1");
		}
		if (FindStringInArray(TalentKey, "glow range?") == -1) {
			PushArrayString(TalentKey, "glow range?");
			PushArrayString(TalentValue, "-1.0");
		}
		if (FindStringInArray(TalentKey, "glow?") == -1) {
			PushArrayString(TalentKey, "glow?");
			PushArrayString(TalentValue, "-1");
		}
		if (FindStringInArray(TalentKey, "model size?") == -1) {
			PushArrayString(TalentKey, "model size?");
			PushArrayString(TalentValue, "-1.0");
		}
		if (FindStringInArray(TalentKey, "fire immunity?") == -1) {
			PushArrayString(TalentKey, "fire immunity?");
			PushArrayString(TalentValue, "-1");
		}
		if (FindStringInArray(TalentKey, "draw type?") == -1) {
			PushArrayString(TalentKey, "draw type?");
			PushArrayString(TalentValue, "-1");
		}
		if (FindStringInArray(TalentKey, "chance?") == -1) {
			PushArrayString(TalentKey, "chance?");
			PushArrayString(TalentValue, "-1.0");
		}
		if (FindStringInArray(TalentKey, "level strength?") == -1) {
			PushArrayString(TalentKey, "level strength?");
			PushArrayString(TalentValue, "-1.0");
		}
		if (FindStringInArray(TalentKey, "strength target?") == -1) {
			PushArrayString(TalentKey, "strength target?");
			PushArrayString(TalentValue, "-1.0");
		}
		if (FindStringInArray(TalentKey, "aura strength?") == -1) {
			PushArrayString(TalentKey, "aura strength?");
			PushArrayString(TalentValue, "-1");
		}
		if (FindStringInArray(TalentKey, "cooldown?") == -1) {
			PushArrayString(TalentKey, "cooldown?");
			PushArrayString(TalentValue, "-1.0");
		}
		if (FindStringInArray(TalentKey, "range max?") == -1) {
			PushArrayString(TalentKey, "range max?");
			PushArrayString(TalentValue, "-1.0");
		}
		if (FindStringInArray(TalentKey, "range player level?") == -1) {
			PushArrayString(TalentKey, "range player level?");
			PushArrayString(TalentValue, "-1.0");
		}
		if (FindStringInArray(TalentKey, "range minimum?") == -1) {
			PushArrayString(TalentKey, "range minimum?");
			PushArrayString(TalentValue, "-1.0");
		}
		if (FindStringInArray(TalentKey, "aura effect?") == -1) {
			PushArrayString(TalentKey, "aura effect?");
			PushArrayString(TalentValue, "-1");
		}
		if (FindStringInArray(TalentKey, "max allowed?") == -1) {
			PushArrayString(TalentKey, "max allowed?");
			PushArrayString(TalentValue, "-1");
		}
		sortSize = GetArraySize(TalentKey);
		pos = 0;
		while (pos < sortSize) {
			GetArrayString(TalentKey, pos, text, sizeof(text));
			if (
			pos == 0 && !StrEqual(text, "max allowed?") ||
			pos == 1 && !StrEqual(text, "aura effect?") ||
			pos == 2 && !StrEqual(text, "range minimum?") ||
			pos == 3 && !StrEqual(text, "range player level?") ||
			pos == 4 && !StrEqual(text, "range max?") ||
			pos == 5 && !StrEqual(text, "cooldown?") ||
			pos == 6 && !StrEqual(text, "aura strength?") ||
			pos == 7 && !StrEqual(text, "strength target?") ||
			pos == 8 && !StrEqual(text, "level strength?") ||
			pos == 9 && !StrEqual(text, "chance?") ||
			pos == 10 && !StrEqual(text, "draw type?") ||
			pos == 11 && !StrEqual(text, "fire immunity?") ||
			pos == 12 && !StrEqual(text, "model size?") ||
			pos == 13 && !StrEqual(text, "glow?") ||
			pos == 14 && !StrEqual(text, "glow range?") ||
			pos == 15 && !StrEqual(text, "glow colour?") ||
			pos == 16 && !StrEqual(text, "base health?") ||
			pos == 17 && !StrEqual(text, "health per level?") ||
			pos == 18 && !StrEqual(text, "name?") ||
			pos == 19 && !StrEqual(text, "chain reaction?") ||
			pos == 20 && !StrEqual(text, "death effect?") ||
			pos == 21 && !StrEqual(text, "death base time?") ||
			pos == 22 && !StrEqual(text, "death max time?") ||
			pos == 23 && !StrEqual(text, "death interval?") ||
			pos == 24 && !StrEqual(text, "death multiplier?") ||
			pos == 25 && !StrEqual(text, "level required?") ||
			pos == 26 && !StrEqual(text, "force model?") ||
			pos == 27 && !StrEqual(text, "damage effect?") ||
			pos == 28 && !StrEqual(text, "enemy multiplication?") ||
			pos == 29 && !StrEqual(text, "onfire base time?") ||
			pos == 30 && !StrEqual(text, "onfire level?") ||
			pos == 31 && !StrEqual(text, "onfire max time?") ||
			pos == 32 && !StrEqual(text, "onfire interval?") ||
			pos == 33 && !StrEqual(text, "strength special?") ||
			pos == 34 && !StrEqual(text, "raw strength?") ||
			pos == 35 && !StrEqual(text, "raw common strength?") ||
			pos == 36 && !StrEqual(text, "raw player strength?") ||
			pos == 37 && !StrEqual(text, "require bile?")) {
				ResizeArray(TalentKey, sortSize+1);
				ResizeArray(TalentValue, sortSize+1);
				SetArrayString(TalentKey, sortSize, text);
				GetArrayString(TalentValue, pos, text, sizeof(text));
				SetArrayString(TalentValue, sortSize, text);
				RemoveFromArray(TalentKey, pos);
				RemoveFromArray(TalentValue, pos);
				continue;
			}
			pos++;
		}
		for (int i = 0; i < sortSize; i++) {
			if (i == SUPER_COMMON_REQ_BILED_SURVIVORS || i == SUPER_COMMON_MAX_ALLOWED || i == SUPER_COMMON_SPAWN_CHANCE ||
			i == SUPER_COMMON_MODEL_SIZE) {
				GetArrayString(TalentValue, i, text, sizeof(text));
				if (StrContains(text, ".") != -1) SetArrayCell(TalentValue, i, StringToFloat(text));	//float
				else SetArrayCell(TalentValue, i, StringToInt(text));	//int
			}
		}
	}
	else if (StrEqual(Config, CONFIG_WEAPONS)) {
		if (FindStringInArray(TalentKey, "damage") == -1) {
			PushArrayString(TalentKey, "damage");
			PushArrayString(TalentValue, "-1");
		}
		if (FindStringInArray(TalentKey, "range") == -1) {
			PushArrayString(TalentKey, "range");
			PushArrayString(TalentValue, "-1.0");
		}
		if (FindStringInArray(TalentKey, "offset") == -1) {
			PushArrayString(TalentKey, "offset");
			PushArrayString(TalentValue, "-1");
		}
		if (FindStringInArray(TalentKey, "ammo") == -1) {
			PushArrayString(TalentKey, "ammo");
			PushArrayString(TalentValue, "-1");
		}
		if (FindStringInArray(TalentKey, "range required?") == -1) {
			PushArrayString(TalentKey, "range required?");
			PushArrayString(TalentValue, "-1.0");
		}
		sortSize = GetArraySize(TalentKey);
		pos = 0;
		while (pos < sortSize) {
			GetArrayString(TalentKey, pos, text, sizeof(text));
			if (
			pos == 0 && !StrEqual(text, "damage") ||
			pos == 1 && !StrEqual(text, "offset") ||
			pos == 2 && !StrEqual(text, "ammo") ||
			pos == 3 && !StrEqual(text, "range") ||
			pos == 4 && !StrEqual(text, "range required?")) {
				ResizeArray(TalentKey, sortSize+1);
				ResizeArray(TalentValue, sortSize+1);
				SetArrayString(TalentKey, sortSize, text);
				GetArrayString(TalentValue, pos, text, sizeof(text));
				SetArrayString(TalentValue, sortSize, text);
				RemoveFromArray(TalentKey, pos);
				RemoveFromArray(TalentValue, pos);
				continue;
			}
			pos++;
		}
		for (int i = 0; i < sortSize; i++) {
			GetArrayString(TalentValue, i, text, sizeof(text));
			if (StrEqual(text, "EOM")) continue;
			if (StrContains(text, ".") != -1) SetArrayCell(TalentValue, i, StringToFloat(text));	//float
			else SetArrayCell(TalentValue, i, StringToInt(text));	//int
		}
	}
	GetArrayString(Section, size, text, sizeof(text));
	PushArrayString(TalentSection, text);
	/*if (StrEqual(Config, CONFIG_MENUTALENTS) || StrEqual(Config, CONFIG_EVENTS)) {
		LogMessage("%s", text);
		sortSize = GetArraySize(TalentKey);
		for (new i = 0; i < sortSize; i++) {
			GetArrayString(TalentKey, i, key, sizeof(key));
			GetArrayString(TalentValue, i, value, sizeof(value));
			LogMessage("\t\"%s\"\t\t\"%s\"", key, value);
		}
	}*/
	if (StrEqual(Config, CONFIG_MENUTALENTS)) PushArrayString(a_Database_Talents, text);
	ResizeArray(Main, size + 1);
	SetArrayCell(Main, size, TalentKey, 0);
	SetArrayCell(Main, size, TalentValue, 1);
	SetArrayCell(Main, size, TalentSection, 2);
}

public ReadyUp_FwdGetHeader(const char[] header) {
	strcopy(s_rup, sizeof(s_rup), header);
}

public ReadyUp_FwdGetCampaignName(const char[] mapname) {
	strcopy(currentCampaignName, sizeof(currentCampaignName), mapname);
}

public ReadyUp_CoopMapFailed(iGamemode) {
	if (!b_IsMissionFailed) {
		b_IsMissionFailed	= true;
		Points_Director = 0.0;
	}
}

// stock bool:IsCommonRegistered(entity) {
// 	if (FindListPositionByEntity(entity, Handle:CommonList) >= 0 ||
// 		FindListPositionByEntity(entity, Handle:CommonInfected) >= 0) return true;
// 	return false;
// }
stock bool IsSpecialCommon(entity) {
	if (FindListPositionByEntity(entity, CommonList) >= 0) {
		if (IsCommonInfected(entity)) return true;
		else ClearSpecialCommon(entity, false);
	}
	return false;
}

#include "rpg/rpg_menu.sp"
#include "rpg/rpg_menu_points.sp"
#include "rpg/rpg_menu_store.sp"
#include "rpg/rpg_menu_director.sp"
#include "rpg/rpg_timers.sp"
#include "rpg/rpg_wrappers.sp"
#include "rpg/rpg_events.sp"
#include "rpg/rpg_database.sp"
