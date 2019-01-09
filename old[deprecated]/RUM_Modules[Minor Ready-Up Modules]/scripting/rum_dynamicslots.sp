#define		TEAM_SPECTATOR				1
#define		TEAM_SURVIVOR				2
#define		TEAM_INFECTED				3

#define		PLUGIN_VERSION				"2.0"
#define		PLUGIN_CONTACT				"michaeltoth.85@gmail.com"
#define		PLUGIN_NAME					"[rum] Dynamic Player Slots"
#define		PLUGIN_DESCRIPTION			"Adjusts slots based on the number of spectators and manages reserve slots."
#define		PLUGIN_CONFIG				"dynamicslots.cfg"
#define		CVAR_SHOW					FCVAR_NOTIFY | FCVAR_PLUGIN

#include	<sourcemod>
#include	<sdktools>
#include	"wrap.inc"
#undef REQUIRE_PLUGIN
#include	"readyup.inc"

public Plugin:myinfo = { name = PLUGIN_NAME, author = PLUGIN_CONTACT, description = PLUGIN_DESCRIPTION, version = PLUGIN_VERSION, url = PLUGIN_CONTACT, };

new i_PlayerSlots, i_ReserveSlots, i_InfectedSlots, i_SurvivorSlots;
new String:s_rup[32];

public OnPluginStart() {

	CreateConVar("rum_dynamicslots", PLUGIN_VERSION, "version header", CVAR_SHOW);
	SetConVarString(FindConVar("rum_dynamicslots"), PLUGIN_VERSION);

	LoadTranslations("rum_dynamicslots.phrases");
}

public OnConfigsExecuted() { CreateTimer(0.1, Timer_ExecuteConfig, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE); }
public Action:Timer_ExecuteConfig(Handle:timer) {

	if (ReadyUp_NtvConfigProcessing() == 0) {

		ReadyUp_ParseConfig(PLUGIN_CONFIG);
		return Plugin_Stop;
	}

	return Plugin_Continue;
}

public ReadyUp_ParseConfigFailed(String:config[], String:error[]) {

	if (StrEqual(config, PLUGIN_CONFIG)) SetFailState("%s , %s", config, error);
}

public ReadyUp_LoadFromConfig(Handle:keys, Handle:values) {

	decl String:key[32];
	decl String:val[32];
	new size = GetArraySize(keys);

	for (new i = 0; i < size; i++) {

		GetArrayString(Handle:keys, i, key, sizeof(key));
		GetArrayString(Handle:values, i, val, sizeof(val));

		if (StrEqual(key, "actual player slots?")) i_PlayerSlots		= StringToInt(val);
		if (StrEqual(key, "number reserve slots?")) i_ReserveSlots		= StringToInt(val);
	}
	if (ReadyUp_GetGameMode() == 2) i_InfectedSlots		= i_PlayerSlots / 2;
	else i_InfectedSlots		= i_PlayerSlots;
	
	i_SurvivorSlots		= i_InfectedSlots;

	ReadyUp_NtvGetHeader();
}

public ReadyUp_FwdGetHeader(const String:header[]) {

	strcopy(s_rup, sizeof(s_rup), header);
	Now_ManageSlots();
}

public ReadyUp_FwdChangeTeam(client, team) { CreateTimer(3.0, Timer_ManageSlots, _, TIMER_FLAG_NO_MAPCHANGE); }
public Action:Timer_ManageSlots(Handle:timer) { Now_ManageSlots(); return Plugin_Stop; }
public ReadyUp_TrueDisconnect(client) { Now_ManageSlots(); }

public ReadyUp_IsClientLoaded(client) {

	Now_ManageSlots();
	new count = 0;
	for (new i = 1; i <= MaxClients; i++) {

		if (IsLegitimateClient(i) && !IsFakeClient(i) && GetClientTeam(i) != TEAM_SPECTATOR && i != client) count++;
	}
	LogMessage("Count: %d Max Allowed (With Spectators): %d", count, i_PlayerSlots + GetSpectatorCount());
	if (count >= i_PlayerSlots + GetSpectatorCount()) {

		decl String:text[64];
		if (!IsReserve(client)) {

			Format(text, sizeof(text), "%T", "reservation kick", client);
			LogMessage("Kicked %N [NO AVAILABLE PLAYER SLOTS FOR UNRESERVED PLAYERS]", client);
			KickClient(client, "%s", text);
			ReadyUp_NtvEntryDenied();

			return;
		}
		else {

			if (KickableClient(client) < 1) {

				// No available clients to remove.
				Format(text, sizeof(text), "%T", "no reservation available", client);
				LogMessage("Kicked %N [NO UNRESERVED PLAYERS TO REMOVE FOR THIS RESERVED PLAYER]", client);
				KickClient(client, "%s", text);
				ReadyUp_NtvEntryDenied();

				return;
			}
			else {

				new target = -1;
				new bool:b_SlotAvailable = false;
				while (target == -1 && KickableClient(client) > 0 && count + 1 >= i_PlayerSlots) {

					target = GetRandomInt(1, MaxClients);
					if (IsLegitimateClient(target) && !IsFakeClient(target) && !IsReserve(target)) {

						Format(text, sizeof(text), "%T", "reservation fill", target);
						LogMessage("Kicked %N [REMOVED TO ALLOW RESERVED PLAYER %N TO ENTER THE GAME]", target, client);
						KickClient(target, "%s", text);

						count--;

						b_SlotAvailable = true;
					}
					else target = -1;
				}
				if (!b_SlotAvailable) {

					Format(text, sizeof(text), "%T", "no reservation available", client);
					LogMessage("KICKED %N [NO UNRESERVED PLAYERS TO REMOVE FOR THIS RESERVED PLAYER]", client);
					KickClient(client, "%s", text);
					ReadyUp_NtvEntryDenied();

					return;
				}
			}
		}
		if (count < i_PlayerSlots) {

			ReadyUp_NtvEntryAllowed(client);
		}
	}
}

stock KickableClient(client) {

	new count = 0;
	for (new i = 1; i <= MaxClients; i++) {

		if (IsLegitimateClient(i) && !IsFakeClient(i) && !IsReserve(i) && i != client) count++;
	}
	return count;
}

stock GetSpectatorCount() {

	new count = 0;
	for (new i = 1; i <= MaxClients; i++) {

		if (IsLegitimateClient(i) && !IsFakeClient(i) && GetClientTeam(i) == TEAM_SPECTATOR) count++;
	}
	return count;
}

stock bool:IsReserve(client) {

	if (HasCommandAccessEx(client, "z") || HasCommandAccessEx(client, "a")) return true;
	return false;
}

stock bool:IsLegitimateClient(client) {

	if (client < 1 || client > MaxClients || !IsClientConnected(client) || !IsClientInGame(client)) return false;
	return true;
}

public Now_ManageSlots() {

	SetConVarInt(FindConVar("sv_maxplayers"), i_PlayerSlots + i_ReserveSlots + GetSpectatorCount());
	SetConVarInt(FindConVar("sv_visiblemaxplayers"), i_PlayerSlots + i_ReserveSlots + GetSpectatorCount());
	if (i_SurvivorSlots < 0 || i_InfectedSlots < 0) {

		SetConVarBounds(FindConVar("z_max_player_zombies"), ConVarBound_Upper, true, (i_PlayerSlots / 2) * 1.0);
		SetConVarInt(FindConVar("z_max_player_zombies"), i_PlayerSlots / 2);
		SetConVarBounds(FindConVar("survivor_limit"), ConVarBound_Upper, true, (i_PlayerSlots / 2) * 1.0);
		SetConVarInt(FindConVar("survivor_limit"), i_PlayerSlots / 2);
	}
	else {

		SetConVarBounds(FindConVar("z_max_player_zombies"), ConVarBound_Upper, true, i_InfectedSlots * 1.0);
		SetConVarInt(FindConVar("z_max_player_zombies"), i_InfectedSlots);
		SetConVarBounds(FindConVar("survivor_limit"), ConVarBound_Upper, true, i_SurvivorSlots * 1.0);
		SetConVarInt(FindConVar("survivor_limit"), i_SurvivorSlots);
	}
	ReadyUp_SlotChangeSuccess();
}