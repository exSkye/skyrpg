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