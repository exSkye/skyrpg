public Action:Timer_ZeroGravity(Handle:timer, any:client) {

	if (IsLegitimateClientAlive(client)) {

		ModifyGravity(client);
	}
	//ZeroGravityTimer[client] = INVALID_HANDLE;
	return Plugin_Stop;
}

public Action:Timer_ResetCrushImmunity(Handle:timer, any:client) {

	if (IsLegitimateClient(client)) bIsCrushCooldown[client] = false;
	return Plugin_Stop;
}

public Action:Timer_ResetBurnImmunity(Handle:timer, any:client) {

	if (IsLegitimateClient(client)) bIsBurnCooldown[client] = false;
	return Plugin_Stop;
}

public Action:Timer_HealImmunity(Handle:timer, any:client) {

	if (IsLegitimateClient(client)) {

		HealImmunity[client] = false;
	}
	return Plugin_Stop;
}

public Action:Timer_IsMeleeCooldown(Handle:timer, any:client) {

	if (IsLegitimateClient(client)) { bIsMeleeCooldown[client] = false; }
	return Plugin_Stop;
}

public Action:Timer_ResetShotgunCooldown(Handle:timer, any:client) {
	if (IsLegitimateClient(client)) shotgunCooldown[client] = false;
	return Plugin_Stop;
}

bool:VerifyMinimumRating(client, bool:setMinimumRating = false) {
	new minimumRating = RoundToCeil(BestRating[client] * fRatingFloor);
	if (setMinimumRating || Rating[client] < minimumRating) Rating[client] = minimumRating;
}

bool:AllowShotgunToTriggerNodes(client) {
	new bool:isshotgun = IsPlayerUsingShotgun(client);
	if (!isshotgun || isshotgun && !shotgunCooldown[client]) return true;
	return false;
}

stock CheckDifficulty() {

	decl String:Difficulty[64];
	GetConVarString(FindConVar("z_difficulty"), Difficulty, sizeof(Difficulty));
	if (!StrEqual(Difficulty, sServerDifficulty, false)) SetConVarString(FindConVar("z_difficulty"), sServerDifficulty);
}

stock GiveProfileItems(client) {

	if (GetArraySize(hWeaponList[client]) == 2) {
		decl String:text[64];
		GetArrayString(Handle:hWeaponList[client], 0, text, sizeof(text));
		QuickCommandAccessEx(client, text, _, true);

		GetArrayString(Handle:hWeaponList[client], 1, text, sizeof(text));
		QuickCommandAccessEx(client, text, _, true);
	}
	else {
		ResizeArray(hWeaponList[client], 2);
		QuickCommandAccessEx(client, defaultLoadoutWeaponPrimary, _, true);
		QuickCommandAccessEx(client, defaultLoadoutWeaponSecondary, _, true);
	}
	if (SkyLevel[client] > 0) CreateTimer(0.5, Timer_GiveLaserBeam, client, TIMER_FLAG_NO_MAPCHANGE);
}

public Action:Timer_GiveLaserBeam(Handle:timer, any:client) {

	if (IsLegitimateClientAlive(client)) {

		ExecCheatCommand(client, "upgrade_add", "LASER_SIGHT");
	}
	return Plugin_Stop;
}

/*public Action:Timer_DisplayHUD(Handle:timer) {

	if (!b_IsActiveRound) return Plugin_Stop;
	static iRotation = 0;
	for (new i = 1; i <= MaxClients; i++) {

		if (IsLegitimateClientAlive(i) && !IsFakeClient(i)) {

			if (GetClientTeam(i) == TEAM_SURVIVOR) {

				DisplayHUD(i, iRotation);
				if (bIsGiveProfileItems[i]) {

					bIsGiveProfileItems[i] = false;
					GiveProfileItems(i);
				}
			}
			else if (GetClientTeam(i) == TEAM_INFECTED) DisplayInfectedHUD(i, iRotation);
		}
	}
	if (iRotation != 1) iRotation = 1;
	else iRotation = 0;

	return Plugin_Continue;
}*/

public Action:Timer_CheckDifficulty(Handle:timer) {

	CheckDifficulty();
	return Plugin_Continue;
}

public Action:Timer_ShowHUD(Handle:timer, any:client) {
	if (!b_IsActiveRound || !IsLegitimateClient(client) || !bTimersRunning[client]) {
		return Plugin_Stop;
	}
	if (PlayerLevel[client] > iMaxLevel) SetTotalExperienceByLevel(client, iMaxLevel, true);
	TimePlayed[client]++;
	//if (TotalHumanSurvivors() < 1) RoundTime++;	// we don't count time towards enrage if there are no human survivors.
	static String:pct[10];
	Format(pct, sizeof(pct), "%");
	static ThisRoundTime = 0;
	ThisRoundTime = RPGRoundTime();
	new mymaxhealth = -1;
	new Float:healregenamount = 0.0;
	//decl String:targetSteamID[64];
	if (iShowAdvertToNonSteamgroupMembers == 1 && !IsGroupMember[client]) {
		IsGroupMemberTime[client]++;
		if (IsGroupMemberTime[client] % iJoinGroupAdvertisement == 0) {
			PrintToChat(client, "%T", "join group advertisement", client, GroupMemberBonus * 100.0, pct, orange, blue, orange, blue, orange, blue, green, orange);
		}
	}

	static playerTeam = 0;
	playerTeam = GetClientTeam(client);
	if (playerTeam == TEAM_SPECTATOR || (playerTeam == TEAM_SURVIVOR || !IsLegitimateClientAlive(client)) && !b_IsLoaded[client]) return Plugin_Continue;
	if (displayBuffOrDebuff[client] != 1) displayBuffOrDebuff[client] = 1;
	else displayBuffOrDebuff[client] = 0;
	if (!IsFakeClient(client)) DisplayHUD(client, displayBuffOrDebuff[client]);
	if (bIsGiveProfileItems[client]) {
		bIsGiveProfileItems[client] = false;
		GiveProfileItems(client);
	}
	if ((playerTeam == TEAM_SURVIVOR) && CurrentRPGMode >= 1) {
		healregenamount = 0.0;				
		mymaxhealth = GetMaximumHealth(client);
		if (ThisRoundTime < iEnrageTime && L4D2_GetInfectedAttacker(client) == -1) {
			healregenamount = GetAbilityStrengthByTrigger(client, _, "p", _, 0, _, _, "h");	// activator, target, trigger ability, effects, zombieclass, damage
			if (healregenamount > 0.0) HealPlayer(client, client, healregenamount, 'h', true);
		}
		ModifyHealth(client, GetAbilityStrengthByTrigger(client, client, "p", _, 0, _, _, "H"), 0.0);
		if (GetClientHealth(client) > mymaxhealth) SetEntityHealth(client, mymaxhealth);
	}
	if (playerTeam != TEAM_SPECTATOR) {
		GetAbilityStrengthByTrigger(client, client, "p");	// adding support for any type of passive.
	}
	RemoveStoreTime(client);
	LastPlayLength[client]++;
	if (ReadyUpGameMode != 3 && CurrentRPGMode >= 1 && ThisRoundTime >= iEnrageTime) {
		if (SurvivorEnrage[client][1] == 0.0) {
			EnrageBlind(client, 100);
			SurvivorEnrage[client][1] = 1.0;
		}
		else {
			SurvivorEnrage[client][1] = 0.0;
		}
	}
	/*for (new i = 1; i <= MaxClients; i++) {
		if (IsLegitimateClientAlive(i) && GetClientTeam(i) == TEAM_INFECTED && FindZombieClass(i) == ZOMBIECLASS_TANK) {
			if (IsClientInRangeSpecialAmmo(i, "W") == -2.0) IsDark = true;
			else IsDark = false;
			if (IsSpecialCommonInRange(i, 'w')) IsWeak = true;
			else IsWeak = false;
			if (IsWeak && IsDark) {
				ClearArray(Handle:TankState_Array[i]);
				SetEntityRenderMode(i, RENDER_TRANSCOLOR);
				SetEntityRenderColor(i, 255, 255, 255, 200);
			}
		}
	}*/

	return Plugin_Continue;
}

stock LedgedSurvivors() {

	new count = 0;
	for (new i = 1; i <= MaxClients; i++) {

		if (IsLegitimateClientAlive(i) && GetClientTeam(i) == TEAM_SURVIVOR && IsLedged(i)) count++;
	}
	return count;
}

stock bool:NoLivingHumanSurvivors() {
	for (new i = 1; i <= MaxClients; i++) {
		if (!IsLegitimateClient(i) || IsFakeClient(i) || GetClientTeam(i) != TEAM_SURVIVOR || !IsPlayerAlive(i)) continue;
		return false;
	}
	return true;
}

stock bool:NoHealthySurvivors(bool:bMustNotBeABot = false) {

	for (new i = 1; i <= MaxClients; i++) {
		if (!IsLegitimateClientAlive(i) || IsIncapacitated(i) || GetClientTeam(i) != TEAM_SURVIVOR) continue;
		if (bMustNotBeABot && IsFakeClient(i)) continue;
		return false;
	}
	return true;
}

stock HumanSurvivors() {

	new count = 0;
	for (new i = 1; i <= MaxClients; i++) {

		if (IsClientInGame(i) && !IsFakeClient(i) && GetClientTeam(i) == TEAM_SURVIVOR) count++;
	}
	return count;
}

public Action:Timer_TeleportRespawn(Handle:timer, any:client) {

	if (b_IsActiveRound && IsLegitimateClient(client)) {

		new target = MyRespawnTarget[client];

		if (target != client && IsLegitimateClientAlive(target)) {

			GetClientAbsOrigin(target, DeathLocation[target]);
			TeleportEntity(client, DeathLocation[target], NULL_VECTOR, NULL_VECTOR);
			MyRespawnTarget[client] = client;
		}
		else TeleportEntity(client, DeathLocation[client], NULL_VECTOR, NULL_VECTOR);
	}
	return Plugin_Stop;
}

public Action:Timer_GiveMaximumHealth(Handle:timer, any:client) {

	if (IsLegitimateClientAlive(client)) {

		GiveMaximumHealth(client);		// So instant heal doesn't put a player above their maximum health pool.
	}

	return Plugin_Stop;
}

public Action:Timer_DestroyCombustion(Handle:timer, any:entity)
{
	if (!IsValidEntity(entity)) return Plugin_Stop;
	AcceptEntityInput(entity, "Kill");
	return Plugin_Stop;
}

/*public Action:Timer_DestroyDiscoveryItem(Handle:timer, any:entity) {

	if (IsValidEntity(entity)) {

		new client				= FindAnyRandomClient();

		if (client == -1) return Plugin_Stop;

		decl String:EName[64];
		GetEntPropString(entity, Prop_Data, "m_iName", EName, sizeof(EName));
		if (StrEqual(EName, "slate") || IsStoreItem(client, EName) || IsTalentExists(EName)) {

			if (!AcceptEntityInput(entity, "Kill")) RemoveEdict(entity);
		}
	}

	return Plugin_Stop;
}*/

public Action:Timer_SlowPlayer(Handle:timer, any:client) {

	if (IsLegitimateClientAlive(client)) {

		SetEntPropFloat(client, Prop_Send, "m_flLaggedMovementValue", SpeedMultiplierBase[client]);
	}
	//SlowMultiplierTimer[client] = INVALID_HANDLE;
	return Plugin_Stop;
}

stock GetTimePlayed(client, String:s[], size) {
	new seconds = TimePlayed[client];
	new minutes = 0;
	new hours = 0;
	new days = 0;
	while (seconds >= 86400) {
		days++;
		seconds -= 86400;
	}
	while (seconds >= 3600) {
		hours++;
		seconds -= 3600;
	}
	while (seconds >= 60) {
		minutes++;
		seconds -= 60;
	}
	Format(s, size, "%d Days, %d Hours, %d Minutes, %d Second(s)", days, hours, minutes, seconds);
}

/*public Action:Timer_AwardSkyPoints(Handle:timer) {

	if (!b_IsActiveRound) return Plugin_Stop;

	for (new i = 1; i <= MaxClients; i++) {

		if (IsClientInGame(i) && !IsFakeClient(i) && GetClientTeam(i) != TEAM_SPECTATOR) {

			CheckSkyPointsAward(i);
		}
	}

	return Plugin_Continue;
}

stock CheckSkyPointsAward(client) {

	new SkyPointsAwardTime		=	GetConfigValueInt("sky points awarded _");
	new SkyPointsAwardValue		=	GetConfigValueInt("sky points time required?");
	new SkyPointsAwardAmount	=	GetConfigValueInt("sky points award amount?");

	new seconds					=	0;
	new minutes					=	0;
	new hours					=	0;
	new days					=	0;
	new oldminutes				=	0;
	new oldhours				=	0;
	new olddays					=	0;

	seconds				=	TimePlayed[client];
	while (seconds >= 86400) {

		olddays++;
		seconds -= 86400;
	}
	while (seconds >= 3600) {

		oldhours++;
		seconds -= 3600;
	}
	while (seconds >= 60) {

		oldminutes++;
		seconds -= 60;
	}

	TimePlayed[client]++;

	seconds = TimePlayed[client];

	while (seconds >= 86400) {

		days++;
		seconds -= 86400;
	}
	while (seconds >= 3600) {

		hours++;
		seconds -= 3600;
	}
	while (seconds >= 60) {

		minutes++;
		seconds -= 60;

	}
	if (SkyPointsAwardTime == 2 && days != olddays && days % SkyPointsAwardValue == 0) AwardSkyPoints(client, SkyPointsAwardAmount);
	if (SkyPointsAwardTime == 1 && hours != oldhours && hours % SkyPointsAwardValue == 0) AwardSkyPoints(client, SkyPointsAwardAmount);
	if (SkyPointsAwardTime == 0 && minutes != oldminutes && minutes % SkyPointsAwardValue == 0) AwardSkyPoints(client, SkyPointsAwardAmount);
}*/

/*public Action:Timer_SpeedIncrease(Handle:timer, any:client) {

	if (IsLegitimateClientAlive(client)) {

		SpeedIncrease(client);
	}
	//SpeedMultiplierTimer[client] = INVALID_HANDLE;
	return Plugin_Stop;
}*/

public Action:Timer_BlindPlayer(Handle:timer, any:client) {

	if (IsLegitimateClient(client)) BlindPlayer(client);
	return Plugin_Stop;
}

public Action:Timer_FrozenPlayer(Handle:timer, any:client) {

	if (IsLegitimateClient(client)) FrozenPlayer(client, _, 0);
	return Plugin_Stop;
}

stock Float:GetActiveZoomTime(client) {
	new listClient = 0;
	new Float:activeZoomTimeTime = 0.0;
	new Float:activeZoomTime = GetEngineTime();
	for (new i = 0; i < GetArraySize(zoomCheckList); i++) {
		listClient = GetArrayCell(Handle:zoomCheckList, i, 0);
		if (client != listClient) continue;
		activeZoomTimeTime = GetArrayCell(Handle:zoomCheckList, i, 1);
		activeZoomTime -= activeZoomTimeTime;
		return activeZoomTime;
	}
	return 0.0;
}

stock bool:isQuickscopeKill(client) {
	new listClient = 0;
	new Float:fClientHoldingFireTime = 0.0;
	new Float:killDelayAfterScope = GetEngineTime();
	for (new i = 0; i < GetArraySize(zoomCheckList); i++) {
		listClient = GetArrayCell(Handle:zoomCheckList, i, 0);
		if (client != listClient) continue;
		fClientHoldingFireTime = GetArrayCell(Handle:zoomCheckList, i, 1);
		killDelayAfterScope -= fClientHoldingFireTime;
		if (killDelayAfterScope <= fquickScopeTime) return true;
		return false;
	}
	return false;
}

stock zoomCheckToggle(client, bool:insert = false) {
	new listClient = 0;
	for (new i = 0; i < GetArraySize(zoomCheckList); i++) {
		listClient = GetArrayCell(Handle:zoomCheckList, i, 0);
		if (client != listClient) continue;
		if (insert) return;
		// The user is unscoping so we remove them from the array.
		RemoveFromArray(zoomCheckList, i);
	}
	if (insert) {
		// we don't even get here if the user is already in the list.
		new size = GetArraySize(zoomCheckList);
		ResizeArray(zoomCheckList, size + 1);
		SetArrayCell(zoomCheckList, size, client, 0);
		SetArrayCell(zoomCheckList, size, GetEngineTime(), 1);
	}
	return;
}

public Action:Timer_ZoomcheckDelayer(Handle:timer, any:client) {
	if (!IsLegitimateClient(client)) return Plugin_Stop;
	if (IsPlayerZoomed(client)) {
		// trigger nodes that fire when a player zooms in (like effects over time)
		zoomCheckToggle(client, true);
	}
	else zoomCheckToggle(client);
	ZoomcheckDelayer[client] = INVALID_HANDLE;
	return Plugin_Stop;
}

stock Float:GetHoldingFireTime(client) {
	new listClient = 0;
	new Float:fClientHoldingFireTime = 0.0;
	new Float:holdingFireTime = GetEngineTime();
	for (new i = 0; i < GetArraySize(holdingFireList); i++) {
		listClient = GetArrayCell(Handle:holdingFireList, i, 0);
		if (listClient != client) continue;
		fClientHoldingFireTime = GetArrayCell(Handle:holdingFireList, i, 1);
		holdingFireTime -= fClientHoldingFireTime;
		return holdingFireTime;
	}
	return 0.0;
}

stock holdingFireCheckToggle(client, bool:insert = false) {
	new listClient = 0;
	for (new i = 0; i < GetArraySize(holdingFireList); i++) {
		listClient = GetArrayCell(Handle:holdingFireList, i, 0);
		if (listClient != client) continue;
		if (insert) return;
		// The user is unscoping so we remove them from the array.
		RemoveFromArray(holdingFireList, i);
	}
	if (insert) {
		// we don't even get here if the user is already in the list.
		new size = GetArraySize(holdingFireList);
		ResizeArray(holdingFireList, size + 1);
		SetArrayCell(holdingFireList, size, client, 0);
		SetArrayCell(holdingFireList, size, GetEngineTime(), 1);
	}
	return;
}

/*public Action:Timer_HoldingFireDelayer(Handle:timer, any:client) {
	if (!IsLegitimateClient(client)) return Plugin_Stop;
	new weaponEntity = GetEntPropEnt(client, Prop_Data, "m_hActiveWeapon");
	new bulletsRemaining = 0;
	if (IsValidEntity(weaponEntity)) bulletsRemaining = GetEntProp(weaponEntity, Prop_Send, "m_iClip1");
	if (bulletsRemaining > 0 && GetEntProp(weaponEntity, Prop_Data, "m_bInReload") != 1 && L4D2_GetInfectedAttacker(client) == -1) {
		// trigger nodes that fire when a player zooms in (like effects over time)
		holdingFireCheckToggle(client, true);
	}
	else holdingFireCheckToggle(client);
	holdingFireDelayer[client] = INVALID_HANDLE;
	return Plugin_Stop;
}*/

public Action:Timer_Blinder(Handle:timer, any:client) {

	if (ISBLIND[client] == INVALID_HANDLE) return Plugin_Stop;

	if (!b_IsActiveRound || !IsLegitimateClient(client) || !IsSpecialCommonInRange(client, 'l')) {

		BlindPlayer(client);
		KillTimer(ISBLIND[client]);
		ISBLIND[client] = INVALID_HANDLE;
		//CloseHandle(ISBLIND[client]);
		return Plugin_Stop;
	}
	return Plugin_Continue;
}

public Action:Timer_Freezer(Handle:timer, any:client) {
	if (!b_IsActiveRound || !IsLegitimateClient(client) || !IsPlayerAlive(client) || !IsSpecialCommonInRange(client, 'r')) {
		/*

			If the client is scorched, they no longer freeze.
		*/
		//KillTimer(ISFROZEN[client]);
		ISFROZEN[client] = INVALID_HANDLE;
		FrozenPlayer(client, _, 0);
		return Plugin_Stop;
	}
	new Float:Velocity[3];
	SetEntityMoveType(client, MOVETYPE_WALK);
	Velocity[0]	=	GetEntPropFloat(client, Prop_Send, "m_vecVelocity[0]");
	Velocity[1]	=	GetEntPropFloat(client, Prop_Send, "m_vecVelocity[1]");
	Velocity[2]	=	GetEntPropFloat(client, Prop_Send, "m_vecVelocity[2]");
	Velocity[2] += 32.0;
	TeleportEntity(client, NULL_VECTOR, NULL_VECTOR, Velocity);
	SetEntityMoveType(client, MOVETYPE_NONE);
	return Plugin_Continue;
}

public ReadyUp_FwdChangeTeam(client, team) {

	if (IsLegitimateClient(client)) {

		if (team == TEAM_SURVIVOR) {

			ChangeHook(client, true);
			if (!b_IsLoading[client] && !b_IsLoaded[client]) OnClientLoaded(client);
		}
		else if (team != TEAM_SURVIVOR) {

			//LogToFile(LogPathDirectory, "%N is no longer a survivor, unhooking.", client);
			if (bIsInCombat[client]) {

				IncapacitateOrKill(client, _, _, true, false, true);
			}
			ChangeHook(client);
		}
	}
}

stock ChangeHook(client, bool:bHook = false) {

	b_IsHooked[client] = bHook;
	SDKUnhook(client, SDKHook_OnTakeDamage, OnTakeDamage);
	if (b_IsHooked[client]) SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);
}

/*public ReadyUp_FwdChangeTeam(client, team) {

	if (team != TEAM_SURVIVOR) {

		if (bIsInCombat[client]) {

			IncapacitateOrKill(client, _, _, true, false, true);
		}

		b_IsHooked[client] = false;
		SDKUnhook(client, SDKHook_OnTakeDamage, OnTakeDamage);
	}
	else if (team == TEAM_SURVIVOR && !b_IsHooked[client]) {

		b_IsHooked[client] = true;
		SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);
	}
}*/

public Action:Timer_DetectGroundTouch(Handle:timer, any:client) {

	if (IsClientHuman(client) && IsPlayerAlive(client)) {

		if (GetClientTeam(client) == TEAM_SURVIVOR && !(GetEntityFlags(client) & FL_ONGROUND) && b_IsJumping[client] && L4D2_GetInfectedAttacker(client) == -1 && !AnyTanksNearby(client)) return Plugin_Continue;
		b_IsJumping[client] = false;
		ModifyGravity(client);
	}
	return Plugin_Stop;
}

public Action:Timer_ResetGravity(Handle:timer, any:client) {

	if (IsLegitimateClientAlive(client)) ModifyGravity(client);
	return Plugin_Stop;
}

public Action:Timer_CloakingDeviceBreakdown(Handle:timer, any:client) {

	if (IsLegitimateClientAlive(client)) {

		SetEntityRenderMode(client, RENDER_NORMAL);
		SetEntityRenderColor(client, 255, 255, 255, 255);
	}
	return Plugin_Stop;
}

public Action:Timer_ResetPlayerHealth(Handle:timer, any:client) {

	if (IsLegitimateClientAlive(client)) {

		LoadHealthMaximum(client);
		GiveMaximumHealth(client);
	}
	return Plugin_Stop;
}

/*public Action:Timer_RemoveImmune(Handle:timer, Handle:packy) {

	ResetPack(packy);
	new client			=	ReadPackCell(packy);
	new pos				=	ReadPackCell(packy);
	new owner			=	ReadPackCell(packy);

	if (client != -1 && IsClientActual(client) && !IsFakeClient(client)) {

		SetArrayString(PlayerAbilitiesImmune[client], pos, "0");
	}
	else {

		SetArrayString(PlayerAbilitiesImmune_Bots, pos, "0");
	}
	if (IsLegitimateClient(owner)) SetArrayString(PlayerAbilitiesImmune[owner][client], pos, "0");

	return Plugin_Stop;
}*/


stock ResetCDImmunity(client) {

	new size = 0;
	/*for (new i = 1; i <= MaxClients; i++) {

		if (!IsLegitimateClient(i)) continue;

		size = GetArraySize(PlayerAbilitiesImmune[client][i]);
		for (new y = 0; y < size; y++) {

			SetArrayString(PlayerAbilitiesImmune[client][i], y, "0");
		}
	}*/

	/*for (new i = 1; i <= MAXPLAYERS; i++) {

		//if (!IsLegitimateClient(i)) continue;
		for (new y = 1; y <= MAXPLAYERS; y++) {

			//if (!IsLegitimateClient(y)) continue;
			size = GetArraySize(PlayerAbilitiesImmune[i][y]);
			for (new z = 0; z < size; z++) {

				SetArrayString(PlayerAbilitiesImmune[i][y], z, "0");
			}
		}
	}*/

	if (IsLegitimateClient(client)) {

		size = GetArraySize(PlayerAbilitiesCooldown[client]);
		for (new i = 0; i < size; i++) {

			SetArrayString(PlayerAbilitiesCooldown[client], i, "0");
		}
		/*size = GetArraySize(PlayerAbilitiesImmune[client]);
		for (new i = 0; i < size; i++) {

			SetArrayString(PlayerAbilitiesImmune[client], i, "0");
		}*/
	}
	else if (client == -1) {

		size = GetArraySize(PlayerAbilitiesCooldown_Bots);
		for (new i = 0; i < size; i++) {

			SetArrayString(PlayerAbilitiesCooldown_Bots, i, "0");
		}
		size = GetArraySize(PlayerAbilitiesImmune_Bots);
		for (new i = 0; i < size; i++) {

			SetArrayString(PlayerAbilitiesImmune_Bots, i, "0");
		}
	}
}

/*public Action:Timer_CreateCooldown(Handle:timer, Handle:packttt) {

	ResetPack(packttt);
	new client				=	ReadPackCell(packttt);
	decl String:TalentName[64];
	ReadPackString(packttt, TalentName, sizeof(TalentName));
	new Float:f_Cooldown	= ReadPackFloat(packttt);

	if (IsLegitimateClientAlive(client)) {

		CreateCooldown(client, GetTalentPosition(client, TalentName), f_Cooldown);
	}

	return Plugin_Stop;
}*/

/*public Action:Timer_IsIncapacitated(Handle:timer, any:client) {
	if (IsLegitimateClientAlive(client) && IsIncapacitated(client)) {
		new attacker = L4D2_GetInfectedAttacker(client);
		if (attacker == -1) GetAbilityStrengthByTrigger(client, attacker, "n", _, 0);
		else {
			GetAbilityStrengthByTrigger(attacker, client, "M");
			GetAbilityStrengthByTrigger(client, attacker, "N");
		}
	}
	return Plugin_Stop;
}*/

public Action:Timer_Slow(Handle:timer, any:client) {
	if (!IsLegitimateClient(client)) return Plugin_Stop;
	if (!b_IsActiveRound || !IsPlayerAlive(client) || ISSLOW[client] == INVALID_HANDLE) {
		SetSpeedMultiplierBase(client);
		fSlowSpeed[client] = 1.0;
		KillTimer(ISSLOW[client]);
		ISSLOW[client] = INVALID_HANDLE;
		return Plugin_Stop;
	}
	//SetEntityMoveType(client, MOVETYPE_WALK);
	SetSpeedMultiplierBase(client);
	fSlowSpeed[client] = 1.0;
	return Plugin_Stop;
}

public Action:Timer_Explode(Handle:timer, Handle:packagey) {

	ResetPack(packagey);

	new client 		= ReadPackCell(packagey);
	if (!IsLegitimateClientAlive(client)) {

		ISEXPLODETIME[client] = 0.0;
		KillTimer(ISEXPLODE[client]);
		ISEXPLODE[client] = INVALID_HANDLE;
		//CloseHandle(ISBLIND[client]);
		//CloseHandle(packagey);
		return Plugin_Stop;
	}

	new Float:ClientPosition[3];
	GetClientAbsOrigin(client, ClientPosition);

	new Float:flStrengthAura = ReadPackCell(packagey) * 1.0;
	new Float:flStrengthTarget = ReadPackFloat(packagey);
	new Float:flStrengthLevel = ReadPackFloat(packagey);
	new Float:flRangeMax = ReadPackFloat(packagey);
	new Float:flDeathMultiplier = ReadPackFloat(packagey);
	new Float:flDeathBaseTime = ReadPackFloat(packagey);
	new Float:flDeathInterval = ReadPackFloat(packagey);
	new Float:flDeathMaxTime = ReadPackFloat(packagey);
	decl String:StAuraColour[64];
	decl String:StAuraPos[64];
	ReadPackString(packagey, StAuraColour, sizeof(StAuraColour));
	ReadPackString(packagey, StAuraPos, sizeof(StAuraPos));
	new iLevelRequired = ReadPackCell(packagey);

	new NumLivingEntities = LivingEntitiesInRange(client, ClientPosition, flRangeMax);

	if (!b_IsActiveRound || !IsLegitimateClient(client) || IsLegitimateClient(client) && !IsPlayerAlive(client) || ISEXPLODETIME[client] >= flDeathBaseTime && NumLivingEntities < 1 || ISEXPLODETIME[client] >= flDeathMaxTime) {

		ISEXPLODETIME[client] = 0.0;
		KillTimer(ISEXPLODE[client]);
		ISEXPLODE[client] = INVALID_HANDLE;
		//CloseHandle(ISBLIND[client]);
		//CloseHandle(packagey);
		return Plugin_Stop;
	}
	new Float:flStrengthTotal = flStrengthAura + ((flStrengthTarget * NumLivingEntities) + (flStrengthLevel * PlayerLevel[client]));

	new Float:TargetPosition[3];
	flStrengthTotal *= flDeathMultiplier;

	if (FindZombieClass(client) == ZOMBIECLASS_TANK && IsCoveredInBile(client)) {

		ISEXPLODETIME[client] += flDeathInterval;
		return Plugin_Continue;
	}
	CreateRing(client, flRangeMax, StAuraColour, StAuraPos);
	CreateExplosion(client);
	ScreenShake(client);
	new ReflectDebuff = 0;
	if (IsClientInRangeSpecialAmmo(client, "d") == -2.0) flStrengthTotal += (flStrengthTotal * IsClientInRangeSpecialAmmo(client, "d", false, _, flStrengthTotal));
	if (IsClientInRangeSpecialAmmo(client, "E") == -2.0) flStrengthTotal += (flStrengthTotal * IsClientInRangeSpecialAmmo(client, "E", false, _, flStrengthTotal));
	if (IsClientInRangeSpecialAmmo(client, "D") == -2.0) flStrengthTotal = (flStrengthTotal * (1.0 - IsClientInRangeSpecialAmmo(client, "D", false, _, flStrengthTotal)));

	new DamageValue = RoundToCeil(flStrengthTotal);
	SetClientTotalHealth(client, DamageValue);

	for (new i = 1; i <= MaxClients; i++) {

		if (!IsLegitimateClientAlive(i) || i == client) continue;
		if (GetClientTeam(i) == TEAM_SURVIVOR && PlayerLevel[i] < iLevelRequired) continue;	// we add infected later.

		GetClientAbsOrigin(i, TargetPosition);
		if (GetVectorDistance(ClientPosition, TargetPosition) > (flRangeMax / 2)) continue;

		CreateExplosion(i);	// boom boom audio and effect on the location.
		if (!IsFakeClient(i)) ScreenShake(i);

		//if (DamageValue > GetClientHealth(i)) IncapacitateOrKill(i);
		//else SetEntityHealth(i, GetClientHealth(i) - DamageValue);
		if (GetClientTeam(i) == TEAM_SURVIVOR) {

			if (IsClientInRangeSpecialAmmo(i, "D") == -2.0) SetClientTotalHealth(i, RoundToCeil(DamageValue * (1.0 - IsClientInRangeSpecialAmmo(i, "D", false, _, DamageValue * 1.0))));
			else SetClientTotalHealth(i, DamageValue);
			if (IsClientInRangeSpecialAmmo(i, "R") == -2.0) {

				ReflectDebuff = RoundToCeil(DamageValue * IsClientInRangeSpecialAmmo(i, "R", false, _, DamageValue * 1.0));
				SetClientTotalHealth(client, ReflectDebuff);
				CreateAndAttachFlame(i, ReflectDebuff, 3.0, 0.5, i, "reflect");
			}
		}
		else if (GetClientTeam(i) == TEAM_INFECTED) {

			if (IsSpecialCommonInRange(i, 'd')) {

				if (IsClientInRangeSpecialAmmo(client, "D") == -2.0) {

					ReflectDebuff = RoundToCeil(DamageValue * (1.0 - IsClientInRangeSpecialAmmo(client, "D", false, _, DamageValue * 1.0)));
					CreateAndAttachFlame(client, ReflectDebuff, 3.0, 0.5, i, "reflect");
				}
				else CreateAndAttachFlame(client, DamageValue, 3.0, 0.5, i, "reflect");
			}
			else AddSpecialInfectedDamage(client, i, DamageValue);
		}
	}
	new ent = -1;
	new SuperReflect = 0;
	decl String:AuraEffect[10];
	new bool:entityIsSpecialCommon;
	for (new i = 0; i < GetArraySize(Handle:CommonInfected); i++) {
		ent = GetArrayCell(Handle:CommonInfected, i);
		if (!IsCommonInfected(ent)) continue;
		entityIsSpecialCommon = IsSpecialCommon(ent);
		if (ent == client || entityIsSpecialCommon) continue;
		GetEntPropVector(ent, Prop_Send, "m_vecOrigin", TargetPosition);
		if (GetVectorDistance(ClientPosition, TargetPosition) > (flRangeMax / 2) || IsSpecialCommonInRange(ent, 'd')) continue;

		if (!entityIsSpecialCommon) AddCommonInfectedDamage(client, ent, DamageValue);
		else {
			// We check what kind of special common the entity is
			GetCommonValueAtPos(AuraEffect, sizeof(AuraEffect), ent, SUPER_COMMON_AURA_EFFECT);
			if (StrContains(AuraEffect, "d", true) == -1 || IsClientInRangeSpecialAmmo(client, "R") == -2.0) {
				if (IsClientInRangeSpecialAmmo(client, "R") == -2.0) AddSpecialCommonDamage(client, ent, RoundToCeil(DamageValue * IsClientInRangeSpecialAmmo(client, "R", false, _, DamageValue * 1.0)));
				else AddSpecialCommonDamage(client, ent, DamageValue);
			}
			else {	// if a player tries to reflect damage at a reflector, it's moot (ie reflects back to the player) so in this case the player takes double damage, though that's after mitigations.
				if (IsClientInRangeSpecialAmmo(client, "D") == -2.0) {
					SuperReflect = RoundToCeil(DamageValue * (1.0 - IsClientInRangeSpecialAmmo(client, "D", false, _, DamageValue * 1.0)));
					SetClientTotalHealth(client, SuperReflect);
					ReceiveCommonDamage(client, ent, SuperReflect);
				}
				else {
					SetClientTotalHealth(client, DamageValue);
					ReceiveCommonDamage(client, ent, DamageValue);
				}
			}
		}
	}
	for (new i = 0; i < GetArraySize(Handle:WitchList); i++) {

		ent = GetArrayCell(Handle:WitchList, i);
		if (ent == client || !IsWitch(ent)) continue;
		GetEntPropVector(ent, Prop_Send, "m_vecOrigin", TargetPosition);
		if (GetVectorDistance(ClientPosition, TargetPosition) > (flRangeMax / 2)) continue;
		if (!IsSpecialCommonInRange(ent, 'd')) AddWitchDamage(client, ent, DamageValue);
		else {
			SetClientTotalHealth(client, DamageValue);
			ReceiveWitchDamage(client, ent, DamageValue);
		}
	}
	ISEXPLODETIME[client] += flDeathInterval;

	return Plugin_Continue;
}

public Action:Timer_IsNotImmune(Handle:timer, any:client) {

	if (IsLegitimateClient(client)) b_IsImmune[client] = false;
	return Plugin_Stop;
}

public Action:Timer_CheckIfHooked(Handle:timer) {

	if (!b_IsActiveRound) {
		iSurvivalCounter = 0;
		return Plugin_Stop;
	}
	static CurRPG = -2;
	static LivingSerfs = 0;
	LivingSerfs = LivingSurvivors();
	static RoundSeconds = 0;
	RoundSeconds = RPGRoundTime(true);
	if (IsSurvivalMode) {
		iSurvivalCounter++;
		if (iSurvivalCounter >= iSurvivalRoundTime) {

			for (new i = 1; i <= MaxClients; i++) {

				if (IsLegitimateClient(i)) {
					if (GetClientTeam(i) == TEAM_SURVIVOR) {
						IsSpecialAmmoEnabled[i][0] = 0.0;
						if (IsPlayerAlive(i)) AwardExperience(i, _, _, true);
						else Defibrillator(i, _, true);
					}
				}
			}
			iSurvivalCounter = 0;
			bIsSettingsCheck = true;
		}
	}
	if (RoundSeconds % HostNameTime == 0) {
		PrintToChatAll("%t", "playing in server name", orange, blue, Hostname, orange, blue, MenuCommand, orange);
	}
	if (SurvivorsSaferoomWaiting()) SurvivorBotsRegroup();
	if (TotalHumanSurvivors() >= 1 &&
		(iEndRoundIfNoHealthySurvivors == 1 && (LivingSerfs == LedgedSurvivors() || NoHealthySurvivors())) || LivingSerfs < 1 || NoLivingHumanSurvivors()) {
		// scenario will not end if there are bots alive because dead players can take control of them.
		ForceServerCommand("scenario_end");
		CallRoundIsOver();
		return Plugin_Stop;
	}
	static String:text[64];
	new secondsUntilEnrage = GetSecondsUntilEnrage();
	if (!IsSurvivalMode && iEnrageTime > 0 && RoundSeconds > 0 && RPGRoundTime() < iEnrageTime && (secondsUntilEnrage <= 300 && (secondsUntilEnrage % 60 == 0 || secondsUntilEnrage == 30 || secondsUntilEnrage <= 3) || (RoundSeconds % iEnrageAdvertisement) == 0)) {
		TimeUntilEnrage(text, sizeof(text));
		PrintToChatAll("%t", "enrage in...", orange, green, text, orange);
	}
	if (CurRPG == -2) CurRPG = iRPGMode;
	for (new i = 1; i <= MaxClients; i++) {
		if (CurRPG < 1 || !IsLegitimateClientAlive(i) || GetClientTeam(i) != TEAM_SURVIVOR) continue;
		if (PlayerHasWeakness(i)) {
			SetEntityRenderMode(i, RENDER_TRANSCOLOR);
			SetEntityRenderColor(i, 0, 0, 0, 255);
			SetEntProp(i, Prop_Send, "m_bIsOnThirdStrike", 1);
			if (!IsFakeClient(i)) EmitSoundToClient(i, "player/heartbeatloop.wav");
		}
		else {
			SetEntityRenderMode(i, RENDER_NORMAL);
			SetEntityRenderColor(i, 255, 255, 255, 255);
			if (!IsFakeClient(i)) StopSound(i, SNDCHAN_AUTO, "player/heartbeatloop.wav");
			SetEntProp(i, Prop_Send, "m_bIsOnThirdStrike", 0);
		}
	}
	return Plugin_Continue;
}

public Action:Timer_Doom(Handle:timer) {

	if (!b_IsActiveRound || DoomSUrvivorsRequired == 0) {

		DoomTimer = 0;
		return Plugin_Stop;
	}
	new SurvivorCount = LivingSurvivors();
	if (DoomSUrvivorsRequired == -1 && SurvivorCount != TotalSurvivors() ||
		DoomSUrvivorsRequired > 0 && SurvivorCount < DoomSUrvivorsRequired) {

		if (DoomTimer == 0) PrintToChatAll("%t", "you are doomed", orange);
		DoomTimer++;
	}
	else DoomTimer = 0;

	if (DoomTimer >= DoomKillTimer) {

		for (new i = 1; i <= MaxClients; i++) {

			if (IsLegitimateClientAlive(i) && GetClientTeam(i) == TEAM_SURVIVOR) {

				if (IsClientInRangeSpecialAmmo(i, "C", true) == -2.0) continue;
				HealingContribution[i] = 0;
				PointsContribution[i] = 0.0;
				TankingContribution[i] = 0;
				DamageContribution[i] = 0;
				BuffingContribution[i] = 0;
				HexingContribution[i] = 0;

				ForcePlayerSuicide(i);
			}
		}
		if (DoomTimer == DoomKillTimer) PrintToChatAll("%t", "survivors are doomed", orange);
		if (LivingHumanSurvivors() < 1) return Plugin_Stop;
	}
	return Plugin_Continue;
}

public Action:Timer_TankCooldown(Handle:timer) {

	static Float:Counter								=	0.0;

	if (!b_IsActiveRound) {

		Counter											=	0.0;
		return Plugin_Stop;
	}
	Counter												+=	1.0;
	f_TankCooldown										-=	1.0;
	if (f_TankCooldown < 1.0) {

		Counter											=	0.0;
		f_TankCooldown									=	-1.0;
		for (new i = 1; i <= MaxClients; i++) {

			if (IsClientInGame(i) && !IsFakeClient(i) && (GetClientTeam(i) == TEAM_INFECTED || ReadyUp_GetGameMode() != 2)) {

				PrintToChat(i, "%T", "Tank Cooldown Complete", i, orange, white);
			}
		}

		return Plugin_Stop;
	}
	if (Counter >= fVersusTankNotice) {

		Counter											=	0.0;
		for (new i = 1; i <= MaxClients; i++) {

			if (IsClientInGame(i) && !IsFakeClient(i) && (GetClientTeam(i) == TEAM_INFECTED || ReadyUp_GetGameMode() != 2)) {

				PrintToChat(i, "%T", "Tank Cooldown Remaining", i, green, f_TankCooldown, white, orange, white);
			}
		}
	}

	return Plugin_Continue;
}

stock GetSuperCommonLimit() {
	return RoundToCeil((AllowedCommons + RaidCommonBoost()) * fSuperCommonLimit);
}

stock GetCommonQueueLimit() {
	return RoundToCeil((AllowedCommons + RaidCommonBoost()) * fCommonQueueLimit);
}

public Action:Timer_SettingsCheck(Handle:timer) {

	if (!b_IsActiveRound) {

		SetConVarInt(FindConVar("z_common_limit"), 0);	// no commons unless active round.
		return Plugin_Stop;
	}

	static RaidLevelCounter		= 0;
	static bool:bIsEnrage = false;
	//static RageCommonLimit		= 0;

	if (!bIsSettingsCheck) return Plugin_Continue;
	bIsSettingsCheck = false;

	//if (!IsSurvivalMode) 
	//if (!IsSurvivalMode) 
	if (iTankRush != 1 || b_IsFinaleActive) {

		RaidLevelCounter = RaidCommonBoost();

		// we force a common limit on the tank rush servers
		if (iTankRush == 1 && RaidLevelCounter < 30) RaidLevelCounter = 30;
	}
	else RaidLevelCounter = 0;
	//else RaidLevelCounter = 0;
	//else RaidLevelCounter = 0;

	if (AllowedPanicInterval - RaidLevelCounter < 60) AllowedPanicInterval = 60;

	bIsEnrage = IsEnrageActive();

	new CommonAllowed = (AllowedCommons + RaidLevelCounter);
	if (bIsEnrage) RaidLevelCounter = RoundToCeil(fEnrageMultiplier * RaidLevelCounter);
	if (CommonAllowed <= iCommonsLimitUpper || bIsEnrage) SetConVarInt(FindConVar("z_common_limit"), AllowedCommons + RaidLevelCounter);
	else SetConVarInt(FindConVar("z_common_limit"), iCommonsLimitUpper);
	if (iTankRush != 1) SetConVarInt(FindConVar("z_reserved_wanderers"), RaidLevelCounter);
	else {

		//if (AllowedCommons + RaidLevelCounter)

		SetConVarInt(FindConVar("z_reserved_wanderers"), 0);
		SetConVarInt(FindConVar("director_always_allow_wanderers"), 0);
	}
	SetConVarInt(FindConVar("z_mega_mob_size"), AllowedMegaMob + RaidLevelCounter);
	SetConVarInt(FindConVar("z_mob_spawn_max_size"), AllowedMobSpawn + RaidLevelCounter);
	SetConVarInt(FindConVar("z_mob_spawn_finale_size"), AllowedMobSpawnFinale + RaidLevelCounter);
	if (iTankRush != 1 && AllowedPanicInterval - RaidLevelCounter > 60) SetConVarInt(FindConVar("z_mega_mob_spawn_max_interval"), AllowedPanicInterval - RaidLevelCounter);
	else SetConVarInt(FindConVar("z_mega_mob_spawn_max_interval"), 60);

	return Plugin_Continue;
}

bool:IsSurvivorsHealthy() {

	for (new i = 1; i <= MaxClients; i++) {

		if (IsLegitimateClientAlive(i) && L4D2_GetInfectedAttacker(i) == -1) return true;
	}
	return false;
}

/*public Action:Timer_IsSpecialCommonInRange(Handle:timer) {
	if (!b_IsActiveRound) return Plugin_Stop;
	static commonInfected = 0;

	for (new i = 1; i <= MaxClients; i++) {
		if (!IsLegitimateClientAlive(i)) continue;
		if (GetClientTeam(i) != TEAM_SURVIVOR) continue;
		commonInfected = 0;
		IsSpecialCommonInRange(i, 'x', _, _, commonInfected);			// kamikazi
		if (commonInfected > 0) { // if it's a kamikazi, we force it to die, so it can trigger its effects on players in the vicinity.
			ClearSpecialCommon(commonInfected);
			commonInfected = 0;
		}
		IsSpecialCommonInRange(i, 'X', _, _, commonInfected);			// life drainer
	}
	return Plugin_Continue;
}*/

public Action:Timer_RespawnQueue(Handle:timer) {

	static Counter										=	-1;
	static TimeRemaining								=	0;
	static RandomClient									=	-1;
	static String:text[64];

	if (!b_IsActiveRound || b_IsFinaleActive) {

		Counter = -1;
		return Plugin_Stop;
	}
	if (TotalHumanSurvivors() > iSurvivorRespawnRestrict) {

		/*	When there are a lot of players on the server, we want to maintain the difficulty that is experienced by lower level players.
			To prevent inflation on an exponential level, we just remove systems that aren't needed to compensate for players when there
			are less players in the server.
			Due to higher survivability and other important factors, removing the respawn queue feels like a pretty solid balance choice.
		*/
		return Plugin_Continue;
	}

	static bool:bIsHealth = false;
	bIsHealth = IsSurvivorsHealthy();

	if (!IsSurvivalMode && bIsHealth) Counter++;
	else Counter = iSurvivalCounter;
	TimeRemaining = RespawnQueue - Counter;
	if (TimeRemaining <= 0) RandomClient = FindAnyRandomClient(true);

	for (new i = 1; i <= MaxClients; i++) {

		if (!IsLegitimateClient(i) || GetClientTeam(i) != TEAM_SURVIVOR || IsPlayerAlive(i)) continue;
		if (TimeRemaining > 0) {

			if (!IsFakeClient(i)) {

				if (bIsHealth) Format(text, sizeof(text), "%T", "respawn queue", i, TimeRemaining);
				else Format(text, sizeof(text), "%T", "respawn queue paused", i, TimeRemaining);
				PrintHintText(i, text);
			}
		}
		else if (IsLegitimateClientAlive(RandomClient)) {

			GetClientAbsOrigin(RandomClient, Float:DeathLocation[i]);
			SDKCall(hRoundRespawn, i);
			b_HasDeathLocation[i] = true;
			MyRespawnTarget[i] = -1;
			CreateTimer(3.0, Timer_TeleportRespawn, i, TIMER_FLAG_NO_MAPCHANGE);
			CreateTimer(3.0, Timer_GiveMaximumHealth, i, TIMER_FLAG_NO_MAPCHANGE);

			RandomClient = FindAnyRandomClient(true);
		}
	}
	if (Counter >= RespawnQueue) Counter = 0;
	return Plugin_Continue;
}

public Action:Timer_AcidCooldown(Handle:timer, any:client) {
	if (IsLegitimateClient(client)) DebuffOnCooldown(client, "acid", true);
	return Plugin_Stop;
}

bool:DebuffOnCooldown(client, String:debuffToSearchFor[], bool:removeDebuffCooldown = false) {
	decl String:result[64];
	new size = GetArraySize(ApplyDebuffCooldowns[client]);
	for (new pos = 0; pos < size; pos++) {
		GetArrayString(ApplyDebuffCooldowns[client], pos, result, sizeof(result));
		if (!StrEqual(debuffToSearchFor, result)) continue;
		if (!removeDebuffCooldown) return true;
		RemoveFromArray(ApplyDebuffCooldowns[client], pos);
		break;
	}
	return false;
}

stock bool:IsClientSorted(client) {

	new size = GetArraySize(Handle:hThreatSort);
	//new target = -1;
	for (new i = 0; i < size; i++) {

		if (client == GetArrayCell(hThreatSort, i)) return true;
	}
	return false;
}

public Action:Timer_PlayTime(Handle:timer) {
	if (!b_IsActiveRound) return Plugin_Stop;
	for (new i = 1; i <= MaxClients; i++) {
		if (!IsLegitimateClient(i) || GetClientTeam(i) == TEAM_SPECTATOR) continue;
		TimePlayed[i]++;
	}
	return Plugin_Continue;
}

stock SortThreatMeter() {

	ClearArray(hThreatSort);
	ClearArray(hThreatMeter);
	new cTopThreat = -1;
	new cTopClient = -1;
	new cTotalClients = 0;
	new size = 0;
	for (new i = 1; i <= MaxClients; i++) {

		if (!IsLegitimateClientAlive(i) || GetClientTeam(i) != TEAM_SURVIVOR) continue;
		cTotalClients++;
	}
	while (GetArraySize(hThreatSort) < cTotalClients) {

		cTopThreat = 0;
		for (new i = 1; i <= MaxClients; i++) {

			if (!IsLegitimateClientAlive(i) || GetClientTeam(i) != TEAM_SURVIVOR || IsClientSorted(i)) continue;
			if (iThreatLevel[i] > cTopThreat) {

				cTopThreat = iThreatLevel[i];
				cTopClient = i;
			}
		}
		if (cTopThreat > 0) {
			//Format(text, sizeof(text), "%d+%d", cTopClient, cTopThreat);
			//PushArrayString(Handle:hThreatMeter, text);
			size = GetArraySize(hThreatMeter);
			ResizeArray(hThreatMeter, size + 1);
			SetArrayCell(hThreatMeter, size, cTopClient, 0);
			SetArrayCell(hThreatMeter, size, cTopThreat, 1);
			PushArrayCell(hThreatSort, cTopClient);
		}
		else break;
	}
}

public Action:Timer_ThreatSystem(Handle:timer) {

	static cThreatTarget			= -1;
	static cThreatOld				= -1;
	static cThreatLevel				= 0;
	static cThreatEnt				= -1;
	static count					= 0;
	static String:temp[64];
	static Float:vPos[3];

	if (!b_IsActiveRound) {
		iSurvivalCounter = -1;

		for (new i = 1; i <= MaxClients; i++) {

			if (IsLegitimateClient(i)) {

				iThreatLevel_temp[i] = 0;
				iThreatLevel[i] = 0;
			}
		}

		count = 0;
		cThreatLevel = 0;
		iTopThreat = 0;
		if (cThreatEnt && EntRefToEntIndex(cThreatEnt) != INVALID_ENT_REFERENCE) AcceptEntityInput(cThreatEnt, "Kill");
		cThreatEnt = -1;

		return Plugin_Stop;
	}
	iSurvivalCounter++;
	SortThreatMeter();
	count++;

	cThreatOld = cThreatTarget;
	cThreatLevel = 0;
	

	if (GetArraySize(hThreatMeter) < 1) {

		for (new i = 1; i <= MaxClients; i++) {

			if (IsLegitimateClient(i) && GetClientTeam(i) == TEAM_SURVIVOR) {

				if (!IsPlayerAlive(i)) {

					iThreatLevel_temp[i] = 0;
					iThreatLevel[i] = 0;
					
					continue;
				}
				if (iThreatLevel[i] > cThreatLevel) {

					cThreatTarget = i;
					cThreatLevel = iThreatLevel[i];
				}
			}
		}
	}
	else {

		//GetArrayString(Handle:hThreatMeter, 0, temp, sizeof(temp));
		//ExplodeString(temp, "+", iThreatInfo, 2, 64);
		//client+threat
		cThreatTarget = GetArrayCell(hThreatMeter, 0, 0);
		//cThreatTarget = StringToInt(iThreatInfo[0]);
		
		//GetClientName(iClient, text, sizeof(text));
		//iThreatTarget = StringToInt(iThreatInfo[1]);
		cThreatLevel = iThreatLevel[cThreatTarget];
	}

	iTopThreat = cThreatLevel;	// when people use taunt, it sets iTopThreat + 1;
	if (cThreatOld != cThreatTarget || count >= 20) {

		count = 0;
		if (cThreatEnt && EntRefToEntIndex(cThreatEnt) != INVALID_ENT_REFERENCE) AcceptEntityInput(cThreatEnt, "Kill");
		cThreatEnt = -1;
	}

	if (cThreatEnt == -1 && IsLegitimateClientAlive(cThreatTarget)) {

		cThreatEnt = CreateEntityByName("info_goal_infected_chase");
		if (cThreatEnt > 0) {
			
			cThreatEnt = EntIndexToEntRef(cThreatEnt);

			DispatchSpawn(cThreatEnt);
			//new Float:vPos[3];
			GetClientAbsOrigin(cThreatTarget, vPos);
			vPos[2] += 20.0;
			TeleportEntity(cThreatEnt, vPos, NULL_VECTOR, NULL_VECTOR);

			SetVariantString("!activator");
			AcceptEntityInput(cThreatEnt, "SetParent", cThreatTarget);

			//decl String:temp[32];
			Format(temp, sizeof temp, "OnUser4 !self:Kill::20.0:-1");
			SetVariantString(temp);
			AcceptEntityInput(cThreatEnt, "AddOutput");
			AcceptEntityInput(cThreatEnt, "FireUser4");
		}
	}

	return Plugin_Continue;
}

public Action:Timer_DirectorPurchaseTimer(Handle:timer) {
	static Counter										=	-1;
	static Float:DirectorHandicap						=	-1.0;
	static Float:DirectorDelay							=	0.0;
	if (!b_IsActiveRound) {
		Counter											=	-1;
		return Plugin_Stop;
	}
	static theClient									=	-1;
	static theTankStartTime								=	-1;
	new iTankCount = GetInfectedCount(ZOMBIECLASS_TANK);
	new iTankLimit = GetSpecialInfectedLimit(true);
	new iInfectedCount = GetInfectedCount();
	new iSurvivors = TotalHumanSurvivors();
	new iSurvivorBots = TotalSurvivors() - iSurvivors;
	new LivingSerfs = LivingSurvivorCount();
	new requiredAlwaysTanks = GetAlwaysTanks(iSurvivors);
	if (iSurvivorBots >= 2) iSurvivorBots /= 2;
	theClient = FindAnyRandomClient();
	if (requiredAlwaysTanks >= 1 && iTankCount < requiredAlwaysTanks && (iTanksAlwaysEnforceCooldown == 0 || f_TankCooldown == -1.0) || iTankRush == 1 && !b_IsFinaleActive && iTankCount < (iSurvivors + iSurvivorBots)) {
		ExecCheatCommand(theClient, "z_spawn_old", "tank auto");
	}
	else if (iTankRush == 0) {

		if (iInfectedCount < (iSurvivors + iSurvivorBots)) {

			SpawnAnyInfected(theClient);
		}
	}
	new iTankRequired = GetAlwaysTanks(iSurvivors);
	if (iTankRequired != 0) {

		if (theTankStartTime == -1) theTankStartTime = GetConfigValueInt("tank rush delay?");//theTankStartTime = GetRandomInt(30, 60);
		if (theTankStartTime == 0 || RPGRoundTime(true) >= theTankStartTime) {

			theTankStartTime = 0;

			if (iInfectedCount - iTankCount < (iSurvivors)) SpawnAnyInfected(theClient);
			//if (!b_IsFinaleActive && iTankCount < iTankLimit && iTankCount < iTanksAlways) {
			// no finale active			don't force on this server		or if we do and not on cooldown
			if (!b_IsFinaleActive && (iTanksAlwaysEnforceCooldown == 0 || f_TankCooldown == -1.0) && ((iTankRequired > 0 && iTankCount < iTankLimit + iTankRequired) || (iTankRequired == 0 && iTankCount < iSurvivors + iSurvivorBots))) {

				if (IsLegitimateClientAlive(theClient))	ExecCheatCommand(theClient, "z_spawn_old", "tank auto");
			}
		}
	}
	/*if (HumanPlayersInGame() < 1) {

		Counter = -1;
		CallRoundIsOver();
		return Plugin_Stop;
	}*/
	if (DirectorHandicap == -1.0) {

		DirectorHandicap = fDirectorThoughtHandicap;
		DirectorDelay	 = fDirectorThoughtDelay;
	}
	if (Counter == -1 || b_IsSurvivalIntermission || LivingSurvivorCount() < 1) {

		Counter = GetTime() + RoundToCeil(DirectorDelay - (LivingHumanSurvivors() * DirectorHandicap));
		return Plugin_Continue;
	}
	else if (Counter > GetTime()) {

		// We still spawn specials, out of range of players to enforce the active special limit.
		return Plugin_Continue;
	}
	//PrintToChatAll("%t", "Director Think Process", orange, white);


	Counter = GetTime() + RoundToCeil(DirectorDelay - (LivingSerfs * DirectorHandicap));

	new size				=	GetArraySize(a_DirectorActions);

	for (new i = 1; i <= MaximumPriority; i++) { CheckDirectorActionPriority(i, size); }

	return Plugin_Continue;
}

stock GetAlwaysTanks(survivors) {

	if (iTanksAlways > 0) return iTanksAlways;
	if (iTanksAlways < 0) {
		return RoundToFloor((survivors * 1.0)/(iTanksAlways * -1));
	}
	return 0;
}

stock CheckDirectorActionPriority(pos, size) {

	decl String:text[64];
	for (new i = 0; i < size; i++) {

		if (i < GetArraySize(a_DirectorActions_Cooldown)) GetArrayString(a_DirectorActions_Cooldown, i, text, sizeof(text));
		else break;
		if (StringToInt(text) > 0) continue;			// Purchase still on cooldown.
		
		DirectorKeys					=	GetArrayCell(a_DirectorActions, i, 0);
		DirectorValues					=	GetArrayCell(a_DirectorActions, i, 1);

		if (GetKeyValueInt(DirectorKeys, DirectorValues, "priority?") != pos || !DirectorPurchase_Valid(DirectorKeys, DirectorValues, i)) continue;
		DirectorPurchase(DirectorKeys, DirectorValues, i);
	}
}

stock bool:DirectorPurchase_Valid(Handle:Keys, Handle:Values, pos) {

	new Float:PointCost		=	0.0;
	new Float:PointCostMin	=	0.0;
	decl String:Cooldown[64];

	GetArrayString(a_DirectorActions_Cooldown, pos, Cooldown, sizeof(Cooldown));
	if (StringToInt(Cooldown) > 0) return false;

	PointCost				=	GetKeyValueFloat(Keys, Values, "point cost?") + (GetKeyValueFloat(Keys, Values, "cost handicap?") * LivingHumanSurvivors());
	if (PointCost > 1.0) PointCost = 1.0;
	PointCostMin			=	GetKeyValueFloat(Keys, Values, "point cost minimum?") + (GetKeyValueFloat(Keys, Values, "min cost handicap?") * LivingHumanSurvivors());

	if (Points_Director > 0.0) PointCost *= Points_Director;
	if (PointCost < PointCostMin) PointCost = PointCostMin;

	if (Points_Director >= PointCost) return true;
	return false;
}

stock bool:bIsDirectorTankEligible() {

	if (ActiveTanks() < DirectorTankLimit()) return true;
	return false;
}

stock ActiveTanks() {
	new iSurvivors = TotalHumanSurvivors();
	//new iSurvivorBots = TotalSurvivors() - iSurvivors;
	new count = GetAlwaysTanks(iSurvivors);

	for (new i = 1; i <= MaxClients; i++) {
		if (IsClientInGame(i) && GetClientTeam(i) == TEAM_INFECTED && IsPlayerAlive(i) && FindZombieClass(i) == ZOMBIECLASS_TANK) count++;
	}
	return count;
}

stock DirectorTankLimit() {
	return GetSpecialInfectedLimit(true);
}

stock GetWitchCount() {

	new count = 0;
	new ent = -1;
	while ((ent = FindEntityByClassname(ent, "witch")) != INVALID_ENT_REFERENCE) {

		// Some maps, like Hard Rain pre-spawn a ton of witches - we want to add them to the witch table.
		count++;
	}
	return count;
}

stock DirectorPurchase(Handle:Keys, Handle:Values, pos) {

	decl String:Command[64];
	decl String:Parameter[64];
	decl String:Model[64];
	new IsPlayerDrop		=	0;
	new Count				=	0;

	new Float:PointCost		=	0.0;
	new Float:PointCostMin	=	0.0;

	new Float:MinimumDelay	=	0.0;

	PointCost				=	GetKeyValueFloat(Keys, Values, "point cost?") + (GetKeyValueFloat(Keys, Values, "cost handicap?") * LivingHumanSurvivors());
	PointCostMin			=	GetKeyValueFloat(Keys, Values, "point cost minimum?") + (GetKeyValueFloat(Keys, Values, "min cost handicap?") * LivingHumanSurvivors());
	FormatKeyValue(Parameter, sizeof(Parameter), Keys, Values, "parameter?");
	Count					=	GetKeyValueInt(Keys, Values, "count?");
	FormatKeyValue(Command, sizeof(Command), Keys, Values, "command?");
	IsPlayerDrop			=	GetKeyValueInt(Keys, Values, "drop?");
	FormatKeyValue(Model, sizeof(Model), Keys, Values, "model?");
	MinimumDelay			=	GetKeyValueFloat(Keys, Values, "minimum delay?");

	if (PointCost > 1.0) {

		PointCost			=	1.0;
	}

	new bool:bIsEnrage = IsEnrageActive();

	//if (ReadyUp_GetGameMode() != 3 && b_IsFinaleActive && StrContains(Parameter, "witch", false) == -1 && StrContains(Parameter, "tank", false) == -1) return;

	if (DirectorWitchLimit == 0) DirectorWitchLimit = LivingSurvivorCount();


	if (StrContains(Parameter, "witch", false) != -1 && (IsSurvivalMode || GetWitchCount() >= DirectorWitchLimit || GetArraySize(Handle:WitchList) + 1 >= DirectorWitchLimit)) return;
	if (StrContains(Parameter, "tank", false) != -1 && (IsSurvivalMode || (ActiveTanks() >= DirectorTankLimit() && !bIsEnrage || bIsEnrage && ActiveTanks() >= LivingHumanSurvivors()) || f_TankCooldown != -1.0)) return;

	if (StrEqual(Parameter, "common")) {

		if (GetArraySize(CommonInfectedQueue) + Count >= GetCommonQueueLimit()) {

			return;
		}
	}

	/*if ((StrEqual(Command, "director_force_panic_event") || IsPlayerDrop) && b_IsFinaleActive) {

		return;
	}*/
	//if (!IsEnrageActive() && StrEqual(Command, "director_force_panic_event")) return;

	if (Points_Director > 0.0) PointCost *= Points_Director;
	if (PointCost < PointCostMin) PointCost = PointCostMin;

	if (Points_Director < PointCost) return;

	if (LivingSurvivorCount() < GetKeyValueInt(Keys, Values, "living survivors?")) return;

	new Client				=	FindLivingSurvivor();
	if (Client < 1) return;
	Points_Director -= PointCost;

	if (!IsEnrageActive() && MinimumDelay > 0.0) {

		SetArrayString(a_DirectorActions_Cooldown, pos, "1");
		MinimumDelay = MinimumDelay - (LivingHumanSurvivors() * fDirectorThoughtHandicap) - (GetKeyValueFloat(Keys, Values, "delay handicap?") * LivingHumanSurvivors());
		if (MinimumDelay < 0.0) MinimumDelay = 0.0;
		fDirectorThoughtDelay = fDirectorThoughtDelay - (LivingHumanSurvivors() * fDirectorThoughtHandicap);
		if (fDirectorThoughtDelay < 0.0) fDirectorThoughtDelay = 0.0;
		CreateTimer(fDirectorThoughtDelay + MinimumDelay, Timer_DirectorActions_Cooldown, pos, TIMER_FLAG_NO_MAPCHANGE);
	}

	if (!StrEqual(Parameter, "common")) ExecCheatCommand(Client, Command, Parameter);
	else {
		decl String:superCommonType[64];
		FormatKeyValue(superCommonType, sizeof(superCommonType), Keys, Values, "supercommon?");
		SpawnCommons(Client, Count, Command, Parameter, Model, IsPlayerDrop, superCommonType);
	}
}

/*stock InsertInfected(survivor, infected) {

	CreateListPositionByEntity(survivor, infected, InfectedHealth[survivor]);
	new isArraySize = GetArraySize(Handle:InfectedHealth[survivor]);
	new t_InfectedHealth = 0;
	ResizeArray(Handle:InfectedHealth[survivor], isArraySize + 1);
	SetArrayCell(Handle:InfectedHealth[survivor], isArraySize, infected, 0);

	//An infected wasn't added on spawn to this player, so we add it now based on class.
	if (FindZombieClass(infected) == ZOMBIECLASS_TANK) t_InfectedHealth = 4000;
	else if (FindZombieClass(infected) == ZOMBIECLASS_HUNTER || FindZombieClass(infected) == ZOMBIECLASS_SMOKER) t_InfectedHealth = 250;
	else if (FindZombieClass(infected) == ZOMBIECLASS_BOOMER) t_InfectedHealth = 50;
	else if (FindZombieClass(infected) == ZOMBIECLASS_SPITTER) t_InfectedHealth = 100;
	else if (FindZombieClass(infected) == ZOMBIECLASS_CHARGER) t_InfectedHealth = 600;
	else if (FindZombieClass(infected) == ZOMBIECLASS_JOCKEY) t_InfectedHealth = 325;

	decl String:ss_InfectedHealth[64];
	Format(ss_InfectedHealth, sizeof(ss_InfectedHealth), "(%d) infected health bonus", FindZombieClass(infected));

	if (StringToInt(GetConfigValue("infected bot level type?")) == 1) t_InfectedHealth += t_InfectedHealth * RoundToCeil(HumanSurvivorLevels() * StringToFloat(GetConfigValue(ss_InfectedHealth)));
	else t_InfectedHealth += t_InfectedHealth * RoundToCeil(PlayerLevel[survivor] * StringToFloat(GetConfigValue(ss_InfectedHealth)));
	if (HandicapLevel[survivor] > 0) t_InfectedHealth += t_InfectedHealth * RoundToCeil(HandicapLevel[survivor] * StringToFloat(GetConfigValue("handicap health increase?")));

	SetArrayCell(Handle:InfectedHealth[survivor], isArraySize, t_InfectedHealth, 1);
	SetArrayCell(Handle:InfectedHealth[survivor], isArraySize, 0, 2);
	SetArrayCell(Handle:InfectedHealth[survivor], isArraySize, 0, 3);
	if (isArraySize == 0) return -1;
	return isArraySize;
}*/

stock SpawnCommons(Client, Count, String:Command[], String:Parameter[], String:Model[], IsPlayerDrop, String:SuperCommon[] = "none") {

	new TargetClient				=	-1;
	new CommonQueueLimit = GetCommonQueueLimit();
	if (StrContains(Model, ".mdl", false) != -1) {

		for (new i = Count; i > 0 && GetArraySize(CommonInfectedQueue) < CommonQueueLimit; i--) {

			if (IsPlayerDrop == 1) {

				ResizeArray(Handle:CommonInfectedQueue, GetArraySize(Handle:CommonInfectedQueue) + 1);
				ShiftArrayUp(Handle:CommonInfectedQueue, 0);
				SetArrayString(Handle:CommonInfectedQueue, 0, Model);
				TargetClient		=	FindLivingSurvivor();
				if (StrContains(SuperCommon, "-", false) == -1 && !StrEqual(SuperCommon, "none", false)) PushArrayString(Handle:SuperCommonQueue, SuperCommon);
				if (TargetClient > 0) ExecCheatCommand(TargetClient, Command, Parameter);
			}
			else PushArrayString(Handle:CommonInfectedQueue, Model);
		}
	}
}

stock FindLivingSurvivor() {


	/*new Client = -1;
	while (Client == -1 && LivingSurvivorCount() > 0) {

		Client = GetRandomInt(1, MaxClients);
		if (!IsClientInGame(Client) || !IsClientHuman(Client) || !IsPlayerAlive(Client) || GetClientTeam(Client) != TEAM_SURVIVOR) Client = -1;
	}
	return Client;*/
	for (new i = LastLivingSurvivor; i <= MaxClients && LivingSurvivorCount() > 0; i++) {

		if (IsLegitimateClientAlive(i) && GetClientTeam(i) == TEAM_SURVIVOR) {

			LastLivingSurvivor = i;
			return i;
		}
	}
	LastLivingSurvivor = 1;
	if (LivingSurvivorCount() < 1) return -1;
	return -1;
}

stock LivingSurvivorCount(ignore = -1) {

	new Count = 0;
	for (new i = 1; i <= MaxClients; i++) {

		if (IsLegitimateClientAlive(i) && GetClientTeam(i) == TEAM_SURVIVOR && (ignore == -1 || i != ignore)) Count++;
	}
	return Count;
}

public Action:Timer_DirectorActions_Cooldown(Handle:timer, any:pos) {

	SetArrayString(a_DirectorActions_Cooldown, pos, "0");
	return Plugin_Stop;
}