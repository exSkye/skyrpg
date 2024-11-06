stock bool ArrayContains(Handle array, char[] val) {
	int size = GetArraySize(array);
	for (int i = 0; i < size; i++) {
		char text[64];
		GetArrayString(array, i, text, 64);
		if (StrEqual(val, text)) return true;
	}
	return false;
}

stock void SetSurvivorsAliveHostname() {
	static char Newhost[64];
	Format(Newhost, sizeof(Newhost), "%s", Hostname);
	if (b_IsActiveRound) Format(Newhost, sizeof(Newhost), "%s(%d alive)", Hostname, LivingSurvivors());
	ServerCommand("hostname %s", Newhost);
}

stock ResetArray(Handle TheArray) {
	ClearArray(TheArray);
}

stock RefreshSurvivorBots() {
	for (int i = 1; i <= MaxClients; i++) {
		if (IsLegitimateClient(i) && IsFakeClient(i)) RefreshSurvivor(i);
	}
}

stock ChallengeEverything(client) {
	TotalTalentPoints[client]							=	0;
	UpgradesAvailable[client]							=	0;
	FreeUpgrades[client]								=	MaximumPlayerUpgrades(client);
	PlayerUpgradesTotal[client] = 0;
	WipeTalentPoints(client);
}

stock SetClientMovementSpeed(client) {
	if (IsValidEntity(client)) SetEntPropFloat(client, Prop_Send, "m_flLaggedMovementValue", fBaseMovementSpeed);
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

stock ResetCoveredInBile(client) {
	for (int i = 1; i <= MaxClients; i++) {
		if (IsLegitimateClient(i)) {
			CoveredInBile[client][i] = -1;
			CoveredInBile[i][client] = -1;
		}
	}
}

stock bool AnyHumans() {
	for (int i = 1; i <= MaxClients; i++) {
		if (IsLegitimateClient(i) && !IsFakeClient(i)) return true;
	}
	return false;
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
	if (!IsEnrageNotified) {
		CreateTimer(fEnrageHordeBoostDelay, Timer_EnrageHordeBoostDelay, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
		CreateTimer(fEnrageDamageIncreaseDelay, Timer_EnrageDamageIncreaseDelay, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);

		IsEnrageNotified = true;
		if (iNotifyEnrage == 1) PrintToChatAll("%t", "enrage period", orange, blue, orange);
	}
	return true;
}

stock MySurvivorCompanion(client) {
	char SteamId[64];
	char CompanionSteamId[64];
	GetClientAuthId(client, AuthId_Steam2, SteamId, sizeof(SteamId));
	for (int i = 1; i <= MaxClients; i++) {

		if (IsLegitimateClient(i) && myCurrentTeam[i] == TEAM_SURVIVOR && IsFakeClient(i)) {

			GetEntPropString(i, Prop_Data, "m_iName", CompanionSteamId, sizeof(CompanionSteamId));
			if (StrEqual(CompanionSteamId, SteamId, false)) return i;
		}
	}
	return -1;
}

stock CheckGamemode() {
	char TheGamemode[64];
	GetConVarString(g_Gamemode, TheGamemode, sizeof(TheGamemode));
	char TheRequiredGamemode[64];
	GetConfigValue(TheRequiredGamemode, sizeof(TheRequiredGamemode), "gametype?");
	LogMessage("Game mode is %s , required game mode is %s", TheGamemode, TheRequiredGamemode);

	if (!StrEqual(TheRequiredGamemode, "-1") && !StrEqual(TheGamemode, TheRequiredGamemode, false)) {
		LogMessage("Gamemode did not match, changing to %s", TheRequiredGamemode);
		SetConVarString(g_Gamemode, TheRequiredGamemode);
		char TheMapname[64];
		GetCurrentMap(TheMapname, sizeof(TheMapname));
		ServerCommand("changelevel %s", TheMapname);
	}
}

/* put the line below after all of the includes!
#pragma newdecls required
*/

/*
 *	Provides a shortcut method to calling ANY value from keys found in CONFIGS/READYUP/RPG/CONFIG.CFG
 *	@return		-1		if the requested key could not be found.
 *	@return		value	if the requested key is found.
 */
stock void GetConfigValue(char[] TheString, int TheSize, char[] KeyName, char[] sDefaultVal = "-1") {
	static char text[512];
	int a_Size			= GetArraySize(MainKeys);
	for (int i = 0; i < a_Size; i++) {

		GetArrayString(MainKeys, i, text, sizeof(text));

		if (StrEqual(text, KeyName)) {

			GetArrayString(MainValues, i, TheString, TheSize);
			return;
		}
	}
	Format(TheString, TheSize, "%s", sDefaultVal);
}

stock float GetConfigValueFloat(char[] KeyName, float fDefaultVal = -1.0) {
	
	static char text[512];

	int a_Size			= GetArraySize(MainKeys);

	for (int i = 0; i < a_Size; i++) {

		GetArrayString(MainKeys, i, text, sizeof(text));

		if (StrEqual(text, KeyName)) {

			GetArrayString(MainValues, i, text, sizeof(text));
			return StringToFloat(text);
		}
	}
	return fDefaultVal;
}

stock int GetConfigValueInt(char[] KeyName, int defaultValue = -1) {
	
	static char text[512];

	int a_Size			= GetArraySize(MainKeys);

	for (int i = 0; i < a_Size; i++) {

		GetArrayString(MainKeys, i, text, sizeof(text));

		if (StrEqual(text, KeyName)) {

			GetArrayString(MainValues, i, text, sizeof(text));
			return StringToInt(text);
		}
	}
	return defaultValue;
}

/*
 *	Checks if any survivors are incapacitated.
 *	@return		true/false		depending on the result.
 */
stock bool AnySurvivorsIncapacitated() {

	for (int i = 1; i <= MaxClients; i++) {

		if (IsClientInGame(i) && myCurrentTeam[i] == TEAM_SURVIVOR && IsIncapacitated(i)) return true;
	}
	return false;
}

/*
 *	Checks if there are any non-bot, non-spectator players in the game.
 *	@return		true/false		depending on the result.
 */
stock bool IsPlayersParticipating() {

	for (int i = 1; i <= MaxClients; i++) {

		if (IsLegitimateClient(i) && !IsFakeClient(i) && myCurrentTeam[i] != TEAM_SPECTATOR) return true;
	}
	return false;
}

stock int GetAnyPlayerNotMe(int client) {
	for (int i = 1; i <= MaxClients; i++) {
		if (i == client || !IsLegitimateClient(i)) continue;
		return i;
	}
	return -1;
}

stock int FindAnyClient() {
	for (int i = 1; i <= MaxClients; i++) {
		if (!IsLegitimateClient(i)) continue;
		return i;
	}
	return -1;
}

/*
 *	Finds a random, non-infected client in-game.
 *	@return		client index if found.
 *	@return		-1 if not found.
 */
stock int FindAnyRandomClient(bool bMustBeAlive = false, int ignoreclient = 0) {

	for (int i = 1; i <= MaxClients; i++) {

		if (IsLegitimateClient(i) && myCurrentTeam[i] == TEAM_SURVIVOR && !IsLedged(i) && (GetEntityFlags(i) & FL_ONGROUND) && i != ignoreclient) {

			if (bMustBeAlive && IsPlayerAlive(i) || !bMustBeAlive) return i;
		}
	}
	return -1;
}

stock bool IsMeleeWeaponParameter(char[] parameter) {

	if (StrEqual(parameter, "fireaxe", false) ||
		StrEqual(parameter, "cricket_bat", false) ||
		StrEqual(parameter, "tonfa", false) ||
		StrEqual(parameter, "frying_pan", false) ||
		StrEqual(parameter, "golfclub", false) ||
		StrEqual(parameter, "electric_guitar", false) ||
		StrEqual(parameter, "katana", false) ||
		StrEqual(parameter, "machete", false) ||
		StrEqual(parameter, "crowbar", false)) return true;
	return false;
}

/*
 *	Checks to see if the client has an active experience booster.
 *	If the client does, ExperienceValue is multiplied against the booster value and returned.
 *	@return (ExperienceValue * Multiplier)		where Multiplier is modified based on the result of AddMultiplier(client, i)
 */
stock float CheckExperienceBooster(int client, int ExperienceValue) {

	// Return ExperienceValue as it is if the client doesn't have a booster active.
	char key[64];
	char value[64];

	float Multiplier					= 0.0;	// 1.0 is the DEFAULT (Meaning NO CHANGE)

	int size								= GetArraySize(a_Store);
	int size2								= 0;
	for (int i = 0; i < size; i++) {

		StoreKeys[client]					= GetArrayCell(a_Store, i, 0);
		StoreValues[client]					= GetArrayCell(a_Store, i, 1);

		size2								= GetArraySize(StoreKeys[client]);
		for (int ii = 0; ii < size2; ii++) {

			GetArrayString(StoreKeys[client], ii, key, sizeof(key));
			GetArrayString(StoreValues[client], ii, value, sizeof(value));

			if (StrEqual(key, "item effect?") && StrEqual(value, "x")) {

				Multiplier += AddMultiplier(client, i);		// If the client has no time in it, it just adds 0.0.
			}
		}
	}

	return Multiplier;
}

/*
 *	Checks to see whether:
 *	a.) The position in the store is an experience booster
 *	b.) If it is, if the client has time remaining in it.
 *	@return		Float:value			time remaining on experience booster. 0.0 if it could not be found.
 */
stock float AddMultiplier(int client, int pos) {

	if (!IsLegitimateClient(client) || pos >= GetArraySize(a_Store_Player[client])) return 0.0;
	char ClientValue[64];
	GetArrayString(a_Store_Player[client], pos, ClientValue, sizeof(ClientValue));

	char key[64];
	char value[64];

	if (StringToInt(ClientValue) > 0) {

		StoreMultiplierKeys[client]			= GetArrayCell(a_Store, pos, 0);
		StoreMultiplierValues[client]		= GetArrayCell(a_Store, pos, 1);

		int size							= GetArraySize(StoreMultiplierKeys[client]);
		for (int i = 0; i < size; i++) {

			GetArrayString(StoreMultiplierKeys[client], i, key, sizeof(key));
			GetArrayString(StoreMultiplierValues[client], i, value, sizeof(value));

			if (StrEqual(key, "item strength?")) return StringToFloat(value);
		}
	}

	return 0.0;		// It wasn't found, so no multiplier is added.
}

stock void GetMeleeWeapon(int client, char[] Weapon, int size) {
	int g_iActiveWeaponOffset = 0;
	int iWeapon = 0;
	GetClientWeapon(client, Weapon, size);
	if (StrEqual(Weapon, "weapon_melee", false)) {
		g_iActiveWeaponOffset = FindSendPropInfo("CTerrorPlayer", "m_hActiveWeapon");
		iWeapon = GetEntDataEnt2(client, g_iActiveWeaponOffset);
		GetEntityClassname(iWeapon, Weapon, size);
		GetEntPropString(iWeapon, Prop_Data, "m_strMapSetScriptName", Weapon, size);
	}
	else Format(Weapon, size, "null");
}

// we format the string for the name of the target, but we also send back an int result to let the code know
// how to interpret the results (and what information to show on the weapons page of the character sheet)
stock int DataScreenTargetName(int client, char[] stringRef, int size) {
	//char text[64];
	float TargetPos[3];
	char hitgroup[4];
	int target = GetAimTargetPosition(client, TargetPos, hitgroup, 4);
	//GetClientAimTargetEx(client, text, sizeof(text), true);
	//new target = StringToInt(text);
	if (target == -1) return -1;
	else {
		if (IsLegitimateClient(target)) {
			GetClientName(target, stringRef, size);
			return 4;
		}
		else if (IsWitch(target)) {
			Format(stringRef, size, "%T", "witch aim target", client);
			return 3;
		}
		else if (IsSpecialCommon(target)) {
			Format(stringRef, size, "%T", "special common aim target", client);
			return 2;
		}
		else {
			Format(stringRef, size, "%T", "common aim target", client);
			return 1;
		}
	}
}

stock int DataScreenWeaponDamage(int client, bool isHealing = false) {
	float TargetPos[3];
	int hitgroup = -1;
	char hitspot[4];
	int target = GetAimTargetPosition(client, TargetPos, hitspot, 4);
	if (strlen(hitspot) > 0) hitgroup = StringToInt(hitspot);
	return GetBaseWeaponDamage(client, target, TargetPos[0], TargetPos[1], TargetPos[2], DMG_BULLET, _, true, hitgroup, isHealing);
}

stock bool IsSurvivor(int client) {

	if (IsLegitimateClient(client) && myCurrentTeam[client] == TEAM_SURVIVOR) return true;
	return false;
}

stock bool IsFireDamage(int damagetype) {

	if (damagetype == 8 || damagetype == 2056 || damagetype == 268435464) return true;
	return false;
}

stock void GetSurvivorBotName(int client, char[] TheBuffer, int TheSize) {

	char TheModel[64];
	GetClientModel(client, TheModel, sizeof(TheModel));	// helms deep creates bots that aren't necessarily on the survivor team.
		
	if (StrEqual(TheModel, NICK_MODEL)) Format(TheBuffer, TheSize, "Nick");
	else if (StrEqual(TheModel, ROCHELLE_MODEL)) Format(TheBuffer, TheSize, "Rochelle");
	else if (StrEqual(TheModel, COACH_MODEL)) Format(TheBuffer, TheSize, "Coach");
	else if (StrEqual(TheModel, ELLIS_MODEL)) Format(TheBuffer, TheSize, "Ellis");
	else if (StrEqual(TheModel, LOUIS_MODEL)) Format(TheBuffer, TheSize, "Louis");
	else if (StrEqual(TheModel, ZOEY_MODEL)) Format(TheBuffer, TheSize, "Zoey");
	else if (StrEqual(TheModel, BILL_MODEL)) Format(TheBuffer, TheSize, "Bill");
	else if (StrEqual(TheModel, FRANCIS_MODEL)) Format(TheBuffer, TheSize, "Francis");
}

stock void ForceLoadDefaultProfiles(int loadtarget) {
	if (!IsLegitimateClient(loadtarget)) return;
	if (myCurrentTeam[loadtarget] == TEAM_SURVIVOR) {
		if (IsFakeClient(loadtarget)) {
			SetTotalExperienceByLevel(loadtarget, iBotPlayerStartingLevel);
			LoadProfileEx(loadtarget, DefaultBotProfileName);
		}
		else {
			SetTotalExperienceByLevel(loadtarget, iPlayerStartingLevel);
			LoadProfileEx(loadtarget, DefaultProfileName);
		}
	}
	else LoadProfileEx(loadtarget, DefaultInfectedProfileName);
	return;
}

stock bool IsSurvivorPlayer(int client) {

	if (IsLegitimateClient(client) && myCurrentTeam[client] == TEAM_SURVIVOR) return true;
	return false;
}

stock bool CommonInfectedModel(int ent, char[] SearchKey) {

	char ModelName[64];
 	GetEntPropString(ent, Prop_Data, "m_ModelName", ModelName, sizeof(ModelName));
 	if (StrContains(ModelName, SearchKey, false) != -1) return true;
 	return false;
}

stock bool CommonInfectedModelEx(int ent, char[] SearchKey, int searchPos) {

	char ModelName[64];
 	GetEntPropString(ent, Prop_Data, "m_ModelName", ModelName, sizeof(ModelName));
	int equalAtPos = (searchPos >= 0) ? searchPos : strlen(ModelName)-searchPos;
 	if (StrEqualAtPos(ModelName, SearchKey, equalAtPos)) return true;
 	return false;
}

stock int GetSurvivorsInRange(int client, float Distance) {

	float cpos[3];
	float spos[3];
	int count = 0;
	GetClientAbsOrigin(client, cpos);

	for (int i = 1; i <= MaxClients; i++) {

		if (!IsLegitimateClientAlive(i) || myCurrentTeam[i] != TEAM_SURVIVOR) continue;
		GetClientAbsOrigin(i, spos);
		if (GetVectorDistance(cpos, spos) <= Distance) count++;
	}
	return count;
}

stock bool SurvivorsWithinRange(int client, float Distance) {

	float cpos[3];
	float spos[3];
	GetClientAbsOrigin(client, cpos);

	for (int i = 1; i <= MaxClients; i++) {

		if (!IsLegitimateClientAlive(i) || myCurrentTeam[i] != TEAM_SURVIVOR) continue;
		GetClientAbsOrigin(i, spos);
		if (GetVectorDistance(cpos, spos) <= Distance) return true;
	}
	return false;
}

stock int DoesClientHaveTheHighGround(float cpos[3], int target) {
	float tpos[3];
	GetEntPropVector(target, Prop_Send, "m_vecOrigin", tpos);
	if (cpos[2] > tpos[2]) return 1;	// client is above target
	if (cpos[2] < tpos[2]) return -1;	// client is below target
	return 0;							// client and target are on same level.
}

stock float GetTargetRange(int client, int target) {
	float cpos[3];
	float tpos[3];
	GetEntPropVector(client, Prop_Send, "m_vecOrigin", cpos);
	GetEntPropVector(target, Prop_Send, "m_vecOrigin", tpos);

	return GetVectorDistance(cpos, tpos);
}

stock bool IsClientInRange(int client, int target, float range) {

	float cpos[3];
	float tpos[3];
	GetEntPropVector(client, Prop_Send, "m_vecOrigin", cpos);
	GetEntPropVector(target, Prop_Send, "m_vecOrigin", tpos);

	if (GetVectorDistance(cpos, tpos) <= range) return true;
	return false;
}

stock bool CheckTankState(int client, char[] StateName) {

	char text[64];
	for (int i = 0; i < GetArraySize(TankState_Array[client]); i++) {

		GetArrayString(TankState_Array[client], i, text, sizeof(text));
		if (StrEqual(text, StateName)) return true;	
	}
	//if (GetArraySize(TankState_Array[client]))
	return false;
}

stock int ChangeTankState(int client, char[] StateName, bool IsDelete = false, bool GetState = false) {

	if (!b_IsActiveRound) return -1;
	if (!IsLegitimateClientAlive(client) || FindZombieClass(client) != ZOMBIECLASS_TANK) return -3;

	char text[64];
	int size = GetArraySize(TankState_Array[client]);

	char sCurState[64];
	if (size > 0) GetArrayString(TankState_Array[client], 0, sCurState, sizeof(sCurState));

	if (GetState || IsDelete) {

		//if (size < 1 && IsDelete) return 0;
		if (size < 1) return 0;
		if (StrEqual(text, StateName)) {

			if (!IsDelete) return 1;
			ClearArray(TankState_Array[client]);
			return -1;
		}
	}
	else {

		if (iTanksPreset == 0 && size > 0 && !StrEqual(sCurState, StateName) || size < 1) {

			if (size > 0) SetArrayString(TankState_Array[client], 0, StateName);
			else PushArrayString(TankState_Array[client], StateName);

			if (iTanksPreset == 1) {

				char sTank[64];
				Format(sTank, sizeof(sTank), "tank spawn:%s", StateName);
				char sText[64];
				for (int i = 1; i <= MaxClients; i++) {
					if (!IsLegitimateClient(i) || IsFakeClient(i)) continue;
					Format(sText, sizeof(sText), "%T", sTank, i);
					PrintToChat(i, "%T", "tank spawn notification", i, orange, sText, white, blue);
				}
			}

			if (StrEqual(StateName, "hulk")) {
				SetSpeedMultiplierBase(client, fTankMovementSpeed_Hulk);
				SetEntityRenderMode(client, RENDER_TRANSCOLOR);
				SetEntityRenderColor(client, 0, 255, 0, 255);
			}
			else if (StrEqual(StateName, "death")) {

				//ClearArray(Handle:TankState_Array[client]);	// you who walks through the valley of death loses everything.
				SetSpeedMultiplierBase(client, fTankMovementSpeed_Death);
				SetEntityRenderMode(client, RENDER_TRANSCOLOR);
				SetEntityRenderColor(client, 0, 0, 0, 255);
			}
			else if (StrEqual(StateName, "burn")) {
				SetSpeedMultiplierBase(client, fTankMovementSpeed_Burning);
				SetEntityRenderMode(client, RENDER_TRANSCOLOR);
				SetEntityRenderColor(client, 255, 0, 0, 200);
			}
			else if (StrEqual(StateName, "teleporter")) {

				SetEntityRenderMode(client, RENDER_TRANSCOLOR);
				SetEntityRenderColor(client, 50, 50, 255, 200);

				if (b_IsActiveRound) FindRandomSurvivorClient(client, true);
			}
		}
		return 2;
	}
	return -2;
}

stock int FindClientOnSurvivorTeam() {
	for (int i = 1; i <= MaxClients; i++) {
		if (!IsLegitimateClient(i) || myCurrentTeam[i] != TEAM_SURVIVOR) continue;
		return i;
	}
	return 0;
}

stock void FindRandomSurvivorClient(int client, bool bIsTeleportTo = false, bool bPrioritizeTanks = true) {

	if (!IsLegitimateClientAlive(client) || !b_IsActiveRound) return;

	ClearArray(RandomSurvivorClient);
	//char ClassRoles[64];
	for (int i = 1; i <= MaxClients; i++) {

		if (IsLegitimateClientAlive(i) && myCurrentTeam[i] == TEAM_SURVIVOR) {

			if (client == i) continue;
			PushArrayCell(RandomSurvivorClient, i);
		}
	}
	if (bPrioritizeTanks && GetArraySize(RandomSurvivorClient) < 1) {

		//if (TotalHumanSurvivors() >= 4)
		FindRandomSurvivorClient(client, bIsTeleportTo, false);	// now all clients are viable.
		return;
	}
	int size = GetArraySize(RandomSurvivorClient);
	if (size < 1) return;

	int target = GetRandomInt(1, size);
	target = GetArrayCell(RandomSurvivorClient, target - 1);

	float Origin[3];
	GetClientAbsOrigin(target, Origin);
	/*char text[64];
	GetClientAimTargetEx(target, text, sizeof(text));

	char aimtarget[3][64];
	ExplodeString(text, " ", aimtarget, 3, 64);

	new Float:Origin[3];
	Origin[0] = StringToFloat(aimtarget[0]);
	Origin[1] = StringToFloat(aimtarget[1]);
	Origin[2] = StringToFloat(aimtarget[2]);*/
	TeleportEntity(client, Origin, NULL_VECTOR, NULL_VECTOR);
	/*if (myCurrentTeam[client] == TEAM_SURVIVOR && bRushingNotified[client]) {

		bRushingNotified[client] = false;
	}*/
	if (myCurrentTeam[client] == TEAM_INFECTED) bHasTeleported[client] = true;
}

/*bool:AnySurvivorInRange(client, Float:Range) {

	for (new i = 1; i <= MaxClients; i++) {

		if (!IsLegitimateClientAlive(i) || myCurrentTeam[i] != TEAM_SURVIVOR || IsFakeClient(i)) continue;
		if (IsClientInRange(client, i, Range)) return true;
	}
	return false;
}*/

stock void CheckTankSubroutine(int tank, int survivor = 0, int damage = 0, bool TankIsVictim = false) {

	if (iRPGMode == -1) return;
	if (!IsLegitimateClientAlive(tank) || FindZombieClass(tank) != ZOMBIECLASS_TANK) return;	

	//if (IsSurvivalMode) return;

	int DeathState		= ChangeTankState(tank, "death", _, true);

	if (DeathState != 1 && (IsSpecialCommonInRange(tank, 'w') || IsClientInRangeSpecialAmmo(tank, "W") > 0.0)) {

		//ChangeTankState(client, "hulk", true);
		ChangeTankState(tank, "death");
	}
	int tankFlags = GetEntityFlags(tank);

	//if (survivor == 0 && damage == 0 && !(GetEntityFlags(tank) & FL_ONFIRE) && !SurvivorsInRange(tank)) ChangeTankState(tank, "teleporter");

	//new TankEnrageMechanic			= GetConfigValueInt("boss tank enrage count?");
	//new Float:TankTeleportMechanic	= GetConfigValueFloat("boss tank teleport distance?");

	if (tankFlags & FL_INWATER) {

		ChangeTankState(tank, "burn", true);
	}
	//bool IsDeath = false;

	//new DeathState		= ChangeTankState(tank, "death", _, true);
	int BurnState		= ChangeTankState(tank, "burn", _, true);
	//bool IsOnFire = false;
	if ((tankFlags & FL_ONFIRE) && BurnState != 1) {

		ExtinguishEntity(tank);
	}
	bool IsBiled	= IsCoveredInBile(tank);
	int IsHulkState		= ChangeTankState(tank, "hulk", _, true);

	if (bIsDefenderTank[tank] || DeathState == 1) {
		SetSpeedMultiplierBase(tank, fTankMovementSpeed_Death);
		SetEntityRenderMode(tank, RENDER_TRANSCOLOR);
		if (bIsDefenderTank[tank]) SetEntityRenderColor(tank, 0, 0, 255, 255);
		else SetEntityRenderColor(tank, 0, 0, 0, 150);
	}
	else if (IsHulkState == 1) {
		SetSpeedMultiplierBase(tank, fTankMovementSpeed_Hulk);

		SetEntityRenderMode(tank, RENDER_TRANSCOLOR);
		SetEntityRenderColor(tank, 0, 255, 0, 200);
	}
	else if (BurnState == 1) {

		SetSpeedMultiplierBase(tank, fTankMovementSpeed_Burning);

		SetEntityRenderMode(tank, RENDER_TRANSCOLOR);
		SetEntityRenderColor(tank, 255, 0, 0, 200);
		if (!(tankFlags & FL_ONFIRE)) IgniteEntity(tank, 3.0);
	}
	if (BurnState != 1) ExtinguishEntity(tank);
	/*if (BurnState) {

		SetSpeedMultiplierBase(tank, 1.0);
		ChangeTankState(tank, "hulk", true);
		IsHulkState = 0;
		SetEntityRenderMode(tank, RENDER_TRANSCOLOR);
		SetEntityRenderColor(tank, 255, 0, 0, 255);
	}*/
	bool IsLegitimateClientSurvivor = IsLegitimateClient(survivor);
	int survivorTeam = -1;
	if (IsLegitimateClientSurvivor) survivorTeam = myCurrentTeam[survivor];
	if (survivor == 0 || !IsLegitimateClientSurvivor || survivorTeam != TEAM_SURVIVOR) return;

	//char ClassRoles[64];

	//new Float:IsSurvivorWeak = IsClientInRangeSpecialAmmo(survivor, "W");
	//new Float:IsSurvivorReflect = 0.0;
	bool IsSurvivorBiled = false;
	if (!TankIsVictim) {

		if (BurnState == 1) {

			int Count = GetClientStatusEffect(survivor, STATUS_EFFECT_BURN);

			if (!IsSurvivorBiled && Count < iDebuffLimit) {

				//if (IsSurvivorReflect) CreateAndAttachFlame(tank, RoundToCeil(damage * 0.1), 10.0, 1.0, survivor, "burn");
				//else
				Count++;
				CreateAndAttachFlame(survivor, RoundToCeil((damage * fBurnPercentage) / Count), fDoTMaxTime, fDoTInterval, tank, STATUS_EFFECT_BURN);
			}
		}
		if (DeathState == 0) ChangeTankState(tank, "hulk");
		else if (IsHulkState == 1) ChangeTankState(tank, "death");
		else if (DeathState == 1) {

			int SurvivorHealth = GetClientTotalHealth(survivor);

			int SurvivorHalfHealth = SurvivorHealth / 2;
			if (SurvivorHalfHealth / GetMaximumHealth(survivor) > 0.25) {

				SetClientTotalHealth(tank, survivor, SurvivorHalfHealth);
				AddSpecialInfectedDamage(survivor, tank, SurvivorHalfHealth, CONTRIBUTION_AWARD_TANKING);
			}
		}
		else if (IsHulkState == 1) {

			CreateExplosion(survivor, damage, tank, true);
		}
	}
	else {

		if (IsBiled) {

			if (BurnState == 1) ChangeTankState(tank, "hulk");
			if (!ISBILED[survivor]) {
				SDKCall(g_hCallVomitOnPlayer, survivor, tank, true);
				CreateTimer(15.0, Timer_RemoveBileStatus, survivor, TIMER_FLAG_NO_MAPCHANGE);
				ISBILED[survivor] = true;
			}
		}
	}
}

public Action Hook_SetTransmit(entity, client) {
	
	if(EntIndexToEntRef(entity) == eBackpack[client]) return Plugin_Handled;
	return Plugin_Continue;
}

// returning plugin stop in here actually prevents you from switching weapons... great for if fatigued.
public Action OnWeaponSwitch(client, weapon) {
	if (IsLegitimateClient(client) && myCurrentTeam[client] == TEAM_SURVIVOR) {
		CreateTimer(0.2, Timer_SetMyWeapons, client, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
	}
	return Plugin_Continue;
}

void EnforceCurrentWeaponAmmoCapacity(int client) {
// If reserves remaining > maximum reserves, set reserves remaining = maximum reserves
	if (GetWeaponResult(client, 3) > maximumReserves[client]) {
		GetWeaponResult(client, 5, maximumReserves[client]);
	}
}

public Action Timer_SetMyWeapons(Handle timer, any client) {
	if (IsLegitimateClient(client)) {
		if (!IsClientInGame(client)) return Plugin_Continue;
		SetMyWeapons(client);
		maximumReserves[client] = GetWeaponResult(client, 2);
		EnforceCurrentWeaponAmmoCapacity(client);
	}
	return Plugin_Stop;
}

public Action OnTraceAttack(victim, &attacker, &inflictor, float &damage, &damagetype, &ammotype, hitbox, hitgroup) {
	if (IsLegitimateClient(attacker) && myCurrentTeam[attacker] == TEAM_SURVIVOR) {
		takeDamageEvent[attacker][0] = ammotype;

		myLastHitbox[attacker] = takeDamageEvent[attacker][1];
		takeDamageEvent[attacker][1] = hitgroup;
	}
	return Plugin_Continue;
}

/*
 *
 * IfCommonInfectedIsAttackerDoStuff(attacker, victim, damagetype, survivorCount)
 * 
 */
stock int IfCommonInfectedIsAttackerDoStuff(attacker, victim, damagetype, survivorCount) {
	char stringRef[64];
	int CommonsDamage = GetCharacterSheetData(victim, stringRef, 64, 2, _, attacker);//GetInfectedData(victim, attacker, true);
	int i_CommonsDamageIncreaseFromBuffer = getDamageIncreaseFromBuffer(attacker, CommonsDamage);
	if (i_CommonsDamageIncreaseFromBuffer > 0) CommonsDamage += i_CommonsDamageIncreaseFromBuffer;
	float ammoStr = 0.0;
	int maxIncomingDamageAllowed = GetMaximumHealth(victim);
	if (CommonsDamage > maxIncomingDamageAllowed) CommonsDamage = maxIncomingDamageAllowed;
	GetAbilityStrengthByTrigger(victim, attacker, TRIGGER_L, _, CommonsDamage, _, _, _, _, _, _, _, _, damagetype);
	if (!(damagetype & DMG_DIRECT)) {
		if (b_IsJumping[victim]) ModifyGravity(victim);
		float fCommonDirectorAward = (fCommonDirectorPoints * CommonsDamage);
		if (!IsSurvivalMode && iEnrageTime > 0 && RPGRoundTime() >= iEnrageTime) fCommonDirectorAward *= fEnrageDirectorPoints;
		if (fCommonDirectorAward > 0.0) Points_Director += fCommonDirectorAward;
		GetAbilityStrengthByTrigger(victim, attacker, TRIGGER_Y, _, CommonsDamage);
		SetClientTotalHealth(attacker, victim, CommonsDamage);
		ReceiveCommonDamage(victim, attacker, CommonsDamage);
	}
	char TheCommonValue[64];
	bool attackerIsSpecial = IsSpecialCommon(attacker);
	int entityPos = (attackerIsSpecial) ? FindListPositionByEntity(attacker, CommonAffixes) : -1;
	int superPos = (attackerIsSpecial) ? GetArrayCell(CommonAffixes, entityPos, 1) : -1;
	if (attackerIsSpecial) {
		char slevelrequired[10];
		GetCommonValueAtPosEx(slevelrequired, sizeof(slevelrequired), superPos, SUPER_COMMON_LEVEL_REQ);
		if (PlayerLevel[victim] >= StringToInt(slevelrequired)) {
			GetCommonValueAtPosEx(TheCommonValue, sizeof(TheCommonValue), superPos, SUPER_COMMON_AURA_EFFECT);

			// Flamers explode when they receive or take damage.
			if (StrEqual(TheCommonValue, "f", true)) CreateDamageStatusEffect(attacker, _, victim, CommonsDamage, _, _, superPos);
			else if (StrEqual(TheCommonValue, "a", true)) CreateBomberExplosion(attacker, victim, TheCommonValue, CommonsDamage, superPos);
			else if (StrEqual(TheCommonValue, "E", true)) {
				char deatheffectshappen[10];
				GetCommonValueAtPosEx(deatheffectshappen, sizeof(deatheffectshappen), superPos, SUPER_COMMON_DEATH_EFFECT);
				CreateDamageStatusEffect(attacker, _, victim, CommonsDamage, _, _, superPos);
				CreateBomberExplosion(attacker, victim, deatheffectshappen, _, superPos);
				ClearSpecialCommon(attacker, _, CommonsDamage, victim, entityPos);
			}
		}
	}
	int BuffDamage = 0;
	ammoStr = IsClientInRangeSpecialAmmo(victim, "R", _, _, CommonsDamage);
	if (ammoStr > 0.0) BuffDamage = RoundToCeil(CommonsDamage * ammoStr);
	if (BuffDamage > 0) {
		if (!attackerIsSpecial) AddCommonInfectedDamage(victim, attacker, BuffDamage);
		else {
			GetCommonValueAtPosEx(TheCommonValue, sizeof(TheCommonValue), superPos, SUPER_COMMON_AURA_EFFECT);
			if (!StrEqual(TheCommonValue, "d", true)) AddSpecialCommonDamage(victim, attacker, BuffDamage);
			else {	// if a player tries to reflect damage at a reflector, it's moot (ie reflects back to the player) so in this case the player takes double damage, though that's after mitigations.
				SetClientTotalHealth(attacker, victim, BuffDamage);
				ReceiveCommonDamage(victim, attacker, BuffDamage);
			}
		}
	}
	if (IsSpecialCommonInRange(attacker, 'f')) DoBurn(attacker, victim, CommonsDamage);
	int damageToReturn = (BuffDamage > 0) ? BuffDamage : CommonsDamage;
	TankingContribution[victim] += RoundToCeil(damageToReturn * SurvivorExperienceMultTank);
	return damageToReturn;
}

stock int IfInfectedIsAttackerDoStuff(attacker, victim) {
	if (b_IsJumping[victim]) ModifyGravity(victim);
	int infectedZombieClass = FindZombieClass(attacker);
	char stringRef[64];
	int totalIncomingDamage = GetCharacterSheetData(victim, stringRef, 64, 6, infectedZombieClass, attacker);//GetInfectedData(victim, attacker, true);
	int i_totalIncomingDamageIncreaseFromBuffer = getDamageIncreaseFromBuffer(attacker, totalIncomingDamage);
	if (i_totalIncomingDamageIncreaseFromBuffer > 0) totalIncomingDamage += i_totalIncomingDamageIncreaseFromBuffer;
	if (totalIncomingDamage < 0) totalIncomingDamage = 0;
	int maxIncomingDamageAllowed = GetMaximumHealth(victim);
	if (totalIncomingDamage > maxIncomingDamageAllowed) totalIncomingDamage = maxIncomingDamageAllowed;
	GetAbilityStrengthByTrigger(attacker, victim, TRIGGER_D, _, totalIncomingDamage);
	GetAbilityStrengthByTrigger(victim, attacker, TRIGGER_L, _, totalIncomingDamage);
	SetClientTotalHealth(attacker, victim, totalIncomingDamage);
	AddSpecialInfectedDamage(victim, attacker, totalIncomingDamage, CONTRIBUTION_AWARD_TANKING);	// bool is tanking instead.
	if (infectedZombieClass == ZOMBIECLASS_TANK) CheckTankSubroutine(attacker, victim, totalIncomingDamage);
	DamageContribution[attacker] += totalIncomingDamage;
	bool bIsInfectedSwarm = false;

	char weapon[64];
	GetClientWeapon(attacker, weapon, sizeof(weapon));
	if (StrEqual(weapon, "insect_swarm")) bIsInfectedSwarm = true;
	int grabbedVictim = L4D2_GetSurvivorVictim(attacker);
	if (grabbedVictim != -1 && IsFakeClient(attacker)) GetAbilityStrengthByTrigger(attacker, grabbedVictim, TRIGGER_v, _, totalIncomingDamage);
	if (grabbedVictim == -1) GetAbilityStrengthByTrigger(attacker, victim, TRIGGER_claw, _, totalIncomingDamage);
	if (bIsInfectedSwarm) GetAbilityStrengthByTrigger(attacker, victim, TRIGGER_T, _, totalIncomingDamage);
	GetAbilityStrengthByTrigger(attacker, victim, TRIGGER_D, _, totalIncomingDamage);
	int ensnarer = L4D2_GetInfectedAttacker(victim);
	if (ensnarer == attacker) GetAbilityStrengthByTrigger(victim, attacker, TRIGGER_s, _, totalIncomingDamage);
	// If the infected player dealing the damage isn't the player hurting the victim, we give the victim a chance to strike at both! This is balance!
	if (attacker != ensnarer) GetAbilityStrengthByTrigger(victim, attacker, TRIGGER_V, _, totalIncomingDamage);
	if (ensnarer != -1) GetAbilityStrengthByTrigger(victim, ensnarer, TRIGGER_V, _, totalIncomingDamage);
	// TheAbilityMultiplier = GetAbilityStrengthByTrigger(victim, attacker, "lessTankyMoreHeals", _, totalIncomingDamage, _, _, "o", 2, true);
	// if (TheAbilityMultiplier > 0.0) totalIncomingDamage += RoundToCeil(totalIncomingDamage * TheAbilityMultiplier);
	int ReflectIncomingDamage = 0;
	float ammoStr = IsClientInRangeSpecialAmmo(victim, "R", _, _, totalIncomingDamage);
	if (!bIsInfectedSwarm && ammoStr > 0.0) ReflectIncomingDamage = RoundToCeil(totalIncomingDamage * ammoStr);
	if (ReflectIncomingDamage > 0) AddSpecialInfectedDamage(victim, attacker, ReflectIncomingDamage);
	if (IsSpecialCommonInRange(attacker, 'f')) DoBurn(attacker, victim, totalIncomingDamage);
	return totalIncomingDamage;
}

stock int IfSurvivorIsAttackerDoStuff(int attacker, int victim, int baseWeaponDamage, int damagetype, int victimType, int ammotype = -1, int hitgroup = -1, int inflictor = -1) {
						// 0 super, 1 common, 2 witch
	bool IsAttackerFake = IsFakeClient(attacker);
	LastWeaponDamage[attacker] = baseWeaponDamage;
	if (!IsAttackerFake && iDisplayHealthBars == 1) DisplayInfectedHealthBars(attacker, victim);
	if (LastAttackedUser[attacker] == victim) ConsecutiveHits[attacker]++;
	else {
		LastAttackedUser[attacker] = victim;
		ConsecutiveHits[attacker] = 0;
	}
	if (!IsAttackerFake && (damagetype & DMG_BULLET) && IsSpecialCommonInRange(attacker, 'd')) {
		SetClientTotalHealth(victim, attacker, getDamageIncreaseFromBuffer(attacker, baseWeaponDamage, "d"));
	}
	if (victimType <= 2) return TryToDamageNonPlayerInfected(attacker, victim, baseWeaponDamage, damagetype, ammotype, hitgroup);
	else if (victimType == 3) {
		if (TryToDamagePlayerInfected(attacker, victim, baseWeaponDamage, damagetype, ammotype, hitgroup) == -1) return -1;
	}
	return 0;
}

stock int TryToDamagePlayerInfected(attacker, victim, baseWeaponDamage, damagetype, ammotype = -1, hitgroup = -1) {
	if (L4D2_GetSurvivorVictim(victim) != -1) GetAbilityStrengthByTrigger(victim, attacker, TRIGGER_t, _, baseWeaponDamage, _, _, _, _, _, _, hitgroup, _, damagetype);
	int zombieclass = FindZombieClass(victim);
	bool fireDamage = IsFireDamage(damagetype);
	if ((fireDamage && iIsSpecialFire != 1 || (!hasMeleeWeaponEquipped[attacker] && zombieclass == ZOMBIECLASS_TANK && TankState[victim] == TANKSTATE_DEATH)) && IsPlayerAlive(victim)) return -1;
	if (fireDamage && zombieclass == ZOMBIECLASS_TANK && TankState[victim] == TANKSTATE_FIRE) return -1;

	if (fireDamage) {
		CreateAndAttachFlame(victim, baseWeaponDamage, 10.0, 0.5, attacker, STATUS_EFFECT_BURN);
	}
	else {
		GetAbilityStrengthByTrigger(attacker, victim, TRIGGER_D, _, baseWeaponDamage, _, _, _, _, _, _, hitgroup, _, damagetype);
		GetAbilityStrengthByTrigger(victim, attacker, TRIGGER_L, _, baseWeaponDamage, _, _, _, _, _, _, hitgroup, _, damagetype);
		AddSpecialInfectedDamage(attacker, victim, baseWeaponDamage, _, _, ammotype, hitgroup);
	}	
	if (zombieclass == ZOMBIECLASS_TANK) CheckTankSubroutine(victim, attacker, baseWeaponDamage, true);
	//}
	//CombatTime[attacker] = GetEngineTime() + fOutOfCombatTime;
	return -1;
}

stock int TryToDamageNonPlayerInfected(int attacker, int victim, int baseWeaponDamage, int damagetype, int ammotype = -1, int hitgroup = -1) {
	//bool isDifferentVictim = (LastAttackedUser[attacker] == victim) ? false : true;
	bool isVictimSpecial = IsSpecialCommon(victim);
	bool fireDamage = IsFireDamage(damagetype);

	if (!fireDamage) {
		GetAbilityStrengthByTrigger(attacker, victim, TRIGGER_D, _, baseWeaponDamage, _, _, _, _, _, _, hitgroup, _, damagetype);
	}
		//}
	if (IsWitch(victim)) {
		//if (FindListPositionByEntity(victim, Handle:WitchList) >= 0) {
		AddWitchDamage(attacker, victim, baseWeaponDamage, _, _, ammotype, hitgroup);
		//}
	}
	else if (isVictimSpecial) {
		if (!fireDamage) {
			if (AddSpecialCommonDamage(attacker, victim, baseWeaponDamage, _, _, ammotype, hitgroup) > 1) return baseWeaponDamage;
		}
		else CreateAndAttachFlame(victim, baseWeaponDamage, 10.0, 0.5, attacker, STATUS_EFFECT_BURN);
		if (CheckTeammateDamages(victim, attacker) < 1.0) {

			char TheCommonValue[10];
			int superPos = FindListPositionByEntity(victim, CommonAffixes, 1);
			if (superPos >= 0) {
				//superPos = GetArrayCell(CommonAffixes, superPos, 1);
				GetCommonValueAtPosEx(TheCommonValue, sizeof(TheCommonValue), superPos, SUPER_COMMON_DAMAGE_EFFECT);
				// The bomber explosion initially targets itself so that the chain-reaction (if enabled) doesn't go indefinitely.
				if (StrEqual(TheCommonValue, "f", true)) CreateDamageStatusEffect(victim, _, attacker, baseWeaponDamage, _, _, superPos);
				// Cannot trigger on survivor bots because they're frankly too stupid and it wouldn't be fair.
				else if (StrEqual(TheCommonValue, "d", true)) CreateDamageStatusEffect(victim, 3, attacker, baseWeaponDamage, _, _, superPos);		// attacker is not target but just used to pass for reference.
			}
		}
	}
	else if (IsCommonInfected(victim)) {
		if (!fireDamage) {
			if (AddCommonInfectedDamage(attacker, victim, baseWeaponDamage, _, damagetype, ammotype, hitgroup) > 1) return -2;
		}
		else CheckTeammateDamagesEx(attacker, victim, baseWeaponDamage, hitgroup, true, true);
	}
	//CombatTime[attacker] = GetEngineTime() + fOutOfCombatTime;
	//}
	return 1;
}

stock SpawnAnyInfected(client) {

	if (IsLegitimateClientAlive(client)) {

		char InfectedName[20];
		int rand = GetRandomInt(1,6);
		if (rand == 1) Format(InfectedName, sizeof(InfectedName), "smoker");
		else if (rand == 2) Format(InfectedName, sizeof(InfectedName), "boomer");
		else if (rand == 3) Format(InfectedName, sizeof(InfectedName), "hunter");
		else if (rand == 4) Format(InfectedName, sizeof(InfectedName), "spitter");
		else if (rand == 5) Format(InfectedName, sizeof(InfectedName), "jockey");
		else Format(InfectedName, sizeof(InfectedName), "charger");
		Format(InfectedName, sizeof(InfectedName), "%s auto", InfectedName);

		ExecCheatCommand(client, "z_spawn_old", InfectedName);
	}
}

stock GetInfectedCount(zombieclass = 0) {

	int count = 0;
	for (int i = 1; i <= MaxClients; i++) {

		if (IsLegitimateClientAlive(i) && myCurrentTeam[i] == TEAM_INFECTED && (zombieclass == 0 || FindZombieClass(i) == zombieclass)) count++;
	}
	return count;
}

stock CreateMyHealthPool(client, bool IMeanDeleteItInstead = false) {

	int whatami = 3;
	if (IsSpecialCommon(client)) {
		whatami = 1;
		if (IMeanDeleteItInstead) {
			ForceClearSpecialCommon(client);
			return;
		}
	}
	else if (IsWitch(client)) whatami = 2;
	else if (IsCommonInfected(client)) return;

	/*if (IsLegitimateClientAlive(client) && FindZombieClass(client) == ZOMBIECLASS_TANK && iTankRush == 1) {

		SetSpeedMultiplierBase(client, 1.0);
	}*/

	/*if (!b_IsFinaleActive && IsEnrageActive() && whatami == 3 && IsLegitimateClientAlive(client) && myCurrentTeam[client] == TEAM_INFECTED && FindZombieClass(client) == ZOMBIECLASS_TANK && !IsTyrantExist()) {

		IsTyrant[client] = true;
		SetEntityRenderMode(client, RENDER_TRANSCOLOR);
		SetEntityRenderColor(client, 0, 255, 0, 255);
	}
	else*/
	for (int i = 1; i <= MaxClients; i++) {
		if (!IsLegitimateClient(i)) continue;
		if (!IMeanDeleteItInstead) {
			if (!b_IsLoaded[i] || myCurrentTeam[i] != TEAM_SURVIVOR) continue;
			if (whatami == 1) AddSpecialCommonDamage(i, client, -1);
			else if (whatami == 2) AddWitchDamage(i, client, -1);
			else if (whatami == 3) AddSpecialInfectedDamage(i, client, -1);
			continue;
		}
		if (whatami == 1) AddSpecialCommonDamage(i, client, -2);
		else if (whatami == 2) AddWitchDamage(i, client, -2);
		else if (whatami == 3) AddSpecialInfectedDamage(i, client, -2);
	}
	return;
}

stock EnsnaredInfected() {

	int count = 0;
	for (int i = 1; i <= MaxClients; i++) {

		if (IsLegitimateClient(i) && IsFakeClient(i) && myCurrentTeam[i] == TEAM_INFECTED && IsEnsnarer(i)) count++;
	}
	return count;
}

stock bool IsEnsnarer(client, class = 0) {

	int zombieclass = class;
	if (class == 0) zombieclass = FindZombieClass(client);
	if (zombieclass == ZOMBIECLASS_HUNTER ||
		zombieclass == ZOMBIECLASS_SMOKER ||
		zombieclass == ZOMBIECLASS_JOCKEY ||
		zombieclass == ZOMBIECLASS_CHARGER) return true;
	return false;
}

/*bool:HasInstanceGenerated(client, target) {
	if (FindListPositionByEntity(target, InfectedHealth[client]) >= 0) return true;
	return false;
}*/

stock InitInfectedHealthForSurvivors(client) {
	for (int i = 1; i <= MaxClients; i++) {
		if (!IsLegitimateClient(i)) continue;
		AddSpecialInfectedDamage(i, client, -1);
	}
}

bool hasTargetHurtClient(client, target, type = 0) {
	int pos = (type == 0) ? FindListPositionByEntity(target, InfectedHealth[client]) :
			  (type == 1) ? FindListPositionByEntity(target, WitchDamage[client]) : -1;
	if (pos < 0) return false;
	if (type == 0 && GetArrayCell(InfectedHealth[client], pos, 3) > 0 || type == 1 && GetArrayCell(WitchDamage[client], pos, 3) > 0) return true;
	return false;
}

stock AddContributionToEngagedEnemiesOfAlly(int client, int teammate, int contributionType, int amount, int experienceTarget = -1) {
	if (contributionType != CONTRIBUTION_AWARD_BUFFING && contributionType != CONTRIBUTION_AWARD_HEALING) return;
	int clientTeam = myCurrentTeam[client];
	int reward = (IsFakeClient(teammate)) ? RoundToCeil(amount * fRewardPenaltyIfSurvivorBot) : amount;
	for (int i = (experienceTarget < 1) ? 1 : experienceTarget; i <= MaxClients; i++) {
		if (i == client || i == teammate || !IsLegitimateClient(i) || myCurrentTeam[i] == clientTeam || !IsPlayerAlive(i)) continue;
		int infectedLoggedPos = FindListPositionByEntity(i, InfectedHealth[teammate]);
		if (infectedLoggedPos < 0) continue;	// skip this SI if the teammate hasn't engaged them yet.
		int teammateDamageContribution = GetArrayCell(InfectedHealth[teammate], infectedLoggedPos, 2);
		int teammateTankingContribution = GetArrayCell(InfectedHealth[teammate], infectedLoggedPos, 3);
		if (teammateDamageContribution < 1 && teammateTankingContribution < 1) continue;
		AddSpecialInfectedDamage(client, i, reward, contributionType, _, _, _, false);
		if (experienceTarget != -1) break;
	}
}

stock AddSpecialInfectedDamage(client, target, TotalDamage = 0, int contributionType = 0, damagevariant = -1, ammotype = -1, hitgroup = -1, bool checkDamages = true) {
	if (!IsLegitimateClient(client)) return 0;
	int isEntityPos = FindListPositionByEntity(target, InfectedHealth[client]);
	//new f 0;
	if (isEntityPos >= 0 && TotalDamage <= -1) {
		// delete the mob.
		RemoveFromArray(InfectedHealth[client], isEntityPos);
		if (TotalDamage == -2) return 0;
		isEntityPos = -1;
	}
	int myzombieclass = FindZombieClass(target);
	if (myzombieclass < 1 || myzombieclass > 6 && myzombieclass != 8) return 0;
	if (isEntityPos < 0) {
		isEntityPos = GetArraySize(InfectedHealth[client]);
		//ResizeArray(InfectedHealth[client], isEntityPos + 1);
		PushArrayCell(InfectedHealth[client], target);
		//SetArrayCell(InfectedHealth[client], isEntityPos, target, 0);
		//An infected wasn't added on spawn to this player, so we add it now based on class.
		int t_InfectedHealth = (myzombieclass != ZOMBIECLASS_TANK) ? iBaseSpecialInfectedHealth[myzombieclass - 1] : iBaseSpecialInfectedHealth[myzombieclass - 2];
		OriginalHealth[target] = t_InfectedHealth;
		DefaultHealth[target] = t_InfectedHealth;
		GetAbilityStrengthByTrigger(target, _, TRIGGER_a, _, 0);
		//if (DefaultHealth[target] < OriginalHealth[target]) DefaultHealth[target] = OriginalHealth[target];
		char stringRef[64];
		SetArrayCell(InfectedHealth[client], isEntityPos, GetCharacterSheetData(client, stringRef, 64, 5, myzombieclass), 1);
		SetArrayCell(InfectedHealth[client], isEntityPos, 0, 2);	// damage contribution
		SetArrayCell(InfectedHealth[client], isEntityPos, 0, 3);	// tanking contribution
		SetArrayCell(InfectedHealth[client], isEntityPos, 0, 4);	// what are 4-6 used for?
		SetArrayCell(InfectedHealth[client], isEntityPos, 0, 7);	// buffing contribution
		SetArrayCell(InfectedHealth[client], isEntityPos, 0, 8);	// healing contribution
		// This slot is only for versus/human infected players; health remaining after "ARMOR" (global health) is gone.

		if (!bHealthIsSet[target]) {

			bHealthIsSet[target] = true;
			ResizeArray(InfectedHealth[target], GetArraySize(InfectedHealth[target]) + 1);
			SetArrayCell(InfectedHealth[target], 0, DefaultHealth[target], 5);
			SetArrayCell(InfectedHealth[target], 0, 0, 6);
			//SetArrayCell(Handle:InfectedHealth[client], isEntityPos, t_InfectedHealth, 5);
		}
	}
	if (TotalDamage < 1) return 0;

	int i_DamageBonus = TotalDamage;
	int i_InfectedMaxHealth = GetArrayCell(InfectedHealth[client], isEntityPos, 1);
	int i_InfectedCurrent = 0;
	if (contributionType == CONTRIBUTION_AWARD_DAMAGE) i_InfectedCurrent = GetArrayCell(InfectedHealth[client], isEntityPos, 2);
	else if (contributionType == CONTRIBUTION_AWARD_TANKING) i_InfectedCurrent = GetArrayCell(InfectedHealth[client], isEntityPos, 3);
	else if (contributionType == CONTRIBUTION_AWARD_BUFFING) i_InfectedCurrent = GetArrayCell(InfectedHealth[client], isEntityPos, 7);
	else if (contributionType == CONTRIBUTION_AWARD_HEALING) i_InfectedCurrent = GetArrayCell(InfectedHealth[client], isEntityPos, 8);
	if (i_InfectedCurrent < 0) i_InfectedCurrent = 0;
	//if (i_DamageBonus > TrueHealthRemaining) i_DamageBonus = TrueHealthRemaining;
	// damage
	if (contributionType == 0) {
		//int i_HealthRemaining = i_InfectedMaxHealth - i_InfectedCurrent;
		int i_HealthRemaining = RoundToCeil(i_InfectedMaxHealth * (1.0 - CheckTeammateDamages(target, client, _, true)));
		if (i_DamageBonus > i_HealthRemaining) i_DamageBonus = i_HealthRemaining;

		if (damagevariant != 2 && i_DamageBonus > 0) {
			GetProficiencyData(client, GetWeaponProficiencyType(client), RoundToCeil(i_DamageBonus * fProficiencyExperienceEarned));

			SetArrayCell(InfectedHealth[client], isEntityPos, i_InfectedCurrent + i_DamageBonus, 2);
			//RoundDamageTotal += (i_DamageBonus);
			RoundDamage[client] += (i_DamageBonus);
		}
		else {

			SetArrayCell(InfectedHealth[client], isEntityPos, i_InfectedMaxHealth - i_DamageBonus, 1);	// lowers the total health pool if variant = 2 (bot damage)
		}
		SetArrayCell(playerContributionTracker[client], CONTRIBUTION_TRACKER_DAMAGE, GetArrayCell(playerContributionTracker[client], CONTRIBUTION_TRACKER_DAMAGE) + i_DamageBonus);
	}	// tanking
	else {
		//i_InfectedCurrent += i_DamageBonus;
		if (contributionType == CONTRIBUTION_AWARD_TANKING) {
			i_InfectedCurrent += i_DamageBonus;
			SetArrayCell(InfectedHealth[client], isEntityPos, i_InfectedCurrent, 3);
		}	// buffing
		else if (contributionType == CONTRIBUTION_AWARD_BUFFING) {
			i_DamageBonus = RoundToCeil(i_DamageBonus * fBuffingAwarded);
			i_InfectedCurrent += i_DamageBonus;
			SetArrayCell(InfectedHealth[client], isEntityPos, i_InfectedCurrent, 7);
		}	// healing
		else if (contributionType == CONTRIBUTION_AWARD_HEALING) {
			i_DamageBonus = RoundToCeil(i_DamageBonus * fHealingAwarded);
			i_InfectedCurrent += i_DamageBonus;
			SetArrayCell(InfectedHealth[client], isEntityPos, i_InfectedCurrent, 8);
		}
	}
	if (checkDamages) {
		ThreatCalculator(client, i_DamageBonus);
		CheckTeammateDamagesEx(client, target, i_DamageBonus, hitgroup);
	}
	return 0;
}

stock ThreatCalculator(client, iThreatAmount) {
	if (IsLegitimateClientAlive(client) && myCurrentTeam[client] == TEAM_SURVIVOR) {
		float TheAbilityMultiplier = GetAbilityMultiplier(client, "t");
		if (TheAbilityMultiplier != -1.0) {
			TheAbilityMultiplier *= (iThreatAmount * 1.0);
			iThreatLevel[client] += (iThreatAmount - RoundToFloor(TheAbilityMultiplier));
		}
		else {
			iThreatLevel[client] += iThreatAmount;
		}
	}
}

stock AddSpecialCommonDamage(client, entity, playerDamage, bool IsStatusDamage = false, damagevariant = -1, ammotype = -1, hitgroup = -1) {
	//if (!IsSpecialCommon(entity)) return 1;
	int pos		= FindListPositionByEntity(entity, CommonAffixes);
	if (pos < 0) return 1;
	int damageTotal = -1;
	int my_pos	= FindListPositionByEntity(entity, SpecialCommon[client]);

	int superPos = GetArrayCell(CommonAffixes, pos, 1);
	if (my_pos < 0) {
		int CommonHealth = GetCommonValueIntAtPosEx(superPos, SUPER_COMMON_BASE_HEALTH);
		if (iBotLevelType == 1) CommonHealth += RoundToCeil(CommonHealth * (SurvivorLevels() * GetCommonValueFloatAtPosEx(superPos, SUPER_COMMON_HEALTH_PER_LEVEL)));
		else CommonHealth += RoundToCeil(CommonHealth * (GetDifficultyRating(client) * GetCommonValueFloatAtPosEx(superPos, SUPER_COMMON_HEALTH_PER_LEVEL)));

		SetClientHandicapValues(client);
		if (handicapLevel[client] > 0) {
			float handicapLevelHealth = GetArrayCell(HandicapSelectedValues[client], 1);
			int handicapHealthBonus = RoundToCeil(CommonHealth * handicapLevelHealth);
			if (handicapHealthBonus > 0) CommonHealth += handicapHealthBonus;
		}
		// only add raid health if > 4 survivors.
		int theCount = LivingSurvivorCount();
		if (iSurvivorModifierRequired > 0 && fSurvivorHealthBonus > 0.0 && theCount >= iSurvivorModifierRequired) CommonHealth += RoundToCeil(CommonHealth * ((theCount - (iSurvivorModifierRequired - 1)) * fSurvivorHealthBonus));
		int my_size	= GetArraySize(SpecialCommon[client]);
		//ResizeArray(SpecialCommon[client], my_size + 1);
		PushArrayCell(SpecialCommon[client], entity);
		SetArrayCell(SpecialCommon[client], my_size, CommonHealth, 1);
		SetArrayCell(SpecialCommon[client], my_size, 0, 2);
		SetArrayCell(SpecialCommon[client], my_size, 0, 3);
		SetArrayCell(SpecialCommon[client], my_size, 0, 4);
		my_pos = my_size;
	}
	if (playerDamage >= 0) {
		damageTotal = GetArrayCell(SpecialCommon[client], my_pos, 2);
		//new TrueHealthRemaining = RoundToCeil((1.0 - CheckTeammateDamages(entity, client)) * healthTotal);	// in case other players have damaged the mob - we can't just assume the remaining health without comparing to other players.
		if (damageTotal < 0) damageTotal = 0;
		//if (playerDamage > TrueHealthRemaining) playerDamage = TrueHealthRemaining;
		int maxHP = GetArrayCell(SpecialCommon[client], my_pos, 1) - damageTotal;
		maxHP = RoundToCeil(maxHP * (1.0 - CheckTeammateDamages(entity, client, _, true)));
		if (playerDamage > maxHP) playerDamage = maxHP;
		SetArrayCell(SpecialCommon[client], my_pos, damageTotal + playerDamage, 2);
		if (playerDamage > 0) {
			GetProficiencyData(client, GetWeaponProficiencyType(client), RoundToCeil(playerDamage * fProficiencyExperienceEarned));
			SetArrayCell(playerContributionTracker[client], CONTRIBUTION_TRACKER_DAMAGE, GetArrayCell(playerContributionTracker[client], CONTRIBUTION_TRACKER_DAMAGE) + playerDamage);
			if (CheckTeammateDamagesEx(client, entity, playerDamage, hitgroup) > 0) return playerDamage;
		}
	}
	return 1;
}

void AwardExperience(client, type = 0, AMOUNT = 0, bool TheRoundHasEnded=false) {

	char pct[4];
	Format(pct, sizeof(pct), "%");

	if (type == -1){//} && RoundExperienceMultiplier[client] > 0.0) {	//	This occurs when a player fully loads-in to a game, and is bonus container from previous round.

		//new RewardWaiting = RoundToCeil(BonusContainer[client] * RoundExperienceMultiplier[client]);
		//BonusContainer[client] += RoundToCeil(BonusContainer[client] * RoundExperienceMultiplier[client]);
		//PrintToChat(client, "%T", "bonus experience waiting", client, blue, green, AddCommasToString(RewardWaiting), blue, orange, blue, orange, blue, green, RoundExperienceMultiplier[client] * 100.0, pct);
		//PrintToChat(client, "%T", "round bonus private", )
		return;
	}

	//int InfectedBotLevelType = iBotLevelType;

	if (!TheRoundHasEnded && AMOUNT > 0) {//} && (bIsInCombat[client] || InfectedBotLevelType == 1 || b_IsFinaleActive || IsEnrageActive() || DoomTimer != 0)) {

		int bAMOUNT = AMOUNT;
		// Commented here because we multiply by REM in the ReceivedInfectedDamageAward call.
		// if (RoundExperienceMultiplier[client] > 0.0) {

		// 	bAMOUNT = AMOUNT + RoundToCeil(AMOUNT * RoundExperienceMultiplier[client]);
		// }
		// else bAMOUNT = AMOUNT;
		if (type == 1) HealingContribution[client] += bAMOUNT;
		else if (type == 2) BuffingContribution[client] += bAMOUNT;
		else if (type == 3) HexingContribution[client] += bAMOUNT;
	}
	if (TheRoundHasEnded || AMOUNT == 0 && !bIsInCombat[client]) {

		//float PointsMultiplier = fPointsMultiplier;
		float HealingMultiplier = fHealingMultiplier;
		float BuffingMultiplier = fBuffingMultiplier;
		float HexingMultiplier = fHexingMultiplier;

		if (IsPlayerAlive(client)) {

			int h_Contribution = 0;
			if (HealingContribution[client] > 0) h_Contribution = RoundToCeil(HealingContribution[client] * HealingMultiplier);

			// float SurvivorPoints = 0.0;
			// if (h_Contribution > 0) SurvivorPoints = (h_Contribution * (PointsMultiplier * HealingMultiplier));

			int Bu_Contribution = 0;
			if (BuffingContribution[client] > 0) Bu_Contribution = RoundToCeil(BuffingContribution[client] * BuffingMultiplier);

			// if (Bu_Contribution > 0) SurvivorPoints += (Bu_Contribution * (PointsMultiplier * BuffingMultiplier));

			int He_Contribution = 0;
			if (HexingContribution[client] > 0) He_Contribution = RoundToCeil(HexingContribution[client] * HexingMultiplier);
			// if (He_Contribution > 0) SurvivorPoints += (He_Contribution * (PointsMultiplier * HexingMultiplier));

			//ReceiveInfectedDamageAward(client, 0, DamageContribution[client], PointsContribution[client], TankingContribution[client], h_Contribution, Bu_Contribution, He_Contribution, TheRoundHasEnded);
			ReceiveInfectedDamageAward(client, 0, DamageContribution[client], PointsContribution[client], TankingContribution[client], h_Contribution, Bu_Contribution, He_Contribution, TheRoundHasEnded);
		}
		HealingContribution[client] = 0;
		PointsContribution[client] = 0.0;
		TankingContribution[client] = 0;
		DamageContribution[client] = 0;
		BuffingContribution[client] = 0;
		HexingContribution[client] = 0;
			//ReceiveInfectedDamageAward(i, client, SurvivorExperience, SurvivorPoints, t_Contribution, h_Contribution);
	}
}

// stock bool IsClassType(client, char[] SearchString) {
// }

// stock GetPassiveStrength(client, char[] SearchKey, char[] TalentName, TheSize = 64) {

// 	if (IsLegitimateClient(client)) {

// 		int size = GetArraySize(a_Menu_Talents);
// 		char SearchValue[64];
// 		//char TalentName[64];
// 		Format(TalentName, TheSize, "-1");
// 		int pos = -1;

// 		for (int i = 0; i < size; i++) {

// 			//PassiveStrengthKeys[client] = GetArrayCell(a_Menu_Talents, i, 0);
// 			PassiveStrengthValues[client] = GetArrayCell(a_Menu_Talents, i, 1);

			
// 			GetArrayString(PassiveStrengthValues[client], PASSIVE_ABILITY, SearchValue, sizeof(SearchValue));
			
// 			if (!StrEqual(SearchKey, SearchValue)) continue;
// 			//PassiveTalentName[client] = GetArrayCell(a_Menu_Talents, i, 2);
// 			GetArrayString(a_Database_Talents, i, TalentName, TheSize);

// 			pos = GetDatabasePosition(client, TalentName);
// 			if (pos >= 0) {

// 				//GCMKeys[client] = PassiveStrengthKeys[client];
// 				//GCMValues[client] = PassiveStrengthValues[client];

// 				return GetArrayCell(a_Database_PlayerTalents[client], pos);
// 			}
// 			break;	// should never get here unless there's a spelling mistake in code/config
// 		}
// 	}
// 	return 0;
// }

stock GetDatabasePosition(client, char[] TalentName) {

	int size				=	0;
	if (client != -1) size	=	GetArraySize(a_Database_PlayerTalents[client]);
	else size				=	GetArraySize(a_Database_PlayerTalents_Bots);
	char text[64];

	for (int i = 0; i < size; i++) {

		GetArrayString(a_Database_Talents, i, text, sizeof(text));
		if (StrEqual(TalentName, text)) return i;
	}
	return -1;
}

stock TalentRequirementsMet(client, Handle Keys, Handle Values, char[] sTalentList = "none", TheSize = 0, requiredTalentsToUnlock = 0) {
	int pos = TALENT_FIRST_RANDOM_KEY_POSITION;
	char TalentName[64];
	char text[64];
	char talentTranslation[64];
	int count = 0;
	while (pos >= 0) {
		pos = FormatKeyValue(TalentName, sizeof(TalentName), Keys, Values, "talents required?", _, _, pos, false);
		int menuPos = GetMenuPosition(client, TalentName);
		if (menuPos >= 0) menuPos = GetArrayCell(MyTalentStrength[client], menuPos);
		if (!StrEqual(sTalentList, "none")) {
			if (pos < 0) {
				Format(sTalentList, TheSize, "%s", text);
				break;
			}

			if (menuPos < 1) {
				count++;
				GetTranslationOfTalentName(client, TalentName, talentTranslation, sizeof(talentTranslation), true);
				Format(talentTranslation, sizeof(talentTranslation), "%T", talentTranslation, client);
				if (count > 1) Format(text, sizeof(text), "%s\n%s", text, talentTranslation);
				else Format(text, sizeof(text), "%s", talentTranslation);
			}
			else requiredTalentsToUnlock--;
		}
		else {
			if (menuPos > 0) requiredTalentsToUnlock--;
			else count++;
		}
		if (TheSize == -1) return count;
		if (pos == -1) break;
		pos++;
	}
	return requiredTalentsToUnlock;
	//return true;
	//return (requiredTalentsToUnlock <= 0) ? true : false;
}

stock bool IsStatusEffectFound(client, Handle Keys, Handle Values) {
	char statusEffectToSearchFor[64];
	int pos = TALENT_FIRST_RANDOM_KEY_POSITION;
	while (pos >= 0) {
		pos = FormatKeyValue(statusEffectToSearchFor, sizeof(statusEffectToSearchFor), Keys, Values, "positive effect required?", _, _, pos, false);
		if (pos == -1) break;
		// if we can't find the positive status effect.
		if (StrContains(ClientStatusEffects[client][1], statusEffectToSearchFor, true) == -1) return false;
		pos++;
	}
	pos = TALENT_FIRST_RANDOM_KEY_POSITION;
	while (pos >= 0) {
		pos = FormatKeyValue(statusEffectToSearchFor, sizeof(statusEffectToSearchFor), Keys, Values, "negative effect required?", _, _, pos, false);
		if (pos == -1) break;
		// if we can't find the negative status effect.
		if (StrContains(ClientStatusEffects[client][0], statusEffectToSearchFor, true) == -1) return false;
		pos++;
	}
	// If all status effects are found (or none are found)
	return true;
}

// stock bool IsAbilityFound(int menuPos, int abilityT, bool isEffectOverTimeActive) {
// 	int numTriggers = (isEffectOverTimeActive) ? GetArrayCell(talentActiveAbilityTriggers, menuPos) : GetArrayCell(talentAbilityTriggers, menuPos);
// 	while (numTriggers > 0) {
// 		int currentAbilityTrigger = (isEffectOverTimeActive) ? GetArrayCell(talentActiveAbilityTriggers, menuPos, numTriggers) : GetArrayCell(talentAbilityTriggers, menuPos, numTriggers);
// 		if (currentAbilityTrigger == abilityT) return true;
// 		numTriggers--;
// 	}
// 	return false;
// }

stock GetGoverningAttribute(client, char[] governingAttribute, theSize, int menuPos) {
	char text[64];
	GetGoverningAttributeValues[client]		= GetArrayCell(a_Menu_Talents, menuPos, 1);
	GetArrayString(GetGoverningAttributeValues[client], GOVERNING_ATTRIBUTE, text, sizeof(text));
	Format(governingAttribute, theSize, "%s", text);
	// if (StrEqual(text, "-1")) Format(governingAttribute, theSize, "-1");
	// else GetTranslationOfTalentName(client, text, governingAttribute, theSize, true, _, true);
}

stock GetTranslationOfTalentName(client, char[] nameOfTalent, char[] translationText, theSize, bool bGetTalentNameInstead = false, bool bJustKiddingActionBarName = false, bool returnResult = false) {
	char talentName[64];
	int size = GetArraySize(a_Menu_Talents);

	for (int i = 0; i < size; i++) {
		//TranslationOTNSection[client]	= GetArrayCell(a_Menu_Talents, i, 2);
		GetArrayString(a_Database_Talents, i, talentName, sizeof(talentName));
		if (!returnResult && !StrEqual(talentName, nameOfTalent) ||
			returnResult && StrContains(talentName, nameOfTalent, false) == -1) continue;
		TranslationOTNValues[client]	= GetArrayCell(a_Menu_Talents, i, 1);
		// Just a quick hack, I'll fix this later when I have time.
		// it works why change it?
		if (bJustKiddingActionBarName) {
			GetArrayString(TranslationOTNValues[client], ACTION_BAR_NAME, translationText, theSize);
		}
		else if (!bGetTalentNameInstead) {
			GetArrayString(TranslationOTNValues[client], GET_TRANSLATION, translationText, theSize);
			//if (StrEqual(translationText, "-1")) SetFailState("No \"translation?\" set for Talent %s in /configs/readyup/rpg/talentmenu.cfg", talentName);
			//else break;
		}
		else {
			GetArrayString(TranslationOTNValues[client], GET_TALENT_NAME, translationText, theSize);
			if (!returnResult && StrEqual(translationText, "-1")) Format(translationText, theSize, "%s", talentName);
		}
		break;
	}
}

bool alliesInRangeOnFire(int activator, float fCoherencyRange) {
	float cpos[3];
	GetClientAbsOrigin(activator, cpos);
	int activatorTeam = GetClientTeam(activator);
	for (int i = 1; i <= MaxClients; i++) {
		if (i == activator || !IsLegitimateClientAlive(i) || myCurrentTeam[i] != activatorTeam) continue;
		float tpos[3];
		GetClientAbsOrigin(i, tpos);
		if (GetVectorDistance(cpos, tpos) > fCoherencyRange) continue;
		if (GetClientStatusEffect(i, STATUS_EFFECT_BURN) < 1) continue;
		return true;
	}
	return false;
}

bool alliesInRangeWithAdrenaline(int activator, float fCoherencyRange) {
	float cpos[3];
	GetClientAbsOrigin(activator, cpos);
	int activatorTeam = GetClientTeam(activator);
	for (int i = 1; i <= MaxClients; i++) {
		if (i == activator || !IsLegitimateClientAlive(i) || myCurrentTeam[i] != activatorTeam) continue;
		float tpos[3];
		GetClientAbsOrigin(i, tpos);
		if (GetVectorDistance(cpos, tpos) > fCoherencyRange) continue;
		if (!HasAdrenaline(i)) continue;
		return true;
	}
	return false;
}

bool anyNearbyAlliesBelowHealthPercentage(int activator, float requireAllyBelowHealthPercentage, float fCoherencyRange) {
	if (fCoherencyRange <= 0.0) return false;
	// Get the origin position.
	float cpos[3];
	GetClientAbsOrigin(activator, cpos);
	int activatorTeam = GetClientTeam(activator);
	// We're going to check in a circle around this position for any teammates below the health requirement.
	for (int i = 1; i <= MaxClients; i++) {
		if (i == activator || !IsLegitimateClientAlive(i) || myCurrentTeam[i] != activatorTeam) continue;
		// Get the position of the player so we can check if they're inside the circle.
		float tpos[3];
		GetClientAbsOrigin(i, tpos);
		// if they're not, well, it ends here.
		if (GetVectorDistance(cpos, tpos) > fCoherencyRange) continue;
		float fPercentageHealthRemaining = ((GetClientHealth(i) * 1.0) / (GetMaximumHealth(i) * 1.0));
		// If the player is in the circle, but is above the required health percentage, it ends here.
		if (fPercentageHealthRemaining >= requireAllyBelowHealthPercentage) continue;
		return true;
	}
	return false;
}

int enemyInRange(int activator, float fCoherencyRange) {
	if (fCoherencyRange <= 0.0) return -1;
	float cpos[3];
	GetClientAbsOrigin(activator, cpos);
	int team = GetClientTeam(activator);
	for (int i = 1; i <= MaxClients; i++) {
		if (i == activator || !IsLegitimateClientAlive(i) || team == myCurrentTeam[i]) continue;
		float tpos[3];
		GetClientAbsOrigin(i, tpos);
		if (GetVectorDistance(cpos, tpos) > fCoherencyRange) continue;
		return i;
	}
	return -1;
}

stock bool clientClassIsAllowed(classCategoriesAllowed, classCategory) {
	return classCategory & classCategoriesAllowed > 0;
}

stock bool clientWeaponCategoryIsAllowed(client, weaponCategoriesAllowed) {
	int weaponCategories = currentWeaponCategory[client];
	return weaponCategories & weaponCategoriesAllowed > 0;
	// new weaponsAllowed = weaponCategoriesAllowed;
	// while (weaponCategories != 0) {
	// 	while (weaponsAllowed != 0) {
	// 		if (weaponCategories % 100 == weaponsAllowed % 100) return true;
	// 		weaponsAllowed /= 100;
	// 	}
	// 	weaponCategories /= 100;
	// 	weaponsAllowed = weaponCategoriesAllowed;
	// }
	//return false;
}

bool enemyClassInRange(int activator, int requireEnemyClassInCoherency, float fCoherencyRange) {
	bool findASmoker = false;
	bool findABoomer = false;
	bool findAHunter = false;
	bool findASpitter = false;
	bool findAJockey = false;
	bool findACharger = false;
	bool findAWitch = false;
	bool findATank = false;

	if (enemyClassInRangeIsValid(2, requireEnemyClassInCoherency)) findASmoker = true;
	if (enemyClassInRangeIsValid(4, requireEnemyClassInCoherency)) findABoomer = true;
	if (enemyClassInRangeIsValid(8, requireEnemyClassInCoherency)) findAHunter = true;
	if (enemyClassInRangeIsValid(16, requireEnemyClassInCoherency)) findASpitter = true;
	if (enemyClassInRangeIsValid(32, requireEnemyClassInCoherency)) findAJockey = true;
	if (enemyClassInRangeIsValid(64, requireEnemyClassInCoherency)) findACharger = true;
	if (enemyClassInRangeIsValid(128, requireEnemyClassInCoherency)) findAWitch = true;
	if (enemyClassInRangeIsValid(256, requireEnemyClassInCoherency)) findATank = true;

	if (findASmoker || findABoomer || findAHunter || findASpitter || findAJockey || findACharger || findATank) {
		for (int i = 1; i <= MaxClients; i++) {
			if (!IsLegitimateClientAlive(i) || myCurrentTeam[i] != TEAM_INFECTED) continue;
			if (GetPlayerDistance(activator, i) > fCoherencyRange) continue;

			int myZombieClass = FindZombieClass(i);
			if (findASmoker && myZombieClass == ZOMBIECLASS_SMOKER) return true;
			if (findABoomer && myZombieClass == ZOMBIECLASS_BOOMER) return true;
			if (findAHunter && myZombieClass == ZOMBIECLASS_HUNTER) return true;
			if (findASpitter && myZombieClass == ZOMBIECLASS_SPITTER) return true;
			if (findAJockey && myZombieClass == ZOMBIECLASS_JOCKEY) return true;
			if (findACharger && myZombieClass == ZOMBIECLASS_CHARGER) return true;
			if (findATank && myZombieClass == ZOMBIECLASS_TANK) return true;
		}
	}
	if (findAWitch) {
		for (int i = 0; i < GetArraySize(damageOfWitch); i++) {
			int witchEntity = GetArrayCell(damageOfWitch, i);
			if (!IsWitch(witchEntity)) {
				RemoveFromArray(damageOfWitch, i);
				i--;
				continue;
			}
			if (GetPlayerDistance(activator, witchEntity) > fCoherencyRange) continue;
			return true;
		}
	}
	return false;
}

bool enemyClassInRangeIsValid(int enemyClass, int enemyClassesAllowed) {
	return enemyClass & enemyClassesAllowed > 0;
}

stock bool doWeMultiplyThisTargetType(int state, int statesAllowed) {
	return state & statesAllowed > 0;
}

stock bool clientHasEffectStateRequired(client, effectStatesAllowed) {
	int effectStates = clientEffectState[client];
	return effectStates & effectStatesAllowed > 0;
}

void SetClientEffectState(client) {
	int effectState = 0;
	bool clientIsOnFire = (GetClientStatusEffect(client, STATUS_EFFECT_BURN) > 0) ? true : false;
	bool clientIsSufferingAcidBurn = (GetClientStatusEffect(client, STATUS_EFFECT_ACID) > 0) ? true : false;
	if (clientIsOnFire) effectState +=												1;		// ON FIRE
	if (!clientIsSufferingAcidBurn) effectState +=									2;		// ACID BURN
	if (ISEXPLODE[client] != INVALID_HANDLE) effectState +=							4;		// EXPLODING
	if (ISSLOW[client] || playerInSlowAmmo[client]) effectState +=					8;		// SLOWED
	if (FreezerInRange[client]) effectState +=							16;		// FROZEN
	if (clientIsOnFire && clientIsSufferingAcidBurn) effectState +=					32;		// SCORCHED
	if (clientIsOnFire && FreezerInRange[client]) effectState +=			64;		// STEAMING
	if (ISBILED[client]) effectState +=												128;	// BILED
	else effectState +=																256;	// NOT BILED
	if (myCurrentTeam[client] == TEAM_SURVIVOR) {
		if (L4D2_GetInfectedAttacker(client) != -1) effectState +=					512;	// ENSNARED
		else effectState +=															1024;	// NOT ENSNARED
	}
	
	int cFlags = GetEntityFlags(client);
	if (cFlags & FL_INWATER) effectState +=											2048;	// DROWNING
	if (cFlags & FL_ONGROUND) effectState +=										4096;	// ON GROUND
	else effectState +=																8192;	// FLYING

	int cButtons = GetEntProp(client, Prop_Data, "m_nButtons");
	if ((cFlags & FL_ONGROUND) && (cButtons & IN_DUCK)) effectState +=				16384;	// CROUCHING

	if (bHasWeakness[client] > 0) effectState +=									32768;	// weakness
	else effectState += 															65536;	// no weakness

	if (playerHasAdrenaline[client]) effectState +=									131072; // adrenaline
	else effectState +=																262144;	// no adrenaline

	clientEffectState[client] = effectState;
}

stock int GetWeaponProficiencyType(int client) {
	return (hasMeleeWeaponEquipped[client]) ? 1 : weaponProficiencyType[client];
}

/*
	result 1 to get the offset, which is used to determine how much reserve ammo there is remaining.
	result 2 to get the max amount of reserve ammo this weapon can hold.
	result 3 to get the current amount of reserve ammo is remaining.
	result 4 is the amount of ammo to return to the magazine
	result 5 is to give the player the max amount of reserve ammo
*/
stock int GetWeaponResult(int client, int result = 0, int amountToAdd = 0) {
	if (!IsValidEntity(myCurrentWeaponId[client]) || myCurrentWeaponPos[client] == -1) return -1;

	float fValue = 0.0;
	int wOffset = 0;
	int iWeapon = 0;
	if (result >= 3) {
		iWeapon = FindDataMapInfo(client, "m_iAmmo");
		wOffset = GetWeaponResult(client, 1);
	}
	if (myPrimaryWeaponPos[client] == -1) return 0;	// maybe for debugging but not really. players load without a primary.
	WeaponResultValues[client] = GetArrayCell(a_WeaponDamages, myPrimaryWeaponPos[client], 1);
	if (result == 0) {
		fValue = GetArrayCell(WeaponResultValues[client], WEAPONINFO_RANGE);
		return RoundToCeil(fValue);
	}
	if (result == 1) return GetArrayCell(WeaponResultValues[client], WEAPONINFO_OFFSET);
	if (result == 2 || result == 5) {
		int value = amountToAdd;
		if (amountToAdd < 1) {
			value = GetArrayCell(WeaponResultValues[client], WEAPONINFO_AMMO);
			value += RoundToCeil(GetAbilityStrengthByTrigger(client, _, TRIGGER_ammoreserve, _, value, _, _, RESULT_ammoreserve, 0, true));
		}
		if (result == 5) {
			if (!IsFakeClient(client)) SetEntData(client, (iWeapon + wOffset), value);
			else SetEntData(client, (iWeapon + wOffset), 999);
		}
		return value;
	}
	if (result == 3) {
		return GetEntData(client, (iWeapon + wOffset));
	}
	if (result == 4) {
		SetEntData(client, (iWeapon + wOffset), GetEntData(client, (iWeapon + wOffset)) + amountToAdd);
		return amountToAdd;
	}
	return -1;
}

stock bool EffectOverTimeActive(int activator, int talentMenuPos, float fEffectTime = 0.0) {
	int size = GetArraySize(PlayerEffectOverTime[activator]);
	if (fEffectTime <= 0.0) { // check if it's active and return true if it is.
		float fEngineTime = GetEngineTime();
		for (int i = 0; i < size; i++) {
			int pos = GetArrayCell(PlayerEffectOverTime[activator], i);
			if (pos != talentMenuPos) continue;
			
			float fCurrentEffectTime = GetArrayCell(PlayerEffectOverTime[activator], i, 1);
			if (fCurrentEffectTime > fEngineTime) return true;	// effect over time is active.
			else {																					// effect over time has ended - remove it.
				RemoveFromArray(PlayerEffectOverTime[activator], i);
				return false;
			}
		}
		return false;																				// effect over time not found, false.
	}
	else {
		float fEffectTimeToAdd = GetEngineTime() + fEffectTime;

		for (int i = 0; i < size; i++) {
			int pos = GetArrayCell(PlayerEffectOverTime[activator], i);
			if (pos != talentMenuPos) continue;
			// if the effect over time is currently active, its effect time is refreshed.
			SetArrayCell(PlayerEffectOverTime[activator], size, fEffectTimeToAdd, 1);
			return true;
		}
		// if the effect over time isn't currently active and thus isn't in the list, it gets added to the list.
		//ResizeArray(PlayerEffectOverTime[activator], size+1);
		PushArrayCell(PlayerEffectOverTime[activator], talentMenuPos);
		SetArrayCell(PlayerEffectOverTime[activator], size, fEffectTimeToAdd, 1);
	}
	return true;
}

stock bool EnemiesWithinExplosionRange(client, float TheRange, TheStrength) {

	if (!IsLegitimateClientAlive(client)) return false;
	float MyRange[3];
	GetClientAbsOrigin(client, MyRange);

	//int ent = -1;

	bool IsInRangeTheRange = false;
	int RealStrength = TheStrength * GetClientHealth(client);
	if (RealStrength < 1) return false;

	float TheirRange[3];
	bool isClientFake = IsFakeClient(client);

	for (int i = 1; i <= MaxClients; i++) {

		if (!IsLegitimateClientAlive(i) || i == client || myCurrentTeam[i] == TEAM_SURVIVOR) continue;
		GetClientAbsOrigin(i, TheirRange);
		if (GetVectorDistance(MyRange, TheirRange) <= TheRange) {

			if (!IsInRangeTheRange) {

				IsInRangeTheRange = true;
				CreateAmmoExplosion(client, MyRange[0], MyRange[1], MyRange[2]);		// Boom!
			}
			if (!isClientFake && IsSpecialCommonInRange(i, 't')) continue;	// even though the mob is within the explosion range, it is immune because a defender is nearby.
			AddSpecialInfectedDamage(client, i, RealStrength, _, 1);
			CheckTeammateDamagesEx(client, i, RealStrength);
		}
	}
	return IsInRangeTheRange;
}

stock bool ComparePlayerState(client, char[] CombatState, bool incapState, bool ledgeState, infectedAttacker) {

	if (StrEqual(CombatState, "-1") || StrContains(CombatState, "0") != -1) return true;

	if (incapState && StrContains(CombatState, "1") != -1) return true;
	if (!incapState && StrContains(CombatState, "2") != -1) return true;
	if (infectedAttacker == -1 && !incapState && StrContains(CombatState, "3") != -1) return true;
	if (ledgeState && StrContains(CombatState, "4") != -1) return true;
	return false;
}

stock GetPIV(client, float Distance, bool IsSameTeam = true) {

	float ClientOrigin[3];
	float iOrigin[3];

	GetClientAbsOrigin(client, ClientOrigin);

	int count = 0;
	for (int i = 1; i <= MaxClients; i++) {

		if (!IsLegitimateClientAlive(i) || i == client) continue;
		if (IsSameTeam && myCurrentTeam[client] != myCurrentTeam[i]) continue;
		GetClientAbsOrigin(i, iOrigin);
		if (GetVectorDistance(ClientOrigin, iOrigin) <= Distance) count++;
	}
	return count;
}

stock float GetPlayerDistance(client, target) {

	float ClientDistance[3];
	GetEntPropVector(client, Prop_Send, "m_vecOrigin", ClientDistance);

	float TargetDistance[3];
	GetEntPropVector(target, Prop_Send, "m_vecOrigin", TargetDistance);

	return GetVectorDistance(ClientDistance, TargetDistance);
}

stock GetCategoryStrength(client, char[] sTalentCategory, bool bGetMaximumTreePointsInstead = false) {
	if (!IsLegitimateClient(client)) return 0;
	int count = 0;
	char sText[64];
	int iStrength = 0;

	int size = GetArraySize(a_Menu_Talents);
	for (int i = 0; i < size; i++) {
		GetCategoryStrengthValues[client]	= GetArrayCell(a_Menu_Talents, i, 1);
		GetArrayString(GetCategoryStrengthValues[client], TALENT_TREE_CATEGORY, sText, sizeof(sText));
		if (!StrEqual(sTalentCategory, sText, false)) continue;
		if (bGetMaximumTreePointsInstead) count++;
		else {
			iStrength = GetTalentStrength(client, _, _, i);
			if (iStrength > 0) count++;
		}
	}
	return count;
}

stock VerifyClientUnlockedTalentEligibility(client) {
	for (int i = 1; i <= iMaxLayers; i++) {
		if (GetLayerUpgradeStrength(client, i, true) == -1) break;
	}
}

stock int GetLayerUpgradeStrength(int client, int layer = 1, bool bIsCheckEligibility = false, bool bResetLayer = false, bool countAllOptionsOnLayer = false, bool getAllLayerNodes = false, bool ignoreAttributes = false) {
	int size = GetArraySize(a_Menu_Talents);
	int count = 0;
	int clientTeam = myCurrentTeam[client];
	for (int i = 0; i < size; i++) {										// loop through this talents keyfile.
		//GetLayerStrengthKeys[client] = GetArrayCell(a_Menu_Talents, i, 0);	// "keys"
		GetLayerStrengthValues[client] = GetArrayCell(a_Menu_Talents, i, 1);// "values"

		int activatorClassesAllowed = GetArrayCell(GetLayerStrengthValues[client], ACTIVATOR_CLASS_REQ);
		if (activatorClassesAllowed > -1) {
			int isSurvivorTalent		= (activatorClassesAllowed % 2 == 1) ? 1 : 0;
			int isInfectedTalent		= (activatorClassesAllowed > 1) ? 1 : 0;
			if (isInfectedTalent == 1 && clientTeam != TEAM_INFECTED) continue;
			if (clientTeam != TEAM_SPECTATOR) {
				if (isSurvivorTalent == 1 && clientTeam != TEAM_SURVIVOR) continue;
			}
		}
		// talents are ordered by "layers" (think a 3-d talent tree)
		if (GetArrayCell(GetLayerStrengthValues[client], GET_TALENT_LAYER) != layer) continue;
		if (ignoreAttributes && GetArrayCell(GetLayerStrengthValues[client], IS_ATTRIBUTE) == 1) continue;
		if (getAllLayerNodes) {	// we just want to get how many nodes are on this layer, even the ones that we ignore for layer count.
			count++;
			continue;
		}
		if (!countAllOptionsOnLayer && GetArrayCell(GetLayerStrengthValues[client], LAYER_COUNTING_IS_IGNORED) == 1) continue;
		if (bResetLayer) {
			count = GetArrayCell(MyTalentStrength[client], i);
			if (count < 1) continue;
			PlayerUpgradesTotal[client]--;	// nodes can only be upgraded once regardless of their unlock cost.
			FreeUpgrades[client]++;//= nodeUnlockCost;
			AddTalentPoints(client, i, 0);	// This func actually SETS the talent points to the value you specify... SetTalentPoints?
			continue;
		}
		new currTalentStrength = GetArrayCell(MyTalentStrength[client], i);
		if (currTalentStrength > 0) count += currTalentStrength;	// how many talent points have the player invested in this node?
	}
	if (bResetLayer) return -2;	// for logging purposes.
	if (bIsCheckEligibility &&
		(fUpgradesRequiredPerLayer > 1.0 && count < RoundToCeil(fUpgradesRequiredPerLayer) || fUpgradesRequiredPerLayer <= 1.0 && count < RoundToCeil(GetLayerUpgradeStrength(client, layer, _, _, _, true, true) * fUpgradesRequiredPerLayer))) {	// we only check the eligibility of the layer the player just locked(refunded) their node in.
		for (int i = layer + 1; i <= iMaxLayers; i++) {	// if any layer is found to not meet eligibility, all subsequent layers are reset.
			GetLayerUpgradeStrength(client, i, _, true);
		}
		return -1;	// logging
	}
	return count;
}

stock GetTalentKeyValue(client, pos, char[] storage, storageLocSize, int menuPos) {
	GetTalentKeyValueValues[client]		= GetArrayCell(a_Menu_Talents, menuPos, 1);
	GetArrayString(GetTalentKeyValueValues[client], pos, storage, storageLocSize);
}

stock float GetTalentStrengthByKeyValue(client, pos, char[] searchValue, bool skipTalentsOnCooldown = true, bool returnFirstResult = false) {
	int size = GetArraySize(a_Menu_Talents);
	char result[64];
	float fTotalTalentStrength = 0.0;
	for (int i = 0; i < size; i++) {
		int count = GetArrayCell(MyTalentStrength[client], i);
		if (count < 1) continue;
		GetTalentStrengthSearchValues[client]		= GetArrayCell(a_Menu_Talents, i, 1);
		GetArrayString(GetTalentStrengthSearchValues[client], pos, result, sizeof(result));
		if (!StrEqual(result, searchValue)) continue;
		if (skipTalentsOnCooldown && IsAbilityCooldown(client, i)) continue;
		float fThisTalentStrength = GetArrayCell(MyTalentStrengths[client], i);//GetTalentInfo(client, GetTalentStrengthSearchValues[client], _, _, talentName);
		if (fThisTalentStrength > 0.0) {
			if (returnFirstResult) return fThisTalentStrength;
			fTotalTalentStrength += fThisTalentStrength;
		}
	}
	return fTotalTalentStrength;
}
//float f_EachPoint				= GetArrayCell(MyTalentStrengths[activator], i);

stock float GetCoherencyStrength(client, int pos, char[] searchValue, int resultPos) {
	int size = GetArraySize(a_Menu_Talents);
	if (GetArraySize(MyTalentStrength[client]) != size) ResizeArray(MyTalentStrength[client], size);
	float cohDistance[MAXPLAYERS + 1][3];
	bool cohSkip[MAXPLAYERS + 1];
	int clientTeam = myCurrentTeam[client];
	for (int i = 1; i < MaxClients; i++) {
		if (client == i || !IsLegitimateClient(i) || myCurrentTeam[i] != clientTeam || !IsPlayerAlive(i)) cohSkip[i] = true;
		else {
			GetClientAbsOrigin(i, cohDistance[i]);
			cohSkip[i] = false;
			if (GetArraySize(MyTalentStrength[i]) != size) ResizeArray(MyTalentStrength[i], size);
		}
	}
	float totalStr = 0.0;
	float curTime = GetEngineTime();
	for (int i = 0; i < size; i++) {
		GetCoherencyValues[client]		= GetArrayCell(a_Menu_Talents, i, 1);
		char result[64];
		GetArrayString(GetCoherencyValues[client], pos, result, sizeof(result));
		// does this talent meet the searchValue/abilityeffects at the pos requested?
		if (!StrEqual(result, searchValue)) continue;
		int combatStateReq = GetArrayCell(GetCoherencyValues[client], COMBAT_STATE_REQ);
		float fTimeSinceAttackerLastAttack = GetArrayCell(GetCoherencyValues[client], TIME_SINCE_LAST_ACTIVATOR_ATTACK);
		bool bIsEffectOverTime = (GetArrayCell(GetCoherencyValues[client], TALENT_IS_EFFECT_OVER_TIME) == 1) ? true : false;
		// grab the coherency radius based. there are several kinds, so we let that dynamically pass through to the call.
		float fRange = GetArrayCell(GetCoherencyValues[client], resultPos);
		for (int coh = 1; coh <= MaxClients; coh++) {
			if (!IsLegitimateClient(coh) || !b_IsLoaded[coh]) continue;
			if (cohSkip[coh]) continue;
			int count = GetArrayCell(MyTalentStrength[coh], i);
			// has the player unlocked this talent?
			if (count < 1) continue;
			if (combatStateReq == 0 && bIsInCombat[coh] || combatStateReq == 1 && !bIsInCombat[coh]) continue;
			if (fTimeSinceAttackerLastAttack > 0.0 && curTime - LastAttackTime[coh] < fTimeSinceAttackerLastAttack) continue;
			bool isEffectOverTimeActive = (!bIsEffectOverTime || !EffectOverTimeActive(coh, i)) ? false : true;
			if (!isEffectOverTimeActive && IsAbilityCooldown(coh, i)) continue;
			if (GetVectorDistance(cohDistance[client], cohDistance[coh]) > fRange) continue;
			float thisStr				= GetArrayCell(MyTalentStrengths[coh], i);
			if (thisStr <= 0.0) continue;
			totalStr += thisStr;
		}
	}
	return totalStr;
}

stock float GetStrengthByKeyValueFloat(client, int pos, char[] searchValue, int resultPos, int tpos = -1) {
	int size = GetArraySize(a_Menu_Talents);
	char result[64];
	if (GetArraySize(MyTalentStrength[client]) != size) ResizeArray(MyTalentStrength[client], size);
	for (int i = (tpos == -1) ? 0 : tpos; i < size; i++) {
		GetStrengthFloat[client]		= GetArrayCell(a_Menu_Talents, i, 1);
		GetArrayString(GetStrengthFloat[client], pos, result, sizeof(result));
		if (!StrEqual(result, searchValue)) continue;

		// found the talent with the required value to the search key.
		// GetTalentValueSearchSection[client]		= GetArrayCell(a_Menu_Talents, i, 2);
		// GetArrayString(GetTalentValueSearchSection[client], 0, result, sizeof(result));
		int count = GetArrayCell(MyTalentStrength[client], i);
		if (count < 1) {
			if (tpos == -1) continue;
			return 0.0;
		}
		// the talent has at least 1 point in it, so we get the target key's value and return it.
		float fResult = GetArrayCell(GetStrengthFloat[client], resultPos);
		return fResult;
	}
	return 0.0;
}

stock GetTalentPointsByKeyValue(client, pos, char[] searchValue, bool getFirstTalentResult = true) {
	int size = GetArraySize(a_Menu_Talents);
	char result[64];
	int count = 0;
	int total = 0;
	if (GetArraySize(MyTalentStrength[client]) != size) ResizeArray(MyTalentStrength[client], size);
	for (int i = 0; i < size; i++) {
		//GetTalentValueSearchKeys[client]		= GetArrayCell(a_Menu_Talents, i, 0);
		GetTalentValueSearchValues[client]		= GetArrayCell(a_Menu_Talents, i, 1);
		GetArrayString(GetTalentValueSearchValues[client], pos, result, sizeof(result));
		if (!StrEqual(result, searchValue)) continue;
		// we found a talent with the search value required, so we want to get its name.
		//GetTalentValueSearchSection[client]		= GetArrayCell(a_Menu_Talents, i, 2);
		//GetArrayString(GetTalentValueSearchSection[client], 0, result, sizeof(result));
		// and its strength.
		count = GetArrayCell(MyTalentStrength[client], i);
		if (count < 1) continue;
		// if there are multiple nodes with the same function, but we only care if at least one is unlocked
		if (getFirstTalentResult) return count;
		total += count;
	}
	return total;
}

stock GetTalentStrength(client, char[] TalentName = "none", target = 0, int pos = -1, bool containsTalentName = false) {
	if (pos >= 0) {
		return GetArrayCell(a_Database_PlayerTalents[client], pos);
	}
	int size				=	GetArraySize(a_Database_PlayerTalents[client]);
	char text[64];
	int count = 0;
	for (int i = 0; i < size; i++) {
		GetArrayString(a_Database_Talents, i, text, sizeof(text));
		if (containsTalentName) {
			if (StrContains(text, TalentName, false) != -1) count += GetArrayCell(a_Database_PlayerTalents[client], i);
		}
		else if (StrEqual(TalentName, text)) {
			return GetArrayCell(a_Database_PlayerTalents[client], i);
		}
	}
	return count;
}

/*
	This method lets us make it so all talent nodes have a key field named "attribute?"

	Server operators can set these to any custom value, as long as there is an attribute node with that name made.
	The attributes multiplier, weighed based on several factors seen below, scales all factors of the talent.

	These include strength, active time, cooldown time, passive time, etc.
	If you don't want a node connected to an attribute, omit "attribute?" from the node.
*/
stock float GetAttributeMultiplier(client, char[] TalentName) {
	int pos = (StrBeginsWith(TalentName, "c")) ? ATTRIBUTE_CONSTITUTION : (StrBeginsWith(TalentName, "a")) ? ATTRIBUTE_AGILITY : (StrBeginsWith(TalentName, "r")) ? ATTRIBUTE_RESILIENCE :
				(StrBeginsWith(TalentName, "t")) ? ATTRIBUTE_TECHNIQUE : (StrBeginsWith(TalentName, "e")) ? ATTRIBUTE_ENDURANCE : ATTRIBUTE_LUCK;
	int thisAttributeLevel = GetArrayCell(attributeData[client], pos);
	return thisAttributeLevel * fAttributeMultiplier[pos];
}

stock int GetAttributePosition(client, char[] attribute) {
	int pos = (StrBeginsWith(attribute, "c")) ? ATTRIBUTE_CONSTITUTION : (StrBeginsWith(attribute, "a")) ? ATTRIBUTE_AGILITY : (StrBeginsWith(attribute, "r")) ? ATTRIBUTE_RESILIENCE :
				(StrBeginsWith(attribute, "t")) ? ATTRIBUTE_TECHNIQUE : (StrBeginsWith(attribute, "e")) ? ATTRIBUTE_ENDURANCE : ATTRIBUTE_LUCK;
	return pos;
}

stock GetKeyPos(Handle Keys, char[] SearchKey) {

	char key[64];
	int size = GetArraySize(Keys);
	for (int i = 0; i < size; i++) {

		GetArrayString(Keys, i, key, sizeof(key));
		if (StrEqual(key, SearchKey)) return i;
	}
	return -1;
}

stock bool FoundCooldownReduction(char[] TalentName, char[] CooldownList) {
	int ExplodeCount = GetDelimiterCount(CooldownList, "|") + 1;
	if (ExplodeCount == 1) {
		if (StrContains(TalentName, CooldownList, false) != -1) return true;
	}
	else {
		char[][] cooldownTalentName = new char[ExplodeCount][64];
		ExplodeString(CooldownList, "|", cooldownTalentName, ExplodeCount, 64);
		for (int i = 0; i < ExplodeCount; i++) {
			if (StrContains(TalentName, cooldownTalentName[i], false) != -1) return true;
		}
	}
	return false;
}

stock int FormatKeyValue(char[] TheValue, TheSize, Handle Keys, Handle Values, char[] SearchKey, char[] DefaultValue = "none", bool bDebug = false, pos = 0, bool incrementPos = true) {

	char key[512];

	int size = GetArraySize(Keys);
	if (pos > 0 && incrementPos) pos++;
	for (int i = pos; i < size; i++) {

		GetArrayString(Keys, i, key, sizeof(key));
		if (StrEqual(key, SearchKey)) {

			GetArrayString(Values, i, TheValue, TheSize);
			return i;
		}
	}
	if (StrEqual(DefaultValue, "none", false)) Format(TheValue, TheSize, "-1");
	else Format(TheValue, TheSize, "%s", DefaultValue);
	return -1;
}

stock float GetKeyValueFloat(Handle Keys, Handle Values, char[] SearchKey, char[] DefaultValue = "none", bool bDebug = false, pos = 0) {

	char key[64];
	if (pos > 0) pos++;
	int size = GetArraySize(Keys);
	for (int i = pos; i < size; i++) {

		GetArrayString(Keys, i, key, sizeof(key));
		if (StrEqual(key, SearchKey)) {

			GetArrayString(Values, i, key, sizeof(key));
			return StringToFloat(key);
		}
	}
	if (StrEqual(DefaultValue, "none", false)) return -1.0;
	return StringToFloat(DefaultValue);
}

// bool IsValidValue_Int(Handle Values, pos, compare) {
// 	char val[64];
// 	GetArrayString(Values, pos, val, 64);
// 	int result = StringToInt(val);
// 	if (result == -1 || result == compare) return true;
// 	return false;
// }

stock GetKeyValueIntAtPos(Handle Values, pos) {
	char key[64];
	GetArrayString(Values, pos, key, sizeof(key));
	return StringToInt(key);
}

stock float GetKeyValueFloatAtPos(Handle Values, pos) {
	char key[64];
	GetArrayString(Values, pos, key, sizeof(key));
	return StringToFloat(key);
}

stock GetKeyValueInt(Handle Keys, Handle Values, char[] SearchKey, char[] DefaultValue = "none", bool bDebug = false) {

	char key[64];

	int size = GetArraySize(Keys);
	for (int i = 0; i < size; i++) {

		GetArrayString(Keys, i, key, sizeof(key));
		if (StrEqual(key, SearchKey)) {

			GetArrayString(Values, i, key, sizeof(key));
			return StringToInt(key);
		}
	}
	if (StrEqual(DefaultValue, "none", false)) return -1;
	return StringToInt(DefaultValue);
}

stock GetMenuOfTalent(client, char[] TalentName, char[] TheText, TheSize) {
	int size = GetArraySize(a_Menu_Talents);
	for (int i = 0; i < size; i++) {
		MOTValues[client]		= GetArrayCell(a_Menu_Talents, i, 1);

		char s_TalentName[64];
		GetArrayString(a_Database_Talents, i, s_TalentName, sizeof(s_TalentName));
		if (!StrEqual(s_TalentName, TalentName, false)) continue;
		GetArrayString(MOTValues[client], PART_OF_MENU_NAMED, TheText, TheSize);
		return;
	}
	Format(TheText, TheSize, "-1");
}

stock GetWeaponSlot(entity) {

	if (IsValidEntity(entity)) {

		char Classname[64];
		GetEntityClassname(entity, Classname, sizeof(Classname));

		if (StrEqualAtPos(Classname, "pistol", 7) || StrEqualAtPos(Classname, "chainsaw", 7)) return 1;
		if (StrEqualAtPos(Classname, "molotov", 7) || StrEqualAtPos(Classname, "pipe_bomb", 7) || StrEqualAtPos(Classname, "vomitjar", 7)) return 2;
		if (StrEqualAtPos(Classname, "defib", 7) || StrEqualAtPos(Classname, "first_aid", 7)) return 3;
		if (StrEqualAtPos(Classname, "adren", 7) || StrEqualAtPos(Classname, "pills", 7)) return 4;
		return 0;
	}
	return -1;
}

stock SurvivorPowerSlide(client) {
	float vel[3];
	vel[0]	=	GetEntPropFloat(client, Prop_Send, "m_vecVelocity[0]");
	vel[1]	=	GetEntPropFloat(client, Prop_Send, "m_vecVelocity[1]");
	vel[2]	=	GetEntPropFloat(client, Prop_Send, "m_vecVelocity[2]");

	if (vel[0] > 0.0) vel[0] += 100.0;
	else vel[0] -= 100.0;
	if (vel[1] > 0.0) vel[1] += 100.0;
	else vel[1] -= 100.0;
	TeleportEntity(client, NULL_VECTOR, NULL_VECTOR, vel);
}

stock BeanBag(client, float force) {

	if (IsLegitimateClientAlive(client)) {

		int myteam = myCurrentTeam[client];

		if (myteam == TEAM_INFECTED && L4D2_GetSurvivorVictim(client) != -1 || (GetEntityFlags(client) & FL_ONGROUND)) {

			float Velocity[3];

			Velocity[0]	=	GetEntPropFloat(client, Prop_Send, "m_vecVelocity[0]");
			Velocity[1]	=	GetEntPropFloat(client, Prop_Send, "m_vecVelocity[1]");
			Velocity[2]	=	GetEntPropFloat(client, Prop_Send, "m_vecVelocity[2]");

			float Vec_Pull;
			float Vec_Lunge;

			Vec_Pull	=	GetRandomFloat(force * -1.0, force);
			Vec_Lunge	=	GetRandomFloat(force * -1.0, force);
			Velocity[2]	+=	force;

			if (Vec_Pull < 0.0 && Velocity[0] > 0.0) Velocity[0] *= -1.0;
			Velocity[0] += Vec_Pull;

			if (Vec_Lunge < 0.0 && Velocity[1] > 0.0) Velocity[1] *= -1.0;
			Velocity[1] += Vec_Lunge;

			TeleportEntity(client, NULL_VECTOR, NULL_VECTOR, Velocity);
			if (myteam == TEAM_INFECTED) {

				int victim = L4D2_GetSurvivorVictim(client);
				if (victim != -1) TeleportEntity(victim, NULL_VECTOR, NULL_VECTOR, Velocity);
			}
		}
	}
}

stock CreateExplosion(client, damage = 0, attacker = 0, bool IsAOE = false, float fRange = 96.0) {

	int entity 				= CreateEntityByName("env_explosion");
	float loc[3];
	float tloc[3];
	int totalIncomingDamage = damage, aClient = 0;
	if (IsLegitimateClientAlive(client) && myCurrentTeam[client] == TEAM_INFECTED) aClient = client;
	if (IsLegitimateClientAlive(client)) GetClientAbsOrigin(client, loc);
	else GetEntPropVector(client, Prop_Send, "m_vecOrigin", loc);

	DispatchKeyValue(entity, "fireballsprite", "sprites/zerogxplode.spr");
	DispatchKeyValue(entity, "iMagnitude", "0");	// we don't want the fireball dealing damage - we do this manually.
	DispatchKeyValue(entity, "iRadiusOverride", "0");
	DispatchKeyValue(entity, "rendermode", "5");
	DispatchKeyValue(entity, "spawnflags", "0");
	DispatchSpawn(entity);
	TeleportEntity(entity, loc, NULL_VECTOR, NULL_VECTOR);
	AcceptEntityInput(entity, "explode");

	int zombieclass = -1;
	if (aClient > 0) zombieclass = FindZombieClass(client);
	if (damage > 0 || zombieclass == ZOMBIECLASS_TANK) {
		if (IsAOE) {
			for (int i = 1; i <= MaxClients; i++) {
				if (!IsLegitimateClientAlive(i)) continue;
				if (myCurrentTeam[i] != TEAM_SURVIVOR) continue;
				GetClientAbsOrigin(i, tloc);
				if (GetVectorDistance(loc, tloc) > fRange) continue;
				if (totalIncomingDamage > 0) {
					SetClientTotalHealth(aClient, i, totalIncomingDamage);
					if (aClient > 0 && myCurrentTeam[aClient] == TEAM_INFECTED) AddSpecialInfectedDamage(i, client, totalIncomingDamage, CONTRIBUTION_AWARD_TANKING);
				}
				if (zombieclass == ZOMBIECLASS_TANK) {
					// tank aoe jump explosion.
					ScreenShake(i);
				}
			}
			return;
		}

		if (IsWitch(client)) {

			if (FindListPositionByEntity(client, WitchList) >= 0) AddWitchDamage(attacker, client, damage);
			else OnWitchCreated(client);
		}
		else if (IsSpecialCommon(client)) AddSpecialCommonDamage(attacker, client, damage);
		else if (IsLegitimateClientAlive(client) && IsLegitimateClientAlive(attacker) && FindZombieClass(attacker) == ZOMBIECLASS_TANK) {
			if ((GetEntityFlags(client) & FL_ONGROUND)) {

				if (GetClientTotalHealth(client) <= totalIncomingDamage) ChangeTankState(attacker, "hulk", true);

				SetClientTotalHealth(attacker, client, totalIncomingDamage);
				AddSpecialInfectedDamage(client, attacker, totalIncomingDamage, CONTRIBUTION_AWARD_TANKING);	// bool is tanking instead.
			}
			else {

				// If a player follows the mechanic successfully, hulk ends and changes to death state.

				//ChangeTankState(attacker, "hulk", true);
				//ChangeTankState(attacker, "death");
			}
		}
	}
}

stock CreateAmmoExplosion(client, float PosX=0.0, float PosY=0.0, float PosZ=0.0) {

	int entity 				= CreateEntityByName("env_explosion");
	float loc[3];
	loc[0] = PosX;
	loc[1] = PosY;
	loc[2] = PosZ;

	DispatchKeyValue(entity, "fireballsprite", "sprites/zerogxplode.spr");
	DispatchKeyValue(entity, "iMagnitude", "0");	// we don't want the fireball dealing damage - we do this manually.
	DispatchKeyValue(entity, "iRadiusOverride", "0");
	DispatchKeyValue(entity, "rendermode", "5");
	DispatchKeyValue(entity, "spawnflags", "0");
	DispatchSpawn(entity);
	TeleportEntity(entity, loc, NULL_VECTOR, NULL_VECTOR);
	AcceptEntityInput(entity, "explode");
}

stock ScreenShake(int client, char[] amp = "16.0", char[] freq = "1.5", char[] dur = "0.9") {
	int entity = CreateEntityByName("env_shake");

	float loc[3];
	GetClientAbsOrigin(client, loc);

	if(entity >= 0) {
		DispatchKeyValue(entity, "spawnflags", "8");
		DispatchKeyValue(entity, "amplitude", amp);
		DispatchKeyValue(entity, "frequency", freq);
		DispatchKeyValue(entity, "duration", dur);
		DispatchKeyValue(entity, "radius", "0.0");
		DispatchSpawn(entity);
		ActivateEntity(entity);
		AcceptEntityInput(entity, "Enable");
		TeleportEntity(entity, loc, NULL_VECTOR, NULL_VECTOR);
		AcceptEntityInput(entity, "StartShake");
		SetVariantString("OnUser1 !self:Kill::1.1:1");
		AcceptEntityInput(entity, "AddOutput");
		AcceptEntityInput(entity, "FireUser1");
	}
}

stock ZeroGravity(client, victim, float g_TalentStrength, float g_TalentTime) {

	if (IsLegitimateClientAlive(client) && IsLegitimateClientAlive(victim)) {

		if (L4D2_GetSurvivorVictim(victim) != -1 || ((GetEntityFlags(victim) & FL_ONGROUND) || !b_GroundRequired[victim])) {


		//if (GetEntityFlags(victim) & FL_ONGROUND || !b_GroundRequired[victim]) {

			//if (ZeroGravityTimer[victim] == INVALID_HANDLE) {

			float vel[3];
			vel[0] = GetEntPropFloat(victim, Prop_Send, "m_vecVelocity[0]");
			vel[1] = GetEntPropFloat(victim, Prop_Send, "m_vecVelocity[1]");
			vel[2] = GetEntPropFloat(victim, Prop_Send, "m_vecVelocity[2]");
			//ZeroGravityTimer[victim] = 
			CreateTimer(g_TalentTime, Timer_ZeroGravity, victim, TIMER_FLAG_NO_MAPCHANGE);
			SetEntityGravity(victim, GravityBase[victim] - g_TalentStrength);
			TeleportEntity(victim, NULL_VECTOR, NULL_VECTOR, vel);

			int survivor = L4D2_GetSurvivorVictim(victim);
			if (survivor != -1) {

				//ZeroGravityTimer[survivor] = 
				CreateTimer(g_TalentTime, Timer_ZeroGravity, survivor, TIMER_FLAG_NO_MAPCHANGE);
				SetEntityGravity(survivor, GravityBase[survivor] - g_TalentStrength);
				TeleportEntity(survivor, NULL_VECTOR, NULL_VECTOR, vel);
			}
			//}
		}
	}
}

stock SlowPlayer(client, float g_TalentStrength, float g_TalentTime) {

	if (IsLegitimateClientAlive(client) && !ISSLOW[client]) {

		//if (SlowMultiplierTimer[client] != INVALID_HANDLE) {

		//	KillTimer(SlowMultiplierTimer[client]);
		//	SlowMultiplierTimer[client] = INVALID_HANDLE;
		//}
		//SlowMultiplierTimer[client] = 
		ISSLOW[client] = true;
		CreateTimer(g_TalentTime, Timer_Slow, client, TIMER_FLAG_NO_MAPCHANGE);
		fSlowSpeed[client] = g_TalentStrength;
	}
}

/*stock CreateLineSoloEx(client, target, int menuPos, float lifetime = 0.5, targetClient = 0) {

	float ClientPos[3];
	float TargetPos[3];
	if (IsLegitimateClient(client)) GetClientAbsOrigin(client, ClientPos);
	else GetEntPropVector(client, Prop_Send, "m_vecOrigin", ClientPos);
	if (IsLegitimateClient(target)) GetClientAbsOrigin(target, TargetPos);
	else GetEntPropVector(target, Prop_Send, "m_vecOrigin", TargetPos);

	int colorsToDraw = GetArrayCell(TalentDrawColors, menuPos);
	int colorsPositions = GetArrayCell(TalentDrawPositions, menuPos);
	// these are paired so if the user creating the talent files does it wrong, then it's the parsers job to catch that and not try to draw the missing value.
	if (colorsToDraw != colorsPositions) {
		if (colorsToDraw < colorsPositions) colorsPositions = colorsToDraw;
		else colorsToDraw = colorsPositions;
	}
	for (int i = 1; i <= colorsToDraw; i++) {
		float fDrawPos = GetArrayCell(TalentDrawPositions, menuPos, i);
		ClientPos[2] += fDrawPos;
		TargetPos[2] += fDrawPos;

		int color = GetArrayCell(TalentDrawColors, menuPos, i);
		if (color == 0) TE_SetupBeamPoints(ClientPos, TargetPos, g_iSprite, g_BeaconSprite, 0, 15, lifetime, 2.0, 0.5, 0, 0.5, {0, 255, 0, 200}, 50);
		else if (color == 1) TE_SetupBeamPoints(ClientPos, TargetPos, g_iSprite, g_BeaconSprite, 0, 15, lifetime, 2.0, 0.5, 0, 0.5, {255, 0, 0, 200}, 50);
		else if (color == 2) TE_SetupBeamPoints(ClientPos, TargetPos, g_iSprite, g_BeaconSprite, 0, 15, lifetime, 2.0, 0.5, 0, 0.5, {0, 0, 255, 200}, 50);
		else if (color == 3) TE_SetupBeamPoints(ClientPos, TargetPos, g_iSprite, g_BeaconSprite, 0, 15, lifetime, 2.0, 0.5, 0, 0.5, {255, 0, 255, 200}, 50);
		else if (color == 4) TE_SetupBeamPoints(ClientPos, TargetPos, g_iSprite, g_BeaconSprite, 0, 15, lifetime, 2.0, 0.5, 0, 0.5, {255, 255, 0, 200}, 50);
		else if (color == 5) TE_SetupBeamPoints(ClientPos, TargetPos, g_iSprite, g_BeaconSprite, 0, 15, lifetime, 2.0, 0.5, 0, 0.5, {255, 69, 0, 200}, 50);
		else if (color == 6) TE_SetupBeamPoints(ClientPos, TargetPos, g_iSprite, g_BeaconSprite, 0, 15, lifetime, 2.0, 0.5, 0, 0.5, {0, 0, 0, 200}, 50);
		else if (color == 7) TE_SetupBeamPoints(ClientPos, TargetPos, g_iSprite, g_BeaconSprite, 0, 15, lifetime, 2.0, 0.5, 0, 0.5, {132, 112, 255, 200}, 50);
		else if (color == 8) TE_SetupBeamPoints(ClientPos, TargetPos, g_iSprite, g_BeaconSprite, 0, 15, lifetime, 2.0, 0.5, 0, 0.5, {178, 34, 34, 200}, 50);
		else if (color == 9) TE_SetupBeamPoints(ClientPos, TargetPos, g_iSprite, g_BeaconSprite, 0, 15, lifetime, 2.0, 0.5, 0, 0.5, {255, 255, 255, 200}, 50);
		else return 0;
		TE_SendToClient(targetClient);
	}
	return 1;
}*/

stock CreateRingForCommonEffect(client, float RingAreaSize, int menuPos, bool IsPulsing = true, float lifetime = 1.0, targetClient, float PosX=0.0, float PosY=0.0, float PosZ=0.0) {
	float ClientPos[3];
	if (client != -1) {
		if (IsLegitimateClient(client)) GetClientAbsOrigin(client, ClientPos);
		else GetEntPropVector(client, Prop_Send, "m_vecOrigin", ClientPos);
	}
	else {
		ClientPos[0] = PosX;
		ClientPos[1] = PosY;
		ClientPos[2] = PosZ;
	}
	float pulserange = 0.0;
	if (IsPulsing) pulserange = 32.0;
	else pulserange = RingAreaSize - 32.0;

	int colorsToDraw = GetArrayCell(CommonDrawColors, menuPos);
	int colorsPositions = GetArrayCell(CommonDrawPositions, menuPos);
	// these are paired so if the user creating the talent files does it wrong, then it's the parsers job to catch that and not try to draw the missing value.
	if (colorsToDraw != colorsPositions) {
		if (colorsToDraw < colorsPositions) colorsPositions = colorsToDraw;
		else colorsToDraw = colorsPositions;
	}
	for (int i = 1; i <= colorsToDraw; i++) {
		float fDrawPos = GetArrayCell(CommonDrawPositions, menuPos, i);
		ClientPos[2] += fDrawPos;

		int color = GetArrayCell(CommonDrawColors, menuPos, i);
		if (color == 0) TE_SetupBeamRingPoint(ClientPos, pulserange, RingAreaSize, g_iSprite, g_BeaconSprite, 0, 15, lifetime, 2.0, 0.5, {0, 255, 0, 200}, 50, 0);
		else if (color == 1) TE_SetupBeamRingPoint(ClientPos, pulserange, RingAreaSize, g_iSprite, g_BeaconSprite, 0, 15, lifetime, 2.0, 0.5, {255, 0, 0, 200}, 50, 0);
		else if (color == 2) TE_SetupBeamRingPoint(ClientPos, pulserange, RingAreaSize, g_iSprite, g_BeaconSprite, 0, 15, lifetime, 2.0, 0.5, {0, 0, 255, 200}, 50, 0);
		else if (color == 3) TE_SetupBeamRingPoint(ClientPos, pulserange, RingAreaSize, g_iSprite, g_BeaconSprite, 0, 15, lifetime, 2.0, 0.5, {255, 0, 255, 200}, 50, 0);
		else if (color == 4) TE_SetupBeamRingPoint(ClientPos, pulserange, RingAreaSize, g_iSprite, g_BeaconSprite, 0, 15, lifetime, 2.0, 0.5, {255, 255, 0, 200}, 50, 0);
		else if (color == 5) TE_SetupBeamRingPoint(ClientPos, pulserange, RingAreaSize, g_iSprite, g_BeaconSprite, 0, 15, lifetime, 2.0, 0.5, {255, 69, 0, 200}, 50, 0);
		else if (color == 6) TE_SetupBeamRingPoint(ClientPos, pulserange, RingAreaSize, g_iSprite, g_BeaconSprite, 0, 15, lifetime, 2.0, 0.5, {0, 0, 0, 200}, 50, 0);
		else if (color == 7) TE_SetupBeamRingPoint(ClientPos, pulserange, RingAreaSize, g_iSprite, g_BeaconSprite, 0, 15, lifetime, 2.0, 0.5, {132, 112, 255, 200}, 50, 0);
		else if (color == 8) TE_SetupBeamRingPoint(ClientPos, pulserange, RingAreaSize, g_iSprite, g_BeaconSprite, 0, 15, lifetime, 2.0, 0.5, {178, 34, 34, 200}, 50, 0);
		else if (color == 9) TE_SetupBeamRingPoint(ClientPos, pulserange, RingAreaSize, g_iSprite, g_BeaconSprite, 0, 15, lifetime, 2.0, 0.5, {255, 255, 255, 200}, 50, 0);
		else return 0;
		TE_SendToClient(targetClient);
	}
	return 1;
}

stock CreateRingSoloEx(client, float RingAreaSize, int menuPos, bool IsPulsing = true, float lifetime = 1.0, targetClient, float PosX=0.0, float PosY=0.0, float PosZ=0.0) {
	float ClientPos[3];
	if (client != -1) {
		if (IsLegitimateClient(client)) GetClientAbsOrigin(client, ClientPos);
		else GetEntPropVector(client, Prop_Send, "m_vecOrigin", ClientPos);
	}
	else {
		ClientPos[0] = PosX;
		ClientPos[1] = PosY;
		ClientPos[2] = PosZ;
	}
	float pulserange = 0.0;
	if (IsPulsing) pulserange = 32.0;
	else pulserange = RingAreaSize - 32.0;

	int colorsToDraw = GetArrayCell(TalentDrawColors, menuPos);
	int colorsPositions = GetArrayCell(TalentDrawPositions, menuPos);
	// these are paired so if the user creating the talent files does it wrong, then it's the parsers job to catch that and not try to draw the missing value.
	if (colorsToDraw != colorsPositions) {
		if (colorsToDraw < colorsPositions) colorsPositions = colorsToDraw;
		else colorsToDraw = colorsPositions;
	}
	for (int i = 1; i <= colorsToDraw; i++) {
		float fDrawPos = GetArrayCell(TalentDrawPositions, menuPos, i);
		ClientPos[2] += fDrawPos;

		int color = GetArrayCell(TalentDrawColors, menuPos, i);
		if (color == 0) TE_SetupBeamRingPoint(ClientPos, pulserange, RingAreaSize, g_iSprite, g_BeaconSprite, 0, 15, lifetime, 2.0, 0.5, {0, 255, 0, 200}, 50, 0);
		else if (color == 1) TE_SetupBeamRingPoint(ClientPos, pulserange, RingAreaSize, g_iSprite, g_BeaconSprite, 0, 15, lifetime, 2.0, 0.5, {255, 0, 0, 200}, 50, 0);
		else if (color == 2) TE_SetupBeamRingPoint(ClientPos, pulserange, RingAreaSize, g_iSprite, g_BeaconSprite, 0, 15, lifetime, 2.0, 0.5, {0, 0, 255, 200}, 50, 0);
		else if (color == 3) TE_SetupBeamRingPoint(ClientPos, pulserange, RingAreaSize, g_iSprite, g_BeaconSprite, 0, 15, lifetime, 2.0, 0.5, {255, 0, 255, 200}, 50, 0);
		else if (color == 4) TE_SetupBeamRingPoint(ClientPos, pulserange, RingAreaSize, g_iSprite, g_BeaconSprite, 0, 15, lifetime, 2.0, 0.5, {255, 255, 0, 200}, 50, 0);
		else if (color == 5) TE_SetupBeamRingPoint(ClientPos, pulserange, RingAreaSize, g_iSprite, g_BeaconSprite, 0, 15, lifetime, 2.0, 0.5, {255, 69, 0, 200}, 50, 0);
		else if (color == 6) TE_SetupBeamRingPoint(ClientPos, pulserange, RingAreaSize, g_iSprite, g_BeaconSprite, 0, 15, lifetime, 2.0, 0.5, {0, 0, 0, 200}, 50, 0);
		else if (color == 7) TE_SetupBeamRingPoint(ClientPos, pulserange, RingAreaSize, g_iSprite, g_BeaconSprite, 0, 15, lifetime, 2.0, 0.5, {132, 112, 255, 200}, 50, 0);
		else if (color == 8) TE_SetupBeamRingPoint(ClientPos, pulserange, RingAreaSize, g_iSprite, g_BeaconSprite, 0, 15, lifetime, 2.0, 0.5, {178, 34, 34, 200}, 50, 0);
		else if (color == 9) TE_SetupBeamRingPoint(ClientPos, pulserange, RingAreaSize, g_iSprite, g_BeaconSprite, 0, 15, lifetime, 2.0, 0.5, {255, 255, 255, 200}, 50, 0);
		else return 0;
		TE_SendToClient(targetClient);
	}
	return 1;
}
stock CreateRingEffectType0(int client, int menuPos, bool IsPulsing = true, float lifetime = 1.0) {
	float ClientPos[3];
	GetEntPropVector(client, Prop_Send, "m_vecOrigin", ClientPos);

	float pulserange = 0.0;
	if (IsPulsing) pulserange = 32.0;

	int colorsToDraw = GetArrayCell(TalentInstantColors, menuPos);
	// these are paired so if the user creating the talent files does it wrong, then it's the parsers job to catch that and not try to draw the missing value.
	for (int i = 1; i <= colorsToDraw; i++) {
		float fDrawPos = GetArrayCell(TalentInstantPositions, menuPos, i);
		ClientPos[2] += fDrawPos;

		float RingAreaSize = GetArrayCell(TalentInstantSizes, menuPos, i);
		if (!IsPulsing) pulserange = RingAreaSize - 32.0;
		int color = GetArrayCell(TalentInstantColors, menuPos, i);
		if (color == 0) TE_SetupBeamRingPoint(ClientPos, pulserange, RingAreaSize, g_iSprite, g_BeaconSprite, 0, 15, lifetime, 2.0, 0.5, {0, 255, 0, 200}, 50, 0);
		else if (color == 1) TE_SetupBeamRingPoint(ClientPos, pulserange, RingAreaSize, g_iSprite, g_BeaconSprite, 0, 15, lifetime, 2.0, 0.5, {255, 0, 0, 200}, 50, 0);
		else if (color == 2) TE_SetupBeamRingPoint(ClientPos, pulserange, RingAreaSize, g_iSprite, g_BeaconSprite, 0, 15, lifetime, 2.0, 0.5, {0, 0, 255, 200}, 50, 0);
		else if (color == 3) TE_SetupBeamRingPoint(ClientPos, pulserange, RingAreaSize, g_iSprite, g_BeaconSprite, 0, 15, lifetime, 2.0, 0.5, {255, 0, 255, 200}, 50, 0);
		else if (color == 4) TE_SetupBeamRingPoint(ClientPos, pulserange, RingAreaSize, g_iSprite, g_BeaconSprite, 0, 15, lifetime, 2.0, 0.5, {255, 255, 0, 200}, 50, 0);
		else if (color == 5) TE_SetupBeamRingPoint(ClientPos, pulserange, RingAreaSize, g_iSprite, g_BeaconSprite, 0, 15, lifetime, 2.0, 0.5, {255, 69, 0, 200}, 50, 0);
		else if (color == 6) TE_SetupBeamRingPoint(ClientPos, pulserange, RingAreaSize, g_iSprite, g_BeaconSprite, 0, 15, lifetime, 2.0, 0.5, {0, 0, 0, 200}, 50, 0);
		else if (color == 7) TE_SetupBeamRingPoint(ClientPos, pulserange, RingAreaSize, g_iSprite, g_BeaconSprite, 0, 15, lifetime, 2.0, 0.5, {132, 112, 255, 200}, 50, 0);
		else if (color == 8) TE_SetupBeamRingPoint(ClientPos, pulserange, RingAreaSize, g_iSprite, g_BeaconSprite, 0, 15, lifetime, 2.0, 0.5, {178, 34, 34, 200}, 50, 0);
		else if (color == 9) TE_SetupBeamRingPoint(ClientPos, pulserange, RingAreaSize, g_iSprite, g_BeaconSprite, 0, 15, lifetime, 2.0, 0.5, {255, 255, 255, 200}, 50, 0);
		else return 0;
		TE_SendToAll();
	}
	return 1;
}

stock CreateRingEffectType1(int client, int menuPos, bool IsPulsing = true, float lifetime = 1.0) {
	float ClientPos[3];
	GetEntPropVector(client, Prop_Send, "m_vecOrigin", ClientPos);

	float pulserange = 0.0;
	if (IsPulsing) pulserange = 32.0;

	int colorsToDraw = GetArrayCell(TalentActiveColors, menuPos);
	// these are paired so if the user creating the talent files does it wrong, then it's the parsers job to catch that and not try to draw the missing value.
	for (int i = 1; i <= colorsToDraw; i++) {
		float fDrawPos = GetArrayCell(TalentActivePositions, menuPos, i);
		ClientPos[2] += fDrawPos;

		float RingAreaSize = GetArrayCell(TalentActiveSizes, menuPos, i);
		if (!IsPulsing) pulserange = RingAreaSize - 32.0;
		int color = GetArrayCell(TalentActiveColors, menuPos, i);
		if (color == 0) TE_SetupBeamRingPoint(ClientPos, pulserange, RingAreaSize, g_iSprite, g_BeaconSprite, 0, 15, lifetime, 2.0, 0.5, {0, 255, 0, 200}, 50, 0);
		else if (color == 1) TE_SetupBeamRingPoint(ClientPos, pulserange, RingAreaSize, g_iSprite, g_BeaconSprite, 0, 15, lifetime, 2.0, 0.5, {255, 0, 0, 200}, 50, 0);
		else if (color == 2) TE_SetupBeamRingPoint(ClientPos, pulserange, RingAreaSize, g_iSprite, g_BeaconSprite, 0, 15, lifetime, 2.0, 0.5, {0, 0, 255, 200}, 50, 0);
		else if (color == 3) TE_SetupBeamRingPoint(ClientPos, pulserange, RingAreaSize, g_iSprite, g_BeaconSprite, 0, 15, lifetime, 2.0, 0.5, {255, 0, 255, 200}, 50, 0);
		else if (color == 4) TE_SetupBeamRingPoint(ClientPos, pulserange, RingAreaSize, g_iSprite, g_BeaconSprite, 0, 15, lifetime, 2.0, 0.5, {255, 255, 0, 200}, 50, 0);
		else if (color == 5) TE_SetupBeamRingPoint(ClientPos, pulserange, RingAreaSize, g_iSprite, g_BeaconSprite, 0, 15, lifetime, 2.0, 0.5, {255, 69, 0, 200}, 50, 0);
		else if (color == 6) TE_SetupBeamRingPoint(ClientPos, pulserange, RingAreaSize, g_iSprite, g_BeaconSprite, 0, 15, lifetime, 2.0, 0.5, {0, 0, 0, 200}, 50, 0);
		else if (color == 7) TE_SetupBeamRingPoint(ClientPos, pulserange, RingAreaSize, g_iSprite, g_BeaconSprite, 0, 15, lifetime, 2.0, 0.5, {132, 112, 255, 200}, 50, 0);
		else if (color == 8) TE_SetupBeamRingPoint(ClientPos, pulserange, RingAreaSize, g_iSprite, g_BeaconSprite, 0, 15, lifetime, 2.0, 0.5, {178, 34, 34, 200}, 50, 0);
		else if (color == 9) TE_SetupBeamRingPoint(ClientPos, pulserange, RingAreaSize, g_iSprite, g_BeaconSprite, 0, 15, lifetime, 2.0, 0.5, {255, 255, 255, 200}, 50, 0);
		else return 0;
		TE_SendToAll();
	}
	return 1;
}

stock CreateRingEffectType2(int client, int menuPos, bool IsPulsing = true, float lifetime = 1.0) {
	float ClientPos[3];
	GetEntPropVector(client, Prop_Send, "m_vecOrigin", ClientPos);

	float pulserange = 0.0;
	if (IsPulsing) pulserange = 32.0;

	int colorsToDraw = GetArrayCell(TalentPassiveColors, menuPos);
	// these are paired so if the user creating the talent files does it wrong, then it's the parsers job to catch that and not try to draw the missing value.
	for (int i = 1; i <= colorsToDraw; i++) {
		float fDrawPos = GetArrayCell(TalentPassivePositions, menuPos, i);
		ClientPos[2] += fDrawPos;

		float RingAreaSize = GetArrayCell(TalentPassiveSizes, menuPos, i);
		if (!IsPulsing) pulserange = RingAreaSize - 32.0;
		int color = GetArrayCell(TalentPassiveColors, menuPos, i);
		if (color == 0) TE_SetupBeamRingPoint(ClientPos, pulserange, RingAreaSize, g_iSprite, g_BeaconSprite, 0, 15, lifetime, 2.0, 0.5, {0, 255, 0, 200}, 50, 0);
		else if (color == 1) TE_SetupBeamRingPoint(ClientPos, pulserange, RingAreaSize, g_iSprite, g_BeaconSprite, 0, 15, lifetime, 2.0, 0.5, {255, 0, 0, 200}, 50, 0);
		else if (color == 2) TE_SetupBeamRingPoint(ClientPos, pulserange, RingAreaSize, g_iSprite, g_BeaconSprite, 0, 15, lifetime, 2.0, 0.5, {0, 0, 255, 200}, 50, 0);
		else if (color == 3) TE_SetupBeamRingPoint(ClientPos, pulserange, RingAreaSize, g_iSprite, g_BeaconSprite, 0, 15, lifetime, 2.0, 0.5, {255, 0, 255, 200}, 50, 0);
		else if (color == 4) TE_SetupBeamRingPoint(ClientPos, pulserange, RingAreaSize, g_iSprite, g_BeaconSprite, 0, 15, lifetime, 2.0, 0.5, {255, 255, 0, 200}, 50, 0);
		else if (color == 5) TE_SetupBeamRingPoint(ClientPos, pulserange, RingAreaSize, g_iSprite, g_BeaconSprite, 0, 15, lifetime, 2.0, 0.5, {255, 69, 0, 200}, 50, 0);
		else if (color == 6) TE_SetupBeamRingPoint(ClientPos, pulserange, RingAreaSize, g_iSprite, g_BeaconSprite, 0, 15, lifetime, 2.0, 0.5, {0, 0, 0, 200}, 50, 0);
		else if (color == 7) TE_SetupBeamRingPoint(ClientPos, pulserange, RingAreaSize, g_iSprite, g_BeaconSprite, 0, 15, lifetime, 2.0, 0.5, {132, 112, 255, 200}, 50, 0);
		else if (color == 8) TE_SetupBeamRingPoint(ClientPos, pulserange, RingAreaSize, g_iSprite, g_BeaconSprite, 0, 15, lifetime, 2.0, 0.5, {178, 34, 34, 200}, 50, 0);
		else if (color == 9) TE_SetupBeamRingPoint(ClientPos, pulserange, RingAreaSize, g_iSprite, g_BeaconSprite, 0, 15, lifetime, 2.0, 0.5, {255, 255, 255, 200}, 50, 0);
		else return 0;
		TE_SendToAll();
	}
	return 1;
}

/*stock CreateLineSolo(client, target, int menuPos, float lifetime = 0.5, targetClient = 0) {

	float ClientPos[3];
	float TargetPos[3];
	if (IsLegitimateClient(client)) GetClientAbsOrigin(client, ClientPos);
	else GetEntPropVector(client, Prop_Send, "m_vecOrigin", ClientPos);
	if (IsLegitimateClient(target)) GetClientAbsOrigin(target, TargetPos);
	else GetEntPropVector(target, Prop_Send, "m_vecOrigin", TargetPos);

	int colorsToDraw = GetArrayCell(TalentDrawColors, menuPos);
	int colorsPositions = GetArrayCell(TalentDrawPositions, menuPos);
	// these are paired so if the user creating the talent files does it wrong, then it's the parsers job to catch that and not try to draw the missing value.
	if (colorsToDraw != colorsPositions) {
		if (colorsToDraw < colorsPositions) colorsPositions = colorsToDraw;
		else colorsToDraw = colorsPositions;
	}
	for (int i = 1; i <= colorsToDraw; i++) {
		float fDrawPos = GetArrayCell(TalentDrawPositions, menuPos, i);
		ClientPos[2] += fDrawPos;
		TargetPos[2] += fDrawPos;

		int color = GetArrayCell(TalentDrawColors, menuPos, i);
		if (color == 0) TE_SetupBeamPoints(ClientPos, TargetPos, g_iSprite, g_BeaconSprite, 0, 15, lifetime, 2.0, 0.5, 0, 0.5, {0, 255, 0, 200}, 50);
		else if (color == 1) TE_SetupBeamPoints(ClientPos, TargetPos, g_iSprite, g_BeaconSprite, 0, 15, lifetime, 2.0, 0.5, 0, 0.5, {255, 0, 0, 200}, 50);
		else if (color == 2) TE_SetupBeamPoints(ClientPos, TargetPos, g_iSprite, g_BeaconSprite, 0, 15, lifetime, 2.0, 0.5, 0, 0.5, {0, 0, 255, 200}, 50);
		else if (color == 3) TE_SetupBeamPoints(ClientPos, TargetPos, g_iSprite, g_BeaconSprite, 0, 15, lifetime, 2.0, 0.5, 0, 0.5, {255, 0, 255, 200}, 50);
		else if (color == 4) TE_SetupBeamPoints(ClientPos, TargetPos, g_iSprite, g_BeaconSprite, 0, 15, lifetime, 2.0, 0.5, 0, 0.5, {255, 255, 0, 200}, 50);
		else if (color == 5) TE_SetupBeamPoints(ClientPos, TargetPos, g_iSprite, g_BeaconSprite, 0, 15, lifetime, 2.0, 0.5, 0, 0.5, {255, 69, 0, 200}, 50);
		else if (color == 6) TE_SetupBeamPoints(ClientPos, TargetPos, g_iSprite, g_BeaconSprite, 0, 15, lifetime, 2.0, 0.5, 0, 0.5, {0, 0, 0, 200}, 50);
		else if (color == 7) TE_SetupBeamPoints(ClientPos, TargetPos, g_iSprite, g_BeaconSprite, 0, 15, lifetime, 2.0, 0.5, 0, 0.5, {132, 112, 255, 200}, 50);
		else if (color == 8) TE_SetupBeamPoints(ClientPos, TargetPos, g_iSprite, g_BeaconSprite, 0, 15, lifetime, 2.0, 0.5, 0, 0.5, {178, 34, 34, 200}, 50);
		else if (color == 9) TE_SetupBeamPoints(ClientPos, TargetPos, g_iSprite, g_BeaconSprite, 0, 15, lifetime, 2.0, 0.5, 0, 0.5, {255, 255, 255, 200}, 50);
		else continue;
		TE_SendToClient(targetClient);
	}
}*/

stock CreateRingFromSuperSolo(client, float RingAreaSize, int menuPos, bool IsPulsing = true, float lifetime = 1.0, targetClient, float PosX=0.0, float PosY=0.0, float PosZ=0.0) {

	float ClientPos[3];
	//if (!IsWitch(client) && !IsCommonInfected(client)) GetClientAbsOrigin(client, ClientPos);
	if (client != -1) {

		if (IsLegitimateClient(client)) GetClientAbsOrigin(client, ClientPos);
		else GetEntPropVector(client, Prop_Send, "m_vecOrigin", ClientPos);
	}
	else {

		ClientPos[0] = PosX;
		ClientPos[1] = PosY;
		ClientPos[2] = PosZ;
	}

	float pulserange = 0.0;
	if (IsPulsing) pulserange = 32.0;
	else pulserange = RingAreaSize - 32.0;

	int colorsToDraw = GetArrayCell(TalentDrawColors, menuPos);
	int colorsPositions = GetArrayCell(TalentDrawPositions, menuPos);
	// these are paired so if the user creating the talent files does it wrong, then it's the parsers job to catch that and not try to draw the missing value.
	if (colorsToDraw != colorsPositions) {
		if (colorsToDraw < colorsPositions) colorsPositions = colorsToDraw;
		else colorsToDraw = colorsPositions;
	}
	for (int i = 1; i <= colorsToDraw; i++) {
		float fDrawPos = GetArrayCell(TalentDrawPositions, menuPos, i);
		ClientPos[2] += fDrawPos;

		int color = GetArrayCell(TalentDrawColors, menuPos, i);
		if (color == 0) TE_SetupBeamRingPoint(ClientPos, pulserange, RingAreaSize, g_iSprite, g_BeaconSprite, 0, 15, lifetime, 2.0, 0.5, {0, 255, 0, 200}, 50, 0);
		else if (color == 1) TE_SetupBeamRingPoint(ClientPos, pulserange, RingAreaSize, g_iSprite, g_BeaconSprite, 0, 15, lifetime, 2.0, 0.5, {255, 0, 0, 200}, 50, 0);
		else if (color == 2) TE_SetupBeamRingPoint(ClientPos, pulserange, RingAreaSize, g_iSprite, g_BeaconSprite, 0, 15, lifetime, 2.0, 0.5, {0, 0, 255, 200}, 50, 0);
		else if (color == 3) TE_SetupBeamRingPoint(ClientPos, pulserange, RingAreaSize, g_iSprite, g_BeaconSprite, 0, 15, lifetime, 2.0, 0.5, {255, 0, 255, 200}, 50, 0);
		else if (color == 4) TE_SetupBeamRingPoint(ClientPos, pulserange, RingAreaSize, g_iSprite, g_BeaconSprite, 0, 15, lifetime, 2.0, 0.5, {255, 255, 0, 200}, 50, 0);
		else if (color == 5) TE_SetupBeamRingPoint(ClientPos, pulserange, RingAreaSize, g_iSprite, g_BeaconSprite, 0, 15, lifetime, 2.0, 0.5, {255, 69, 0, 200}, 50, 0);
		else if (color == 6) TE_SetupBeamRingPoint(ClientPos, pulserange, RingAreaSize, g_iSprite, g_BeaconSprite, 0, 15, lifetime, 2.0, 0.5, {0, 0, 0, 200}, 50, 0);
		else if (color == 7) TE_SetupBeamRingPoint(ClientPos, pulserange, RingAreaSize, g_iSprite, g_BeaconSprite, 0, 15, lifetime, 2.0, 0.5, {132, 112, 255, 200}, 50, 0);
		else if (color == 8) TE_SetupBeamRingPoint(ClientPos, pulserange, RingAreaSize, g_iSprite, g_BeaconSprite, 0, 15, lifetime, 2.0, 0.5, {178, 34, 34, 200}, 50, 0);
		else if (color == 9) TE_SetupBeamRingPoint(ClientPos, pulserange, RingAreaSize, g_iSprite, g_BeaconSprite, 0, 15, lifetime, 2.0, 0.5, {255, 255, 255, 200}, 50, 0);
		else continue;
		TE_SendToClient(targetClient);
	}
}

// line 840
/*stock CreateLine(client, target, int menuPos, float lifetime = 0.5, targetClient = 0) {

	float ClientPos[3];
	float TargetPos[3];
	if (IsLegitimateClient(client)) GetClientAbsOrigin(client, ClientPos);
	else GetEntPropVector(client, Prop_Send, "m_vecOrigin", ClientPos);
	if (IsLegitimateClient(target)) GetClientAbsOrigin(target, TargetPos);
	else GetEntPropVector(target, Prop_Send, "m_vecOrigin", TargetPos);

	int colorsToDraw = GetArrayCell(TalentDrawColors, menuPos);
	int colorsPositions = GetArrayCell(TalentDrawPositions, menuPos);
	// these are paired so if the user creating the talent files does it wrong, then it's the parsers job to catch that and not try to draw the missing value.
	if (colorsToDraw != colorsPositions) {
		if (colorsToDraw < colorsPositions) colorsPositions = colorsToDraw;
		else colorsToDraw = colorsPositions;
	}
	for (int i = 1; i <= colorsToDraw; i++) {
		float fDrawPos = GetArrayCell(TalentDrawPositions, menuPos, i);
		ClientPos[2] += fDrawPos;
		TargetPos[2] += fDrawPos;

		int color = GetArrayCell(TalentDrawColors, menuPos, i);
		if (color == 0) TE_SetupBeamPoints(ClientPos, TargetPos, g_iSprite, g_BeaconSprite, 0, 15, lifetime, 2.0, 0.5, 0, 0.5, {0, 255, 0, 200}, 50);
		else if (color == 1) TE_SetupBeamPoints(ClientPos, TargetPos, g_iSprite, g_BeaconSprite, 0, 15, lifetime, 2.0, 0.5, 0, 0.5, {255, 0, 0, 200}, 50);
		else if (color == 2) TE_SetupBeamPoints(ClientPos, TargetPos, g_iSprite, g_BeaconSprite, 0, 15, lifetime, 2.0, 0.5, 0, 0.5, {0, 0, 255, 200}, 50);
		else if (color == 3) TE_SetupBeamPoints(ClientPos, TargetPos, g_iSprite, g_BeaconSprite, 0, 15, lifetime, 2.0, 0.5, 0, 0.5, {255, 0, 255, 200}, 50);
		else if (color == 4) TE_SetupBeamPoints(ClientPos, TargetPos, g_iSprite, g_BeaconSprite, 0, 15, lifetime, 2.0, 0.5, 0, 0.5, {255, 255, 0, 200}, 50);
		else if (color == 5) TE_SetupBeamPoints(ClientPos, TargetPos, g_iSprite, g_BeaconSprite, 0, 15, lifetime, 2.0, 0.5, 0, 0.5, {255, 69, 0, 200}, 50);
		else if (color == 6) TE_SetupBeamPoints(ClientPos, TargetPos, g_iSprite, g_BeaconSprite, 0, 15, lifetime, 2.0, 0.5, 0, 0.5, {0, 0, 0, 200}, 50);
		else if (color == 7) TE_SetupBeamPoints(ClientPos, TargetPos, g_iSprite, g_BeaconSprite, 0, 15, lifetime, 2.0, 0.5, 0, 0.5, {132, 112, 255, 200}, 50);
		else if (color == 8) TE_SetupBeamPoints(ClientPos, TargetPos, g_iSprite, g_BeaconSprite, 0, 15, lifetime, 2.0, 0.5, 0, 0.5, {178, 34, 34, 200}, 50);
		else if (color == 9) TE_SetupBeamPoints(ClientPos, TargetPos, g_iSprite, g_BeaconSprite, 0, 15, lifetime, 2.0, 0.5, 0, 0.5, {255, 255, 255, 200}, 50);
		else continue;
		TE_SendToAll();
	}
}*/

stock CreateExplosionRingOnClient(client, float fRange) {
	float ClientPos[3];
	GetEntPropVector(client, Prop_Send, "m_vecOrigin", ClientPos);
	TE_SetupBeamRingPoint(ClientPos, fRange - 32.0, fRange, g_iSprite, g_BeaconSprite, 0, 15, 0.5, 2.0, 0.5, {255, 0, 0, 200}, 50, 0);
	TE_SendToAll();
}

stock CreateHealingRingOnClient(client, float fRange) {
	float ClientPos[3];
	GetEntPropVector(client, Prop_Send, "m_vecOrigin", ClientPos);
	TE_SetupBeamRingPoint(ClientPos, fRange - 32.0, fRange, g_iSprite, g_BeaconSprite, 0, 15, 0.5, 2.0, 0.5, {0, 255, 0, 200}, 50, 0);
	TE_SendToAll();
}

stock CreateRing(client, float RingAreaSize, int menuPos, bool IsPulsing = true, float lifetime = 1.0, targetClient = 0, bool ringStartsAtMaxSize = false) {

	float ClientPos[3];
	if (IsLegitimateClient(client)) GetClientAbsOrigin(client, ClientPos);
	else GetEntPropVector(client, Prop_Send, "m_vecOrigin", ClientPos);

	float pulserange = (ringStartsAtMaxSize) ? RingAreaSize : (IsPulsing) ? 32.0 : RingAreaSize - 32.0;

	int colorsToDraw = GetArrayCell(TalentDrawColors, menuPos);
	int colorsPositions = GetArrayCell(TalentDrawPositions, menuPos);
	// these are paired so if the user creating the talent files does it wrong, then it's the parsers job to catch that and not try to draw the missing value.
	if (colorsToDraw != colorsPositions) {
		if (colorsToDraw < colorsPositions) colorsPositions = colorsToDraw;
		else colorsToDraw = colorsPositions;
	}
	for (int i = 1; i <= colorsToDraw; i++) {
		float fDrawPos = GetArrayCell(TalentDrawPositions, menuPos, i);
		ClientPos[2] += fDrawPos;

		int color = GetArrayCell(TalentDrawColors, menuPos, i);
		if (color == 0) TE_SetupBeamRingPoint(ClientPos, pulserange, RingAreaSize, g_iSprite, g_BeaconSprite, 0, 15, lifetime, 2.0, 0.5, {0, 255, 0, 200}, 50, 0);
		else if (color == 1) TE_SetupBeamRingPoint(ClientPos, pulserange, RingAreaSize, g_iSprite, g_BeaconSprite, 0, 15, lifetime, 2.0, 0.5, {255, 0, 0, 200}, 50, 0);
		else if (color == 2) TE_SetupBeamRingPoint(ClientPos, pulserange, RingAreaSize, g_iSprite, g_BeaconSprite, 0, 15, lifetime, 2.0, 0.5, {0, 0, 255, 200}, 50, 0);
		else if (color == 3) TE_SetupBeamRingPoint(ClientPos, pulserange, RingAreaSize, g_iSprite, g_BeaconSprite, 0, 15, lifetime, 2.0, 0.5, {255, 0, 255, 200}, 50, 0);
		else if (color == 4) TE_SetupBeamRingPoint(ClientPos, pulserange, RingAreaSize, g_iSprite, g_BeaconSprite, 0, 15, lifetime, 2.0, 0.5, {255, 255, 0, 200}, 50, 0);
		else if (color == 5) TE_SetupBeamRingPoint(ClientPos, pulserange, RingAreaSize, g_iSprite, g_BeaconSprite, 0, 15, lifetime, 2.0, 0.5, {255, 69, 0, 200}, 50, 0);
		else if (color == 6) TE_SetupBeamRingPoint(ClientPos, pulserange, RingAreaSize, g_iSprite, g_BeaconSprite, 0, 15, lifetime, 2.0, 0.5, {0, 0, 0, 200}, 50, 0);
		else if (color == 7) TE_SetupBeamRingPoint(ClientPos, pulserange, RingAreaSize, g_iSprite, g_BeaconSprite, 0, 15, lifetime, 2.0, 0.5, {132, 112, 255, 200}, 50, 0);
		else if (color == 8) TE_SetupBeamRingPoint(ClientPos, pulserange, RingAreaSize, g_iSprite, g_BeaconSprite, 0, 15, lifetime, 2.0, 0.5, {178, 34, 34, 200}, 50, 0);
		else if (color == 9) TE_SetupBeamRingPoint(ClientPos, pulserange, RingAreaSize, g_iSprite, g_BeaconSprite, 0, 15, lifetime, 2.0, 0.5, {255, 255, 255, 200}, 50, 0);
		else continue;
		TE_SendToAll();
	}
}

/*stock BeaconCorpsesInRange(client) {

	new Float:ClientPos[3];
	GetClientAbsOrigin(client, ClientPos);
	new Float:Pos[3];

	for (new i = 1; i <= MaxClients; i++) {

		if (!IsLegitimateClient(i) || myCurrentTeam[i] != TEAM_SURVIVOR || IsFakeClient(i) || IsPlayerAlive(i)) continue;
		if (GetVectorDistance(ClientPos, DeathLocation[i]) < 1024.0) {

			Pos[0] = DeathLocation[i][0];
			Pos[1] = DeathLocation[i][1];
			Pos[2] = DeathLocation[i][2] + 40.0;
			TE_SetupBeamRingPoint(Pos, 128.0, 256.0, g_iSprite, g_BeaconSprite, 0, 15, 0.5, 2.0, 0.5, {20, 20, 150, 150}, 50, 0);
			TE_SendToClient(client);
		}
	}
}*/

stock CreateBeacons(client, float Distance) {

	float Pos[3];
	float Pos2[3];

	GetClientAbsOrigin(client, Pos);
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsLegitimateClientAlive(i) && i != client && myCurrentTeam[i] != myCurrentTeam[client]) {

			GetClientAbsOrigin(i, Pos2);
			if (GetVectorDistance(Pos, Pos2) > Distance) continue;

			Pos2[2] += 20.0;
			TE_SetupBeamRingPoint(Pos2, 32.0, 128.0, g_iSprite, g_BeaconSprite, 0, 15, 0.5, 2.0, 0.5, {20, 20, 150, 150}, 50, 0);
			TE_SendToClient(client);
		}
	}
}

stock EnrageBlind(client, amount=0) {

	if (IsLegitimateClient(client) && !IsFakeClient(client)) {

		int clients[2];
		clients[0] = client;
		UserMsg BlindMsgID = GetUserMessageId("Fade");
		Handle message = StartMessageEx(BlindMsgID, clients, 1);
		BfWriteShort(message, 1536);
		BfWriteShort(message, 1536);
		
		if (amount == 0)
		{
			BfWriteShort(message, (0x0001 | 0x0010));
		}
		else
		{
			BfWriteShort(message, (0x0002 | 0x0008));
		}

		if (amount > 0) {

			BfWriteByte(message, 100);
			BfWriteByte(message, 20);
			BfWriteByte(message, 20);
		}
		else {

			BfWriteByte(message, 0);
			BfWriteByte(message, 0);
			BfWriteByte(message, 0);
		}
		BfWriteByte(message, amount);
		EndMessage();
	}
}

stock CreateFireEx(client) {
	float pos[3];
	GetEntPropVector(client, Prop_Send, "m_vecOrigin", pos);
	CreateFire(pos);
}

//static const String:MODEL_PIPEBOMB[] = "models/w_models/weapons/w_eq_pipebomb.mdl;"

static const char MODEL_GASCAN[] = "models/props_junk/gascan001a.mdl";
stock CreateFire(const float BombOrigin[3])
{
	int entity = CreateEntityByName("prop_physics");
	DispatchKeyValue(entity, "physdamagescale", "0.0");
	if (!IsModelPrecached(MODEL_GASCAN))
	{
		PrecacheModel(MODEL_GASCAN);
	}
	DispatchKeyValue(entity, "model", MODEL_GASCAN);
	DispatchSpawn(entity);
	TeleportEntity(entity, BombOrigin, NULL_VECTOR, NULL_VECTOR);
	SetEntityMoveType(entity, MOVETYPE_VPHYSICS);
	AcceptEntityInput(entity, "Break");
}

stock bool EnemyCombatantsWithinRange(client, float f_Distance) {

	float d_Client[3];
	float e_Client[3]
	GetClientAbsOrigin(client, d_Client);
	for (int i = 1; i <= MaxClients; i++) {

		if (IsLegitimateClient(i) && myCurrentTeam[i] != myCurrentTeam[client]) {

			GetClientAbsOrigin(i, e_Client);
			if (GetVectorDistance(d_Client, e_Client) <= f_Distance) return true;
		}
	}
	return false;
}

stock bool IsTanksActive() {

	for (int i = 1; i <= MaxClients; i++) {

		if (IsLegitimateClient(i) && myCurrentTeam[i] == TEAM_INFECTED && FindZombieClass(i) == ZOMBIECLASS_TANK) return true;
	}
	return false;
}

stock ModifyGravity(client, float g_Gravity = 0.8, float g_Time = 0.0, bool b_Jumping = false) {

	if (IsLegitimateClientAlive(client)) {

		//if (b_IsJumping[client]) return;	// survivors only, for the moon jump ability
		if (b_Jumping) {

			b_IsJumping[client] = true;
			CreateTimer(0.1, Timer_DetectGroundTouch, client, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
		}
		if (g_Gravity == 0.8) SetEntityGravity(client, g_Gravity);
		else {

			if (g_Gravity > 1.0 && g_Gravity < 100.0) g_Gravity *= 0.01;
			else if (g_Gravity > 1.0 && g_Gravity < 1000.0) g_Gravity *= 0.001;
			else if (g_Gravity > 1.0 && g_Gravity < 10000.0) g_Gravity *= 0.0001;
			g_Gravity = 0.8 - g_Gravity;
			if (g_Gravity < 0.1) g_Gravity = 0.1;
			SetEntityGravity(client, g_Gravity);
		}
		if (g_Gravity < 0.8 && !b_Jumping) CreateTimer(g_Time, Timer_ResetGravity, client, TIMER_FLAG_NO_MAPCHANGE);
	}
}

stock bool OnPlayerRevived(client, targetclient) {

	if (SetTempHealth(client, targetclient, GetMaximumHealth(targetclient) * fHealthSurvivorRevive, true)) return true;
	return false;
}

stock float GetTempHealth(client) {

	return GetEntPropFloat(client, Prop_Send, "m_healthBuffer");
}

stock SetMaximumHealth(client) {
	if (!IsLegitimateClient(client)) return 1;
	int ClientTeam = myCurrentTeam[client];

	if (ClientTeam != TEAM_SURVIVOR) return DefaultHealth[client];

	bool playerIsIncapacitated = IsIncapacitated(client);

	//GetAbilityStrengthByTrigger(client, _, "p", _, 0, _, _, "h", _, true, 0, _, _, _, _, true);
	int isRaw = RoundToCeil(GetAbilityStrengthByTrigger(client, client, TRIGGER_p, _, 0, _, _, RESULT_H, _, true, 2));			// 2 gets ONLY raw returns
	if (isRaw < 0) isRaw = 0;
	int allyProximityHealthBonus = RoundToCeil(GetCoherencyStrength(client, ACTIVATOR_ABILITY_EFFECTS, "H", COHERENCY_RANGE));
	if (allyProximityHealthBonus > 0) isRaw += allyProximityHealthBonus;

	float TheAbilityMultiplier = GetAbilityMultiplier(client, "V");
	//if (TheAbilityMultiplier == -1.0) TheAbilityMultiplier = 0.0;
	if (TheAbilityMultiplier != -1) isRaw += RoundToCeil(isRaw * TheAbilityMultiplier);
	// health values are now only raw values.

	if (!playerIsIncapacitated) {
		float ammoStr = IsClientInRangeSpecialAmmo(client, "O", _, _, isRaw);
		if (ammoStr > 0.0) isRaw += RoundToCeil(isRaw * ammoStr);
	}
	if (isRaw > 30000) isRaw = 30000;
	if (playerIsIncapacitated) DefaultHealth[client] = iDefaultIncapHealth + isRaw;
	else DefaultHealth[client] = iSurvivorBaseHealth + isRaw;

	SetEntProp(client, Prop_Send, "m_iMaxHealth", DefaultHealth[client]);

	if (playerIsIncapacitated && bIsGiveIncapHealth[client]) {
		if (L4D2_GetInfectedAttacker(client) == -1) GiveMaximumHealth(client, RoundToCeil(DefaultHealth[client] * fIncapHealthStartPercentage));
		else GiveMaximumHealth(client, DefaultHealth[client]);
		bIsGiveIncapHealth[client] = false;
	}
	if (GetClientHealth(client) > DefaultHealth[client]) GiveMaximumHealth(client);
	return DefaultHealth[client];
}

stock FindZombieClass(client) {
	if (IsLegitimateClient(client)) {
		if (myCurrentTeam[client] == TEAM_SURVIVOR) return 0;
		return GetEntProp(client, Prop_Send, "m_zombieClass");
	}
	if (IsWitch(client)) return 7;
	if (IsCommonInfected(client)) return 9;
	return -1;
}

stock SetInfectedHealth(client, value) {
	if (IsValidEntity(client)) {
		SetConVarInt(FindConVar("z_health"), value);
		SetEntProp(client, Prop_Data, "m_iHealth", value);
		SetEntProp(client, Prop_Data, "m_iMaxHealth", value);
	}
}

stock GetInfectedMaxHealth(entity) {
	return GetEntProp(entity, Prop_Data, "m_iMaxHealth");
}

stock float GetInfectedHealthPercentage(client) {
	float healthRemaining = GetEntProp(client, Prop_Data, "m_iHealth") * 1.0;
	float healthMax = GetEntProp(client, Prop_Data, "m_iMaxHealth") * 1.0;
	return healthRemaining/healthMax;
}

stock GetInfectedHealth(client) {

	return GetEntProp(client, Prop_Data, "m_iHealth");
}

stock SetBaseHealth(client) {

	SetEntProp(client, Prop_Data, "m_iMaxHealth", DefaultHealth[client]);
}

stock GiveMaximumHealth(client, healthOverride = 0) {

	if (IsLegitimateClientAlive(client) && b_IsLoaded[client]) {
		if (healthOverride == 0) healthOverride = GetMaximumHealth(client);

		GetAbilityStrengthByTrigger(client, _, TRIGGER_a);

		if (myCurrentTeam[client] == TEAM_INFECTED || !IsIncapacitated(client)) SetEntPropFloat(client, Prop_Send, "m_healthBuffer", 0.0);
		else SetEntPropFloat(client, Prop_Send, "m_healthBuffer", healthOverride * 1.0);
		
		SetEntPropFloat(client, Prop_Send, "m_healthBufferTime", GetGameTime());
		SetEntityHealth(client, healthOverride);
	}
}

stock GetMaximumHealth(client)
{
	if (IsLegitimateClient(client)) {

		//return GetEntProp(client, Prop_Send, "m_iMaxHealth");
		int iMaxHealth = GetEntProp(client, Prop_Send, "m_iMaxHealth");
		if (iMaxHealth > 30000) return 30000;
		return iMaxHealth;
	}
	else return 0;
}

// This is for active statuses, not buffs/talents/etc.
CheckActiveStatuses(client, char[] sStatus, bool bGetStatus = true, bool bDeleteStatus = false) {

	char text[64];

	int size = GetArraySize(ActiveStatuses[client]);

	for (int i = 0; i < size; i++) {

		GetArrayString(ActiveStatuses[client], i, text, sizeof(text));
		if (StrEqual(sStatus, text)) {

			if (!bDeleteStatus || bGetStatus) return 2;	// 2 - Cannot add status because it is already in effect.
			RemoveFromArray(ActiveStatuses[client], i);
			return 0;									// 0 - means the status was deleted.
		}
	}
	if (!bDeleteStatus && !bGetStatus) {

		PushArrayString(ActiveStatuses[client], sStatus);
		return 1;										// 1 - status inserted
	}
	return -1;											// -1 - status not found.
}

stock CloakingDevice(client) {

	int theresult = CheckActiveStatuses(client, "lunge");

	if (IsLegitimateClientAlive(client) && theresult == -1) {

		SetEntityRenderMode(client, RENDER_TRANSCOLOR);
		SetEntityRenderColor(client, 255, 255, 255, 0);
		//CreateTimer(g_Time, Timer_CloakingDeviceBreakdown, client, TIMER_FLAG_NO_MAPCHANGE);

		CheckActiveStatuses(client, "lunge", false);	// adds the lunge effect to the active statuses.
	}
}

stock AbsorbDamage(client, float s_Strength, damage) {

	if (IsLegitimateClientAlive(client)) {

		if (myCurrentTeam[client] == TEAM_INFECTED || !IsIncapacitated(client)) {

			int absorb = RoundToFloor(s_Strength);
			if (absorb > damage) absorb = damage;

			SetEntityHealth(client, GetClientHealth(client) + absorb);
		}
	}
}

stock DamagePlayer(client, victim, float s_Strength) {

	if (IsLegitimateClientAlive(client) && IsLegitimateClientAlive(victim)) {

		int d_Damage = RoundToFloor(s_Strength);

		if (GetClientHealth(victim) > 1) {

			if (GetClientHealth(victim) + 1 < d_Damage) d_Damage = GetClientHealth(victim) - 1;
			if (d_Damage > 0) {

				DamageAward[client][victim] += d_Damage;
				SetEntityHealth(victim, GetClientHealth(victim) - d_Damage);
			}
		}
	}
}

stock WipeDamageAward(client) {

	for (int i = 1; i <= MaxClients; i++) {

		DamageAward[client][i] = 0;
	}
}

void ReflectDamage(int client, int target, int AttackDamage) {
	int enemytype = -1;
	int enemyteam = -1;
	if (IsSpecialCommon(target)) enemytype = 1;
	else if (IsCommonInfected(target)) enemytype = 0;
	else if (IsWitch(target)) enemytype = 2;
	else if (IsLegitimateClientAlive(target)) {
		enemytype = 3;
		enemyteam = myCurrentTeam[target];
	}
	if (enemytype == 1) AddSpecialCommonDamage(client, target, AttackDamage);
	else if (enemytype == 0) AddCommonInfectedDamage(client, target, AttackDamage);
	else if (enemytype == 2) AddWitchDamage(client, target, AttackDamage);
	else if (enemytype == 3 && enemyteam == TEAM_INFECTED) AddSpecialInfectedDamage(client, target, AttackDamage);
	if (enemytype > 0) {
		if (LastAttackedUser[client] == target) ConsecutiveHits[client]++;
		else {
			LastAttackedUser[client] = target;
			ConsecutiveHits[client] = 0;
		}
	}
	if (iDisplayHealthBars == 1 && enemytype >= 2) DisplayInfectedHealthBars(client, target);
}

int CheckTeammateDamagesEx(int client, int target, int TotalDamage, int hitgroup = -1, bool deathIsConfirmed = false, bool igniteEntityOnDeath = false) {
	if (TotalDamage < 1) return 0;
	if (deathIsConfirmed || CheckTeammateDamages(target, client) >= 1.0 || CheckTeammateDamages(target, client, true) >= 1.0) {
		char eName[64];
		char cName[64];
		Format(cName, 64, "none");
		GetClientName(client, cName, sizeof(cName));
		char formattedDamage[10];
		AddCommasToString(TotalDamage, formattedDamage, 10);
		
		if (IsLegitimateClient(target)) {
			if (FindZombieClass(target) == ZOMBIECLASS_TANK) {
				GetClientName(target, eName, sizeof(eName));
				PrintToChatAll("%t", "player damage to special", blue, cName, white, orange, eName, white, green, formattedDamage, white);
				AddAttributeExperience(client, ATTRIBUTE_LUCK, TotalDamage);
			}
			//{1}{2} {3}lands the killing blow on {4}{5} {6}for {7}{8} {9}damage

			GetAbilityStrengthByTrigger(client, target, TRIGGER_e, _, TotalDamage, _, _, _, _, _, _, hitgroup);
			GetAbilityStrengthByTrigger(target, client, TRIGGER_E, _, TotalDamage, _, _, _, _, _, _, hitgroup);
			CalculateInfectedDamageAward(target, client);
		}
		else {
			if (IsWitch(target)) {
				Format(eName, sizeof(eName), "%t", "witch");
				PrintToChatAll("%t", "player damage to special", blue, cName, white, orange, eName, white, green, formattedDamage, white);
				GetAbilityStrengthByTrigger(client, target, TRIGGER_witchkill, _, TotalDamage, _, _, _, _, _, _, hitgroup);
				CalculateInfectedDamageAward(target, client);
				OnWitchCreated(target, true);
				AddAttributeExperience(client, ATTRIBUTE_LUCK, TotalDamage);
			}
			else if (IsSpecialCommon(target)) {
				// GetCommonValueAtPos(eName, sizeof(eName), target, SUPER_COMMON_NAME);
				// Format(eName, sizeof(eName), "Common %s", eName);
				// PrintToChatAll("%t", "player damage to special", blue, cName, white, orange, eName, white, green, TotalDamage, white);

				GetAbilityStrengthByTrigger(client, target, TRIGGER_superkill, _, TotalDamage, _, _, _, _, _, _, hitgroup);
				ClearSpecialCommon(target, _, TotalDamage, client);
				AddAttributeExperience(client, ATTRIBUTE_LUCK, TotalDamage);
			}
			else if (IsCommonInfected(target)) {
				GetAbilityStrengthByTrigger(client, target, TRIGGER_C, _, TotalDamage, _, _, _, _, _, _, hitgroup);
				//GetAbilityStrengthByTrigger(client, target, "killcommon", _, TotalDamage, _, _, _, _, _, _, hitgroup);
				CalculateInfectedDamageAward(target, client);
				RemoveCommonInfected(target, igniteEntityOnDeath);
				AddAttributeExperience(client, ATTRIBUTE_LUCK, 1);
			}
		}
		return TotalDamage;
	}
	return 0;
}

/*stock ReflectDamage(client, victim, Float:g_TalentStrength, d_Damage) {

	if (IsLegitimateClientAlive(client) && IsLegitimateClientAlive(victim)) {

		new reflectHealth = RoundToFloor(g_TalentStrength);
		new reflectValue = 0;
		if (reflectHealth > d_Damage) reflectHealth = d_Damage;
		if (!IsIncapacitated(client) && IsPlayerAlive(client)) {

			if (GetClientHealth(client) > reflectHealth) reflectValue = reflectHealth;
			else reflectValue = GetClientHealth(client) - 1;
			SetEntityHealth(client, GetClientHealth(client) - reflectValue);
			DamageAward[client][victim] -= reflectValue;
			DamageAward[victim][client] += reflectValue;
		}
	}
}*/

stock SendPanelToClientAndClose(Handle panel, client, MenuHandler:handler, time) {

	SendPanelToClient(panel, client, handler, time);
	CloseHandle(panel);
}

stock CreateAcid(client, victim, float radius = 128.0) {
	if (IsCommonInfected(client) || IsLegitimateClient(client)) {
		if (IsLegitimateClientAlive(victim)) {
			float pos[3];
			if (IsLegitimateClient(victim)) GetClientAbsOrigin(victim, pos);
			else GetEntPropVector(victim, Prop_Send, "m_vecOrigin", pos);
			pos[2] += 96.0;
			int acidball = CreateEntityByName("spitter_projectile");
			if (IsValidEntity(acidball)) {
				DispatchSpawn(acidball);
				SetEntPropEnt(acidball, Prop_Send, "m_hThrower", client);
				SetEntPropFloat(acidball, Prop_Send, "m_DmgRadius", radius);
				SetEntProp(acidball, Prop_Send, "m_bIsLive", 1);
				TeleportEntity(acidball, pos, NULL_VECTOR, NULL_VECTOR);
				SDKCall(g_hCreateAcid, acidball);
			}
		}
	}
}

stock ForceClientJump(activator, float g_TalentStrength, victim = 0) {

	if (IsLegitimateClient(activator)) {

		if (GetEntityFlags(activator) & FL_ONGROUND || victim > 0 && GetEntityFlags(victim) & FL_ONGROUND) {

			//new attacker = -1;
			//if (GetClientTeam(activator) != TEAM_INFECTED) attacker = L4D2_GetInfectedAttacker(activator);
			//if (attacker == -1 || !IsClientActual(attacker) || myCurrentTeam[attacker] != TEAM_INFECTED || (FindZombieClass(attacker) != ZOMBIECLASS_JOCKEY && FindZombieClass(attacker) != ZOMBIECLASS_CHARGER)) attacker = -1;

			float vel[3];
			vel[0] = GetEntPropFloat(activator, Prop_Send, "m_vecVelocity[0]");
			vel[1] = GetEntPropFloat(activator, Prop_Send, "m_vecVelocity[1]");
			vel[2] = GetEntPropFloat(activator, Prop_Send, "m_vecVelocity[2]");
			vel[2] += g_TalentStrength;
			if (victim == 0) TeleportEntity(activator, NULL_VECTOR, NULL_VECTOR, vel);
			else TeleportEntity(victim, NULL_VECTOR, NULL_VECTOR, vel);
		}
	}
}

stock int GiveAmmoBack(client, rawToReturn = 0, float percentageToReturn = 0.0, activator = 0) {
	if (activator == 0) activator = client;
	int reserveCap = GetWeaponResult(client, 2);
	int reserveRemaining = GetWeaponResult(client, 3);
	if (reserveRemaining >= reserveCap) return 0;
	int returnAmount = rawToReturn;
	if (percentageToReturn > 0.0) {
		returnAmount = RoundToCeil(reserveCap * percentageToReturn);
	}
	if (returnAmount > reserveCap - reserveRemaining) {
		returnAmount = reserveCap - reserveRemaining;
	}
	if (activator != client) {
		AwardExperience(activator, 2, returnAmount);
		AddContributionToEngagedEnemiesOfAlly(activator, client, CONTRIBUTION_AWARD_BUFFING, returnAmount);
	}
	return GetWeaponResult(client, 4, returnAmount);
}

stock bool GetResultByVScript(client, char[] scriptCallByRef, bool printResults = false) {
	int entity = CreateEntityByName("logic_script");
	if (entity >= 1) {
		DispatchSpawn(entity);
		char text[96];
		Format(text, sizeof(text), "Convars.SetValue(\"sm_vscript_res\", \"\" + %s + \"\");", scriptCallByRef);
		SetVariantString(text);
		AcceptEntityInput(entity, "RunScriptCode");
		AcceptEntityInput(entity, "Kill");
		GetConVarString(staggerBuffer, text, sizeof(text));
		SetConVarString(staggerBuffer, "");
		if (StrEqual(text, "true", false)) return true;
	}
	return false;
}

stock bool IsCoveredInBile(client) {
	if (!IsLegitimateClient(client)) return false;
	return (ISBILED[client]) ? true : false;
}

public Action Timer_RemoveBileStatus(Handle timer, any client) {
	if (IsLegitimateClient(client)) ISBILED[client] = false;
	return Plugin_Stop;
}

stock RestoreHealBullet(client, bulletsRestored = 1) {

	if (!hasMeleeWeaponEquipped[client]) {

		int WeaponSlot = GetActiveWeaponSlot(client);
		int PlayerWeapon = GetPlayerWeaponSlot(client, WeaponSlot);
		if (PlayerWeapon < 0 || !IsValidEntity(PlayerWeapon)) return;
		int bullets = GetEntProp(PlayerWeapon, Prop_Send, "m_iClip1", 1);
		if (bullets + bulletsRestored < 200) SetEntProp(PlayerWeapon, Prop_Send, "m_iClip1", bullets + bulletsRestored);
		else SetEntProp(PlayerWeapon, Prop_Send, "m_iClip1", 200);
	}
}

stock ModifyPlayerAmmo(target, float g_TalentStrength) {

	int PlayerWeapon = GetPlayerWeaponSlot(target, 0);
	if (!IsValidEntity(PlayerWeapon)) return;

	int PlayerAmmo = GetEntProp(PlayerWeapon, Prop_Send, "m_iClip1", 1);
	//new PlayerMaxAmmo = GetEntProp(PlayerWeapon, Prop_Send, "m_iMaxClip1", 1);
	int PlayerAmmoAward = RoundToCeil(g_TalentStrength * PlayerAmmo);
	PlayerAmmoAward = GetRandomInt(1, PlayerAmmoAward);

	/*

		If the players clip reaches the max, it resets to the default.
	*/
	//new PlayerMaxIncrease = PlayerMaxAmmo + RoundToCeil(PlayerMaxAmmo * g_TalentStrength);
	SetEntProp(PlayerWeapon, Prop_Send, "m_iClip1", PlayerAmmo + PlayerAmmoAward, 1);

	//if (PlayerAmmo + PlayerAmmoAward >= PlayerMaxIncrease) SetEntProp(PlayerWeapon, Prop_Send, "m_iClip1", PlayerMaxAmmo, 1);
}

stock bool RestrictedWeaponList(char[] WeaponName) {	// Some weapons might be insanely powerful, so we see if they're in this string and don't let them damage multiplier if they are.

	if (StrContains(RestrictedWeapons, WeaponName, false) != -1) return true;
	return false;
}

stock ConfirmExperienceAction(client, bool TheRoundHasEnded = false, bool IsAllowLevelUp = false) {

	if (!IsLegitimateClient(client)) return;

	int ExperienceRequirement = CheckExperienceRequirement(client, _, PlayerLevel[client]);

	int thisPlayerMaxLevel = (IsFakeClient(client)) ? iMaxLevelBots : iMaxLevel;

	if (iIsLevelingPaused[client] == 1 || PlayerLevel[client] >= thisPlayerMaxLevel) {

		if (ExperienceLevel[client] > ExperienceRequirement) {

			ExperienceOverall[client] -= (ExperienceLevel[client] - ExperienceRequirement);
			ExperienceLevel[client] = ExperienceRequirement;
		}
	}
	if (ExperienceLevel[client] >= ExperienceRequirement && PlayerLevel[client] < thisPlayerMaxLevel && (iIsLevelingPaused[client] == 0 || IsAllowLevelUp)) {

		char Name[64];
		GetClientName(client, Name, sizeof(Name));
		//else GetSurvivorBotName(client, Name, sizeof(Name));
		int count = 0;
		int MaxLevel = thisPlayerMaxLevel;

		while (ExperienceLevel[client] >= ExperienceRequirement) {
			ExperienceLevel[client] -= ExperienceRequirement;
			if (PlayerLevel[client] + count <= MaxLevel)	count++;
			if (PlayerLevel[client] + count < MaxLevel) {

				ExperienceRequirement		= CheckExperienceRequirement(client, _, PlayerLevel[client] + count);
			}
			else {

				//ExperienceLevel[client]		= 1;
				ExperienceRequirement		= CheckExperienceRequirement(client, _, MaxLevel);
			}
		}
		if (ExperienceLevel[client] < 1) ExperienceLevel[client] = 1;
		if (count >= 1) {

			if (count > 0) {

				if (PlayerLevel[client] < MaxLevel) {

					PlayerLevel[client] += count;
					UpgradesAwarded[client] += count;
					UpgradesAvailable[client] += count;
					TotalTalentPoints[client] += count;
					if (!IsFakeClient(client)) PrintToChat(client, "%T", "upgrade awarded", client, white, green, orange, white, count);
					PlayerLevelUpgrades[client] = 0;
				}

				if (count == 1) PrintToChatAll("%t", "player level up", green, white, green, Name, PlayerLevel[client]);
				else {
					char formattedLevel[64];
					AddCommasToString(PlayerLevel[client], formattedLevel, sizeof(formattedLevel));
					PrintToChatAll("%t", "player multiple level up", blue, Name, white, green, count, white, blue, formattedLevel);
				}
				FormatPlayerName(client);
			}
			else {

				// experience resets & cartel are awarded, but no level if at cap

				//ExperienceLevel[client] = 1;
			}
			// Whenever a player levels, we also level up talents that have earned enough experience for at least 1 point gain.
			ConfirmExperienceActionTalents(client, _, TheRoundHasEnded);

			bIsSettingsCheck = true;
		}
	}
}

stock ConfirmExperienceActionTalents(client, bool WipeXP = false, bool TheRoundHasEnded = false) {

	if (!IsLegitimateClient(client)) return;
	char Name[64];
	GetClientName(client, Name, sizeof(Name));
	if (WipeXP) {
	
		int WipedExperience = RoundToCeil(ExperienceLevel[client] * fDeathPenalty);
		if (WipedExperience > 1) {

			ExperienceOverall[client] -= WipedExperience;
			ExperienceLevel[client] -= WipedExperience;
			char clientName[64];
			GetClientName(client, clientName, sizeof(clientName));
			char wipedXPAmount[64];
			AddCommasToString(WipedExperience, wipedXPAmount, sizeof(wipedXPAmount));
			PrintToChatAll("%t", "death penalty", blue, orange, green, wipedXPAmount, blue, clientName);
			// a member of your group has died!
			// you have lost x experience!
		}
	}
}

stock bool SurvivorsBiled() {
	for (int i = 1; i <= MaxClients; i++) {
		if (IsLegitimateClientAlive(i) && myCurrentTeam[i] == TEAM_SURVIVOR && IsCoveredInBile(i)) return true;
	}
	return false;
}

stock bool RollChanceIsSuccessful(client, float rollChance) {
	if (rollChance <= 0.0 || GetRandomInt(1, RoundToCeil(1.0 / rollChance)) == 1) return true;
	return false;
}

stock RemoveAllDebuffs(client, int debuffName) {
	int size = GetArraySize(EntityOnFire);
	for (int i = 0; i < size; i++) {
		if (client != GetArrayCell(EntityOnFire, i, 0)) continue;	// client isn't the client owning this debuff
		int debuffType = GetArrayCell(EntityOnFire, i, 6);
		if (debuffName != debuffType) continue;
		RemoveFromArray(EntityOnFire, i);
		size--;
		if (i > 0) i--;
	}
}

/*

		2nd / 3rd args have defaults for use with special common infected.
		When these special commons explode, they can apply custom versions of these flames to players
		and the plugin will check every so often to see if a player has such an entity attached to them.
		If they do, they'll burn. Players can have multiple of these, so it is dangerous.
*/
void CreateAndAttachFlame(int client, int damage = 0, float lifetime = 10.0, float tickInt = 1.0, int owner, int DebuffName = STATUS_EFFECT_BURN, float tickIntContinued = -2.0) {
	bool isLegitimate = IsLegitimateClient(client);
	if (isLegitimate) {
		float TheAbilityMultiplier = GetAbilityMultiplier(client, "B");
		if (TheAbilityMultiplier > 0.0) damage += RoundToCeil(damage * TheAbilityMultiplier);
		if (tickIntContinued <= 0.0) tickIntContinued = tickInt;
	}
	int size = GetArraySize(EntityOnFire);
	PushArrayCell(EntityOnFire, client);	// structured by blocks (3d array list)
	SetArrayCell(EntityOnFire, size, damage, 1);
	SetArrayCell(EntityOnFire, size, lifetime, 2);
	SetArrayCell(EntityOnFire, size, tickInt, 3);
	SetArrayCell(EntityOnFire, size, tickIntContinued, 4);
	SetArrayCell(EntityOnFire, size, owner, 5);
	SetArrayCell(EntityOnFire, size, DebuffName, 6);
	if (isLegitimate && DebuffName == STATUS_EFFECT_BURN) IgniteEntity(client, lifetime);
	if (damage == 0 && DebuffName == STATUS_EFFECT_ACID && IsCommonInfected(client)) CreateAcid(FindInfectedClient(true), client, 48.0);
}

stock RemoveClientStatusEffect(client, int EffectName = STATUS_EFFECT_GET_RANDOM) {
	if (!IsLegitimateClient(client)) return 0;
	for (int i = 0; i < GetArraySize(EntityOnFire); i++) {
		if (GetArrayCell(EntityOnFire, i) != client) continue;
		if (EffectName != STATUS_EFFECT_GET_RANDOM) {
			int EffectType = GetArrayCell(EntityOnFire, i, 6);
			if (EffectName != EffectType) continue;
		}
		RemoveFromArray(EntityOnFire, i);
		return 1;
	}
	return 0;
}

stock GetClientStatusEffect(client, int EffectName = 0) {
	int Count = 0;
	if (!IsLegitimateClient(client)) return 0;
	for (int i = 0; i < GetArraySize(EntityOnFire); i++) {
		if (GetArrayCell(EntityOnFire, i) != client) continue;
		if (EffectName != STATUS_EFFECT_GET_TOTAL) {
			int DebuffName = GetArrayCell(EntityOnFire, i, 6);
			if (DebuffName != EffectName) continue;
		}
		Count++;
	}
	return Count;
}

stock ClearRelevantData() {

	for (int i = 1; i <= MaxClients; i++) {

		if (!IsClientActual(i) || !IsClientInGame(i)) continue;
		ResetOtherData(i);
	}
	//ClearArray(Handle:WitchList);
}

stock WipeDebuffs(bool IsEndOfCampaign = false, client = -1, bool IsDisconnect = false) {

	if (client == -1) {

		//ResetArray(Handle:CommonInfected);
		ResetArray(WitchList);
		ResetArray(CommonAffixes);

		if (IsEndOfCampaign) {

			ClearArray(EntityOnFire);
			ClearArray(CommonInfectedQueue);
			Points_Director = 0.0;

			for (int i = 1; i <= MaxClients; i++) {

				if (IsLegitimateClient(i)) Points[i] = 0.0;
			}
		}
	}
	else {

		b_HardcoreMode[client] = false;
		ResetCDImmunity(client);
		EnrageBlind(client, 0);

		if (IsDisconnect) {
			//ClearArray(CommonInfected[client]);
			CleanseStack[client] = 0;
			CounterStack[client] = 0.0;
			MultiplierStack[client] = 0;
			Format(BuildingStack[client], sizeof(BuildingStack[]), "none");

			Points[client] = 0.0;
		}
		b_IsFloating[client] = false;
		if (b_IsActiveRound) {
			b_IsInSaferoom[client] = false;
			bIsInCheckpoint[client] = false;
		}
		else {
			b_IsInSaferoom[client] = true;
			bIsInCheckpoint[client] = true;
		}
		b_IsBlind[client]				= false;
		b_IsImmune[client]				= false;
		b_IsJumping[client]				= false;
		CommonKills[client]				= 0;
		CommonKillsHeadshot[client]		= 0;
		bIsMeleeCooldown[client]			= false;
		shotgunCooldown[client]			= false;
		AmmoTriggerCooldown[client] = false;
		ExplosionCounter[client][0] = 0.0;
		ExplosionCounter[client][1] = 0.0;
		HealingContribution[client] = 0;
		TankingContribution[client] = 0;
		DamageContribution[client] = 0;
		PointsContribution[client] = 0.0;
		HexingContribution[client] = 0;
		BuffingContribution[client] = 0;
		CleansingContribution[client] = 0;
		ResetContributionTracker(client);
		WipeDamageContribution(client);
	}
}

stock ResetContributionTracker(client) {
	ClearArray(playerContributionTracker[client]);
	ResizeArray(playerContributionTracker[client], 4);
	for (int i = 0; i < 4; i++) SetArrayCell(playerContributionTracker[client], i, 0);
}

stock CreateCombustion(client, float g_Strength, float f_Time)
{
	int entity				= CreateEntityByName("env_fire");
	float loc[3];
	GetClientAbsOrigin(client, loc);

	char s_Strength[64];
	Format(s_Strength, sizeof(s_Strength), "%3.3f", g_Strength);

	DispatchKeyValue(entity, "StartDisabled", "0");
	DispatchKeyValue(entity, "damagescale", s_Strength);
	char s_Health[64];
	Format(s_Health, sizeof(s_Health), "%3.3f", f_Time);

	DispatchKeyValue(entity, "fireattack", "2");
	DispatchKeyValue(entity, "firesize", "128");
	DispatchKeyValue(entity, "health", s_Health);
	DispatchKeyValue(entity, "ignitionpoint", "1");
	DispatchSpawn(entity);

	TeleportEntity(entity, loc, NULL_VECTOR, NULL_VECTOR);
	AcceptEntityInput(entity, "Enable");
	AcceptEntityInput(entity, "StartFire");
	
	CreateTimer(f_Time, Timer_DestroyCombustion, entity, TIMER_FLAG_NO_MAPCHANGE);
}

stock bool IsInRange(float EntitLoc[3], float TargetLo[3], float AllowsMaxRange, float ModeSize = 1.0) {

	//new Float:ModelSize = 48.0 * ModeSize;
	
	if (GetVectorDistance(EntitLoc, TargetLo) <= (AllowsMaxRange / 2)) return true;
	return false;
}

stock int LivingEntitiesInRangeByType(int client, float effectRange, int targetTeam = 0) {
	int count = 0;
	float ClientPos[3];
	GetEntPropVector(client, Prop_Send, "m_vecOrigin", ClientPos);
	float TargetPos[3];
	if (targetTeam >= 3) {	// 3 survivor, 4 infected
		for (int i = 1; i <= MaxClients; i++) {
			if (i == client) continue;
			if (!IsLegitimateClientAlive(i)) continue;
			if (myCurrentTeam[i] + 1 != targetTeam) continue;

			GetClientAbsOrigin(i, TargetPos);
			if (GetVectorDistance(ClientPos, TargetPos) > effectRange) continue;
			count++;
		}
	}
	else if (targetTeam == 2) { // witch
		for (int i = 0; i < GetArraySize(damageOfWitch); i++) {
			int witch = GetArrayCell(damageOfWitch, i);
			if (witch == client) continue;
			if (!IsWitch(witch)) {
				RemoveFromArray(damageOfWitch, i);
				i--;
				continue;
			}

			GetEntPropVector(witch, Prop_Send, "m_vecOrigin", TargetPos);
			if (GetVectorDistance(ClientPos, TargetPos) > effectRange) continue;
			count++;
		}
	}
	else if (targetTeam == 1) { // special commons
		for (int i = 0; i < GetArraySize(CommonAffixes); i++) {
			int specialCommon = GetArrayCell(CommonAffixes, i);
			if (specialCommon == client) continue;

			GetEntPropVector(specialCommon, Prop_Send, "m_vecOrigin", TargetPos);
			if (GetVectorDistance(ClientPos, TargetPos) > effectRange) continue;
			count++;
		}
	}
	else if (targetTeam == 0) {
		// }
		for (int i = 0; i < GetArraySize(damageOfCommonInfected); i++) {
			int common = GetArrayCell(damageOfCommonInfected, i);
			if (common == client || !IsCommonInfected(common)) continue;

			GetEntPropVector(common, Prop_Send, "m_vecOrigin", TargetPos);
			if (GetVectorDistance(ClientPos, TargetPos) > effectRange) continue;
			count++;
		}
	}
	return count;
}

stock LivingEntitiesInRange(entity, float SourceLoc[3], float EffectRange, targetType = 0) {

	int count = 0;
	float Pos[3];
	if (targetType != 1) {
		for (int i = 1; i <= MaxClients; i++) {
			if (IsLegitimateClientAlive(i)) {
				if (targetType != 4) {
					if (targetType == 2 && myCurrentTeam[i] != TEAM_SURVIVOR) continue;
					else if (targetType == 3 && myCurrentTeam[i] != TEAM_INFECTED) continue;
				}

				GetClientAbsOrigin(i, Pos);
				if (!IsInRange(SourceLoc, Pos, EffectRange)) continue;
				count++;
			}
		}
	}
	//new ent = -1;
	//if (targetType <= 1) {
		// new survivor = FindClientOnSurvivorTeam();
		// if (survivor > 0) {
		// 	new size = GetArraySize(CommonInfected[survivor]);
		// 	for (new i = 0; i < size; i++) {
		// 		new ent = GetArrayCell(CommonInfected[survivor], i);
		// 		if (!IsCommonInfected(ent) || ent == entity) continue;
		// 		GetEntPropVector(ent, Prop_Send, "m_vecOrigin", Pos);
		// 		if (GetVectorDistance(SourceLoc, Pos) > EffectRange) continue;
		// 		count++;
		// 	}
		// }
		// for (new i = 0; i < GetArraySize(Handle:CommonAffixes); i++) {
		// 	ent = GetArrayCell(Handle:CommonAffixes, i);
		// 	if (!IsCommonInfected(ent)) continue;
		// 	GetEntPropVector(ent, Prop_Send, "m_vecOrigin", Pos);
		// 	if (!IsInRange(SourceLoc, Pos, EffectRange)) continue;
		// 	count++;
		// }
	//}
	return count;
}

stock GetTalentNameAtMenuPosition(client, pos, char[] TheString, stringSize) {
	//TalentAtMenuPositionSection[client] = GetArrayCell(a_Menu_Talents, pos, 2);
	GetArrayString(a_Database_Talents, pos, TheString, stringSize);
}

stock GetMenuPosition(client, char[] TalentName) {
	int size						=	GetArraySize(a_Menu_Talents);
	char Name[PLATFORM_MAX_PATH];
	for (int i = 0; i < size; i++) {
		//MenuPosition[client]				= GetArrayCell(a_Menu_Talents, i, 2);
		GetArrayString(a_Database_Talents, i, Name, sizeof(Name));
		if (StrEqual(Name, TalentName)) return i;
	}
	return -1;
}


stock GetTalentPosition(client, char[] TalentName) {
	int pos = -1;
	int a_Size				=	0;
	a_Size					=	GetArraySize(a_Database_PlayerTalents[client]);
	char Name[PLATFORM_MAX_PATH];
	for (int i = 0; i < a_Size; i++) {
		GetArrayString(a_Database_Talents, i, Name, sizeof(Name));
		if (StrEqual(Name, TalentName)) return i;
	}
	return pos;
}

stock RemoveImmunities(client) {

	// We remove all immunities when a round ends, otherwise they may not properly remove and then players become immune, forever.
	int size = 0;
	if (client == -1) {

		size = GetArraySize(PlayerAbilitiesCooldown_Bots);
		for (int i = 0; i < size; i++) {

			//SetArrayString(PlayerAbilitiesImmune_Bots, i, "0");
			SetArrayCell(PlayerAbilitiesCooldown_Bots, i, 0);
		}
		for (int i = 1; i <= MAXPLAYERS; i++) {

			RemoveImmunities(i);
		}
	}
	else {

		size = GetArraySize(PlayerAbilitiesCooldown[client]);
		for (int i = 0; i < size; i++) {

			//SetArrayString(PlayerAbilitiesImmune[client], i, "0");
			SetArrayCell(PlayerAbilitiesCooldown[client], i, 0);
		}
		size = GetArraySize(PlayerActiveAbilitiesCooldown[client]);
		for (int i = 0; i < size; i++) {
			SetArrayCell(PlayerActiveAbilitiesCooldown[client], i, 0);
		}
	}
}

/*stock CreateImmune(activator, client, pos, Float:f_Cooldown) {

	if (IsLegitimateClient(client)) {

		//if (!IsFakeClient(client)) SetArrayString(PlayerAbilitiesImmune[client], pos, "1");
		//else SetArrayString(PlayerAbilitiesImmune_Bots, pos, "1");
		SetArrayString(PlayerAbilitiesImmune[client][activator], pos, "1");

		new Handle:packy;
		CreateDataTimer(f_Cooldown, Timer_RemoveImmune, packy, TIMER_FLAG_NO_MAPCHANGE);
		if (IsFakeClient(client)) client = -1;
		WritePackCell(packy, client);
		WritePackCell(packy, pos);
		WritePackCell(packy, activator);
	}
}*/

stock GetAimTargetPosition(client, float TargetPos[3], char[] hitgroup = "-1", int size) {
	float ClientEyeAngles[3];
	float ClientEyePosition[3];
	GetClientEyeAngles(client, ClientEyeAngles);
	GetClientEyePosition(client, ClientEyePosition);
	int aimTarget = 0;

	Handle trace = TR_TraceRayFilterEx(ClientEyePosition, ClientEyeAngles, MASK_SHOT, RayType_Infinite, TraceRayIgnoreSelf, client);
	if (TR_DidHit(trace)) {
		aimTarget = TR_GetEntityIndex(trace);
		if (IsCommonInfected(aimTarget) || IsWitch(aimTarget) || IsLegitimateClient(aimTarget)) {
			GetEntPropVector(aimTarget, Prop_Send, "m_vecOrigin", TargetPos);
			if (!StrEqual(hitgroup, "-1")) Format(hitgroup, size, "%d", TR_GetHitGroup(trace));
		}
		else {
			aimTarget = -1;
			TR_GetEndPosition(TargetPos, trace);
		}
	}
	CloseHandle(trace);
	return aimTarget;
}

stock bool ClientsWithinRange(client, target, float fDistance = 96.0) {
	float clientPos[3];
	GetEntPropVector(client, Prop_Send, "m_vecOrigin", clientPos);
	float targetPos[3];
	GetEntPropVector(target, Prop_Send, "m_vecOrigin", targetPos);

	if (GetVectorDistance(clientPos, targetPos) <= fDistance) return true;
	return false;
}

// GetTargetOnly is set to true only when casting single-target spells, which require an actual target.
stock GetClientAimTargetEx(client, char[] TheText, TheSize, bool GetTargetOnly = false) {

	float ClientEyeAngles[3];
	float ClientEyePosition[3];
	float ClientLookTarget[3];

	GetClientEyeAngles(client, ClientEyeAngles);
	GetClientEyePosition(client, ClientEyePosition);

	Handle trace = TR_TraceRayFilterEx(ClientEyePosition, ClientEyeAngles, MASK_SHOT, RayType_Infinite, TraceRayIgnoreSelf, client);

	if (TR_DidHit(trace)) {

		int Target = TR_GetEntityIndex(trace);
		if (GetTargetOnly) {

			if (IsLegitimateClientAlive(Target)) Format(TheText, TheSize, "%d", Target);
			else Format(TheText, TheSize, "-1");
		}
		else {

			TR_GetEndPosition(ClientLookTarget, trace);
			Format(TheText, TheSize, "%3.3f %3.3f %3.3f", ClientLookTarget[0], ClientLookTarget[1], ClientLookTarget[2]);
		}
	}
	CloseHandle(trace);
}

public bool TraceRayIgnoreSelf(entity, mask, any client) {
	
	if (entity < 1 || entity == client) return false;
	return true;
}

stock GetAbilityDataPosition(client, pos) {
	for (int i = 0; i < GetArraySize(PlayActiveAbilities[client]); i++) {
		if (GetArrayCell(PlayActiveAbilities[client], i, 0) == pos) return i;
	}
	return -1;
}

stock bool BotsOnSurvivorTeam() {
	for (int i = 1; i <= MaxClients; i++) {
		if (!IsLegitimateClient(i) || !IsFakeClient(i) || myCurrentTeam[i] != TEAM_SURVIVOR) continue;
		return true;
	}
	return false;
}

stock bool SetActiveAbilityConditionsMet(client, int menuPos, bool GetIfConditionIsAlreadyMet = false) {
	int areConditionsMet = GetArrayCell(PlayActiveAbilities[client], menuPos, 2);
	if (GetIfConditionIsAlreadyMet) {
		if (areConditionsMet == 1) return true;
		return false;
	}
	if (areConditionsMet == 1) return true;
	SetArrayCell(PlayActiveAbilities[client], menuPos, 1, 2);	// sets conditions met to true.
	return true;
}

stock bool IsSpellAnAura(client, int pos) {
	//IsSpellAnAuraKeys[client]	= GetArrayCell(a_Menu_Talents, pos, 0);
	IsSpellAnAuraValues[client] = GetArrayCell(a_Menu_Talents, pos, 1);
	return (GetArrayCell(IsSpellAnAuraValues[client], IS_AURA_INSTEAD) == 1) ? true : false;
}

stock float GetAbilityValue(client, valuePos, int menuPos) {
	AbilityConfigValues[client]		= GetArrayCell(a_Menu_Talents, menuPos, 1);
	return GetArrayCell(AbilityConfigValues[client], valuePos);
}

stock int FindListPositionByEntity(int entity, Handle h_SearchList, int block = 0) {

	int size = GetArraySize(h_SearchList);
	if (size < 1) return -1;
	for (int i = 0; i < size; i++) {

		if (GetArrayCell(h_SearchList, i, block) == entity) return i;
	}
	return -1;	// returns false
}

stock bool CallAbilityCooldownAbilityTrigger(client, int menuPos, bool activePeriodNotCooldownPeriodEnds = false, int talentPositionInUnlockedList) {
	int talentEndTrigger = (activePeriodNotCooldownPeriodEnds) ? GetArrayCell(MyUnlockedTalents[client], talentPositionInUnlockedList, 4) : GetArrayCell(MyUnlockedTalents[client], talentPositionInUnlockedList, 5);
	if (talentEndTrigger >= 0) {
		GetAbilityStrengthByTrigger(client, L4D2_GetInfectedAttacker(client), talentEndTrigger);
		return true;
	}
	return false;
}

stock GetIfTriggerRequirementsMetAlways(client, char[] TalentName) {
	char text[64];
	int size = GetArraySize(a_Menu_Talents);
	for (int i = 0; i < size; i++) {
		//GetIfTriggerRequirementsMetSection[client]	= GetArrayCell(a_Menu_Talents, i, 2);
		GetArrayString(a_Database_Talents, i, text, sizeof(text));
		if (!StrEqual(text, TalentName)) continue;
		//GetIfTriggerRequirementsMetKeys[client]		= GetArrayCell(a_Menu_Talents, i, 0);
		GetIfTriggerRequirementsMetValues[client]	= GetArrayCell(a_Menu_Talents, i, 1);
		// Reactive abilities start with their requirements for active end or cooldown end ability triggers to fire, not met.
		if (GetArrayCell(GetIfTriggerRequirementsMetValues[client], ABILITY_IS_REACTIVE) == 1) return 0;
		break;
	}
	// If we get here, we meet the requirements.
	return 1;
}

bool AbilityIsInactiveAndOnCooldown(client, float fCooldownRemaining, char[] abilityT, int menuPos) {
	if (fCooldownRemaining == -1.0) return false;

	float AmmoCooldownTime = GetAbilityValue(client, ABILITY_ACTIVE_TIME, menuPos);
	if (AmmoCooldownTime == -1.0) return false;

	float fAmmoCooldownTime = GetSpellCooldown(client, abilityT, menuPos);
	AmmoCooldownTime = AmmoCooldownTime - (fAmmoCooldownTime - fCooldownRemaining);
	if (AmmoCooldownTime > 0.0) return false;
	return true;
}

stock bool IsAbilityEquipped(client, char[] TalentName, int pos) {

	char text[64];

	int size = iActionBarSlots;
	if (GetArraySize(ActionBar[client]) != size) ResizeArray(ActionBar[client], size);
	int menSize = GetArraySize(a_Menu_Talents);
	if (GetArraySize(MyTalentStrength[client]) != menSize) {
		ResizeArray(MyTalentStrength[client], menSize);
		return false;
	}
	for (int i = 0; i < size; i++) {
		GetArrayString(ActionBar[client], i, text, sizeof(text));
		if (!StrEqual(text, TalentName)) continue;
		if (GetArrayCell(MyTalentStrength[client], pos) > 0) return true;
		break;
	}
	return false;
}

stock bool IsAbilityActive(client, char[] TalentName, float timeToAdd = 0.0, char[] checkEffect = "none", int pos) {
	if (StrEqual(checkEffect, "L")) return false;

	float fCooldownRemaining = GetAmmoCooldownTime(client, TalentName, true);
	if (fCooldownRemaining == -1.0) return false;
	if (GetAbilityValue(client, ABILITY_COOLDOWN, pos) == -1.0) return false;

	float AmmoCooldownTime		 = GetAbilityValue(client, ABILITY_ACTIVE_TIME, pos);
	if (AmmoCooldownTime == -1.0) return false;

	float fAmmoCooldownTime = GetSpellCooldown(client, _, pos);
	AmmoCooldownTime				 = AmmoCooldownTime - (fAmmoCooldownTime - fCooldownRemaining) + timeToAdd;

	if (AmmoCooldownTime < 0.0) return false;
	return true;
}

stock float GetValueFloat(int client, int menuPos, int pos) {
	GetValueFloatArray[client] = GetArrayCell(a_Menu_Talents, menuPos, 1);
	return GetArrayCell(GetValueFloatArray[client], pos);
}

stock void CreateCooldown(client, pos, float f_Cooldown) {
	if (pos < 0) return;
	if (IsLegitimateClient(client)) {
		if (bIsSurvivorFatigue[client]) {
			float fCooldownPenalty = f_Cooldown * fFatigueCooldownPenalty;
			f_Cooldown += fCooldownPenalty;
		}
		SetArrayCell(PlayerAbilitiesCooldown[client], pos, 1);
		Handle packi;
		CreateDataTimer(f_Cooldown, Timer_RemoveCooldown, packi, TIMER_FLAG_NO_MAPCHANGE);
		WritePackCell(packi, client);
		WritePackCell(packi, pos);
	}
}

stock void CreateActiveCooldown(client, pos, float f_Cooldown) {
	if (pos < 0) return;
	if (IsLegitimateClient(client)) {
		if (bIsSurvivorFatigue[client]) {
			float fCooldownPenalty = f_Cooldown * fFatigueCooldownPenalty;
			f_Cooldown += fCooldownPenalty;
		}
		SetArrayCell(PlayerActiveAbilitiesCooldown[client], pos, 1);
		Handle packi;
		CreateDataTimer(f_Cooldown, Timer_RemoveActiveCooldown, packi, TIMER_FLAG_NO_MAPCHANGE);
		WritePackCell(packi, client);
		WritePackCell(packi, pos);
	}
}

stock bool HasAbilityPoints(client, char[] TalentName) {
	if (IsLegitimateClientAlive(client)) {
		int a_Size				=	0;
		a_Size		=	GetArraySize(a_Database_PlayerTalents[client]);
		char Name[PLATFORM_MAX_PATH];
		for (int i = 0; i < a_Size; i++) {
			GetArrayString(a_Database_Talents, i, Name, sizeof(Name));
			if (StrEqual(Name, TalentName)) {
				GetArrayString(a_Database_PlayerTalents[client], i, Name, sizeof(Name));
				if (StringToInt(Name) > 0) return true;
			}
		}
	}
	return false;
}

stock GetUpgradeExperienceCost(client, bool b_IsLevelUp = false) {
	int experienceCost = 0;
	if (IsLegitimateClient(client)) {
		if (fUpgradeExpCost < 1.0) experienceCost		= RoundToCeil(CheckExperienceRequirement(client) * ((UpgradesAwarded[client] + 1) * fUpgradeExpCost));
		else experienceCost = CheckExperienceRequirement(client);
	}
	return experienceCost;
}

stock PrintToSurvivors(RPGMode, char[] SurvivorName, char[] InfectedName, SurvExp, float SurvPoints) {
	for (int i = 1; i <= MaxClients; i++) {
		if (IsLegitimateClient(i) && !IsFakeClient(i) && myCurrentTeam[i] == TEAM_SURVIVOR) {
			if (RPGMode == 1) PrintToChat(i, "%T", "Experience Earned Total Team Survivor", i, white, blue, white, orange, white, green, white, SurvivorName, InfectedName, SurvExp);
			else if (RPGMode == 2) PrintToChat(i, "%T", "Experience Points Earned Total Team Survivor", i, white, blue, white, orange, white, green, white, green, white, SurvivorName, InfectedName, SurvExp, SurvPoints);
		}
	}
}

stock PrintToInfected(RPGMode, char[] SurvivorName, char[] InfectedName, InfTotalExp, float InfTotalPoints) {
	for (int i = 1; i <= MaxClients; i++) {
		if (IsLegitimateClient(i) && !IsFakeClient(i) && myCurrentTeam[i] == TEAM_INFECTED) {
			if (RPGMode == 1) PrintToChat(i, "%T", "Experience Earned Total Team", i, white, orange, white, green, white, InfectedName, InfTotalExp);
			else if (RPGMode == 2) PrintToChat(i, "%T", "Experience Points Earned Total Team", i, white, orange, white, green, white, green, white, InfectedName, InfTotalExp, InfTotalPoints);
		}
	}
}

stock ResetOtherData(client) {
	if (IsLegitimateClient(client)) {
		for (int i = 1; i <= MAXPLAYERS; i++) {
			DamageAward[client][i]		=	0;
			DamageAward[i][client]		=	0;
			CoveredInBile[client][i]	=	-1;
			CoveredInBile[i][client]	=	-1;
		}
	}
}

stock LivingInfected(bool KillAll=false) {
	int count = 0;
	for (int i = 1; i <= MaxClients; i++) {
		if (IsLegitimateClient(i) && myCurrentTeam[i] == TEAM_INFECTED && FindZombieClass(i) != ZOMBIECLASS_TANK) {
			if (KillAll) ForcePlayerSuicide(i);
			else count++;
		}
	}
	return count;
}

stock LivingSurvivors() {
	int count = 0;
	for (int i = 1; i <= MaxClients; i++) {
		if (IsLegitimateClientAlive(i) && myCurrentTeam[i] == TEAM_SURVIVOR) count++;
	}
	return count;
}

stock TotalSurvivors() {
	int count = 0;
	for (int i = 1; i <= MaxClients; i++) {
		if (IsLegitimateClient(i) && myCurrentTeam[i] == TEAM_SURVIVOR) count++;
	}
	return count;
}

stock ChangeInfectedClass(client, zombieclass = 0, bool dontChangeClass = false) {
	bool clientIsFake = IsLegitimateClient(client) && IsFakeClient(client);
	if (clientIsFake || IsLegitimateClient(client)) {
		if (myCurrentTeam[client] == TEAM_INFECTED) {
			if (!dontChangeClass) {
				if (!IsGhost(client)) SetEntProp(client, Prop_Data, "m_takedamage", 1, 1);
				int wi;
				while ((wi = GetPlayerWeaponSlot(client, 0)) != -1) {
					if (wi > 0) {
						RemovePlayerItem(client, wi);
						if (IsValidEntity(wi)) AcceptEntityInput(wi, "Kill");
					}
				}
				SDKCall(g_hSetClass, client, zombieclass);
				if (clientIsFake) {
					if (zombieclass == 1) SetClientInfo(client, "name", "Smoker");
					else if (zombieclass == 2) SetClientInfo(client, "name", "Boomer");
					else if (zombieclass == 3) SetClientInfo(client, "name", "Hunter");
					else if (zombieclass == 4) SetClientInfo(client, "name", "Spitter");
					else if (zombieclass == 5) SetClientInfo(client, "name", "Jockey");
					else if (zombieclass == 6) SetClientInfo(client, "name", "Charger");
					else if (zombieclass == 8) SetClientInfo(client, "name", "Tank");
				}
				AcceptEntityInput(MakeCompatEntRef(GetEntProp(client, Prop_Send, "m_customAbility")), "Kill");
				if (IsPlayerAlive(client)) SetEntProp(client, Prop_Send, "m_customAbility", GetEntData(SDKCall(g_hCreateAbility, client), g_oAbility));
				if (!IsGhost(client)) SetEntProp(client, Prop_Data, "m_takedamage", 2, 1);		// client can be killed again.
			}
			SpeedMultiplier[client] = 1.0;		// defaulting the speed. It'll get modified in speed modifer spawn talents.
			SetEntPropFloat(client, Prop_Send, "m_flLaggedMovementValue", SpeedMultiplier[client]);
			SetSpecialInfectedHealth(client, zombieclass);
		}
	}
}

stock bool HasIdlePlayer(int bot) {
    int userid = GetEntData(bot, FindSendPropInfo("SurvivorBot", "m_humanSpectatorUserID"));
    int client = GetClientOfUserId(userid);
    if (IsLegitimateClient(client) && !IsFakeClient(client) && myCurrentTeam[client] != TEAM_SURVIVOR) return true;
    return false;
}

stock bool IsClientIdle(int client) {
	for (int i = 1; i <= MaxClients; i++) {
		if (!IsLegitimateClient(i) || !IsFakeClient(i) || myCurrentTeam[i] != TEAM_SURVIVOR || !HasIdlePlayer(i)) continue;
		int userid = GetEntData(i, FindSendPropInfo("SurvivorBot", "m_humanSpectatorUserID"));
		int spec = GetClientOfUserId(userid);
		if (spec == client) return true;
	}
	return false;
}

stock SetSpecialInfectedHealth(attacker, zombieclass = 0) {
	int t_InfectedHealth = 0;
	int myzombieclass = (zombieclass == 0) ? FindZombieClass(attacker) : zombieclass;
	if (myzombieclass == 7 || myzombieclass == 9 || myzombieclass == -1) return;

	t_InfectedHealth = (myzombieclass != ZOMBIECLASS_TANK) ? iBaseSpecialInfectedHealth[myzombieclass - 1] : iBaseSpecialInfectedHealth[myzombieclass - 2];

	OriginalHealth[attacker] = t_InfectedHealth;
	GetAbilityStrengthByTrigger(attacker, _, TRIGGER_a, _, 0);

	DefaultHealth[attacker] = OriginalHealth[attacker];
}

stock TotalHumanSurvivors(ignore = -1) {
	int count = 0;
	for (int i = 1; i <= MaxClients; i++) {
		if (ignore != -1 && i == ignore) continue;
		if (!IsLegitimateClient(i) || IsFakeClient(i) || myCurrentTeam[i] != TEAM_SURVIVOR) continue;
		count++;
	}
	return count;
}

stock LivingHumanSurvivors() {
	int count = 0;
	for (int i = 1; i <= MaxClients; i++) {
		if (!IsLegitimateClient(i) || IsFakeClient(i) || !IsPlayerAlive(i) || myCurrentTeam[i] != TEAM_SURVIVOR) continue;
		count++;
	}
	return count;
}

stock HumanPlayersInGame() {
	int count = 0;
	for (int i = 1; i <= MaxClients; i++) {
		if (IsLegitimateClient(i) && !IsFakeClient(i) && myCurrentTeam[i] != TEAM_SPECTATOR) count++;
	}
	return count;
}

stock bool StringExistsArray(char[] Name, Handle array) {
	char text[PLATFORM_MAX_PATH];
	int a_Size			=	GetArraySize(array);
	for (int i = 0; i < a_Size; i++) {
		GetArrayString(array, i, text, sizeof(text));
		if (StrEqual(Name, text)) return true;
	}
	return false;
}

stock AddCommasToString(value, char[] theString, theSize) {
	char buffer[64];
	char separator[2];
	separator = ",";
	buffer[0] = '\0'; 
	int divisor = 1000; 
	int offcut = 0;

	while (value >= 1000 || value <= -1000) {
		offcut = value % divisor;
		value = RoundToFloor(float(value) / float(divisor));
		Format(buffer, sizeof(buffer), "%s%03.d%s", separator, offcut, buffer);
	}
	Format(theString, theSize, "%d%s", value, buffer);
}

stock ReceiveCommonDamage(client, entity, playerDamageTaken) {
	if (IsSpecialCommon(entity)) AddSpecialCommonDamage(client, entity, playerDamageTaken, true);
	else AddCommonInfectedDamage(client, entity, playerDamageTaken, true);
}

stock ReceiveWitchDamage(client, entity, playerDamageTaken, int contributionType = CONTRIBUTION_AWARD_TANKING) {
	int my_pos = FindListPositionByEntity(entity, WitchDamage[client]);

	if (my_pos < 0) {
		int my_size = GetArraySize(WitchDamage[client]);
		int WitchHealth = iWitchHealthBase;
		if (iBotLevelType == 0) WitchHealth += RoundToCeil(WitchHealth * (GetDifficultyRating(client) * fWitchHealthMult));
		else WitchHealth += RoundToCeil(WitchHealth * (SurvivorLevels() * fWitchHealthMult));

		//WitchDamage[client], my_size + 1);
		PushArrayCell(WitchDamage[client], entity);
		SetArrayCell(WitchDamage[client], my_size, WitchHealth, 1);
		SetArrayCell(WitchDamage[client], my_size, 0, 2);
		if (contributionType == CONTRIBUTION_AWARD_TANKING) SetArrayCell(WitchDamage[client], my_size, playerDamageTaken, 3);
		else if (contributionType == CONTRIBUTION_AWARD_BUFFING) SetArrayCell(WitchDamage[client], my_size, playerDamageTaken, 7);
		else if (contributionType == CONTRIBUTION_AWARD_HEALING) SetArrayCell(WitchDamage[client], my_size, playerDamageTaken, 8);
		SetArrayCell(WitchDamage[client], my_size, 0, 4);
	}
	else {
		if (contributionType == CONTRIBUTION_AWARD_TANKING) {
			int curTanking = GetArrayCell(WitchDamage[client], my_pos, 3);
			SetArrayCell(WitchDamage[client], my_pos, curTanking + playerDamageTaken, 3);
		}
		else if (contributionType == CONTRIBUTION_AWARD_BUFFING) {
			playerDamageTaken = RoundToCeil(playerDamageTaken * fBuffingAwarded);
			int curBuffing = GetArrayCell(WitchDamage[client], my_pos, 7);
			SetArrayCell(WitchDamage[client], my_pos, curBuffing + playerDamageTaken, 7);
		}
		else if (contributionType == CONTRIBUTION_AWARD_HEALING) {
			playerDamageTaken = RoundToCeil(playerDamageTaken * fHealingAwarded);
			int curHealing = GetArrayCell(WitchDamage[client], my_pos, 8);
			SetArrayCell(WitchDamage[client], my_pos, curHealing + playerDamageTaken, 8);
		}
	}
}

//if (CheckTeammateDamages(target, client) >= 1.0 || CheckTeammateDamages(target, client, true) >= 1.0) {
stock int AddCommonInfectedDamage(client, entity, playerDamage = 0, bool IsStatusDamage = false, damagetype = -1, ammotype = -1, hitgroup = -1) {
	int pos		= FindListPositionByEntity(entity, CommonInfected[client]);
	
	int commonDamageReceived = -1;
	int commonHealthRemaining = -1;
	if (pos < 0) {
		//RemoveCommonInfected(entity);
		pos = GetArraySize(CommonInfected[client]);
		//ResizeArray(CommonInfected[client], pos+1);
		PushArrayCell(CommonInfected[client], entity);
		char stringRef[64];
		commonHealthRemaining = GetCharacterSheetData(client, stringRef, 64, 1);
		commonDamageReceived = 0;
		SetArrayCell(CommonInfected[client], pos, commonHealthRemaining, 1);
		SetArrayCell(CommonInfected[client], pos, 0, 2);
	}
	//if (IsSpecialCommonInRange(entity, 't')) return 1;
	if (playerDamage < 1) return 1;
	if (!IsStatusDamage) {
		if (commonHealthRemaining == -1) {
			commonDamageReceived = GetArrayCell(CommonInfected[client], pos, 2);
			commonHealthRemaining = GetArrayCell(CommonInfected[client], pos, 1);
		}
		commonHealthRemaining = RoundToCeil(commonHealthRemaining * (1.0 - CheckTeammateDamages(entity, client, _, true)));
		if (hitgroup == HITGROUP_HEAD || playerDamage >= commonHealthRemaining) playerDamage = commonHealthRemaining;
		DamageContribution[client] += RoundToFloor(playerDamage * SurvivorExperienceMult);
		SetArrayCell(CommonInfected[client], pos, commonDamageReceived + playerDamage, 2);
		SetArrayCell(playerContributionTracker[client], CONTRIBUTION_TRACKER_DAMAGE, GetArrayCell(playerContributionTracker[client], CONTRIBUTION_TRACKER_DAMAGE) + playerDamage);
		CheckTeammateDamagesEx(client, entity, playerDamage, hitgroup, ((hitgroup == HITGROUP_HEAD) ? true : false));
		if (playerDamage == commonHealthRemaining) return playerDamage;
		return 1;
	}
	int tankingDamageReceived = GetArrayCell(CommonInfected[client], pos, 3);
	SetArrayCell(CommonInfected[client], pos, tankingDamageReceived + playerDamage, 3);
	return -1 * playerDamage;
}

stock AddWitchDamage(client, entity, playerDamageToWitch, bool IsStatusDamage = false, damagevariant = -1, ammotype = -1, hitgroup = -1) {
	int damageTotal = -1;
	int healthTotal = -1;
	
	if (client == -1) {
		for (int i = 1; i <= MaxClients; i++) {
			if (!IsLegitimateClient(i) || myCurrentTeam[i] != TEAM_SURVIVOR) continue;
			AddWitchDamage(i, entity, playerDamageToWitch, _, 2);	// 2 so we subtract from her health but don't reward any players.
		}
		return 1;
	}

	int my_size	= GetArraySize(WitchDamage[client]);
	int my_pos	= FindListPositionByEntity(entity, WitchDamage[client]);
	// create an instance of the witch for the player, because one wasn't found.
	if (my_pos < 0) {
		//ResizeArray(WitchDamage[client], my_size + 1);
		PushArrayCell(WitchDamage[client], entity);
		char stringRef[64];
		SetArrayCell(WitchDamage[client], my_size, GetCharacterSheetData(client, stringRef, 64, 3), 1);
		SetArrayCell(WitchDamage[client], my_size, 0, 2);
		SetArrayCell(WitchDamage[client], my_size, 0, 3);
		SetArrayCell(WitchDamage[client], my_size, 0, 4);
		my_pos = my_size;
	}
	if (playerDamageToWitch >= 0) {
		healthTotal = GetArrayCell(WitchDamage[client], my_pos, 1);
		healthTotal = RoundToCeil(healthTotal * (1.0 - CheckTeammateDamages(entity, client, _, true)));
		//new TrueHealthRemaining = RoundToCeil((1.0 - CheckTeammateDamages(entity, client)) * healthTotal);	// in case other players have damaged the mob - we can't just assume the remaining health without comparing to other players.
		if (damagevariant != 2) {
			damageTotal = GetArrayCell(WitchDamage[client], my_pos, 2);
			if (damageTotal < 0) damageTotal = 0;
			if (healthTotal < playerDamageToWitch) playerDamageToWitch = healthTotal;
			//if (IsSpecialCommonInRange(entity, 't')) return 1;
			//if (playerDamageToWitch > TrueHealthRemaining) playerDamageToWitch = TrueHealthRemaining;

			SetArrayCell(WitchDamage[client], my_pos, damageTotal + playerDamageToWitch, 2);
			if (playerDamageToWitch > 0) {
				GetProficiencyData(client, GetWeaponProficiencyType(client), RoundToCeil(playerDamageToWitch * fProficiencyExperienceEarned));
				SetArrayCell(playerContributionTracker[client], CONTRIBUTION_TRACKER_DAMAGE, GetArrayCell(playerContributionTracker[client], CONTRIBUTION_TRACKER_DAMAGE) + playerDamageToWitch);
			}
		}
		else SetArrayCell(WitchDamage[client], my_pos, healthTotal - playerDamageToWitch, 1);
	}
	else {

		/*

			When the witch is burning, or hexed (ie it is simply losing health) we come here instead.
			Negative values detract from the overall health instead of adding player contribution.
		*/
		damageTotal = GetArrayCell(WitchDamage[client], my_pos, 1);
		SetArrayCell(WitchDamage[client], my_pos, damageTotal + playerDamageToWitch, 1);
	}
	CheckTeammateDamagesEx(client, entity, playerDamageToWitch, hitgroup);
	ThreatCalculator(client, playerDamageToWitch);
	return 1;
}

/*

	This function removes a dying (or dead) common infected from all client cooldown arrays.
*/
stock RemoveCommonAffixes(entity) {
	int size = GetArraySize(CommonAffixes);
	int ent = -1;
	for (int i = 0; i < size; i++) {
		ent = GetArrayCell(CommonAffixes, i);
		if (entity != ent) continue;
		RemoveFromArray(CommonAffixes, i);
		break;
	}
}

stock FindInfectedClient(bool GetClient=false) {

	int count = 0;
	for (int i = 1; i <= MaxClients; i++) {

		if (IsLegitimateClient(i) && myCurrentTeam[i] == TEAM_INFECTED) {

			if (GetClient) return i;
			count++;
		}
	}
	return count;
}

stock CreateAoE(int owner, int menuPos, float fRangeOfEffect, amount, effectType = 0, bool bMustBeSameTeamAsOwner = true, int hitgroup, int damagetype, int targetCallAbilityTrigger) {
	float ownerPos[3];
	GetEntPropVector(owner, Prop_Send, "m_vecOrigin", ownerPos);
	int playersInRange = 0;
	int ownerTeam = myCurrentTeam[owner];
	for (int teammate = 1; teammate <= MaxClients; teammate++) {
		if (teammate == owner) continue;
		if (!IsLegitimateClientAlive(teammate) || bMustBeSameTeamAsOwner && myCurrentTeam[teammate] != ownerTeam) continue;
		float teammatePos[3];
		GetClientAbsOrigin(teammate, teammatePos);
		if (GetVectorDistance(ownerPos, teammatePos) > 384.0 || GetClientHealth(teammate) >= GetMaximumHealth(teammate)) continue;
		playersInRange++;
		if (effectType == 0) HealPlayer(teammate, owner, amount * 1.0, 'h', true);
		if (targetCallAbilityTrigger >= 0) GetAbilityStrengthByTrigger(teammate, owner, targetCallAbilityTrigger, _, amount, _, _, _, _, _, _, hitgroup, _, damagetype);
	}
	if (playersInRange > 0) CreateRing(owner, 384.0, menuPos, false);
}

stock CreatePlayerExplosion(client, damageToDealToEligibleTargets, bool bDontHurtAllies = true) {
	float originOfExplosion[3];
	GetEntPropVector(client, Prop_Send, "m_vecOrigin", originOfExplosion);
	float fRangeOfExplosion = 256.0;

	float realPlayerOrigin[3];
	CreateExplosion(client);
	ScreenShake(client);
	CreateExplosionRingOnClient(client, 512.0);

	for (int realPlayer = 1; realPlayer <= MaxClients; realPlayer++) {
		if (realPlayer == client || !IsLegitimateClientAlive(realPlayer)) continue;
		//if (bDontHurtAllies && team == myCurrentTeam[client] || team == TEAM_SURVIVOR && (PlayerLevel[realPlayer] < 20 || IsFakeClient(realPlayer))) continue;
		if (myCurrentTeam[realPlayer] == myCurrentTeam[client] || myCurrentTeam[realPlayer] == TEAM_SURVIVOR && (PlayerLevel[realPlayer] < 20 || IsFakeClient(realPlayer))) continue;
		GetEntPropVector(realPlayer, Prop_Send, "m_vecOrigin", realPlayerOrigin);
		if (GetVectorDistance(originOfExplosion, realPlayerOrigin) > fRangeOfExplosion) continue;
		if (!IsFakeClient(realPlayer)) ScreenShake(realPlayer);
		if (FindZombieClass(realPlayer) == ZOMBIECLASS_TANK) ChangeTankState(realPlayer, "fire", true);
		if (myCurrentTeam[realPlayer] == TEAM_INFECTED) AddSpecialInfectedDamage(client, realPlayer, damageToDealToEligibleTargets);
		else SetClientTotalHealth(client, realPlayer, damageToDealToEligibleTargets);
	}
	// witches.
	for (int pos = 0; pos < GetArraySize(WitchList); pos++) {
		int witch = GetArrayCell(WitchList, pos);
		if (!IsWitch(witch)) continue;	// pruned elsewhere
		GetEntPropVector(witch, Prop_Send, "m_vecOrigin", realPlayerOrigin);
		if (GetVectorDistance(originOfExplosion, realPlayerOrigin) > fRangeOfExplosion) continue;
		AddWitchDamage(client, witch, damageToDealToEligibleTargets);
	}
	// special commons
	for (int pos = 0; pos < GetArraySize(CommonAffixes); pos++) {
		int common = GetArrayCell(CommonAffixes, pos);
		//if (!IsSpecialCommon(common)) continue;	// pruned elsewhere
		GetEntPropVector(common, Prop_Send, "m_vecOrigin", realPlayerOrigin);
		if (GetVectorDistance(originOfExplosion, realPlayerOrigin) > fRangeOfExplosion) continue;
		AddSpecialCommonDamage(client, common, damageToDealToEligibleTargets);
	}
	// commons
	for (int pos = 0; pos < GetArraySize(CommonInfected[client]); pos++) {
		int common = GetArrayCell(CommonInfected[client], pos);
		//if (IsSpecialCommon(common) || !IsCommonInfected(common)) continue;	// pruned elsewhere
		GetEntPropVector(common, Prop_Send, "m_vecOrigin", realPlayerOrigin);
		if (GetVectorDistance(originOfExplosion, realPlayerOrigin) > fRangeOfExplosion) continue;
		AddCommonInfectedDamage(client, common, damageToDealToEligibleTargets);
	}
}

stock GetTeamRatingAverage(teamToGatherRatingOf = 2) {	// 2 == survivors
	int rating = 0;
	int count = 0;
	for (int i = 1; i <= MaxClients; i++) {
		if (!IsLegitimateClient(i) || myCurrentTeam[i] != teamToGatherRatingOf || PlayerLevel[i] < iLevelRequiredToEarnScore) continue;
		rating += Rating[i];
		if (!IsFakeClient(i)) count++;
	}
	if (count > 1) rating /= count;
	return rating;
}

stock OnCommonCreated(entity, bool bIsDestroyed = false, bool isSpecial = false) {

	//char EntityId[64];
	//Format(EntityId, sizeof(EntityId), "%d", entity);
	if (!bIsDestroyed) return;//PushArrayCell(CommonList, entity);
	else if (isSpecial || IsSpecialCommon(entity)) ClearSpecialCommon(entity);
}
stock GetCommonBaseHealth(client = 0) {
	int ratingVal = (client == 0) ? GetTeamRatingAverage() : GetDifficultyRating(client);
	return (iCommonBaseHealth + RoundToCeil(iCommonBaseHealth * (ratingVal * fCommonLevelHealthMult)));
}

void InitCommonInfected(int entity) {
	//if (!b_IsActiveRound) return;
	int damagePos = FindListPositionByEntity(entity, damageOfCommonInfected);
	if (damagePos == -1) {
		damagePos = GetArraySize(damageOfCommonInfected);
		PushArrayCell(damageOfCommonInfected, entity);
	}
	SetArrayCell(damageOfCommonInfected, damagePos, 0, 1);
}

void RemoveCommonInfected(int entity, bool ignite = false) {
	if (!b_IsActiveRound) {
		//if (IsCommonInfected(entity)) AcceptEntityInput(entity, "Kill");
		return;
	}
	if (IsSpecialCommon(entity)) return;
	for (int i = 1; i <= MaxClients; i++) {
		if (!IsLegitimateClient(i)) continue;
		int pos = FindListPositionByEntity(entity, CommonInfected[i]);
		if (pos >= 0) RemoveFromArray(CommonInfected[i], pos);
	}
	// SDKUnhook(entity, SDKHook_OnTakeDamage, OnTakeDamage);
	// SDKUnhook(entity, SDKHook_TraceAttack, OnTraceAttack);
	if (!ignite) {
		if (!CommonInfectedModel(entity, FALLEN_SURVIVOR_MODEL)) AcceptEntityInput(entity, "BecomeRagdoll");
		else SetEntProp(entity, Prop_Data, "m_iHealth", 1);
	}
	else {
		SetEntProp(entity, Prop_Data, "m_iHealth", 1);
		IgniteEntity(entity, 1.0);
	}
}

/*

	Witches are created different than other infected.
	If we want to track them and then remove them when they die
	we need to write custom code for it.

	This function serves to manage, maintain, and remove dead witches
	from both the list of active witches as well as reward players who
	hurt them and then reset that said damage as well.
*/
stock OnWitchCreated(entity, bool bIsDestroyed = false, lastHitAttacker = 0) {
	if (WitchList == INVALID_HANDLE) return;

	int damagePos = FindListPositionByEntity(entity, damageOfWitch);
	if (!bIsDestroyed) {

		/*

			When a new witch is created, we add them to the list, and then we
			make sure all survivor players lists are the same size.
		*/
		PushArrayCell(WitchList, entity);
		//SetInfectedHealth(entity, 50000);
		//SDKHook(entity, SDKHook_OnTakeDamage, OnTakeDamage);
		if (damagePos == -1) {
			damagePos = GetArraySize(damageOfWitch);
			//ResizeArray(damageOfWitch, damagePos+1);
			PushArrayCell(damageOfWitch, entity);
		}
		SetArrayCell(damageOfWitch, damagePos, 0, 1);
		//SDKHook(entity, SDKHook_TraceAttack, OnTraceAttack);

		//CreateMyHealthPool(entity);
	}
	else {
		/*

			When a Witch dies, we reward all players who did damage to the witch
			and then we remove the row of the witch id in both the witch list
			and in player lists.
		*/
		int pos = FindListPositionByEntity(entity, WitchList);
		if (pos >= 0) {
			LogMessage("[WITCH_LIST] Witch %d Killed", entity);
			// SDKUnhook(entity, SDKHook_OnTakeDamage, OnTakeDamage);
			// SDKUnhook(entity, SDKHook_TraceAttack, OnTraceAttack);
			if (IsWitch(entity)) AcceptEntityInput(entity, "Kill");
			RemoveFromArray(WitchList, pos);		// Delete the witch. Forever. now occurs in CalculateInfectedDamageAward()
		}
		if (damagePos >= 0) RemoveFromArray(damageOfWitch, damagePos);
	}
}

stock FindEntityInString(char[] SearchKey, char[] Delim = ":") {

	if (StrContains(SearchKey, Delim, false) == -1) return -1;
	char tExploded[2][64];

	ExplodeString(SearchKey, Delim, tExploded, 2, 64);
	return StringToInt(tExploded[1]);
}

stock GetArraySizeEx(char[] SearchKey, char[] Delim = ":") {

	int count = 0;
	for (int i = 0; i <= strlen(SearchKey); i++) {

		if (StrContains(SearchKey[i], Delim, false) != -1) count++;
	}
	if (count == 0) return -1;
	return count + 1;
}

stock FindDelim(char[] EntityName, char[] Delim = ":") {

	char DelimStr[2];

	for (int i = 0; i <= strlen(EntityName); i++) {

		Format(DelimStr, sizeof(DelimStr), "%s", EntityName[i]);
		if (StrContains(DelimStr, Delim, false) != -1) {

			// Found it!
			return i + 1;
		}
	}
	return -1;
}

stock GetDelimiterCount(char[] TextCase, char[] Delimiter) {

	int count = 0;
	char Delim[2];
	for (int i = 0; i <= strlen(TextCase); i++) {

		Format(Delim, sizeof(Delim), "%s", TextCase[i]);
		if (StrContains(Delim, Delimiter, false) != -1) count++;
	}
	return count;
}

stock FindListPositionBySearchKey(char[] SearchKey, Handle h_SearchList, block = 0, bool bDebug = false) {
	// Some parts of rpg are formatted differently, so we need to check by entityname instead of id.
	char SearchId[64];
	int size = GetArraySize(h_SearchList);
	for (int i = 0; i < size; i++) {
		SearchKey_Section						= GetArrayCell(h_SearchList, i, block);
		if (GetArraySize(SearchKey_Section) < 1) {
			continue;
		}
		GetArrayString(SearchKey_Section, 0, SearchId, sizeof(SearchId));
		if (StrEqual(SearchId, SearchKey, false)) {
			return i;
		}
	}
	return -1;
}

stock bool IsSurvivorInAGroup(client) {
	if (IsFakeClient(client)) return false;	// we don't penalize players if bots die, so we always assume bots "aren't in a group" during this phase
	ClearArray(MyGroup[client]);
	// Checks if a player is in a group, right before they die.
	// While the dying player loses it all, group members will also lose a percentage of their XP, based on their group size.
	// Small groups have a larger split of the total XP, which means they also take a larger penalty when one of their members goes out.
	float Origin[3];
	GetClientAbsOrigin(client, Origin);
	float Pos[3];
	char AuthID[64];
	for (int i = 1; i <= MaxClients; i++) {
		if (i == client || !IsLegitimateClientAlive(i) || myCurrentTeam[i] != TEAM_SURVIVOR || IsFakeClient(i)) continue;
		GetClientAbsOrigin(i, Pos);
		if (GetVectorDistance(Origin, Pos) <= 1536.0 || IsPlayerRushing(i)) {	// rushers get treated like they're a member of everyone who dies group, so that they are punished every time someone dies.
			GetClientAuthId(i, AuthId_Steam2, AuthID, sizeof(AuthID));
			PushArrayString(MyGroup[client], AuthID);
		}
	}
	if (GetArraySize(MyGroup[client]) < iSurvivorGroupMinimum) return false;
	return true;
}

stock bool IsPlayerRushing(client, float fDistance = 2048.0) {

	int TotalClients = LivingHumanSurvivors();
	int MyGroupSize = GroupSize(client);
	int LargestGroup = GroupSize();

	if (!AnyGroups() && MyGroupSize >= LargestGroup || TotalClients <= iSurvivorGroupMinimum || NearbySurvivors(client, fDistance, true, true) >= iSurvivorGroupMinimum) return false;
	return true;
}

stock float SurvivorRushingMultiplier(client, bool IsForTankTeleport = false) {

	int SurvivorsCount	= LivingHumanSurvivors();
	if (SurvivorsCount <= iSurvivorGroupMinimum) return 1.0;	// no penalty if less players than group minimum exist.

	int SurvivorsNear	= NearbySurvivors(client, 1536.0, true, true);
	if (SurvivorsNear >= iSurvivorGroupMinimum) return 1.0; // If the player is in a group of players, they take no penalty.
	else if (IsForTankTeleport) return -2.0;					// If tanks are trying to find a player to teleport to, if this player isn't in a group, they are eligible targets.

	float GetMultiplier = 1.0 / SurvivorsCount;
	GetMultiplier *= SurvivorsNear;
	return GetMultiplier;
}

stock bool AnyGroups() {

	for (int i = 1; i <= MaxClients; i++) {

		if (!IsLegitimateClientAlive(i) || myCurrentTeam[i] != TEAM_SURVIVOR) continue;
		if (NearbySurvivors(i, 1536.0, true) >= iSurvivorGroupMinimum) return true;
	}
	return false;
}

stock GroupSize(client = 0) {

	if (client > 0) return NearbySurvivors(client, 1536.0, true);
	int largestGroup = 0;
	int count = 0;
	for (int i = 1; i <= MaxClients; i++) {

		if (client == i || !IsLegitimateClientAlive(i) || myCurrentTeam[i] != TEAM_SURVIVOR) continue;
		count = NearbySurvivors(i, 1536.0, true);
		if (count > largestGroup) largestGroup = count;
	}
	return count;
}

stock NearbySurvivors(client, float range = 512.0, bool Survivors = false, bool IsRushing = false) {

	float pos[3];
	if (IsLegitimateClientAlive(client)) GetClientAbsOrigin(client, pos);
	else GetEntPropVector(client, Prop_Send, "m_vecOrigin", pos);
	float spos[3];

	int count = 0;
	int TheTime = GetTime();

	for (int i = 1; i <= MaxClients; i++) {

		if (IsLegitimateClientAlive(i) && myCurrentTeam[i] == TEAM_SURVIVOR && i != client) {

			if (Survivors && IsFakeClient(i)) continue;
			if (IsRushing && (MyBirthday[i] == 0 || (TheTime - MyBirthday[i]) < 60 || NearbySurvivors(i, 1536.0, true) < iSurvivorGroupMinimum)) {

				// If a player has only been in the game a short time, or is not near enough survivors to be in a group, we consider them part of everyone's group.

				count++;
				continue;
			}

			GetClientAbsOrigin(i, spos);
			if (GetVectorDistance(pos, spos) <= range) count++;
		}
	}
	return count;
}

stock NumSurvivorsInRange(client, float range = 512.0, int team = 2) {

	float pos[3];
	if (IsLegitimateClientAlive(client)) GetClientAbsOrigin(client, pos);
	else GetEntPropVector(client, Prop_Send, "m_vecOrigin", pos);
	float spos[3];
	int count = 0;
	for (int i = 1; i <= MaxClients; i++) {
		if (!IsLegitimateClientAlive(i) || myCurrentTeam[i] != team || i == client) continue;
		GetClientAbsOrigin(i, spos);
		if (GetVectorDistance(pos, spos) <= range) count++;
	}
	return count;
}

stock bool SurvivorsInRange(client, float range = 512.0, bool NoSurvivorBots = false) {

	float pos[3];
	if (IsLegitimateClientAlive(client)) GetClientAbsOrigin(client, pos);
	else GetEntPropVector(client, Prop_Send, "m_vecOrigin", pos);
	float spos[3];

	for (int i = 1; i <= MaxClients; i++) {
		if (!IsLegitimateClientAlive(i) || myCurrentTeam[i] != TEAM_SURVIVOR || i == client) continue;
		if (NoSurvivorBots && IsFakeClient(i)) continue;

		GetClientAbsOrigin(i, spos);
		if (GetVectorDistance(pos, spos) <= range) return true;
	}
	return false;
}

stock bool AnyTanksNearby(client, float range = 0.0) {

	if (range == 0.0) range = TanksNearbyRange;

	float pos[3];
	float ipos[3];
	for (int i = 1; i <= MaxClients; i++) {

		if (IsLegitimateClientAlive(i) && myCurrentTeam[i] == TEAM_INFECTED && FindZombieClass(i) == ZOMBIECLASS_TANK) {

			GetClientAbsOrigin(client, pos);
			GetClientAbsOrigin(i, ipos);
			if (GetVectorDistance(pos, ipos) <= range) return true;
		}
	}
	return false;
}

stock bool IsVectorsCrossed(client, float torigin[3], float aorigin[3], float f_Distance) {

	float porigin[3];
	float vorigin[3];
	MakeVectorFromPoints(torigin, aorigin, vorigin);
	if (GetVectorDistance(porigin, vorigin) <= f_Distance) return true;
	return false;
}

public OnEntityDestroyed(entity) {
	if (!IsWitch(entity) && !IsCommonInfected(entity)) return;
	if (!b_IsActiveRound) return;

	if (IsSpecialCommon(entity)) ClearSpecialCommon(entity);
	else {
		for (int i = 1; i <= MaxClients; i++) {
			if (!IsLegitimateClient(i)) continue;
			int ent = FindListPositionByEntity(entity, CommonInfected[i]);
			if (ent >= 0) RemoveFromArray(CommonInfected[i], ent);
		}
	}
}

bool IsPlayerZoomed(client) {
	return (GetEntPropEnt(client, Prop_Send, "m_hZoomOwner") == -1) ? false : true;
}

stock GetRockOwner(ent) {
	float fTankPos[3];
	float fRockPos[3];
	int tank = -1;
	GetEntPropVector(ent, Prop_Send, "m_vecOrigin", fRockPos);
	for (int i = 1; i <= MaxClients; i++) {

		if (!IsLegitimateClientAlive(i) || myCurrentTeam[i] != TEAM_INFECTED || FindZombieClass(i) != ZOMBIECLASS_TANK) continue;
		GetClientAbsOrigin(i, fTankPos);
		if (GetVectorDistance(fTankPos, fRockPos) >= 64.0) continue;

		tank = i;
		break;
	}
	if (tank != -1) {
		PrintToChatAll("\x04Tank \x03evolves \x04into Burn Tank!");
		ChangeTankState(tank, "burn");
		FindRandomSurvivorClient(tank, true);
		IsPlayerOnGroundOutsideOfTankZone(tank);
	}
}

public OnEntityCreated(entity, const char[] classname) {
	OnEntityCreatedEx(entity, classname);
}

stock OnEntityCreatedEx(entity, const char[] classname, bool creationOverride = false) {
	bool bIsCommonInfected = IsCommonInfected(entity);
	bool bIsWitch = (!bIsCommonInfected) ? IsWitch(entity) : false;
	if (!b_IsActiveRound && bIsCommonInfected) {
		AcceptEntityInput(entity, "Kill");
		return;
	}
	if (bIsWitch || bIsCommonInfected) {
		//SetInfectedHealth(entity, 50000);
		if (bIsWitch) OnWitchCreated(entity);
		SDKHook(entity, SDKHook_OnTakeDamage, OnTakeDamage);
		SDKHook(entity, SDKHook_TraceAttack, OnTraceAttack);
	}
	if (!b_IsActiveRound) return;
	if (StrEqual(classname, "tank_rock", false)) {
		//CreateTimer(1.4, Timer_DestroyRock, entity, TIMER_FLAG_NO_MAPCHANGE);
		GetRockOwner(entity);
	}
	if (creationOverride || bIsCommonInfected) {
		// SetInfectedHealth(entity, 500);
		if (CreateCommonAffix(entity) == 0) {
			if (GetArraySize(CommonInfectedQueue) > 0) {
				char Model[64];
				GetArrayString(CommonInfectedQueue, 0, Model, sizeof(Model));
				if (IsModelPrecached(Model)) SetEntityModel(entity, Model);
				RemoveFromArray(CommonInfectedQueue, 0);
			}
			InitCommonInfected(entity);
		}
		//SDKHook(entity, SDKHook_TraceAttack, OnTraceAttack);
	}
}

bool SurvivorsBeingQuiet() {
	for (int i = 1; i <= MaxClients; i++) {
		if (!IsLegitimateClientAlive(i) || IsFakeClient(i) || myCurrentTeam[i] != TEAM_SURVIVOR) continue;
		if (!clientIsWalking[i]) return false;
	}
	return true;
}

bool IsWitch(entity) {

	if (entity <= 0 || !IsValidEntity(entity)) return false;

	char className[16];
	GetEntityClassname(entity, className, sizeof(className));
	return strcmp(className, "witch") == 0;
}

bool IsCommonInfected(entity) {
	if (entity <= 0 || !IsValidEntity(entity)) return false;
	char className[16];
	GetEntityClassname(entity, className, sizeof(className));
	return strcmp(className, "infected") == 0;
}

stock ExperienceBarBroadcast(client, char[] sStatusEffects) {

	char eBar[64];
	char currExperience[64];
	char currExperienceTarget[64];
	if (myCurrentTeam[client] == TEAM_SURVIVOR) {
		ExperienceBar(client, eBar, sizeof(eBar));
		AddCommasToString(ExperienceLevel[client], currExperience, sizeof(currExperience));
		AddCommasToString(CheckExperienceRequirement(client), currExperienceTarget, sizeof(currExperienceTarget));

		if (BroadcastType == 0) PrintHintText(client, "%T", "Hint Text Broadcast 0", client, eBar);
		if (BroadcastType == 1) PrintHintText(client, "%T", "Hint Text Broadcast 1", client, eBar, currExperience, currExperienceTarget);
		if (BroadcastType == 2) PrintHintText(client, "%T", "Hint Text Broadcast 2", client, eBar, currExperience, currExperienceTarget, Points[client]);
	}
	else if (myCurrentTeam[client] == TEAM_INFECTED) {

		ExperienceBar(client, eBar, sizeof(eBar), 1);	// armor
		char aBar[64];
		ExperienceBar(client, aBar, sizeof(aBar), 2);	// actual health
		int tHealth = GetArrayCell(InfectedHealth[client], 0, 5);	// total health
		int dHealth = GetArrayCell(InfectedHealth[client], 0, 6);	// damage to health

		AddCommasToString(tHealth - dHealth, currExperience, sizeof(currExperience));
		AddCommasToString(tHealth, currExperienceTarget, sizeof(currExperienceTarget));

		PrintHintText(client, "%T", "Infected Health Broadcast", client, eBar, aBar, currExperience, currExperienceTarget, sStatusEffects);
	}
}

stock WipeDamageContribution(client) {

	/*

		This function will completely wipe out a players contribution and earnings.
		Use this when a player dies to essentially "give back" the health equal to contribution.
		Other players can then earn the contribution that is restored, albeit a mob that was about to die would
		suddenly gain a bunch of its life force back.
	*/
	if (IsLegitimateClient(client)) {

		ClearArray(InfectedHealth[client]);
		ClearArray(WitchDamage[client]);
		ClearArray(SpecialCommon[client]);
	}
}

stock float GetMyDamageContribution(int client, int pos, int ClientType) {
	int cHealth = -1;
	int tHealth = -1;
	if (ClientType == CLIENT_SPECIAL_INFECTED) {
		cHealth = GetArrayCell(InfectedHealth[client], pos, 2);
		tHealth = GetArrayCell(InfectedHealth[client], pos, 1);
	}
	else if (ClientType == CLIENT_WITCH) {
		cHealth = GetArrayCell(WitchDamage[client], pos, 2);
		tHealth = GetArrayCell(WitchDamage[client], pos, 1);
	}
	else if (ClientType == CLIENT_SUPER_COMMON) {
		cHealth = GetArrayCell(SpecialCommon[client], pos, 2);
		tHealth = GetArrayCell(SpecialCommon[client], pos, 1);
	}
	else {
		cHealth = GetArrayCell(CommonInfected[client], pos, 2);
		tHealth = GetArrayCell(CommonInfected[client], pos, 1);
	}
	float tBonus = (cHealth * 1.0) / (tHealth * 1.0);
	if (tBonus > 1.0) tBonus = 1.0;
	return tBonus;
}

stock float CheckTeammateDamages(infected, client = -1, bool bIsMyDamageOnly = false, bool skipMyDamage = false) {

	/*

		Common Infected have a shared-health pool, as a result we compare a players
		damage only when considering commons damage; the player who deals the killing blow
		on a common will receive the bonus.

		However, special commons and special infected will have separate health pools.
	*/

	float isDamageValue = 0.0;
	int pos = -1;
	int cHealth = 0;
	int tHealth = 0;
	float tBonus = 0.0;
	int enemytype = -1;
	if (IsLegitimateClient(infected)) enemytype = 0;
	else if (IsWitch(infected)) enemytype = 1;
	else if (IsSpecialCommon(infected)) enemytype = 2;
	else enemytype = 3;
	//else if (IsCommonInfected(infected)) enemytype = 3;
	for (int i = 1; i <= MaxClients; i++) {
		if (!IsLegitimateClient(i) || myCurrentTeam[i] != TEAM_SURVIVOR) continue;
		if (skipMyDamage && client == i) continue;
		if (bIsMyDamageOnly && client != i) continue;
		/*
			isDamageValue is a percentage of the total damage a player has dealt to the special infected.
			We calculate this by taking the player damage contribution and dividing it by the total health of the infected.
			we then add this value, and return the total of all players.
			if the value > or = to 1.0, the infected player dies.

			This health bar will display two health bars.
			True health: The actual health the infected player has remaining
			E. Health: The health the infected has FOR YOU
		*/
		if (enemytype == 0) {

			pos = FindListPositionByEntity(infected, InfectedHealth[i]);
			if (pos < 0) continue;	// how?
			cHealth = GetArrayCell(InfectedHealth[i], pos, 2);
			tHealth = GetArrayCell(InfectedHealth[i], pos, 1);
		}
		else if (enemytype == 1) {

			pos = FindListPositionByEntity(infected, WitchDamage[i]);
			if (pos < 0) continue;
			cHealth = GetArrayCell(WitchDamage[i], pos, 2);
			tHealth = GetArrayCell(WitchDamage[i], pos, 1);
		}
		else if (enemytype == 2) {

			pos = FindListPositionByEntity(infected, SpecialCommon[i]);
			if (pos < 0) continue;
			cHealth = GetArrayCell(SpecialCommon[i], pos, 2);
			tHealth = GetArrayCell(SpecialCommon[i], pos, 1);
		}
		else {

			pos = FindListPositionByEntity(infected, CommonInfected[i]);
			if (pos < 0) continue;
			cHealth = GetArrayCell(CommonInfected[i], pos, 2);
			tHealth = GetArrayCell(CommonInfected[i], pos, 1);
		}
		tBonus = (cHealth * 1.0) / (tHealth * 1.0);
		isDamageValue += tBonus;
		if (bIsMyDamageOnly) break;
	}
	//PrintToChatAll("Damage percent: %3.3f", isDamageValue);
	if (isDamageValue > 1.0) isDamageValue = 1.0;
	return isDamageValue;
}

stock DisplayInfectedHealthBars(int survivor, int infected, char[] superName = "0") {

	if (iRPGMode == -1) return;

	char text[512];
	if (StrEqual(superName, "0")) {
		if (IsLegitimateClient(infected)) GetClientName(infected, text, sizeof(text));
		else if (IsWitch(infected)) Format(text, sizeof(text), "Bitch");
		else if (IsCommonInfected(infected)) {
			if (!IsSpecialCommon(infected)) return;
			int superPos = FindListPositionByEntity(infected, CommonAffixes);
			if (superPos >= 0) {
				superPos = GetArrayCell(CommonAffixes, superPos, 1);
				GetCommonValueAtPosEx(text, sizeof(text), superPos, SUPER_COMMON_NAME);
			}
		}
	}
	else Format(text, sizeof(text), "%s", superName);

	//Format(text, sizeof(text), "%s %s", GetConfigValue("director team name?"), text);
	GetInfectedHealthBar(survivor, infected, false, clientContributionHealthDisplay[survivor], sizeof(clientContributionHealthDisplay[]));
	if (LivingSurvivors() > 1) {
		GetInfectedHealthBar(survivor, infected, true, clientTrueHealthDisplay[survivor], sizeof(clientTrueHealthDisplay[]));
		Format(text, sizeof(text), "E.HP%s(%s)\nCNT%s", clientTrueHealthDisplay[survivor], text, clientContributionHealthDisplay[survivor]);
	}
	else Format(text, sizeof(text), "CNT%s(%s)", clientContributionHealthDisplay[survivor], text);
	PrintCenterText(survivor, text);
}

stock bool IsClientCleansing(client) {

	if (IsClientInRangeSpecialAmmo(client, "C") > 0.0) return true;// && !IsPlayerFeeble(client)) return true;
	return false;
}

stock GetPlayerStamina(client) {
	int StaminaMax = iSurvivorStaminaMax + RoundToCeil(PlayerLevel[client] * fStaminaPerPlayerLevel);
	int StaminaBonus = RoundToCeil(GetAbilityStrengthByTrigger(client, client, TRIGGER_getstam, _, 0, _, _, RESULT_stamina, _, _, 2));
	if (StaminaBonus > 0) StaminaMax += StaminaBonus;

	float TheAbilityMultiplier = 0.0;
	TheAbilityMultiplier = GetAbilityMultiplier(client, "T");
	//if (TheAbilityMultiplier == -1.0) TheAbilityMultiplier = 0.0;	// no change
	if (TheAbilityMultiplier != -1) StaminaMax += RoundToCeil(StaminaMax * TheAbilityMultiplier);
	// Here we make sure that the players current stamina never goes above their maximum stamina.
	if (SurvivorStamina[client] > StaminaMax) SurvivorStamina[client] = StaminaMax;
	return StaminaMax;
}

// Not needed until versus support is added, and that won't be until infected talents are added.
// stock DisplayInfectedHUD(client, statusType) {
// 	GetStatusEffects(client, statusType, clientStatusEffectDisplay[client], sizeof(clientStatusEffectDisplay[]));
// 	ExperienceBarBroadcast(client, clientStatusEffectDisplay[client]);
// }

stock GetPlayerStaminaBar(client, char[] eBar, theSize) {

	Format(eBar, theSize, "[----------]");
	if (IsLegitimateClientAlive(client)) {

		/*

			Players have a stamina bar.
		*/

		float eCnt = 0.0;
		float ePct = (SurvivorStamina[client] * 1.0 / (GetPlayerStamina(client) * 1.0)) * 100.0;
		for (int i = 1; i < strlen(eBar); i++) {

			if (eCnt + 10.0 <= ePct) {

				eBar[i] = '~';
				eCnt += 10.0;
			}
		}
	}
}

stock GetTargetHealth(client, target, bool MyHealth = false) {

	int TotalHealth = 0;
	int DamageDealt = 0;
	int pos = -1;
	bool bIsSpecialCommon;
	bool bIsCommonInfected;
	bool bIsWitch;
	bool bIsLegitimateClient;
	if (IsSpecialCommon(target)) {
		pos = FindListPositionByEntity(target, SpecialCommon[client]);
		bIsSpecialCommon = true;
	}
	else if (IsCommonInfected(target)) {
		pos = FindListPositionByEntity(target, CommonInfected[client]);
		bIsCommonInfected = true;
	}
	else if (IsWitch(target)) {
		pos = FindListPositionByEntity(target, WitchDamage[client]);
		bIsWitch = true;
	}
	else if (IsLegitimateClientAlive(target)) {
		if (myCurrentTeam[target] == TEAM_INFECTED) {
			pos = FindListPositionByEntity(target, InfectedHealth[client]);
			bIsLegitimateClient = true;
		}
		else return GetClientHealth(target);
	}

	if (pos >= 0) {
		if (bIsWitch) {
			TotalHealth		= GetArrayCell(WitchDamage[client], pos, 1);
			DamageDealt		= GetArrayCell(WitchDamage[client], pos, 2);
		}
		else if (bIsLegitimateClient) {
			TotalHealth		= GetArrayCell(InfectedHealth[client], pos, 1);
			DamageDealt		= GetArrayCell(InfectedHealth[client], pos, 2);
		}
		else if (bIsSpecialCommon) {
			TotalHealth		= GetArrayCell(SpecialCommon[client], pos, 1);
			DamageDealt		= GetArrayCell(SpecialCommon[client], pos, 2);
		}
		else if (bIsCommonInfected) {
			TotalHealth		= GetArrayCell(CommonInfected[client], pos, 1);
			DamageDealt		= GetArrayCell(CommonInfected[client], pos, 2);
		}
		if (!MyHealth) TotalHealth = RoundToCeil((1.0 - CheckTeammateDamages(target, client)) * TotalHealth);
		else TotalHealth -= DamageDealt;
	}
	return TotalHealth;
}

stock GetHumanInfectedHealth(client) {

	float isHealthRemaining = CheckTeammateDamages(client);
	return RoundToCeil(GetMaximumHealth(client) * isHealthRemaining);
}

stock float GetClientHealthPercentageSurvivor(client, bool GetHealthRemaining = false) {
	float fHealthRemaining = (GetClientHealth(client) * 1.0) / (GetMaximumHealth(client) * 1.0);
	if (GetHealthRemaining) return fHealthRemaining;
	return 1.0 - fHealthRemaining;
}

stock bool IsInfectedTarget(client) {
	if (IsLegitimateClient(client) && myCurrentTeam[client] == TEAM_INFECTED) return true;
	if (IsWitch(client) || IsSpecialCommon(client) || IsCommonInfected(client)) return true;
	return false;
}

stock float GetClientHealthPercentage(client, target, bool GetHealthRemaining = false) {
	int pos = -1;
	if (IsLegitimateClient(target)) {
		if (myCurrentTeam[target] == TEAM_INFECTED) pos = FindListPositionByEntity(target, InfectedHealth[client]);
		else return GetClientHealthPercentageSurvivor(target, GetHealthRemaining);
	}
	else if (IsWitch(target)) pos = FindListPositionByEntity(target, WitchDamage[client]);
	else if (IsSpecialCommon(target)) pos = FindListPositionByEntity(target, SpecialCommon[client]);
	else pos = FindListPositionByEntity(target, CommonInfected[client]);

	if (pos < 0) return -1.0;
	float fHealthRemaining = CheckTeammateDamages(target, client);
	if (GetHealthRemaining) return 1.0 - fHealthRemaining;
	return fHealthRemaining;
}

stock GetInfectedHealthBar(survivor, infected, bool bTrueHealth = false, char[] eBar, theSize = 64, bool getHealthValue = false) {
	if (!getHealthValue) Format(eBar, theSize, "[----------------------------------------]");
	int pos = 0;
	bool bIsLegitimateClient;
	bool bIsWitch;
	bool bIsSpecialCommon;
	if (IsLegitimateClient(infected)) {
		pos = FindListPositionByEntity(infected, InfectedHealth[survivor]);
		bIsLegitimateClient = true;
	}
	else if (IsWitch(infected)) {
		pos = FindListPositionByEntity(infected, WitchDamage[survivor]);
		bIsWitch = true;
	}
	else if (IsSpecialCommon(infected)) {
		pos = FindListPositionByEntity(infected, SpecialCommon[survivor]);
		bIsSpecialCommon = true;
	}
	else if (IsCommonInfected(infected)) {
		pos = FindListPositionByEntity(infected, CommonInfected[survivor]);
	}
	if (pos >= 0) {
		float isHealthRemaining = 1.0;
		isHealthRemaining = CheckTeammateDamages(infected, survivor);
		// isDamageContribution is the total damage the player has, themselves, dealt to the special infected.
		int isDamageContribution = 0;
		int isTotalHealth = 0;
		if (bIsLegitimateClient) {
			isDamageContribution = GetArrayCell(InfectedHealth[survivor], pos, 2);
			isTotalHealth = GetArrayCell(InfectedHealth[survivor], pos, 1);
		}
		else if (bIsWitch) {
			isDamageContribution = GetArrayCell(WitchDamage[survivor], pos, 2);
			isTotalHealth = GetArrayCell(WitchDamage[survivor], pos, 1);
		}
		else if (bIsSpecialCommon) {
			isDamageContribution = GetArrayCell(SpecialCommon[survivor], pos, 2);
			isTotalHealth = GetArrayCell(SpecialCommon[survivor], pos, 1);
		}
		else {
			isDamageContribution = GetArrayCell(CommonInfected[survivor], pos, 2);
			isTotalHealth = GetArrayCell(CommonInfected[survivor], pos, 1);
		}
		if (getHealthValue) return isTotalHealth;
		//new Float:tPct = 100.0 - (isHealthRemaining * 100.0);
		//new Float:yPct = ((isDamageContribution * 1.0) / (isTotalHealth * 1.0) * 100.0);
		float ePct = 0.0;
		if (bTrueHealth) ePct = 100.0 - (isHealthRemaining * 100.0);
		else ePct = ((isDamageContribution * 1.0) / (isTotalHealth * 1.0) * 100.0);
		float eCnt = 0.0;
		for (int i = 1; i + 1 < strlen(eBar); i++) {
			if (eCnt + 2.5 < ePct) {
				eBar[i] = '|';
				eCnt += 2.5;
			}
		}
	}
	return 0;
}

stock ExperienceBar(client, char[] sTheString, iTheSize, iBarType = 0, bool bReturnValue = false) {// 0 XP, 1 Infected armor (humans only), 2 Infected Health from talents, etc. (humans only)

	//char eBar[256];
	float ePct = 0.0;
	if (iBarType == 0) ePct = ((ExperienceLevel[client] * 1.0) / (CheckExperienceRequirement(client) * 1.0)) * 100.0;
	else if (iBarType == 1) ePct = 100.0 - CheckTeammateDamages(client) * 100.0;
	else if (iBarType == 2) {

		ePct = (GetArrayCell(InfectedHealth[client], 0, 6) / GetArrayCell(InfectedHealth[client], 0, 5)) * 100.0;
	}
	if (bReturnValue) {

		Format(sTheString, iTheSize, "%3.3f", ePct);
	}
	else {

		float eCnt = 0.0;
		//Format(eBar, sizeof(eBar), "[--------------------]");
		Format(sTheString, iTheSize, "<....................>");

		for (int i = 1; i + 1 <= strlen(sTheString); i++) {

			if (eCnt + 10.0 < ePct) {

				sTheString[i] = '|';
				eCnt += 5.0;
			}
		}
	}

	//return eBar;
}

stock MenuExperienceBar(client, currXP = -1, nextXP = -1, char[] eBar, theSize) {

	float ePct = 0.0;
	if (currXP == -1) currXP = ExperienceLevel[client];
	if (nextXP == -1) nextXP = CheckExperienceRequirement(client);
	ePct = ((currXP * 1.0) / (nextXP * 1.0)) * 100.0;

	float eCnt = 0.0;
	Format(eBar, theSize, "<__________>");

	for (int i = 1; i + 1 <= strlen(eBar); i++) {

		if (eCnt < ePct) {

			eBar[i] = '~';
			eCnt += 10.0;
		}
	}
}

stock CartelLevel(client) {
	return PlayerLevel[client];
}

stock bool IsOpenRPGMenu(char[] searchString) {
	char[][] RPGCommands = new char[RPGMenuCommandExplode][16];
	ExplodeString(RPGMenuCommand, ",", RPGCommands, RPGMenuCommandExplode, 16);
	for (int i = 0; i < RPGMenuCommandExplode; i++) {
		if (StrContains(searchString, RPGCommands[i], false) != -1) return true;
	}
	return false;
}

stock void GetFormattedPlayerName(int client, char[] stringToStoreFormat, int stringToStoreFormatSize) {
	char avgAugLvl[10];
	AddCommasToString(playerCurrentAugmentAverageLevel[client], avgAugLvl, sizeof(avgAugLvl));
	if (iRPGMode > 0) {
		if (myCurrentTeam[client] == TEAM_SURVIVOR) {
			if (handicapLevel[client] > 0) Format(stringToStoreFormat, stringToStoreFormatSize, "{B}H.{G}%d {B}A.{G}%s {B}T.{G}%d {B}%s", handicapLevel[client], avgAugLvl, PlayerLevel[client], baseName[client]);
			else Format(stringToStoreFormat, stringToStoreFormatSize, "{B}A.{G}%s {B}T.{G}%d {B}%s", avgAugLvl, PlayerLevel[client], baseName[client]);
		}
		else if (myCurrentTeam[client] == TEAM_INFECTED) Format(stringToStoreFormat, stringToStoreFormatSize, "{R}T.{G}%d {R}%s", PlayerLevel[client], baseName[client]);
	}
}

public bool ChatTrigger(client, args, bool teamOnly) {

	if (!IsLegitimateClient(client)) return true;
	char[] sBuffer = new char[MAX_CHAT_LENGTH];
	char[] Message = new char[MAX_CHAT_LENGTH];
	char authString[64];
	GetClientAuthId(client, AuthId_Steam2, authString, sizeof(authString));
	GetCmdArg(1, sBuffer, MAX_CHAT_LENGTH);
	if (sBuffer[0] == '!' && IsOpenRPGMenu(sBuffer)) {
		CMD_OpenRPGMenu(client);
		return false;	// if we want to suppress the chat command
	}
	Format(LastSpoken[client], sizeof(LastSpoken[]), "%s", sBuffer);
	int clientTeam = myCurrentTeam[client];
	char avgAugLvl[10];
	AddCommasToString(playerCurrentAugmentAverageLevel[client], avgAugLvl, sizeof(avgAugLvl));
	if (iRPGMode > 0) {
		if (clientTeam == TEAM_SURVIVOR) {
			if (handicapLevel[client] > 0) Format(Message, MAX_CHAT_LENGTH, "{B}H.{G}%d {B}A.{G}%s {B}T.{G}%d {B}%s {N}-> {B}%s", handicapLevel[client], avgAugLvl, PlayerLevel[client], baseName[client], sBuffer);
			else Format(Message, MAX_CHAT_LENGTH, "{B}A.{G}%s {B}T.{G}%d {B}%s {N}-> {B}%s", avgAugLvl, PlayerLevel[client], baseName[client], sBuffer);
		}
		else if (clientTeam == TEAM_INFECTED) Format(Message, MAX_CHAT_LENGTH, "{R}T.{G}%d {R}%s {N}-> {R}%s", PlayerLevel[client], baseName[client], sBuffer);
		else if (clientTeam == TEAM_SPECTATOR) Format(Message, MAX_CHAT_LENGTH, "{GRA}T.{G}%d {GRA}%s {N}-> {GRA}%s", PlayerLevel[client], baseName[client], sBuffer);
		if (SkyLevel[client] >= 1) Format(Message, MAX_CHAT_LENGTH, "{N}Prestige{G}%d %s", SkyLevel[client], Message);
	}

	if (clientTeam == TEAM_SPECTATOR) Format(Message, MAX_CHAT_LENGTH, "{GRA}SPEC %s", Message);
	else {
		if (IsGhost(client)) Format(Message, MAX_CHAT_LENGTH, "{B}GHOST %s", Message);
		else if (!IsPlayerAlive(client)) Format(Message, MAX_CHAT_LENGTH, "{R}DEAD %s", Message);
		else if (IsIncapacitated(client)) Format(Message, MAX_CHAT_LENGTH, "{R}INCAP %s", Message);
	}
	if (teamOnly) {
		if (clientTeam == TEAM_SURVIVOR) Format(Message, MAX_CHAT_LENGTH, "{B}TEAM %s", Message);
		else if (clientTeam == TEAM_INFECTED) Format(Message, MAX_CHAT_LENGTH, "{R}TEAM %s", Message);
		for (int i = 1; i <= MaxClients; i++) {
			if (IsLegitimateClient(i) && myCurrentTeam[i] == clientTeam) Client_PrintToChat(i, true, Message);
		}
		if (clientTeam == TEAM_SPECTATOR) Format(Spectator_LastChatUser, sizeof(Spectator_LastChatUser), "%s", authString);
		else if (clientTeam == TEAM_SURVIVOR) Format(Survivor_LastChatUser, sizeof(Survivor_LastChatUser), "%s", authString);
		else if (clientTeam == TEAM_INFECTED) Format(Infected_LastChatUser, sizeof(Infected_LastChatUser), "%s", authString);
	}
	else {
		for (int i = 1; i <= MaxClients; i++) {
			if (IsLegitimateClient(i)) Client_PrintToChat(i, true, Message);
		}
	}
	return false;
}

stock GetTargetClient(client, char[] TargetName) {
	char Name[64];
	for (int i = 1; i <= MaxClients; i++) {
		if (IsLegitimateClient(i) && i != client && myCurrentTeam[i] == myCurrentTeam[client]) {
			GetClientName(i, Name, sizeof(Name));
			if (StrContains(Name, TargetName, false) != -1) return i;
		}
	}
	return -1;
}

stock TeamworkRewardNotification(client, target, float PointCost, char[] ItemName) {

	// Client is the user who purchased the item.
	// Target is the user who received it the item.
	// PointCost is the actual price the client paid - to determine their experience reward.
	if (client == target || b_IsFinaleActive) return;
	if (PointCost > fTeamworkExperience) PointCost = fTeamworkExperience;
	// there's no teamwork in 'i'
	int experienceReward	= RoundToCeil(PointCost * (fItemMultiplierTeam * (GetRandomInt(1, GetTalentStrength(client, "luck")) * fItemMultiplierLuck)));
	char ClientName[MAX_NAME_LENGTH];
	GetClientName(client, ClientName, sizeof(ClientName));
	char ItemName_s[64];
	Format(ItemName_s, sizeof(ItemName_s), "%T", ItemName, target);
	PrintToChat(target, "%T", "received item from teammate", target, green, ItemName_s, white, blue, ClientName);
	// {1}{2} {3}purchased and given to you by {4}{5}
	Format(ItemName_s, sizeof(ItemName_s), "%T", ItemName, client);
	GetClientName(target, ClientName, sizeof(ClientName));
	PrintToChat(client, "%T", "teamwork reward notification", client, green, ClientName, white, blue, ItemName_s, white, green, experienceReward);
	// {1}{2} {3}has received {4}{5}{6}: {7}{8}
	if (PlayerLevel[client] < iMaxLevel) {
		ExperienceLevel[client] += experienceReward;
		ExperienceOverall[client] += experienceReward;
		ConfirmExperienceAction(client);
		GetProficiencyData(client, 6, experienceReward);
	}
}

stock GetActiveWeaponSlot(client) {
	if (StrEqualAtPos(MyCurrentWeapon[client], "melee", 7) || StrEqualAtPos(MyCurrentWeapon[client], "pistol", 7) || StrEqualAtPos(MyCurrentWeapon[client], "chainsaw", 7)) return 1;
	return 0;
}

stock float GetMissingHealth(client) {

	return ((GetClientHealth(client) * 1.0) / (GetMaximumHealth(client) * 1.0));
}

stock SetSpeedMultiplierBase(attacker, float amount = 1.0) {

	if (myCurrentTeam[attacker] == TEAM_SURVIVOR) {
		if (FreezerInRange[attacker]) SetEntPropFloat(attacker, Prop_Send, "m_flLaggedMovementValue", 0.5);
		else SetEntPropFloat(attacker, Prop_Send, "m_flLaggedMovementValue", fBaseMovementSpeed);
	}
	else SetEntPropFloat(attacker, Prop_Send, "m_flLaggedMovementValue", amount);
}

stock PlayerSpawnAbilityTrigger(attacker) {

	if (IsLegitimateClientAlive(attacker)) {

		TankState[attacker] = TANKSTATE_TIRED;

		SetSpeedMultiplierBase(attacker);

		SpeedMultiplier[attacker] = SpeedMultiplierBase[attacker];		// defaulting the speed. It'll get modified in speed modifer spawn talents.
		
		if (myCurrentTeam[attacker] == TEAM_INFECTED) DefaultHealth[attacker] = GetClientHealth(attacker);
		else {

			if (!IsFakeClient(attacker)) DefaultHealth[attacker] = iSurvivorBaseHealth;
			else DefaultHealth[attacker] = iSurvivorBotBaseHealth;
		}
		b_IsImmune[attacker] = false;

		GetAbilityStrengthByTrigger(attacker, _, TRIGGER_a, _, 0);
		if (myCurrentTeam[attacker] != TEAM_SURVIVOR) {

			GiveMaximumHealth(attacker);
			//CreateMyHealthPool(attacker);		// when the infected spawns, if there are any human players, they'll automatically be added to their pools to ensure that bots don't one-shot them.
		}
	}
}

stock bool NoHumanInfected() {

	for (int i = 1; i <= MaxClients; i++) {

		if (IsClientInGame(i) && !IsFakeClient(i) && myCurrentTeam[i] == TEAM_INFECTED) return false;
	}

	return true;
}

stock InfectedBotSpawn(client) {

	//new Float:HealthBonus = 0.0;
	//new Float:SpeedBonus = 0.0;

	//if (IsLegitimateClient(client)) {

		/*

			In the new health adjustment system, it is based on the number of living players as well as their total level.
			Health bonus is multiplied by the number of total levels of players alive in the session.
		*/
		/*char InfectedHealthBonusType[64];
		Format(InfectedHealthBonusType, sizeof(InfectedHealthBonusType), "(%d) infected health bonus", FindZombieClass(client));
		HealthBonus = StringToFloat(GetConfigValue(InfectedHealthBonusType)) * (SurvivorLevels() * 1.0);*/

		//GetAbilityStrengthByTrigger(client, _, 'a', 0, 0);
	//}
}

stock bool CheckServerLevelRequirements(client) {

	if (iServerLevelRequirement > 0) {

		if (IsFakeClient(client)) {

			if (PlayerLevel[client] < iServerLevelRequirement) SetTotalExperienceByLevel(client, iServerLevelRequirement);
			return true;
		}
	}
	if (IsFakeClient(client)) return true;
	char LevelKickMessage[128];
	if (iServerLevelRequirement == -2 && !IsGroupMember[client]) {

		// some servers can allow only steamgroup members to join.
		// this prevents people who are trying to quick-match a vanilla game from joining the server if you activate it.
		b_IsLoading[client] = true;
		Format(LevelKickMessage, sizeof(LevelKickMessage), "Only steamgroup members can access this server.");
		KickClient(client, LevelKickMessage);
		return false;
	}
	if (PlayerLevel[client] < iServerLevelRequirement) {

		b_IsLoading[client] = true;	// prevent saving data on kick

		Format(LevelKickMessage, sizeof(LevelKickMessage), "Your level: %d\nSorry, you must be level %d to enter this server.", PlayerLevel[client], iServerLevelRequirement);
		KickClient(client, LevelKickMessage);
		return false;
	}
	else bIsSettingsCheck = true;
	//EnforceServerTalentMaximum(client);
	return true;
}

stock GetSpecialInfectedLimit(bool IsTankLimit = false) {

	int speciallimit = 0;
	int Dividend = iRatingSpecialsRequired;
	if (IsTankLimit) Dividend = iRatingTanksRequired;
	int maxRatingForTanks = iMaximumTanksPerPlayer * iRatingTanksRequired;
	for (int i = 1; i <= MaxClients; i++) {

		if (IsLegitimateClient(i) && myCurrentTeam[i] == TEAM_SURVIVOR) {

			if (Rating[i] < 0) Rating[i] = 0;
			speciallimit += (IsTankLimit && Rating[i] > maxRatingForTanks) ? maxRatingForTanks : Rating[i];
		}
	}
	if (iIgnoredRating > 0) {

		int ignoredRating = TotalSurvivors() * iIgnoredRating;
		if (ignoredRating > iIgnoredRatingMax) ignoredRating = iIgnoredRatingMax;

		speciallimit -= ignoredRating;
		if (speciallimit < 0) speciallimit = 0;
	}
	speciallimit = RoundToFloor(speciallimit * 1.0 / Dividend * 1.0);
	if (!IsTankLimit && iSpecialInfectedMinimum >= 0) {
		if (iSpecialInfectedMinimum > 0) speciallimit += iSpecialInfectedMinimum;
		else speciallimit += TotalSurvivors();
	}
	
	/*if (speciallimit < 1) {

		if (b_IsFinaleActive) speciallimit = 2;
		else speciallimit = 1;
	}*/
	return speciallimit;
}

stock RaidCommonBoost(bool bInfectedTalentStrength = false, bool IsEnsnareMultiplier = false) {

	int totalTeamRating = 0;
	int maxRatingForCommons = iMaximumCommonsPerPlayer * RaidLevMult;
	for (int i = 1; i <= MaxClients; i++) {
		if (!IsLegitimateClient(i) || myCurrentTeam[i] != TEAM_SURVIVOR || IsFakeClient(i)) continue;
		if (Rating[i] < 0) Rating[i] = 0;
		if (Rating[i] > maxRatingForCommons) totalTeamRating += maxRatingForCommons;
		else totalTeamRating += Rating[i];
	}
	int Multiplier = RaidLevMult;
	if (bInfectedTalentStrength) Multiplier = InfectedTalentLevel;
	else if (IsEnsnareMultiplier) Multiplier = iEnsnareLevelMultiplier;

	if (iIgnoredRating > 0) {

		int ignoredRating = TotalSurvivors() * iIgnoredRating;
		if (ignoredRating > iIgnoredRatingMax) ignoredRating = iIgnoredRatingMax;

		totalTeamRating -= ignoredRating;
		if (totalTeamRating < 0) totalTeamRating = 0;
	}

	if (Multiplier > 0) totalTeamRating /= Multiplier;
	if (totalTeamRating < 1) totalTeamRating = 0;
	return totalTeamRating;
}

stock HumanSurvivorLevels() {

	int fff = 0;
	for (int i = 1; i <= MaxClients; i++) {

		if (IsLegitimateClient(i) && !IsFakeClient(i) && myCurrentTeam[i] == TEAM_SURVIVOR) {

			if (Rating[i] < 0) Rating[i] = 0;
			fff += Rating[i];
		}
	}
	//if (StringToInt(GetConfigValue("infected bot level type?")) == 1) return f;	// player combined level
	//if (LivingHumanSurvivors() > 0) return f / LivingHumanSurvivors();
	if (iIgnoredRating > 0) {

		int ignoredRating = TotalSurvivors() * iIgnoredRating;
		if (ignoredRating > iIgnoredRatingMax) ignoredRating = iIgnoredRatingMax;

		fff -= ignoredRating;
		if (fff < 0) fff = 0;
	}
	return fff;
}

stock SurvivorLevels() {

	int fff = 0;
	for (int i = 1; i <= MaxClients; i++) {

		if (IsLegitimateClient(i) && myCurrentTeam[i] == TEAM_SURVIVOR) {

			if (Rating[i] < 0) Rating[i] = 0;
			fff += Rating[i];
		}
	}
	//if (StringToInt(GetConfigValue("infected bot level type?")) == 1) return f;	// player combined level
	//if (LivingHumanSurvivors() > 0) return f / LivingHumanSurvivors();
	if (iIgnoredRating > 0) {

		int ignoredRating = TotalSurvivors() * iIgnoredRating;
		if (ignoredRating > iIgnoredRatingMax) ignoredRating = iIgnoredRatingMax;

		fff -= ignoredRating;
		if (fff < 0) fff = 0;
	}
	return fff;
}

bool IsLegitimateClient(client) {

	if (client < 1 || client > MaxClients || !IsClientConnected(client) || !IsClientInGame(client)) return false;
	return true;
}

stock bool IsLegitimateClientAlive(client) {

	if (IsLegitimateClient(client) && IsPlayerAlive(client)) return true;
	return false;
}

stock RaidInfectedBotLimit() {

	/*new count = LivingHumanSurvivors() + 1;
	new CurrInfectedLevel = SurvivorLevels();
	new RaidLevelRequirement = RaidLevMult;
	while (CurrInfectedLevel >= RaidLevelRequirement) {

		CurrInfectedLevel -= RaidLevelRequirement;
		count++;
	}
	new HumanInGame = HumanPlayersInGame();
	if (HumanInGame > 4) count = HumanInGame;*/

	bIsSettingsCheck = true;
	int count = GetSpecialInfectedLimit();

	ReadyUp_NtvHandicapChanged(count);
}

stock RefreshSurvivor(client, bool IsUnhook = false) {
	if (IsLegitimateClientAlive(client) && myCurrentTeam[client] == TEAM_SURVIVOR) {
		iCurrentIncapCount[client] = 0;
		SetEntProp(client, Prop_Send, "m_currentReviveCount", 0);
		StopSound(client, SNDCHAN_AUTO, "player/heartbeatloop.wav");
		SetEntProp(client, Prop_Send, "m_bIsOnThirdStrike", 0);
		//if (IsFakeClient(client)) {

			//SetMaximumHealth(client);
			//Rating[client] = 1;
			//PlayerLevel[client] = iPlayerStartingLevel;
		//}
	}
}

public Action Timer_CheckForExperienceDebt(Handle timer, any client) {

	if (!IsLegitimateClient(client)) return Plugin_Stop;
	return Plugin_Stop;
}

stock DeleteMeFromExistence(client) {

	int pos = -1;

	for (int i = 1; i <= MaxClients; i++) {

		if (!IsLegitimateClient(i)) continue;
		pos = FindListPositionByEntity(client, InfectedHealth[i]);
		if (pos >= 0) RemoveFromArray(InfectedHealth[i], pos);
	}
	ForcePlayerSuicide(client);
}

public ForceIncapSurvivor(client, attacker, healthvalue) {
	ImmuneToAllDamage[client] = true;
	CreateTimer(2.0, Timer_RemoveDamageImmunity, client, TIMER_FLAG_NO_MAPCHANGE);

	ReadyUp_NtvStatistics(client, 3, 1);
	ReadyUp_NtvStatistics(attacker, 4, 1);

	SetEntProp(client, Prop_Send, "m_isIncapacitated", 1);
	SetEntPropFloat(client, Prop_Send, "m_healthBufferTime", GetGameTime());
	iThreatLevel[client] /= 2;
	bIsGiveIncapHealth[client] = true;
	SetMaximumHealth(client);
	b_HasDeathLocation[client] = false;
	if (attacker != 0 && IsLegitimateClient(attacker)) GetAbilityStrengthByTrigger(client, attacker, TRIGGER_N, _, healthvalue);
	else GetAbilityStrengthByTrigger(client, attacker, TRIGGER_n, _, healthvalue);
	RoundIncaps[client]++;
	int infectedAttacker = L4D2_GetInfectedAttacker(client);

	if (infectedAttacker == -1) GetAbilityStrengthByTrigger(client, attacker, TRIGGER_n, _, healthvalue);
	else {
		//CreateTimer(1.0, Timer_IsIncapacitated, victim, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
		GetAbilityStrengthByTrigger(client, attacker, TRIGGER_N, _, healthvalue);
		if (infectedAttacker == attacker) GetAbilityStrengthByTrigger(attacker, client, TRIGGER_m, _, healthvalue);
		else GetAbilityStrengthByTrigger(client, infectedAttacker, TRIGGER_m, _, healthvalue);
	}
}

	/*
	// ---------------------------
	//  Hit Group standards
	// ---------------------------
	#define HITGROUP_GENERIC     0
	#define HITGROUP_HEAD        1
	#define HITGROUP_CHEST       2
	#define HITGROUP_STOMACH     3
	#define HITGROUP_LEFTARM     4
	#define HITGROUP_RIGHTARM    5
	#define HITGROUP_LEFTLEG     6
	#define HITGROUP_RIGHTLEG    7
	#define HITGROUP_GEAR        10            // alerts NPC, but doesn't do damage or bleed (1/100th damage)
	*/

stock GetHitgroupType(int hitgroup) {
	if (hitgroup >= 4 && hitgroup <= 7) return HITGROUP_LIMB;	// limb
	if (hitgroup == 1) return HITGROUP_HEAD;					// headshot
	return HITGROUP_OTHER;										// not a limb
}

// stock bool CheckIfLimbDamage(attacker, victim, Handle event, damage) {
// 	if (myCurrentTeam[attacker] == TEAM_SURVIVOR) {
// 		if (!b_IsHooked[attacker]) ChangeHook(attacker, true);
// 		int hitgroup = GetEventInt(event, "hitgroup");
// 		if (hitgroup >= 4 && hitgroup <= 7) {
// 			GetAbilityStrengthByTrigger(attacker, victim, "limbshot", _, damage, _, _, _, _, _, _, hitgroup);
// 			return true;
// 		}
// 	}
// 	return false;
// }

void CallTriggerByHitgroup(int attacker, int victim, int hitgroup, int ammotype, int damage) {
	int type = GetHitgroupType(hitgroup);
	if (type == HITGROUP_LIMB) GetAbilityStrengthByTrigger(attacker, victim, TRIGGER_limbshot, _, damage, _, _, _, _, _, _, hitgroup, _, ammotype);
	if (type == HITGROUP_HEAD) {
		GetAbilityStrengthByTrigger(attacker, victim, TRIGGER_headshot, _, damage, _, _, _, _, _, _, hitgroup, _, ammotype);
		if (IsCommonInfected(victim) && !IsSpecialCommon(victim)) AddCommonInfectedDamage(attacker, victim, GetCommonBaseHealth(attacker));	// if someone shoots a common infected in the head, we want to auto-kill it.
	}
}

/*
	GetAbilityStrengthByTrigger(activator, target = 0, String:AbilityT[], zombieclass = 0, damagevalue = 0,
										bool:IsOverdriveStacks = false, bool:IsCleanse = false, String:ResultEffects[] = "none", ResultType = 0,
										bool:bDontActuallyActivate = false, typeOfValuesToRetrieve = 1, hitgroup = -1)
*/

// stock bool CheckIfHeadshot(attacker, victim, Handle event, damage) {
// 	if (myCurrentTeam[attacker] == TEAM_SURVIVOR) {
// 		if (!b_IsHooked[attacker]) ChangeHook(attacker, true);
// 		int hitgroup = GetEventInt(event, "hitgroup");
// 		if (hitgroup == 1) {
// 			ConsecutiveHeadshots[attacker]++;
// 			GetAbilityStrengthByTrigger(attacker, victim, "headshot", _, damage, _, _, _, _, _, _, hitgroup);
// 			if (IsCommonInfected(victim) && !IsSpecialCommon(victim)) {
// 				AddCommonInfectedDamage(attacker, victim, GetCommonBaseHealth(attacker));	// if someone shoots a common infected in the head, we want to auto-kill it.
// 			}
// 			LastHitWasHeadshot[attacker] = true;
// 			return true;
// 		}
// 		ConsecutiveHeadshots[attacker] = 0;
// 		LastHitWasHeadshot[attacker] = false;
// 	}
// 	return false;
// }

stock bool EquipBackpack(client) {

	if (eBackpack[client] > 0 && IsValidEntity(eBackpack[client])) {

		AcceptEntityInput(eBackpack[client], "Kill");
		eBackpack[client] = 0;
	}

	if (eBackpack[client] > 0 && IsValidEntity(eBackpack[client]) || !IsLegitimateClientAlive(client)) return false;	// backpack is already created.
	float Origin[3];

	int entity = CreateEntityByName("prop_dynamic_override");

	GetClientAbsOrigin(client, Origin);

	char text[64];
	Format(text, sizeof(text), "%d", client);
	DispatchKeyValue(entity, "model", sBackpackModel);
	//DispatchKeyValue(entity, "parentname", text);
	DispatchSpawn(entity);

	SetVariantString("!activator");
	AcceptEntityInput(entity, "SetParent", client);
	SetVariantString("spine");
	AcceptEntityInput(entity, "SetParentAttachment");

	// Lux
	AcceptEntityInput(entity, "DisableCollision");
	SetEntProp(entity, Prop_Send, "m_noGhostCollision", 1, 1);
	SetEntProp(entity, Prop_Data, "m_CollisionGroup", 0x0004);
	float dFault[3];
	SetEntPropVector(entity, Prop_Send, "m_vecMins", dFault);
	SetEntPropVector(entity, Prop_Send, "m_vecMaxs", dFault);
	// Lux

	//TeleportEntity(entity, g_vPos[index], g_vAng[index], NULL_VECTOR);
	SetEntProp(entity, Prop_Data, "m_iEFlags", 0);


	Origin[0] += 10.0;

	TeleportEntity(entity, Origin, NULL_VECTOR, NULL_VECTOR);
	eBackpack[client] = entity;

	return true;
}

stock bool GetClientStance(client, float fChaseTime = 20.0) {

	//if (stance == ClientActiveStance[client]) return true;
	/*if (bChangeStance) {

		ClientActiveStance[client] = stance;

		if (stance == 1) {

			new entity = CreateEntityByName("info_goal_infected_chase");
			if (entity > 0)
			{
				iChaseEnt[client] = EntIndexToEntRef(entity);

				DispatchSpawn(entity);
				new Float:vPos[3];
				GetClientAbsOrigin(client, vPos);
				vPos[2] += 20.0;
				TeleportEntity(entity, vPos, NULL_VECTOR, NULL_VECTOR);

				SetVariantString("!activator");
				AcceptEntityInput(entity, "SetParent", client);

				char temp[32];
				Format(temp, sizeof temp, "OnUser4 !self:Kill::300.0:-1");
				SetVariantString(temp);
				AcceptEntityInput(entity, "AddOutput");
				AcceptEntityInput(entity, "FireUser4");

				//iChaseEnt[client] = entity;
			}
		}
		else {

			if(iChaseEnt[client] && EntRefToEntIndex(iChaseEnt[client]) != INVALID_ENT_REFERENCE) AcceptEntityInput(iChaseEnt[client], "Kill");
			iChaseEnt[client] = -1;
		}
		return true;
	}*/
	if (ClientActiveStance[client] == 1) return false;

	int entity = CreateEntityByName("info_goal_infected_chase");
	if (entity > 0) {
		
		iChaseEnt[client] = entity;//EntIndexToEntRef(entity);

		DispatchSpawn(entity);
		float vPos[3];
		GetClientAbsOrigin(client, vPos);
		vPos[2] += 20.0;
		TeleportEntity(entity, vPos, NULL_VECTOR, NULL_VECTOR);

		SetVariantString("!activator");
		AcceptEntityInput(entity, "SetParent", client);

		char temp[32];
		Format(temp, sizeof temp, "OnUser4 !self:Kill::%f:-1", fChaseTime);
		SetVariantString(temp);
		AcceptEntityInput(entity, "AddOutput");
		AcceptEntityInput(entity, "FireUser4");

		ClientActiveStance[client] = 1;
		CreateTimer(fChaseTime, Timer_ForcedThreat, client, TIMER_FLAG_NO_MAPCHANGE);

		iThreatLevel[client] = iTopThreat + 1;

		return true;
	}
	return false;
}

stock bool IsAllSurvivorsDead() {

	for (int i = 1; i <= MaxClients; i++) {

		if (IsLegitimateClientAlive(i) && myCurrentTeam[i] == TEAM_SURVIVOR) return false;
	}
	return true;
}

stock GiveAdrenaline(client, bool Remove=false) {

	if (Remove) SetEntProp(client, Prop_Send, "m_bAdrenalineActive", 0);
	else if (!HasAdrenaline(client)) SetEntProp(client, Prop_Send, "m_bAdrenalineActive", 1);
}

stock bool HasAdrenaline(client) {

	if (IsClientInRangeSpecialAmmo(client, "a") > 0.0) return true;
	return (GetEntProp(client, Prop_Send, "m_bAdrenalineActive") == 1);
}

/*stock bool:IsDualWield(client) {

	return bool:GetEntProp(client, Prop_Send, "m_isDualWielding");
}*/

stock bool IsLedged(client) {

	return (GetEntProp(client, Prop_Send, "m_isHangingFromLedge") == 1);
}

stock bool FallingFromLedge(client) {

	return (GetEntProp(client, Prop_Send, "m_isFallingFromLedge") == 1);
}

void SetAdrenalineState(int client, float time = 10.0) {

	if (!HasAdrenaline(client)) SDKCall(g_hEffectAdrenaline, client, time);
}

int GetClientTotalHealth(int client) {

	int SolidHealth			= GetClientHealth(client);
	float TempHealth	= GetEntPropFloat(client, Prop_Send, "m_healthBuffer");
	//if (IsIncapacitated(client)) TempHealth = 0.0;

	if (!IsIncapacitated(client)) return RoundToCeil(SolidHealth + TempHealth);
	else return RoundToCeil(TempHealth);
}

void SetClientTotalHealth(int attacker = -1, int client, int damage, bool IsSetHealthInstead = false) {
	if (ImmuneToAllDamage[client] || bIsGiveIncapHealth[client]) return;
	float fHealthBuffer = 0.0;
	int realDamage = 0;

	if (IsSetHealthInstead) {

		SetMaximumHealth(client);
		SetEntityHealth(client, damage);
		SetEntPropFloat(client, Prop_Send, "m_healthBuffer", damage * 1.0);
		SetEntPropFloat(client, Prop_Send, "m_healthBufferTime", GetGameTime());
		return;
	}
	if (bIsSurvivorFatigue[client]) {
		int damagePenalty = RoundToCeil(damage * fFatigueDamageTakenPenalty);
		damage += damagePenalty;
	}
	if (fEnrageDamageIncreaseCurrent > 0.0) {
		int enrageDamagePenalty = RoundToCeil(damage * fEnrageDamageIncreaseCurrent);
		damage += enrageDamagePenalty;
	}

	int attackerType =	(IsLegitimateClient(attacker) && myCurrentTeam[attacker] == TEAM_INFECTED) ? 0 :
						(IsWitch(attacker)) ? 1 :
						(IsSpecialCommon(attacker)) ? 2 :
						(IsCommonInfected(attacker)) ? 3 : -1;
	if (attackerType >= 0) {
		int damagePos = (attackerType == 0) ? FindListPositionByEntity(attacker, damageOfSpecialInfected) :
						(attackerType == 1) ? FindListPositionByEntity(attacker, damageOfWitch) :
						(attackerType == 2) ? FindListPositionByEntity(attacker, CommonAffixes) :
						(attackerType == 3) ? FindListPositionByEntity(attacker, damageOfCommonInfected) : -1;
		if (damagePos >= 0) {
			if (attackerType == 0) SetArrayCell(damageOfSpecialInfected, damagePos, GetArrayCell(damageOfSpecialInfected, damagePos, 1) + damage, 1);
			else if (attackerType == 1) SetArrayCell(damageOfWitch, damagePos, GetArrayCell(damageOfWitch, damagePos, 1) + damage, 1);
			else if (attackerType == 2) SetArrayCell(CommonAffixes, damagePos, GetArrayCell(CommonAffixes, damagePos, 2) + damage, 2);
			else if (attackerType == 3) SetArrayCell(damageOfCommonInfected, damagePos, GetArrayCell(damageOfCommonInfected, damagePos, 1) + damage, 1);
		}
	}

	if (IsLegitimateClient(attacker) && myCurrentTeam[attacker] != myCurrentTeam[client]) lastHealthDamage[client][attacker] = damage;

	if (myCurrentTeam[client] == TEAM_SURVIVOR) {
		ReadyUp_NtvStatistics(client, 7, damage);

		int tempDamageDealt = 0;
		fHealthBuffer = GetEntPropFloat(client, Prop_Send, "m_healthBuffer");
		if (fHealthBuffer > 0.0) {

			if (damage >= fHealthBuffer) {	// temporary health is always checked first.

				if (IsIncapacitated(client)) IncapacitateOrKill(client);	// kill
				else {

					SetEntPropFloat(client, Prop_Send, "m_healthBuffer", 0.0);
					SetEntPropFloat(client, Prop_Send, "m_healthBufferTime", GetGameTime());
					int rounded = RoundToFloor(fHealthBuffer);
					damage -= rounded;
					tempDamageDealt = rounded;
				}
			}
			else {
				tempDamageDealt = damage;
				fHealthBuffer -= damage;
				SetEntityHealth(client, RoundToCeil(fHealthBuffer));
				SetEntPropFloat(client, Prop_Send, "m_healthBuffer", fHealthBuffer);
				SetEntPropFloat(client, Prop_Send, "m_healthBufferTime", GetGameTime());
				damage = 0;
			}
		}
		if (IsPlayerAlive(client)) {
			realDamage = GetClientTotalHealth(client);
			if (damage >= realDamage) IncapacitateOrKill(client);	// hint: they won't be killed.
			else if (!IsIncapacitated(client)) {
				realDamage = damage;
				SetEntityHealth(client, GetClientHealth(client) - damage);
			}
			if (attacker != client) SetArrayCell(playerContributionTracker[client], CONTRIBUTION_TRACKER_TANKING, GetArrayCell(playerContributionTracker[client], CONTRIBUTION_TRACKER_TANKING) + realDamage + tempDamageDealt);
		}
	}
	else {
		ReadyUp_NtvStatistics(client, 8, damage);
		if (damage >= GetClientHealth(client)) {
			CalculateInfectedDamageAward(client, attacker);
		}
		else SetEntityHealth(client, GetClientHealth(client) - damage);
	}
}

stock RestoreClientTotalHealth(client, damage) {

	int SolidHealth			= GetClientHealth(client);
	float TempHealth	= 0.0;
	if (myCurrentTeam[client] == TEAM_SURVIVOR) TempHealth = GetEntPropFloat(client, Prop_Send, "m_healthBuffer");
	if (RoundToFloor(TempHealth) > 0) {

		SetEntPropFloat(client, Prop_Send, "m_healthBuffer", TempHealth + damage);
		SetEntPropFloat(client, Prop_Send, "m_healthBufferTime", GetGameTime() * 1.0);
	}
	else SetEntityHealth(client, SolidHealth + damage);
}

stock bool SetTempHealth(client, targetclient, float TemporaryHealth=30.0, bool IsRevive=false, bool IsInNeedOfPickup=false) {

	if (!IsLegitimateClientAlive(targetclient)) return false;
	if (IsRevive) {
		if (IsInNeedOfPickup) ReviveDownedSurvivor(targetclient, client);
		// When a player revives someone (or is revived) we call the SetTempHealth function and here
		// It simply calls itself 
		GetAbilityStrengthByTrigger(targetclient, client, TRIGGER_R, _, 0);
		GetAbilityStrengthByTrigger(client, targetclient, TRIGGER_r, _, 0);
		//GiveMaximumHealth(targetclient);
	}
	else {

		SetEntPropFloat(targetclient, Prop_Send, "m_healthBuffer", TemporaryHealth);
		SetEntPropFloat(targetclient, Prop_Send, "m_healthBufferTime", GetGameTime());
	}
	return true;
}

stock ModifyHealth(client){
	if (!IsLegitimateClientAlive(client)) return;
	SetMaximumHealth(client);
}

stock void ReviveDownedSurvivor(client, int activator = 0) {
	SetEntProp(client, Prop_Send, "m_isIncapacitated", 0);
	iCurrentIncapCount[client]++;
	if (iCurrentIncapCount[client] >= iMaxIncap) SetEntProp(client, Prop_Send, "m_bIsOnThirdStrike", 1);
	int reviveOwner = GetEntPropEnt(client, Prop_Send, "m_reviveOwner");
	if (IsLegitimateClientAlive(reviveOwner)) {
		SetEntPropEnt(reviveOwner, Prop_Send, "m_reviveTarget", -1);
		SetEntityMoveType(reviveOwner, MOVETYPE_WALK);
	}
	SetEntPropEnt(client, Prop_Send, "m_reviveOwner", -1);
	SetEntityMoveType(client, MOVETYPE_WALK);
	SetEntityHealth(client, RoundToCeil(GetMaximumHealth(client) * fHealthSurvivorRevive));
	if (client != activator) GetAbilityStrengthByTrigger(client, activator, TRIGGER_R, _, 0);
	if (IsLegitimateClient(activator)) GetAbilityStrengthByTrigger(activator, client, TRIGGER_r, _, 0);
}

stock bool IsBeingRevived(client) {

	int target = GetEntPropEnt(client, Prop_Send, "m_reviveOwner");
	if (IsLegitimateClientAlive(target)) return true;
	return false;
}

stock ReleasePlayer(client) {
	int attacker = L4D2_GetInfectedAttacker(client);
	if (attacker > 0) {
		float clientPos[3];
		GetClientAbsOrigin(client, clientPos);
		L4D_StaggerPlayer(client, attacker, clientPos);
		//CalculateInfectedDamageAward(attacker, client);
		return attacker;
	}
	return -1;
}

stock HealPlayer(client, activator, float f_TalentStrength, ability, bool IsStrength = false) {	// must heal for abilities that instant-heal
	if (!IsLegitimateClient(client) || !IsPlayerAlive(client) || bIsGiveIncapHealth[client]) return 0;
	bool bIsIncapacitated = IsIncapacitated(client);
	// if (bIsIncapacitated && bHasWeakness[client]) return 0;
	int MyMaximumHealth = GetMaximumHealth(client);
	int PlayerHealth = GetClientHealth(client);
	/*if (PlayerHealth >= MyMaximumHealth && !IsIncapacitated(client)) {

		SetMaximumHealth(client);
		return 0;
	}*/
	if (L4D2_GetInfectedAttacker(client) != -1) return 0;
	float TalentStrength = GetAbilityMultiplier(activator, "E");
	if (TalentStrength == -1.0) TalentStrength = 0.0;
	TalentStrength = (TalentStrength > 0.0) ? f_TalentStrength + (TalentStrength * f_TalentStrength) : f_TalentStrength;
	//if (!IsIncapacitated(client)) PlayerHealth = GetClientHealth(client) * 1.0;
	float PlayerHealth_Temp = GetEntPropFloat(client, Prop_Send, "m_healthBuffer");
	int HealAmount = (TalentStrength < 1.0 || !IsStrength) ? RoundToCeil(GetMaximumHealth(client) * TalentStrength) : RoundToCeil(TalentStrength);
	if (HealAmount < 1) return 0;
	// if (TalentStrength == 1.0) {
	// 	SetEntPropFloat(client, Prop_Send, "m_healthBuffer", 0.0);
	// 	SetEntPropFloat(client, Prop_Send, "m_healthBufferTime", GetGameTime());
	// 	GiveMaximumHealth(client);
	// 	return HealAmount;
	// }
	HealAmount = (PlayerHealth + HealAmount < MyMaximumHealth) ? HealAmount : MyMaximumHealth - PlayerHealth;
	int NewHealth = PlayerHealth + HealAmount;
	if (bIsIncapacitated) {
		if (NewHealth < MyMaximumHealth) {
			// Incap health can't exceed actual player health - or they get instantly ressed.
			// that's wrong and i'll fix it, later. noted.
			SetEntityHealth(client, NewHealth);
			SetEntPropFloat(client, Prop_Send, "m_healthBuffer", NewHealth * 1.0);
			SetEntPropFloat(client, Prop_Send, "m_healthBufferTime", GetGameTime());
		}
		// We auto-revive any survivor who heals over their maximum incap health.
		// We also give them a default health on top of the overheal, to help them maybe not get knocked again, immediately.
		// You don't die if you get incapped too many times, but it would be a pretty annoying game play loop.
		else {
		//if (!IsBeingRevived(client)) {
			if (!IsLedged(client)) ReviveDownedSurvivor(client);
		}
		/*else {
			SetEntityHealth(client, MyMaximumHealth);
			SetEntPropFloat(client, Prop_Send, "m_healthBuffer", MyMaximumHealth * 1.0);
			SetEntPropFloat(client, Prop_Send, "m_healthBufferTime", GetGameTime());
		}*/
	}
	else {

		if (RoundToCeil(PlayerHealth + PlayerHealth_Temp + HealAmount) >= MyMaximumHealth) {

			int TempDiff = MyMaximumHealth - (PlayerHealth + HealAmount);

			if (TempDiff > 0) {

				HealAmount = MyMaximumHealth - RoundToFloor(PlayerHealth + PlayerHealth_Temp);

				SetEntPropFloat(client, Prop_Send, "m_healthBuffer", 0.0);
				SetEntPropFloat(client, Prop_Send, "m_healthBufferTime", GetGameTime());
				GiveMaximumHealth(client);
			}
			else {

				SetEntityHealth(client, PlayerHealth + HealAmount);
				SetEntPropFloat(client, Prop_Send, "m_healthBuffer", TempDiff * 1.0);
				SetEntPropFloat(client, Prop_Send, "m_healthBufferTime", GetGameTime());
			}
		}
		else {

			SetEntityHealth(client, PlayerHealth + HealAmount);
			if (PlayerHealth_Temp > 0.0) {
				SetEntPropFloat(client, Prop_Send, "m_healthBuffer", PlayerHealth_Temp);
				SetEntPropFloat(client, Prop_Send, "m_healthBufferTime", GetGameTime());
			}
		}
	}
	//if (HealAmount > MyMaximumHealth - PlayerHealth) HealAmount = MyMaximumHealth - PlayerHealth;
	if (HealAmount > 0) {
		AwardExperience(activator, 1, HealAmount);
		SetArrayCell(playerContributionTracker[activator], CONTRIBUTION_TRACKER_HEALING, GetArrayCell(playerContributionTracker[activator], CONTRIBUTION_TRACKER_HEALING) + HealAmount);
		if (IsLegitimateClientAlive(activator)) {
			//if (!dontFireTriggers) {
			if (activator != client) {
				GetProficiencyData(client, 6, HealAmount);
				AddContributionToEngagedEnemiesOfAlly(activator, client, CONTRIBUTION_AWARD_HEALING, HealAmount);
				//GetAbilityStrengthByTrigger(activator, client, "healally", _, HealAmount);
				GetAbilityStrengthByTrigger(client, activator, TRIGGER_wasHealed, _, HealAmount);
			}
			else GetAbilityStrengthByTrigger(activator, client, TRIGGER_healself, _, HealAmount);
			//}
			float TheAbilityMultiplier = GetAbilityMultiplier(activator, "t");
			if (TheAbilityMultiplier != -1.0) {

				TheAbilityMultiplier *= (HealAmount * 1.0);
				iThreatLevel[activator] += (HealAmount - RoundToFloor(TheAbilityMultiplier));
			}
			else {

				iThreatLevel[activator] += HealAmount;
			}
		}
		// friendly fire module is no longer used - depricated //if (ability == 'T') ReadyUp_NtvFriendlyFire(activator, client, 0 - HealAmount, GetClientHealth(client), 1, 0);	// we "subtract" negative values from health.
	}
	//PrintToChat(client, "heal amount: %d", HealAmount);
	return HealAmount;		// to prevent cartel being awarded for overheal.
}

stock EnableHardcoreMode(client, bool Disable=false) {

	if (!Disable) {
	
		SetEntityRenderMode(client, RENDER_TRANSCOLOR);
		SetEntityRenderColor(client, 255, 0, 0, 255);
		SetEntProp(client, Prop_Send, "m_bIsOnThirdStrike", 1);
		EmitSoundToClient(client, "player/heartbeatloop.wav");
	}
	else {

		SetEntityRenderMode(client, RENDER_NORMAL);
		SetEntityRenderColor(client, 255, 255, 255, 255);
		StopSound(client, SNDCHAN_AUTO, "player/heartbeatloop.wav");
	}
}

/*void ScenarioEnd(int client, const char[] s = "scenario_end") {
	int iFlags = GetCommandFlags(s);
	if (IsFakeClient(client)) {
        SetCommandFlags(s, iFlags & ~FCVAR_CHEAT);
        FakeClientCommand(client, "%s", s);
        SetCommandFlags(s, iFlags);
    }
	else {
        int uFlags = GetUserFlagBits(client);
        SetUserFlagBits(client, ADMFLAG_ROOT);
        SetCommandFlags(s, iFlags & ~FCVAR_CHEAT);
        FakeClientCommand(client, "%s", s);
        SetCommandFlags(s, iFlags);
        SetUserFlagBits(client, uFlags);
    }
}*/

void ExecCheatCommand(int client = 0, const char[] command, const char[] parameters = "") {
	if (StrEqual(parameters, "ammo")) {
		// we handle refilling ammo differently since we use custom values for reserve amount.
		//GetWeaponResult(client, 5);
		GetWeaponResult(client, 5, maximumReserves[client]);
		return;
	}
	int iFlags = GetCommandFlags(command);
	SetCommandFlags(command, iFlags & ~FCVAR_CHEAT);
	if(client < 1) ServerCommand("%s %s",command,parameters);
	else FakeClientCommand(client,"%s %s",command,parameters);
	SetCommandFlags(command, iFlags);
}

stock bool IsClientActual(client) {
	if (client < 1 || client > MaxClients || !IsClientConnected(client)) return false;
	return true;
}

stock bool IsClientBot(client) {
	if (!IsClientActual(client)) return false;
	if (IsFakeClient(client)) return true;
	return false;
}

stock bool IsClientHuman(client) {
	if (IsClientActual(client) && IsClientInGame(client) && !IsFakeClient(client)) return true;
	return false;
}

stock bool IsGhost(client) {
	return bool:GetEntProp(client, Prop_Send, "m_isGhost", 1);
}

stock bool HasCommandAccessEx(client, char[] permissions) {
	if (!IsClientActual(client)) return false;
	int flags = GetUserFlagBits(client);
	int cflags = ReadFlagString(permissions);
	if (flags & cflags) return true;
	return false;
}

stock int ValidSurvivors() {
	int count = 0;
	for (int i = 1; i <= MaxClients; i++) {
		if (IsClientInGame(i) && !IsFakeClient(i) && myCurrentTeam[i] == TEAM_SURVIVOR && IsPlayerAlive(i)) count++;
	}
	return count;
}

// targetstate = 0 (ignore) 1 (ensnared) 2 (incapacitated) 3 (dead)
void GetClientsInRangeByState(int client, float range, int incappedAllies, int ensnaredAllies, int healthyAllies) {
	if (range <= 0.0) return;
	int team = myCurrentTeam[client];
	float cpos[3];
	incappedAllies = 0;
	ensnaredAllies = 0;
	healthyAllies = 0;
	GetClientAbsOrigin(client, cpos);
	for (int i = 1; i <= MaxClients; i++) {
		if (!IsLegitimateClient(i) || i == client || !IsPlayerAlive(i)) continue;
		if (myCurrentTeam[i] != team) continue;

		float tpos[3];
		GetClientAbsOrigin(i, tpos);
		if (GetVectorDistance(cpos, tpos) > range) continue;

		int hasEnsnarer = L4D2_GetInfectedAttacker(i);
		if (hasEnsnarer != -1) ensnaredAllies++;

		bool isIncap = IsIncapacitated(i);
		if (isIncap) incappedAllies++;

		if (!hasEnsnarer && !isIncap) healthyAllies++;
	}
}

stock int PlayersInVicinity(client, float range) {
	float pos[3];
	float cpos[3];
	int count = 0;
	GetClientAbsOrigin(client, cpos);
	for (int i = 1; i <= MaxClients; i++) {
		if (IsClientInGame(i) && !IsFakeClient(i) && myCurrentTeam[i] == myCurrentTeam[client] && i != client && IsPlayerAlive(i)) {
			GetClientAbsOrigin(i, pos);
			if (GetVectorDistance(cpos, pos) <= range) count++;
		}
	}
	return count;
}

stock bool PlayersOutOfRange(entity, float range) {
	float tPos[3];
	if (entity > 0 && IsValidEntity(entity)) {
		char CName[128];
		GetEntityClassname(entity, CName, sizeof(CName));
		if (StrEqual(CName, "prop_door_rotating_checkpoint", false)) {
			GetEntPropVector(entity, Prop_Send, "m_vecOrigin", tPos);
			float pPos[3];
			for (new i = 1; i <= MaxClients; i++) {
				if (!IsClientInGame(i) || IsFakeClient(i) || myCurrentTeam[i] != TEAM_SURVIVOR || !IsPlayerAlive(i)) continue;
				GetClientAbsOrigin(i, Float:pPos);
				if (GetVectorDistance(pPos, tPos) > range) return true;
			}
			return false;
		}
		else return false;
	}
	return true;
}

stock bool IsSurvival() {
	char GameType[128];
	GetConVarString(FindConVar("mp_gamemode"), GameType, 128);
	if (StrEqual(GameType, "survival")) return true;
	return false;
}

stock bool IsIncapacitated(client) {
	return (GetEntProp(client, Prop_Send, "m_isIncapacitated") == 1) ? true : false;
}

stock int thisAugmentArrayPos(int client, int val) {
	int size = GetArraySize(playerLootOnGround[client]);
	for (int i = 0; i < size; i++) {
		int dropOrder = GetArrayCell(playerLootOnGround[client], i, 9);
		if (dropOrder == val) return i;
	}
	return -1;	// should NEVER happen.
}