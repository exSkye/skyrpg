void SetProficiencyData(int client, int proficiencyType, int iLevelsToGive) {
	if (proficiencyType < 0 || proficiencyType > 7) return;
	int iExperienceEarned = 0;
	int curLevel = 0;// GetProficiencyData(client, proficiencyType, _, _, true);
	int targetLevel = iLevelsToGive;
	while (curLevel < targetLevel) {
 		iExperienceEarned += iProficiencyStart + RoundToCeil(iProficiencyStart * (fProficiencyExperienceMultiplier * curLevel));
		curLevel++;
	}
	if (proficiencyType == 0) pistolXP[client] = iExperienceEarned;
	else if (proficiencyType == 1) meleeXP[client] = iExperienceEarned;
	else if (proficiencyType == 2) uziXP[client] = iExperienceEarned;
	else if (proficiencyType == 3) shotgunXP[client] = iExperienceEarned;
	else if (proficiencyType == 4) sniperXP[client] = iExperienceEarned;
	else if (proficiencyType == 5) assaultXP[client] = iExperienceEarned;
	else if (proficiencyType == 6) medicXP[client] = iExperienceEarned;
	else if (proficiencyType == 7) grenadeXP[client] = iExperienceEarned;

	char proficiencyName[64];
	char playerName[64];
	GetClientName(client, playerName, sizeof(playerName));
	if (proficiencyType == 0) Format(proficiencyName, sizeof(proficiencyName), "%t", "pistol proficiency up");
	else if (proficiencyType == 1) Format(proficiencyName, sizeof(proficiencyName), "%t", "melee proficiency up");
	else if (proficiencyType == 2) Format(proficiencyName, sizeof(proficiencyName), "%t", "uzi proficiency up");
	else if (proficiencyType == 3) Format(proficiencyName, sizeof(proficiencyName), "%t", "shotgun proficiency up");
	else if (proficiencyType == 4) Format(proficiencyName, sizeof(proficiencyName), "%t", "sniper proficiency up");
	else if (proficiencyType == 5) Format(proficiencyName, sizeof(proficiencyName), "%t", "assault proficiency up");
	else if (proficiencyType == 6) Format(proficiencyName, sizeof(proficiencyName), "%t", "medic proficiency up");
	else if (proficiencyType == 7) Format(proficiencyName, sizeof(proficiencyName), "%t", "grenade proficiency up");
	PrintToChatAll("%t", "proficiency level up", blue, playerName, white, orange, proficiencyName, white, blue, curLevel);
}

/*
	return types:
	0 - level	1 - experience	2 - experience requirement
*/
stock GetProficiencyData(client, proficiencyType = 0, iExperienceEarned = 0, iReturnType = 0, bGetLevel = false) {
	if (proficiencyType == -1) return 1;
	int proficiencyExperience = pistolXP[client];
	if (proficiencyType == 1) proficiencyExperience = meleeXP[client];
	else if (proficiencyType == 2) proficiencyExperience = uziXP[client];
	else if (proficiencyType == 3) proficiencyExperience = shotgunXP[client];
	else if (proficiencyType == 4) proficiencyExperience = sniperXP[client];
	else if (proficiencyType == 5) proficiencyExperience = assaultXP[client];
	else if (proficiencyType == 6) proficiencyExperience = medicXP[client];
	else if (proficiencyType == 7) proficiencyExperience = grenadeXP[client];

	//PrintToChat(client, "%d %d", proficiencyType, iExperienceEarned);

	/*
		get current level
	*/
	int curLevel = 1;
	if (!bGetLevel) curLevel = GetProficiencyData(client, proficiencyType, _, _, true);
	proficiencyExperience += iExperienceEarned;	// else not necessary as we are passing 0 for iExperienceEarned in curLevel

	int proficiencyLevel = 0;
	int experienceRequirement = iProficiencyStart;
	//new Float:experienceMultiplier = 0.0;
	while (proficiencyExperience >= experienceRequirement) {
		proficiencyExperience -= experienceRequirement;
		proficiencyLevel++;
		experienceRequirement = iProficiencyStart + RoundToCeil(iProficiencyStart * (fProficiencyExperienceMultiplier * proficiencyLevel));
	}
	if (bGetLevel) return proficiencyLevel;
	if (iReturnType == 1) return proficiencyExperience;
	if (iReturnType == 2) return experienceRequirement;
	if (iExperienceEarned > 0) {
		if (proficiencyType == 0) pistolXP[client] += iExperienceEarned;
		else if (proficiencyType == 1) meleeXP[client] += iExperienceEarned;
		else if (proficiencyType == 2) uziXP[client] += iExperienceEarned;
		else if (proficiencyType == 3) shotgunXP[client] += iExperienceEarned;
		else if (proficiencyType == 4) sniperXP[client] += iExperienceEarned;
		else if (proficiencyType == 5) assaultXP[client] += iExperienceEarned;
		else if (proficiencyType == 6) medicXP[client] += iExperienceEarned;
		else if (proficiencyType == 7) grenadeXP[client] += iExperienceEarned;
	}
	if (curLevel < proficiencyLevel) {
		char proficiencyName[64];
		char playerName[64];
		GetClientName(client, playerName, sizeof(playerName));
		if (proficiencyType == 0) Format(proficiencyName, sizeof(proficiencyName), "%t", "pistol proficiency up");
		else if (proficiencyType == 1) Format(proficiencyName, sizeof(proficiencyName), "%t", "melee proficiency up");
		else if (proficiencyType == 2) Format(proficiencyName, sizeof(proficiencyName), "%t", "uzi proficiency up");
		else if (proficiencyType == 3) Format(proficiencyName, sizeof(proficiencyName), "%t", "shotgun proficiency up");
		else if (proficiencyType == 4) Format(proficiencyName, sizeof(proficiencyName), "%t", "sniper proficiency up");
		else if (proficiencyType == 5) Format(proficiencyName, sizeof(proficiencyName), "%t", "assault proficiency up");
		else if (proficiencyType == 6) Format(proficiencyName, sizeof(proficiencyName), "%t", "medic proficiency up");
		else if (proficiencyType == 7) Format(proficiencyName, sizeof(proficiencyName), "%t", "grenade proficiency up");
		PrintToChatAll("%t", "proficiency level up", blue, playerName, white, orange, proficiencyName, white, blue, proficiencyLevel);
	}
	return curLevel;
}