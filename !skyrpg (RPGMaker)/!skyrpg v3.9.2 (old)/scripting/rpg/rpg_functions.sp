/*
 *	Provides a shortcut method to calling ANY value from keys found in CONFIGS/READYUP/RPG/CONFIG.CFG
 *	@return		-1		if the requested key could not be found.
 *	@return		value	if the requested key is found.
 */
stock String:GetConfigValue(String:KeyName[]) {
	
	decl String:text[512];

	new a_Size			= GetArraySize(MainKeys);

	for (new i = 0; i < a_Size; i++) {

		GetArrayString(Handle:MainKeys, i, text, sizeof(text));

		if (StrEqual(text, KeyName)) {

			GetArrayString(Handle:MainValues, i, text, sizeof(text));
			return text;
		}
	}

	Format(text, sizeof(text), "-1");

	return text;
}

/*
 *	Checks if any non-bot survivors are incapacitated.
 *	@return		true/false		depending on the result.
 */
stock bool:AnySurvivorsIncapacitated() {

	for (new i = 1; i <= MaxClients; i++) {

		if (IsClientInGame(i) && !IsFakeClient(i) && GetClientTeam(i) == TEAM_SURVIVOR && IsIncapacitated(i)) return true;
	}
	return false;
}

/*
 *	Checks if there are any non-bot, non-spectator players in the game.
 *	@return		true/false		depending on the result.
 */
stock bool:IsPlayersParticipating() {

	for (new i = 1; i <= MaxClients; i++) {

		if (IsLegitimateClient(i) && !IsFakeClient(i) && GetClientTeam(i) != TEAM_SPECTATOR) return true;
	}
	return false;
}

/*
 *	Finds a random, non-bot client in-game.
 *	@return		client index if found.
 *	@return		-1 if not found.
 */
stock FindAnyRandomClient() {

	for (new i = 1; i <= MaxClients; i++) {

		if (IsClientInGame(i) && !IsFakeClient(i)) return i;
	}
	return -1;
}

stock bool:IsMeleeWeaponParameter(String:parameter[]) {

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

stock GetMeleeWeaponDamage(attacker, victim, String:weapon[]) {

	new zombieclass				= FindZombieClass(victim);
	new size					= GetArraySize(a_Melee_Damage);
	new healthvalue				= 0;

	decl String:s_zombieclass[4];

	for (new i = 0; i < size; i++) {

		MeleeKeys[attacker]		= GetArrayCell(a_Melee_Damage, i, 0);
		MeleeValues[attacker]	= GetArrayCell(a_Melee_Damage, i, 1);
		MeleeSection[attacker]	= GetArrayCell(a_Melee_Damage, i, 2);

		GetArrayString(Handle:MeleeSection[attacker], 0, s_zombieclass, sizeof(s_zombieclass));
		if (StringToInt(s_zombieclass) == zombieclass) {

			healthvalue			= RoundToCeil(StringToFloat(GetKeyValue(MeleeKeys[attacker], MeleeValues[attacker], weapon)) * GetMaximumHealth(victim));
			if (healthvalue > GetClientTotalHealth(victim)) healthvalue		= GetClientTotalHealth(victim);
			return healthvalue;
		}
	}
	return 0;
}

/*
 *	Checks to see if the client has an active experience booster.
 *	If the client does, ExperienceValue is multiplied against the booster value and returned.
 *	@return (ExperienceValue * Multiplier)		where Multiplier is modified based on the result of AddMultiplier(client, i)
 */
stock Float:CheckExperienceBooster(client, ExperienceValue) {

	// Return ExperienceValue as it is if the client doesn't have a booster active.
	decl String:key[64];
	decl String:value[64];

	new Float:Multiplier					= 0.0;	// 1.0 is the DEFAULT (Meaning NO CHANGE)

	new size								= GetArraySize(a_Store);
	new size2								= 0;
	for (new i = 0; i < size; i++) {

		StoreKeys[client]					= GetArrayCell(a_Store, i, 0);
		StoreValues[client]					= GetArrayCell(a_Store, i, 1);

		size2								= GetArraySize(StoreKeys[client]);
		for (new ii = 0; ii < size2; ii++) {

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
stock Float:AddMultiplier(client, pos) {

	if (!IsLegitimateClient(client) || pos >= GetArraySize(a_Store_Player[client])) return 0.0;
	decl String:ClientValue[64];
	GetArrayString(a_Store_Player[client], pos, ClientValue, sizeof(ClientValue));

	decl String:key[64];
	decl String:value[64];

	if (StringToInt(ClientValue) > 0) {

		StoreMultiplierKeys[client]			= GetArrayCell(a_Store, pos, 0);
		StoreMultiplierValues[client]		= GetArrayCell(a_Store, pos, 1);

		new size							= GetArraySize(StoreMultiplierKeys[client]);
		for (new i = 0; i < size; i++) {

			GetArrayString(StoreMultiplierKeys[client], i, key, sizeof(key));
			GetArrayString(StoreMultiplierValues[client], i, value, sizeof(value));

			if (StrEqual(key, "item strength?")) return StringToFloat(value);
		}
	}

	return 0.0;		// It wasn't found, so no multiplier is added.
}

stock GetBaseWeaponDamage(client, target) {

	decl String:WeaponName[64];
	decl String:Weapon[64];
	new WeaponId = -1;
	new g_iActiveWeaponOffset = 0;
	new iWeapon = 0;
	GetClientWeapon(client, Weapon, sizeof(Weapon));
	if (StrEqual(Weapon, "weapon_melee", false)) {

		g_iActiveWeaponOffset = FindSendPropInfo("CTerrorPlayer", "m_hActiveWeapon");
		iWeapon = GetEntDataEnt2(client, g_iActiveWeaponOffset);
		GetEdictClassname(iWeapon, Weapon, sizeof(Weapon));
		GetEntPropString(iWeapon, Prop_Data, "m_strMapSetScriptName", Weapon, sizeof(Weapon));
	}
	else if (StrContains(Weapon, "weapon_", false) != -1) {

		if (StrContains(Weapon, "pistol", false) == -1) WeaponId = GetPlayerWeaponSlot(client, 0);
		else WeaponId = GetPlayerWeaponSlot(client, 1);
		if (IsValidEdict(WeaponId)) GetEdictClassname(WeaponId, Weapon, sizeof(Weapon));
		else return -1;
	}

	new WeaponDamage = 0;
	new Float:WeaponRange = 0.0;
	new Float:WeaponDamageRangePenalty = 0.0;
	new Float:RangeRequired = 0.0;

	new Float:cpos[3];
	new Float:tpos[3];
	GetClientAbsOrigin(client, cpos);
	if (!IsWitch(target) && !IsSpecialCommon(target) && !IsCommonInfected(target)) GetClientAbsOrigin(target, tpos);
	else GetEntPropVector(target, Prop_Send, "m_vecOrigin", tpos);
	new Float:Distance = GetVectorDistance(cpos, tpos);
	//PrintToChat(client, "Distance: %3.3f", Distance);

	new size = GetArraySize(a_WeaponDamages);
	for (new i = 0; i < size; i++) {

		DamageKeys[client] = GetArrayCell(a_WeaponDamages, i, 0);
		DamageValues[client] = GetArrayCell(a_WeaponDamages, i, 1);
		DamageSection[client] = GetArrayCell(a_WeaponDamages, i, 2);
		GetArrayString(Handle:DamageSection[client], 0, WeaponName, sizeof(WeaponName));
		if (!StrEqual(WeaponName, Weapon, false)) continue;
		WeaponDamage = StringToInt(GetKeyValue(DamageKeys[client], DamageValues[client], "damage"));
		WeaponRange = StringToFloat(GetKeyValue(DamageKeys[client], DamageValues[client], "range"));
		RangeRequired = StringToFloat(GetKeyValue(DamageKeys[client], DamageValues[client], "range required?"));
		if (Distance > WeaponRange && WeaponRange > 0.0) {

			/*

				In order to balance weapons and prevent one weapon from being the all-powerful go-to choice
				a weapon fall-off range is introduced.
				The amount of damage when receiving this penalty is equal to
				RoundToCeil(((Distance - WeaponRange) / WeaponRange) * damage);

				We subtract this value from overall damage.

				Some weapons (like certain sniper rifles) may not have a fall-off range.
			*/
			WeaponDamageRangePenalty = 1.0 - ((Distance - WeaponRange) / WeaponRange);
			WeaponDamage = RoundToCeil(WeaponDamage * WeaponDamageRangePenalty);
			if (WeaponDamage < 1) WeaponDamage = 1;		// If you're double the range or greater, congrats, bb gun.
		}
		if (Distance <= RangeRequired && RangeRequired > 0.0) {

			WeaponDamageRangePenalty = 1.0 - ((RangeRequired - Distance) / RangeRequired);
			WeaponDamage = RoundToCeil(WeaponDamage * WeaponDamageRangePenalty);
			if (WeaponDamage < 1) WeaponDamage = 1;
		}
		//LogToFile(LogPathDirectory, "%s Damage: %d", Weapon, WeaponDamage);
		//LogToFile(LogPathDirectory, "%N will deal %d damage", client, WeaponDamage);
		return WeaponDamage;
	}
	//LogToFile(LogPathDirectory, "Could not find header for %s", Weapon);
	return 0;
}

stock CheckFallDamage(victim) {

	new Float:clientVel[3];
	Entity_GetAbsVelocity(victim, clientVel);
	//if (clientVel[2] == 0.0) IncapacitateOrKill(victim, _, _, true);
	//else {
	if (clientVel[2] != 0.0) {

		if (clientVel[2] < 0.0) clientVel[2] *= -0.01;
		clientVel[2] *= 0.025;
	}
	//PrintToChat(victim, "Vel: %3.3f", clientVel[2]);

	if (GetClientHealth(victim) > RoundToCeil(GetMaximumHealth(victim) * clientVel[2])) SetEntityHealth(victim, GetClientHealth(victim) - RoundToCeil(GetMaximumHealth(victim) * clientVel[2]));
	else IncapacitateOrKill(victim, _, _, true);
}

stock bool:IsFireDamage(damagetype) {

	if (damagetype == 8 || damagetype == 2056 || damagetype == 268435464) return true;
	return false;
}

/*
 *	SDKHooks function.
 *	We're using it to prevent any melee damage, due to the bizarre way that melee damage is handled, it's hit or miss whether it is changed.
 *	@return Plugin_Changed		if a melee weapon was used.
 *	@return Plugin_Continue		if a melee weapon was not used.
 */

public Action:OnTakeDamage(victim, &attacker, &inflictor, &Float:damage, &damagetype) {

	if (!b_IsActiveRound) return Plugin_Continue;
	//if (IsSpecialCommon(victim)) PrintToChatAll("Damage type: %d", damagetype);

	if (IsCommonInfected(victim) || IsWitch(victim) || (IsLegitimateClientAlive(victim) && GetClientTeam(victim) == TEAM_INFECTED)) {

		if (IsSpecialCommonInRange(victim, 't')) {

			/*

				If a defender is in range of a special, common, or witch, the damage is 0.
			*/
			damage = 0.0;
			return Plugin_Handled;
		}
	}
	if (IsSpecialCommon(victim) && (damagetype == 8 || damagetype == 2056 || damagetype == 268435464)) {

		damage = 0.0;
		return Plugin_Handled;
	}
	/*if (!IsSpecialCommon(victim) && IsCommonInfected(victim) && IsLegitimateClientAlive(attacker) && GetClientTeam(attacker) == TEAM_SURVIVOR) {

		CommonsKilled++;
		CommonKills[attacker]++;

		if (CommonKills[attacker] >= StringToInt(GetConfigValue("common kills award required?"))) {

			ExperienceLevel[attacker] += StringToInt(GetConfigValue("common experience award?"));
			ExperienceOverall[attacker] += StringToInt(GetConfigValue("common experience award?"));
			if (ExperienceLevel[attacker] > CheckExperienceRequirement(attacker)) {

				ExperienceOverall[attacker] -= (ExperienceLevel[attacker] - CheckExperienceRequirement(attacker));
				ExperienceLevel[attacker] = CheckExperienceRequirement(attacker);
			}
			ConfirmExperienceAction(attacker);
			if (StringToInt(GetConfigValue("display common kills award?")) == 1) PrintToChat(attacker, "%T", "common kills award", attacker, white, green, GetConfigValue("common experience award?"), white);
			CommonKills[attacker] = 0;
			if (StringToInt(GetConfigValue("hint text broadcast?")) == 1) ExperienceBarBroadcast(attacker);
		}
		FindAbilityByTrigger(attacker, 0, 'C', FindZombieClass(attacker), 0);
		if (IsLegitimateClientAlive(attacker) && !IsFakeClient(attacker) && GetClientTeam(attacker) == TEAM_SURVIVOR && IsIncapacitated(attacker)) {

			FindAbilityByTrigger(attacker, attacker, 'k', FindZombieClass(attacker), 0);
		}
		SDKUnhook(victim, SDKHook_OnTakeDamage, OnTakeDamage);
		AcceptEntityInput(victim, "Kill");
		damage = 0.0;
		return Plugin_Changed;
	}*/
	new isEntityPos = -1;
 	new t_InfectedHealth = -1;
 	new isArraySize = -1;

	if (IsLegitimateClient(attacker) && IsFakeClient(attacker) && GetClientTeam(attacker) == TEAM_SURVIVOR ||
		IsLegitimateClient(victim) && IsFakeClient(victim) && GetClientTeam(victim) == TEAM_SURVIVOR) {

		//	Survivor bots who are victims or attackers are ignored.
		return Plugin_Continue;
	}
	if (IsLegitimateClient(attacker) && !IsFakeClient(attacker) && GetClientTeam(attacker) == TEAM_SURVIVOR) b_IsDead[attacker] = false;
	if (IsLegitimateClient(victim) && !IsFakeClient(victim) && GetClientTeam(victim) == TEAM_SURVIVOR) b_IsDead[victim] = false;
	if (IsWitch(attacker) && IsLegitimateClient(victim) && !IsFakeClient(victim) && GetClientTeam(victim) == TEAM_SURVIVOR) {

		new i_WitchDamage = StringToInt(GetConfigValue("witch damage initial?"));
		//new i_WitchDamage = RoundToCeil(damage);
		ExperienceLevel_Bots += StringToInt(GetConfigValue("witch director experience?"));
		if (ExperienceLevel_Bots > CheckExperienceRequirement(-1)) ExperienceLevel_Bots = CheckExperienceRequirement(-1);
		Points_Director += (StringToFloat(GetConfigValue("witch director points?")) * LivingHumanSurvivors());
		if (StringToFloat(GetConfigValue("witch damage scale level?")) > 0.0) {

			i_WitchDamage += RoundToCeil(i_WitchDamage * (StringToFloat(GetConfigValue("witch damage scale level?")) * PlayerLevel[victim]));
		}
		if (HandicapLevel[victim] != -1) {

			new Float:fl_WitchHealthMultiplier = StringToFloat(GetConfigValue("witch damage increase?")) * HandicapLevel[victim];
			i_WitchDamage += RoundToCeil(i_WitchDamage * fl_WitchHealthMultiplier);
		}
		if (i_WitchDamage >= GetClientTotalHealth(victim)) IncapacitateOrKill(victim, attacker, i_WitchDamage);
		else SetClientTotalHealth(victim, i_WitchDamage);
		FindAbilityByTrigger(victim, attacker, 'w', FindZombieClass(victim), i_WitchDamage);
		FindAbilityByTrigger(attacker, victim, 'h', FindZombieClass(attacker), i_WitchDamage);
		ReceiveWitchDamage(victim, attacker, i_WitchDamage);
	}
	if ((attacker < 1 || !IsClientActual(attacker)) && IsLegitimateClient(victim) && !IsFakeClient(victim) && GetClientTeam(victim) == TEAM_SURVIVOR) {

		if (IsPlayerAlive(victim)) b_IsDead[victim] = false;

		for (new i = 1; i <= MaxClients; i++) {

			if (IsLegitimateClient(i) && GetClientTeam(i) != GetClientTeam(victim) && CoveredInBile[victim][i] >= 0) {

				CoveredInBile[victim][i]++;
			}
		}
		//GetEventString(event, "weapon", weapon, sizeof(weapon));

		if (IsCommonInfected(attacker)) {

			new CommonsDamage = RoundToCeil(damage);
			ExperienceLevel_Bots += StringToInt(GetConfigValue("common infected director experience?"));
			if (ExperienceLevel_Bots > CheckExperienceRequirement(-1)) ExperienceLevel_Bots = CheckExperienceRequirement(-1);
			if (!(damagetype & DMG_DIRECT)) {

				Points_Director += (StringToFloat(GetConfigValue("common infected director points?")) * LivingHumanSurvivors());
				if (b_IsJumping[victim]) ModifyGravity(victim);
							
				//new CommonsDamage = RoundToCeil(damage);
				if (StringToFloat(GetConfigValue("common damage scale level?")) > 0.0) {

					if (StringToInt(GetConfigValue("infected bot level type?")) == 0) {

						CommonsDamage = RoundToCeil(CommonsDamage * (StringToFloat(GetConfigValue("common damage scale level?")) * PlayerLevel[victim]));
					}
					else {

						CommonsDamage = RoundToCeil(CommonsDamage * (StringToFloat(GetConfigValue("common damage scale level?")) * LivingSurvivorLevels()));
					}
				}
				if (HandicapLevel[victim] != -1) {

					new Float:fl_InfectedHealthMultiplier = StringToFloat(GetConfigValue("commons damage increase?")) * HandicapLevel[victim];
					CommonsDamage += RoundToCeil(CommonsDamage * fl_InfectedHealthMultiplier);
				}
				if (L4D2_GetInfectedAttacker(victim) != -1) {

					new eInfectedAttacker = L4D2_GetInfectedAttacker(victim);

					isEntityPos = FindListPositionByEntity(eInfectedAttacker, Handle:InfectedHealth[victim]);

					if (isEntityPos < 0) {

						isArraySize = GetArraySize(Handle:InfectedHealth[victim]);
						isEntityPos = InsertInfected(victim, eInfectedAttacker);
					}
					if (isEntityPos >= 0) SetArrayCell(Handle:InfectedHealth[victim], isEntityPos, GetArrayCell(Handle:InfectedHealth[victim], isEntityPos, 3) + CommonsDamage, 3);
				}
				if (IsSpecialCommonInRange(attacker, 'b')) {

					CommonsDamage = GetSpecialCommonDamage(CommonsDamage, attacker, 'b', victim);
				}

				FindAbilityByTrigger(victim, attacker, 'Y', FindZombieClass(victim), CommonsDamage);
				if (GetClientTotalHealth(victim) > CommonsDamage) SetClientTotalHealth(victim, CommonsDamage); //SetEntityHealth(victim, GetClientHealth(victim) - CommonsDamage);
				else if (GetClientTotalHealth(victim) <= CommonsDamage) IncapacitateOrKill(victim);
				ReceiveCommonDamage(victim, attacker, CommonsDamage);
			}
			if (IsSpecialCommon(attacker)) {

				// Flamers explode when they receive or take damage.
				if (FindCharInString(GetCommonValue(attacker, "aura effect?"), 'f') != -1) {

					CreateExplosion(attacker);
					CreateDamageStatusEffect(attacker);
				}
			}
		}
		if (damagetype & DMG_FALL) CheckFallDamage(victim);
		/*if (attacker < 1) {

			// Probably worldspawn triggers. Deal crazy damage.
			// Get the current velocity of the client that is displayed
			CheckFallDamage(victim);
		}*/
		//LogToFile(LogPathDirectory, "[COMMON DAMAGE] Common hits %N for %d", victim, CommonsDamage);
	}
 	new baseWeaponDamage = 0;
 	decl String:weapon[64];
 	if (IsLegitimateClient(attacker) && GetClientTeam(attacker) == TEAM_SURVIVOR) {

 		//Someday we'll do more common infected stuff here.
 		GetClientWeapon(attacker, weapon, sizeof(weapon));
 		baseWeaponDamage = GetBaseWeaponDamage(attacker, victim);
 		if (damagetype & DMG_BLAST && !IsClientStatusEffect(victim, Handle:EntityOnFire)) {

 			//baseWeaponDamage *= 1.5;
 			CreateAndAttachFlame(victim, baseWeaponDamage, 1.0, 0.5);
 			CreateExplosion(victim, baseWeaponDamage, attacker);	// boom boom audio and effect on the location.
			//if (IsLegitimateClientAlive(victim) && !IsFakeClient(victim)) ScreenShake(victim);
		}
 		if (damagetype & DMG_DIRECT) {

 			/*

 				Due to crashes from spam, we have it so it will only create the flame on people who are not currently burning.
 			*/
 			if (IsLegitimateClientAlive(victim) && ISEXPLODE[victim] != INVALID_HANDLE && !IsClientStatusEffect(victim, Handle:EntityOnFire)) CreateAndAttachFlame(victim, RoundToCeil(baseWeaponDamage * StringToFloat(GetConfigValue("scorch multiplier?"))), 1.0, 0.5);
 			else CreateAndAttachFlame(victim, baseWeaponDamage, 1.0, 0.5);
 		}
 		if (baseWeaponDamage == -1) {

 			damage = 0.0;
 			return Plugin_Changed;
 		}
 		new LowLevelHandicap = StringToInt(GetConfigValue("low level handicap?"));
 		new Float:LowLevelWeaponDamage = StringToFloat(GetConfigValue("low level weapon damage?"));
 		if (PlayerLevel[attacker] < LowLevelHandicap) baseWeaponDamage = RoundToCeil(baseWeaponDamage * LowLevelWeaponDamage);

 		if (StrEqual(weapon, "weapon_grenade_launcher", false) || StrEqual(weapon, "grenade_launcher_projectile", false)) {

 			damage = 0.0;
 			return Plugin_Changed;
 		}
 		if (StrEqual(weapon, "melee", false) && bIsMeleeCooldown[attacker]) {

 			damage = 0.0;
 			return Plugin_Changed;
 		}
 		if (CheckKillPositions(attacker, false)) {

 			damage = 0.0;
 			return Plugin_Changed;
 		}
 	}
 	if (IsLegitimateClientAlive(victim) && IsLegitimateClientAlive(attacker) && GetClientTeam(victim) == GetClientTeam(attacker)) {

		FindAbilityByTrigger(attacker, victim, 'd', FindZombieClass(attacker), baseWeaponDamage);
		FindAbilityByTrigger(victim, attacker, 'l', FindZombieClass(victim), baseWeaponDamage);
	}
 	if (IsLegitimateClient(attacker) && GetClientTeam(attacker) == TEAM_INFECTED && IsLegitimateClient(victim) && GetClientTeam(victim) == TEAM_SURVIVOR && !(damagetype & DMG_DIRECT)) {

 		if (b_IsJumping[victim]) ModifyGravity(victim);
		new totalIncomingDamage = RoundToCeil(damage);
				
		//Incoming Damage is calculated a very specific way, so that handicap is always the final calculation.
		decl String:idpLevel[64];
		Format(idpLevel, sizeof(idpLevel), "(%d) damage player level?", FindZombieClass(attacker));
		if (StringToInt(GetConfigValue("infected bot level type?")) == 1) {

			totalIncomingDamage += RoundToFloor(totalIncomingDamage * (LivingSurvivorLevels() * StringToFloat(GetConfigValue(idpLevel))));
		}
		else {

			totalIncomingDamage += RoundToFloor(totalIncomingDamage * (PlayerLevel[victim] * StringToFloat(GetConfigValue(idpLevel))));
		}

		decl String:s_findZombie[64];
		if (HandicapLevel[victim] != -1) {

			Format(s_findZombie, sizeof(s_findZombie), "(%d) damage increase?", FindZombieClass(attacker));
			new Float:f_InfectedHealthMultiplier = StringToFloat(GetConfigValue(s_findZombie)) * HandicapLevel[victim];
			totalIncomingDamage += RoundToCeil(totalIncomingDamage * f_InfectedHealthMultiplier);
		}
		//LogToFile(LogPathDirectory, "[INFECTED DAMAGE] %N hits %N for %d", attacker, victim, totalIncomingDamage);

		if (totalIncomingDamage >= GetClientTotalHealth(victim)) IncapacitateOrKill(victim, attacker, totalIncomingDamage);
		else SetClientTotalHealth(victim, totalIncomingDamage);
		RoundDamageTotal += totalIncomingDamage;
		RoundDamage[attacker] += totalIncomingDamage;
		//DamageAward[attacker][victim] += totalIncomingDamage;
		if (IsFakeClient(attacker)) {

			Points_Director += (totalIncomingDamage * StringToFloat(GetConfigValue("points multiplier infected?")));
			ExperienceLevel_Bots += RoundToCeil(totalIncomingDamage * StringToFloat(GetConfigValue("experience multiplier infected?")));
			if (ExperienceLevel_Bots > CheckExperienceRequirement(-1)) ExperienceLevel_Bots = CheckExperienceRequirement(-1);
		}

		if (L4D2_GetSurvivorVictim(attacker) != -1) FindAbilityByTrigger(attacker, L4D2_GetSurvivorVictim(attacker), 'v', FindZombieClass(attacker), totalIncomingDamage);
		if (StrEqual(weapon, "insect_swarm")) FindAbilityByTrigger(attacker, victim, 'T', FindZombieClass(attacker), totalIncomingDamage);
		FindAbilityByTrigger(attacker, victim, 'D', FindZombieClass(attacker), totalIncomingDamage);
		FindAbilityByTrigger(victim, attacker, 'L', FindZombieClass(victim), totalIncomingDamage);
		if (L4D2_GetInfectedAttacker(victim) == attacker) FindAbilityByTrigger(victim, attacker, 's', FindZombieClass(victim), totalIncomingDamage);
		if (L4D2_GetInfectedAttacker(victim) != -1 && L4D2_GetInfectedAttacker(victim) != attacker) {

			// If the infected player dealing the damage isn't the player hurting the victim, we give the victim a chance to strike at both! This is balance!
			FindAbilityByTrigger(victim, L4D2_GetInfectedAttacker(victim), 'V', FindZombieClass(victim), totalIncomingDamage);
			if (attacker != L4D2_GetInfectedAttacker(victim)) FindAbilityByTrigger(victim, attacker, 'V', FindZombieClass(victim), totalIncomingDamage);
		}
		//PrintToChat(victim, "Damage: %d", totalIncomingDamage);

		isEntityPos = FindListPositionByEntity(attacker, Handle:InfectedHealth[victim]);

		if (isEntityPos < 0) {

			isArraySize = GetArraySize(Handle:InfectedHealth[victim]);
			isEntityPos = InsertInfected(victim, attacker);
		}
		if (isEntityPos >= 0) SetArrayCell(Handle:InfectedHealth[victim], isEntityPos, GetArrayCell(Handle:InfectedHealth[victim], isEntityPos, 3) + totalIncomingDamage, 3);
	}
 	else if (IsLegitimateClient(attacker) && GetClientTeam(attacker) == TEAM_SURVIVOR && !(damagetype & DMG_DIRECT) && (IsLegitimateClient(victim) || IsWitch(victim) || IsSpecialCommon(victim) || IsCommonInfected(victim))) {

 		if (IsWitch(victim) || IsSpecialCommon(victim) || IsCommonInfected(victim)) {

 			decl String:ModelName[64];
 			Format(ModelName, sizeof(ModelName), "-1");
 			if (!IsSpecialCommon(victim) && IsCommonInfected(victim)) {

 				GetEntPropString(victim, Prop_Data, "m_ModelName", ModelName, sizeof(ModelName));
 			}

	 		Format(weapon, sizeof(weapon), "%s", FindPlayerWeapon(attacker));
			if (!StrEqual(weapon, "melee", false) || !bIsMeleeCooldown[attacker]) {

				/*if (!StrEqual(ModelName, "-1", false)) {

					if (!StrEqual(weapon, "melee", false) && StrContains(ModelName, "jimmy", false) != -1) baseWeaponDamage = 1;	// If you shoot a jimmy gibbs with a weapon, it deals 1 damage. Melee is required!
					else if (StrEqual(weapon, "melee", false) && StrContains(ModelName, "jimmy", false) != -1) {

						OnCommonInfectedCreated(victim, true);
					}
					if (StrEqual(weapon, "melee", false) && StrContains(ModelName, "riot", false) != -1) baseWeaponDamage = 1;		// If you hit a riot cop with a melee weapon, it deals 1 damage. They must be shot!
					else if (!StrEqual(weapon, "melee", false) && StrContains(ModelName, "riot", false) != -1) {

						OnCommonInfectedCreated(victim, true);
					}
				}*/
				if (StrEqual(weapon, "melee", false)) {

					bIsMeleeCooldown[attacker] = true;				
					CreateTimer(0.3, Timer_IsMeleeCooldown, attacker, TIMER_FLAG_NO_MAPCHANGE);
					FindAbilityByTrigger(attacker, victim, 'b', FindZombieClass(attacker), baseWeaponDamage);	// striking a player with a melee weapon
					FindAbilityByTrigger(victim, attacker, 'B', FindZombieClass(victim), baseWeaponDamage);	// being struck by a melee weapon
				}
				FindAbilityByTrigger(attacker, victim, 'D', FindZombieClass(attacker), baseWeaponDamage);
				FindAbilityByTrigger(victim, attacker, 'L', FindZombieClass(victim), baseWeaponDamage);
				//LogToFile(LogPathDirectory, "%N (%s) damages WITCH for %d (Total %d)", attacker, weapon, baseWeaponDamage, baseWeaponDamage);
				if (IsWitch(victim)) {

					if (FindListPositionByEntity(victim, Handle:WitchList) >= 0) AddWitchDamage(attacker, victim, baseWeaponDamage);
					else OnWitchCreated(victim, true);
				}
				else if (IsSpecialCommon(victim)) AddSpecialCommonDamage(attacker, victim, baseWeaponDamage);
				else if (IsCommonInfected(victim)) AddCommonInfectedDamage(attacker, victim, baseWeaponDamage);
				if (StringToInt(GetConfigValue("display health bars?")) == 1) {

					DisplayInfectedHealthBars(attacker, victim);
				}
				if (CheckTeammateDamages(victim, attacker) >= 1.0 ||
					CheckTeammateDamages(victim, attacker, true) >= 1.0 ||
					CheckTeammateDamages(victim, attacker) < 0.0 ||
					CheckTeammateDamages(victim, attacker, true) < 0.0) {

					if (IsWitch(victim)) OnWitchCreated(victim, true);
					else if (IsSpecialCommon(victim)) {

						ClearSpecialCommon(victim);
					}
					else if (IsCommonInfected(victim)) {

						OnCommonInfectedCreated(victim, true);
					}
				}
				else {

					/*

							So the player / common took damage.
					*/
					if (IsSpecialCommon(victim)) {

						// The bomber explosion initially targets itself so that the chain-reaction (if enabled) doesn't go indefinitely.
						if (FindCharInString(GetCommonValue(victim, "damage effect?"), 'f') != -1) {

							CreateExplosion(victim);
							CreateDamageStatusEffect(victim);
						}
						if (FindCharInString(GetCommonValue(victim, "damage effect?"), 'd') != -1) {

							CreateDamageStatusEffect(victim, 3, attacker, baseWeaponDamage);		// attacker is not target but just used to pass for reference.
						}
					}
					else if (IsCommonInfected(victim) && (damagetype & DMG_HEADSHOT)) OnCommonInfectedCreated(victim, true);
				}
			}
		}
		else if (IsLegitimateClient(victim) && GetClientTeam(victim) == TEAM_INFECTED) {

			if (L4D2_GetSurvivorVictim(victim) != -1) FindAbilityByTrigger(victim, attacker, 't', FindZombieClass(victim), baseWeaponDamage);

			if (StrContains(weapon, "molotov", false) == -1 && IsPlayerAlive(victim) &&
				!RestrictedWeaponList(weapon)) {

				//LogToFile(LogPathDirectory, "Damage type is %i and weapon is %s (%N)", damagetype, weapon, attacker);

				if (StrEqual(weapon, "melee", false) && !bIsMeleeCooldown[attacker]) {

					bIsMeleeCooldown[attacker] = true;
					CreateTimer(0.3, Timer_IsMeleeCooldown, attacker, TIMER_FLAG_NO_MAPCHANGE);
					FindAbilityByTrigger(attacker, victim, 'b', FindZombieClass(attacker), baseWeaponDamage);	// striking a player with a melee weapon
					FindAbilityByTrigger(victim, attacker, 'B', FindZombieClass(victim), baseWeaponDamage);	// being struck by a melee weapon
				}
				FindAbilityByTrigger(attacker, victim, 'D', FindZombieClass(attacker), baseWeaponDamage);
				FindAbilityByTrigger(victim, attacker, 'L', FindZombieClass(victim), baseWeaponDamage);

				t_InfectedHealth = GetClientHealth(victim);
				isEntityPos = FindListPositionByEntity(victim, Handle:InfectedHealth[attacker]);

				if (isEntityPos < 0) {

					isArraySize = GetArraySize(Handle:InfectedHealth[attacker]);
					ResizeArray(Handle:InfectedHealth[attacker], isArraySize + 1);
					SetArrayCell(Handle:InfectedHealth[attacker], isArraySize, victim, 0);

					//An infected wasn't added on spawn to this player, so we add it now based on class.
					if (FindZombieClass(victim) == ZOMBIECLASS_TANK) t_InfectedHealth = 4000;
					else if (FindZombieClass(victim) == ZOMBIECLASS_HUNTER || FindZombieClass(victim) == ZOMBIECLASS_SMOKER) t_InfectedHealth = 250;
					else if (FindZombieClass(victim) == ZOMBIECLASS_BOOMER) t_InfectedHealth = 50;
					else if (FindZombieClass(victim) == ZOMBIECLASS_SPITTER) t_InfectedHealth = 100;
					else if (FindZombieClass(victim) == ZOMBIECLASS_CHARGER) t_InfectedHealth = 600;
					else if (FindZombieClass(victim) == ZOMBIECLASS_JOCKEY) t_InfectedHealth = 325;

					decl String:ss_InfectedHealth[64];
					Format(ss_InfectedHealth, sizeof(ss_InfectedHealth), "(%d) infected health bonus", FindZombieClass(victim));

					if (StringToInt(GetConfigValue("infected bot level type?")) == 1) t_InfectedHealth += t_InfectedHealth * RoundToCeil(LivingSurvivorLevels() * StringToFloat(GetConfigValue(ss_InfectedHealth)));
					else t_InfectedHealth += t_InfectedHealth * RoundToCeil(PlayerLevel[attacker] * StringToFloat(GetConfigValue(ss_InfectedHealth)));
					if (HandicapLevel[attacker] > 0) t_InfectedHealth += t_InfectedHealth * RoundToCeil(HandicapLevel[attacker] * StringToFloat(GetConfigValue("handicap health increase?")));

					SetArrayCell(Handle:InfectedHealth[attacker], isArraySize, t_InfectedHealth, 1);
					SetArrayCell(Handle:InfectedHealth[attacker], isArraySize, 0, 2);
					SetArrayCell(Handle:InfectedHealth[attacker], isArraySize, 0, 3);
					SetArrayCell(Handle:InfectedHealth[attacker], isArraySize, 0, 4);
					isEntityPos = isArraySize;
				}
				new i_DamageBonus = baseWeaponDamage;
				new i_InfectedMaxHealth = GetArrayCell(Handle:InfectedHealth[attacker], isEntityPos, 1);
				new i_InfectedCurrent = GetArrayCell(Handle:InfectedHealth[attacker], isEntityPos, 2);
				new i_HealthRemaining = i_InfectedMaxHealth - i_InfectedCurrent;
				if (i_DamageBonus > i_HealthRemaining) i_DamageBonus = i_HealthRemaining;

				SetArrayCell(Handle:InfectedHealth[attacker], isEntityPos, GetArrayCell(Handle:InfectedHealth[attacker], isEntityPos, 2) + i_DamageBonus, 2);
				RoundDamageTotal += (i_DamageBonus);
				RoundDamage[attacker] += (i_DamageBonus);
				//LogToFile(LogPathDirectory, "[PLAYER %N] %s Damage Total: %d", attacker, weapon, baseWeaponDamage);

				if (StringToInt(GetConfigValue("display health bars?")) == 1) {

					DisplayInfectedHealthBars(attacker, victim);
				}
				if (CheckTeammateDamages(victim, attacker) >= 1.0 ||
					CheckTeammateDamages(victim, attacker, true) >= 1.0 ||
					CheckTeammateDamages(victim, attacker) < 0.0 ||
					CheckTeammateDamages(victim, attacker, true) < 0.0) {

					FindAbilityByTrigger(attacker, victim, 'e', FindZombieClass(attacker), i_DamageBonus);
					FindAbilityByTrigger(victim, attacker, 'E', FindZombieClass(victim), i_DamageBonus);

					CalculateInfectedDamageAward(victim);
				}
			}
		}
	}
	damage = 0.0;
	return Plugin_Handled;
}

stock AddSpecialCommonDamage(client, entity, playerDamage) {

	if (!IsSpecialCommon(entity)) {

		ClearSpecialCommon(entity);
		return;
	}
	new pos		= FindListPositionByEntity(entity, Handle:CommonList);
	if (pos < 0) return;

	new damageTotal = -1;

	new my_size	= GetArraySize(Handle:SpecialCommon[client]);
	new my_pos	= FindListPositionByEntity(entity, Handle:SpecialCommon[client]);
	if (my_pos < 0) {

		new CommonHealth = StringToInt(GetCommonValue(entity, "base health?"));
		new mlevel = PlayerLevel[client];
		CommonHealth = RoundToCeil(CommonHealth * (StringToFloat(GetCommonValue(entity, "health per level?")) * mlevel) + (CommonHealth * LivingSurvivors()));

		ResizeArray(Handle:SpecialCommon[client], my_size + 1);
		SetArrayCell(Handle:SpecialCommon[client], my_size, entity, 0);
		SetArrayCell(Handle:SpecialCommon[client], my_size, CommonHealth, 1);
		SetArrayCell(Handle:SpecialCommon[client], my_size, playerDamage, 2);
		SetArrayCell(Handle:SpecialCommon[client], my_size, 0, 3);
		SetArrayCell(Handle:SpecialCommon[client], my_size, 0, 4);
	} 
	else {

		if (playerDamage >= 0) {

			damageTotal = GetArrayCell(Handle:SpecialCommon[client], my_pos, 2);
			if (damageTotal < 0) damageTotal = 0;
			SetArrayCell(Handle:SpecialCommon[client], my_pos, damageTotal + playerDamage, 2);
		}
		else {

			damageTotal = GetArrayCell(Handle:SpecialCommon[client], my_pos, 1);
			SetArrayCell(Handle:SpecialCommon[client], my_pos, damageTotal + playerDamage, 1);
			CheckIfEntityShouldDie(entity, client);
		}
	}
}

stock AwardHealingPoints(healer, target, healAmount) {

	new size = GetArraySize(Handle:InfectedHealth[target]);
	new entity = -1;
	new isEntityPos = -1;
	for (new i = 0; i < size && entity == -1; i++) {

		if (GetArrayCell(Handle:InfectedHealth[target], i, 3) > 0) {
		
			entity = GetArrayCell(Handle:InfectedHealth[target], i, 0);
		}
	}
	if (entity == -1) {

		size = GetArraySize(Handle:WitchDamage[target]);
		for (new i = 0; i < size && entity == -1; i++) {

			if (GetArrayCell(Handle:WitchDamage[target], i, 3) > 0) {

				entity = GetArrayCell(Handle:WitchDamage[target], i, 0);
			}
		}
	}
	if (entity == -1) return;

	if (!IsWitch(entity)) isEntityPos = FindListPositionByEntity(entity, Handle:InfectedHealth[healer]);
	else isEntityPos = FindListPositionByEntity(entity, Handle:WitchDamage[healer]);

	if (isEntityPos < 0) {

		if (!IsWitch(entity) && !IsLegitimateClient(entity)) return;

		new t_InfectedHealth = 0;
		if (!IsWitch(entity)) t_InfectedHealth = GetClientHealth(entity);
		else t_InfectedHealth = StringToInt(GetConfigValue("base witch health?"));

		new isArraySize = 0;
		if (!IsWitch(entity)) {

			isArraySize = GetArraySize(Handle:InfectedHealth[healer]);
			ResizeArray(Handle:InfectedHealth[healer], isArraySize + 1);
			SetArrayCell(Handle:InfectedHealth[healer], isArraySize, entity, 0);
		}
		else {

			isArraySize = GetArraySize(Handle:WitchDamage[healer]);
			ResizeArray(Handle:WitchDamage[healer], isArraySize + 1);
			SetArrayCell(Handle:WitchDamage[healer], isArraySize, entity, 0);
		}

		//An infected wasn't added on spawn to this player, so we add it now based on class.
		if (!IsWitch(entity)) {

			if (FindZombieClass(entity) == ZOMBIECLASS_TANK) t_InfectedHealth = 4000;
			else if (FindZombieClass(entity) == ZOMBIECLASS_HUNTER || FindZombieClass(entity) == ZOMBIECLASS_SMOKER) t_InfectedHealth = 250;
			else if (FindZombieClass(entity) == ZOMBIECLASS_BOOMER) t_InfectedHealth = 50;
			else if (FindZombieClass(entity) == ZOMBIECLASS_SPITTER) t_InfectedHealth = 100;
			else if (FindZombieClass(entity) == ZOMBIECLASS_CHARGER) t_InfectedHealth = 600;
			else if (FindZombieClass(entity) == ZOMBIECLASS_JOCKEY) t_InfectedHealth = 325;

			decl String:ss_InfectedHealth[64];
			Format(ss_InfectedHealth, sizeof(ss_InfectedHealth), "(%d) infected health bonus", FindZombieClass(entity));

			if (StringToInt(GetConfigValue("infected bot level type?")) == 1) t_InfectedHealth += t_InfectedHealth * RoundToCeil(LivingSurvivorLevels() * StringToFloat(GetConfigValue(ss_InfectedHealth)));
			else t_InfectedHealth += t_InfectedHealth * RoundToCeil(PlayerLevel[healer] * StringToFloat(GetConfigValue(ss_InfectedHealth)));
			if (HandicapLevel[healer] > 0) t_InfectedHealth += t_InfectedHealth * RoundToCeil(HandicapLevel[healer] * StringToFloat(GetConfigValue("handicap health increase?")));

			SetArrayCell(Handle:InfectedHealth[healer], isArraySize, t_InfectedHealth, 1);
			SetArrayCell(Handle:InfectedHealth[healer], isArraySize, 0, 2);
			SetArrayCell(Handle:InfectedHealth[healer], isArraySize, 0, 3);
			SetArrayCell(Handle:InfectedHealth[healer], isArraySize, 0, 4);	// healing
		}
		else {

			new iWitchHealth = StringToInt(GetConfigValue("base witch health?"));
			new imlevel = PlayerLevel[healer];
			iWitchHealth += RoundToCeil(iWitchHealth * (imlevel * StringToFloat(GetConfigValue("level witch multiplier?"))));

			SetArrayCell(Handle:WitchDamage[healer], isArraySize, iWitchHealth, 1);
			SetArrayCell(Handle:WitchDamage[healer], isArraySize, 0, 2);
			SetArrayCell(Handle:WitchDamage[healer], isArraySize, 0, 3);
			SetArrayCell(Handle:WitchDamage[healer], isArraySize, 0, 4);	// healing
		}
		isEntityPos = isArraySize;//openbucket
	}

	if (GetClientHealth(target) + healAmount > GetMaximumHealth(target) && GetClientHealth(target) < GetMaximumHealth(target)) healAmount = GetMaximumHealth(target) - GetClientHealth(target);
	if (!IsWitch(entity)) SetArrayCell(Handle:InfectedHealth[healer], isEntityPos, GetArrayCell(Handle:InfectedHealth[healer], isEntityPos, 4) + healAmount, 4);
	else SetArrayCell(Handle:WitchDamage[healer], isEntityPos, GetArrayCell(Handle:WitchDamage[healer], isEntityPos, 4) + healAmount, 4);
}

/*
 *	Cycles through all given talents in the CONFIG/READYUP/RPG/SURVIVORMENU.CFG or CONFIG/READYUP/RPG/INFECTEDMENU.CFG
 *	file, respective to the activator's team, searching for any talent that has the ability char in its "ability trigger?" key
 *	and then activates it. If it can't be found in ANY of the talents, however, a logmessage, NOT A FAILSTATE, is returned.
 *	Prototype: void FindAbilityByTrigger(activator, int target = 0, char ability, int zombieclass = 0, int d_Damage)
 */
//if (!IsLegitimateClient(activator) && (IsWitch(activator) || IsCommonInfected(activator)))

stock FindAbilityByTrigger(activator, target = 0, ability, zombieclass = 0, d_Damage) {

	if (IsWitch(activator) || IsCommonInfected(activator)) return;	// Commons don't trigger anything.

	if (IsLegitimateClient(activator) && ((IsFakeClient(activator) && GetClientTeam(activator) == TEAM_INFECTED) || !IsFakeClient(activator))) {

		new a_Size			=	GetArraySize(a_Menu_Talents);

		decl String:TalentName[64];
		for (new i = 0; i < a_Size; i++) {

			TriggerKeys[activator]				= GetArrayCell(a_Menu_Talents, i, 0);
			TriggerValues[activator]			= GetArrayCell(a_Menu_Talents, i, 1);
			TriggerSection[activator]			= GetArrayCell(a_Menu_Talents, i, 2);

			// We get the name of the talent. It's not actually used for anything when it's passed through the ActivateAbility function, but I wanted to
			// keep it in case I find a use for it, whether of debugging nature, or something else, later on.

			//PrintToChatAll("SIZE: %d", GetArraySize(TriggerSection[activator]));
			GetArrayString(Handle:TriggerSection[activator], 0, TalentName, sizeof(TalentName));

			// If the talent in question has an ability trigger that matches the ability trigger passed through, we call ActivateAbility.
			// Note that GetKeyValue(Handle:Keys, Handle:Values, String:KeyString) is similar to GetConfigValue, except it lets you pull values from ANY set of handles, so we aren't restricted
			// by any specific config file. In this case, we use the Handles pulled from the respective array, above.
			if (FindCharInString(GetKeyValue(TriggerKeys[activator], TriggerValues[activator], "ability trigger?"), ability) != -1) {

				decl String:activatorteam[10];
				Format(activatorteam, sizeof(activatorteam), "%d", GetClientTeam(activator));
				decl String:targetteam[10];
				Format(targetteam, sizeof(targetteam), "0");
				
				if (IsWitch(target)) Format(targetteam, sizeof(targetteam), "0");
				else if (IsSpecialCommon(target)) Format(targetteam, sizeof(targetteam), "4");	// special common infected have their own team designation so talents don't get them confused with witches, commons, specials.
				else if (IsLegitimateClient(target)) Format(targetteam, sizeof(targetteam), "%d", GetClientTeam(target));
				//PrintToChatAll("%s ability by %N is active", ability, activator);

				if (StrContains(GetKeyValue(TriggerKeys[activator], TriggerValues[activator], "activator team required?"), activatorteam, false) != -1 &&
					StrContains(GetKeyValue(TriggerKeys[activator], TriggerValues[activator], "target team required?"), targetteam, false) != -1) {

					//PrintToChatAll("%s ability by %N is going to activate ability", ability, activator);

					ActivateAbility(activator, target, i, d_Damage, FindZombieClass(activator), TriggerKeys[activator], TriggerValues[activator], TalentName, ability);
				}
			}
		}
	}
}

/*
 *	This function checks to make sure the activator and target, along with other variables like zombieclass are eligible.
 *	If they are, it calculates strength of effect, cooldowns, and other timers, and then rolls the TriggerAbility function.
 *	TriggerAbility essentially returns true if chance rolls aren't required for the talent, or has a chance to return true or false if they are, depending on its outcome.
 *	ActivateAbilityEx is called on a successful roll, given there are effects to cast on the respective player(s).
 *	void ActivateAbility(activator, target, int pos, int damage, int zombieclass, Handle:Keys, Handle:Values, String:TalentName[], char ability)
 */
stock ActivateAbility(activator, target, pos, damage, zombieclass, Handle:Keys, Handle:Values, String:TalentName[], ability) {

	if (IsLegitimateClient(activator) && (target == 0 || (target > 0 && (IsLegitimateClient(target)) || IsWitch(target) || IsCommonInfected(target)))) {

		decl String:survivoreffects[64];
		decl String:infectedeffects[64];
		decl String:commoneffects[64];

		new Float:i_Strength			=	0.0;
		new Float:i_FirstPoint			=	0.0;
		new Float:i_EachPoint			=	0.0;
		new Float:i_Time				=	0.0;
		new Float:i_Cooldown			=	0.0;
		decl String:ClientZombieClass[64];
		decl String:VictimZombieClass[64];
		decl String:ClientZombieClassRequired[64];
		decl String:VictimZombieClassRequired[64];
		decl String:ClientModelRequired[64];
		decl String:ClientModel[64];
		new Float:CommonVector[3];
		new Float:ActivatorVector[3];

		new OriginBased = StringToInt(GetKeyValue(Keys, Values, "origin based?"));
		new PIV = 1;

		new Float:f_SafeCombatDistance = StringToFloat(GetKeyValue(Keys, Values, "safe combat distance required?"));
		if (f_SafeCombatDistance > 0.0 && EnemyCombatantsWithinRange(activator, f_SafeCombatDistance)) return;
		new Float:f_CombatDistance = StringToFloat(GetKeyValue(Keys, Values, "combat distance required?"));
		if (f_CombatDistance > 0.0 && !EnemyCombatantsWithinRange(activator, f_CombatDistance)) return;

		if (IsLegitimateClient(activator) && GetClientTeam(activator) == TEAM_SURVIVOR) GetClientModel(activator, ClientModel, sizeof(ClientModel));
		else if (IsLegitimateClient(target) && GetClientTeam(target) == TEAM_SURVIVOR) GetClientModel(target, ClientModel, sizeof(ClientModel));

		Format(ClientModelRequired, sizeof(ClientModelRequired), "-1");
		if (IsLegitimateClient(activator) && GetClientTeam(activator) == TEAM_SURVIVOR ||
			IsLegitimateClient(target) && GetClientTeam(target) == TEAM_SURVIVOR) Format(ClientModelRequired, sizeof(ClientModelRequired), "%s", GetKeyValue(Keys, Values, "survivor required?"));

		Format(ClientZombieClassRequired, sizeof(ClientZombieClassRequired), "%s", GetKeyValue(Keys, Values, "activator class required?"));
		Format(VictimZombieClassRequired, sizeof(VictimZombieClassRequired), "%s", GetKeyValue(Keys, Values, "target class required?"));

		decl String:WeaponsPermitted[512];
		Format(WeaponsPermitted, sizeof(WeaponsPermitted), "ignore");

		decl String:WeaponsPermittedStrict[512];
		Format(WeaponsPermittedStrict, sizeof(WeaponsPermittedStrict), "ignore");

		Format(WeaponsPermitted, sizeof(WeaponsPermitted), "%s", GetKeyValue(Keys, Values, "weapons permitted?"));
		Format(WeaponsPermittedStrict, sizeof(WeaponsPermittedStrict), "%s", GetKeyValue(Keys, Values, "weapons permitted strict?"));
		decl String:PlayerWeapon[64];
		if (GetClientTeam(activator) == TEAM_INFECTED) Format(PlayerWeapon, sizeof(PlayerWeapon), "ignore");
		else GetClientWeapon(activator, PlayerWeapon, sizeof(PlayerWeapon));
		if (StrEqual(ClientModelRequired, "-1", false) || StrEqual(ClientModel, ClientModelRequired, false)) {

			//LogMessage("Weapons Permitted: %s (Player %N has %s)", WeaponsPermitted, activator, PlayerWeapon);

			if (StrEqual(WeaponsPermitted, "ignore", false) || StrEqual(WeaponsPermitted, "all", false) || StrContains(PlayerWeapon, WeaponsPermitted, false) != -1) {

				if (StrEqual(WeaponsPermittedStrict, "-1", false) || StrEqual(WeaponsPermittedStrict, "ignore", false) ||
					StrEqual(WeaponsPermittedStrict, "all", false) || StrEqual(WeaponsPermittedStrict, PlayerWeapon, false)) {

					if (IsWitch(target)) Format(VictimZombieClass, sizeof(VictimZombieClass), "7");
					else if (IsSpecialCommon(target)) Format(VictimZombieClass, sizeof(VictimZombieClass), "8");
					else if (IsCommonInfected(target)) Format(VictimZombieClass, sizeof(VictimZombieClass), "9");
					else if (IsLegitimateClient(target)) {

						if (GetClientTeam(target) == TEAM_INFECTED) Format(VictimZombieClass, sizeof(VictimZombieClass), "%d", FindZombieClass(target));
						else Format(VictimZombieClass, sizeof(VictimZombieClass), "0");
					}
					if (GetClientTeam(activator) == TEAM_INFECTED) Format(ClientZombieClass, sizeof(ClientZombieClass), "%d", FindZombieClass(activator));
					else Format(ClientZombieClass, sizeof(ClientZombieClass), "0");

					if (IsLegitimateClient(activator) && (StrContains(ClientZombieClassRequired, "0", false) != -1 && GetClientTeam(activator) == TEAM_SURVIVOR ||
						StrContains(ClientZombieClassRequired, ClientZombieClass, false) != -1 && GetClientTeam(activator) == TEAM_INFECTED) &&
						((IsCommonInfected(target) || IsWitch(target) || target == 0) || (IsLegitimateClient(target) && (StrContains(VictimZombieClassRequired, "0", false) != -1 && GetClientTeam(target) == TEAM_SURVIVOR ||
						StrContains(VictimZombieClassRequired, VictimZombieClass, false) != -1 && GetClientTeam(target) == TEAM_INFECTED)))) {

						//if (StrEqual(key, "class required?") && (StringToInt(value) == zombieclass || (StringToInt(value) == 0 && GetClientTeam(client) == TEAM_SURVIVOR) || zombieclass == 9)) {

						//if (!IsAbilityCooldown(client, TalentName) && !b_IsImmune[victim]) {

						if (!IsAbilityCooldown(activator, TalentName) && (IsCommonInfected(target) || IsWitch(target) || !IsAbilityImmune(target, TalentName))) {

							survivoreffects		=	FindAbilityEffects(activator, Keys, Values, 2);
							infectedeffects		=	FindAbilityEffects(activator, Keys, Values, 3);
							commoneffects		=	FindAbilityEffects(activator, Keys, Values, 0);

							if (!IsFakeClient(activator)) i_Strength			=	GetTalentStrength(activator, TalentName) * 1.0;
							else i_Strength									=	GetTalentStrength(-1, TalentName) * 1.0;

							//i_Strength			=	1.0;
							if (i_Strength <= 0.0) return;	// Locked talents will appear as LESS THAN 0.0 (they will be -1.0)

							new t_Strength		= RoundToCeil(i_Strength);
								
							i_FirstPoint		=	StringToFloat(GetKeyValue(Keys, Values, "first point value?"));
							i_EachPoint			=	StringToFloat(GetKeyValue(Keys, Values, "increase per point?"));
							i_Strength			=	i_FirstPoint + (i_EachPoint * i_Strength);

							if (!IsFakeClient(activator)) i_Time				=	GetTalentStrength(activator, TalentName) * 1.0;
							else i_Time										=	GetTalentStrength(-1, TalentName) * 1.0;
							//i_Time					=	1.0;
							if (i_Time > 0.0) i_Time	*=	StringToFloat(GetKeyValue(Keys, Values, "ability time per point?"));

							if (!IsFakeClient(activator)) i_Cooldown			=	GetTalentStrength(activator, TalentName) * 1.0;
							else i_Cooldown									=	GetTalentStrength(-1, TalentName) * 1.0;

							i_Cooldown				=	StringToFloat(GetKeyValue(Keys, Values, "cooldown start?")) + (StringToFloat(GetKeyValue(Keys, Values, "cooldown per point?")) * i_Cooldown);
							//i_Cooldown				=	1.0;

							if (TriggerAbility(activator, target, ability, pos, Keys, Values, TalentName)) {//annabelle	//	Don't need to check if the player has ability points since the roll is 0 if they don't.

								if (i_Cooldown > 0.0) {

									if (IsClientActual(activator)) CreateCooldown(activator, GetTalentPosition(activator, TalentName), i_Cooldown);	// Infected Bots don't have cooldowns between abilities! Mwahahahaha
									if (IsLegitimateClient(target)) CreateImmune(target, GetTalentPosition(target, TalentName), i_Cooldown);		// Immunities to individual talents so multiple talents can trigger!
								}

								if (!StrEqual(infectedeffects, "0")) {

									if (IsLegitimateClient(activator) && GetClientTeam(activator) == TEAM_INFECTED) ActivateAbilityEx(activator, activator, damage, infectedeffects, i_Strength, i_Time, target);
									else if (IsLegitimateClientAlive(target) && GetClientTeam(target) == TEAM_INFECTED) ActivateAbilityEx(target, activator, damage, infectedeffects, i_Strength, i_Time, target);
								}
								if (!StrEqual(survivoreffects, "0")) {

									if (IsLegitimateClient(activator) && GetClientTeam(activator) == TEAM_SURVIVOR) ActivateAbilityEx(activator, activator, damage, survivoreffects, i_Strength, i_Time, target);
									else if (IsLegitimateClientAlive(target) && GetClientTeam(target) == TEAM_SURVIVOR) ActivateAbilityEx(target, activator, damage, survivoreffects, i_Strength, i_Time, target);
								}
								new isMultipleTargets = StringToInt(GetKeyValue(Keys, Values, "multiple targets?")) * t_Strength;
								new killtargets = isMultipleTargets;
								if (!StrEqual(commoneffects, "0")) {

									if (OriginBased == 0) {

										if (IsLegitimateClient(activator) && GetClientTeam(activator) == TEAM_SURVIVOR && IsCommonInfected(target)) ActivateAbilityEx(target, activator, damage, commoneffects, i_Strength, i_Time, target);
									}
									else if (OriginBased == 1) {

										GetClientAbsOrigin(activator, ActivatorVector);
										new ent = -1;
										while ((ent = FindEntityByClassname(ent, "infected")) != -1 && killtargets >= 0) {

											GetEntPropVector(ent, Prop_Send, "m_vecOrigin", CommonVector);
											if (GetVectorDistance(CommonVector, ActivatorVector) > i_Strength) continue;
											ActivateAbilityEx(ent, activator, damage, commoneffects, i_Strength, i_Time, ent);
											if (killtargets > 1) killtargets--;
											else if (killtargets == 1) break;
										}
									}
								}
								if (OriginBased > 0) {

									decl String:TargetZombieClass[64];
									PIV = 1;
									new IsVisualEffect = StringToInt(GetKeyValue(Keys, Values, "draw?"));
									decl String:IsVisualColour[64];
									Format(IsVisualColour, sizeof(IsVisualColour), "%s", GetKeyValue(Keys, Values, "draw colour?"));

									decl String:ActivatorColour[64];
									decl String:TargetColour[64];
									Format(ActivatorColour, sizeof(ActivatorColour), "%s", GetKeyValue(Keys, Values, "activator draw colour?"));
									Format(TargetColour, sizeof(TargetColour), "%s", GetKeyValue(Keys, Values, "target draw colour?"));

									for (new i = 1; i <= MaxClients; i++) {

										if (!IsLegitimateClientAlive(i)) continue;
										if (GetClientTeam(i) == TEAM_INFECTED) Format(TargetZombieClass, sizeof(TargetZombieClass), "%d", FindZombieClass(i));
										if (OriginBased == 1 && i != activator && GetPlayerDistance(activator, i) <= i_Strength) {

											if (isMultipleTargets > 0) PIV = GetPIV(activator, i_Strength);

											//	We activate abilities if players are within range of the activator (and not the activator)
											if (!StrEqual(infectedeffects, "0") && GetClientTeam(i) == TEAM_INFECTED && StrContains(VictimZombieClassRequired, TargetZombieClass, false) != -1) ActivateAbilityEx(i, activator, damage / PIV, infectedeffects, i_Strength, i_Time, i);
											if (!StrEqual(survivoreffects, "0") && GetClientTeam(i) == TEAM_SURVIVOR) ActivateAbilityEx(i, activator, damage, survivoreffects, i_Strength, i_Time, i);

											if (IsVisualEffect == 1) {

												for (new y = 1; y <= MaxClients; y++) {

													if (!IsLegitimateClient(y) || IsFakeClient(y)) continue;

													if (IsLegitimateClient(activator) && GetClientTeam(y) != GetClientTeam(activator) || IsWitch(activator) || IsCommonInfected(activator)) CreateLineSolo(activator, i, TargetColour, _, y);
													else CreateLineSolo(activator, i, ActivatorColour, _, y);
												}
											}
											else if (IsVisualEffect == 2) {

												for (new y = 1; y <= MaxClients; y++) {

													if (!IsLegitimateClient(y) || IsFakeClient(y)) continue;

													if (IsLegitimateClient(activator) && GetClientTeam(y) != GetClientTeam(activator) || IsWitch(activator) || IsCommonInfected(activator)) CreateRingSolo(activator, i_Strength, TargetColour, _, _, y);
													else CreateRingSolo(activator, i_Strength, ActivatorColour, _, _, y);
												}
											}
										}
										else if (OriginBased == 2 && i != target && GetPlayerDistance(target, i) <= i_Strength) {

											//	We activate abilities for the target of the activator.
											if (!StrEqual(infectedeffects, "0") && GetClientTeam(i) == TEAM_INFECTED && StrContains(VictimZombieClassRequired, TargetZombieClass, false) != -1) ActivateAbilityEx(i, target, damage / PIV, infectedeffects, i_Strength, i_Time, i);
											if (!StrEqual(survivoreffects, "0") && GetClientTeam(i) == TEAM_SURVIVOR) ActivateAbilityEx(i, target, damage, survivoreffects, i_Strength, i_Time, i);

											if (IsVisualEffect == 1) {

												for (new y = 1; y <= MaxClients; y++) {

													if (!IsLegitimateClient(y) || IsFakeClient(y)) continue;

													if (IsLegitimateClient(target) && GetClientTeam(y) != GetClientTeam(target) || IsWitch(target) || IsCommonInfected(target)) CreateLineSolo(target, i, TargetColour, _, y);
													else CreateLineSolo(activator, i, ActivatorColour, _, y);
												}
											}
											else if (IsVisualEffect == 2) {

												for (new y = 1; y <= MaxClients; y++) {

													if (!IsLegitimateClient(y) || IsFakeClient(y)) continue;

													if (IsLegitimateClient(activator) && GetClientTeam(y) != GetClientTeam(activator) || IsWitch(activator) || IsCommonInfected(activator)) CreateRingSolo(activator, i_Strength, TargetColour, _, _, y);
													else CreateRingSolo(activator, i_Strength, ActivatorColour, _, _, y);
												}
											}
										}
										else if (OriginBased == 3 && i != target && i != activator) {

											if (GetPlayerDistance(activator, i) <= i_Strength) {

												if (!StrEqual(infectedeffects, "0") && GetClientTeam(i) == TEAM_INFECTED && StrContains(VictimZombieClassRequired, TargetZombieClass, false) != -1) ActivateAbilityEx(i, activator, damage / PIV, infectedeffects, i_Strength, i_Time, i);
												if (!StrEqual(survivoreffects, "0") && GetClientTeam(i) == TEAM_SURVIVOR) ActivateAbilityEx(i, activator, damage, survivoreffects, i_Strength, i_Time, i);

												if (IsVisualEffect == 1) {

													for (new y = 1; y <= MaxClients; y++) {

														if (!IsLegitimateClient(y) || IsFakeClient(y)) continue;

														if (IsLegitimateClient(activator) && GetClientTeam(y) != GetClientTeam(activator) || IsWitch(activator) || IsCommonInfected(activator)) CreateLineSolo(activator, i, TargetColour, _, y);
														else CreateLineSolo(activator, i, ActivatorColour, _, y);
													}
												}
												else if (IsVisualEffect == 2) {

													for (new y = 1; y <= MaxClients; y++) {

														if (!IsLegitimateClient(y) || IsFakeClient(y)) continue;

														if (IsLegitimateClient(activator) && GetClientTeam(y) != GetClientTeam(activator) || IsWitch(activator) || IsCommonInfected(activator)) CreateRingSolo(activator, i_Strength, TargetColour, _, _, y);
														else CreateRingSolo(activator, i_Strength, ActivatorColour, _, _, y);
													}
												}
											}
											if (GetPlayerDistance(target, i) <= i_Strength) {

												if (!StrEqual(infectedeffects, "0") && GetClientTeam(i) == TEAM_INFECTED && StrContains(VictimZombieClassRequired, TargetZombieClass, false) != -1) ActivateAbilityEx(i, target, damage / PIV, infectedeffects, i_Strength, i_Time, i);
												if (!StrEqual(survivoreffects, "0") && GetClientTeam(i) == TEAM_SURVIVOR) ActivateAbilityEx(i, target, damage, survivoreffects, i_Strength, i_Time, i);

												if (IsVisualEffect == 1) {

													for (new y = 1; y <= MaxClients; y++) {

														if (IsLegitimateClient(target) && GetClientTeam(y) != GetClientTeam(target) || IsWitch(target) || IsCommonInfected(target)) CreateLineSolo(target, i, TargetColour, _, y);
														else CreateLineSolo(activator, i, ActivatorColour, _, y);
													}
												}
												else if (IsVisualEffect == 2) {

													for (new y = 1; y <= MaxClients; y++) {

														if (IsLegitimateClient(activator) && GetClientTeam(y) != GetClientTeam(activator) || IsWitch(activator) || IsCommonInfected(activator)) CreateRingSolo(activator, i_Strength, TargetColour, _, _, y);
														else CreateRingSolo(activator, i_Strength, ActivatorColour, _, _, y);
													}
												}
											}
										}
									}
								}
							}
						}
					}
				}
			}
		}
	}
}

stock GetPIV(client, Float:Distance, bool:IsSameTeam = true) {

	new Float:ClientOrigin[3];
	new Float:iOrigin[3];

	GetClientAbsOrigin(client, ClientOrigin);

	new count = 0;
	for (new i = 1; i <= MaxClients; i++) {

		if (!IsLegitimateClientAlive(i) || i == client) continue;
		if (IsSameTeam && GetClientTeam(client) != GetClientTeam(i)) continue;
		GetClientAbsOrigin(i, iOrigin);
		if (GetVectorDistance(ClientOrigin, iOrigin) <= Distance) count++;
	}
	return count;
}

stock Float:GetPlayerDistance(client, target) {

	new Float:ClientDistance[3];
	if (!IsWitch(client) && !IsCommonInfected(client)) GetClientAbsOrigin(client, ClientDistance);
	else GetEntPropVector(client, Prop_Send, "m_vecOrigin", ClientDistance);

	new Float:TargetDistance[3];
	if (!IsWitch(target) && !IsCommonInfected(target)) GetClientAbsOrigin(target, TargetDistance);
	else GetEntPropVector(target, Prop_Send, "m_vecOrigin", TargetDistance);

	return GetVectorDistance(ClientDistance, TargetDistance);
}

stock bool:TriggerAbility(client, victim, ability, pos, Handle:Keys, Handle:Values, String:TalentName[]) {

	if (IsLegitimateClient(client) && (victim == 0 || (IsLegitimateClient(victim) || IsWitch(victim) || IsCommonInfected(victim)))) {// (victim == 0 || (victim > 0 && IsLegitimateClient(victim)))) {

		decl String:abilities[64];
		decl String:DefenseAbility[64];
		Format(DefenseAbility, sizeof(DefenseAbility), "defense");
		Format(abilities, sizeof(abilities), "%s", GetKeyValue(Keys, Values, "ability trigger?"));
		if (FindCharInString(abilities, 'c') == -1) {				// No chance roll required to execute this ability.

			if (victim == 0 || IsWitch(victim) || IsCommonInfected(victim)) return true;			// Common infected, always returns true if there's no chance roll.
			if ((GetClientTeam(victim) == TEAM_INFECTED && IsFakeClient(victim)) || HandicapDifference(client, victim) > 0 || HandicapDifference(client, victim) == 0) return true;
		}
		else if (AbilityChanceSuccess(client, TalentName)) return true;
		//else if (AbilityChanceSuccess(client, TalentName) && (!IsClientActual(victim) || IsFakeClient(victim))) return true;
	}
	return false;
}

stock String:FindAbilityEffects(client, Handle:Keys, Handle:Values, team = 0) {

	decl String:text[64];
	Format(text, sizeof(text), "-1");

	if (team == TEAM_SURVIVOR) Format(text, sizeof(text), "%s", GetKeyValue(Keys, Values, "survivor ability effects?"));
	else if (team == TEAM_INFECTED) Format(text, sizeof(text), "%s", GetKeyValue(Keys, Values, "infected ability effects?"));
	else if (team == 0) {

		/*

			Common Infected.
		*/
		Format(text, sizeof(text), "%s", GetKeyValue(Keys, Values, "common ability effects?"));
	}
	return text;
}

/*stock bool:AbilityChanceUpgradesExist(client, String:s_TalentName[] = "none") {

	

		In order to stream-line the extremely-complex system and introduce it to players in phases
		menus that require the ability chance talent will not be displayed to a player if they have
		not yet placed points in ability chance.
		This prevents a player from accidentally upgrading a ton of abilities that require ability
		chance without upgrading ability chance, simply due to the obtuse design of the talent system.
	
	if (IsLegitimateClient(client)) {

		new pos				=	FindChanceRollAbility(client, s_TalentName);

		if (pos == -1) SetFailState("Ability Requires \'C\' but no ability with effect \'C\' could be found.");

		decl String:talentname[64];
		new i_Strength		=	0;
		new range			=	0;

		AbilityKeys[client]			= GetArrayCell(a_Menu_Talents, pos, 0);
		AbilityValues[client]		= GetArrayCell(a_Menu_Talents, pos, 1);
		AbilitySection[client]		= GetArrayCell(a_Menu_Talents, pos, 2);

		GetArrayString(Handle:AbilitySection[client], 0, talentname, sizeof(talentname));

		i_Strength			=	GetTalentStrength(client, talentname);
		if (i_Strength == 0) return false;
		else return true;
	}
	return false;
}*/

stock bool:AbilityChanceSuccess(client, String:s_TalentName[] = "none") {

	if (IsLegitimateClient(client)) {

		new pos				=	FindChanceRollAbility(client, s_TalentName);

		if (pos == -1) {

			//LogToFile(LogPathDirectory, "Talent Name: %s Ability Requires \'C\' but no ability with effect \'C\' could be found.", s_TalentName);
			return false;
		}

		decl String:talentname[64];

		new Float:i_FirstPoint	=	0.0;
		new Float:i_EachPoint	=	0.0;
		new i_Strength		=	0;
		new range			=	0;

		AbilityKeys[client]			= GetArrayCell(a_Menu_Talents, pos, 0);
		AbilityValues[client]		= GetArrayCell(a_Menu_Talents, pos, 1);
		AbilitySection[client]		= GetArrayCell(a_Menu_Talents, pos, 2);

		GetArrayString(Handle:AbilitySection[client], 0, talentname, sizeof(talentname));

		if (!IsFakeClient(client)) {

			i_Strength			=	GetTalentStrength(client, talentname);
			i_FirstPoint		=	(StringToFloat(GetKeyValue(AbilityKeys[client], AbilityValues[client], "first point value?")) * 100.0) + (Technique[client] * 0.1);
			i_EachPoint			=	StringToFloat(GetKeyValue(AbilityKeys[client], AbilityValues[client], "increase per point?")) + (Agility[client] * 0.1);
			range				=	RoundToCeil(1.0 / i_EachPoint - (Luck[client] * 0.1));
			i_EachPoint			*=	100.0;

			if (i_Strength == 0) return false;
			//i_Strength = 1;
			i_Strength			=	RoundToCeil(i_FirstPoint + (i_EachPoint * i_Strength) + StrengthValue(client));
		}
		else {

			i_Strength			=	GetTalentStrength(-1, talentname);
			i_FirstPoint		=	(StringToFloat(GetKeyValue(AbilityKeys[client], AbilityValues[client], "first point value?")) * 100.0) + (Technique_Bots * 0.1);
			i_EachPoint			=	StringToFloat(GetKeyValue(AbilityKeys[client], AbilityValues[client], "increase per point?")) + (Agility_Bots * 0.1);
			range				=	RoundToCeil(1.0 / i_EachPoint - (Luck_Bots * 0.1));
			i_EachPoint			*=	100.0;

			if (i_Strength == 0) i_FirstPoint = 0.0;
			i_Strength			=	RoundToCeil(i_FirstPoint + (i_EachPoint * i_Strength) + (Strength_Bots * 0.1));
		}

		//LogToFile(LogPathDirectory, "%N of %d sided die for %s (verified: %s)", client, range, talentname, s_TalentName);
		range				=	GetRandomInt(1, range);
		//LogToFile(LogPathDirectory, "%N rolled %d of the required range.", client, range);
		//LogMessage("Talent: %s, range: %d Strength: %d", talentname, range, i_Strength);

		if (range <= i_Strength) return true;
	}
	return false;
}

stock GetTalentStrength(client, String:TalentName[]) {

	decl String:text[64];
	//Format(text, sizeof(text), "-1");
	//if (IsLegitimateClient(client)) {

	new size				=	0;
	if (client != -1) size	=	GetArraySize(a_Database_PlayerTalents[client]);
	else size				=	GetArraySize(a_Database_PlayerTalents_Bots);

	for (new i = 0; i < size; i++) {

		GetArrayString(Handle:a_Database_Talents, i, text, sizeof(text));
		if (StrEqual(TalentName, text)) {

			if (client != -1) GetArrayString(Handle:a_Database_PlayerTalents[client], i, text, sizeof(text));
			else GetArrayString(Handle:a_Database_PlayerTalents_Bots, i, text, sizeof(text));
			break;
		}
	}
	return StringToInt(text);
}

stock GetKeyPos(Handle:Keys, String:SearchKey[]) {

	decl String:key[64];
	new size = GetArraySize(Keys);
	for (new i = 0; i < size; i++) {

		GetArrayString(Handle:Keys, i, key, sizeof(key));
		if (StrEqual(key, SearchKey)) return i;
	}
	return -1;
}

stock String:GetKeyValue(Handle:Keys, Handle:Values, String:SearchKey[], String:DefaultValue[] = "none", bool:bDebug = false) {

	decl String:key[64];
	decl String:value[64];
	if (StrEqual(DefaultValue, "none", false)) Format(value, sizeof(value), "-1");
	else Format(value, sizeof(value), "%s", DefaultValue);

	new size = GetArraySize(Keys);
	for (new i = 0; i < size; i++) {

		GetArrayString(Handle:Keys, i, key, sizeof(key));
		if (bDebug) {

			GetArrayString(Handle:Values, i, value, sizeof(value));
			LogMessage("DEBUG: Key: %s Value: %s", key, value);
		}
		if (StrEqual(key, SearchKey)) {

			GetArrayString(Handle:Values, i, value, sizeof(value));
			return value;
		}
	}
	return value;
}

stock String:GetMenuOfTalent(client, String:TalentName[]) {

	decl String:s_TalentName[64];
	decl String:result[64];
	Format(result, sizeof(result), "-1");

	new size = GetArraySize(a_Menu_Talents);
	for (new i = 0; i < size; i++) {

		MOTKeys[client]			= GetArrayCell(a_Menu_Talents, i, 0);
		MOTValues[client]		= GetArrayCell(a_Menu_Talents, i, 1);
		MOTSection[client]		= GetArrayCell(a_Menu_Talents, i, 2);

		GetArrayString(Handle:MOTSection[client], 0, s_TalentName, sizeof(s_TalentName));
		if (!StrEqual(s_TalentName, TalentName, false)) continue;
		Format(result, sizeof(result), GetKeyValue(MOTKeys[client], MOTValues[client], "part of menu named?"));
		break;
	}
	return result;
}

stock FindChanceRollAbility(client, String:s_TalentName[] = "none") {

	if (IsLegitimateClient(client)) {

		new a_Size			=	0;

		a_Size		= GetArraySize(a_Menu_Talents);

		decl String:TalentName[64];

		for (new i = 0; i < a_Size; i++) {

			ChanceKeys[client]			= GetArrayCell(a_Menu_Talents, i, 0);
			ChanceValues[client]		= GetArrayCell(a_Menu_Talents, i, 1);
			ChanceSection[client]		= GetArrayCell(a_Menu_Talents, i, 2);

			//GetArrayString(Handle:ChanceSection[client], 0, TalentName, sizeof(TalentName));
			Format(TalentName, sizeof(TalentName), "%s", GetKeyValue(ChanceKeys[client], ChanceValues[client], "part of menu named?"));
			if (!StrEqual(TalentName, GetMenuOfTalent(client, s_TalentName), false)) continue;

			if (GetClientTeam(client) == TEAM_SURVIVOR && FindCharInString(GetKeyValue(ChanceKeys[client], ChanceValues[client], "survivor ability effects?"), 'C') != -1 ||
				GetClientTeam(client) == TEAM_INFECTED && FindCharInString(GetKeyValue(ChanceKeys[client], ChanceValues[client], "infected ability effects?"), 'C') != -1) {

				return i;
			}
		}
	}
	return -1;
}

stock GetWeaponSlot(entity) {

	if (IsValidEntity(entity)) {

		decl String:Classname[64];
		GetEdictClassname(entity, Classname, sizeof(Classname));

		if (StrContains(Classname, "pistol", false) != -1 || StrContains(Classname, "chainsaw", false) != -1) return 1;
		if (StrContains(Classname, "molotov", false) != -1 || StrContains(Classname, "pipe_bomb", false) != -1 || StrContains(Classname, "vomitjar", false) != -1) return 2;
		if (StrContains(Classname, "defib", false) != -1 || StrContains(Classname, "first_aid", false) != -1) return 3;
		if (StrContains(Classname, "adren", false) != -1 || StrContains(Classname, "pills", false) != -1) return 4;
		return 0;
	}
	return -1;
}

stock BeanBag(client, Float:force) {

	if (IsLegitimateClientAlive(client)) {

		if (L4D2_GetSurvivorVictim(client) != -1 || (GetEntityFlags(client) & FL_ONGROUND)) {

			new Float:Velocity[3];

			Velocity[0]	=	GetEntPropFloat(client, Prop_Send, "m_vecVelocity[0]");
			Velocity[1]	=	GetEntPropFloat(client, Prop_Send, "m_vecVelocity[1]");
			Velocity[2]	=	GetEntPropFloat(client, Prop_Send, "m_vecVelocity[2]");

			new Float:Vec_Pull;
			new Float:Vec_Lunge;

			Vec_Pull	=	GetRandomFloat(force * -1.0, force);
			Vec_Lunge	=	GetRandomFloat(force * -1.0, force);
			Velocity[2]	+=	force;

			if (Vec_Pull < 0.0 && Velocity[0] > 0.0) Velocity[0] *= -1.0;
			Velocity[0] += Vec_Pull;

			if (Vec_Lunge < 0.0 && Velocity[1] > 0.0) Velocity[1] *= -1.0;
			Velocity[1] += Vec_Lunge;

			TeleportEntity(client, NULL_VECTOR, NULL_VECTOR, Velocity);
			new victim = L4D2_GetSurvivorVictim(client);
			if (victim != -1) TeleportEntity(victim, NULL_VECTOR, NULL_VECTOR, Velocity);
		}
	}
}

stock CreateExplosion(client, damage = 0, attacker = 0) {

	new entity 				= CreateEntityByName("env_explosion");
	new Float:loc[3];
	if (!IsWitch(client) && !IsCommonInfected(client)) GetClientAbsOrigin(client, loc);
	else GetEntPropVector(client, Prop_Send, "m_vecOrigin", loc);

	DispatchKeyValue(entity, "fireballsprite", "sprites/zerogxplode.spr");
	DispatchKeyValue(entity, "iMagnitude", "0");	// we don't want the fireball dealing damage - we do this manually.
	DispatchKeyValue(entity, "iRadiusOverride", "0");
	DispatchKeyValue(entity, "rendermode", "5");
	DispatchKeyValue(entity, "spawnflags", "0");
	DispatchSpawn(entity);
	TeleportEntity(entity, Float:loc, NULL_VECTOR, NULL_VECTOR);
	AcceptEntityInput(entity, "explode");

	if (damage > 0) {

		if (IsWitch(client)) {

			if (FindListPositionByEntity(client, Handle:WitchList) >= 0) AddWitchDamage(attacker, client, damage);
			else OnWitchCreated(client, true);
		}
		else if (IsSpecialCommon(client)) AddSpecialCommonDamage(attacker, client, damage);
		else if (IsCommonInfected(client)) AddCommonInfectedDamage(attacker, client, damage);
	}
}

stock ScreenShake(client) {

	new entity = CreateEntityByName("env_shake");

	new Float:loc[3];
	GetClientAbsOrigin(client, loc);
	if(entity >= 0)
	{
		DispatchKeyValue(entity, "spawnflags", "8");
		DispatchKeyValue(entity, "amplitude", "16.0");
		DispatchKeyValue(entity, "frequency", "1.5");
		DispatchKeyValue(entity, "duration", "0.9");
		DispatchKeyValue(entity, "radius", "0.0");
		DispatchSpawn(entity);
		ActivateEntity(entity);
		AcceptEntityInput(entity, "Enable");

		TeleportEntity(entity, Float:loc, NULL_VECTOR, NULL_VECTOR);
		AcceptEntityInput(entity, "StartShake");

		SetVariantString("OnUser1 !self:Kill::1.1:1");
		AcceptEntityInput(entity, "AddOutput");
		AcceptEntityInput(entity, "FireUser1");
	}
}

stock ZeroGravity(client, victim, Float:g_TalentStrength, Float:g_TalentTime) {

	if (IsLegitimateClientAlive(client) && IsLegitimateClientAlive(victim)) {

		if (L4D2_GetSurvivorVictim(victim) != -1 || ((GetEntityFlags(victim) & FL_ONGROUND) || !b_GroundRequired[victim])) {


		//if (GetEntityFlags(victim) & FL_ONGROUND || !b_GroundRequired[victim]) {

			//if (ZeroGravityTimer[victim] == INVALID_HANDLE) {

			new Float:vel[3];
			vel[0] = GetEntPropFloat(victim, Prop_Send, "m_vecVelocity[0]");
			vel[1] = GetEntPropFloat(victim, Prop_Send, "m_vecVelocity[1]");
			vel[2] = GetEntPropFloat(victim, Prop_Send, "m_vecVelocity[2]");
			//ZeroGravityTimer[victim] = 
			CreateTimer(g_TalentTime, Timer_ZeroGravity, victim, TIMER_FLAG_NO_MAPCHANGE);
			SetEntityGravity(victim, GravityBase[victim] - g_TalentStrength);
			TeleportEntity(victim, NULL_VECTOR, NULL_VECTOR, vel);

			new survivor = L4D2_GetSurvivorVictim(victim);
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

stock SpeedIncrease(client, Float:effectTime = 0.0, Float:amount = -1.0, bool:IsTeamAffected = false) {

	if (IsLegitimateClientAlive(client)) {

		//if (amount == -1.0) amount = SpeedMultiplierBase[client];

		/*if (effectTime == 0.0) {

			if (!IsFakeClient(client)) SpeedMultiplier[client] = SpeedMultiplierBase[client] + (Agility[client] * 0.01) + amount;
			else SpeedMultiplier[client] = SpeedMultiplierBase[client] + (Agility_Bots * 0.01) + amount;
		}
		else {*/

		if (amount >= 0.0) {

			SpeedMultiplier[client] = SpeedMultiplierBase[client] + amount;
			/*if (SpeedMultiplierTimer[client] != INVALID_HANDLE) {

				KillTimer(SpeedMultiplierTimer[client]);
				SpeedMultiplierTimer[client] = INVALID_HANDLE;
			}
			SpeedMultiplierTimer[client] = */
			SetEntPropFloat(client, Prop_Send, "m_flLaggedMovementValue", SpeedMultiplier[client]);
			CreateTimer(effectTime, Timer_SpeedIncrease, client, TIMER_FLAG_NO_MAPCHANGE);
		}
		else {

			SetSpeedMultiplierBase(client);
			//SpeedMultiplier[client] = SpeedMultiplierBase[client];
		}
		//LogMessage("%N Base: %3.3f amount: %3.3f Current: %3.3f", client, SpeedMultiplierBase[client], amount, SpeedMultiplier[client]);

		if (IsTeamAffected) {

			for (new i = 1; i <= MaxClients; i++) {

				if (IsLegitimateClientAlive(i) && !IsFakeClient(i) && GetClientTeam(i) == GetClientTeam(client) && client != i) {

					if (effectTime == 0.0) SpeedMultiplier[i] = SpeedMultiplierBase[i] + (Agility[i] * 0.01) + amount;
					else {

						SpeedMultiplier[i] = SpeedMultiplierBase[i] + amount;
						/*if (SpeedMultiplierTimer[i] != INVALID_HANDLE) {

							KillTimer(SpeedMultiplierTimer[i]);
							SpeedMultiplierTimer[i] = INVALID_HANDLE;
						}*/
						//SpeedMultiplierTimer[i] = 
						CreateTimer(effectTime, Timer_SpeedIncrease, i, TIMER_FLAG_NO_MAPCHANGE);
					}
					SetEntPropFloat(i, Prop_Send, "m_flLaggedMovementValue", SpeedMultiplier[i]);
				}
			}
		}
	}
}

stock SlowPlayer(client, Float:g_TalentStrength, Float:g_TalentTime) {

	if (IsLegitimateClientAlive(client)) {

		//if (SlowMultiplierTimer[client] != INVALID_HANDLE) {

		//	KillTimer(SlowMultiplierTimer[client]);
		//	SlowMultiplierTimer[client] = INVALID_HANDLE;
		//}
		SpeedMultiplier[client] = 1.0;
		//SlowMultiplierTimer[client] = 
		CreateTimer(g_TalentTime, Timer_SlowPlayer, client, TIMER_FLAG_NO_MAPCHANGE);
		if (g_TalentStrength > 1.0 && g_TalentStrength < 100.0) g_TalentStrength *= 0.01;
		else if (g_TalentStrength > 1.0 && g_TalentStrength < 1000.0) g_TalentStrength *= 0.001;
		else if (g_TalentStrength > 1.0 && g_TalentStrength < 10000.0) g_TalentStrength *= 0.0001;
		SetEntPropFloat(client, Prop_Send, "m_flLaggedMovementValue", SpeedMultiplier[client] - g_TalentStrength);
	}
}

stock DamageBonus(attacker, victim, damagevalue, Float:amount) {

	if (IsLegitimateClientAlive(victim)) {

		new i_DamageBonus = RoundToFloor(damagevalue * amount);

		if (GetClientTeam(victim) == TEAM_SURVIVOR) {

			if (GetClientTotalHealth(victim) > i_DamageBonus) SetClientTotalHealth(victim, i_DamageBonus); //SetEntityHealth(victim, GetClientHealth(victim) - CommonsDamage);
			else if (GetClientTotalHealth(victim) <= i_DamageBonus) IncapacitateOrKill(victim, attacker);
		}
		else {

			new isEntityPos = FindListPositionByEntity(victim, Handle:InfectedHealth[attacker]);

			if (isEntityPos < 0) {

				new t_InfectedHealth = GetClientHealth(victim);

				new isArraySize = GetArraySize(Handle:InfectedHealth[attacker]);
				ResizeArray(Handle:InfectedHealth[attacker], isArraySize + 1);
				SetArrayCell(Handle:InfectedHealth[attacker], isArraySize, victim, 0);

				//An infected wasn't added on spawn to this player, so we add it now based on class.
				if (FindZombieClass(victim) == ZOMBIECLASS_TANK) t_InfectedHealth = 4000;
				else if (FindZombieClass(victim) == ZOMBIECLASS_HUNTER || FindZombieClass(victim) == ZOMBIECLASS_SMOKER) t_InfectedHealth = 250;
				else if (FindZombieClass(victim) == ZOMBIECLASS_BOOMER) t_InfectedHealth = 50;
				else if (FindZombieClass(victim) == ZOMBIECLASS_SPITTER) t_InfectedHealth = 100;
				else if (FindZombieClass(victim) == ZOMBIECLASS_CHARGER) t_InfectedHealth = 600;
				else if (FindZombieClass(victim) == ZOMBIECLASS_JOCKEY) t_InfectedHealth = 325;

				decl String:ss_InfectedHealth[64];
				Format(ss_InfectedHealth, sizeof(ss_InfectedHealth), "(%d) infected health bonus", FindZombieClass(victim));

				if (StringToInt(GetConfigValue("infected bot level type?")) == 1) t_InfectedHealth += t_InfectedHealth * RoundToCeil(LivingSurvivorLevels() * StringToFloat(GetConfigValue(ss_InfectedHealth)));
				else t_InfectedHealth += t_InfectedHealth * RoundToCeil(PlayerLevel[attacker] * StringToFloat(GetConfigValue(ss_InfectedHealth)));
				if (HandicapLevel[attacker] > 0) t_InfectedHealth += t_InfectedHealth * RoundToCeil(HandicapLevel[attacker] * StringToFloat(GetConfigValue("handicap health increase?")));

				SetArrayCell(Handle:InfectedHealth[attacker], isArraySize, t_InfectedHealth, 1);
				SetArrayCell(Handle:InfectedHealth[attacker], isArraySize, 0, 2);
				SetArrayCell(Handle:InfectedHealth[attacker], isArraySize, 0, 3);
				SetArrayCell(Handle:InfectedHealth[attacker], isArraySize, 0, 4);
				isEntityPos = isArraySize;
			}

			new i_InfectedMaxHealth = GetArrayCell(Handle:InfectedHealth[attacker], isEntityPos, 1);
			new i_InfectedCurrent = GetArrayCell(Handle:InfectedHealth[attacker], isEntityPos, 2);
			new i_HealthRemaining = i_InfectedMaxHealth - i_InfectedCurrent;
			if (i_DamageBonus > i_HealthRemaining) i_DamageBonus = i_HealthRemaining;
			SetArrayCell(Handle:InfectedHealth[attacker], isEntityPos, GetArrayCell(Handle:InfectedHealth[attacker], isEntityPos, 2) + i_DamageBonus, 2);
			RoundDamageTotal += i_DamageBonus;
			RoundDamage[attacker] += i_DamageBonus;
			//LogToFile(LogPathDirectory, "[PLAYER %N] Damage Bonus against %N for %d (base damage: %d)", attacker, victim, i_DamageBonus, damagevalue);

			if (StringToInt(GetConfigValue("display health bars?")) == 1) {

				DisplayInfectedHealthBars(attacker, victim);
			}
			if (CheckTeammateDamages(victim, attacker) >= 1.0 ||
				CheckTeammateDamages(victim, attacker, true) >= 1.0 ||
				CheckTeammateDamages(victim, attacker) < 0.0 ||
				CheckTeammateDamages(victim, attacker, true) < 0.0) {

				CalculateInfectedDamageAward(victim);
			}
		}
	}
}

stock CreateLineSolo(client, target, String:DrawColour[], Float:lifetime = 0.5, targetClient = 0) {

	new Float:ClientPos[3];
	new Float:TargetPos[3];
	if (!IsWitch(client) && !IsCommonInfected(client)) GetClientAbsOrigin(client, ClientPos);
	else GetEntPropVector(client, Prop_Send, "m_vecOrigin", ClientPos);
	if (!IsWitch(target) && !IsCommonInfected(target)) GetClientAbsOrigin(target, TargetPos);
	else GetEntPropVector(target, Prop_Send, "m_vecOrigin", TargetPos);
	
	if (StrEqual(DrawColour, "green", false)) TE_SetupBeamPoints(ClientPos, TargetPos, g_iSprite, g_BeaconSprite, 0, 15, lifetime, 2.0, 0.5, 0, 0.5, {0, 255, 0, 200}, 50);
	else if (StrEqual(DrawColour, "red", false)) TE_SetupBeamPoints(ClientPos, TargetPos, g_iSprite, g_BeaconSprite, 0, 15, lifetime, 2.0, 0.5, 0, 0.5, {255, 0, 0, 200}, 50);
	else if (StrEqual(DrawColour, "blue", false)) TE_SetupBeamPoints(ClientPos, TargetPos, g_iSprite, g_BeaconSprite, 0, 15, lifetime, 2.0, 0.5, 0, 0.5, {0, 0, 255, 200}, 50);
	else if (StrEqual(DrawColour, "purple", false)) TE_SetupBeamPoints(ClientPos, TargetPos, g_iSprite, g_BeaconSprite, 0, 15, lifetime, 2.0, 0.5, 0, 0.5, {255, 0, 255, 200}, 50);
	else if (StrEqual(DrawColour, "yellow", false)) TE_SetupBeamPoints(ClientPos, TargetPos, g_iSprite, g_BeaconSprite, 0, 15, lifetime, 2.0, 0.5, 0, 0.5, {255, 255, 0, 200}, 50);
	else if (StrEqual(DrawColour, "orange", false)) TE_SetupBeamPoints(ClientPos, TargetPos, g_iSprite, g_BeaconSprite, 0, 15, lifetime, 2.0, 0.5, 0, 0.5, {255, 69, 0, 200}, 50);
	else if (StrEqual(DrawColour, "black", false)) TE_SetupBeamPoints(ClientPos, TargetPos, g_iSprite, g_BeaconSprite, 0, 15, lifetime, 2.0, 0.5, 0, 0.5, {0, 0, 0, 200}, 50);
	else if (StrEqual(DrawColour, "brightblue", false)) TE_SetupBeamPoints(ClientPos, TargetPos, g_iSprite, g_BeaconSprite, 0, 15, lifetime, 2.0, 0.5, 0, 0.5, {132, 112, 255, 200}, 50);
	else if (StrEqual(DrawColour, "darkgreen", false)) TE_SetupBeamPoints(ClientPos, TargetPos, g_iSprite, g_BeaconSprite, 0, 15, lifetime, 2.0, 0.5, 0, 0.5, {178, 34, 34, 200}, 50);
	else {

		/*

			To prevent erroring out if not specified (ie user error), we draw a default, yellow line.
		*/
		TE_SetupBeamPoints(ClientPos, TargetPos, g_iSprite, g_BeaconSprite, 0, 15, lifetime, 2.0, 0.5, 0, 0.5, {255, 255, 0, 200}, 50);
	}

	TE_SendToClient(targetClient);
}

stock CreateRingSolo(client, Float:RingAreaSize, String:DrawColour[], bool:IsPulsing = true, Float:lifetime = 1.0, targetClient) {

	new Float:ClientPos[3];
	if (!IsWitch(client) && !IsCommonInfected(client)) GetClientAbsOrigin(client, ClientPos);
	else GetEntPropVector(client, Prop_Send, "m_vecOrigin", ClientPos);

	new Float:pulserange = 0.0;
	if (IsPulsing) pulserange = 32.0;
	else pulserange = RingAreaSize - 32.0;
	//LogMessage("==============\nDraw Colour: %s\n===============", DrawColour);

	ClientPos[2] += 20.0;
	if (StrEqual(DrawColour, "green", false)) TE_SetupBeamRingPoint(ClientPos, pulserange, RingAreaSize, g_iSprite, g_BeaconSprite, 0, 15, lifetime, 2.0, 0.5, {0, 255, 0, 200}, 50, 0);
	else if (StrEqual(DrawColour, "red", false)) TE_SetupBeamRingPoint(ClientPos, pulserange, RingAreaSize, g_iSprite, g_BeaconSprite, 0, 15, lifetime, 2.0, 0.5, {255, 0, 0, 200}, 50, 0);
	else if (StrEqual(DrawColour, "blue", false)) TE_SetupBeamRingPoint(ClientPos, pulserange, RingAreaSize, g_iSprite, g_BeaconSprite, 0, 15, lifetime, 2.0, 0.5, {0, 0, 255, 200}, 50, 0);
	else if (StrEqual(DrawColour, "purple", false)) TE_SetupBeamRingPoint(ClientPos, pulserange, RingAreaSize, g_iSprite, g_BeaconSprite, 0, 15, lifetime, 2.0, 0.5, {255, 0, 255, 200}, 50, 0);
	else if (StrEqual(DrawColour, "yellow", false)) TE_SetupBeamRingPoint(ClientPos, pulserange, RingAreaSize, g_iSprite, g_BeaconSprite, 0, 15, lifetime, 2.0, 0.5, {255, 255, 0, 200}, 50, 0);
	else if (StrEqual(DrawColour, "orange", false)) TE_SetupBeamRingPoint(ClientPos, pulserange, RingAreaSize, g_iSprite, g_BeaconSprite, 0, 15, lifetime, 2.0, 0.5, {255, 69, 0, 200}, 50, 0);
	else if (StrEqual(DrawColour, "black", false)) TE_SetupBeamRingPoint(ClientPos, pulserange, RingAreaSize, g_iSprite, g_BeaconSprite, 0, 15, lifetime, 2.0, 0.5, {0, 0, 0, 200}, 50, 0);
	else if (StrEqual(DrawColour, "brightblue", false)) TE_SetupBeamRingPoint(ClientPos, pulserange, RingAreaSize, g_iSprite, g_BeaconSprite, 0, 15, lifetime, 2.0, 0.5, {132, 112, 255, 200}, 50, 0);
	else if (StrEqual(DrawColour, "darkgreen", false)) TE_SetupBeamRingPoint(ClientPos, pulserange, RingAreaSize, g_iSprite, g_BeaconSprite, 0, 15, lifetime, 2.0, 0.5, {178, 34, 34, 200}, 50, 0);
	else TE_SetupBeamRingPoint(ClientPos, pulserange, RingAreaSize, g_iSprite, g_BeaconSprite, 0, 15, lifetime, 2.0, 0.5, {255, 255, 0, 200}, 50, 0);
	TE_SendToClient(targetClient);
}

// line 840
stock CreateLine(client, target, String:DrawColour[], Float:lifetime = 0.5, targetClient = 0) {

	new Float:ClientPos[3];
	new Float:TargetPos[3];
	if (!IsWitch(client) && !IsCommonInfected(client)) GetClientAbsOrigin(client, ClientPos);
	else GetEntPropVector(client, Prop_Send, "m_vecOrigin", ClientPos);
	if (!IsWitch(target) && !IsCommonInfected(target)) GetClientAbsOrigin(target, TargetPos);
	else GetEntPropVector(target, Prop_Send, "m_vecOrigin", TargetPos);
	for (new i = 1; i <= MaxClients; i++) {

		if (IsLegitimateClient(i) && !IsFakeClient(i) && (i == targetClient || targetClient == 0)) {

			if (StrEqual(DrawColour, "green", false)) TE_SetupBeamPoints(ClientPos, TargetPos, g_iSprite, g_BeaconSprite, 0, 15, lifetime, 2.0, 0.5, 0, 0.5, {0, 255, 0, 200}, 50);
			else if (StrEqual(DrawColour, "red", false)) TE_SetupBeamPoints(ClientPos, TargetPos, g_iSprite, g_BeaconSprite, 0, 15, lifetime, 2.0, 0.5, 0, 0.5, {255, 0, 0, 200}, 50);
			else if (StrEqual(DrawColour, "blue", false)) TE_SetupBeamPoints(ClientPos, TargetPos, g_iSprite, g_BeaconSprite, 0, 15, lifetime, 2.0, 0.5, 0, 0.5, {0, 0, 255, 200}, 50);
			else if (StrEqual(DrawColour, "purple", false)) TE_SetupBeamPoints(ClientPos, TargetPos, g_iSprite, g_BeaconSprite, 0, 15, lifetime, 2.0, 0.5, 0, 0.5, {255, 0, 255, 200}, 50);
			else if (StrEqual(DrawColour, "yellow", false)) TE_SetupBeamPoints(ClientPos, TargetPos, g_iSprite, g_BeaconSprite, 0, 15, lifetime, 2.0, 0.5, 0, 0.5, {255, 255, 0, 200}, 50);
			else if (StrEqual(DrawColour, "orange", false)) TE_SetupBeamPoints(ClientPos, TargetPos, g_iSprite, g_BeaconSprite, 0, 15, lifetime, 2.0, 0.5, 0, 0.5, {255, 69, 0, 200}, 50);
			else if (StrEqual(DrawColour, "black", false)) TE_SetupBeamPoints(ClientPos, TargetPos, g_iSprite, g_BeaconSprite, 0, 15, lifetime, 2.0, 0.5, 0, 0.5, {0, 0, 0, 200}, 50);
			else if (StrEqual(DrawColour, "brightblue", false)) TE_SetupBeamPoints(ClientPos, TargetPos, g_iSprite, g_BeaconSprite, 0, 15, lifetime, 2.0, 0.5, 0, 0.5, {132, 112, 255, 200}, 50);
			else if (StrEqual(DrawColour, "darkgreen", false)) TE_SetupBeamPoints(ClientPos, TargetPos, g_iSprite, g_BeaconSprite, 0, 15, lifetime, 2.0, 0.5, 0, 0.5, {178, 34, 34, 200}, 50);
			else TE_SetupBeamPoints(ClientPos, TargetPos, g_iSprite, g_BeaconSprite, 0, 15, lifetime, 2.0, 0.5, 0, 0.5, {255, 255, 0, 200}, 50);
			TE_SendToClient(i);
		}
	}
}

stock CreateRing(client, Float:RingAreaSize, String:DrawColour[], bool:IsPulsing = true, Float:lifetime = 1.0, targetClient = 0) {

	new Float:ClientPos[3];
	if (!IsWitch(client) && !IsCommonInfected(client)) GetClientAbsOrigin(client, ClientPos);
	else GetEntPropVector(client, Prop_Send, "m_vecOrigin", ClientPos);

	new Float:pulserange = 0.0;
	if (IsPulsing) pulserange = 32.0;
	else pulserange = RingAreaSize - 32.0;
	//LogMessage("==============\nDraw Colour: %s\n===============", DrawColour);

	for (new i = 1; i <= MaxClients; i++)
	{
		if (IsLegitimateClient(i) && !IsFakeClient(i) && (i == targetClient || targetClient == 0)) {

			ClientPos[2] += 20.0;
			if (StrEqual(DrawColour, "green", false)) TE_SetupBeamRingPoint(ClientPos, pulserange, RingAreaSize, g_iSprite, g_BeaconSprite, 0, 15, lifetime, 2.0, 0.5, {0, 255, 0, 200}, 50, 0);
			else if (StrEqual(DrawColour, "red", false)) TE_SetupBeamRingPoint(ClientPos, pulserange, RingAreaSize, g_iSprite, g_BeaconSprite, 0, 15, lifetime, 2.0, 0.5, {255, 0, 0, 200}, 50, 0);
			else if (StrEqual(DrawColour, "blue", false)) TE_SetupBeamRingPoint(ClientPos, pulserange, RingAreaSize, g_iSprite, g_BeaconSprite, 0, 15, lifetime, 2.0, 0.5, {0, 0, 255, 200}, 50, 0);
			else if (StrEqual(DrawColour, "purple", false)) TE_SetupBeamRingPoint(ClientPos, pulserange, RingAreaSize, g_iSprite, g_BeaconSprite, 0, 15, lifetime, 2.0, 0.5, {255, 0, 255, 200}, 50, 0);
			else if (StrEqual(DrawColour, "yellow", false)) TE_SetupBeamRingPoint(ClientPos, pulserange, RingAreaSize, g_iSprite, g_BeaconSprite, 0, 15, lifetime, 2.0, 0.5, {255, 255, 0, 200}, 50, 0);
			else if (StrEqual(DrawColour, "orange", false)) TE_SetupBeamRingPoint(ClientPos, pulserange, RingAreaSize, g_iSprite, g_BeaconSprite, 0, 15, lifetime, 2.0, 0.5, {255, 69, 0, 200}, 50, 0);
			else if (StrEqual(DrawColour, "black", false)) TE_SetupBeamRingPoint(ClientPos, pulserange, RingAreaSize, g_iSprite, g_BeaconSprite, 0, 15, lifetime, 2.0, 0.5, {0, 0, 0, 200}, 50, 0);
			else if (StrEqual(DrawColour, "brightblue", false)) TE_SetupBeamRingPoint(ClientPos, pulserange, RingAreaSize, g_iSprite, g_BeaconSprite, 0, 15, lifetime, 2.0, 0.5, {132, 112, 255, 200}, 50, 0);
			else if (StrEqual(DrawColour, "darkgreen", false)) TE_SetupBeamRingPoint(ClientPos, pulserange, RingAreaSize, g_iSprite, g_BeaconSprite, 0, 15, lifetime, 2.0, 0.5, {178, 34, 34, 200}, 50, 0);
			else TE_SetupBeamRingPoint(ClientPos, pulserange, RingAreaSize, g_iSprite, g_BeaconSprite, 0, 15, lifetime, 2.0, 0.5, {255, 255, 0, 200}, 50, 0);
			TE_SendToClient(i);
		}
	}
}

stock CreateBeacons(client, Float:Distance) {

	new Float:Pos[3];
	new Float:Pos2[3];

	GetClientAbsOrigin(client, Pos);
	for (new i = 1; i <= MaxClients; i++)
	{
		if (IsLegitimateClientAlive(i) && i != client && GetClientTeam(i) != GetClientTeam(client)) {

			GetClientAbsOrigin(i, Pos2);
			if (GetVectorDistance(Pos, Pos2) > Distance) continue;

			Pos2[2] += 20.0;
			TE_SetupBeamRingPoint(Pos2, 32.0, 128.0, g_iSprite, g_BeaconSprite, 0, 15, 0.5, 2.0, 0.5, {20, 20, 150, 150}, 50, 0);
			TE_SendToClient(client);
		}
	}
}

stock FrozenPlayer(client, Float:effectTime = 3.0, amount = 100) {

	if (IsLegitimateClient(client) && !IsFakeClient(client)) {

		new clients[2];
		clients[0] = client;
		new UserMsg:BlindMsgID = GetUserMessageId("Fade");
		new Handle:message = StartMessageEx(BlindMsgID, clients, 1);
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

		BfWriteByte(message, 132);
		BfWriteByte(message, 112);
		BfWriteByte(message, 255);
		
		if (amount > 0) {

			//b_IsBlind[client] = true;
			SetEntityMoveType(client, MOVETYPE_NONE);
			if (effectTime > 0.0) CreateTimer(effectTime, Timer_FrozenPlayer, client, TIMER_FLAG_NO_MAPCHANGE);
			else {

				/*

					Special Commons set an effect time of 0.0.
				*/
				if (ISFROZEN[client] == INVALID_HANDLE) ISFROZEN[client] = CreateTimer(0.25, Timer_Freezer, client, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
			}
			BfWriteByte(message, amount);
		}
		else {

			//b_IsBlind[client] = false;
			SetEntityMoveType(client, MOVETYPE_WALK);
			BfWriteByte(message, 0);
		}
		EndMessage();
	}
}

stock BlindPlayer(client, Float:effectTime = 3.0, amount = 0) {

	if (IsLegitimateClient(client) && !IsFakeClient(client)) {

		new clients[2];
		clients[0] = client;
		new UserMsg:BlindMsgID = GetUserMessageId("Fade");
		new Handle:message = StartMessageEx(BlindMsgID, clients, 1);
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

		BfWriteByte(message, 0);
		BfWriteByte(message, 0);
		BfWriteByte(message, 0);
		
		if (amount > 0) {

			//b_IsBlind[client] = true;
			if (effectTime > 0.0) CreateTimer(effectTime, Timer_BlindPlayer, client, TIMER_FLAG_NO_MAPCHANGE);
			else {

				/*

					Special Commons set an effect time of 0.0.
				*/
				if (ISBLIND[client] == INVALID_HANDLE) ISBLIND[client] = CreateTimer(0.25, Timer_Blinder, client, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
			}
			BfWriteByte(message, amount);
		}
		else {

			//b_IsBlind[client] = false;
			BfWriteByte(message, 0);
		}
		EndMessage();
	}
}

stock CreateFireEx(client)
{
	if (IsLegitimateClient(client)) {

		decl Float:pos[3];
		GetClientAbsOrigin(client, pos);
		CreateFire(pos);
	}
}

static const String:MODEL_GASCAN[] = "models/props_junk/gascan001a.mdl";
stock CreateFire(const Float:BombOrigin[3])
{
	new entity = CreateEntityByName("prop_physics");
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

stock bool:EnemyCombatantsWithinRange(client, Float:f_Distance) {

	new Float:d_Client[3];
	new Float:e_Client[3]
	GetClientAbsOrigin(client, d_Client);
	for (new i = 1; i <= MaxClients; i++) {

		if (IsLegitimateClient(i) && GetClientTeam(i) != GetClientTeam(client)) {

			GetClientAbsOrigin(i, e_Client);
			if (GetVectorDistance(d_Client, e_Client) <= f_Distance) return true;
		}
	}
	return false;
}

stock bool:IsTanksActive() {

	for (new i = 1; i <= MaxClients; i++) {

		if (IsLegitimateClient(i) && GetClientTeam(i) == TEAM_INFECTED && FindZombieClass(i) == ZOMBIECLASS_TANK) return true;
	}
	return false;
}

stock bool:IsCoveredInBile(client) {

	for (new i = 1; i <= MaxClients; i++) {

		if (!IsClientInGame(i)) continue;
		if (CoveredInBile[client][i] >= 0) return true;
	}
	return false;
}

stock ModifyGravity(client, Float:g_Gravity = 1.0, Float:g_Time = 0.0, bool:b_Jumping = false) {

	if (IsLegitimateClientAlive(client)) {

		//if (b_IsJumping[client]) return;	// survivors only, for the moon jump ability
		if (b_Jumping) {

			b_IsJumping[client] = true;
			CreateTimer(0.1, Timer_DetectGroundTouch, client, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
		}
		if (g_Gravity == 1.0) SetEntityGravity(client, g_Gravity);
		else {

			if (g_Gravity > 1.0 && g_Gravity < 100.0) g_Gravity *= 0.01;
			else if (g_Gravity > 1.0 && g_Gravity < 1000.0) g_Gravity *= 0.001;
			else if (g_Gravity > 1.0 && g_Gravity < 10000.0) g_Gravity *= 0.0001;
			SetEntityGravity(client, 1.0 - g_Gravity);
		}
		if (g_Gravity < 1.0 && !b_Jumping) CreateTimer(g_Time, Timer_ResetGravity, client, TIMER_FLAG_NO_MAPCHANGE);
	}
}

stock GetReviveHealth() {

	return RoundToCeil(GetConVarFloat(FindConVar("survivor_revive_health")));
}

stock SetTempHealth(activator, target, Float:s_Strength) {

	if (IsLegitimateClientAlive(target)) {

		new Float:TempHealth	= GetMaximumHealth(activator) * s_Strength;

		SetEntPropFloat(target, Prop_Send, "m_healthBuffer", GetConVarFloat(FindConVar("survivor_revive_health")) + TempHealth);
	}
}

stock SetMaximumHealth(client, bool:b_HealthModifier = false, Float:s_Strength = 0.0) {

	if (IsLegitimateClientAlive(client) && IsFakeClient(client) || IsLegitimateClient(client) && !IsFakeClient(client)) {

		if (b_HealthModifier) SetEntProp(client, Prop_Send, "m_iMaxHealth", RoundToFloor(DefaultHealth[client] + s_Strength));
		else {

			//if (GetClientTeam(client) == TEAM_INFECTED) DefaultHealth[client] = GetMaximumHealth(client);DefaultHealth[client]	=	100;

			//SetEntProp(client, Prop_Send, "m_iMaxHealth", RoundToFloor(GetMaximumHealth(client) + (s_Strength * GetMaximumHealth(client))));
			if (IsFakeClient(client)) SetEntProp(client, Prop_Send, "m_iMaxHealth", RoundToFloor(s_Strength));
			else if (GetClientTeam(client) == TEAM_SURVIVOR) SetEntProp(client, Prop_Send, "m_iMaxHealth", 100 + RoundToFloor(s_Strength * 100));
			else if (GetClientTeam(client) == TEAM_INFECTED) SetEntProp(client, Prop_Send, "m_iMaxHealth", DefaultHealth[client]);
			//DefaultHealth[client]	=	GetMaximumHealth(client);
		}
	}
}

stock FindZombieClass(client)
{
	if (IsWitch(client)) return 7;
	if (IsSpecialCommon(client)) return 8;
	if (IsCommonInfected(client)) return 9;
	if (GetClientTeam(client) == TEAM_SURVIVOR) return 0;
	return GetEntProp(client, Prop_Send, "m_zombieClass");
}

stock SetInfectedHealth(client, value) {

	SetEntProp(client, Prop_Data, "m_iHealth", value);
}

stock GetInfectedHealth(client) {

	return GetEntProp(client, Prop_Data, "m_iHealth");
}

stock SetBaseHealth(client) {

	SetEntProp(client, Prop_Send, "m_iMaxHealth", OriginalHealth[client]);
}

stock GiveMaximumHealth(client)
{
	if (IsLegitimateClientAlive(client)) {

		if (!b_HardcoreMode[client]) {

			SetEntityHealth(client, GetMaximumHealth(client));
			SetEntPropFloat(client, Prop_Send, "m_healthBuffer", 0.0);
		}
		else {

			SetEntityHealth(client, 1);
			SetEntPropFloat(client, Prop_Send, "m_healthBuffer", (GetMaximumHealth(client) - 1) * 1.0);
		}
	}
}

stock GetMaximumHealth(client)
{
	if (IsLegitimateClient(client)) return GetEntProp(client, Prop_Send, "m_iMaxHealth");
	else return 0;
}

stock CloakingDevice(client, Float:s_Strength, Float:g_Time) {

	if (IsLegitimateClientAlive(client)) {

		SetEntityRenderMode(client, RENDER_TRANSCOLOR);
		SetEntityRenderColor(client, 255, 255, 255, 255 - RoundToCeil(s_Strength));
		CreateTimer(g_Time, Timer_CloakingDeviceBreakdown, client, TIMER_FLAG_NO_MAPCHANGE);
	}
}

stock AbsorbDamage(client, Float:s_Strength, damage) {

	if (IsLegitimateClientAlive(client)) {

		if (GetClientTeam(client) == TEAM_INFECTED || !IsIncapacitated(client)) {

			new absorb = RoundToFloor(s_Strength);
			if (absorb > damage) absorb = damage;

			SetEntityHealth(client, GetClientHealth(client) + absorb);
		}
	}
}

stock DamagePlayer(client, victim, Float:s_Strength) {

	if (IsLegitimateClientAlive(client) && IsLegitimateClientAlive(victim)) {

		new d_Damage = RoundToFloor(s_Strength);

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

	for (new i = 1; i <= MaxClients; i++) {

		DamageAward[client][i] = 0;
	}
}

stock ModifyHealth(client, Float:s_Strength, Float:g_Time) {

	if (IsLegitimateClientAlive(client)) {

		if (g_Time > 0.0) {

			SetMaximumHealth(client, true, s_Strength);
			CreateTimer(g_Time, Timer_ResetPlayerHealth, client, TIMER_FLAG_NO_MAPCHANGE);
		}
		else {

			if (GetClientTeam(client) == TEAM_INFECTED) {

				DefaultHealth[client] += RoundToCeil(OriginalHealth[client] * s_Strength);
				SetMaximumHealth(client, false, DefaultHealth[client] * 1.0);
			}
			else SetMaximumHealth(client, false, s_Strength);		// false means permanent.
		}
	}
}

stock ReflectDamage(client, victim, Float:g_TalentStrength, d_Damage) {

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
}

stock SendPanelToClientAndClose(Handle:panel, client, MenuHandler:handler, time) {

	SendPanelToClient(panel, client, handler, time);
	CloseHandle(panel);
}

stock CreateAcid(client, victim, Float:radius = 128.0) {

	if (IsLegitimateClientAlive(client) && IsFakeClient(client) || IsLegitimateClient(client) && !IsFakeClient(client)) {

		if (IsLegitimateClientAlive(victim)) {

			decl Float:pos[3];
			GetClientAbsOrigin(victim, pos);
			pos[2] += 12.0;
			new acidball = CreateEntityByName("spitter_projectile");
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

stock ForceClientJump(client, victim, Float:g_TalentStrength) {

	if (IsLegitimateClientAlive(victim)) {

		if (GetEntityFlags(victim) & FL_ONGROUND || !b_GroundRequired[victim]) {

			new attacker = L4D2_GetInfectedAttacker(victim);
			if (attacker == -1 || !IsClientActual(attacker) || GetClientTeam(attacker) != TEAM_INFECTED || (FindZombieClass(attacker) != ZOMBIECLASS_JOCKEY && FindZombieClass(attacker) != ZOMBIECLASS_CHARGER)) attacker = -1;

			if (IsClientActual(victim)) {

				new Float:vel[3];
				vel[0] = GetEntPropFloat(victim, Prop_Send, "m_vecVelocity[0]");
				vel[1] = GetEntPropFloat(victim, Prop_Send, "m_vecVelocity[1]");
				vel[2] = GetEntPropFloat(victim, Prop_Send, "m_vecVelocity[2]");
				vel[2] += g_TalentStrength;
				TeleportEntity(victim, NULL_VECTOR, NULL_VECTOR, vel);
				if (attacker != -1) TeleportEntity(attacker, NULL_VECTOR, NULL_VECTOR, vel);
			}
		}
	}
}

stock ActivateAbilityEx(target, activator, d_Damage, String:Effects[], Float:g_TalentStrength, Float:g_TalentTime, victim = 0) {

	// Activator is ALWAYS the person who holds the talent. The TARGET is who the ability ALWAYS activates on.

	if (g_TalentStrength > 0.0) {

		if (FindCharInString(Effects, 'a') != -1) SDKCall(g_hEffectAdrenaline, target, g_TalentTime);
		if (FindCharInString(Effects, 'A') != -1 && GetClientTeam(target) == TEAM_SURVIVOR) {

			SDKCall(hRoundRespawn, target);
			CreateTimer(1.0, Timer_TeleportRespawn, target, TIMER_FLAG_NO_MAPCHANGE);
		}
		if (FindCharInString(Effects, 'b') != -1) BeanBag(target, g_TalentStrength);
		if (FindCharInString(Effects, 'B') != -1) BlindPlayer(target, g_TalentTime, RoundToFloor((g_TalentStrength * 100.0) * 2.55));
		if (FindCharInString(Effects, 'c') != -1) {

			//CreateCombustion(target, g_TalentStrength, g_TalentTime);
			CreateAndAttachFlame(target, RoundToCeil(d_Damage * g_TalentStrength), 3.0, 0.5);
		}
		if (FindCharInString(Effects, 'd') != -1) {

			if (IsWitch(victim)) AddWitchDamage(activator, victim, RoundToCeil(d_Damage * g_TalentStrength));
			else if (IsSpecialCommon(victim)) AddSpecialCommonDamage(activator, victim, RoundToCeil(d_Damage * g_TalentStrength));
			else if (IsCommonInfected(victim)) AddCommonInfectedDamage(activator, victim, RoundToCeil(d_Damage * g_TalentStrength));
			else DamageBonus(activator, victim, d_Damage, g_TalentStrength);
		}
		//if (FindCharInString(Effects, 'D') != -1) DamageIncrease(target, g_TalentTime, g_TalentStrength, true);
		if (FindCharInString(Effects, 'f') != -1) CreateFireEx(target);
		if (FindCharInString(Effects, 'e') != -1) CreateBeacons(target, g_TalentStrength);
		if (FindCharInString(Effects, 'E') != -1) SetTempHealth(activator, target, g_TalentStrength);
		if (FindCharInString(Effects, 'g') != -1) ModifyGravity(target, g_TalentStrength, g_TalentTime, true);
		if (FindCharInString(Effects, 'h') != -1) {

			if (target != activator && IsLegitimateClientAlive(activator)) AwardHealingPoints(activator, target, RoundToCeil(g_TalentStrength));
			HealPlayer(target, activator, g_TalentStrength, 'h');
		}
		if (FindCharInString(Effects, 'u') != -1) {

			if (target != activator && IsLegitimateClientAlive(activator)) AwardHealingPoints(activator, target, d_Damage);
			HealPlayer(target, activator, d_Damage * 1.0, 'h');
		}
		if (FindCharInString(Effects, 'H') != -1) {

			//PrintToChatAll("Modifying health.");
			ModifyHealth(target, g_TalentStrength, g_TalentTime);
		}
		if (FindCharInString(Effects, 'i') != -1) {

			SDKCall(g_hCallVomitOnPlayer, activator, target, true);
			CoveredInBile[target][activator] = 0;
			new Handle:packe;
			CreateDataTimer(g_TalentTime, Timer_CoveredInBile, packe, TIMER_FLAG_NO_MAPCHANGE);
			WritePackCell(packe, activator);
			WritePackCell(packe, target);
		}
		if (FindCharInString(Effects, 'j') != -1) ForceClientJump(activator, target, g_TalentStrength);
		if (FindCharInString(Effects, 'k') != -1) {

			if (IsCommonInfected(target) && !IsSpecialCommon(target)) {

				CommonsKilled++;
				CommonKills[activator]++;
				if (CommonKills[activator] >= StringToInt(GetConfigValue("common kills award required?"))) {

					ExperienceLevel[activator] += StringToInt(GetConfigValue("common experience award?"));
					ExperienceOverall[activator] += StringToInt(GetConfigValue("common experience award?"));
					if (ExperienceLevel[activator] > CheckExperienceRequirement(activator)) {

						ExperienceOverall[activator] -= (ExperienceLevel[activator] - CheckExperienceRequirement(activator));
						ExperienceLevel[activator] = CheckExperienceRequirement(activator);
					}
					ConfirmExperienceAction(activator);
					if (StringToInt(GetConfigValue("display common kills award?")) == 1) PrintToChat(activator, "%T", "common kills award", activator, white, green, GetConfigValue("common experience award?"), white);
					CommonKills[activator] = 0;
					if (StringToInt(GetConfigValue("hint text broadcast?")) == 1) ExperienceBarBroadcast(activator);
				}
				SDKUnhook(target, SDKHook_OnTakeDamage, OnTakeDamage);
				AcceptEntityInput(target, "Kill");
				FindAbilityByTrigger(activator, 0, 'C', FindZombieClass(activator), d_Damage);
				if (IsLegitimateClientAlive(activator) && !IsFakeClient(activator) && GetClientTeam(activator) == TEAM_SURVIVOR && IsIncapacitated(activator)) {

					FindAbilityByTrigger(activator, activator, 'k', FindZombieClass(activator), 0);
				}
			}
			else if (IsLegitimateClientAlive(target) && GetClientTeam(target) == TEAM_INFECTED) CalculateInfectedDamageAward(victim);
			//ForcePlayerSuicide(target);
		}
		if (FindCharInString(Effects, 'l') != -1) CloakingDevice(target, g_TalentStrength, g_TalentTime);
		if (FindCharInString(Effects, 'm') != -1) DamagePlayer(activator, target, g_TalentStrength);
		if (FindCharInString(Effects, 'M') != -1) ModifyPlayerAmmo(target, g_TalentStrength);
		if (FindCharInString(Effects, 'n') != -1) IncapHealPlayer(target, activator, g_TalentStrength, g_TalentTime);
		if (FindCharInString(Effects, 'o') != -1) AbsorbDamage(target, g_TalentStrength, d_Damage);
		if (FindCharInString(Effects, 'p') != -1) SpeedIncrease(target, g_TalentTime, g_TalentStrength, false);
		if (FindCharInString(Effects, 'P') != -1) SpeedIncrease(target, g_TalentTime, g_TalentStrength, true);
		if (FindCharInString(Effects, 'r') != -1) AttemptRevivePlayer(target, g_TalentTime, g_TalentStrength);
		if (FindCharInString(Effects, 'R') != -1) ReflectDamage(activator, target, g_TalentStrength, d_Damage);
		if (FindCharInString(Effects, 's') != -1) SlowPlayer(target, g_TalentStrength, g_TalentTime);
		if (FindCharInString(Effects, 'S') != -1) L4D_StaggerPlayer(target, activator, NULL_VECTOR);
		if (FindCharInString(Effects, 't') != -1) CreateAcid(activator, target, 512.0);
		if (FindCharInString(Effects, 'T') != -1) HealPlayer(target, activator, g_TalentStrength, 'T');
		if (FindCharInString(Effects, 'x') != -1) {

			if (IsPlayerAlive(target) && !IsGhost(target) && GetClientTeam(target) == TEAM_INFECTED && FindZombieClass(target) == ZOMBIECLASS_BOOMER) {

				SetEntityHealth(target, 1);
				IgniteEntity(target, 1.0);
			}
		}
		if (FindCharInString(Effects, 'z') != -1) ZeroGravity(activator, target, g_TalentStrength, g_TalentTime);
	}
}

stock ModifyPlayerAmmo(target, Float:g_TalentStrength) {

	new PlayerWeapon = GetPlayerWeaponSlot(target, 0);
	if (!IsValidEntity(PlayerWeapon)) return;

	new PlayerAmmo = GetEntProp(PlayerWeapon, Prop_Send, "m_iClip1", 1);
	//new PlayerMaxAmmo = GetEntProp(PlayerWeapon, Prop_Send, "m_iMaxClip1", 1);
	new PlayerAmmoAward = RoundToCeil(g_TalentStrength * PlayerAmmo);
	PlayerAmmoAward = GetRandomInt(1, PlayerAmmoAward);

	/*

		If the players clip reaches the max, it resets to the default.
	*/
	//new PlayerMaxIncrease = PlayerMaxAmmo + RoundToCeil(PlayerMaxAmmo * g_TalentStrength);
	SetEntProp(PlayerWeapon, Prop_Send, "m_iClip1", PlayerAmmo + PlayerAmmoAward, 1);

	//if (PlayerAmmo + PlayerAmmoAward >= PlayerMaxIncrease) SetEntProp(PlayerWeapon, Prop_Send, "m_iClip1", PlayerMaxAmmo, 1);
}

stock AttemptRevivePlayer(target, Float:g_TalentTime, Float:g_TalentStrength) {

	if (GetClientTeam(target) != TEAM_SURVIVOR || !IsIncapacitated(target)) return;
	SDKCall(hRevive, target);

	ModifyTempHealth(target, g_TalentTime, g_TalentStrength);
}

stock ModifyTempHealth(target, Float:g_TalentTime, Float:g_TalentStrength) {

	new PlayerMaximumHealth = GetMaximumHealth(target);
	SetEntPropFloat(target, Prop_Send, "m_healthBuffer", RoundToCeil(PlayerMaximumHealth * g_TalentStrength) * 1.0);
	if (g_TalentTime > 0.0) CreateTimer(g_TalentTime, Timer_SetTempHealth, target, TIMER_FLAG_NO_MAPCHANGE);
}

public Action:Timer_SetTempHealth(Handle:timer, any:client) {

	if (IsLegitimateClientAlive(client)) {

		FindAbilityByTrigger(client, 0, 'R', FindZombieClass(client), 0);
	}
	return Plugin_Stop;
}

stock bool:RestrictedWeaponList(String:WeaponName[]) {	// Some weapons might be insanely powerful, so we see if they're in this string and don't let them damage multiplier if they are.

	decl String:RestrictedWeapons[512];
	Format(RestrictedWeapons, sizeof(RestrictedWeapons), "%s", GetConfigValue("restricted weapons?"));
	if (StrContains(RestrictedWeapons, WeaponName, false) != -1) return true;
	return false;
}

stock CheckExperienceRequirement(client, bool:bot = false, iLevel = 0) {

	new experienceRequirement = 0;
	if (client == -1 || IsLegitimateClient(client)) {

		experienceRequirement			=	StringToInt(GetConfigValue("experience start?"));
		new Float:experienceMultiplier	=	0.0;

		if (client != -1) {

			if (iLevel == 0) experienceMultiplier		=	StringToFloat(GetConfigValue("requirement multiplier?")) * (PlayerLevel[client] - 1);
			else experienceMultiplier = StringToFloat(GetConfigValue("requirement multiplier?")) * (iLevel - 1);
		}
		else experienceMultiplier					=	StringToFloat(GetConfigValue("requirement multiplier?")) * (PlayerLevel_Bots - 1);

		experienceRequirement			+=	RoundToCeil(experienceRequirement * experienceMultiplier);
	}

	return experienceRequirement;
}

stock StrengthValue(client) {

	if (GetRandomInt(1, 100) <= Luck[client]) return GetRandomInt(0, Strength[client]);
	return 0;
}

stock bool:IsAbilityImmune(client, String:TalentName[]) {

	if (IsClientActual(client)) {

		new a_Size				=	0;
		if (!IsFakeClient(client)) a_Size					=	GetArraySize(a_Database_PlayerTalents[client]);
		else a_Size											=	GetArraySize(a_Database_PlayerTalents_Bots);

		decl String:Name[PLATFORM_MAX_PATH];

		for (new i = 0; i < a_Size; i++) {

			GetArrayString(Handle:a_Database_Talents, i, Name, sizeof(Name));
			if (StrEqual(Name, TalentName)) {

				decl String:t_Cooldown[8];
				if (!IsFakeClient(client)) GetArrayString(Handle:PlayerAbilitiesImmune[client], i, t_Cooldown, sizeof(t_Cooldown));
				else GetArrayString(Handle:PlayerAbilitiesImmune_Bots, i, t_Cooldown, sizeof(t_Cooldown));
				if (StrEqual(t_Cooldown, "1")) return true;
				break;
			}
		}
	}
	return false;
}

/*

	This function is called when a common infected is spawned, and attempts to roll for affixes.
*/
stock CreateCommonAffix(entity) {

	new size = GetArraySize(a_CommonAffixes);
	new Float:flMovementSpeed = 1.0;

	//decl String:EntityId[64];
	//Format(EntityId, sizeof(EntityId), "%d", entity);

	new Float:RollChance = 0.0;
	decl String:Section_Name[64];

	for (new i = 0; i < size; i++) {

		CCASection			= GetArrayCell(a_CommonAffixes, i, 2);
		CCAKeys				= GetArrayCell(a_CommonAffixes, i, 0);
		CCAValues			= GetArrayCell(a_CommonAffixes, i, 1);

		//if (GetArraySize(AfxSection) < 1 || GetArraySize(AfxKeys) < 1) continue;

		RollChance = StringToFloat(GetKeyValue(CCAKeys, CCAValues, "chance?"));
		//LogMessage("Roll is 1 - %d (Roll Chance is %3.3f)", RoundToCeil(1.0 / RollChance), RollChance);

		if (GetRandomInt(1, RoundToCeil(1.0 / RollChance)) > 1) {

			continue;		// == 1 for successful roll
		}
		//LogMessage("Common %d rolled successfully!", entity);
		GetArrayString(Handle:CCASection, 0, Section_Name, sizeof(Section_Name));
		
		Format(Section_Name, sizeof(Section_Name), "%s:%d", Section_Name, entity);

		PushArrayString(Handle:CommonAffixes, Section_Name);
		OnCommonCreated(entity);

		//	Now that we've confirmed this common is special, let's go ahead and activate pertinent functions...
		//	Doing some of these, repeatedly, in a timer is a) wasteful and b) crashy. I know, from experience.

		if (StringToInt(GetKeyValue(CCAKeys, CCAValues, "glow?")) == 1) {

			SetEntProp(entity, Prop_Send, "m_iGlowType", 3);
			SetEntProp(entity, Prop_Send, "m_nGlowRange", RoundToCeil(StringToFloat(GetKeyValue(CCAKeys, CCAValues, "glow range?"))));
			decl String:iglowColour[3][4];
			ExplodeString(GetKeyValue(CCAKeys, CCAValues, "glow colour?"), " ", iglowColour, 3, 4);
			SetEntProp(entity, Prop_Send, "m_glowColorOverride", StringToInt(iglowColour[0]) + (StringToInt(iglowColour[1]) * 256) + (StringToInt(iglowColour[2]) * 65536));
			AcceptEntityInput(entity, "StartGlowing");
		}
		if (FindCharInString(GetKeyValue(CCAKeys, CCAValues, "aura effect?"), 'f') != -1) {

			/*new common = entity;

			new entityflame = CreateEntityByName("entityflame");
			DispatchSpawn(entityflame);
			new Float:vPos[3];
			GetEntPropVector(common, Prop_Data, "m_vecOrigin", vPos);
			TeleportEntity(entityflame, vPos, NULL_VECTOR, NULL_VECTOR);
			SetEntPropFloat(entityflame, Prop_Data, "m_flLifetime", 6000.0);
			SetEntPropEnt(entityflame, Prop_Data, "m_hEntAttached", common);
			SetEntPropEnt(entityflame, Prop_Send, "m_hEntAttached", common);
			SetEntPropEnt(common, Prop_Data, "m_hEffectEntity", entityflame);
			SetEntPropEnt(common, Prop_Send, "m_hEffectEntity", entityflame);
			ActivateEntity(entityflame);
			AcceptEntityInput(entityflame, "Enable");

			decl String:sTemp[16];
			Format(sTemp, sizeof(sTemp), "fire%d%d", entityflame, common);
			DispatchKeyValue(common, "targetname", sTemp);
			SetVariantString(sTemp);
			AcceptEntityInput(entityflame, "IgniteEntity", common, common, 600);
			SetVariantString(sTemp);
			AcceptEntityInput(entityflame, "Ignite", common, common, 600);*/
			CreateAndAttachFlame(entity);
		}
		SetEntPropFloat(entity, Prop_Send, "m_flModelScale", StringToFloat(GetKeyValue(CCAKeys, CCAValues, "model size?")));
		flMovementSpeed = StringToFloat(GetKeyValue(CCAKeys, CCAValues, "movement speed?"));
		if (flMovementSpeed < 0.5) flMovementSpeed = 1.0;
		SetEntPropFloat(entity, Prop_Data, "m_flSpeed", flMovementSpeed);
		return;		// we only create one affix on a common. maybe we'll allow more down the road.
	}
	// If no special common affix was successful, it's a standard common.
	OnCommonInfectedCreated(entity);


	//ClearArray(Handle:AfxSection);
	//ClearArray(Handle:AfxKeys);
	//ClearArray(Handle:AfxValues);
	//LogMessage("This common remains normal... %d", entity);
}

stock ReflectionDamage(client, victim, player, damage, Float:lifetime = 3.0, Float:tickInt = 1.0) {

	if (!IsClientStatusEffect(client, Handle:EntityReflect)) {

		new Float:ClientPosition[3];
		new Float:TargetPosition[3];
		GetEntPropVector(client, Prop_Send, "m_vecOrigin", ClientPosition);
		if (IsWitch(victim) || IsCommonInfected(victim)) GetEntPropVector(victim, Prop_Send, "m_vecOrigin", TargetPosition);
		else if (IsLegitimateClientAlive(victim)) GetClientAbsOrigin(victim, TargetPosition);
		else return;

		if (damage > 0) {

			/*

				Reflection damage. Ouch :()
			*/

			CreateLine(client, victim, "darkgreen");

			decl String:t_EntityReflect[64];
			Format(t_EntityReflect, sizeof(t_EntityReflect), "p:%d_v:%d_d:%d_l:%3.2f_i:%3.2f", player, victim, damage, lifetime, tickInt);
			LogMessage("REFLECT LINK START %s", t_EntityReflect);
			PushArrayString(Handle:EntityReflect, t_EntityReflect);
		}

		/*if (IsWitch(victim)) {

			if (FindListPositionByEntity(victim, Handle:WitchList) >= 0) AddWitchDamage(player, victim, damage);
			else OnWitchCreated(victim, true);
		}
		else if (IsSpecialCommon(victim)) AddSpecialCommonDamage(player, victim, damage);
		else if (IsCommonInfected(victim)) AddCommonInfectedDamage(player, victim, damage);
		else if (IsLegitimateClientAlive(victim)) {

			if (GetClientTotalHealth(victim) > damage) SetClientTotalHealth(victim, damage); //SetEntityHealth(victim, GetClientHealth(victim) - CommonsDamage);
			else if (GetClientTotalHealth(victim) <= damage) IncapacitateOrKill(victim, client);
		}
		CreateLine(client, victim, "darkgreen");*/
	}
}

public Action:Timer_EntityReflection(Handle:timer) {

	decl String:Value[64];
	decl String:Evaluate[5][64];
	new Activator = -1;
	new Client = -1;
	new damage = 0;
	new Float:FlTime = 0.0;
	new Float:TickInt = 1.0;
	new t_Damage = 0;
	decl String:t_Delim[2][64];
	decl String:t_EntityReflect[64];

	decl String:Remainder[64];

	if (!b_IsActiveRound) {

		ClearArray(Handle:CommonInfected);
		for (new i = 1; i <= MaxClients; i++) {

			if (IsLegitimateClient(i)) ClearArray(Handle:CommonInfectedDamage[i]);
		}
		return Plugin_Stop;
	}

	new size = GetArraySize(Handle:EntityReflect);
	for (new i = 0; i < size; i++) {

		GetArrayString(Handle:EntityReflect, i, Value, sizeof(Value));
		ExplodeString(Value, "_", Evaluate, 5, 64);
		ExplodeString(Evaluate[0], ":", t_Delim, 2, 64);
		Activator = StringToInt(t_Delim[1]);

		ExplodeString(Evaluate[1], ":", t_Delim, 2, 64);
		Client = StringToInt(t_Delim[1]);
		if (!IsLegitimateClientAlive(Activator) || (!IsCommonInfected(Client) && !IsWitch(Client) && !IsLegitimateClientAlive(Client))) {

			RemoveFromArray(Handle:EntityReflect, i);
			i--;
			size = GetArraySize(Handle:EntityReflect);
			continue;
		}
		ExplodeString(Evaluate[2], ":", t_Delim, 2, 64);
		damage = StringToInt(t_Delim[1]);
		ExplodeString(Evaluate[3], ":", t_Delim, 2, 64);
		FlTime = StringToFloat(t_Delim[1]);
		ExplodeString(Evaluate[4], ":", t_Delim, 2, 64);
		TickInt = StringToFloat(t_Delim[1]);

		FlTime -= 0.01;

		Format(Remainder, sizeof(Remainder), "%3.2f", FlTime / TickInt);
		if (StrContains(Remainder, ".00", false) != -1) {

			//Remainder = RoundToCeil(Counter % TickInt);
			//if (Remainder != 0) continue;	// Tick interval is influenced by CARTEL so is different for each player.

			t_Damage = RoundToCeil(damage / (FlTime / TickInt));
			damage -= t_Damage;
			if (IsLegitimateClientAlive(Client)) {

				//PrintToChatAll("Ouch! Taking %d reflect damage!", t_Damage);
				//LogMessage("Reflecting damage (%d) at %N %s", t_Damage, Client, Value);

				if (t_Damage > GetClientHealth(Client)) IncapacitateOrKill(Client);
				else SetEntityHealth(Client, GetClientHealth(Client) - t_Damage);
			}
			else EntityStatusEffectDamage(Client, t_Damage);
		}

		if (FlTime <= 0.0) {

			RemoveFromArray(Handle:EntityReflect, i);
			i--;
			size = GetArraySize(Handle:EntityReflect);
			continue;
		}
		Format(t_EntityReflect, sizeof(t_EntityReflect), "p:%d_v:%d_d:%d_l:%3.2f_i:%3.2f", Activator, Client, damage, FlTime, TickInt);
		SetArrayString(Handle:EntityReflect, i, t_EntityReflect);
	}
	return Plugin_Continue;
}

/*

		2nd / 3rd args have defaults for use with special common infected.
		When these special commons explode, they can apply custom versions of these flames to players
		and the plugin will check every so often to see if a player has such an entity attached to them.
		If they do, they'll burn. Players can have multiple of these, so it is dangerous.
*/
stock CreateAndAttachFlame(client, damage = 0, Float:lifetime = 600.0, Float:tickInt = 1.0) {

	if (!IsClientStatusEffect(client, Handle:EntityOnFire)) {

		new FlameEntity = CreateEntityByName("entityflame");

		new Float:ClientPosition[3];
		if (IsLegitimateClientAlive(client)) GetClientAbsOrigin(client, ClientPosition);
		else if (IsCommonInfected(client) || IsWitch(client)) GetEntPropVector(client, Prop_Send, "m_vecOrigin", ClientPosition);

		DispatchSpawn(FlameEntity);
		TeleportEntity(FlameEntity, ClientPosition, NULL_VECTOR, NULL_VECTOR);
		if (!IsLegitimateClient(client)) SetEntPropFloat(FlameEntity, Prop_Data, "m_flLifetime", 600.0);
		else SetEntPropFloat(FlameEntity, Prop_Data, "m_flLifetime", lifetime);
		SetEntPropEnt(FlameEntity, Prop_Data, "m_hEntAttached", client);
		SetEntPropEnt(FlameEntity, Prop_Send, "m_hEntAttached", client);
		SetEntPropEnt(client, Prop_Data, "m_hEffectEntity", FlameEntity);
		SetEntPropEnt(client, Prop_Send, "m_hEffectEntity", FlameEntity);
		ActivateEntity(FlameEntity);
		AcceptEntityInput(FlameEntity, "Enable");

		decl String:sTemp[16];
		Format(sTemp, sizeof(sTemp), "fire%d%d", FlameEntity, client);

		DispatchKeyValue(client, "targetname", sTemp);
		SetVariantString(sTemp);
		AcceptEntityInput(FlameEntity, "IgniteEntity", client, client, 600);
		SetVariantString(sTemp);
		AcceptEntityInput(FlameEntity, "Ignite", client, client, 600);

		if (damage > 0) {

			decl String:t_EntityOnFire[64];
			Format(t_EntityOnFire, sizeof(t_EntityOnFire), "f:%d_o:%d_d:%d_l:%3.2f_i:%3.2f", FlameEntity, client, damage, lifetime, tickInt);
			PushArrayString(Handle:EntityOnFire, t_EntityOnFire);
		}
	}
}

stock bool:IsClientStatusEffect(client, Handle:EffectHandle) {

	new size = GetArraySize(Handle:EffectHandle);
	decl String:Evaluate[5][64];
	decl String:Value[64];
	decl String:NewV[64];
	decl String:ClientN[2][64];
	for (new i = 0; i < size; i++) {

		GetArrayString(Handle:EffectHandle, i, Value, sizeof(Value));
		ExplodeString(Value, "_", Evaluate, 5, 64);
		Format(NewV, sizeof(NewV), "%s", Evaluate[1]);
		ExplodeString(NewV, ":", ClientN, 2, 64);
		Format(NewV, sizeof(NewV), "%d", client);

		if (StrEqual(ClientN[1], NewV, false)) return true;
	}
	return false;
}

public Action:Timer_EntityOnFire(Handle:timer) {

	decl String:Value[64];
	decl String:Evaluate[5][64];
	new EntityFlame = -1;
	new Client = -1;
	new damage = 0;
	new Float:FlTime = 0.0;
	new Float:TickInt = 1.0;
	new t_Damage = 0;
	decl String:t_Delim[2][64];
	decl String:t_EntityOnFire[64];

	decl String:EntityClassname[64];
	decl String:Remainder[64];

	if (!b_IsActiveRound) {

		ClearArray(Handle:CommonInfected);
		for (new i = 1; i <= MaxClients; i++) {

			if (IsLegitimateClient(i)) ClearArray(Handle:CommonInfectedDamage[i]);
		}
		return Plugin_Stop;
	}

	new size = GetArraySize(Handle:EntityOnFire);
	for (new i = 0; i < size; i++) {

		GetArrayString(Handle:EntityOnFire, i, Value, sizeof(Value));
		ExplodeString(Value, "_", Evaluate, 5, 64);
		ExplodeString(Evaluate[0], ":", t_Delim, 2, 64);
		EntityFlame = StringToInt(t_Delim[1]);

		/*

			If the entity has expired, delete it, move on.
		*/
		if (!IsValidEntity(EntityFlame)) {

			RemoveFromArray(Handle:EntityOnFire, i);
			i--;
			size = GetArraySize(Handle:EntityOnFire);
			continue;
		}
		GetEntityClassname(EntityFlame, EntityClassname, sizeof(EntityClassname));
		if (!StrEqual(EntityClassname, "entityflame", false)) {

			/*

				If the entity exists, but it has expired (ie a different entity occupies its pos) delete it.
			*/
			AcceptEntityInput(EntityFlame, "Kill");
			RemoveFromArray(Handle:EntityOnFire, i);
			i--;
			size = GetArraySize(Handle:EntityOnFire);
			continue;
		}
		/*

			The entity is a flame, time to find out who it's attached to.
		*/
		ExplodeString(Evaluate[1], ":", t_Delim, 2, 64);
		Client = StringToInt(t_Delim[1]);
		if (!IsCommonInfected(Client) && !IsWitch(Client) && !IsLegitimateClientAlive(Client)) {

			/*

				The stored client is not a common infected (or special common), it isn't a witch, and if it's a player, it's not living, so we remove it.
			*/
			AcceptEntityInput(EntityFlame, "Kill");
			RemoveFromArray(Handle:EntityOnFire, i);
			i--;
			size = GetArraySize(Handle:EntityOnFire);
			continue;
		}
		/*

			Grab the damage n stuff
		*/
		ExplodeString(Evaluate[2], ":", t_Delim, 2, 64);
		damage = StringToInt(t_Delim[1]);
		//if (damage == 0) continue;	// for the mobs we don't want to deal damage to / we want the fire to exist until they die.

		ExplodeString(Evaluate[3], ":", t_Delim, 2, 64);
		FlTime = StringToFloat(t_Delim[1]);
		ExplodeString(Evaluate[4], ":", t_Delim, 2, 64);
		TickInt = StringToFloat(t_Delim[1]);

		FlTime -= 0.01;

		Format(Remainder, sizeof(Remainder), "%3.2f", FlTime / TickInt);
		if (StrContains(Remainder, ".00", false) != -1) {

			t_Damage = RoundToCeil(damage / (FlTime / TickInt));
			damage -= t_Damage;
			if (IsLegitimateClientAlive(Client)) {

				//PrintToChatAll("Ouch! Taking %d Fire damage!", t_Damage);
				//LogMessage("Reflecting damage (%d) at %N %s", t_Damage, Client, Value);
				if (t_Damage > GetClientHealth(Client)) IncapacitateOrKill(Client);
				else SetEntityHealth(Client, GetClientHealth(Client) - t_Damage);
			}
			else {

				/*

					Health pools are instanced for commons and witches.
				*/
				EntityStatusEffectDamage(Client, t_Damage);
			}
		}
		if (FlTime <= 0.0) {

			AcceptEntityInput(EntityFlame, "Kill");
			RemoveFromArray(Handle:EntityOnFire, i);
			i--;
			size = GetArraySize(Handle:EntityOnFire);
			continue;
		}
		Format(t_EntityOnFire, sizeof(t_EntityOnFire), "f:%d_o:%d_d:%d_l:%3.2f_i:%3.2f", EntityFlame, Client, damage, FlTime, TickInt);
		LogMessage("ON FIRE CONTINUE %s", t_EntityOnFire);
		SetArrayString(Handle:EntityOnFire, i, t_EntityOnFire);
	}
	return Plugin_Continue;
}

stock CreateCombustion(client, Float:g_Strength, Float:f_Time)
{
	new entity				= CreateEntityByName("env_fire");
	new Float:loc[3];
	GetClientAbsOrigin(client, loc);

	decl String:s_Strength[64];
	Format(s_Strength, sizeof(s_Strength), "%3.3f", g_Strength);

	DispatchKeyValue(entity, "StartDisabled", "0");
	DispatchKeyValue(entity, "damagescale", s_Strength);
	decl String:s_Health[64];
	Format(s_Health, sizeof(s_Health), "%3.3f", f_Time);

	DispatchKeyValue(entity, "fireattack", "2");
	DispatchKeyValue(entity, "firesize", "128");
	DispatchKeyValue(entity, "health", s_Health);
	DispatchKeyValue(entity, "ignitionpoint", "1");
	DispatchSpawn(entity);

	TeleportEntity(entity, Float:loc, NULL_VECTOR, NULL_VECTOR);
	AcceptEntityInput(entity, "Enable");
	AcceptEntityInput(entity, "StartFire");
	
	CreateTimer(f_Time, Timer_DestroyCombustion, entity, TIMER_FLAG_NO_MAPCHANGE);
}

public Action:Timer_PeriodicTalents(Handle:timer) {

	//PrintToChatAll("Periodic timer.");
	if (!b_IsActiveRound) return Plugin_Stop;
	//PrintToChatAll("Periodic timer is active.");
	for (new i = 1; i <= MaxClients; i++) {

		if (!IsLegitimateClient(i)) continue;
		if (IsPlayerAlive(i) && GetClientTeam(i) == TEAM_INFECTED ||
			!IsFakeClient(i) && GetClientTeam(i) == TEAM_SURVIVOR && L4D2_GetInfectedAttacker(i) == -1) {

			//PrintToChatAll("Searching for abilities");
			FindAbilityByTrigger(i, 0, 'p', FindZombieClass(i), 0);
		}
	}

	return Plugin_Continue;
}

stock GetSpecialCommonDamage(damage, client, Effect, victim) {

	/*

		Victim is always a survivor, and is only used to pass to the GetCommonsInRange function which uses their level
		to determine its range of buff.
	*/
	new Float:f_Strength = 1.0;

	new Float:ClientPos[3], Float:fEntPos[3];
	if (IsCommonInfected(client) || IsWitch(client)) GetEntPropVector(client, Prop_Send, "m_vecOrigin", ClientPos);
	else if (IsLegitimateClientAlive(client)) GetClientAbsOrigin(client, ClientPos);

	new ent = -1;
	while ((ent = FindEntityByClassname(ent, "infected")) != -1) {

		if (ent != client && IsSpecialCommon(ent) && FindCharInString(GetCommonValue(ent, "aura effect"), Effect) != -1) {

			GetEntPropVector(ent, Prop_Send, "m_vecOrigin", fEntPos);
			/*

				If the damaging common is in range of an entity meeting the specific effect, then we add its effects. In this case, it's damage.
			*/
			if (IsInRange(fEntPos, ClientPos, StringToFloat(GetCommonValue(ent, "range max?")), StringToFloat(GetCommonValue(ent, "model size?")))) {

				f_Strength += (StringToFloat(GetCommonValue(ent, "strength target?")) * GetEntitiesInRange(ent, victim, 0));
				f_Strength += (StringToFloat(GetCommonValue(ent, "strength special?")) * GetEntitiesInRange(ent, victim, 1));
			}
		}
	}
	return RoundToCeil(damage * f_Strength);
}

stock GetEntitiesInRange(client, victim, EntityType) {

	new Float:ClientPos[3];
	GetEntPropVector(client, Prop_Send, "m_vecOrigin", ClientPos);

	new Float:AfxRange		= StringToFloat(GetCommonValue(client, "range player level?")) * PlayerLevel[victim];
	new Float:AfxRangeMax	= StringToFloat(GetCommonValue(client, "range max?"));
	new Float:ModelSize		= StringToFloat(GetCommonValue(client, "model size?"));
	new Float:AfxRangeBase	= StringToFloat(GetCommonValue(client, "range minimum?"));
	if (AfxRange + AfxRangeBase > AfxRangeMax) AfxRange = AfxRangeMax;
	else AfxRange += AfxRangeBase;

	new ent = -1;
	new Float:EntPos[3];

	new count = 0;
	if (EntityType == 0) {

		while ((ent = FindEntityByClassname(ent, "infected")) != -1) {

			if (ent != client) {

				GetEntPropVector(ent, Prop_Send, "m_vecOrigin", EntPos);
				if (IsInRange(ClientPos, EntPos, AfxRange, ModelSize)) count++;
			}
		}
	}
	else {

		for (new i = 1; i <= MaxClients; i++) {

			if (IsLegitimateClientAlive(i) && GetClientTeam(i) == TEAM_INFECTED) {

				GetClientAbsOrigin(i, EntPos);
				if (IsInRange(ClientPos, EntPos, AfxRange, ModelSize)) count++;
			}
		}
	}
	return count;
}

stock bool:IsSpecialCommonInRange(client, Effect = -1, vEntity = -1, bool:IsAuraEffect = true) {	// false for death effect

	new Float:ClientPos[3];
	new Float:fEntPos[3];
	if (IsCommonInfected(client) || IsWitch(client)) GetEntPropVector(client, Prop_Send, "m_vecOrigin", ClientPos);
	else if (IsLegitimateClientAlive(client)) GetClientAbsOrigin(client, ClientPos);

	new ent = -1;
	while ((ent = FindEntityByClassname(ent, "infected")) != -1) {

		if (vEntity >= 0 && ent != vEntity) continue;

		if (ent != client) {

			if (IsSpecialCommon(ent)) {

				if (IsAuraEffect && FindCharInString(GetCommonValue(ent, "aura effect?"), Effect) != -1 || !IsAuraEffect && FindCharInString(GetCommonValue(ent, "death effect?"), Effect) != -1) {

					GetEntPropVector(ent, Prop_Send, "m_vecOrigin", fEntPos);
					if (IsInRange(fEntPos, ClientPos, StringToFloat(GetCommonValue(ent, "range max?")), StringToFloat(GetCommonValue(ent, "model size?")))) return true;
				} 
			}
		}
	}
	return false;
}

/*

	This timer runs 100 times / second. =)
	Overseer of the Common Affixes Program or CAP.
*/

public Action:Timer_CommonAffixes(Handle:timer) {

	if (!b_IsActiveRound) {

		for (new i = 1; i <= MaxClients; i++) {

			ClearArray(CommonAffixesCooldown[i]);
			ClearArray(SpecialCommon[i]);
		}
		ClearArray(Handle:CommonAffixes);
		ClearArray(Handle:CommonList);
		new ent = -1;
		//decl String:Model[64];
		while ((ent = FindEntityByClassname(ent, "infected")) != -1) {

			//LogMessage("Removing Defibrillators");
			AcceptEntityInput(ent, "Kill");
		}
		return Plugin_Stop;
	}
	decl String:Section_Name[64];
	decl String:AffixName[64];
	decl String:t_AffixName[2][64];
	new entity = -1;
	new affix = -1;

	/*

		For any common affixes that require drawing, we do that now, before we run through the affixes that are always requiring player-detection, like aoe abilities.
	*/
	for (new i = 0; i < GetArraySize(CommonAffixes); i++) {

		GetArrayString(Handle:CommonAffixes, i, Section_Name, sizeof(Section_Name));
		entity = FindEntityInString(Section_Name);
		if (entity != -1 && IsSpecialCommon(entity)) {

			Format(AffixName, sizeof(AffixName), "%s", Section_Name[FindDelim(Section_Name)]);

			ExplodeString(AffixName, ":", t_AffixName, 2, 64);
			Format(AffixName, sizeof(AffixName), "%s", t_AffixName[0]);

			affix = FindListPositionBySearchKey(AffixName, a_CommonAffixes, 2, false);	// defaults to false but we are toggling this for debugging purposes.
			if (affix >= 0) {

				h_CAKeys		= GetArrayCell(a_CommonAffixes, affix, 0);
				h_CAValues		= GetArrayCell(a_CommonAffixes, affix, 1);

				DrawCommonAffixes(entity, AffixName, h_CAKeys, h_CAValues);
				//LogMessage("Entity %d is drawing %s in affix pos %d", entity, AffixName, affix);
			}
		}
	}
	return Plugin_Continue;
}

stock String:GetCommonValue(entity, String:Key[]) {

	decl String:SectionName[64];
	decl String:AffixName[2][64];
	new ent = -1;
	decl String:NewValue[64];
	Format(NewValue, sizeof(NewValue), "-1");

	new size = GetArraySize(CommonAffixes);
	for (new i = 0; i < size && StringToInt(NewValue) == -1; i++) {

		GetArrayString(Handle:CommonAffixes, i, SectionName, sizeof(SectionName));
		ent = FindEntityInString(SectionName);
		if (entity != ent) continue;	// searching for a specific entity.

		Format(AffixName[0], sizeof(AffixName[]), "%s", SectionName[FindDelim(SectionName)]);
		ExplodeString(AffixName[0], ":", AffixName, 2, 64);

		ent = FindListPositionBySearchKey(AffixName[0], a_CommonAffixes, 2, false);
		if (ent < 0) LogMessage("[GetCommonValue] failed at FindListPositionBySearchKey(%s)", AffixName[0]);
		else {

			h_CommonKeys		= GetArrayCell(a_CommonAffixes, ent, 0);
			h_CommonValues		= GetArrayCell(a_CommonAffixes, ent, 1);
			Format(NewValue, sizeof(NewValue), "%s", GetKeyValue(h_CommonKeys, h_CommonValues, Key));
			break;
		}
	}
	return NewValue;
}

stock bool:IsInRange(Float:EntitLoc[3], Float:TargetLo[3], Float:AllowsMaxRange, Float:ModeSize = 1.0) {

	new Float:ModelSize = 48.0 * ModeSize;
	
	if ((EntitLoc[2] + ModelSize >= TargetLo[2] ||
		 EntitLoc[2] - ModelSize <= TargetLo[2]) && GetVectorDistance(EntitLoc, TargetLo) <= (AllowsMaxRange / 2)) return true;
	return false;
}

stock DrawCommonAffixes(entity, String:AffixName[], Handle:CAKeys, Handle:CAValues) {

	decl String:AfxEffect[64];
	decl String:AfxDrawColour[64];
	new Float:AfxRange = -1.0;
	new Float:AfxRangeMax = -1.0;
	new AfxDrawType = -1;

	new Float:EntityPos[3];
	new Float:TargetPos[3];
	if (!IsValidEntity(entity) || !IsSpecialCommon(entity)) return;

	GetEntPropVector(entity, Prop_Send, "m_vecOrigin", EntityPos);

	new Float:ModelSize = StringToFloat(GetKeyValue(CAKeys, CAValues, "model size?"));
	new Float:AfxRangeBase = -1.0;

	SetEntPropFloat(entity, Prop_Send, "m_flModelScale", ModelSize);

	Format(AfxEffect, sizeof(AfxEffect), "%s", GetKeyValue(CAKeys, CAValues, "aura effect?"));
	AfxRange		= StringToFloat(GetKeyValue(CAKeys, CAValues, "range player level?"));
	AfxRangeMax		= StringToFloat(GetKeyValue(CAKeys, CAValues, "range max?"));
	AfxDrawType		= StringToInt(GetKeyValue(CAKeys, CAValues, "draw type?"));
	AfxRangeBase	= StringToFloat(GetKeyValue(CAKeys, CAValues, "range minimum?"));
	//AfxRange += AfxRangeBase;

	Format(AfxDrawColour, sizeof(AfxDrawColour), "%s", GetKeyValue(CAKeys, CAValues, "draw colour?"));
	if (StrEqual(AfxDrawColour, "-1", false)) return;		// if there's no colour, we return otherwise you'll get errors like this: TE_Send Exception reported: No TempEntity call is in progress

	new Float:t_Range = -1.0;

	for (new i = 1; i <= MaxClients; i++) {

		if (!IsLegitimateClient(i) || IsFakeClient(i)) continue;

		if (AfxRange > 0.0) t_Range = AfxRange * PlayerLevel[i];
		else t_Range = AfxRangeMax;
		if (t_Range + AfxRangeBase > AfxRangeMax) t_Range = AfxRangeMax;
		else t_Range += AfxRangeBase;

		if (AfxDrawType == 0) CreateRingSolo(entity, t_Range, AfxDrawColour, false, 0.25, i);
		else if (AfxDrawType == 1) {

			for (new y = 1; y <= MaxClients; y++) {

				if (!IsLegitimateClient(y) || IsFakeClient(y) || GetClientTeam(y) != TEAM_SURVIVOR) continue;
				GetClientAbsOrigin(y, TargetPos);
				// Player is outside the applicable range.
				if (!IsInRange(EntityPos, TargetPos, t_Range, ModelSize)) continue;

				CreateLineSolo(entity, y, AfxDrawColour, 0.25, i);	// the last arg makes sure the line is drawn only for the player, otherwise it is drawn for all players, and that is bad as we are looping all players here already.
			}
		}
		t_Range = 0.0;
	}

	

	//Now we execute the effects, after all players have clearly seen them.

	new t_Strength			= 0;
	new AfxStrength			= StringToInt(GetKeyValue(CAKeys, CAValues, "aura strength?"));
	new AfxMultiplication	= StringToInt(GetKeyValue(CAKeys, CAValues, "enemy multiplication?"));
	new Float:AfxStrengthLevel = StringToFloat(GetKeyValue(CAKeys, CAValues, "level strength?"));
	
	if (AfxMultiplication == 1) t_Strength = AfxStrength * LivingEntitiesInRange(entity, EntityPos, t_Range);
	else t_Strength = AfxStrength;

	for (new i = 1; i <= MaxClients; i++) {

		if (!IsLegitimateClientAlive(i) || IsFakeClient(i) || GetClientTeam(i) != TEAM_SURVIVOR) continue;
		GetClientAbsOrigin(i, TargetPos);

		if (AfxRange > 0.0) t_Range = AfxRange * PlayerLevel[i];
		else t_Range = AfxRangeMax;
		if (t_Range + AfxRangeBase > AfxRangeMax) t_Range = AfxRangeMax;
		else t_Range += AfxRangeBase;

		// Player is outside the applicable range.
		if (!IsInRange(EntityPos, TargetPos, t_Range, ModelSize)) continue;

		if (AfxStrengthLevel > 0.0) t_Strength += RoundToCeil(t_Strength * (PlayerLevel[i] * AfxStrengthLevel));

		//If they are not immune to the effects, we consider the effects.
		
		if (FindCharInString(AfxEffect, 'd') != -1) {

			if (t_Strength > GetClientHealth(i)) IncapacitateOrKill(i);
			else SetEntityHealth(i, GetClientHealth(i) - t_Strength);
		}
		if (FindCharInString(AfxEffect, 'l') != -1) {

			/*

				We don't want multiple blinders to spam blind a player who is already blind.
				Furthermore, we don't want it to accidentally blind a player AFTER it dies and leave them permablind.

				ISBLIND is tied a timer, and when the timer reverses the blind, it will close the handle.
			*/
			if (ISBLIND[i] == INVALID_HANDLE) BlindPlayer(i, 0.0, 255);
		}
		if (FindCharInString(AfxEffect, 'r') != -1) {

			/*

				Freeze players, teleport them up a lil bit.

			*/
			if (ISFROZEN[i] == INVALID_HANDLE) FrozenPlayer(i, 0.0);
		}
	}
	new ent = -1;
	new pos = -1;
	for (new i = 1; i <= MaxClients; i++) {

		if (!IsLegitimateClientAlive(i) || GetClientTeam(i) != TEAM_INFECTED) continue;
		GetClientAbsOrigin(i, TargetPos);

		if (IsInRange(EntityPos, TargetPos, AfxRangeMax, ModelSize)) {

			if (FindCharInString(AfxEffect, 'h') != -1) {

				for (new y = 1; y <= MaxClients; y++) {

					if (!IsLegitimateClient(y) || IsFakeClient(y) || GetClientTeam(y) != TEAM_SURVIVOR) continue;
					pos = FindListPositionByEntity(entity, Handle:InfectedHealth[i]);
					if (pos < 0) continue;
					SetArrayCell(Handle:InfectedHealth[i], pos, GetArrayCell(Handle:InfectedHealth[i], pos, 1) + t_Strength, 1);
				}
			}
		}
	}
	while ((ent = FindEntityByClassname(ent, "infected")) != -1) {

		if (ent != entity) {

			GetEntPropVector(ent, Prop_Send, "m_vecOrigin", TargetPos);
			if (IsInRange(EntityPos, TargetPos, AfxRangeMax, ModelSize)) {

				if (FindCharInString(AfxEffect, 'h') != -1) {

					/*

						We heal the entity.
					*/
					for (new i = 1; i <= MaxClients; i++) {

						if (!IsLegitimateClient(i) || IsFakeClient(i) || GetClientTeam(i) != TEAM_SURVIVOR) continue;
						if (IsSpecialCommon(ent)) {

							pos = FindListPositionByEntity(ent, Handle:SpecialCommon[i]);
							if (pos < 0) continue;
							SetArrayCell(Handle:SpecialCommon[i], pos, GetArrayCell(Handle:SpecialCommon[i], pos, 1) + t_Strength, 1);
						}
						else if (IsCommonInfected(ent)) {

							pos = FindListPositionByEntity(ent, Handle:CommonInfectedDamage[i]);
							if (pos < 0) continue;
							SetArrayCell(Handle:CommonInfectedDamage[i], pos, GetArrayCell(Handle:CommonInfectedDamage[i], pos, 1) + t_Strength, 1);
						}
					}
				}
			}
		}
	}
}

stock LivingEntitiesInRange(entity, Float:SourceLoc[3], Float:EffectRange) {

	new count = 0;
	new Float:Pos[3];
	new Float:ModelSize = 48.0 * GetEntPropFloat(entity, Prop_Send, "m_flModelScale");
	for (new i = 1; i <= MaxClients; i++) {

		if (IsLegitimateClientAlive(i)) {

			GetClientAbsOrigin(i, Pos);
			//if (SourceLoc[2] + ModelSize < Pos[2] ||
			//	SourceLoc[2] - ModelSize > Pos[2]) continue;
			if (!IsInRange(SourceLoc, Pos, EffectRange, ModelSize)) continue;
			count++;
		}
	}
	new ent = -1;
	while ((ent = FindEntityByClassname(ent, "infected")) != -1) {

		if (ent != entity) {

			GetEntPropVector(ent, Prop_Send, "m_vecOrigin", Pos);
			if (!IsInRange(SourceLoc, Pos, EffectRange, ModelSize)) continue;
			count++;
		}
	}
	return count;
}

stock bool:IsAbilityCooldown(client, String:TalentName[]) {

	if (IsClientActual(client)) {

		new a_Size				=	0;
		if (!IsFakeClient(client)) a_Size					=	GetArraySize(a_Database_PlayerTalents[client]);
		else a_Size											=	GetArraySize(a_Database_PlayerTalents_Bots);

		decl String:Name[PLATFORM_MAX_PATH];

		for (new i = 0; i < a_Size; i++) {

			GetArrayString(Handle:a_Database_Talents, i, Name, sizeof(Name));
			if (StrEqual(Name, TalentName)) {

				decl String:t_Cooldown[8];
				if (!IsFakeClient(client)) GetArrayString(Handle:PlayerAbilitiesCooldown[client], i, t_Cooldown, sizeof(t_Cooldown));
				else GetArrayString(Handle:PlayerAbilitiesCooldown_Bots, i, t_Cooldown, sizeof(t_Cooldown));
				if (StrEqual(t_Cooldown, "1")) return true;
				break;
			}
		}
	}
	return false;
}

stock GetTalentPosition(client, String:TalentName[]) {

	new pos = 0;
	if (IsClientActual(client)) {

		new a_Size				=	0;
		if (!IsFakeClient(client)) a_Size					=	GetArraySize(a_Database_PlayerTalents[client]);
		else a_Size											=	GetArraySize(a_Database_PlayerTalents_Bots);

		decl String:Name[PLATFORM_MAX_PATH];

		for (new i = 0; i < a_Size; i++) {

			GetArrayString(Handle:a_Database_Talents, i, Name, sizeof(Name));
			if (StrEqual(Name, TalentName)) {

				pos = i;
				break;
			}
		}
	}
	return pos;
}

stock RemoveImmunities(client) {

	// We remove all immunities when a round ends, otherwise they may not properly remove and then players become immune, forever.
	new size = 0;
	if (client == -1) {

		size = GetArraySize(PlayerAbilitiesImmune_Bots);
		for (new i = 0; i < size; i++) {

			SetArrayString(PlayerAbilitiesImmune_Bots, i, "0");
			SetArrayString(PlayerAbilitiesCooldown_Bots, i, "0");
		}
		for (new i = 1; i <= MAXPLAYERS; i++) {

			RemoveImmunities(i);
		}
	}
	else {

		size = GetArraySize(PlayerAbilitiesImmune[client]);
		for (new i = 0; i < size; i++) {

			SetArrayString(PlayerAbilitiesImmune[client], i, "0");
			SetArrayString(PlayerAbilitiesCooldown[client], i, "0");
		}
	}
}

stock CreateImmune(client, pos, Float:f_Cooldown) {

	if (IsLegitimateClient(client)) {

		if (!IsFakeClient(client)) SetArrayString(PlayerAbilitiesImmune[client], pos, "1");
		else SetArrayString(PlayerAbilitiesImmune_Bots, pos, "1");

		new Handle:packy;
		CreateDataTimer(f_Cooldown, Timer_RemoveImmune, packy, TIMER_FLAG_NO_MAPCHANGE);
		if (IsFakeClient(client)) client = -1;
		WritePackCell(packy, client);
		WritePackCell(packy, pos);
	}
}

stock CreateCooldown(client, pos, Float:f_Cooldown) {

	if (IsLegitimateClient(client)) {

		//if (GetArraySize(PlayerAbilitiesCooldown[client]) < pos) ResizeArray(PlayerAbilitiesCooldown[client], pos + 1);
		if (!IsFakeClient(client)) SetArrayString(PlayerAbilitiesCooldown[client], pos, "1");
		else SetArrayString(PlayerAbilitiesCooldown_Bots, pos, "1");

		new Handle:packi;
		CreateDataTimer(f_Cooldown, Timer_RemoveCooldown, packi, TIMER_FLAG_NO_MAPCHANGE);
		if (IsFakeClient(client)) client = -1;
		WritePackCell(packi, client);
		WritePackCell(packi, pos);
	}
}

stock bool:HasAbilityPoints(client, String:TalentName[]) {

	if (IsLegitimateClientAlive(client)) {

		// Check if the player has any ability points in the specified ability

		new a_Size				=	0;
		if (client != -1) a_Size		=	GetArraySize(a_Database_PlayerTalents[client]);
		else a_Size						=	GetArraySize(a_Database_PlayerTalents_Bots);

		decl String:Name[PLATFORM_MAX_PATH];

		for (new i = 0; i < a_Size; i++) {

			GetArrayString(Handle:a_Database_Talents, i, Name, sizeof(Name));
			if (StrEqual(Name, TalentName)) {

				if (client != -1) GetArrayString(Handle:a_Database_PlayerTalents[client], i, Name, sizeof(Name));
				else GetArrayString(Handle:a_Database_PlayerTalents_Bots, i, Name, sizeof(Name));
				if (StringToInt(Name) > 0) return true;
			}
		}
	}
	return false;
}

stock AwardSkyPoints(client, amount) {

	SkyPoints[client] += amount;
	decl String:Name[64];
	GetClientName(client, Name, sizeof(Name));
	PrintToChatAll("%t", "Sky Points Award", green, amount, orange, GetConfigValue("sky points menu name?"), white, green, Name, white);
}

stock String:GetTimePlayed(client) {

	decl String:text[64];
	new seconds				=	TimePlayed[client];
	new days				=	0;
	while (seconds >= 86400) {

		days++;
		seconds -= 86400;
	}
	new hours				=	0;
	while (seconds >= 3600) {

		hours++;
		seconds -= 3600;
	}
	new minutes				=	0;
	while (seconds >= 60) {

		minutes++;
		seconds -= 60;
	}
	decl String:Days_t[64];
	decl String:Hours_t[64];
	decl String:Minutes_t[64];
	decl String:Seconds_t[64];

	if (days > 0 && days < 10) Format(Days_t, sizeof(Days_t), "0%d", days);
	else if (days >= 10) Format(Days_t, sizeof(Days_t), "%d", days);
	else Format(Days_t, sizeof(Days_t), "0");
	if (hours > 0 && hours < 10) Format(Hours_t, sizeof(Hours_t), "0%d", hours);
	else if (hours >= 10) Format(Hours_t, sizeof(Hours_t), "%d", hours);
	else Format(Hours_t, sizeof(Hours_t), "0");
	if (minutes > 0 && minutes < 10) Format(Minutes_t, sizeof(Minutes_t), "0%d", minutes);
	else if (minutes >= 10) Format(Minutes_t, sizeof(Minutes_t), "%d", minutes);
	else Format(Minutes_t, sizeof(Minutes_t), "0");
	if (seconds > 0 && seconds < 10) Format(Seconds_t, sizeof(Seconds_t), "0%d", seconds);
	else if (seconds >= 10) Format(Seconds_t, sizeof(Seconds_t), "%d", seconds);
	else Format(Seconds_t, sizeof(Seconds_t), "0");

	Format(text, sizeof(text), "%T", "Time Played", client, Days_t, Hours_t, Minutes_t, Seconds_t);
	return text;
}

stock ConfirmExperienceAction(client) {

	if (ExperienceLevel[client] >= GetUpgradeExperienceCost(client)) {

		if (GetUpgradeExperienceCost(client) < CheckExperienceRequirement(client)) {

			ExperienceLevel[client] -= GetUpgradeExperienceCost(client);
			UpgradesAwarded[client]++;
			UpgradesAvailable[client] += StringToInt(GetConfigValue("talent upgrades awarded?"));
			PrintToChat(client, "%T", "upgrade awarded", client, white, green, orange, white, StringToInt(GetConfigValue("talent upgrades awarded?")));
		}
		else {

			if (StringToFloat(GetConfigValue("upgrade experience cost?")) < 1.0) {

				ExperienceBuyLevel(client);
				UpgradesAwarded[client] = 0;
			}
			else {

				//ExperienceLevel[client] -= GetUpgradeExperienceCost(client);
				UpgradesAwarded[client]++;
				UpgradesAvailable[client] += StringToInt(GetConfigValue("talent upgrades awarded?"));
				PrintToChat(client, "%T", "upgrade awarded", client, white, green, orange, white, StringToInt(GetConfigValue("talent upgrades awarded?")));
				ExperienceBuyLevel(client);
			}
		}
	}
}

/*stock ConfirmExperienceAction(client) {

	if (ExperienceLevel[client] >= GetUpgradeExperienceCost(client)) {

		if (StringToFloat(GetConfigValue("upgrade experience cost?")) < 1.0) {



			ExperienceLevel[client] -= GetUpgradeExperienceCost(client);
			UpgradesAwarded[client]++;
			UpgradesAvailable[client] += StringToInt(GetConfigValue("talent upgrades awarded?"));
			PrintToChat(client, "%T", "upgrade awarded", client, white, green, orange, white, StringToInt(GetConfigValue("talent upgrades awarded?")));
		}
		else {

			//ExperienceLevel[client] -= GetUpgradeExperienceCost(client);
			UpgradesAwarded[client]++;
			UpgradesAvailable[client] += StringToInt(GetConfigValue("talent upgrades awarded?"));
			PrintToChat(client, "%T", "upgrade awarded", client, white, green, orange, white, StringToInt(GetConfigValue("talent upgrades awarded?")));
			ExperienceBuyLevel(client);
		}
	}
}*/

stock GetUpgradeExperienceCost(client, bool:b_IsLevelUp = false) {

	new experienceCost = 0;
	if (client == -1 || IsLegitimateClient(client)) {

		if (client == -1) return RoundToCeil(CheckExperienceRequirement(-1) * ((PlayerLevelUpgrades_Bots + 1) * StringToFloat(GetConfigValue("upgrade experience cost?"))));
		
		//new Float:Multiplier		= (PlayerUpgradesTotal[client] * 1.0) / (MaximumPlayerUpgrades(client) * 1.0);
		if (StringToFloat(GetConfigValue("upgrade experience cost?")) < 1.0) experienceCost		= RoundToCeil(CheckExperienceRequirement(client) * ((UpgradesAwarded[client] + 1) * StringToFloat(GetConfigValue("upgrade experience cost?"))));
		else experienceCost = CheckExperienceRequirement(client);
		//experienceCost				= RoundToCeil(CheckExperienceRequirement(client) * Multiplier);
	}
	return experienceCost;
}

stock PrintToSurvivors(RPGMode, String:SurvivorName[], String:InfectedName[], SurvExp, Float:SurvPoints) {

	for (new i = 1; i <= MaxClients; i++) {

		if (IsLegitimateClient(i) && !IsFakeClient(i) && GetClientTeam(i) == TEAM_SURVIVOR) {

			if (RPGMode == 1) PrintToChat(i, "%T", "Experience Earned Total Team Survivor", i, white, blue, white, orange, white, green, white, SurvivorName, InfectedName, SurvExp);
			else if (RPGMode == 2) PrintToChat(i, "%T", "Experience Points Earned Total Team Survivor", i, white, blue, white, orange, white, green, white, green, white, SurvivorName, InfectedName, SurvExp, SurvPoints);
		}
	}
}

stock PrintToInfected(RPGMode, String:SurvivorName[], String:InfectedName[], InfTotalExp, Float:InfTotalPoints) {

	for (new i = 1; i <= MaxClients; i++) {

		if (IsLegitimateClient(i) && !IsFakeClient(i) && GetClientTeam(i) == TEAM_INFECTED) {

			if (RPGMode == 1) PrintToChat(i, "%T", "Experience Earned Total Team", i, white, orange, white, green, white, InfectedName, InfTotalExp);
			else if (RPGMode == 2) PrintToChat(i, "%T", "Experience Points Earned Total Team", i, white, orange, white, green, white, green, white, InfectedName, InfTotalExp, InfTotalPoints);
		}
	}
}

stock ClearRelevantData() {

	for (new i = 1; i <= MaxClients; i++) {

		if (!IsClientActual(i) || !IsClientInGame(i)) continue;
		Points[i]					= 0.0;
		b_IsBlind[i]				= false;
		b_IsImmune[i]				= false;
		b_IsJumping[i]				= false;
		CommonKills[i]				= 0;
		CommonKillsHeadshot[i]		= 0;
		bIsMeleeCooldown[i]			= false;
		ClearArray(Handle:WitchDamage[i]);

		ResetOtherData(i);
	}
	//ClearArray(Handle:WitchList);
}

stock ResetOtherData(client) {

	if (IsLegitimateClient(client)) {

		for (new i = 1; i <= MAXPLAYERS; i++) {

			DamageAward[client][i]		=	0;
			DamageAward[i][client]		=	0;
			CoveredInBile[client][i]	=	-1;
			CoveredInBile[i][client]	=	-1;
		}
	}
}

stock LivingSurvivors() {

	new count = 0;
	for (new i = 1; i <= MaxClients; i++) {

		if (IsLegitimateClientAlive(i) && GetClientTeam(i) == TEAM_SURVIVOR) count++;
	}
	return count;
}

stock LivingHumanSurvivors() {

	new count = 0;
	for (new i = 1; i <= MaxClients; i++) {

		if (IsLegitimateClientAlive(i) && !IsFakeClient(i) && GetClientTeam(i) == TEAM_SURVIVOR) count++;
	}
	return count;
}

stock HumanPlayersInGame() {

	new count = 0;
	for (new i = 1; i <= MaxClients; i++) {

		if (IsLegitimateClient(i) && !IsFakeClient(i) && GetClientTeam(i) != TEAM_SPECTATOR) count++;
	}
	return count;
}

public Action:Cmd_ResetTPL(client, args) { PlayerLevelUpgrades[client] = 0; }

stock ExperienceBuyLevel(client, bool:bot = false) {

	decl String:Name[64];
	if (!bot) {

		if (ExperienceLevel[client] >= CheckExperienceRequirement(client)) {

			ExperienceLevel[client]		=	0;
			PlayerLevelUpgrades[client] = 0;
			PlayerLevel[client]++;

			GetClientName(client, Name, sizeof(Name));

			PrintToChatAll("%t", "player level up", green, white, green, Name, PlayerLevel[client]);
		}
	}
	else {

		if (ExperienceLevel_Bots == CheckExperienceRequirement(-1)) {

			ExperienceOverall_Bots += ExperienceLevel_Bots;
			ExperienceLevel_Bots		=	0;
			PlayerLevelUpgrades_Bots = 0;
			PlayerLevel_Bots++;

			Format(Name, sizeof(Name), "%s", GetConfigValue("director team name?"));
			PrintToChatAll("%t", "player level up", green, white, green, Name, PlayerLevel_Bots);
		}
	}

	BuildMenu(client);
}

stock String:FormatDatabase() {
	
	decl String:text[PLATFORM_MAX_PATH];

	new a_Size			=	GetArraySize(MainKeys);
}

stock bool:StringExistsArray(String:Name[], Handle:array) {

	decl String:text[PLATFORM_MAX_PATH];

	new a_Size			=	GetArraySize(array);

	for (new i = 0; i < a_Size; i++) {

		GetArrayString(Handle:array, i, text, sizeof(text));

		if (StrEqual(Name, text)) return true;
	}

	return false;
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

stock HandicapDifference(client, target) {

	if (IsLegitimateClientAlive(client) && IsLegitimateClientAlive(target)) {

		new clientLevel = 0;
		new targetLevel = 0;

		if (!IsFakeClient(client)) clientLevel = PlayerLevel[client];
		else clientLevel = PlayerLevel_Bots;

		if (!IsFakeClient(target)) targetLevel = PlayerLevel[target];
		else targetLevel = PlayerLevel_Bots;

		if (targetLevel < clientLevel) {
		
			new dif = clientLevel - targetLevel;
			new han = StringToInt(GetConfigValue("handicap level difference required?"));

			if (dif > han) return (dif - han);
		}
	}
	return 0;
}

/*stock EnforceServerTalentMaximum(client) {

	new Handle:MKeys = CreateArray(8);
	new Handle:MValues = CreateArray(8);
	new Handle:MSection = CreateArray(8);

	new TalentMaximum = 0;
	new PlayerTalentPoints = 0;

	decl String:TalentName[64];

	new size						=	GetArraySize(a_Menu_Talents);

	for (new i = 0; i < size; i++) {

		MKeys			= GetArrayCell(a_Menu_Talents, i, 0);
		MValues			= GetArrayCell(a_Menu_Talents, i, 1);
		MSection		= GetArrayCell(a_Menu_Talents, i, 2);

		GetArrayString(Handle:MSection, 0, TalentName, sizeof(TalentName));

		TalentMaximum = StringToInt(GetKeyValue(MKeys, MValues, "maximum talent points allowed?"));

		PlayerTalentPoints = GetTalentStrength(client, TalentName);
		if (PlayerTalentPoints > TalentMaximum) {

		//

			The player was on a server with different talent settings; specifically,
			it's clear some talents allowed greater values. Since this server doesn't,
			we set them to the maximum, refund the extra points.
		//
			FreeUpgrades[client] += (PlayerTalentPoints - TalentMaximum);
			PlayerUpgradesTotal[client] -= (PlayerTalentPoints - TalentMaximum);
			AddTalentPoints(client, TalentName, TalentMaximum);
		}
	}
}*/

stock ReceiveCommonDamage(client, entity, playerDamageTaken) {

	new pos = -1;
	if (IsSpecialCommon(entity)) pos = FindListPositionByEntity(entity, Handle:CommonList);
	else if (IsCommonInfected(entity)) pos = FindListPositionByEntity(entity, Handle:CommonInfected);

	if (pos < 0) return;
	new my_pos = 0;
	if (IsSpecialCommon(entity)) {

		AddSpecialCommonDamage(client, entity, 0);
		my_pos = FindListPositionByEntity(entity, Handle:SpecialCommon[client]);
		if (my_pos >= 0) SetArrayCell(Handle:SpecialCommon[client], my_pos, GetArrayCell(Handle:SpecialCommon[client], my_pos, 3) + playerDamageTaken, 3);
	}
	else if (IsCommonInfected(entity)) {

		AddCommonInfectedDamage(client, entity, 0);
		my_pos = FindListPositionByEntity(entity, Handle:CommonInfectedDamage[client]);
		if (my_pos >= 0) SetArrayCell(Handle:CommonInfectedDamage[client], my_pos, GetArrayCell(Handle:CommonInfectedDamage[client], my_pos, 3) + playerDamageTaken, 3);
	}

}

stock ReceiveWitchDamage(client, entity, playerDamageTaken) {

	if (!IsWitch(entity)) {

		OnWitchCreated(entity, true);
		return;
	}
	new pos = FindListPositionByEntity(entity, Handle:WitchList);
	if (pos < 0) return;

	new my_size = GetArraySize(Handle:WitchDamage[client]);
	new my_pos = FindListPositionByEntity(entity, Handle:WitchDamage[client]);
	if (my_pos < 0) {

		new WitchHealth = StringToInt(GetConfigValue("base witch health?"));
		new mlevel = PlayerLevel[client];
		WitchHealth += RoundToCeil(WitchHealth * (mlevel * StringToFloat(GetConfigValue("level witch multiplier?"))));

		ResizeArray(Handle:WitchDamage[client], my_size + 1);
		SetArrayCell(Handle:WitchDamage[client], my_size, entity, 0);
		SetArrayCell(Handle:WitchDamage[client], my_size, WitchHealth, 1);
		SetArrayCell(Handle:WitchDamage[client], my_size, 0, 2);
		SetArrayCell(Handle:WitchDamage[client], my_size, playerDamageTaken, 3);
		SetArrayCell(Handle:WitchDamage[client], my_size, 0, 4);
	}
	else {

		SetArrayCell(Handle:WitchDamage[client], my_pos, GetArrayCell(Handle:WitchDamage[client], my_pos, 3) + playerDamageTaken, 3);
	}
}

stock EntityStatusEffectDamage(client, damage) {

	/*

		This function rotates through the list of all players who have an initialized health pool with this entity.
		If they don't, it will create one.

		To simulate the illusion of the entity taking fire damage when players are not dealing damage to it, we instead
		remove the value from its total health pool. Everyone's CNT bars will rise, and the entity's E.HP bar will fall.
	*/
	new pos = -1;
	if (IsWitch(client)) pos = FindListPositionByEntity(client, Handle:WitchList);
	for (new i = 1; i <= MaxClients; i++) {

		if (!IsLegitimateClientAlive(i) || IsFakeClient(i)) continue;

		if (IsWitch(client) && pos >= 0) {

			AddWitchDamage(i, client, 0);	// If the player doesn't have the witch, it will be initialized for them.
			AddWitchDamage(i, client, damage * -1);		// After we verify initialization, we multiple damage by -1 so the function knows to remove health instead of add contribution.
		}
		else if (IsSpecialCommon(client)) {

			AddSpecialCommonDamage(i, client, 0);
			AddSpecialCommonDamage(i, client, damage * -1);
		}
		else if (IsCommonInfected(client)) {

			AddCommonInfectedDamage(i, client, 0);
			AddCommonInfectedDamage(i, client, damage * -1);
		}
	}
}

stock AddCommonInfectedDamage(client, entity, playerDamage) {

	if (!IsCommonInfected(entity)) {

		OnCommonInfectedCreated(entity, true);
		return;
	}
	new damageTotal = -1;
	new pos		= FindListPositionByEntity(entity, Handle:CommonInfected);
	if (pos < 0) return;

	new my_size	= GetArraySize(Handle:CommonInfectedDamage[client]);
	new my_pos	= FindListPositionByEntity(entity, Handle:CommonInfectedDamage[client]);
	if (my_pos < 0) {

		new CommonHealth = StringToInt(GetConfigValue("common base health?"));
		new mlevel = PlayerLevel[client];
		CommonHealth += (mlevel * StringToInt(GetConfigValue("common level health?")));

		ResizeArray(Handle:CommonInfectedDamage[client], my_size + 1);
		SetArrayCell(Handle:CommonInfectedDamage[client], my_size, entity, 0);
		SetArrayCell(Handle:CommonInfectedDamage[client], my_size, CommonHealth, 1);
		SetArrayCell(Handle:CommonInfectedDamage[client], my_size, playerDamage, 2);
		SetArrayCell(Handle:CommonInfectedDamage[client], my_size, 0, 3);
		SetArrayCell(Handle:CommonInfectedDamage[client], my_size, 0, 4);
	}
	else {

		if (playerDamage >= 0) {

			damageTotal = GetArrayCell(Handle:CommonInfectedDamage[client], my_pos, 2);
			if (damageTotal < 0) damageTotal = 0;
			SetArrayCell(Handle:CommonInfectedDamage[client], my_pos, damageTotal + playerDamage, 2);
		}
		else {

			/*

				When the witch is burning, or hexed (ie it is simply losing health) we come here instead.
				Negative values detract from the overall health instead of adding player contribution.
			*/
			damageTotal = GetArrayCell(Handle:CommonInfectedDamage[client], my_pos, 1);
			SetArrayCell(Handle:CommonInfectedDamage[client], my_pos, damageTotal + playerDamage, 1);
			CheckIfEntityShouldDie(entity, client);
		}
	}
}

stock AddWitchDamage(client, entity, playerDamageToWitch) {

	if (!IsWitch(entity)) {

		OnWitchCreated(entity, true);
		return;
	}
	new damageTotal = -1;
	new pos		= FindListPositionByEntity(entity, Handle:WitchList);
	if (pos < 0) return;

	new my_size	= GetArraySize(Handle:WitchDamage[client]);
	new my_pos	= FindListPositionByEntity(entity, Handle:WitchDamage[client]);
	if (my_pos < 0) {

		new WitchHealth = StringToInt(GetConfigValue("base witch health?"));
		new mlevel = PlayerLevel[client];
		WitchHealth += RoundToCeil(WitchHealth * (mlevel * StringToFloat(GetConfigValue("level witch multiplier?"))));

		ResizeArray(Handle:WitchDamage[client], my_size + 1);
		SetArrayCell(Handle:WitchDamage[client], my_size, entity, 0);
		SetArrayCell(Handle:WitchDamage[client], my_size, WitchHealth, 1);
		SetArrayCell(Handle:WitchDamage[client], my_size, playerDamageToWitch, 2);
		SetArrayCell(Handle:WitchDamage[client], my_size, 0, 3);
		SetArrayCell(Handle:WitchDamage[client], my_size, 0, 4);
	}
	else {

		if (playerDamageToWitch >= 0) {

			damageTotal = GetArrayCell(Handle:WitchDamage[client], my_pos, 2);
			if (damageTotal < 0) damageTotal = 0;
			SetArrayCell(Handle:WitchDamage[client], my_pos, damageTotal + playerDamageToWitch, 2);
		}
		else {

			/*

				When the witch is burning, or hexed (ie it is simply losing health) we come here instead.
				Negative values detract from the overall health instead of adding player contribution.
			*/
			damageTotal = GetArrayCell(Handle:WitchDamage[client], my_pos, 1);
			SetArrayCell(Handle:WitchDamage[client], my_pos, damageTotal + playerDamageToWitch, 1);
			CheckIfEntityShouldDie(entity, client);
		}
	}
}

stock CheckIfEntityShouldDie(victim, attacker) {

	if (CheckTeammateDamages(victim, attacker) >= 1.0 ||
		CheckTeammateDamages(victim, attacker, true) >= 1.0 ||
		CheckTeammateDamages(victim, attacker) < 0.0 ||
		CheckTeammateDamages(victim, attacker, true) < 0.0) {

		if (IsWitch(victim)) OnWitchCreated(victim, true);
		else if (IsSpecialCommon(victim)) {

			ClearSpecialCommon(victim);
		}
	}
	else {

		/*

			So the player / common took damage.
		*/
		if (IsSpecialCommon(victim)) {

			// The bomber explosion initially targets itself so that the chain-reaction (if enabled) doesn't go indefinitely.
			if (FindCharInString(GetCommonValue(victim, "aura effect?"), 'f') != -1) {

				CreateExplosion(victim);
				CreateDamageStatusEffect(victim);		// 0 is the default, which is fire.
			}
		}
	}
}

/*

	This function removes a dying (or dead) common infected from all client cooldown arrays.
*/
stock RemoveCommonAffixes(entity) {

	new size = GetArraySize(Handle:CommonAffixes);

	decl String:EntityId[64];
	decl String:SectionName[64];
	Format(EntityId, sizeof(EntityId), "%d", entity);

	for (new i = 0; i < size; i++) {

		//CASection			= GetArrayCell(CommonAffixes, i, 2);
		//if (GetArraySize(CASection) < 1) continue;
		GetArrayString(Handle:CommonAffixes, i, SectionName, sizeof(SectionName));
		if (StrContains(SectionName, EntityId, false) == -1) continue;
		RemoveFromArray(Handle:CommonAffixes, i);
		break;
	}
	for (new i = 1; i <= MaxClients; i++) {

		size = GetArraySize(CommonAffixesCooldown[i]);
		for (new y = 0; y < size; y++) {

			RCAffixes[i]			= GetArrayCell(CommonAffixesCooldown[i], y, 2);
			GetArrayString(Handle:RCAffixes[i], 0, SectionName, sizeof(SectionName));
			if (StrContains(SectionName, EntityId, false) == -1) continue;
			RemoveFromArray(Handle:CommonAffixesCooldown[i], y);
			break;
		}
	}
}

stock OnCommonCreated(entity, bool:bIsDestroyed = false) {

	//decl String:EntityId[64];
	//Format(EntityId, sizeof(EntityId), "%d", entity);

	if (!bIsDestroyed) PushArrayCell(Handle:CommonList, entity);
	else if (IsSpecialCommon(entity)) ClearSpecialCommon(entity);
}

stock ClearSpecialCommon(entity, bool:IsCommonEntity = true) {

	if (CommonList == INVALID_HANDLE) return;

	new pos = FindListPositionByEntity(entity, Handle:CommonList);
	if (pos >= 0) {

		if (IsCommonEntity) {

			if (FindCharInString(GetCommonValue(entity, "death effect?"), 'f') != -1) {

				CreateExplosion(entity);
				CreateDamageStatusEffect(entity);
			}
			for (new y = 1; y <= MaxClients; y++) {

				if (!IsLegitimateClientAlive(y) || GetClientTeam(y) != TEAM_SURVIVOR) continue;
				if (FindCharInString(GetCommonValue(entity, "death effect?"), 'b') != -1 && IsSpecialCommonInRange(y, 'b', entity)) SDKCall(g_hCallVomitOnPlayer, y, y, true);
				if (FindCharInString(GetCommonValue(entity, "death effect?"), 'e') != -1 && IsSpecialCommonInRange(y, 'e', entity, false)) {	// false so we compare death effect instead of aura effect which defaults to true

					if (ISEXPLODE[y] == INVALID_HANDLE) {

						ISEXPLODETIME[y] = 0.0;
						new Handle:packagey;
						ISEXPLODE[y] = CreateDataTimer(StringToFloat(GetCommonValue(entity, "death interval?")), Timer_Explode, packagey, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
						WritePackCell(packagey, y);
						WritePackCell(packagey, StringToInt(GetCommonValue(entity, "aura strength?")));
						WritePackFloat(packagey, StringToFloat(GetCommonValue(entity, "strength target?")));
						WritePackFloat(packagey, StringToFloat(GetCommonValue(entity, "level strength?")));
						WritePackFloat(packagey, StringToFloat(GetCommonValue(entity, "range max?")));
						WritePackFloat(packagey, StringToFloat(GetCommonValue(entity, "death multiplier?")));
						WritePackFloat(packagey, StringToFloat(GetCommonValue(entity, "death base time?")));
						WritePackFloat(packagey, StringToFloat(GetCommonValue(entity, "death interval?")));
						WritePackFloat(packagey, StringToFloat(GetCommonValue(entity, "death max time?")));
					}
				}
				if (FindCharInString(GetCommonValue(entity, "death effect?"), 's') != -1 && IsSpecialCommonInRange(y, 's', entity, false)) {

					if (ISSLOW[y] == INVALID_HANDLE) {

						SetSpeedMultiplierBase(y, StringToFloat(GetCommonValue(entity, "death multiplier?")));
						SetEntityMoveType(y, MOVETYPE_WALK);
						ISSLOW[y] = CreateTimer(StringToFloat(GetCommonValue(entity, "death base time?")), Timer_Slow, y, TIMER_FLAG_NO_MAPCHANGE);
					}
				}
			}

			CalculateInfectedDamageAward(entity);
			SDKUnhook(entity, SDKHook_OnTakeDamage, OnTakeDamage);
			AcceptEntityInput(entity, "Kill");
		}
		RemoveFromArray(Handle:CommonList, pos);
		RemoveCommonAffixes(entity);
	}
}

stock OnCommonInfectedCreated(entity, bool:bIsDestroyed = false) {

	if (CommonInfected == INVALID_HANDLE) return;

	if (!bIsDestroyed) {

		PushArrayCell(Handle:CommonInfected, entity);
		for (new i = 1; i <= MaxClients; i++) {

			if (IsLegitimateClient(i) && GetClientTeam(i) == TEAM_SURVIVOR && !IsFakeClient(i)) {

				AddCommonInfectedDamage(i, entity, 0);
			}
		}
	}
	else {

		new pos = FindListPositionByEntity(entity, Handle:CommonInfected);
		if (pos >= 0) {

			CalculateInfectedDamageAward(entity);
			SDKUnhook(entity, SDKHook_OnTakeDamage, OnTakeDamage);
			AcceptEntityInput(entity, "Kill");
			RemoveFromArray(Handle:CommonInfected, pos);
		}
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
stock OnWitchCreated(entity, bool:bIsDestroyed = false) {

	if (WitchList == INVALID_HANDLE) return;

	if (!bIsDestroyed) {

		/*

			When a new witch is created, we add them to the list, and then we
			make sure all survivor players lists are the same size.
		*/
		//LogMessage("[WITCH_LIST] Witch Created %d", entity);
		PushArrayCell(Handle:WitchList, entity);
		SDKHook(entity, SDKHook_OnTakeDamage, OnTakeDamage);
	}
	else {

		/*

			When a Witch dies, we reward all players who did damage to the witch
			and then we remove the row of the witch id in both the witch list
			and in player lists.
		*/
		new pos = FindListPositionByEntity(entity, Handle:WitchList);
		if (pos < 0) {

			LogMessage("[WITCH_LIST] Could not find Witch by id %d", entity);
		}
		else {

			CalculateInfectedDamageAward(entity);
			//ogMessage("[WITCH_LIST] Witch %d Killed", entity);
			SDKUnhook(entity, SDKHook_OnTakeDamage, OnTakeDamage);
			AcceptEntityInput(entity, "Kill");
			RemoveFromArray(Handle:WitchList, pos);		// Delete the witch. Forever.
		}
	}
}

stock FindEntityInString(String:SearchKey[], String:Delim[] = ":") {

	decl String:tExploded[2][64];
	ExplodeString(SearchKey, ":", tExploded, 2, 64);
	return StringToInt(tExploded[1]);
}

stock FindDelim(String:EntityName[], String:Delim[] = ":") {

	for (new i = 0; i <= strlen(EntityName); i++) {

		if (StrContains(EntityName[i], Delim, false) != -1) {

			// Found it!
			return i;
		}
	}
	return -1;
}

stock FindListPositionBySearchKey(String:SearchKey[], Handle:h_SearchList, block = 0, bool:bDebug = false) {

	/*

		Some parts of rpg are formatted differently, so we need to check by entityname instead of id.
	*/
	decl String:SearchId[64];

	//new Handle:Section = CreateArray(8);

	new size = GetArraySize(Handle:h_SearchList);
	if (bDebug) {

		LogMessage("=== FindListPositionBySearchKey ===");
		LogMessage("Searchkey: %s", SearchKey);
	}
	for (new i = 0; i < size; i++) {

		//size = GetArraySize(Handle:h_SearchList);
		//if (i >= size) continue;

		SearchKey_Section						= GetArrayCell(h_SearchList, i, block);

		if (GetArraySize(SearchKey_Section) < 1) {

			//if (bDebug) LogMessage("Section header cannot be found for pos %d in the array", i);
			continue;
		}

		GetArrayString(Handle:SearchKey_Section, 0, SearchId, sizeof(SearchId));
		if (bDebug) {

			LogMessage("Section: %s", SearchId);
			LogMessage("Pos: %d", i);
			LogMessage("Size: %d", size);
		}
		if (StrEqual(SearchId, SearchKey, false)) {

			if (bDebug) {

				LogMessage("Searchkey Found!");
				LogMessage("===================================");
			}

			//ClearArray(Handle:Section);
			return i;
		}
		else if (bDebug) LogMessage("Wrong Searchkey (%s)", SearchId);
	}
	if (bDebug) {

		LogMessage("Searchkey not found :(");
		LogMessage("===================================");
	}
	//ClearArray(Handle:Section);
	return -1;
}

stock GetCommonAffixesPosByEntId(String:SearchKey[], bool:bDebug = false) {

	new size = GetArraySize(Handle:CommonAffixes);

	decl String:text[64];
	for (new i = 0; i < size; i++) {

		GetArrayString(Handle:CommonAffixes, i, text, sizeof(text));
		if (bDebug) LogMessage("CommonAffix text: %s (Searching for: %s)", text, SearchKey);
		if (StrContains(text, SearchKey, false) == -1) continue;
		return i;
	}
	return -1;
}

stock FindListPositionByEntity(entity, Handle:h_SearchList, block = 0) {

	new size = GetArraySize(Handle:h_SearchList);
	for (new i = 0; i < size; i++) {

		if (GetArrayCell(Handle:h_SearchList, i, block) == entity) return i;
	}
	return -1;	// returns false
}

stock bool:AnyTanksNearby(client) {

	new Float:pos[3];
	new Float:ipos[3];
	for (new i = 1; i <= MaxClients; i++) {

		if (IsLegitimateClientAlive(i) && IsFakeClient(i) && GetClientTeam(i) == TEAM_INFECTED && FindZombieClass(i) == ZOMBIECLASS_TANK) {

			GetClientAbsOrigin(client, pos);
			GetClientAbsOrigin(i, ipos);
			if (GetVectorDistance(pos, ipos) <= StringToFloat(GetConfigValue("tank nearby ability deactivate?"))) return true;
		}
	}
	return false;
}

stock bool:IsVectorsCrossed(client, Float:torigin[3], Float:aorigin[3], Float:f_Distance) {

	new Float:porigin[3];
	new Float:vorigin[3];
	MakeVectorFromPoints(torigin, aorigin, vorigin);
	if (GetVectorDistance(porigin, vorigin) <= f_Distance) return true;
	return false;
}

public OnEntityDestroyed(entity) {

	if (!b_IsActiveRound) return;
	//new pos = FindListPositionByEntity(entity, Handle:CommonList);
	//if (pos >= 0) OnCommonCreated(entity, true);

	//if (IsCommonInfected(entity)) SDKUnhook(entity, SDKHook_OnTakeDamage, OnTakeDamage);
}

public OnEntityCreated(entity, const String:classname[]) {

	if (!b_IsActiveRound) return;
	if (StrEqual(classname, "infected", false)) {

		//SDKHook(entity, SDKHook_OnTakeDamage, OnTakeDamage);

		if (GetArraySize(CommonInfectedQueue) > 0) {

			decl String:Model[64];
			GetArrayString(Handle:CommonInfectedQueue, 0, Model, sizeof(Model));
			if (IsModelPrecached(Model)) SetEntityModel(entity, Model);
			RemoveFromArray(Handle:CommonInfectedQueue, 0);
		}
		SDKHook(entity, SDKHook_OnTakeDamage, OnTakeDamage);
		CreateCommonAffix(entity);
	}
	if (IsWitch(entity)) OnWitchCreated(entity);
	if (StrContains(classname, "defibrillator", false) != -1) {

		AcceptEntityInput(entity, "Kill");
	}
	else if (StrContains(classname, "launcher", false) != -1) {

		AcceptEntityInput(entity, "Kill");
	}
}

bool:IsWitch(entity) {

	if (entity <= 0 || !IsValidEntity(entity) || !IsValidEdict(entity)) return false;

	decl String:className[16];
	GetEdictClassname(entity, className, sizeof(className));
	return strcmp(className, "witch") == 0;
}

bool:IsCommonInfected(entity) {

	if (entity <= 0 || !IsValidEntity(entity) || !IsValidEdict(entity)) return false;

	decl String:className[16];
	GetEdictClassname(entity, className, sizeof(className));
	return strcmp(className, "infected") == 0;
}

stock ExperienceBarBroadcast(client) {

	new BroadcastType			=	StringToInt(GetConfigValue("hint text type?"));

	if (BroadcastType == 0) PrintHintText(client, "%T", "Hint Text Broadcast 0", client, ExperienceBar(client));
	if (BroadcastType == 1) PrintHintText(client, "%T", "Hint Text Broadcast 1", client, ExperienceBar(client), AddCommasToString(ExperienceLevel[client]), AddCommasToString(CheckExperienceRequirement(client)));
	if (BroadcastType == 2) PrintHintText(client, "%T", "Hint Text Broadcast 2", client, ExperienceBar(client), AddCommasToString(ExperienceLevel[client]), AddCommasToString(CheckExperienceRequirement(client)), Points[client]);
}

stock CheckTankingDamage(infected, client) {

	new pos = -1;
	new cHealth = 0;
	new cDamage = 0;

	if (!IsWitch(infected) && !IsSpecialCommon(infected) && !IsCommonInfected(infected)) pos = FindListPositionByEntity(infected, Handle:InfectedHealth[client]);
	else if (IsWitch(infected)) pos = FindListPositionByEntity(infected, Handle:WitchDamage[client]);
	else if (IsSpecialCommon(infected)) pos = FindListPositionByEntity(infected, Handle:SpecialCommon[client]);
	else if (IsCommonInfected(infected)) pos = FindListPositionByEntity(infected, Handle:CommonInfectedDamage[client]);

	if (pos < 0) return 0;

	if (!IsWitch(infected) && !IsSpecialCommon(infected) && !IsCommonInfected(infected)) {

		cHealth = GetArrayCell(Handle:InfectedHealth[client], pos, 2);
		cDamage = GetArrayCell(Handle:InfectedHealth[client], pos, 3);
	}
	else if (IsWitch(infected)) {

		cHealth = GetArrayCell(Handle:WitchDamage[client], pos, 2);
		cDamage = GetArrayCell(Handle:WitchDamage[client], pos, 3);
	}
	else if (IsSpecialCommon(infected)) {

		cHealth = GetArrayCell(Handle:SpecialCommon[client], pos, 2);
		cDamage = GetArrayCell(Handle:SpecialCommon[client], pos, 3);
	}
	else if (IsCommonInfected(infected)) {

		cHealth = GetArrayCell(Handle:CommonInfectedDamage[client], pos, 2);
		cDamage = GetArrayCell(Handle:CommonInfectedDamage[client], pos, 3);
	}
	
	/*

		If the player dealt more damage to the special than took damage from it, they do not receive tanking rewards.
	*/
	if (cHealth > cDamage) return 0;
	return cDamage;
}

stock CheckHealingAward(infected, client) {

	new pos = -1;
	if (!IsWitch(infected) && !IsSpecialCommon(infected) && !IsCommonInfected(infected)) pos = FindListPositionByEntity(infected, Handle:InfectedHealth[client]);
	else if (IsWitch(infected)) pos = FindListPositionByEntity(infected, Handle:WitchDamage[client]);
	else if (IsSpecialCommon(infected)) pos = FindListPositionByEntity(infected, Handle:SpecialCommon[client]);
	else if (IsCommonInfected(infected)) pos = FindListPositionByEntity(infected, Handle:CommonInfectedDamage[client]);

	if (pos < 0) return 0;
	if (!IsWitch(infected) && !IsSpecialCommon(infected) && !IsCommonInfected(infected)) return GetArrayCell(Handle:InfectedHealth[client], pos, 4);
	else if (IsWitch(infected)) return GetArrayCell(Handle:WitchDamage[client], pos, 4);
	else if (IsSpecialCommon(infected)) return GetArrayCell(Handle:SpecialCommon[client], pos, 4);
	else if (IsCommonInfected(infected)) return GetArrayCell(Handle:CommonInfectedDamage[client], pos, 4);
	return 0;
}

stock WipeDamageContribution(client) {

	/*

		This function will completely wipe out a players contribution and earnings.
		Use this when a player dies to essentially "give back" the health equal to contribution.
		Other players can then earn the contribution that is restored, albeit a mob that was about to die would
		suddenly gain a bunch of its life force back.
	*/
	if (IsLegitimateClient(client)) {

		ClearArray(Handle:InfectedHealth[client]);
		ClearArray(Handle:WitchDamage[client]);
		ClearArray(Handle:SpecialCommon[client]);
		ClearArray(Handle:CommonInfectedDamage[client]);
	}
}

stock Float:CheckTeammateDamages(infected, client, bool:bIsMyDamageOnly = false) {

	new Float:isDamageValue = 0.0;
	new pos = -1;
	new cHealth = 0;
	new tHealth = 0;
	new Float:tBonus = 0.0;
	for (new i = 1; i <= MaxClients; i++) {

		if (!IsLegitimateClient(i) || GetClientTeam(i) != TEAM_SURVIVOR) continue;
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
		if (!IsWitch(infected) && !IsSpecialCommon(infected) && !IsCommonInfected(infected)) {

			pos = FindListPositionByEntity(infected, Handle:InfectedHealth[i]);
			if (pos < 0) continue;	// how?
			cHealth = GetArrayCell(Handle:InfectedHealth[i], pos, 2);
			tHealth = GetArrayCell(Handle:InfectedHealth[i], pos, 1);
		}
		else if (IsWitch(infected)) {

			pos = FindListPositionByEntity(infected, Handle:WitchDamage[i]);
			if (pos < 0) continue;
			cHealth = GetArrayCell(Handle:WitchDamage[i], pos, 2);
			tHealth = GetArrayCell(Handle:WitchDamage[i], pos, 1);
		}
		else if (IsSpecialCommon(infected)) {

			pos = FindListPositionByEntity(infected, Handle:SpecialCommon[i]);
			if (pos < 0) continue;
			cHealth = GetArrayCell(Handle:SpecialCommon[i], pos, 2);
			tHealth = GetArrayCell(Handle:SpecialCommon[i], pos, 1);
		}
		else if (IsCommonInfected(infected)) {

			pos = FindListPositionByEntity(infected, Handle:CommonInfectedDamage[i]);
			if (pos < 0) continue;
			cHealth = GetArrayCell(Handle:CommonInfectedDamage[i], pos, 2);
			tHealth = GetArrayCell(Handle:CommonInfectedDamage[i], pos, 1);
		}
		tBonus = (cHealth * 1.0) / (tHealth * 1.0);
		isDamageValue += tBonus;
	}
	//PrintToChatAll("Damage percent: %3.3f", isDamageValue);
	if (isDamageValue > 1.0) isDamageValue = 1.0;
	return isDamageValue;
}

stock DisplayInfectedHealthBars(survivor, infected) {

	decl String:text[512];
	if (!IsWitch(infected) && !IsSpecialCommon(infected) && !IsCommonInfected(infected)) GetClientName(infected, text, sizeof(text));
	else if (IsWitch(infected)) Format(text, sizeof(text), "Bitch");
	else if (IsSpecialCommon(infected)) Format(text, sizeof(text), "%s", GetCommonValue(infected, "name?"));
	else if (IsCommonInfected(infected)) Format(text, sizeof(text), "Common");

	//Format(text, sizeof(text), "%s %s", GetConfigValue("director team name?"), text);
	if (LivingSurvivorCount() > 1) {

		Format(text, sizeof(text), "E.HP%s(%s)\nCNT%s", GetInfectedHealthBar(survivor, infected, true), text, GetInfectedHealthBar(survivor, infected, false));
		//Format(text, sizeof(text), "%s\nCNT%s", text, GetInfectedHealthBar(survivor, infected, false));
		Format(text, sizeof(text), "%s\t%s\n%s", GetStatusEffects(survivor), GetStatusEffects(survivor, 1), text);
	}
	else Format(text, sizeof(text), "%s\t%s\nCNT%s(%s)", GetStatusEffects(survivor), GetStatusEffects(survivor, 1), GetInfectedHealthBar(survivor, infected, false), text);
	PrintHintText(survivor, text);
}

stock String:GetStatusEffects(client, EffectType = 0) {

	decl String:eBar[64];
	if (EffectType == 0) {

		Format(eBar, sizeof(eBar), "[-]");
		if (IsClientStatusEffect(client, Handle:EntityOnFire)) Format(eBar, sizeof(eBar), "%s[Bu]", eBar);
		if (ISBLIND[client] != INVALID_HANDLE) Format(eBar, sizeof(eBar), "%s[Bl]", eBar);
		if (ISEXPLODE[client] != INVALID_HANDLE) Format(eBar, sizeof(eBar), "%s[Ex]", eBar);
		if (ISFROZEN[client] != INVALID_HANDLE) Format(eBar, sizeof(eBar), "%s[Fr]", eBar);
		if (ISSLOW[client] != INVALID_HANDLE) Format(eBar, sizeof(eBar), "%s[Sl]", eBar);
		if (ISFROZEN[client] != INVALID_HANDLE && IsClientStatusEffect(client, Handle:EntityOnFire)) Format(eBar, sizeof(eBar), "%s[Tx]", eBar);
		if (ISEXPLODE[client] != INVALID_HANDLE && IsClientStatusEffect(client, Handle:EntityOnFire)) ReplaceString(eBar, sizeof(eBar), "[Bu]", "[Sc]");
		if (IsClientStatusEffect(client, Handle:EntityReflect)) Format(eBar, sizeof(eBar), "%s[Re]", eBar);
		if (!(GetEntityFlags(client) & FL_ONGROUND)) Format(eBar, sizeof(eBar), "%s[Fl]", eBar);
	}
	else if (EffectType == 1) {

		Format(eBar, sizeof(eBar), "[+]");
	}
	return eBar;
}

stock String:GetInfectedHealthBar(survivor, infected, bool:bTrueHealth = false) {

	decl String:eBar[256];
	Format(eBar, sizeof(eBar), "[--------------------]");

	new pos = 0;
	if (!IsWitch(infected) && !IsSpecialCommon(infected) && !IsCommonInfected(infected)) pos = FindListPositionByEntity(infected, Handle:InfectedHealth[survivor]);
	else if (IsWitch(infected)) pos = FindListPositionByEntity(infected, Handle:WitchDamage[survivor]);
	else if (IsSpecialCommon(infected)) pos = FindListPositionByEntity(infected, Handle:SpecialCommon[survivor]);
	else if (IsCommonInfected(infected)) pos = FindListPositionByEntity(infected, Handle:CommonInfectedDamage[survivor]);
	if (pos >= 0) {

		new Float:isHealthRemaining = CheckTeammateDamages(infected, survivor);

		// isDamageContribution is the total damage the player has, themselves, dealt to the special infected.
		new isDamageContribution = 0;
		new isTotalHealth = 0;
		if (!IsWitch(infected) && !IsSpecialCommon(infected) && !IsCommonInfected(infected)) {

			isDamageContribution = GetArrayCell(Handle:InfectedHealth[survivor], pos, 2);
			isTotalHealth = GetArrayCell(Handle:InfectedHealth[survivor], pos, 1);
		}
		else if (IsWitch(infected)) {

			isDamageContribution = GetArrayCell(Handle:WitchDamage[survivor], pos, 2);
			isTotalHealth = GetArrayCell(Handle:WitchDamage[survivor], pos, 1);
		}
		else if (IsSpecialCommon(infected)) {

			isDamageContribution = GetArrayCell(Handle:SpecialCommon[survivor], pos, 2);
			isTotalHealth = GetArrayCell(Handle:SpecialCommon[survivor], pos, 1);
		}
		else if (IsCommonInfected(infected)) {

			isDamageContribution = GetArrayCell(Handle:CommonInfectedDamage[survivor], pos, 2);
			isTotalHealth = GetArrayCell(Handle:CommonInfectedDamage[survivor], pos, 1);
		}

		
		new Float:tPct = 100.0 - (isHealthRemaining * 100.0);
		new Float:yPct = ((isDamageContribution * 1.0) / (isTotalHealth * 1.0) * 100.0);
		new Float:ePct = 0.0;

		if (bTrueHealth) ePct = tPct;
		else ePct = yPct;
		new Float:eCnt = 0.0;

		for (new i = 1; i + 1 < strlen(eBar); i++) {

			if (eCnt + 5.0 < ePct) {

				eBar[i] = '=';
				eCnt += 5.0;
			}
		}
	}
	return eBar;
}

stock String:ExperienceBar(client) {

	decl String:eBar[256];
	new Float:ePct = 0.0;
	ePct = ((ExperienceLevel[client] * 1.0) / (CheckExperienceRequirement(client) * 1.0)) * 100.0;

	new Float:eCnt = 0.0;
	Format(eBar, sizeof(eBar), "[--------------------]");

	for (new i = 1; i + 1 <= strlen(eBar); i++) {

		if (eCnt + 5.0 < ePct) {

			eBar[i] = '=';
			eCnt += 5.0;
		}
	}

	return eBar;
}

stock String:MenuExperienceBar(client) {

	decl String:eBar[256];
	new Float:ePct = 0.0;
	ePct = ((ExperienceLevel[client] * 1.0) / (CheckExperienceRequirement(client) * 1.0)) * 100.0;

	new Float:eCnt = 0.0;
	Format(eBar, sizeof(eBar), "[----------]");

	for (new i = 1; i + 1 <= strlen(eBar); i++) {

		if (eCnt < ePct) {

			eBar[i] = '=';
			eCnt += 10.0;
		}
	}

	return eBar;
}

stock ChangeInfectedClass(client, zombieclass) {

	if (IsLegitimateClient(client) && !IsFakeClient(client) || IsLegitimateClientAlive(client) && IsFakeClient(client)) {

		if (GetClientTeam(client) == TEAM_INFECTED) {

			if (!IsGhost(client)) SetEntProp(client, Prop_Data, "m_takedamage", 1, 1);
			new wi;
			while ((wi = GetPlayerWeaponSlot(client, 0)) != -1) {

				RemovePlayerItem(client, wi);
				AcceptEntityInput(wi, "Kill");
				//RemoveEdict(wi);
			}
			SDKCall(g_hSetClass, client, zombieclass);
			AcceptEntityInput(MakeCompatEntRef(GetEntProp(client, Prop_Send, "m_customAbility")), "Kill");
			if (IsPlayerAlive(client)) SetEntProp(client, Prop_Send, "m_customAbility", GetEntData(SDKCall(g_hCreateAbility, client), g_oAbility));
			if (!IsGhost(client))
			{
				SetEntProp(client, Prop_Data, "m_takedamage", 2, 1);		// client can be killed again.
				SpeedMultiplier[client] = 1.0;		// defaulting the speed. It'll get modified in speed modifer spawn talents.
				SetEntPropFloat(client, Prop_Send, "m_flLaggedMovementValue", SpeedMultiplier[client]);

				FindAbilityByTrigger(client, _, 'a', FindZombieClass(client), 0);
			}
		}
	}
}

public Action:CMD_TeamChatCommand(client, args) {

	if (QuickCommandAccess(client, args, true)) {

		// Set colors for chat
		if (ChatTrigger(client, args, true)) return Plugin_Continue;
		else return Plugin_Handled;
	}
	return Plugin_Handled;
}

public Action:CMD_ChatCommand(client, args) {

	if (QuickCommandAccess(client, args, false)) {

		// Set Colors for chat
		if (ChatTrigger(client, args, false)) return Plugin_Continue;
		else return Plugin_Handled;
	}
	return Plugin_Handled;
}

public bool:ChatTrigger(client, args, bool:teamOnly) {

	if (!IsLegitimateClient(client)) return false;
	decl String:sBuffer[MAX_CHAT_LENGTH];
	decl String:Message[MAX_CHAT_LENGTH];
	decl String:Name[64];

	decl String:authString[64];
	GetClientAuthString(client, authString, sizeof(authString));

	GetClientName(client, Name, sizeof(Name));
	GetCmdArg(1, sBuffer, sizeof(sBuffer));
	StripQuotes(sBuffer);
	if (StrEqual(sBuffer, LastSpoken[client], false)) return false;
	Format(LastSpoken[client], sizeof(LastSpoken[]), "%s", sBuffer);
	//if (GetClientTeam(client) == TEAM_SPECTATOR) return true;

	decl String:TagColour[64];
	decl String:TagName[64];
	decl String:ChatColour[64];

	if (!IsReserve(client) && StringToInt(GetConfigValue("all players chat settings?")) == 0) {

		if (GetClientTeam(client) == TEAM_SURVIVOR) Format(Message, sizeof(Message), "{N}({B}%d{N}) {B}%s", PlayerLevel[client], Name);
		else if (GetClientTeam(client) == TEAM_INFECTED) Format(Message, sizeof(Message), "{N}({R}%d{N}) {R}%s", PlayerLevel[client], Name);
		else if (GetClientTeam(client) == TEAM_SPECTATOR) Format(Message, sizeof(Message), "{N}({GRA}%d{N}) {GRA}%s", PlayerLevel[client], Name);
		Format(sBuffer, sizeof(sBuffer), "-> %s", sBuffer);
	}
	else {

		GetArrayString(Handle:ChatSettings[client], 0, TagColour, sizeof(TagColour));
		GetArrayString(Handle:ChatSettings[client], 1, TagName, sizeof(TagName));
		GetArrayString(Handle:ChatSettings[client], 2, ChatColour, sizeof(ChatColour));

		if (StrEqual(TagColour, "none", false)) {

			Format(TagColour, sizeof(TagColour), "N");
			SetArrayString(Handle:ChatSettings[client], 0, TagColour);
		}
		if (!StrEqual(TagName, "none", false)) {

			Format(Message, sizeof(Message), "{N}[{%s}%s{N}]", TagColour, TagName);
		}
		if (StrEqual(ChatColour, "none", false)) {

			Format(ChatColour, sizeof(ChatColour), "N");
			SetArrayString(Handle:ChatSettings[client], 2, ChatColour);
		}
		if (!StrEqual(TagName, "none", false)) {

			if (GetClientTeam(client) == TEAM_SURVIVOR) Format(Message, sizeof(Message), "%s {N}({B}Lv.%d{N}) {B}%s", Message, PlayerLevel[client], Name);
			else if (GetClientTeam(client) == TEAM_INFECTED) Format(Message, sizeof(Message), "%s {N}({R}Lv.%d{N}) {R}%s", Message, PlayerLevel[client], Name);
			else if (GetClientTeam(client) == TEAM_SPECTATOR) Format(Message, sizeof(Message), "%s {N}({GRA}Lv.%d{N}) {GRA}%s", Message, PlayerLevel[client], Name);
		}
		else {

			if (GetClientTeam(client) == TEAM_SURVIVOR) Format(Message, sizeof(Message), "{N}({B}Lv.%d{N}) {B}%s", PlayerLevel[client], Name);
			else if (GetClientTeam(client) == TEAM_INFECTED) Format(Message, sizeof(Message), "{N}({R}Lv.%d{N}) {R}%s", PlayerLevel[client], Name);
			else if (GetClientTeam(client) == TEAM_SPECTATOR) Format(Message, sizeof(Message), "{N}({GRA}Lv.%d{N}) {GRA}%s", PlayerLevel[client], Name);
		}
		Format(sBuffer, sizeof(sBuffer), "{N}-> {%s}%s", ChatColour, sBuffer);
	}

	if (GetClientTeam(client) == TEAM_SPECTATOR) Format(Message, sizeof(Message), "{GRA}*spec* %s", Message);
	else {

		if (IsGhost(client)) Format(Message, sizeof(Message), "{B}*ghost* %s", Message);
		else if (!IsPlayerAlive(client)) {

			if (GetClientTeam(client) == TEAM_SURVIVOR) Format(Message, sizeof(Message), "{B}*dead* %s", Message);
			else Format(Message, sizeof(Message), "{R}*dead* %s", Message);
		}
		else if (IsIncapacitated(client)) Format(Message, sizeof(Message), "{B}*incap* %s", Message);
	}
	if (teamOnly) {

		if (GetClientTeam(client) == TEAM_SURVIVOR) Format(Message, sizeof(Message), "{B}*team* %s", Message);
		else if (GetClientTeam(client) == TEAM_INFECTED) Format(Message, sizeof(Message), "{R}*team* %s", Message);
		for (new i = 1; i <= MaxClients; i++) {

			if (IsLegitimateClient(i) && GetClientTeam(i) == GetClientTeam(client)) {

				if (GetClientTeam(client) == TEAM_SPECTATOR && !StrEqual(Spectator_LastChatUser, authString, false) ||
					GetClientTeam(client) == TEAM_SURVIVOR && !StrEqual(Survivor_LastChatUser, authString, false) ||
					GetClientTeam(client) == TEAM_INFECTED && !StrEqual(Infected_LastChatUser, authString, false)) {

					Client_PrintToChat(i, true, Message);
				}
				Client_PrintToChat(i, true, sBuffer);
			}
		}
		if (GetClientTeam(client) == TEAM_SPECTATOR) Format(Spectator_LastChatUser, sizeof(Spectator_LastChatUser), "%s", authString);
		else if (GetClientTeam(client) == TEAM_SURVIVOR) Format(Survivor_LastChatUser, sizeof(Survivor_LastChatUser), "%s", authString);
		else if (GetClientTeam(client) == TEAM_INFECTED) Format(Infected_LastChatUser, sizeof(Infected_LastChatUser), "%s", authString);
	}
	else {

		for (new i = 1; i <= MaxClients; i++) {

			if (IsLegitimateClient(i)) {

				if (!StrEqual(Public_LastChatUser, authString, false)) {

					Client_PrintToChat(i, true, Message);
				}
				Client_PrintToChat(i, true, sBuffer);
			}
		}
		//Format(Public_LastChatUser, sizeof(Public_LastChatUser), "%s", authString);
	}
	return false;
}

stock GetTargetClient(client, String:TargetName[]) {

	decl String:Name[64];
	for (new i = 1; i <= MaxClients; i++) {

		if (IsLegitimateClient(i) && i != client && GetClientTeam(i) == GetClientTeam(client)) {

			GetClientName(i, Name, sizeof(Name));
			if (StrContains(Name, TargetName, false) != -1) {

				// The name the player entered has been found, is a member of their team.
				//PrintToChatAll("Found %s , client %d", Name, i);
				return i;
			}
			/*else {

				PrintToChatAll("String: %s CLIENT NAME: %s CLIENT ID: %d", TargetName, Name, i);
			}*/
		}
	}
	return -1;
}

stock TeamworkRewardNotification(client, target, Float:PointCost, String:ItemName[]) {

	// Client is the user who purchased the item.
	// Target is the user who received it the item.
	// PointCost is the actual price the client paid - to determine their experience reward.

	if (client == target || b_IsFinaleActive) return;
	if (PointCost > StringToFloat(GetConfigValue("maximum teamwork experience?"))) PointCost = StringToFloat(GetConfigValue("maximum teamwork experience?"));
	// there's no teamwork in 'i'
	if (Luck[client] < 1) Luck[client] = 1; // a secret bonus to anyone with 0 luck who helps someone for the first time.

	new experienceReward	= RoundToCeil(PointCost * (StringToFloat(GetConfigValue("buy teammate item multiplier?")) * (GetRandomInt(1, Luck[client]) * StringToFloat(GetConfigValue("buy item luck multiplier?")))));

	decl String:ClientName[MAX_NAME_LENGTH];
	GetClientName(client, ClientName, sizeof(ClientName));
	decl String:ItemName_s[64];
	Format(ItemName_s, sizeof(ItemName_s), "%T", ItemName, target);

	PrintToChat(target, "%T", "received item from teammate", target, green, ItemName_s, white, blue, ClientName);
	// {1}{2} {3}purchased and given to you by {4}{5}

	Format(ItemName_s, sizeof(ItemName_s), "%T", ItemName, client);
	GetClientName(target, ClientName, sizeof(ClientName));
	PrintToChat(client, "%T", "teamwork reward notification", client, green, ClientName, white, blue, ItemName_s, white, green, experienceReward);
	// {1}{2} {3}has received {4}{5}{6}: {7}{8}

	ExperienceLevel[client] += experienceReward;
	ExperienceOverall[client] += experienceReward;
	if (ExperienceLevel[client] > CheckExperienceRequirement(client)) {

		ExperienceOverall[client] -= (ExperienceLevel[client] - CheckExperienceRequirement(client));
		ExperienceLevel[client] = CheckExperienceRequirement(client);
	}
}

public Action:CMD_TalentUpgrade(client, args) {

	if (args < 2)
	{
		PrintToChat(client, "!talentupgrade <idcode> <value>");
		return Plugin_Handled;
	}
	decl String:TalentName[64];

	decl String:arg[64];
	decl String:idNum[64];
	GetCmdArg(1, idNum, sizeof(idNum));
	GetCmdArg(2, arg, sizeof(arg));
	new value = StringToInt(arg);

	if (value < 0) value = 0;

	new size = GetArraySize(a_Menu_Talents);
	for (new i = 0; i < size; i++) {

		TalentUpgradeKeys[client]			= GetArrayCell(a_Menu_Talents, i, 0);
		TalentUpgradeValues[client]			= GetArrayCell(a_Menu_Talents, i, 1);
		TalentUpgradeSection[client]		= GetArrayCell(a_Menu_Talents, i, 2);

		GetArrayString(Handle:TalentUpgradeSection[client], 0, TalentName, sizeof(TalentName));

		if (!StrEqual(GetKeyValue(TalentUpgradeKeys[client], TalentUpgradeValues[client], "id_number"), idNum, false)) continue;
		if (FreeUpgrades[client] >= value && GetTalentStrength(client, TalentName) + value <= StringToInt(GetKeyValue(TalentUpgradeKeys[client], TalentUpgradeValues[client], "maximum talent points allowed?"))) {

			PlayerUpgradesTotal[client] += value;
			PurchaseTalentPoints[client] += value;
			FreeUpgrades[client] -= value;
			AddTalentPoints(client, TalentName, GetTalentStrength(client, TalentName) + value);
			return Plugin_Handled;
		}
	}
	return Plugin_Handled;
}

stock Float:GetMissingHealth(client) {

	return ((GetClientHealth(client) * 1.0) / (GetMaximumHealth(client) * 1.0));
}

stock bool:QuickCommandAccess(client, args, bool:b_IsTeamOnly) {

	decl String:Command[64];
	GetCmdArg(1, Command, sizeof(Command));
	StripQuotes(Command);
	new TargetClient = -1;
	if (Command[0] != '/' && Command[0] != '!') return true;

	decl String:SplitCommand[2][64];
	if (StrContains(Command, " ", false) != -1) {

		ExplodeString(Command, " ", SplitCommand, 2, 64);
		Format(Command, sizeof(Command), "%s", SplitCommand[0]);
		TargetClient	 = GetTargetClient(client, SplitCommand[1]);
		if (StrContains(Command, "revive", false) != -1 && TargetClient != client) return false;
	}

	decl String:text[512];
	decl String:cost[64];
	decl String:bind[64];
	decl String:pointtext[64];
	decl String:description[512];
	decl String:team[64];
	decl String:CheatCommand[64];
	decl String:CheatParameter[64];
	decl String:Model[64];
	decl String:Count[64];
	decl String:CountHandicap[64];
	decl String:Drop[64];
	new Float:PointCost		= 0.0;
	new Float:PointCostM	= 0.0;
	decl String:MenuName[64];
	new Float:f_GetMissingHealth = 1.0;

	new size					=	0;
	decl String:Description_Old[512];
	decl String:ItemName[64];
	decl String:IsRespawn[64];

	if (StringToInt(GetConfigValue("rpg mode?")) != 1) {

		if (StrEqual(Command[1], GetConfigValue("quick bind help?"), false)) {

			size						=	GetArraySize(a_Points);

			for (new i = 0; i < size; i++) {

				MenuKeys[client]		=	GetArrayCell(a_Points, i, 0);
				MenuValues[client]		=	GetArrayCell(a_Points, i, 1);

				//size2					=	GetArraySize(MenuKeys[client]);

				PointCost				= StringToFloat(GetKeyValue(MenuKeys[client], MenuValues[client], "point cost?"));
				if (PointCost < 0.0) continue;

				PointCostM				= StringToFloat(GetKeyValue(MenuKeys[client], MenuValues[client], "point cost minimum?"));
				Format(bind, sizeof(bind), "!%s", GetKeyValue(MenuKeys[client], MenuValues[client], "quick bind?"));
				Format(description, sizeof(description), "%T", GetKeyValue(MenuKeys[client], MenuValues[client], "description?"), client);
				Format(team, sizeof(team), "%s", GetKeyValue(MenuKeys[client], MenuValues[client], "team?"));

				/*
						
						Determine the actual cost for the player.
				*/
				
				if (Points[client] == 0.0 || Points[client] > 0.0 && (Points[client] * PointCost) < PointCostM) PointCost = PointCostM;
				else {

					PointCost += (PointCost * StringToFloat(GetConfigValue("points cost increase per level?")));
					if (PointCost > 1.0) PointCost = 1.0;
					PointCost *= Points[client];
				}
				Format(cost, sizeof(cost), "%3.3f", PointCost);
				

				if (StringToInt(team) != GetClientTeam(client)) continue;
				Format(pointtext, sizeof(pointtext), "%T", "Points", client);
				Format(pointtext, sizeof(pointtext), "%s %s", cost, pointtext);

				Format(text, sizeof(text), "%T", "Command Information", client, orange, bind, white, green, pointtext, white, blue, description);
				if (StrEqual(Description_Old, bind, false)) continue;		// in case there are duplicates
				Format(Description_Old, sizeof(Description_Old), "%s", bind);
				PrintToConsole(client, text);
			}
			PrintToChat(client, "%T", "Commands Listed Console", client, orange, white, green);
		}
		else {

			size						=	GetArraySize(a_Points);

			for (new i = 0; i < size; i++) {

				MenuKeys[client]		=	GetArrayCell(a_Points, i, 0);
				MenuValues[client]		=	GetArrayCell(a_Points, i, 1);
				MenuSection[client]		=	GetArrayCell(a_Points, i, 2);

				GetArrayString(Handle:MenuSection[client], 0, ItemName, sizeof(ItemName));

				PointCost		= StringToFloat(GetKeyValue(MenuKeys[client], MenuValues[client], "point cost?"));
				PointCostM		= StringToFloat(GetKeyValue(MenuKeys[client], MenuValues[client], "point cost minimum?"));
				Format(bind, sizeof(bind), "%s", GetKeyValue(MenuKeys[client], MenuValues[client], "quick bind?"));
				Format(team, sizeof(team), "%s", GetKeyValue(MenuKeys[client], MenuValues[client], "team?"));
				Format(CheatCommand, sizeof(CheatCommand), "%s", GetKeyValue(MenuKeys[client], MenuValues[client], "command?"));
				Format(CheatParameter, sizeof(CheatParameter), "%s", GetKeyValue(MenuKeys[client], MenuValues[client], "parameter?"));
				Format(Model, sizeof(Model), "%s", GetKeyValue(MenuKeys[client], MenuValues[client], "model?"));
				Format(Count, sizeof(Count), "%s", GetKeyValue(MenuKeys[client], MenuValues[client], "count?"));
				Format(CountHandicap, sizeof(CountHandicap), "%s", GetKeyValue(MenuKeys[client], MenuValues[client], "count handicap?"));
				Format(Drop, sizeof(Drop), "%s", GetKeyValue(MenuKeys[client], MenuValues[client], "drop?"));
				Format(MenuName, sizeof(MenuName), "%s", GetKeyValue(MenuKeys[client], MenuValues[client], "part of menu named?"));
				Format(IsRespawn, sizeof(IsRespawn), "%s", GetKeyValue(MenuKeys[client], MenuValues[client], "isrespawn?"));

				if (StrEqual(Command[1], bind, false) && StringToInt(team) == GetClientTeam(client)) {		// we found the bind the player used, and the player is on the appropriate team.

					if (StringToInt(IsRespawn) == 1) {

						if (TargetClient == -1) {

							if (!b_HasDeathLocation[client] || IsPlayerAlive(client) || b_HardcoreMode[client]) return false;
						}
						if (TargetClient != -1) {

							if ((IsPlayerAlive(TargetClient) || b_HardcoreMode[TargetClient])) return false;
						}
					}
					if (TargetClient != -1 && IsPlayerAlive(TargetClient)) {

						if (IsIncapacitated(TargetClient)) f_GetMissingHealth	= 0.0;	// Player is incapped, has no missing life.
						else f_GetMissingHealth	= GetMissingHealth(TargetClient);
					}

					new ExperienceCost			=	0;
					new PointPurchaseType		=	StringToInt(GetConfigValue("points purchase type?"));
					new TargetClient_s			=	0;

					if (FindCharInString(CheatCommand, ':') != -1) {

						BuildPointsMenu(client, CheatCommand[1], CONFIG_POINTS);		// Always CONFIG_POINTS for quick commands
					}
					else {

						if (GetClientTeam(client) == TEAM_INFECTED) {

							if (StringToInt(CheatParameter) == 8 && ActiveTanks() >= StringToInt(GetConfigValue("versus tank limit?"))) {

								PrintToChat(client, "%T", "Tank Limit Reached", client, orange, green, StringToInt(GetConfigValue("versus tank limit?")), white);
								return false;
							}
							else if (StringToInt(CheatParameter) == 8 && f_TankCooldown != -1.0) {

								PrintToChat(client, "%T", "Tank On Cooldown", client, orange, white);
								return false;
							}
						}
						if (Points[client] == 0.0 || Points[client] > 0.0 && (Points[client] * PointCost) < PointCostM) PointCost = PointCostM;
						else PointCost *= Points[client];

						if (Points[client] >= PointCost ||
							PointCost == 0.0 ||
							GetClientTeam(client) == TEAM_INFECTED && StrEqual(CheatCommand, "change class", false) && StringToInt(CheatParameter) != 8 && (TargetClient == -1 && IsGhost(client) || TargetClient != -1 && IsGhost(TargetClient))) {

							if (!StrEqual(CheatCommand, "change class") ||
								StrEqual(CheatCommand, "change class") && StrEqual(CheatParameter, "8") ||
								StrEqual(CheatCommand, "change class") && (TargetClient == -1 && IsPlayerAlive(client) && !IsGhost(client) || TargetClient != -1 && IsPlayerAlive(TargetClient) && !IsGhost(TargetClient))) {

								if (PointPurchaseType == 0 && (Points[client] >= PointCost || PointCost == 0.0)) Points[client] -= PointCost;
								else if (PointPurchaseType == 1 && (ExperienceLevel[client] >= ExperienceCost || ExperienceCost == 0)) ExperienceLevel[client] -= ExperienceCost;
							}

							if (StrEqual(CheatParameter, "common") && StrContains(Model, ".mdl", false) != -1) {

								Format(Count, sizeof(Count), "%d", StringToInt(Count) + (StringToInt(CountHandicap) * LivingSurvivorCount()));

								for (new iii = StringToInt(Count); iii > 0 && GetArraySize(CommonInfectedQueue) < StringToInt(GetConfigValue("common queue limit?")); iii--) {

									if (StringToInt(Drop) == 1) {

										ResizeArray(Handle:CommonInfectedQueue, GetArraySize(Handle:CommonInfectedQueue) + 1);
										ShiftArrayUp(Handle:CommonInfectedQueue, 0);
										SetArrayString(Handle:CommonInfectedQueue, 0, Model);
										TargetClient_s		=	FindLivingSurvivor();
										if (TargetClient_s > 0) ExecCheatCommand(TargetClient_s, CheatCommand, CheatParameter);
									}
									else PushArrayString(Handle:CommonInfectedQueue, Model);
								}
							}
							else if (StrEqual(CheatCommand, "change class")) {

								// We don't give them points back if ghost because we don't take points if ghost.
								//if (IsGhost(client) && PointPurchaseType == 0) Points[client] += PointCost;
								//else if (IsGhost(client) && PointPurchaseType == 1) ExperienceLevel[client] += ExperienceCost;
								if ((!IsGhost(client) && FindZombieClass(client) == ZOMBIECLASS_TANK && TargetClient == -1 ||
									TargetClient != -1 && !IsGhost(TargetClient) && FindZombieClass(TargetClient) == ZOMBIECLASS_TANK) && PointPurchaseType == 0) Points[client] += PointCost;
								else if ((!IsGhost(client) && FindZombieClass(client) == ZOMBIECLASS_TANK && TargetClient == -1 || TargetClient != -1 && !IsGhost(TargetClient) && FindZombieClass(TargetClient) == ZOMBIECLASS_TANK) && PointPurchaseType == 1) ExperienceLevel[client] += ExperienceCost;
								else if ((!IsGhost(client) && IsPlayerAlive(client) && FindZombieClass(client) == ZOMBIECLASS_CHARGER && L4D2_GetSurvivorVictim(client) != -1 && TargetClient == -1 ||
										  TargetClient != -1 && !IsGhost(TargetClient) && IsPlayerAlive(TargetClient) && FindZombieClass(TargetClient) == ZOMBIECLASS_CHARGER && L4D2_GetSurvivorVictim(TargetClient) == -1) && PointPurchaseType == 0) Points[client] += PointCost;
								else if ((!IsGhost(client) && IsPlayerAlive(client) && FindZombieClass(client) == ZOMBIECLASS_CHARGER && L4D2_GetSurvivorVictim(client) != -1 && TargetClient == -1 ||
										  TargetClient != -1 && !IsGhost(TargetClient) && IsPlayerAlive(TargetClient) && FindZombieClass(TargetClient) == ZOMBIECLASS_CHARGER && L4D2_GetSurvivorVictim(TargetClient) == -1) && PointPurchaseType == 1) ExperienceLevel[client] += ExperienceCost;
								if (FindZombieClass(client) != ZOMBIECLASS_TANK && TargetClient == -1 || TargetClient != -1 && FindZombieClass(TargetClient) != ZOMBIECLASS_TANK) {

									if (TargetClient == -1) ChangeInfectedClass(client, StringToInt(CheatParameter));
									else ChangeInfectedClass(TargetClient, StringToInt(CheatParameter));

									if (TargetClient != -1) TeamworkRewardNotification(client, TargetClient, PointCost, ItemName);
								}
							}
							else if (StringToInt(IsRespawn) == 1) {

								if (TargetClient == -1) {

									h_PreviousDeath[client] = -1;

									SDKCall(hRoundRespawn, client);
									CreateTimer(1.0, Timer_TeleportRespawn, client, TIMER_FLAG_NO_MAPCHANGE);
								}
								else {

									h_PreviousDeath[TargetClient] = client;		// we want to teleport the targeted player to the person who respawned them.

									SDKCall(hRoundRespawn, TargetClient);
									CreateTimer(1.0, Timer_TeleportRespawn, TargetClient, TIMER_FLAG_NO_MAPCHANGE);

									TeamworkRewardNotification(client, TargetClient, PointCost, ItemName);
								}
							}
							else {

								//CheckIfRemoveWeapon(client, CheatParameter);

								if (PointCost == 0.0 && GetClientTeam(client) == TEAM_SURVIVOR) {

									// there is no code here to give a player a FREE weapon forcefully because that would be fucked up. TargetClient just gets ignored here.
									if (StrContains(CheatParameter, "pistol", false) != -1 || IsMeleeWeaponParameter(CheatParameter)) L4D_RemoveWeaponSlot(client, L4DWeaponSlot_Secondary);
									else L4D_RemoveWeaponSlot(client, L4DWeaponSlot_Primary);
								}
								if (IsMeleeWeaponParameter(CheatParameter)) {

									// Get rid of their old weapon
									//if (TargetClient == -1)	L4D_RemoveWeaponSlot(client, L4DWeaponSlot_Secondary);
									//else L4D_RemoveWeaponSlot(TargetClient, L4DWeaponSlot_Secondary);

									new ent			= CreateEntityByName("weapon_melee");

									DispatchKeyValue(ent, "melee_script_name", CheatParameter);
									DispatchSpawn(ent);

									if (TargetClient == -1) EquipPlayerWeapon(client, ent);
									else EquipPlayerWeapon(TargetClient, ent);
								}
								else {

									//if (StrContains(CheatParameter, "pistol", false) != -1) L4D_RemoveWeaponSlot(client, L4DWeaponSlot_Secondary);
									//else L4D_RemoveWeaponSlot(client, L4DWeaponSlot_Primary);

									if (TargetClient == -1) {

										if (StrEqual(CheatParameter, "health")) {

											if (L4D2_GetInfectedAttacker(client) != -1) Points[client] += PointCost;
											else {

												ExecCheatCommand(client, CheatCommand, CheatParameter);
												GiveMaximumHealth(client);		// So instant heal doesn't put a player above their maximum health pool.
											}
										}
										else ExecCheatCommand(client, CheatCommand, CheatParameter);
									}
									else {

										if (StrEqual(CheatParameter, "health")) {

											if (L4D2_GetInfectedAttacker(TargetClient) != -1 || f_GetMissingHealth > StringToFloat(GetConfigValue("teammate heal health requirement?"))) Points[client] += PointCost;
											else {

												ExecCheatCommand(TargetClient, CheatCommand, CheatParameter);
												GiveMaximumHealth(TargetClient);		// So instant heal doesn't put a player above their maximum health pool.
											}
										}
										else ExecCheatCommand(TargetClient, CheatCommand, CheatParameter);
									}
								}
								if (TargetClient != -1) {

									if (StrEqual(CheatParameter, "health", false) && L4D2_GetInfectedAttacker(TargetClient) == -1 && f_GetMissingHealth <= StringToFloat(GetConfigValue("teammate heal health requirement?")) || !StrEqual(CheatParameter, "health", false)) {

										if (StrEqual(CheatParameter, "health", false)) TeamworkRewardNotification(client, TargetClient, PointCost * (1.0 - f_GetMissingHealth), ItemName);
										else TeamworkRewardNotification(client, TargetClient, PointCost, ItemName);
									}
								}
							}
							//if (TargetClient != -1) LogMessage("%N bought %s for %N", client, CheatParameter, TargetClient);
						}
						else {

							if (PointPurchaseType == 0) PrintToChat(client, "%T", "Not Enough Points", client, orange, white, PointCost);
							else if (PointPurchaseType == 1) PrintToChat(client, "%T", "Not Enough Experience", client, orange, white, ExperienceCost);
						}
					}
					break;
				}
			}
		}
	}
	if (Command[0] == '!') return true;
	return false;
}

stock LoadHealthMaximum(client) {

	if (GetClientTeam(client) == TEAM_INFECTED) DefaultHealth[client] = GetClientHealth(client);
	else DefaultHealth[client] = 100;	// 100 is the default. no reason to think otherwise.
	FindAbilityByTrigger(client, _, 'a', FindZombieClass(client), 0);
}

stock SetSpeedMultiplierBase(attacker, Float:amount = 1.0) {

	if (!IsFakeClient(attacker)) SpeedMultiplierBase[attacker] = amount + (Agility[attacker] * 0.01);
	else SpeedMultiplierBase[attacker] = amount + (Agility_Bots * 0.01);
	SpeedMultiplier[attacker] = SpeedMultiplierBase[attacker];
	//LogMessage("Base movement speed for %N: %3.3f", attacker, SpeedMultiplierBase[attacker]);
	SetEntPropFloat(attacker, Prop_Send, "m_flLaggedMovementValue", SpeedMultiplierBase[attacker]);
}

stock PlayerSpawnAbilityTrigger(attacker) {

	if (IsLegitimateClientAlive(attacker)) {

		SetSpeedMultiplierBase(attacker);

		SpeedMultiplier[attacker] = SpeedMultiplierBase[attacker];		// defaulting the speed. It'll get modified in speed modifer spawn talents.
		
		if (GetClientTeam(attacker) == TEAM_INFECTED) DefaultHealth[attacker] = GetClientHealth(attacker);
		else DefaultHealth[attacker] = 100;
		b_IsImmune[attacker] = false;

		FindAbilityByTrigger(attacker, _, 'a', FindZombieClass(attacker), 0);
		GiveMaximumHealth(attacker);
	}
}

stock bool:NoHumanInfected() {

	for (new i = 1; i <= MaxClients; i++) {

		if (IsClientInGame(i) && !IsFakeClient(i) && GetClientTeam(i) == TEAM_INFECTED) return false;
	}

	return true;
}

stock InfectedBotSpawn(client) {

	//new Float:HealthBonus = 0.0;
	//new Float:SpeedBonus = 0.0;

	if (IsLegitimateClient(client)) {

		/*

			In the new health adjustment system, it is based on the number of living players as well as their total level.
			Health bonus is multiplied by the number of total levels of players alive in the session.
		*/
		/*decl String:InfectedHealthBonusType[64];
		Format(InfectedHealthBonusType, sizeof(InfectedHealthBonusType), "(%d) infected health bonus", FindZombieClass(client));
		HealthBonus = StringToFloat(GetConfigValue(InfectedHealthBonusType)) * (LivingSurvivorLevels() * 1.0);*/

		//FindAbilityByTrigger(client, _, 'a', 0, 0);
	}
}

stock CheckServerLevelRequirements(client) {

	new ServerLevelRequirement = StringToInt(GetConfigValue("server level requirement?"));
	LogMessage("Server Level Requirement is %d and %N level is %d", ServerLevelRequirement, client, PlayerLevel[client]);
	if (ServerLevelRequirement <= 1) return;
	if (PlayerLevel[client] < ServerLevelRequirement) {

		decl String:LevelKickMessage[128];
		Format(LevelKickMessage, sizeof(LevelKickMessage), "%T", "level requirement kick", client, PlayerLevel[client], GetConfigValue("server level requirement?"));
		KickClient(client, LevelKickMessage);
	}
	//EnforceServerTalentMaximum(client);
}

stock LivingSurvivorLevels() {

	new f = 0;
	for (new i = 1; i <= MaxClients; i++) {

		if (IsLegitimateClientAlive(i) && !IsFakeClient(i) && GetClientTeam(i) == TEAM_SURVIVOR) f += PlayerLevel[i];
	}
	if (StringToInt(GetConfigValue("infected bot level type?")) == 1) return f;	// player combined level
	if (LivingHumanSurvivors() > 0) return f / LivingHumanSurvivors();
	return 0;
}

stock bool:IsLegitimateClient(client) {

	if (client < 1 || client > MaxClients || !IsClientConnected(client) || !IsClientInGame(client)) return false;
	return true;
}

stock bool:IsLegitimateClientAlive(client) {

	if (IsLegitimateClient(client) && IsPlayerAlive(client)) return true;
	return false;
}

stock RefreshSurvivor(client) {

	SetEntProp(client, Prop_Send, "m_currentReviveCount", 0);
	StopSound(client, SNDCHAN_AUTO, "player/heartbeatloop.wav");
	SetEntProp(client, Prop_Send, "m_bIsOnThirdStrike", 0);
}

stock AutoAdjustHandicap(client, AdjustmentProtocol = 0) {

	if (HandicapLevel[client] == -1) return;
	if (AdjustmentProtocol == 0) {		// 0 for incapacitation changes.

		if (HandicapLevel[client] > 1) {

			HandicapLevel[client]--;
			PrintToChat(client, "%T", "handicap level reduced by force", client, white, green, white, orange, HandicapLevel[client]);
		}
	}
	else if (AdjustmentProtocol == 1 || HandicapLevel[client] <= 1) {	// 1 for things like death where we want to straight-up deactivate it.

		HandicapLevel[client] = -1;
		PrintToChat(client, "%T", "handicap level disabled by force", client, white, green, white, orange);
	}
}

/*stock CheckMaxAllowedHandicap(client) {

	if (HandicapLevel[client] != -1 && HandicapLevel[client] > (StringToInt(GetConfigValue("handicap breadth?")) - MapRoundsPlayed)) {

		if (HandicapLevel[client] == 1 || StringToInt(GetConfigValue("handicap breadth?")) - MapRoundsPlayed <= 0) {

			HandicapLevel[client] = -1;
			PrintToChat(client, "%T", "handicap level disabled by force", client, white, green, white, orange);
		}
		else if (StringToInt(GetConfigValue("handicap breadth?")) - MapRoundsPlayed >= 1) {

			HandicapLevel[client] = (StringToInt(GetConfigValue("handicap breadth?")) - MapRoundsPlayed);
			PrintToChat(client, "%T", "handicap level reduced by force", client, white, green, white, orange, HandicapLevel[client]);
		}
	}
}*/

public Action:Timer_CheckForExperienceDebt(Handle:timer, any:client) {

	if (!IsLegitimateClient(client)) return Plugin_Stop;
	if (StringToInt(GetConfigValue("experience debt enabled?")) == 1 && PlayerLevel[client] >= StringToInt(GetConfigValue("experience debt level?")) && !IsPlayerAlive(client) && !b_IsDead[client]) {

		b_IsDead[client] = true;
		ExperienceDebt[client] += GetUpgradeExperienceCost(client);
		if (ExperienceDebt[client] > StringToInt(GetConfigValue("experience debt cap?"))) ExperienceDebt[client] = StringToInt(GetConfigValue("experience debt cap?"));
		PrintToChat(client, "%T", "experience debt penalty", client, orange, blue, orange, GetUpgradeExperienceCost(client));

		if (IsLegitimateClient(client) && b_IsHooked[client]) {

			b_IsHooked[client] = false;
			SDKUnhook(client, SDKHook_OnTakeDamage, OnTakeDamage);
		}
		if (HandicapLevel[client] != -1) {

			HandicapLevel[client] = -1;
			PrintToChat(client, "%T", "handicap level disabled by force", client, white, green, white, orange);
		}
	}
	return Plugin_Stop;
}

stock IncapacitateOrKill(client, attacker = 0, healthvalue = 0, bool:bIsFalling = false) {

	if (IsLegitimateClient(client) && !IsFakeClient(client) && IsPlayerAlive(client)) {

		new IncapCounter	= GetEntProp(client, Prop_Send, "m_currentReviveCount");
		if (IncapCounter >= StringToInt(GetConfigValue("survivor max incap?")) ||
			IsIncapacitated(client)) {

			if (!bIsFalling) b_HasDeathLocation[client] = true;
			else b_HasDeathLocation[client] = false;
			GetClientAbsOrigin(client, Float:DeathLocation[client]);
			CreateTimer(1.0, Timer_CheckForExperienceDebt, client, TIMER_FLAG_NO_MAPCHANGE);
			b_IsHooked[client] = false;
			SDKUnhook(client, SDKHook_OnTakeDamage, OnTakeDamage);
			ForcePlayerSuicide(client);
			RefreshSurvivor(client);
			AutoAdjustHandicap(client, 1);
			WipeDamageContribution(client);
			FindAbilityByTrigger(client, attacker, 'E', FindZombieClass(client), 0);
			if (attacker > 0) FindAbilityByTrigger(attacker, client, 'e', FindZombieClass(attacker), healthvalue);
		}
		else if (!IsIncapacitated(client)) {

			SetEntProp(client, Prop_Send, "m_isIncapacitated", 1);
			IncapacitatedHealth[client] = 300;
			if (attacker != 0 && IsLegitimateClient(attacker)) FindAbilityByTrigger(client, attacker, 'N', FindZombieClass(client), healthvalue);
			else FindAbilityByTrigger(client, attacker, 'n', FindZombieClass(client), healthvalue);
			SetEntityHealth(client, IncapacitatedHealth[client]);
			RoundIncaps[client]++;
			AutoAdjustHandicap(client, 0);
		}
	}
}

stock bool:IsAllSurvivorsDead() {

	for (new i = 1; i <= MaxClients; i++) {

		if (IsLegitimateClientAlive(i) && GetClientTeam(i) == TEAM_SURVIVOR) return false;
	}
	return true;
}

stock GetClientTotalHealth(client) {

	new SolidHealth			= GetClientHealth(client);
	new Float:TempHealth	= GetEntPropFloat(client, Prop_Send, "m_healthBuffer");

	return RoundToCeil(SolidHealth + TempHealth);
}

stock SetClientTotalHealth(client, damage) {

	new SolidHealth			= GetClientHealth(client);

	if (!IsIncapacitated(client)) {

		new Float:TempHealth	= GetEntPropFloat(client, Prop_Send, "m_healthBuffer");
		if (damage <= RoundToFloor(TempHealth)) SetEntPropFloat(client, Prop_Send, "m_healthBuffer", TempHealth - damage);
		else if (damage > RoundToFloor(TempHealth)) {

			damage = damage - RoundToFloor(TempHealth);
			SetEntPropFloat(client, Prop_Send, "m_healthBuffer", 0.0);
			SetEntityHealth(client, SolidHealth - damage);
		}
	}
	else {

		new ActualHealth = GetClientHealth(client);

		if (damage > ActualHealth) IncapacitateOrKill(client);
		else SetEntityHealth(client, ActualHealth - damage);
	}
}

stock RestoreClientTotalHealth(client, damage) {

	new SolidHealth			= GetClientHealth(client);
	new Float:TempHealth	= 0.0;
	if (GetClientTeam(client) == TEAM_SURVIVOR) GetEntPropFloat(client, Prop_Send, "m_healthBuffer");
	if (RoundToFloor(TempHealth) > 0) SetEntPropFloat(client, Prop_Send, "m_healthBuffer", TempHealth + damage);
	else SetEntityHealth(client, SolidHealth + damage);
}

stock SetClientTempHealth(client, health) {

	new Float:TempHealth	= GetEntPropFloat(client, Prop_Send, "m_healthBuffer");
	SetEntPropFloat(client, Prop_Send, "m_healthBuffer", TempHealth + health);
}

/*stock ModifyTempHealth(client, Float:health) {

	SetEntPropFloat(client, Prop_Send, "m_healthBuffer", health);
}*/

stock SetClientMaximumTempHealth(client) {

	SetMaximumHealth(client);
	SetEntityHealth(client, 1);
	SetClientTempHealth(client, GetMaximumHealth(client) - 1);
}

stock IncapHealPlayer(client, activator, Float:s_Strength, Float:s_Time) {

	if (!IsLegitimateClient(client) || IsFakeClient(client) || GetClientTeam(client) != TEAM_SURVIVOR || !IsPlayerAlive(client)) return;
	if (s_Time <= 0.0) {

		/*

			Permanent health increase.
		*/
		IncapacitatedHealth[client] = RoundToCeil(300 + (300 * s_Strength));
		if (IsIncapacitated(client)) SetEntityHealth(client, IncapacitatedHealth[client]);
	}
	else if (IsIncapacitated(client)) {

		new Float:HealAmount		= IncapacitatedHealth[client] * s_Strength;
		if (GetClientHealth(client) + RoundToFloor(HealAmount) > IncapacitatedHealth[client]) SetEntityHealth(client, IncapacitatedHealth[client]);
		else SetEntityHealth(client, GetClientHealth(client) + RoundToFloor(HealAmount));
	}
}

stock HealPlayer(client, activator, Float:s_Strength, ability) {

	if (IsLegitimateClientAlive(client)) {

		if (ability == 'h' && IsIncapacitated(client)) return;

		new Float:HealAmount		= GetMaximumHealth(client) * s_Strength;
		if (GetClientTeam(client) == TEAM_SURVIVOR && !IsIncapacitated(client) || GetClientTeam(client) == TEAM_INFECTED) {

			if (!b_HardcoreMode[client] || GetClientTeam(client) != TEAM_SURVIVOR) {

				if (GetClientHealth(client) + RoundToFloor(HealAmount) > GetMaximumHealth(client)) GiveMaximumHealth(client);
				else SetEntityHealth(client, GetClientHealth(client) + RoundToFloor(HealAmount));
			}
			/*else {

				if (GetClientTotalHealth(client) > GetMaximumHealth(client)) SetClientMaximumTempHealth(client);
				else {

					SetEntityHealth(client, 1);
					SetClientTempHealth(client, RoundToFloor(HealAmount));
				}
			}*/
		}
		if (ability == 'T') ReadyUp_NtvFriendlyFire(activator, client, 0 - RoundToCeil(HealAmount), GetClientHealth(client), 1, 0);	// we "subtract" negative values from health.
	}
}

stock EnableHardcoreMode(client) {

	SetEntityRenderMode(client, RENDER_TRANSCOLOR);
	SetEntityRenderColor(client, 255, 0, 0, 255);
	SetEntProp(client, Prop_Send, "m_bIsOnThirdStrike", 1);
	EmitSoundToClient(client, "player/heartbeatloop.wav");
	//SetClientMaximumTempHealth(client);
}

/*

	Helping new players adjust to the game brought on the idea of Pets.
	Pets provide benefits to the user, and can be changed at any time.

	Pets that have not yet been discovered are hidden from player view.
	This function properly positions the pet.
*/
/*
new entity = CreateEntityByName("prop_dynamic_override");
	if( entity != -1 )
	{
		SetEntityModel(entity, g_sModels[index]);
		DispatchSpawn(entity);
		if( g_bLeft4Dead2 )
		{
			SetEntPropFloat(entity, Prop_Send, "m_flModelScale", g_fSize[index]);
		}

		SetVariantString("!activator");
		AcceptEntityInput(entity, "SetParent", client);
		SetVariantString("eyes");
		AcceptEntityInput(entity, "SetParentAttachment");
		TeleportEntity(entity, g_vPos[index], g_vAng[index], NULL_VECTOR);
		SetEntProp(entity, Prop_Data, "m_iEFlags", 0);

		if( g_iCvarOpaq )
		{
			SetEntityRenderMode(entity, RENDER_TRANSCOLOR);
			SetEntityRenderColor(entity, 255, 255, 255, g_iCvarOpaq);
		}

		g_iSelected[client] = index;
		g_iHatIndex[client] = EntIndexToEntRef(entity);

		if( !g_bHatView[client] )
			SDKHook(entity, SDKHook_SetTransmit, Hook_SetTransmit);

		if( g_bTranslation == false )
		{
			CPrintToChat(client, "%s%t", CHAT_TAG, "Hat_Wearing", g_sNames[index]);
		}
		else
		{
			decl String:sMsg[128];
			Format(sMsg, sizeof(sMsg), "Hat %d", index + 1);
			Format(sMsg, sizeof(sMsg), "%T", sMsg, client);
			CPrintToChat(client, "%s%t", CHAT_TAG, "Hat_Wearing", sMsg);
		}

		return true;
	}
*/

