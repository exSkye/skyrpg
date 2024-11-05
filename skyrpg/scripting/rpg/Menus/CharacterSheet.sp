public CharacterSheetMenuHandle(Handle menu, MenuAction action, client, slot) {

	if (action == MenuAction_Select) {
		if (slot == 0) {
			playerPageOfCharacterSheet[client] = (playerPageOfCharacterSheet[client] == 0) ? 1 : 0;
			CharacterSheetMenu(client);
		}
	}
	if (action == MenuAction_Cancel) {

		if (slot == MenuCancel_ExitBack) {

			BuildMenu(client);
		}
	}
	if (action == MenuAction_End) {

		CloseHandle(menu);
	}
}

public void CharacterSheetMenu(client) {
	Handle menu		= CreateMenu(CharacterSheetMenuHandle);

	char text[512];
	// we create a string called data to use as reference in GetCharacterSheetData()
	// as opposed to using a String method that has to create a new string each time.
	char data[64];
	// parse the menu according to how the server operator has designed it.
	
	if (playerPageOfCharacterSheet[client] == 0) {
		Format(text, sizeof(text), "%T", "Infected Sheet Info", client);

		if (StrContains(text, "{CH}", true) != -1) {
			GetCharacterSheetData(client, data, sizeof(data), 1);
			ReplaceString(text, sizeof(text), "{CH}", data);
		}
		if (StrContains(text, "{CD}", true) != -1) {
			GetCharacterSheetData(client, data, sizeof(data), 2);
			ReplaceString(text, sizeof(text), "{CD}", data);
		}
		if (StrContains(text, "{WH}", true) != -1) {
			GetCharacterSheetData(client, data, sizeof(data), 3);
			ReplaceString(text, sizeof(text), "{WH}", data);
		}
		if (StrContains(text, "{WD}", true) != -1) {
			GetCharacterSheetData(client, data, sizeof(data), 4);
			ReplaceString(text, sizeof(text), "{WD}", data);
		}
		if (StrContains(text, "{HUNTERHP}", true) != -1) {
			GetCharacterSheetData(client, data, sizeof(data), 5, ZOMBIECLASS_HUNTER);
			ReplaceString(text, sizeof(text), "{HUNTERHP}", data);
		}
		if (StrContains(text, "{SMOKERHP}", true) != -1) {
			GetCharacterSheetData(client, data, sizeof(data), 5, ZOMBIECLASS_SMOKER);
			ReplaceString(text, sizeof(text), "{SMOKERHP}", data);
		}
		if (StrContains(text, "{BOOMERHP}", true) != -1) {
			GetCharacterSheetData(client, data, sizeof(data), 5, ZOMBIECLASS_BOOMER);
			ReplaceString(text, sizeof(text), "{BOOMERHP}", data);
		}
		if (StrContains(text, "{SPITTERHP}", true) != -1) {
			GetCharacterSheetData(client, data, sizeof(data), 5, ZOMBIECLASS_SPITTER);
			ReplaceString(text, sizeof(text), "{SPITTERHP}", data);
		}
		if (StrContains(text, "{JOCKEYHP}", true) != -1) {
			GetCharacterSheetData(client, data, sizeof(data), 5, ZOMBIECLASS_JOCKEY);
			ReplaceString(text, sizeof(text), "{JOCKEYHP}", data);
		}
		if (StrContains(text, "{CHARGERHP}", true) != -1) {
			GetCharacterSheetData(client, data, sizeof(data), 5, ZOMBIECLASS_CHARGER);
			ReplaceString(text, sizeof(text), "{CHARGERHP}", data);
		}
		if (StrContains(text, "{TANKHP}", true) != -1) {
			GetCharacterSheetData(client, data, sizeof(data), 5, ZOMBIECLASS_TANK);
			ReplaceString(text, sizeof(text), "{TANKHP}", data);
		}
		if (StrContains(text, "{HUNTERDMG}", true) != -1) {
			GetCharacterSheetData(client, data, sizeof(data), 6, ZOMBIECLASS_HUNTER);
			ReplaceString(text, sizeof(text), "{HUNTERDMG}", data);
		}
		if (StrContains(text, "{SMOKERDMG}", true) != -1) {
			GetCharacterSheetData(client, data, sizeof(data), 6, ZOMBIECLASS_SMOKER);
			ReplaceString(text, sizeof(text), "{SMOKERDMG}", data);
		}
		if (StrContains(text, "{BOOMERDMG}", true) != -1) {
			GetCharacterSheetData(client, data, sizeof(data), 6, ZOMBIECLASS_BOOMER);
			ReplaceString(text, sizeof(text), "{BOOMERDMG}", data);
		}
		if (StrContains(text, "{SPITTERDMG}", true) != -1) {
			GetCharacterSheetData(client, data, sizeof(data), 6, ZOMBIECLASS_SPITTER);
			ReplaceString(text, sizeof(text), "{SPITTERDMG}", data);
		}
		if (StrContains(text, "{JOCKEYDMG}", true) != -1) {
			GetCharacterSheetData(client, data, sizeof(data), 6, ZOMBIECLASS_JOCKEY);
			ReplaceString(text, sizeof(text), "{JOCKEYDMG}", data);
		}
		if (StrContains(text, "{CHARGERDMG}", true) != -1) {
			GetCharacterSheetData(client, data, sizeof(data), 6, ZOMBIECLASS_CHARGER);
			ReplaceString(text, sizeof(text), "{CHARGERDMG}", data);
		}
		if (StrContains(text, "{TANKDMG}", true) != -1) {
			GetCharacterSheetData(client, data, sizeof(data), 6, ZOMBIECLASS_TANK);
			ReplaceString(text, sizeof(text), "{TANKDMG}", data);
		}
	}
	else { // Survivor Sheet!
		char targetName[64];
		float TargetPos[3];
		char hitgroup[4];
		int target = GetAimTargetPosition(client, TargetPos, hitgroup, 4);
		if (target == -1) {
			target = FindAnotherSurvivor(client);
			if (target == -1) target = client;
		}
		//int typeOfAimTarget = DataScreenTargetName(client, targetName, sizeof(targetName));
		char weaponDamage[64];
		char otherText[64];
		char pct[4];
		Format(pct, sizeof(pct), "%");
		int currentWeaponDamage = DataScreenWeaponDamage(client);
		AddCommasToString(currentWeaponDamage, weaponDamage, sizeof(weaponDamage));
		Format(weaponDamage, sizeof(weaponDamage), "%s", weaponDamage);
		//int infected = FindInfectedClient(true);

		Format(text, sizeof(text), "%T", "Survivor Sheet Info", client, pct);
		if (StrContains(text, "{AUGAVGLVL}", true) != -1) {
			Format(otherText, sizeof(otherText), "%d", playerCurrentAugmentAverageLevel);
			ReplaceString(text, sizeof(text), "{AUGAVGLVL}", otherText);
		}
		if (StrContains(text, "{PLAYTIME}", true) != -1) {
			GetTimePlayed(client, otherText, sizeof(otherText));
			ReplaceString(text, sizeof(text), "{PLAYTIME}", otherText);
		}
		if (StrContains(text, "{AIMTARGET}", true) != -1) {
			ReplaceString(text, sizeof(text), "{AIMTARGET}", targetName);
		}
		if (StrContains(text, "{WDMG}", true) != -1) {
			ReplaceString(text, sizeof(text), "{WDMG}", weaponDamage);
		}
		if (StrContains(text, "{MYSTAM}", true) != -1) {
			Format(weaponDamage, sizeof(weaponDamage), "%d", GetPlayerStamina(client));
			ReplaceString(text, sizeof(text), "{MYSTAM}", weaponDamage);
		}
		if (StrContains(text, "{MYHP}", true) != -1) {
			SetMaximumHealth(client);
			Format(weaponDamage, sizeof(weaponDamage), "%d", GetMaximumHealth(client));
			ReplaceString(text, sizeof(text), "{MYHP}", weaponDamage);
		}
		if (StrContains(text, "{CON}", true) != -1) {
			Format(weaponDamage, sizeof(weaponDamage), "%d", GetTalentStrength(client, "constitution", _, _, true));
			ReplaceString(text, sizeof(text), "{CON}", weaponDamage);
		}
		if (StrContains(text, "{AGI}", true) != -1) {
			Format(weaponDamage, sizeof(weaponDamage), "%d", GetTalentStrength(client, "agility", _, _, true));
			ReplaceString(text, sizeof(text), "{AGI}", weaponDamage);
		}
		if (StrContains(text, "{RES}", true) != -1) {
			Format(weaponDamage, sizeof(weaponDamage), "%d", GetTalentStrength(client, "resilience", _, _, true));
			ReplaceString(text, sizeof(text), "{RES}", weaponDamage);
		}
		if (StrContains(text, "{TEC}", true) != -1) {
			Format(weaponDamage, sizeof(weaponDamage), "%d", GetTalentStrength(client, "technique", _, _, true));
			ReplaceString(text, sizeof(text), "{TEC}", weaponDamage);
		}
		if (StrContains(text, "{END}", true) != -1) {
			Format(weaponDamage, sizeof(weaponDamage), "%d", GetTalentStrength(client, "endurance", _, _, true));
			ReplaceString(text, sizeof(text), "{END}", weaponDamage);
		}
		if (StrContains(text, "{LUC}", true) != -1) {
			Format(weaponDamage, sizeof(weaponDamage), "%d", GetTalentStrength(client, "luck", _, _, true));
			ReplaceString(text, sizeof(text), "{LUC}", weaponDamage);
		}
		if (StrContains(text, "{DR}", true) != -1) {
			Format(weaponDamage, sizeof(weaponDamage), "%3.2f", GetAbilityStrengthByTrigger(client, client, TRIGGER_L, _, currentWeaponDamage, _, _, RESULT_o, _, true, _, _, _, _, 1));
			ReplaceString(text, sizeof(text), "{DR}", weaponDamage);
		}
		if (StrContains(text, "{HPRGN}", true) != -1) {
			int healRegen = RoundToCeil(GetAbilityStrengthByTrigger(client, _, TRIGGER_p, _, 0, _, _, RESULT_h, _, true, 0, _, _, _, 1));
			Format(weaponDamage, sizeof(weaponDamage), "%d", healRegen);
			ReplaceString(text, sizeof(text), "{HPRGN}", weaponDamage);
		}
		if (!hasMeleeWeaponEquipped[client]) {
			if (StrContains(text, "{HEALSTRGUN}", true) != -1) {
				Format(weaponDamage, sizeof(weaponDamage), "%d", GetBulletOrMeleeHealAmount(client, target, currentWeaponDamage, DMG_BULLET));
				ReplaceString(text, sizeof(text), "{HEALSTRGUN}", weaponDamage);
			}
			if (StrContains(text, "{HEALSTRMEL}", true) != -1) ReplaceString(text, sizeof(text), "{HEALSTRMEL}", "N/A");
		}
		else {
			if (StrContains(text, "{HEALSTRMEL}", true) != -1) {
				Format(weaponDamage, sizeof(weaponDamage), "%d", GetBulletOrMeleeHealAmount(client, target, currentWeaponDamage, DMG_SLASH));
				ReplaceString(text, sizeof(text), "{HEALSTRMEL}", weaponDamage);
			}
			if (StrContains(text, "{HEALSTRGUN}", true) != -1) ReplaceString(text, sizeof(text), "{HEALSTRGUN}", "N/A");
		}
	}

	SetMenuTitle(menu, text);
	if (playerPageOfCharacterSheet[client] == 0) Format(text, sizeof(text), "%T", "Character Sheet (Survivor Page)", client);
	else Format(text, sizeof(text), "%T", "Character Sheet (Infected Page)", client);
	AddMenuItem(menu, text, text);

	SetMenuExitBackButton(menu, true);
	DisplayMenu(menu, client, 0);
}

stock GetCharacterSheetData(client, char[] stringRef, theSize, request, zombieclass = 0, attacker = 0) {
	//new Float:fResult;
	int iResult;
	int baseDamage;
	int baseHealth;
	float fMultiplier;
	//new Float:AbilityMultiplier = (request % 2 == 0) ? GetAbilityMultiplier(client, "X", 4) : 0.0;
	int theCount = LivingSurvivorCount();
	int myCurrentDifficulty = GetDifficultyRating(client);
	// common infected health
	if (request == 1) {	// odd requests return integers
						// equal requests return floats
		//iResult = (iDontStoreInfectedInArray == 1) ? GetCommonBaseHealth() : GetCommonBaseHealth(client);
		iResult = GetCommonBaseHealth(client);
		baseDamage = iResult;
	}
	// common infected damage
	if (request == 2) {
		fMultiplier = fCommonDamageLevel;
		iResult = iCommonInfectedBaseDamage + RoundToCeil(iCommonInfectedBaseDamage * (myCurrentDifficulty * fMultiplier));
		baseDamage = iCommonInfectedBaseDamage;
	}
	// witch health
	if (request == 3) {
		fMultiplier = fWitchHealthMult;
		iResult = iWitchHealthBase + RoundToCeil(iWitchHealthBase * (myCurrentDifficulty * fWitchHealthMult));
		baseHealth = iWitchHealthBase;
	}
	// witch infected damage
	if (request == 4) {
		fMultiplier = fWitchDamageScaleLevel;
		iResult = iWitchDamageInitial + RoundToCeil(iWitchDamageInitial * (myCurrentDifficulty * fMultiplier));
		baseDamage = iWitchDamageInitial;
	}
	// only if a zombieclass has been specified.
	if (zombieclass != 0) {
		if (zombieclass != ZOMBIECLASS_TANK) zombieclass--;
		else zombieclass -= 2;
	}
	// special infected health
	if (request == 5) {
		fMultiplier = fHealthPlayerLevel[zombieclass];
		iResult = iBaseSpecialInfectedHealth[zombieclass];
		iResult += RoundToCeil(iResult * (myCurrentDifficulty * fMultiplier));
		baseHealth = iBaseSpecialInfectedHealth[zombieclass];
	}
	// special infected damage
	if (request == 6) {
		fMultiplier = fDamagePlayerLevel[zombieclass];
		iResult = iBaseSpecialDamage[zombieclass];
		iResult += RoundToFloor(iResult * (myCurrentDifficulty * fMultiplier));
		baseDamage = iBaseSpecialDamage[zombieclass];
	}// even requests are for damage.
	if (request != 7) {
		if (GetArraySize(HandicapSelectedValues[client]) != 4) SetClientHandicapValues(client, true);
		// health result or damage result
		float handicapLevelBonus = 0.0;
		if (request % 2 != 0) {
			if (fSurvivorHealthBonus > 0.0 && iSurvivorModifierRequired > 0 && theCount >= iSurvivorModifierRequired) iResult += RoundToCeil(iResult * ((theCount - (iSurvivorModifierRequired - 1)) * fSurvivorHealthBonus));
			if (handicapLevel[client] > 0) {
				handicapLevelBonus = GetArrayCell(HandicapSelectedValues[client], 1);
				int healthBonus = RoundToCeil(baseHealth * ((myCurrentDifficulty * fMultiplier) * handicapLevelBonus));
				if (healthBonus > 0) iResult += healthBonus;
			}
		}
		else {
			if (fSurvivorDamageBonus > 0.0 && iSurvivorModifierRequired > 0 && theCount >= iSurvivorModifierRequired) iResult += RoundToCeil(iResult * ((theCount - (iSurvivorModifierRequired - 1)) * fSurvivorDamageBonus));
			if (handicapLevel[client] > 0) {
				handicapLevelBonus = GetArrayCell(HandicapSelectedValues[client], 0);
				int damageBonus = RoundToCeil(baseDamage * ((myCurrentDifficulty * fMultiplier) * handicapLevelBonus));
				if (damageBonus > 0) iResult += damageBonus;
			}
		}
	}
	if (request != 7 && request % 2 == 0) {
		float damageReductionPenaltyMultiplier = 0.0;	// the lesstanky, lessdamage, lessheals, etc. talents are proficiencies so they ignore cooldowns and always get calculated
		damageReductionPenaltyMultiplier += GetAbilityStrengthByTrigger(client, client, TRIGGER_lessTankyMoreHeals, _, 0, _, _, _, 2, true);
		damageReductionPenaltyMultiplier += GetAbilityStrengthByTrigger(client, client, TRIGGER_lessTankyMoreDamage, _, 0, _, _, _, 2, true);
		damageReductionPenaltyMultiplier += GetAbilityMultiplier(client, "expo");			// "exposed" debuff, currently present on the knife ability.
		// Special ammo "E" is the berserk ammo.
		float ammoStr = IsClientInRangeSpecialAmmo(client, "E");
		if (ammoStr > 0.0) {
			damageReductionPenaltyMultiplier += ammoStr;
		}
		if (IsLegitimateClient(attacker)) {
			ammoStr = IsClientInRangeSpecialAmmo(attacker, "E");
			if (ammoStr > 0.0) {
				damageReductionPenaltyMultiplier += ammoStr;
			}
		}
		int damageTakenToAdd = (damageReductionPenaltyMultiplier > 0.0) ? RoundToCeil(iResult * damageReductionPenaltyMultiplier) : 0;

		float damageReductionMultiplier = 0.0;
		damageReductionMultiplier += GetAbilityStrengthByTrigger(client, client, TRIGGER_lessDamageMoreTanky, _, 0, _, _, _, 2, true);
		damageReductionMultiplier += GetAbilityStrengthByTrigger(client, client, TRIGGER_lessHealsMoreTanky, _, 0, _, _, _, 2, true);
		damageReductionMultiplier += GetAbilityStrengthByTrigger(client, attacker, TRIGGER_L, _, 0, _, _, RESULT_o, 2, true);
		// Special ammo "D" is the shield ammo.
		ammoStr = IsClientInRangeSpecialAmmo(client, "D");
		if (ammoStr > 0.0) {
			damageReductionMultiplier += ammoStr;
		}
		// Ability multiplier "X" is currently for last chance and basilisk armor, or any other damage reduction abilities.
		float abilityDamageReduction = GetAbilityMultiplier(client, "X");
		if (abilityDamageReduction > 0.0) damageReductionMultiplier += abilityDamageReduction;
		if (damageReductionMultiplier > fMaxDamageResistance) {
			// prevent damage taken from being reduced to 0 (if desired) but by default the limit is 90%
			damageReductionMultiplier = fMaxDamageResistance;
		}
		int damageTakenToRemove = (damageReductionMultiplier > 0.0) ? RoundToCeil(iResult * damageReductionMultiplier) : 0;
		iResult += damageTakenToAdd;
		iResult -= damageTakenToRemove;
		//iResult = RoundToCeil(CheckActiveAbility(client, iResult, 1));
		if (iResult < 1) iResult = 1;
	}
	AddCommasToString(iResult, stringRef, theSize);
	return iResult;
}