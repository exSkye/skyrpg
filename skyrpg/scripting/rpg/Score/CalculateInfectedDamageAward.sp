void CalculateInfectedDamageAward(int client, int killerblow = 0, int superPos = -1) {
	bool IsLegitimateClientClient = IsLegitimateClient(client);
	int clientTeam = -1;
	if (IsLegitimateClientClient) clientTeam = myCurrentTeam[client];
	int clientZombieClass = -1;
	if (clientTeam != -1) clientZombieClass = FindZombieClass(client);
	int ClientType =	(IsLegitimateClientClient && clientTeam == TEAM_INFECTED) ? 0 :
						(IsWitch(client)) ? 1 :
						(IsSpecialCommon(client)) ? 2 : 3;
	bool IsLegitimateClientKiller = IsLegitimateClient(killerblow);
	int killerClientTeam = -1;
	if (IsLegitimateClientKiller) killerClientTeam = myCurrentTeam[killerblow];
	/*if (ClientType >= 0 && IsLegitimateClientKiller && killerClientTeam == TEAM_SURVIVOR) {
		if (isQuickscopeKill(killerblow)) {
			// If the user met the server operators standards for a quickscope kill, we do something.
			GetAbilityStrengthByTrigger(killerblow, client, "quickscope");
		}
	}*/
	//CreateItemRoll(client, killerblow);	// all infected types can generate an item roll
	float SurvivorPoints = 0.0;
	int SurvivorExperience = 0;
	float PointsMultiplier = fPointsMultiplier;
	float ExperienceMultiplier = SurvivorExperienceMult;
	float TankingMultiplier = SurvivorExperienceMultTank;
	//new Float:HealingMultiplier = SurvivorExperienceMultHeal;
	//new Float:RatingReductionMult = 0.0;
	int t_Contribution = 0;
	float TheAbilityMultiplier = 0.0;
	if (IsLegitimateClientKiller && ClientType == 0 && killerClientTeam == TEAM_SURVIVOR) {
		GetAbilityStrengthByTrigger(killerblow, client, TRIGGER_specialkill);
		TheAbilityMultiplier = GetAbilityMultiplier(killerblow, "I");
		if (TheAbilityMultiplier > 0.0) { // heal because you dealt the killing blow
			HealPlayer(killerblow, killerblow, TheAbilityMultiplier * GetMaximumHealth(killerblow), 'h', true);
		}
		TheAbilityMultiplier = GetAbilityMultiplier(killerblow, "l");
		if (TheAbilityMultiplier > 0.0) {
			// Creates fire on the target and deals AOE explosion.
			CreateExplosion(client, RoundToCeil(lastBaseDamage[killerblow] * TheAbilityMultiplier), killerblow, true);
			CreateFireEx(client);
		}
	}
	//new owner = 0;
	//if (IsLegitimateClientAlive(commonkiller) && GetClientTeam(commonkiller) == TEAM_SURVIVOR) owner = commonkiller;
	float i_DamageContribution = 0.0000;
	// If it's a special common, we activate its death abilities.
	int posOverride = -1;
	if (ClientType == 2) {
		char TheEffect[10];
		posOverride = FindListPositionByEntity(client, CommonAffixes);
		GetCommonValueAtPosEx(TheEffect, sizeof(TheEffect), superPos, SUPER_COMMON_AURA_EFFECT);
		CreateBomberExplosion(client, client, TheEffect);	// bomber aoe
	}
	int iLivingSurvivors = LivingSurvivors();
	//decl String:MyName[64];
	char killerName[64];
	char killedName[64];
	if (ClientType != 3 && (ClientType > 0 || IsLegitimateClientClient)) {
		if (IsLegitimateClientClient) GetClientName(client, killedName, sizeof(killedName));
		else {
			if (ClientType == 1) Format(killedName, sizeof(killedName), "Witch");
			else {
				GetCommonValueAtPosEx(killedName, sizeof(killedName), superPos, SUPER_COMMON_NAME);
				Format(killedName, sizeof(killedName), "Super %s", killedName);
			}
		}
		if (iClientTypeToDisplayOnKill == -1 || ClientType <= iClientTypeToDisplayOnKill) {
			if (!IsLegitimateClientKiller) PrintToChatAll("%t", "killed special infected", orange, killedName, white);
			else {
				GetFormattedPlayerName(killerblow, killerName, sizeof(killerName));
				char advertisement[512];
				Format(advertisement, sizeof(advertisement), "%t", "player killed special infected", blue, killerName, white, orange, killedName);
				for (int i = 1; i <= MaxClients; i++) {
					if (!IsLegitimateClient(i) || IsFakeClient(i)) continue;
					Client_PrintToChat(i, true, advertisement);
				}
			}
		}
	}
	bool survivorsRequiredForBonusRating = (iLivingSurvivors > iTeamRatingRequired) ? true : false;
	bool bSomeoneHurtThisInfected = false;
	int infectedDamageTrackerPos = (ClientType == CLIENT_SPECIAL_INFECTED) ? FindListPositionByEntity(client, damageOfSpecialInfected) :
								(ClientType == CLIENT_WITCH) ? FindListPositionByEntity(client, damageOfWitch) :
								(ClientType == CLIENT_SUPER_COMMON) ? posOverride : FindListPositionByEntity(client, damageOfCommonInfected);
	
	for (int i = 1; i <= MaxClients; i++) {
		int SurvivorDamage = 0;
		int pos = -1;
		int RatingBonusTank = 0;
		int RatingBonusBuffing = 0;
		int RatingBonusHealing = 0;
		int RatingBonus = 0;
		int RatingTeamBonus = 0;
		int RatingTeamBonusTank = 0;
		int RatingTeamBonusBuffing = 0;
		int RatingTeamBonusHealing = 0;
		SurvivorExperience = 0;
		SurvivorPoints = 0.0;
		i_DamageContribution = 0.0000;

		if (!IsLegitimateClient(i) || myCurrentTeam[i] != TEAM_SURVIVOR) continue;
		if (ClientType == CLIENT_COMMON) {
			pos = FindListPositionByEntity(client, CommonInfected[i]);
			if (pos == -1) continue;

			SurvivorDamage = GetArrayCell(CommonInfected[i], pos, 2);
			//RemoveFromArray(CommonInfected[i], pos);
		}
		else if (ClientType == CLIENT_SPECIAL_INFECTED) {
			pos = FindListPositionByEntity(client, InfectedHealth[i]);
			if (pos == -1) continue;

			SurvivorDamage = GetArrayCell(InfectedHealth[i], pos, 2);
			//RemoveFromArray(InfectedHealth[i], pos);
		}
		else if (ClientType == CLIENT_WITCH) {
			pos = FindListPositionByEntity(client, WitchDamage[i]);
			if (pos == -1) continue;

			SurvivorDamage = GetArrayCell(WitchDamage[i], pos, 2);
			//RemoveFromArray(WitchDamage[i], pos);
		}
		else if (ClientType == CLIENT_SUPER_COMMON) {
			pos = FindListPositionByEntity(client, SpecialCommon[i]);
			if (pos == -1) continue;

			SurvivorDamage = GetArrayCell(SpecialCommon[i], pos, 2);
		}
		if (!IsPlayerAlive(i)) continue;
		// to prevent abuse farming of higher handicap levels, players must contribute a certain percentage in at least one category.
		float scoreMult = GetScoreMultiplier(i);
		if (scoreMult > 0.0) {
			RatingBonus = RoundToCeil(GetRatingRewardForDamage(i, client, pos, ClientType) * scoreMult);
			RatingBonusTank = RoundToCeil(GetRatingRewardForTanking(i, client, pos, ClientType) * scoreMult);
			if (ClientType <= 1) {
				RatingBonusBuffing = RoundToCeil(GetRatingRewardForBuffing(i, client, pos, ClientType) * scoreMult);
				RatingBonusHealing = RoundToCeil(GetRatingRewardForHealing(i, client, pos, ClientType, infectedDamageTrackerPos) * scoreMult);
			}
		}
		if (iAntiFarmMax > 0) {
			if (CheckKillPositions(i)) continue;
			CheckKillPositions(i, true);
		}
		if (killerblow != i) GetAbilityStrengthByTrigger(i, client, TRIGGER_assist);
		if (RatingBonus > 0 || RatingBonusTank > 0 || RatingBonusBuffing > 0 || RatingBonusHealing > 0) RollLoot(i, client);
		if (!bSomeoneHurtThisInfected) bSomeoneHurtThisInfected = true;
		CheckMinimumRate(i);
		if (PlayerLevel[i] >= iLevelRequiredToEarnScore || handicapLevel[i] > 0) {
			
			char ratingBonusText[64];
			char ratingBonusTankText[64];
			char ratingBonusBuffingText[64];
			char ratingBonusHealingText[64];
			if (!survivorsRequiredForBonusRating) {
				if (RatingBonus > 0) {
					if (ClientType <= iClientTypeToDisplayOnKill) {
						AddCommasToString(RatingBonus, ratingBonusText, sizeof(ratingBonusText));
						Format(ratingBonusText, sizeof(ratingBonusText), "%T", "rating increase", i, white, blue, ratingBonusText, orange);
					}
					Rating[i] += RatingBonus;
				}
				if (RatingBonusTank > 0) {
					if (ClientType <= iClientTypeToDisplayOnKill) {
						AddCommasToString(RatingBonusTank, ratingBonusTankText, sizeof(ratingBonusTankText));
						Format(ratingBonusTankText, sizeof(ratingBonusTankText), "%T", "rating increase for tanking", i, white, blue, ratingBonusTankText, orange);
					}
					Rating[i] += RatingBonusTank;
				}
				if (RatingBonusBuffing > 0) {
					if (ClientType <= iClientTypeToDisplayOnKill) {
						AddCommasToString(RatingBonusBuffing, ratingBonusBuffingText, sizeof(ratingBonusBuffingText));
						Format(ratingBonusBuffingText, sizeof(ratingBonusBuffingText), "%T", "rating increase for buffing", i, white, blue, ratingBonusBuffingText, orange);
					}
					Rating[i] += RatingBonusBuffing;
				}
				if (RatingBonusHealing > 0) {
					if (ClientType <= iClientTypeToDisplayOnKill) {
						AddCommasToString(RatingBonusHealing, ratingBonusHealingText, sizeof(ratingBonusHealingText));
						Format(ratingBonusHealingText, sizeof(ratingBonusHealingText), "%T", "rating increase for healing", i, white, blue, ratingBonusHealingText, orange);
					}
					Rating[i] += RatingBonusHealing;
				}
			}
			else {
				if (RatingBonus > 0) {
					RatingTeamBonus = RoundToCeil(RatingBonus * ((iLivingSurvivors - iTeamRatingRequired) * fTeamRatingBonus));
					if (ClientType <= iClientTypeToDisplayOnKill) {
						AddCommasToString(RatingBonus+RatingTeamBonus, ratingBonusText, sizeof(ratingBonusText));
						Format(ratingBonusText, sizeof(ratingBonusText), "%T", "rating increase", i, white, blue, ratingBonusText, orange);
					}
					Rating[i] += RatingBonus;
				}
				if (RatingBonusTank > 0) {
					RatingTeamBonusTank = RoundToCeil(RatingBonusTank * ((iLivingSurvivors - iTeamRatingRequired) * fTeamRatingBonus));
					if (ClientType <= iClientTypeToDisplayOnKill) {
						AddCommasToString(RatingBonusTank+RatingTeamBonusTank, ratingBonusTankText, sizeof(ratingBonusTankText));
						Format(ratingBonusTankText, sizeof(ratingBonusTankText), "%T", "rating increase for tanking", i, white, blue, ratingBonusTankText, orange);
					}
					Rating[i] += RatingBonusTank;
				}
				if (RatingBonusBuffing > 0) {
					RatingTeamBonusBuffing = RoundToCeil(RatingBonusBuffing * ((iLivingSurvivors - iTeamRatingRequired) * fTeamRatingBonus));
					if (ClientType <= iClientTypeToDisplayOnKill) {
						AddCommasToString(RatingBonusBuffing+RatingTeamBonusBuffing, ratingBonusBuffingText, sizeof(ratingBonusBuffingText));
						Format(ratingBonusBuffingText, sizeof(ratingBonusBuffingText), "%T", "rating increase for buffing", i, white, blue, ratingBonusBuffingText, orange);
					}
					Rating[i] += RatingBonusBuffing;
				}
				if (RatingBonusHealing > 0) {
					RatingTeamBonusHealing = RoundToCeil(RatingBonusHealing * ((iLivingSurvivors - iTeamRatingRequired) * fTeamRatingBonus));
					if (ClientType <= iClientTypeToDisplayOnKill) {
						AddCommasToString(RatingBonusHealing+RatingTeamBonusHealing, ratingBonusHealingText, sizeof(ratingBonusHealingText));
						Format(ratingBonusHealingText, sizeof(ratingBonusHealingText), "%T", "rating increase for healing", i, white, blue, ratingBonusHealingText, orange);
					}
					Rating[i] += RatingBonusHealing;
				}
			}
			if (!IsFakeClient(i) && ClientType <= iClientTypeToDisplayOnKill) {
				bool isModified = false;
				char printer[512];
				if (RatingBonus > 0) {
					isModified = true;
					Format(printer, sizeof(printer), "%s", ratingBonusText);
				}
				if (RatingBonusTank > 0) {
					if (isModified) Format(printer, sizeof(printer), "%s\n%s", printer, ratingBonusTankText);
					else {
						Format(printer, sizeof(printer), "%s", ratingBonusTankText);
						isModified = true;
					}
				}
				if (RatingBonusBuffing > 0) {
					if (isModified) Format(printer, sizeof(printer), "%s\n%s", printer, ratingBonusBuffingText);
					else {
						Format(printer, sizeof(printer), "%s", ratingBonusBuffingText);
						isModified = true;
					}
				}
				if (RatingBonusHealing > 0) {
					if (isModified) Format(printer, sizeof(printer), "%s\n%s", printer, ratingBonusHealingText);
					else Format(printer, sizeof(printer), "%s", ratingBonusHealingText);
				}
				if (isModified) PrintToChat(i, "%s", printer);
			}
		}
		bIsSettingsCheck = true;		// whenever rating is earned for anything other than common infected kills, we want to check the settings to see if a boost to commons is necessary.
		if (i == killerblow) {
			TheAbilityMultiplier = GetAbilityMultiplier(i, "R");
			if (TheAbilityMultiplier > 0.0) { // heal because you dealt the killing blow
				HealPlayer(i, i, TheAbilityMultiplier * RatingBonus, 'h', true);
			}
		}
		// if (SurvivorDamage > 0) {
		// 	SurvivorExperience = RoundToFloor(SurvivorDamage * ExperienceMultiplier);
		// 	SurvivorPoints = SurvivorDamage * PointsMultiplier;
		// }
		i_DamageContribution = CheckTeammateDamages(client, i, true);
		if (i_DamageContribution > 0.0) {
			SurvivorExperience = RoundToFloor(SurvivorDamage * ExperienceMultiplier);
			SurvivorPoints = SurvivorDamage * PointsMultiplier;
		}
		if (ClientType != 3 && RatingBonusTank > 0) {
			t_Contribution = CheckTankingDamage(i, ClientType, pos);
			if (t_Contribution > 0) {
				t_Contribution = RoundToCeil(t_Contribution * TankingMultiplier);
				SurvivorPoints += (t_Contribution * (PointsMultiplier * TankingMultiplier));
			}
		}
		//h_Contribution = HealingContribution[i];
		//HealingContribution[i] = 0;
		//CreateLootItem(i, i_DamageContribution, CheckTankingDamage(client, i), RoundToCeil(h_Contribution * HealingMultiplier));
		// if (h_Contribution > 0) {
		// 	h_Contribution = RoundToCeil(h_Contribution * HealingMultiplier);
		// 	SurvivorPoints += (h_Contribution * (PointsMultiplier * HealingMultiplier));
		// }
		//if (!bIsInCombat[i]) ReceiveInfectedDamageAward(i, client, SurvivorExperience, SurvivorPoints, t_Contribution, h_Contribution, Bu_Contribution, He_Contribution);
		//HealingContribution[i] += h_Contribution;
		TankingContribution[i] += t_Contribution;
		PointsContribution[i] += SurvivorPoints;
		DamageContribution[i] += SurvivorExperience;
	}
	if (ClientType != CLIENT_SUPER_COMMON && infectedDamageTrackerPos >= 0) {
		if (ClientType == CLIENT_SPECIAL_INFECTED) RemoveFromArray(damageOfSpecialInfected, infectedDamageTrackerPos);
		else if (ClientType == CLIENT_WITCH) RemoveFromArray(damageOfWitch, infectedDamageTrackerPos);
		else if (ClientType == CLIENT_COMMON) RemoveFromArray(damageOfCommonInfected, infectedDamageTrackerPos);
	}
	if (bSomeoneHurtThisInfected) {
		if (ClientType == 0) {
			ReadyUp_NtvStatistics(killerblow, 6, 1);
			if (clientZombieClass != ZOMBIECLASS_TANK) numberOfSpecialsKilledThisRound++;
			else numberOfTanksKilledThisRound++;

			if (IsFakeClient(client)) {
				float fDirectorPointsEarned = (DamageContribution[client] * fPointsMultiplierInfected);
				if (!IsSurvivalMode && iEnrageTime > 0 && RPGRoundTime() >= iEnrageTime) fDirectorPointsEarned *= fEnrageDirectorPoints;
				if (fDirectorPointsEarned > 0.0) {
					Points_Director += fDirectorPointsEarned;
					// decl String:InfectedName[64];
					// GetClientName(client, InfectedName, sizeof(InfectedName));
					// PrintToChatAll("%t", "director points earned", orange, green, fDirectorPointsEarned, orange, InfectedName);
					DamageContribution[client] = 0;
				}
			}
		}
		else if (ClientType == 1) numberOfWitchesKilledThisRound++;
		else if (ClientType == 2) {
			if (CommonInfectedModel(client, FALLEN_SURVIVOR_MODEL) && killerClientTeam == TEAM_SURVIVOR) {
				float fModifiedDefibChance = fFallenSurvivorDefibChance;
				int curLuck = GetTalentStrength(killerblow, "luck");
				if (curLuck > 0) fModifiedDefibChance += (curLuck * fFallenSurvivorDefibChanceLuck);
				if (fModifiedDefibChance >= 1.0 || GetRandomInt(1, RoundToCeil(1.0 / fModifiedDefibChance)) == 1) {
					int defib = CreateEntityByName("weapon_defibrillator_spawn");
					float vel[3];
					vel[0] = GetRandomFloat(-10000.0, 1000.0);
					vel[1] = GetRandomFloat(-1000.0, 1000.0);
					vel[2] = GetRandomFloat(100.0, 1000.0);

					float Origin[3];
					GetEntPropVector(client, Prop_Send, "m_vecOrigin", Origin);
					Origin[2] += 32.0;
					DispatchKeyValue(defib, "spawnflags", "1");
					DispatchSpawn(defib);
					ActivateEntity(defib);
					TeleportEntity(defib, Origin, NULL_VECTOR, vel);
				}
			}
			numberOfSupersKilledThisRound++;
			ReadyUp_NtvStatistics(killerblow, 2, 1);
		}
		else if (ClientType == 3) {
			ReadyUp_NtvStatistics(killerblow, 2, 1);
			numberOfCommonsKilledThisRound++;
		}
	}
	if (IsLegitimateClientClient && clientTeam == TEAM_INFECTED) {

		if (clientZombieClass == ZOMBIECLASS_TANK) bIsDefenderTank[client] = false;

		if (iTankRush != 1 && clientZombieClass == ZOMBIECLASS_TANK && DirectorTankCooldown > 0.0 && f_TankCooldown == -1.0) {

			f_TankCooldown				=	DirectorTankCooldown;

			CreateTimer(1.0, Timer_TankCooldown, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
		}
		ClearArray(TankState_Array[client]);
		MyBirthday[client] = 0;
		CreateMyHealthPool(client, true);
		ChangeHook(client);
		ForcePlayerSuicide(client);

		if (b_IsFinaleActive && GetInfectedCount(ZOMBIECLASS_TANK) < 1) {

			b_IsFinaleTanks = true;	// next time the event tank spawns, it will allow it to spawn multiple tanks.
		}
	}
}