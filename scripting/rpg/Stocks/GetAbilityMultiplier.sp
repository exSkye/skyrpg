// by default this function does not handle instants, so we use an override to force it.
stock float GetAbilityMultiplier(client, char[] abilityT, override = 0, char[] TalentName_t = "none") { // we need the option to force certain results in the menus (1) active (2) passive
	int talentAmount = GetArraySize(a_Menu_Talents);
	if (GetArraySize(ActionBarMenuPos[client]) != iActionBarSlots ||
		GetArraySize(MyTalentStrength[client]) != talentAmount) return -1.0;
	float totalStrength = 0.0;
	bool foundone = false;

	//if (StrEqual(TalentName_t, "none")) Format(abilityT, sizeof(abilityT), "%c", ability);
	char MyTeam[6];
	Format(MyTeam, sizeof(MyTeam), "%d", myCurrentTeam[client]);

	int size = GetArraySize(ActionBar[client]);
	//char allowedWeapons[64];
	//char clientWeapon[64];
	// ClearArray(AbilityMultiplierCalculator[client]);
	// AbilityMultiplierCalculator[client] = CreateArray(16);
	for (int i = 0; i < size; i++) {
		float theStrength = 0.0;
		char TalentName[64];
		GetArrayString(ActionBar[client], i, TalentName, sizeof(TalentName));
		if (StrEqual(TalentName, "none")) continue;
		int pos = GetArrayCell(ActionBarMenuPos[client], i);//GetMenuPosition(client, TalentName);
		if (pos < 0 || pos > talentAmount) continue;
		if (StrEqual(TalentName_t, "none")) {
			if (override == 0 && GetArrayCell(MyTalentStrength[client], pos) <= 0) continue;
			//if (!IsAbilityEquipped(client, TalentName, pos)) continue;
		}
		else if (!StrEqual(TalentName, TalentName_t)) continue;
		AbilityMultiplierCalculator[client]								= GetArrayCell(a_Menu_Talents, pos, 1);
		if (GetArrayCell(AbilityMultiplierCalculator[client], IS_TALENT_ABILITY) != 1) continue;
		int combatStateRequired = GetArrayCell(AbilityMultiplierCalculator[client], COMBAT_STATE_REQ);
		// if no combat state is set, it will return -1, and then work regardless of their combat status.
		if (combatStateRequired == 0 && bIsInCombat[client] ||
			combatStateRequired == 1 && !bIsInCombat[client]) continue;
		// int iWeaponsPermitted = GetArrayCell(GetAbilityArray[client], WEAPONS_PERMITTED);
		// if (iWeaponsPermitted >= 10 && !clientWeaponCategoryIsAllowed(client, iWeaponsPermitted)) continue;
		char activeEffect[10];
		char passiveEffect[10];
		char cooldownEffect[10];
		GetArrayString(AbilityMultiplierCalculator[client], ABILITY_ACTIVE_EFFECT, activeEffect, sizeof(activeEffect));
		GetArrayString(AbilityMultiplierCalculator[client], ABILITY_PASSIVE_EFFECT, passiveEffect, sizeof(passiveEffect));
		GetArrayString(AbilityMultiplierCalculator[client], ABILITY_COOLDOWN_EFFECT, cooldownEffect, sizeof(cooldownEffect));
		bool IsCurrentlyActive = IsAbilityActive(client, TalentName, _, abilityT, pos);
		float fCooldownRemaining = GetAmmoCooldownTime(client, TalentName, true);
		bool abilityIsOnCooldown = (AbilityIsInactiveAndOnCooldown(client, fCooldownRemaining, abilityT, pos)) ? true : false;
		int isReactive = GetArrayCell(AbilityMultiplierCalculator[client], ABILITY_IS_REACTIVE);
		if (isReactive != 1 && override == 5) continue;
		if (isReactive == 1 && override != 5) continue;
		char TheTeams[6];
		GetArrayString(AbilityMultiplierCalculator[client], ABILITY_TEAMS_ALLOWED, TheTeams, sizeof(TheTeams));
		if (!StrEqual(TheTeams, "-1") && StrContains(TheTeams, MyTeam) == -1) continue;
		if (override != -1 && abilityIsOnCooldown) {
			return -1.0;
		}
		bool talentPassiveIsActive = (GetAmmoCooldownTime(client, TalentName) == -1.0) ? true : false;
		//if (override == 0 && GetAmmoCooldownTime(client, TalentName, true) != -1.0 || override == 1) {
		if (override == 4 || !IsCurrentlyActive && abilityIsOnCooldown) {
			float cooldownStr = GetArrayCell(AbilityMultiplierCalculator[client], ABILITY_COOLDOWN_STRENGTH);
			if (cooldownStr > 0.0) theStrength += cooldownStr;
			if (override == 4 || fCooldownRemaining > 0.0 && theStrength > 0.0) {
				if (!StrEqual(abilityT, cooldownEffect)) continue;
			}
		}
		if (override == 3) {
			float fMaximumMultiplier = (!IsCurrentlyActive) ? GetArrayCell(AbilityMultiplierCalculator[client], ABILITY_MAXIMUM_PASSIVE_MULTIPLIER) : GetArrayCell(AbilityMultiplierCalculator[client], ABILITY_MAXIMUM_ACTIVE_MULTIPLIER);
			return fMaximumMultiplier;
		}
		else if (override == 1 || IsCurrentlyActive) {
			if (StrEqual(TalentName_t, "none")) {
				if (!StrEqual(abilityT, activeEffect)) {
					continue;
				}
				int iActiveStateEnsnareReq = GetArrayCell(AbilityMultiplierCalculator[client], ABILITY_ACTIVE_STATE_ENSNARE_REQ);
				if (override != 1 && iActiveStateEnsnareReq == 1 && L4D2_GetInfectedAttacker(client) == -1) continue;
				if (override == 5) {
					// this only happens if the requirements to trigger are met (and cannot trigger if they've been met before.)
					if (!SetActiveAbilityConditionsMet(client, pos, true)) {
						SetActiveAbilityConditionsMet(client, pos);
						return -2.0;	// this is how we know that reactive abilities are active (and can thus trigger)
					}
					else {
						return -3.0;	// this is the return if the reactive effect has already triggered (reactive can only trigger once during their active period.)
					}
				}
			}
			AbilityMultiplierCalculator[client]								= GetArrayCell(a_Menu_Talents, pos, 1);
			float fAbilityActiveStr = GetArrayCell(AbilityMultiplierCalculator[client], ABILITY_ACTIVE_STRENGTH);
			if (fAbilityActiveStr > 0.0) theStrength += fAbilityActiveStr;
		}
		else if (override == 2 || talentPassiveIsActive || GetArrayCell(AbilityMultiplierCalculator[client], ABILITY_PASSIVE_IGNORES_COOLDOWN) == 1) {
			if (StrEqual(TalentName_t, "none")) {
				if (!StrEqual(abilityT, passiveEffect)) continue;
				int iPassiveStateEnsnareReq = GetArrayCell(AbilityMultiplierCalculator[client], ABILITY_PASSIVE_STATE_ENSNARE_REQ);
				if (override != 2 && iPassiveStateEnsnareReq == 1 && L4D2_GetInfectedAttacker(client) == -1) continue;
			}
			float passiveStr = GetArrayCell(AbilityMultiplierCalculator[client], ABILITY_PASSIVE_STRENGTH);
			if (passiveStr > 0.0) theStrength += passiveStr;
		}
		else continue;	// If it's not active, or it's on cooldown, we ignore its value.
		if (override == 4) {
			totalStrength += ((1.0 - totalStrength) * theStrength);
		} 
		else totalStrength += theStrength;
		foundone = true;
	}
	if (!foundone) totalStrength = -1.0;
	return totalStrength;
}