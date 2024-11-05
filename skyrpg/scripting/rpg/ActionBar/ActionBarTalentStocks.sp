stock bool GetActiveSpecialAmmoType(client, effect) {

	char EffectT[4];
	Format(EffectT, sizeof(EffectT), "%c", effect);
	char TheAmmoEffect[10];
	GetSpecialAmmoEffect(TheAmmoEffect, sizeof(TheAmmoEffect), client, ActiveSpecialAmmo[client]);

	if (StrContains(TheAmmoEffect, EffectT, true) != -1) return true;
	return false;
}

stock bool IsClientInRangeSpecialAmmoBoolean(client, char[] EffectT = "any") {
	if (client < 1) return false;
	if (GetArraySize(SpecialAmmoData) < 1) return false;
	bool clientIsLegitimate = IsLegitimateClient(client);
	//decl String:EffectT[4];
	if (clientIsLegitimate && !IsPlayerAlive(client)) return false;
	float ClientPos[3];
	if (clientIsLegitimate) GetClientAbsOrigin(client, ClientPos);
	else {
		GetEntPropVector(client, Prop_Send, "m_vecOrigin", ClientPos);
	}
	for (int i = 0; i < GetArraySize(SpecialAmmoData); i++) {
		float EntityPos[3];
		char TalentInfo[4][512];
		char value[10];
		//if (i < 0) i = 0;
		// TalentInfo[0] = TalentName of ammo.
		// TalentInfo[1] = Talent Strength (so use StringToInt)
		// TalentInfo[2] = Talent Damage
		// TalentInfo[3] = Talent Interval
		int owner = FindClientByIdNumber(GetArrayCell(SpecialAmmoData, i, 7));
		int pos			= GetArrayCell(SpecialAmmoData, i, 3);
		if (!StrEqual(EffectT, "any")) {
			IsClientInRangeSAValues[owner]				= GetArrayCell(a_Menu_Talents, pos, 1);
			GetArrayString(IsClientInRangeSAValues[owner], SPELL_AMMO_EFFECT, value, sizeof(value));
			if (StrContains(EffectT, value, true) == -1) continue;	// a talent could allow multiple ammo types through. e.g. EffectT = bh (bean bag or heal)
		}
		GetArrayString(a_Database_Talents, pos, TalentInfo[0], sizeof(TalentInfo[]));
		//GetTalentNameAtMenuPosition(owner, pos, TalentInfo[0], sizeof(TalentInfo[]));

		float t_Range		= GetSpecialAmmoStrength(owner, TalentInfo[0], 3, _, _, pos);
		EntityPos[0] = GetArrayCell(SpecialAmmoData, i, 0);
		EntityPos[1] = GetArrayCell(SpecialAmmoData, i, 1);
		EntityPos[2] = GetArrayCell(SpecialAmmoData, i, 2);
		if (GetVectorDistance(ClientPos, EntityPos) > (t_Range / 2)) continue;
		return true;
	}
	return false;
}

/*

	Checks whether a player is within range of a special ammo, and if they are, how affected they are.
	GetStatusOnly is so we know whether to start the revive bar for revive ammo, without triggering the actual effect, we just want to know IF they're affected, for example.
	If ammoposition is >= 0 AND GetStatus is enabled, it will return only for the ammo in question.
*/

stock float IsClientInRangeSpecialAmmo(client, char[] EffectT, AmmoPosition = -1, int realowner = 0, int experienceCalculator = 0, int experienceTarget = -1) {
	if (GetArraySize(SpecialAmmoData) < 1) return 0.0;
	bool clientIsLegitimate = IsLegitimateClient(client);
	//decl String:EffectT[4];
	if (!clientIsLegitimate || !IsPlayerAlive(client)) return 0.0;
	float ClientPos[3];
	if (clientIsLegitimate) GetClientAbsOrigin(client, ClientPos);
	else {
		GetEntPropVector(client, Prop_Send, "m_vecOrigin", ClientPos);
	}

	//Format(EffectT, sizeof(EffectT), "%c", effect);
	float EffectStrength = 0.0;
	float EffectStrengthBonus = 0.0;
	for (int i = (AmmoPosition > 0) ? AmmoPosition : 0; i < GetArraySize(SpecialAmmoData); i++) {
		if (i < 0) break;
		float EntityPos[3];
		char TalentInfo[4][512];
		char value[10];
		//if (i < 0) i = 0;
		// TalentInfo[0] = TalentName of ammo.
		// TalentInfo[1] = Talent Strength (so use StringToInt)
		// TalentInfo[2] = Talent Damage
		// TalentInfo[3] = Talent Interval
		int owner = FindClientByIdNumber(GetArrayCell(SpecialAmmoData, i, 7));
		int pos			= GetArrayCell(SpecialAmmoData, i, 3);
		if (pos < 0) continue;
		IsClientInRangeSAValues[owner]				= GetArrayCell(a_Menu_Talents, pos, 1);
		GetArrayString(IsClientInRangeSAValues[owner], SPELL_AMMO_EFFECT, value, sizeof(value));
		if (!StrEqual(value, EffectT, true)) continue;	// if this ammo isn't the ammo type we're checking, skip.
		GetArrayString(a_Database_Talents, pos, TalentInfo[0], sizeof(TalentInfo[]));
		//GetTalentNameAtMenuPosition(owner, pos, TalentInfo[0], sizeof(TalentInfo[]));

		float t_Range		= GetSpecialAmmoStrength(owner, TalentInfo[0], 3, _, _, pos);
		EntityPos[0] = GetArrayCell(SpecialAmmoData, i, 0);
		EntityPos[1] = GetArrayCell(SpecialAmmoData, i, 1);
		EntityPos[2] = GetArrayCell(SpecialAmmoData, i, 2);
		if (GetVectorDistance(ClientPos, EntityPos) > (t_Range / 2)) continue;

		if (realowner == 0 || realowner == owner) {

			float EffectStrengthValue = GetArrayCell(IsClientInRangeSAValues[owner], SPECIAL_AMMO_TALENT_STRENGTH);
			float fSpellBuffStrUp = GetAbilityStrengthByTrigger(owner, _, TRIGGER_spellbuff, _, _, _, _, RESULT_strengthup, 0, true);
			if (fSpellBuffStrUp > 0.0) EffectStrengthValue += (EffectStrengthValue * fSpellBuffStrUp);

			float EffectMultiplierValue = GetArrayCell(IsClientInRangeSAValues[owner], SPELL_EFFECT_MULTIPLIER);

			if (EffectStrength == 0.0) EffectStrength = EffectStrengthValue;
			else EffectStrengthBonus += EffectMultiplierValue;
			if (experienceCalculator > 0) {
				// the owner of this ammo that is buffing a player that has benefitted from it and is not just idling inside its field deserves to be rewarded
				// so we're going to give them buffing experience.
				int buffingExperienceToAwardTheOwner = RoundToCeil(experienceCalculator * EffectStrengthValue);
				//if (EffectStrengthBonus > 0.0) buffingExperienceToAwardTheOwner += RoundToCeil(experienceCalculator * EffectMultiplierValue);
				if (!clientIsLegitimate || myCurrentTeam[client] != myCurrentTeam[owner]) AwardExperience(owner, HEXING_CONTRIBUTION, buffingExperienceToAwardTheOwner);
				else {
					AwardExperience(owner, BUFFING_CONTRIBUTION, buffingExperienceToAwardTheOwner);
					AddContributionToEngagedEnemiesOfAlly(owner, client, CONTRIBUTION_AWARD_BUFFING, buffingExperienceToAwardTheOwner, experienceTarget);
				}
			}
		}
		if (AmmoPosition >= 0) break;
	}
	if (EffectStrengthBonus > 0.0) EffectStrength += (EffectStrength * EffectStrengthBonus);
	return EffectStrength;
}

public Action Timer_AmmoTriggerCooldown(Handle timer, any client) {

	if (IsLegitimateClient(client)) AmmoTriggerCooldown[client] = false;
	return Plugin_Stop;
}

stock AdvertiseAction(client, char[] TalentName, bool isSpell = false) {

	char TalentName_Temp[64];
	char text[64];

	GetTranslationOfTalentName(client, TalentName, text, sizeof(text), _, true);
	if (StrEqual(text, "-1")) GetTranslationOfTalentName(client, TalentName, text, sizeof(text), true);

	char printer[512];
	Format(TalentName_Temp, sizeof(TalentName_Temp), "%t", text);
	if (isSpell) Format(printer, sizeof(printer), "%t", "player uses spell", baseName[client], TalentName_Temp);
	else Format(printer, sizeof(printer), "%t", "player uses ability", baseName[client], TalentName_Temp);
	for (int i = 1; i <= MaxClients; i++) {
		if (!IsLegitimateClient(i) || IsFakeClient(i)) continue;
		Client_PrintToChat(i, true, printer);
	}
}

stock float GetSpellCooldown(client, char[] spellChar = "o", int pos) {	// by default, pass ANY value other than L

	float SpellCooldown = GetAbilityValue(client, ABILITY_COOLDOWN, pos);
	if (SpellCooldown == -1.0) return 0.0;
	float TheAbilityMultiplier = (!StrEqual(spellChar, "L")) ? GetAbilityMultiplier(client, "L", -1) : -1.0;

	if (TheAbilityMultiplier != -1.0) {

		if (TheAbilityMultiplier < 0.0) TheAbilityMultiplier = 0.1;
		else if (TheAbilityMultiplier > 0.0) { //cooldowns are reduced

			SpellCooldown -= (SpellCooldown * TheAbilityMultiplier);
			if (SpellCooldown < 0.0) SpellCooldown = 0.0;
		}
	}
	return SpellCooldown;
}

stock bool UseAbility(client, target = -1, char[] TalentName, Handle Values, float TargetPos[3], int menuPos) {

	if (!b_IsActiveRound || GetAmmoCooldownTime(client, TalentName, true) != -1.0 || IsAbilityActive(client, TalentName, _, _, menuPos)) return false;
	if (IsLegitimateClientAlive(target)) GetClientAbsOrigin(target, TargetPos);

	float TheAbilityMultiplier = 0.0;
	int myAttacker = L4D2_GetInfectedAttacker(client);
	if (GetArrayCell(Values, ABILITY_REQ_NO_ENSNARE) == 1 && myAttacker != -1) return false;

	float ClientPos[3];
	GetClientAbsOrigin(client, ClientPos);

	int MySecondary = GetPlayerWeaponSlot(client, 1);
	char MyWeapon[64];

	char Effects[64];
	//int menuPos = GetMenuPosition(client, TalentName);
	float SpellCooldown = GetSpellCooldown(client, _, menuPos);

	//new MyAttacker = L4D2_GetInfectedAttacker(client);
	int MyBonus = 0;
	//new MyMaxHealth = GetMaximumHealth(client);
	GetArrayString(Values, ABILITY_TOGGLE_EFFECT, Effects, sizeof(Effects));
	if (!StrEqual(Effects, "-1")) {
		if (StrEqual(Effects, "stagger", true)) {
			if (myAttacker == -1 || IsIncapacitated(client)) return false;	// knife cannot trigger if you are not a victim.
			ReleasePlayer(client);
			//EmitSoundToClient(client, "player/heartbeatloop.wav");
			//StopSound(client, SNDCHAN_AUTO, "player/heartbeatloop.wav");
		}
		else if (StrEqual(Effects, "r", true)) {

			if (!IsPlayerAlive(client) && b_HasDeathLocation[client] && GetTime() - clientDeathTime[client] < 60) {

				RespawnImmunity[client] = true;
				MyRespawnTarget[client] = -1;
				SDKCall(hRoundRespawn, client);
				CreateTimer(0.1, Timer_TeleportRespawn, client, TIMER_FLAG_NO_MAPCHANGE);
				CreateTimer(0.1, Timer_GiveMaximumHealth, client, TIMER_FLAG_NO_MAPCHANGE);
				CreateTimer(3.0, Timer_ImmunityExpiration, client, TIMER_FLAG_NO_MAPCHANGE);

				int oldrating = GetArrayCell(tempStorage, client, 0);
				int oldhandicap = GetArrayCell(tempStorage, client, 1);
				float oldmultiplier = GetArrayCell(tempStorage, client, 2);
				Rating[client] = oldrating;
				handicapLevel[client] = oldhandicap;
				RoundExperienceMultiplier[client] = oldmultiplier;

				PrintToChatAll("%t", "rise again", white, orange, white);
			}
			else return false;
		}
		else if (StrEqual(Effects, "P", true)) {
			// Toggles between pistol / magnum
			if (MySecondary > 0 && IsValidEntity(MySecondary)) {
				GetEntityClassname(MySecondary, MyWeapon, sizeof(MyWeapon));
				RemovePlayerItem(client, MySecondary);
				AcceptEntityInput(MySecondary, "Kill");
			}
			if (StrContains(MyWeapon, "magnum", false) == -1 && StrContains(MyWeapon, "pistol", false) != -1) {

				// give them a magnum.
				ExecCheatCommand(client, "give", "pistol_magnum");
			}
			else {

				// make them dual wield.
				ExecCheatCommand(client, "give", "pistol");
				CreateTimer(0.5, Timer_GiveSecondPistol, client, TIMER_FLAG_NO_MAPCHANGE);
			}
		}
		else if (StrEqual(Effects, "T", true)) {
			GetClientStance(client, GetAmmoCooldownTime(client, TalentName, true));
		}
	}
	/*if (StrContains(Effects, "S", true) != -1) {
		StaggerPlayer(client, client);
	}*/
	GetArrayString(Values, ABILITY_ACTIVE_EFFECT, Effects, sizeof(Effects));
	if (!StrEqual(Effects, "-1")) {

		//if (AbilityTime > 0.0) IsAbilityActive(client, TalentName, AbilityTime);
		//We check active time another way now

		if (StrEqual(Effects, "A", true)) { // restores stamina

			TheAbilityMultiplier = GetAbilityMultiplier(client, "A", 1);
			int MyStamina = GetPlayerStamina(client);
			MyBonus = RoundToCeil(MyStamina * TheAbilityMultiplier);
			if (SurvivorStamina[client] + MyBonus > MyStamina) {

				SurvivorStamina[client] = MyStamina;
			}
			else SurvivorStamina[client] += MyBonus;
		}
		if (StrEqual(Effects, "H", true)) {	// heals the individual

			TheAbilityMultiplier = GetAbilityMultiplier(client, "H", 1);
			HealPlayer(client, client, TheAbilityMultiplier, 'h');
		}
		if (StrEqual(Effects, "t", true)) {	// instantly lowers threat by a percentage

			TheAbilityMultiplier = GetAbilityMultiplier(client, "t", 1);
			iThreatLevel[client] -= RoundToFloor(iThreatLevel[client] * TheAbilityMultiplier);
		}
	}

	//if (menupos >= 0) CheckActiveAbility(client, menupos, _, _, true, true);
	//AdvertiseAction(client, TalentName, false);
	//IsAmmoActive(client, TalentName, SpellCooldown, true);

	// We do this AFTER we've activated the talent.
	if (GetArrayCell(Values, ABILITY_IS_REACTIVE) == 2) {	// instant, one-time-use abilities that have a cast-bar and then fire immediately.
		if (GetAbilityMultiplier(client, Effects, 5) == -2.0) {
			int reactiveType = GetArrayCell(Values, ABILITY_REACTIVE_TYPE);
			if (reactiveType == 1) L4D_StaggerPlayer(client, GetAnyPlayerNotMe(client), ClientPos);
			else if (reactiveType == 2) {
				float fActiveTime = GetArrayCell(Values, ABILITY_ACTIVE_TIME);
				CreateProgressBar(client, fActiveTime);
				Handle datapack;
				CreateDataTimer(fActiveTime, Timer_ReactiveCast, datapack, TIMER_FLAG_NO_MAPCHANGE);
				WritePackCell(datapack, client);
				WritePackCell(datapack, GetMaximumHealth(client) * (GetArrayCell(Values, ABILITY_ACTIVE_STRENGTH)));
			}
			AdvertiseAction(client, TalentName, false);
			IsAmmoActive(client, TalentName, SpellCooldown, true);
		}
	}
	else {
		AdvertiseAction(client, TalentName, false);
		IsAmmoActive(client, TalentName, SpellCooldown, true);
	}

	return true;
}

public Action Timer_ReactiveCast(Handle timer, Handle datapack) {
	ResetPack(datapack);
	int client = ReadPackCell(datapack);
	if (IsLegitimateClient(client)) {
		int amount = ReadPackCell(datapack);
		CreateFireEx(client);
		DoBurn(client, client, amount);

		// we also do this burn damage to all supers, witches, and specials in range of the fire.
		// because molotov is a set size, trying to match that here.
		float cpos[3];
		GetClientAbsOrigin(client, cpos);
		float tpos[3];
		// specials
		for (int target = 1; target <= MaxClients; target++) {
			if (!IsLegitimateClient(target) || myCurrentTeam[target] != TEAM_INFECTED) continue;
			GetClientAbsOrigin(target, tpos);
			if (GetVectorDistance(cpos, tpos) > 256.0) continue;
			DoBurn(target, client, amount);
		}
		// supers
		int common;
		/*for (new target = 0; target < GetArraySize(CommonInfected); target++) {
			common = GetArrayCell(CommonInfected, target);
			if (!IsSpecialCommon(common)) continue;
			GetEntPropVector(common, Prop_Send, "m_vecOrigin", tpos);
			if (GetVectorDistance(cpos, tpos) > 256.0) continue;
			DoBurn(common, client, amount);
		}*/
		// witches
		for (int target = 0; target < GetArraySize(WitchList); target++) {
			common = GetArrayCell(WitchList, target);
			if (!IsWitch(common)) continue;
			GetEntPropVector(common, Prop_Send, "m_vecOrigin", tpos);
			if (GetVectorDistance(cpos, tpos) > 256.0) continue;
			DoBurn(common, client, amount);
		}
	}
	return Plugin_Stop;
}

stock bool IsActiveAbilityCooldown(client, int menuPos) {
	int size = GetArraySize(a_Menu_Talents);
	if (GetArraySize(PlayerActiveAbilitiesCooldown[client]) != size) {
		ResizeArray(PlayerActiveAbilitiesCooldown[client], size);
		return false;
	}
	if (GetArrayCell(PlayerActiveAbilitiesCooldown[client], menuPos) == 1) return true;
	return false;
}

stock bool IsAbilityCooldown(client, int menuPos) {
	int size = GetArraySize(a_Menu_Talents);
	if (GetArraySize(PlayerAbilitiesCooldown[client]) != size) {
		ResizeArray(PlayerAbilitiesCooldown[client], size);
		return false;
	}
	if (GetArrayCell(PlayerAbilitiesCooldown[client], menuPos) == 1) return true;
	return false;
}