/* put the line below after all of the includes!
#pragma newdecls required
*/

public Action Timer_EntityOnFire(Handle timer) {
	if (!b_IsActiveRound) {
		return Plugin_Stop;
	}

	float currentEngineTime = GetEngineTime();
	for (int i = 0; i < GetArraySize(EntityOnFire); i++) {
		int Client = GetArrayCell(EntityOnFire, i);
		bool IsClientAlive = IsLegitimateClientAlive(Client);
		bool IsClientSurvivor = (IsClientAlive && myCurrentTeam[Client] == TEAM_SURVIVOR) ? true : false;
		bool clientIsSpecialCommon = IsSpecialCommon(Client);
		bool clientIsCommonInfected = (!IsSpecialCommon && IsCommonInfected(Client)) ? true : false;
		bool clientIsWitch = IsWitch(Client);
		if (!clientIsSpecialCommon && !clientIsCommonInfected && !clientIsWitch && !IsClientAlive) {
			RemoveFromArray(EntityOnFire, i);
			if (i > 0) i--;
			continue;
		}
		if ((GetEntityFlags(Client) & FL_INWATER)) {
			ExtinguishEntity(Client);
			RemoveFromArray(EntityOnFire, i);
			if (i > 0) i--;
			continue;
		}
		int damage = GetArrayCell(EntityOnFire, i, 1);
		float FlTime = GetArrayCell(EntityOnFire, i, 2);
		float TickInt = GetArrayCell(EntityOnFire, i, 3);
		float TickIntOriginal = GetArrayCell(EntityOnFire, i, 4);
		int Owner = GetArrayCell(EntityOnFire, i, 5);
		int t_Damage = 0;
		if (Owner != -1) Owner = FindClientByIdNumber(Owner);
		// if (Owner == -1) {
		// 	ExtinguishEntity(Client);
		// 	RemoveFromArray(EntityOnFire, i);
		// 	RemoveFromArray(EntityOnFireName, i);
		// 	if (i > 0) i--;
		// 	continue;
		// }
		if (TickInt - fDebuffTickrate <= 0.0) {
			TickInt = TickIntOriginal;
			t_Damage = RoundToCeil(damage / (FlTime / TickInt));
			//damage -= t_Damage;
			// HERE WE FIND OUT IF THE COMMON OR WITCH OR WHATEVER IS IMMUNE TO THE DAMAGE
			//CODEBEAN
			char ModelName[64];
			GetEntPropString(Client, Prop_Data, "m_ModelName", ModelName, sizeof(ModelName));
			if (IsClientSurvivor ||
				!IsSpecialCommonInRangeEx(Client, "jimmy") && StrContains(ModelName, "jimmy", false) == -1 && (Owner > 0 && IsFakeClient(Owner) || !IsSpecialCommonInRange(Client, 't'))) {
				if (IsClientAlive) {
					float ammoStr = IsClientInRangeSpecialAmmo(Client, "D", _, _, t_Damage);
					if (ammoStr > 0.0) {
						int DamageShield = RoundToCeil(t_Damage * (1.0 - ammoStr));
						if (IsClientSurvivor && DamageShield > 0) {
							CombatTime[Client] = currentEngineTime + fOutOfCombatTime;
							SetClientTotalHealth(Owner, Client, DamageShield);
							if (Owner > 0) AddSpecialInfectedDamage(Client, Owner, DamageShield, CONTRIBUTION_AWARD_TANKING);
						}
					}
					else {
						CombatTime[Client] = currentEngineTime + fOutOfCombatTime;
						if (IsClientSurvivor) {
							SetClientTotalHealth(Owner, Client, t_Damage);
							if (Owner > 0) AddSpecialInfectedDamage(Client, Owner, t_Damage, CONTRIBUTION_AWARD_TANKING);
						}
						else if (Owner > 0) {
							AddSpecialInfectedDamage(Owner, Client, t_Damage, CONTRIBUTION_AWARD_DAMAGE);
						}
					}
				}
				else if (Owner > 0) {
					if (clientIsWitch) {
						AddWitchDamage(Owner, Client, t_Damage);
					}
					else if (clientIsSpecialCommon) {
						AddSpecialCommonDamage(Owner, Client, t_Damage);
					}
					else if (clientIsCommonInfected) {
						AddCommonInfectedDamage(Owner, Client, t_Damage);
					}
					if (Client != Owner && myCurrentTeam[Client] != myCurrentTeam[Owner]) {
						HexingContribution[Owner] += t_Damage;
						GetAbilityStrengthByTrigger(Client, Owner, TRIGGER_L, _, t_Damage);
					}
				}
			}
		}
		if (FlTime - fDebuffTickrate <= 0.0 || damage <= 0) {
			RemoveFromArray(EntityOnFire, i);
			if (i > 0) i--;
			ExtinguishEntity(Client);
			continue;
		}
		SetArrayCell(EntityOnFire, i, damage - t_Damage, 1);
		SetArrayCell(EntityOnFire, i, FlTime - fDebuffTickrate, 2);
		SetArrayCell(EntityOnFire, i, TickInt - fDebuffTickrate, 3);
	}
	return Plugin_Continue;
}

public Action Timer_CommonAffixes(Handle timer) {

	if (!b_IsActiveRound) {

		for (int i = 1; i <= MaxClients; i++) {

			//ClearArray(CommonAffixesCooldown[i]);
			ClearArray(SpecialCommon[i]);
		}
		//ResetArray(Handle:CommonInfected);
		ResetArray(WitchList);
		ResetArray(CommonAffixes);
		return Plugin_Stop;
	}
	static IsCommonAffixesEnabled = -2;
	if (IsCommonAffixesEnabled == -2) IsCommonAffixesEnabled = iCommonAffixes;
	if (IsCommonAffixesEnabled == 2) {
		for (int zombie = 0; zombie < GetArraySize(CommonAffixes); zombie++) {
			int ent = GetArrayCell(CommonAffixes, zombie);
			if (IsCommonInfected(ent)) {
				int superPos = GetArrayCell(CommonAffixes, zombie, 1);
				DrawCommonAffixes(ent, superPos);
			}
		}
	}
	// tanks with cloned abilities
	for (int i = 1; i <= MaxClients; i++) {

		if (!IsLegitimateClientAlive(i) || myCurrentTeam[i] != TEAM_INFECTED || FindZombieClass(i) != ZOMBIECLASS_TANK) continue;
		if (bIsDefenderTank[i]) {

			// draw defender tank rings
			DrawSpecialInfectedAffixes(i);
		}
	}
	return Plugin_Continue;
}

public Action Timer_StaggerTimer(Handle timer) {
	//decl String:clientId[2][64];
	//decl String:text[64];
	if (!b_IsActiveRound) {
		ClearArray(StaggeredTargets);
		return Plugin_Stop;
	}
	for (int i = 1; i <= MaxClients; i++) {
		if (!IsLegitimateClient(i)) continue;
		//IsStaggered(i);
		if (SDKCall(g_hIsStaggering, i)) bIsClientCurrentlyStaggered[i] = true;
		else bIsClientCurrentlyStaggered[i] = false;
	}
	static float timeRemaining = 0.0;
	for (int i = 0; i < GetArraySize(StaggeredTargets); i++) {
		//GetArrayString(StaggeredTargets, i, text, sizeof(text));
		//ExplodeString(text, ":", clientId, 2, 64);
		//timeRemaining = StringToFloat(clientId[1]);
		timeRemaining = GetArrayCell(StaggeredTargets, i, 1);
		if (timeRemaining <= fStaggerTickrate) RemoveFromArray(StaggeredTargets, i);
		else {
			SetArrayCell(StaggeredTargets, i, timeRemaining - fStaggerTickrate, 1);
			//Format(text, sizeof(text), "%s:%3.3f", clientId[0], timeRemaining - fStaggerTickrate);
			//SetArrayString(StaggeredTargets, i, text);
		}
	}
	return Plugin_Continue;
}

public Action Timer_ChargerJumpCheck(Handle timer, any client) {

	if (IsClientInGame(client) && IsFakeClient(client) && myCurrentTeam[client] == TEAM_INFECTED) {

		if (FindZombieClass(client) != ZOMBIECLASS_CHARGER || !IsPlayerAlive(client)) return Plugin_Stop;
		int victim = L4D2_GetSurvivorVictim(client);
		if (victim == -1) return Plugin_Continue;
		if ((GetEntityFlags(client) & FL_ONGROUND)) {

			GetAbilityStrengthByTrigger(client, victim, TRIGGER_v, _, 0);
			return Plugin_Continue;
		}
	}
	return Plugin_Stop;
}

public Action Timer_GiveSecondPistol(Handle timer, any client) {

	if (IsLegitimateClientAlive(client)) {

		ExecCheatCommand(client, "give", "pistol");
	}
	return Plugin_Stop;
}

public Action Timer_ImmunityExpiration(Handle timer, any client) {

	if (IsLegitimateClient(client)) RespawnImmunity[client] = false;
	return Plugin_Stop;
}

public Action Timer_ZeroGravity(Handle timer, any client) {

	if (IsLegitimateClientAlive(client)) {

		ModifyGravity(client);
	}
	//ZeroGravityTimer[client] = INVALID_HANDLE;
	return Plugin_Stop;
}

public Action Timer_ResetCrushImmunity(Handle timer, any client) {
	if (IsLegitimateClient(client)) bIsCrushCooldown[client] = false;
	return Plugin_Stop;
}

public Action Timer_ResetBurnImmunity(Handle timer, any client) {

	if (IsLegitimateClient(client)) bIsBurnCooldown[client] = false;
	return Plugin_Stop;
}

public Action Timer_HealImmunity(Handle timer, any client) {

	if (IsLegitimateClient(client)) {

		HealImmunity[client] = false;
	}
	return Plugin_Stop;
}

// public Action Timer_IsMeleeCooldown(Handle timer, any client) {

// 	if (IsLegitimateClient(client)) { bIsMeleeCooldown[client] = false; }
// 	return Plugin_Stop;
// }

public Action Timer_ResetShotgunCooldown(Handle timer, any client) {
	if (IsLegitimateClient(client)) shotgunCooldown[client] = false;
	return Plugin_Stop;
}

void VerifyMinimumRating(int client, bool setMinimumRating = false) {
	int minimumRating = RoundToCeil(BestRating[client] * fRatingFloor);
	if (setMinimumRating || Rating[client] < minimumRating) Rating[client] = minimumRating;
}

stock void CheckDifficulty() {
	char Difficulty[64];
	GetConVarString(FindConVar("z_difficulty"), Difficulty, sizeof(Difficulty));
	if (!StrEqual(Difficulty, sServerDifficulty, false)) SetConVarString(FindConVar("z_difficulty"), sServerDifficulty);
}

stock void GiveProfileItems(int client) {
	if (GetArraySize(hWeaponList[client]) == 2) {
		char text[64];
		GetArrayString(hWeaponList[client], 0, text, sizeof(text));
		if (!StrEqual(text, "none")) {
			QuickCommandAccessEx(client, text, _, true);
		}
		GetArrayString(hWeaponList[client], 1, text, sizeof(text));
		if (!StrEqual(text, "none")) {
			QuickCommandAccessEx(client, text, _, true);
			if (StrContains(text, "pistol") != -1 && StrContains(text, "magnum") == -1) {
				CreateTimer(0.5, Timer_GiveSecondPistol, client, TIMER_FLAG_NO_MAPCHANGE);
			}
		}
	}
}

public Action Timer_GiveLaserBeam(Handle timer, any client) {

	if (IsLegitimateClientAlive(client)) {

		ExecCheatCommand(client, "upgrade_add", "LASER_SIGHT");
	}
	return Plugin_Stop;
}

public Action Timer_CheckDifficulty(Handle timer) {
	if (b_IsRoundIsOver) return Plugin_Stop;
	CheckDifficulty();
	return Plugin_Continue;
}
public Action Timer_TickingMine(Handle timer, any entity) {
	int size = GetArraySize(playerCustomEntitiesCreated);
	bool entityIsFoundInArray = false;
	float currentEngineTime = GetEngineTime();
	for (int i = 0; i < size; i++) {
		if (GetArrayCell(playerCustomEntitiesCreated, i, 2) != entity) continue;
		if (!b_IsActiveRound || !IsValidEntity(entity)) {
			RemoveFromArray(playerCustomEntitiesCreated, i);
			return Plugin_Stop;
		}
		entityIsFoundInArray = true;
		float timeUntilMineExplodes = GetArrayCell(playerCustomEntitiesCreated, i, 4);
		float AoESize = GetArrayCell(playerCustomEntitiesCreated, i, 3);
		int visualInterval = GetArrayCell(playerCustomEntitiesCreated, i, 5);
		SetArrayCell(playerCustomEntitiesCreated, i, visualInterval + 1, 5);
		if (visualInterval % 3 == 0) CreateExplosionRingOnClient(entity, AoESize);
		
		float entityPos[3];
		GetEntPropVector(entity, Prop_Send, "m_vecOrigin", entityPos);
		float commonPos[3];
		int ci = -1;
		int storedCommons = 0;
		if (timeUntilMineExplodes <= currentEngineTime) {
			// explode the mine
			int activator = GetArrayCell(playerCustomEntitiesCreated, i);
			int damage = GetArrayCell(playerCustomEntitiesCreated, i, 1);

			CreateExplosion(entity);
			// commons
			for (int survivor = 1; survivor <= MaxClients; survivor++) {
				if (!IsLegitimateClient(survivor)) continue;
				storedCommons = GetArraySize(CommonInfected[survivor]);
				for (int common = 0; common < storedCommons; common++) {
					ci = GetArrayCell(CommonInfected[survivor], common);
					if (!IsCommonInfected(ci)) continue;
					GetEntPropVector(ci, Prop_Send, "m_vecOrigin", commonPos);
					if (GetVectorDistance(entityPos, commonPos) > AoESize/2.0) continue;
					AddCommonInfectedDamage(activator, ci, damage);
				}
			}
			// specials
			for (int si = 0; si <= MaxClients; si++) {
				if (!IsLegitimateClientAlive(si) || myCurrentTeam[si] != TEAM_INFECTED) continue;
				GetEntPropVector(si, Prop_Send, "m_vecOrigin", commonPos);
				if (GetVectorDistance(entityPos, commonPos) > AoESize/2.0) continue;
				AddSpecialInfectedDamage(activator, si, damage);
			}
			RemoveFromArray(playerCustomEntitiesCreated, i);
			return Plugin_Stop;
		}
		else if (timeUntilMineExplodes - currentEngineTime > 3.0) {
			for (int survivor = 1; survivor <= MaxClients; survivor++) {
				if (!IsLegitimateClient(survivor)) continue;
				storedCommons = GetArraySize(CommonInfected[survivor]);
				for (int common = 0; common < storedCommons; common++) {
					ci = GetArrayCell(CommonInfected[survivor], common);
					if (!IsCommonInfected(ci)) continue;
					GetEntPropVector(ci, Prop_Send, "m_vecOrigin", commonPos);
					if (GetVectorDistance(entityPos, commonPos) > AoESize/2.0) continue;
					SetArrayCell(playerCustomEntitiesCreated, i, currentEngineTime + 3.0, 4);
					survivor = MaxClients+1;
					break;
				}
			}
		}
		break;
	}
	if (entityIsFoundInArray) return Plugin_Continue;
	return Plugin_Stop;
}

public Action Timer_ShowHUD(Handle timer, any client) {
	if (!b_IsActiveRound || !IsLegitimateClient(client)) return Plugin_Stop;
	if (!IsPlayerAlive(client)) return Plugin_Continue;

	char pct[10];
	Format(pct, 10, "%");
	int ThisRoundTime = RPGRoundTime();

	if (PlayerLevel[client] > iMaxLevel) SetTotalExperienceByLevel(client, iMaxLevel, true);
	TimePlayed[client]++;
	//if (TotalHumanSurvivors() < 1) RoundTime++;	// we don't count time towards enrage if there are no human survivors.
	//decl String:targetSteamID[64];
	if (iShowAdvertToNonSteamgroupMembers == 1 && !IsGroupMember[client]) {
		IsGroupMemberTime[client]++;
		if (IsGroupMemberTime[client] % iJoinGroupAdvertisement == 0) {
			PrintToChat(client, "%T", "join group advertisement", client, GroupMemberBonus * 100.0, pct, orange, blue, orange, blue, orange, blue, green, orange);
		}
	}
	displayBuffOrDebuff[client] = (displayBuffOrDebuff[client] == 0) ? 1 : 0;
	if (!IsFakeClient(client)) DisplayHUD(client, displayBuffOrDebuff[client]);
	if (ReadyUpGameMode != 3 && bIsGiveProfileItems[client]) {
		bIsGiveProfileItems[client] = false;
		GiveProfileItems(client);
	}
	if (myCurrentTeam[client] == TEAM_SURVIVOR && CurrentRPGMode >= 1) {
		int mymaxhealth = GetMaximumHealth(client);
		float healregenamount = GetAbilityStrengthByTrigger(client, _, TRIGGER_p, _, 0, _, _, RESULT_h, _, true, 1);	// activator, target, trigger ability, effects, zombieclass, damage
		float healregenpercentageboost = GetAbilityStrengthByTrigger(client, _, TRIGGER_p, _, 0, _, _, RESULT_h, _, true, 2);
		if (healregenpercentageboost > 0.0) healregenamount += (healregenamount * healregenpercentageboost);
		float cohHealing = GetCoherencyStrength(client, ACTIVATOR_ABILITY_EFFECTS, "h", COHERENCY_RANGE);
		if (cohHealing > 0.0) healregenamount += cohHealing;
		if (healregenamount > 0.0) {
			float clericHealPercentage = GetTalentStrengthByKeyValue(client, ACTIVATOR_ABILITY_EFFECTS, "cleric");// not skip, going to try skipping.
			float clericRange = GetStrengthByKeyValueFloat(client, ACTIVATOR_ABILITY_EFFECTS, "cleric", COHERENCY_RANGE);
			float pacifistHealAmountRaw = GetAbilityStrengthByTrigger(client, _, TRIGGER_pacifist, _, 0, _, _, RESULT_h, _, _, 1);
			float pacifistHealAmountPer = GetAbilityStrengthByTrigger(client, _, TRIGGER_pacifist, _, 0, _, _, RESULT_h, _, _, 2);
			if (pacifistHealAmountPer > 0.0) pacifistHealAmountRaw += (pacifistHealAmountRaw * pacifistHealAmountPer);
			if (clericHealPercentage > 0.0 || pacifistHealAmountRaw > 0.0) {
				if (clericRange <= 0.0) clericRange = 256.0;
				if (clericHealPercentage > 0.0) healregenamount *= clericHealPercentage;
				if (healregenamount < 1.0) healregenamount = 1.0;
				if (pacifistHealAmountRaw > 0.0) healregenamount += pacifistHealAmountRaw;
				float clientPos[3];
				GetClientAbsOrigin(client, clientPos);
				for (int teammate = 1; teammate <= MaxClients; teammate++) {
					if (teammate == client || !IsLegitimateClientAlive(teammate) || myCurrentTeam[client] != myCurrentTeam[teammate]) continue;
					float teammatePos[3];
					GetClientAbsOrigin(teammate, teammatePos);
					if (GetVectorDistance(clientPos, teammatePos) > clericRange || GetClientHealth(teammate) >= GetMaximumHealth(teammate)) continue;
					HealPlayer(teammate, client, healregenamount, 'h', true);
				}
				CreateHealingRingOnClient(client, clericRange);
			}
		}
		//ModifyHealth(client, GetAbilityStrengthByTrigger(client, client, "p", _, 0, _, _, "H"), 0.0);
		ModifyHealth(client);
		if (GetClientHealth(client) > mymaxhealth) SetEntityHealth(client, mymaxhealth);
	}
	GetAbilityStrengthByTrigger(client, client, TRIGGER_pacifist, _, _, _, _, _, _, _, 0);
	GetAbilityStrengthByTrigger(client, client, TRIGGER_p, _, _, _, _, _, _, _, 0); // percentage passives
	RemoveStoreTime(client);
	LastPlayLength[client]++;
	if (iEnrageTime > 0 && ReadyUpGameMode != 3 && CurrentRPGMode >= 1 && ThisRoundTime >= iEnrageTime) {
		if (SurvivorEnrage[client][1] == 0.0) {
			EnrageBlind(client, 100);
			SurvivorEnrage[client][1] = 1.0;
		}
		else {
			SurvivorEnrage[client][1] = 0.0;
		}
	}
	return Plugin_Continue;
}

stock LedgedSurvivors() {

	int count = 0;
	for (int i = 1; i <= MaxClients; i++) {

		if (IsLegitimateClientAlive(i) && myCurrentTeam[i] == TEAM_SURVIVOR && IsLedged(i)) count++;
	}
	return count;
}

stock bool NoLivingHumanSurvivors() {
	for (int i = 1; i <= MaxClients; i++) {
		if (!IsLegitimateClient(i) || IsFakeClient(i) || myCurrentTeam[i] != TEAM_SURVIVOR || !IsPlayerAlive(i)) continue;
		return false;
	}
	return true;
}

stock bool NoHealthySurvivors(bool bMustNotBeABot = false) {

	for (int i = 1; i <= MaxClients; i++) {
		if (!IsLegitimateClientAlive(i) || IsIncapacitated(i) || myCurrentTeam[i] != TEAM_SURVIVOR) continue;
		if (bMustNotBeABot && IsFakeClient(i)) continue;
		return false;
	}
	return true;
}

stock HumanSurvivors() {

	int count = 0;
	for (int i = 1; i <= MaxClients; i++) {

		if (IsClientInGame(i) && !IsFakeClient(i) && myCurrentTeam[i] == TEAM_SURVIVOR) count++;
	}
	return count;
}

public Action Timer_TeleportRespawn(Handle timer, any client) {

	if (b_IsActiveRound && IsLegitimateClient(client) && myCurrentTeam[client] == TEAM_SURVIVOR) {
		//ChangeHook(client, true);

		int target = MyRespawnTarget[client];

		if (target != client && IsLegitimateClientAlive(target)) {

			GetClientAbsOrigin(target, DeathLocation[target]);
			TeleportEntity(client, DeathLocation[target], NULL_VECTOR, NULL_VECTOR);
			MyRespawnTarget[client] = client;
		}
		else TeleportEntity(client, DeathLocation[client], NULL_VECTOR, NULL_VECTOR);
		b_HasDeathLocation[client] = false;
	}
	return Plugin_Stop;
}

public Action Timer_GiveMaximumHealth(Handle timer, any client) {

	if (IsLegitimateClientAlive(client)) {

		GiveMaximumHealth(client);		// So instant heal doesn't put a player above their maximum health pool.
	}

	return Plugin_Stop;
}

public Action Timer_DestroyCombustion(Handle timer, any entity)
{
	if (!IsValidEntity(entity) || entity < 1) return Plugin_Stop;
	AcceptEntityInput(entity, "Kill");
	return Plugin_Stop;
}

public Action Timer_SlowPlayer(Handle timer, any client) {

	if (IsLegitimateClientAlive(client)) {

		SetEntPropFloat(client, Prop_Send, "m_flLaggedMovementValue", SpeedMultiplierBase[client]);
	}
	//SlowMultiplierTimer[client] = INVALID_HANDLE;
	return Plugin_Stop;
}

stock GetTimePlayed(client, char[] s, size) {
	int seconds = TimePlayed[client];
	int minutes = 0;
	int hours = 0;
	int days = 0;
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
	Format(s, size, "Playtime:");
	if (days > 1) Format(s, size, "%s %d Days,", s, days);
	else if (days > 0) Format(s, size, "%s %d Day,", s, days);
	if (hours > 1) Format(s, size, "%s %d Hours,", s, hours);
	else if (hours > 0) Format(s, size, "%s %d Hour,", s, hours);
	if (minutes > 1) Format(s, size, "%s %d Minutes,", s, minutes);
	else if (minutes > 0) Format(s, size, "%s %d Minute,", s, minutes);
	if (seconds > 1) Format(s, size, "%s %d Seconds", s, seconds);
	else if (seconds > 0) Format(s, size, "%s %d Second", s, seconds);
}

/*public Action:Timer_AwardSkyPoints(Handle:timer) {

	if (!b_IsActiveRound) return Plugin_Stop;

	for (new i = 1; i <= MaxClients; i++) {

		if (IsClientInGame(i) && !IsFakeClient(i) && myCurrentTeam[i] != TEAM_SPECTATOR) {

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

public Action Timer_BlindPlayer(Handle timer, any client) {

	if (IsLegitimateClient(client)) BlindPlayer(client);
	return Plugin_Stop;
}

public Action Timer_FrozenPlayer(Handle timer, any client) {

	if (IsLegitimateClient(client)) FrozenPlayer(client, _, 0);
	return Plugin_Stop;
}

stock float GetActiveZoomTime(client) {
	int listClient = 0;
	float activeZoomTimeTime = 0.0;
	float activeZoomTime = GetEngineTime();
	for (int i = 0; i < GetArraySize(zoomCheckList); i++) {
		listClient = GetArrayCell(zoomCheckList, i, 0);
		if (client != listClient) continue;
		activeZoomTimeTime = GetArrayCell(zoomCheckList, i, 1);
		activeZoomTime -= activeZoomTimeTime;
		return activeZoomTime;
	}
	return 0.0;
}

stock bool isQuickscopeKill(client) {
	int listClient = 0;
	float fClientHoldingFireTime = 0.0;
	float killDelayAfterScope = GetEngineTime();
	for (int i = 0; i < GetArraySize(zoomCheckList); i++) {
		listClient = GetArrayCell(zoomCheckList, i, 0);
		if (client != listClient) continue;
		fClientHoldingFireTime = GetArrayCell(zoomCheckList, i, 1);
		killDelayAfterScope -= fClientHoldingFireTime;
		if (killDelayAfterScope <= fquickScopeTime) return true;
		return false;
	}
	return false;
}

stock zoomCheckToggle(client, bool insert = false) {
	int listClient = 0;
	for (int i = 0; i < GetArraySize(zoomCheckList); i++) {
		listClient = GetArrayCell(zoomCheckList, i, 0);
		if (client != listClient) continue;
		if (insert) return;
		// The user is unscoping so we remove them from the array.
		RemoveFromArray(zoomCheckList, i);
	}
	if (insert) {
		// we don't even get here if the user is already in the list.
		int size = GetArraySize(zoomCheckList);
		ResizeArray(zoomCheckList, size + 1);
		SetArrayCell(zoomCheckList, size, client, 0);
		SetArrayCell(zoomCheckList, size, GetEngineTime(), 1);
	}
	return;
}

public Action Timer_ZoomcheckDelayer(Handle timer, any client) {
	if (!IsLegitimateClient(client)) return Plugin_Stop;
	if (IsPlayerZoomed(client)) {
		// trigger nodes that fire when a player zooms in (like effects over time)
		zoomCheckToggle(client, true);
	}
	else zoomCheckToggle(client);
	ZoomcheckDelayer[client] = INVALID_HANDLE;
	return Plugin_Stop;
}

stock float GetHoldingFireTime(client) {
	int listClient = 0;
	float fClientHoldingFireTime = 0.0;
	float holdingFireTime = GetEngineTime();
	for (int i = 0; i < GetArraySize(holdingFireList); i++) {
		listClient = GetArrayCell(holdingFireList, i, 0);
		if (listClient != client) continue;
		fClientHoldingFireTime = GetArrayCell(holdingFireList, i, 1);
		holdingFireTime -= fClientHoldingFireTime;
		return holdingFireTime;
	}
	return 0.0;
}

stock holdingFireCheckToggle(client, bool insert = false) {
	int listClient = 0;
	for (int i = 0; i < GetArraySize(holdingFireList); i++) {
		listClient = GetArrayCell(holdingFireList, i, 0);
		if (listClient != client) continue;
		if (insert) return;
		// The user is unscoping so we remove them from the array.
		RemoveFromArray(holdingFireList, i);
	}
	if (insert) {
		// we don't even get here if the user is already in the list.
		int size = GetArraySize(holdingFireList);
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

public Action Timer_Blinder(Handle timer, any client) {

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

public Action Timer_Freezer(Handle timer, any client) {
	if (!b_IsActiveRound || !IsLegitimateClient(client) || !IsPlayerAlive(client) || !IsSpecialCommonInRange(client, 'r')) {
		/*

			If the client is scorched, they no longer freeze.
		*/
		//KillTimer(ISFROZEN[client]);
		ISFROZEN[client] = INVALID_HANDLE;
		FrozenPlayer(client, _, 0);
		return Plugin_Stop;
	}
	float Velocity[3];
	SetEntityMoveType(client, MOVETYPE_WALK);
	Velocity[0]	=	GetEntPropFloat(client, Prop_Send, "m_vecVelocity[0]");
	Velocity[1]	=	GetEntPropFloat(client, Prop_Send, "m_vecVelocity[1]");
	Velocity[2]	=	GetEntPropFloat(client, Prop_Send, "m_vecVelocity[2]");
	Velocity[2] += 32.0;
	TeleportEntity(client, NULL_VECTOR, NULL_VECTOR, Velocity);
	SetEntityMoveType(client, MOVETYPE_NONE);
	return Plugin_Continue;
}

// public ReadyUp_FwdChangeTeam(client, team) {

// 	if (IsLegitimateClient(client)) {

// 		if (team == TEAM_SURVIVOR) {

// 			ChangeHook(client, true);
// 			if (!b_IsLoading[client] && !b_IsLoaded[client]) OnClientLoaded(client);
// 		}
// 		else if (team != TEAM_SURVIVOR) {

// 			//LogToFile(LogPathDirectory, "%N is no longer a survivor, unhooking.", client);
// 			// if (bIsInCombat[client]) {

// 			// 	IncapacitateOrKill(client, _, _, true, false, true);
// 			// }
// 			ChangeHook(client);
// 		}
// 	}
// }

public ReadyUp_FwdChangeTeam(client, team) {
	if (bIsInCombat[client]) IncapacitateOrKill(client, _, _, true, true, true);
	CreateTimer(0.2, Timer_ChangeTeamCheck, client, TIMER_FLAG_NO_MAPCHANGE);
}

public Action Timer_ChangeTeamCheck(Handle timer, any client) {
	if (!IsLegitimateClient(client)) return Plugin_Stop;
	myCurrentTeam[client] = GetClientTeam(client);
	if (myCurrentTeam[client] == TEAM_SURVIVOR) {
		//ChangeHook(client, true);
		if (!b_IsLoaded[client]) OnClientLoaded(client);
	}
	//else ChangeHook(client);
	return Plugin_Stop;
}

stock void ChangeHook(client, bool bHook = false) {

	b_IsHooked[client] = bHook;
	SDKUnhook(client, SDKHook_OnTakeDamage, OnTakeDamage);
	SDKUnhook(client, SDKHook_TraceAttack, OnTraceAttack);
	SDKUnhook(client, SDKHook_WeaponSwitch, OnWeaponSwitch);
	if (b_IsHooked[client]) {
		SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);
		SDKHook(client, SDKHook_TraceAttack, OnTraceAttack);
		SDKHook(client, SDKHook_WeaponSwitch, OnWeaponSwitch);
	}
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

public Action Timer_DetectGroundTouch(Handle timer, any client) {

	if (IsClientHuman(client) && IsPlayerAlive(client)) {

		if (myCurrentTeam[client] == TEAM_SURVIVOR && !(GetEntityFlags(client) & FL_ONGROUND) && b_IsJumping[client] && L4D2_GetInfectedAttacker(client) == -1 && !AnyTanksNearby(client)) return Plugin_Continue;
		b_IsJumping[client] = false;
		ModifyGravity(client);
	}
	return Plugin_Stop;
}

public Action Timer_ResetGravity(Handle timer, any client) {

	if (IsLegitimateClientAlive(client)) ModifyGravity(client);
	return Plugin_Stop;
}

public Action Timer_CloakingDeviceBreakdown(Handle timer, any client) {

	if (IsLegitimateClientAlive(client)) {

		SetEntityRenderMode(client, RENDER_NORMAL);
		SetEntityRenderColor(client, 255, 255, 255, 255);
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
	int size = 0;
	if (IsLegitimateClient(client)) {
		size = GetArraySize(PlayerAbilitiesCooldown[client]);
		for (int i = 0; i < size; i++) {
			SetArrayCell(PlayerAbilitiesCooldown[client], i, 0);
		}
		size = GetArraySize(PlayerActiveAbilitiesCooldown[client]);
		for (int i = 0; i < size; i++) {
			SetArrayCell(PlayerActiveAbilitiesCooldown[client], i, 0);
		}
	}
	else if (client == -1) {
		size = GetArraySize(PlayerAbilitiesCooldown_Bots);
		for (int i = 0; i < size; i++) {
			SetArrayCell(PlayerAbilitiesCooldown_Bots, i, 0);
		}
		size = GetArraySize(PlayerAbilitiesImmune_Bots);
		for (int i = 0; i < size; i++) {
			SetArrayCell(PlayerAbilitiesImmune_Bots, i, 0);
		}
	}
}

public Action Timer_Slow(Handle timer, any client) {
	if (!IsLegitimateClient(client)) return Plugin_Stop;
	if (!b_IsActiveRound || !IsPlayerAlive(client) || !ISSLOW[client]) {
		SetSpeedMultiplierBase(client);
		fSlowSpeed[client] = 1.0;
		//KillTimer(ISSLOW[client]);
		ISSLOW[client] = false;
		return Plugin_Stop;
	}
	//SetEntityMoveType(client, MOVETYPE_WALK);
	SetSpeedMultiplierBase(client);
	fSlowSpeed[client] = 1.0;
	//KillTimer(ISSLOW[client]);
	ISSLOW[client] = false;
	return Plugin_Stop;
}

public Action Timer_Explode(Handle timer, Handle packagey) {

	ResetPack(packagey);

	int client 		= ReadPackCell(packagey);
	if (!IsLegitimateClientAlive(client)) {

		ISEXPLODETIME[client] = 0.0;
		KillTimer(ISEXPLODE[client]);
		ISEXPLODE[client] = INVALID_HANDLE;
		//CloseHandle(ISBLIND[client]);
		//CloseHandle(packagey);
		return Plugin_Stop;
	}
	CombatTime[client] = GetEngineTime() + fOutOfCombatTime;
	bIsInCombat[client] = true;

	float ClientPosition[3];
	GetClientAbsOrigin(client, ClientPosition);

	int flStrengthAura = ReadPackCell(packagey);
	float flStrengthTarget = ReadPackFloat(packagey);
	float flStrengthLevel = ReadPackFloat(packagey);
	float flRangeMax = ReadPackFloat(packagey);
	float flDeathBaseTime = ReadPackFloat(packagey);
	float flDeathInterval = ReadPackFloat(packagey);
	float flDeathMaxTime = ReadPackFloat(packagey);
	int iLevelRequired = ReadPackCell(packagey);

	int NumLivingEntities = LivingEntitiesInRange(client, ClientPosition, flRangeMax);
	bool bIsLegitimateClient = IsLegitimateClient(client);

	if (!b_IsActiveRound || !bIsLegitimateClient || bIsLegitimateClient && !IsPlayerAlive(client) || ISEXPLODETIME[client] >= flDeathBaseTime && NumLivingEntities < 1 || ISEXPLODETIME[client] >= flDeathMaxTime) {

		ISEXPLODETIME[client] = 0.0;
		KillTimer(ISEXPLODE[client]);
		ISEXPLODE[client] = INVALID_HANDLE;
		//CloseHandle(ISBLIND[client]);
		//CloseHandle(packagey);
		return Plugin_Stop;
	}
	int strengthBase = flStrengthAura + RoundToCeil(flStrengthAura * ((flStrengthTarget * NumLivingEntities) + (flStrengthLevel * GetDifficultyRating(client))));
	int DamageValue = strengthBase;

	float TargetPosition[3];

	if (FindZombieClass(client) == ZOMBIECLASS_TANK && IsCoveredInBile(client)) {

		ISEXPLODETIME[client] += flDeathInterval;
		return Plugin_Continue;
	}
	CreateExplosionRingOnClient(client, flRangeMax);
	CreateExplosion(client);
	int ReflectDebuff = 0;
	DamageValue += RoundToCeil(strengthBase * IsClientInRangeSpecialAmmo(client, "d", _, _, strengthBase));
	DamageValue += RoundToCeil(strengthBase * IsClientInRangeSpecialAmmo(client, "E", _, _, strengthBase));
	float specialAmmoResult = IsClientInRangeSpecialAmmo(client, "D", _, _, strengthBase);
	if (specialAmmoResult > 0.0) DamageValue += RoundToCeil(strengthBase * (1.0 - specialAmmoResult));

	if (!IsFakeClient(client)) {
		ScreenShake(client);
		SetClientTotalHealth(_, client, DamageValue);
	}
	bool isTargetClientABot;
	float ammoStr = 0.0;
	float currentEngineTime = GetEngineTime();
	for (int i = 1; i <= MaxClients; i++) {

		if (!IsLegitimateClientAlive(i) || i == client) continue;
		if (myCurrentTeam[i] == TEAM_SURVIVOR && PlayerLevel[i] < iLevelRequired) continue;	// we add infected later.

		GetClientAbsOrigin(i, TargetPosition);
		if (GetVectorDistance(ClientPosition, TargetPosition) > (flRangeMax / 2)) continue;
		CombatTime[i] = currentEngineTime + fOutOfCombatTime;
		bIsInCombat[i] = true;

		CreateExplosion(i);	// boom boom audio and effect on the location.
		isTargetClientABot = IsFakeClient(i);
		if (!isTargetClientABot) ScreenShake(i);

		//if (DamageValue > GetClientHealth(i)) IncapacitateOrKill(i);
		//else SetEntityHealth(i, GetClientHealth(i) - DamageValue);
		if (myCurrentTeam[i] == TEAM_SURVIVOR && !isTargetClientABot) {
			ammoStr = IsClientInRangeSpecialAmmo(i, "D", _, _, DamageValue);
			if (ammoStr > 0.0) SetClientTotalHealth(client, i, RoundToCeil(DamageValue * (1.0 - ammoStr)));
			else SetClientTotalHealth(client, i, DamageValue);
			ammoStr = IsClientInRangeSpecialAmmo(i, "R", _, _, DamageValue);
			if (ammoStr > 0.0) {

				ReflectDebuff = RoundToCeil(DamageValue * ammoStr);
				SetClientTotalHealth(i, client, ReflectDebuff);
				CreateAndAttachFlame(i, ReflectDebuff, 3.0, 0.5, i, STATUS_EFFECT_REFLECT);
			}
		}
		else if (myCurrentTeam[i] == TEAM_INFECTED) {

			if (IsSpecialCommonInRange(i, 'd')) {
				ammoStr = IsClientInRangeSpecialAmmo(client, "D", _, _, DamageValue);
				if (ammoStr > 0.0) {

					ReflectDebuff = RoundToCeil(DamageValue * (1.0 - ammoStr));
					CreateAndAttachFlame(client, ReflectDebuff, 3.0, 0.5, i, STATUS_EFFECT_REFLECT);
				}
				else CreateAndAttachFlame(client, DamageValue, 3.0, 0.5, i, STATUS_EFFECT_REFLECT);
			}
			else AddSpecialInfectedDamage(client, i, DamageValue);
		}
	}
	float cpos[3];
	flRangeMax /= 2;
	for (int i = 0; i < GetArraySize(CommonInfected[client]); i++) {
		int common = GetArrayCell(CommonInfected[client], i);
		//if (!IsCommonInfected(common)) continue;
		GetEntPropVector(common, Prop_Send, "m_vecOrigin", cpos);
		if (GetVectorDistance(ClientPosition, cpos) > flRangeMax) continue;
		AddCommonInfectedDamage(client, common, DamageValue);
	}
	ISEXPLODETIME[client] += flDeathInterval;

	return Plugin_Continue;
}

public Action Timer_IsNotImmune(Handle timer, any client) {

	if (IsLegitimateClient(client)) b_IsImmune[client] = false;
	return Plugin_Stop;
}

/*bool ScenarioEndConditionsMet() {
	int numberOfLivingHumanSurvivors 	= LivingHumanSurvivors();
	int numberOfLivingSurvivors	  		= LivingSurvivors();
	//int numberOfHumanSurvivors		  	= TotalHumanSurvivors();
	// if there are no survivors at all, we let the game run, but don't advance the enrage timer.
	if (TotalSurvivors() < 1) {
		RoundTime = 0;
		return false;
	}
	// If we end the round when there's no human survivors alive, this will also end rounds if no human survivors exist.
	if (iEndRoundIfNoLivingHumanSurvivors == 1 && numberOfLivingHumanSurvivors < 1) return true;
	// Requires all survivors to be completely dead if iEndRoundIfNoHealthySurvivors = 0
	if (iEndRoundIfNoHealthySurvivors == 0) {
		// either there are no living human survivors and we require it, or all survivors are dead.
		if (numberOfLivingSurvivors < 1) return true;
	}
	// If all living survivors are dead, or they're all hanging from ledges, or they're all incapped/dead/ledged.
	else if (numberOfLivingSurvivors < 1 || numberOfLivingSurvivors == LedgedSurvivors() || NoHealthySurvivors()) return true;
	return false;
}*/

public Action Timer_CheckIfHooked(Handle timer) {

	if (!b_IsActiveRound) {
		iSurvivalCounter = 0;
		return Plugin_Stop;
	}
	if (showNumLivingSurvivorsInHostname == 1) SetSurvivorsAliveHostname();
	static CurRPG = -2;
	static RoundSeconds = 0;
	RoundSeconds = RPGRoundTime(true);
	if (IsSurvivalMode) {
		iSurvivalCounter++;
		if (iSurvivalCounter >= iSurvivalRoundTime) {

			for (int i = 1; i <= MaxClients; i++) {

				if (IsLegitimateClient(i)) {
					if (myCurrentTeam[i] == TEAM_SURVIVOR) {
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
		char advertisement[512];
		Format(advertisement, sizeof(advertisement), "server advertisement %d", iAdvertisementCounter+1);
		Format(advertisement, sizeof(advertisement), "%t", advertisement);
		ReplaceString(advertisement, sizeof(advertisement), "{HOST}", Hostname);
		ReplaceString(advertisement, sizeof(advertisement), "{RPGCMD}", MenuCommand);
		for (int i = 1; i <= MaxClients; i++) {
			if (!IsLegitimateClient(i) || IsFakeClient(i)) continue;
			Client_PrintToChat(i, true, advertisement);
		}
		if (iAdvertisementCounter + 1 == iNumAdvertisements) iAdvertisementCounter = 0;
		else iAdvertisementCounter++;
		//PrintToChatAll("%t", "playing in server name", orange, blue, Hostname, orange, blue, MenuCommand, orange);
	}
	static char text[64];
	int secondsUntilEnrage = GetSecondsUntilEnrage();
	if (iDisplayEnrageCountdown == 1 && !IsSurvivalMode && iEnrageTime > 0 && RoundSeconds > 0 && RPGRoundTime() < iEnrageTime && (secondsUntilEnrage <= iHideEnrageTimerUntilSecondsLeft && secondsUntilEnrage % 60 == 0 || (RoundSeconds % iEnrageAdvertisement) == 0)) {
		TimeUntilEnrage(text, sizeof(text));
		PrintToChatAll("%t", "enrage in...", orange, green, text, orange);
	}
	if (CurRPG == -2) CurRPG = iRPGMode;
	for (int i = 1; i <= MaxClients; i++) {
		if (CurRPG < 1 || !IsLegitimateClientAlive(i) || myCurrentTeam[i] != TEAM_SURVIVOR) continue;
		if (bHasWeakness[i] > 0) {
			SetEntityRenderMode(i, RENDER_TRANSCOLOR);
			SetEntityRenderColor(i, 0, 0, 0, 255);
			if (bHasWeakness[i] < 3) SetEntProp(i, Prop_Send, "m_bIsOnThirdStrike", 1);
			else SetEntProp(i, Prop_Send, "m_bIsOnThirdStrike", 0);
			if (!IsFakeClient(i) && !bWeaknessAssigned[i]) {
				//EmitSoundToClient(i, "player/heartbeatloop.wav");
				bWeaknessAssigned[i] = true;
			}
		}
		else {
			SetEntityRenderMode(i, RENDER_NORMAL);
			SetEntityRenderColor(i, 255, 255, 255, 255);
			if (!IsFakeClient(i) && bWeaknessAssigned[i]) {
				StopSound(i, SNDCHAN_AUTO, "player/heartbeatloop.wav");
				bWeaknessAssigned[i] = false;
			}
			SetEntProp(i, Prop_Send, "m_bIsOnThirdStrike", 0);
		}
	}
	return Plugin_Continue;
}

public Action Timer_Doom(Handle timer) {

	if (!b_IsActiveRound || DoomSUrvivorsRequired == 0) {

		DoomTimer = 0;
		return Plugin_Stop;
	}
	int SurvivorCount = LivingSurvivors();
	if (DoomSUrvivorsRequired == -1 && SurvivorCount != TotalSurvivors() ||
		DoomSUrvivorsRequired > 0 && SurvivorCount < DoomSUrvivorsRequired) {

		if (DoomTimer == 0) PrintToChatAll("%t", "you are doomed", orange);
		DoomTimer++;
	}
	else DoomTimer = 0;

	if (DoomTimer >= DoomKillTimer) {

		for (int i = 1; i <= MaxClients; i++) {

			if (IsLegitimateClientAlive(i) && myCurrentTeam[i] == TEAM_SURVIVOR) {
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

public Action Timer_TankCooldown(Handle timer) {

	static float Counter								=	0.0;

	if (!b_IsActiveRound) {

		Counter											=	0.0;
		return Plugin_Stop;
	}
	Counter												+=	1.0;
	f_TankCooldown										-=	1.0;
	if (f_TankCooldown < 1.0) {

		Counter											=	0.0;
		f_TankCooldown									=	-1.0;
		for (int i = 1; i <= MaxClients; i++) {

			if (IsClientInGame(i) && !IsFakeClient(i) && (myCurrentTeam[i] == TEAM_INFECTED || ReadyUp_GetGameMode() != 2)) {

				PrintToChat(i, "%T", "Tank Cooldown Complete", i, orange, white);
			}
		}

		return Plugin_Stop;
	}
	if (Counter >= fVersusTankNotice) {

		Counter											=	0.0;
		for (int i = 1; i <= MaxClients; i++) {

			if (IsClientInGame(i) && !IsFakeClient(i) && (myCurrentTeam[i] == TEAM_INFECTED || ReadyUp_GetGameMode() != 2)) {

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

public Action Timer_SettingsCheck(Handle timer) {

	if (!b_IsActiveRound) {

		SetConVarInt(FindConVar("z_common_limit"), 0);	// no commons unless active round.
		return Plugin_Stop;
	}
	if (RPGRoundTime(true) < iCommonInfectedSpawnDelayOnNewRound) {
		SetConVarInt(FindConVar("z_common_limit"), 0);
		return Plugin_Continue;
	}

	int RaidLevelCounter = RaidCommonBoost();
	int EnrageBoost = (IsEnrageActive()) ? RoundToCeil(RaidLevelCounter * fEnrageMultiplier) : 0;

	if (!bIsSettingsCheck) return Plugin_Continue;
	bIsSettingsCheck = false;

	int CommonAllowed = AllowedCommons + RaidLevelCounter + EnrageBoost;
	if (CommonAllowed <= iCommonsLimitUpper) SetConVarInt(FindConVar("z_common_limit"), CommonAllowed);
	else SetConVarInt(FindConVar("z_common_limit"), iCommonsLimitUpper);
	if (iTankRush != 1) {
		SetConVarInt(FindConVar("z_reserved_wanderers"), RaidLevelCounter + EnrageBoost);
		SetConVarInt(FindConVar("director_always_allow_wanderers"), 1);
	}
	else {

		//if (AllowedCommons + RaidLevelCounter)

		SetConVarInt(FindConVar("z_reserved_wanderers"), 0);
		SetConVarInt(FindConVar("director_always_allow_wanderers"), 0);
	}
	SetConVarInt(FindConVar("z_mega_mob_size"), AllowedMegaMob + RaidLevelCounter + EnrageBoost);
	SetConVarInt(FindConVar("z_mob_spawn_max_size"), AllowedMobSpawn + RaidLevelCounter + EnrageBoost);
	SetConVarInt(FindConVar("z_mob_spawn_finale_size"), AllowedMobSpawnFinale + RaidLevelCounter);

	return Plugin_Continue;
}

// int TotalHandicapLevel() {
// 	int count = 0;
// 	for (int i = 1; i <= MaxClients; i++) {
// 		if (!IsLegitimateClientAlive(i) || myCurrentTeam[i] != TEAM_SURVIVOR || IsFakeClient(i) || handicapLevel[i] < 1) continue;
// 		count += handicapLevel[i];
// 	}
// 	return count;
// }

bool IsSurvivorsHealthy() {

	for (int i = 1; i <= MaxClients; i++) {

		if (IsLegitimateClientAlive(i) && L4D2_GetInfectedAttacker(i) == -1) return true;
	}
	return false;
}

/*public Action:Timer_IsSpecialCommonInRange(Handle:timer) {
	if (!b_IsActiveRound) return Plugin_Stop;
	static commonInfected = 0;

	for (new i = 1; i <= MaxClients; i++) {
		if (!IsLegitimateClientAlive(i)) continue;
		if (myCurrentTeam[i] != TEAM_SURVIVOR) continue;
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

public Action Timer_RespawnQueue(Handle timer) {

	static Counter										=	-1;
	static TimeRemaining								=	0;
	static RandomClient									=	-1;
	static char text[64];

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

	static bool bIsHealth = false;
	bIsHealth = IsSurvivorsHealthy();

	if (!IsSurvivalMode && bIsHealth) Counter++;
	else Counter = iSurvivalCounter;
	TimeRemaining = RespawnQueue - Counter;
	if (TimeRemaining <= 0) RandomClient = FindAnyRandomClient(true);

	for (int i = 1; i <= MaxClients; i++) {

		if (!IsLegitimateClient(i) || myCurrentTeam[i] != TEAM_SURVIVOR || IsPlayerAlive(i)) continue;
		if (TimeRemaining > 0) {

			if (!IsFakeClient(i)) {

				if (bIsHealth) Format(text, sizeof(text), "%T", "respawn queue", i, TimeRemaining);
				else Format(text, sizeof(text), "%T", "respawn queue paused", i, TimeRemaining);
				PrintHintText(i, text);
			}
		}
		else if (IsLegitimateClientAlive(RandomClient)) {

			GetClientAbsOrigin(RandomClient, DeathLocation[i]);
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

stock bool IsClientSorted(client) {

	int size = GetArraySize(hThreatSort);
	//new target = -1;
	for (int i = 0; i < size; i++) {

		if (client == GetArrayCell(hThreatSort, i)) return true;
	}
	return false;
}

public Action Timer_PlayTime(Handle timer) {
	if (!b_IsActiveRound) return Plugin_Stop;
	for (int i = 1; i <= MaxClients; i++) {
		if (!IsLegitimateClient(i) || myCurrentTeam[i] == TEAM_SPECTATOR) continue;
		TimePlayed[i]++;
	}
	return Plugin_Continue;
}

stock SortThreatMeter() {

	ClearArray(hThreatSort);
	ClearArray(hThreatMeter);
	int cTopThreat = -1;
	int cTopClient = -1;
	int cTotalClients = 0;
	int size = 0;
	for (int i = 1; i <= MaxClients; i++) {

		if (!IsLegitimateClientAlive(i) || myCurrentTeam[i] != TEAM_SURVIVOR) continue;
		cTotalClients++;
	}
	while (GetArraySize(hThreatSort) < cTotalClients) {

		cTopThreat = 0;
		for (int i = 1; i <= MaxClients; i++) {

			if (!IsLegitimateClientAlive(i) || myCurrentTeam[i] != TEAM_SURVIVOR || IsClientSorted(i)) continue;
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

public Action Timer_PrecacheReset(Handle timer) {
	char cur[64];
	GetCurrentMap(cur, 64);
	ServerCommand("changelevel %s", cur);
	return Plugin_Stop;
}

public Action Timer_ResetMap(Handle timer) {
	//if (StrContains(TheCurrentMap, "helms", false) != -1) L4D_RestartScenarioFromVote(TheCurrentMap);
	if (StrContains(TheCurrentMap, "helms", false) != -1) ServerCommand("changelevel %s", TheCurrentMap);
	return Plugin_Stop;
}

public Action Timer_AutoRes(Handle timer) {
	if (b_IsCheckpointDoorStartOpened) return Plugin_Stop;
	for (int i = 1; i <= MaxClients; i++) {
		if (IsLegitimateClient(i) && myCurrentTeam[i] == TEAM_SURVIVOR) {
			if (!IsPlayerAlive(i)) SDKCall(hRoundRespawn, i);
			else if (IsIncapacitated(i)) ExecCheatCommand(i, "give", "health");
		}
	}
	return Plugin_Continue;
}

public Action Timer_Defibrillator(Handle timer, any client) {
	if (IsLegitimateClient(client) && !IsPlayerAlive(client)) {
		Defibrillator(0, client);
	}
	return Plugin_Stop;
}

stock ActiveTanks() {
	int iSurvivors = TotalHumanSurvivors();
	//new iSurvivorBots = TotalSurvivors() - iSurvivors;
	int count = GetAlwaysTanks(iSurvivors);

	for (int i = 1; i <= MaxClients; i++) {
		if (IsClientInGame(i) && myCurrentTeam[i] == TEAM_INFECTED && IsPlayerAlive(i) && FindZombieClass(i) == ZOMBIECLASS_TANK) count++;
	}
	return count;
}

stock GetWitchCount() {

	int count = 0;
	int ent = -1;
	while ((ent = FindEntityByClassname(ent, "witch")) != INVALID_ENT_REFERENCE) {

		// Some maps, like Hard Rain pre-spawn a ton of witches - we want to add them to the witch table.
		count++;
	}
	return count;
}

stock SpawnCommons(Client, Count, char[] Command, char[] Parameter, char[] Model, IsPlayerDrop, char[] SuperCommon = "none") {
	int TargetClient				=	-1;
	int CommonQueueLimit = GetCommonQueueLimit();
	if (StrEqualAtPos(Model, ".mdl", strlen(Model)-4)) {
		for (int i = Count; i > 0 && GetArraySize(CommonInfectedQueue) < CommonQueueLimit; i--) {
			if (IsPlayerDrop == 1) {
				ResizeArray(CommonInfectedQueue, GetArraySize(CommonInfectedQueue) + 1);
				ShiftArrayUp(CommonInfectedQueue, 0);
				SetArrayString(CommonInfectedQueue, 0, Model);
				TargetClient		=	FindLivingSurvivor();
				if (StrContains(SuperCommon, "-", false) == -1 && !StrEqual(SuperCommon, "none", false)) PushArrayString(SuperCommonQueue, SuperCommon);
				if (TargetClient > 0) ExecCheatCommand(TargetClient, Command, Parameter);
			}
			else PushArrayString(CommonInfectedQueue, Model);
		}
	}
}

stock FindAnotherSurvivor(client) {
	for (int i = 1; i <= MaxClients; i++) {
		if (!IsLegitimateClient(i)) continue;
		if (myCurrentTeam[i] != TEAM_SURVIVOR) continue;
		if (i == client) continue;
		return i;
	}
	return -1;
}

stock FindLivingSurvivor(bool noBOT = false) {


	/*new Client = -1;
	while (Client == -1 && LivingSurvivorCount() > 0) {

		Client = GetRandomInt(1, MaxClients);
		if (!IsClientInGame(Client) || !IsClientHuman(Client) || !IsPlayerAlive(Client) || GetClientTeam(Client) != TEAM_SURVIVOR) Client = -1;
	}
	return Client;*/
	int livingSurvivors = LivingSurvivorCount();
	for (int i = LastLivingSurvivor; i <= MaxClients && livingSurvivors > 0; i++) {

		if (IsLegitimateClientAlive(i) && myCurrentTeam[i] == TEAM_SURVIVOR) {
			if (noBOT && IsFakeClient(i)) continue;

			LastLivingSurvivor = i;
			return i;
		}
	}
	LastLivingSurvivor = 1;
	if (LivingSurvivorCount() < 1) return -1;
	return -1;
}

stock LivingSurvivorCount(ignore = -1) {

	int Count = 0;
	for (int i = 1; i <= MaxClients; i++) {

		if (IsLegitimateClientAlive(i) && myCurrentTeam[i] == TEAM_SURVIVOR && (ignore == -1 || i != ignore)) Count++;
	}
	return Count;
}

public Action Timer_SpecialAmmoData(Handle timer, any client) {

	if (!b_IsActiveRound || !IsLegitimateClient(client) || !bTimersRunning[client]) {
		return Plugin_Stop;
	}
	if (myCurrentTeam[client] != TEAM_SURVIVOR) return Plugin_Continue;
	int numOfStatusEffects = GetClientStatusEffect(client, STATUS_EFFECT_GET_TOTAL);
	CheckActiveAbility(client, -1, _, _, true);	// draws effects for any active ability this client has.
	for (int i = 0; i < GetArraySize(SpecialAmmoData); i++) {
		int dataClient = FindClientByIdNumber(GetArrayCell(SpecialAmmoData, i, 7));
		int WorldEnt = GetArrayCell(SpecialAmmoData, i, 9);
		// if (!IsLegitimateClientAlive(dataClient)) {
		// 	RemoveFromArray(Handle:SpecialAmmoData, i);
		// 	if (WorldEnt > 0 && IsValidEntity(WorldEnt)) AcceptEntityInput(WorldEnt, "Kill");
		// 	continue;
		// }

		int dataAmmoType = 0;
		int drawtarget = GetArrayCell(SpecialAmmoData, i, 11);

		float EntityPos[3];
		char TalentInfo[4][512];
		float f_TimeRemaining = 0.0;
		//new ent = -1;
		char DataAmmoEffect[10];
		//Format(DataAmmoEffect, sizeof(DataAmmoEffect), "0");	// reset it after each go.
		
		//TalentInfo[0] = TalentName of ammo.
		//TalentInfo[1] = Talent Strength (so use StringToInt)
		//TalentInfo[2] = Talent Damage
		//TalentInfo[3] = Talent Interval
		GetArrayString(a_Database_Talents, GetArrayCell(SpecialAmmoData, i, 3), TalentInfo[0], sizeof(TalentInfo[]));
		//GetTalentNameAtMenuPosition(client, GetArrayCell(SpecialAmmoData, i, 3), TalentInfo[0], sizeof(TalentInfo[]));
		GetSpecialAmmoEffect(DataAmmoEffect, sizeof(DataAmmoEffect), client, TalentInfo[0]);
		if (StrEqual(DataAmmoEffect, "x", true)) dataAmmoType = 1;
		else if (StrEqual(DataAmmoEffect, "h", true)) dataAmmoType = 2;
		else if (StrEqual(DataAmmoEffect, "F", true)) dataAmmoType = 3;
		else if (StrEqual(DataAmmoEffect, "b", true)) dataAmmoType = 4;
		else if (StrEqual(DataAmmoEffect, "a", true)) dataAmmoType = 5;
		else if (StrEqual(DataAmmoEffect, "H", true)) dataAmmoType = 6;
		else if (StrEqual(DataAmmoEffect, "B", true)) dataAmmoType = 7;
		else if (StrEqual(DataAmmoEffect, "C", true)) dataAmmoType = 8;
		
		int bulletStrength = GetArrayCell(SpecialAmmoData, i, 5);
		if (dataClient == client) {	// if this player is the owner of this spell or talent...
			int menuPos			= GetArrayCell(SpecialAmmoData, i, 3);
			if (IsSpellAnAura(client, menuPos)) {
				GetClientAbsOrigin(client, EntityPos);
				// update the location of the ammo/spell/whatever
				SetArrayCell(SpecialAmmoData, i, EntityPos[0], 0);
				SetArrayCell(SpecialAmmoData, i, EntityPos[1], 1);
				SetArrayCell(SpecialAmmoData, i, EntityPos[2], 2);
				float fVisualDelay = GetArrayCell(SpecialAmmoData, i, 13);
				fVisualDelay -= fSpecialAmmoInterval;
				if (fVisualDelay > 0.0) SetArrayCell(SpecialAmmoData, i, fVisualDelay, 13);
				else {
					SetArrayCell(SpecialAmmoData, i, GetArrayCell(SpecialAmmoData, i, 12), 13);
					for (int ii = 1; ii <= MaxClients; ii++) {
						if (!IsLegitimateClient(ii) || IsFakeClient(ii)) continue;
						DrawSpecialAmmoTarget(ii, menuPos, EntityPos[0], EntityPos[1], EntityPos[2], fSpecialAmmoInterval, client, TalentInfo[0], drawtarget);
					}
				}
			}
			else {
				EntityPos[0] = GetArrayCell(SpecialAmmoData, i, 0);
				EntityPos[1] = GetArrayCell(SpecialAmmoData, i, 1);
				EntityPos[2] = GetArrayCell(SpecialAmmoData, i, 2);
			}
			f_TimeRemaining = GetArrayCell(SpecialAmmoData, i, 8);
			f_TimeRemaining -= fSpecialAmmoInterval;
			if (f_TimeRemaining <= 0.0) {
				RemoveFromArray(SpecialAmmoData, i);
				if (WorldEnt > 0 && IsValidEntity(WorldEnt)) AcceptEntityInput(WorldEnt, "Kill");
				continue;
			}
			// Anything that was changed needs to be reinserted.
			SetArrayCell(SpecialAmmoData, i, f_TimeRemaining, 8);
			if (iStrengthOnSpawnIsStrength != 1) SetArrayCell(SpecialAmmoData, i, GetSpecialAmmoStrength(client, TalentInfo[0], 1, _, _, menuPos), 10);

			if (dataAmmoType == 1) CreateAmmoExplosion(client, EntityPos[0], EntityPos[1], EntityPos[2]);
		}
		float ammoStr = IsClientInRangeSpecialAmmo(client, DataAmmoEffect, _, _, bulletStrength);
		if (ammoStr > 0.0) {
			bool IsPlayerSameTeam = (client == dataClient || myCurrentTeam[client] == myCurrentTeam[dataClient]) ? true : false;

			float AmmoStrength			= ammoStr * bulletStrength;
			//if (AmmoStrength <= 0.0) continue;

			if (!IsPlayerSameTeam) {	// the owner of the ammo and the player inside of it are NOT on the same team.
				if (dataAmmoType == 1) ExplosiveAmmo(client, RoundToCeil(AmmoStrength), dataClient);
				else if (dataAmmoType == 2) LeechAmmo(client, RoundToCeil(AmmoStrength), dataClient);
				else if (dataAmmoType == 3) {
					if (ISEXPLODE[client] == INVALID_HANDLE) CreateAndAttachFlame(client, RoundToCeil(AmmoStrength), f_TimeRemaining, f_TimeRemaining, dataClient);
					else CreateAndAttachFlame(client, RoundToCeil(AmmoStrength * TheScorchMult), f_TimeRemaining, f_TimeRemaining, dataClient);
				}
				else if (dataAmmoType == 4) BeanBagAmmo(client, AmmoStrength, dataClient);
			}
			else {
				if (dataAmmoType == 5 && !HasAdrenaline(client)) SetAdrenalineState(client, f_TimeRemaining);
				else if (dataAmmoType == 6) HealingAmmo(client, RoundToCeil(AmmoStrength), dataClient);
				else if (dataAmmoType == 7 && !ISBILED[client]) {
					SDKCall(g_hCallVomitOnPlayer, client, dataClient, true);
					CreateTimer(20.0, Timer_RemoveBileStatus, client, TIMER_FLAG_NO_MAPCHANGE);
					ISBILED[client] = true;
				}
				else if (dataAmmoType == 8 && numOfStatusEffects > 0) RemoveClientStatusEffect(client); //TransferStatusEffect(client, dataClient);
			}
		}
	}
	return Plugin_Continue;
}

public Action Timer_StartPlayerTimers(Handle timer) {
	if (!b_IsActiveRound) return Plugin_Stop;
	for (int i = 1; i <= MaxClients; i++) {
		if (!IsLegitimateClient(i)) continue;
		if (bTimersRunning[i] || !b_IsLoaded[i]) continue;
		bTimersRunning[i] = true;
		CreateTimer(fSpecialAmmoInterval, Timer_AmmoActiveTimer, i, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
		CreateTimer(fSpecialAmmoInterval, Timer_SpecialAmmoData, i, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
		CreateTimer(fDrawHudInterval, Timer_ShowHUD, i, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
		CreateTimer(fSpecialAmmoInterval, Timer_ShowActionBar, i, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
		CreateTimer(fUpdateClientInterval, Timer_UpdateClient, i, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
	}
	return Plugin_Continue;
}

public Action Timer_UpdateClient(Handle timer, any client) {
	if (!b_IsActiveRound || !IsLegitimateClient(client)) return Plugin_Stop;
	if (myCurrentTeam[client] == TEAM_SPECTATOR) return Plugin_Continue;
	SetClientEffectState(client);
	// call ability triggers when this state changes.
	if (!bClientIsInAnyAmmo[client] && IsClientInRangeSpecialAmmoBoolean(client)) {
		bClientIsInAnyAmmo[client] = true;
		GetAbilityStrengthByTrigger(client, _, TRIGGER_enterammo, _, DataScreenWeaponDamage(client));
	}
	else if (bClientIsInAnyAmmo[client] && !IsClientInRangeSpecialAmmoBoolean(client)) {
		bClientIsInAnyAmmo[client] = false;
		GetAbilityStrengthByTrigger(client, _, TRIGGER_exitammo, _, DataScreenWeaponDamage(client));
	}
	return Plugin_Continue;
}

public Action Timer_ShowActionBar(Handle timer, any client) {
	if (!b_IsActiveRound || !IsLegitimateClient(client)) return Plugin_Stop;
	if (myCurrentTeam[client] == TEAM_SPECTATOR || IsFakeClient(client)) return Plugin_Continue;

	if (!bIsHideThreat[client]) SendPanelToClientAndClose(ShowThreatMenu(client), client, ShowThreatMenu_Init, 1); //ShowThreatMenu(i);
	else if (DisplayActionBar[client]) ShowActionBar(client);
	return Plugin_Continue;
}

public Action Timer_AmmoActiveTimer(Handle timer, any client) {

	if (!b_IsActiveRound || !IsLegitimateClient(client) || !bTimersRunning[client]) {
		bTimersRunning[client] = false;
		ClearArray(PlayerActiveAmmo[client]);
		ClearArray(PlayActiveAbilities[client]);
		ClearArray(playerLootOnGround[client]);
		return Plugin_Stop;
	}
	if (myCurrentTeam[client] != TEAM_SURVIVOR) return Plugin_Continue;
	bHasWeakness[client] = PlayerHasWeakness(client);
	//SortThreatMeter();
	char result[64];
	//new currTalentStrength = 0;
	float talentTimeRemaining = 0.0;
	int triggerRequirementsAreMet = 0;
	if (bJumpTime[client]) JumpTime[client] += fSpecialAmmoInterval;
	// if (!IsFakeClient(client)) {
	// 	if (!bIsHideThreat[client]) SendPanelToClientAndClose(ShowThreatMenu(client), client, ShowThreatMenu_Init, 1); //ShowThreatMenu(i);
	// 	else if (DisplayActionBar[client]) ShowActionBar(client);
	// }
	// timer for the cooldowns of anything on the action bar (ammos, abilities)
	int size = GetArraySize(PlayerActiveAmmo[client]);
	if (size > 0) {
		for (int i = 0; i < size; i++) {
			talentTimeRemaining = GetArrayCell(PlayerActiveAmmo[client], i, 1);
			if (talentTimeRemaining - fSpecialAmmoInterval <= 0.0) {
				RemoveFromArray(PlayerActiveAmmo[client], i);
				size--;
				if (i > 0) i--;
				continue;
			}
			SetArrayCell(PlayerActiveAmmo[client], i, talentTimeRemaining - fSpecialAmmoInterval, 1);
		}
	}
	size = GetArraySize(PlayActiveAbilities[client]);
	for (int i = 0; i < size; i++) {
		GetArrayString(a_Database_Talents, GetArrayCell(PlayActiveAbilities[client], i, 0), result, sizeof(result));
		int menuPos = GetMenuPosition(client, result);
		int talentPositionInUnlockedList = FindListPositionByEntity(menuPos, MyUnlockedTalents[client]);
		talentTimeRemaining = GetArrayCell(PlayActiveAbilities[client], i, 1);
		triggerRequirementsAreMet = GetArrayCell(PlayActiveAbilities[client], i, 2);
		if (triggerRequirementsAreMet == 1 && talentPositionInUnlockedList >= 0 && !IsAbilityActive(client, result, _, _, menuPos) && IsAbilityActive(client, result, fSpecialAmmoInterval, _, menuPos)) {
			CallAbilityCooldownAbilityTrigger(client, menuPos, true, talentPositionInUnlockedList);
		}
		if (talentTimeRemaining - fSpecialAmmoInterval < 0.0) {
			if (triggerRequirementsAreMet == 1 && talentPositionInUnlockedList >= 0) CallAbilityCooldownAbilityTrigger(client, menuPos, _, talentPositionInUnlockedList);
			RemoveFromArray(PlayActiveAbilities[client], i);
			size--;
			if (i > 0) i--;	// all the data shifts down by 1 when we remove an ability, so if we can shift i down by 1, we do.
		}
		else {
			SetArrayCell(PlayActiveAbilities[client], i, talentTimeRemaining - fSpecialAmmoInterval, 1);
		}
	}
	return Plugin_Continue;
}

public Action Timer_RemoveDamageImmunity(Handle timer, any client) {
	if (IsLegitimateClient(client)) ImmuneToAllDamage[client] = false;
	return Plugin_Stop;
}

public Action Timer_ForcedThreat(Handle timer, any client) {

	if (IsLegitimateClient(client)) {

		ClientActiveStance[client] = 0;
		if(iChaseEnt[client] > 0 && IsValidEntity(iChaseEnt[client])) AcceptEntityInput(iChaseEnt[client], "Kill");
		iChaseEnt[client] = -1;
	}
	return Plugin_Stop;
}

public Action Timer_RemoveCooldown(Handle timer, Handle packi) {

	ResetPack(packi);
	int client				=	ReadPackCell(packi);
	int pos					=	ReadPackCell(packi);

	if (IsLegitimateClient(client)) {
		int size = GetArraySize(a_Database_Talents);
		if (GetArraySize(PlayerAbilitiesCooldown[client]) != size) ResizeArray(PlayerAbilitiesCooldown[client], size);
		SetArrayCell(PlayerAbilitiesCooldown[client], pos, 0);
	}
	return Plugin_Stop;
}

public Action Timer_RemoveActiveCooldown(Handle timer, Handle packi) {

	ResetPack(packi);
	int client				=	ReadPackCell(packi);
	int pos					=	ReadPackCell(packi);

	if (IsLegitimateClient(client)) {
		int size = GetArraySize(a_Database_Talents);
		if (GetArraySize(PlayerActiveAbilitiesCooldown[client]) != size) ResizeArray(PlayerActiveAbilitiesCooldown[client], size);
		SetArrayCell(PlayerActiveAbilitiesCooldown[client], pos, 0);
	}
	return Plugin_Stop;
}

public Action Timer_DeleteLootBag(Handle timer, any entity) {
	if (!b_IsActiveRound) return Plugin_Stop;
	if (!IsValidEntity(entity) || entity < 1) return Plugin_Stop;

	char text[512];
	GetEntPropString(entity, Prop_Data, "m_iName", text, sizeof(text));
	if (!StrBeginsWith(text, "loot")) return Plugin_Stop;
	AcceptEntityInput(entity, "Kill");	// delete the loot bag.
	for (int i = 1; i <= MaxClients; i++) {
		if (!IsLegitimateClient(i) || IsFakeClient(i)) continue;
		char key[64];
		GetClientAuthId(i, AuthId_Steam2, key, 64);
		if (StrContains(text, key) == -1) continue;

		int lootBagPosition = thisAugmentArrayPos(i, StringToInt(text[FindDelim(text, "+")]));
		if (lootBagPosition >= 0) RemoveFromArray(playerLootOnGround[i], lootBagPosition);
		break;
	}
	return Plugin_Stop;
}