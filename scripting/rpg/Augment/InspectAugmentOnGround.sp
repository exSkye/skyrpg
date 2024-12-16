stock bool InspectAugmentOnGround(client) {
	int entity = GetClientAimTarget(client, false);
    if (entity == -1) return false;

    float currentEngineTime = GetEngineTime();

    if (entity != lastLootGroundInspection[client]) {
        GetEntityClassname(entity, lastLootGroundClassname[client], sizeof(lastLootGroundClassname[]));
        if (!StrEqualAtPos(lastLootGroundClassname[client], "physics", 5)) return false;	// not a loot object
        GetEntPropString(entity, Prop_Data, "m_iName", lastLootGroundClassname[client], sizeof(lastLootGroundClassname[]));
        if (!StrBeginsWith(lastLootGroundClassname[client], "loot")) return false;		// not specifically loot (we will change this to allow types later, maybe)
    }   // prevents running the calculation too often.
    else if (lastLootGroundInspectionTime[client] > currentEngineTime) return false;
    // okay, so it's a loot object. Is the player close enough to pick it up?
    float myPos[3];
    GetEntPropVector(client, Prop_Send, "m_vecOrigin", myPos);
    float lootPos[3];
    GetEntPropVector(entity, Prop_Send, "m_vecOrigin", lootPos);
    if (GetVectorDistance(myPos, lootPos) > 64.0) return false;			// no.

    lastLootGroundInspectionTime[client] = currentEngineTime() + 2.0;
    lastLootGroundInspection[client] = entity;

	for (int i = 1; i <= MaxClients; i++) {
		if (!IsLegitimateClient(i)) continue;
		char key[64];
		GetClientAuthId(i, AuthId_Steam2, key, 64);
		// check if the owner (entity classname) is the player trying to pick it up (key)
		if (!StrEqualAtPos(lastLootGroundClassname[client], key, 5)) continue;
		lastLootGroundOwner[client] = i;
		break;
	}



    char splitClassname[2][64];
	ExplodeString(lastLootGroundClassname[client], "-", splitClassname, 2, 64);
	int lootBagPosition = thisAugmentArrayPos(lastLootGroundOwner[client], StringToInt(splitClassname[0][FindDelim(splitClassname[0], "+")]));
	if (lootBagPosition == -1) return false;

	int augmentActivatorRating = GetArrayCell(playerLootOnGround[lastLootGroundOwner[client]], lootBagPosition, 2);
	int augmentTargetRating = GetArrayCell(playerLootOnGround[lastLootGroundOwner[client]], lootBagPosition, 4);
	int itemScoreRoll = GetArrayCell(playerLootOnGround[lastLootGroundOwner[client]], lootBagPosition);
    int maxPossibleCategoryRoll = GetArrayCell(playerLootOnGround[lastLootGroundOwner[client]], lootBagPosition, 6);
    int maxPossibleActivatorScore = GetArrayCell(playerLootOnGround[lastLootGroundOwner[client]], lootBagPosition, 7);
    int maxPossibleTargetScore = GetArrayCell(playerLootOnGround[lastLootGroundOwner[client]], lootBagPosition, 8);
}

public Handle Inspect_Augment(client, slot) {
	AugmentClientIsInspecting[client] = slot;
	Handle menu = CreatePanel();
	char text[512];
	char augmentName[64];
	char augmentCategory[64], augmentActivator[64], augmentTarget[64];
	GetAugmentComparator(client, AugmentClientIsInspecting[client], augmentName, augmentCategory, augmentActivator, augmentTarget);
	char augmentOwner[64];
	GetArrayString(myAugmentOwners[client], slot, augmentOwner, sizeof(augmentOwner));
	char augmentOwnerName[64];
	GetArrayString(myAugmentOwnersName[client], slot, augmentOwnerName, sizeof(augmentOwnerName));
	char key[64];
	GetClientAuthId(client, AuthId_Steam2, key, sizeof(key));
	bool isNotOriginalOwner = (StrContains(augmentOwner, key, false) == -1) ? true : false;

	int isEquipped = GetArrayCell(myAugmentInfo[client], slot, 3);
	if (isEquipped == -2) Format(augmentName, sizeof(augmentName), "%s*", augmentName);
	if (isNotOriginalOwner) {
		Format(augmentName, sizeof(augmentName), "%s^", augmentName);
		LogMessage("Original owner: %s, current owner: %s", augmentOwner, key);
	}
	char scrap[64];
	AddCommasToString(augmentParts[client], scrap, 64);
	char augAvgLvl[64];
	AddCommasToString(playerCurrentAugmentAverageLevel[client], augAvgLvl, 64);
	Format(text, sizeof(text), "Avg Augment Lv. %s\nMaterials: %s\n \n%s\n%s", augAvgLvl, scrap, augmentName, augmentCategory);
	if (!StrEqual(augmentActivator, "-1")) Format(text, sizeof(text), "%s\n%s", text, augmentActivator);
	if (!StrEqual(augmentTarget, "-1")) Format(text, sizeof(text), "%s\n%s", text, augmentTarget);
	Format(text, sizeof(text), "%s\n \n", text);
	DrawPanelText(menu, text);
	int currentCategoryScoreRoll = GetArrayCell(myAugmentInfo[client], slot);
	int iThisAugmentLevel = currentCategoryScoreRoll / iAugmentLevelDivisor;
	char myAugLevelFormatted[10];
	AddCommasToString(iThisAugmentLevel, myAugLevelFormatted, sizeof(myAugLevelFormatted));
	Format(text, sizeof(text), "Augment Score: %s", myAugLevelFormatted);
	
	if (isNotOriginalOwner) {
		// client is not the original owner of this augment.
		Format(text, sizeof(text), "%s\nStolen From: %s", text, augmentOwnerName);
	}
	else Format(text, sizeof(text), "%s\nDiscovered By: You", text);
	Format(text, sizeof(text), "%s\n \n", text);

	char profilesThisAugmentIsSavedIn[512];
	GetArrayString(myAugmentSavedProfiles[client], slot, profilesThisAugmentIsSavedIn, sizeof(profilesThisAugmentIsSavedIn));
	if (StrEqual(profilesThisAugmentIsSavedIn, "none")) {
		Format(text, sizeof(text), "%s\nThis augment is not saved to any profiles.", text);
	}
	else Format(text, sizeof(text), "%s\nSaved to:\n%s", text, profilesThisAugmentIsSavedIn);
	Format(text, sizeof(text), "%s\n \n \n", text);

	DrawPanelText(menu, text);
	ClearArray(EquipAugmentPanel[client]);
	int thisClientMaxAugmentLevel = (playerCurrentAugmentAverageLevel[client] > 0) ? playerCurrentAugmentAverageLevel[client] + RoundToCeil(playerCurrentAugmentAverageLevel[client] * fAugmentLevelDifferenceForStolen) : 0;
	if (isEquipped < 0 && isNotOriginalOwner && thisClientMaxAugmentLevel < iThisAugmentLevel) {
		char maxAllowedLevel[10];
		AddCommasToString(thisClientMaxAugmentLevel, maxAllowedLevel, 10);
		Format(text, sizeof(text), "%T", "augment restricted", client, maxAllowedLevel);
		PushArrayString(EquipAugmentPanel[client], "req not met");
	}
	else {
		if (isEquipped < 0) {
			Format(text, sizeof(text), "%T", "equip augment", client);
			PushArrayString(EquipAugmentPanel[client], "equip augment");
		}
		else {
			Format(text, sizeof(text), "%T", "unequip augment", client);
			PushArrayString(EquipAugmentPanel[client], "unequip augment");
		}
	}
	DrawPanelItem(menu, text);
	if (isEquipped == -1) {
		if (itemToDisassemble[client] != AugmentClientIsInspecting[client]) Format(text, sizeof(text), "%T", "disassemble augment", client);
		else Format(text, sizeof(text), "%T", "confirm disassemble augment", client);
		PushArrayString(EquipAugmentPanel[client], "disassemble augment");
		DrawPanelItem(menu, text);
	}
	if (GetArraySize(myUnlockedCategories[client]) > 1) {
		Format(text, sizeof(text), "%T", "reroll augment", client);
		PushArrayString(EquipAugmentPanel[client], "reroll augment");
		DrawPanelItem(menu, text);
	}
	
	// only show the upgrade screen if all 3 categories aren't fully-upgraded
	// god help the soul that actually does this and blows through all those materials :rofl:
	if (currentCategoryScoreRoll < maxCategoryScoreRoll || currentActivatorScoreRoll > 0 && currentActivatorScoreRoll < maxActivatorScoreRoll || currentTargetScoreRoll > 0 && currentTargetScoreRoll < maxTargetScoreRoll) {
		char augmentNameCopy[64];
		char augmentCategoryName[64];
		char augmentActivatorName[64];
		char augmentTargetName[64];
		GetAugmentComparator(client, AugmentClientIsInspecting[client], augmentNameCopy, augmentCategoryName, augmentActivatorName, augmentTargetName, _, true);
		char pct[4];
		Format(pct, sizeof(pct), "%");
		Format(text, sizeof(text), "%T", "upgrade augment", client);
		PushArrayString(EquipAugmentPanel[client], "upgrade augment");
		DrawPanelItem(menu, text);
		if (currentCategoryScoreRoll < maxCategoryScoreRoll) {
			Format(text, sizeof(text), "%s: +%3.1f%s -> +%3.1f%s", augmentCategoryName, (currentCategoryScoreRoll * fAugmentRatingMultiplier) * 100.0, pct, (maxCategoryScoreRoll * fAugmentRatingMultiplier) * 100.0, pct);
			DrawPanelText(menu, text);
		}
		if (currentActivatorScoreRoll > 0 && currentActivatorScoreRoll < maxActivatorScoreRoll) {
			Format(text, sizeof(text), "%s: +%3.1f%s -> +%3.1f%s", augmentActivatorName, (currentActivatorScoreRoll * fAugmentActivatorRatingMultiplier) * 100.0, pct, (maxActivatorScoreRoll * fAugmentActivatorRatingMultiplier) * 100.0, pct);
			DrawPanelText(menu, text);
		}
		if (currentTargetScoreRoll > 0 && currentTargetScoreRoll < maxTargetScoreRoll) {
			Format(text, sizeof(text), "%s: +%3.1f%s -> +%3.1f%s", augmentTargetName, (currentTargetScoreRoll * fAugmentTargetRatingMultiplier) * 100.0, pct, (maxTargetScoreRoll * fAugmentTargetRatingMultiplier) * 100.0, pct);
			DrawPanelText(menu, text);
		}
		Format(text, sizeof(text), "\n \n");
		DrawPanelText(menu, text);
	}
	char isSavedText[512];
	GetArrayString(myAugmentSavedProfiles[client], AugmentClientIsInspecting[client], isSavedText, sizeof(isSavedText));
	bool isSaved = (StrEqual(isSavedText, "none")) ? false : true;
	if (isEquipped < 0 && !isSaved) {
		if (isEquipped == -1) {
			Format(text, sizeof(text), "%T", "lock augment", client);
			PushArrayString(EquipAugmentPanel[client], "lock augment");
		}
		else {
			Format(text, sizeof(text), "%T", "unlock augment", client);
			PushArrayString(EquipAugmentPanel[client], "unlock augment");
		}
		DrawPanelItem(menu, text);
	}
	PushArrayString(EquipAugmentPanel[client], "return");
	Format(text, sizeof(text), "%T", "return to talent menu", client);
	DrawPanelItem(menu, text);
	return menu;
}