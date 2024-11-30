#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <smlib>
#include <left4dhooks>
#undef REQUIRE_PLUGIN
#include <readyup>
#define REQUIRE_PLUGIN
#include "rpg/Definitions.sp"
public Plugin myinfo = {
	name = PLUGIN_NAME,
	author = PLUGIN_CONTACT,
	description = PLUGIN_DESCRIPTION,
	version = PLUGIN_VERSION,
	url = "",
};

public void OnPluginStart() {
	OnMapStartFunc(); // The very first thing that must happen before anything else happens.
	CreateConVar("skyrpg_version", PLUGIN_VERSION, "!skyrpg   = )");
	SetConVarString(FindConVar("skyrpg_version"), PLUGIN_VERSION);
	g_Steamgroup = FindConVar("sv_steamgroup");
	SetConVarFlags(g_Steamgroup, GetConVarFlags(g_Steamgroup) & ~FCVAR_NOTIFY);
	g_svCheats = FindConVar("sv_cheats");
	SetConVarFlags(g_svCheats, GetConVarFlags(g_svCheats) & ~FCVAR_NOTIFY);
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
	RegAdminCmd("deleteprofiles", CMD_DeleteProfiles, ADMFLAG_ROOT);
	// These are mandatory because of quick commands, so I hardcode the entries.
	RegConsoleCmd("reload_inventory", CMD_LoadAugments);
	RegConsoleCmd("autodismantle", CMD_AutoDismantle);
	RegConsoleCmd("rollloot", CMD_RollLoot);
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

stock OnMapStartFunc() {
	if (!b_MapStart) {
		b_MapStart = true;
		if (!b_FirstLoad) CreateAllArrays();
	}
	SetSurvivorsAliveHostname();
}

public void OnMapStart() {
	SetConVarInt(FindConVar("director_no_death_check"), 1);	// leave 0 until figure out why scenario_end doesn't work anymore.
	SetConVarInt(FindConVar("sv_rescue_disabled"), 0);
	SetConVarInt(FindConVar("z_common_limit"), 0);	// there are no commons until the round starts in all game modes to give players a chance to move.
	iTopThreat = 0;
	// When the server restarts, for any reason, RPG will properly load.
	//if (!b_FirstLoad) OnMapStartFunc();
	// This can call more than once, and we only want it to fire once.
	// The variable resets to false when a map ends.
	PrecacheModel("models/infected/common_male_clown.mdl", true);
	PrecacheModel("models/infected/common_male_ceda.mdl", true);
	PrecacheModel(FALLEN_SURVIVOR_MODEL, true);
	PrecacheModel("models/infected/common_male_riot.mdl", true);
	PrecacheModel("models/infected/common_male_mud.mdl", true);
	PrecacheModel("models/infected/common_male_jimmy.mdl", true);
	PrecacheModel("models/infected/common_male_roadcrew.mdl", true);
	PrecacheModel("models/infected/witch_bride.mdl", true);
	PrecacheModel("models/infected/witch.mdl", true);
	PrecacheModel("models/props_interiors/toaster.mdl", true);
	int modelprecacheSize = GetArraySize(ModelsToPrecache);
	if (modelprecacheSize > 0) {
		for (int i = 0; i < modelprecacheSize; i++) {
			char modelName[64];
			GetArrayString(ModelsToPrecache, i, modelName, 64);
			if (IsModelPrecached(modelName)) continue;
			PrecacheModel(modelName, true);
		}
	}
	PrecacheSound(JETPACK_AUDIO, true); // we have jetpacks!!! hold jump!
	g_iSprite = PrecacheModel("materials/sprites/laserbeam.vmt", true);
	g_BeaconSprite = PrecacheModel("materials/sprites/halo01.vmt", true);
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
	if (!FileExists(CONFIG_MAIN)) Format(CONFIG_MAIN, sizeof(CONFIG_MAIN), "rpg/config.cfg");
	else Format(CONFIG_MAIN, sizeof(CONFIG_MAIN), "rpg/%s.cfg", TheCurrentMap);

	UnhookAll();
	SetSurvivorsAliveHostname();
	CheckGamemode();
}

stock ResetValues(client) {
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
		if (CommonInfected[i] != INVALID_HANDLE) ClearArray(CommonInfected[i]);
	}
	ClearArray(NewUsersRound);
}

//	This generates results from the /rpg/config.cfg
stock LoadMainConfig() {
	GetConfigValue(sServerDifficulty, sizeof(sServerDifficulty), "server difficulty?");
	CheckDifficulty();
	GetConfigValue(sDeleteBotFlags, sizeof(sDeleteBotFlags), "delete bot flags?");
	fAugmentCooldownIncrease			= GetConfigValueFloat("augment cooldown modifier?", 0.3);
	iGiveSurvivorsWeaponsOnPregame		= GetConfigValueInt("weapon profiles loaded every map?", 0);
	fSpecialInfectedMinDelay			= GetConfigValueFloat("special infected min spawn delay?", 10.0);
	fSpecialInfectedMaxDelay			= GetConfigValueFloat("special infected max spawn delay?", 20.0);
	fSpecialInfectedDelayHandicap		= GetConfigValueFloat("special infected spawn reduction?", 1.0);
	fSpecialInfectedDelayMin			= GetConfigValueFloat("special infected spawn reduction max?", 5.0);
	fSpecialInfectedDelayRangeMin		= GetConfigValueFloat("special infected spawn range min?", 5.0);
	iForceFFALoot						= GetConfigValueInt("force ffa loot?", 1);
	fFatigueDamagePenalty				= GetConfigValueFloat("fatigued outgoing damage penalty?", 0.5);
	fFatigueDamageTakenPenalty			= GetConfigValueFloat("fatigued incoming damage penalty?", 0.5);
	fFatigueCooldownPenalty				= GetConfigValueFloat("fatigued talent cooldown penalty?", 0.5);
	fSuperCommonDistanceHeight			= GetConfigValueFloat("super common aura vertical distance?", 48.0);
	fFinaleDelayToForceTankSummon		= GetConfigValueInt("active finale force tank spawn delay?", 180) * 1.0;
	iDirectorThinkingAdvertisementTime	= GetConfigValueInt("director thinking advertisement?", 30);
	fBagPickupDelay						= GetConfigValueFloat("bag pickup delay?", 0.1);
	fDoTInterval						= GetConfigValueFloat("DoT tick interval?", 1.0);
	fDoTMaxTime							= GetConfigValueFloat("DoT maximum duration?", 10.0);
	iFireBaseDamage						= GetConfigValueInt("fire base damage?", 10);	// vanilla default is 40
	iDisplayEnrageCountdown				= GetConfigValueInt("display enrage timer?", 0);
	fDebuffTickrate						= GetConfigValueFloat("debuff tickrate?", 0.5);
	fCategoryStrengthPenaltyAugmentTier	= GetConfigValueFloat("category roll penalty per augment tier?", 0.2);
	iClientTypeToDisplayOnKill			= GetConfigValueInt("infected kill messages to display?", 0);
	fProficiencyExperienceMultiplier 	= GetConfigValueFloat("proficiency requirement multiplier?");
	fProficiencyExperienceEarned 		= GetConfigValueFloat("experience multiplier proficiency?");
	fRatingPercentLostOnDeath			= GetConfigValueFloat("rating percentage lost on death?");
	iProficiencyStart					= GetConfigValueInt("proficiency level start?");
	iTeamRatingRequired					= GetConfigValueInt("team count rating bonus?");
	fTeamRatingBonus					= GetConfigValueFloat("team player rating bonus?");
	iTanksPreset						= GetConfigValueInt("preset tank type on spawn?");
	iSurvivorRespawnRestrict			= GetConfigValueInt("respawn queue players ignored?");
	iIsSpecialFire						= GetConfigValueInt("special infected fire?");
	iSkyLevelMax						= GetConfigValueInt("max sky level?");
	fOnFireDebuffDelay					= GetConfigValueFloat("standing in fire debuff delay?");
	forceProfileOnNewPlayers			= GetConfigValueInt("Force Profile On New Player?");
	iShowLockedTalents					= GetConfigValueInt("show locked talents?");
	iAwardBroadcast						= GetConfigValueInt("award broadcast?");
	GetConfigValue(loadProfileOverrideFlags, sizeof(loadProfileOverrideFlags), "profile override flags?");
	GetConfigValue(sSpecialsAllowed, sizeof(sSpecialsAllowed), "special infected classes?");
	iSpecialsAllowed					= GetConfigValueInt("special infected allowed?");
	iSpecialInfectedMinimum				= GetConfigValueInt("special infected minimum?");
	fEnrageHordeBoost					= GetConfigValueFloat("enrage common increase?", 0.01);
	fEnrageHordeBoostDelay				= GetConfigValueFloat("enrage common increase delay?", 6.0);
	fEnrageDamageIncrease				= GetConfigValueFloat("enrage damage increase?", 0.01);
	fEnrageDamageIncreaseDelay			= GetConfigValueFloat("enrage damage increase delay?", 3.0);
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
	fDirectorThoughtDelay				= GetConfigValueFloat("director thought process delay?", 1.0);
	fDirectorThoughtHandicap			= GetConfigValueFloat("director thought process handicap?", 0.0);
	fDirectorThoughtProcessMinimum		= GetConfigValueFloat("director thought process minimum?", 1.0);
	iSurvivalRoundTime					= GetConfigValueInt("survival round time?");
	ConsumptionInt						= GetConfigValueInt("stamina consumption interval?");
	fStamSprintInterval					= GetConfigValueFloat("stamina sprint interval?", 0.12);
	fStamJetpackInterval				= GetConfigValueFloat("stamina jetpack interval?", 0.05);
	fStamRegenTime						= GetConfigValueFloat("stamina regeneration time?");
	fStamRegenTimeAdren					= GetConfigValueFloat("stamina regeneration time adren?");
	fBaseMovementSpeed					= GetConfigValueFloat("base movement speed?");
	iPlayerStartingLevel				= GetConfigValueInt("new player starting level?");
	iBotPlayerStartingLevel				= GetConfigValueInt("new bot player starting level?");
	if (iMaxLevelBots < iBotPlayerStartingLevel) iMaxLevelBots = iBotPlayerStartingLevel;
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
	fHealingAwarded						= GetConfigValueFloat("healing multiplier?", 0.5);
	fBuffingAwarded						= GetConfigValueFloat("buffing multiplier?", 0.1);
	fBuffingMultTank					= GetConfigValueFloat("buffing multiplier tank?", 0.5);
	fBuffingMultWitch					= GetConfigValueFloat("buffing multiplier witch?", 0.5);
	fBuffingMultSpecials				= GetConfigValueFloat("buffing multiplier specials?", 0.2);
	fBuffingMultSupers					= GetConfigValueFloat("buffing multiplier supers?", 0.1);
	fBuffingMultCommons					= GetConfigValueFloat("buffing multiplier commons?", 0.0);
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
	iMaxLevelBots						= GetConfigValueInt("max level bots?", -1);
	iExperienceStart					= GetConfigValueInt("experience start?");
	fExperienceMultiplier				= GetConfigValueFloat("requirement multiplier?");
	fExperienceMultiplierHardcore		= GetConfigValueFloat("requirement multiplier hardcore?");
	GetConfigValue(sBotTeam, sizeof(sBotTeam), "survivor team?");
	iActionBarSlots						= GetConfigValueInt("action bar slots?");
	iNumAugments						= GetConfigValueInt("augment slots?", 3);
	iMenuCommandsToDisplay				= GetConfigValueInt("rpg menu commands to advertise?", 1);
	GetConfigValue(MenuCommand, sizeof(MenuCommand), "rpg menu command?");
	int ExplodeCount = GetDelimiterCount(MenuCommand, ",") + 1;
	if (ExplodeCount > 1) {
		char[][] MenuCommands = new char[ExplodeCount][32];
		ExplodeString(MenuCommand, ",", MenuCommands, ExplodeCount, 32);
		Format(MenuCommand, sizeof(MenuCommand), "{O}!{B}%s", MenuCommands[0]);

		int commandsToDisplay = (iMenuCommandsToDisplay < 1) ? ExplodeCount-1 : iMenuCommandsToDisplay;
		for (int i = 1; i < commandsToDisplay; i++) {
			if (i + 1 < commandsToDisplay) Format(MenuCommand, sizeof(MenuCommand), "%s, {O}!{B}%s", MenuCommand, MenuCommands[i]);
			else Format(MenuCommand, sizeof(MenuCommand), "%s, or {O}!{B}%s", MenuCommand, MenuCommands[i]);
		}
	}
	iDisplayTalentUpgradesToTeam		= GetConfigValueInt("display when players upgrade to team?");
	DoomSUrvivorsRequired				= GetConfigValueInt("doom survivors ignored?");
	DoomKillTimer						= GetConfigValueInt("doom kill timer?");
	fVersusTankNotice					= GetConfigValueFloat("versus tank notice?");
	AllowedCommons						= GetConfigValueInt("common limit base?");
	AllowedMegaMob						= GetConfigValueInt("mega mob limit base?");
	AllowedMobSpawn						= GetConfigValueInt("mob limit base?");
	AllowedMobSpawnFinale				= GetConfigValueInt("mob finale limit base?");
	RespawnQueue						= GetConfigValueInt("survivor respawn queue?");
	MaximumPriority						= GetConfigValueInt("director priority maximum?");
	fUpgradeExpCost						= GetConfigValueFloat("upgrade experience cost?");
	iWitchHealthBase					= GetConfigValueInt("base witch health?");
	fWitchHealthMult					= GetConfigValueFloat("level witch multiplier?");
	iCommonBaseHealth					= GetConfigValueInt("common base health?");
	fCommonLevelHealthMult				= GetConfigValueFloat("common level health?");
	GroupMemberBonus					= GetConfigValueFloat("steamgroup bonus?");
	RaidLevMult							= GetConfigValueInt("raid level multiplier?");
	iIgnoredRating						= GetConfigValueInt("rating to ignore?");
	iIgnoredRatingMax					= GetConfigValueInt("max rating to ignore?");
	iInfectedLimit						= GetConfigValueInt("ensnare infected limit?");
	TheScorchMult						= GetConfigValueFloat("scorch multiplier?");
	TheInfernoMult						= GetConfigValueFloat("inferno multiplier?");
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
	GetConfigValue(sItemModel, sizeof(sItemModel), "item drop model?");
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
	fCoopSoloSurvBon					= GetConfigValueFloat("solo round survival bonus?");
	iMaxIncap							= GetConfigValueInt("survivor max incap?");
	iMaxLayers							= GetConfigValueInt("max talent layers?");
	iCommonInfectedBaseDamage			= GetConfigValueInt("common infected base damage?");
	iShowTotalNodesOnTalentTree			= GetConfigValueInt("show upgrade maximum by nodes?");
	fSuperCommonTickrate				= GetConfigValueFloat("super common tick rate?");
	fDrawHudInterval					= GetConfigValueFloat("hud display tick rate?");
	fSpecialAmmoInterval				= GetConfigValueFloat("special ammo tick rate?");
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
	iEndRoundIfNoHealthySurvivors		= GetConfigValueInt("end round if all survivors are incapped?", 0);
	iEndRoundIfNoLivingHumanSurvivors	= GetConfigValueInt("end round if no living human survivors?", 1);
	fTankMovementSpeed_Burning			= GetConfigValueFloat("fire tank movement speed?", 2.0);	// if this key is omitted, a default value is set. these MUST be > 0.0, so the default is hard-coded.
	fTankMovementSpeed_Hulk				= GetConfigValueFloat("hulk tank movement speed?", 1.5);
	fTankMovementSpeed_Death			= GetConfigValueFloat("death tank movement speed?", 0.5);
	fTankMovementSpeed_Freezer			= GetConfigValueFloat("freezer tank movement speed?", 1.5);
	fTankMovementSpeed_Bomber			= GetConfigValueFloat("bomber tank movement speed?", 1.0);
	iResetPlayerLevelOnDeath			= GetConfigValueInt("reset player level on death?");
	leaderboardPageCount				= GetConfigValueInt("leaderboard players per page?", 5);
	fForceTankJumpHeight				= GetConfigValueFloat("force tank to jump power?", 500.0);
	fForceTankJumpRange					= GetConfigValueFloat("force tank to jump range?", 256.0);
	iResetDirectorPointsOnNewRound		= GetConfigValueInt("reset director points every round?", 1);
	iLootEnabled						= GetConfigValueInt("loot system enabled?", 1);
	fLootChanceTank						= GetConfigValueFloat("loot chance tank?", 1.0);
	fLootChanceWitch					= GetConfigValueFloat("loot chance witch?", 0.5);
	fLootChanceSpecials					= GetConfigValueFloat("loot chance specials?", 0.1);
	fLootChanceSupers					= GetConfigValueFloat("loot chance supers?", 0.01);
	fLootChanceCommons					= GetConfigValueFloat("loot chance commons?", 0.001);
	fUpgradesRequiredPerLayer			= GetConfigValueFloat("layer upgrades required?", 0.3);
	iEnsnareRestrictions				= GetConfigValueInt("ensnare restrictions?", 1);
	fTeleportTankHeightDistance			= GetConfigValueFloat("teleport tank height distance?", 512.0);
	fSurvivorBufferBonus				= GetConfigValueFloat("common buffers survivors effect?", 2.0);
	iCommonInfectedSpawnDelayOnNewRound	= GetConfigValueInt("new round spawn common delay?", 30);
	iHideEnrageTimerUntilSecondsLeft	= GetConfigValueInt("hide enrage timer until seconds left?", iEnrageTime/3);
	showNumLivingSurvivorsInHostname	= GetConfigValueInt("show living survivors in hostname?", 0);
	iUpgradesRequiredForLoot			= GetConfigValueInt("assigned upgrades required for loot?", 5);
	iUseLinearLeveling					= GetConfigValueInt("experience requirements are linear?", 0);
	iUniqueServerCode					= GetConfigValueInt("unique server code?", 10);
	iAugmentLevelDivisor				= GetConfigValueInt("augment level divisor?", 1000);
	fAugmentRatingMultiplier			= GetConfigValueFloat("augment bonus category rating multiplier?", 0.00001);
	fAugmentActivatorRatingMultiplier	= GetConfigValueFloat("augment bonus activator rating multiplier?", 0.000005);
	fAugmentTargetRatingMultiplier		= GetConfigValueFloat("augment bonus target rating multiplier?", 0.000005);
	iRatingRequiredForAugmentLootDrops	= GetConfigValueInt("rating required for augment drops?", 30000);
	fAugmentTierChance					= GetConfigValueFloat("augment tier chance?", 0.75);
	fAntiFarmDistance					= GetConfigValueFloat("anti farm kill distance?");
	iAntiFarmMax						= GetConfigValueInt("anti farm kill max locations?");
	fLootBagExpirationTimeInSeconds		= GetConfigValueFloat("loot bags disappear after this many seconds?", 10.0);
	iExplosionBaseDamagePipe			= GetConfigValueInt("base pipebomb damage?", 500);
	iExplosionBaseDamage				= GetConfigValueInt("base explosion damage for non pipebomb sources?", 500);
	fProficiencyLevelDamageIncrease		= GetConfigValueFloat("weapon proficiency level bonus damage?", 0.01);
	iJetpackEnabled						= GetConfigValueInt("jetpack enabled?", 1);
	iNumLootDropChancesPerPlayer[0]		= GetConfigValueInt("roll attempts on common kill?", 1);
	iNumLootDropChancesPerPlayer[1]		= GetConfigValueInt("roll attempts on supers kill?", 1);
	iNumLootDropChancesPerPlayer[2]		= GetConfigValueInt("roll attempts on specials kill?", 1);
	iNumLootDropChancesPerPlayer[3]		= GetConfigValueInt("roll attempts on witch kill?", 1);
	iNumLootDropChancesPerPlayer[4]		= GetConfigValueInt("roll attempts on tank kill?", 1);
	iInventoryLimit						= GetConfigValueInt("max persistent loot inventory size?", 50);
	iDonorInventoryIncrease				= GetConfigValueInt("donor inventory limit increase?", 50);
	iLevelRequiredToEarnScore			= GetConfigValueInt("level required to earn score?", 10);
	fNoHandicapScoreMultiplier			= GetConfigValueFloat("base score multiplier (no handicap?)", 0.05);
	iMaximumTanksPerPlayer				= GetConfigValueInt("maximum tank spawns per player?", 2);
	iMaximumCommonsPerPlayer			= GetConfigValueInt("maximum common increase per player?", 30);
	iMaximumCommonsPerSurvivor			= GetConfigValueInt("maximum common increase per survivor?", 3);
	iAugmentCategoryRerollCost			= GetConfigValueInt("augment category reroll cost?", 100);
	iAugmentActivatorRerollCost			= GetConfigValueInt("augment activator reroll cost?", 200);
	iAugmentTargetRerollCost			= GetConfigValueInt("augment target reroll cost?", 300);
	iMultiplierForAugmentLootDrops		= GetConfigValueInt("augment score tier multiplier?", 2);
	iAugmentsAffectCooldowns			= GetConfigValueInt("augment affects cooldowns?", 1);
	fIncapHealthStartPercentage			= GetConfigValueFloat("incap health start?", 0.5);
	iStuckDelayTime						= GetConfigValueInt("seconds between stuck command use?", 120);
	fTankingContribution				= GetConfigValueFloat("tanking contribution?", 1.0);
	fDamageContribution					= GetConfigValueFloat("damage contribution?", 0.2);
	fHealingContribution				= GetConfigValueFloat("healing contribution?", 0.15);
	fBuffingContribution				= GetConfigValueFloat("buffing contribution?", 0.3);
	iExperimentalMode					= GetConfigValueInt("invert walk and sprint?", 1);
	fAugmentLevelDifferenceForStolen	= GetConfigValueFloat("equip stolen augment average range?", 0.1);
	fUpdateClientInterval				= GetConfigValueFloat("update client data tickrate?", 0.5);
	fRewardPenaltyIfSurvivorBot			= GetConfigValueFloat("reward penalty if target is survivor bot?", 0.1);
	fFallenSurvivorDefibChance			= GetConfigValueFloat("fallen survivor defib drop chance base?", 0.01);
	fFallenSurvivorDefibChanceLuck		= GetConfigValueFloat("fallen survivor defib drop chance luck?", 0.01);
	iAugmentCategoryUpgradeCost			= GetConfigValueInt("augment category upgrade cost?", 50);
	iAugmentActivatorUpgradeCost		= GetConfigValueInt("augment activator upgrade cost?", 50);
	iAugmentTargetUpgradeCost			= GetConfigValueInt("augment target upgrade cost?", 50);
	fPainPillsHealAmount				= GetConfigValueFloat("on use pain killers heal?", 0.3);
	iNumAdvertisements					= GetConfigValueInt("number of advertisements?", 0);
	HostNameTime						= GetConfigValueInt("delay in seconds between advertisements?", 180);
	iAttributeExperienceRequirement		= GetConfigValueInt("attribute start xp requirement?", 5000);
	attributeExperienceMultiplier		= GetConfigValueFloat("attribute experience multiplier?", 0.12);
	fAttributeMultiplier[0]				= GetConfigValueFloat("constitution multiplier?", 0.03);
	fAttributeModifier[0]				= GetConfigValueFloat("constitution xp modifier?", 2.0);
	fAttributeMultiplier[1]				= GetConfigValueFloat("agility multiplier?", 0.01);
	fAttributeModifier[1]				= GetConfigValueFloat("agility xp modifier?", 1.0);
	fAttributeMultiplier[2]				= GetConfigValueFloat("resilience multiplier?", 0.01);
	fAttributeModifier[2]				= GetConfigValueFloat("resilience xp modifier?", 0.1);
	fAttributeMultiplier[3]				= GetConfigValueFloat("technique multiplier?", 0.01);
	fAttributeModifier[3]				= GetConfigValueFloat("technique xp modifier?", 0.1);
	fAttributeMultiplier[4]				= GetConfigValueFloat("endurance multiplier?", 0.03);
	fAttributeModifier[4]				= GetConfigValueFloat("endurance xp modifier?", 1.0);
	fAttributeMultiplier[5]				= GetConfigValueFloat("luck multiplier?", 0.01);
	fAttributeModifier[5]				= GetConfigValueFloat("luck xp modifier?", 0.1);
	fGoverningAttributeModifier			= GetConfigValueFloat("governing attribute xp modifier?", 0.1);
	iFancyBorders						= GetConfigValueInt("fancy borders?", 1);
	iGenerateLootBags					= GetConfigValueInt("generate loot bags?", 1);
	fDisplayLootPickupMessageTime		= GetConfigValueFloat("loot interact message time?", 3.0);
	fEnrageTankMovementSpeed			= GetConfigValueFloat("enrage tank movement speed?", 1.5);
	iGrindMode							= GetConfigValueInt("grind mode?", 130);
	fGrindMultiplier					= GetConfigValueFloat("requirement multiplier grind?", 0.02);
	iSkyPointsTimeRequired				= GetConfigValueInt("sky points time required?", 15);
	iSkyPointsTimeRequiredDonator		= GetConfigValueInt("sky points time required donator?", 10);
	iSkyPointsAwardAmount				= GetConfigValueInt("sky points award amount?", 1);
	iBaseCommonLimitIncreasePerPlayer	= GetConfigValueInt("base common limit increase per player?", 10);
	iNewPlayerSkyPoints					= GetConfigValueInt("new player starting sky points?", 5);
	fSoloDifficultyExperienceBonus		= GetConfigValueFloat("experience bonus if solo survivor?", 0.5);
	fStartingStaminaPercentage			= GetConfigValueFloat("starting stamina percentage on load?", 0.8);
	fMinWeaponDamageAllowed				= GetConfigValueFloat("minimum weapon damage after penalties?", 0.2);
	iHandicapLevelsAreScoreBased		= GetConfigValueInt("handicap levels are score-based?", 0);
	iScoreLostOnDeathLevelRequired		= GetConfigValueInt("level required to lose score on death?", 1);
	fDebuffIntervalCheck				= GetConfigValueFloat("debuff interval tick rate?", 0.2);
	fTankStateTickrate					= GetConfigValueFloat("tankstate check tick rate?", 0.2);
	fJetpackInterruptionTime			= GetConfigValueFloat("jetpack interruption time on button press?", 120.0);
	iDisableRescueClosets				= GetConfigValueInt("disable rescue closets?", 1);

	GetConfigValue(acmd, sizeof(acmd), "action slot command?");
	GetConfigValue(abcmd, sizeof(abcmd), "abilitybar menu command?");
	GetConfigValue(DefaultProfileName, sizeof(DefaultProfileName), "new player profile?");
	GetConfigValue(DefaultBotProfileName, sizeof(DefaultBotProfileName), "new bot player profile?");
	GetConfigValue(DefaultInfectedProfileName, sizeof(DefaultInfectedProfileName), "new infected player profile?");
	GetConfigValue(defaultLoadoutWeaponPrimary, sizeof(defaultLoadoutWeaponPrimary), "default loadout primary weapon?");
	GetConfigValue(defaultLoadoutWeaponSecondary, sizeof(defaultLoadoutWeaponSecondary), "default loadout secondary weapon?");
	GetConfigValue(serverKey, sizeof(serverKey), "server steam key?");
	LogMessage("skyrpg has loaded successfully.");
}
#include "rpg/Array/CustomArray.sp"
#include "rpg/Forwards.sp"
#include "rpg/ConnectivityStuff.sp"
#include "rpg/BuffAndDebuffChecks.sp"
#include "rpg/OnPlayerRunCmd.sp"
#include "rpg/ActionBar/CastActionBar.sp"
#include "rpg/ActionBar/ActionBarTalentStocks.sp"
#include "rpg/ActionBar/SpecialAmmoStocks.sp"
#include "rpg/Stocks/SuperCommonStocks.sp"
#include "rpg/ExperienceChecks.sp"
#include "rpg/Stocks/Stocks.sp"
#include "rpg/Stocks/DisplayHUD.sp"
#include "rpg/Loot/GenerateLoot.sp"
#include "rpg/Loot/PickupLoot.sp"
#include "rpg/Commands.sp"
#include "rpg/EndOfRound.sp"
#include "rpg/Pregame.sp"
#include "rpg/Parser.sp"
#include "rpg/Menus/MenuStocks.sp"
#include "rpg/Menus/MenuTitle.sp"
#include "rpg/Menus/MainMenu.sp"
#include "rpg/Menus/TalentMenu.sp"
#include "rpg/Menus/ActionBarTalentMenu.sp"
#include "rpg/Menus/HandicapMenu.sp"
#include "rpg/Augment/AugmentInventory.sp"
#include "rpg/Augment/GetAugmentComparator.sp"
#include "rpg/Augment/AugmentModifiers.sp"
//#include "rpg/Augment/InspectAugmentOnGround.sp"
#include "rpg/TalentModifiers.sp"
#include "rpg/ActionBar/ShowAndDrawActionBar.sp"
#include "rpg/Menus/TeamComposition.sp"
#include "rpg/ThreatMeter/ThreatMeter.sp"
#include "rpg/Menus/CharacterSheet.sp"
#include "rpg/Menus/Proficiency.sp"
#include "rpg/Menus/Attributes.sp"
#include "rpg/Menus/Leaderboards.sp"
#include "rpg/ProfileEditor.sp"
#include "rpg/Menus/PointsBuyMenu.sp"
#include "rpg/Menus/Store.sp"
#include "rpg/AIDirector/AIDirectorMenu.sp"
#include "rpg/Timers.sp"
#include "rpg/AIDirector/Director.sp"
#include "rpg/Stocks/ConvertTriggerAndResult.sp"
#include "rpg/Stocks/ActivateAbilityEx.sp"
#include "rpg/Stocks/GetAbilityStrengthByTrigger.sp"
#include "rpg/Stocks/GetBaseWeaponDamage.sp"
#include "rpg/Stocks/ProficiencyStocks.sp"
#include "rpg/Stocks/GetAbilityMultiplier.sp"
#include "rpg/Stocks/QuickCommandAccess.sp"
#include "rpg/Stocks/OnTakeDamage.sp"
#include "rpg/Stocks/GetStatusEffects.sp"
#include "rpg/Stocks/IncapacitateOrKill.sp"
#include "rpg/SetSurvivorWeaponBits.sp"
#include "rpg/Event/EventStocks.sp"
#include "rpg/Event/Call_Event.sp"
#include "rpg/Score/CalculateInfectedDamageAward.sp"
#include "rpg/Score/RatingCalculator.sp"
#include "rpg/Database/Connect.sp"
#include "rpg/Database/Queries.sp"
#include "rpg/Database/Generate.sp"
#include "rpg/Database/LeaderboardsQuery.sp"