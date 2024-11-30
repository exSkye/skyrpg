stock CheckMinimumRate(client) {
	if (Rating[client] < 0) Rating[client] = 0;
}

stock float GetScoreMultiplier(int client) {
	if (GetArraySize(HandicapSelectedValues[client]) != 4) SetClientHandicapValues(client, true);
	float scoreMultiplier = fNoHandicapScoreMultiplier;
	if (handicapLevel[client] > 0) scoreMultiplier = GetArrayCell(HandicapSelectedValues[client], 3);

	return scoreMultiplier;
}

stock int GetRatingRewardForDamage(int survivor, int infected, int pos, int ClientType) {
	float myDamageContribution = GetMyDamageContribution(survivor, pos, ClientType);
	if (myDamageContribution < fDamageContribution) return 0;
	
	int RatingRewardDamage = 0;
	float RatingMultiplier = 0.0;
	if (ClientType == CLIENT_SPECIAL_INFECTED) {
		if (FindZombieClass(infected) != ZOMBIECLASS_TANK) RatingMultiplier = fRatingMultSpecials;
		else RatingMultiplier = fRatingMultTank;
	}
	else if (ClientType == CLIENT_WITCH) RatingMultiplier = fRatingMultWitch;
	else if (ClientType == CLIENT_SUPER_COMMON) RatingMultiplier = fRatingMultSupers;
	else RatingMultiplier = fRatingMultCommons;

	RatingRewardDamage = RoundToFloor(myDamageContribution * 100.0);
	RatingRewardDamage = RoundToFloor(RatingRewardDamage * RatingMultiplier);
	return RatingRewardDamage;
}

stock int CheckTankingDamage(int client, int target, int pos) {
	int cDamage = 0;

	if (target == CLIENT_SPECIAL_INFECTED) cDamage = GetArrayCell(InfectedHealth[client], pos, 3);
	else if (target == CLIENT_WITCH) cDamage = GetArrayCell(WitchDamage[client], pos, 3);
	else if (target == CLIENT_SUPER_COMMON) cDamage = GetArrayCell(SpecialCommon[client], pos, 3);
	else cDamage = GetArrayCell(CommonInfected[client], pos, 3);

	return cDamage;
}

stock int GetRatingRewardForTanking(int survivor, int infected, int pos, int clientType) {
	int damageReceived = 0;
	float RatingMultiplier = 0.0;

	if (clientType == CLIENT_SPECIAL_INFECTED) {
		damageReceived		= GetArrayCell(InfectedHealth[survivor], pos, 3);
		if (FindZombieClass(infected) != ZOMBIECLASS_TANK) RatingMultiplier = fRatingMultSpecials;
		else RatingMultiplier = fRatingMultTank;
	}
	else if (clientType == CLIENT_WITCH) {
		damageReceived		= GetArrayCell(WitchDamage[survivor], pos, 3);
		RatingMultiplier = fRatingMultWitch;
	}
	else if (clientType == CLIENT_SUPER_COMMON) {
		damageReceived		= GetArrayCell(SpecialCommon[survivor], pos, 3);
		RatingMultiplier = fRatingMultSupers;
	}
	else {
		damageReceived		= GetArrayCell(CommonInfected[survivor], pos, 3);
		RatingMultiplier = fRatingMultCommons;
	}
	int damageReceivedRequired = RoundToCeil(GetMaximumHealth(survivor) * fTankingContribution);
	if (damageReceived < damageReceivedRequired) return 0;

	int maxScore = RoundToFloor(100.0 * RatingMultiplier);
	if (damageReceived > maxScore) damageReceived = maxScore;
	return damageReceived;
}

stock int GetRatingRewardForBuffing(int survivor, int infected, int pos, int clientType) {
	float RatingMultiplier = 0.0;
	int buffingDone = 0;
	int tHealth = 0;
	float BuffingMultiplier = 0.0;
	if (clientType == CLIENT_SPECIAL_INFECTED) {
		buffingDone		= GetArrayCell(InfectedHealth[survivor], pos, 7);
		tHealth			= GetArrayCell(InfectedHealth[survivor], pos, 1);
		if (FindZombieClass(infected) != ZOMBIECLASS_TANK) {
			RatingMultiplier = fRatingMultSpecials;
			BuffingMultiplier = fBuffingMultSpecials;
		}
		else {
			RatingMultiplier = fRatingMultTank;
			BuffingMultiplier = fBuffingMultTank;
		}
	}
	else if (clientType == CLIENT_WITCH) {
		buffingDone		= GetArrayCell(WitchDamage[survivor], pos, 7);
		tHealth			= GetArrayCell(WitchDamage[survivor], pos, 1);
		RatingMultiplier = fRatingMultWitch;
		BuffingMultiplier = fBuffingMultWitch;
	}
	else if (clientType == CLIENT_SUPER_COMMON) {
		buffingDone		= GetArrayCell(SpecialCommon[survivor], pos, 7);
		tHealth			= GetArrayCell(SpecialCommon[survivor], pos, 1);
		RatingMultiplier = fRatingMultSupers;
		BuffingMultiplier = fBuffingMultSupers;
	}
	else {
		buffingDone		= GetArrayCell(CommonInfected[survivor], pos, 7);
		tHealth			= GetArrayCell(CommonInfected[survivor], pos, 1);
		RatingMultiplier = fRatingMultCommons;
		BuffingMultiplier = fBuffingMultCommons;
	}
	buffingDone *= BuffingMultiplier;
	float fBuffContribution = (buffingDone * 1.0) / (tHealth * 1.0);
	if (fBuffContribution < fBuffingContribution) return 0;
	if (fBuffContribution > 1.0) fBuffContribution = 1.0;
	
	int score = RoundToFloor((100.0 * RatingMultiplier) * fBuffContribution);
	return score;
}

stock int GetRatingRewardForHealing(int survivor, int infected, int pos, int clientType, int infectedDamageTrackerPos) {
	int healingProvided = 0;
	float RatingMultiplier = 0.0;
	int infectedDamageDealt = -1;

	if (clientType == CLIENT_SPECIAL_INFECTED) {
		healingProvided		= GetArrayCell(InfectedHealth[survivor], pos, 8);
		if (FindZombieClass(infected) != ZOMBIECLASS_TANK) RatingMultiplier = fRatingMultSpecials;
		else RatingMultiplier = fRatingMultTank;

		if (infectedDamageTrackerPos == -1) return 0;
		infectedDamageDealt = GetArrayCell(damageOfSpecialInfected, infectedDamageTrackerPos, 1);
	}
	else if (clientType == CLIENT_WITCH) {
		healingProvided		= GetArrayCell(WitchDamage[survivor], pos, 8);
		RatingMultiplier = fRatingMultWitch;

		if (infectedDamageTrackerPos == -1) return 0;
		infectedDamageDealt = GetArrayCell(damageOfWitch, infectedDamageTrackerPos, 1);
	}
	else if (clientType == CLIENT_SUPER_COMMON) {
		healingProvided		= GetArrayCell(SpecialCommon[survivor], pos, 8);
		RatingMultiplier = fRatingMultSupers;

		if (infectedDamageTrackerPos == -1) return 0;
		infectedDamageDealt = GetArrayCell(CommonAffixes, infectedDamageTrackerPos, 2);
	}
	else {
		healingProvided		= GetArrayCell(CommonInfected[survivor], pos, 8);
		RatingMultiplier = fRatingMultCommons;

		if (infectedDamageTrackerPos == -1) return 0;
		infectedDamageDealt = GetArrayCell(damageOfCommonInfected, infectedDamageTrackerPos, 1);
	}
	if (healingProvided < 1 || infectedDamageDealt < 1) return 0;
	
	float fHealContribution = (healingProvided * 1.0) / (infectedDamageDealt * 1.0);
	if (fHealContribution < fHealingContribution) return 0;
	if (fHealContribution > 1.0) fHealContribution = 1.0;

	int score = RoundToFloor((100.0 * RatingMultiplier) * fHealContribution);
	return score;
}

stock float GetTankingContribution(survivor, infected) {

	int TotalHealth = 0;
	int DamageTaken = 0;

	bool bLegitimateClient;
	bool bIsWitch;
	bool bIsSpecialCommon;

	int pos = -1;
	if (IsLegitimateClient(infected)) {
		pos = FindListPositionByEntity(infected, InfectedHealth[survivor]);
		bLegitimateClient = true;
	}
	else if (IsWitch(infected)) {
		pos = FindListPositionByEntity(infected, WitchDamage[survivor]);
		bIsWitch = true;
	}
	else if (IsSpecialCommon(infected)) {
		pos = FindListPositionByEntity(infected, SpecialCommon[survivor]);
		bIsSpecialCommon = true;
	}

	if (pos < 0) return 0.0;

	if (bIsWitch) {

		TotalHealth		= GetArrayCell(WitchDamage[survivor], pos, 1);
		DamageTaken		= GetArrayCell(WitchDamage[survivor], pos, 3);
	}
	else if (bIsSpecialCommon) {

		TotalHealth		= GetArrayCell(SpecialCommon[survivor], pos, 1);
		DamageTaken		= GetArrayCell(SpecialCommon[survivor], pos, 3);
	}
	else if (bLegitimateClient && myCurrentTeam[infected] == TEAM_INFECTED) {

		TotalHealth		= GetArrayCell(InfectedHealth[survivor], pos, 1);
		DamageTaken		= GetArrayCell(InfectedHealth[survivor], pos, 3);
	}
	if (DamageTaken == 0) return 0.0;
	if (DamageTaken > TotalHealth) return 1.0;
	//new Float:TheDamageTaken = (DamageTaken * 1.0) / (TotalHealth * 1.0);
	return ((DamageTaken * 1.0) / (TotalHealth * 1.0));
}

stock GetDifficultyRating(client) {
	if (!IsLegitimateClient(client) || myCurrentTeam[client] != TEAM_SURVIVOR || !b_IsLoaded[client]) return 1;
	bool isClientFake = IsFakeClient(client);
	int iRatingPerLevel = (RatingPerLevel < 1 && !isClientFake || RatingPerLevelSurvivorBots < 1 && isClientFake) ? 0 : (!isClientFake) ? RatingPerLevel : RatingPerLevelSurvivorBots;
	int iRatingPerTalentLevel = (!isClientFake) ? RatingPerTalentPoint : RatingPerTalentPointBots;
	if (iRatingPerLevel > 0) {
		iRatingPerTalentLevel *= TotalPointsAssigned(client);
		iRatingPerLevel *= PlayerLevel[client];
	}
	int trueAugmentLevel = (!isClientFake && playerCurrentAugmentLevel[client] > 0) ? playerCurrentAugmentLevel[client] * RatingPerAugmentLevel : 0;
	//if (iRatingPerAugmentLevel < 0) iRatingPerAugmentLevel = 0;
	return iRatingPerLevel + iRatingPerTalentLevel + trueAugmentLevel + Rating[client];
}

stock ReceiveInfectedDamageAward(int client, int infected, int base_e_reward, float p_reward, int base_t_reward, int base_h_reward , int base_bu_reward, int base_he_reward, bool TheRoundHasEnded = false) {
	int RPGMode									= iRPGMode;
	if (RPGMode < 0) return;
	PrintToChat(client, "%T", "exited combat", client, orange);
	//new RPGBroadcast							= StringToInt(GetConfigValue("award broadcast?"));
	char InfectedName[64];
	//decl String:InfectedTeam[64];
	int enemytype = -1;
	if (infected > 0) {
		if (IsLegitimateClient(infected)) {
			GetClientName(infected, InfectedName, sizeof(InfectedName));
			enemytype = 3;
		}
		else if (IsWitch(infected)) {
			Format(InfectedName, sizeof(InfectedName), "Witch");
			enemytype = 2;
		}
		else if (IsSpecialCommon(infected)) {
			int superPos = FindListPositionByEntity(infected, CommonAffixes, 1);
			GetCommonValueAtPosEx(InfectedName, sizeof(InfectedName), superPos, SUPER_COMMON_NAME);
			enemytype = 1;
		}
		else if (IsCommonInfected(infected)) {
			Format(InfectedName, sizeof(InfectedName), "Common");
			enemytype = 0;
		}
		Format(InfectedName, sizeof(InfectedName), "%s %s", sDirectorTeam, InfectedName);
	}
	int e_reward = 0;
	int h_reward = 0;
	int t_reward = 0;
	int bu_reward = 0;
	int he_reward = 0;
	//new Float:fRoundMultiplier = 1.0;
	if (RoundExperienceMultiplier[client] > 0.0) {
		//fRoundMultiplier += RoundExperienceMultiplier[client];
		if (base_e_reward > 0) e_reward = RoundToCeil(base_e_reward * RoundExperienceMultiplier[client]);
		if (base_h_reward > 0) h_reward = RoundToCeil(base_h_reward * RoundExperienceMultiplier[client]);
		if (base_t_reward > 0) t_reward = RoundToCeil(base_t_reward * RoundExperienceMultiplier[client]);
		if (base_bu_reward > 0) bu_reward = RoundToCeil(base_bu_reward * RoundExperienceMultiplier[client]);
		if (base_he_reward > 0) he_reward = RoundToCeil(base_he_reward * RoundExperienceMultiplier[client]);
	}
	int RestedAwardBonus = 0;
	if (RestedExperience[client] > 0) {
		if (base_e_reward > 0) RestedAwardBonus = RoundToFloor(base_e_reward * fRestedExpMult);
		if (base_h_reward > 0) RestedAwardBonus += RoundToFloor(base_h_reward * fRestedExpMult);
		if (base_t_reward > 0) RestedAwardBonus += RoundToFloor(base_t_reward * fRestedExpMult);
		if (base_bu_reward > 0) RestedAwardBonus += RoundToFloor(base_bu_reward * fRestedExpMult);
		if (base_he_reward > 0) RestedAwardBonus += RoundToFloor(base_he_reward * fRestedExpMult);

		if (RestedAwardBonus >= RestedExperience[client]) {
			RestedAwardBonus = RestedExperience[client];
			RestedExperience[client] = 0;
		}
		else if (RestedAwardBonus < RestedExperience[client]) {
			RestedExperience[client] -= RestedAwardBonus;
		}
	}
	int ExperienceBooster = (e_reward > 0) ? RoundToFloor(e_reward * CheckExperienceBooster(client, e_reward)) : 0;
	if (ExperienceBooster < 1) ExperienceBooster = 0;
	//new Float:TeammateBonus = 0.0;//(LivingSurvivors() - 1) * fSurvivorExpMult;
	float multiplierBonus = 0.0;
	int theCount = LivingSurvivorCount();
	if (iSurvivorModifierRequired > 0 && fSurvivorExpMult > 0.0 && theCount >= iSurvivorModifierRequired) {
		float TeammateBonus = (theCount - (iSurvivorModifierRequired - 1)) * fSurvivorExpMult;
		if (TeammateBonus > 0.0) multiplierBonus += TeammateBonus;
	}
	if (IsGroupMember[client] && GroupMemberBonus > 0.0) multiplierBonus += GroupMemberBonus;
	if (!BotsOnSurvivorTeam() && TotalHumanSurvivors() <= iSurvivorBotsBonusLimit && fSurvivorBotsNoneBonus > 0.0) multiplierBonus += fSurvivorBotsNoneBonus;

	if (multiplierBonus > 0.0) {
		if (base_e_reward > 0) e_reward += RoundToCeil(multiplierBonus * base_e_reward);
		if (base_h_reward > 0) h_reward += RoundToCeil(multiplierBonus * base_h_reward);
		if (base_t_reward > 0) t_reward += RoundToCeil(multiplierBonus * base_t_reward);
		if (base_bu_reward > 0) bu_reward += RoundToCeil(multiplierBonus * base_bu_reward);
		if (base_he_reward > 0) he_reward += RoundToCeil(multiplierBonus * base_he_reward);
	}
	// multiplicative bonus if the survivor is the last one alive. all other bonuses are additive.
	if (theCount == 1 && fSoloDifficultyExperienceBonus > 0.0) {
		if (e_reward > 0) e_reward += RoundToCeil(fSoloDifficultyExperienceBonus * e_reward);
		if (h_reward > 0) h_reward += RoundToCeil(fSoloDifficultyExperienceBonus * h_reward);
		if (t_reward > 0) t_reward += RoundToCeil(fSoloDifficultyExperienceBonus * t_reward);
		if (bu_reward > 0) bu_reward += RoundToCeil(fSoloDifficultyExperienceBonus * bu_reward);
		if (he_reward > 0) he_reward += RoundToCeil(fSoloDifficultyExperienceBonus * he_reward);
	}
	if (e_reward < 1) e_reward = 0;
	if (h_reward < 1) h_reward = 0;
	if (t_reward < 1) t_reward = 0;
	if (bu_reward < 1) bu_reward = 0;
	if (he_reward < 1) he_reward = 0;
	//h_reward = RoundToCeil(GetClassMultiplier(client, h_reward * 1.0, "hXP"));
	//t_reward = RoundToCeil(GetClassMultiplier(client, t_reward * 1.0, "tXP"));
	//if (!TheRoundHasEnded) {
	// Previously, if a player completed a round without ever leaving combat, they would receive no bonus container.
	BonusContainer[client] = 0;	// if the player enables it mid-match, this ensures the bonus container is always 0 for paused levelers.
	//	0 = Points Only
	//	1 = RPG Only
	//	2 - RPG + Points
	if (RPGMode > 0 && PlayerLevel[client] < iMaxLevel) {
		if (!TheRoundHasEnded && DisplayType > 0 && (infected == 0 || enemytype > 0)) {								// \x04Jockey \x01killed: \x04 \x03experience
			char rewardText[64];

			if (e_reward > 0) {
				AddCommasToString(e_reward, rewardText, sizeof(rewardText));
				if (infected > 0) PrintToChat(client, "%T", "base experience reward", client, orange, InfectedName, orange, blue, rewardText, green, blue);
				else if (infected == 0) PrintToChat(client, "%T", "damage experience reward", client, orange, blue, rewardText, green, blue);
				AddAttributeExperience(client, ATTRIBUTE_AGILITY, e_reward);
			}
			if (DisplayType == 2) {
				if (RestedAwardBonus > 0) {
					AddCommasToString(RestedAwardBonus, rewardText, sizeof(rewardText));
					PrintToChat(client, "%T", "rested experience reward", client, orange, blue, rewardText, green, blue);
				}
				if (ExperienceBooster > 0) {
					AddCommasToString(ExperienceBooster, rewardText, sizeof(rewardText));
					PrintToChat(client, "%T", "booster experience reward", client, orange, blue, rewardText, green, blue);
				}
			}
			if (t_reward > 0) {
				AddCommasToString(t_reward, rewardText, sizeof(rewardText));
				PrintToChat(client, "%T", "tanking experience reward", client, orange, blue, rewardText, green, blue);
				AddAttributeExperience(client, ATTRIBUTE_CONSTITUTION, t_reward);
			}
			if (h_reward > 0) {
				AddCommasToString(h_reward, rewardText, sizeof(rewardText));
				PrintToChat(client, "%T", "healing experience reward", client, orange, blue, rewardText, green, blue);
				AddAttributeExperience(client, ATTRIBUTE_ENDURANCE, h_reward);
			}
			if (bu_reward > 0) {
				AddCommasToString(bu_reward, rewardText, sizeof(rewardText));
				PrintToChat(client, "%T", "buffing experience reward", client, orange, blue, rewardText, green, blue);
				AddAttributeExperience(client, ATTRIBUTE_ENDURANCE, bu_reward);
			}
			if (he_reward > 0) {
				AddCommasToString(he_reward, rewardText, sizeof(rewardText));
				PrintToChat(client, "%T", "hexing experience reward", client, orange, blue, rewardText, green, blue);
				AddAttributeExperience(client, ATTRIBUTE_ENDURANCE, he_reward);
			}
		}
		int TotalExperienceEarned = (e_reward + RestedAwardBonus + ExperienceBooster + t_reward + h_reward + bu_reward + he_reward);
 		ExperienceLevel[client] += TotalExperienceEarned;
		ExperienceOverall[client] += TotalExperienceEarned;
		//GetProficiencyData(client, GetWeaponProficiencyType(client), TotalExperienceEarned);
		ConfirmExperienceAction(client, TheRoundHasEnded);
	}
	if (!TheRoundHasEnded && RPGMode >= 0 && RPGMode != 1 && p_reward > 0.0) {
		Points[client] += p_reward;
		if (DisplayType > 0 && (infected == 0 || enemytype > 0)) PrintToChat(client, "%T", "points from damage reward", client, green, white, green, p_reward, blue);
	}
}