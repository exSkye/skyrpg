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
	char Count[64];
	char CountHandicap[64];
	char Drop[64];
	float PointCost		= 0.0;
	float PointCostM	= 0.0;
	char MenuName[64];
	float f_GetMissingHealth = 1.0;

	int size					=	0;
	char Description_Old[512];
	char ItemName[64];
	char IsRespawn[64];
	int RemoveClient = -1;
	int iWeaponCat = -1;
	int iTargetClient = -1;
	int iCommonQueueLimit = GetCommonQueueLimit();

	//if (StringToInt(GetConfigValue("rpg mode?")) != 1) BuyItem(client, Command[1]);

	if ((iRPGMode != 1 || !b_IsActiveRound || bIsItemExists || bGiveProfileItem) && iRPGMode >= 0) {

		//GetConfigValue(thetext, sizeof(thetext), "quick bind help?");

		if (StrEqual(Command[1], sQuickBindHelp, false)) {

			size						=	GetArraySize(a_Points);

			for (int i = 0; i < size; i++) {

				MenuKeys[client]		=	GetArrayCell(a_Points, i, 0);
				MenuValues[client]		=	GetArrayCell(a_Points, i, 1);

				//size2					=	GetArraySize(MenuKeys[client]);

				PointCost				= GetKeyValueFloat(MenuKeys[client], MenuValues[client], "point cost?");
				if (PointCost < 0.0) continue;

				PointCostM				= GetKeyValueFloat(MenuKeys[client], MenuValues[client], "point cost minimum?");
				FormatKeyValue(bind, sizeof(bind), MenuKeys[client], MenuValues[client], "quick bind?");
				Format(bind, sizeof(bind), "!%s", bind);
				FormatKeyValue(description, sizeof(description), MenuKeys[client], MenuValues[client], "description?");
				Format(description, sizeof(description), "%T", description, client);
				FormatKeyValue(team, sizeof(team), MenuKeys[client], MenuValues[client], "team?");

				/*
						
						Determine the actual cost for the player.
				*/
				
				if (Points[client] == 0.0 || Points[client] > 0.0 && (Points[client] * PointCost) < PointCostM) PointCost = PointCostM;
				else {

					PointCost += (PointCost * fPointsCostLevel);
					//if (PointCost > 1.0) PointCost = 1.0;
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

			for (int i = 0; i < size; i++) {

				MenuKeys[client]		=	GetArrayCell(a_Points, i, 0);
				MenuValues[client]		=	GetArrayCell(a_Points, i, 1);
				MenuSection[client]		=	GetArrayCell(a_Points, i, 2);

				GetArrayString(MenuSection[client], 0, ItemName, sizeof(ItemName));

				PointCost		= GetKeyValueFloat(MenuKeys[client], MenuValues[client], "point cost?");
				PointCostM		= GetKeyValueFloat(MenuKeys[client], MenuValues[client], "point cost minimum?");
				FormatKeyValue(bind, sizeof(bind), MenuKeys[client], MenuValues[client], "quick bind?");
				FormatKeyValue(team, sizeof(team), MenuKeys[client], MenuValues[client], "team?");
				FormatKeyValue(CheatCommand, sizeof(CheatCommand), MenuKeys[client], MenuValues[client], "command?");
				FormatKeyValue(CheatParameter, sizeof(CheatParameter), MenuKeys[client], MenuValues[client], "parameter?");

				if (bIsItemExists && StrEqual(Command, ItemName)) return true;

				iWeaponCat = GetKeyValueInt(MenuKeys[client], MenuValues[client], "weapon category?");
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

				if (StrEqual(Command[1], bind, false) && StringToInt(team) == myCurrentTeam[client]) {		// we found the bind the player used, and the player is on the appropriate team.

					FormatKeyValue(Model, sizeof(Model), MenuKeys[client], MenuValues[client], "model?");
					FormatKeyValue(Count, sizeof(Count), MenuKeys[client], MenuValues[client], "count?");
					FormatKeyValue(CountHandicap, sizeof(CountHandicap), MenuKeys[client], MenuValues[client], "count handicap?");
					FormatKeyValue(Drop, sizeof(Drop), MenuKeys[client], MenuValues[client], "drop?");
					FormatKeyValue(MenuName, sizeof(MenuName), MenuKeys[client], MenuValues[client], "part of menu named?");
					FormatKeyValue(IsRespawn, sizeof(IsRespawn), MenuKeys[client], MenuValues[client], "isrespawn?");
					iPreGameFree = GetKeyValueInt(MenuKeys[client], MenuValues[client], "pre-game free?");

					if (StringToInt(IsRespawn) == 1) {

						if (TargetClient == -1) {

							if (!b_HasDeathLocation[client] || IsPlayerAlive(client) || IsEnrageActive()) return false;
						}
						if (TargetClient != -1) {

							if (IsPlayerAlive(TargetClient) || IsEnrageActive()) return false;
						}
					}
					if (TargetClient != -1 && IsPlayerAlive(TargetClient)) {

						if (IsIncapacitated(TargetClient)) f_GetMissingHealth	= 0.0;	// Player is incapped, has no missing life.
						else f_GetMissingHealth	= GetMissingHealth(TargetClient);
					}

					int ExperienceCost			=	GetKeyValueInt(MenuKeys[client], MenuValues[client], "experience cost?");
					if (ExperienceCost > 0) {

						float fExperienceCostMultiplier = GetKeyValueFloat(MenuKeys[client], MenuValues[client], "experience multiplier?");
						if (fExperienceCostMultiplier == -1.0) fExperienceCostMultiplier = fExperienceMultiplier;
						if (ExperienceCost > 0) ExperienceCost = RoundToCeil(ExperienceCost * (fExperienceCostMultiplier * (PlayerLevel[client] - 1)));
					}
					int TargetClient_s			=	0;

					if (FindCharInString(CheatCommand, ':') != -1) {

						BuildPointsMenu(client, CheatCommand[1], CONFIG_POINTS);		// Always CONFIG_POINTS for quick commands
					}
					else {

						if (myCurrentTeam[client] == TEAM_INFECTED) {

							if (StringToInt(CheatParameter) == 8 && ActiveTanks() >= iTankLimitVersus) {

								PrintToChat(client, "%T", "Tank Limit Reached", client, orange, green, iTankLimitVersus, white);
								return false;
							}
							else if (StringToInt(CheatParameter) == 8 && f_TankCooldown != -1.0) {

								PrintToChat(client, "%T", "Tank On Cooldown", client, orange, white);
								return false;
							}
						}
						if (Points[client] == 0.0 || Points[client] > 0.0 && (Points[client] * PointCost) < PointCostM) PointCost = PointCostM;
						else PointCost *= Points[client];

						if (Points[client] >= PointCost ||
							PointCost == 0.0 ||
							(!b_IsActiveRound && iPreGameFree == 1) ||
							myCurrentTeam[client] == TEAM_INFECTED && StrEqual(CheatCommand, "change class", false) && StringToInt(CheatParameter) != 8 && (TargetClient == -1 && IsGhost(client) || TargetClient != -1 && IsGhost(TargetClient))) {

							if (!StrEqual(CheatCommand, "change class") ||
								StrEqual(CheatCommand, "change class") && StrEqual(CheatParameter, "8") ||
								StrEqual(CheatCommand, "change class") && (TargetClient == -1 && IsPlayerAlive(client) && !IsGhost(client) || TargetClient != -1 && IsPlayerAlive(TargetClient) && !IsGhost(TargetClient))) {

								if (PointPurchaseType == 0 && (Points[client] >= PointCost || PointCost == 0.0 || (!b_IsActiveRound && iPreGameFree == 1))) {

									if (PointCost > 0.0 && Points[client] >= PointCost || PointCost <= 0.0) {

										if (iPreGameFree != 1 || b_IsActiveRound) Points[client] -= PointCost;
									}
								}
								else if (PointPurchaseType == 1 && (ExperienceLevel[client] >= ExperienceCost || ExperienceCost == 0)) ExperienceLevel[client] -= ExperienceCost;
							}

							if (StrEqual(CheatParameter, "common") && StrContains(Model, ".mdl", false) != -1) {

								Format(Count, sizeof(Count), "%d", StringToInt(Count) + (StringToInt(CountHandicap) * LivingSurvivorCount()));

								for (int iii = StringToInt(Count); iii > 0 && GetArraySize(CommonInfectedQueue) < iCommonQueueLimit; iii--) {

									if (StringToInt(Drop) == 1) {

										ResizeArray(CommonInfectedQueue, GetArraySize(CommonInfectedQueue) + 1);
										ShiftArrayUp(CommonInfectedQueue, 0);
										SetArrayString(CommonInfectedQueue, 0, Model);
										TargetClient_s		=	FindLivingSurvivor();
										if (TargetClient_s > 0) ExecCheatCommand(TargetClient_s, CheatCommand, CheatParameter);
									}
									else PushArrayString(CommonInfectedQueue, Model);
								}
							}
							else if (StrEqual(CheatCommand, "change class")) {

								// We don't give them points back if ghost because we don't take points if ghost.
								//if (IsGhost(client) && PointPurchaseType == 0) Points[client] += PointCost;
								//else if (IsGhost(client) && PointPurchaseType == 1) ExperienceLevel[client] += ExperienceCost;
								if ((!IsGhost(client) && FindZombieClass(client) == ZOMBIECLASS_TANK && TargetClient == -1 ||
									TargetClient != -1 && !IsGhost(TargetClient) && FindZombieClass(TargetClient) == ZOMBIECLASS_TANK) && PointPurchaseType == 0) Points[client] += PointCost;
								else if ((!IsGhost(client) && FindZombieClass(client) == ZOMBIECLASS_TANK && TargetClient == -1 || TargetClient != -1 && !IsGhost(TargetClient) && FindZombieClass(TargetClient) == ZOMBIECLASS_TANK) && PointPurchaseType == 1) ExperienceLevel[client] += ExperienceCost;
								else if ((!IsGhost(client) && IsPlayerAlive(client) && FindZombieClass(client) == ZOMBIECLASS_CHARGER && L4D2_GetSurvivorVictim(client) != -1 && TargetClient == -1 ||
										  TargetClient != -1 && !IsGhost(TargetClient) && IsPlayerAlive(TargetClient) && FindZombieClass(TargetClient) == ZOMBIECLASS_CHARGER && L4D2_GetSurvivorVictim(TargetClient) == -1) && PointPurchaseType == 0) Points[client] += PointCost;
								else if ((!IsGhost(client) && IsPlayerAlive(client) && FindZombieClass(client) == ZOMBIECLASS_CHARGER && L4D2_GetSurvivorVictim(client) != -1 && TargetClient == -1 ||
										  TargetClient != -1 && !IsGhost(TargetClient) && IsPlayerAlive(TargetClient) && FindZombieClass(TargetClient) == ZOMBIECLASS_CHARGER && L4D2_GetSurvivorVictim(TargetClient) == -1) && PointPurchaseType == 1) ExperienceLevel[client] += ExperienceCost;
								if (FindZombieClass(client) != ZOMBIECLASS_TANK && TargetClient == -1 || TargetClient != -1 && FindZombieClass(TargetClient) != ZOMBIECLASS_TANK) {

									if (TargetClient == -1) ChangeInfectedClass(client, StringToInt(CheatParameter));
									else ChangeInfectedClass(TargetClient, StringToInt(CheatParameter));

									if (TargetClient != -1) TeamworkRewardNotification(client, TargetClient, PointCost, ItemName);
								}
							}
							else if (StringToInt(IsRespawn) == 1) {

								if (TargetClient == -1 && !IsPlayerAlive(client) && b_HasDeathLocation[client]) {

									SDKCall(hRoundRespawn, client);
									b_HasDeathLocation[client] = false;
									CreateTimer(1.0, Timer_TeleportRespawn, client, TIMER_FLAG_NO_MAPCHANGE);
								}
								else if (TargetClient != -1 && !IsPlayerAlive(TargetClient) && b_HasDeathLocation[TargetClient]) {

									SDKCall(hRoundRespawn, TargetClient);
									b_HasDeathLocation[TargetClient] = false;
									CreateTimer(1.0, Timer_TeleportRespawn, TargetClient, TIMER_FLAG_NO_MAPCHANGE);

									TeamworkRewardNotification(client, TargetClient, PointCost, ItemName);
								}
							}
							else {

								//CheckIfRemoveWeapon(client, CheatParameter);
								RemoveClient = client;
								if (IsLegitimateClientAlive(TargetClient)) RemoveClient = TargetClient;
								if ((PointCost == 0.0 || (iPreGameFree == 1 && !b_IsActiveRound)) && myCurrentTeam[RemoveClient] == TEAM_SURVIVOR) {

									// there is no code here to give a player a FREE weapon forcefully because that would be fucked up. TargetClient just gets ignored here.
									if (StrContains(CheatParameter, "pistol", false) != -1 || IsMeleeWeaponParameter(CheatParameter)) L4D_RemoveWeaponSlot(RemoveClient, L4DWeaponSlot_Secondary);
									else L4D_RemoveWeaponSlot(RemoveClient, L4DWeaponSlot_Primary);
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

									if (StrContains(CheatParameter, "pistol", false) != -1) L4D_RemoveWeaponSlot(client, L4DWeaponSlot_Secondary);
									else if (iWeaponCat >= 0 && iWeaponCat <= 1) L4D_RemoveWeaponSlot(client, L4DWeaponSlot_Primary);

									if (TargetClient == -1) {

										iTargetClient = client;

										if (StrEqual(CheatParameter, "health")) {

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

										if (StrEqual(CheatParameter, "health")) {

											if (L4D2_GetInfectedAttacker(TargetClient) != -1 || f_GetMissingHealth > fHealRequirementTeam) Points[client] += PointCost;
											else {

												ExecCheatCommand(TargetClient, CheatCommand, CheatParameter);
												GiveMaximumHealth(TargetClient);		// So instant heal doesn't put a player above their maximum health pool.
											}
										}
										else ExecCheatCommand(TargetClient, CheatCommand, CheatParameter);
									}
									if (StrContains(CheatParameter, "pistol", false) != -1 && StrContains(CheatParameter, "magnum", false) == -1) {

										CreateTimer(0.5, Timer_GiveSecondPistol, iTargetClient, TIMER_FLAG_NO_MAPCHANGE);
									}
									if (iWeaponCat == 0 && SkyLevel[client] > 0) CreateTimer(0.5, Timer_GiveLaserBeam, iTargetClient, TIMER_FLAG_NO_MAPCHANGE);
								}
								if (TargetClient != -1) {

									if (StrEqual(CheatParameter, "health", false) && L4D2_GetInfectedAttacker(TargetClient) == -1 && f_GetMissingHealth <= fHealRequirementTeam || !StrEqual(CheatParameter, "health", false)) {

										if (StrEqual(CheatParameter, "health", false)) TeamworkRewardNotification(client, TargetClient, PointCost * (1.0 - f_GetMissingHealth), ItemName);
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