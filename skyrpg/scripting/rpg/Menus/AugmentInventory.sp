stock int GetAugmentTranslation(client, char[] augmentCategory, char[] returnval) {

	int size = GetArraySize(a_Menu_Main);
	char result[64];
	int len = -1;
	for (int i = 0; i < size; i++) {
		GetAugmentTranslationKeys[client] = GetArrayCell(a_Menu_Main, i, 0);
		GetAugmentTranslationVals[client] = GetArrayCell(a_Menu_Main, i, 1);
		FormatKeyValue(result, 64, GetAugmentTranslationKeys[client], GetAugmentTranslationVals[client], "talent tree category?");
		if (StrContains(augmentCategory, result) == -1) continue;
		len = strlen(result);
		Format(returnval, 64, "%s", result);
		//GetAugmentTranslationVals[client] = GetArrayCell(a_Menu_Main, i, 2);
		//GetArrayString(GetAugmentTranslationVals[client], 0, returnval, 64);

		return len;
	}
	return -1;
}

public int GetAugmentPos(client, char[] itemCode) {
	int size = GetArraySize(myAugmentIDCodes[client]);
	char code[64];
	for (int i = 0; i < size; i++) {
		GetArrayString(myAugmentIDCodes[client], i, code, 64);
		if (!StrEqual(itemCode, code)) continue;
		return i;
	}
	return -1;
}

public Handle Augments_Equip(client) {
	Handle menu = CreatePanel();
	char text[512];
	char pct[4];
	Format(pct, 4, "%");
	char baseMenuText[64];
	char menuText[64];
	char activatorText[64];
	char targetText[64];
	char itemStr[64];
	char itemCode[64];
	if (GetArraySize(equippedAugmentsCategory[client]) != iNumAugments) ResizeArray(equippedAugmentsCategory[client], iNumAugments);
	if (GetArraySize(equippedAugmentsActivator[client]) != iNumAugments) ResizeArray(equippedAugmentsActivator[client], iNumAugments);
	if (GetArraySize(equippedAugmentsTarget[client]) != iNumAugments) ResizeArray(equippedAugmentsTarget[client], iNumAugments);
	for (int i = 0; i < iNumAugments; i++) {
		GetArrayString(equippedAugmentsCategory[client], i, baseMenuText, 64);
		int len = GetAugmentTranslation(client, baseMenuText, menuText);
		GetArrayString(equippedAugmentsIDCodes[client], i, itemCode, 64);
		int augmentPos = GetAugmentPos(client, itemCode);
		if (len == -1 || augmentPos == -1) {
			SetArrayCell(equippedAugments[client], i, 0);
			SetArrayCell(equippedAugments[client], i, 0, 4);
			SetArrayCell(equippedAugments[client], i, 0, 5);
			DrawPanelItem(menu, "<empty>");
			continue;
		}
		GetArrayString(equippedAugmentsActivator[client], i, activatorText, 64);
		GetArrayString(equippedAugmentsTarget[client], i, targetText, 64);
		Format(menuText, 64, "%T", menuText, client);
		int iItemLevel = GetArrayCell(equippedAugments[client], i, 2);

		int activatorRating = GetArrayCell(equippedAugments[client], i, 4);
		int targetRating = GetArrayCell(equippedAugments[client], i, 5);
		
		GetAugmentSurname(client, augmentPos, activatorText, 64, targetText, 64);
		if (activatorRating < 1 && targetRating < 1) Format(itemStr, 64, "Minor");
		else if (!StrEqual(activatorText, "-1") && !StrEqual(targetText, "-1")) Format(itemStr, 64, "Perfect %s %s", activatorText, targetText);
		else if (!StrEqual(activatorText, "-1")) Format(itemStr, 64, "Major %s", activatorText);
		else Format(itemStr, 64, "Major %s", targetText);

		Format(text, sizeof(text), "+%3.1f%s %s %s %s", (iItemLevel * fAugmentRatingMultiplier) * 100.0, pct, itemStr, menuText, baseMenuText[len]);
		DrawPanelItem(menu, text);
	}
	
	Format(text, sizeof(text), "%T", "return to talent menu", client);
	DrawPanelItem(menu, text);
	return menu;
}

public Augments_Equip_Init (Handle topmenu, MenuAction action, client, param2) {
	if (action == MenuAction_Select) {
		if (param2 > iNumAugments) {
			SendPanelToClientAndClose(Inspect_Augment(client, AugmentClientIsInspecting[client]), client, Inspect_Augment_Handle, MENU_TIME_FOREVER);
		}
		else {
			//char currentAugmentIDCode[64];
			//UnequipAugment_Confirm(client, currentAugmentIDCode);
			augmentSlotToEquipOn[client] = param2-1;

			char currentlyEquippedAugment[64];
			GetArrayString(equippedAugmentsIDCodes[client], augmentSlotToEquipOn[client], currentlyEquippedAugment, sizeof(currentlyEquippedAugment));
			if (StrEqual(currentlyEquippedAugment, "none")) {
				EquipAugment_Confirm(client, augmentSlotToEquipOn[client]);
				Augments_Inventory(client);
			}
			else SendPanelToClientAndClose(UnequipAugment_Compare(client), client, UnequipAugment_Compare_Init, MENU_TIME_FOREVER);
			//EquipAugment_Confirm(client, param2-1);

			//SendPanelToClientAndClose(Inspect_Augment(client, AugmentClientIsInspecting[client]), client, Inspect_Augment_Handle, MENU_TIME_FOREVER);
		}
		//CloseHandle(topmenu);
	}
	if (action == MenuAction_End) {

		CloseHandle(topmenu);
	}
}

public Handle UnequipAugment_Compare(int client) {
	Handle menu = CreatePanel();
	char pct[4];
	Format(pct, 4, "%");
	//augmentSlotToEquipOn[client] vs AugmentClientIsInspecting[client]
	char augmentName[64];
	char augmentCategory[64];
	char augmentActivator[128];
	char augmentTarget[128];
	GetAugmentComparator(client, augmentSlotToEquipOn[client], augmentName, augmentCategory, augmentActivator, augmentTarget, true);

	char text[512];
	DrawPanelText(menu, augmentName);
	DrawPanelText(menu, augmentCategory);
	if (!StrEqual(augmentActivator, "-1")) DrawPanelText(menu, augmentActivator);
	if (!StrEqual(augmentTarget, "-1")) DrawPanelText(menu, augmentTarget);
	int iEquippedAugmentLevel = GetArrayCell(myAugmentInfo[client], augmentSlotToEquipOn[client]) / iAugmentLevelDivisor;
	Format(text, sizeof(text), "Augment Score: %d\n \n", iEquippedAugmentLevel);
	Format(text, sizeof(text), "Replace above(equipped) augment with:");
	DrawPanelItem(menu, text);
	GetAugmentComparator(client, AugmentClientIsInspecting[client], augmentName, augmentCategory, augmentActivator, augmentTarget);
	DrawPanelText(menu, augmentName);
	DrawPanelText(menu, augmentCategory);
	if (!StrEqual(augmentActivator, "-1")) DrawPanelText(menu, augmentActivator);
	if (!StrEqual(augmentTarget, "-1")) DrawPanelText(menu, augmentTarget);
	int iInspectedAugmentLevel = GetArrayCell(myAugmentInfo[client], AugmentClientIsInspecting[client]) / iAugmentLevelDivisor;
	Format(text, sizeof(text), "Augment Score: %d\n \n", iInspectedAugmentLevel);
	Format(text, sizeof(text), "%T", "return to talent menu", client);
	DrawPanelItem(menu, text);
	
	return menu;
}

stock void GetAugmentBuff(int client, int slot, char[] buffName, int buff = 0, bool isAugmentEquipped = false) {
	if (isAugmentEquipped) {
		if (buff == 0) GetArrayString(equippedAugmentsCategory[client], slot, buffName, 64);
		else if (buff == 1) GetArrayString(equippedAugmentsActivator[client], slot, buffName, 64);
		else if (buff == 2) GetArrayString(equippedAugmentsTarget[client], slot, buffName, 64);
	}
	else {
		if (buff == 0) GetArrayString(myAugmentCategories[client], slot, buffName, 64);
		else if (buff == 1) GetArrayString(myAugmentActivatorEffects[client], slot, buffName, 64);
		else if (buff == 2) GetArrayString(myAugmentTargetEffects[client], slot, buffName, 64);
	}
}

stock void GetAugmentStrength(int client, int slot, int type, char[] augmentStr) {
	char pct[4];
	Format(pct, 4, "%");
	int iItemLevel = 0;
	int activatorRating = -1;
	int targetRating = -1;
	activatorRating = GetArrayCell(myAugmentInfo[client], slot, 4);
	targetRating = GetArrayCell(myAugmentInfo[client], slot, 5);
	iItemLevel = GetArrayCell(myAugmentInfo[client], slot);
	if (type == 0) Format(augmentStr, 64, "+%3.1f%s", (iItemLevel * fAugmentRatingMultiplier) * 100.0, pct);
	else if (type == 1) Format(augmentStr, 64, "+%3.1f%s", (activatorRating * fAugmentActivatorRatingMultiplier) * 100.0, pct);
	else if (type == 2) Format(augmentStr, 64, "+%3.1f%s", (targetRating * fAugmentTargetRatingMultiplier) * 100.0, pct);
}

stock void GetAugmentComparator(int client, int slot, char[] augmentName, char[] augmentCategory, char[] augmentActivator, char[] augmentTarget, bool isAugmentEquipped = false, bool justGetTalentName = false, bool replaceStr = false) {
	char text[512];
	char pct[4];
	Format(pct, 4, "%");
	char baseMenuText[64];
	char menuText[64];
	char activatorText[64];
	char targetText[64];

	int iItemLevel = 0;
	int activatorRating = -1;
	int targetRating = -1;
	if (isAugmentEquipped && slot >= GetArraySize(equippedAugments[client]) ||
		!isAugmentEquipped && slot >= GetArraySize(myAugmentInfo[client])) {
		// they cleared or something
		BuildMenu(client);
		return;
	}

	if (isAugmentEquipped) {
		iItemLevel = GetArrayCell(equippedAugments[client], slot, 2);
		GetArrayString(equippedAugmentsCategory[client], slot, baseMenuText, 64);
		GetArrayString(equippedAugmentsActivator[client], slot, activatorText, 64);
		activatorRating = GetArrayCell(equippedAugments[client], slot, 4);
		GetArrayString(equippedAugmentsTarget[client], slot, targetText, 64);
		targetRating = GetArrayCell(equippedAugments[client], slot, 5);
	}
	else {
		activatorRating = GetArrayCell(myAugmentInfo[client], slot, 4);
		targetRating = GetArrayCell(myAugmentInfo[client], slot, 5);
		iItemLevel = GetArrayCell(myAugmentInfo[client], slot);
		GetArrayString(myAugmentCategories[client], slot, baseMenuText, 64);
		GetArrayString(myAugmentActivatorEffects[client], slot, activatorText, 64);
		GetArrayString(myAugmentTargetEffects[client], slot, targetText, 64);
	}

	int len = GetAugmentTranslation(client, baseMenuText, menuText);
	Format(menuText, 64, "%T", menuText, client);

	char itemStr[64];
	char actText[64];
	char tarText[64];
	GetAugmentSurname(client, slot, actText, 64, tarText, 64);

	if (activatorRating < 1 && targetRating < 1) Format(itemStr, 64, "Minor");
	else if (!StrEqual(actText, "-1") && !StrEqual(tarText, "-1")) Format(itemStr, 64, "Perfect %s %s", actText, tarText);
	else if (!StrEqual(actText, "-1")) Format(itemStr, 64, "Major %s", actText);
	else Format(itemStr, 64, "Major %s", tarText);
	Format(text, sizeof(text), "%s %s %s Augment", itemStr, menuText, baseMenuText[len]);
	Format(augmentName, 64, "%s", text);
	if (justGetTalentName) Format(augmentCategory, 64, "%s %s", menuText, baseMenuText[len]);
	else {
		if (!replaceStr) Format(text, sizeof(text), "\n\t+%3.1f%s to %s %s talents", (iItemLevel * fAugmentRatingMultiplier) * 100.0, pct, menuText, baseMenuText[len]);
		else Format(text, sizeof(text), "\n\t+%3.1f{PCT} to %s %s talents", (iItemLevel * fAugmentRatingMultiplier) * 100.0, menuText, baseMenuText[len]);
		Format(augmentCategory, 64, "%s", text);
	}
	
	if (activatorRating > 0) {
		Format(activatorText, 64, "%s augment info", activatorText);
		Format(activatorText, 64, "%T", activatorText, client);
		if (justGetTalentName) Format(augmentActivator, 128, "%s", activatorText);
		else {
			if (!replaceStr) Format(text, sizeof(text), "\t\t+%3.1f%s to %s talents", (activatorRating * fAugmentActivatorRatingMultiplier) * 100.0, pct, activatorText);
			else Format(text, sizeof(text), "\t\t+%3.1f{PCT} to %s talents", (activatorRating * fAugmentActivatorRatingMultiplier) * 100.0, activatorText);
			Format(augmentActivator, 128, "%s", text);
		}
	}
	else Format(augmentActivator, 128, "-1");
	
	if (targetRating > 0) {
		Format(targetText, 64, "%s augment info", targetText);
		Format(targetText, 64, "%T", targetText, client);
		if (justGetTalentName) Format(augmentTarget, 128, "%s", targetText);
		else {
			if (!replaceStr) Format(text, sizeof(text), "\t\t+%3.1f%s to %s talents", (targetRating * fAugmentTargetRatingMultiplier) * 100.0, pct, targetText);
			else Format(text, sizeof(text), "\t\t+%3.1f{PCT} to %s talents", (targetRating * fAugmentTargetRatingMultiplier) * 100.0, targetText);
			Format(augmentTarget, 128, "%s", text);
		}
	}
	else Format(augmentTarget, 128, "-1");
}

public UnequipAugment_Compare_Init(Handle topmenu, MenuAction action, client, param2) {
	if (action == MenuAction_Select) {
		switch (param2) {
			case 1: {
				char currentlyEquippedAugment[64];
				GetArrayString(equippedAugmentsIDCodes[client], augmentSlotToEquipOn[client], currentlyEquippedAugment, sizeof(currentlyEquippedAugment));
				UnequipAugment_Confirm(client, currentlyEquippedAugment);
				EquipAugment_Confirm(client, augmentSlotToEquipOn[client]);
				augmentSlotToEquipOn[client] = -1;
				Augments_Inventory(client);
			}
			case 2: {
				SendPanelToClientAndClose(Augments_Equip(client), client, Augments_Equip_Init, MENU_TIME_FOREVER);
			}
		}
	}
	if (action == MenuAction_End) CloseHandle(topmenu);
}

stock bool UnequipAugment_Confirm(client, char[] augmentID) {
	int size = GetArraySize(myAugmentIDCodes[client]);
	char text[512];
	for (int i = 0; i < size; i++) {
		GetArrayString(myAugmentIDCodes[client], i, text, sizeof(text));
		if (!StrEqual(text, augmentID)) continue;
		GetArrayString(myAugmentSavedProfiles[client], i, text, sizeof(text));
		bool isSaved = (StrEqual(text, "none")) ? true : false;
		if (!isSaved) SetArrayCell(myAugmentInfo[client], i, -1, 3);
		else SetArrayCell(myAugmentInfo[client], i, -3, 3);

		char sql[512];
		Format(sql, sizeof(sql), "UPDATE `%s_loot` SET `isequipped` = '%d' WHERE (`itemid` = '%s');", TheDBPrefix, ((!isSaved) ? -1 : -3), augmentID);
 		SQL_TQuery(hDatabase, QueryResults, sql, client);

		return true;
	}
	return false;
}

stock EquipAugment_Confirm(int client, int pos, int augmentInspectionOverride = -1) {
	int augmentPos = (augmentInspectionOverride == -1) ? AugmentClientIsInspecting[client] : augmentInspectionOverride;
	// there's a lot of augment data that needs to be stored in the equipped augment arrays.
	char baseMenuText[64];
	char activatorText[64];
	char targetText[64];
	GetArrayString(myAugmentCategories[client], augmentPos, baseMenuText, 64);
	GetArrayString(myAugmentActivatorEffects[client], augmentPos, activatorText, 64);
	GetArrayString(myAugmentTargetEffects[client], augmentPos, targetText, 64);
	int itemRating = GetArrayCell(myAugmentInfo[client], augmentPos);
	int activatorRating = GetArrayCell(myAugmentInfo[client], augmentPos, 4);
	int targetRating = GetArrayCell(myAugmentInfo[client], augmentPos, 5);
	//int isEquipped = GetArrayCell(myAugmentInfo[client], AugmentClientIsInspecting[client], 3);
	int itemCost = GetArrayCell(myAugmentInfo[client], augmentPos, 1);
	int iItemLevel = GetArrayCell(myAugmentInfo[client], augmentPos);


	SetArrayCell(myAugmentInfo[client], augmentPos, pos, 3);
	
	char itemCode[64];
	GetArrayString(myAugmentIDCodes[client], augmentPos, itemCode, 64);
	SetArrayString(equippedAugmentsIDCodes[client], pos, itemCode);

	char sql[512];
	Format(sql, sizeof(sql), "UPDATE `%s_loot` SET `isequipped` = '%d' WHERE (`itemid` = '%s');", TheDBPrefix, pos, itemCode);
	SQL_TQuery(hDatabase, QueryResults, sql, client);

	SetArrayCell(equippedAugments[client], pos, iItemLevel);
	SetArrayCell(equippedAugments[client], pos, itemCost, 1);
	SetArrayCell(equippedAugments[client], pos, itemRating, 2);
	SetArrayString(equippedAugmentsCategory[client], pos, baseMenuText);
	SetArrayString(equippedAugmentsActivator[client], pos, activatorText);
	SetArrayCell(equippedAugments[client], pos, activatorRating, 4);
	SetArrayString(equippedAugmentsTarget[client], pos, targetText);
	SetArrayCell(equippedAugments[client], pos, targetRating, 5);
	SetClientTalentStrength(client);	// talent strengths need to be updated when an augment is equipped or unequipped.
	FormatPlayerName(client);
}

stock void GetAugmentSurname(int client, int pos, char[] surname, int surnameSize, char[] surname2, int surname2Size, bool bFormatTranslation = true) {
	GetArrayString(myAugmentActivatorEffects[client], pos, surname, surnameSize);
	if (!StrEqual(surname, "-1")) {
		Format(surname, surnameSize, "%s major surname", surname);
		if (bFormatTranslation) Format(surname, surnameSize, "%T", surname, client);
	}
	GetArrayString(myAugmentTargetEffects[client], pos, surname2, surname2Size);
	if (!StrEqual(surname2, "-1")) {
		Format(surname2, surname2Size, "%s perfect surname", surname2);
		if (bFormatTranslation) Format(surname2, surname2Size, "%T", surname2, client);
	}
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
	Format(text, sizeof(text), "Avg Augment Lv. %s\nScrap: %s\n \n%s\n%s", augAvgLvl, scrap, augmentName, augmentCategory);
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
	int currentActivatorScoreRoll = GetArrayCell(myAugmentInfo[client], slot, 4);
	int currentTargetScoreRoll = GetArrayCell(myAugmentInfo[client], slot, 5);
	int maxCategoryScoreRoll = GetArrayCell(myAugmentInfo[client], slot, 6);
	int maxActivatorScoreRoll = GetArrayCell(myAugmentInfo[client], slot, 7);
	int maxTargetScoreRoll = GetArrayCell(myAugmentInfo[client], slot, 8);
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

public Inspect_Augment_Handle (Handle topmenu, MenuAction action, client, param2) {
	if (action == MenuAction_Select) {
		//int isItemForSale = GetArrayCell(myAugmentInfo[client], AugmentClientIsInspecting[client], 2);
		int isEquipped = GetArrayCell(myAugmentInfo[client], AugmentClientIsInspecting[client], 3);
		char tquery[512];
		char itemCode[64];
		GetArrayString(myAugmentIDCodes[client], AugmentClientIsInspecting[client], itemCode, 64);
		char sql[512];
		char menuSelection[64];
		if (param2-1 >= GetArraySize(EquipAugmentPanel[client])) {
			SendPanelToClientAndClose(Inspect_Augment(client, AugmentClientIsInspecting[client]), client, Inspect_Augment_Handle, MENU_TIME_FOREVER);
			return;
		}
		char text[512];
		GetArrayString(myAugmentSavedProfiles[client], AugmentClientIsInspecting[client], text, sizeof(text));
		bool isSaved = (StrEqual(text, "none")) ? false : true;
		
		GetArrayString(EquipAugmentPanel[client], param2-1, menuSelection, sizeof(menuSelection));
		if (StrEqual(menuSelection, "req not met")) {
			SendPanelToClientAndClose(Inspect_Augment(client, AugmentClientIsInspecting[client]), client, Inspect_Augment_Handle, MENU_TIME_FOREVER);
		}
		else if (StrEqual(menuSelection, "upgrade augment")) {
			// until this is built, we just send the user back to the inspect page.
			// i want to make sure it's tracking this data properly first.
			SendPanelToClientAndClose(Upgrade_Augment(client), client, Upgrade_Augment_Handle, MENU_TIME_FOREVER);
		}
		else if (StrEqual(menuSelection, "equip augment")) SendPanelToClientAndClose(Augments_Equip(client), client, Augments_Equip_Init, MENU_TIME_FOREVER);
		else if (StrEqual(menuSelection, "unequip augment")) {
			Format(sql, sizeof(sql), "UPDATE `%s_loot` SET `isequipped` = '%d' WHERE (`itemid` = '%s');", TheDBPrefix, ((!isSaved) ? -1 : -3), itemCode);
			SQL_TQuery(hDatabase, QueryResults, sql, client);

			if (!isSaved) SetArrayCell(myAugmentInfo[client], AugmentClientIsInspecting[client], -1, 3);
			else SetArrayCell(myAugmentInfo[client], AugmentClientIsInspecting[client], -3, 3);
			
			SetArrayString(equippedAugmentsIDCodes[client], isEquipped, "none");
			SetArrayCell(equippedAugments[client], isEquipped, -1);
			SetArrayCell(equippedAugments[client], isEquipped, -1, 1);
			SetArrayCell(equippedAugments[client], isEquipped, -1, 2);
			SetArrayString(equippedAugmentsCategory[client], isEquipped, "");

			SetArrayString(equippedAugmentsActivator[client], isEquipped, "");
			SetArrayCell(equippedAugments[client], isEquipped, -1, 4);

			SetArrayString(equippedAugmentsTarget[client], isEquipped, "");
			SetArrayCell(equippedAugments[client], isEquipped, -1, 5);
			SetClientTalentStrength(client);	// talent strengths need to be updated when an augment is equipped or unequipped.
			FormatPlayerName(client);

			SendPanelToClientAndClose(Inspect_Augment(client, AugmentClientIsInspecting[client]), client, Inspect_Augment_Handle, MENU_TIME_FOREVER);
		}
		else if (StrEqual(menuSelection, "disassemble augment")) {
			if (itemToDisassemble[client] == AugmentClientIsInspecting[client]) {
				itemToDisassemble[client] = -1;	// to ensure the next augment in the list is not targeted for disassembly
				augmentParts[client]++;
				Format(tquery, sizeof(tquery), "DELETE FROM `%s_loot` WHERE `itemid` = '%s';", TheDBPrefix, itemCode);
				SQL_TQuery(hDatabase, QueryResults, tquery, client);
				RemoveFromArray(myAugmentIDCodes[client], AugmentClientIsInspecting[client]);
				RemoveFromArray(myAugmentCategories[client], AugmentClientIsInspecting[client]);
				RemoveFromArray(myAugmentOwners[client], AugmentClientIsInspecting[client]);
				RemoveFromArray(myAugmentInfo[client], AugmentClientIsInspecting[client]);
				RemoveFromArray(myAugmentTargetEffects[client], AugmentClientIsInspecting[client]);
				RemoveFromArray(myAugmentActivatorEffects[client], AugmentClientIsInspecting[client]);
				RemoveFromArray(myAugmentSavedProfiles[client], AugmentClientIsInspecting[client]);
				if (GetArraySize(myAugmentIDCodes[client]) > 0) Augments_Inventory(client);
				else BuildMenu(client);
			}
			else {
				itemToDisassemble[client] = AugmentClientIsInspecting[client];
				SendPanelToClientAndClose(Inspect_Augment(client, AugmentClientIsInspecting[client]), client, Inspect_Augment_Handle, MENU_TIME_FOREVER);
			}
		}
		else if (StrEqual(menuSelection, "reroll augment")) SendPanelToClientAndClose(Reroll_Augment(client), client, Reroll_Augment_Handle, MENU_TIME_FOREVER);
		else if (StrEqual(menuSelection, "lock augment")) {
			Format(sql, sizeof(sql), "UPDATE `%s_loot` SET `isequipped` = '-2' WHERE (`itemid` = '%s');", TheDBPrefix, itemCode);
			SQL_TQuery(hDatabase, QueryResults, sql, client);
			SetArrayCell(myAugmentInfo[client], AugmentClientIsInspecting[client], -2, 3);
			SendPanelToClientAndClose(Inspect_Augment(client, AugmentClientIsInspecting[client]), client, Inspect_Augment_Handle, MENU_TIME_FOREVER);
		}
		else if (StrEqual(menuSelection, "unlock augment")) {			
			Format(sql, sizeof(sql), "UPDATE `%s_loot` SET `isequipped` = '%d' WHERE (`itemid` = '%s');", TheDBPrefix, ((!isSaved) ? -1 : -3), itemCode);
			SQL_TQuery(hDatabase, QueryResults, sql, client);
			if (!isSaved) SetArrayCell(myAugmentInfo[client], AugmentClientIsInspecting[client], -1, 3);
			else SetArrayCell(myAugmentInfo[client], AugmentClientIsInspecting[client], -3, 3);
			SendPanelToClientAndClose(Inspect_Augment(client, AugmentClientIsInspecting[client]), client, Inspect_Augment_Handle, MENU_TIME_FOREVER);
		}
		else if (StrEqual(menuSelection, "return")) Augments_Inventory(client);
	}
}

stock void Reroll_Augment_Pay(int client) {
	int type = augmentRerollBuffType[client];
	int pos = augmentRerollBuffPos[client];
	Handle menu = CreateMenu(Reroll_Augment_Pay_Handle);

	char augmentName[64];
	char augmentCategory[64], augmentCategoryName[64];
	char augmentActivator[64], augmentActivatorName[64];
	char augmentTarget[64], augmentTargetName[64];
	GetAugmentComparator(client, AugmentClientIsInspecting[client], augmentName, augmentCategory, augmentActivator, augmentTarget, _, _, true);
	GetAugmentComparator(client, AugmentClientIsInspecting[client], augmentName, augmentCategoryName, augmentActivatorName, augmentTargetName, _, true);
	char text[512];
	char scrap[64];
	AddCommasToString(augmentParts[client], scrap, 64);

	Format(text, sizeof(text), "Scrap: %s\n \n%s\n%s", scrap, augmentName, augmentCategory);
	if (!StrEqual(augmentActivator, "-1")) Format(text, sizeof(text), "%s\n%s", text, augmentActivator);
	if (!StrEqual(augmentTarget, "-1")) Format(text, sizeof(text), "%s\n%s", text, augmentTarget);

	char buff[64];
	char searchBuff[64];
	if (type == 0) GetArrayString(myUnlockedCategories[client], pos, searchBuff, 64);
	else if (type == 1) GetArrayString(myUnlockedActivators[client], pos, searchBuff, 64);
	else if (type == 2) GetArrayString(myUnlockedTargets[client], pos, searchBuff, 64);
	if (type == 0) {
		int len = GetAugmentTranslation(client, searchBuff, buff);
		Format(buff, 64, "%T", buff, client);
		Format(buff, 64, "%s %s", buff, searchBuff[len]);
	}
	else {
		Format(buff, 64, "%s augment info", searchBuff);
		Format(buff, 64, "%T", buff, client);
	}

	Format(text, sizeof(text), "%s\n \nReplace [ %s ] with [ %s ] ?", text, ((type == 0) ? augmentCategoryName : (type == 1) ? augmentActivatorName : augmentTargetName), buff);
	ReplaceString(text, sizeof(text), "{PCT}", "%%", true);
	SetMenuTitle(menu, text);
	Format(text, sizeof(text), "Confirm Reroll for %d Scrap", ((type == 0) ? iAugmentCategoryRerollCost : (type == 1) ? iAugmentActivatorRerollCost : iAugmentTargetRerollCost));
	AddMenuItem(menu, text, text);

	SetMenuExitBackButton(menu, true);
	DisplayMenu(menu, client, 0);
}

public Reroll_Augment_Pay_Handle(Handle menu, MenuAction action, client, slot) {
	if (action == MenuAction_Select) {
		int type = augmentRerollBuffType[client];
		int pos = augmentRerollBuffPos[client];

		char buff[64];
		char tquery[512];
		char sItemCode[512];
		GetArrayString(myAugmentIDCodes[client], AugmentClientIsInspecting[client], sItemCode, sizeof(sItemCode));
		int isEquipped = GetArrayCell(myAugmentInfo[client], AugmentClientIsInspecting[client], 3);
		bool isEligible = false;
		if (type == 0 && augmentParts[client] >= iAugmentCategoryRerollCost) {
			isEligible = true;
			GetArrayString(myUnlockedCategories[client], pos, buff, 64);
			SetArrayString(myAugmentCategories[client], AugmentClientIsInspecting[client], buff);
			Format(tquery, sizeof(tquery), "UPDATE `%s_loot` SET `category` = '%s' WHERE (`itemid` = '%s');", TheDBPrefix, buff, sItemCode);
			augmentParts[client] -= iAugmentCategoryRerollCost;
		}
		else if (type == 1 && augmentParts[client] >= iAugmentActivatorRerollCost) {
			isEligible = true;
			GetArrayString(myUnlockedActivators[client], pos, buff, 64);
			SetArrayString(myAugmentActivatorEffects[client], AugmentClientIsInspecting[client], buff);
			Format(tquery, sizeof(tquery), "UPDATE `%s_loot` SET `acteffects` = '%s' WHERE (`itemid` = '%s');", TheDBPrefix, buff, sItemCode);
			augmentParts[client] -= iAugmentActivatorRerollCost;
		}
		else if (type == 2 && augmentParts[client] >= iAugmentTargetRerollCost) {
			isEligible = true;
			GetArrayString(myUnlockedTargets[client], pos, buff, 64);
			SetArrayString(myAugmentTargetEffects[client], AugmentClientIsInspecting[client], buff);
			Format(tquery, sizeof(tquery), "UPDATE `%s_loot` SET `tareffects` = '%s' WHERE (`itemid` = '%s');", TheDBPrefix, buff, sItemCode);
			augmentParts[client] -= iAugmentTargetRerollCost;
		}
		if (isEligible) {
			SQL_TQuery(hDatabase, QueryResults, tquery);
			if (isEquipped >= 0) {
				UnequipAugment_Confirm(client, sItemCode);
				EquipAugment_Confirm(client, isEquipped);
			}
			SendPanelToClientAndClose(Inspect_Augment(client, AugmentClientIsInspecting[client]), client, Inspect_Augment_Handle, MENU_TIME_FOREVER);
		}
		else Reroll_Augment_Pay(client);
	}
	else if (action == MenuAction_Cancel) {
		if (slot == MenuCancel_ExitBack) Reroll_Augment_Confirm(client, augmentRerollBuffType[client]);
	}
	if (action == MenuAction_End) CloseHandle(menu);
}

stock void Reroll_Augment_Confirm(int client, int type) {
	augmentRerollBuffType[client] = type;
	Handle menu = CreateMenu(Reroll_Augment_Confirm_Handle);

	char augmentName[64];
	char augmentCategory[64], augmentCategoryName[64];
	char augmentActivator[64], augmentActivatorName[64];
	char augmentTarget[64], augmentTargetName[64];
	GetAugmentComparator(client, AugmentClientIsInspecting[client], augmentName, augmentCategory, augmentActivator, augmentTarget, _, _, true);
	GetAugmentComparator(client, AugmentClientIsInspecting[client], augmentName, augmentCategoryName, augmentActivatorName, augmentTargetName, _, true);
	char text[512];
	char scrap[64];
	AddCommasToString(augmentParts[client], scrap, 64);
	Format(text, sizeof(text), "Scrap: %s\n \n%s\n%s", scrap, augmentName, augmentCategory);
	if (!StrEqual(augmentActivator, "-1")) Format(text, sizeof(text), "%s\n%s", text, augmentActivator);
	if (!StrEqual(augmentTarget, "-1")) Format(text, sizeof(text), "%s\n%s", text, augmentTarget);
	Format(text, sizeof(text), "%s\n \nSelect a category to replace %s\n", text, ((type == 0) ? augmentCategoryName : (type == 1) ? augmentActivatorName : augmentTargetName));
	ReplaceString(text, sizeof(text), "{PCT}", "%%", true);
	SetMenuTitle(menu, text);

	char buff[64];
	int size = GetArraySize(myUnlockedCategories[client]);
	if (type == 1) size = GetArraySize(myUnlockedActivators[client]);
	else if (type == 2) size = GetArraySize(myUnlockedTargets[client]);
	GetAugmentBuff(client, AugmentClientIsInspecting[client], buff, type);
	for (int i = 0; i < size; i++) {
		char searchBuff[64];
		if (type == 0) GetArrayString(myUnlockedCategories[client], i, searchBuff, 64);
		else if (type == 1) GetArrayString(myUnlockedActivators[client], i, searchBuff, 64);
		else if (type == 2) GetArrayString(myUnlockedTargets[client], i, searchBuff, 64);
		if (StrEqual(buff, searchBuff)) {
			augmentRerollBuffPosToSkip[client] = i;
			continue;
		}
		if (type == 0) {
			int len = GetAugmentTranslation(client, searchBuff, text);
			Format(text, 64, "%T", text, client);
			Format(text, 64, "%s %s", text, searchBuff[len]);
		}
		else {
			Format(text, 64, "%s augment info", searchBuff);
			Format(text, 64, "%T", text, client);
		}
		AddMenuItem(menu, text, text);
	}
	SetMenuExitBackButton(menu, true);
	DisplayMenu(menu, client, 0);
}

public Reroll_Augment_Confirm_Handle(Handle menu, MenuAction action, client, slot) {
	if (action == MenuAction_Select) {
		augmentRerollBuffPos[client] = (slot >= augmentRerollBuffPosToSkip[client]) ? slot + 1 : slot;
		Reroll_Augment_Pay(client);
	}
	else if (action == MenuAction_Cancel) {
		if (slot == MenuCancel_ExitBack) SendPanelToClientAndClose(Reroll_Augment(client), client, Reroll_Augment_Handle, MENU_TIME_FOREVER);
	}
	if (action == MenuAction_End) CloseHandle(menu);
}

public Handle Reroll_Augment(client) {
	Handle menu = CreatePanel();
	char augmentName[64];
	char augmentCategory[64], augmentCategoryName[64];
	char augmentActivator[64], augmentActivatorName[64];
	char augmentTarget[64], augmentTargetName[64];
	GetAugmentComparator(client, AugmentClientIsInspecting[client], augmentName, augmentCategory, augmentActivator, augmentTarget);
	GetAugmentComparator(client, AugmentClientIsInspecting[client], augmentName, augmentCategoryName, augmentActivatorName, augmentTargetName, _, true); 
	char text[512];
	char scrap[64];
	AddCommasToString(augmentParts[client], scrap, 64);
	Format(text, sizeof(text), "Scrap: %s\n \n", scrap);
	DrawPanelText(menu, text);

	DrawPanelText(menu, augmentName);
	DrawPanelText(menu, augmentCategory);
	if (!StrEqual(augmentActivator, "-1")) DrawPanelText(menu, augmentActivator);
	if (!StrEqual(augmentTarget, "-1")) DrawPanelText(menu, augmentTarget);
	DrawPanelText(menu, "\n \n");
	Format(text, sizeof(text), "(%d scrap) Reroll %s", iAugmentCategoryRerollCost, augmentCategoryName);
	DrawPanelItem(menu, text);

	if (!StrEqual(augmentActivator, "-1") && GetArraySize(myUnlockedActivators[client]) > 1) {
		Format(text, sizeof(text), "(%d scrap) Reroll %s", iAugmentActivatorRerollCost, augmentActivatorName);
		DrawPanelItem(menu, text);
	}
	if (!StrEqual(augmentTarget, "-1") && GetArraySize(myUnlockedTargets[client]) > 1) {
		Format(text, sizeof(text), "(%d scrap) Reroll %s", iAugmentTargetRerollCost, augmentTargetName);
		DrawPanelItem(menu, text);
	}
	Format(text, sizeof(text), "%T", "return to talent menu", client);
	DrawPanelItem(menu, text);
	return menu;
}

public Reroll_Augment_Handle (Handle topmenu, MenuAction action, client, param2) {
	char augmentName[64], augmentCategory[64], augmentActivator[64], augmentTarget[64];
	GetAugmentComparator(client, AugmentClientIsInspecting[client], augmentName, augmentCategory, augmentActivator, augmentTarget);
	if (action == MenuAction_Select) {
		switch (param2) {
			case 1:
				Reroll_Augment_Confirm(client, 0);
			case 2:
				if (!StrEqual(augmentActivator, "-1") && GetArraySize(myUnlockedActivators[client]) > 1) Reroll_Augment_Confirm(client, 1);
				else if (!StrEqual(augmentTarget, "-1") && GetArraySize(myUnlockedTargets[client]) > 1) Reroll_Augment_Confirm(client, 2);
				else SendPanelToClientAndClose(Inspect_Augment(client, AugmentClientIsInspecting[client]), client, Inspect_Augment_Handle, MENU_TIME_FOREVER);
			case 3:
				if (!StrEqual(augmentActivator, "-1") && !StrEqual(augmentTarget, "-1") && GetArraySize(myUnlockedTargets[client]) > 1) Reroll_Augment_Confirm(client, 2);
				else SendPanelToClientAndClose(Inspect_Augment(client, AugmentClientIsInspecting[client]), client, Inspect_Augment_Handle, MENU_TIME_FOREVER);
			case 4:
				SendPanelToClientAndClose(Inspect_Augment(client, AugmentClientIsInspecting[client]), client, Inspect_Augment_Handle, MENU_TIME_FOREVER);
		}
	}
}

public Handle Upgrade_Augment(client) {
	ClearArray(EquipAugmentPanel[client]);
	Handle menu = CreatePanel();
	char augmentName[64];
	char augmentCategory[64], augmentCategoryName[64];
	char augmentActivator[64], augmentActivatorName[64];
	char augmentTarget[64], augmentTargetName[64];
	GetAugmentComparator(client, AugmentClientIsInspecting[client], augmentName, augmentCategory, augmentActivator, augmentTarget);
	GetAugmentComparator(client, AugmentClientIsInspecting[client], augmentName, augmentCategoryName, augmentActivatorName, augmentTargetName, _, true);
	char text[512];
	char scrap[64];
	AddCommasToString(augmentParts[client], scrap, 64);
	Format(text, sizeof(text), "Scrap: %s\n \n", scrap);
	DrawPanelText(menu, text);

	DrawPanelText(menu, augmentName);
	DrawPanelText(menu, augmentCategory);
	if (!StrEqual(augmentActivator, "-1")) DrawPanelText(menu, augmentActivator);
	if (!StrEqual(augmentTarget, "-1")) DrawPanelText(menu, augmentTarget);
	DrawPanelText(menu, "\n \n");

	int currentCategoryScoreRoll = GetArrayCell(myAugmentInfo[client], AugmentClientIsInspecting[client]);
	int currentActivatorScoreRoll = GetArrayCell(myAugmentInfo[client], AugmentClientIsInspecting[client], 4);
	int currentTargetScoreRoll = GetArrayCell(myAugmentInfo[client], AugmentClientIsInspecting[client], 5);
	int maxCategoryScoreRoll = GetArrayCell(myAugmentInfo[client], AugmentClientIsInspecting[client], 6);
	int maxActivatorScoreRoll = GetArrayCell(myAugmentInfo[client], AugmentClientIsInspecting[client], 7);
	int maxTargetScoreRoll = GetArrayCell(myAugmentInfo[client], AugmentClientIsInspecting[client], 8);
	// only show the upgrade screen if all 3 categories aren't fully-upgraded
	// god help the soul that actually does this and blows through all those materials :rofl:
	if (currentCategoryScoreRoll < maxCategoryScoreRoll || currentActivatorScoreRoll > 0 && currentActivatorScoreRoll < maxActivatorScoreRoll || currentTargetScoreRoll > 0 && currentTargetScoreRoll < maxTargetScoreRoll) {
		char pct[4];
		Format(pct, sizeof(pct), "%");
		if (currentCategoryScoreRoll < maxCategoryScoreRoll) {
			Format(text, sizeof(text), "(%d scrap) Upgrade %s", iAugmentCategoryUpgradeCost, augmentCategoryName);
			DrawPanelItem(menu, text);
			Format(text, sizeof(text), "+%3.1f%s up to +%3.1f%s", ((currentCategoryScoreRoll + 1) * fAugmentRatingMultiplier) * 100.0, pct, (maxCategoryScoreRoll * fAugmentRatingMultiplier) * 100.0, pct);
			DrawPanelText(menu, text);
			PushArrayString(EquipAugmentPanel[client], "upgrade category");
		}
		if (currentActivatorScoreRoll > 0 && currentActivatorScoreRoll < maxActivatorScoreRoll) {
			Format(text, sizeof(text), "(%d scrap) Upgrade %s", iAugmentActivatorUpgradeCost, augmentActivatorName);
			DrawPanelItem(menu, text);
			Format(text, sizeof(text), "+%3.1f%s up to +%3.1f%s", ((currentActivatorScoreRoll + 1) * fAugmentActivatorRatingMultiplier) * 100.0, pct, (maxActivatorScoreRoll * fAugmentActivatorRatingMultiplier) * 100.0, pct);
			DrawPanelText(menu, text);
			PushArrayString(EquipAugmentPanel[client], "upgrade activator");
		}
		if (currentTargetScoreRoll > 0 && currentTargetScoreRoll < maxTargetScoreRoll) {
			Format(text, sizeof(text), "(%d scrap) Upgrade %s", iAugmentTargetUpgradeCost, augmentTargetName);
			DrawPanelItem(menu, text);
			Format(text, sizeof(text), "+%3.1f%s up to +%3.1f%s", ((currentTargetScoreRoll + 1) * fAugmentTargetRatingMultiplier) * 100.0, pct, (maxTargetScoreRoll * fAugmentTargetRatingMultiplier) * 100.0, pct);
			DrawPanelText(menu, text);
			PushArrayString(EquipAugmentPanel[client], "upgrade target");
		}
	}
	Format(text, sizeof(text), "%T", "return to talent menu", client);
	DrawPanelItem(menu, text);
	PushArrayString(EquipAugmentPanel[client], "menu return");
	return menu;
}

public Upgrade_Augment_Handle (Handle topmenu, MenuAction action, client, param2) {
	if (action == MenuAction_Select) {
		char menuSelection[64];
		if (param2-1 >= GetArraySize(EquipAugmentPanel[client])) {
			SendPanelToClientAndClose(Inspect_Augment(client, AugmentClientIsInspecting[client]), client, Inspect_Augment_Handle, MENU_TIME_FOREVER);
			return;
		}
		GetArrayString(EquipAugmentPanel[client], param2-1, menuSelection, sizeof(menuSelection));

		char sItemCode[512];
		GetArrayString(myAugmentIDCodes[client], AugmentClientIsInspecting[client], sItemCode, sizeof(sItemCode));
		int isEquipped = GetArrayCell(myAugmentInfo[client], AugmentClientIsInspecting[client], 3);
		bool bUpgradeHasOccurred = false;	// flag

		char tquery[512];

		if (StrEqual(menuSelection, "menu return")) {
			SendPanelToClientAndClose(Inspect_Augment(client, AugmentClientIsInspecting[client]), client, Inspect_Augment_Handle, MENU_TIME_FOREVER);
			return;
		}
		else if (StrEqual(menuSelection, "upgrade category")) {
			if (augmentParts[client] >= iAugmentCategoryUpgradeCost) {
				bUpgradeHasOccurred = true;
				augmentParts[client] -= iAugmentCategoryUpgradeCost;
				int currentCategoryScoreRoll = GetArrayCell(myAugmentInfo[client], AugmentClientIsInspecting[client]);
				int maxCategoryScoreRoll = GetArrayCell(myAugmentInfo[client], AugmentClientIsInspecting[client], 6);
				int catRoll = GetRandomInt(currentCategoryScoreRoll, maxCategoryScoreRoll);
				SetArrayCell(myAugmentInfo[client], AugmentClientIsInspecting[client], catRoll);
				Format(tquery, sizeof(tquery), "UPDATE `%s_loot` SET `rating` = '%d' WHERE (`itemid` = '%s');", TheDBPrefix, catRoll, sItemCode);
			}
		}
		else if (StrEqual(menuSelection, "upgrade activator")) {
			if (augmentParts[client] >= iAugmentActivatorUpgradeCost) {
				bUpgradeHasOccurred = true;
				augmentParts[client] -= iAugmentActivatorUpgradeCost;
				int currentActivatorScoreRoll = GetArrayCell(myAugmentInfo[client], AugmentClientIsInspecting[client], 4);
				int maxActivatorScoreRoll = GetArrayCell(myAugmentInfo[client], AugmentClientIsInspecting[client], 7);
				int actRoll = GetRandomInt(currentActivatorScoreRoll, maxActivatorScoreRoll);
				SetArrayCell(myAugmentInfo[client], AugmentClientIsInspecting[client], actRoll, 4);
				Format(tquery, sizeof(tquery), "UPDATE `%s_loot` SET `actrating` = '%d' WHERE (`itemid` = '%s');", TheDBPrefix, actRoll, sItemCode);
			}
		}
		else if (StrEqual(menuSelection, "upgrade target")) {
			if (augmentParts[client] >= iAugmentTargetUpgradeCost) {
				bUpgradeHasOccurred = true;
				augmentParts[client] -= iAugmentTargetUpgradeCost;
				int currentTargetScoreRoll = GetArrayCell(myAugmentInfo[client], AugmentClientIsInspecting[client], 5);
				int maxTargetScoreRoll = GetArrayCell(myAugmentInfo[client], AugmentClientIsInspecting[client], 8);
				int tarRoll = GetRandomInt(currentTargetScoreRoll, maxTargetScoreRoll);
				SetArrayCell(myAugmentInfo[client], AugmentClientIsInspecting[client], tarRoll, 5);
				Format(tquery, sizeof(tquery), "UPDATE `%s_loot` SET `tarrating` = '%d' WHERE (`itemid` = '%s');", TheDBPrefix, tarRoll, sItemCode);
			}
		}

		// just so I don't have to rewrite this code several times or move it somewhere else
		if (bUpgradeHasOccurred) {
			SQL_TQuery(hDatabase, QueryResults, tquery);
			// if the augment we're modifying is equipped, we just unequip/re-equip the augment which will trigger updating the players stats.
			if (isEquipped >= 0) {
				UnequipAugment_Confirm(client, sItemCode);
				EquipAugment_Confirm(client, isEquipped);
			}
		}
		SendPanelToClientAndClose(Upgrade_Augment(client), client, Upgrade_Augment_Handle, MENU_TIME_FOREVER);
	}
}

stock Augments_Inventory(client) {
	itemToDisassemble[client] = -1;
	Handle menu = CreateMenu(Augments_Inventory_Handle);
	char pct[4];
	Format(pct, 4, "%");
	int size = GetArraySize(myAugmentIDCodes[client]);
	char text[512];
	Format(text, 512, "Inventory space:\t%d/%d\nScrap:\t%d", size, iInventoryLimit, augmentParts[client]);
	SetMenuTitle(menu, text);
	//SortADTArray(myAugmentInfo[client], Sort_Ascending, Sort_Integer);
	if (size > 0) {
		char key[64];
		GetClientAuthId(client, AuthId_Steam2, key, sizeof(key));

		ClearArray(augmentInventoryPosition[client]);
		// show equipped augments, in order, first.
		int currentAugment = 0;
		while (currentAugment < iNumAugments) {
			for (int i = 0; i < size; i++) {
				int isEquipped = GetArrayCell(myAugmentInfo[client], i, 3);
				if (isEquipped != currentAugment) continue;
				// I'm using an arraylist to store which position of the inventory to actually load, so that I can
				// show players their equipped augments, ordered, before all other augments.
				//int currentPositionsStored = GetArraySize(augmentInventoryPosition[client]);
				//ResizeArray(augmentInventoryPosition[client], currentPositionsStored + 1);
				PushArrayCell(augmentInventoryPosition[client], i);

				char augmentName[64], augmentCategory[64], augmentActivator[64], augmentTarget[64];
				GetAugmentComparator(client, i, augmentName, augmentCategory, augmentActivator, augmentTarget, _, true);
				char augmentCatStr[64], augmentActStr[64], augmentTarStr[64];
				GetAugmentStrength(client, i, 0, augmentCatStr);
				GetAugmentStrength(client, i, 1, augmentActStr);
				GetAugmentStrength(client, i, 2, augmentTarStr);
				Format(augmentCatStr, sizeof(augmentCatStr), "%s %s", augmentCatStr, augmentCategory);
				Format(augmentCatStr, sizeof(augmentCatStr), "%s (slot %d)", augmentCatStr, isEquipped+1);
				char augmentOwner[64];
				GetArrayString(myAugmentOwners[client], i, augmentOwner, sizeof(augmentOwner));
				
				bool isNotOriginalOwner = (StrContains(augmentOwner, key, false) == -1) ? true : false;
				if (isNotOriginalOwner) Format(augmentCatStr, sizeof(augmentCatStr), "%s^", augmentCatStr);

				char profilesSavedTo[64];
				GetArrayString(myAugmentSavedProfiles[client], i, profilesSavedTo, sizeof(profilesSavedTo));
				if (!StrEqual(profilesSavedTo, "none")) Format(augmentCatStr, sizeof(augmentCatStr), "%s!", augmentCatStr);

				Format(text, sizeof(text), "%s", augmentCatStr);
				if (!StrEqual(augmentActivator, "-1")) {
					Format(augmentActStr, sizeof(augmentActStr), "%s %s", augmentActStr, augmentActivator);
					Format(text, sizeof(text), "%s\n%s", text, augmentActStr);
				}
				if (!StrEqual(augmentTarget, "-1")) {
					Format(augmentTarStr, sizeof(augmentTarStr), "%s %s", augmentTarStr, augmentTarget);
					Format(text, sizeof(text), "%s\n%s", text, augmentTarStr);
				}
				AddMenuItem(menu, text, text);
				break;
			}
			currentAugment++;
		}
		// unequipped augments now.
		for (int i = 0; i < size; i++) {
			int isEquipped = GetArrayCell(myAugmentInfo[client], i, 3);
			if (isEquipped >= 0) continue;
			// I'm using an arraylist to store which position of the inventory to actually load, so that I can
			// show players their equipped augments, ordered, before all other augments.
			//int currentPositionsStored = GetArraySize(augmentInventoryPosition[client]);
			//ResizeArray(augmentInventoryPosition[client], currentPositionsStored + 1);
			PushArrayCell(augmentInventoryPosition[client], i);

			char augmentName[64], augmentCategory[64], augmentActivator[64], augmentTarget[64];
			GetAugmentComparator(client, i, augmentName, augmentCategory, augmentActivator, augmentTarget, _, true);
			char augmentCatStr[64], augmentActStr[64], augmentTarStr[64];
			GetAugmentStrength(client, i, 0, augmentCatStr);
			GetAugmentStrength(client, i, 1, augmentActStr);
			GetAugmentStrength(client, i, 2, augmentTarStr);
			Format(augmentCatStr, sizeof(augmentCatStr), "%s %s", augmentCatStr, augmentCategory);
			if (isEquipped == -2) Format(augmentCatStr, sizeof(augmentCatStr), "%s*", augmentCatStr);
			
			char augmentOwner[64];
			GetArrayString(myAugmentOwners[client], i, augmentOwner, sizeof(augmentOwner));
			
			bool isNotOriginalOwner = (StrContains(augmentOwner, key, false) == -1) ? true : false;
			if (isNotOriginalOwner) Format(augmentCatStr, sizeof(augmentCatStr), "%s^", augmentCatStr);
			
			char profilesSavedTo[64];
			GetArrayString(myAugmentSavedProfiles[client], i, profilesSavedTo, sizeof(profilesSavedTo));
			if (!StrEqual(profilesSavedTo, "none")) Format(augmentCatStr, sizeof(augmentCatStr), "%s!", augmentCatStr);

			Format(text, sizeof(text), "%s", augmentCatStr);
			if (!StrEqual(augmentActivator, "-1")) {
				Format(augmentActStr, sizeof(augmentActStr), "%s %s", augmentActStr, augmentActivator);
				Format(text, sizeof(text), "%s\n%s", text, augmentActStr);
			}
			if (!StrEqual(augmentTarget, "-1")) {
				Format(augmentTarStr, sizeof(augmentTarStr), "%s %s", augmentTarStr, augmentTarget);
				Format(text, sizeof(text), "%s\n%s", text, augmentTarStr);
			}
			AddMenuItem(menu, text, text);
		}
	}
	SetMenuExitBackButton(menu, true);
	DisplayMenu(menu, client, 0);
}

public Augments_Inventory_Handle(Handle menu, MenuAction action, client, slot) {
	if (action == MenuAction_Select) SendPanelToClientAndClose(Inspect_Augment(client, GetArrayCell(augmentInventoryPosition[client], slot)), client, Inspect_Augment_Handle, MENU_TIME_FOREVER);
	else if (action == MenuAction_Cancel) {
		if (slot == MenuCancel_ExitBack) BuildMenu(client);
	}
	if (action == MenuAction_End) CloseHandle(menu);
}