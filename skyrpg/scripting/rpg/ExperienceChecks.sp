stock GetExperienceRequirement(newlevel) {
	int baseExperienceCounter = (newlevel > iHardcoreMode) ? iHardcoreMode : newlevel;
	int hardExperienceCounter = (newlevel > iHardcoreMode) ? newlevel - iHardcoreMode : 0;

	float fExpMult = fExperienceMultiplier * (baseExperienceCounter - 1);
	float fExpHard = fExperienceMultiplierHardcore * (hardExperienceCounter - 1);
	return iExperienceStart + RoundToCeil(iExperienceStart * (fExpMult + fExpHard));
}

stock CheckExperienceRequirement(client, bool bot = false, iLevel = 0, previousLevelRequirement = 0) {
	int experienceRequirement = 0;
	if (IsLegitimateClient(client)) {
		int levelToCalculateFor = (iLevel == 0) ? PlayerLevel[client] : iLevel;

		experienceRequirement			=	iExperienceStart;
		float experienceMultiplier	=	0.0;
		float hardcoreMultiplier	=	0.0;

		int baseExperienceCounter = (levelToCalculateFor > iHardcoreMode) ? iHardcoreMode : levelToCalculateFor;
		int hardExperienceCounter = (levelToCalculateFor > iHardcoreMode) ? levelToCalculateFor - iHardcoreMode : 0;

		if (iUseLinearLeveling == 1) {
			experienceMultiplier 			=	fExperienceMultiplier * (baseExperienceCounter - 1);
			hardcoreMultiplier				=	fExperienceMultiplierHardcore * (hardExperienceCounter - 1);
			experienceRequirement			=	iExperienceStart + RoundToCeil(iExperienceStart * (experienceMultiplier + hardcoreMultiplier));
		}
		else if (previousLevelRequirement != 0) {
			if (PlayerLevel[client] < iHardcoreMode) experienceRequirement			=	previousLevelRequirement + RoundToCeil(previousLevelRequirement * fExperienceMultiplier);
			else experienceRequirement			=	previousLevelRequirement + RoundToCeil(previousLevelRequirement * fExperienceMultiplierHardcore);
		}
		else if (levelToCalculateFor > 1) {
			for (int i = 1; i < levelToCalculateFor; i++) {
				if (i < iHardcoreMode) experienceRequirement		+=	RoundToCeil(experienceRequirement * fExperienceMultiplier);
				else experienceRequirement		+=	RoundToCeil(experienceRequirement * fExperienceMultiplierHardcore);
			}
		}
	}
	return experienceRequirement;
}

stock GetPlayerLevel(client) {
	int iExperienceOverall = ExperienceOverall[client];
	int iLevel = 1;
	int ExperienceRequirement = CheckExperienceRequirement(client, false, iLevel);
	while (iExperienceOverall >= ExperienceRequirement && iLevel < iMaxLevel) {
		if (iIsLevelingPaused[client] == 1 && iExperienceOverall == ExperienceRequirement) break;
		iExperienceOverall -= ExperienceRequirement;
		iLevel++;
		ExperienceRequirement = CheckExperienceRequirement(client, false, iLevel);
	}
	return iLevel;
}

void AddAttributeExperience(int client, int attribute, int experience, bool clientDataIsLoading = false) {
	int attributeLevel = 1;
	// if the client is loading, set their total experience acquired.
	if (clientDataIsLoading) SetArrayCell(attributeData[client], attribute, experience, 3);
	else {
		// applies a modifier to the amount of experience earned based on the attribute.
		experience = RoundToCeil(experience * fAttributeModifier[attribute]);
		// client is earning experience through activity, add it to their total experience for this attribute.
		int totalExperienceAcquired = GetArrayCell(attributeData[client], attribute, 3);
		SetArrayCell(attributeData[client], attribute, totalExperienceAcquired + experience, 3);
		// pull the clients stored current attribute so we're only calculating current and future levels
		attributeLevel = GetArrayCell(attributeData[client], attribute);

		int totalExperienceThisLevel = GetArrayCell(attributeData[client], attribute, 1);
		if (totalExperienceThisLevel < 0) totalExperienceThisLevel = 0;
		experience += totalExperienceThisLevel;
	}

	int levelUpExperienceRequirement = iAttributeExperienceRequirement + RoundToCeil(iAttributeExperienceRequirement * (attributeExperienceMultiplier * (attributeLevel-1)));
	int levelUps = 0;
	while (experience >= levelUpExperienceRequirement) {
		experience -= levelUpExperienceRequirement;
		levelUps++;
		attributeLevel++;
		levelUpExperienceRequirement = iAttributeExperienceRequirement + RoundToCeil(iAttributeExperienceRequirement * (attributeExperienceMultiplier * (attributeLevel-1)));
	}
	if (levelUps > 0) {
		if (!clientDataIsLoading) {
			char text[64];
			if (attribute == ATTRIBUTE_CONSTITUTION) Format(text, sizeof(text), "%t", "constitution");
			else if (attribute == ATTRIBUTE_AGILITY) Format(text, sizeof(text), "%t", "agility");
			else if (attribute == ATTRIBUTE_RESILIENCE) Format(text, sizeof(text), "%t", "resilience");
			else if (attribute == ATTRIBUTE_TECHNIQUE) Format(text, sizeof(text), "%t", "technique");
			else if (attribute == ATTRIBUTE_ENDURANCE) Format(text, sizeof(text), "%t", "endurance");
			else Format(text, sizeof(text), "%t", "luck");
			// {B}Sky {W}gains {O}2 {B}Constitution {w}levels and is now {B}Constitution {O}Level {B}31
			if (levelUps > 1) PrintToChatAll("%t", "attribute multiple level increase", blue, baseName[client], white, orange, levelUps, blue, text, white, blue, text, orange, blue, attributeLevel);
			else PrintToChatAll("%t", "attribute level increase", blue, baseName[client], white, blue, text, orange, blue, attributeLevel);
		}

		// set the current experience and the required experience to variables so players can see their experience bars without having to recalculate it.
		SetArrayCell(attributeData[client], attribute, attributeLevel);
		SetArrayCell(attributeData[client], attribute, experience, 1);
		SetArrayCell(attributeData[client], attribute, levelUpExperienceRequirement, 2);
	}
	else {
		if (clientDataIsLoading) {
			SetArrayCell(attributeData[client], attribute, attributeLevel);
			SetArrayCell(attributeData[client], attribute, levelUpExperienceRequirement, 2);
		}
		SetArrayCell(attributeData[client], attribute, experience, 1);
	}
}

stock GetTotalExperienceByLevel(newlevel) {
	int experienceTotal = 0;
	if (newlevel > iMaxLevel) newlevel = iMaxLevel;
	for (int i = 1; i <= newlevel; i++) {
		if (newlevel == i) break;
		experienceTotal += GetExperienceRequirement(i);
	}
	experienceTotal++;
	return experienceTotal;
}

stock SetTotalExperienceByLevel(client, newlevel, bool giveMaxXP = false) {
	int oldlevel = PlayerLevel[client];
	ExperienceOverall[client] = 0;
	ExperienceLevel[client] = 0;
	if (newlevel > iMaxLevel) newlevel = iMaxLevel;
	PlayerLevel[client] = newlevel;
	for (int i = 1; i <= newlevel; i++) {
		if (newlevel == i) break;
		ExperienceOverall[client] += CheckExperienceRequirement(client, false, i);
	}

	ExperienceOverall[client]++;
	ExperienceLevel[client]++;	// i don't like 0 / level, so i always do 1 / level as the minimum.
	if (giveMaxXP) ExperienceOverall[client] = CheckExperienceRequirement(client, false, iMaxLevel);
	if (oldlevel > PlayerLevel[client]) ChallengeEverything(client);
	else if (PlayerLevel[client] > oldlevel) {
		FreeUpgrades[client] += (PlayerLevel[client] - oldlevel);
	}
}