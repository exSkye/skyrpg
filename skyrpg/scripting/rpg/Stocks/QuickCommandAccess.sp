stock bool QuickCommandAccess(client, args, bool b_IsTeamOnly) {

	if (IsLegitimateClient(client) && myCurrentTeam[client] != TEAM_SPECTATOR) CMD_CastAction(client, args);
	char Command[64];
	GetCmdArg(1, Command, sizeof(Command));
	StripQuotes(Command);
	if (Command[0] != '/' && Command[0] != '!') return true;

	return QuickCommandAccessEx(client, Command, b_IsTeamOnly);
}

stock bool QuickCommandAccessEx(client, char[] sCommand, bool b_IsTeamOnly = false, bool bGiveProfileItem = false, bool bIsItemExists = false) {

	int TargetClient = -1;
	char SplitCommand[2][64];
	char Command[64];
	Format(Command, sizeof(Command), "%s", sCommand);
	if (!bIsItemExists && !bGiveProfileItem && StrContains(Command, " ", false) != -1) {

		ExplodeString(Command, " ", SplitCommand, 2, 64);
		Format(Command, sizeof(Command), "%s", SplitCommand[0]);
		TargetClient	 = GetTargetClient(client, SplitCommand[1]);
		if (StrContains(Command, "revive", false) != -1 && TargetClient != client) return false;
	//	if (StrContains(Command, "@") != -1 && HasCommandAccess(client, GetConfigValue("reload configs flags?"))) {

		//	if (StrContains(Command, "commons", true) != -1) WipeAllCommons();
			//else if (StrContains(Command, "supercommons", true) != -1) WipeAllCommons(true);
		//}
	}

	char text[512];
	char cost[64];
	char bind[64];
	char pointtext[64];
	char description[512];
	char team[64];
	char CheatCommand[64];
	char CheatParameter[64];
	char Model[64];
	float PointCost		= 0.0;
	float PointCostM	= 0.0;
	char MenuName[64];
	float f_GetMissingHealth = 1.0;

	int size					=	0;
	char Description_Old[512];
	char ItemName[64];
	int RemoveClient = -1;
	int iWeaponCat = -1;
	int iTargetClient = -1;
	int iCommonQueueLimit = GetCommonQueueLimit();
	
	if ((iRPGMode != 1 || !b_IsActiveRound || bIsItemExists || bGiveProfileItem) && iRPGMode >= 0) {
		if (StrEqual(Command[1], sQuickBindHelp, false)) {
			size						=	GetArraySize(a_Points);
			for (int i = 0; i < size; i++) {
				MenuValues[client]		=	GetArrayCell(a_Points, i, 1);
				PointCost				= GetArrayCell(MenuValues[client], POINTS_POINT_COST);
				if (PointCost < 0.0) continue;

				PointCostM				= GetArrayCell(MenuValues[client], POINTS_POINT_COST_MINIMUM);
				GetArrayString(MenuValues[client], POINTS_QUICK_BIND, bind, 64);
				Format(bind, sizeof(bind), "!%s", bind);
				GetArrayString(MenuValues[client], POINTS_DESCRIPTION, description, 64);
				Format(description, sizeof(description), "%T", description, client);
				GetArrayString(MenuValues[client], POINTS_TEAM, team, 64);

				if (Points[client] == 0.0 || Points[client] > 0.0 && (Points[client] * PointCost) < PointCostM) PointCost = PointCostM;
				else {
					PointCost += (PointCost * fPointsCostLevel);
					PointCost *= Points[client];
				}
				Format(cost, sizeof(cost), "%3.3f", PointCost);
				if (StringToInt(team) != myCurrentTeam[client]) continue;
				Format(pointtext, sizeof(pointtext), "%T", "Points", client);
				Format(pointtext, sizeof(pointtext), "%s %s", cost, pointtext);

				Format(text, sizeof(text), "%T", "Command Information", client, orange, bind, white, green, pointtext, white, blue, description);
				if (StrEqual(Description_Old, bind, false)) continue;		// in case there are duplicates
				Format(Description_Old, sizeof(Description_Old), "%s", bind);
				PrintToConsole(client, text);
			}
			PrintToChat(client, "%T", "Commands Listed Console", client, orange, white, green);
		}
		else {
			size						=	GetArraySize(a_Points);
			int iPreGameFree			=	0;
			bool bPlayerAlive = IsPlayerAlive(client);
			bool bEnrageActive = IsEnrageActive();
			int iNumLivingSurvivors = LivingSurvivorCount();
			int iNumActiveTanks = ActiveTanks();
			bool isGhost = IsGhost(client);
			bool isTargetGhost = (TargetClient > 0) ? IsGhost(TargetClient) : false;
			bool isTargetAlive = (TargetClient > 0) ? IsPlayerAlive(TargetClient) : false;
			int infectedAttacker = (TargetClient > 0) ? L4D2_GetInfectedAttacker(TargetClient) : -1;
			char clientTeam[5];
			Format(clientTeam, sizeof(clientTeam), "%d", myCurrentTeam[client]);
			for (int i = 0; i < size; i++) {
				MenuValues[client]		=	GetArrayCell(a_Points, i, 1);
				MenuSection[client]		=	GetArrayCell(a_Points, i, 2);
				GetArrayString(MenuSection[client], 0, ItemName, sizeof(ItemName));

				PointCost		= GetArrayCell(MenuValues[client], POINTS_POINT_COST);
				PointCostM		= GetArrayCell(MenuValues[client], POINTS_POINT_COST_MINIMUM);
				GetArrayString(MenuValues[client], POINTS_QUICK_BIND, bind, 64);
				GetArrayString(MenuValues[client], POINTS_TEAM, team, 64);
				GetArrayString(MenuValues[client], POINTS_COMMAND, CheatCommand, 64);
				GetArrayString(MenuValues[client], POINTS_PARAMETER, CheatParameter, 64);

				bool isCheatParameterHealth = StrEqual(CheatParameter, "health");

				int cheatParameterInt = StringToInt(CheatParameter);
				bool cheatParameterEquals8 = (cheatParameterInt == 8) ? true : false;

				if (bIsItemExists && StrEqual(Command, ItemName)) return true;

				iWeaponCat = GetArrayCell(MenuValues[client], POINTS_WEAPON_CATEGORY);
				if (bGiveProfileItem) {
					if (StrEqual(Command, ItemName)) {
						if (iWeaponCat == 0) L4D_RemoveWeaponSlot(client, L4DWeaponSlot_Primary);
						else if (iWeaponCat == 1) L4D_RemoveWeaponSlot(client, L4DWeaponSlot_Secondary);
						if (!StrEqual(CheatCommand, "melee")) ExecCheatCommand(client, CheatCommand, CheatParameter);
						else {
							int ent			= CreateEntityByName("weapon_melee");
							DispatchKeyValue(ent, "melee_script_name", CheatParameter);
							DispatchSpawn(ent);
							EquipPlayerWeapon(client, ent);
						}
						return true;
					}
					continue;
				}
				if (StrEqual(Command[1], bind, false) && StrContains(team, clientTeam, false) != -1) {		// we found the bind the player used, and the player is on the appropriate team.
					GetArrayString(MenuValues[client], POINTS_MODEL, Model, 64);
					int count = GetArrayCell(MenuValues[client], POINTS_COUNT);
					int countAddedByHandicap = GetArrayCell(MenuValues[client], POINTS_COUNT_HANDICAP);
					int isDrop = GetArrayCell(MenuValues[client], POINTS_DROP);
					GetArrayString(MenuValues[client], POINTS_PART_OF_MENU_NAMED, MenuName, 64);
					int isRespawn = GetArrayCell(MenuValues[client], POINTS_IS_RESPAWN);
					iPreGameFree = GetArrayCell(MenuValues[client], POINTS_FREE_DURING_PREGAME);
					if (isRespawn == 1) {
						if (TargetClient == -1) {
							if (!b_HasDeathLocation[client] || bPlayerAlive || bEnrageActive) return false;
						}
						if (TargetClient != -1) {
							if (isTargetAlive || bEnrageActive) return false;
						}
					}
					if (TargetClient != -1 && isTargetAlive) {

						if (IsIncapacitated(TargetClient)) f_GetMissingHealth	= 0.0;	// Player is incapped, has no missing life.
						else f_GetMissingHealth	= GetMissingHealth(TargetClient);
					}

					int ExperienceCost = GetArrayCell(MenuValues[client], POINTS_EXPERIENCE_COST);
					if (ExperienceCost > 0) {
						float fExperienceCostMultiplier = GetArrayCell(MenuValues[client], POINTS_EXPERIENCE_MULTIPLIER);
						if (fExperienceCostMultiplier == -1.0) fExperienceCostMultiplier = fExperienceMultiplier;
						if (ExperienceCost > 0) ExperienceCost = RoundToCeil(ExperienceCost * (fExperienceCostMultiplier * (PlayerLevel[client] - 1)));
					}
					int TargetClient_s			=	0;

					if (StrBeginsWith(CheatCommand, ":")) {
						BuildPointsMenu(client, CheatCommand[1], CONFIG_POINTS);		// Always CONFIG_POINTS for quick commands
					}
					else {
						if (myCurrentTeam[client] == TEAM_INFECTED) {
							if (cheatParameterEquals8 && iNumActiveTanks >= iTankLimitVersus) {
								PrintToChat(client, "%T", "Tank Limit Reached", client, orange, green, iTankLimitVersus, white);
								return false;
							}
							else if (cheatParameterEquals8 && f_TankCooldown != -1.0) {

								PrintToChat(client, "%T", "Tank On Cooldown", client, orange, white);
								return false;
							}
						}
						if (Points[client] == 0.0 || Points[client] > 0.0 && (Points[client] * PointCost) < PointCostM) PointCost = PointCostM;
						else PointCost *= Points[client];
						bool isChangeClass = StrEqual(CheatCommand, "change class");
						if (Points[client] >= PointCost ||
							PointCost == 0.0 ||
							(!b_IsActiveRound && iPreGameFree == 1) ||
							myCurrentTeam[client] == TEAM_INFECTED && isChangeClass && !cheatParameterEquals8 && (TargetClient == -1 && isGhost || TargetClient != -1 && isTargetGhost)) {

							if (!isChangeClass ||
								isChangeClass && StrEqual(CheatParameter, "8") ||
								isChangeClass && (TargetClient == -1 && bPlayerAlive && !isGhost || TargetClient != -1 && isTargetAlive && !isTargetGhost)) {
								if (PointPurchaseType == 0 && (Points[client] >= PointCost || PointCost == 0.0 || (!b_IsActiveRound && iPreGameFree == 1))) {
									if (PointCost > 0.0 && Points[client] >= PointCost || PointCost <= 0.0) {
										if (iPreGameFree != 1 || b_IsActiveRound) Points[client] -= PointCost;
									}
								}
								else if (PointPurchaseType == 1 && (ExperienceLevel[client] >= ExperienceCost || ExperienceCost == 0)) ExperienceLevel[client] -= ExperienceCost;
							}
							if (StrEqual(CheatParameter, "common") && StrEqualAtPos(Model, ".mdl", strlen(Model)-4)) {
								count += (countAddedByHandicap * iNumLivingSurvivors);
								for (int commonsToAddRemaining = count; commonsToAddRemaining > 0 && GetArraySize(CommonInfectedQueue) < iCommonQueueLimit; commonsToAddRemaining--) {
									if (isDrop == 1) {
										ResizeArray(CommonInfectedQueue, GetArraySize(CommonInfectedQueue) + 1);
										ShiftArrayUp(CommonInfectedQueue, 0);
										SetArrayString(CommonInfectedQueue, 0, Model);
										TargetClient_s		=	FindLivingSurvivor();
										if (TargetClient_s > 0) ExecCheatCommand(TargetClient_s, CheatCommand, CheatParameter);
									}
									else PushArrayString(CommonInfectedQueue, Model);
								}
							}
							else if (isChangeClass) {
								int clientSurvivorVictim = L4D2_GetSurvivorVictim(client);
								int targetSurvivorVictim = L4D2_GetSurvivorVictim(TargetClient);
								int clientZombieClass = FindZombieClass(client);
								int targetZombieClass = FindZombieClass(TargetClient);
								// We don't give them points back if ghost because we don't take points if ghost.
								if ((!isGhost && clientZombieClass == ZOMBIECLASS_TANK && TargetClient == -1 ||
									TargetClient != -1 && !isTargetGhost && targetZombieClass == ZOMBIECLASS_TANK) && PointPurchaseType == 0) Points[client] += PointCost;
								else if ((!isGhost && clientZombieClass == ZOMBIECLASS_TANK && TargetClient == -1 || TargetClient != -1 && !isTargetGhost && targetZombieClass == ZOMBIECLASS_TANK) && PointPurchaseType == 1) ExperienceLevel[client] += ExperienceCost;
								else if ((!isGhost && bPlayerAlive && clientZombieClass == ZOMBIECLASS_CHARGER && clientSurvivorVictim != -1 && TargetClient == -1 ||
										  TargetClient != -1 && !isTargetGhost && isTargetAlive && targetZombieClass == ZOMBIECLASS_CHARGER && targetSurvivorVictim == -1) && PointPurchaseType == 0) Points[client] += PointCost;
								else if ((!isGhost && bPlayerAlive && clientZombieClass == ZOMBIECLASS_CHARGER && clientSurvivorVictim != -1 && TargetClient == -1 ||
										  TargetClient != -1 && !isTargetGhost && isTargetAlive && targetZombieClass == ZOMBIECLASS_CHARGER && targetSurvivorVictim == -1) && PointPurchaseType == 1) ExperienceLevel[client] += ExperienceCost;
								if (clientZombieClass != ZOMBIECLASS_TANK && TargetClient == -1 || TargetClient != -1 && targetZombieClass != ZOMBIECLASS_TANK) {
									if (TargetClient == -1) ChangeInfectedClass(client, cheatParameterInt);
									else ChangeInfectedClass(TargetClient, cheatParameterInt);
									if (TargetClient != -1) TeamworkRewardNotification(client, TargetClient, PointCost, ItemName);
								}
							}
							else if (isRespawn == 1) {
								if (TargetClient == -1 && !bPlayerAlive && b_HasDeathLocation[client]) {
									SDKCall(hRoundRespawn, client);
									b_HasDeathLocation[client] = false;
									CreateTimer(1.0, Timer_TeleportRespawn, client, TIMER_FLAG_NO_MAPCHANGE);
								}
								else if (TargetClient != -1 && !isTargetAlive && b_HasDeathLocation[TargetClient]) {
									SDKCall(hRoundRespawn, TargetClient);
									b_HasDeathLocation[TargetClient] = false;
									CreateTimer(1.0, Timer_TeleportRespawn, TargetClient, TIMER_FLAG_NO_MAPCHANGE);
									TeamworkRewardNotification(client, TargetClient, PointCost, ItemName);
								}
							}
							else {
								RemoveClient = client;
								if (isTargetAlive) RemoveClient = TargetClient;
								if ((PointCost == 0.0 || (iPreGameFree == 1 && !b_IsActiveRound)) && myCurrentTeam[RemoveClient] == TEAM_SURVIVOR) {
									// there is no code here to give a player a FREE weapon forcefully because that would be fucked up. TargetClient just gets ignored here.
									if (StrBeginsWith(CheatParameter, "pistol") || IsMeleeWeaponParameter(CheatParameter)) L4D_RemoveWeaponSlot(RemoveClient, L4DWeaponSlot_Secondary);
									else if (iWeaponCat >= 0 && iWeaponCat <= 1) L4D_RemoveWeaponSlot(RemoveClient, L4DWeaponSlot_Primary);
								}
								if (IsMeleeWeaponParameter(CheatParameter)) {
									// Get rid of their old weapon
									if (TargetClient == -1)	L4D_RemoveWeaponSlot(client, L4DWeaponSlot_Secondary);
									else L4D_RemoveWeaponSlot(TargetClient, L4DWeaponSlot_Secondary);
									int ent			= CreateEntityByName("weapon_melee");
									DispatchKeyValue(ent, "melee_script_name", CheatParameter);
									DispatchSpawn(ent);
									if (TargetClient == -1) EquipPlayerWeapon(client, ent);
									else EquipPlayerWeapon(TargetClient, ent);
								}
								else {
									if (StrBeginsWith(CheatParameter, "pistol")) L4D_RemoveWeaponSlot(client, L4DWeaponSlot_Secondary);
									else if (iWeaponCat >= 0 && iWeaponCat <= 1) L4D_RemoveWeaponSlot(client, L4DWeaponSlot_Primary);
									if (TargetClient == -1) {
										iTargetClient = client;
										if (isCheatParameterHealth) {
											if (L4D2_GetInfectedAttacker(client) != -1) Points[client] += PointCost;
											else {
												ExecCheatCommand(client, CheatCommand, CheatParameter);
												GiveMaximumHealth(client);		// So instant heal doesn't put a player above their maximum health pool.
											}
										}
										else ExecCheatCommand(client, CheatCommand, CheatParameter);
									}
									else {
										iTargetClient = TargetClient;
										if (isCheatParameterHealth) {
											if (infectedAttacker != -1 || f_GetMissingHealth > fHealRequirementTeam) Points[client] += PointCost;
											else {
												ExecCheatCommand(TargetClient, CheatCommand, CheatParameter);
												GiveMaximumHealth(TargetClient);		// So instant heal doesn't put a player above their maximum health pool.
											}
										}
										else ExecCheatCommand(TargetClient, CheatCommand, CheatParameter);
									}
									if (StrBeginsWith(CheatParameter, "pistol") && !StrEqualAtPos(CheatParameter, "magnum", 7)) {
										CreateTimer(0.5, Timer_GiveSecondPistol, iTargetClient, TIMER_FLAG_NO_MAPCHANGE);
									}
								}
								if (TargetClient != -1) {
									if (isCheatParameterHealth && infectedAttacker == -1 && f_GetMissingHealth <= fHealRequirementTeam || !isCheatParameterHealth) {
										if (isCheatParameterHealth) TeamworkRewardNotification(client, TargetClient, PointCost * (1.0 - f_GetMissingHealth), ItemName);
										else TeamworkRewardNotification(client, TargetClient, PointCost, ItemName);
									}
								}
							}
						}
						else {
							if (PointPurchaseType == 0) PrintToChat(client, "%T", "Not Enough Points", client, orange, white, PointCost);
							else if (PointPurchaseType == 1) PrintToChat(client, "%T", "Not Enough Experience", client, orange, white, ExperienceCost);
						}
					}
					break;
				}
			}
			if (bIsItemExists) return false;
		}
	}
	if (Command[0] == '!') return true;
	return false;
}