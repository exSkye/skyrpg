stock IncapacitateOrKill(client, attacker = 0, healthvalue = 0, bool bIsFalling = false, bool bIsLifelinkPenalty = false, bool ForceKill = false) {
	bool isPlayerASurvivorBot = IsFakeClient(client);
	if ((ForceKill || IsLegitimateClientAlive(client)) && (myCurrentTeam[client] != TEAM_INFECTED || isPlayerASurvivorBot)) {
		bool isClientIncapacitated = IsIncapacitated(client);
		//new IncapCounter	= GetEntProp(client, Prop_Send, "m_currentReviveCount");
		if (ForceKill || isClientIncapacitated || bIsFalling && !IsLedged(client) || bHasWeakness[client] > 0 || iCurrentIncapCount[client] >= iMaxIncap) {
			//if (FindZombieClass(attacker) == ZOMBIECLASS_JOCKEY) PrintToChatAll("jockey did the incap.");
			if (!ForceKill) {
				GetClientAbsOrigin(client, DeathLocation[client]);
				b_HasDeathLocation[client] = true;
				SetArrayCell(tempStorage, client, Rating[client], 0);
				SetArrayCell(tempStorage, client, handicapLevel[client], 1);
				SetArrayCell(tempStorage, client, RoundExperienceMultiplier[client], 2);
			}
			clientDeathTime[client] = GetTime();
			HealingContribution[client] = 0;
			DamageContribution[client] = 0;
			PointsContribution[client] = 0.0;
			TankingContribution[client] = 0;
			BuffingContribution[client] = 0;
			HexingContribution[client] = 0;
			ResetContributionTracker(client);
			char PlayerName[64];
			char PlayerID[64];
			if (!isPlayerASurvivorBot) {

				GetClientName(client, PlayerName, sizeof(PlayerName));
				GetClientAuthId(client, AuthId_Steam2, PlayerID, sizeof(PlayerID));
				if (!StrEqual(serverKey, "-1")) Format(PlayerID, sizeof(PlayerID), "%s%s", serverKey, PlayerID);
			}
			else {

				GetSurvivorBotName(client, PlayerName, sizeof(PlayerName));
				Format(PlayerID, sizeof(PlayerID), "%s%s", sBotTeam, PlayerName);
			}
			char pct[4];
			Format(pct, sizeof(pct), "%");
			if (iRPGMode >= 0 && IsPlayerAlive(client)) {

				if (iIsLevelingPaused[client] == 1 || PlayerLevel[client] >= iMaxLevel || PlayerLevel[client] >= iHardcoreMode && fDeathPenalty > 0.0 && (iDeathPenaltyPlayers < 1 || TotalHumanSurvivors() >= iDeathPenaltyPlayers)) ConfirmExperienceActionTalents(client, true);

				if (iIsLevelingPaused[client] == 1 || PlayerLevel[client] >= iMaxLevel) {

					ExperienceOverall[client] -= (ExperienceLevel[client] - 1);
					ExperienceLevel[client] = 1;
				}

				int LivingHumansCounter = LivingSurvivors() - 1;
				if (LivingHumansCounter < 0) LivingHumansCounter = 0;

				PrintToChatAll("%t", "teammate has died", blue, PlayerName, orange, green, (LivingHumansCounter * fSurvivorExpMult) * 100.0, pct);
				if (RoundExperienceMultiplier[client] > 0.0) {

					PrintToChatAll("%t", "bonus container burst", blue, PlayerName, orange, green, 100.0 * RoundExperienceMultiplier[client], orange, pct);
					BonusContainer[client] = 0;
					RoundExperienceMultiplier[client] = 0.0;
				}
			}

			char text[512];
			char ColumnName[64];
			//new TheGameMode = ReadyUp_GetGameMode();
			if (Rating[client] > BestRating[client]) {

				BestRating[client] = Rating[client];
				Format(ColumnName, sizeof(ColumnName), "%s", sDbLeaderboards);
				if (StrEqual(ColumnName, "-1")) {

					if (ReadyUpGameMode != 3) Format(ColumnName, sizeof(ColumnName), "%s", COOPRECORD_DB);
					else Format(ColumnName, sizeof(ColumnName), "%s", SURVRECORD_DB);
				}
				Format(text, sizeof(text), "UPDATE `%s` SET `%s` = '%d' WHERE `steam_id` = '%s';", TheDBPrefix, ColumnName, BestRating[client], PlayerID);
				SQL_TQuery(hDatabase, QueryResults, text, client);
			}
			//if (ReadyUpGameMode != 3)
			CheckForRatingLossOnDeath(client);

			if (!isPlayerASurvivorBot) {

				char MyName[64];
				GetClientName(client, MyName, sizeof(MyName));
				if (!CheckServerLevelRequirements(client)) {

					PrintToChatAll("%t", "player no longer eligible", blue, MyName, orange);
					return;
				}
			}
			RaidInfectedBotLimit();

			if (iIsLifelink == 1 && !bIsLifelinkPenalty) {	// prevents looping

				for (int i = 1; i <= MaxClients; i++) {

					if (IsLegitimateClientAlive(i) && myCurrentTeam[i] == TEAM_SURVIVOR) IncapacitateOrKill(i, _, _, true, true);		// second true prevents this loop from being triggered by the function.
				}
			}
			if (iResetPlayerLevelOnDeath == 1) {
				if (!IsFakeClient(client)) PlayerLevel[client] = iPlayerStartingLevel;
				else PlayerLevel[client] = iBotPlayerStartingLevel;
				SkyLevel[client] = 0;
				ExperienceLevel[client] = 0;
				ExperienceOverall[client] = 0;
			}
			ForcePlayerSuicide(client);
			iCurrentIncapCount[client] = 0;
			iThreatLevel[client] = 0;
			bIsGiveProfileItems[client] = true;		// so when the player returns to life, their weapon loadout for that profile will be given to them.
			MyBirthday[client] = 0;
			bIsInCombat[client] = false;
			MyRespawnTarget[client] = client;

			RefreshSurvivor(client);

			GetAbilityStrengthByTrigger(client, attacker, TRIGGER_E, _, 0);
			if (attacker > 0) GetAbilityStrengthByTrigger(attacker, client, TRIGGER_e, _, healthvalue);
			if (IsLegitimateClientAlive(attacker) && FindZombieClass(attacker) == ZOMBIECLASS_TANK) {

				if (IsFakeClient(attacker)) ChangeTankState(attacker, TANKSTATE_DEATH);
			}
			if (!IsFakeClient(client)) SavePlayerData(client);
		}
		else if (!isClientIncapacitated) ForceIncapSurvivor(client, attacker, healthvalue);
	}
}

void CheckForRatingLossOnDeath(int client) {
	if (iHandicapLevelsAreScoreBased == 1 && PlayerLevel[client] >= iScoreLostOnDeathLevelRequired && fRatingPercentLostOnDeath > 0.0) {
		Rating[client] = RoundToCeil(Rating[client] * (1.0 - fRatingPercentLostOnDeath)) + 1;
		int minimumRating = RoundToCeil(BestRating[client] * fRatingFloor);
		if (Rating[client] < minimumRating) Rating[client] = minimumRating;

		if (handicapLevel[client] > 0 && handicapLevel[client] <= GetArraySize(a_HandicapLevels)) {
			OnDeathHandicapValues[client]	= GetArrayCell(a_HandicapLevels, handicapLevel[client]-1, 1);
			int scoreRequired	 = GetArrayCell(OnDeathHandicapValues[client], HANDICAP_SCORE_REQUIRED);

			if (Rating[client] < scoreRequired) {
				handicapLevel[client] = 0;
				SetClientHandicapValues(client);
				FormatPlayerName(client);
				PrintToChat(client, "\x04Score requirement for current handicap level not met. \x03Handicap level reset.");
			}
		}
	}
	else if (iHandicapLevelsAreScoreBased != 1 && handicapLevel[client] > 0) {
		if (PlayerLevel[client] >= iScoreLostOnDeathLevelRequired && fRatingPercentLostOnDeath > 0.0) {
			Rating[client] = RoundToCeil(Rating[client] * (1.0 - fRatingPercentLostOnDeath)) + 1;
			int minRating = RoundToCeil(BestRating[client] * fRatingFloor);
			if (Rating[client] < minRating) Rating[client] = minRating;
		}
		handicapLevel[client]--;
		handicapLevelAllowed[client] = handicapLevel[client];
		SetClientHandicapValues(client);
		FormatPlayerName(client);
		if (handicapLevel[client] > 0) PrintToChat(client, "\x04Handicap restricted.\n\x03Handicap set to \x05%d", handicapLevel[client]);
		else PrintToChat(client, "\x04Handicap disabled.");
	}
}