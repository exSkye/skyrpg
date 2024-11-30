stock VerifyAllActionBars(client) {

	if (!IsLegitimateClient(client)) return;
	int ActionSlots = iActionBarSlots;
	if (GetArraySize(ActionBar[client]) != ActionSlots) ResizeArray(ActionBar[client], ActionSlots);
	if (GetArraySize(ActionBarMenuPos[client]) != iActionBarSlots) ResizeArray(ActionBarMenuPos[client], iActionBarSlots);

	// If the user doesn't meet the requirements or have the item it'll be unequipped here

	char talentname[64];

	int size = iActionBarSlots;
	for (int i = 0; i < size; i++) {
		GetArrayString(ActionBar[client], i, talentname, sizeof(talentname));
		int menuPos = GetArrayCell(ActionBarMenuPos[client], i);
		VerifyActionBar(client, talentname, i, menuPos);
	}
}

stock ShowActionBar(client) {

	Handle menu = CreateMenu(ActionBarHandle);

	char text[128];
	char talentname[64];
	char staminabar[64];
	int maxstam = GetPlayerStamina(client);
	MenuExperienceBar(client, SurvivorStamina[client], maxstam, staminabar, 64);
	Format(text, sizeof(text), "stamina: %d%s%d", SurvivorStamina[client], staminabar, maxstam);
	static char baseWeaponDamageText[64];
	//decl String:lastBaseDamageText[64];
	if (iShowDamageOnActionBar == 1) {
		int baseWeaponDamage = DataScreenWeaponDamage(client);	// expensive way
		if (baseWeaponDamage > 0) {
			AddCommasToString(baseWeaponDamage, baseWeaponDamageText, sizeof(baseWeaponDamageText));
		//AddCommasToString(lastBaseDamage[client], baseWeaponDamageText, sizeof(baseWeaponDamageText));
			Format(text, sizeof(text), "%s\nDamage: %s", text, baseWeaponDamageText);
		}
		int healDamage = DataScreenWeaponDamage(client, true);
		if (healDamage > 0) {
			AddCommasToString(healDamage, baseWeaponDamageText, sizeof(baseWeaponDamageText));
		//AddCommasToString(lastBaseDamage[client], baseWeaponDamageText, sizeof(baseWeaponDamageText));
			Format(text, sizeof(text), "%s\nHeal: %s", text, baseWeaponDamageText);
		}
	}
	Format(text, sizeof(text), "%s\nsame target Hits: %d", text, ConsecutiveHits[client]);
	SetMenuTitle(menu, text);
	int size = iActionBarSlots;
	float AmmoCooldownTime = -1.0, fAmmoCooldownTime = -1.0, fAmmoCooldown = 0.0, fAmmoActive = 0.0;

	for (int i = 0; i < size; i++) {
		GetArrayString(ActionBar[client], i, talentname, sizeof(talentname));
		int menuPos = GetArrayCell(ActionBarMenuPos[client], i);
		int TalentStrength = GetTalentStrength(client, _, _, menuPos);
		if (TalentStrength < 1) {
			Format(text, sizeof(text), "%T", "No Action Equipped", client);
			Format(text, sizeof(text), "!%s%d:\t%s", acmd, i+1, text);
			AddMenuItem(menu, text, text);
			continue;
		}
		GetTranslationOfTalentName(client, talentname, text, sizeof(text), _, true);
		Format(text, sizeof(text), "%T", text, client);
		Format(text, sizeof(text), "!%s%d:\t%s", acmd, i+1, text);
		bool bIsAbility = IsAbilityTalent(client, menuPos);
		// spells
		int talentMenuPos = GetArrayCell(ActionBarMenuPos[client], i);
		if (!bIsAbility) {
			int ManaCost = RoundToCeil(GetSpecialAmmoStrength(client, talentname, 2, _, _, talentMenuPos));
			if (ManaCost > 0) Format(text, sizeof(text), "%s\nStamina Cost: %d", text, ManaCost);

			fAmmoCooldownTime = GetAmmoCooldownTime(client, talentname);
			AmmoCooldownTime = GetSpecialAmmoStrength(client, talentname, _, _, _, talentMenuPos);
			if (fAmmoCooldownTime != -1.0) {
				// finding out the active time of ammos isn't as easy because of design...
				fAmmoCooldown = AmmoCooldownTime + GetSpecialAmmoStrength(client, talentname, 1, _, _, talentMenuPos);
				AmmoCooldownTime = AmmoCooldownTime - (fAmmoCooldown - fAmmoCooldownTime);
			}
		}	// abilities
		else {
			AmmoCooldownTime = GetAmmoCooldownTime(client, talentname, true);
			fAmmoCooldownTime = AmmoCooldownTime;

			// abilities dont show active time correctly (NOT FIXED)
			fAmmoActive = GetAbilityValue(client, ABILITY_ACTIVE_TIME, talentMenuPos);
			if (fAmmoCooldownTime != -1.0) {

				fAmmoCooldown = GetSpellCooldown(client, _, talentMenuPos);
				AmmoCooldownTime = fAmmoActive - (fAmmoCooldown - fAmmoCooldownTime);
			}
		}
		if (bIsAbility && AmmoCooldownTime != -1.0 && AmmoCooldownTime > 0.0 ||
			!bIsAbility && (AmmoCooldownTime > 0.0 || AmmoCooldownTime == -1.0)) Format(text, sizeof(text), "%s\nActive: %ds", text, RoundToNearest(AmmoCooldownTime));

		AmmoCooldownTime = fAmmoCooldownTime;
		if (AmmoCooldownTime != -1.0) Format(text, sizeof(text), "%s\nCooldown: %ds", text, RoundToNearest(AmmoCooldownTime));
		AddMenuItem(menu, text, text);
	}
	SetMenuExitBackButton(menu, false);
	DisplayMenu(menu, client, 0);
}

stock bool AbilityDoesDamage(client, char[] TalentName) {

	char theQuery[64];
	int menuPos = GetMenuPosition(client, TalentName);
	//Format(theQuery, sizeof(theQuery), "does damage?");
	IsAbilityTalent(client, menuPos, theQuery, 64, ABILITY_DOES_DAMAGE);

	if (StringToInt(theQuery) == 1) return true;
	return false;
}

stock bool VerifyActionBar(client, char[] TalentName, int pos, int menuPos) {
	//if (defaultTalentStrength == -1) defaultTalentStrength = GetTalentStrength(client, TalentName);
	if (StrEqual(TalentName, "none", false)) return false;
	if (!IsTalentExists(TalentName) || GetTalentStrength(client, TalentName, _, menuPos) < 1) {
		if (GetArraySize(ActionBarMenuPos[client]) != iActionBarSlots) ResizeArray(ActionBarMenuPos[client], iActionBarSlots);
		char none[64];
		Format(none, sizeof(none), "none");
		SetArrayString(ActionBar[client], pos, none);
		SetArrayCell(ActionBarMenuPos[client], pos, -1);
		return false;
	}
	return true;
}

stock bool IsAbilityTalent(client, int menuPos, char[] SearchKey = "none", TheSize = 0, pos = -1) {	// Can override the search query, and then said string will be replaced and sent back
	IsAbilityValues[client]			= GetArrayCell(a_Menu_Talents, menuPos, 1);
	if (pos == -1 || pos == IS_TALENT_ABILITY) {
		if (GetArrayCell(IsAbilityValues[client], IS_TALENT_ABILITY) == 1) return true;
		return false;
	}
	GetArrayString(IsAbilityValues[client], pos, SearchKey, TheSize);
	return false;
}
// Delay can be set to a default value because it is only used for overloading.
stock DrawAbilityEffect(client, int menuPos, iEffectType = 0) {
	// no longer needed because we check for it before we get here.if (StrEqual(sDrawEffect, "-1")) return;							//size					color		pos		   pulse?  lifetime
	//CreateRingEx(client, fDrawSize, sDrawEffect, fDrawHeight, false, 0.2);
	if (iEffectType == 1) CreateRingEffectType1(client, menuPos, false, 0.2);
	else if (iEffectType == 2) CreateRingEffectType2(client, menuPos, false, 0.2);
	else {
		Handle drawpack;
		float fDrawDelay = GetArrayCell(TalentInstantDelays, menuPos);
		CreateDataTimer(fDrawDelay, Timer_DrawInstantEffect, drawpack, TIMER_FLAG_NO_MAPCHANGE);
		WritePackCell(drawpack, client);
		WritePackCell(drawpack, menuPos);
	}
}

public Action Timer_DrawInstantEffect(Handle timer, Handle drawpack) {
	ResetPack(drawpack);
	int client				=	ReadPackCell(drawpack);

	if (IsLegitimateClient(client) && IsPlayerAlive(client)) {
		int menuPos = ReadPackCell(drawpack);
		CreateRingEffectType0(client, menuPos, false, 0.2);
	}

	return Plugin_Stop;
}

stock bool IsActionAbilityCooldown(client, char[] TalentName, bool IsActiveInstead = false, int pos) {

	float AmmoCooldownTime = GetAmmoCooldownTime(client, TalentName, true);
	float fAmmoCooldownTime = AmmoCooldownTime;
	float fAmmoCooldown = 0.0;

	// abilities dont show active time correctly (NOT FIXED)
	float fAmmoActive = GetAbilityValue(client, ABILITY_ACTIVE_TIME, pos);
	if (fAmmoCooldownTime != -1.0) {

		fAmmoCooldown = GetSpellCooldown(client, _, pos);
		AmmoCooldownTime = fAmmoActive - (fAmmoCooldown - fAmmoCooldownTime);//copy to source
	}
	if (!IsActiveInstead) {

		if (AmmoCooldownTime != -1.0) return true;
	}
	else {

		if (AmmoCooldownTime != -1.0 && AmmoCooldownTime > 0.0) return true;
	}
	
	return false;
}

stock float CheckActiveAbility(client, thevalue, eventtype = 0, bool IsPassive = false, bool IsDrawEffect = false, bool IsInstantDraw = false) {

	// we try to match up the eventtype with any ACTIVE talents on the action bar.
	// it is REALLY super simple, we have functions for everything. everythingggggg
	// get the size of the action bars first.
	//LAMEO
	//if (IsSurvivorBot(client) && !IsDrawEffect) return 0.0;
	int ActionBarSize = iActionBarSlots;	// having your own extensive api really helps.
	if (GetArraySize(ActionBar[client]) != ActionBarSize) ResizeArray(ActionBar[client], ActionBarSize);
	if (GetArraySize(ActionBarMenuPos[client]) != iActionBarSlots) ResizeArray(ActionBarMenuPos[client], iActionBarSlots);
	char text[64];// free guesses on what this one is for.
	char none[64];
	Format(none, sizeof(none), "none");	// you guessed it.
	//int pos = -1;
	float MyMultiplier = 1.0;
	//new MyAttacker = L4D2_GetInfectedAttacker(client);
	int size = GetArraySize(ActionBar[client]);
	//new Float:fAbilityTime = 0.0;

	int IsPassiveAbility = 0;
	int abPos = -1;
	float visualsCooldown = 0.0;
	PassiveEffectDisplay[client]++;
	if (PassiveEffectDisplay[client] >= size ||
		PassiveEffectDisplay[client] < 0) PassiveEffectDisplay[client] = 0;

	for (int i = 0; i < size; i++) {
		if (IsInstantDraw && thevalue != i) continue;
		GetArrayString(ActionBar[client], i, text, sizeof(text));
		//if (StrEqual(text, "none", false) || GetTalentStrength(client, text) < 1) continue;
		int pos = GetArrayCell(ActionBarMenuPos[client], i);
		if (!VerifyActionBar(client, text, i, pos)) continue;	// not a real talent or has no points in it.
		if (!IsAbilityActive(client, text, _, _, pos) && !IsDrawEffect) continue;	// inactive / passive / toggle abilities go through to the draw section.
		//pos = GetMenuPosition(client, text);
		if (pos < 0) continue;
		CheckAbilityKeys[client]		= GetArrayCell(a_Menu_Talents, pos, 0);
		CheckAbilityValues[client]		= GetArrayCell(a_Menu_Talents, pos, 1);
		
		if (IsDrawEffect) {
			if (GetArrayCell(CheckAbilityValues[client], IS_TALENT_ABILITY) == 1) {
				IsPassiveAbility = GetArrayCell(CheckAbilityValues[client], ABILITY_PASSIVE_ONLY);
				if (IsInstantDraw) DrawAbilityEffect(client, pos);
				else {
					abPos = GetAbilityDataPosition(client, pos);
					if (abPos == -1) continue;
					visualsCooldown = GetArrayCell(PlayActiveAbilities[client], abPos, 3);
					visualsCooldown -= fSpecialAmmoInterval;
					if (visualsCooldown > 0.0) {
						SetArrayCell(PlayActiveAbilities[client], abPos, visualsCooldown, 3);
						continue;	// do not draw if visuals are on cooldown
					}
					if (IsActionAbilityCooldown(client, text, true, pos)) {// || !StrEqual(sPassiveEffects, "-1.0") && !IsActionAbilityCooldown(client, text)) {
						SetArrayCell(PlayActiveAbilities[client], abPos, GetArrayCell(CheckAbilityValues[client], ABILITY_ACTIVE_DRAW_DELAY), 3);
						DrawAbilityEffect(client, pos, 1);
					}
					else if (PassiveEffectDisplay[client] == i && IsPassiveAbility == 1) {
						SetArrayCell(PlayActiveAbilities[client], abPos, GetArrayCell(CheckAbilityValues[client], ABILITY_PASSIVE_DRAW_DELAY), 3);
						DrawAbilityEffect(client, pos, 2);
					}
				}
			}
			continue;
		}
		//if (GetArrayCell(CheckAbilityValues[client], ABILITY_EVENT_TYPE) != eventtype) continue;
		
		// if (!IsPassive) {
		// 	GetArrayString(CheckAbilityValues[client], ABILITY_ACTIVE_EFFECT, Effects, sizeof(Effects));
		// }
		// else {
		// 	GetArrayString(CheckAbilityValues[client], ABILITY_PASSIVE_EFFECT, Effects, sizeof(Effects));
		// }

	}
	if (MyMultiplier <= 0.0) return 0.0;
	return (MyMultiplier * thevalue);
}

public ActionBarHandle(Handle menu, MenuAction action, client, slot) {

	if (action == MenuAction_Select) {
		CastActionEx(client, _, -1, slot);
	}
	else if (action == MenuAction_Cancel) {

		if (slot != MenuCancel_ExitBack) {
		}
		//DisplayActionBar[client] = false;
	}
	if (action == MenuAction_End) {

		//DisplayActionBar[client] = false;
		CloseHandle(menu);
	}
}

stock GetAbilityText(client, char[] TheString, TheSize, Handle Keys, Handle Values, pos = ABILITY_ACTIVE_EFFECT) {
	char text[512];
	char text2[512];
	char tDraft[512];
	char AbilityType[64];
	float TheAbilityMultiplier = 0.0;
	char pct[4];
	Format(pct, sizeof(pct), "%");
	GetArrayString(Values, pos, text, sizeof(text));
	if (StrEqual(text, "-1")) {

		Format(TheString, TheSize, "-1");
		return;
	}
	float maxMultiplier = -1.0;

	if (pos == ABILITY_ACTIVE_EFFECT) {

		Format(tDraft, sizeof(tDraft), "%T", "Active Effects", client);
		Format(AbilityType, sizeof(AbilityType), "Active Ability");
		TheAbilityMultiplier = GetArrayCell(Values, ABILITY_ACTIVE_STRENGTH);
		maxMultiplier = GetArrayCell(Values, ABILITY_MAXIMUM_ACTIVE_MULTIPLIER);//GetArrayString(Values, ABILITY_MAXIMUM_ACTIVE_MULTIPLIER, TheMaximumMultiplier, sizeof(TheMaximumMultiplier));
	}
	else if (pos == ABILITY_PASSIVE_EFFECT) {

		Format(tDraft, sizeof(tDraft), "%T", "Passive Effects", client);
		Format(AbilityType, sizeof(AbilityType), "Passive Ability");
		TheAbilityMultiplier = GetArrayCell(Values, ABILITY_PASSIVE_STRENGTH);
		maxMultiplier = GetArrayCell(Values, ABILITY_MAXIMUM_PASSIVE_MULTIPLIER);//GetArrayString(Values, ABILITY_MAXIMUM_PASSIVE_MULTIPLIER, TheMaximumMultiplier, sizeof(TheMaximumMultiplier));
	}
	else if (pos == ABILITY_COOLDOWN_EFFECT) {

		Format(tDraft, sizeof(tDraft), "%T", "Cooldown Effects", client);
		Format(AbilityType, sizeof(AbilityType), "Cooldown Ability");
		TheAbilityMultiplier = GetArrayCell(Values, ABILITY_COOLDOWN_STRENGTH);
	}
	else {

		Format(tDraft, sizeof(tDraft), "%T", "Toggle Effects", client);
		Format(AbilityType, sizeof(AbilityType), "Toggle Ability");
		TheAbilityMultiplier = GetArrayCell(Values, ABILITY_TOGGLE_STRENGTH);
	}
	Format(text2, sizeof(text2), "%s %s", text, AbilityType);
	int isReactive = GetArrayCell(Values, ABILITY_IS_REACTIVE);
	if (isReactive == 1) {
		Format(text2, sizeof(text2), "%T", text2, client);
	}
	else {
		if (StrEqual(text, "C", true)) {
			Format(text2, sizeof(text2), "%T", text2, client, TheAbilityMultiplier * 100.0, pct, maxMultiplier * 100.0, pct);
		}
		else if (TheAbilityMultiplier > 0.0 || StrEqual(text, "S", true)) {

			Format(text2, sizeof(text2), "%T", text2, client, TheAbilityMultiplier * 100.0, pct);
		}
		else {

			Format(text2, sizeof(text2), "%s Disabled", text);
			Format(text2, sizeof(text2), "%T", text2, client);
		}
	}
	Format(tDraft, sizeof(tDraft), "%s %s", tDraft, text2);
	if (pos == ABILITY_ACTIVE_EFFECT) {
		float fActiveTime = GetArrayCell(Values, ABILITY_ACTIVE_TIME);
		if (fActiveTime > 0.0) {
			Format(text2, sizeof(text2), "%T", "Ability Active Time", client, fActiveTime);
			Format(TheString, TheSize, "%s\n%s", text2, tDraft);
		}
		else Format(TheString, TheSize, "%s", tDraft);
	}
	else if (pos == ABILITY_COOLDOWN_EFFECT) {
		float fAbilityCooldown = GetArrayCell(Values, ABILITY_COOLDOWN);

		TheAbilityMultiplier = GetAbilityMultiplier(client, "L");
		if (TheAbilityMultiplier > 0.0) { //cooldowns are reduced
			fAbilityCooldown -= (fAbilityCooldown * TheAbilityMultiplier);
		}
		if (fAbilityCooldown > 0.0) Format(text2, sizeof(text2), "%T", "Ability Cooldown", client, fAbilityCooldown);
		else Format(text2, sizeof(text2), "%T", "No Ability Cooldown", client);

		Format(TheString, TheSize, "%s\n%s", text2, tDraft);
	}
	else Format(TheString, TheSize, "%s", tDraft);
}