#define			TEAM_SPECTATOR							1
#define			TEAM_SURVIVOR							2
#define			TEAM_INFECTED							3
#define			MAX_ENTITIES							2048
#define			PLUGIN_VERSION							"1.15 hc"
#define			PLUGIN_CONTACT							"skylorekatja@gmail.com"
#define			PLUGIN_NAME								"[RUM][Server Mgmt] Player Plus 2"
#define			PLUGIN_DESCRIPTION						"Handles bot creation in coop and versus"
#define			CVAR_SHOW								FCVAR_NOTIFY | FCVAR_PLUGIN

#include		<sourcemod>
#include		<sdktools>
#include		"wrap.inc"

#undef			REQUIRE_PLUGIN
#include		"readyup.inc"

public Plugin:myinfo = { name = PLUGIN_NAME, author = PLUGIN_CONTACT, description = PLUGIN_DESCRIPTION, version = PLUGIN_VERSION, url = PLUGIN_CONTACT };

new Handle:g_sGameConf									= INVALID_HANDLE;
new Handle:hSetHumanSpec								= INVALID_HANDLE;
new Handle:hTakeOverBot									= INVALID_HANDLE;
new Handle:hRoundRespawn								= INVALID_HANDLE;

new String:white[4];
new String:green[4];
new String:blue[4];
new String:orange[4];

public OnPluginStart()
{
	CreateConVar("rum_playerplus2", PLUGIN_VERSION, "version header", CVAR_SHOW);
	SetConVarString(FindConVar("rum_playerplus2"), PLUGIN_VERSION);

	LoadTranslations("rum_playerplus.phrases");

	g_sGameConf = LoadGameConfigFile("rum_playerplus");
	if (g_sGameConf != INVALID_HANDLE)
	{
		StartPrepSDKCall(SDKCall_Player);
		PrepSDKCall_SetFromConf(g_sGameConf, SDKConf_Signature, "SetHumanSpec");
		PrepSDKCall_AddParameter(SDKType_CBasePlayer, SDKPass_Pointer);
		hSetHumanSpec = EndPrepSDKCall();
	
		StartPrepSDKCall(SDKCall_Player);
		PrepSDKCall_SetFromConf(g_sGameConf, SDKConf_Signature, "TakeOverBot");
		PrepSDKCall_AddParameter(SDKType_Bool, SDKPass_Plain);
		hTakeOverBot = EndPrepSDKCall();

		StartPrepSDKCall(SDKCall_Player);
		PrepSDKCall_SetFromConf(g_sGameConf, SDKConf_Signature, "RoundRespawn");
		hRoundRespawn = EndPrepSDKCall();
	}
	else SetFailState("File not found: .../gamedata/rum_playerplus.txt");

	Format(white, sizeof(white), "\x01");
	Format(orange, sizeof(orange), "\x04");
	Format(green, sizeof(green), "\x05");
	Format(blue, sizeof(blue), "\x03");

	AddCommandListener(Cmd_JoinTeam, "jointeam");
}

public Action:Cmd_JoinTeam(client, String:command[], argc) {

	decl String:a_temp[32];
	GetCmdArg(1, a_temp, sizeof(a_temp));
	if ((StrEqual(a_temp, "Survivor") || StringToInt(a_temp) == TEAM_SURVIVOR) && GetClientTeam(client) != TEAM_SURVIVOR) ChangeTeamSurvivor(client);
	else if (ReadyUp_GetGameMode() == 2 && ((StrEqual(a_temp, "Infected") || StringToInt(a_temp) == TEAM_INFECTED) && GetClientTeam(client) != TEAM_INFECTED)) ChangeClientTeam(client, TEAM_INFECTED);
	else if (StrEqual(a_temp, "Spectator") || StringToInt(a_temp) == TEAM_SPECTATOR) ChangeClientTeam(client, TEAM_SPECTATOR);
	if (StringToInt(a_temp) != TEAM_SURVIVOR) KickSurvivorBots();

	return Plugin_Handled;
}

public ReadyUp_FwdChangeTeam(client, team) {

	decl String:Name[64];
	GetClientName(client, Name, sizeof(Name));

	if (team == TEAM_SPECTATOR) {

		PrintToChatAll("%t", "Change Team Spectator", green, Name, white, green);
		ChangeClientTeam(client, TEAM_SPECTATOR);
	}
	else if (team == TEAM_SURVIVOR) {

		PrintToChatAll("%t", "Change Team Survivor", green, Name, white, blue);
		ChangeTeamSurvivor(client);
	}
	else if (team == TEAM_INFECTED) {

		PrintToChatAll("%t", "Change Team Infected", green, Name, white, orange);
		ChangeClientTeam(client, TEAM_INFECTED);
	}
	//if (team != TEAM_SURVIVOR) KickSurvivorBots();
	CreateTimer(0.1, Timer_KickSurvivorBots, _, TIMER_FLAG_NO_MAPCHANGE);
}

public ReadyUp_TrueDisconnect(client) {

	//if (GetClientTeam(client) == TEAM_SURVIVOR) KickSurvivorBots();
	CreateTimer(0.1, Timer_KickSurvivorBots, _, TIMER_FLAG_NO_MAPCHANGE);
}

public Action:Timer_KickSurvivorBots(Handle:timer) { KickSurvivorBots(); return Plugin_Stop; }
public ReadyUp_CheckpointDoorStartOpened() {

	for (new i = 1; i <= MaxClients; i++) {


		if (IsClientInGame(i) && GetClientTeam(i) == TEAM_SURVIVOR && !IsPlayerAlive(i)) {

			SDKCall(hRoundRespawn, i);
		}
	}

	KickSurvivorBots();
	GiveMedKits();
	
}
public ReadyUp_ReadyUpStart() { KickSurvivorBots(); }

public GiveMedKits() {

	for (new i = 1; i <= MaxClients; i++) {

		if (IsClientInGame(i) && !IsFakeClient(i) && GetClientTeam(i) == TEAM_SURVIVOR && GetPlayerWeaponSlot(i, 3) == -1) ExecCheatCommand(i, "give", "first_aid_kit");
	}
}

public KickSurvivorBots() {

	/*if (TotalHumanCount() > 0 && (TotalSurvivorCount() < 4 || TotalHumanSurvivorCount() < 4)) {

		if (TotalSurvivorCount() < 4) {

			CreateSurvivorBot();
		}
		return;
	}*/
	for (new i = 1; i <= MaxClients; i++) {

		if (IsClientBot(i) && GetClientTeam(i) == TEAM_SURVIVOR) KickClient(i);
	}
}

public TotalHumanSurvivorCount() {

	new Count = 0;
	for (new i = 1; i <= MaxClients; i++) {

		if (IsClientInGame(i) && !IsFakeClient(i) && GetClientTeam(i) == TEAM_SURVIVOR) Count++;
	}
	return Count;
}

public TotalHumanCount() {

	new Count = 0;
	for (new i = 1; i <= MaxClients; i++) {

		if (IsClientInGame(i) && !IsFakeClient(i)) Count++;
	}
	return Count;
}

public TotalSurvivorCount() {

	new Count = 0;
	for (new i = 1; i <= MaxClients; i++) {

		if (IsClientInGame(i) && GetClientTeam(i) == TEAM_SURVIVOR) Count++;
	}
	return Count;
}

public CreateSurvivorBot() {

	new survivorBot									= CreateFakeClient("Survivor Bot");
	if (survivorBot != 0) {

		ChangeClientTeam(survivorBot, TEAM_SURVIVOR);
		if (DispatchKeyValue(survivorBot, "classname", "survivorbot") && DispatchSpawn(survivorBot)) {

			//SDKCall(hRoundRespawn, survivorBot);

			new Float:Pos[3];

			if (IsPlayerAlive(survivorBot)) {

				for (new i = 1; i <= MaxClients; i++) {

					if (IsClientInGame(i) && GetClientTeam(i) == TEAM_SURVIVOR && i != survivorBot) {

						GetClientAbsOrigin(i, Pos);
						TeleportEntity(survivorBot, Pos, NULL_VECTOR, NULL_VECTOR);
						break;
					}
				}
			}
			if (IsClientActual(survivorBot) && GetClientTeam(survivorBot) == TEAM_SURVIVOR) KickClient(survivorBot);
		}
	}
}

public ChangeTeamSurvivor(client) {

	new survivor										= FindSurvivorBot();

	if (survivor == 0) {

		new survivorBot									= CreateFakeClient("Survivor Bot");
		if (survivorBot != 0) {

			ChangeClientTeam(survivorBot, TEAM_SURVIVOR);
			if (DispatchKeyValue(survivorBot, "classname", "survivorbot") && DispatchSpawn(survivorBot)) {

				//SDKCall(hRoundRespawn, survivorBot);

				new Float:Pos[3];

				if (IsPlayerAlive(survivorBot)) {

					for (new i = 1; i <= MaxClients; i++) {

						if (IsClientInGame(i) && GetClientTeam(i) == TEAM_SURVIVOR && i != survivorBot) {

							GetClientAbsOrigin(i, Pos);
							TeleportEntity(survivorBot, Pos, NULL_VECTOR, NULL_VECTOR);
							break;
						}
					}
				}
				if (IsClientActual(survivorBot) && GetClientTeam(survivorBot) == TEAM_SURVIVOR) KickClient(survivorBot);

				if (client > 0 && IsClientInGame(client)) CreateTimer(1.0, Timer_ChangeTeamSurvivor, client, TIMER_FLAG_NO_MAPCHANGE);
				else KickSurvivorBots();
			}
		}
	}
	else if (IsClientInGame(survivor)) {

		SDKCall(hSetHumanSpec, survivor, client);
		SDKCall(hTakeOverBot, client, true);

		KickSurvivorBots();
	}
}

public Action:Timer_ChangeTeamSurvivor(Handle:timer, any:client) {

	if (client > 0 && IsClientInGame(client) && !IsFakeClient(client)) {

		ChangeTeamSurvivor(client);
	}

	return Plugin_Stop;
}

public FindSurvivorBot() {

	//new owner = 0;

	for (new i = 1; i <= MaxClients; i++) {

		if (IsClientConnected(i) && IsClientActual(i) && IsClientInGame(i) && GetClientTeam(i) == TEAM_SURVIVOR && IsFakeClient(i)) {
		
			// This is so that we don't identify a bot that currently has a player assigned to them
			// like a player who is "away from keyboard"
			//owner = GetEntProp(i, Prop_Send, "m_hOwnerEntity");
			//LogMessage("owner is %N", owner);
			//if (IsClientConnected(owner) && IsClientActual(owner) && !IsFakeClient(owner)) continue;
			
			return i;
		}
	}

	return 0;
}
