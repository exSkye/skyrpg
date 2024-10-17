/* put the line below after all of the includes!
#pragma newdecls required
*/

stock void BuildPointsMenu(int client, char[] MenuName, char[] ConfigName = "none") {

	Handle menu					=	CreateMenu(BuildPointsMenuHandle);
	char OpenedMenu_t[64];
	Format(OpenedMenu_t, sizeof(OpenedMenu_t), "%s", MenuName);
	OpenedMenu[client]				=	OpenedMenu_t;

	char text[PLATFORM_MAX_PATH];
	char Name[64];
	char Name_Temp[64];

	float PointCost				=	0.0;
	float PointCostMinimum		=	0.0;
	int ExperienceCost				=	0;
	int menuPos						=	-1;
	char Command[64];
	char IsCooldown[64];
	Format(IsCooldown, sizeof(IsCooldown), "0");
	char quickCommand[64];
	//decl String:campaignSupported[512];
	//Format(campaignSupported, sizeof(campaignSupported), "-1");

	char teamsAllowed[64];
	char gamemodesAllowed[64];
	char flagsAllowed[64];
	char currentGamemode[64];
	char clientTeam[64];

	int iWeaponCat = 0;

	// Collect player team and server gamemode.
	Format(currentGamemode, sizeof(currentGamemode), "%d", ReadyUp_GetGameMode());
	Format(clientTeam, sizeof(clientTeam), "%d", GetClientTeam(client));

	int size						=	GetArraySize(a_Points);
	int iPreGameFree				=	0;
	if (size < 1) SetFailState("POINT MENU SIZE COULD NOT BE FOUND!!!");

	ClearArray(RPGMenuPosition[client]);
	char pos[4];

	int iNumLivingSurvivors = LivingHumanSurvivors();

	for (int i = 0; i < size; i++) {
		MenuValues[client]						=	GetArrayCell(a_Points, i, 1);
		MenuSection[client]						=	GetArrayCell(a_Points, i, 2);

		GetArrayString(MenuSection[client], 0, Name, sizeof(Name));
		
		if (iIsWeaponLoadout[client] > 0) {
			iWeaponCat = GetArrayCell(MenuValues[client], POINTS_WEAPON_CATEGORY);
			if (iWeaponCat < 0 || iIsWeaponLoadout[client] - 1 != iWeaponCat) continue;
		}
		else if (!TalentListingFoundForPoints(client, MenuValues[client], MenuName)) continue;
		menuPos++;

		Format(pos, sizeof(pos), "%d", i);
		PushArrayString(RPGMenuPosition[client], pos);

		Format(quickCommand, sizeof(quickCommand), "none");

		// Reset data in display requirement variables to default values.
		GetArrayString(MenuValues[client], POINTS_TEAM, teamsAllowed, 64);
		GetArrayString(MenuValues[client], POINTS_GAMEMODE, gamemodesAllowed, 64);
		GetArrayString(MenuValues[client], POINTS_FLAGS, flagsAllowed, 64);
		
		PointCost			= GetArrayCell(MenuValues[client], POINTS_POINT_COST);
		ExperienceCost		= GetArrayCell(MenuValues[client], POINTS_EXPERIENCE_COST);

		GetArrayString(MenuValues[client], POINTS_COMMAND, Command, 64);
		PointCostMinimum	= GetArrayCell(MenuValues[client], POINTS_POINT_COST_MINIMUM);
		GetArrayString(MenuValues[client], POINTS_QUICK_BIND, quickCommand, 64);
		Format(quickCommand, sizeof(quickCommand), "!%s", quickCommand);

		iPreGameFree = GetArrayCell(MenuValues[client], POINTS_FREE_DURING_PREGAME);

		// If the player doesn't meet the requirements to have access to this menu option, we skip it.
		if (!StrEqual(teamsAllowed, "-1") && StrContains(teamsAllowed, clientTeam, false) == -1 ||
			!StrEqual(gamemodesAllowed, "-1") && StrContains(gamemodesAllowed, currentGamemode, false) == -1 ||
			!StrEqual(flagsAllowed, "-1", false) && !HasCommandAccess(client, flagsAllowed)) {
			menuPos--;
			continue;
		}
		if (StrEqual(Command, "respawn") && (IsPlayerAlive(client) || !b_HasDeathLocation[client] || b_HardcoreMode[client])) {
			menuPos--;
			continue;
		}
		Format(Name_Temp, sizeof(Name_Temp), "%T", Name, client);
		if (StrBeginsWith(Command, ":")) Format(text, sizeof(text), "%T", "Buy Menu Option 1", client, Name_Temp, quickCommand);
		else {
			if (StrEqual(MenuName, "director menu")) {
				float PointCostHandicap = GetArrayCell(MenuValues[client], POINTS_HANDICAP_COST);
				PointCost				+= (PointCostHandicap * iNumLivingSurvivors);
				if (PointCost > 1.0) PointCost = 1.0;
				float PointCostMinHandicap = GetArrayCell(MenuValues[client], POINTS_HANDICAP_COST_MINIMUM);
				PointCostMinimum		+=	(PointCostMinHandicap * iNumLivingSurvivors);

				if (Points_Director > 0.0) PointCost *= Points_Director;
				if (PointCost < PointCostMinimum) PointCost = PointCostMinimum;

				if (menuPos < GetArraySize(a_DirectorActions_Cooldown)) GetArrayString(a_DirectorActions_Cooldown, menuPos, IsCooldown, sizeof(IsCooldown));
			}
			if (StringToInt(IsCooldown) > 0) Format(text, sizeof(text), "%T", "Buy Menu Option Cooldown", client, Name_Temp);
			else {
				if (!StrEqual(MenuName, "director menu")) {
					if (Points[client] == 0.0 || Points[client] > 0.0 && (Points[client] * PointCost) < PointCostMinimum) PointCost = PointCostMinimum;
					else {
						PointCost += (PointCost * fPointsCostLevel);
						PointCost *= Points[client];
					}
				}
				if (iPreGameFree == 1 && !b_IsActiveRound) PointCost = 0.0;
				if (iIsWeaponLoadout[client] > 0) Format(text, sizeof(text), "%s", Name_Temp);
				else {
					if (PointPurchaseType == 0) Format(text, sizeof(text), "%T", "Buy Menu Option 2", client, Name_Temp, PointCost, quickCommand);
					else if (PointPurchaseType == 1) Format(text, sizeof(text), "%T", "Buy Menu Option 3", client, Name_Temp, ExperienceCost, quickCommand);
				}
			}
		}
		AddMenuItem(menu, text, text);
	}

	if (!StrEqual(MenuName, "director menu")) BuildMenuTitle(client, menu);
	else BuildMenuTitle(client, menu, -1);

	SetMenuExitBackButton(menu, true);
	DisplayMenu(menu, client, 0);
}

public BuildPointsMenuHandle(Handle menu, MenuAction action, client, slot) {

	if (action == MenuAction_Select) {

		char ConfigName[64];
		Format(ConfigName, sizeof(ConfigName), "%s", MenuSelection[client]);
		char MenuName[64];
		Format(MenuName, sizeof(MenuName), "%s", OpenedMenu[client]);

		char Name[64];
		char Command[64];
		char Parameter[64];
		//decl String:campaignSupported[512];
		//Format(campaignSupported, sizeof(campaignSupported), "-1");	// If there's no value for it, ignore.

		float PointCost				=	0.0;
		float PointCostMinimum		=	0.0;
		int ExperienceCost				=	0;
		int Count						=	0;
		int CountHandicap				=	0;
		int Drop						=	0;
		char Model[64];
		char IsCooldown[64];
		Format(IsCooldown, sizeof(IsCooldown), "0");
		int TargetClient				=	-1;
		int PCount						=	0;

		char teamsAllowed[64];
		char gamemodesAllowed[64];
		char flagsAllowed[64];
		char currentGamemode[64];
		char clientTeam[64];

		char pos[4];

		// Collect player team and server gamemode.
		Format(currentGamemode, sizeof(currentGamemode), "%d", ReadyUp_GetGameMode());
		Format(clientTeam, sizeof(clientTeam), "%d", GetClientTeam(client));

		//new size						=	GetArraySize(a_Points);

		int menuPos						=	0;
		int iPreGameFree				=	0;
		int iWeaponCat					=	-1;

		GetArrayString(RPGMenuPosition[client], slot, pos, sizeof(pos));

		int ipos = StringToInt(pos);
		MenuValues[client]						=	GetArrayCell(a_Points, ipos, 1);
		MenuSection[client]						=	GetArrayCell(a_Points, ipos, 2);

		GetArrayString(MenuSection[client], 0, Name, sizeof(Name));
		if (iIsWeaponLoadout[client] > 0) {

			iWeaponCat = GetArrayCell(MenuValues[client], POINTS_WEAPON_CATEGORY);
			SetArrayString(hWeaponList[client], iWeaponCat, Name);
			iIsWeaponLoadout[client] = 0;
			SpawnLoadoutEditor(client);
			return;
		}
		menuPos++;

		GetArrayString(MenuValues[client], POINTS_TEAM, teamsAllowed, 64);
		GetArrayString(MenuValues[client], POINTS_GAMEMODE, gamemodesAllowed, 64);
		GetArrayString(MenuValues[client], POINTS_FLAGS, flagsAllowed, 64);
			
		PointCost			= GetArrayCell(MenuValues[client], POINTS_POINT_COST);
		ExperienceCost		= GetArrayCell(MenuValues[client], POINTS_EXPERIENCE_COST);
		GetArrayString(MenuValues[client], POINTS_COMMAND, Command, 64);
		PointCostMinimum	= GetArrayCell(MenuValues[client], POINTS_POINT_COST_MINIMUM);
		
		GetArrayString(MenuValues[client], POINTS_PARAMETER, Parameter, 64);
		GetArrayString(MenuValues[client], POINTS_MODEL, Model, 64);

		Count				= GetArrayCell(MenuValues[client], POINTS_COUNT);
		CountHandicap		= GetArrayCell(MenuValues[client], POINTS_COUNT_HANDICAP);
		Drop				= GetArrayCell(MenuValues[client], POINTS_DROP);
		PCount				= GetArrayCell(MenuValues[client], POINTS_PCOUNT);

		if (PCount < 1) PCount = 1;
		int iParameter = StringToInt(Parameter);

		int CommonQueueMaxx = GetCommonQueueLimit();
		bool bIsDirectorMenu = StrEqual(MenuName, "director menu");
		if (StrBeginsWith(Command, ":")) {
			if (bIsDirectorMenu) BuildPointsMenu(client, Command[1], ConfigName);
			else if (StrEqual(Command[1], "director priority")) BuildDirectorPriorityMenu(client);
			else if (StrEqual(Command[1], "MainMenu")) BuildMenu(client);
			else BuildPointsMenu(client, Command[1], ConfigName);
		}
		else {
			int iZombieClass = FindZombieClass(client);
			iPreGameFree = GetArrayCell(MenuValues[client], POINTS_FREE_DURING_PREGAME);
			bool isParameterHealth = StrEqual(Parameter, "health");
			bool isCommandChangeClass = StrEqual(Command, "change class");
			bool isClientGhost = IsGhost(client);
			bool isParameterCommon = (isParameterHealth) ? false : StrEqual(Parameter, "common");
			bool isPlayerAlive = IsPlayerAlive(client);

			if (!bIsDirectorMenu) {
				if (GetClientTeam(client) == TEAM_INFECTED) {
					if (iParameter == 8 && ActiveTanks() >= iTankLimitVersus) {
						PrintToChat(client, "%T", "Tank Limit Reached", client, orange, green, iTankLimitVersus, white);
						BuildPointsMenu(client, MenuName, ConfigName);
						return;
					}
					else if (iParameter == 8 && f_TankCooldown != -1.0) {
						PrintToChat(client, "%T", "Tank On Cooldown", client, orange, white);
						BuildPointsMenu(client, MenuName, ConfigName);
						return;
					}
				}
				if (ExperienceCost > 0) ExperienceCost *= (fExperienceMultiplier * (PlayerLevel[client] - 1));
				if (Points[client] == 0.0 || Points[client] > 0.0 && (Points[client] * PointCost) < PointCostMinimum) PointCost = PointCostMinimum;
				else {
					PointCost += (PointCost * fPointsCostLevel);
					PointCost *= Points[client];
				}
				if ((isParameterHealth && GetClientHealth(client) < GetMaximumHealth(client) || !isParameterHealth) && (!isParameterHealth && b_HardcoreMode[client] || !b_HardcoreMode[client]) && (PointPurchaseType == 0 && (Points[client] >= PointCost || PointCost == 0.0 || (!b_IsActiveRound && iPreGameFree == 1) || isClientGhost && isCommandChangeClass && iParameter != 8)) ||
					(PointPurchaseType == 1 && (ExperienceLevel[client] >= ExperienceCost || ExperienceCost == 0 || isClientGhost && isCommandChangeClass && iParameter != 8))) {
					if (!isCommandChangeClass || isCommandChangeClass && iParameter == 8 || isCommandChangeClass && isPlayerAlive && !isClientGhost) {
						if (PointPurchaseType == 0 && (Points[client] >= PointCost || PointCost == 0.0 || (!b_IsActiveRound && iPreGameFree == 1))) {
							if (PointCost > 0.0 && Points[client] >= PointCost || PointCost <= 0.0) {
								if (iPreGameFree != 1 || b_IsActiveRound) Points[client] -= PointCost;
							}
						}
						else if (PointPurchaseType == 1 && (ExperienceLevel[client] >= ExperienceCost || ExperienceCost == 0)) ExperienceLevel[client] -= ExperienceCost;
					}
					if (isParameterCommon && StrEqualAtPos(Model, ".mdl", strlen(Model)-4)) {
						Count = Count + (CountHandicap * LivingSurvivorCount());

						for (int i = Count; i > 0 && GetArraySize(CommonInfectedQueue) < CommonQueueMaxx; i--) {

							if (Drop == 1) {

								ResizeArray(CommonInfectedQueue, GetArraySize(CommonInfectedQueue) + 1);
								ShiftArrayUp(CommonInfectedQueue, 0);
								SetArrayString(CommonInfectedQueue, 0, Model);
								TargetClient		=	FindLivingSurvivor();
								if (TargetClient > 0) ExecCheatCommand(TargetClient, Command, Parameter);
							}
							else PushArrayString(CommonInfectedQueue, Model);
						}
					}
					else if (isCommandChangeClass) {
						if (!isClientGhost) {
							int iSurvivorVictim = L4D2_GetSurvivorVictim(client);
							if (iZombieClass == ZOMBIECLASS_TANK && PointPurchaseType == 0) Points[client] += PointCost;
							else if (iZombieClass == ZOMBIECLASS_TANK && PointPurchaseType == 1) ExperienceLevel[client] += ExperienceCost;
							else if (isPlayerAlive && iZombieClass == ZOMBIECLASS_CHARGER && iSurvivorVictim != -1 && PointPurchaseType == 0) Points[client] += PointCost;
							else if (isPlayerAlive && iZombieClass == ZOMBIECLASS_CHARGER && iSurvivorVictim != -1 && PointPurchaseType == 1) ExperienceLevel[client] += ExperienceCost;
						}
						if (iZombieClass != ZOMBIECLASS_TANK) ChangeInfectedClass(client, iParameter);
					}
					else if (StrEqual(Command, "respawn")) {
						SDKCall(hRoundRespawn, client);
						CreateTimer(0.2, Timer_TeleportRespawn, client, TIMER_FLAG_NO_MAPCHANGE);
					}
					else if (StrEqual(Command, "melee")) {
						L4D_RemoveWeaponSlot(client, L4DWeaponSlot_Secondary);
						int ent			= CreateEntityByName("weapon_melee");
						DispatchKeyValue(ent, "melee_script_name", Parameter);
						DispatchSpawn(ent);
						EquipPlayerWeapon(client, ent);
					}
					else {
						if ((PointCost == 0.0 || (iPreGameFree == 1 && !b_IsActiveRound)) && GetClientTeam(client) == TEAM_SURVIVOR) {
							if (StrBeginsWith(Parameter, "pistol") || IsMeleeWeaponParameter(Parameter)) {
								L4D_RemoveWeaponSlot(client, L4DWeaponSlot_Secondary);
							}
							else L4D_RemoveWeaponSlot(client, L4DWeaponSlot_Primary);
						}
						for (int i = 0; i <= PCount; i++) {
							ExecCheatCommand(client, Command, Parameter);
						}
						if (isParameterHealth) {
							CreateTimer(0.2, Timer_GiveMaximumHealth, client, TIMER_FLAG_NO_MAPCHANGE);
						}
					}
				}
			}
			else {
				if (menuPos < GetArraySize(a_DirectorActions_Cooldown)) GetArrayString(a_DirectorActions_Cooldown, menuPos, IsCooldown, sizeof(IsCooldown));
				if (StringToInt(IsCooldown) > 0 && GetConfigValueInt("menu override director cooldown?") == 0) PrintToChat(client, "%T", "Menu Option is On Cooldown", client, green, Name, white);
				else {
					if (PointPurchaseType == 0) {
						if (Points_Director == 0.0 || Points_Director > 0.0 && (Points_Director * PointCost) < PointCostMinimum) PointCost = PointCostMinimum;
						else PointCost *= Points_Director;
						if (Points_Director >= PointCost) {
							Points_Director -= PointCost;
							if (isParameterCommon && StrEqualAtPos(Model, ".mdl", strlen(Model)-4)) {
								for (int i = Count; i > 0 && GetArraySize(CommonInfectedQueue) < CommonQueueMaxx; i--) {
									if (Drop == 1) {
										ResizeArray(CommonInfectedQueue, GetArraySize(CommonInfectedQueue) + 1);
										ShiftArrayUp(CommonInfectedQueue, 0);
										SetArrayString(CommonInfectedQueue, 0, Model);
										TargetClient		=	FindLivingSurvivor();
										if (TargetClient > 0) ExecCheatCommand(TargetClient, Command, Parameter);
									}
									else PushArrayString(CommonInfectedQueue, Model);
								}
							}
							else ExecCheatCommand(client, Command, Parameter);
						}
					}
					else if (PointPurchaseType == 1) {

						if (ExperienceLevel_Bots >= ExperienceCost || ExperienceCost == 0) ExperienceLevel_Bots -= ExperienceCost;
						if (isParameterCommon && StrEqualAtPos(Model, ".mdl", strlen(Model)-4)) {

							for (int i = Count; i > 0 && GetArraySize(CommonInfectedQueue) < CommonQueueMaxx; i--) {

								if (Drop == 1) {

									ResizeArray(CommonInfectedQueue, GetArraySize(CommonInfectedQueue) + 1);
									ShiftArrayUp(CommonInfectedQueue, 0);
									SetArrayString(CommonInfectedQueue, 0, Model);
									TargetClient		=	FindLivingSurvivor();
									if (TargetClient > 0) ExecCheatCommand(TargetClient, Command, Parameter);
								}
								else PushArrayString(CommonInfectedQueue, Model);
							}
						}
						else ExecCheatCommand(client, Command, Parameter);
					}
				}
			}
			BuildPointsMenu(client, MenuName, ConfigName);
		}
	}
	else if (action == MenuAction_Cancel) {

		if (slot == MenuCancel_ExitBack) {

			if (iIsWeaponLoadout[client] == 0) BuildMenu(client);
			else SpawnLoadoutEditor(client);
		}
	}
	else if (action == MenuAction_End) {

		CloseHandle(menu);
	}
}
