public Action CMD_RollLoot(client, args) {
	//GenerateAndGivePlayerAugment(client);
	return Plugin_Handled;
}

stock RollLoot(client, enemyClient) {
	if (iLootEnabled == 0 || IsFakeClient(client) || Rating[client] < iRatingRequiredForAugmentLootDrops) return;
	
	int lootPoolSize = (iLootDropsForUnlockedTalentsOnly[client] == 1) ? GetArraySize(possibleLootPool[client]) : GetArraySize(unlockedLootPool[client]);
	if (lootPoolSize < 1) return;
	
	int zombieclass = FindZombieClass(enemyClient);
	float fLootChance = (zombieclass == 10) ? fLootChanceCommons :					// common
						(zombieclass == 9) ? fLootChanceSupers :					// super
						(zombieclass == 7) ? fLootChanceWitch :						// witch
						(zombieclass == 8) ? fLootChanceTank :						// tank
						(zombieclass > 0) ? fLootChanceSpecials : 0.0;				// special infected
	if (fLootChance == 0.0) return;
	
	// in borderlands you have a low chance of getting loot, so they throw a ton of roll attempts at you.
	// sometimes you get an overwhelming amount, sometimes you get one item, sometimes you get nothing.
	int numOfRollsToAttempt = (zombieclass == 10) ? iNumLootDropChancesPerPlayer[0] :
							(zombieclass == 9) ? iNumLootDropChancesPerPlayer[1] :
							(zombieclass == 7) ? iNumLootDropChancesPerPlayer[3] :
							(zombieclass == 8) ? iNumLootDropChancesPerPlayer[4] : iNumLootDropChancesPerPlayer[2];
	int numOfAugmentPartsToReturn = 0;
	for (int i = numOfRollsToAttempt; i > 0; i--) {
		if (fLootChance < 1.0) {	// guaranteed drops when the chance is > 1.0
			int roll = GetRandomInt(1, RoundToCeil(1.0 / fLootChance));
			if (roll != 1) continue;
		}
		else if (fLootChance > 1.0) {
			// This means a guaranteed roll so we remove the guaranteed roll. There can be as many guaranteed rolls as a server operator wants.
			fLootChance -= 1.0;
		}
		
		int result = GenerateAugment(client, enemyClient);
		if (result == -2) numOfAugmentPartsToReturn++;
	}
	if (numOfAugmentPartsToReturn > 0) {
		augmentParts[client] += numOfAugmentPartsToReturn;
		if (numOfAugmentPartsToReturn > 0) {
			char text[512];
			Format(text, sizeof(text), "{G}+%d {O}Crafting {B}Materials", numOfAugmentPartsToReturn);
			if (iFancyBorders == 1) {
				Format(text, sizeof(text), "{O}-----------------------\n%s\n{O}-----------------------", text);
			}
			Client_PrintToChat(client, true, text);
		}
	}
}

stock void CreateItemDrop(int owner, int client, int pos) {
	char text[64];
	GetClientAuthId(owner, AuthId_Steam2, text, 64);
	Format(text, sizeof(text), "loot_%s+%d-%d", text, pos, iLootDropsForUnlockedTalentsOnly[owner]);
	if (iGenerateLootBags != 1) {
		IsPlayerTryingToPickupLoot(owner, false, text);
		return;
	}

	int entity = CreateEntityByName("prop_physics_override");
	if (!IsValidEntityEx(entity)) return;

	float Origin[3];
	if (IsLegitimateClient(client)) GetClientAbsOrigin(client, Origin);
	else GetEntPropVector(client, Prop_Send, "m_vecOrigin", Origin);

	DispatchKeyValue(entity, "targetname", text);
	DispatchKeyValue(entity, "spawnflags", "1029");
	DispatchKeyValue(entity, "solid", "6");
	DispatchKeyValue(entity, "model", sItemModel);
	DispatchKeyValue(entity, "glowstate", "2");
	DispatchSpawn(entity);

	int lootsize = GetArraySize(playerLootOnGround[owner])-1;
	if (lootsize < 1) return;
	int ascore = GetArrayCell(playerLootOnGround[owner], lootsize, 2);
	int tscore = GetArrayCell(playerLootOnGround[owner], lootsize, 4);
	if (ascore >= 0 && tscore >= 0) lootsize = 2;
	else if (ascore >= 0 || tscore >= 0) lootsize = 1;
	else lootsize = 0;

	SetEntityRenderMode(entity, RENDER_TRANSCOLOR);
	if (lootsize == 0) {	// green for minor
		SetEntityRenderColor(entity, 0, 255, 0, 255);
		DispatchKeyValue(entity, "glowcolor", "0 255 0");
	}
	else if (lootsize == 1) {	// blue for major
		SetEntityRenderColor(entity, 0, 0, 255, 255);
		DispatchKeyValue(entity, "glowcolor", "0 0 255");
	}
	else {	// gold for perfect
		SetEntityRenderColor(entity, 255, 215, 0, 255);
		DispatchKeyValue(entity, "glowcolor", "255 215 0");
	}
	CreateTimer(fLootBagExpirationTimeInSeconds, Timer_DeleteLootBag, entity, TIMER_FLAG_NO_MAPCHANGE);

	float vel[3];
	vel[0] = GetRandomFloat(-100.0, 100.0);
	vel[1] = GetRandomFloat(-100.0, 100.0);
	vel[2] = GetRandomFloat(10.0, 100.0);

	Origin[2] += 32.0;
	TeleportEntity(entity, Origin, NULL_VECTOR, vel);
	//SetEntityMoveType(entity, MOVETYPE_VPHYSICS);
}

stock int GenerateAugment(int client, int spawnTarget) {
	if (IsFakeClient(client)) return 0;
	int min = Rating[client];
	int max = (min + iRatingRequiredForAugmentLootDrops > BestRating[client]) ? min + iRatingRequiredForAugmentLootDrops : BestRating[client];
	int lootFindBonus = 0;
	if (handicapLevel[client] > 0) {
		lootFindBonus = GetArrayCell(HandicapSelectedValues[client], 2);
	}
	int potentialItemRating = GetRandomInt(min, max+lootFindBonus);
	if (potentialItemRating < iplayerSettingAutoDismantleScore[client]) {
		// we give the player augment parts instead because they don't want this item.
		return -2;
	}
	int clientInventoryLimit = iInventoryLimit;
	if (bHasDonorPrivileges[client]) clientInventoryLimit += iDonorInventoryIncrease;
	if (GetArraySize(myAugmentIDCodes[client]) >= clientInventoryLimit) {
		Format(statusMessageToDisplay[client], 64, "Inventory Full. Scrapping all drops.");
		fStatusMessageDisplayTime[client] = GetEngineTime() + fDisplayLootPickupMessageTime;
		return -2;
	}
	int lootPool = (iLootDropsForUnlockedTalentsOnly[client] == 1) ? GetArraySize(myLootDropCategoriesAllowed[client]) : GetArraySize(myUnlockedLootDropCategoriesAllowed[client]);
	if (lootPool < 1) return 0;
	int thisAugmentRatingRequiredForNextTier = iRatingRequiredForAugmentLootDrops;
	int count = 0;
	int scoreReserve[2];
	while (potentialItemRating >= thisAugmentRatingRequiredForNextTier && count < 3) {
		count++;
		if (count == 3) break;
		thisAugmentRatingRequiredForNextTier = (count * iMultiplierForAugmentLootDrops) * iRatingRequiredForAugmentLootDrops;
		scoreReserve[count-1] = thisAugmentRatingRequiredForNextTier;
	}
	count--;
	int lootsize = 0;
	int lootrolls[3];
	int subScores[3];
	thisAugmentRatingRequiredForNextTier = (count < 1) ? iRatingRequiredForAugmentLootDrops : (count * iMultiplierForAugmentLootDrops) * iRatingRequiredForAugmentLootDrops;

	float augmentTierCategoryPenalty = 1.0;
	while (potentialItemRating >= thisAugmentRatingRequiredForNextTier) {
		count--;
		int reserve = (count > 0) ? scoreReserve[count-1] : 0;
		int subMax = (thisAugmentRatingRequiredForNextTier < potentialItemRating - reserve) ? potentialItemRating : potentialItemRating - reserve;
		int roll = GetRandomInt(thisAugmentRatingRequiredForNextTier, subMax);
		potentialItemRating -= roll;
		lootrolls[lootsize] = roll;
		subScores[lootsize] = subMax;	// max score that can ever roll on this augment for this category.
		thisAugmentRatingRequiredForNextTier = (count < 1) ? iRatingRequiredForAugmentLootDrops : (count * iMultiplierForAugmentLootDrops) * iRatingRequiredForAugmentLootDrops;
		if (lootsize < 2 && potentialItemRating >= thisAugmentRatingRequiredForNextTier) lootsize++;
		else break;
	}
	// [0] - category score roll
	// [1] - category position
	// [2] - activator score roll
	// [3] - activator position
	// [4] - target score roll
	// [5] - target position
	// [6] - max category score roll
	// [7] - max activator score roll
	// [8] - max target score roll
	int size = GetArraySize(playerLootOnGround[client]);
	ResizeArray(playerLootOnGround[client], size+1);
	ResizeArray(playerLootOnGroundId[client], size+1);
	SetArrayCell(playerLootOnGround[client], size, -1, 7);
	SetArrayCell(playerLootOnGround[client], size, -1, 8);

	char sItemCode[64];
	FormatTime(sItemCode, 64, "%y%m%d%H%M%S", GetTime());
	lootDropCounter++;
	Format(sItemCode, 64, "%d%s%d", iUniqueServerCode, sItemCode, lootDropCounter);
	SetArrayString(playerLootOnGroundId[client], size, sItemCode);

	int pos = GetRandomInt(0, lootPool-1);
	SetArrayCell(playerLootOnGround[client], size, pos, 1);

	int possibilities = RoundToCeil(1.0 / fAugmentTierChance);
	int type = GetRandomInt(1, possibilities);
	char activatorEffects[64];
	char targetEffects[64];

	if (iLootDropsForUnlockedTalentsOnly[client] == 1) {
		pos = GetRandomInt(0, GetArraySize(possibleLootPoolActivator[client])-1);
		if (type == 1 && lootsize > 0 && pos < GetArraySize(myLootDropActivatorEffectsAllowed[client])) {
			GetArrayString(myLootDropActivatorEffectsAllowed[client], pos, activatorEffects, 64);
			SetArrayCell(playerLootOnGround[client], size, lootrolls[1], 2);
			SetArrayCell(playerLootOnGround[client], size, pos, 3);
			SetArrayCell(playerLootOnGround[client], size, subScores[1], 7);

			augmentTierCategoryPenalty -= fCategoryStrengthPenaltyAugmentTier;
		}
		else {
			SetArrayCell(playerLootOnGround[client], size, -1, 2);
			SetArrayCell(playerLootOnGround[client], size, -1, 3);
		}
		type = GetRandomInt(1, possibilities);
		pos = GetRandomInt(0, GetArraySize(possibleLootPoolTarget[client])-1);
		if (type == 1 && lootsize > 1 && pos < GetArraySize(myLootDropTargetEffectsAllowed[client])) {
			GetArrayString(myLootDropTargetEffectsAllowed[client], pos, targetEffects, 64);
			SetArrayCell(playerLootOnGround[client], size, lootrolls[2], 4);
			SetArrayCell(playerLootOnGround[client], size, pos, 5);
			SetArrayCell(playerLootOnGround[client], size, subScores[2], 8);

			augmentTierCategoryPenalty -= fCategoryStrengthPenaltyAugmentTier;
		}
		else {
			SetArrayCell(playerLootOnGround[client], size, -1, 4);
			SetArrayCell(playerLootOnGround[client], size, -1, 5);
		}
	}
	else {
		pos = GetRandomInt(0, GetArraySize(unlockedLootPoolActivator[client])-1);
		if (type == 1 && lootsize > 0 && pos < GetArraySize(myUnlockedLootDropActivatorEffectsAllowed[client])) {
			GetArrayString(myUnlockedLootDropActivatorEffectsAllowed[client], pos, activatorEffects, 64);
			SetArrayCell(playerLootOnGround[client], size, lootrolls[1], 2);
			SetArrayCell(playerLootOnGround[client], size, pos, 3);
			SetArrayCell(playerLootOnGround[client], size, subScores[1], 7);

			augmentTierCategoryPenalty -= fCategoryStrengthPenaltyAugmentTier;
		}
		else {
			SetArrayCell(playerLootOnGround[client], size, -1, 2);
			SetArrayCell(playerLootOnGround[client], size, -1, 3);
		}
		type = GetRandomInt(1, possibilities);
		pos = GetRandomInt(0, GetArraySize(unlockedLootPoolTarget[client])-1);
		if (type == 1 && lootsize > 1 && pos < GetArraySize(myUnlockedLootDropTargetEffectsAllowed[client])) {
			GetArrayString(myUnlockedLootDropTargetEffectsAllowed[client], pos, targetEffects, 64);
			SetArrayCell(playerLootOnGround[client], size, lootrolls[2], 4);
			SetArrayCell(playerLootOnGround[client], size, pos, 5);
			SetArrayCell(playerLootOnGround[client], size, subScores[2], 8);

			augmentTierCategoryPenalty -= fCategoryStrengthPenaltyAugmentTier;
		}
		else {
			SetArrayCell(playerLootOnGround[client], size, -1, 4);
			SetArrayCell(playerLootOnGround[client], size, -1, 5);
		}
	}
	SetArrayCell(playerLootOnGround[client], size, RoundToCeil(augmentTierCategoryPenalty * lootrolls[0]));
	// for the crafting update, tracking the max possible roll for this augment, so when a player decides to roll for upgrades
	// they can't exceed what this items max roll originally would be.
	// this means this system can be used to upgrade existing gear if nothing good is dropping, but doesn't eliminate the necessity
	// of finding new loot at higher scores and handicaps.
	SetArrayCell(playerLootOnGround[client], size, RoundToCeil(augmentTierCategoryPenalty * (max+lootFindBonus)), 6);
	SetArrayCell(playerLootOnGround[client], size, size, 9);
	CreateItemDrop(client, spawnTarget, size);
	return 1;
}

stock void GetUniqueAugmentLootDropItemCode(char[] sTime) {
	FormatTime(sTime, 64, "%y%m%d%H%M%S", GetTime());
	lootDropCounter++;
	Format(sTime, 64, "%d%s%d", iUniqueServerCode, sTime, lootDropCounter);
}

stock SetClientTalentStrength(client, bool giveAccessToAllTalents = false) {
	if (GetArraySize(attributeData[client]) != 6) {
		ResizeArray(attributeData[client], 6);
		for (int i = ATTRIBUTE_CONSTITUTION; i <= ATTRIBUTE_LUCK; i++) {
			AddAttributeExperience(client, i, 0, true);
		}
	}
	b_IsLoading[client] = true;
	int ASize = GetArraySize(a_Menu_Talents);
	ResizeArray(MyTalentStrength[client], ASize);
	ResizeArray(MyTalentStrengths[client], ASize);
	ClearArray(MyUnlockedTalents[client]);
	char TalentName[64];
	for (int i = 0; i < ASize; i++) {
		// preset all talents to being unclaimed.
		SetArrayCell(MyTalentStrengths[client], i, 0.0);
		SetArrayCell(MyTalentStrengths[client], i, 0.0, 1);
		SetArrayCell(MyTalentStrengths[client], i, 0.0, 2);
		SetArrayCell(MyTalentStrength[client], i, 0);

		//PreloadTalentSection[client]	= GetArrayCell(a_Menu_Talents, i, 2);
		GetArrayString(a_Database_Talents, i, TalentName, sizeof(TalentName));
		if (!giveAccessToAllTalents && GetTalentStrength(client, TalentName) < 1) {
			continue;
		}
		PreloadTalentValues[client]	= GetArrayCell(a_Menu_Talents, i, 1);
		float f_EachPoint	= GetTalentInfo(client, PreloadTalentValues[client], _, _, TalentName, _, 1, true);
		float f_Time		= GetTalentInfo(client, PreloadTalentValues[client], 2, _, TalentName, _, 1, true);
		float f_Cooldown	= GetTalentInfo(client, PreloadTalentValues[client], 3, _, TalentName, _, 1, true);
		SetArrayCell(MyTalentStrengths[client], i, f_EachPoint);
		SetArrayCell(MyTalentStrengths[client], i, f_Time, 1);
		SetArrayCell(MyTalentStrengths[client], i, f_Cooldown, 2);
		SetArrayCell(MyTalentStrength[client], i, 1);

		int numUnlockedTalents = GetArraySize(MyUnlockedTalents[client]);
		//ResizeArray(MyUnlockedTalents[client], numUnlockedTalents + 1);
		PushArrayCell(MyUnlockedTalents[client], i);

		char activatoreffects[64];
		char targeteffects[64];
		GetArrayString(PreloadTalentValues[client], ACTIVATOR_ABILITY_EFFECTS, activatoreffects, sizeof(activatoreffects));
		GetArrayString(PreloadTalentValues[client], TARGET_ABILITY_EFFECTS, targeteffects, sizeof(targeteffects));

		char secondaryEffects[64];
		GetArrayString(PreloadTalentValues[client], SECONDARY_EFFECTS, secondaryEffects, sizeof(secondaryEffects));

		// intcomp is significantly faster than strcomp
		int activatorInt = ConvertEffectToInt(activatoreffects);
		SetArrayCell(MyUnlockedTalents[client], numUnlockedTalents, activatorInt, 1);

		int targetInt = ConvertEffectToInt(targeteffects);
		SetArrayCell(MyUnlockedTalents[client], numUnlockedTalents, targetInt, 2);

		int secondaryInt = ConvertEffectToInt(secondaryEffects);
		SetArrayCell(MyUnlockedTalents[client], numUnlockedTalents, secondaryInt, 3);

		char activeEndAbilityTrigger[64];
		char endAbilityTrigger[64];
		GetArrayString(PreloadTalentValues[client], ABILITY_ACTIVE_END_ABILITY_TRIGGER, activeEndAbilityTrigger, sizeof(activeEndAbilityTrigger));
		GetArrayString(PreloadTalentValues[client], ABILITY_COOLDOWN_END_TRIGGER, endAbilityTrigger, sizeof(endAbilityTrigger));
		int endActiveAbilityTriggerInt = ConvertTriggerToInt(activeEndAbilityTrigger);
		int endAbilityTriggerInt = ConvertTriggerToInt(endAbilityTrigger);
		SetArrayCell(MyUnlockedTalents[client], numUnlockedTalents, endActiveAbilityTriggerInt, 4);
		SetArrayCell(MyUnlockedTalents[client], numUnlockedTalents, endAbilityTriggerInt, 5);

		char secondaryAbilityTrigger[64];
		GetArrayString(PreloadTalentValues[client], SECONDARY_ABILITY_TRIGGER, secondaryAbilityTrigger, sizeof(secondaryAbilityTrigger));
		int secondaryAbilityInt = ConvertTriggerToInt(secondaryAbilityTrigger);
		SetArrayCell(MyUnlockedTalents[client], numUnlockedTalents, secondaryAbilityInt, 6);

		char activatorCallAbilityTrigger[64];
		GetArrayString(PreloadTalentValues[client], ACTIVATOR_CALL_ABILITY_TRIGGER, activatorCallAbilityTrigger, sizeof(activatorCallAbilityTrigger));
		int activatorCallAbilityTriggerInt = ConvertTriggerToInt(activatorCallAbilityTrigger);
		SetArrayCell(MyUnlockedTalents[client], numUnlockedTalents, activatorCallAbilityTriggerInt, 7);

		char targetCallAbilityTrigger[64];
		GetArrayString(PreloadTalentValues[client], TARGET_CALL_ABILITY_TRIGGER, targetCallAbilityTrigger, sizeof(targetCallAbilityTrigger));
		int targetCallAbilityTriggerInt = ConvertTriggerToInt(targetCallAbilityTrigger);
		SetArrayCell(MyUnlockedTalents[client], numUnlockedTalents, targetCallAbilityTriggerInt, 8);


		// We're going to memo certain string results since checking strings very-often and many times is expensive and slow.
		char playerRequiredToBeInSpecialAmmo[10];
		GetArrayString(PreloadTalentValues[client], ACTIVATOR_MUST_BE_IN_AMMO, playerRequiredToBeInSpecialAmmo, sizeof(playerRequiredToBeInSpecialAmmo));
		if (StrEqual(playerRequiredToBeInSpecialAmmo, "-1")) SetArrayCell(MyTalentStrengths[client], i, -1, 6);
		else SetArrayCell(MyTalentStrengths[client], i, 1, 6);

		char TargetRequiredToBeInSpecialAmmo[10];
		GetArrayString(PreloadTalentValues[client], TARGET_MUST_BE_IN_AMMO, TargetRequiredToBeInSpecialAmmo, sizeof(TargetRequiredToBeInSpecialAmmo));
		if (StrEqual(TargetRequiredToBeInSpecialAmmo, "-1")) SetArrayCell(MyTalentStrengths[client], i, -1, 7);
		else SetArrayCell(MyTalentStrengths[client], i, 1, 7);

		char coherencyTalentNearbyRequired[64];
		GetArrayString(PreloadTalentValues[client], COHERENCY_TALENT_NEARBY_REQUIRED, coherencyTalentNearbyRequired, sizeof(coherencyTalentNearbyRequired));
		if (StrEqual(coherencyTalentNearbyRequired, "-1")) SetArrayCell(MyTalentStrengths[client], i, -1, 8);
		else SetArrayCell(MyTalentStrengths[client], i, 1, 8);

		char specificWeaponRequired[64];
		GetArrayString(PreloadTalentValues[client], WEAPON_NAME_REQUIRED, specificWeaponRequired, sizeof(specificWeaponRequired));
		if (StrEqual(specificWeaponRequired, "-1")) SetArrayCell(MyTalentStrengths[client], i, -1, 9);
		else SetArrayCell(MyTalentStrengths[client], i, 1, 9);
	}
	int iCurrentAugmentLevel = 0;
	if (GetArraySize(equippedAugments[client]) != iNumAugments) ClearEquippedAugmentData(client);
	else {
		for (int i = 0; i < iNumAugments; i++) {
			int iCur = GetArrayCell(equippedAugments[client], i, 2) + GetArrayCell(equippedAugments[client], i, 4) + GetArrayCell(equippedAugments[client], i, 5);
			if (iCur > 0) iCurrentAugmentLevel += iCur;
		}
		playerCurrentAugmentLevel[client] = (iCurrentAugmentLevel / iAugmentLevelDivisor);
		playerCurrentAugmentAverageLevel[client] = GetClientAverageAugment(client);
		SetLootDropCategories(client);
	}
	myCurrentTeam[client] = GetClientTeam(client);
	b_IsLoading[client] = false;
	SurvivorStamina[client] = GetPlayerStamina(client);
	SetMaximumHealth(client);
	if (!b_IsActiveRound) GiveMaximumHealth(client);
	if (GetTalentPointsByKeyValue(client, ACTIVATOR_ABILITY_EFFECTS, "weakness") > 0 ||
		GetTalentPointsByKeyValue(client, SECONDARY_EFFECTS, "weakness") > 0) bForcedWeakness[client] = true;
	else bForcedWeakness[client] = false;

	GenerateUnlockedLootPool(client);
}

int GetClientAverageAugment(client) {
	// int numEquippedAugments = 0;
	// for (int i = 0; i < iNumAugments; i++) {
	// 	int iCur = GetArrayCell(equippedAugments[client], i, 2);
	// 	if (iCur > 0) numEquippedAugments++;
	// }
	// int averageAugmentScore = (numEquippedAugments > 0) ? (playerCurrentAugmentLevel[client] / numEquippedAugments) : playerCurrentAugmentLevel[client];
	int averageAugmentScore = (playerCurrentAugmentLevel[client] > 0) ? (playerCurrentAugmentLevel[client] / iNumAugments) : playerCurrentAugmentLevel[client];
	return averageAugmentScore;
}

stock GenerateUnlockedLootPool(client) {
	ClearArray(unlockedLootPoolActivator[client]);
	ClearArray(unlockedLootPoolTarget[client]);
	ClearArray(unlockedLootPool[client]);
	ClearArray(myUnlockedLootDropCategoriesAllowed[client]);
	ClearArray(myUnlockedUnlockedCategories[client]);
	ClearArray(myUnlockedLootDropActivatorEffectsAllowed[client]);
	ClearArray(myUnlockedUnlockedActivators[client]);
	ClearArray(myUnlockedLootDropTargetEffectsAllowed[client]);
	ClearArray(myUnlockedUnlockedTargets[client]);
	int iMaxLayerAccessible = 1;
	int[] upgradesRequiredToUnlockThisLayer = new int[iMaxLayers+1];
	for (int currentLayer = 1; currentLayer <= iMaxLayers; currentLayer++) {
		int totalNodesThisLayer = GetLayerUpgradeStrength(client, currentLayer, _, _, _, true);
		if (totalNodesThisLayer < 1) continue;
		
		int strengthOfCurrentLayer = GetLayerUpgradeStrength(client, currentLayer);
		int totalUpgradesRequiredToUnlockNextLayer = (fUpgradesRequiredPerLayer <= 1.0) ? RoundToCeil(totalNodesThisLayer * fUpgradesRequiredPerLayer) : RoundToCeil(fUpgradesRequiredPerLayer);
		upgradesRequiredToUnlockThisLayer[currentLayer] = (totalUpgradesRequiredToUnlockNextLayer > strengthOfCurrentLayer)
											? totalUpgradesRequiredToUnlockNextLayer - strengthOfCurrentLayer
											: 0;
		if (upgradesRequiredToUnlockThisLayer[currentLayer] > 0) break;
		iMaxLayerAccessible = currentLayer;
	}

	int size = GetArraySize(a_Menu_Talents);
	int explodeCount = GetDelimiterCount(sCategoriesToIgnore, ",") + 1;
	char[][] categoriesToSkip = new char[explodeCount][64];
	ExplodeString(sCategoriesToIgnore, ",", categoriesToSkip, explodeCount, 64);
	char talentName[64];
	for (int i = 0; i < size; i++) {
		LootDropCategoryToBuffValues[client]			= GetArrayCell(a_Menu_Talents, i, 1);
		int thisTalentLayer = GetArrayCell(LootDropCategoryToBuffValues[client], GET_TALENT_LAYER);
		if (thisTalentLayer > iMaxLayerAccessible) continue;


		GetArrayString(LootDropCategoryToBuffValues[client], PART_OF_MENU_NAMED, talentName, sizeof(talentName));
		bool bSkipThisTalent = false;
		for (int ii = 0; ii < explodeCount; ii++) {
			if (StrContains(talentName, categoriesToSkip[ii]) == -1) continue;
			bSkipThisTalent = true;
			break;
		}
		if (bSkipThisTalent) continue;

		PushArrayCell(unlockedLootPool[client], i);
		GetArrayString(LootDropCategoryToBuffValues[client], TALENT_TREE_CATEGORY, talentName, sizeof(talentName));
		PushArrayString(myUnlockedLootDropCategoriesAllowed[client], talentName);

		if (!ArrayContains(myUnlockedUnlockedCategories[client], talentName)) PushArrayString(myUnlockedUnlockedCategories[client], talentName);

		GetArrayString(LootDropCategoryToBuffValues[client], ACTIVATOR_ABILITY_EFFECTS, talentName, sizeof(talentName));
		if (!StrEqual(talentName, "-1") && !StrEqual(talentName, "0")) {
			PushArrayString(myUnlockedLootDropActivatorEffectsAllowed[client], talentName);
			if (!ArrayContains(myUnlockedUnlockedActivators[client], talentName)) PushArrayString(myUnlockedUnlockedActivators[client], talentName);
			PushArrayCell(unlockedLootPoolActivator[client], i);
		}

		GetArrayString(LootDropCategoryToBuffValues[client], TARGET_ABILITY_EFFECTS, talentName, sizeof(talentName));
		if (!StrEqual(talentName, "-1") && !StrEqual(talentName, "0")) {
			PushArrayString(myUnlockedLootDropTargetEffectsAllowed[client], talentName);
			if (!ArrayContains(myUnlockedUnlockedTargets[client], talentName)) PushArrayString(myUnlockedUnlockedTargets[client], talentName);
			PushArrayCell(unlockedLootPoolTarget[client], i);
		}
	}
}

stock void SetLootDropCategories(client) {
	ClearArray(possibleLootPool[client]);
	ClearArray(possibleLootPoolActivator[client]);
	ClearArray(possibleLootPoolTarget[client]);
	ClearArray(myLootDropCategoriesAllowed[client]);
	ClearArray(myLootDropTargetEffectsAllowed[client]);
	ClearArray(myLootDropActivatorEffectsAllowed[client]);
	ClearArray(myUnlockedCategories[client]);
	ClearArray(myUnlockedActivators[client]);
	ClearArray(myUnlockedTargets[client]);
	int size = GetArraySize(a_Menu_Talents);
	if (GetArraySize(MyTalentStrength[client]) != size) ResizeArray(MyTalentStrength[client], size);
	int explodeCount = GetDelimiterCount(sCategoriesToIgnore, ",") + 1;
	char[][] categoriesToSkip = new char[explodeCount][64];
	ExplodeString(sCategoriesToIgnore, ",", categoriesToSkip, explodeCount, 64);
	char talentName[64];
	for (int i = 0; i < size; i++) {
		if (GetArrayCell(MyTalentStrength[client], i) < 1) continue;
		LootDropCategoryToBuffValues[client]			= GetArrayCell(a_Menu_Talents, i, 1);
		GetArrayString(LootDropCategoryToBuffValues[client], PART_OF_MENU_NAMED, talentName, sizeof(talentName));
		bool bSkipThisTalent = false;
		for (int ii = 0; ii < explodeCount; ii++) {
			if (StrContains(talentName, categoriesToSkip[ii]) == -1) continue;
			bSkipThisTalent = true;
			break;
		}
		if (bSkipThisTalent) continue;
		PushArrayCell(possibleLootPool[client], i);
		GetArrayString(LootDropCategoryToBuffValues[client], TALENT_TREE_CATEGORY, talentName, sizeof(talentName));
		PushArrayString(myLootDropCategoriesAllowed[client], talentName);
		if (!ArrayContains(myUnlockedCategories[client], talentName)) PushArrayString(myUnlockedCategories[client], talentName);
		//if (GetArrayCell(LootDropCategoryToBuffValues[client], SKIP_TALENT_FOR_AUGMENT_ROLL) != 1) {
		GetArrayString(LootDropCategoryToBuffValues[client], ACTIVATOR_ABILITY_EFFECTS, talentName, sizeof(talentName));
		if (!StrEqual(talentName, "-1") && !StrEqual(talentName, "0")) {
			PushArrayString(myLootDropActivatorEffectsAllowed[client], talentName);
			if (!ArrayContains(myUnlockedActivators[client], talentName)) PushArrayString(myUnlockedActivators[client], talentName);
			PushArrayCell(possibleLootPoolActivator[client], i);
		}
		//}

		GetArrayString(LootDropCategoryToBuffValues[client], TARGET_ABILITY_EFFECTS, talentName, sizeof(talentName));
		if (!StrEqual(talentName, "-1") && !StrEqual(talentName, "0")) {
			PushArrayString(myLootDropTargetEffectsAllowed[client], talentName);
			if (!ArrayContains(myUnlockedTargets[client], talentName)) PushArrayString(myUnlockedTargets[client], talentName);
			PushArrayCell(possibleLootPoolTarget[client], i);
		}
	}
}