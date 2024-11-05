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