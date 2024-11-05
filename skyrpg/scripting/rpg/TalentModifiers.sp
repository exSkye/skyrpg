stock float GetTalentModifier(int client, int modifierType = MODIFIER_HEALING) {
	float talentModifier = 1.0;
	if (modifierType == MODIFIER_HEALING) {
		float healingBonus = GetAbilityStrengthByTrigger(client, _, TRIGGER_lessDamageMoreHeals, _, 0, _, _, _, 2, true, _, _, _, _, 1);
		healingBonus += GetAbilityStrengthByTrigger(client, _, TRIGGER_lessTankyMoreHeals, _, 0, _, _, _, 2, true, _, _, _, _, 1);

		float healingPenalty = GetAbilityStrengthByTrigger(client, _, TRIGGER_lessHealsMoreDamage, _, 0, _, _, _, 2, true, _, _, _, _, 1);
		healingPenalty += GetAbilityStrengthByTrigger(client, _, TRIGGER_lessHealsMoreTanky, _, 0, _, _, _, 2, true, _, _, _, _, 1);

		talentModifier += healingBonus;
		talentModifier -= healingPenalty;
	}
	else if (modifierType == MODIFIER_TANKING) {
		float tankyBonus = GetAbilityStrengthByTrigger(client, _, TRIGGER_lessDamageMoreTanky, _, 0, _, _, _, 2, true, _, _, _, _, 1);
		tankyBonus += GetAbilityStrengthByTrigger(client, _, TRIGGER_lessHealsMoreTanky, _, 0, _, _, _, 2, true, _, _, _, _, 1);

		float tankyPenalty = GetAbilityStrengthByTrigger(client, _, TRIGGER_lessTankyMoreHeals, _, 0, _, _, _, 2, true, _, _, _, _, 1);
		tankyPenalty += GetAbilityStrengthByTrigger(client, _, TRIGGER_lessTankyMoreDamage, _, 0, _, _, _, 2, true, _, _, _, _, 1);

		talentModifier += tankyBonus;
		talentModifier -= tankyPenalty;
	}
	else if (modifierType == MODIFIER_DAMAGE) {	// MODIFIER_DAMAGE
		float damageBonus = GetAbilityStrengthByTrigger(client, _, TRIGGER_lessTankyMoreDamage, _, 0, _, _, _, 2, true, _, _, _, _, 1);
		damageBonus += GetAbilityStrengthByTrigger(client, _, TRIGGER_lessHealsMoreDamage, _, 0, _, _, _, 2, true, _, _, _, _, 1);

		float damagePenalty = GetAbilityStrengthByTrigger(client, _, TRIGGER_lessDamageMoreHeals, _, 0, _, _, _, 2, true, _, _, _, _, 1);
		damagePenalty += GetAbilityStrengthByTrigger(client, _, TRIGGER_lessDamageMoreTanky, _, 0, _, _, _, 2, true, _, _, _, _, 1);

		talentModifier += damageBonus;
		talentModifier -= damagePenalty;
	}
	if (talentModifier < 0.1) return 0.1;
	return talentModifier;
}

stock float GetTalentInfo(client, Handle Values, infotype = 0, bool bIsNext = false, char[] pTalentNameOverride = "none", target = 0, iStrengthOverride = 0, bool skipGettingValues = false) {
	float f_Strength	= 0.0;
	char TalentNameOverride[64];
	if (StrEqual(pTalentNameOverride, "none")) Format(TalentNameOverride, sizeof(TalentNameOverride), "%s", PurchaseTalentName[client]);
	else Format(TalentNameOverride, sizeof(TalentNameOverride), "%s", pTalentNameOverride);

	if (iStrengthOverride > 0) f_Strength = iStrengthOverride * 1.0;
	else f_Strength	=	GetTalentStrength(client, TalentNameOverride) * 1.0;
	if (bIsNext) f_Strength++;
	if (f_Strength <= 0.0) return 0.0;
	if (target == 0 || !IsLegitimateClient(target)) target = client;
	/*
		Server operators can make up their own custom attributes, and make them affect any node they want.
		This key "governing attribute?" lets me know what attribute multiplier to collect.
		If you don't want a node governed by an attribute, omit the field.
	*/
	if (!skipGettingValues) {
		Values = GetArrayCell(a_Menu_Talents, GetMenuPosition(client, TalentNameOverride), 1);
	}

	//we want to add support for a "type" of talent.
	char sTalentStrengthType[64];
	if (infotype == 0 || infotype == 1) GetArrayString(Values, TALENT_UPGRADE_STRENGTH_VALUE, sTalentStrengthType, sizeof(sTalentStrengthType));
	else if (infotype == 3) GetArrayString(Values, TALENT_COOLDOWN_STRENGTH_VALUE, sTalentStrengthType, sizeof(sTalentStrengthType));
	int istrength = RoundToCeil(f_Strength);
	float f_StrengthIncrement = (infotype == 2) ? GetArrayCell(Values, TALENT_ACTIVE_STRENGTH_VALUE) : (StrContains(sTalentStrengthType, ".") == -1) ? StringToInt(sTalentStrengthType) * 1.0 : StringToFloat(sTalentStrengthType);
	if (istrength < 1 || infotype == 3 && f_StrengthIncrement <= 0.0) return 0.0;

	int talentCategoryType = GetArrayCell(Values, ABILITY_CATEGORY);
	if (talentCategoryType == 0) {
		f_StrengthIncrement = (f_StrengthIncrement * GetTalentModifier(client, MODIFIER_HEALING));
	}
	else if (talentCategoryType == 1) {
		f_StrengthIncrement = (f_StrengthIncrement * GetTalentModifier(client, MODIFIER_DAMAGE));
	}
	else if (talentCategoryType == 2) {
		f_StrengthIncrement = (f_StrengthIncrement * GetTalentModifier(client, MODIFIER_TANKING));
	}

	float f_StrengthPoint = f_StrengthIncrement;
	if (infotype != 3) {
		char text[64];
		GetArrayString(Values, GOVERNING_ATTRIBUTE, text, sizeof(text));
		float governingAttributeMultiplier = 0.0;
		if (!StrEqual(text, "-1")) {
			governingAttributeMultiplier = GetAttributeMultiplier(client, text);
			if (governingAttributeMultiplier > 0.0) {
				f_StrengthPoint += (f_StrengthPoint * governingAttributeMultiplier);
			}
		}
	}

	char activatorEffects[64];
	GetArrayString(Values, ACTIVATOR_ABILITY_EFFECTS, activatorEffects, 64);
	char targetEffects[64];
	GetArrayString(Values, TARGET_ABILITY_EFFECTS, targetEffects, 64);

	int skipAugmentModifiers = GetArrayCell(Values, TALENT_NO_AUGMENT_MODIFIERS);
	if (iAugmentsAffectCooldowns == 1 && skipAugmentModifiers != 1) {
		float fCategoryAugmentBuff = GetCategoryAugmentBuff(client, TalentNameOverride, f_StrengthPoint);
		if (infotype == 3) fCategoryAugmentBuff *= fAugmentCooldownIncrease;
		float fCategoryTalentBuff = GetCategoryTalentBuff(client, activatorEffects, targetEffects);
		if (fCategoryAugmentBuff > 0.0) f_StrengthPoint += (f_StrengthIncrement * fCategoryAugmentBuff);
		if (fCategoryTalentBuff > 0.0) f_StrengthPoint += (f_StrengthIncrement * fCategoryTalentBuff);
	}
	if (infotype == 3) {
		char sCooldownGovernor[64];
		float cdReduction = 0.0;
		int acdReduction = GetArraySize(a_Menu_Talents);
		for (int i = 0; i < acdReduction; i++) {
			int TheTalentStrength = GetArrayCell(MyTalentStrength[client], i);
			if (TheTalentStrength < 1) continue;
			acdrValues[client] = GetArrayCell(a_Menu_Talents, i, 1);
			GetArrayString(acdrValues[client], COOLDOWN_GOVERNOR_OF_TALENT, sCooldownGovernor, sizeof(sCooldownGovernor));
			if (!FoundCooldownReduction(TalentNameOverride, sCooldownGovernor)) continue;

			//acdrSection[client] = GetArrayCell(a_Menu_Talents, i, 2);
			GetArrayString(a_Database_Talents, i, sCooldownGovernor, sizeof(sCooldownGovernor));
			cdReduction += GetTalentInfo(client, acdrValues[client], _, _, sCooldownGovernor);
		}
		//if (governingAttributeMultiplier > 0.0) cdReduction += governingAttributeMultiplier;
		if (cdReduction > 0.0) f_StrengthPoint -= (f_StrengthPoint * cdReduction);
		float fMinimumCooldown = GetArrayCell(Values, TALENT_MINIMUM_COOLDOWN_TIME);
		float fStartingCooldown = GetArrayCell(Values, TALENT_COOLDOWN_STRENGTH_VALUE);
		if (fMinimumCooldown < 0.0) fMinimumCooldown = fStartingCooldown;
		if (f_StrengthPoint < fMinimumCooldown) f_StrengthPoint = fMinimumCooldown;	// can't have cooldowns that are less than 0.0 seconds.
	}

	return f_StrengthPoint;
}