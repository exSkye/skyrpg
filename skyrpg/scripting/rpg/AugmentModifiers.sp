stock float GetCategoryTalentBuff(client, char[] activatorEffects, char[] targetEffects) {
	char val[64];
	float result = 0.0;
	int size = GetArraySize(equippedAugmentsCategory[client]);
	for (int i = 0; i < size; i++) {
		GetArrayString(equippedAugmentsActivator[client], i, val, 64);
		int rat = GetArrayCell(equippedAugments[client], i, 4);
		if (rat > 0 && StrEqual(val, activatorEffects, true)) result += (rat * fAugmentActivatorRatingMultiplier);
		
		GetArrayString(equippedAugmentsTarget[client], i, val, 64);
		rat = GetArrayCell(equippedAugments[client], i, 5);
		if (rat > 0 && StrEqual(val, targetEffects, true)) result += (rat * fAugmentTargetRatingMultiplier);
	}
	return result;
}

stock float GetCategoryAugmentBuff(client, char[] TalentNameOverride, float f_StrengthIncrement) {
	char menuName[64];
	GetMenuOfTalent(client, TalentNameOverride, menuName, sizeof(menuName));
	int size = GetArraySize(equippedAugmentsCategory[client]);
	float result = 0.0;
	for (int i = 0; i < size; i++) {
		char menuText[64];
		GetArrayString(equippedAugmentsCategory[client], i, menuText, 64);
		if (!StrEqual(menuName, menuText)) continue;
		int itemRating = GetArrayCell(equippedAugments[client], i, 2);
		if (itemRating > 0) result += (itemRating * fAugmentRatingMultiplier);
	}
	return result;
}