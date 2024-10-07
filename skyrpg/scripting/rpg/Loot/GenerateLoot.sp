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
		if (numOfAugmentPartsToReturn > 1) {
			char text[64];
			Format(text, 64, "{G}+%d {O}scrap", numOfAugmentPartsToReturn);
			Client_PrintToChat(client, true, text);
		}
	}
}

stock void CreateItemDrop(int owner, int client, int pos) {
	float Origin[3];
	if (IsLegitimateClient(client)) GetClientAbsOrigin(client, Origin);
	else GetEntPropVector(client, Prop_Send, "m_vecOrigin", Origin);

	char text[64];
	GetClientAuthId(owner, AuthId_Steam2, text, 64);
	Format(text, sizeof(text), "loot_%s+%d-%d", text, pos, iLootDropsForUnlockedTalentsOnly[owner]);
	int entity = CreateEntityByName("prop_physics_override");
	DispatchKeyValue(entity, "targetname", text);
	DispatchKeyValue(entity, "spawnflags", "1029");
	DispatchKeyValue(entity, "solid", "6");
	DispatchKeyValue(entity, "model", sItemModel);
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
	}
	else if (lootsize == 1) {	// blue for major
		SetEntityRenderColor(entity, 0, 0, 255, 255);
	}
	else {	// gold for perfect
		SetEntityRenderColor(entity, 255, 215, 0, 255);
	}
	CreateTimer(fLootBagExpirationTimeInSeconds, Timer_DeleteLootBag, entity, TIMER_FLAG_NO_MAPCHANGE);

	float vel[3];
	vel[0] = GetRandomFloat(-10000.0, 1000.0);
	vel[1] = GetRandomFloat(-1000.0, 1000.0);
	vel[2] = GetRandomFloat(100.0, 1000.0);

	Origin[2] += 32.0;
	TeleportEntity(entity, Origin, NULL_VECTOR, vel);
	//SetEntityMoveType(entity, MOVETYPE_VPHYSICS);
}

stock void PickupAugment(int client, int owner, char[] ownerSteamID = "none", char[] ownerName = "none", int pos, int lootPoolToDrawFrom) {
	int size = GetArraySize(myAugmentIDCodes[client]);
	ResizeArray(myAugmentIDCodes[client], size+1);
	ResizeArray(myAugmentCategories[client], size+1);
	ResizeArray(myAugmentOwners[client], size+1);
	ResizeArray(myAugmentOwnersName[client], size+1);
	ResizeArray(myAugmentInfo[client], size+1);
	ResizeArray(myAugmentActivatorEffects[client], size+1);
	ResizeArray(myAugmentTargetEffects[client], size+1);
	ResizeArray(myAugmentSavedProfiles[client], size+1);
	char nosaved[64];
	Format(nosaved, sizeof(nosaved), "none");
	SetArrayString(myAugmentSavedProfiles[client], size, nosaved);

	// [0] - category score roll
	// [1] - category position
	// [2] - activator score roll
	// [3] - activator position
	// [4] - target score roll
	// [5] = target position
	// [6] = handicap score bonus (used for upgrading later)
	//int pos = GetArraySize(playerLootOnGround[owner])-1;
	char sItemCode[64];
	GetArrayString(playerLootOnGroundId[owner], pos, sItemCode, sizeof(sItemCode));
	SetArrayString(myAugmentIDCodes[client], size, sItemCode);

	char buffedCategory[64];
	if (lootPoolToDrawFrom == 1) GetArrayString(myLootDropCategoriesAllowed[owner], GetArrayCell(playerLootOnGround[owner], pos, 1), buffedCategory, 64);
	else GetArrayString(myUnlockedLootDropCategoriesAllowed[owner], GetArrayCell(playerLootOnGround[owner], pos, 1), buffedCategory, 64);

	char menuText[64];
	int len = GetAugmentTranslation(client, buffedCategory, menuText);
	Format(menuText, 64, "%T", menuText, client);

	SetArrayString(myAugmentCategories[client], size, buffedCategory);

	int augmentItemScore = GetArrayCell(playerLootOnGround[owner], pos);
	char key[64];
	GetClientAuthId(client, AuthId_Steam2, key, sizeof(key));
	SetArrayString(myAugmentOwners[client], size, ownerSteamID);
	SetArrayString(myAugmentOwnersName[client], size, ownerName);
	SetArrayCell(myAugmentInfo[client], size, augmentItemScore);	// item rating (cell 4 is activatorRating and cell5 is targetRating)
	SetArrayCell(myAugmentInfo[client], size, 0, 1);			// item cost
	SetArrayCell(myAugmentInfo[client], size, 0, 2);			// is item for sale
	SetArrayCell(myAugmentInfo[client], size, -1, 3);			// which augment slot the item is equipped in - -1 for no slot.


	int augmentActivatorRating = -1;
	int augmentTargetRating = -1;
	char activatorEffects[64];
	char targetEffects[64];

	int maxpossibleroll = GetArrayCell(playerLootOnGround[owner], pos, 6);
	SetArrayCell(myAugmentInfo[client], size, maxpossibleroll, 6);

	int maxPossibleActivatorScore = 0;
	int maxPossibleTargetScore = 0;

	int apos = GetArrayCell(playerLootOnGround[owner], pos, 3);
	if (apos >= 0) {
		if (lootPoolToDrawFrom == 1) GetArrayString(myLootDropActivatorEffectsAllowed[owner], apos, activatorEffects, 64);
		else GetArrayString(myUnlockedLootDropActivatorEffectsAllowed[owner], apos, activatorEffects, 64);

		SetArrayString(myAugmentActivatorEffects[client], size, activatorEffects);
		augmentActivatorRating = GetArrayCell(playerLootOnGround[owner], pos, 2);
		maxPossibleActivatorScore = GetArrayCell(playerLootOnGround[owner], pos, 7);
		SetArrayCell(myAugmentInfo[client], size, maxPossibleActivatorScore, 7);
	}
	else {
		augmentActivatorRating = -1;
		Format(activatorEffects, 64, "-1");
		SetArrayString(myAugmentActivatorEffects[client], size, "-1");
		SetArrayCell(myAugmentInfo[client], size, -1, 7);
	}
	SetArrayCell(myAugmentInfo[client], size, augmentActivatorRating, 4);

	int tpos = GetArrayCell(playerLootOnGround[owner], pos, 5);
	if (tpos >= 0) {
		if (lootPoolToDrawFrom == 1) GetArrayString(myLootDropTargetEffectsAllowed[owner], tpos, targetEffects, 64);
		else GetArrayString(myUnlockedLootDropTargetEffectsAllowed[owner], tpos, targetEffects, 64);

		SetArrayString(myAugmentTargetEffects[client], size, targetEffects);
		augmentTargetRating = GetArrayCell(playerLootOnGround[owner], pos, 4);
		maxPossibleTargetScore = GetArrayCell(playerLootOnGround[owner], pos, 8);
		SetArrayCell(myAugmentInfo[client], size, maxPossibleTargetScore, 8);
	}
	else {
		augmentTargetRating = -1;
		Format(targetEffects, 64, "-1");
		SetArrayString(myAugmentTargetEffects[client], size, "-1");
		SetArrayCell(myAugmentInfo[client], size, -1, 8);
	}
	SetArrayCell(myAugmentInfo[client], size, augmentTargetRating, 5);
	char augmentStrengthText[64];
	if (augmentActivatorRating == -1 && augmentTargetRating == -1) {
		Format(augmentStrengthText, 64, "{B}Minor");
	}
	else {
		char majorname[64];
		char perfectname[64];
		GetAugmentSurname(client, size, majorname, sizeof(majorname), perfectname, sizeof(perfectname), false);
		if (!StrEqual(majorname, "-1")) Format(majorname, sizeof(majorname), "%t", majorname);
		if (!StrEqual(perfectname, "-1")) Format(perfectname, sizeof(perfectname), "%t", perfectname);
		if (!StrEqual(majorname, "-1") && !StrEqual(perfectname, "-1")) Format(augmentStrengthText, 64, "{B}Perfect {O}%s %s", majorname, perfectname);
		else if (!StrEqual(majorname, "-1")) Format(augmentStrengthText, 64, "{B}Major {O}%s", majorname);
		else Format(augmentStrengthText, 64, "{B}Major {O}%s", perfectname);
	}
	char name[64];
	GetClientName(client, name, sizeof(name));
	char text[512];
	Format(text, sizeof(text), "{B}%s {N}{OBTAINTYPE} a {B}+{OG}%3.1f{O}PCT %s {OG}%s {O}%s {B}augment", name, (augmentItemScore * fAugmentRatingMultiplier) * 100.0, augmentStrengthText, menuText, buffedCategory[len]);
	if (StrContains(ownerSteamID, key, false) != -1) ReplaceString(text, sizeof(text), "{OBTAINTYPE}", "found", true);
	else {
		ReplaceString(text, sizeof(text), "{OBTAINTYPE}", "stole", true);
		Format(text, sizeof(text), "%s {N}from {O}%s", text, ownerName);
	}
	ReplaceString(text, sizeof(text), "PCT", "%%", true);
	for (int i = 1; i <= MaxClients; i++) {
		if (!IsLegitimateClient(i) || IsFakeClient(i)) continue;
		Client_PrintToChat(i, true, text);
	}
	if (!StrEqual(serverKey, "-1")) Format(key, sizeof(key), "%s%s", serverKey, key);
	char tquery[512];
	Format(tquery, sizeof(tquery), "INSERT INTO `%s_loot` (`firstownername`, `firstowner`, `steam_id`, `itemid`, `rating`, `category`, `price`, `isforsale`, `isequipped`, `acteffects`, `actrating`, `tareffects`, `tarrating`, `maxscoreroll`, `maxactroll`, `maxtarroll`) VALUES ('%s', '%s', '%s', '%s', '%d', '%s', '%d', '%d', '%d', '%s', '%d', '%s', '%d', '%d', '%d', '%d');", TheDBPrefix, ownerName, ownerSteamID, key, sItemCode, augmentItemScore, buffedCategory, 0, 0, -1, activatorEffects, augmentActivatorRating, targetEffects, augmentTargetRating, maxpossibleroll, maxPossibleActivatorScore, maxPossibleTargetScore);
	SQL_TQuery(hDatabase, QueryResults, tquery);
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
		int totalUpgradesRequiredToUnlockNextLayer = RoundToCeil(totalNodesThisLayer * fUpgradesRequiredPerLayer);
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