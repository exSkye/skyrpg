 /**
 * =============================================================================
 * Ready Up - RPG (C)2017 Michael toth
 * =============================================================================
 *
 * This program is free software; you can redistribute it and/or modify it under
 * the terms of the GNU General Public License, version 3.0, as published by the
 * Free Software Foundation.
 * 
 * This program is distributed in the hope that it will be useful, but WITHOUT
 * ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
 * FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more
 * details.
 *
 * You should have received a copy of the GNU General Public License along with
 * this program.  If not, see <http://www.gnu.org/licenses/>.
 *
 * As a special exception, AlliedModders LLC gives you permission to link the
 * code of this program (as well as its derivative works) to "Half-Life 2," the
 * "Source Engine," the "SourcePawn JIT," and any Game MODs that run on software
 * by the Valve Corporation.  You must obey the GNU General Public License in
 * all respects for all other code used.  Additionally, AlliedModders LLC grants
 * this exception to all derivative works.  AlliedModders LLC defines further
 * exceptions, found in LICENSE.txt (as of this writing, version JULY-31-2007),
 * or <http://www.sourcemod.net/license.php>.
 */
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
#define PLUGIN_VERSION				"Dev build v0.0.5.6"
#define CLASS_VERSION				"v1.0"
#define PROFILE_VERSION				"v1.3"
#define LOOT_VERSION				"v0.0"
#define PLUGIN_CONTACT				"skye"
#define PLUGIN_NAME					"RPG Construction Set"
#define PLUGIN_DESCRIPTION			"Fully-customizable and modular RPG, like the one for Atari."
#define PLUGIN_URL					"https://discord.gg/tzgnQRbkWm"
#define CONFIG_EVENTS				"rpg/events.cfg"
#define CONFIG_MAINMENU				"rpg/mainmenu.cfg"
#define CONFIG_MENUTALENTS			"rpg/talentmenu.cfg"
#define CONFIG_POINTS				"rpg/points.cfg"
#define CONFIG_MAPRECORDS			"rpg/maprecords.cfg"
#define CONFIG_STORE				"rpg/store.cfg"
#define CONFIG_TRAILS				"rpg/trails.cfg"
#define CONFIG_CHATSETTINGS			"rpg/chatsettings.cfg"
#define CONFIG_PETS					"rpg/pets.cfg"
#define CONFIG_WEAPONS				"rpg/weapondamages.cfg"
#define CONFIG_COMMONAFFIXES		"rpg/commonaffixes.cfg"
#define LOGFILE						"rum_rpg.txt"
#define JETPACK_AUDIO				"ambient/gas/steam2.wav"
//	=================================
#define DEBUG     		false
//	=================================
#define CVAR_SHOW			FCVAR_NOTIFY | FCVAR_PLUGIN
#define DMG_HEADSHOT		2147483648
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
#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <smlib>
#include <l4d2_direct>
#include "wrap.inc"
#include "left4downtown.inc"
#include "l4d_stocks.inc"
#undef REQUIRE_PLUGIN
#include <readyup>
#define REQUIRE_PLUGIN
public Plugin:myinfo = {
	name = PLUGIN_NAME,
	author = PLUGIN_CONTACT,
	description = PLUGIN_DESCRIPTION,
	version = PLUGIN_VERSION,
	url = PLUGIN_URL,
};
new Handle:TimeOfEffectOverTime;
new Handle:EffectOverTime;
new Handle:currentEquippedWeapon[MAXPLAYERS + 1];	// bullets fired from current weapon; variable needs to be renamed.
new Handle:GetCategoryStrengthKeys[MAXPLAYERS + 1];
new Handle:GetCategoryStrengthValues[MAXPLAYERS + 1];
new Handle:GetCategoryStrengthSection[MAXPLAYERS + 1];
new bool:bIsDebugEnabled = false;
new pistolXP[MAXPLAYERS + 1];
new meleeXP[MAXPLAYERS + 1];
new uziXP[MAXPLAYERS + 1];
new shotgunXP[MAXPLAYERS + 1];
new sniperXP[MAXPLAYERS + 1];
new assaultXP[MAXPLAYERS + 1];
new medicXP[MAXPLAYERS + 1];
new grenadeXP[MAXPLAYERS + 1];
new Float:fProficiencyExperienceMultiplier;
new Float:fProficiencyExperienceEarned;
//new iProficiencyMaxLevel;
new iProficiencyStart;
new iMaxIncap;
new Handle:hExecuteConfig = INVALID_HANDLE;
new iTanksPreset;
new ProgressEntity[MAXPLAYERS + 1];
//new Float:fScoutBonus;
//new Float:fTotemRating;
new iSurvivorRespawnRestrict;
new bool:bIsDefenderTank[MAXPLAYERS + 1];
new Float:fOnFireDebuffDelay;
new Float:fOnFireDebuff[MAXPLAYERS + 1];
//new iOnFireDebuffLimit;
new iSkyLevelMax;
new SkyLevel[MAXPLAYERS + 1];
new iIsSpecialFire;
new iIsRatingEnabled;
new Handle:hThreatSort;
new bool:bIsHideThreat[MAXPLAYERS + 1];
//new Float:fTankThreatBonus;
new iTopThreat;
new iThreatLevel[MAXPLAYERS + 1];
new iThreatLevel_temp[MAXPLAYERS + 1];
new Handle:hThreatMeter;
new forceProfileOnNewPlayers;
new bool:bEquipSpells[MAXPLAYERS + 1];
new Handle:LoadoutConfigKeys[MAXPLAYERS + 1];
new Handle:LoadoutConfigValues[MAXPLAYERS + 1];
new Handle:LoadoutConfigSection[MAXPLAYERS + 1];
new bool:bIsGiveProfileItems[MAXPLAYERS + 1];
new String:sProfileLoadoutConfig[64];
new iIsWeaponLoadout[MAXPLAYERS + 1];
new iAwardBroadcast;
new iSurvivalCounter;
new iRestedDonator;
new iRestedRegular;
new iRestedSecondsRequired;
new iRestedMaximum;
new iFriendlyFire;
new String:sDonatorFlags[10];
new iDropsEnabled;
new Float:fDeathPenalty;
new iHardcoreMode;
new iDeathPenaltyPlayers;
new Handle:RoundStatistics;
new bool:bRushingNotified[MAXPLAYERS + 1];
new bool:bHasTeleported[MAXPLAYERS + 1];
new bool:IsAirborne[MAXPLAYERS + 1];
new Handle:RandomSurvivorClient;
new eBackpack[MAXPLAYERS + 1];
new bool:b_IsFinaleTanks;
new String:RatingType[64];
new bool:bJumpTime[MAXPLAYERS + 1];
new Float:JumpTime[MAXPLAYERS + 1];
new Handle:AbilityConfigKeys[MAXPLAYERS + 1];
new Handle:AbilityConfigValues[MAXPLAYERS + 1];
new Handle:AbilityConfigSection[MAXPLAYERS + 1];
new bool:IsGroupMember[MAXPLAYERS + 1];
new IsGroupMemberTime[MAXPLAYERS + 1];
new Handle:GetAbilityKeys[MAXPLAYERS + 1];
new Handle:GetAbilityValues[MAXPLAYERS + 1];
new Handle:GetAbilitySection[MAXPLAYERS + 1];
new Handle:IsAbilityKeys[MAXPLAYERS + 1];
new Handle:IsAbilityValues[MAXPLAYERS + 1];
new Handle:IsAbilitySection[MAXPLAYERS + 1];
new bool:bIsSprinting[MAXPLAYERS + 1];
new Handle:CheckAbilityKeys[MAXPLAYERS + 1];
new Handle:CheckAbilityValues[MAXPLAYERS + 1];
new Handle:CheckAbilitySection[MAXPLAYERS + 1];
new StrugglePower[MAXPLAYERS + 1];
new Handle:GetTalentStrengthKeys[MAXPLAYERS + 1];
new Handle:GetTalentStrengthValues[MAXPLAYERS + 1];
new Handle:CastKeys[MAXPLAYERS + 1];
new Handle:CastValues[MAXPLAYERS + 1];
new Handle:CastSection[MAXPLAYERS + 1];
new ActionBarSlot[MAXPLAYERS + 1];
new Handle:ActionBar[MAXPLAYERS + 1];
new bool:DisplayActionBar[MAXPLAYERS + 1];
new ConsecutiveHits[MAXPLAYERS + 1];
new MyVomitChase[MAXPLAYERS + 1];
new Float:JetpackRecoveryTime[MAXPLAYERS + 1];
new bool:b_IsHooked[MAXPLAYERS + 1];
new IsPvP[MAXPLAYERS + 1];
new bool:bJetpack[MAXPLAYERS + 1];
//new ServerLevelRequirement;
new Handle:TalentsAssignedKeys[MAXPLAYERS + 1];
new Handle:TalentsAssignedValues[MAXPLAYERS + 1];
new Handle:CartelValueKeys[MAXPLAYERS + 1];
new Handle:CartelValueValues[MAXPLAYERS + 1];
new ReadyUpGameMode;
new bool:b_IsLoaded[MAXPLAYERS + 1];
new bool:LoadDelay[MAXPLAYERS + 1];
new LoadTarget[MAXPLAYERS + 1];
new String:CompanionNameQueue[MAXPLAYERS + 1][64];
new bool:HealImmunity[MAXPLAYERS + 1];
new String:Hostname[64];
new String:sHostname[64];
new String:ProfileLoadQueue[MAXPLAYERS + 1][64];
new bool:bIsSettingsCheck;
new Handle:SuperCommonQueue;
new bool:bIsCrushCooldown[MAXPLAYERS + 1];
new bool:bIsBurnCooldown[MAXPLAYERS + 1];
new bool:ISBILED[MAXPLAYERS + 1];
new Rating[MAXPLAYERS + 1];
new String:MyAmmoEffects[MAXPLAYERS + 1];
new Float:RoundExperienceMultiplier[MAXPLAYERS + 1];
new BonusContainer[MAXPLAYERS + 1];
new CurrentMapPosition;
new DoomTimer;
new CleanseStack[MAXPLAYERS + 1];
new Float:CounterStack[MAXPLAYERS + 1];
new MultiplierStack[MAXPLAYERS + 1];
new String:BuildingStack[MAXPLAYERS + 1];
new Handle:TempAttributes[MAXPLAYERS + 1];
new Handle:TempTalents[MAXPLAYERS + 1];
new Handle:PlayerProfiles[MAXPLAYERS + 1];
new String:LoadoutName[MAXPLAYERS + 1][64];
new bool:b_IsSurvivalIntermission;
new Float:ISDAZED[MAXPLAYERS + 1];
//new Float:ExplodeTankTimer[MAXPLAYERS + 1];
new TankState[MAXPLAYERS + 1];
//new LastAttacker[MAXPLAYERS + 1];
new bool:b_IsFloating[MAXPLAYERS + 1];
new Float:JumpPosition[MAXPLAYERS + 1][2][3];
new Float:LastDeathTime[MAXPLAYERS + 1];
new Float:SurvivorEnrage[MAXPLAYERS + 1][2];
new bool:bHasWeakness[MAXPLAYERS + 1];
new HexingContribution[MAXPLAYERS + 1];
new BuffingContribution[MAXPLAYERS + 1];
new HealingContribution[MAXPLAYERS + 1];
new TankingContribution[MAXPLAYERS + 1];
new CleansingContribution[MAXPLAYERS + 1];
new Float:PointsContribution[MAXPLAYERS + 1];
new DamageContribution[MAXPLAYERS + 1];
new Float:ExplosionCounter[MAXPLAYERS + 1][2];
new Handle:CoveredInVomit;
new bool:AmmoTriggerCooldown[MAXPLAYERS + 1];
new Handle:SpecialAmmoEffectKeys[MAXPLAYERS + 1];
new Handle:SpecialAmmoEffectValues[MAXPLAYERS + 1];
new Handle:ActiveAmmoCooldownKeys[MAXPLAYERS +1];
new Handle:ActiveAmmoCooldownValues[MAXPLAYERS + 1];
new Handle:PlayActiveAbilities[MAXPLAYERS + 1];
new Handle:PlayerActiveAmmo[MAXPLAYERS + 1];
new Handle:SpecialAmmoKeys[MAXPLAYERS + 1];
new Handle:SpecialAmmoValues[MAXPLAYERS + 1];
new Handle:SpecialAmmoSection[MAXPLAYERS + 1];
new Handle:DrawSpecialAmmoKeys[MAXPLAYERS + 1];
new Handle:DrawSpecialAmmoValues[MAXPLAYERS + 1];
new Handle:SpecialAmmoStrengthKeys[MAXPLAYERS + 1];
new Handle:SpecialAmmoStrengthValues[MAXPLAYERS + 1];
new Handle:WeaponLevel[MAXPLAYERS + 1];
new Handle:ExperienceBank[MAXPLAYERS + 1];
new Handle:MenuPosition[MAXPLAYERS + 1];
new Handle:IsClientInRangeSAKeys[MAXPLAYERS + 1];
new Handle:IsClientInRangeSAValues[MAXPLAYERS + 1];
new Handle:SpecialAmmoData;
new Handle:SpecialAmmoSave;
new Float:MovementSpeed[MAXPLAYERS + 1];
new IsPlayerDebugMode[MAXPLAYERS + 1];
new String:ActiveSpecialAmmo[MAXPLAYERS + 1][64];
new Float:IsSpecialAmmoEnabled[MAXPLAYERS + 1][4];
new bool:bIsInCombat[MAXPLAYERS + 1];
new Float:CombatTime[MAXPLAYERS + 1];
new Handle:AKKeys[MAXPLAYERS + 1];
new Handle:AKValues[MAXPLAYERS + 1];
new Handle:AKSection[MAXPLAYERS + 1];
new bool:bIsSurvivorFatigue[MAXPLAYERS + 1];
new SurvivorStamina[MAXPLAYERS + 1];
new Float:SurvivorConsumptionTime[MAXPLAYERS + 1];
new Float:SurvivorStaminaTime[MAXPLAYERS + 1];
new Handle:ISSLOW[MAXPLAYERS + 1];
new Float:fSlowSpeed[MAXPLAYERS + 1];
new Handle:ISFROZEN[MAXPLAYERS + 1];
new Float:ISEXPLODETIME[MAXPLAYERS + 1];
new Handle:ISEXPLODE[MAXPLAYERS + 1];
new Handle:ISBLIND[MAXPLAYERS + 1];
new Handle:EntityOnFire;
new Handle:CommonInfected;
new Handle:RCAffixes[MAXPLAYERS + 1];
new Handle:h_CommonKeys;
new Handle:h_CommonValues;
new Handle:SearchKey_Section;
new Handle:h_CAKeys;
new Handle:h_CAValues;
new Handle:CommonList;
new Handle:CommonAffixes;			// the array holding the common entity id and the affix associated with the common infected. If multiple affixes, multiple keyvalues for the entity id will be created instead of multiple entries.
new Handle:a_CommonAffixes;			// the array holding the config data
new Handle:CommonAffixesCooldown[MAXPLAYERS + 1];		// the array holding cooldown information for common affix damages.
new UpgradesAwarded[MAXPLAYERS + 1];
new UpgradesAvailable[MAXPLAYERS + 1];
new Handle:InfectedAuraKeys[MAXPLAYERS + 1];
new Handle:InfectedAuraValues[MAXPLAYERS + 1];
new Handle:InfectedAuraSection[MAXPLAYERS + 1];
new bool:b_IsDead[MAXPLAYERS + 1];
new ExperienceDebt[MAXPLAYERS + 1];
new Handle:TalentUpgradeKeys[MAXPLAYERS + 1];
new Handle:TalentUpgradeValues[MAXPLAYERS + 1];
new Handle:TalentUpgradeSection[MAXPLAYERS + 1];
new Handle:InfectedHealth[MAXPLAYERS + 1];
new Handle:SpecialCommon[MAXPLAYERS + 1];
new Handle:WitchList;
new Handle:WitchDamage[MAXPLAYERS + 1];
//new IncapacitatedHealth[MAXPLAYERS + 1];
new Handle:Give_Store_Keys;
new Handle:Give_Store_Values;
new Handle:Give_Store_Section;
new bool:bIsMeleeCooldown[MAXPLAYERS + 1];
new Handle:a_WeaponDamages;
new Handle:MeleeKeys[MAXPLAYERS + 1];
new Handle:MeleeValues[MAXPLAYERS + 1];
new Handle:MeleeSection[MAXPLAYERS + 1];
new String:Public_LastChatUser[64];
new String:Infected_LastChatUser[64];
new String:Survivor_LastChatUser[64];
new String:Spectator_LastChatUser[64];
new String:currentCampaignName[64];
//new Float:g_MapFlowDistance;
new Handle:h_KilledPosition_X[MAXPLAYERS + 1];
new Handle:h_KilledPosition_Y[MAXPLAYERS + 1];
new Handle:h_KilledPosition_Z[MAXPLAYERS + 1];
new bool:bIsEligibleMapAward[MAXPLAYERS + 1];
new String:ChatSettingsName[MAXPLAYERS + 1][64];
new Handle:a_ChatSettings;
new Handle:ChatSettings[MAXPLAYERS + 1];
new bool:b_ConfigsExecuted;
new bool:b_FirstLoad;
new bool:b_MapStart;
new bool:b_HardcoreMode[MAXPLAYERS + 1];
new PreviousRoundIncaps[MAXPLAYERS + 1];
new RoundIncaps[MAXPLAYERS + 1];
//new RoundDeaths[MAXPLAYERS + 1];
new String:CONFIG_MAIN[64];
new bool:b_IsCampaignComplete;
new bool:b_IsRoundIsOver;
new RatingHandicap[MAXPLAYERS + 1];
new bool:bIsHandicapLocked[MAXPLAYERS + 1];
new bool:b_IsCheckpointDoorStartOpened;
//new bool:b_IsSavingInfectedBotData;
//new bool:b_IsLoadingInfectedBotData;
new resr[MAXPLAYERS + 1];
new LastPlayLength[MAXPLAYERS + 1];
new RestedExperience[MAXPLAYERS + 1];
//new bool:bIsLoadedBotData;
new MapRoundsPlayed;
new String:LastSpoken[MAXPLAYERS + 1][512];
new Handle:RPGMenuPosition[MAXPLAYERS + 1];
new bool:b_IsInSaferoom[MAXPLAYERS + 1];
new Handle:hDatabase												=	INVALID_HANDLE;
new String:ConfigPathDirectory[64];
new String:LogPathDirectory[64];
new String:PurchaseSurvEffects[MAXPLAYERS + 1][64];
new String:PurchaseTalentName[MAXPLAYERS + 1][64];
new PurchaseTalentPoints[MAXPLAYERS + 1];
new Handle:a_Trails;
new Handle:TrailsKeys[MAXPLAYERS + 1];
new Handle:TrailsValues[MAXPLAYERS + 1];
new bool:b_IsFinaleActive;
new RoundDamage[MAXPLAYERS + 1];
new RoundDamageTotal;
new SpecialsKilled;
new Handle:LockedTalentKeys;
new Handle:LockedTalentValues;
new Handle:LockedTalentSection;
new Handle:MOTKeys[MAXPLAYERS + 1];
new Handle:MOTValues[MAXPLAYERS + 1];
new Handle:MOTSection[MAXPLAYERS + 1];
new Handle:DamageKeys[MAXPLAYERS + 1];
new Handle:DamageValues[MAXPLAYERS + 1];
new Handle:DamageSection[MAXPLAYERS + 1];
new Handle:BoosterKeys[MAXPLAYERS + 1];
new Handle:BoosterValues[MAXPLAYERS + 1];
new Handle:StoreChanceKeys[MAXPLAYERS + 1];
new Handle:StoreChanceValues[MAXPLAYERS + 1];
new Handle:StoreItemNameSection[MAXPLAYERS + 1];
new Handle:StoreItemSection[MAXPLAYERS + 1];
new String:PathSetting[64];
new Handle:SaveSection[MAXPLAYERS + 1];
new OriginalHealth[MAXPLAYERS + 1];
new bool:b_IsLoadingStore[MAXPLAYERS + 1];
new Handle:LoadStoreSection[MAXPLAYERS + 1];
new SlatePoints[MAXPLAYERS + 1];
new FreeUpgrades[MAXPLAYERS + 1];
new Handle:StoreTimeKeys[MAXPLAYERS + 1];
new Handle:StoreTimeValues[MAXPLAYERS + 1];
new Handle:StoreKeys[MAXPLAYERS + 1];
new Handle:StoreValues[MAXPLAYERS + 1];
new Handle:StoreMultiplierKeys[MAXPLAYERS + 1];
new Handle:StoreMultiplierValues[MAXPLAYERS + 1];
new Handle:a_Store_Player[MAXPLAYERS + 1];
new bool:b_IsLoadingTrees[MAXPLAYERS + 1];
new bool:b_IsArraysCreated[MAXPLAYERS + 1];
new Handle:a_Store;
new PlayerUpgradesTotal[MAXPLAYERS + 1];
new Float:f_TankCooldown;
new Float:DeathLocation[MAXPLAYERS + 1][3];
new TimePlayed[MAXPLAYERS + 1];
new bool:b_IsLoading[MAXPLAYERS + 1];
new LastLivingSurvivor;
new Float:f_OriginStart[MAXPLAYERS + 1][3];
new Float:f_OriginEnd[MAXPLAYERS + 1][3];
new t_Distance[MAXPLAYERS + 1];
new t_Healing[MAXPLAYERS + 1];
new bool:b_IsActiveRound;
new bool:b_IsFirstPluginLoad;
new String:s_rup[32];
new Handle:MainKeys;
new Handle:MainValues;
new Handle:a_Menu_Talents;
new Handle:a_Menu_Main;
new Handle:a_Events;
new Handle:a_Points;
new Handle:a_Pets;
new Handle:a_Database_Talents;
new Handle:a_Database_Talents_Defaults;
new Handle:a_Database_Talents_Defaults_Name;
new Handle:MenuKeys[MAXPLAYERS + 1];
new Handle:MenuValues[MAXPLAYERS + 1];
new Handle:MenuSection[MAXPLAYERS + 1];
new Handle:TriggerKeys[MAXPLAYERS + 1];
new Handle:TriggerValues[MAXPLAYERS + 1];
new Handle:TriggerSection[MAXPLAYERS + 1];
new Handle:AbilityKeys[MAXPLAYERS + 1];
new Handle:AbilityValues[MAXPLAYERS + 1];
new Handle:AbilitySection[MAXPLAYERS + 1];
new Handle:ChanceKeys[MAXPLAYERS + 1];
new Handle:ChanceValues[MAXPLAYERS + 1];
new Handle:ChanceSection[MAXPLAYERS + 1];
new Handle:PurchaseKeys[MAXPLAYERS + 1];
new Handle:PurchaseValues[MAXPLAYERS + 1];
new Handle:EventSection;
new Handle:HookSection;
new Handle:CallKeys;
new Handle:CallValues;
//new Handle:CallSection;
new Handle:DirectorKeys;
new Handle:DirectorValues;
//new Handle:DirectorSection;
new Handle:DatabaseKeys;
new Handle:DatabaseValues;
new Handle:DatabaseSection;
new Handle:a_Database_PlayerTalents_Bots;
new Handle:PlayerAbilitiesCooldown_Bots;
new Handle:PlayerAbilitiesImmune_Bots;
new Handle:BotSaveKeys;
new Handle:BotSaveValues;
new Handle:BotSaveSection;
new Handle:LoadDirectorSection;
new Handle:QueryDirectorKeys;
new Handle:QueryDirectorValues;
new Handle:QueryDirectorSection;
new Handle:FirstDirectorKeys;
new Handle:FirstDirectorValues;
new Handle:FirstDirectorSection;
new Handle:a_Database_PlayerTalents[MAXPLAYERS + 1];
new Handle:a_Database_PlayerTalents_Experience[MAXPLAYERS + 1];
new Handle:PlayerAbilitiesName;
new Handle:PlayerAbilitiesCooldown[MAXPLAYERS + 1];
//new Handle:PlayerAbilitiesImmune[MAXPLAYERS + 1][MAXPLAYERS + 1];
new Handle:PlayerInventory[MAXPLAYERS + 1];
new Handle:PlayerEquipped[MAXPLAYERS + 1];
new Handle:a_DirectorActions;
new Handle:a_DirectorActions_Cooldown;
new PlayerLevel[MAXPLAYERS + 1];
new PlayerLevelUpgrades[MAXPLAYERS + 1];
new TotalTalentPoints[MAXPLAYERS + 1];
new ExperienceLevel[MAXPLAYERS + 1];
new SkyPoints[MAXPLAYERS + 1];
new String:MenuSelection[MAXPLAYERS + 1][PLATFORM_MAX_PATH];
new String:MenuSelection_p[MAXPLAYERS + 1][PLATFORM_MAX_PATH];
new String:MenuName_c[MAXPLAYERS + 1][PLATFORM_MAX_PATH];
new Float:Points[MAXPLAYERS + 1];
new DamageAward[MAXPLAYERS + 1][MAXPLAYERS + 1];
new DefaultHealth[MAXPLAYERS + 1];
new String:white[4];
new String:green[4];
new String:blue[4];
new String:orange[4];
new bool:b_IsBlind[MAXPLAYERS + 1];
new bool:b_IsImmune[MAXPLAYERS + 1];
new Float:SpeedMultiplier[MAXPLAYERS + 1];
new Float:SpeedMultiplierBase[MAXPLAYERS + 1];
new bool:b_IsJumping[MAXPLAYERS + 1];
new Handle:g_hEffectAdrenaline = INVALID_HANDLE;
new Handle:g_hCallVomitOnPlayer = INVALID_HANDLE;
new Handle:hRoundRespawn = INVALID_HANDLE;
new Handle:g_hCreateAcid = INVALID_HANDLE;
new Float:GravityBase[MAXPLAYERS + 1];
new bool:b_GroundRequired[MAXPLAYERS + 1];
new CoveredInBile[MAXPLAYERS + 1][MAXPLAYERS + 1];
new CommonKills[MAXPLAYERS + 1];
new CommonKillsHeadshot[MAXPLAYERS + 1];
new String:OpenedMenu_p[MAXPLAYERS + 1][512];
new String:OpenedMenu[MAXPLAYERS + 1][512];
new ExperienceOverall[MAXPLAYERS + 1];
//new String:CurrentTalentLoading_Bots[128];
//new Handle:a_Database_PlayerTalents_Bots;
//new Handle:PlayerAbilitiesCooldown_Bots;				// Because [designation] = ZombieclassID
new ExperienceLevel_Bots;
//new ExperienceOverall_Bots;
//new PlayerLevelUpgrades_Bots;
new PlayerLevel_Bots;
//new TotalTalentPoints_Bots;
new Float:Points_Director;
new Handle:CommonInfectedQueue;
new g_oAbility = 0;
new Handle:g_hIsStaggering = INVALID_HANDLE;
new Handle:g_hSetClass = INVALID_HANDLE;
new Handle:g_hCreateAbility = INVALID_HANDLE;
new Handle:gd = INVALID_HANDLE;
//new Handle:DirectorPurchaseTimer = INVALID_HANDLE;
new bool:b_IsDirectorTalents[MAXPLAYERS + 1];
//new LoadPos_Bots;
new LoadPos[MAXPLAYERS + 1];
new LoadPos_Director;
new Handle:g_Steamgroup;
new Handle:g_Gamemode;
new RoundTime;
new g_iSprite = 0;
new g_BeaconSprite = 0;
new iNoSpecials;
//new bool:b_FirstClientLoaded;
new bool:b_HasDeathLocation[MAXPLAYERS + 1];
new bool:b_IsMissionFailed;
new Handle:CCASection;
new Handle:CCAKeys;
new Handle:CCAValues;
new LastWeaponDamage[MAXPLAYERS + 1];
new Float:UseItemTime[MAXPLAYERS + 1];
new Handle:NewUsersRound;
new bool:bIsSoloHandicap;
new Handle:MenuStructure[MAXPLAYERS + 1];
new Handle:TankState_Array[MAXPLAYERS + 1];
new bool:bIsGiveIncapHealth[MAXPLAYERS + 1];
new Handle:TheLeaderboards[MAXPLAYERS + 1];
new Handle:TheLeaderboardsData[MAXPLAYERS + 1];
new TheLeaderboardsPage[MAXPLAYERS + 1];		// 10 entries at a time, until the end of time.
new bool:bIsMyRanking[MAXPLAYERS + 1];
new TheLeaderboardsPageSize[MAXPLAYERS + 1];
new CurrentRPGMode;
new bool:IsSurvivalMode = false;
new BestRating[MAXPLAYERS + 1];
new MyRespawnTarget[MAXPLAYERS + 1];
new bool:RespawnImmunity[MAXPLAYERS + 1];
new String:TheDBPrefix[64];
new LastAttackedUser[MAXPLAYERS + 1];
new Handle:LoggedUsers;
new Handle:TalentTreeKeys[MAXPLAYERS + 1];
new Handle:TalentTreeValues[MAXPLAYERS + 1];
new Handle:TalentExperienceKeys[MAXPLAYERS + 1];
new Handle:TalentExperienceValues[MAXPLAYERS + 1];
new Handle:TalentActionKeys[MAXPLAYERS + 1];
new Handle:TalentActionValues[MAXPLAYERS + 1];
new Handle:TalentActionSection[MAXPLAYERS + 1];
new bool:bIsTalentTwo[MAXPLAYERS + 1];
new Handle:CommonDrawKeys;
new Handle:CommonDrawValues;
new bool:bAutoRevive[MAXPLAYERS + 1];
new bool:bIsClassAbilities[MAXPLAYERS + 1];
new bool:bIsDisconnecting[MAXPLAYERS + 1];
new Handle:LegitClassSection[MAXPLAYERS + 1];
new LoadProfileRequestName[MAXPLAYERS + 1];
//new String:LoadProfileRequest[MAXPLAYERS + 1];
new String:TheCurrentMap[64];
new bool:IsEnrageNotified;
//new bool:bIsNewClass[MAXPLAYERS + 1];
new ClientActiveStance[MAXPLAYERS + 1];
new bool:b_RescueIsHere;
new Handle:SurvivorsIgnored[MAXPLAYERS + 1];
new bool:HasSeenCombat[MAXPLAYERS + 1];
new MyBirthday[MAXPLAYERS + 1];
//======================================
//Main config static variables.
//======================================
new Float:fSuperCommonLimit;
new Float:fBurnPercentage;
new iTankRush;
new iTanksAlways;
new Float:fSprintSpeed;
new iRPGMode;
new iTankPlayerCount;
new DirectorWitchLimit;
new Float:fCommonQueueLimit;
new Float:fDirectorThoughtDelay;
new Float:fDirectorThoughtHandicap;
new iSurvivalRoundTime;
new Float:fDazedDebuffEffect;
new ConsumptionInt;
new Float:fStamSprintInterval;
new Float:fStamRegenTime;
new Float:fStamRegenTimeAdren;
new Float:fBaseMovementSpeed;
new Float:fFatigueMovementSpeed;
new iPlayerStartingLevel;
new iBotPlayerStartingLevel;
new Float:fOutOfCombatTime;
new iWitchDamageInitial;
new Float:fWitchDamageScaleLevel;
new Float:fSurvivorDamageBonus;
new Float:fSurvivorHealthBonus;
new iEnrageTime;
new Float:fWitchDirectorPoints;
new Float:fEnrageDirectorPoints;
new Float:fCommonDamageLevel;
new iBotLevelType;
new Float:fCommonDirectorPoints;
new iDisplayHealthBars;
new iMaxDifficultyLevel;
new Float:fDamagePlayerLevel[7];
new Float:fHealthPlayerLevel[7];
new iBaseSpecialDamage[7];
new iBaseSpecialInfectedHealth[7];
new Float:fPointsMultiplierInfected;
new Float:fPointsMultiplier;
new Float:fHealingMultiplier;
new Float:fBuffingMultiplier;
new Float:fHexingMultiplier;
new Float:TanksNearbyRange;
new iCommonAffixes;
new BroadcastType;
new iDoomTimer;
new iSurvivorStaminaMax;
new Float:fRatingMultSpecials;
new Float:fRatingMultSupers;
new Float:fRatingMultCommons;
new Float:fRatingMultTank;
new Float:fTeamworkExperience;
new Float:fItemMultiplierLuck;
new Float:fItemMultiplierTeam;
new String:sQuickBindHelp[64];
new Float:fPointsCostLevel;
new PointPurchaseType;
new iTankLimitVersus;
new Float:fHealRequirementTeam;
new iSurvivorBaseHealth;
new iSurvivorBotBaseHealth;
new String:spmn[64];
new Float:fHealthSurvivorRevive;
new String:RestrictedWeapons[1024];
new iMaxLevel;
new iExperienceStart;
new Float:fExperienceMultiplier;
new String:sBotTeam[64];
new iActionBarSlots;
new String:MenuCommand[64];
new HostNameTime;
new DoomSUrvivorsRequired;
new DoomKillTimer;
new Float:fVersusTankNotice;
new AllowedCommons;
new AllowedMegaMob;
new AllowedMobSpawn;
new AllowedMobSpawnFinale;
new AllowedPanicInterval;
new RespawnQueue;
new MaximumPriority;
new Float:ConsMult;
new Float:AgilMult;
new Float:ResiMult;
new Float:TechMult;
new Float:EnduMult;
new Float:fUpgradeExpCost;
new iHandicapLevelDifference;
new iWitchHealthBase;
new Float:fWitchHealthMult;
new RatingPerLevel;
new iCommonBaseHealth;
new Float:fCommonRaidHealthMult;
new Float:fCommonLevelHealthMult;
new iServerLevelRequirement;
new iRoundStartWeakness;
new Float:GroupMemberBonus;
new Float:FinSurvBon;
new RaidLevMult;
new iIgnoredRating;
new iIgnoredRatingMax;
//new iTrailsEnabled;
new iInfectedLimit;
new Float:SurvivorExperienceMult;
new Float:SurvivorExperienceMultTank;
new Float:SurvivorExperienceMultHeal;
new Float:TheScorchMult;
new Float:TheInfernoMult;
new Float:fAmmoHighlightTime;
new Float:fAdrenProgressMult;
new Float:DirectorTankCooldown;
new DisplayType;
new String:sDirectorTeam[64];
new Float:fRestedExpMult;
new Float:fSurvivorExpMult;
new iIsPvpServer;
new iDebuffLimit;
new iRatingSpecialsRequired;
new iRatingTanksRequired;
new String:sDbLeaderboards[64];
new iIsLifelink;
new RatingPerHandicap;
new Handle:ItemDropArray;
new String:sItemModel[512];
new iSurvivorGroupMinimum;
new Float:fDropChanceSpecial;
new Float:fDropChanceCommon;
new Float:fDropChanceWitch;
new Float:fDropChanceTank;
new Float:fDropChanceInfected;
new Handle:PreloadKeys;
new Handle:PreloadValues;
new Handle:ItemDropKeys;
new Handle:ItemDropValues;
new Handle:ItemDropSection;
new Handle:persistentCirculation;
new iItemExpireDate;
new iRarityMax;
new iEnrageAdvertisement;
new iJoinGroupAdvertisement;
new iNotifyEnrage;
new String:sBackpackModel[64];

new String:ItemDropArraySize[64];
new bool:bIsNewPlayer[MAXPLAYERS + 1];

new Handle:MyGroup[MAXPLAYERS + 1];
new iCommonsLimitUpper;
new bool:bIsInCheckpoint[MAXPLAYERS + 1];
new Float:fCoopSurvBon;
new iMinSurvivors;
new PassiveEffectDisplay[MAXPLAYERS + 1];
new String:sServerDifficulty[64];
new iSpecialsAllowed;
new String:sSpecialsAllowed[64];
new iSurvivorModifierRequired;
new Float:fEnrageMultiplier;
new OverHealth[MAXPLAYERS + 1];
new bool:bHealthIsSet[MAXPLAYERS + 1];
new iIsLevelingPaused[MAXPLAYERS + 1];
new iIsBulletTrails[MAXPLAYERS + 1];

new Handle:ActiveStatuses[MAXPLAYERS + 1];
new InfectedTalentLevel;
new Float:fEnrageModifier;
new Float:LastAttackTime[MAXPLAYERS + 1];

new Handle:hWeaponList[MAXPLAYERS + 1];
new Handle:GCVKeys[MAXPLAYERS + 1];
new Handle:GCVValues[MAXPLAYERS + 1];
new Handle:GCVSection[MAXPLAYERS + 1];

new MyStatusEffects[MAXPLAYERS + 1];
new iShowLockedTalents;
new Handle:GCMKeys[MAXPLAYERS + 1];
new Handle:GCMValues[MAXPLAYERS + 1];
new Handle:PassiveStrengthKeys[MAXPLAYERS + 1];
new Handle:PassiveStrengthValues[MAXPLAYERS + 1];
new Handle:PassiveTalentName[MAXPLAYERS + 1];
new Handle:UpgradeCategoryKeys[MAXPLAYERS + 1];
new Handle:UpgradeCategoryValues[MAXPLAYERS + 1];
new Handle:UpgradeCategoryName[MAXPLAYERS + 1];
new iChaseEnt[MAXPLAYERS + 1];
//new Float:fSpellBulletStrength;
//new Float:fSpellEnduranceMultiplier;
new iTeamRatingRequired;
new Float:fTeamRatingBonus;
//new iNoobAssistanceLevel;
//new iNoobAssistance[MAXPLAYERS + 1];
//new Float:fNoobAssistanceResistance;
//new Float:fNoobAssistanceHealing;
//new Float:fNoobAssistanceRecovery;
new Float:fRatingPercentLostOnDeath;
new Float:fHealSizeDefault;
new PlayerCurrentMenuLayer[MAXPLAYERS + 1];
new iMaxLayers;
new Handle:TranslationOTNKeys[MAXPLAYERS + 1];
new Handle:TranslationOTNValues[MAXPLAYERS + 1];
new Handle:TranslationOTNSection[MAXPLAYERS + 1];
new Handle:acdrKeys[MAXPLAYERS + 1];
new Handle:acdrValues[MAXPLAYERS + 1];
new Handle:acdrSection[MAXPLAYERS + 1];
new Handle:GetLayerStrengthKeys[MAXPLAYERS + 1];
new Handle:GetLayerStrengthValues[MAXPLAYERS + 1];
new Handle:GetLayerStrengthSection[MAXPLAYERS + 1];
new iCommonInfectedBaseDamage;
new playerPageOfCharacterSheet[MAXPLAYERS + 1];
new nodesInExistence;
new iShowTotalNodesOnTalentTree;
new Handle:PlayerEffectOverTime[MAXPLAYERS + 1];
new Handle:CheckEffectOverTimeKeys[MAXPLAYERS + 1];
new Handle:CheckEffectOverTimeValues[MAXPLAYERS + 1];
new Float:fSpecialAmmoInterval;
new Float:fEffectOverTimeInterval;
new Handle:FormatEffectOverTimeKeys[MAXPLAYERS + 1];
new Handle:FormatEffectOverTimeValues[MAXPLAYERS + 1];
new Handle:FormatEffectOverTimeSection[MAXPLAYERS + 1];
new Handle:CooldownEffectTriggerKeys[MAXPLAYERS + 1];
new Handle:CooldownEffectTriggerValues[MAXPLAYERS + 1];
new Handle:IsSpellAnAuraKeys[MAXPLAYERS + 1];
new Handle:IsSpellAnAuraValues[MAXPLAYERS + 1];
//new Float:fStaggerTime;
new Float:fStaggerTickrate;
new Handle:StaggeredTargets;
new Handle:staggerBuffer;
new bool:staggerCooldownOnTriggers[MAXPLAYERS + 1];
new Handle:CallAbilityCooldownTriggerKeys[MAXPLAYERS + 1];
new Handle:CallAbilityCooldownTriggerValues[MAXPLAYERS + 1];
new Handle:CallAbilityCooldownTriggerSection[MAXPLAYERS + 1];
new Handle:GetIfTriggerRequirementsMetKeys[MAXPLAYERS + 1];
new Handle:GetIfTriggerRequirementsMetValues[MAXPLAYERS + 1];
new Handle:GetIfTriggerRequirementsMetSection[MAXPLAYERS + 1];
new bool:ShowPlayerLayerInformation[MAXPLAYERS + 1];
new Handle:GAMKeys[MAXPLAYERS + 1];
new Handle:GAMValues[MAXPLAYERS + 1];
new Handle:GAMSection[MAXPLAYERS + 1];
new String:RPGMenuCommand[64];
new RPGMenuCommandExplode;
//new PrestigeLevel[MAXPLAYERS + 1];
new String:DefaultProfileName[64];
new String:DefaultBotProfileName[64];
new String:DefaultInfectedProfileName[64];
new Handle:GetGoverningAttributeKeys[MAXPLAYERS + 1];
new Handle:GetGoverningAttributeValues[MAXPLAYERS + 1];
new Handle:GetGoverningAttributeSection[MAXPLAYERS + 1];
new iRushingModuleEnabled;
new iTanksAlwaysEnforceCooldown;
new Handle:WeaponResultKeys[MAXPLAYERS + 1];
new Handle:WeaponResultValues[MAXPLAYERS + 1];
new Handle:WeaponResultSection[MAXPLAYERS + 1];
new bool:shotgunCooldown[MAXPLAYERS + 1];
new Float:fRatingFloor;
new String:clientStatusEffectDisplay[MAXPLAYERS + 1][64];
new String:clientTrueHealthDisplay[MAXPLAYERS + 1][64];
new String:clientContributionHealthDisplay[MAXPLAYERS + 1][64];
new currLivingSurvivors;
new iExperienceDebtLevel;
new iExperienceDebtEnabled;
new Float:fExperienceDebtPenalty;
new iShowDamageOnActionBar;
new iDefaultIncapHealth;
new Handle:GetAbilityCooldownKeys[MAXPLAYERS + 1];
new Handle:GetAbilityCooldownValues[MAXPLAYERS + 1];
new Handle:GetAbilityCooldownSection[MAXPLAYERS + 1];
new Handle:GetTalentValueSearchKeys[MAXPLAYERS + 1];
new Handle:GetTalentValueSearchValues[MAXPLAYERS + 1];
new Handle:GetTalentValueSearchSection[MAXPLAYERS + 1];
new iSkyLevelNodeUnlocks;
new Handle:GetTalentKeyValueKeys[MAXPLAYERS + 1];
new Handle:GetTalentKeyValueValues[MAXPLAYERS + 1];
new Handle:GetTalentKeyValueSection[MAXPLAYERS + 1];
new Handle:ApplyDebuffCooldowns[MAXPLAYERS + 1];
new iCanSurvivorBotsBurn;
new String:defaultLoadoutWeaponPrimary[64];
new String:defaultLoadoutWeaponSecondary[64];
new iDeleteCommonsFromExistenceOnDeath;
new iShowDetailedDisplayAlways;
new iCanJetpackWhenInCombat;
new Handle:ZoomcheckDelayer[MAXPLAYERS + 1];
new Handle:zoomCheckList;
new Float:fquickScopeTime;
new Handle:holdingFireDelayer[MAXPLAYERS + 1];
new Handle:holdingFireList;
new LastBulletCheck[MAXPLAYERS + 1];
new iEnsnareLevelMultiplier;
new Handle:CommonInfectedHealth;
new lastBaseDamage[MAXPLAYERS + 1];
new lastTarget[MAXPLAYERS + 1];
new String:lastWeapon[MAXPLAYERS + 1][64];
new iSurvivorBotsBonusLimit;
new Float:fSurvivorBotsNoneBonus;
new bool:bTimersRunning[MAXPLAYERS + 1];
new iShowAdvertToNonSteamgroupMembers;
new displayBuffOrDebuff[MAXPLAYERS + 1];

public Action:CMD_DropWeapon(client, args) {
	new CurrentEntity			=	GetEntPropEnt(client, Prop_Data, "m_hActiveWeapon");
	if (!IsValidEntity(CurrentEntity) || CurrentEntity < 1) return Plugin_Handled;
	decl String:EntityName[64];
	GetEdictClassname(CurrentEntity, EntityName, sizeof(EntityName));
	if (StrContains(EntityName, "melee", false) != -1) return Plugin_Handled;
	new Entity					=	CreateEntityByName(EntityName);
	DispatchSpawn(Entity);
	new Float:Origin[3];
	GetClientAbsOrigin(client, Origin);
	Origin[2] += 64.0;
	TeleportEntity(Entity, Origin, NULL_VECTOR, NULL_VECTOR);
	SetEntityMoveType(Entity, MOVETYPE_VPHYSICS);
	if (GetWeaponSlot(Entity) < 2) SetEntProp(Entity, Prop_Send, "m_iClip1", GetEntProp(CurrentEntity, Prop_Send, "m_iClip1"));
	AcceptEntityInput(CurrentEntity, "Kill");
	return Plugin_Handled;
}

public Action:CMD_IAmStuck(client, args) {
	if (L4D2_GetInfectedAttacker(client) == -1 && !AnyTanksNearby(client, 512.0)) {
		new target = FindAnyRandomClient(true, client);
		if (target > 0) {
			GetClientAbsOrigin(target, Float:DeathLocation[client]);
			TeleportEntity(client, DeathLocation[client], NULL_VECTOR, NULL_VECTOR);
			SetEntityMoveType(client, MOVETYPE_WALK);
		}
	}

	return Plugin_Handled;
}


stock DoGunStuff(client) {
	new targetgun = GetPlayerWeaponSlot(client, 0); //get the players primary weapon
	if (!IsValidEdict(targetgun)) return; //check for validity
	new iAmmoOffset = FindDataMapOffs(client, "m_iAmmo"); //get the iAmmo Offset
	iAmmoOffset = GetEntData(client, (iAmmoOffset + GetWeaponResult(client, 1)));
	PrintToChat(client, "reserve remaining: %d | reserve cap: %d", iAmmoOffset, GetWeaponResult(client, 2));
	return;
}

stock CMD_OpenRPGMenu(client) {
	//DoGunStuff(client);
	ClearArray(Handle:MenuStructure[client]);	// keeps track of the open menus.
	VerifyAllActionBars(client);	// Because.
	if (LoadProfileRequestName[client] != -1) {
		if (!IsLegitimateClient(LoadProfileRequestName[client])) LoadProfileRequestName[client] = -1;
	}
	iIsWeaponLoadout[client] = 0;
	bEquipSpells[client] = false;
	PlayerCurrentMenuLayer[client] = 1;
	ShowPlayerLayerInformation[client] = false;
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

public OnPluginStart() {
	CreateConVar("skyrpg_version", PLUGIN_VERSION, "version header", CVAR_SHOW);
	SetConVarString(FindConVar("skyrpg_version"), PLUGIN_VERSION);
	CreateConVar("skyrpg_profile", PROFILE_VERSION, "RPG Profile Editor Module", CVAR_SHOW);
	SetConVarString(FindConVar("skyrpg_profile"), PROFILE_VERSION);
	CreateConVar("skyrpg_contact", PLUGIN_CONTACT, "SkyRPG contact", CVAR_SHOW);
	SetConVarString(FindConVar("skyrpg_contact"), PLUGIN_CONTACT);
	CreateConVar("skyrpg_url", PLUGIN_URL, "SkyRPG url", CVAR_SHOW);
	SetConVarString(FindConVar("skyrpg_url"), PLUGIN_URL);
	g_Steamgroup = FindConVar("sv_steamgroup");
	SetConVarFlags(g_Steamgroup, GetConVarFlags(g_Steamgroup) & ~FCVAR_NOTIFY);
	//g_Tags = FindConVar("sv_tags");
	//SetConVarFlags(g_Tags, GetConVarFlags(g_Tags) & ~FCVAR_NOTIFY);
	g_Gamemode = FindConVar("mp_gamemode");
	LoadTranslations("skyrpg.phrases");
	BuildPath(Path_SM, ConfigPathDirectory, sizeof(ConfigPathDirectory), "configs/readyup/");
	if (!DirExists(ConfigPathDirectory)) CreateDirectory(ConfigPathDirectory, 777);
	BuildPath(Path_SM, LogPathDirectory, sizeof(LogPathDirectory), "logs/readyup/rpg/");
	if (!DirExists(LogPathDirectory)) CreateDirectory(LogPathDirectory, 777);
	BuildPath(Path_SM, LogPathDirectory, sizeof(LogPathDirectory), "logs/readyup/rpg/%s", LOGFILE);
	if (!FileExists(LogPathDirectory)) SetFailState("[SKYRPG LOGGING] please create file at %s", LogPathDirectory);
	RegAdminCmd("debugrpg", Cmd_debugrpg, ADMFLAG_KICK);
	RegAdminCmd("resettpl", Cmd_ResetTPL, ADMFLAG_KICK);
	RegAdminCmd("origin", Cmd_GetOrigin, ADMFLAG_KICK);
	// These are mandatory because of quick commands, so I hardcode the entries.
	RegConsoleCmd("say", CMD_ChatCommand);
	RegConsoleCmd("say_team", CMD_TeamChatCommand);
	RegConsoleCmd("callvote", CMD_BlockVotes);
	RegConsoleCmd("vote", CMD_BlockVotes);
	//RegConsoleCmd("talentupgrade", CMD_TalentUpgrade);
	RegConsoleCmd("loadoutname", CMD_LoadoutName);
	RegConsoleCmd("stuck", CMD_IAmStuck);
	RegConsoleCmd("ff", CMD_TogglePvP);
	RegConsoleCmd("revive", CMD_RespawnYumYum);
	RegConsoleCmd("abar", CMD_ActionBar);
	RegConsoleCmd("handicap", CMD_Handicap);
	RegAdminCmd("firesword", CMD_FireSword, ADMFLAG_KICK);
	RegAdminCmd("fbegin", CMD_FBEGIN, ADMFLAG_KICK);
	RegAdminCmd("witches", CMD_WITCHESCOUNT, ADMFLAG_KICK);
	RegAdminCmd("staggertest", CMD_STAGGERTEST, ADMFLAG_KICK);
	Format(white, sizeof(white), "\x01");
	Format(orange, sizeof(orange), "\x04");
	Format(green, sizeof(green), "\x05");
	Format(blue, sizeof(blue), "\x03");
	gd = LoadGameConfigFile("rum_rpg");
	if (gd != INVALID_HANDLE)
	{		
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
	CheckDifficulty();
	staggerBuffer = CreateConVar("sm_vscript_res", "", "returns results from vscript check on stagger");
}


public Action:CMD_STAGGERTEST(client, args) {
	/*new target = GetClientAimTarget(client, false);
	decl String:targetName[64];
	GetEntityClassname(target, targetName, sizeof(targetName));
	PrintToChat(client, "entity name: %s", targetName);
	GetEntPropString(target, Prop_Data, "m_iName", targetName, sizeof(targetName));
	PrintToChat(client, "entity targetname: %s", targetName);*/

	for (new i = 1; i <= MaxClients; i++) {
		if (!IsLegitimateClient(i) || GetClientTeam(i) != TEAM_SURVIVOR) continue;
		if (i == client) continue;

		StaggerPlayer(client, i);
		StaggerPlayer(i, client);
		break;
	}
	return Plugin_Handled;
}


public Action:CMD_WITCHESCOUNT(client, args) {

	PrintToChat(client, "Witches: %d", GetArraySize(WitchList));
	return Plugin_Handled;
}

public Action:CMD_FBEGIN(client, args) {

	ReadyUpEnd_Complete();
}

public Action:Cmd_GetOrigin(client, args) {

	new Float:OriginP[3];
	decl String:sMelee[64];
	GetMeleeWeapon(client, sMelee, sizeof(sMelee));
	GetClientAbsOrigin(client, OriginP);
	PrintToChat(client, "[0] %3.3f [1] %3.3f [2] %3.3f\n%s", OriginP[0], OriginP[1], OriginP[2], sMelee);
	return Plugin_Handled;
}

public Action:CMD_BlockVotes(client, args) {



	return Plugin_Handled;
}

public ReadyUp_SetSurvivorMinimum(minSurvs) {

	iMinSurvivors = minSurvs;
}

public ReadyUp_GetMaxSurvivorCount(count) {
	if (count <= 1) bIsSoloHandicap = true;
	else bIsSoloHandicap = false;
}

stock UnhookAll() {
	for (new i = 1; i <= MaxClients; i++) {
		if (IsLegitimateClient(i)) {
			SDKUnhook(i, SDKHook_OnTakeDamage, OnTakeDamage);
			b_IsHooked[i] = false;
		}
	}
}

public ReadyUp_TrueDisconnect(client) {

	if (bIsInCombat[client]) IncapacitateOrKill(client, _, _, true, true, true);
	//ChangeHook(client);
	staggerCooldownOnTriggers[client] = false;
	ISBILED[client] = false;
	DisplayActionBar[client] = false;
	IsPvP[client] = 0;
	b_IsFloating[client] = false;
	b_IsLoading[client] = false;
	b_HardcoreMode[client] = false;
	//WipeDebuffs(_, client, true);
	if (b_IsLoaded[client]) SaveAndClear(client, true);
	IsPlayerDebugMode[client] = 0;
	CleanseStack[client] = 0;
	CounterStack[client] = 0.0;
	MultiplierStack[client] = 0;
	LoadTarget[client] = -1;
	b_IsLoaded[client] = false;		// only set to false if a REAL player leaves - this way bots don't repeatedly load their data.
	Format(ProfileLoadQueue[client], sizeof(ProfileLoadQueue[]), "none");
	Format(BuildingStack[client], sizeof(BuildingStack[]), "none");
	Format(LoadoutName[client], sizeof(LoadoutName[]), "none");
	//CreateTimer(1.0, Timer_RemoveSaveSafety, client, TIMER_FLAG_NO_MAPCHANGE);
	bIsSettingsCheck = true;
	if (b_IsActiveRound && TotalHumanSurvivors() < 1) {	// If the disconnecting player was the last human survivor, if the round is live, we end the round.
		ForceServerCommand("scenario_end");
		CallRoundIsOver();
	}
}


/*public ReadyUp_FwdChangeTeam(client, team) {

	if (team == TEAM_SPECTATOR) {

		if (bIsInCombat[client]) {

			IncapacitateOrKill(client, _, _, true, true);
		}

		b_IsHooked[client] = false;
		SDKUnhook(client, SDKHook_OnTakeDamage, OnTakeDamage);
	}
	else if (team == TEAM_SURVIVOR && !b_IsHooked[client]) {

		b_IsHooked[client] = true;
		SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);
	}
}*/

//stock LoadConfigValues() {
//}

public OnAllPluginsLoaded() {

	OnMapStartFunc();
	CheckDifficulty();
}

stock OnMapStartFunc() {

	if (!b_MapStart) {
		
		b_MapStart								= true;
		CreateTimer(1.0, Timer_CheckDifficulty, _, TIMER_REPEAT);
		//LoadConfigValues();
		LogMessage("=====\t\tLOADING RPG\t\t=====");
		//new String:fubar[64];
		if (holdingFireList == INVALID_HANDLE || !b_FirstLoad) holdingFireList = CreateArray(32);
		if (zoomCheckList == INVALID_HANDLE || !b_FirstLoad) zoomCheckList = CreateArray(32);
		if (hThreatSort == INVALID_HANDLE || !b_FirstLoad) hThreatSort = CreateArray(32);
		if (hThreatMeter == INVALID_HANDLE || !b_FirstLoad) hThreatMeter = CreateArray(32);
		if (LoggedUsers == INVALID_HANDLE || !b_FirstLoad) LoggedUsers = CreateArray(32);
		if (SuperCommonQueue == INVALID_HANDLE || !b_FirstLoad) SuperCommonQueue = CreateArray(32);
		if (CommonInfectedQueue == INVALID_HANDLE || !b_FirstLoad) CommonInfectedQueue = CreateArray(32);
		if (CoveredInVomit == INVALID_HANDLE || !b_FirstLoad) CoveredInVomit = CreateArray(32);
		if (NewUsersRound == INVALID_HANDLE || !b_FirstLoad) NewUsersRound = CreateArray(32);
		if (SpecialAmmoData == INVALID_HANDLE || !b_FirstLoad) SpecialAmmoData = CreateArray(32);
		if (SpecialAmmoSave == INVALID_HANDLE || !b_FirstLoad) SpecialAmmoSave = CreateArray(32);
		if (MainKeys == INVALID_HANDLE || !b_FirstLoad) MainKeys = CreateArray(32);
		if (MainValues == INVALID_HANDLE || !b_FirstLoad) MainValues = CreateArray(32);
		if (a_Menu_Talents == INVALID_HANDLE || !b_FirstLoad) a_Menu_Talents = CreateArray(3);
		if (a_Menu_Main == INVALID_HANDLE || !b_FirstLoad) a_Menu_Main = CreateArray(3);
		if (a_Events == INVALID_HANDLE || !b_FirstLoad) a_Events = CreateArray(3);
		if (a_Points == INVALID_HANDLE || !b_FirstLoad) a_Points = CreateArray(3);
		if (a_Pets == INVALID_HANDLE || !b_FirstLoad) a_Pets = CreateArray(3);
		if (a_Store == INVALID_HANDLE || !b_FirstLoad) a_Store = CreateArray(3);
		if (a_Trails == INVALID_HANDLE || !b_FirstLoad) a_Trails = CreateArray(3);
		if (a_Database_Talents == INVALID_HANDLE || !b_FirstLoad) a_Database_Talents = CreateArray(32);
		if (a_Database_Talents_Defaults == INVALID_HANDLE || !b_FirstLoad) a_Database_Talents_Defaults 	= CreateArray(32);
		if (a_Database_Talents_Defaults_Name == INVALID_HANDLE || !b_FirstLoad) a_Database_Talents_Defaults_Name				= CreateArray(32);
		if (EventSection == INVALID_HANDLE || !b_FirstLoad) EventSection									= CreateArray(32);
		if (HookSection == INVALID_HANDLE || !b_FirstLoad) HookSection										= CreateArray(32);
		if (CallKeys == INVALID_HANDLE || !b_FirstLoad) CallKeys										= CreateArray(32);
		if (CallValues == INVALID_HANDLE || !b_FirstLoad) CallValues										= CreateArray(32);
		if (DirectorKeys == INVALID_HANDLE || !b_FirstLoad) DirectorKeys									= CreateArray(32);
		if (DirectorValues == INVALID_HANDLE || !b_FirstLoad) DirectorValues									= CreateArray(32);
		if (DatabaseKeys == INVALID_HANDLE || !b_FirstLoad) DatabaseKeys									= CreateArray(32);
		if (DatabaseValues == INVALID_HANDLE || !b_FirstLoad) DatabaseValues									= CreateArray(32);
		if (DatabaseSection == INVALID_HANDLE || !b_FirstLoad) DatabaseSection									= CreateArray(32);
		if (a_Database_PlayerTalents_Bots == INVALID_HANDLE || !b_FirstLoad) a_Database_PlayerTalents_Bots					= CreateArray(32);
		if (PlayerAbilitiesCooldown_Bots == INVALID_HANDLE || !b_FirstLoad) PlayerAbilitiesCooldown_Bots					= CreateArray(32);
		if (PlayerAbilitiesImmune_Bots == INVALID_HANDLE || !b_FirstLoad) PlayerAbilitiesImmune_Bots						= CreateArray(32);
		if (BotSaveKeys == INVALID_HANDLE || !b_FirstLoad) BotSaveKeys										= CreateArray(32);
		if (BotSaveValues == INVALID_HANDLE || !b_FirstLoad) BotSaveValues									= CreateArray(32);
		if (BotSaveSection == INVALID_HANDLE || !b_FirstLoad) BotSaveSection									= CreateArray(32);
		if (LoadDirectorSection == INVALID_HANDLE || !b_FirstLoad) LoadDirectorSection								= CreateArray(32);
		if (QueryDirectorKeys == INVALID_HANDLE || !b_FirstLoad) QueryDirectorKeys								= CreateArray(32);
		if (QueryDirectorValues == INVALID_HANDLE || !b_FirstLoad) QueryDirectorValues								= CreateArray(32);
		if (QueryDirectorSection == INVALID_HANDLE || !b_FirstLoad) QueryDirectorSection							= CreateArray(32);
		if (FirstDirectorKeys == INVALID_HANDLE || !b_FirstLoad) FirstDirectorKeys								= CreateArray(32);
		if (FirstDirectorValues == INVALID_HANDLE || !b_FirstLoad) FirstDirectorValues								= CreateArray(32);
		if (FirstDirectorSection == INVALID_HANDLE || !b_FirstLoad) FirstDirectorSection							= CreateArray(32);
		if (PlayerAbilitiesName == INVALID_HANDLE || !b_FirstLoad) PlayerAbilitiesName								= CreateArray(32);
		if (a_DirectorActions == INVALID_HANDLE || !b_FirstLoad) a_DirectorActions								= CreateArray(3);
		if (a_DirectorActions_Cooldown == INVALID_HANDLE || !b_FirstLoad) a_DirectorActions_Cooldown						= CreateArray(32);
		if (a_ChatSettings == INVALID_HANDLE || !b_FirstLoad) a_ChatSettings								= CreateArray(3);
		if (LockedTalentKeys == INVALID_HANDLE || !b_FirstLoad) LockedTalentKeys							= CreateArray(32);
		if (LockedTalentValues == INVALID_HANDLE || !b_FirstLoad) LockedTalentValues						= CreateArray(32);
		if (LockedTalentSection == INVALID_HANDLE || !b_FirstLoad) LockedTalentSection						= CreateArray(32);
		if (Give_Store_Keys == INVALID_HANDLE || !b_FirstLoad) Give_Store_Keys							= CreateArray(32);
		if (Give_Store_Values == INVALID_HANDLE || !b_FirstLoad) Give_Store_Values							= CreateArray(32);
		if (Give_Store_Section == INVALID_HANDLE || !b_FirstLoad) Give_Store_Section							= CreateArray(32);
		if (a_WeaponDamages == INVALID_HANDLE || !b_FirstLoad) a_WeaponDamages = CreateArray(32);
		if (a_CommonAffixes == INVALID_HANDLE || !b_FirstLoad) a_CommonAffixes = CreateArray(32);
		if (CommonList == INVALID_HANDLE || !b_FirstLoad) CommonList = CreateArray(32);
		if (WitchList == INVALID_HANDLE || !b_FirstLoad) WitchList				= CreateArray(32);
		if (CommonAffixes == INVALID_HANDLE || !b_FirstLoad) CommonAffixes	= CreateArray(32);
		if (h_CAKeys == INVALID_HANDLE || !b_FirstLoad) h_CAKeys = CreateArray(32);
		if (h_CAValues == INVALID_HANDLE || !b_FirstLoad) h_CAValues = CreateArray(32);
		if (SearchKey_Section == INVALID_HANDLE || !b_FirstLoad) SearchKey_Section = CreateArray(32);
		if (CCASection == INVALID_HANDLE || !b_FirstLoad) CCASection = CreateArray(32);
		if (CCAKeys == INVALID_HANDLE || !b_FirstLoad) CCAKeys = CreateArray(32);
		if (CCAValues == INVALID_HANDLE || !b_FirstLoad) CCAValues = CreateArray(32);
		if (h_CommonKeys == INVALID_HANDLE || !b_FirstLoad) h_CommonKeys = CreateArray(32);
		if (h_CommonValues == INVALID_HANDLE || !b_FirstLoad) h_CommonValues = CreateArray(32);
		if (CommonInfected == INVALID_HANDLE || !b_FirstLoad) CommonInfected = CreateArray(32);
		if (EntityOnFire == INVALID_HANDLE || !b_FirstLoad) EntityOnFire = CreateArray(32);
		if (CommonDrawKeys == INVALID_HANDLE || !b_FirstLoad) CommonDrawKeys = CreateArray(32);
		if (CommonDrawValues == INVALID_HANDLE || !b_FirstLoad) CommonDrawValues = CreateArray(32);
		if (ItemDropArray == INVALID_HANDLE || !b_FirstLoad) ItemDropArray = CreateArray(32);
		
		if (PreloadKeys == INVALID_HANDLE || !b_FirstLoad) PreloadKeys = CreateArray(32);
		if (PreloadValues == INVALID_HANDLE || !b_FirstLoad) PreloadValues = CreateArray(32);
		if (ItemDropKeys == INVALID_HANDLE || !b_FirstLoad) ItemDropKeys = CreateArray(32);
		if (ItemDropValues == INVALID_HANDLE || !b_FirstLoad) ItemDropValues = CreateArray(32);
		if (ItemDropSection == INVALID_HANDLE || !b_FirstLoad) ItemDropSection = CreateArray(32);
		if (persistentCirculation == INVALID_HANDLE || !b_FirstLoad) persistentCirculation = CreateArray(32);
		if (RandomSurvivorClient == INVALID_HANDLE || !b_FirstLoad) RandomSurvivorClient = CreateArray(32);
		if (RoundStatistics == INVALID_HANDLE || !b_FirstLoad) RoundStatistics = CreateArray(16);
		if (EffectOverTime == INVALID_HANDLE || !b_FirstLoad) EffectOverTime = CreateTrie();
		if (TimeOfEffectOverTime == INVALID_HANDLE || !b_FirstLoad) TimeOfEffectOverTime = CreateTrie();
		if (StaggeredTargets == INVALID_HANDLE || !b_FirstLoad) StaggeredTargets = CreateArray(32);
		if (CommonInfectedHealth == INVALID_HANDLE || !b_FirstLoad) CommonInfectedHealth = CreateArray(32);
		for (new i = 1; i <= MAXPLAYERS; i++) {

			LastDeathTime[i] = 0.0;
			MyVomitChase[i] = -1;
			b_IsFloating[i] = false;
			DisplayActionBar[i] = false;
			ActionBarSlot[i] = -1;

			if (currentEquippedWeapon[i] == INVALID_HANDLE || !b_FirstLoad) currentEquippedWeapon[i] = CreateTrie();
			if (GetCategoryStrengthKeys[i] == INVALID_HANDLE || !b_FirstLoad) GetCategoryStrengthKeys[i] = CreateArray(32);
			if (GetCategoryStrengthValues[i] == INVALID_HANDLE || !b_FirstLoad) GetCategoryStrengthValues[i] = CreateArray(32);
			if (GetCategoryStrengthSection[i] == INVALID_HANDLE || !b_FirstLoad) GetCategoryStrengthSection[i] = CreateArray(32);
			if (GCMKeys[i] == INVALID_HANDLE || !b_FirstLoad) GCMKeys[i] = CreateArray(32);
			if (GCMValues[i] == INVALID_HANDLE || !b_FirstLoad) GCMValues[i] = CreateArray(32);
			if (PassiveStrengthKeys[i] == INVALID_HANDLE || !b_FirstLoad) PassiveStrengthKeys[i] = CreateArray(32);
			if (PassiveStrengthValues[i] == INVALID_HANDLE || !b_FirstLoad) PassiveStrengthValues[i] = CreateArray(32);
			if (PassiveTalentName[i] == INVALID_HANDLE || !b_FirstLoad) PassiveTalentName[i] = CreateArray(32);
			if (UpgradeCategoryKeys[i] == INVALID_HANDLE || !b_FirstLoad) UpgradeCategoryKeys[i] = CreateArray(32);
			if (UpgradeCategoryValues[i] == INVALID_HANDLE || !b_FirstLoad) UpgradeCategoryValues[i] = CreateArray(32);
			if (UpgradeCategoryName[i] == INVALID_HANDLE || !b_FirstLoad) UpgradeCategoryName[i] = CreateArray(32);
			if (TranslationOTNKeys[i] == INVALID_HANDLE || !b_FirstLoad) TranslationOTNKeys[i] = CreateArray(32);
			if (TranslationOTNValues[i] == INVALID_HANDLE || !b_FirstLoad) TranslationOTNValues[i] = CreateArray(32);
			if (TranslationOTNSection[i] == INVALID_HANDLE || !b_FirstLoad) TranslationOTNSection[i] = CreateArray(32);
			if (GCVKeys[i] == INVALID_HANDLE || !b_FirstLoad) GCVKeys[i] = CreateArray(32);
			if (GCVValues[i] == INVALID_HANDLE || !b_FirstLoad) GCVValues[i] = CreateArray(32);
			if (GCVSection[i] == INVALID_HANDLE || !b_FirstLoad) GCVSection[i] = CreateArray(32);
			if (hWeaponList[i] == INVALID_HANDLE || !b_FirstLoad) hWeaponList[i] = CreateArray(32);
			if (LoadoutConfigKeys[i] == INVALID_HANDLE || !b_FirstLoad) LoadoutConfigKeys[i] = CreateArray(32);
			if (LoadoutConfigValues[i] == INVALID_HANDLE || !b_FirstLoad) LoadoutConfigValues[i] = CreateArray(32);
			if (LoadoutConfigSection[i] == INVALID_HANDLE || !b_FirstLoad) LoadoutConfigSection[i] = CreateArray(32);
			if (ActiveStatuses[i] == INVALID_HANDLE || !b_FirstLoad) ActiveStatuses[i] = CreateArray(32);
			if (AbilityConfigKeys[i] == INVALID_HANDLE || !b_FirstLoad) AbilityConfigKeys[i] = CreateArray(32);
			if (AbilityConfigValues[i] == INVALID_HANDLE || !b_FirstLoad) AbilityConfigValues[i] = CreateArray(32);
			if (AbilityConfigSection[i] == INVALID_HANDLE || !b_FirstLoad) AbilityConfigSection[i] = CreateArray(32);
			if (GetAbilityKeys[i] == INVALID_HANDLE || !b_FirstLoad) GetAbilityKeys[i] = CreateArray(32);
			if (GetAbilityValues[i] == INVALID_HANDLE || !b_FirstLoad) GetAbilityValues[i] = CreateArray(32);
			if (GetAbilitySection[i] == INVALID_HANDLE || !b_FirstLoad) GetAbilitySection[i] = CreateArray(32);
			if (IsAbilityKeys[i] == INVALID_HANDLE || !b_FirstLoad) IsAbilityKeys[i] = CreateArray(32);
			if (IsAbilityValues[i] == INVALID_HANDLE || !b_FirstLoad) IsAbilityValues[i] = CreateArray(32);
			if (IsAbilitySection[i] == INVALID_HANDLE || !b_FirstLoad) IsAbilitySection[i] = CreateArray(32);
			if (CheckAbilityKeys[i] == INVALID_HANDLE || !b_FirstLoad) CheckAbilityKeys[i] = CreateArray(32);
			if (CheckAbilityValues[i] == INVALID_HANDLE || !b_FirstLoad) CheckAbilityValues[i] = CreateArray(32);
			if (CheckAbilitySection[i] == INVALID_HANDLE || !b_FirstLoad) CheckAbilitySection[i] = CreateArray(32);
			if (GetTalentStrengthKeys[i] == INVALID_HANDLE || !b_FirstLoad) GetTalentStrengthKeys[i] = CreateArray(32);
			if (GetTalentStrengthValues[i] == INVALID_HANDLE || !b_FirstLoad) GetTalentStrengthValues[i] = CreateArray(32);
			if (CastKeys[i] == INVALID_HANDLE || !b_FirstLoad) CastKeys[i] = CreateArray(32);
			if (CastValues[i] == INVALID_HANDLE || !b_FirstLoad) CastValues[i] = CreateArray(32);
			if (CastSection[i] == INVALID_HANDLE || !b_FirstLoad) CastSection[i] = CreateArray(32);
			if (ActionBar[i] == INVALID_HANDLE || !b_FirstLoad) ActionBar[i] = CreateArray(32);
			if (TalentsAssignedKeys[i] == INVALID_HANDLE || !b_FirstLoad) TalentsAssignedKeys[i] = CreateArray(32);
			if (TalentsAssignedValues[i] == INVALID_HANDLE || !b_FirstLoad) TalentsAssignedValues[i] = CreateArray(32);
			if (CartelValueKeys[i] == INVALID_HANDLE || !b_FirstLoad) CartelValueKeys[i] = CreateArray(32);
			if (CartelValueValues[i] == INVALID_HANDLE || !b_FirstLoad) CartelValueValues[i] = CreateArray(32);
			if (LegitClassSection[i] == INVALID_HANDLE || !b_FirstLoad) LegitClassSection[i] = CreateArray(32);
			if (TalentActionKeys[i] == INVALID_HANDLE || !b_FirstLoad) TalentActionKeys[i] = CreateArray(32);
			if (TalentActionValues[i] == INVALID_HANDLE || !b_FirstLoad) TalentActionValues[i] = CreateArray(32);
			if (TalentActionSection[i] == INVALID_HANDLE || !b_FirstLoad) TalentActionSection[i] = CreateArray(32);
			if (TalentExperienceKeys[i] == INVALID_HANDLE || !b_FirstLoad) TalentExperienceKeys[i] = CreateArray(32);
			if (TalentExperienceValues[i] == INVALID_HANDLE || !b_FirstLoad) TalentExperienceValues[i] = CreateArray(32);
			if (TalentTreeKeys[i] == INVALID_HANDLE || !b_FirstLoad) TalentTreeKeys[i] = CreateArray(32);
			if (TalentTreeValues[i] == INVALID_HANDLE || !b_FirstLoad) TalentTreeValues[i] = CreateArray(32);
			if (TheLeaderboards[i] == INVALID_HANDLE || !b_FirstLoad) TheLeaderboards[i] = CreateArray(32);
			if (TheLeaderboardsData[i] == INVALID_HANDLE || !b_FirstLoad) TheLeaderboardsData[i] = CreateArray(32);
			if (TankState_Array[i] == INVALID_HANDLE || !b_FirstLoad) TankState_Array[i] = CreateArray(32);
			if (PlayerInventory[i] == INVALID_HANDLE || !b_FirstLoad) PlayerInventory[i] = CreateArray(32);
			if (PlayerEquipped[i] == INVALID_HANDLE || !b_FirstLoad) PlayerEquipped[i] = CreateArray(32);
			if (MenuStructure[i] == INVALID_HANDLE || !b_FirstLoad) MenuStructure[i] = CreateArray(32);
			if (TempAttributes[i] == INVALID_HANDLE || !b_FirstLoad) TempAttributes[i] = CreateArray(32);
			if (TempTalents[i] == INVALID_HANDLE || !b_FirstLoad) TempTalents[i] = CreateArray(32);
			if (PlayerProfiles[i] == INVALID_HANDLE || !b_FirstLoad) PlayerProfiles[i] = CreateArray(32);
			if (SpecialAmmoEffectKeys[i] == INVALID_HANDLE || !b_FirstLoad) SpecialAmmoEffectKeys[i] = CreateArray(32);
			if (SpecialAmmoEffectValues[i] == INVALID_HANDLE || !b_FirstLoad) SpecialAmmoEffectValues[i] = CreateArray(32);
			if (ActiveAmmoCooldownKeys[i] == INVALID_HANDLE || !b_FirstLoad) ActiveAmmoCooldownKeys[i] = CreateArray(32);
			if (ActiveAmmoCooldownValues[i] == INVALID_HANDLE || !b_FirstLoad) ActiveAmmoCooldownValues[i] = CreateArray(32);
			if (PlayActiveAbilities[i] == INVALID_HANDLE || !b_FirstLoad) PlayActiveAbilities[i] = CreateArray(32);
			if (PlayerActiveAmmo[i] == INVALID_HANDLE || !b_FirstLoad) PlayerActiveAmmo[i] = CreateArray(32);
			if (SpecialAmmoKeys[i] == INVALID_HANDLE || !b_FirstLoad) SpecialAmmoKeys[i] = CreateArray(32);
			if (SpecialAmmoValues[i] == INVALID_HANDLE || !b_FirstLoad) SpecialAmmoValues[i] = CreateArray(32);
			if (SpecialAmmoSection[i] == INVALID_HANDLE || !b_FirstLoad) SpecialAmmoSection[i] = CreateArray(32);
			if (DrawSpecialAmmoKeys[i] == INVALID_HANDLE || !b_FirstLoad) DrawSpecialAmmoKeys[i] = CreateArray(32);
			if (DrawSpecialAmmoValues[i] == INVALID_HANDLE || !b_FirstLoad) DrawSpecialAmmoValues[i] = CreateArray(32);
			if (SpecialAmmoStrengthKeys[i] == INVALID_HANDLE || !b_FirstLoad) SpecialAmmoStrengthKeys[i] = CreateArray(32);
			if (SpecialAmmoStrengthValues[i] == INVALID_HANDLE || !b_FirstLoad) SpecialAmmoStrengthValues[i] = CreateArray(32);
			if (WeaponLevel[i] == INVALID_HANDLE || !b_FirstLoad) WeaponLevel[i] = CreateArray(32);
			if (ExperienceBank[i] == INVALID_HANDLE || !b_FirstLoad) ExperienceBank[i] = CreateArray(32);
			if (MenuPosition[i] == INVALID_HANDLE || !b_FirstLoad) MenuPosition[i] = CreateArray(32);
			if (IsClientInRangeSAKeys[i] == INVALID_HANDLE || !b_FirstLoad) IsClientInRangeSAKeys[i] = CreateArray(32);
			if (IsClientInRangeSAValues[i] == INVALID_HANDLE || !b_FirstLoad) IsClientInRangeSAValues[i] = CreateArray(32);
			if (InfectedAuraKeys[i] == INVALID_HANDLE || !b_FirstLoad) InfectedAuraKeys[i] = CreateArray(32);
			if (InfectedAuraValues[i] == INVALID_HANDLE || !b_FirstLoad) InfectedAuraValues[i] = CreateArray(32);
			if (InfectedAuraSection[i] == INVALID_HANDLE || !b_FirstLoad) InfectedAuraSection[i] = CreateArray(32);
			if (TalentUpgradeKeys[i] == INVALID_HANDLE || !b_FirstLoad) TalentUpgradeKeys[i] = CreateArray(32);
			if (TalentUpgradeValues[i] == INVALID_HANDLE || !b_FirstLoad) TalentUpgradeValues[i] = CreateArray(32);
			if (TalentUpgradeSection[i] == INVALID_HANDLE || !b_FirstLoad) TalentUpgradeSection[i] = CreateArray(32);
			if (InfectedHealth[i] == INVALID_HANDLE || 	!b_FirstLoad) InfectedHealth[i] = CreateArray(32);
			if (WitchDamage[i] == INVALID_HANDLE || !b_FirstLoad) WitchDamage[i]	= CreateArray(32);
			if (SpecialCommon[i] == INVALID_HANDLE || !b_FirstLoad) SpecialCommon[i] = CreateArray(32);
			if (MenuKeys[i] == INVALID_HANDLE || !b_FirstLoad) MenuKeys[i]								= CreateArray(32);
			if (MenuValues[i] == INVALID_HANDLE || !b_FirstLoad) MenuValues[i]							= CreateArray(32);
			if (MenuSection[i] == INVALID_HANDLE || !b_FirstLoad) MenuSection[i]							= CreateArray(32);
			if (TriggerKeys[i] == INVALID_HANDLE || !b_FirstLoad) TriggerKeys[i]							= CreateArray(32);
			if (TriggerValues[i] == INVALID_HANDLE || !b_FirstLoad) TriggerValues[i]						= CreateArray(32);
			if (TriggerSection[i] == INVALID_HANDLE || !b_FirstLoad) TriggerSection[i]						= CreateArray(32);
			if (AbilityKeys[i] == INVALID_HANDLE || !b_FirstLoad) AbilityKeys[i]							= CreateArray(32);
			if (AbilityValues[i] == INVALID_HANDLE || !b_FirstLoad) AbilityValues[i]						= CreateArray(32);
			if (AbilitySection[i] == INVALID_HANDLE || !b_FirstLoad) AbilitySection[i]						= CreateArray(32);
			if (ChanceKeys[i] == INVALID_HANDLE || !b_FirstLoad) ChanceKeys[i]							= CreateArray(32);
			if (ChanceValues[i] == INVALID_HANDLE || !b_FirstLoad) ChanceValues[i]							= CreateArray(32);
			if (PurchaseKeys[i] == INVALID_HANDLE || !b_FirstLoad) PurchaseKeys[i]						= CreateArray(32);
			if (PurchaseValues[i] == INVALID_HANDLE || !b_FirstLoad) PurchaseValues[i]						= CreateArray(32);
			if (ChanceSection[i] == INVALID_HANDLE || !b_FirstLoad) ChanceSection[i]						= CreateArray(32);
			if (a_Database_PlayerTalents[i] == INVALID_HANDLE || !b_FirstLoad) a_Database_PlayerTalents[i]				= CreateArray(32);
			if (a_Database_PlayerTalents_Experience[i] == INVALID_HANDLE || !b_FirstLoad) a_Database_PlayerTalents_Experience[i] = CreateArray(32);
			if (PlayerAbilitiesCooldown[i] == INVALID_HANDLE || !b_FirstLoad) PlayerAbilitiesCooldown[i]				= CreateArray(32);
			if (acdrKeys[i] == INVALID_HANDLE || !b_FirstLoad) acdrKeys[i] = CreateArray(32);
			if (acdrValues[i] == INVALID_HANDLE || !b_FirstLoad) acdrValues[i] = CreateArray(32);
			if (acdrSection[i] == INVALID_HANDLE || !b_FirstLoad) acdrSection[i] = CreateArray(32);
			if (GetLayerStrengthKeys[i] == INVALID_HANDLE || !b_FirstLoad) GetLayerStrengthKeys[i] = CreateArray(32);
			if (GetLayerStrengthValues[i] == INVALID_HANDLE || !b_FirstLoad) GetLayerStrengthValues[i] = CreateArray(32);
			if (GetLayerStrengthSection[i] == INVALID_HANDLE || !b_FirstLoad) GetLayerStrengthSection[i] = CreateArray(32);
			/*if (PlayerAbilitiesImmune[i][i] == INVALID_HANDLE || !b_FirstLoad) {	//[i][i] will NEVER be occupied.
				for (new y = 0; y <= MAXPLAYERS; y++) PlayerAbilitiesImmune[i][y]				= CreateArray(32);
			}*/
			if (a_Store_Player[i] == INVALID_HANDLE || !b_FirstLoad) a_Store_Player[i]						= CreateArray(32);
			if (StoreKeys[i] == INVALID_HANDLE || !b_FirstLoad) StoreKeys[i]							= CreateArray(32);
			if (StoreValues[i] == INVALID_HANDLE || !b_FirstLoad) StoreValues[i]							= CreateArray(32);
			if (StoreMultiplierKeys[i] == INVALID_HANDLE || !b_FirstLoad) StoreMultiplierKeys[i]					= CreateArray(32);
			if (StoreMultiplierValues[i] == INVALID_HANDLE || !b_FirstLoad) StoreMultiplierValues[i]				= CreateArray(32);
			if (StoreTimeKeys[i] == INVALID_HANDLE || !b_FirstLoad) StoreTimeKeys[i]						= CreateArray(32);
			if (StoreTimeValues[i] == INVALID_HANDLE || !b_FirstLoad) StoreTimeValues[i]						= CreateArray(32);
			if (LoadStoreSection[i] == INVALID_HANDLE || !b_FirstLoad) LoadStoreSection[i]						= CreateArray(32);
			if (SaveSection[i] == INVALID_HANDLE || !b_FirstLoad) SaveSection[i]							= CreateArray(32);
			if (StoreChanceKeys[i] == INVALID_HANDLE || !b_FirstLoad) StoreChanceKeys[i]						= CreateArray(32);
			if (StoreChanceValues[i] == INVALID_HANDLE || !b_FirstLoad) StoreChanceValues[i]					= CreateArray(32);
			if (StoreItemNameSection[i] == INVALID_HANDLE || !b_FirstLoad) StoreItemNameSection[i]					= CreateArray(32);
			if (StoreItemSection[i] == INVALID_HANDLE || !b_FirstLoad) StoreItemSection[i]						= CreateArray(32);
			if (TrailsKeys[i] == INVALID_HANDLE || !b_FirstLoad) TrailsKeys[i]							= CreateArray(32);
			if (TrailsValues[i] == INVALID_HANDLE || !b_FirstLoad) TrailsValues[i]							= CreateArray(32);
			if (DamageKeys[i] == INVALID_HANDLE || !b_FirstLoad) DamageKeys[i]						= CreateArray(32);
			if (DamageValues[i] == INVALID_HANDLE || !b_FirstLoad) DamageValues[i]					= CreateArray(32);
			if (DamageSection[i] == INVALID_HANDLE || !b_FirstLoad) DamageSection[i]				= CreateArray(32);
			if (MOTKeys[i] == INVALID_HANDLE || !b_FirstLoad) MOTKeys[i] = CreateArray(32);
			if (MOTValues[i] == INVALID_HANDLE || !b_FirstLoad) MOTValues[i] = CreateArray(32);
			if (MOTSection[i] == INVALID_HANDLE || !b_FirstLoad) MOTSection[i] = CreateArray(32);
			if (BoosterKeys[i] == INVALID_HANDLE || !b_FirstLoad) BoosterKeys[i]							= CreateArray(32);
			if (BoosterValues[i] == INVALID_HANDLE || !b_FirstLoad) BoosterValues[i]						= CreateArray(32);
			if (RPGMenuPosition[i] == INVALID_HANDLE || !b_FirstLoad) RPGMenuPosition[i]						= CreateArray(32);
			if (ChatSettings[i] == INVALID_HANDLE || !b_FirstLoad) ChatSettings[i]						= CreateArray(32);
			if (h_KilledPosition_X[i] == INVALID_HANDLE || !b_FirstLoad) h_KilledPosition_X[i]				= CreateArray(32);
			if (h_KilledPosition_Y[i] == INVALID_HANDLE || !b_FirstLoad) h_KilledPosition_Y[i]				= CreateArray(32);
			if (h_KilledPosition_Z[i] == INVALID_HANDLE || !b_FirstLoad) h_KilledPosition_Z[i]				= CreateArray(32);
			if (MeleeKeys[i] == INVALID_HANDLE || !b_FirstLoad) MeleeKeys[i]						= CreateArray(32);
			if (MeleeValues[i] == INVALID_HANDLE || !b_FirstLoad) MeleeValues[i]					= CreateArray(32);
			if (MeleeSection[i] == INVALID_HANDLE || !b_FirstLoad) MeleeSection[i]					= CreateArray(32);
			if (CommonAffixesCooldown[i] == INVALID_HANDLE || !b_FirstLoad) CommonAffixesCooldown[i] = CreateArray(32);
			if (RCAffixes[i] == INVALID_HANDLE || !b_FirstLoad) RCAffixes[i] = CreateArray(32);
			if (AKKeys[i] == INVALID_HANDLE || !b_FirstLoad) AKKeys[i]						= CreateArray(32);
			if (AKValues[i] == INVALID_HANDLE || !b_FirstLoad) AKValues[i]					= CreateArray(32);
			if (AKSection[i] == INVALID_HANDLE || !b_FirstLoad) AKSection[i]					= CreateArray(32);
			if (SurvivorsIgnored[i] == INVALID_HANDLE || !b_FirstLoad) SurvivorsIgnored[i] = CreateArray(32);
			if (MyGroup[i] == INVALID_HANDLE || !b_FirstLoad) MyGroup[i] = CreateArray(32);
			if (PlayerEffectOverTime[i] == INVALID_HANDLE || !b_FirstLoad) PlayerEffectOverTime[i] = CreateArray(32);
			if (CheckEffectOverTimeKeys[i] == INVALID_HANDLE || !b_FirstLoad) CheckEffectOverTimeKeys[i] = CreateArray(32);
			if (CheckEffectOverTimeValues[i] == INVALID_HANDLE || !b_FirstLoad) CheckEffectOverTimeValues[i] = CreateArray(32);
			if (FormatEffectOverTimeKeys[i] == INVALID_HANDLE || !b_FirstLoad) FormatEffectOverTimeKeys[i] = CreateArray(32);
			if (FormatEffectOverTimeValues[i] == INVALID_HANDLE || !b_FirstLoad) FormatEffectOverTimeValues[i] = CreateArray(32);
			if (FormatEffectOverTimeSection[i] == INVALID_HANDLE || !b_FirstLoad) FormatEffectOverTimeSection[i] = CreateArray(32);
			if (CooldownEffectTriggerKeys[i] == INVALID_HANDLE || !b_FirstLoad) CooldownEffectTriggerKeys[i] = CreateArray(32);
			if (CooldownEffectTriggerValues[i] == INVALID_HANDLE || !b_FirstLoad) CooldownEffectTriggerValues[i] = CreateArray(32);
			if (IsSpellAnAuraKeys[i] == INVALID_HANDLE || !b_FirstLoad) IsSpellAnAuraKeys[i] = CreateArray(32);
			if (IsSpellAnAuraValues[i] == INVALID_HANDLE || !b_FirstLoad) IsSpellAnAuraValues[i] = CreateArray(32);
			if (CallAbilityCooldownTriggerKeys[i] == INVALID_HANDLE || !b_FirstLoad) CallAbilityCooldownTriggerKeys[i] = CreateArray(32);
			if (CallAbilityCooldownTriggerValues[i] == INVALID_HANDLE || !b_FirstLoad) CallAbilityCooldownTriggerValues[i] = CreateArray(32);
			if (CallAbilityCooldownTriggerSection[i] == INVALID_HANDLE || !b_FirstLoad) CallAbilityCooldownTriggerSection[i] = CreateArray(32);
			if (GetIfTriggerRequirementsMetKeys[i] == INVALID_HANDLE || !b_FirstLoad) GetIfTriggerRequirementsMetKeys[i] = CreateArray(32);
			if (GetIfTriggerRequirementsMetValues[i] == INVALID_HANDLE || !b_FirstLoad) GetIfTriggerRequirementsMetValues[i] = CreateArray(32);
			if (GetIfTriggerRequirementsMetSection[i] == INVALID_HANDLE || !b_FirstLoad) GetIfTriggerRequirementsMetSection[i] = CreateArray(32);
			if (GAMKeys[i] == INVALID_HANDLE || !b_FirstLoad) GAMKeys[i] = CreateArray(32);
			if (GAMValues[i] == INVALID_HANDLE || !b_FirstLoad) GAMValues[i] = CreateArray(32);
			if (GAMSection[i] == INVALID_HANDLE || !b_FirstLoad) GAMSection[i] = CreateArray(32);
			if (GetGoverningAttributeKeys[i] == INVALID_HANDLE || !b_FirstLoad) GetGoverningAttributeKeys[i] = CreateArray(32);
			if (GetGoverningAttributeValues[i] == INVALID_HANDLE || !b_FirstLoad) GetGoverningAttributeValues[i] = CreateArray(32);
			if (GetGoverningAttributeSection[i] == INVALID_HANDLE || !b_FirstLoad) GetGoverningAttributeSection[i] = CreateArray(32);
			if (WeaponResultKeys[i] == INVALID_HANDLE || !b_FirstLoad) WeaponResultKeys[i] = CreateArray(32);
			if (WeaponResultValues[i] == INVALID_HANDLE || !b_FirstLoad) WeaponResultValues[i] = CreateArray(32);
			if (WeaponResultSection[i] == INVALID_HANDLE || !b_FirstLoad) WeaponResultSection[i] = CreateArray(32);
			if (GetAbilityCooldownKeys[i] == INVALID_HANDLE || !b_FirstLoad) GetAbilityCooldownKeys[i] = CreateArray(32);
			if (GetAbilityCooldownValues[i] == INVALID_HANDLE || !b_FirstLoad) GetAbilityCooldownValues[i] = CreateArray(32);
			if (GetAbilityCooldownSection[i] == INVALID_HANDLE || !b_FirstLoad) GetAbilityCooldownSection[i] = CreateArray(32);
			if (GetTalentValueSearchKeys[i] == INVALID_HANDLE || !b_FirstLoad) GetTalentValueSearchKeys[i] = CreateArray(32);
			if (GetTalentValueSearchValues[i] == INVALID_HANDLE || !b_FirstLoad) GetTalentValueSearchValues[i] = CreateArray(32);
			if (GetTalentValueSearchSection[i] == INVALID_HANDLE || !b_FirstLoad) GetTalentValueSearchSection[i] = CreateArray(32);
			if (GetTalentKeyValueKeys[i] == INVALID_HANDLE || !b_FirstLoad) GetTalentKeyValueKeys[i] = CreateArray(32);
			if (GetTalentKeyValueValues[i] == INVALID_HANDLE || !b_FirstLoad) GetTalentKeyValueValues[i] = CreateArray(32);
			if (GetTalentKeyValueSection[i] == INVALID_HANDLE || !b_FirstLoad) GetTalentKeyValueSection[i] = CreateArray(32);
			if (ApplyDebuffCooldowns[i] == INVALID_HANDLE || !b_FirstLoad) ApplyDebuffCooldowns[i] = CreateArray(32);
		}

		if (!b_FirstLoad) b_FirstLoad = true;
		//LogMessage("AWAITING PARAMETERS");

		if (!b_ConfigsExecuted) {
			b_ConfigsExecuted = true;
			if (hExecuteConfig == INVALID_HANDLE) hExecuteConfig = CreateTimer(1.0, Timer_ExecuteConfig, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
			CreateTimer(10.0, Timer_GetCampaignName, _, TIMER_FLAG_NO_MAPCHANGE);
		}
	}
	ReadyUp_NtvIsCampaignFinale();
}

public ReadyUp_GetCampaignStatus(mapposition) {
	CurrentMapPosition = mapposition;
}

public OnMapStart() {
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

	GetCurrentMap(TheCurrentMap, sizeof(TheCurrentMap));
	Format(CONFIG_MAIN, sizeof(CONFIG_MAIN), "%srpg/%s.cfg", ConfigPathDirectory, TheCurrentMap);
	//LogMessage("CONFIG_MAIN DEFAULT: %s", CONFIG_MAIN);
	if (!FileExists(CONFIG_MAIN)) Format(CONFIG_MAIN, sizeof(CONFIG_MAIN), "rpg/config.cfg");
	else Format(CONFIG_MAIN, sizeof(CONFIG_MAIN), "rpg/%s.cfg", TheCurrentMap);

	SetConVarInt(FindConVar("director_no_death_check"), 1);
	SetConVarInt(FindConVar("sv_rescue_disabled"), 0);
	SetConVarInt(FindConVar("z_common_limit"), 0);	// there are no commons until the round starts in all game modes to give players a chance to move.

	CheckDifficulty();
	UnhookAll();
}

stock ResetValues(client) {

	// Yep, gotta do this *properly*
	b_HasDeathLocation[client] = false;
}

public OnMapEnd() {

	if (b_IsActiveRound) b_IsActiveRound = false;
	for (new i = 1; i <= MaxClients; i++) {

		if (ISEXPLODE[i] != INVALID_HANDLE) {

			KillTimer(ISEXPLODE[i]);
			ISEXPLODE[i] = INVALID_HANDLE;
		}
	}

	ClearArray(Handle:NewUsersRound);
}

public Action:Timer_GetCampaignName(Handle:timer) {

	ReadyUp_NtvGetCampaignName();
	return Plugin_Stop;
}

public OnConfigsExecuted() {
	if (!b_ConfigsExecuted) {
		b_ConfigsExecuted = true;
		if (hExecuteConfig == INVALID_HANDLE) {
			hExecuteConfig = CreateTimer(1.0, Timer_ExecuteConfig, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
		}
		CreateTimer(10.0, Timer_GetCampaignName, _, TIMER_FLAG_NO_MAPCHANGE);
	}
}

stock CheckGamemode() {
	decl String:TheGamemode[64];
	GetConVarString(g_Gamemode, TheGamemode, sizeof(TheGamemode));
	decl String:TheRequiredGamemode[64];
	GetConfigValue(TheRequiredGamemode, sizeof(TheRequiredGamemode), "gametype?");
	if (!StrEqual(TheGamemode, TheRequiredGamemode, false)) {
		LogMessage("Gamemode did not match, changing to %s", TheRequiredGamemode);
		PrintToChatAll("Gamemode did not match, changing to %s", TheRequiredGamemode);
		SetConVarString(g_Gamemode, TheRequiredGamemode);
		decl String:TheMapname[64];
		GetCurrentMap(TheMapname, sizeof(TheMapname));
		ServerCommand("changelevel %s", TheMapname);
	}
}

public Action:Timer_ExecuteConfig(Handle:timer) {
	if (ReadyUp_NtvConfigProcessing() == 0) {
		// These are processed one-by-one in a defined-by-dependencies order, but you can place them here in any order you want.
		// I've placed them here in the order they load for uniformality.
		ReadyUp_ParseConfig(CONFIG_MAIN);
		ReadyUp_ParseConfig(CONFIG_EVENTS);
		ReadyUp_ParseConfig(CONFIG_MENUTALENTS);
		ReadyUp_ParseConfig(CONFIG_POINTS);
		ReadyUp_ParseConfig(CONFIG_STORE);
		ReadyUp_ParseConfig(CONFIG_TRAILS);
		ReadyUp_ParseConfig(CONFIG_CHATSETTINGS);
		ReadyUp_ParseConfig(CONFIG_MAINMENU);
		ReadyUp_ParseConfig(CONFIG_WEAPONS);
		ReadyUp_ParseConfig(CONFIG_PETS);
		ReadyUp_ParseConfig(CONFIG_COMMONAFFIXES);

		hExecuteConfig = INVALID_HANDLE;
		return Plugin_Stop;
	}
	return Plugin_Continue;
}

public Action:Timer_AutoRes(Handle:timer) {
	if (b_IsCheckpointDoorStartOpened) return Plugin_Stop;
	for (new i = 1; i <= MaxClients; i++) {

		if (IsLegitimateClient(i) && GetClientTeam(i) == TEAM_SURVIVOR) {

			if (!IsPlayerAlive(i)) SDKCall(hRoundRespawn, i);
			else if (IsIncapacitated(i)) ExecCheatCommand(i, "give", "health");
		}
	}
	return Plugin_Continue;
}

stock bool:AnyHumans() {
	for (new i = 1; i <= MaxClients; i++) {
		if (IsLegitimateClient(i) && !IsFakeClient(i)) return true;
	}
	return false;
}

public ReadyUp_ReadyUpStart() {
	CheckDifficulty();
	CheckGamemode();
	RoundTime = 0;
	b_IsRoundIsOver = true;
	iTopThreat = 0;
	//SetSurvivorsAliveHostname();
	CreateTimer(1.0, Timer_AutoRes, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
	/*
	When a new round starts, we want to forget who was the last person to speak on different teams.
	*/
	Format(Public_LastChatUser, sizeof(Public_LastChatUser), "none");
	Format(Spectator_LastChatUser, sizeof(Spectator_LastChatUser), "none");
	Format(Survivor_LastChatUser, sizeof(Survivor_LastChatUser), "none");
	Format(Infected_LastChatUser, sizeof(Infected_LastChatUser), "none");
	new bool:TeleportPlayers = false;
	new Float:teleportIntoSaferoom[3];

	if (StrEqual(TheCurrentMap, "zerowarn_1r", false)) {
		teleportIntoSaferoom[0] = 4087.998291;
		teleportIntoSaferoom[1] = 11974.557617;
		teleportIntoSaferoom[2] = -300.968750;
		TeleportPlayers = true;
	}

	for (new i = 1; i <= MaxClients; i++) {

		if (IsClientInGame(i)) {
			if (GetClientTeam(i) == TEAM_SURVIVOR) GiveProfileItems(i);
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

public Action:Timer_Defibrillator(Handle:timer, any:client) {

	if (IsLegitimateClient(client) && !IsPlayerAlive(client)) Defibrillator(0, client);
	return Plugin_Stop;
}

public ReadyUpEnd_Complete() {
	/*PrintToChatAll("DOor opened");
	b_IsCheckpointDoorStartOpened = true;
	b_IsActiveRound = true;*/
	if (b_IsRoundIsOver) {

		CheckDifficulty();
		b_IsMissionFailed = false;
		//if (ReadyUp_GetGameMode() == 3) {
		b_IsRoundIsOver = false;
		ClearArray(CommonInfected);
		ClearArray(CommonInfectedHealth);
			//b_IsSurvivalIntermission = true;
			//CreateTimer(5.0, Timer_AutoRes, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
		//}
		//RoundTime					=	GetTime();
		b_IsCheckpointDoorStartOpened = false;
		for (new i = 1; i <= MaxClients; i++) {
			if (IsLegitimateClient(i) && IsFakeClient(i) && !b_IsLoaded[i]) IsClientLoadedEx(i);
		}

		if (iRoundStartWeakness == 1) {

			for (new i = 1; i <= MaxClients; i++) {

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
					//}
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

stock TimeUntilEnrage(String:TheText[], TheSize) {

	if (!IsEnrageActive()) {

		new Seconds = (iEnrageTime * 60) - (GetTime() - RoundTime);
		new Minutes = 0;
		while (Seconds >= 60) {

			Seconds -= 60;
			Minutes++;
		}
		Format(TheText, TheSize, "%dm%ds", Minutes, Seconds);
	}
	else Format(TheText, TheSize, "ACTIVE");
}

stock RPGRoundTime(bool:IsSeconds = false) {

	new Seconds = GetTime() - RoundTime;
	if (IsSeconds) return Seconds;
	new Minutes = 0;
	while (Seconds >= 60) {

		Minutes++;
		Seconds -= 60;
	}
	return Minutes;
}

stock bool:IsEnrageActive() {

	if (!b_IsActiveRound || IsSurvivalMode || iEnrageTime < 1) return false;
	if (RPGRoundTime() < iEnrageTime) return false;
	if (!IsEnrageNotified && iNotifyEnrage == 1) {
		IsEnrageNotified = true;
		PrintToChatAll("%t", "enrage period", orange, blue, orange);
	}

	return true;
}

stock bool:PlayerHasWeakness(client) {

	if (!IsLegitimateClientAlive(client)) return false;
	if (IsSpecialCommonInRange(client, 'w')) return true;
	if (!b_IsCheckpointDoorStartOpened || DoomTimer != 0) return true;
	if (IsClientInRangeSpecialAmmo(client, "W", true) == -2.0) return true;	// the player is not weak if inside cleansing ammo.*
	if (GetTalentStrengthByKeyValue(client, "activator ability effects?", "weakness") > 0) return true;
	if (LastDeathTime[client] > GetEngineTime()) return true;
	return false;
}

public ReadyUp_CheckpointDoorStartOpened() {
	if (!b_IsCheckpointDoorStartOpened) {
		b_IsCheckpointDoorStartOpened		= true;
		b_RescueIsHere = false;
		b_IsActiveRound = true;
		bIsSettingsCheck = true;
		IsEnrageNotified = false;
		b_IsFinaleTanks = false;
		for (new i = 1; i <= MaxClients; i++) {
			if (IsLegitimateClient(i) && IsFakeClient(i) && GetClientTeam(i) == TEAM_INFECTED) ForcePlayerSuicide(i);
		}
		ClearArray(Handle:persistentCirculation);
		ClearArray(Handle:CoveredInVomit);
		ClearArray(RoundStatistics);
		ResizeArray(RoundStatistics, 5);
		for (new i = 0; i < 5; i++) {

			SetArrayCell(Handle:RoundStatistics, i, 0);
			if (CurrentMapPosition == 0) SetArrayCell(Handle:RoundStatistics, i, 0, 1);	// first map of campaign, reset the total.
		}

		//DestroyCommons();
		decl String:pct[4];
		Format(pct, sizeof(pct), "%");
		new iMaxHandicap = 0;
		new iMinHandicap = RatingPerLevel;
		decl String:text[64];
		new survivorCounter = TotalHumanSurvivors();
		new bool:AnyBotsOnSurvivorTeam = BotsOnSurvivorTeam();

		for (new i = 1; i <= MaxClients; i++) {

			if (IsLegitimateClient(i)) {

				//ChangeHook(i, true);
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
				}
				else SetBotHandicap(i);
			}
		}

		if (CurrentMapPosition != 0 || ReadyUpGameMode == 3) CheckDifficulty();

		RoundTime					=	GetTime();

		new ent = -1;
		if (ReadyUpGameMode != 3) {

			while ((ent = FindEntityByClassname(ent, "witch")) != -1) {

				// Some maps, like Hard Rain pre-spawn a ton of witches - we want to add them to the witch table.
				OnWitchCreated(ent);
			}
		}
		else {

			IsSurvivalMode = true;

			for (new i = 1; i <= MaxClients; i++) {

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
		RoundDamageTotal			=	0;
		//MVPDamage					=	0;
		b_IsFinaleActive			=	false;

		if (GetConfigValueInt("director save priority?") == 1) PrintToChatAll("%t", "Director Priority Save Enabled", white, green);
		decl String:thetext[64];
		GetConfigValue(thetext, sizeof(thetext), "path setting?");

		if (ReadyUpGameMode != 3 && !StrEqual(thetext, "none")) {

			if (!StrEqual(thetext, "random")) ServerCommand("sm_forcepath %s", thetext);
			else {

				if (StrEqual(PathSetting, "none")) {

					new random = GetRandomInt(1, 100);
					if (random <= 33) Format(PathSetting, sizeof(PathSetting), "easy");
					else if (random <= 66) Format(PathSetting, sizeof(PathSetting), "medium");
					else Format(PathSetting, sizeof(PathSetting), "hard");
				}
				ServerCommand("sm_forcepath %s", PathSetting);
			}
		}

		//new RatingLevelMultiplier = GetConfigValueInt("rating level multiplier?");
		for (new i = 1; i <= MaxClients; i++) {
			if (IsLegitimateClient(i) && GetClientTeam(i) == TEAM_SURVIVOR) {
				if (!IsPlayerAlive(i)) SDKCall(hRoundRespawn, i);
				VerifyMinimumRating(i);
				HealImmunity[i] = false;
				//DefaultHealth[i] = StringToInt(GetConfigValue("survivor health?"));
				//PlayerSpawnAbilityTrigger(i);
				//RefreshSurvivor(i);
				//SetClientMovementSpeed(i);
				//ResetCoveredInBile(i);
				//BlindPlayer(i);
				//GiveMaximumHealth(i);

				if (b_IsLoaded[i]) GiveMaximumHealth(i);
				else if (!b_IsLoading[i]) OnClientLoaded(i);
			}
		}
		f_TankCooldown				=	-1.0;
		ResetCDImmunity(-1);
		DoomTimer = 0;
		if (ReadyUpGameMode != 2) {
			// It destroys itself when a round ends.
			CreateTimer(1.0, Timer_DirectorPurchaseTimer, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
		}
		if (!bIsSoloHandicap && RespawnQueue > 0) CreateTimer(1.0, Timer_RespawnQueue, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
		RaidInfectedBotLimit();
		CreateTimer(1.0, Timer_StartPlayerTimers, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);

		//CreateTimer(1.0, Timer_ShowHUD, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
		//CreateTimer(1.0, Timer_DisplayHUD, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
		//CreateTimer(1.0, Timer_AwardSkyPoints, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
		CreateTimer(1.0, Timer_CheckIfHooked, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
		CreateTimer(GetConfigValueFloat("settings check interval?"), Timer_SettingsCheck, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
		//CreateTimer(fSpecialAmmoInterval, Timer_AmmoActiveTimer, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
		//CreateTimer(fEffectOverTimeInterval, Timer_EffectOverTime, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
		if (DoomSUrvivorsRequired != 0) CreateTimer(1.0, Timer_Doom, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
		//CreateTimer(fSpecialAmmoInterval, Timer_SpecialAmmoData, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
		//CreateTimer(1.0, Timer_PlayTime, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
		CreateTimer(0.5, Timer_EntityOnFire, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);		// Fire status effect
		CreateTimer(1.0, Timer_ThreatSystem, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);		// threat system modulator
		//CreateTimer(0.1, Timer_IsSpecialCommonInRange, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);	// some special commons react based on range, not damage.
		CreateTimer(fStaggerTickrate, Timer_StaggerTimer, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
		if (GetConfigValueInt("common affixes?") > 0) {
			ClearArray(Handle:CommonAffixes);
			CreateTimer(0.5, Timer_CommonAffixes, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
		}

		ClearRelevantData();
		LastLivingSurvivor = 1;
		new size = GetArraySize(a_DirectorActions);
		ResizeArray(a_DirectorActions_Cooldown, size);
		for (new i = 0; i < size; i++) SetArrayString(a_DirectorActions_Cooldown, i, "0");
		//if (CommonInfectedQueue == INVALID_HANDLE) CommonInfectedQueue = CreateArray(32);
		//ClearArray(CommonInfectedQueue);
		new theCount = LivingSurvivorCount();
		if (theCount >= iSurvivorModifierRequired) {
			PrintToChatAll("%t", "teammate bonus experience", blue, green, ((theCount - (iSurvivorModifierRequired - 1)) * fSurvivorExpMult) * 100.0, pct);
		}
		RefreshSurvivorBots();
		if (iEnrageTime > 0) {
			TimeUntilEnrage(text, sizeof(text));
			PrintToChatAll("%t", "time until things get bad", orange, green, text, orange);
		}
	}
}

stock RefreshSurvivorBots() {

	for (new i = 1; i <= MaxClients; i++) {

		if (IsSurvivorBot(i)) {

			//if (!IsPlayerAlive(i)) SDKCall(hRoundRespawn, i);
			RefreshSurvivor(i);
		}
	}
}

stock SetClientMovementSpeed(client) {
	if (IsValidEntity(client)) SetEntPropFloat(client, Prop_Send, "m_flLaggedMovementValue", fBaseMovementSpeed);
}

stock ResetCoveredInBile(client) {

	for (new i = 1; i <= MaxClients; i++) {

		if (IsLegitimateClient(i)) {

			CoveredInBile[client][i] = -1;
			CoveredInBile[i][client] = -1;
		}
	}
}

stock FindTargetClient(client, String:arg[]) {

	decl String:target_name[MAX_TARGET_LENGTH];
	decl target_list[MAXPLAYERS], target_count, bool:tn_is_ml;
	new targetclient;
	if ((target_count = ProcessTargetString(
		arg,
		client,
		target_list,
		MAXPLAYERS,
		COMMAND_FILTER_CONNECTED,
		target_name,
		sizeof(target_name),
		tn_is_ml)) > 0)
	{
		for (new i = 0; i < target_count; i++) targetclient = target_list[i];
	}
	return targetclient;
}

stock CMD_CastAction(client, args) {
	decl String:actionpos[64];
	GetCmdArg(1, actionpos, sizeof(actionpos));
	if (StrContains(actionpos, "action", false) != -1) {

		CastActionEx(client, actionpos, sizeof(actionpos));
	}
}

stock CastActionEx(client, String:t_actionpos[] = "none", TheSize, pos = -1) {

	new ActionSlots = iActionBarSlots;
	decl String:actionpos[64];


	if (pos == -1) pos = StringToInt(t_actionpos[strlen(t_actionpos) - 1]) - 1;//StringToInt(actionpos[strlen(actionpos) - 1]);
	if (pos >= 0 && pos < ActionSlots) {
		//pos--;	// shift down 1 for the array.
		GetArrayString(Handle:ActionBar[client], pos, actionpos, sizeof(actionpos));
		if (IsTalentExists(actionpos)) { //PrintToChat(client, "%T", "Action Slot Empty", client, white, orange, blue, pos+1);
		//else {

			new size =	GetArraySize(a_Menu_Talents);
			new RequiresTarget = 0;
			new AbilityTalent = 0;
			decl String:tTargetPos[3][64];
			new Float:TargetPos[3];
			decl String:TalentName[64];

			for (new i = 0; i < size; i++) {

				CastKeys[client]			= GetArrayCell(a_Menu_Talents, i, 0);
				CastValues[client]			= GetArrayCell(a_Menu_Talents, i, 1);
				CastSection[client]			= GetArrayCell(a_Menu_Talents, i, 2);

				GetArrayString(Handle:CastSection[client], 0, TalentName, sizeof(TalentName));
				if (!StrEqual(TalentName, actionpos)) continue;
				AbilityTalent = GetKeyValueInt(CastKeys[client], CastValues[client], "is ability?");
				if (GetKeyValueInt(CastKeys[client], CastValues[client], "passive only?") == 1) continue;
				if (AbilityTalent != 1 && GetTalentStrength(client, actionpos) < 1) {

					// talent exists but user has no points in it from a respec or whatever so we remove it.
					// we don't tell them either, next time they use it they'll find out.

					Format(actionpos, TheSize, "none");
					SetArrayString(Handle:ActionBar[client], pos, actionpos);
				}
				else {
					RequiresTarget = GetKeyValueInt(CastKeys[client], CastValues[client], "is single target?");
					if (RequiresTarget > 0) {
						GetClientAimTargetEx(client, actionpos, TheSize, true);
						RequiresTarget = StringToInt(actionpos);
						if (IsLegitimateClientAlive(RequiresTarget)) {
							if (AbilityTalent != 1) CastSpell(client, RequiresTarget, TalentName, TargetPos);
							else {
								UseAbility(client, RequiresTarget, TalentName, CastKeys[client], CastValues[client], TargetPos);
							}
						}
					}
					else {
						GetClientAimTargetEx(client, actionpos, TheSize);
						ExplodeString(actionpos, " ", tTargetPos, 3, 64);
						TargetPos[0] = StringToFloat(tTargetPos[0]);
						TargetPos[1] = StringToFloat(tTargetPos[1]);
						TargetPos[2] = StringToFloat(tTargetPos[2]);

						if (AbilityTalent != 1) CastSpell(client, _, TalentName, TargetPos);
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

public Action:CMD_ChatTag(client, args) {

	if (IsReserve(client) && args > 0 || GetConfigValueInt("all players chat settings?") == 1) {

		decl String:arg[64];
		GetCmdArg(1, arg, sizeof(arg));
		if (strlen(arg) > GetConfigValueInt("tag name max length?")) PrintToChat(client, "%T", "Tag Name Too Long", client, GetConfigValueInt("tag name max length?"));
		else if (strlen(arg) > 1) {
		
			ReplaceString(arg, sizeof(arg), "+", " ");
			SetArrayString(ChatSettings[client], 1, arg);
			PrintToChat(client, "%T", "Tag Name Set", client, arg);
		}
		else {

			//GetArrayString(Handle:ChatSettings[client], 1, arg, sizeof(arg));
			GetClientName(client, arg, sizeof(arg));
			SetArrayString(ChatSettings[client], 1, arg);
			PrintToChat(client, "%T", "Tag Name Set", client, arg);
		}
	}
	return Plugin_Handled;
}

stock MySurvivorCompanion(client) {

	decl String:SteamId[64], String:CompanionSteamId[64];
	GetClientAuthString(client, SteamId, sizeof(SteamId));

	for (new i = 1; i <= MaxClients; i++) {

		if (IsLegitimateClient(i) && GetClientTeam(i) == TEAM_SURVIVOR && IsFakeClient(i)) {

			GetEntPropString(i, Prop_Data, "m_iName", CompanionSteamId, sizeof(CompanionSteamId));
			if (StrEqual(CompanionSteamId, SteamId, false)) return i;
		}
	}
	return -1;
}

public Action:CMD_CompanionOptions(client, args) {

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

public Action:CMD_TogglePvP(client, args) {

	new TheTime = RoundToCeil(GetEngineTime());
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

public Action:CMD_GiveLevel(client, args) {
	decl String:thetext[64];
	GetConfigValue(thetext, sizeof(thetext), "give player level flags?");
	if ((HasCommandAccess(client, thetext) || client == 0) && args > 1) {
		decl String:arg[MAX_NAME_LENGTH], String:arg2[64], String:arg3[64];
		GetCmdArg(1, arg, sizeof(arg));
		GetCmdArg(2, arg2, sizeof(arg2));
		GetCmdArg(3, arg3, sizeof(arg3));
		new targetclient = FindTargetClient(client, arg);
		if (args < 3) {
			if (IsLegitimateClient(targetclient) && PlayerLevel[targetclient] != StringToInt(arg2)) {

				SetTotalExperienceByLevel(targetclient, StringToInt(arg2));
				decl String:Name[64];
				GetClientName(targetclient, Name, sizeof(Name));
				if (client > 0) PrintToChat(client, "%T", "client level set", client, Name, green, white, blue, PlayerLevel[targetclient]);
				else PrintToServer("set %N level to %d", Name, PlayerLevel[targetclient]);
			}
		}
		else {

			if (IsLegitimateClient(targetclient)) {

				if (StrContains(arg3, "rating", false) != -1) Rating[targetclient] = StringToInt(arg2);
				else ModifyCartelValue(targetclient, arg3, StringToInt(arg2));
			}
		}
	}
	return Plugin_Handled;
}

stock GetPlayerLevel(client) {

	new iExperienceOverall = ExperienceOverall[client];
	new iLevel = 1;
	new ExperienceRequirement = CheckExperienceRequirement(client, false, iLevel);
	while (iExperienceOverall >= ExperienceRequirement && iLevel < iMaxLevel) {

		if (iIsLevelingPaused[client] == 1 && iExperienceOverall == ExperienceRequirement) break;

		iExperienceOverall -= ExperienceRequirement;
		iLevel++;
		ExperienceRequirement = CheckExperienceRequirement(client, false, iLevel);
	}

	return iLevel;
}

stock SetTotalExperienceByLevel(client, newlevel) {

	new oldlevel = PlayerLevel[client];
	ExperienceOverall[client] = 0;
	ExperienceLevel[client] = 0;
	PlayerLevel[client] = newlevel;
	for (new i = 1; i <= newlevel; i++) {

		if (newlevel == i) break;
		ExperienceOverall[client] += CheckExperienceRequirement(client, false, i);
	}

	ExperienceOverall[client]++;
	ExperienceLevel[client]++;	// i don't like 0 / level, so i always do 1 / level as the minimum.
	if (oldlevel > PlayerLevel[client]) ChallengeEverything(client);
	else if (PlayerLevel[client] > oldlevel) {
		FreeUpgrades[client] += (PlayerLevel[client] - oldlevel);
	}
}

public Action:CMD_ReloadConfigs(client, args) {

	decl String:thetext[64];
	GetConfigValue(thetext, sizeof(thetext), "reload configs flags?");

	if (HasCommandAccess(client, thetext)) {

		CreateTimer(1.0, Timer_ExecuteConfig, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
		PrintToChat(client, "Reloading Config.");
	}

	return Plugin_Handled;
}

public ReadyUp_FirstClientLoaded() {

	//CreateTimer(1.0, Timer_ShowHUD, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
	OnMapStartFunc();
	RefreshSurvivorBots();
	ReadyUpGameMode = ReadyUp_GetGameMode();
}

public Action:CMD_SharePoints(client, args) {

	if (args < 2) {

		decl String:thetext[64];
		GetConfigValue(thetext, sizeof(thetext), "reload configs flags?");

		PrintToChat(client, "%T", "Share Points Syntax", client, orange, white, thetext);
		return Plugin_Handled;
	}

	decl String:arg[MAX_NAME_LENGTH], String:arg2[10];
	GetCmdArg(1, arg, sizeof(arg));
	GetCmdArg(2, arg2, sizeof(arg2));
	new Float:SharePoints = 0.0;
	if (StrContains(arg2, ".", false) == -1) SharePoints = StringToInt(arg2) * 1.0;
	else SharePoints = StringToFloat(arg2);

	if (SharePoints > Points[client]) return Plugin_Handled;

	new targetclient = FindTargetClient(client, arg);
	if (!IsLegitimateClient(targetclient)) return Plugin_Handled;

	decl String:Name[MAX_NAME_LENGTH];
	GetClientName(targetclient, Name, sizeof(Name));
	decl String:GiftName[MAX_NAME_LENGTH];
	GetClientName(client, GiftName, sizeof(GiftName));

	Points[client] -= SharePoints;
	Points[targetclient] += SharePoints;

	PrintToChatAll("%t", "Share Points Given", blue, GiftName, white, green, SharePoints, white, blue, Name); 
	return Plugin_Handled;
}

stock GetMaxHandicap(client) {

	new iMaxHandicap = RatingPerHandicap;
	iMaxHandicap *= CartelLevel(client);
	iMaxHandicap += RatingPerLevel;

	return iMaxHandicap;
}

stock VerifyHandicap(client) {

	new iMaxHandicap = GetMaxHandicap(client);
	new iMinHandicap = RatingPerLevel;

	if (RatingHandicap[client] < iMinHandicap) RatingHandicap[client] = iMinHandicap;
	if (RatingHandicap[client] > iMaxHandicap) RatingHandicap[client] = iMaxHandicap;
}

public Action:CMD_Handicap(client, args) {

	if (iIsRatingEnabled != 1) return Plugin_Handled;

	new iMaxHandicap = GetMaxHandicap(client);
	new iMinHandicap = RatingPerLevel;
	if (RatingHandicap[client] < iMinHandicap) RatingHandicap[client] = iMinHandicap;
	if (RatingHandicap[client] > iMaxHandicap) RatingHandicap[client] = iMaxHandicap;
	if (args < 1) {

		PrintToChat(client, "%T", "handicap range", client, white, orange, iMinHandicap, white, orange, iMaxHandicap);
	}
	else {

		if (!bIsHandicapLocked[client]) {

			decl String:arg[10];
			GetCmdArg(1, arg, sizeof(arg));
			new iSetHandicap = StringToInt(arg);

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
	if (IsSurvivorBot(client)) {
		new iLowHandicap = RatingPerLevel;
		for (new i = 1; i <= MaxClients; i++) {

			if (!IsLegitimateClient(i) || GetClientTeam(i) != TEAM_SURVIVOR) continue;
			if (RatingHandicap[i] > iLowHandicap) iLowHandicap = RatingHandicap[i];
		}
		RatingHandicap[client] = iLowHandicap;
	}
	return RatingHandicap[client];
}

public Action:CMD_ActionBar(client, args) {

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

public Action:CMD_GiveStorePoints(client, args) {

	decl String:thetext[64];
	GetConfigValue(thetext, sizeof(thetext), "give store points flags?");

	if (!HasCommandAccess(client, thetext)) { PrintToChat(client, "You don't have access."); return Plugin_Handled; }
	if (args < 2) {

		PrintToChat(client, "%T", "Give Store Points Syntax", client, orange, white);
		return Plugin_Handled;
	}

	decl String:arg[MAX_NAME_LENGTH], String:arg2[4];
	GetCmdArg(1, arg, sizeof(arg));

	if (args > 1) {

		GetCmdArg(2, arg2, sizeof(arg2));
	}
	
	new targetclient = FindTargetClient(client, arg);
	decl String:Name[MAX_NAME_LENGTH];
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

public Action:CMD_MyWeapon(client, args){
	decl String:myWeapon[64];
	GetWeaponName(client, myWeapon, sizeof(myWeapon));
	PrintToChat(client, "%s", myWeapon);
	return Plugin_Handled;
}
public Action:CMD_CollectBonusExperience(client, args) {

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

public Action:Timer_SaveAndClear(Handle:timer) {
	new LivingSurvs = TotalHumanSurvivors();
	for (new i = 1; i <= MaxClients; i++) {

		if (IsLegitimateClient(i) && GetClientTeam(i) == TEAM_SURVIVOR) {

			//ToggleTank(i, true);
			if (b_IsMissionFailed && LivingSurvs > 0) {

				RoundExperienceMultiplier[i] = 0.0;

				// So, the round ends due a failed mission, whether it's coop or survival, and we reset all players ratings.
				VerifyMinimumRating(i, true);
			}

			if(iChaseEnt[i] && EntRefToEntIndex(iChaseEnt[i]) != INVALID_ENT_REFERENCE) AcceptEntityInput(iChaseEnt[i], "Kill");
			iChaseEnt[i] = -1;

			SaveAndClear(i);
		}
	}
	return Plugin_Stop;
}

stock CallRoundIsOver() {

	if (!b_IsRoundIsOver) {

		for (new i = 0; i < 5; i++) {
			SetArrayCell(Handle:RoundStatistics, i, GetArrayCell(RoundStatistics, i) + GetArrayCell(RoundStatistics, i, 1), 1);
		}
		new pEnt = -1;
		decl String:pText[2][64];
		decl String:text[64];
		new pSize = GetArraySize(persistentCirculation);
		for (new i = 0; i < pSize; i++) {
			GetArrayString(persistentCirculation, i, text, sizeof(text));
			ExplodeString(text, ":", pText, 2, 64);
			pEnt = StringToInt(pText[0]);

			if (IsValidEntity(pEnt)) AcceptEntityInput(pEnt, "Kill");
		}

		ClearArray(persistentCirculation);

		b_IsRoundIsOver					= true;
		for (new i = 1; i <= MaxClients; i++) {
			if (IsLegitimateClient(i)) bTimersRunning[i] = false;
		}
		b_RescueIsHere = false;
		if (b_IsActiveRound) b_IsActiveRound = false;
		ClearArray(CommonInfected);
		ClearArray(CommonInfectedHealth);
		ClearArray(Handle:SpecialAmmoData);
		ClearArray(CommonAffixes);
		//SetSurvivorsAliveHostname();
		if (!b_IsMissionFailed) {
			//InfectedLevel = HumanSurvivorLevels();

			if (!IsSurvivalMode) {

				for (new i = 1; i <= MaxClients; i++) {

					if (IsLegitimateClient(i) && GetClientTeam(i) == TEAM_SURVIVOR) {

						iThreatLevel[i] = 0;
						bIsInCombat[i] = false;
					
						if (IsPlayerAlive(i)) {

							if (Rating[i] < 0 && CurrentMapPosition != 1) VerifyMinimumRating(i);
							if (RoundExperienceMultiplier[i] < 0.0) RoundExperienceMultiplier[i] = 0.0;
							if (CurrentMapPosition != 1) {

								RoundExperienceMultiplier[i] += fCoopSurvBon;
								//PrintToChat(i, "xp bonus of %3.3f added : %3.3f bonus", fCoopSurvBon, RoundExperienceMultiplier[i]);
 							}
							//else PrintToChat(i, "no round bonus applied.");
							AwardExperience(i, _, _, true);
						}
					}
				}
			}
		}
		CreateTimer(1.0, Timer_SaveAndClear, _, TIMER_FLAG_NO_MAPCHANGE);
		b_IsCheckpointDoorStartOpened	= false;
		RemoveImmunities(-1);

		ClearArray(Handle:LoggedUsers);		// when a round ends, logged users are removed.
		b_IsActiveRound = false;
		MapRoundsPlayed++;

		new Seconds			= GetTime() - RoundTime;
		new Minutes			= 0;
		while (Seconds >= 60) {

			Minutes++;
			Seconds -= 60;
		}

		//common is 0
		//super is 1
		//witch is 2
		//si is 3
		//tank is 4

		decl String:roundStatisticsText[6][64];

		PrintToChatAll("%t", "Round Time", orange, blue, Minutes, white, blue, Seconds, white);
		if (CurrentMapPosition != 1) {
			AddCommasToString(GetArrayCell(RoundStatistics, 0), roundStatisticsText[0], sizeof(roundStatisticsText[]));
			AddCommasToString(GetArrayCell(RoundStatistics, 1), roundStatisticsText[1], sizeof(roundStatisticsText[]));
			AddCommasToString(GetArrayCell(RoundStatistics, 2), roundStatisticsText[2], sizeof(roundStatisticsText[]));
			AddCommasToString(GetArrayCell(RoundStatistics, 3), roundStatisticsText[3], sizeof(roundStatisticsText[]));
			AddCommasToString(GetArrayCell(RoundStatistics, 4), roundStatisticsText[4], sizeof(roundStatisticsText[]));
			AddCommasToString(GetArrayCell(RoundStatistics, 0) + GetArrayCell(RoundStatistics, 1) + GetArrayCell(RoundStatistics, 2) + GetArrayCell(RoundStatistics, 3) + GetArrayCell(RoundStatistics, 4), roundStatisticsText[5], sizeof(roundStatisticsText[]));

			PrintToChatAll("%t", "round statistics", green, orange, blue,
							roundStatisticsText[0], orange, blue,
							roundStatisticsText[1], orange, blue,
							roundStatisticsText[2], orange, blue,
							roundStatisticsText[3], orange, blue,
							roundStatisticsText[4], orange, green,
							roundStatisticsText[5]);
		}
		else {
			AddCommasToString(GetArrayCell(RoundStatistics, 0, 1), roundStatisticsText[0], sizeof(roundStatisticsText[]));
			AddCommasToString(GetArrayCell(RoundStatistics, 1, 1), roundStatisticsText[1], sizeof(roundStatisticsText[]));
			AddCommasToString(GetArrayCell(RoundStatistics, 2, 1), roundStatisticsText[2], sizeof(roundStatisticsText[]));
			AddCommasToString(GetArrayCell(RoundStatistics, 3, 1), roundStatisticsText[3], sizeof(roundStatisticsText[]));
			AddCommasToString(GetArrayCell(RoundStatistics, 4, 1), roundStatisticsText[4], sizeof(roundStatisticsText[]));
			AddCommasToString(GetArrayCell(RoundStatistics, 0, 1) + GetArrayCell(RoundStatistics, 1, 1) + GetArrayCell(RoundStatistics, 2, 1) + GetArrayCell(RoundStatistics, 3, 1) + GetArrayCell(RoundStatistics, 4, 1), roundStatisticsText[5], sizeof(roundStatisticsText[]));

			PrintToChatAll("%t", "campaign statistics", green, orange, blue,
							roundStatisticsText[0], orange, blue,
							roundStatisticsText[1], orange, blue,
							roundStatisticsText[2], orange, blue,
							roundStatisticsText[3], orange, blue,
							roundStatisticsText[4], orange, green,
							roundStatisticsText[5]);
		}
		
		ResetArray(Handle:CommonInfected);
		ResetArray(Handle:WitchList);
		ResetArray(Handle:CommonList);
		/*ClearArray(Handle:CommonInfected);
		ClearArray(Handle:WitchList);
		ClearArray(Handle:CommonList);*/
		ClearArray(Handle:EntityOnFire);
		ClearArray(Handle:CommonInfectedQueue);
		ClearArray(Handle:SuperCommonQueue);
		ClearArray(Handle:StaggeredTargets);

		if (b_IsMissionFailed && StrContains(TheCurrentMap, "zerowarn", false) != -1) {
			PrintToChatAll("\x04Zero warning:\n\nThis campaign requires map restart on missionFail to prevent serverCrash.\nSorry for the inconvenience, Data will be preserved!!!");
			LogMessage("restarting zero warning.");
			// need to force-teleport players here on new spawn: 4087.998291 11974.557617 -269.968750
			CreateTimer(5.0, Timer_ResetMap, _, TIMER_FLAG_NO_MAPCHANGE);
		}
	}
}


public Action:Timer_ResetMap(Handle:timer) {

	ServerCommand("changelevel %s", TheCurrentMap);
	return Plugin_Stop;
}

stock ResetArray(Handle:TheArray) {

	ClearArray(Handle:TheArray);
}

public ReadyUp_ParseConfigFailed(String:config[], String:error[]) {

	if (StrEqual(config, CONFIG_MAIN) ||
		StrEqual(config, CONFIG_EVENTS) ||
		StrEqual(config, CONFIG_MENUTALENTS) ||
		StrEqual(config, CONFIG_MAINMENU) ||
		StrEqual(config, CONFIG_POINTS) ||
		StrEqual(config, CONFIG_STORE) ||
		StrEqual(config, CONFIG_TRAILS) ||
		StrEqual(config, CONFIG_CHATSETTINGS) ||
		StrEqual(config, CONFIG_WEAPONS) ||
		StrEqual(config, CONFIG_PETS) ||
		StrEqual(config, CONFIG_COMMONAFFIXES)) {

		SetFailState("%s , %s", config, error);
	}
}

public ReadyUp_LoadFromConfigEx(Handle:key, Handle:value, Handle:section, String:configname[], keyCount) {

	//PrintToChatAll("Size: %d config: %s", GetArraySize(Handle:key), configname);
	if (!StrEqual(configname, CONFIG_MAIN) &&
		!StrEqual(configname, CONFIG_EVENTS) &&
		!StrEqual(configname, CONFIG_MENUTALENTS) &&
		!StrEqual(configname, CONFIG_MAINMENU) &&
		!StrEqual(configname, CONFIG_POINTS) &&
		!StrEqual(configname, CONFIG_STORE) &&
		!StrEqual(configname, CONFIG_TRAILS) &&
		!StrEqual(configname, CONFIG_CHATSETTINGS) &&
		!StrEqual(configname, CONFIG_WEAPONS) &&
		!StrEqual(configname, CONFIG_PETS) &&
		!StrEqual(configname, CONFIG_COMMONAFFIXES)) return;
	decl String:s_key[512];
	decl String:s_value[512];
	decl String:s_section[512];
	new Handle:TalentKeys		=					CreateArray(32);
	new Handle:TalentValues		=					CreateArray(32);
	new Handle:TalentSection	=					CreateArray(32);
	new lastPosition = 0;
	new counter = 0;
	if (keyCount > 0) {
		if (StrEqual(configname, CONFIG_MENUTALENTS)) ResizeArray(a_Menu_Talents, keyCount);
		else if (StrEqual(configname, CONFIG_MAINMENU)) ResizeArray(a_Menu_Main, keyCount);
		else if (StrEqual(configname, CONFIG_EVENTS)) ResizeArray(a_Events, keyCount);
		else if (StrEqual(configname, CONFIG_POINTS)) ResizeArray(a_Points, keyCount);
		else if (StrEqual(configname, CONFIG_PETS)) ResizeArray(a_Pets, keyCount);
		else if (StrEqual(configname, CONFIG_STORE)) ResizeArray(a_Store, keyCount);
		else if (StrEqual(configname, CONFIG_TRAILS)) ResizeArray(a_Trails, keyCount);
		else if (StrEqual(configname, CONFIG_CHATSETTINGS)) ResizeArray(a_ChatSettings, keyCount);
		else if (StrEqual(configname, CONFIG_WEAPONS)) ResizeArray(a_WeaponDamages, keyCount);
		else if (StrEqual(configname, CONFIG_COMMONAFFIXES)) ResizeArray(a_CommonAffixes, keyCount);
	}
	new a_Size						= GetArraySize(key);
	for (new i = 0; i < a_Size; i++) {

		GetArrayString(Handle:key, i, s_key, sizeof(s_key));
		GetArrayString(Handle:value, i, s_value, sizeof(s_value));

		PushArrayString(TalentKeys, s_key);
		PushArrayString(TalentValues, s_value);

		if (StrEqual(configname, CONFIG_MAIN)) {

			PushArrayString(Handle:MainKeys, s_key);
			PushArrayString(Handle:MainValues, s_value);
			if (StrEqual(s_key, "rpg mode?")) {

				CurrentRPGMode = StringToInt(s_value);
				LogMessage("=====\t\tRPG MODE SET TO %d\t\t=====", CurrentRPGMode);
			}
		}
		//} else {
		if (StrEqual(s_key, "EOM")) {

			GetArrayString(Handle:section, i, s_section, sizeof(s_section));
			PushArrayString(TalentSection, s_section);

			if (StrEqual(configname, CONFIG_MENUTALENTS)) SetConfigArrays(configname, a_Menu_Talents, TalentKeys, TalentValues, TalentSection, GetArraySize(a_Menu_Talents), lastPosition - counter);
			else if (StrEqual(configname, CONFIG_MAINMENU)) SetConfigArrays(configname, a_Menu_Main, TalentKeys, TalentValues, TalentSection, GetArraySize(a_Menu_Main), lastPosition - counter);
			else if (StrEqual(configname, CONFIG_EVENTS)) SetConfigArrays(configname, a_Events, TalentKeys, TalentValues, TalentSection, GetArraySize(a_Events), lastPosition - counter);
			else if (StrEqual(configname, CONFIG_POINTS)) SetConfigArrays(configname, a_Points, TalentKeys, TalentValues, TalentSection, GetArraySize(a_Points), lastPosition - counter);
			else if (StrEqual(configname, CONFIG_PETS)) SetConfigArrays(configname, a_Pets, TalentKeys, TalentValues, TalentSection, GetArraySize(a_Pets), lastPosition - counter);
			else if (StrEqual(configname, CONFIG_STORE)) SetConfigArrays(configname, a_Store, TalentKeys, TalentValues, TalentSection, GetArraySize(a_Store), lastPosition - counter);
			else if (StrEqual(configname, CONFIG_TRAILS)) SetConfigArrays(configname, a_Trails, TalentKeys, TalentValues, TalentSection, GetArraySize(a_Trails), lastPosition - counter);
			else if (StrEqual(configname, CONFIG_CHATSETTINGS)) SetConfigArrays(configname, a_ChatSettings, TalentKeys, TalentValues, TalentSection, GetArraySize(a_ChatSettings), lastPosition - counter);
			else if (StrEqual(configname, CONFIG_WEAPONS)) SetConfigArrays(configname, a_WeaponDamages, TalentKeys, TalentValues, TalentSection, GetArraySize(a_WeaponDamages), lastPosition - counter);
			else if (StrEqual(configname, CONFIG_COMMONAFFIXES)) SetConfigArrays(configname, a_CommonAffixes, TalentKeys, TalentValues, TalentSection, GetArraySize(a_CommonAffixes), lastPosition - counter);
			
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

		new size						=	GetArraySize(a_Points);
		new Handle:Keys					=	CreateArray(32);
		new Handle:Values				=	CreateArray(32);
		new Handle:Section				=	CreateArray(32);
		
		new sizer						=	0;

		for (new i = 0; i < size; i++) {

			Keys						=	GetArrayCell(a_Points, i, 0);
			Values						=	GetArrayCell(a_Points, i, 1);
			Section						=	GetArrayCell(a_Points, i, 2);

			new size2					=	GetArraySize(Keys);
			for (new ii = 0; ii < size2; ii++) {

				GetArrayString(Handle:Keys, ii, s_key, sizeof(s_key));
				GetArrayString(Handle:Values, ii, s_value, sizeof(s_value));

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

	decl String:thetext[64];
	if (StrEqual(configname, CONFIG_MAIN) && !b_IsFirstPluginLoad) {

		b_IsFirstPluginLoad = true;
		if (hDatabase == INVALID_HANDLE) {

			MySQL_Init();
		}
		LoadMainConfig();

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
		GetConfigValue(thetext, sizeof(thetext), "chat tag naming command?");
		RegConsoleCmd(thetext, CMD_ChatTag);
		GetConfigValue(thetext, sizeof(thetext), "share points command?");
		RegConsoleCmd(thetext, CMD_SharePoints);
		/*GetConfigValue(thetext, sizeof(thetext), "toggle ammo command?");
		RegConsoleCmd(thetext, CMD_ToggleAmmo);
		GetConfigValue(thetext, sizeof(thetext), "cycle ammo forward command?");
		RegConsoleCmd(thetext, CMD_CycleForwardAmmo);
		GetConfigValue(thetext, sizeof(thetext), "cycle ammo backward command?");*/
		//RegConsoleCmd(thetext, CMD_CycleBackwardAmmo);
		GetConfigValue(thetext, sizeof(thetext), "buy menu command?");
		RegConsoleCmd(thetext, CMD_BuyMenu);
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

	if (StrEqual(configname, CONFIG_EVENTS)) SubmitEventHooks(1);
	ReadyUp_NtvGetHeader();

	if (StrEqual(configname, CONFIG_MAIN)) {
		GetConfigValue(thetext, sizeof(thetext), "item drop model?");
		PrecacheModel(thetext, true);
		GetConfigValue(thetext, sizeof(thetext), "backpack model?");
		PrecacheModel(thetext, true);
	}

	/*

		We need to preload an array full of all the positions of item drops.
		Faster than searching every time.
	*/
	if (StrEqual(configname, CONFIG_MENUTALENTS)) {

		ClearArray(ItemDropArray);
		new mySize = GetArraySize(a_Menu_Talents);
		new curSize= -1;
		new pos = 0;

		for (new i = 0; i <= iRarityMax; i++) {
			for (new j = 0; j < mySize; j++) {
				PreloadKeys				= GetArrayCell(a_Menu_Talents, j, 0);
				PreloadValues			= GetArrayCell(a_Menu_Talents, j, 1);
				if (GetKeyValueInt(PreloadKeys, PreloadValues, "is item?") == 1) {
					//PushArrayCell(ItemDropArray, i);
					if (GetKeyValueInt(PreloadKeys, PreloadValues, "rarity?") == i) {
						curSize = GetArraySize(ItemDropArray);
						if (pos == curSize) ResizeArray(ItemDropArray, curSize + 1);
						SetArrayCell(ItemDropArray, pos, j, i);
						pos++;
					}
				}
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
	GetConVarString(FindConVar("z_difficulty"), sServerDifficulty, sizeof(sServerDifficulty));
	if (strlen(sServerDifficulty) < 4) GetConfigValue(sServerDifficulty, sizeof(sServerDifficulty), "server difficulty?");
	fHealSizeDefault					= GetConfigValueFloat("default aura size for heal types?");
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
	GetConfigValue(sSpecialsAllowed, sizeof(sSpecialsAllowed), "special infected classes?");
	iSpecialsAllowed					= GetConfigValueInt("special infected allowed?");
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
	iRushingModuleEnabled				= GetConfigValueInt("anti-rushing enabled?");
	iTanksAlways						= GetConfigValueInt("tanks always active?");
	iTanksAlwaysEnforceCooldown 		= GetConfigValueInt("tanks always enforce cooldown?");
	fSprintSpeed						= GetConfigValueFloat("sprint speed?");
	iRPGMode							= GetConfigValueInt("rpg mode?");
	//fTankMultiplier					= GetConfigValueFloat("director tanks player multiplier?");
	iTankPlayerCount					= GetConfigValueInt("director tanks per _ players?");
	DirectorWitchLimit					= GetConfigValueInt("director witch limit?");
	fCommonQueueLimit					= GetConfigValueFloat("common queue limit?");
	fDirectorThoughtDelay				= GetConfigValueFloat("director thought process delay?");
	fDirectorThoughtHandicap			= GetConfigValueFloat("director thought process handicap?");
	iSurvivalRoundTime					= GetConfigValueInt("survival round time?");
	fDazedDebuffEffect					= GetConfigValueFloat("dazed debuff effect?");
	ConsumptionInt						= GetConfigValueInt("stamina consumption interval?");
	fStamSprintInterval					= GetConfigValueFloat("stamina sprint interval?");
	fStamRegenTime						= GetConfigValueFloat("stamina regeneration time?");
	fStamRegenTimeAdren					= GetConfigValueFloat("stamina regeneration time adren?");
	fBaseMovementSpeed					= GetConfigValueFloat("base movement speed?");
	fFatigueMovementSpeed				= GetConfigValueFloat("fatigue movement speed?");
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
	decl String:text[64], String:text2[64], String:text3[64], String:text4[64];
	for (new i = 0; i < 7; i++) {
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
	fPointsMultiplierInfected			= GetConfigValueFloat("points multiplier infected?");
	fPointsMultiplier					= GetConfigValueFloat("points multiplier survivor?");
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
	AllowedPanicInterval				= GetConfigValueInt("mega mob max interval base?");
	RespawnQueue						= GetConfigValueInt("survivor respawn queue?");
	MaximumPriority						= GetConfigValueInt("director priority maximum?");
	ConsMult							= GetConfigValueFloat("constitution ab multiplier?");
	AgilMult							= GetConfigValueFloat("agility ab multiplier?");
	ResiMult							= GetConfigValueFloat("resilience ab multiplier?");
	TechMult							= GetConfigValueFloat("technique ab multiplier?");
	EnduMult							= GetConfigValueFloat("endurance ab multiplier?");
	fUpgradeExpCost						= GetConfigValueFloat("upgrade experience cost?");
	iHandicapLevelDifference			= GetConfigValueInt("handicap level difference required?");
	iWitchHealthBase					= GetConfigValueInt("base witch health?");
	fWitchHealthMult					= GetConfigValueFloat("level witch multiplier?");
	//RatingPerLevel					= GetConfigValueInt("rating level multiplier?");
	iCommonBaseHealth					= GetConfigValueInt("common base health?");
	fCommonRaidHealthMult				= GetConfigValueFloat("common raid health multiplier?");
	fCommonLevelHealthMult				= GetConfigValueFloat("common level health?");
	//iServerLevelRequirement			= GetConfigValueInt("server level requirement?");
	iRoundStartWeakness					= GetConfigValueInt("weakness on round start?");
	GroupMemberBonus					= GetConfigValueFloat("steamgroup bonus?");
	RaidLevMult							= GetConfigValueInt("raid level multiplier?");
	iIgnoredRating						= GetConfigValueInt("rating to ignore?");
	iIgnoredRatingMax					= GetConfigValueInt("max rating to ignore?");
	//iTrailsEnabled					= GetConfigValueInt("trails enabled?");
	iInfectedLimit						= GetConfigValueInt("ensnare infected limit?");
	SurvivorExperienceMult				= GetConfigValueFloat("experience multiplier survivor?");
	SurvivorExperienceMultTank			= GetConfigValueFloat("experience multiplier tanking?");
	SurvivorExperienceMultHeal			= GetConfigValueFloat("experience multiplier healing?");
	TheScorchMult						= GetConfigValueFloat("scorch multiplier?");
	TheInfernoMult						= GetConfigValueFloat("inferno multiplier?");
	fAmmoHighlightTime					= GetConfigValueFloat("special ammo highlight time?");
	fAdrenProgressMult					= GetConfigValueFloat("adrenaline progress multiplier?");
	DirectorTankCooldown				= GetConfigValueFloat("director tank cooldown?");
	DisplayType							= GetConfigValueInt("survivor reward display?");
	GetConfigValue(sDirectorTeam, sizeof(sDirectorTeam), "director team name?");
	fRestedExpMult						= GetConfigValueFloat("rested experience multiplier?");
	fSurvivorExpMult					= GetConfigValueFloat("survivor experience bonus?");
	iIsPvpServer						= GetConfigValueInt("pvp server?");
	iDebuffLimit						= GetConfigValueInt("debuff limit?");
	iRatingSpecialsRequired				= GetConfigValueInt("specials rating required?");
	iRatingTanksRequired				= GetConfigValueInt("tank rating required?");
	GetConfigValue(sDbLeaderboards, sizeof(sDbLeaderboards), "db record?");
	iIsLifelink							= GetConfigValueInt("lifelink enabled?");
	RatingPerHandicap					= GetConfigValueInt("rating level handicap?");
	GetConfigValue(sItemModel, sizeof(sItemModel), "item drop model?");
	fDropChanceSpecial					= GetConfigValueFloat("item chance supers?");
	fDropChanceCommon					= GetConfigValueFloat("item chance commons?");
	fDropChanceWitch					= GetConfigValueFloat("item chance witch?");
	fDropChanceTank						= GetConfigValueFloat("item chance tank?");
	fDropChanceInfected					= GetConfigValueFloat("item chance infected?");
	iDropsEnabled						= GetConfigValueInt("item drop enabled?");
	iItemExpireDate						= GetConfigValueInt("item expire date?");
	iRarityMax							= GetConfigValueInt("item rarity max?");
	iEnrageAdvertisement				= GetConfigValueInt("enrage advertise time?");
	iNotifyEnrage						= GetConfigValueInt("enrage notification?");
	iJoinGroupAdvertisement				= GetConfigValueInt("join group advertise time?");
	GetConfigValue(sBackpackModel, sizeof(sBackpackModel), "backpack model?");
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
	fSpecialAmmoInterval				= GetConfigValueFloat("special ammo tick rate?");
	fEffectOverTimeInterval				= GetConfigValueFloat("effect over time tick rate?");
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
	iDeleteCommonsFromExistenceOnDeath	= GetConfigValueInt("delete commons from existence on death?");
	iShowDetailedDisplayAlways			= GetConfigValueInt("show detailed display to survivors always?");
	iCanJetpackWhenInCombat				= GetConfigValueInt("can players jetpack when in combat?");
	fquickScopeTime						= GetConfigValueFloat("delay after zoom for quick scope kill?");
	iEnsnareLevelMultiplier				= GetConfigValueInt("ensnare level multiplier?");
	iNoSpecials							= GetConfigValueInt("disable non boss special infected?");
	fSurvivorBotsNoneBonus				= GetConfigValueFloat("group bonus if no survivor bots?");
	iSurvivorBotsBonusLimit				= GetConfigValueInt("no survivor bots group bonus requirement?");
	iShowAdvertToNonSteamgroupMembers	= GetConfigValueInt("show advertisement to non-steamgroup members?");
	GetConfigValue(DefaultProfileName, sizeof(DefaultProfileName), "new player profile?");
	GetConfigValue(DefaultBotProfileName, sizeof(DefaultBotProfileName), "new bot player profile?");
	GetConfigValue(DefaultInfectedProfileName, sizeof(DefaultInfectedProfileName), "new infected player profile?");
	GetConfigValue(defaultLoadoutWeaponPrimary, sizeof(defaultLoadoutWeaponPrimary), "default loadout primary weapon?");
	GetConfigValue(defaultLoadoutWeaponSecondary, sizeof(defaultLoadoutWeaponSecondary), "default loadout secondary weapon?");
	LogMessage("Main Config Loaded.");
}

//public Action:CMD_Backpack(client, args) { EquipBackpack(client); return Plugin_Handled; }

public Action:CMD_BuyMenu(client, args) {

	if (iRPGMode < 0 || iRPGMode == 1 && b_IsActiveRound) return Plugin_Handled;

	//if (StringToInt(GetConfigValue("rpg mode?")) != 1) 
	BuildPointsMenu(client, "Buy Menu", "rpg/points.cfg");
	
	return Plugin_Handled;
}

public Action:CMD_ToggleAmmo(client, args) {
	if (HasSpecialAmmo(client) && !bIsSurvivorFatigue[client]) {
		if (IsSpecialAmmoEnabled[client][0] == 1.0) {
			IsSpecialAmmoEnabled[client][0] = 0.0;
			//LastTarget[client] = -1;
			PrintToChat(client, "%T", "Special Ammo Disabled", client, white, orange);
		}
		else {

			IsSpecialAmmoEnabled[client][0] = 1.0;
			PrintToChat(client, "%T", "Special Ammo Enabled", client, white, green);
		}
	}
	else {

		//	If the user doesn't have special ammo...
		PrintToChat(client, "%T", "No Special Ammo", client, white, orange, white);
		IsSpecialAmmoEnabled[client][0] = 0.0;
	}
	return Plugin_Handled;
}

public Action:CMD_CycleForwardAmmo(client, args) {

	if (HasSpecialAmmo(client) && !bIsSurvivorFatigue[client]) CycleSpecialAmmo(client, true);
	return Plugin_Handled;
}

public Action:CMD_CycleBackwardAmmo(client, args) {

	if (HasSpecialAmmo(client) && !bIsSurvivorFatigue[client]) CycleSpecialAmmo(client, false);
	return Plugin_Handled;
}

public Action:CMD_DataErase(client, args) {
	decl String:arg[MAX_NAME_LENGTH];
	decl String:thetext[64];

	GetConfigValue(thetext, sizeof(thetext), "delete bot flags?");
	if (args > 0 && HasCommandAccess(client, thetext)) {
		GetCmdArg(1, arg, sizeof(arg));
		new targetclient = FindTargetClient(client, arg);
		if (IsLegitimateClient(targetclient) && GetClientTeam(targetclient) != TEAM_INFECTED) DeleteAndCreateNewData(targetclient);
	}
	else DeleteAndCreateNewData(client);
	return Plugin_Handled;
}

public Action:CMD_DataEraseBot(client, args) {
	DeleteAndCreateNewData(client, true);
	return Plugin_Handled;
}

stock DeleteAndCreateNewData(client, bool:IsBot = false) {
	//decl String:thetext[64];
	//GetConfigValue(thetext, sizeof(thetext), "database prefix?");
	decl String:key[64];
	decl String:tquery[1024];
	decl String:text[64];
	decl String:pct[4];
	Format(pct, sizeof(pct), "%");
	if (!IsBot) {
		GetClientAuthString(client, key, sizeof(key));
		Format(tquery, sizeof(tquery), "DELETE FROM `%s` WHERE `steam_id` = '%s';", TheDBPrefix, key);
		SQL_TQuery(hDatabase, QueryResults, tquery, client);
		ResetData(client);
		CreateNewPlayerEx(client);
		PrintToChat(client, "data erased, new data created.");	// not bothering with a translation here, since it's a debugging command.
	}
	else {
		GetConfigValue(text, sizeof(text), "delete bot flags?");
		if (HasCommandAccess(client, text)) {

			for (new i = 1; i <= MaxClients; i++) {

				if (IsSurvivorBot(i)) KickClient(i);
			}

			Format(tquery, sizeof(tquery), "DELETE FROM `%s` WHERE `steam_id` LIKE '%s%s%s';", TheDBPrefix, pct, sBotTeam, pct);
			//Format(tquery, sizeof(tquery), "DELETE FROM `%s` WHERE `steam_id` LIKE 'STEAM';", TheDBPrefix);
			SQL_TQuery(hDatabase, QueryResults, tquery, client);
			LogMessage("%s", tquery);
			PrintToChatAll("%t", "bot data deleted", orange, blue);
		}
	}
}

public Action:CMD_DirectorTalentToggle(client, args) {
	decl String:thetext[64];
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

stock SetConfigArrays(String:Config[], Handle:Main, Handle:Keys, Handle:Values, Handle:Section, size, last) {

	decl String:text[64];
	//GetArrayString(Section, 0, text, sizeof(text));

	new Handle:TalentKey = CreateArray(32);
	new Handle:TalentValue = CreateArray(32);
	new Handle:TalentSection = CreateArray(32);

	decl String:key[64];
	decl String:value[64];
	new a_Size = GetArraySize(Keys);

	for (new i = last; i < a_Size; i++) {

		GetArrayString(Handle:Keys, i, key, sizeof(key));
		GetArrayString(Handle:Values, i, value, sizeof(value));

		PushArrayString(TalentKey, key);
		PushArrayString(TalentValue, value);
	}

	GetArrayString(Handle:Section, size, text, sizeof(text));
	PushArrayString(TalentSection, text);

	if (StrEqual(Config, CONFIG_MENUTALENTS)) PushArrayString(a_Database_Talents, text);

	ResizeArray(Main, size + 1);
	SetArrayCell(Main, size, TalentKey, 0);
	SetArrayCell(Main, size, TalentValue, 1);
	SetArrayCell(Main, size, TalentSection, 2);
}

public ReadyUp_FwdGetHeader(const String:header[]) {

	strcopy(s_rup, sizeof(s_rup), header);
}

public ReadyUp_FwdGetCampaignName(const String:mapname[]) {

	strcopy(currentCampaignName, sizeof(currentCampaignName), mapname);
}

public ReadyUp_CoopMapFailed(iGamemode) {

	if (!b_IsMissionFailed) {

		b_IsMissionFailed	= true;
		Points_Director = 0.0;
	}
}

stock bool:IsCommonRegistered(entity) {
	if (FindListPositionByEntity(entity, Handle:CommonList) >= 0 ||
		FindListPositionByEntity(entity, Handle:CommonInfected) >= 0) return true;
	return false;
}

stock bool:IsSpecialCommon(entity) {
	if (FindListPositionByEntity(entity, Handle:CommonList) >= 0) {
		if (IsCommonInfected(entity)) return true;
		else ClearSpecialCommon(entity, false);
	}

	return false;
}

/*stock FindClientWithAuth(authid) {

	decl String:AuthString[64];
	decl String:AuthComp[64];

	for (new i = 1; i <= MaxClients; i++) {
		
		if (!IsLegitimateClient(i)) continue;

		GetClientAuthId(i, AuthIdType:AuthId_Steam3, AuthString, 64);
		IntToString(authid, AuthComp, sizeof(AuthComp));

		if (StrContains(AuthString, AuthComp) != -1) return i;
	}
	return -1;
}*/
//GetClientAuthId(client, AuthIdType:AuthId_Steam3, String:AuthString, maxlen, bool:validate=true);

#include "rpg/rpg_menu.sp"
#include "rpg/rpg_menu_points.sp"
#include "rpg/rpg_menu_store.sp"
#include "rpg/rpg_menu_chat.sp"
#include "rpg/rpg_menu_director.sp"
#include "rpg/rpg_timers.sp"
#include "rpg/rpg_functions.sp"
#include "rpg/rpg_events.sp"
#include "rpg/rpg_database.sp"