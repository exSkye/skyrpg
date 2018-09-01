#define TEAM_SPECTATOR		1
#define TEAM_SURVIVOR		2
#define TEAM_INFECTED		3

#define MAX_ENTITIES		2048

#define PLUGIN_VERSION		"1.0"
#define PLUGIN_CONTACT		"skyyplugins@gmail.com"

#define PLUGIN_NAME			"[RUM][Server Mgmt] Campaign Rotation"
#define PLUGIN_DESCRIPTION	"Campaign / Map rotation management"
#define CONFIG				"rotation.cfg"
#define CVAR_SHOW			FCVAR_NOTIFY | FCVAR_PLUGIN

#include <sourcemod>
#include <sdktools>
#include "wrap.inc"
#undef REQUIRE_PLUGIN
#include "readyup.inc"

public Plugin:myinfo = {
	name = PLUGIN_NAME,
	author = PLUGIN_CONTACT,
	description = PLUGIN_DESCRIPTION,
	version = PLUGIN_VERSION,
	url = PLUGIN_CONTACT,
};

new i_TimeDelay;
new i_Random;
new i_MaxAttempts;
new i_MaxSurvivalRounds;

new i_Ignore;
new i_Attempts;
new i_Rounds;

new String:s_rup[32];
new String:NextMap[PLATFORM_MAX_PATH];

new Handle:a_MapList1;
new Handle:a_MapList2;

public OnPluginStart()
{
	CreateConVar("rum_rotation", PLUGIN_VERSION, "version header", CVAR_SHOW);
	SetConVarString(FindConVar("rum_rotation"), PLUGIN_VERSION);

	LoadTranslations("common.phrases");
	LoadTranslations("rum_rotation.phrases");

	a_MapList1										= CreateArray(64);
	a_MapList2										= CreateArray(64);
}

public ReadyUp_FwdCallModule(String:nameConfig[], String:nameCommand[], value) {

	if (StrEqual(nameConfig, CONFIG)) {

		if (StrEqual(nameCommand, "ignore rotation")) {

			i_Ignore								= value;
		}
	}
}

public OnConfigsExecuted() {

	i_Attempts										= 0;
	i_Rounds										= 0;

	CreateTimer(0.1, Timer_ExecuteConfig, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
}

public Action:Timer_ExecuteConfig(Handle:timer) {

	if (ReadyUp_NtvConfigProcessing() == 0) {

		ReadyUp_ParseConfig(CONFIG);
		return Plugin_Stop;
	}
	return Plugin_Continue;
}

public ReadyUp_ParseConfigFailed(String:config[], String:error[]) {

	if (StrEqual(config, CONFIG)) {
	
		SetFailState("%s , %s", config, error);
	}
}

public ReadyUp_LoadFromConfig(Handle:key, Handle:value) {

	decl String:s_key[32];
	decl String:s_value[32];

	new a_Size						= GetArraySize(key);

	for (new i = 0; i < a_Size; i++) {

		GetArrayString(Handle:key, i, s_key, sizeof(s_key));
		GetArrayString(Handle:value, i, s_value, sizeof(s_value));
		if (StrEqual(s_key, "delay before map change?")) i_TimeDelay				= StringToInt(s_value);
		else if (StrEqual(s_key, "next map is random?")) i_Random					= StringToInt(s_value);
		else if (StrEqual(s_key, "maximum finale fails?")) i_MaxAttempts			= StringToInt(s_value);
		else if (StrEqual(s_key, "survival rounds played?")) i_MaxSurvivalRounds	= StringToInt(s_value);
	}

	ReadyUp_NtvGetHeader();

	i_Ignore										= 0;	// Changes to 1 on campaign finales / start of survival maps if a vote map modules issues the order.
}

public ReadyUp_FwdGetHeader(const String:header[]) {

	strcopy(s_rup, sizeof(s_rup), header);
}

public ReadyUp_FirstClientLoaded() {

	i_Attempts										= 0;

	ReadyUp_NtvGetMapList();
}

public ReadyUp_FwdGetMapList(Handle:MapList1, Handle:MapList2) {

	ClearArray(Handle:a_MapList1);
	ClearArray(Handle:a_MapList2);

	new a_Size = GetArraySize(MapList1);

	decl String:a_Map[128];

	for (new i = 0; i < a_Size; i++) {

		GetArrayString(Handle:MapList1, i, a_Map, sizeof(a_Map));
		PushArrayString(a_MapList1, a_Map);

		GetArrayString(Handle:MapList2, i, a_Map, sizeof(a_Map));
		PushArrayString(a_MapList2, a_Map);
	}
}

public ReadyUp_CampaignComplete() {

	new gametype										= ReadyUp_GetGameMode();

	if (gametype == 1) Now_CheckIfChangeMaps();	// don't need IsChangeMaps since this only fires if a campaign finale is won.
}

public ReadyUp_RoundIsOver() {

	new gametype										= ReadyUp_GetGameMode();

	if (gametype >= 2) {

		i_Rounds++;

		if (gametype == 2 && i_Rounds >= 2 && IsChangeMap() || gametype == 3 && i_Rounds >= i_MaxSurvivalRounds) Now_CheckIfChangeMaps();
	}
}

public ReadyUp_CoopMapFailed() {

	new gametype										= ReadyUp_GetGameMode();

	if (gametype != 2) {

		// Is not a versus round!

		if (gametype == 1 && IsChangeMap() || gametype == 3) i_Attempts++;		// only check IsChangeMap() if a coop game.

		if (i_Attempts >= i_MaxAttempts) {

			Now_CheckIfChangeMaps();
		}
	}
}

stock Now_CheckIfChangeMaps() {

	if (i_Ignore == 1) return;	// Another module is handling rotations.

	NextMap											= Now_GetNextMap();
	i_Attempts										= 0;
	i_Rounds										= 0;

	PrintToChatAll("%t", "next map in rotation", s_rup, NextMap);

	CreateTimer(i_TimeDelay * 1.0, Timer_ChangeMap, _, TIMER_FLAG_NO_MAPCHANGE);
}

public Action:Timer_ChangeMap(Handle:timer) {

	if (i_Ignore == 0) {

		ServerCommand("changelevel %s", NextMap);
	}

	return Plugin_Stop;
}

stock String:Now_GetNextMap() {

	PrintToChatAll("Hell");

	new gametype									= ReadyUp_GetGameMode();

	decl String:mapname[128];
	GetCurrentMap(mapname, sizeof(mapname));
	mapname											= LowerString(mapname);	// fucking linux case-sensitivity;;not really, i love linux. RED HAT FOREVER!!!

	decl String:a_mapname[128];

	new a_Size										= GetArraySize(a_MapList2);

	if (i_Random == 1) {

		new random									= GetRandomInt(0, a_Size - 1);

		GetArrayString(Handle:a_MapList1, random, a_mapname, sizeof(a_mapname));
		a_mapname									= LowerString(a_mapname);

		return a_mapname;
	}

	for (new i = 0; i < a_Size; i++) {

		if (gametype != 3) GetArrayString(Handle:a_MapList2, i, a_mapname, sizeof(a_mapname));
		else GetArrayString(Handle:a_MapList1, i, a_mapname, sizeof(a_mapname));
		a_mapname									= LowerString(a_mapname);

		if (StrEqual(mapname, a_mapname)) {

			if (i + 1 < a_Size) {

				if (gametype != 3) GetArrayString(Handle:a_MapList1, i + 1, a_mapname, sizeof(a_mapname));
				else GetArrayString(Handle:a_MapList2, i + 1, a_mapname, sizeof(a_mapname));
				a_mapname							= LowerString(a_mapname);

				return a_mapname;
			}

			break;
		}
	}

	if (gametype != 3) GetArrayString(Handle:a_MapList1, 0, a_mapname, sizeof(a_mapname));
	else GetArrayString(Handle:a_MapList2, 0, a_mapname, sizeof(a_mapname));
	a_mapname										= LowerString(a_mapname);

	return a_mapname;
}

stock bool:IsChangeMap() {

	decl String:mapname[128];
	GetCurrentMap(mapname, sizeof(mapname));
	mapname											= LowerString(mapname);

	decl String:a_mapname[128];

	new a_Size										= GetArraySize(a_MapList2);

	for (new i = 0; i < a_Size; i++) {

		GetArrayString(Handle:a_MapList2, i, a_mapname, sizeof(a_mapname));
		a_mapname									= LowerString(a_mapname);

		if (StrEqual(mapname, a_mapname)) return true;
	}

	return false;
}

stock String:LowerString(String:s[]) {

	decl String:s_[32];
	for (new i = 0; i <= strlen(s); i++) {

		if (!IsCharLower(s[i])) s_[i] = CharToLower(s[i]);
		else s_[i] = s[i];
	}
	return s_;
}