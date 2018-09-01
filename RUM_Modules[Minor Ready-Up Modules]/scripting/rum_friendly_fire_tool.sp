#define MAX_ENTITIES		2048

#define PLUGIN_VERSION		"1.5"
#define PLUGIN_CONTACT		"skyyplugins@gmail.com"

#define PLUGIN_NAME			"[RUM][Player Management] Robust Friendly-Fire Management Tool"
#define PLUGIN_DESCRIPTION	"A very robust friendly-fire tool that punishes the wicked and rewards the good."
#define CONFIG				"friendly_fire_tool.cfg"
#define CVAR_SHOW			FCVAR_NOTIFY | FCVAR_PLUGIN

#include <sourcemod>
#include <sdktools>
#include "wrap.inc"
#include "l4d_stocks.inc"
#undef REQUIRE_PLUGIN
#include "readyup.inc"

public Plugin:myinfo = {
	name = PLUGIN_NAME,
	author = PLUGIN_CONTACT,
	description = PLUGIN_DESCRIPTION,
	version = PLUGIN_VERSION,
	url = PLUGIN_CONTACT,
};

new bool:IsRoundLive;
new String:white[4];
new String:blue[4];
new String:orange[4];
new String:green[4];
new String:s_rup[32];

new Float:PerpetratorReflectValue;
new Float:VictimDamageValue;
new FriendlyFireBaseLimit;
new RoundDecay;
new PunishmentDecay;
new PunishmentSlayCount;
new PunishmentBanLength;
new DamageDecay;
new FriendlyFireCeilLimit;
new PlayerIncapTime;
new PlayerHealingTime;

new HealingAmount[MAXPLAYERS + 1];
new DamageAmount[MAXPLAYERS + 1];
new Punishments[MAXPLAYERS + 1];
new PunishmentDecayTime[MAXPLAYERS + 1];
new IncapPenalty[MAXPLAYERS + 1];
new HealPenalty[MAXPLAYERS + 1];
new Handle:hDatabase = INVALID_HANDLE;

public OnPluginStart()
{
	CreateConVar("rum_locksaferoom", PLUGIN_VERSION, "version header", CVAR_SHOW);
	SetConVarString(FindConVar("rum_locksaferoom"), PLUGIN_VERSION);

	Format(white, sizeof(white), "\x01");
	Format(blue, sizeof(blue), "\x03");
	Format(orange, sizeof(orange), "\x04");
	Format(green, sizeof(green), "\x05");

	LoadTranslations("rum_friendly_fire_tool.phrases");

	HookEvent("player_hurt", Event_PlayerHurt);
	HookEvent("player_incapacitated", Event_PlayerIncapacitated);

	RegConsoleCmd("ffdata", CMD_FFData);
}

public OnConfigsExecuted() {

	SQL_TConnect(DBConnect, "friendlyfire");
	CreateTimer(0.1, Timer_ExecuteConfig, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
}

public Action:CMD_FFData(client, args) { SendPanelToClientAndClose(FFMenu(client), client, FFHandle, MENU_TIME_FOREVER); }

public Handle:FFMenu(client) {

	new Handle:menu = CreatePanel();
	decl String:text[512];

	Format(text, sizeof(text), "%T", "limit threshold", client, AddCommasToString(DamageAmount[client]), AddCommasToString(GetThreshold(client)));
	DrawPanelText(menu, text);
	Format(text, sizeof(text), "%T", "punishment counter", client, Punishments[client]);
	DrawPanelText(menu, text);
	Format(text, sizeof(text), "%T", "slay and ban counter", client, PunishmentSlayCount);
	DrawPanelText(menu, text);

	Format(text, sizeof(text), "%T", "close menu", client);
	DrawPanelItem(menu, text);

	return menu;
}

public FFHandle(Handle:topmenu, MenuAction:action, client, param2) {

	if (action == MenuAction_Select) {

		switch (param2) {

			case 1:
			{
				SendPanelToClientAndClose(FFMenu(client), client, FFHandle, 1);
			}
		}
	}
	if (topmenu != INVALID_HANDLE) {

		CloseHandle(topmenu);
	}
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

	decl String:s_key[512];
	decl String:s_value[512];

	new a_Size						= GetArraySize(key);

	for (new i = 0; i < a_Size; i++) {

		GetArrayString(Handle:key, i, s_key, sizeof(s_key));
		GetArrayString(Handle:value, i, s_value, sizeof(s_value));
		
		if (StrEqual(s_key, "perpetrator reflect value?")) PerpetratorReflectValue			= StringToFloat(s_value);
		else if (StrEqual(s_key, "victim damage value?")) VictimDamageValue					= StringToFloat(s_value);
		else if (StrEqual(s_key, "friendly fire starting limit?")) FriendlyFireBaseLimit	= StringToInt(s_value);
		else if (StrEqual(s_key, "friendly fire damage decay per round?")) RoundDecay		= StringToInt(s_value);
		else if (StrEqual(s_key, "punishment decay time?")) PunishmentDecay					= StringToInt(s_value);
		else if (StrEqual(s_key, "slay punishment up to?")) PunishmentSlayCount				= StringToInt(s_value);
		else if (StrEqual(s_key, "ban length?")) PunishmentBanLength						= StringToInt(s_value);
		else if (StrEqual(s_key, "damage decay per punishment?")) DamageDecay				= StringToInt(s_value);
		else if (StrEqual(s_key, "friendly fire maximum limit?")) FriendlyFireCeilLimit		= StringToInt(s_value);
		else if (StrEqual(s_key, "incapacitating teammate penalty?")) PlayerIncapTime		= StringToInt(s_value);
		else if (StrEqual(s_key, "healing teammate penalty?")) PlayerHealingTime			= StringToInt(s_value);
	}

	ReadyUp_NtvGetHeader();
}

stock LoadData(client) {

	HealingAmount[client]			= 0;
	DamageAmount[client]			= 0;
	Punishments[client]				= 0;
	PunishmentDecayTime[client]		= 0;
	IncapPenalty[client]			= 0;
	HealPenalty[client]				= 0;

	decl String:key[64];
	decl String:tquery[512];
	GetClientAuthString(client, key, sizeof(key));

	Format(tquery, sizeof(tquery), "SELECT `h`, `d`, `p`, `u`, `i`, `e` FROM `friendlyfire` WHERE (`steam_id` = '%s');", key);
	SQL_TQuery(hDatabase, QueryResults_Load, tquery, client);
}

stock CreateNewData(client) {

	decl String:tquery[512];
	decl String:key[64];
	GetClientAuthString(client, key, sizeof(key));
	Format(tquery, sizeof(tquery), "INSERT INTO `friendlyfire` (`steam_id`, `h`, `d`, `p`, `u`, `i`, `e`) VALUES ('%s', '%d', '%d', '%d', '%d', '%d', '%d');", key, HealingAmount[client], DamageAmount[client], Punishments[client], PunishmentDecayTime[client], IncapPenalty[client], HealPenalty[client]);
	SQL_TQuery(hDatabase, QueryResults, tquery, client);
}

stock SaveData(client) {

	decl String:tquery[512];
	decl String:key[64];
	GetClientAuthString(client, key, sizeof(key));

	Format(tquery, sizeof(tquery), "UPDATE `friendlyfire` SET `h` = '%d', `d` = '%d', `p` = '%d', `u` = '%d', `i` = '%d', `e` = '%d' WHERE `steam_id` = '%s';", HealingAmount[client], DamageAmount[client], Punishments[client], PunishmentDecayTime[client], IncapPenalty[client], HealPenalty[client], key);
	SQL_TQuery(hDatabase, QueryResults, tquery, client);
}

public QueryResults(Handle:owner, Handle:hndl, const String:error[], any:client) { }

public QueryResults_Load(Handle:owner, Handle:hndl, const String:error[], any:client) {

	if (hndl != INVALID_HANDLE) {

		decl String:text[64];
		new bool:bIsDataFound	= false;
		if (!IsClientActual(client) || !IsClientInGame(client)) return;
		while (SQL_FetchRow(hndl)) {

			bIsDataFound = true;

			SQL_FetchString(hndl, 0, text, sizeof(text));
			HealingAmount[client]			= StringToInt(text);
			SQL_FetchString(hndl, 1, text, sizeof(text));
			DamageAmount[client]			= StringToInt(text);
			SQL_FetchString(hndl, 2, text, sizeof(text));
			Punishments[client]				= StringToInt(text);
			SQL_FetchString(hndl, 3, text, sizeof(text));
			PunishmentDecayTime[client]		= StringToInt(text);
			SQL_FetchString(hndl, 4, text, sizeof(text));
			IncapPenalty[client]			= StringToInt(text);
			SQL_FetchString(hndl, 5, text, sizeof(text));
			HealPenalty[client]				= StringToInt(text);
		}
		if (!bIsDataFound) {

			CreateNewData(client);
		}
	}
}

public DBConnect(Handle:owner, Handle:hndl, const String:error[], any:data) {

	if (hndl == INVALID_HANDLE) {

		SetFailState("Unable to connect to database with error: %s", error);
		return;
	}

	hDatabase = hndl;

	SQL_FastQuery(hDatabase, "SET NAMES \"UTF8\"");
	decl String:tquery[512];

	Format(tquery, sizeof(tquery), "CREATE TABLE IF NOT EXISTS `friendlyfire` (`steam_id` varchar(32) NOT NULL, PRIMARY KEY (`steam_id`)) ENGINE=MyISAM;");
	SQL_TQuery(hDatabase, QueryResults, tquery);
	Format(tquery, sizeof(tquery), "ALTER TABLE `friendlyfire` ADD `h` int(32) NOT NULL DEFAULT '0';");
	SQL_TQuery(hDatabase, QueryResults, tquery);
	Format(tquery, sizeof(tquery), "ALTER TABLE `friendlyfire` ADD `d` int(32) NOT NULL DEFAULT '0';");
	SQL_TQuery(hDatabase, QueryResults, tquery);
	Format(tquery, sizeof(tquery), "ALTER TABLE `friendlyfire` ADD `p` int(32) NOT NULL DEFAULT '0';");
	SQL_TQuery(hDatabase, QueryResults, tquery);
	Format(tquery, sizeof(tquery), "ALTER TABLE `friendlyfire` ADD `u` int(32) NOT NULL DEFAULT '0';");
	SQL_TQuery(hDatabase, QueryResults, tquery);
	Format(tquery, sizeof(tquery), "ALTER TABLE `friendlyfire` ADD `i` int(32) NOT NULL DEFAULT '0';");
	SQL_TQuery(hDatabase, QueryResults, tquery);
	Format(tquery, sizeof(tquery), "ALTER TABLE `friendlyfire` ADD `e` int(32) NOT NULL DEFAULT '0';");
	SQL_TQuery(hDatabase, QueryResults, tquery);
}

stock bool:IsLimitExceeded(client) {


	// The "Limit" is The Total healing a player has EVER made, or the Base Limit, whichever is greater.
	// This system rewards players who help teammates, by raising their allowed friendly-fire amount.

	if (DamageAmount[client] >= GetThreshold(client)) return true;
	return false;
}

stock GetThreshold(client) {

	if (HealingAmount[client] > FriendlyFireCeilLimit) HealingAmount[client] = FriendlyFireCeilLimit;
	new Threshold		= HealingAmount[client];
	if (Threshold < FriendlyFireBaseLimit) Threshold = FriendlyFireBaseLimit;
	return Threshold;
}

public Action:Timer_PunishmentDecay(Handle:timer) {

	if (!IsRoundLive) return Plugin_Stop;

	for (new i = 1; i <= MaxClients; i++) {

		if (IsClientInGame(i) && !IsFakeClient(i) && Punishments[i] > 0) {

			if (PunishmentDecayTime[i] <= GetTime()) {

				Punishments[i]--;
				if (Punishments[i] > 0) PunishmentDecayTime[i] = GetTime() + PunishmentDecay;
			}
		}
	}

	return Plugin_Continue;
}

stock PunishmentAction(client) {

	Punishments[client]++;
	PunishmentDecayTime[client] = GetTime() + PunishmentDecay;
	DamageAmount[client] -= DamageDecay;
	if (DamageAmount[client] < 0) DamageAmount[client] = 0;

	decl String:Name[64];
	GetClientName(client, Name, sizeof(Name));
	if (Punishments[client] <= PunishmentSlayCount) {

		ForcePlayerSuicide(client);
		PrintToChatAll("%t", "client punishment (slay)", green, Name, white, orange);
	}
	else {

		decl String:BanReason[64];
		Format(BanReason, sizeof(BanReason), "Excessive Friendly-Fire (%d Violations)", Punishments[client]);

		new BanTime			= Punishments[client] * PunishmentBanLength;
		new Minutes			= 0;
		while (BanTime >= 60) {

			BanTime			-= 60;
			Minutes++;
		}
		BanTime				= Minutes;

		PunishmentDecayTime[client] = GetTime() + ((Punishments[client] * PunishmentBanLength) * 2);
		SaveData(client);
		
		BanClient(client, BanTime, BANFLAG_AUTHID, BanReason, BanReason);
	}
}

public ReadyUp_FwdGetHeader(const String:header[]) {

	strcopy(s_rup, sizeof(s_rup), header);
}

public ReadyUp_CheckpointDoorStartOpened() {

	IsRoundLive = true;
	CreateTimer(1.0, Timer_PunishmentDecay, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
	PrintToChatAll("%t", "friendly fire tool running", orange, white, green, white);
}

public ReadyUp_RoundIsOver() {

	IsRoundLive = false;

	for (new i = 1; i <= MaxClients; i++) {

		if (IsLegitimateClient(i) && !IsFakeClient(i)) {

			DamageAmount[i]									-= RoundDecay;
			if (DamageAmount[i] < 0) DamageAmount[i]		= 0;

			SaveData(i);
		}
	}
}

public Action:Event_PlayerIncapacitated(Handle:event, String:event_name[], bool:dontBroadcast) {

	new perpetrator		= GetClientOfUserId(GetEventInt(event, "attacker"));
	new victim			= GetClientOfUserId(GetEventInt(event, "userid"));

	if (IsLegitimateClientAlive(perpetrator) && IsLegitimateClientAlive(victim)) {

		// Incapacitating a teammate places the player on a penalty period, where they cannot earn healing points.
		// It also resets their healing points to 0.
		HealingAmount[perpetrator]	= 0;
		IncapPenalty[perpetrator]	= GetTime() + PlayerIncapTime;
	}
}

public Action:Event_PlayerHurt(Handle:event, String:event_name[], bool:dontBroadcast) {

	new perpetrator		= GetClientOfUserId(GetEventInt(event, "attacker"));
	new victim			= GetClientOfUserId(GetEventInt(event, "userid"));

	if (IsLegitimateClientAlive(perpetrator) &&
		IsLegitimateClientAlive(victim) &&
		!IsFakeClient(perpetrator) &&
		!IsFakeClient(victim) &&
		!IsIncapacitated(perpetrator) &&
		!IsIncapacitated(victim) &&
		GetClientTeam(perpetrator) == GetClientTeam(victim)) {

		new DamageValue	= GetEventInt(event, "dmg_health");
		if (!IsRoundLive) {			// Friendly fire is reflected during the warm-up period.

			SetEntityHealth(victim, GetClientHealth(victim) + DamageValue);
			return;
		}
	}
}

stock bool:EnemiesWithinRange(client) {

	new Float:Pos1[3];
	new Float:Pos2[3];

	GetClientAbsOrigin(client, Pos1);
	for (new i = 1; i <= MaxClients; i++) {

		if (IsLegitimateClientAlive(i) && GetClientTeam(i) != GetClientTeam(client)) {

			GetClientAbsOrigin(i, Pos2);
			if (GetVectorDistance(Pos1, Pos2) <= 128.0) return true;
		}
	}
	return false;
}

public ReadyUp_FwdFriendlyFire(perpetrator, victim, amount, victimhealth, isfire, bonusDamage) {

	if (!IsRoundLive) return;
	if (IsLegitimateClientAlive(perpetrator) &&
		IsLegitimateClientAlive(victim) &&
		!IsFakeClient(perpetrator) &&
		!IsFakeClient(victim) &&
		!IsIncapacitated(perpetrator) &&
		!IsIncapacitated(victim) &&
		GetClientTeam(perpetrator) == GetClientTeam(victim) &&
		L4D2_GetInfectedAttacker(perpetrator) == -1 &&
		L4D2_GetInfectedAttacker(victim) == -1) {

		new Float:Pos1[3];
		new Float:Pos2[3];
		GetClientAbsOrigin(perpetrator, Pos1);
		GetClientAbsOrigin(victim, Pos2);
		if ((GetVectorDistance(Pos1, Pos2) <= 128.0 || EnemiesWithinRange(victim)) && amount > 0) {

			if (isfire == 0) {

				if (victimhealth + amount > GetClientHealth(victim)) SetEntityHealth(victim, victimhealth + amount);
			}
			//SetEntityHealth(victim, GetClientHealth(victim) + amount);
			return;	// No friendly-fire if players are very close (or on top of each other)
		}

		new PerpetratorReflectDamage		= 0;
		new VictimReflectDamage				= 0;

		if (amount < 0) {

			if (IncapPenalty[perpetrator] > GetTime() || HealPenalty[perpetrator] > GetTime()) return;	// Players can't receive healing bonuses for the duration of their incap penalty time

			HealPenalty[perpetrator] = GetTime() + PlayerHealingTime;	// To prevent players from heal/revive spamming teammates, they only receive healing points every so often for doing it.
			HealingAmount[perpetrator] -= amount;	// we subtract because subtracting a negative number is also addition. (OOP)
			DamageAmount[perpetrator] += amount;
			if (DamageAmount[perpetrator] < 0) DamageAmount[perpetrator] = 0;
		}
		else {

			amount						+= bonusDamage;

			DamageAmount[perpetrator]	+= amount;
			if (HealingAmount[perpetrator] - DamageAmount[perpetrator] > 0) HealingAmount[perpetrator] -= DamageAmount[perpetrator];
			else HealingAmount[perpetrator] = 0;

			if (PerpetratorReflectValue >= 0.0) {

				if (PerpetratorReflectValue > 0.0) PerpetratorReflectDamage = RoundToCeil(amount * PerpetratorReflectValue);
				else PerpetratorReflectDamage								= amount;
				if (PerpetratorReflectDamage < GetClientHealth(perpetrator)) SetEntityHealth(perpetrator, GetClientHealth(perpetrator) - PerpetratorReflectDamage);
			}
			if (VictimDamageValue >= 0.0) {

				if (VictimDamageValue > 0.0) VictimReflectDamage			= RoundToCeil(amount * VictimDamageValue);
				else VictimReflectDamage									= amount;
				if (VictimReflectDamage < GetClientHealth(victim)) SetEntityHealth(victim, GetClientHealth(victim) - VictimReflectDamage);
			}

			if (IsLimitExceeded(perpetrator)) PunishmentAction(perpetrator);
		}
	}
}

public ReadyUp_IsClientLoaded(client) {

	LoadData(client);
}

public ReadyUp_TrueDisconnect(client) {

	SaveData(client);
}

stock bool:IsLegitimateClient(client) {

	if (client < 1 || client > MaxClients || !IsClientConnected(client) || !IsClientInGame(client)) return false;
	return true;
}

stock bool:IsLegitimateClientAlive(client) {

	if (IsLegitimateClient(client) && IsPlayerAlive(client)) return true;
	return false;
}

stock SendPanelToClientAndClose(Handle:panel, client, MenuHandler:handler, time) {

	SendPanelToClient(panel, client, handler, time);
	CloseHandle(panel);
}

stock String:AddCommasToString(value) 
{
	new String:buffer[128];
	new String:separator[1];
	separator = ",";
	buffer[0] = '\0'; 
	new divisor = 1000; 
	
	while (value >= 1000 || value <= -1000)
	{
		new offcut = value % divisor;
		value = RoundToFloor(float(value) / float(divisor));
		Format(buffer, sizeof(buffer), "%s%03.d%s", separator, offcut, buffer); 
	}
	
	Format(buffer, sizeof(buffer), "%d%s", value, buffer);
	return buffer;
}