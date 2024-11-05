public ReadyUp_ReadyUpStart() {
	lootDropCounter = 0;	// reset the loot drop counter.
	CheckDifficulty();
	RoundTime = 0;
	b_IsRoundIsOver = true;
	iTopThreat = 0;
	SetSurvivorsAliveHostname();
	CreateTimer(1.0, Timer_AutoRes, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
	/*
	When a new round starts, we want to forget who was the last person to speak on different teams.
	*/
	Format(Public_LastChatUser, sizeof(Public_LastChatUser), "none");
	Format(Spectator_LastChatUser, sizeof(Spectator_LastChatUser), "none");
	Format(Survivor_LastChatUser, sizeof(Survivor_LastChatUser), "none");
	Format(Infected_LastChatUser, sizeof(Infected_LastChatUser), "none");
	bool TeleportPlayers = false;
	float teleportIntoSaferoom[3];
	if (StrEqual(TheCurrentMap, "zerowarn_1r", false)) {
		teleportIntoSaferoom[0] = 4087.998291;
		teleportIntoSaferoom[1] = 11974.557617;
		teleportIntoSaferoom[2] = -300.968750;
		TeleportPlayers = true;
	}

	for (int i = 1; i <= MaxClients; i++) {
		if (!IsLegitimateClient(i) || !b_IsLoaded[i]) continue;
		if (myCurrentTeam[i] == TEAM_SURVIVOR && ReadyUpGameMode != 3) {
			CreateTimer(1.0, Timer_Pregame, i, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
		}
		if (TeleportPlayers) TeleportEntity(i, teleportIntoSaferoom, NULL_VECTOR, NULL_VECTOR);
		staggerCooldownOnTriggers[i] = false;
		ISBILED[i] = false;
		iThreatLevel[i] = 0;
		bIsEligibleMapAward[i] = true;
		HealingContribution[i] = 0;
		TankingContribution[i] = 0;
		DamageContribution[i] = 0;
		PointsContribution[i] = 0.0;
		HexingContribution[i] = 0;
		BuffingContribution[i] = 0;
		b_IsFloating[i] = false;
		ISDAZED[i] = 0.0;
		bIsInCombat[i] = false;
		b_IsInSaferoom[i] = true;
		// Anti-Farm/Anti-Camping system stuff.
		ClearArray(h_KilledPosition[i]);		// We clear all positions from the array.
		if (!IsFakeClient(i)) continue;
		if (b_IsLoaded[i]) GiveMaximumHealth(i);
	}
	RefreshSurvivorBots();
}

public ReadyUp_ReadyUpEnd() {
	ReadyUpEnd_Complete();
}

public ReadyUpEnd_Complete() {

	if (b_IsRoundIsOver) {
		b_IsRoundIsOver = false;
		CreateTimer(30.0, Timer_CheckDifficulty, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
		CheckDifficulty();
		b_IsMissionFailed = false;
		ClearArray(CommonAffixes);
		b_IsCheckpointDoorStartOpened = false;
		char pct[4];
		Format(pct, sizeof(pct), "%");
		for (int i = 1; i <= MaxClients; i++) {
			if (!IsLegitimateClient(i)) continue;
			if (IsFakeClient(i) && !b_IsLoaded[i]) IsClientLoadedEx(i);
			if (!IsFakeClient(i) && RoundExperienceMultiplier[i] > 0.0) {
				char saferoomName[64];
				GetClientName(i, saferoomName, sizeof(saferoomName));
				PrintToChatAll("%t", "round bonus multiplier", blue, saferoomName, white, orange, (1.0 + RoundExperienceMultiplier[i]) * 100.0, orange, pct, white);
			}
		}
		for (int i = 1; i <= MaxClients; i++) {
			if (!IsLegitimateClient(i) || !b_IsLoaded[i]) continue;
			staggerCooldownOnTriggers[i] = false;
			ISBILED[i] = false;
			bHasWeakness[i] = 0;
			SurvivorEnrage[i][0] = 0.0;
			SurvivorEnrage[i][1] = 0.0;
			ISDAZED[i] = 0.0;
			if (myCurrentTeam[i] == TEAM_SURVIVOR) {
				SurvivorStamina[i] = GetPlayerStamina(i) - 1;
				SetMaximumHealth(i);
				GiveMaximumHealth(i);
			}
			bIsSurvivorFatigue[i] = false;
			LastWeaponDamage[i] = 1;
			HealingContribution[i] = 0;
			TankingContribution[i] = 0;
			DamageContribution[i] = 0;
			PointsContribution[i] = 0.0;
			HexingContribution[i] = 0;
			BuffingContribution[i] = 0;
			b_IsFloating[i] = false;
			//SetMyWeapons(i);
		}
	}
}

public ReadyUp_CheckpointDoorStartOpened() {
	if (!b_IsCheckpointDoorStartOpened) {
		b_IsCheckpointDoorStartOpened		= true;
		SetBotClientHandicapValues();
		b_IsRescueVehicleArrived = false;
		b_IsActiveRound = true;
		bIsSettingsCheck = true;
		IsEnrageNotified = false;
		b_IsFinaleTanks = false;
		ClearArray(ListOfWitchesWhoHaveBeenShot);
		ClearArray(persistentCirculation);
		ClearArray(CoveredInVomit);
		if (CurrentMapPosition == 0) {
			iTotalCampaignTime = 0;
			numberOfCommonsKilledThisCampaign = 0;
			numberOfCommonsKilledThisRound = 0;
			numberOfSupersKilledThisCampaign = 0;
			numberOfSupersKilledThisRound = 0;
			numberOfWitchesKilledThisCampaign = 0;
			numberOfWitchesKilledThisRound = 0;
			numberOfSpecialsKilledThisCampaign = 0;
			numberOfSpecialsKilledThisRound = 0;
			numberOfTanksKilledThisCampaign = 0;
			numberOfTanksKilledThisRound = 0;
		}
		else {
			numberOfCommonsKilledThisRound = 0;
			numberOfSupersKilledThisRound = 0;
			numberOfWitchesKilledThisRound = 0;
			numberOfSpecialsKilledThisRound = 0;
			numberOfTanksKilledThisRound = 0;
		}
		char pct[4];
		Format(pct, sizeof(pct), "%");
		char text[64];
		int survivorCounter = TotalHumanSurvivors();
		bool AnyBotsOnSurvivorTeam = BotsOnSurvivorTeam();
		for (int i = 1; i <= MaxClients; i++) {
			if (!IsLegitimateClient(i)) continue;
			//SetMyWeapons(i);
			if (IsFakeClient(i)) continue;
			bIsMeleeCooldown[i] = false;
			iCurrentIncapCount[i] = 0;
			if (GroupMemberBonus > 0.0) {
				if (IsGroupMember[i]) PrintToChat(i, "%T", "group member bonus", i, blue, GroupMemberBonus * 100.0, pct, green, orange);
				else PrintToChat(i, "%T", "group member benefit", i, orange, blue, GroupMemberBonus * 100.0, pct, green, blue);
			}
			if (!AnyBotsOnSurvivorTeam && fSurvivorBotsNoneBonus > 0.0 && survivorCounter <= iSurvivorBotsBonusLimit) PrintToChat(i, "%T", "group no survivor bots bonus", i, blue, fSurvivorBotsNoneBonus * 100.0, pct, green, orange);
			if (RoundExperienceMultiplier[i] > 0.0) PrintToChat(i, "%T", "survivalist bonus experience", i, blue, orange, green, RoundExperienceMultiplier[i] * 100.0, white, pct);
		}
		CheckDifficulty();
		RoundTime					=	GetTime();
		int ent = -1;
		if (ReadyUpGameMode != 3) {
			while ((ent = FindEntityByClassname(ent, "witch")) != -1) {
				// Some maps, like Hard Rain pre-spawn a ton of witches - we want to add them to the witch table.
				OnWitchCreated(ent);
				SDKHook(ent, SDKHook_OnTakeDamage, OnTakeDamage);
				SDKHook(ent, SDKHook_TraceAttack, OnTraceAttack);
			}
			char thetext[64];
			GetConfigValue(thetext, sizeof(thetext), "path setting?");
			if (ReadyUpGameMode != 3 && !StrEqual(thetext, "none")) {
				if (!StrEqual(thetext, "random")) ServerCommand("sm_forcepath %s", thetext);
				else {
					if (StrEqual(PathSetting, "none")) {
						int random = GetRandomInt(1, 100);
						if (random <= 33) Format(PathSetting, sizeof(PathSetting), "easy");
						else if (random <= 66) Format(PathSetting, sizeof(PathSetting), "medium");
						else Format(PathSetting, sizeof(PathSetting), "hard");
					}
					ServerCommand("sm_forcepath %s", PathSetting);
				}
			}
		}
		else {
			IsSurvivalMode = true;
		}
		b_IsCampaignComplete				= false;
		if (ReadyUpGameMode != 3) b_IsRoundIsOver						= false;
		if (ReadyUpGameMode == 2) MapRoundsPlayed = 0;	// Difficulty leniency does not occur in versus.
		//RoundDamageTotal			=	0;
		b_IsFinaleActive			=	false;
		for (int i = 1; i <= MaxClients; i++) {
			if (!IsLegitimateClient(i) || !b_IsLoaded[i] || myCurrentTeam[i] != TEAM_SURVIVOR) continue;
			if (!IsPlayerAlive(i)) SDKCall(hRoundRespawn, i);
			VerifyMinimumRating(i);
			HealImmunity[i] = false;
			if (b_IsLoaded[i]) {
				SetMaximumHealth(i);
				GiveMaximumHealth(i);
			}
		}
		f_TankCooldown				=	-1.0;
		ResetCDImmunity(-1);
		DoomTimer = 0;
		if (ReadyUpGameMode != 2 && fDirectorThoughtDelay > 0.0) CreateTimer(1.0, Timer_DirectorPurchaseTimer, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
		if (RespawnQueue > 0) CreateTimer(1.0, Timer_RespawnQueue, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
		RaidInfectedBotLimit();
		CreateTimer(1.0, Timer_StartPlayerTimers, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
		CreateTimer(1.0, Timer_CheckIfHooked, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
		CreateTimer(GetConfigValueFloat("settings check interval?"), Timer_SettingsCheck, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
		if (DoomSUrvivorsRequired != 0) CreateTimer(1.0, Timer_Doom, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
		CreateTimer(fDebuffTickrate, Timer_EntityOnFire, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);		// Fire status effect
		CreateTimer(1.0, Timer_ThreatSystem, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);		// threat system modulator
		CreateTimer(fStaggerTickrate, Timer_StaggerTimer, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
		CreateTimer(fSuperCommonTickrate, Timer_SetNumberOfEntitiesWithinRangeOfSpecialCommon, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
		//CreateTimer(fDrawHudInterval, Timer_ShowHUD, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
		//CreateTimer(fSpecialAmmoInterval, Timer_ShowActionBar, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
		if (iCommonAffixes > 0) {
			ClearArray(CommonAffixes);
			CreateTimer(1.0, Timer_CommonAffixes, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
		}
		ClearRelevantData();
		LastLivingSurvivor = 1;
		int size = GetArraySize(a_DirectorActions);
		ResizeArray(a_DirectorActions_Cooldown, size);
		for (int i = 0; i < size; i++) SetArrayString(a_DirectorActions_Cooldown, i, "0");
		int theCount = LivingSurvivorCount();
		if (iSurvivorModifierRequired > 0 && fSurvivorExpMult > 0.0 && theCount >= iSurvivorModifierRequired) {
			PrintToChatAll("%t", "teammate bonus experience", blue, green, ((theCount - (iSurvivorModifierRequired - 1)) * fSurvivorExpMult) * 100.0, pct);
		}
		RefreshSurvivorBots();
		if (iResetDirectorPointsOnNewRound == 1) Points_Director = 0.0;
		char currentMapEnrageTimerText[64];
		Format(currentMapEnrageTimerText, sizeof(currentMapEnrageTimerText), "enrage time %s?", TheCurrentMap);
		int iEnrageTimeCurrentMap			= GetConfigValueInt(currentMapEnrageTimerText);
		if (iEnrageTimeCurrentMap > 0) {
			iEnrageTime							= iEnrageTimeCurrentMap;
			iHideEnrageTimerUntilSecondsLeft	= iEnrageTime/3;
		}
		else LogMessage("No custom enrage timer cvar found in your config.cfg: %s", currentMapEnrageTimerText);

		if (iEnrageTime > 0) {
			TimeUntilEnrage(text, sizeof(text));
			PrintToChatAll("%t", "time until things get bad", orange, green, text, orange);
		}
	}
}