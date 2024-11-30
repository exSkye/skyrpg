/* put the line below after all of the includes!
#pragma newdecls required
*/

stock GetPrestigeLevelNodeUnlocks(level) {
	if (iSkyLevelNodeUnlocks > 0) return iSkyLevelNodeUnlocks;
	return level;
}

stock DoBurn(attacker, victim, baseWeaponDamage, bool isAoE = false) {
	//if (iTankRush == 1 && FindZombieClass(victim) == ZOMBIECLASS_TANK) return;
	bool IsLegitimateClientVictim = IsLegitimateClientAlive(victim);
	if (IsLegitimateClientVictim) {
		bIsBurnCooldown[victim] = true;
		CreateTimer(1.0, Timer_ResetBurnImmunity, victim, TIMER_FLAG_NO_MAPCHANGE);
	}
 	int hAttacker = attacker;
 	if (!IsLegitimateClient(hAttacker)) hAttacker = -1;
	bool IsCommonInfectedVictim = IsCommonInfected(victim);
 	if (IsCommonInfectedVictim || IsWitch(victim) && !(GetEntityFlags(victim) & FL_ONFIRE)) {
		if (IsCommonInfectedVictim) {
			if (!IsSpecialCommon(victim)) RemoveCommonInfected(victim);
			else AddSpecialCommonDamage(attacker, victim, baseWeaponDamage, true);
		}
		else {
			AddWitchDamage(attacker, victim, baseWeaponDamage, true);
		}
	}
 	if (IsLegitimateClientVictim && GetClientStatusEffect(victim, STATUS_EFFECT_BURN) < iDebuffLimit) {
		if (ISEXPLODE[victim] == INVALID_HANDLE) CreateAndAttachFlame(victim, RoundToCeil(baseWeaponDamage * TheInfernoMult), 10.0, 0.5, hAttacker, STATUS_EFFECT_BURN);
		else CreateAndAttachFlame(victim, RoundToCeil((baseWeaponDamage * TheInfernoMult) * TheScorchMult), 10.0, 0.5, hAttacker, STATUS_EFFECT_BURN);
 	}
}

stock CreateProgressBar(client, float TheTime, bool NahDestroyItInstead=false, bool NoAdrenaline=false) {

	if (TheTime >= 1.0) {

		float fActionTimeToReduce = GetAbilityStrengthByTrigger(client, client, TRIGGER_progbarspeed, _, 0, _, _, _, 1, true);
		if (fActionTimeToReduce > 0.0) TheTime *= (1.0 - fActionTimeToReduce);
	}

	SetEntPropFloat(client, Prop_Send, "m_flProgressBarStartTime", GetGameTime());
	if (NahDestroyItInstead) SetEntPropFloat(client, Prop_Send, "m_flProgressBarDuration", 0.0);
	else {

		float TheRealTime = TheTime;
		if (!NoAdrenaline && HasAdrenaline(client)) TheRealTime *= fAdrenProgressMult;

		SetEntPropFloat(client, Prop_Send, "m_flProgressBarDuration", TheRealTime);
		UseItemTime[client] = TheRealTime + GetEngineTime();
	}
}

stock AdjustProgressBar(client, float TheTime) { SetEntPropFloat(client, Prop_Send, "m_flProgressBarDuration", TheTime); }

stock bool ActiveProgressBar(client) {

	if (GetEntPropFloat(client, Prop_Send, "m_flProgressBarDuration") <= 0.0) return false;
	return true;
}

stock Defibrillator(client, target = 0, bool IgnoreDistance = false) {
	if (target > 0 && IsLegitimateClientAlive(target)) return;
	int restore = (target == -1) ? 1 : 0;
	if (restore == 1) target = 0;
	// respawn people near the player.
	int respawntarget = 0;
	for (int i = 1; i <= MaxClients; i++) {
		if (IsLegitimateClientAlive(i) && myCurrentTeam[i] == TEAM_SURVIVOR) {
			respawntarget = i;
			break;
		}
	}
	float Origin[3];
	if (client > 0) GetClientAbsOrigin(client, Origin);
	// target defaults to 0.
	for (int i = target; i <= MaxClients; i++) {
		if (IsLegitimateClient(i) && !IsPlayerAlive(i) && myCurrentTeam[i] == TEAM_SURVIVOR && (i != client || target == 0) && i != target) {
			if (target > 0 && i != target) continue;
			if (target == 0 && b_HasDeathLocation[i] && (IgnoreDistance || GetVectorDistance(Origin, DeathLocation[i]) < 256.0)) {
				if (restore == 1) {
					int oldrating = GetArrayCell(tempStorage, i, 0);
					int oldhandicap = GetArrayCell(tempStorage, i, 1);
					float oldmultiplier = GetArrayCell(tempStorage, i, 2);
					Rating[i] = oldrating;
					handicapLevel[i] = oldhandicap;
					RoundExperienceMultiplier[i] = oldmultiplier;
				}
				PrintToChatAll("%t", "rise again", white, orange, white);
				RespawnImmunity[i] = true;
				MyRespawnTarget[i] = i;
				SDKCall(hRoundRespawn, i);
				CreateTimer(0.1, Timer_TeleportRespawn, i, TIMER_FLAG_NO_MAPCHANGE);
				CreateTimer(3.0, Timer_ImmunityExpiration, i, TIMER_FLAG_NO_MAPCHANGE);
			}
			else if (target == 0 && !b_HasDeathLocation[i] && IsLegitimateClientAlive(respawntarget)) {
				SDKCall(hRoundRespawn, i);
				RespawnImmunity[i] = true;
				MyRespawnTarget[i] = respawntarget;
				CreateTimer(0.1, Timer_TeleportRespawn, i, TIMER_FLAG_NO_MAPCHANGE);
				CreateTimer(3.0, Timer_ImmunityExpiration, i, TIMER_FLAG_NO_MAPCHANGE);
			}
			//SDKCall(hRoundRespawn, i);
			//if (client > 0) LastDeathTime[i] = GetEngineTime() + StringToFloat(GetConfigValue("death weakness time?"));
			//b_HasDeathLocation[i] = false;
		}
	}
}

stock void InventoryItem(client, char[] EntityName = "none", bool bIsPickup = false, int entity = -1) {

	char ItemName[64];

	int ExplodeCount = GetDelimiterCount(EntityName, ":");
	char[][] Classname = new char[ExplodeCount][64];
	ExplodeString(EntityName, ":", Classname, ExplodeCount, 64);

	if (bIsPickup) {	// Picking up the entity. We store it in the users inventory.

		GetEntityClassname(entity, Classname[0], 64);
		GetEntPropString(entity, Prop_Data, "m_iName", ItemName, sizeof(ItemName));
	}
	else {		// Creating the entity. Defaults to -1

		entity	= CreateEntityByName(Classname[0]);
		if (!IsValidEntityEx(entity)) return;
		DispatchKeyValue(entity, "targetname", Classname[1]);
		DispatchKeyValue(entity, "rendermode", "5");
		DispatchKeyValue(entity, "spawnflags", "0");
		DispatchSpawn(entity);
		//TeleportEntity(entity, loc, NULL_VECTOR, NULL_VECTOR);
	}
}

stock bool IsCommonStaggered(client) {
	//decl String:clientId[2][64];
	//decl String:text[64];
	//static Float:timeRemaining = 0.0;
	for (int i = 0; i < GetArraySize(StaggeredTargets); i++) {
		//GetArrayString(StaggeredTargets, i, text, sizeof(text));
		//ExplodeString(text, ":", clientId, 2, 64);
		if (GetArrayCell(StaggeredTargets, i, 0) == client) return true;
		//if (StringToInt(clientId[0]) == client) return true;
	}
	return false;
}

stock EntityWasStaggered(victim, attacker = 0) {
	bool bIsLegitimateAttacker = IsLegitimateClient(attacker);
	bool bIsLegitimateVictim = IsLegitimateClient(victim);
	int attackerTeam = (bIsLegitimateAttacker) ? myCurrentTeam[attacker] : 0;
	int victimTeam = (bIsLegitimateVictim) ? myCurrentTeam[victim] : 0;
	if (bIsLegitimateAttacker && (!bIsLegitimateVictim || victimTeam != attackerTeam)) GetAbilityStrengthByTrigger(attacker, victim, TRIGGER_didStagger);
	if (bIsLegitimateVictim && (!bIsLegitimateAttacker || attackerTeam != victimTeam)) GetAbilityStrengthByTrigger(victim, attacker, TRIGGER_wasStagger);
}

public Action Timer_ResetStaggerCooldownOnTriggers(Handle timer, any client) {
	if (IsLegitimateClient(client)) staggerCooldownOnTriggers[client] = false;
	return Plugin_Stop;
}

// bool AllLivingSurvivorsInCheckpoint() {
// 	for (int i = 1; i <= MaxClients; i++) {
// 		if (!IsLegitimateClientAlive(i)) continue;
// 		if (GetClientTeam(i) != TEAM_SURVIVOR) continue;
// 		if (!bIsInCheckpoint[i]) return false;
// 	}
// 	return true;
// }

//void GetClientWeap

stock bool AnyTanksInExistence() {
	for (int i = 1; i <= MaxClients; i++) {
		if (!IsLegitimateClient(i) || myCurrentTeam[i] != TEAM_INFECTED) continue;
		if (FindZombieClass(i) == ZOMBIECLASS_TANK) return true;
	}
	return false;
}

stock bool IsPlayerOnGroundOutsideOfTankZone(tank) {
	float fTankPos[3];
	float fClientPos[3];
	GetClientAbsOrigin(tank, fTankPos);
	for (int i = 1; i <= MaxClients; i++) {
		if (!IsLegitimateClient(i)) continue;	// only player clients allowed.
		if (myCurrentTeam[i] != TEAM_SURVIVOR) continue;	// only survivors.
		if (!(GetEntityFlags(i) & FL_ONGROUND)) continue;	// only players with feet on the ground.
		GetClientAbsOrigin(i, fClientPos);
		if (HeightDifference(fClientPos[2], fTankPos[2]) >= fTeleportTankHeightDistance) {
			// teleport tank to survivor.
			TeleportEntity(tank, fClientPos, NULL_VECTOR, NULL_VECTOR);
			return true;
		}
	}
	return false;
}

stock float HeightDifference(float clientZ, float tankZ) {
	if (clientZ == tankZ) return 0.0;
	float fDistance = clientZ - tankZ;
	if (fDistance < 0.0) fDistance *= 1.0;	// distance should not be able to reach negatives using this algorithm
	return fDistance;
}

stock ToggleJetpack(client, DisableJetpack = false) {
	if (iJetpackEnabled != 1) return;

	float ClientPos[3];
	GetClientAbsOrigin(client, ClientPos);
	if (!DisableJetpack && !bJetpack[client] && !AnyTanksInExistence()) {

		EmitSoundToAll(JETPACK_AUDIO, client, SNDCHAN_WEAPON, SNDLEVEL_NORMAL, SND_NOFLAGS, 0.5, SNDPITCH_NORMAL, -1, ClientPos, NULL_VECTOR, true, 0.0);
		SetEntityMoveType(client, MOVETYPE_FLY);
		bJetpack[client] = true;
	}
	else if (DisableJetpack && bJetpack[client]) {

		StopSound(client, SNDCHAN_WEAPON, JETPACK_AUDIO);
		//EmitSoundToAll(JETPACK_AUDIO, client, SNDCHAN_WEAPON, SNDLEVEL_NORMAL, SND_NOFLAGS, 1.0, SNDPITCH_NORMAL, -1, ClientPos, NULL_VECTOR, true, 0.0);
		SetEntityMoveType(client, MOVETYPE_WALK);
		bJetpack[client] = false;
	}
}

stock FindCommonInfectedTargetInArray(Handle hArray, target) {
	int size = GetArraySize(hArray);
	for (int i = 0; i < size; i++) {
		if (i >= size - 1 - i) break;
		if (GetArrayCell(hArray, i) == target) return i;
		if (GetArrayCell(hArray, size - 1 - i) == target) return size-1-i;
	}
	return -1;
}

stock GetBulletOrMeleeHealAmount(healer, target, damage, damagetype, int hitgroup = -1) {
	if (damagetype & DMG_BULLET || damagetype & DMG_SLASH || damagetype & DMG_CLUB) {
		//GetBaseWeaponDamage(client, target, TargetPos[0], TargetPos[1], TargetPos[2], DMG_BULLET, _, true, hitgroup, isHealing);
		int iHealerAmount = GetBaseWeaponDamage(healer, target, _, _, _, damagetype, _, _, hitgroup, true);
		return iHealerAmount;
	}
	return 0;
}

// Curious RPG System option?
// Points earned from hurting players used to unlock abilities, while experienced earned to increase level determines which abilities a player has access to.
// This way, even if the level is different, everyone starts with the same footing.
// Optional RPG System. Maybe call it "buy rpg mode?"
stock bool SameTeam_OnTakeDamage(healer, target, damage, bool IsDamageTalent = false, int damagetype = -1, int hitgroup) {
	//if (!AllowShotgunToTriggerNodes(healer)) return false;
	//if (HealImmunity[target] ||
	if (bIsInCheckpoint[target]) return true;
	int iHealerAmount = GetBulletOrMeleeHealAmount(healer, target, damage, damagetype, hitgroup);
	if (iHealerAmount < 1) return true;
	if (iHealingPlayerInCombatPutInCombat == 1 && bIsInCombat[target]) {
		CombatTime[healer] = GetEngineTime() + fOutOfCombatTime;
		bIsInCombat[healer] = true;
	}
	if (StrContains(MyCurrentWeapon[healer], "pistol", false) == -1) GiveAmmoBack(healer, 1);
	HealPlayer(target, healer, iHealerAmount * 1.0, 'h', true);
	if (IsDamageTalent) {
		GetAbilityStrengthByTrigger(healer, target, TRIGGER_d, FindZombieClass(healer), iHealerAmount);
		if (damagetype & DMG_CLUB) GetAbilityStrengthByTrigger(healer, target, TRIGGER_U, _, iHealerAmount);
		if (damagetype & DMG_SLASH) GetAbilityStrengthByTrigger(healer, target, TRIGGER_u, _, iHealerAmount);
	}
	if (LastAttackedUser[healer] == target) ConsecutiveHits[healer]++;
	else {
		LastAttackedUser[healer] = target;
		ConsecutiveHits[healer] = 0;
	}
	return true;
}
