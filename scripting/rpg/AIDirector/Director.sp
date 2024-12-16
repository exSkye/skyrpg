public Action Timer_DirectorPurchaseTimer(Handle timer) {
	static Counter										=	-1;
	static float DirectorDelay							=	0.0;
	if (!b_IsActiveRound) {
		Counter											=	-1;
		return Plugin_Stop;
	}
	static theClient									=	-1;
	static theTankStartTime								=	-1;
	static int directorThoughtNotification = 0;
	directorThoughtNotification++;
	int iTankCount = GetInfectedCount(ZOMBIECLASS_TANK);
	int iTankLimit = GetSpecialInfectedLimit(true);
	int iInfectedCount = GetInfectedCount();
	int iSurvivors = TotalHumanSurvivors();
	int iSurvivorBots = TotalSurvivors() - iSurvivors;
	int LivingSerfs = LivingSurvivorCount();
	int requiredAlwaysTanks = GetAlwaysTanks(iSurvivors);
	int currentTime = GetTime();
	if (iSurvivorBots >= 2) iSurvivorBots /= 2;
	theClient = FindAnyRandomClient();
	if (requiredAlwaysTanks >= 1 && iTankCount < requiredAlwaysTanks && (iTanksAlwaysEnforceCooldown == 0 || f_TankCooldown == -1.0) || iTankRush == 1 && !b_IsFinaleActive && iTankCount < (iSurvivors + iSurvivorBots)) {
		ExecCheatCommand(theClient, "z_spawn_old", "tank auto");
	}
	else if (iTankRush == 0) {
		float fCurrentTime = GetEngineTime();
		if (fInfectedSpawnDelay < fCurrentTime && iInfectedCount < GetSpecialInfectedLimit()) {

			float fSpawnHandicap = fSpecialInfectedDelayHandicap * LivingSerfs;

			float fSpawnMinWait = fSpecialInfectedMinDelay - fSpawnHandicap;
			if (fSpawnMinWait < fSpecialInfectedDelayMin) fSpawnMinWait = fSpecialInfectedDelayMin;

			float fSpawnMaxWait = fSpecialInfectedMaxDelay - fSpawnHandicap;
			if (fSpawnMaxWait - fSpecialInfectedDelayRangeMin <= fSpawnMinWait) fSpawnMaxWait = fSpawnMinWait + fSpecialInfectedDelayRangeMin;

			float fSpawnDelayNext = GetRandomFloat(fSpawnMinWait, fSpawnMaxWait);

			fInfectedSpawnDelay = fCurrentTime + fSpawnDelayNext;
			if (!SurvivorsBeingQuiet()) SpawnAnyInfected(theClient);
		}
	}
	if (Counter == -1 || b_IsSurvivalIntermission || LivingSerfs < 1) {

		Counter = RoundToCeil(currentTime + DirectorDelay);
		return Plugin_Continue;
	}
	else if (Counter > currentTime) {

		// We still spawn specials, out of range of players to enforce the active special limit.
		return Plugin_Continue;
	}
	if (iDirectorThinkingAdvertisementTime > 0 && directorThoughtNotification % iDirectorThinkingAdvertisementTime == 0) PrintToChatAll("%t", "Director Think Process", orange, white);
	DirectorDelay	 = (fDirectorThoughtHandicap > 0.0 && LivingSerfs-1 > 0) ? fDirectorThoughtDelay - ((LivingSerfs-1) * fDirectorThoughtHandicap) : fDirectorThoughtDelay;
	if (DirectorDelay < fDirectorThoughtProcessMinimum) DirectorDelay = fDirectorThoughtProcessMinimum;
	Counter = RoundToCeil(currentTime + DirectorDelay);
	int size				=	GetArraySize(a_DirectorActions);
	for (int i = 1; i <= MaximumPriority; i++) { CheckDirectorActionPriority(i, size); }
	return Plugin_Continue;
}

stock GetAlwaysTanks(survivors) {
	if (iTanksAlways > 0) return iTanksAlways;
	if (iTanksAlways < 0) {
		return RoundToFloor((survivors * 1.0)/(iTanksAlways * -1));
	}
	return 0;
}

public Action Timer_DirectorActions_Cooldown(Handle timer, any pos) {
	SetArrayCell(a_DirectorActions_Cooldown, pos, 0);
	return Plugin_Stop;
}

stock CheckDirectorActionPriority(pos, size) {
	char talentName[64];
	for (int i = 0; i < size; i++) {
		int isActionOnCooldown = GetArrayCell(a_DirectorActions_Cooldown, i);
		if (isActionOnCooldown > 0) continue;			// Purchase still on cooldown.
		
		DirectorKeys					=	GetArrayCell(a_DirectorActions, i, 2);
		GetArrayString(DirectorKeys, 0, talentName, sizeof(talentName));

		DirectorValues					=	GetArrayCell(a_DirectorActions, i, 1);
		int thisActionPriority = GetArrayCell(DirectorValues, POINTS_PRIORITY);
		if (thisActionPriority != pos) continue;
		if (!DirectorPurchase_Valid(DirectorValues, i)) continue;
		DirectorPurchase(DirectorValues, i, talentName);
	}
}

stock bool DirectorPurchase_Valid(Handle Values, pos) {
	int isActionOnCooldown = GetArrayCell(a_DirectorActions_Cooldown, pos);
	if (isActionOnCooldown > 0) return false;

	int numLivingHumanSurvivors = LivingHumanSurvivors();

	float PointCost	= GetArrayCell(Values, POINTS_POINT_COST);
	float PointCostHandicap = GetArrayCell(Values, POINTS_HANDICAP_COST);
	PointCostHandicap *= numLivingHumanSurvivors;
	PointCost += PointCostHandicap;
	if (PointCost > 1.0) PointCost = 1.0;

	float PointCostMin = GetArrayCell(Values, POINTS_POINT_COST_MINIMUM);
	float PointCostMinHandicap = GetArrayCell(Values, POINTS_HANDICAP_COST_MINIMUM);
	PointCostMinHandicap *= numLivingHumanSurvivors;
	PointCostMin += PointCostMinHandicap;

	if (Points_Director > 0.0) PointCost *= Points_Director;
	if (PointCost < PointCostMin) PointCost = PointCostMin;

	if (Points_Director >= PointCost) return true;
	return false;
}

stock bool bIsDirectorTankEligible() {

	if (ActiveTanks() < DirectorTankLimit()) return true;
	return false;
}

stock DirectorTankLimit() {
	return GetSpecialInfectedLimit(true);
}

stock DirectorPurchase(Handle Values, pos, char[] TalentName) {
	// These calls are all ordered to squeeze every last bit of performance as possible.
	char Command[64];
	GetArrayString(Values, POINTS_COMMAND, Command, 64);
	if (b_IsFinaleActive && StrBeginsWith(Command, "director_force")) return;

	int numLivingHumanSurvivors = LivingHumanSurvivors()-1;
	int numLivingSurvivors = LivingSurvivorCount()-1;

	char Parameter[64];
	GetArrayString(Values, POINTS_PARAMETER, Parameter, 64);
	int Count					=	GetArrayCell(Values, POINTS_COUNT);
	int CountHandicap			=	GetArrayCell(Values, POINTS_COUNT_HANDICAP);
	Count += (CountHandicap * numLivingSurvivors);
	if (StrEqual(Parameter, "common") && GetArraySize(CommonInfectedQueue) + Count >= GetCommonQueueLimit()) return;

	bool bIsEnrage = IsEnrageActive();
	if (DirectorWitchLimit == 0) DirectorWitchLimit = numLivingSurvivors;
	int numActiveTanks = ActiveTanks();

	if (StrBeginsWith(Parameter, "witch") && (IsSurvivalMode || GetArraySize(WitchList) + 1 >= DirectorWitchLimit)) return;
	if (StrBeginsWith(Parameter, "tank") && (IsSurvivalMode || (numActiveTanks >= DirectorTankLimit() && !bIsEnrage || bIsEnrage && numActiveTanks >= numLivingHumanSurvivors) || f_TankCooldown != -1.0)) return;

	float PointCost				=	GetArrayCell(Values, POINTS_POINT_COST);
	float PointCostHandicap		=	GetArrayCell(Values, POINTS_HANDICAP_COST);
	PointCostHandicap *= numLivingHumanSurvivors;
	PointCost += PointCostHandicap;

	float PointCostMin			=	GetArrayCell(Values, POINTS_POINT_COST_MINIMUM);
	float PointCostMinHandicap	=	GetArrayCell(Values, POINTS_HANDICAP_COST_MINIMUM);
	PointCostMinHandicap *= numLivingHumanSurvivors;
	PointCostMin = PointCostMin + (PointCostMin * PointCostMinHandicap);

	int IsPlayerDrop			=	GetArrayCell(Values, POINTS_DROP);

	char Model[64];
	GetArrayString(Values, POINTS_MODEL, Model, 64);
	
	float MinimumDelay			=	GetArrayCell(Values, POINTS_MINIMUM_DELAY);

	if (PointCost > 1.0) {
		PointCost			=	1.0;
	}
	if (Points_Director > 0.0) PointCost *= Points_Director;
	if (PointCost < PointCostMin) PointCost = PointCostMin;
	if (Points_Director < PointCost) return;

	int numLivingSurvivorsRequired = GetArrayCell(Values, POINTS_LIVING_SURVIVORS);
	if (numLivingSurvivors < numLivingSurvivorsRequired) return;

	int Client				=	FindLivingSurvivor();
	if (Client < 1) return;

	char sTalentName[64];
	Format(sTalentName, sizeof(sTalentName), "%t", TalentName);
	PrintToChatAll("%t", "director purchase announcement", orange, blue, green, sTalentName, orange, green, PointCost, orange);
	Points_Director -= PointCost;

	if (!bIsEnrage && MinimumDelay > 0.0) {
		SetArrayCell(a_DirectorActions_Cooldown, pos, 1);
		float fDelayHandicap = GetArrayCell(Values, POINTS_HANDICAP_DELAY);
		if (numLivingHumanSurvivors > 0) {
			MinimumDelay = MinimumDelay - (numLivingHumanSurvivors * fDirectorThoughtHandicap) - (fDelayHandicap * numLivingHumanSurvivors);
		}
		if (MinimumDelay < 0.0) MinimumDelay = 1.0;
		if (numLivingHumanSurvivors > 0) {
			fDirectorThoughtDelay = fDirectorThoughtDelay - (numLivingHumanSurvivors * fDirectorThoughtHandicap);
		}
		if (fDirectorThoughtDelay < 0.0) {
			fDirectorThoughtDelay = 0.0;
		}
		CreateTimer(fDirectorThoughtDelay + MinimumDelay, Timer_DirectorActions_Cooldown, pos, TIMER_FLAG_NO_MAPCHANGE);
	}

	if (!StrEqual(Parameter, "common")) ExecCheatCommand(Client, Command, Parameter);
	else {
		char superCommonType[64];
		GetArrayString(Values, POINTS_SUPERCOMMON, superCommonType, 64);
		SpawnCommons(Client, Count, Command, Parameter, Model, IsPlayerDrop, superCommonType);
	}
}