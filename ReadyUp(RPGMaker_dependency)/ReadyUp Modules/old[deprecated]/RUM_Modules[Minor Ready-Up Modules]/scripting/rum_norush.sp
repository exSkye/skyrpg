#define TEAM_SURVIVOR		2

#define PLUGIN_VERSION		"1.0.1"
#define PLUGIN_CONTACT		"steamcommunity.com/id/palevixen"
#define PLUGIN_NAME			"[RUM][Player Management] No Rushing"
#define PLUGIN_DESCRIPTION	"penalizes players who move too far ahead their teammates."
#define CONFIG_MAPS			"norush/"
#define CVAR_SHOW			FCVAR_NOTIFY | FCVAR_PLUGIN

#include <sourcemod>
#include <sdktools>
#include <l4d2_direct>

#include "wrap.inc"
#include "l4d_stocks.inc"

#undef REQUIRE_PLUGIN
#include "readyup.inc"

public Plugin:myinfo = {

	name		= PLUGIN_NAME,
	author		= PLUGIN_CONTACT,
	description	= PLUGIN_DESCRIPTION,
	version		= PLUGIN_VERSION,
	url			= PLUGIN_CONTACT,
};

new bool:b_IsPluginLoaded;
new bool:b_IsRoundLive;
new String:s_rup[32];
new String:filepath[PLATFORM_MAX_PATH];

new map_SurvivorsRequired;
new Float:map_SurvivorMaxDistance;
new Float:map_SurvivorWarnDistance;
new Float:map_SurvivorRequiredBehind;
new Float:map_RequiredBehindDistance;
new bool:b_IsPlayerWarned[MAXPLAYERS + 1];

new Float:g_MapFlowDistance;

new String:orange[4];

public OnPluginStart() {

	CreateConVar("rum_norush", PLUGIN_VERSION, "version header", CVAR_SHOW);
	SetConVarString(FindConVar("rum_norush"), PLUGIN_VERSION);

	LoadTranslations("rum_norush.phrases");
	Format(orange, sizeof(orange), "\x04");

	BuildPath(Path_SM, filepath, sizeof(filepath), "configs/readyup/%s", CONFIG_MAPS);
	if (!DirExists(filepath)) CreateDirectory(filepath, 511);
}

public OnConfigsExecuted() {

	if (ReadyUp_GetGameMode() != 3) {

		b_IsPluginLoaded			= true;
		map_SurvivorsRequired		= 0;
		map_SurvivorMaxDistance		= 0.0;
		map_SurvivorWarnDistance	= 0.0;
		map_SurvivorRequiredBehind	= 0.0;
		CreateTimer(0.1, Timer_ExecuteConfig, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
	}
	else b_IsPluginLoaded			= false;
}

public Action:Timer_ExecuteConfig(Handle:timer) {

	if (ReadyUp_NtvConfigProcessing() == 0) {

		decl String:mapname[64];
		GetCurrentMap(mapname, sizeof(mapname));
		Format(mapname, sizeof(mapname), "%s%s.cfg", CONFIG_MAPS, mapname);
		ReadyUp_ParseConfig(mapname);
		return Plugin_Stop;
	}
	return Plugin_Continue;
}

public ReadyUp_FirstClientLoaded() {

	g_MapFlowDistance				= L4D2Direct_GetMapMaxFlowDistance();
}

public OnClientDisconnect(client) {

	if (IsClientInGame(client)) b_IsPlayerWarned[client] = false;
}

public ReadyUp_CheckpointDoorStartOpened() {

	if (b_IsPluginLoaded) {

		b_IsRoundLive				= true;
		CreateTimer(0.1, Timer_DistanceCheck, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
	}
}

public ReadyUp_RoundIsOver() {

	b_IsRoundLive					= false;
	for (new i = 1; i <= MaxClients; i++) {

		if (IsClientConnected(i) && IsClientInGame(i)) b_IsPlayerWarned[i] = false;
	}
}

public ReadyUp_ParseConfigFailed(String:config[], String:error[]) {

	decl String:mapname[64];
	GetCurrentMap(mapname, sizeof(mapname));
	Format(mapname, sizeof(mapname), "%s%s.cfg", CONFIG_MAPS, mapname);
	b_IsPluginLoaded				= false;
	SetFailState("%s , %s", config, error);
}

public ReadyUp_LoadFromConfig(Handle:key, Handle:value) {

	decl String:s_key[64];
	decl String:s_val[64];
	new size						= GetArraySize(key);

	for (new i = 0; i < size; i++) {

		GetArrayString(Handle:key, i, s_key, sizeof(s_key));
		GetArrayString(Handle:value, i, s_val, sizeof(s_val));

		if (StrEqual(s_key, "survivors required?")) map_SurvivorsRequired					= StringToInt(s_val);
		else if (StrEqual(s_key, "maximum distance?")) map_SurvivorMaxDistance				= StringToFloat(s_val);
		else if (StrEqual(s_key, "warning distance?")) map_SurvivorWarnDistance				= StringToFloat(s_val);
		else if (StrEqual(s_key, "survivors behind?")) map_SurvivorRequiredBehind			= StringToFloat(s_val);
		else if (StrEqual(s_key, "required behind distance?")) map_RequiredBehindDistance	= StringToFloat(s_val);
	}

	ReadyUp_NtvGetHeader();
}

public ReadyUp_FwdGetHeader(const String:header[]) {

	strcopy(s_rup, sizeof(s_rup), header);
}

stock Float:GetPlayerMapProgression(client) {

	return (L4D2Direct_GetFlowDistance(client) / g_MapFlowDistance);
}



stock Float:NumberSurvivorsBehindPlayer(client, bool:b_IsCalculateAverage) {

	// This function will return the number of survivors that this player is ahead of on the map.
	// This ignores the survivor who has no players behind them.

	new Float:clientMapProgression	= (L4D2Direct_GetFlowDistance(client) / g_MapFlowDistance);
	new Float:playerMapProgression	= 0.0;
	new Float:survivorsBehindPlayer	= 0.0;
	new Float:averageDistanceBehind	= 0.0;

	for (new i = 1; i <= MaxClients; i++) {

		if (IsLegitimateClientAlive(i) && !IsFakeClient(i) && GetClientTeam(i) == TEAM_SURVIVOR && i != client) {

			// Ignores the player who has no players behind them
			if (NumberSurvivorsBehindPlayer(i, false) == 0.0) continue;

			// Get the player map distance so we can compare it to the client.
			playerMapProgression	= (L4D2Direct_GetFlowDistance(i) / g_MapFlowDistance);

			// There's a minimum distance behind the client a player must be, so we don't calculate someone who is RIGHT BEHIND them.
			if (clientMapProgression > playerMapProgression + map_RequiredBehindDistance) survivorsBehindPlayer++;
		}
	}
	if (!b_IsCalculateAverage) return survivorsBehindPlayer;
	else if (survivorsBehindPlayer >= map_SurvivorRequiredBehind) {

		survivorsBehindPlayer		= 0.0;

		for (new i = 1; i <= MaxClients; i++) {

			if (IsLegitimateClientAlive(i) && !IsFakeClient(i) && GetClientTeam(i) == TEAM_SURVIVOR && i != client) {

				if (NumberSurvivorsBehindPlayer(i, false) == 0.0 ||
					DistanceBehindPlayer(client, i, true) ||
					DistanceBehindPlayer(client, i, false)) continue;

				playerMapProgression	= (L4D2Direct_GetFlowDistance(i) / g_MapFlowDistance);
				averageDistanceBehind	+= playerMapProgression;
				survivorsBehindPlayer++;
			}
		}

		averageDistanceBehind			= (averageDistanceBehind / survivorsBehindPlayer);
	}
	return averageDistanceBehind;
}

stock bool:DistanceBehindPlayer(target, client, bool:b_IsFurthestDistance) {

	// We check if the client is the furthest player behind the target. To do this, we gather the targets map flow and the clients map flow, and see
	// if there is another player behind the target, who is not furthest behind on the map, who is further behind the target than the client.

	new Float:targetMapProgression	= (L4D2Direct_GetFlowDistance(target) / g_MapFlowDistance);
	new Float:clientMapProgression	= (L4D2Direct_GetFlowDistance(client) / g_MapFlowDistance);
	new Float:playerMapProgression	= 0.0;

	for (new i = 1; i <= MaxClients; i++) {

		if (IsLegitimateClientAlive(i) && !IsFakeClient(i) && GetClientTeam(i) == TEAM_SURVIVOR && i != client && i != target) {

			if (NumberSurvivorsBehindPlayer(i, false) == 0.0) continue;
			playerMapProgression	= (L4D2Direct_GetFlowDistance(i) / g_MapFlowDistance);

			if (targetMapProgression > playerMapProgression + map_RequiredBehindDistance) {

				// The player is a legitimate distance behind the target, so find out if their distance is less than the client. If it is, return false.
				if (b_IsFurthestDistance && playerMapProgression < clientMapProgression ||
					!b_IsFurthestDistance && playerMapProgression > clientMapProgression) return false;
			}
		}
	}
	return true;
}

stock TeleportClientToFurthest(client) {

	for (new i = 1; i <= MaxClients; i++) {

		if (IsLegitimateClientAlive(i) && !IsFakeClient(i) && GetClientTeam(i) == TEAM_SURVIVOR && i != client) {

			if (NumberSurvivorsBehindPlayer(i, false) == 0.0) continue;
			if (DistanceBehindPlayer(client, i, true)) {

				new Float:Origin[3];
				GetClientAbsOrigin(i, Origin);
				TeleportEntity(client, Origin, NULL_VECTOR, NULL_VECTOR);
				return;
			}
		}
	}
}

public Action:Timer_DistanceCheck(Handle:timer) {

	if (!b_IsRoundLive) return Plugin_Stop;
	if (ActiveSurvivors() < map_SurvivorsRequired) return Plugin_Continue;

	new Float:clientMapProgression	= 0.0;
	new Float:averageDistanceBehind	= 0.0;

	for (new i = 1; i <= MaxClients; i++) {

		if (IsLegitimateClientAlive(i) && !IsFakeClient(i) && GetClientTeam(i) == TEAM_SURVIVOR && L4D2_GetInfectedAttacker(i) == -1) {

			// Player isn't ensnared.
			clientMapProgression	= (L4D2Direct_GetFlowDistance(i) / g_MapFlowDistance);
			averageDistanceBehind	= NumberSurvivorsBehindPlayer(i, true);
			if (averageDistanceBehind + map_SurvivorWarnDistance < clientMapProgression) {

				if (b_IsPlayerWarned[i]) {

					if (averageDistanceBehind + map_SurvivorMaxDistance < clientMapProgression) {

						b_IsPlayerWarned[i]	= false;
						PrintToChat(i, "%T", "violation", i, orange);
						TeleportClientToFurthest(i);
					}
				}
				else {

					b_IsPlayerWarned[i]		= true;
					PrintToChat(i, "%T", "warning", i, orange);
				}
			}
			else if (b_IsPlayerWarned[i]) b_IsPlayerWarned[i] = false;
		}
	}
	return Plugin_Continue;
}

stock bool:IsLegitimateClient(client) {

	if (client < 1 || client > MaxClients || !IsClientConnected(client) || !IsClientInGame(client)) return false;
	return true;
}

stock bool:IsLegitimateClientAlive(client) {

	if (IsLegitimateClient(client) && IsPlayerAlive(client)) return true;
	return false;
}

stock ActiveSurvivors() {

	new count		= 0;
	for (new i = 1; i <= MaxClients; i++) {

		if (IsLegitimateClientAlive(i) && !IsFakeClient(i) && GetClientTeam(i) == TEAM_SURVIVOR) count++;
	}
	return count;
}