stock BuildMenuTitle(client, Handle:menu, bot = 0, type = 0, bool:bIsPanel = false, bool:ShowLayerEligibility = false) {	// 0 is legacy type that appeared on all menus. 0 - Main Menu | 1 - Upgrades | 2 - Points

	decl String:text[512], String:stext[512];
	new CurRPGMode = iRPGMode;

	if (bot == 0) {

		decl String:PointsText[64];
		Format(PointsText, sizeof(PointsText), "%T", "Points Text", client, Points[client]);

		new CheckRPGMode = iRPGMode;
		if (CheckRPGMode > 0) {

			new bool:bIsLayerEligible = (PlayerCurrentMenuLayer[client] <= 1 || GetLayerUpgradeStrength(client, PlayerCurrentMenuLayer[client] - 1) >= PlayerCurrentMenuLayer[client]) ? true : false;

			new TotalPoints = TotalPointsAssigned(client);
			decl String:PlayerLevelText[256];
			Format(PlayerLevelText, sizeof(PlayerLevelText), "%T", "Player Level Text", client, PlayerLevel[client], iMaxLevel, AddCommasToString(ExperienceLevel[client]), MenuExperienceBar(client), AddCommasToString(CheckExperienceRequirement(client)), AddCommasToString(Rating[client]));
			new maximumPlayerUpgradesToShow = (iShowTotalNodesOnTalentTree == 1) ? MaximumPlayerUpgrades(client, true) : MaximumPlayerUpgrades(client);
			if (CheckRPGMode != 0) {
				Format(text, sizeof(text), "%T", "RPG Header", client, PlayerLevelText, TotalPoints, maximumPlayerUpgradesToShow, UpgradesAvailable[client] + FreeUpgrades[client]);
				if (ShowLayerEligibility) {
					if (bIsLayerEligible) {
						new strengthOfCurrentLayer = GetLayerUpgradeStrength(client, PlayerCurrentMenuLayer[client]);
						new allUpgradesThisLayer = GetLayerUpgradeStrength(client, PlayerCurrentMenuLayer[client], _, _, true);
						new totalPossibleNodesThisLayer = GetLayerUpgradeStrength(client, PlayerCurrentMenuLayer[client], _, _, _, true);
						Format(text, sizeof(text), "%T", "RPG Layer Eligible", client, text, PlayerCurrentMenuLayer[client], strengthOfCurrentLayer, PlayerCurrentMenuLayer[client] + 1, allUpgradesThisLayer, totalPossibleNodesThisLayer);
					}
					else Format(text, sizeof(text), "%T", "RPG Layer Not Eligible", client, text, PlayerCurrentMenuLayer[client]);
				}
			}
			if (CheckRPGMode != 1) Format(text, sizeof(text), "%s\n%s", text, PointsText);
			//Format(stext, sizeof(stext), "%T", "Class Level Text", client, TheClass, AddCommasToString(CartelLevel(client)));
			//Format(stext, sizeof(stext), "Class: %s", stext);
			//Format(stext, sizeof(stext), "%s\n \nDifficulty: %s (%s)", stext, AddCommasToString(Rating[client]), AddCommasToString(TruRating(client)));
			//Format(text, sizeof(text), "%s\n \n%s", text, stext);
			//Format(text, sizeof(text), "%s\n \n%s", text, stext);

			//new RestedExperienceMaximum = GetConfigValueInt("rested experience maximum?");
			//if (RestedExperienceMaximum < 1) RestedExperienceMaximum = CheckExperienceRequirement(client);
			//if (RestedExperience[client] > 0) Format(text, sizeof(text), "%T", "Menu Rested Experience", client, text, AddCommasToString(RestedExperience[client]), AddCommasToString(RestedExperienceMaximum), RoundToCeil(100.0 * GetConfigValueFloat("rested experience multiplier?")));
			if (ExperienceDebt[client] > 0 && GetConfigValueInt("experience debt enabled?") == 1 && PlayerLevel[client] >= GetConfigValueInt("experience debt level?")) {

				Format(text, sizeof(text), "%T", "Menu Experience Debt", client, text, AddCommasToString(ExperienceDebt[client]), RoundToCeil(100.0 * GetConfigValueFloat("experience debt penalty?")));
			}
		}
		else if (CurRPGMode == 0) Format(text, sizeof(text), "%s", PointsText);
		else Format(text, sizeof(text), "Control Panel");
	}
	else {

		if (CurRPGMode == 0 || CurRPGMode == 2 && bot == -1) Format(text, sizeof(text), "%T", "Menu Header 0 Director", client, Points_Director);
		else if (CurRPGMode == 1) {

			// Bots level up strictly based on experience gain. Honestly, I have been thinking about removing talent-based leveling.
			Format(text, sizeof(text), "%T", "Menu Header 1 Talents Bot", client, PlayerLevel_Bots, iMaxLevel, AddCommasToString(ExperienceLevel_Bots), AddCommasToString(CheckExperienceRequirement(-1, true)), AddCommasToString(GetUpgradeExperienceCost(-1)));
		}
		else if (CurRPGMode == 2) {

			Format(text, sizeof(text), "%T", "Menu Header 2 Talents Bot", client, PlayerLevel_Bots, iMaxLevel, AddCommasToString(ExperienceLevel_Bots), AddCommasToString(CheckExperienceRequirement(-1, true)), AddCommasToString(GetUpgradeExperienceCost(-1)), Points_Director);
		}
	}
	ReplaceString(text, sizeof(text), "PCT", "%%", true);
	Format(text, sizeof(text), "\n \n%s\n \n", text);
	if (!bIsPanel) SetMenuTitle(menu, text);
	else DrawPanelText(menu, text);
}

/*stock VerifyUpgradeExperienceCost(client) {

	if (GetUpgradeExperienceCost(client) > CheckExperienceRequirement(client) && PlayerUpgradesTotal[client] < MaximumPlayerUpgrades(client)) {

		if (FreeUpgrades[client] < MaximumPlayerUpgrades(client) - PlayerUpgradesTotal[client]) {

			FreeUpgrades[client] += (MaximumPlayerUpgrades(client) - PlayerUpgradesTotal[client] - FreeUpgrades[client]);
		}
	}
}*/

stock bool:CheckKillPositions(client, bool:b_AddPosition) {

	// If the finale is active, we don't do anything here, and always return false.
	//if (!b_IsFinaleActive) return false;
	// If there are enemy combatants within range - and thus the player is fighting - don't save locations.
	//if (EnemyCombatantsWithinRange(client, StringToFloat(GetConfigValue("out of combat distance?")))) return false;

	// If not adding a kill position, it means we need to check the clients current position against all positions in the list, and see if any are within the config value.
	// If they are, we return true, otherwise false.
	// If we are adding a position, we check to see if the size is greater than the max value in the config. If it is, we remove the oldest entry, and add the newest entry.
	// We can do this by removing from array, or just resizing the array to the config value after adding the value.

	new Float:Origin[3];
	GetClientAbsOrigin(client, Origin);
	decl String:coords[64];

	new Float:AntiFarmDistance = GetConfigValueFloat("anti farm kill distance?");
	new AntiFarmMax = GetConfigValueInt("anti farm kill max locations?");

	if (!b_AddPosition) {

		new Float:Last_Origin[3];
		new size				= GetArraySize(h_KilledPosition_X[client]);
		
		for (new i = 0; i < size; i++) {

			GetArrayString(Handle:h_KilledPosition_X[client], i, coords, sizeof(coords));
			Last_Origin[0]		= StringToFloat(coords);
			GetArrayString(Handle:h_KilledPosition_Y[client], i, coords, sizeof(coords));
			Last_Origin[1]		= StringToFloat(coords);
			GetArrayString(Handle:h_KilledPosition_Z[client], i, coords, sizeof(coords));
			Last_Origin[2]		= StringToFloat(coords);

			// If the players current position is too close to any stored positions, return true
			if (GetVectorDistance(Origin, Last_Origin) <= AntiFarmDistance) return true;
		}
	}
	else {

		new newsize = GetArraySize(h_KilledPosition_X[client]);

		ResizeArray(h_KilledPosition_X[client], newsize + 1);
		Format(coords, sizeof(coords), "%3.4f", Origin[0]);
		SetArrayString(h_KilledPosition_X[client], newsize, coords);

		ResizeArray(h_KilledPosition_Y[client], newsize + 1);
		Format(coords, sizeof(coords), "%3.4f", Origin[1]);
		SetArrayString(h_KilledPosition_Y[client], newsize, coords);

		ResizeArray(h_KilledPosition_Z[client], newsize + 1);
		Format(coords, sizeof(coords), "%3.4f", Origin[2]);
		SetArrayString(h_KilledPosition_Z[client], newsize, coords);

		while (GetArraySize(h_KilledPosition_X[client]) > AntiFarmMax) {

			RemoveFromArray(Handle:h_KilledPosition_X[client], 0);
			RemoveFromArray(Handle:h_KilledPosition_Y[client], 0);
			RemoveFromArray(Handle:h_KilledPosition_Z[client], 0);
		}
	}
	return false;
}

stock bool:HasTalentUpgrades(client, String:TalentName[]) {

	if (IsLegitimateClient(client)) {

		new a_Size			=	0;

		a_Size		= GetArraySize(a_Menu_Talents);

		decl String:TalentName_Compare[64];

		for (new i = 0; i < a_Size; i++) {

			ChanceKeys[client]			= GetArrayCell(a_Menu_Talents, i, 0);
			ChanceValues[client]		= GetArrayCell(a_Menu_Talents, i, 1);
			ChanceSection[client]		= GetArrayCell(a_Menu_Talents, i, 2);

			GetArrayString(Handle:ChanceSection[client], 0, TalentName_Compare, sizeof(TalentName_Compare));
			if (StrEqual(TalentName, TalentName_Compare, false) && GetTalentStrength(client, TalentName) > 0) return true;
		}
	}
	return false;
}

public Action:CMD_LoadProfileEx(client, args) {

	if (args < 1) {

		PrintToChat(client, "!loadprofile <in-game user / steamid>");
		return Plugin_Handled;
	}
	decl String:arg[512];
	GetCmdArg(1, arg, sizeof(arg));

	if (!bIsTalentTwo[client] && StrContains(arg, "STEAM", false) == -1) {	// they have named a user.

		decl String:TheName[512];
		for (new i = 1; i <= MaxClients; i++) {

			if (!IsLegitimateClient(i) || IsFakeClient(i)) continue;

			GetClientName(i, TheName, sizeof(TheName));
			if (StrContains(arg, TheName, false) != -1) {

				GetClientAuthString(i, arg, sizeof(arg));
				break;
			}
		}
	}
	ReadProfiles(client, arg);
	PrintToChat(client, "trying to load profile of steam id: %s", arg);
	return Plugin_Handled;
}

stock LoadProfileEx(client, String:key[]) {
	if (IsSurvivorBot(LoadTarget[client]) || IsSurvivorBot(client) || LoadTarget[client] == -1 || IsLegitimateClient(LoadTarget[client]) && GetClientTeam(LoadTarget[client]) == TEAM_SURVIVOR) {
		new targetClient = LoadTarget[client];
		if (LoadTarget[client] == -1 || !IsLegitimateClient(LoadTarget[client])) targetClient = client;
		LoadTarget[client] = -1;
		if (IsSurvivorBot(targetClient) || b_IsLoaded[targetClient]) {
			LoadProfileEx_Confirm(targetClient, key);
		}
	}
}

stock LoadProfileEx_Confirm(client, String:key[]) {

	decl String:tquery[512];
	if (hDatabase == INVALID_HANDLE) {

		LogMessage("Database couldn't be found, cannot save for %N", client);
		return;
	}
	ClearArray(TempAttributes[client]);

	//if (HasCommandAccess(client, GetConfigValue("director talent flags?"))) PrintToChat(client, "%T", "loading profile ex", client, orange, key);
	//else
	if (!IsFakeClient(client)) PrintToChat(client, "%T", "loading profile", client, orange, green, key);

	//b_IsLoading[client] = false;
	Format(tquery, sizeof(tquery), "SELECT `steam_id`, `total upgrades` FROM `%s` WHERE (`steam_id` = '%s');", TheDBPrefix, key);
	// maybe set a value equal to the users steamid integer only, so if steam:0:1:23456, set the value of "client" equal to 23456 and then set the client equal to whatever client's steamid contains 23456?
	//LogMessage("Loading %N data: %s", client, tquery);
	SQL_TQuery(hDatabase, QueryResults_LoadEx, tquery, client);
	LogMessage(tquery);
}

/*stock CheckLoadProfileRequest(client, RequestType = 0, bool:DontTell = false) {

	if (!IsLegitimateClient(client)) return -1;
	decl String:TargetName[64];

	for (new i = 1; i <= MaxClients; i++) {

		if (IsLegitimateClient(i) && GetClientTeam(i) == TEAM_SURVIVOR && i != client) {

			if (client == LoadProfileRequestName[i]) {	// this is the player that client sent the request to.

				if (RequestType == 0) {		// 0	- Deny Request

					GetClientName(i, TargetName, sizeof(TargetName));
					if (!DontTell) PrintToChat(client, "%T", "profile request cancelled", client, orange, green, TargetName);
					LoadProfileRequestName[i] = -1;
					if (LoadTarget[])
				}
			}
		}
	}
}*/

/*stock CheckLoadProfileRequest(client, bool:CancelRequest = false, bool:DontTell = false) {

	if (!IsLegitimateClient(client)) return -1;
	decl String:TargetName[64];

	for (new i = 1; i <= MaxClients; i++) {

		if (IsLegitimateClient(i) && GetClientTeam(i) != TEAM_INFECTED && i != client) {

			if (client == LoadProfileRequestName[i]) {

				// the client has sent a load request, so if they are trying to cancel, we cancel.
				if (CancelRequest) {

					GetClientName(i, TargetName, sizeof(TargetName));
					if (!DontTell) PrintToChat(client, "%T", "profile request cancelled", client, orange, green, TargetName);
					LoadProfileRequestName[i] = -1;
					LoadTarget[client] = -1;
					return -1;
				}
				return i;
			}
		}
	}
	if (LoadTarget[client] == -1) return client;
	return LoadTarget[client];
}*/

public QueryResults_LoadEx(Handle:howner, Handle:hndl, const String:error[], any:client)
{
	if ( hndl != INVALID_HANDLE )
	{
		decl String:key[64];
		decl String:text[64];
		decl String:result[3][64];

		new owner = client;	// so if the load target is not the client we can track both.
		new bool:rowsFound = false;

		while (SQL_FetchRow(hndl))
		{
			SQL_FetchString(hndl, 0, key, sizeof(key));
			rowsFound = true;	// not sure how else to verify this without running a count query first.
			if (LoadTarget[owner] != owner && LoadTarget[owner] != -1 && (IsSurvivorBot(LoadTarget[owner]) || IsLegitimateClient(LoadTarget[owner]) && GetClientTeam(LoadTarget[owner]) != TEAM_INFECTED)) client = LoadTarget[owner];
			if (!IsLegitimateClient(client)) return;

			ExplodeString(key, "+", result, 3, 64);
			if (!StrEqual(result[1], LoadoutName[owner], false)) Format(LoadoutName[client], sizeof(LoadoutName[]), "%s", result[1]);
			PushArrayString(TempAttributes[client], key);
			PushArrayCell(TempAttributes[client], SQL_FetchInt(hndl, 1));

			PlayerUpgradesTotal[client]	= SQL_FetchInt(hndl, 1);
			UpgradesAvailable[client]	= 0;
			FreeUpgrades[client] = PlayerLevel[client] - PlayerUpgradesTotal[client];
			if (FreeUpgrades[client] < 0) FreeUpgrades[client] = 0;
			PurchaseTalentPoints[client] = PlayerUpgradesTotal[client];
		}
		if (!rowsFound) {
			b_IsLoading[client] = false;
			LogMessage("Could not load the profile on target client forced by %N, exiting loading sequence.", client);
			return;
		}
		decl String:tquery[512];
		//decl String:key[64];
		//GetClientAuthString(client, key, sizeof(key));

		LoadPos[client] = 0;
		if (!b_IsLoadingTrees[client]) b_IsLoadingTrees[client] = true;
		GetArrayString(Handle:a_Database_Talents, 0, text, sizeof(text));
		Format(tquery, sizeof(tquery), "SELECT `steam_id`, `%s` FROM `%s` WHERE (`steam_id` = '%s');", text, TheDBPrefix, key);
		SQL_TQuery(hDatabase, QueryResults_LoadTalentTreesEx, tquery, client);
	}
	else
	{
		SetFailState("Error: %s PREFIX IS: %s", error, TheDBPrefix);
		return;
	}
}

public QueryResults_LoadTalentTreesEx(Handle:owner, Handle:hndl, const String:error[], any:client) {

	if (hndl != INVALID_HANDLE) {

		decl String:text[512];
		decl String:tquery[512];
		new talentlevel = 0;
		new size = GetArraySize(Handle:a_Menu_Talents);
		decl String:key[64];
		decl String:skey[64];

		if (!IsLegitimateClient(client)) {

			LogMessage("is not a valid client.");
			return;
		}

		if (GetArraySize(a_Database_PlayerTalents[client]) != size) {

			ResizeArray(PlayerAbilitiesCooldown[client], size);
			ResizeArray(a_Database_PlayerTalents[client], size);
			ResizeArray(a_Database_PlayerTalents_Experience[client], size);
		}

		while (SQL_FetchRow(hndl)) {

			SQL_FetchString(hndl, 0, key, sizeof(key));

			if (LoadPos[client] < GetArraySize(a_Database_Talents)) {

				talentlevel = SQL_FetchInt(hndl, 1);
				//SetArrayString(TempTalents[client], LoadPos[client], text);
				SetArrayCell(a_Database_PlayerTalents[client], LoadPos[client], talentlevel);

				LoadPos[client]++;
				while (LoadPos[client] < GetArraySize(a_Database_Talents)) {

					TalentTreeKeys[client]			= GetArrayCell(a_Menu_Talents, LoadPos[client], 0);
					TalentTreeValues[client]		= GetArrayCell(a_Menu_Talents, LoadPos[client], 1);

					if (GetKeyValueInt(TalentTreeKeys[client], TalentTreeValues[client], "talent type?") == 1 ||
						GetKeyValueInt(TalentTreeKeys[client], TalentTreeValues[client], "is survivor class role?") == 1 ||
						GetKeyValueInt(TalentTreeKeys[client], TalentTreeValues[client], "is sub menu?") == 1 ||
						GetKeyValueInt(TalentTreeKeys[client], TalentTreeValues[client], "is ability?") == 1 ||
						GetKeyValueInt(TalentTreeKeys[client], TalentTreeValues[client], "is item?") == 1) {

						LoadPos[client]++;
						continue;	// we don't load class attributes because we're loading another players talent specs. don't worry... we'll load the CARTEL for the user, after.
					}
					break;
				}
				if (LoadPos[client] < GetArraySize(a_Database_Talents)) {

					GetArrayString(Handle:a_Database_Talents, LoadPos[client], text, sizeof(text));
					Format(tquery, sizeof(tquery), "SELECT `steam_id`, `%s` FROM `%s` WHERE (`steam_id` = '%s');", text, TheDBPrefix, key);
					SQL_TQuery(hDatabase, QueryResults_LoadTalentTreesEx, tquery, client);
					return;
				}
				else {

					Format(tquery, sizeof(tquery), "SELECT `steam_id`, `primarywep`, `secondwep` FROM `%s` WHERE (`steam_id` = '%s');", TheDBPrefix, key);
					//PrintToChat(client, "%s", tquery);
					SQL_TQuery(hDatabase, QueryResults_LoadTalentTreesEx, tquery, client);
					return;
				}
			}
			else {
				if (GetArraySize(hWeaponList[client]) != 2) {

					ClearArray(Handle:hWeaponList[client]);
					ResizeArray(Handle:hWeaponList[client], 2);
				}
				if (GetArraySize(hWeaponList[client]) > 0) {

					SQL_FetchString(hndl, 1, text, sizeof(text));
					SetArrayString(Handle:hWeaponList[client], 0, text);
					
					SQL_FetchString(hndl, 2, text, sizeof(text));
					SetArrayString(Handle:hWeaponList[client], 1, text);

					GiveProfileItems(client);
				}
				//PrintToChat(client, "ABOUT TO LOAD %s", text);
				//}

				GetClientAuthString(client, skey, sizeof(skey));	// this is necessary, because they might still be in the process of loading another users data. this is a backstop in-case the loader has switched targets mid-load. this is why we don't first check the value of LoadProfileRequestName[client].
				LoadPos[client] = 0;
				LoadTalentTrees(client, skey, true, key);
			}
			new PlayerTalentPoints			=	0;
			decl String:TalentName[64];

			//new size						=	GetArraySize(a_Menu_Talents);

			//if (StrEqual(ConfigName, CONFIG_MENUSURVIVOR)) size			=	GetArraySize(a_Menu_Talents_Survivor);
			//else if (StrEqual(ConfigName, CONFIG_MENUINFECTED)) size	=	GetArraySize(a_Menu_Talents_Infected);

			for (new i = 0; i < size; i++) {

				MenuKeys[client]			= GetArrayCell(a_Menu_Talents, i, 0);
				MenuValues[client]			= GetArrayCell(a_Menu_Talents, i, 1);
				MenuSection[client]			= GetArrayCell(a_Menu_Talents, i, 2);
				if (GetKeyValueInt(MenuKeys[client], MenuValues[client], "talent type?") == 1) continue;		// skips attributes.
				if (GetKeyValueInt(MenuKeys[client], MenuValues[client], "is survivor class role?") == 1) continue;
				//if (GetKeyValueInt(MenuKeys[client], MenuValues[client], "is ability?") == 1) continue;		// abilities used to be auto-unlocked, now they require a point.
				if (GetKeyValueInt(MenuKeys[client], MenuValues[client], "is item?") == 1) continue;

				GetArrayString(Handle:MenuSection[client], 0, TalentName, sizeof(TalentName));

				PlayerTalentPoints = GetTalentStrength(client, TalentName);
				if (PlayerTalentPoints > 1) {
					FreeUpgrades[client] += (PlayerTalentPoints - 1);
					PlayerUpgradesTotal[client] -= (PlayerTalentPoints - 1);
					AddTalentPoints(client, TalentName, (PlayerTalentPoints - 1));
				}
			}
		}
		if (IsSurvivorBot(client) && PlayerLevel[client] < iPlayerStartingLevel) {

			b_IsLoading[client] = false;
			bIsTalentTwo[client] = false;
			b_IsLoadingTrees[client] = false;
			CreateNewPlayerEx(client);
			return;
		}
		else {

			decl String:Name[64];
			if (iRPGMode >= 1) {

				SetMaximumHealth(client);
				GiveMaximumHealth(client);
				ProfileEditorMenu(client);
				GetClientName(client, Name, sizeof(Name));
				b_IsLoading[client] = false;
				b_IsLoadingTrees[client] = false;
				//bIsTalentTwo[client] = false;

				if (PlayerLevel[client] >= iPlayerStartingLevel) {

					PrintToChatAll("%t", "loaded profile", blue, Name, white, green, LoadoutName[client]);
					if (bIsNewPlayer[client]) {

						bIsNewPlayer[client] = false;
						SaveAndClear(client);
						ReadProfiles(client, "all");	// new players are given an option on what they want to play.
					}
				}
				else SetTotalExperienceByLevel(client, iPlayerStartingLevel);
				//EquipBackpack(client);
				return;
			}
		}
	}
	else {
		
		SetFailState("Error: %s", error);
		return;
	}
}

stock LoadProfile_Confirm(client, String:ProfileName[]) {

	//new Handle:menu = CreateMenu(LoadProfile_ConfirmHandle);
	//decl String:text[64];
	//decl String:result[2][64];
	LoadProfileEx(client, ProfileName);
}

stock LoadProfileEx_Request(client, target) {

	LoadProfileRequestName[target] = client;

	new Handle:menu = CreateMenu(LoadProfileRequestHandle);
	decl String:text[512];
	decl String:ClientName[64];
	GetClientName(client, ClientName, sizeof(ClientName));
	Format(text, sizeof(text), "%T", "profile load request", target, ClientName);
	SetMenuTitle(menu, text);

	Format(text, sizeof(text), "%T", "Allow Profile Request", target);
	AddMenuItem(menu, text, text);
	Format(text, sizeof(text), "%T", "Deny Profile Request", target);
	AddMenuItem(menu, text, text);

	SetMenuExitBackButton(menu, true);
	DisplayMenu(menu, target, 0);
}

public LoadProfileRequestHandle(Handle:menu, MenuAction:action, client, slot) {

	if (action == MenuAction_Select) {

		decl String:TargetName[64];
		if (slot == 0 && IsLegitimateClient(LoadProfileRequestName[client])) {

			GetClientName(LoadProfileRequestName[client], TargetName, sizeof(TargetName));
			PrintToChat(client, "%T", "target has authorized you", client, green, TargetName, orange);
			GetClientName(client, TargetName, sizeof(TargetName));
			PrintToChat(LoadProfileRequestName[client], "%T", "authorized client to load", LoadProfileRequestName[client], orange, green, TargetName, orange, blue, orange);

			LoadTarget[LoadProfileRequestName[client]] = client;
			//LoadProfileEx_Confirm(LoadProfileRequestName[client], LoadProfileRequest[client]);
		}
		else {

			if (IsLegitimateClient(LoadProfileRequestName[client]) && LoadTarget[LoadProfileRequestName[client]] == client) {

				GetClientName(client, TargetName, sizeof(TargetName));
				PrintToChat(LoadProfileRequestName[client], "%T", "user has withdrawn authorization", LoadProfileRequestName[client], green, TargetName, orange);
				GetClientName(LoadProfileRequestName[client], TargetName, sizeof(TargetName));
				PrintToChat(client, "%T", "withdrawn authorization to user", client, orange, green, TargetName);
				LoadTarget[LoadProfileRequestName[client]] = -1;
			}
			LoadProfileRequestName[client] = -1;
			CloseHandle(menu);
		}
	}
	else if (action == MenuAction_Cancel) {

		if (slot == MenuCancel_ExitBack) {

			ProfileEditorMenu(client);
		}
	}
	if (action == MenuAction_End && menu != INVALID_HANDLE) {

		CloseHandle(menu);
	}
}

stock GetTeamComposition(client) {

	new Handle:menu = CreateMenu(TeamCompositionMenuHandle);
	ClearArray(Handle:RPGMenuPosition[client]);

	decl String:text[512];

	new myteam = GetClientTeam(client);
	for (new i = 1; i <= MaxClients; i++) {

		if (!IsLegitimateClient(i) || myteam != GetClientTeam(i)) continue;

		GetClientName(i, text, sizeof(text));
		Format(text, sizeof(text), "[Rating: %s] (Lv.%s) %s", AddCommasToString(Rating[i]), AddCommasToString(PlayerLevel[i]), text);
		AddMenuItem(menu, text, text);
	}
	SetMenuExitBackButton(menu, true);
	DisplayMenu(menu, client, 0);
}

public TeamCompositionMenuHandle(Handle:menu, MenuAction:action, client, slot) {

	if (action == MenuAction_Select) {

		GetTeamComposition(client);
	}
	else if (action == MenuAction_Cancel) {

		if (slot == MenuCancel_ExitBack) {

			BuildMenu(client, "main");
		}
	}
	if (action == MenuAction_End) {

		//LoadTarget[client] = -1;
		CloseHandle(menu);
	}
}

stock LoadProfileTargetSurvivorBot(client) {

	new Handle:menu = CreateMenu(TargetSurvivorBotMenuHandle);
	ClearArray(Handle:RPGMenuPosition[client]);

	decl String:text[512];
	decl String:pos[512];

	Format(text, sizeof(text), "%T", "select survivor bot", client);
	SetMenuTitle(menu, text);
	for (new i = 1; i <= MaxClients; i++) {

		if (IsLegitimateClient(i) && GetClientTeam(i) != TEAM_INFECTED) {

			Format(pos, sizeof(pos), "%d", i);
			PushArrayString(Handle:RPGMenuPosition[client], pos);
			GetClientName(i, pos, sizeof(pos));
			Format(pos, sizeof(pos), "[Rtg %d] Lv.%d %s", Rating[i], PlayerLevel[i], pos);
			AddMenuItem(menu, pos, pos);
		}
	}
	SetMenuExitBackButton(menu, true);
	DisplayMenu(menu, client, 0);
}

public TargetSurvivorBotMenuHandle(Handle:menu, MenuAction:action, client, slot) {

	if (action == MenuAction_Select) {

		decl String:text[64];
		GetArrayString(Handle:RPGMenuPosition[client], slot, text, sizeof(text));
		new target = StringToInt(text);
		if (IsLegitimateClient(LoadTarget[client]) && IsLegitimateClient(LoadProfileRequestName[LoadTarget[client]]) && client == LoadProfileRequestName[LoadTarget[client]]) LoadProfileRequestName[LoadTarget[client]] = -1;
		if (target == client) {

			LoadTarget[client] = -1;
		}
		else {

			decl String:thetext[64];
			GetConfigValue(thetext, sizeof(thetext), "profile override flags?");

			if (IsSurvivorBot(target) || HasCommandAccess(client, thetext)) LoadTarget[client] = target;
			else {

				LoadProfileEx_Request(client, target);
				ProfileEditorMenu(client);
			}
		}
		ProfileEditorMenu(client);
	}
	else if (action == MenuAction_Cancel) {

		if (slot == MenuCancel_ExitBack) {

			ProfileEditorMenu(client);
		}
	}
	if (action == MenuAction_End) {

		//LoadTarget[client] = -1;
		CloseHandle(menu);
	}
}

stock ReadProfilesEx(client) {	// To view/load another users profile, we need to know who to target.


	//	ReadProfiles_Generate has been called and the PlayerProfiles[client] handle has been generated.
	new Handle:menu = CreateMenu(ReadProfilesMenuHandle);
	ClearArray(Handle:RPGMenuPosition[client]);

	decl String:text[64];
	decl String:pos[10];
	decl String:result[3][64];

	Format(text, sizeof(text), "%T", "profile editor title", client, LoadoutName[client]);
	SetMenuTitle(menu, text);

	new size = GetArraySize(PlayerProfiles[client]);
	if (size < 1) {

		PrintToChat(client, "%T", "no profiles to load", client, orange);
		ProfileEditorMenu(client);
		return;
	}
	for (new i = 0; i < size; i++) {

		GetArrayString(Handle:PlayerProfiles[client], i, text, sizeof(text));
		ExplodeString(text, "+", result, 3, 64);
		AddMenuItem(menu, result[1], result[1]);

		Format(pos, sizeof(pos), "%d", i);
		PushArrayString(Handle:RPGMenuPosition[client], pos);
	}
	SetMenuExitBackButton(menu, true);
	DisplayMenu(menu, client, 0);
}

public ReadProfilesMenuHandle(Handle:menu, MenuAction:action, client, slot) {

	if (action == MenuAction_Select) {

		decl String:text[64];
		GetArrayString(Handle:RPGMenuPosition[client], slot, text, sizeof(text));

		//new target = client;
		//if (LoadTarget[client] != -1 && LoadTarget[client] != client) target = LoadTarget[client]; 
		// && (IsSurvivorBot(LoadTarget[client]) || !bIsInCombat[LoadTarget[client]]))

		if (StringToInt(text) < GetArraySize(PlayerProfiles[client])) {
			//(!bIsInCombat[client] || target != client) &&

			GetArrayString(Handle:PlayerProfiles[client], StringToInt(text), text, sizeof(text));
			LoadProfile_Confirm(client, text);
		}
		else ProfileEditorMenu(client);
	}
	else if (action == MenuAction_Cancel) {

		if (slot == MenuCancel_ExitBack) ProfileEditorMenu(client);
	}
	if (action == MenuAction_End) {

		CloseHandle(menu);
	}
}

stock bool:GetLastOpenedMenu(client, bool:SetIt = false) {

	new size	= GetArraySize(a_Menu_Main);
	decl String:menuname[64];
	decl String:pmenu[64];

	for (new i = 0; i < size; i++) {

		// Pull data from the parsed config.
		MenuKeys[client]		= GetArrayCell(a_Menu_Main, i, 0);
		MenuValues[client]		= GetArrayCell(a_Menu_Main, i, 1);
		FormatKeyValue(menuname, sizeof(menuname), MenuKeys[client], MenuValues[client], "menu name?");

		if (!StrEqual(menuname, LastOpenedMenu[client], false)) continue;
		FormatKeyValue(pmenu, sizeof(pmenu), MenuKeys[client], MenuValues[client], "previous menu?");

		if (SetIt) {

			if (!StrEqual(pmenu, "-1", false)) Format(LastOpenedMenu[client], sizeof(LastOpenedMenu[]), "%s", pmenu);
			return true;
		}
	}
	return false;
}

stock AddMenuStructure(client, String:MenuName[]) {

	ResizeArray(Handle:MenuStructure[client], GetArraySize(MenuStructure[client]) + 1);
	SetArrayString(Handle:MenuStructure[client], GetArraySize(MenuStructure[client]) - 1, MenuName);
}

stock VerifyAllActionBars(client) {

	if (!IsLegitimateClient(client)) return;
	new ActionSlots = iActionBarSlots;
	if (GetArraySize(Handle:ActionBar[client]) != ActionSlots) ResizeArray(Handle:ActionBar[client], ActionSlots);

	// If the user doesn't meet the requirements or have the item it'll be unequipped here

	decl String:talentname[64];

	new size = iActionBarSlots;
	for (new i = 0; i < size; i++) {

		GetArrayString(Handle:ActionBar[client], i, talentname, sizeof(talentname));
		VerifyActionBar(client, talentname, i);
	}
}

stock ShowActionBar(client) {

	new Handle:menu = CreateMenu(ActionBarHandle);

	decl String:text[128], String:talentname[64];
	Format(text, sizeof(text), "Stamina: %d (Max: %d)", SurvivorStamina[client], GetPlayerStamina(client));
	
	new baseWeaponDamage = DataScreenWeaponDamage(client);
	if (baseWeaponDamage > 0) Format(text, sizeof(text), "%s\nBullet Damage: %s", text, AddCommasToString(baseWeaponDamage));
	SetMenuTitle(menu, text);
	new size = iActionBarSlots;
	new Float:AmmoCooldownTime = -1.0, Float:fAmmoCooldownTime = -1.0, Float:fAmmoCooldown = 0.0, Float:fAmmoActive = 0.0;

	decl String:acmd[10];
	GetConfigValue(acmd, sizeof(acmd), "action slot command?");
	new TalentStrength = 0;

	//decl String:TheValue[64];
	new bool:bIsAbility = false;
	new ManaCost = 0;
	new Float:TheAbilityMultiplier = 0.0;
	//decl String:tCooldown[16];
	for (new i = 0; i < size; i++) {

		GetArrayString(Handle:ActionBar[client], i, talentname, sizeof(talentname));
		if (VerifyActionBar(client, talentname, i)) {

			TalentStrength = GetTalentStrength(client, talentname);
		}
		else TalentStrength = 0;

		if (TalentStrength > 0) {

			AmmoCooldownTime = GetAmmoCooldownTime(client, talentname);
			GetTranslationOfTalentName(client, talentname, text, sizeof(text), _, true);
			Format(text, sizeof(text), "%T", text, client);
		}
		else Format(text, sizeof(text), "%T", "No Action Equipped", client);

		Format(text, sizeof(text), "!%s%d:\t%s", acmd, i+1, text);

		if (TalentStrength > 0) {

			bIsAbility = IsAbilityTalent(client, talentname);

			if (!bIsAbility) {

				ManaCost = RoundToCeil(GetSpecialAmmoStrength(client, talentname, 2));
				if (ManaCost > 0) Format(text, sizeof(text), "%s\nCost: %d Mana", text, ManaCost);
			}
			else if (bIsAbility && AbilityDoesDamage(client, talentname)) {

				TheAbilityMultiplier = GetAbilityMultiplier(client, "0", _, talentname);
				baseWeaponDamage = RoundToCeil(baseWeaponDamage * TheAbilityMultiplier);

				Format(text, sizeof(text), "%s\nDamage: %d", text, baseWeaponDamage);
			}

			if (bIsAbility) {

				AmmoCooldownTime = GetAmmoCooldownTime(client, talentname, true);
				fAmmoCooldownTime = AmmoCooldownTime;

				// abilities dont show active time correctly (NOT FIXED)
				fAmmoActive = GetAbilityValue(client, talentname, "active time?");
				if (fAmmoCooldownTime != -1.0) {

					fAmmoCooldown = GetSpellCooldown(client, talentname);
					AmmoCooldownTime = fAmmoActive - (fAmmoCooldown - fAmmoCooldownTime);
				}
				//PrintToChat(client, "%s %3.3f", talentname, AmmoCooldownTime);
			}
			else {

				AmmoCooldownTime = GetAmmoCooldownTime(client, talentname);
				fAmmoCooldownTime = AmmoCooldownTime;
				if (fAmmoCooldownTime != -1.0) {

					AmmoCooldownTime = GetSpecialAmmoStrength(client, talentname);

					// finding out the active time of ammos isn't as easy because of design...
					fAmmoCooldown = AmmoCooldownTime + GetSpecialAmmoStrength(client, talentname, 1);
					AmmoCooldownTime = AmmoCooldownTime - (fAmmoCooldown - fAmmoCooldownTime);
					//PrintToChat(client, "%3.3f = %3.3f - (%3.3f - %3.3f)", AmmoCooldownTime, GetSpecialAmmoStrength(client, talentname), fAmmoCooldown, fAmmoCooldownTime);
				}
				else {

					AmmoCooldownTime = GetSpecialAmmoStrength(client, talentname);
				}
			}
			if (bIsAbility && AmmoCooldownTime != -1.0 && AmmoCooldownTime > 0.0 || !bIsAbility && (AmmoCooldownTime > 0.0 || AmmoCooldownTime == -1.0)) Format(text, sizeof(text), "%s\nActive: %3.2fs", text, AmmoCooldownTime);

			AmmoCooldownTime = fAmmoCooldownTime;
			if (AmmoCooldownTime != -1.0) Format(text, sizeof(text), "%s\nCooldown: %3.2fs", text, AmmoCooldownTime);
		}
		AddMenuItem(menu, text, text);
	}
	SetMenuExitBackButton(menu, false);
	DisplayMenu(menu, client, 0);
}

stock bool:AbilityDoesDamage(client, String:TalentName[]) {

	decl String:theQuery[64];
	Format(theQuery, sizeof(theQuery), "does damage?");
	IsAbilityTalent(client, TalentName, theQuery, sizeof(theQuery));

	if (StringToInt(theQuery) == 1) return true;
	return false;
}

stock bool:VerifyActionBar(client, String:TalentName[], pos) {

	if (StrEqual(TalentName, "none", false)) return false;
	if (!IsAbilityTalent(client, TalentName) && (!IsTalentExists(TalentName) || GetTalentStrength(client, TalentName) < 1)) {

		decl String:none[64];
		Format(none, sizeof(none), "none");
		SetArrayString(Handle:ActionBar[client], pos, none);
		return false;
	}
	return true;
}

stock bool:IsAbilityTalent(client, String:TalentName[], String:SearchKey[] = "none", TheSize = 0) {	// Can override the search query, and then said string will be replaced and sent back

	decl String:text[64];

	new size = GetArraySize(a_Database_Talents);
	for (new i = 0; i < size; i++) {

		GetArrayString(a_Database_Talents, i, text, sizeof(text));
		IsAbilityKeys[client]			= GetArrayCell(a_Menu_Talents, i, 0);
		IsAbilityValues[client]			= GetArrayCell(a_Menu_Talents, i, 1);
		IsAbilitySection[client]		= GetArrayCell(a_Menu_Talents, i, 2);

		GetArrayString(Handle:IsAbilitySection[client], 0, text, sizeof(text));
		if (!StrEqual(TalentName, text)) continue;
		if (StrEqual(SearchKey, "none")) {

			if (GetKeyValueInt(IsAbilityKeys[client], IsAbilityValues[client], "is ability?") == 1) return true;
		}
		else {

			FormatKeyValue(SearchKey, TheSize, IsAbilityKeys[client], IsAbilityValues[client], SearchKey);
			return true;
		}
		break;
	}
	return false;
}

stock DrawAbilityEffect(client, String:sDrawEffect[], String:sTalentName[], iEffectType = 0) {

	if (StrEqual(sDrawEffect, "-1")) return;

	/*new Float:fCooldownTime = GetAmmoCooldownTime(client, sTalentName, true);
	new Float:fActive = GetAbilityValue(client, sTalentName, "active time?");
	new Float:fCooldown = GetSpellCooldown(client, sTalentName);

	if (fActive == -1.0) fCooldownTime = 0.2;
	else {

		if (fCooldownTime != -1.0) fCooldownTime = fActive - (fCooldown - fCooldownTime);
		if (fCooldownTime > 0.2) fCooldownTime = 0.2;
	}*/


	new ExplodeCount = GetDelimiterCount(sDrawEffect, "+") + 1;
	decl String:sEffects[ExplodeCount][64];
	ExplodeString(sDrawEffect, "+", sEffects, ExplodeCount, 64);
	//																size						color		pos			pulse?	lifetime
	if (iEffectType == 1 || iEffectType == 2) CreateRing(client, StringToFloat(sEffects[0]), sEffects[1], sEffects[2], false, 0.2);
	else {

		decl String:sInsEffects[3][64];
		new Handle:drawpack[ExplodeCount];
		for (new i = 0; i < ExplodeCount; i++) {

			ExplodeString(sEffects[i], ":", sInsEffects, 3, 64);
			CreateDataTimer(StringToFloat(sInsEffects[0]), Timer_DrawInstantEffect, drawpack[i], TIMER_FLAG_NO_MAPCHANGE);
			WritePackCell(drawpack[i], client);
			WritePackString(drawpack[i], sInsEffects[1]);
			WritePackString(drawpack[i], sInsEffects[2]);
			WritePackFloat(drawpack[i], StringToFloat(sInsEffects[0]));
		}
	}
}

public Action:Timer_DrawInstantEffect(Handle:timer, Handle:drawpack) {

	ResetPack(drawpack);
	new client				=	ReadPackCell(drawpack);
	if (IsLegitimateClient(client) && IsPlayerAlive(client)) {

		decl String:DrawColour[64], String:DrawPos[64];
		ReadPackString(drawpack, DrawColour, sizeof(DrawColour));
		ReadPackString(drawpack, DrawPos, sizeof(DrawPos));
		new Float:fDisplayTime = ReadPackFloat(drawpack);

		CreateRing(client, 128.0, DrawColour, DrawPos, false, fDisplayTime);
	}

	return Plugin_Stop;
}

stock bool:IsActionAbilityCooldown(client, String:TalentName[], bool:IsActiveInstead = false) {

	new Float:AmmoCooldownTime = GetAmmoCooldownTime(client, TalentName, true);
	new Float:fAmmoCooldownTime = AmmoCooldownTime;
	new Float:fAmmoCooldown = 0.0;

	// abilities dont show active time correctly (NOT FIXED)
	new Float:fAmmoActive = GetAbilityValue(client, TalentName, "active time?");
	if (fAmmoCooldownTime != -1.0) {

		fAmmoCooldown = GetSpellCooldown(client, TalentName);
		AmmoCooldownTime = fAmmoActive - (fAmmoCooldown - fAmmoCooldownTime);//copy to source
	}
	if (!IsActiveInstead) {

		if (AmmoCooldownTime != -1.0) return true;
	}
	else {

		if (AmmoCooldownTime != -1.0 && AmmoCooldownTime > 0.0) return true;
	}
	
	return false;
}

stock Float:CheckActiveAbility(client, thevalue, eventtype = 0, bool:IsPassive = false, bool:IsDrawEffect = false, bool:IsInstantDraw = false) {

	// we try to match up the eventtype with any ACTIVE talents on the action bar.
	// it is REALLY super simple, we have functions for everything. everythingggggg
	// get the size of the action bars first.
	if (IsSurvivorBot(client) && !IsDrawEffect) return 0.0;
	new ActionBarSize = iActionBarSlots;	// having your own extensive api really helps.
	if (GetArraySize(ActionBar[client]) != ActionBarSize) ResizeArray(ActionBar[client], ActionBarSize);
	decl String:text[64], String:Effects[64], String:none[64], String:sDrawEffect[PLATFORM_MAX_PATH];	// free guesses on what this one is for.
	Format(none, sizeof(none), "none");	// you guessed it.
	new pos = -1;
	new bool:IsMultiplier = false;
	new Float:MyMultiplier = 1.0;
	//new MyAttacker = L4D2_GetInfectedAttacker(client);
	new size = GetArraySize(Handle:ActionBar[client]);
	//new Float:fAbilityTime = 0.0;

	new IsPassiveAbility = 0;
	PassiveEffectDisplay[client]++;
	if (PassiveEffectDisplay[client] >= size ||
		PassiveEffectDisplay[client] < 0) PassiveEffectDisplay[client] = 0;

	for (new i = 0; i < size; i++) {

		if (IsInstantDraw && thevalue != i) continue;

		GetArrayString(Handle:ActionBar[client], i, text, sizeof(text));
		if (!VerifyActionBar(client, text, i)) continue;	// not a real talent or has no points in it.
		if (!IsAbilityActive(client, text) && !IsDrawEffect) continue;	// inactive / passive / toggle abilities go through to the draw section.

		pos = GetMenuPosition(client, text);
		if (pos < 0) continue;

		CheckAbilityKeys[client]		= GetArrayCell(a_Menu_Talents, pos, 0);
		CheckAbilityValues[client]		= GetArrayCell(a_Menu_Talents, pos, 1);


		if (IsDrawEffect) {

			if (GetKeyValueInt(CheckAbilityKeys[client], CheckAbilityValues[client], "is ability?") == 1) {

				IsPassiveAbility = GetKeyValueInt(CheckAbilityKeys[client], CheckAbilityValues[client], "passive only?");

				//CheckAbilitySection[client]		= GetArrayCell(a_Menu_Talents, pos, 2);
				//GetArrayString(CheckAbilitySection[client], 0, sTalentName, sizeof(sTalentName));

				//fAbilityTime = GetKeyValueFloat(CheckAbilityKeys[client], CheckAbilityValues[client], "active time?");

				if (IsInstantDraw) {

					FormatKeyValue(sDrawEffect, sizeof(sDrawEffect), CheckAbilityKeys[client], CheckAbilityValues[client], "instant draw?");
					if (!StrEqual(sDrawEffect, "-1")) DrawAbilityEffect(client, sDrawEffect, text);
				}
				else {

					if (IsActionAbilityCooldown(client, text, true)) {// || !StrEqual(sPassiveEffects, "-1.0") && !IsActionAbilityCooldown(client, text)) {

						FormatKeyValue(sDrawEffect, sizeof(sDrawEffect), CheckAbilityKeys[client], CheckAbilityValues[client], "draw effect?");
						if (!StrEqual(sDrawEffect, "-1")) DrawAbilityEffect(client, sDrawEffect, text, 1);
					}
					else if (PassiveEffectDisplay[client] == i && IsPassiveAbility == 1) {

						FormatKeyValue(sDrawEffect, sizeof(sDrawEffect), CheckAbilityKeys[client], CheckAbilityValues[client], "passive draw?");
						if (!StrEqual(sDrawEffect, "-1")) DrawAbilityEffect(client, sDrawEffect, text, 2);
					}
				}
			}
			continue;
		}

		if (GetKeyValueInt(CheckAbilityKeys[client], CheckAbilityValues[client], "event type?") != eventtype) continue;
		
		if (!IsPassive) {

			FormatKeyValue(Effects, sizeof(Effects), CheckAbilityKeys[client], CheckAbilityValues[client], "active effect?");

			if (StrContains(Effects, "X", true) != -1) {

				if (thevalue >= GetClientHealth(client)) {

					// attacks that would kill or incapacitate are completely nullified
					// this unfortunately also means that abilties that would be offensive or utility as a result of this attack do not fire.
					// we will later create a class that ignores this rule. Adventurer: "Years of hardened adventuring and ability use has led to the ability to both use AND bend mothers will"
					if (!IsMultiplier) return 0.0;
					MyMultiplier = 0.0;		// even if other active abilities fire, no incoming damage is coming through. Go you, adventurer.
				}
			}
		}
		else {

			FormatKeyValue(Effects, sizeof(Effects), CheckAbilityKeys[client], CheckAbilityValues[client], "passive effect?");

			if (StrContains(Effects, "S", true) != -1 && thevalue == 19) {

				return 1.0;
			}
		}
	}
	if (MyMultiplier <= 0.0) return 0.0;
	return (MyMultiplier * thevalue);
}

public ActionBarHandle(Handle:menu, MenuAction:action, client, slot) {

	if (action == MenuAction_Select) {

		CastActionEx(client, _, -1, slot);
	}
	else if (action == MenuAction_Cancel) {

		if (slot != MenuCancel_ExitBack) {
		}
	}
	if (action == MenuAction_End) {

		//DisplayActionBar[client] = false;
		CloseHandle(menu);
	}
}

stock BuildMenu(client, String:TheMenuName[] = "none") {

	if (b_IsLoading[client]) {

		PrintToChat(client, "%T", "loading data cannot open menu", client, orange);
		return;
	}

	decl String:MenuName[64];
	if (StrEqual(TheMenuName, "none", false) && GetArraySize(MenuStructure[client]) > 0) {

		GetArrayString(Handle:MenuStructure[client], GetArraySize(MenuStructure[client]) - 1, MenuName, sizeof(MenuName));
		RemoveFromArray(Handle:MenuStructure[client], GetArraySize(MenuStructure[client]) - 1);
	}
	else Format(MenuName, sizeof(MenuName), "%s", TheMenuName);
	if (StrEqual(MenuName, "main")) ShowPlayerLayerInformation[client] = false;		// layer info is NEVER shown on the main menu.

	//PrintToChatAll("Menu name: %s", MenuName);


	// Format(LastOpenedMenu[client], sizeof(LastOpenedMenu[]), "%s", MenuName);
	//VerifyUpgradeExperienceCost(client);
	VerifyMaxPlayerUpgrades(client);
	ClearArray(RPGMenuPosition[client]);

	// Build the base menu
	new Handle:menu		= CreateMenu(BuildMenuHandle);
	// Keep track of the position selected.
	decl String:pos[64];

	if (!b_IsDirectorTalents[client]) BuildMenuTitle(client, menu, _, 0, _, ShowPlayerLayerInformation[client]);
	else BuildMenuTitle(client, menu, 1, _, _, ShowPlayerLayerInformation[client]);

	decl String:text[PLATFORM_MAX_PATH];
	// declare the variables for requirements to display in menu.
	decl String:teamsAllowed[64];
	decl String:gamemodesAllowed[64];
	decl String:flagsAllowed[64];
	decl String:currentGamemode[4];
	decl String:clientTeam[4];
	decl String:configname[64];

	decl String:t_MenuName[64];
	decl String:c_MenuName[64];

	//PrintToChatAll("Menu named: %s", MenuName);


	decl String:s_TalentDependency[64];
	// Collect player team and server gamemode.
	Format(currentGamemode, sizeof(currentGamemode), "%d", ReadyUp_GetGameMode());
	Format(clientTeam, sizeof(clientTeam), "%d", GetClientTeam(client));

	new size	= GetArraySize(a_Menu_Main);
	new CurRPGMode = iRPGMode;
	new XPRequired = CheckExperienceRequirement(client);
	//new ActionBarOption = -1;

	decl String:pct[4];
	Format(pct, sizeof(pct), "%");

	new iIsReadMenuName = 0;
	new iHasLayers = 0;
	new strengthOfCurrentLayer = 0;

	decl String:sCvarRequired[64];
	decl String:sCatRepresentation[64];

	decl String:translationInfo[64];

	for (new i = 0; i < size; i++) {

		// Pull data from the parsed config.
		MenuKeys[client]		= GetArrayCell(a_Menu_Main, i, 0);
		MenuValues[client]		= GetArrayCell(a_Menu_Main, i, 1);
		MenuSection[client]		= GetArrayCell(a_Menu_Main, i, 2);

		FormatKeyValue(t_MenuName, sizeof(t_MenuName), MenuKeys[client], MenuValues[client], "target menu?");
		FormatKeyValue(c_MenuName, sizeof(c_MenuName), MenuKeys[client], MenuValues[client], "menu name?");
		if (!StrEqual(MenuName, c_MenuName, false)) continue;

		//ActionBarOption = GetKeyValueInt(MenuKeys[client], MenuValues[client], "action bar option?");
		//if (ActionBarSlot[client] != -1 && ActionBarOption != 1) continue;
		
		// Reset data in display requirement variables to default values.
		Format(teamsAllowed, sizeof(teamsAllowed), "123");			// 1 (Spectator) 2 (Survivor) 3 (Infected) players allowed.
		Format(gamemodesAllowed, sizeof(gamemodesAllowed), "123");	// 1 (Coop) 2 (Versus) 3 (Survival) game mode variants allowed.
		Format(flagsAllowed, sizeof(flagsAllowed), "-1");			// -1 means no flag requirements specified.
		//TheDBPrefix
		// Collect the display requirement variables values.
		FormatKeyValue(teamsAllowed, sizeof(teamsAllowed), MenuKeys[client], MenuValues[client], "team?", teamsAllowed);
		FormatKeyValue(gamemodesAllowed, sizeof(gamemodesAllowed), MenuKeys[client], MenuValues[client], "gamemode?", gamemodesAllowed);
		FormatKeyValue(flagsAllowed, sizeof(flagsAllowed), MenuKeys[client], MenuValues[client], "flags?", flagsAllowed);
		FormatKeyValue(configname, sizeof(configname), MenuKeys[client], MenuValues[client], "config?");
		FormatKeyValue(s_TalentDependency, sizeof(s_TalentDependency), MenuKeys[client], MenuValues[client], "talent dependency?");
		FormatKeyValue(sCvarRequired, sizeof(sCvarRequired), MenuKeys[client], MenuValues[client], "cvar_required?");
		FormatKeyValue(translationInfo, sizeof(translationInfo), MenuKeys[client], MenuValues[client], "translation?");

		iIsReadMenuName = GetKeyValueInt(MenuKeys[client], MenuValues[client], "ignore header name?");
		iHasLayers = GetKeyValueInt(MenuKeys[client], MenuValues[client], "layers?");

		if (CurRPGMode < 0 && !StrEqual(configname, "leaderboards", false)) continue;

		// If a talent dependency is found AND the player has NO upgrades in said talent, the category is not displayed.
		if (StringToInt(s_TalentDependency) != -1 && !HasTalentUpgrades(client, s_TalentDependency)) continue;

		// If the player doesn't meet the requirements to have access to this menu option, we skip it.
		/*if (StrContains(teamsAllowed, clientTeam, false) == -1 || StrContains(gamemodesAllowed, currentGamemode, false) == -1 ||
			(!StrEqual(flagsAllowed, "-1", false) && !HasCommandAccess(client, flagsAllowed))) continue;*/

		if ((StrContains(teamsAllowed, clientTeam, false) == -1 && !b_IsDirectorTalents[client] || StrEqual(teamsAllowed, "2", false) && b_IsDirectorTalents[client]) ||
			!b_IsDirectorTalents[client] && (StrContains(gamemodesAllowed, currentGamemode, false) == -1 ||
			(!StrEqual(flagsAllowed, "-1", false) && !HasCommandAccess(client, flagsAllowed)))) continue;

		// Some menu options display only under specific circumstances, regardless of the new mainmenu.cfg structure.
		if (CurRPGMode == 0 && !StrEqual(configname, CONFIG_POINTS)) continue;
		if (CurRPGMode == 1 && StrEqual(configname, CONFIG_POINTS) && !b_IsDirectorTalents[client]) continue;
		if (GetArraySize(a_Store) < 1 && StrEqual(configname, CONFIG_STORE)) continue;

		if (!StrEqual(sCvarRequired, "-1", false) && FindConVar(sCvarRequired) == INVALID_HANDLE) continue;
		//if (StrEqual(configname, "respec", false) && bIsInCombat[client] && b_IsActiveRound) continue;

		// If director talent menu options is enabled by an admin, only specific options should show. We determine this here.
		if (b_IsDirectorTalents[client]) {

			if (StrEqual(configname, CONFIG_MENUTALENTS) || StrEqual(configname, CONFIG_POINTS) || b_IsDirectorTalents[client] && StrEqual(configname, "level up") || PlayerLevel[client] >= iMaxLevel && StrEqual(configname, "prestige") || StrEqual(MenuName, c_MenuName, false)) {

				Format(pos, sizeof(pos), "%d", i);
				PushArrayString(Handle:RPGMenuPosition[client], pos);
			}
			else continue;
		}
		if (iIsReadMenuName == 1) {

			if (StrEqual(configname, "autolevel toggle")) {

				if (iIsLevelingPaused[client] == 1 && b_IsActiveRound) Format(text, sizeof(text), "%T", "auto level (locked)", client, fDeathPenalty * 100.0, pct);
				else if (iIsLevelingPaused[client] == 1) Format(text, sizeof(text), "%T", "auto level (disabled)", client, fDeathPenalty * 100.0, pct);
				else Format(text, sizeof(text), "%T", "auto level (enabled)", client, fDeathPenalty * 100.0, pct);
			}
			else if (StrEqual(configname, "trails toggle")) {

				if (iIsBulletTrails[client] == 0) Format(text, sizeof(text), "%T", "bullet trails (disabled)", client);
				else Format(text, sizeof(text), "%T", "bullet trails (enabled)", client);
			}
			else if (StrEqual(configname, "level up")) {

				//if (!b_IsDirectorTalents[client]) {

				//if (PlayerUpgradesTotal[client] < MaximumPlayerUpgrades(client)) continue; //Format(text, sizeof(text), "%T", "level up unavailable", client, MaximumPlayerUpgrades(client) - PlayerUpgradesTotal[client]);
				if (iIsLevelingPaused[client] == 1) {

					if (ExperienceLevel[client] >= XPRequired) Format(text, sizeof(text), "%T", "level up available", client, AddCommasToString(XPRequired));
					else Format(text, sizeof(text), "%T", "level up unavailable", client, AddCommasToString(XPRequired - ExperienceLevel[client]));
				}
				else continue;
				/*}
				else {

					if (PlayerLevelUpgrades_Bots < MaxUpgradesPerLevel()) Format(text, sizeof(text), "%T", "level up unavailable", client, MaxUpgradesPerLevel() - PlayerLevelUpgrades_Bots);
					else Format(text, sizeof(text), "%T", "level up available", client, AddCommasToString(CheckExperienceRequirement(-1)));
				}*/
			}
			else if (StrEqual(configname, "prestige")) {

				if (ExperienceLevel[client] >= XPRequired && PlayerLevel[client] == iMaxLevel) Format(text, sizeof(text), "%T", "prestige up available", client);
				else Format(text, sizeof(text), "%T", "prestige unavailable", client, iMaxLevel, AddCommasToString(XPRequired));
			}
			else if (StrEqual(configname, "layerup")) {
				if (PlayerCurrentMenuLayer[client] <= 1) continue;
				Format(text, sizeof(text), "%T", "layer move", client, PlayerCurrentMenuLayer[client] - 1);
			}
			else if (StrEqual(configname, "layerdown")) {
				if (PlayerCurrentMenuLayer[client] >= iMaxLayers) continue;
				strengthOfCurrentLayer = GetLayerUpgradeStrength(client, PlayerCurrentMenuLayer[client]);
				if (strengthOfCurrentLayer >= PlayerCurrentMenuLayer[client] + 1) Format(text, sizeof(text), "%T", "layer move", client, PlayerCurrentMenuLayer[client] + 1);
				else Format(text, sizeof(text), "%T", "layer move locked", client, PlayerCurrentMenuLayer[client] + 1, PlayerCurrentMenuLayer[client], PlayerCurrentMenuLayer[client] + 1 - strengthOfCurrentLayer);
			}
		}
		else {
			GetArrayString(Handle:MenuSection[client], 0, text, sizeof(text));
			//if (iHasLayers < 1) {
			Format(text, sizeof(text), "%T", text, client);
			/*}
			else {
				Format(text, sizeof(text), "%T", text, PlayerCurrentMenuLayer[client], client);
			}*/
		}
		FormatKeyValue(sCatRepresentation, sizeof(sCatRepresentation), MenuKeys[client], MenuValues[client], "talent tree category?");
		if (!StrEqual(sCatRepresentation, "-1")) {
			new iMaxCategoryStrength = 0;
			if (iHasLayers == 1) {
				Format(sCatRepresentation, sizeof(sCatRepresentation), "%s%d", sCatRepresentation, PlayerCurrentMenuLayer[client]);
				iMaxCategoryStrength = GetCategoryStrength(client, sCatRepresentation, true);
				if (iMaxCategoryStrength < 1) continue;
			}
			Format(sCatRepresentation, sizeof(sCatRepresentation), "%T", "tree strength display", client, GetCategoryStrength(client, sCatRepresentation), iMaxCategoryStrength);
			Format(text, sizeof(text), "%s\t%s", text, sCatRepresentation);
		}
		// important that this specific statement about hiding/displaying menus is last, due to potential conflicts with director menus.
		if (!b_IsDirectorTalents[client]) {

			decl String:thevalue[64];
			GetConfigValue(thevalue, sizeof(thevalue), "chat settings flags?");

			if ((HasCommandAccess(client, thevalue) || GetConfigValueInt("all players chat settings?") == 1) || !StrEqual(configname, CONFIG_CHATSETTINGS)) {

				Format(pos, sizeof(pos), "%d", i);
				PushArrayString(Handle:RPGMenuPosition[client], pos);
			}
			else continue;
		}
		if (!StrEqual(translationInfo, "-1")) {
			Format(translationInfo, sizeof(translationInfo), "%T", translationInfo, client);
			Format(text, sizeof(text), "%s\n%s", text, translationInfo);
		}

		AddMenuItem(menu, text, text);
	}
	if (!StrEqual(MenuName, "main", false)) SetMenuExitBackButton(menu, true);
	else SetMenuExitBackButton(menu, false);
	DisplayMenu(menu, client, 0);
}

stock GetProfileLoadoutConfig(client, String:TheString[], thesize) {

	decl String:config[64];
	new size = GetArraySize(Handle:a_Menu_Main);

	for (new i = 0; i < size; i++) {

		LoadoutConfigKeys[client]		= GetArrayCell(a_Menu_Main, i, 0);
		LoadoutConfigValues[client]		= GetArrayCell(a_Menu_Main, i, 1);
		LoadoutConfigSection[client]	= GetArrayCell(a_Menu_Main, i, 2);

		FormatKeyValue(config, sizeof(config), LoadoutConfigKeys[client], LoadoutConfigValues[client], "config?");
		if (!StrEqual(sProfileLoadoutConfig, config)) continue;

		GetArrayString(Handle:LoadoutConfigSection[client], 0, TheString, thesize);
		break;
	}
	return;
}

public BuildMenuHandle(Handle:menu, MenuAction:action, client, slot) {

	if (action == MenuAction_Select)
	{
		// Declare variables for target config, menu name (some submenu's require this information) and the ACTUAL position for a slot
		// (as pos won't always line up with slot since items can be hidden under special circumstances.)
		decl String:config[64];
		decl String:menuname[64];
		decl String:pos[4];

		decl String:t_MenuName[64];
		decl String:c_MenuName[64];

		decl String:Name[64];

		decl String:sCvarRequired[64];

		new XPRequired = CheckExperienceRequirement(client);
		new iIsIgnoreHeader = 0;
		new iHasLayers = 0;
		//new isSubMenu = 0;

		// Get the real position to use based on the slot that was pressed.
		// This position was stored above in the accompanying menu function.
		GetArrayString(Handle:RPGMenuPosition[client], slot, pos, sizeof(pos));
		MenuKeys[client]			= GetArrayCell(a_Menu_Main, StringToInt(pos), 0);
		MenuValues[client]			= GetArrayCell(a_Menu_Main, StringToInt(pos), 1);
		MenuSection[client]			= GetArrayCell(a_Menu_Main, StringToInt(pos), 2);
		GetArrayString(Handle:MenuSection[client], 0, menuname, sizeof(menuname));

		new showLayerInfo = GetKeyValueInt(MenuKeys[client], MenuValues[client], "show layer info?");

		// We want to know the value of the target config based on the keys and values pulled.
		// This will be used to determine where we send the player.
		FormatKeyValue(config, sizeof(config), MenuKeys[client], MenuValues[client], "config?");
		FormatKeyValue(t_MenuName, sizeof(t_MenuName), MenuKeys[client], MenuValues[client], "target menu?");
		FormatKeyValue(c_MenuName, sizeof(c_MenuName), MenuKeys[client], MenuValues[client], "menu name?");

		iIsIgnoreHeader = GetKeyValueInt(MenuKeys[client], MenuValues[client], "ignore header name?");
		iHasLayers = GetKeyValueInt(MenuKeys[client], MenuValues[client], "layers?");

		FormatKeyValue(sCvarRequired, sizeof(sCvarRequired), MenuKeys[client], MenuValues[client], "cvar_required?");
		//isSubMenu = GetKeyValueInt(MenuKeys[client], MenuValues[client], "is sub menu?");
		// we only modify the value if it's set, otherwise it's grandfathered.
		if (showLayerInfo == 1) ShowPlayerLayerInformation[client] = true;
		else if (showLayerInfo == 0) ShowPlayerLayerInformation[client] = false;
		
		AddMenuStructure(client, c_MenuName);
		if (!StrEqual(sCvarRequired, "-1", false) && FindConVar(sCvarRequired) != INVALID_HANDLE) {

			// Calls the fortspawn menu in another plugin.
			ReadyUp_NtvCallModule(sCvarRequired, t_MenuName, client);
		}
		// I've set it to not require case-sensitivity in case some moron decides to get cute.
		else if (!StrEqual(t_MenuName, "-1", false) && iIsIgnoreHeader <= 0) {
			if (StrEqual(t_MenuName, "editactionbar", false)) {
				bEquipSpells[client] = true;

				Format(MenuName_c[client], sizeof(MenuName_c[]), "%s", c_MenuName);
				BuildSubMenu(client, menuname, config, c_MenuName);
			}
			else BuildMenu(client, t_MenuName);
		}
		else if (StrEqual(config, "spawnloadout", false)) {

			SpawnLoadoutEditor(client);
		}
		else if (StrEqual(config, "composition", false)) {

			GetTeamComposition(client);
		}
		else if (StrEqual(config, "autolevel toggle", false)) {

			if (iIsLevelingPaused[client] == 1 && !b_IsActiveRound) iIsLevelingPaused[client] = 0;
			else if (iIsLevelingPaused[client] == 0) iIsLevelingPaused[client] = 1;
			BuildMenu(client);
		}
		else if (StrEqual(config, "trails toggle", false)) {

			if (iIsBulletTrails[client] == 1) iIsBulletTrails[client] = 0;
			else iIsBulletTrails[client] = 1;
			BuildMenu(client);
		}
		else if (StrEqual(config, "level up", false)) {

			if (iIsLevelingPaused[client] == 1 && ExperienceLevel[client] >= XPRequired) ConfirmExperienceAction(client, _, true);
			BuildMenu(client);
		}
		else if (StrEqual(config, "layerup")) {
			if (PlayerCurrentMenuLayer[client] > 1) PlayerCurrentMenuLayer[client]--;
			BuildMenu(client);
		}
		else if (StrEqual(config, "layerdown")) {
			//if (PlayerCurrentMenuLayer[client] < iMaxLayers && GetLayerUpgradeStrength(client, PlayerCurrentMenuLayer[client]) >= PlayerCurrentMenuLayer[client] + 1) PlayerCurrentMenuLayer[client]++;
			if (PlayerCurrentMenuLayer[client] < iMaxLayers) PlayerCurrentMenuLayer[client]++;
			BuildMenu(client);
		}
		else if (StrEqual(config, "prestige", false)) {

			if (ExperienceLevel[client] >= XPRequired && PlayerLevel[client] >= iMaxLevel && SkyLevel[client] < iSkyLevelMax) {

				PlayerLevel[client] = iPlayerStartingLevel;
				SkyLevel[client]++;
				ExperienceLevel[client] = 0;
				GetClientName(client, Name, sizeof(Name));
				PrintToChatAll("%t", "player sky level up", green, white, blue, Name, SkyLevel[client]);
				ChallengeEverything(client);
				SaveAndClear(client);
			}
			BuildMenu(client);
		}
		else if (StrEqual(config, "profileeditor", false)) {

			ProfileEditorMenu(client);
		}
		else if (StrEqual(config, "charactersheet", false)) {
			playerPageOfCharacterSheet[client] = 0;
			CharacterSheetMenu(client);
		}
		else if (StrEqual(config, "readallprofiles", false)) {

			ReadProfiles(client, "all");
		}
		else if (StrEqual(config, "leaderboards", false)) {

			bIsMyRanking[client] = true;
			TheLeaderboardsPage[client] = 0;
			LoadLeaderboards(client, 0);
		} 
		else if (StrEqual(config, "respec", false)) {

			ChallengeEverything(client);
			BuildMenu(client);
		}
		else if (StrEqual(config, "threatmeter", false)) {

			//ShowThreatMenu(client);
			bIsHideThreat[client] = false;
		}
		else if (GetArraySize(a_Store) > 0 && StrEqual(config, CONFIG_STORE)) {

			BuildStoreMenu(client);
		}
		else if (StrEqual(config, CONFIG_CHATSETTINGS)) {

			Format(ChatSettingsName[client], sizeof(ChatSettingsName[]), "none");
			BuildChatSettingsMenu(client);
		}
		else if (StrEqual(config, CONFIG_MENUTALENTS)) {

			// In previous versions of RPG, players could see, but couldn't open specific menus if the director talents were active.
			// In this version, if director talents are active, you just can't see a talent with "activator class required?" that is strictly 0.
			// However, values that are, say, "01" will show, as at least 1 infected class can use the talent.
			Format(MenuName_c[client], sizeof(MenuName_c[]), "%s", c_MenuName);
			
			if (iHasLayers == 1) {
				FormatKeyValue(menuname, sizeof(menuname), MenuKeys[client], MenuValues[client], "talent tree category?");
				Format(menuname, sizeof(menuname), "%s%d", menuname, PlayerCurrentMenuLayer[client]);
			}
			if (!StrEqual(t_MenuName, "-1", false)) BuildSubMenu(client, menuname, config, t_MenuName);
			else BuildSubMenu(client, menuname, config, c_MenuName);
			//PrintToChat(client, "buidling a sub menu. %s", t_MenuName);
		}
		else if (StrEqual(config, CONFIG_POINTS)) {

			// A much safer method for grabbing the current config value for the MenuSelection.
			iIsWeaponLoadout[client] = 0;
			Format(MenuSelection[client], sizeof(MenuSelection[]), "%s", config);
			BuildPointsMenu(client, menuname, config);
		}
		else if (StrEqual(config, "inventory", false)) {

			LoadInventory(client);
		}
		else if (StrEqual(config, "proficiency", false)) {
			LoadProficiencyData(client);
		}
		/*else {

			BuildMenu(client);
		}*/
	}
	else if (action == MenuAction_Cancel) {

		if (slot == MenuCancel_ExitBack) {

			BuildMenu(client);
		}
	}
	if (action == MenuAction_End) {

		CloseHandle(menu);
	}
}

stock PlayerTalentLevel(client) {

	new PTL = RoundToFloor((((PlayerUpgradesTotal[client] * 1.0) + FreeUpgrades[client]) / PlayerLevel[client]) * PlayerLevel[client]);
	if (PTL < 0) PTL = 0;

	return PTL;
	//return PlayerLevel[client];
}

stock Float:PlayerBuffLevel(client) {

	new Float:PBL = ((PlayerUpgradesTotal[client] * 1.0) + FreeUpgrades[client]) / PlayerLevel[client];
	PBL = 1.0 - PBL;
	//PBL = PBL * 100.0;
	if (PBL < 0.0) PBL = 0.0; // This can happen if a player uses free upgrades, so, yeah...
	return PBL;
}

stock MaximumPlayerUpgrades(client, bool:getNodeCountInstead = false) {

	if (!getNodeCountInstead) return PlayerLevel[client];
	return nodesInExistence;
}

stock VerifyMaxPlayerUpgrades(client) {

	if (PlayerUpgradesTotal[client] + FreeUpgrades[client] > MaximumPlayerUpgrades(client)) {
		PrintToChatAll("7");
		FreeUpgrades[client]								=	MaximumPlayerUpgrades(client);
		UpgradesAvailable[client]							=	0;
		PlayerUpgradesTotal[client]							=	0;
		WipeTalentPoints(client);
	}
}

stock String:UpgradesUsed(client) {

	decl String:text[512];
	Format(text, sizeof(text), "%T", "Upgrades Used", client);
	Format(text, sizeof(text), "(%s: %d / %d)", text, PlayerUpgradesTotal[client], MaximumPlayerUpgrades(client));
	return text;
}

stock LoadInventory(client) {

	if (hDatabase == INVALID_HANDLE) return;
	decl String:key[64];
	GetClientAuthString(client, key, sizeof(key));
	Format(key, sizeof(key), "%s%s", key, LOOT_VERSION);
	decl String:tquery[128];
	Format(tquery, sizeof(tquery), "SELECT `owner_id` FROM `%s_loot` WHERE (`owner_id` = '%s');", TheDBPrefix, key);
	ClearArray(Handle:PlayerInventory[client]);
	SQL_TQuery(hDatabase, LoadInventory_Generate, tquery, client);
}

stock LoadProficiencyData(client) {
	new Handle:menu = CreateMenu(LoadProficiencyMenuHandle);
	ClearArray(Handle:RPGMenuPosition[client]);

	decl String:text[64];
	new CurLevel = 0;
	new CurExp = 0;
	new CurGoal = 0;
	for (new i = 0; i <= 7; i++) {
		CurLevel = GetProficiencyData(client, i);
		CurExp = GetProficiencyData(client, i, _, 1);
		CurGoal = GetProficiencyData(client, i, _, 2);
		//new Float:CurPerc = (CurExp * 1.0) / (CurGoal * 1.0);
		if (i == 0) Format(text, sizeof(text), "%T", "pistol proficiency", client);
		else if (i == 1) Format(text, sizeof(text), "%T", "melee proficiency", client);
		else if (i == 2) Format(text, sizeof(text), "%T", "uzi proficiency", client);
		else if (i == 3) Format(text, sizeof(text), "%T", "shotgun proficiency", client);
		else if (i == 4) Format(text, sizeof(text), "%T", "sniper proficiency", client);
		else if (i == 5) Format(text, sizeof(text), "%T", "assault proficiency", client);
		else if (i == 6) Format(text, sizeof(text), "%T", "medic proficiency", client);
		else if (i == 7) Format(text, sizeof(text), "%T", "grenade proficiency", client);

		Format(text, sizeof(text), "%s Lv.%d %s %s %sXP", text, CurLevel, AddCommasToString(CurExp), MenuExperienceBar(client, CurExp, CurGoal), AddCommasToString(CurGoal));
		AddMenuItem(menu, text, text, ITEMDRAW_DISABLED);
	}
	SetMenuExitBackButton(menu, true);
	DisplayMenu(menu, client, 0);
}

public LoadProficiencyMenuHandle(Handle:menu, MenuAction:action, client, slot) {

	if (action == MenuAction_Select) { }
	else if (action == MenuAction_Cancel) {
		if (slot == MenuCancel_ExitBack) BuildMenu(client);
	}
	if (action == MenuAction_End) CloseHandle(menu);
}

stock LoadInventoryEx(client) {

	new Handle:menu = CreateMenu(LoadInventoryMenuHandle);
	ClearArray(Handle:RPGMenuPosition[client]);

	decl String:text[64];
	decl String:pos[10];
	decl String:result[3][64];

	Format(text, sizeof(text), "%T", "Inventory", client);
	SetMenuTitle(menu, text);

	new size = GetArraySize(PlayerInventory[client]);
	if (size < 1) {

		Format(text, sizeof(text), "%T", "inventory empty", client);
		AddMenuItem(menu, text, text);
	}
	else {

		for (new i = 0; i < size; i++) {

			GetArrayString(Handle:PlayerInventory[client], i, text, sizeof(text));
			ExplodeString(text, "+", result, 3, 64);
			AddMenuItem(menu, result[1], result[1]);

			Format(pos, sizeof(pos), "%d", i);
			PushArrayString(Handle:RPGMenuPosition[client], pos);
		}
	}
	SetMenuExitBackButton(menu, true);
	DisplayMenu(menu, client, 0);
}

public LoadInventoryMenuHandle(Handle:menu, MenuAction:action, client, slot) {

	if (action == MenuAction_Select) {

	}
	else if (action == MenuAction_Cancel) {

		if (slot == MenuCancel_ExitBack) {

			BuildMenu(client);
		}
	}
	if (action == MenuAction_End) {

		CloseHandle(menu);
	}
}

public Handle:DisplayTheLeaderboards(client) {

	new Handle:menu = CreatePanel();

	decl String:tquery[64];
	decl String:text[512];
	decl String:testelim[4];
	Format(testelim, sizeof(testelim), " ");

	if (TheLeaderboardsPageSize[client] > 0) {

		Format(text, sizeof(text), "Name\t(Level)\t(Rating)");
		DrawPanelText(menu, text);

		for (new i = 0; i < TheLeaderboardsPageSize[client]; i++) {

			TheLeaderboardsData[client]		= GetArrayCell(TheLeaderboards[client], 0, 0);
			GetArrayString(Handle:TheLeaderboardsData[client], i, tquery, sizeof(tquery));
			Format(text, sizeof(text), "%s", tquery);

			TheLeaderboardsData[client]		= GetArrayCell(TheLeaderboards[client], 0, 1);
			GetArrayString(Handle:TheLeaderboardsData[client], i, tquery, sizeof(tquery));

			Format(text, sizeof(text), "%s\t(%s)", text, AddCommasToString(StringToInt(tquery)));

			TheLeaderboardsData[client]		= GetArrayCell(TheLeaderboards[client], 0, 3);
			GetArrayString(Handle:TheLeaderboardsData[client], i, tquery, sizeof(tquery));
			Format(text, sizeof(text), "%s\t(%s)", text, AddCommasToString(StringToInt(tquery)));

			DrawPanelText(menu, text);

			if (bIsMyRanking[client]) break;
		}
	}
	Format(text, sizeof(text), "%T", "Leaderboards Top Page", client);
	DrawPanelItem(menu, text);
	if (TheLeaderboardsPageSize[client] >= GetConfigValueInt("leaderboard players per page?")) {

		Format(text, sizeof(text), "%T", "Leaderboards Next Page", client);
		DrawPanelItem(menu, text);
	}
	Format(text, sizeof(text), "%T", "View My Ranking", client);
	DrawPanelItem(menu, text);
	Format(text, sizeof(text), "%T", "return to talent menu", client);
	DrawPanelItem(menu, text);

	return menu;
}

public DisplayTheLeaderboards_Init (Handle:topmenu, MenuAction:action, client, param2)
{
	if (action == MenuAction_Select)
	{
		switch (param2)
		{
			case 1:
			{
				bIsMyRanking[client] = false;
				LoadLeaderboards(client, 0);
			}
			case 2:
			{
				if (TheLeaderboardsPageSize[client] >= GetConfigValueInt("leaderboard players per page?")) {

					bIsMyRanking[client] = false;
					LoadLeaderboards(client, 1);
				}
				else {

					bIsMyRanking[client] = true;
					LoadLeaderboards(client, 0);
				}
			}
			case 3:
			{
				if (TheLeaderboardsPageSize[client] >= GetConfigValueInt("leaderboard players per page?")) {

					bIsMyRanking[client] = true;
					LoadLeaderboards(client, 0);
				}
				else {

					ClearArray(TheLeaderboards[client]);
					TheLeaderboardsPage[client] = 0;
					BuildMenu(client);
				}
			}
			case 4:
			{
				if (TheLeaderboardsPageSize[client] >= GetConfigValueInt("leaderboard players per page?")) {

					ClearArray(TheLeaderboards[client]);
					TheLeaderboardsPage[client] = 0;
					BuildMenu(client);
				}
			}
		}
	}
	if (topmenu != INVALID_HANDLE)
	{
		CloseHandle(topmenu);
	}
}

public Handle:SpawnLoadoutEditor(client) {

	new Handle:menu		= CreateMenu(SpawnLoadoutEditorHandle);

	decl String:text[512];
	Format(text, sizeof(text), "%T", "profile editor title", client, LoadoutName[client]);
	SetMenuTitle(menu, text);

	GetArrayString(Handle:hWeaponList[client], 0, text, sizeof(text));
	if (!QuickCommandAccessEx(client, text, _, _, true)) Format(text, sizeof(text), "%T", "No Weapon Equipped", client);
	else Format(text, sizeof(text), "%T", text, client);
	Format(text, sizeof(text), "%T", "Primary Weapon", client, text);
	AddMenuItem(menu, text, text);

	GetArrayString(Handle:hWeaponList[client], 1, text, sizeof(text));
	if (!QuickCommandAccessEx(client, text, _, _, true)) Format(text, sizeof(text), "%T", "No Weapon Equipped", client);
	else Format(text, sizeof(text), "%T", text, client);
	Format(text, sizeof(text), "%T", "Secondary Weapon", client, text);
	AddMenuItem(menu, text, text);

	SetMenuExitBackButton(menu, true);
	DisplayMenu(menu, client, 0);
}

public SpawnLoadoutEditorHandle(Handle:menu, MenuAction:action, client, slot) {

	if (action == MenuAction_Select) {

		decl String:menuname[64];
		GetProfileLoadoutConfig(client, menuname, sizeof(menuname));

		Format(MenuSelection[client], sizeof(MenuSelection[]), "%s", sProfileLoadoutConfig);

		iIsWeaponLoadout[client] = slot + 1;	// 1 - 1 = 0 Primary, 2 - 1 = 1 Secondary
		BuildPointsMenu(client, menuname, "rpg/points.cfg");
	}
	else if (action == MenuAction_Cancel) {

		if (slot == MenuCancel_ExitBack) {

			iIsWeaponLoadout[client] = 0;
			BuildMenu(client, "main");
		}
	}
	if (action == MenuAction_End) {

		CloseHandle(menu);
	}
}

stock GetTotalThreat() {

	new iThreatAmount = 0;
	for (new i = 1; i <= MaxClients; i++) {

		if (IsLegitimateClientAlive(i) && GetClientTeam(i) == TEAM_SURVIVOR) {

			iThreatAmount += iThreatLevel[i];
		}
	}
	return iThreatAmount;
}

/*stock GetThreatPos(client) {

	decl String:text[64];
	decl String:iThreatInfo[2][64];

	new size = GetArraySize(Handle:hThreatMeter);
	if (size > 0) {

		for (new i = 0; i < size; i++) {

			GetArrayString(Handle:hThreatMeter, i, text, sizeof(text));
			ExplodeString(text, "+", iThreatInfo, 2, 64);
			//client+threat
			
			if (client == StringToInt(iThreatInfo[0])) return i;
		}
	}
	return -1;
}*/

public Handle:ShowThreatMenu(client) {

	new Handle:menu = CreatePanel();

	decl String:text[512];
	decl String:iThreatInfo[2][64];
	//GetArrayString(Handle:hThreatMeter, 0, text, sizeof(text));
	new iTotalThreat = GetTotalThreat();
	new iThreatTarget = -1;
	new Float:iThreatPercent = 0.0;

	decl String:tBar[64];
	new iBar = 0;

	decl String:tClient[64];

	Format(text, sizeof(text), "%T", "threat meter title", client);
	//new pos = GetThreatPos(client);
	if (iThreatLevel[client] > 0) {

		//GetArrayString(Handle:hThreatMeter, pos, text, sizeof(text));
		//ExplodeString(text, "+", iThreatInfo, 2, 64);
		//iThreatTarget = StringToInt(text[FindDelim(text, "+")]);
		//if (iThreatTarget > 0) {

		iThreatPercent = ((1.0 * iThreatLevel[client]) / (1.0 * iTotalThreat));
		iBar = RoundToFloor(iThreatPercent / 0.05);
		if (iBar > 0) {

			for (new ii = 0; ii < iBar; ii++) {

				if (ii == 0) Format(tBar, sizeof(tBar), "~");
				else Format(tBar, sizeof(tBar), "%s~", tBar);
			}
			Format(tBar, sizeof(tBar), "%s>", tBar);
		}
		else Format(tBar, sizeof(tBar), ">");
		GetClientName(client, tClient, sizeof(tClient));
		Format(tBar, sizeof(tBar), "%s%s %s", tBar, AddCommasToString(iThreatLevel[client]), tClient);
		Format(text, sizeof(text), "%s\nYou:\n%s\n\t\nTeam:", text, tBar);
		//}
	}
	SetPanelTitle(menu, text);

	new size = GetArraySize(hThreatMeter);
	new iClient = 0;
	if (size > 0) {

		for (new i = 0; i < size; i++) {
		
			GetArrayString(Handle:hThreatMeter, i, text, sizeof(text));
			ExplodeString(text, "+", iThreatInfo, 2, 64);
			//client+threat
			iClient = StringToInt(iThreatInfo[0]);
			if (client == iClient) continue;			// the menu owner data is shown in the title so not here.
			GetClientName(iClient, text, sizeof(text));
			iThreatTarget = StringToInt(iThreatInfo[1]);

			if (!IsLegitimateClientAlive(iClient) || iThreatTarget < 1) continue;	// we don't show players who have no threat on the table.

			iThreatPercent = ((1.0 * iThreatTarget) / (1.0 * iTotalThreat));
			iBar = RoundToFloor(iThreatPercent / 0.05);
			if (iBar > 0) {

				for (new ii = 0; ii < iBar; ii++) {

					if (ii == 0) Format(tBar, sizeof(tBar), "~");
					else Format(tBar, sizeof(tBar), "%s~", tBar);
				}
				Format(tBar, sizeof(tBar), "%s>", tBar);
			}
			else Format(tBar, sizeof(tBar), ">");
			Format(tBar, sizeof(tBar), "%s%s %s", tBar, AddCommasToString(iThreatTarget), text);
			DrawPanelText(menu, tBar);
		}
	}
	Format(text, sizeof(text), "%T", "return to talent menu", client);
	DrawPanelItem(menu, text);
	return menu;
}

public ShowThreatMenu_Init (Handle:topmenu, MenuAction:action, client, param2)
{
	if (action == MenuAction_Select)
	{
		switch (param2)
		{
			case 1:
			{
				//bIsMyRanking[client] = false;
				//LoadLeaderboards(client, 0);
				bIsHideThreat[client] = true;
				BuildMenu(client);
			}
		}
	}
	/*if (action == MenuAction_Cancel) {

		//if (action == MenuCancel_ExitBack) {

		bIsHideThreat[client] = true;
		BuildMenu(client);
		//}
	}
	if (action == MenuAction_End) {

		bIsHideThreat[client] = true;
		CloseHandle(topmenu);
	}
	if (topmenu != INVALID_HANDLE)
	{
		//bIsHideThreat[client] = true;
		CloseHandle(topmenu);
	}*/
}

public CharacterSheetMenuHandle(Handle:menu, MenuAction:action, client, slot) {

	if (action == MenuAction_Select) {
		if (slot == 0) {
			playerPageOfCharacterSheet[client] = (playerPageOfCharacterSheet[client] == 0) ? 1 : 0;
			CharacterSheetMenu(client);
		}
	}
	if (action == MenuAction_Cancel) {

		if (slot == MenuCancel_ExitBack) {

			BuildMenu(client);
		}
	}
	if (action == MenuAction_End) {

		CloseHandle(menu);
	}
}

public Handle:CharacterSheetMenu(client) {
	new Handle:menu		= CreateMenu(CharacterSheetMenuHandle);

	decl String:text[512];
	// we create a string called data to use as reference in GetCharacterSheetData()
	// as opposed to using a String method that has to create a new string each time.
	decl String:data[64];
	// parse the menu according to how the server operator has designed it.
	
	if (playerPageOfCharacterSheet[client] == 0) {
		Format(text, sizeof(text), "%T", "Infected Sheet Info", client);

		if (StrContains(text, "{CH}", true) != -1) {
			GetCharacterSheetData(client, data, sizeof(data), 1);
			ReplaceString(text, sizeof(text), "{CH}", data);
		}
		if (StrContains(text, "{CD}", true) != -1) {
			GetCharacterSheetData(client, data, sizeof(data), 2);
			ReplaceString(text, sizeof(text), "{CD}", data);
		}
		if (StrContains(text, "{WH}", true) != -1) {
			GetCharacterSheetData(client, data, sizeof(data), 3);
			ReplaceString(text, sizeof(text), "{WH}", data);
		}
		if (StrContains(text, "{WD}", true) != -1) {
			GetCharacterSheetData(client, data, sizeof(data), 4);
			ReplaceString(text, sizeof(text), "{WD}", data);
		}
		if (StrContains(text, "{HUNTERHP}", true) != -1) {
			GetCharacterSheetData(client, data, sizeof(data), 5, ZOMBIECLASS_HUNTER);
			ReplaceString(text, sizeof(text), "{HUNTERHP}", data);
		}
		if (StrContains(text, "{SMOKERHP}", true) != -1) {
			GetCharacterSheetData(client, data, sizeof(data), 5, ZOMBIECLASS_SMOKER);
			ReplaceString(text, sizeof(text), "{SMOKERHP}", data);
		}
		if (StrContains(text, "{BOOMERHP}", true) != -1) {
			GetCharacterSheetData(client, data, sizeof(data), 5, ZOMBIECLASS_BOOMER);
			ReplaceString(text, sizeof(text), "{BOOMERHP}", data);
		}
		if (StrContains(text, "{SPITTERHP}", true) != -1) {
			GetCharacterSheetData(client, data, sizeof(data), 5, ZOMBIECLASS_SPITTER);
			ReplaceString(text, sizeof(text), "{SPITTERHP}", data);
		}
		if (StrContains(text, "{JOCKEYHP}", true) != -1) {
			GetCharacterSheetData(client, data, sizeof(data), 5, ZOMBIECLASS_JOCKEY);
			ReplaceString(text, sizeof(text), "{JOCKEYHP}", data);
		}
		if (StrContains(text, "{CHARGERHP}", true) != -1) {
			GetCharacterSheetData(client, data, sizeof(data), 5, ZOMBIECLASS_CHARGER);
			ReplaceString(text, sizeof(text), "{CHARGERHP}", data);
		}
		if (StrContains(text, "{TANKHP}", true) != -1) {
			GetCharacterSheetData(client, data, sizeof(data), 5, ZOMBIECLASS_TANK);
			ReplaceString(text, sizeof(text), "{TANKHP}", data);
		}
		if (StrContains(text, "{HUNTERDMG}", true) != -1) {
			GetCharacterSheetData(client, data, sizeof(data), 6, ZOMBIECLASS_HUNTER);
			ReplaceString(text, sizeof(text), "{HUNTERDMG}", data);
		}
		if (StrContains(text, "{SMOKERDMG}", true) != -1) {
			GetCharacterSheetData(client, data, sizeof(data), 6, ZOMBIECLASS_SMOKER);
			ReplaceString(text, sizeof(text), "{SMOKERDMG}", data);
		}
		if (StrContains(text, "{BOOMERDMG}", true) != -1) {
			GetCharacterSheetData(client, data, sizeof(data), 6, ZOMBIECLASS_BOOMER);
			ReplaceString(text, sizeof(text), "{BOOMERDMG}", data);
		}
		if (StrContains(text, "{SPITTERDMG}", true) != -1) {
			GetCharacterSheetData(client, data, sizeof(data), 6, ZOMBIECLASS_SPITTER);
			ReplaceString(text, sizeof(text), "{SPITTERDMG}", data);
		}
		if (StrContains(text, "{JOCKEYDMG}", true) != -1) {
			GetCharacterSheetData(client, data, sizeof(data), 6, ZOMBIECLASS_JOCKEY);
			ReplaceString(text, sizeof(text), "{JOCKEYDMG}", data);
		}
		if (StrContains(text, "{CHARGERDMG}", true) != -1) {
			GetCharacterSheetData(client, data, sizeof(data), 6, ZOMBIECLASS_CHARGER);
			ReplaceString(text, sizeof(text), "{CHARGERDMG}", data);
		}
		if (StrContains(text, "{TANKDMG}", true) != -1) {
			GetCharacterSheetData(client, data, sizeof(data), 6, ZOMBIECLASS_TANK);
			ReplaceString(text, sizeof(text), "{TANKDMG}", data);
		}
	}
	else { // Survivor Sheet!
		decl String:targetName[64];
		//new typeOfAimTarget = DataScreenTargetName(client, targetName, sizeof(targetName));
		decl String:weaponDamage[64];
		Format(weaponDamage, sizeof(weaponDamage), "%s", AddCommasToString(DataScreenWeaponDamage(client)));

		Format(text, sizeof(text), "%T", "Survivor Sheet Info", client);
		if (StrContains(text, "{AIMTARGET}", true) != -1) {
			ReplaceString(text, sizeof(text), "{AIMTARGET}", targetName);
		}
		if (StrContains(text, "{WDMG}", true) != -1) {
			ReplaceString(text, sizeof(text), "{WDMG}", weaponDamage);
		}
		if (StrContains(text, "{MYSTAM}", true) != -1) {
			Format(weaponDamage, sizeof(weaponDamage), "%d", GetPlayerStamina(client));
			ReplaceString(text, sizeof(text), "{MYSTAM}", weaponDamage);
		}
		if (StrContains(text, "{MYHP}", true) != -1) {
			SetMaximumHealth(client);
			Format(weaponDamage, sizeof(weaponDamage), "%d", GetMaximumHealth(client));
			ReplaceString(text, sizeof(text), "{MYHP}", weaponDamage);
		}
		if (StrContains(text, "{CON}", true) != -1) {
			Format(weaponDamage, sizeof(weaponDamage), "%d", GetTalentStrength(client, "constitution", _, _, true));
			ReplaceString(text, sizeof(text), "{CON}", weaponDamage);
		}
		if (StrContains(text, "{AGI}", true) != -1) {
			Format(weaponDamage, sizeof(weaponDamage), "%d", GetTalentStrength(client, "agility", _, _, true));
			ReplaceString(text, sizeof(text), "{AGI}", weaponDamage);
		}
		if (StrContains(text, "{RES}", true) != -1) {
			Format(weaponDamage, sizeof(weaponDamage), "%d", GetTalentStrength(client, "resilience", _, _, true));
			ReplaceString(text, sizeof(text), "{RES}", weaponDamage);
		}
		if (StrContains(text, "{TEC}", true) != -1) {
			Format(weaponDamage, sizeof(weaponDamage), "%d", GetTalentStrength(client, "technique", _, _, true));
			ReplaceString(text, sizeof(text), "{TEC}", weaponDamage);
		}
		if (StrContains(text, "{END}", true) != -1) {
			Format(weaponDamage, sizeof(weaponDamage), "%d", GetTalentStrength(client, "endurance", _, _, true));
			ReplaceString(text, sizeof(text), "{END}", weaponDamage);
		}
		if (StrContains(text, "{LUC}", true) != -1) {
			Format(weaponDamage, sizeof(weaponDamage), "%d", GetTalentStrength(client, "luck", _, _, true));
			ReplaceString(text, sizeof(text), "{LUC}", weaponDamage);
		}
	}

	SetMenuTitle(menu, text);
	if (playerPageOfCharacterSheet[client] == 0) Format(text, sizeof(text), "%T", "Character Sheet (Survivor Page)", client);
	else Format(text, sizeof(text), "%T", "Character Sheet (Infected Page)", client);
	AddMenuItem(menu, text, text);


	SetMenuExitBackButton(menu, true);
	DisplayMenu(menu, client, 0);
}

stock bool:IsWeaponPermittedFound(client, String:WeaponsPermitted[], String:PlayerWeapon[]) {
	new bool:IsFound = false;
	if (StrContains(WeaponsPermitted, "{ALLSMG}", true) != -1 && StrContains(PlayerWeapon, "smg", false) != -1 ||
		StrContains(WeaponsPermitted, "{ALLSHOTGUN}", true) != -1 && StrContains(PlayerWeapon, "shotgun", false) != -1 ||
		StrContains(WeaponsPermitted, "{PUMP}", true) != -1 && (StrContains(PlayerWeapon, "pump", false) != -1 || StrContains(PlayerWeapon, "chrome", false) != -1) ||
		StrContains(WeaponsPermitted, "{ALLRIFLE}", true) != -1 && StrContains(PlayerWeapon, "rifle", false) && StrContains(PlayerWeapon, "hunting", false) == -1 ||
		StrContains(WeaponsPermitted, "{ALLSNIPER}", true) != -1 && StrContains(PlayerWeapon, "sniper", false) != -1 ||
		StrContains(WeaponsPermitted, "{ALLPISTOL}", true) != -1 && StrContains(PlayerWeapon, "pistol", false) != -1 ||
		StrContains(WeaponsPermitted, "{MAGNUM}", true) != -1 && StrContains(PlayerWeapon, "magnum", false) != -1 ||
		StrContains(WeaponsPermitted, "{PISTOL}", true) != -1 && (StrContains(PlayerWeapon, "pistol", false) != -1 && StrContains(PlayerWeapon, "magnum", false) == -1) ||
		StrContains(WeaponsPermitted, "{MELEE}", true) != -1 && IsMeleeAttacker(client) ||
		StrContains(WeaponsPermitted, "{TIER1}", true) != -1 &&
			(StrContains(PlayerWeapon, "smg", false) != -1 || StrContains(PlayerWeapon, "chrome", false) != -1 ||
			StrContains(PlayerWeapon, "pump", false) != -1 ||
			(StrContains(PlayerWeapon, "pistol", false) != -1 && StrContains(PlayerWeapon, "magnum", false) == -1)) ||
		StrContains(WeaponsPermitted, "{TIER2}", true) != -1 &&
			(StrContains(PlayerWeapon, "spas", false) != -1 || StrContains(PlayerWeapon, "autoshotgun", false) != -1 ||
			StrContains(PlayerWeapon, "sniper", false) != -1 ||
			(StrContains(PlayerWeapon, "rifle", false) != -1 && StrContains(PlayerWeapon, "huntingrifle", false) == -1)) ||
		StrContains(WeaponsPermitted, PlayerWeapon, false) != -1) IsFound = true;
	return IsFound;
}

stock GetCharacterSheetData(client, String:stringRef[], theSize, request, zombieclass = 0, bool:isRecalled = false) {
	//new Float:fResult;
	new iResult = (iBotLevelType == 1) ? SurvivorLevels() : GetDifficultyRating(client);
	new Float:fMultiplier;
	new Float:AbilityMultiplier = (request % 2 == 0) ? GetAbilityMultiplier(client, "X", 4) : 0.0;
	// common infected health
	if (request == 1) {	// odd requests return integers
						// equal requests return floats
		fMultiplier = (iBotLevelType == 1) ? fCommonRaidHealthMult : fCommonLevelHealthMult;
		iResult = iCommonBaseHealth + RoundToCeil(iCommonBaseHealth * (iResult * fMultiplier));
	}
	// common infected damage
	if (request == 2) {
		fMultiplier = fCommonDamageLevel;
		iResult = iCommonInfectedBaseDamage + RoundToCeil(iCommonInfectedBaseDamage * (fMultiplier * iResult));
	}
	// witch health
	if (request == 3) {
		fMultiplier = fWitchHealthMult;
		iResult = iWitchHealthBase + RoundToCeil(iWitchHealthBase * (iResult * fWitchHealthMult));
	}
	// witch infected damage
	if (request == 4) {
		fMultiplier = fWitchDamageScaleLevel;
		iResult = iWitchDamageInitial + RoundToCeil(fMultiplier * iResult);
	}
	// only if a zombieclass has been specified.
	if (zombieclass != 0) {
		if (zombieclass != ZOMBIECLASS_TANK) zombieclass--;
		else zombieclass -= 2;
	}
	// special infected health
	if (request == 5) {
		fMultiplier = fHealthPlayerLevel[zombieclass];
		iResult = iBaseSpecialInfectedHealth[zombieclass] + RoundToCeil(iBaseSpecialInfectedHealth[zombieclass] * (iResult * fMultiplier));
	}
	// special infected damage
	if (request == 6) {
		fMultiplier = fDamagePlayerLevel[zombieclass];
		iResult = iBaseSpecialDamage[zombieclass] + RoundToFloor(iBaseSpecialDamage[zombieclass] * (iResult * fMultiplier));
	}// even requests are for damage. result 7 returns damage shield values. result 8(which is even so no check required) returns damage reduction ability strength.
	if (zombieclass != 0 && (request % 2 == 0 || request == 7)) {
		new DamageShield = 0;
		new Float:DamageShieldMult = (IsClientInRangeSpecialAmmo(client, "D") == -2.0) ? IsClientInRangeSpecialAmmo(client, "D", false, _, iResult * 1.0) : 0.0;

		if (DamageShieldMult > 0.0) DamageShield = RoundToCeil(iResult * DamageShieldMult);
		if (request == 7) {	// Damage Shield percentage reduction in the string and the raw value reduced in the return value.
			if (DamageShield > 0) Format(stringRef, theSize, "%3.3f", DamageShieldMult * 100.0);
			return DamageShield;
		}
		iResult -= DamageShield;
		if (request == 8) {
			if (AbilityMultiplier > 0.0) {
				Format(stringRef, theSize, "%3.3f", AbilityMultiplier * 100.0);
				return RoundToCeil(iResult * AbilityMultiplier);
			}
			return 0;
		}
		iResult -= RoundToCeil(iResult * AbilityMultiplier);
	}


	//if (request % 2 == 0) Format(stringRef, theSize, "%3.3f", fResult);
	//else Format(stringRef, theSize, "%d", iResult);
	Format(stringRef, theSize, "%s", AddCommasToString(iResult));
	return 0;
}

public Handle:ProfileEditorMenu(client) {

	new Handle:menu		= CreateMenu(ProfileEditorMenuHandle);

	decl String:text[512];
	Format(text, sizeof(text), "%T", "profile editor title", client, LoadoutName[client]);
	SetMenuTitle(menu, text);

	Format(text, sizeof(text), "%T", "Save Profile", client);
	AddMenuItem(menu, text, text);
	Format(text, sizeof(text), "%T", "Load Profile", client);
	AddMenuItem(menu, text, text);
	Format(text, sizeof(text), "%T", "Load All", client);
	AddMenuItem(menu, text, text);

	decl String:TheName[64];
	new thetarget = LoadProfileRequestName[client];
	if (thetarget == -1 || thetarget == client || !IsLegitimateClient(thetarget) || GetClientTeam(thetarget) != TEAM_SURVIVOR) thetarget = LoadTarget[client];
	if (IsSurvivorBot(thetarget) ||
		IsLegitimateClient(thetarget) && GetClientTeam(thetarget) != TEAM_INFECTED && thetarget != client) {

		//decl String:theclassname[64];
		GetClientName(thetarget, TheName, sizeof(TheName));
		Format(TheName, sizeof(TheName), "[Rtg %d] Lv.%d %s", Rating[thetarget], PlayerLevel[thetarget], TheName);
	}
	else {

		LoadTarget[client] = -1;
		Format(TheName, sizeof(TheName), "%T", "Yourself", client);
	}
	Format(text, sizeof(text), "%T", "Select Load Target", client, TheName);
	AddMenuItem(menu, text, text);
	Format(text, sizeof(text), "%T", "Delete Profile", client);
	AddMenuItem(menu, text, text);

	new Requester = CheckRequestStatus(client);
	if (Requester != -1) {

		if (!IsLegitimateClient(LoadProfileRequestName[client])) LoadProfileRequestName[client] = -1;
		else {

			GetClientName(LoadProfileRequestName[client], TheName, sizeof(TheName));
			Format(text, sizeof(text), "%T", "Cancel Load Request", client, TheName);
			AddMenuItem(menu, text, text);
		}
	}

	SetMenuExitBackButton(menu, true);
	DisplayMenu(menu, client, 0);
}

stock CheckRequestStatus(client, bool:CancelRequest = false) {

	decl String:TargetName[64];

	for (new i = 1; i <= MaxClients; i++) {

		if (IsLegitimateClient(i) && !IsFakeClient(i) && i != client && LoadProfileRequestName[i] == client) {

			if (!CancelRequest) return i;
			LoadProfileRequestName[i] = -1;
			GetClientName(client, TargetName, sizeof(TargetName));
			PrintToChat(i, "%T", "user has withdrawn request", i, green, TargetName, orange);
			GetClientName(i, TargetName, sizeof(TargetName));
			PrintToChat(client, "%T", "withdrawn request to user", client, orange, green, TargetName);

			return -1;
		}
	}
	return -1;
}

stock DeleteProfile(client, bool:DisplayToClient = true) {

	if (strlen(LoadoutName[client]) < 4) return;

	decl String:tquery[512];
	decl String:t_Loadout[64];
	decl String:pct[4];
	Format(pct, sizeof(pct), "%");
	GetClientAuthString(client, t_Loadout, sizeof(t_Loadout));
	Format(t_Loadout, sizeof(t_Loadout), "%s+%s", t_Loadout, LoadoutName[client]);
	Format(tquery, sizeof(tquery), "DELETE FROM `%s` WHERE `steam_id` LIKE '%s%s' AND `steam_id` LIKE '%sSavedProfile%s';", TheDBPrefix, t_Loadout, pct, pct, pct);
	//PrintToChat(client, tquery);
	LogMessage(tquery);
	SQL_TQuery(hDatabase, QueryResults, tquery, client);
	if (DisplayToClient) {

		PrintToChat(client, "%T", "loadout deleted", client, orange, green, LoadoutName[client]);
		Format(LoadoutName[client], sizeof(LoadoutName[]), "none");
	}
}

public ProfileEditorMenuHandle(Handle:menu, MenuAction:action, client, slot) {

	if (action == MenuAction_Select) {

		if (slot == 0) {

			DeleteProfile(client, false);
			SaveProfile(client);
			ProfileEditorMenu(client);
		}
		if (slot == 1) {

			ReadProfiles(client);
		}
		if (slot == 2) {

			ReadProfiles(client, "all");
		}
		if (slot == 3) {

			//ReadProfiles(client, "all");
			LoadProfileTargetSurvivorBot(client);
		}
		if (slot == 4) {

			DeleteProfile(client);
			ReadProfiles(client);
		}
		if (slot == 5) {

			new Requester = CheckRequestStatus(client);

			if (Requester != -1) {

				CheckRequestStatus(client, true);
				ProfileEditorMenu(client);
			}
		}
	}
	else if (action == MenuAction_Cancel) {

		if (slot == MenuCancel_ExitBack) {

			BuildMenu(client);
		}
	}
	if (action == MenuAction_End) {

		CloseHandle(menu);
	}
}

stock SaveProfile(client, SaveType = 0) {	// 1 insert a new save, 2 overwrite an existing save.

	if (strlen(LoadoutName[client]) < 8) {

		PrintToChat(client, "use !loadoutname to name your loadout. Must be >= 8 chars");
		return;
	}

	decl String:tquery[512];
	decl String:key[128];
	decl String:pct[4];
	Format(pct, sizeof(pct), "%");

	GetClientAuthString(client, key, sizeof(key));
	Format(key, sizeof(key), "%s+", key);
	if (SaveType != 0) {

		if (SaveType == 1) PrintToChat(client, "%T", "new save", client, orange, green, LoadoutName[client]);
		else PrintToChat(client, "%T", "update save", client, orange, green, LoadoutName[client]);

		if (StrContains(LoadoutName[client], "Lv.", false) == -1) Format(key, sizeof(key), "%s%s Lv.%d+SavedProfile%s", key, LoadoutName[client], PlayerLevel[client] - UpgradesAvailable[client] - FreeUpgrades[client], PROFILE_VERSION);
		else Format(key, sizeof(key), "%s%s+SavedProfile%s", key, LoadoutName[client], PROFILE_VERSION);
		SaveProfileEx(client, key, SaveType);
	}
	else {

		Format(tquery, sizeof(tquery), "SELECT COUNT(*) FROM `%s` WHERE `steam_id` LIKE '%s%s';", TheDBPrefix, key, pct);
		SQL_TQuery(hDatabase, Query_CheckIfProfileLimit, tquery, client);
	}
}

stock SaveProfileEx(client, String:key[], SaveType) {

	decl String:tquery[512];
	decl String:text[512];
	decl String:ActionBarText[64];

	decl String:sPrimary[64];
	decl String:sSecondary[64];
	GetArrayString(Handle:hWeaponList[client], 0, sPrimary, sizeof(sPrimary));
	GetArrayString(Handle:hWeaponList[client], 1, sSecondary, sizeof(sSecondary));

	new talentlevel = 0;
	new size = GetArraySize(a_Database_Talents);
	new isDisab = 0;
	if (DisplayActionBar[client]) isDisab = 1;
	if (SaveType == 1) {

		//	A save doesn't exist for this steamid so we create one before saving anything.
		Format(tquery, sizeof(tquery), "INSERT INTO `%s` (`steam_id`) VALUES ('%s');", TheDBPrefix, key);
		//PrintToChat(client, tquery);
		SQL_TQuery(hDatabase, QueryResults, tquery, client);
	}

	// if the database isn't connected, we don't try to save data, because that'll just throw errors.
	// If the player didn't participate, or if they are currently saving data, we don't save as well.
	// It's possible (but not likely) for a player to try to save data while saving, due to their ability to call the function at any time through commands.
	if (hDatabase == INVALID_HANDLE) {

		LogMessage("Database couldn't be found, cannot save for %N", client);
		return;
	}

	//if (PlayerLevel[client] < 1) return;		// Clearly, their data hasn't loaded, so we don't save.
	Format(tquery, sizeof(tquery), "UPDATE `%s` SET `total upgrades` = '%d' WHERE `steam_id` = '%s';", TheDBPrefix, PlayerLevel[client] - UpgradesAvailable[client] - FreeUpgrades[client], key);
	//PrintToChat(client, tquery);
	//LogMessage(tquery);
	SQL_TQuery(hDatabase, QueryResults, tquery, client);

	Format(tquery, sizeof(tquery), "UPDATE `%s` SET `primarywep` = '%s', `secondwep` = '%s' WHERE `steam_id` = '%s';", TheDBPrefix, sPrimary, sSecondary, key);
	SQL_TQuery(hDatabase, QueryResults, tquery, client);

	for (new i = 0; i < size; i++) {

		GetArrayString(a_Database_Talents, i, text, sizeof(text));
		TalentTreeKeys[client]			= GetArrayCell(a_Menu_Talents, i, 0);
		TalentTreeValues[client]		= GetArrayCell(a_Menu_Talents, i, 1);

		if (GetKeyValueInt(TalentTreeKeys[client], TalentTreeValues[client], "talent type?") == 1) continue;	// we don't save class attributes.
		if (GetKeyValueInt(TalentTreeKeys[client], TalentTreeValues[client], "is survivor class role?") == 1) continue;
		if (GetKeyValueInt(TalentTreeKeys[client], TalentTreeValues[client], "is sub menu?") == 1) continue;
		//if (GetKeyValueInt(TalentTreeKeys[client], TalentTreeValues[client], "is ability?") == 1) continue;
		if (GetKeyValueInt(TalentTreeKeys[client], TalentTreeValues[client], "is item?") == 1) continue;

		talentlevel = GetArrayCell(a_Database_PlayerTalents[client], i);// GetArrayString(a_Database_PlayerTalents[client], i, text2, sizeof(text2));
		Format(tquery, sizeof(tquery), "UPDATE `%s` SET `%s` = '%d' WHERE `steam_id` = '%s';", TheDBPrefix, text, talentlevel, key);
		SQL_TQuery(hDatabase, QueryResults, tquery, client);
	}

	for (new i = 0; i < iActionBarSlots; i++) {	// isnt looping?

		GetArrayString(Handle:ActionBar[client], i, ActionBarText, sizeof(ActionBarText));
		//if (StrEqual(ActionBarText, "none")) continue;
		if (!IsAbilityTalent(client, ActionBarText) && (!IsTalentExists(ActionBarText) || GetTalentStrength(client, ActionBarText) < 1)) Format(ActionBarText, sizeof(ActionBarText), "none");
		Format(tquery, sizeof(tquery), "UPDATE `%s` SET `aslot%d` = '%s' WHERE (`steam_id` = '%s');", TheDBPrefix, i+1, ActionBarText, key);
		SQL_TQuery(hDatabase, QueryResults, tquery);
	}
	Format(tquery, sizeof(tquery), "UPDATE `%s` SET `disab` = '%d' WHERE (`steam_id` = '%s');", TheDBPrefix, isDisab, key);
	SQL_TQuery(hDatabase, QueryResults, tquery);

	LogMessage("Saving Profile %N where steamid: %s", client, key);
}

stock ReadProfiles(client, String:target[] = "none") {

	if (bIsTalentTwo[client]) {

		BuildMenu(client);
		return;
	}

	if (hDatabase == INVALID_HANDLE) return;
	decl String:key[64];
	if (StrEqual(target, "none", false)) GetClientAuthString(client, key, sizeof(key));
	else Format(key, sizeof(key), "%s", target);
	Format(key, sizeof(key), "%s+", key);
	decl String:tquery[128];
	decl String:pct[4];
	Format(pct, sizeof(pct), "%");

	new owner = client;
	if (LoadTarget[owner] != -1 && LoadTarget[owner] != owner && IsSurvivorBot(LoadTarget[owner])) client = LoadTarget[owner]; 

	if (!StrEqual(target, "all", false)) Format(tquery, sizeof(tquery), "SELECT `steam_id` FROM `%s` WHERE `steam_id` LIKE '%s%s' AND `total upgrades` <= '%d';", TheDBPrefix, key, pct, PlayerLevel[client]);
	else Format(tquery, sizeof(tquery), "SELECT `steam_id` FROM `%s` WHERE `steam_id` LIKE '%s+SavedProfile%s' AND `total upgrades` <= '%d';", TheDBPrefix, pct, PROFILE_VERSION, PlayerLevel[client]);
	//PrintToChat(client, tquery);
	//decl String:tqueryE[512];
	//SQL_EscapeString(Handle:hDatabase, tquery, tqueryE, sizeof(tqueryE));
	// maybe set a value equal to the users steamid integer only, so if steam:0:1:23456, set the value of "client" equal to 23456 and then set the client equal to whatever client's steamid contains 23456?
	//LogMessage("Loading %N data: %s", client, tquery);
	ClearArray(Handle:PlayerProfiles[owner]);
	if (!StrEqual(target, "all", false)) SQL_TQuery(hDatabase, ReadProfiles_Generate, tquery, owner);
	else SQL_TQuery(hDatabase, ReadProfiles_GenerateAll, tquery, owner);
}

stock BuildSubMenu(client, String:MenuName[], String:ConfigName[], String:ReturnMenu[] = "none") {
	bIsClassAbilities[client] = false;
	// Each talent has a defined "menu name" ("part of menu named?") and will list under that menu. Genius, right?
	new Handle:menu					=	CreateMenu(BuildSubMenuHandle);
	// So that back buttons work properly we need to know the previous menu; Store the current menu.
	if (!StrEqual(ReturnMenu, "none", false)) Format(OpenedMenu[client], sizeof(OpenedMenu[]), "%s", ReturnMenu);
	Format(OpenedMenu_p[client], sizeof(OpenedMenu_p[]), "%s", OpenedMenu[client]);
	Format(OpenedMenu[client], sizeof(OpenedMenu[]), "%s", MenuName);
	Format(MenuSelection_p[client], sizeof(MenuSelection_p[]), "%s", MenuSelection[client]);
	Format(MenuSelection[client], sizeof(MenuSelection[]), "%s", ConfigName);

	if (!b_IsDirectorTalents[client]) {

		if (StrEqual(ConfigName, CONFIG_MENUTALENTS)) {

			BuildMenuTitle(client, menu, _, 1, _, ShowPlayerLayerInformation[client]);
		}
		else if (StrEqual(ConfigName, CONFIG_POINTS)) {

			BuildMenuTitle(client, menu, _, 2);
		}
	}
	else BuildMenuTitle(client, menu, 1);

	decl String:text[PLATFORM_MAX_PATH];
	decl String:pct[4];
	decl String:TalentName[128];
	decl String:TalentName_Temp[128];
	new isSubMenu = 0;
	new TalentLevelRequired			=	0;
	new PlayerTalentPoints			=	0;
	//new AbilityInherited			=	0;
	//new StorePurchaseCost			=	0;
	new AbilityTalent				=	0;
	new isSpecialAmmo				=	0;
	//decl String:sClassAllowed[64];
	//decl String:sClassID[64];
	decl String:sTalentsRequired[512];
	new bool:bIsNotEligible = false;
	//new iSkyLevelReq = 0;//deprecated for now
	new nodeUnlockCost = 0;
	new optionsRemaining = 0;
	Format(pct, sizeof(pct), "%");//required for translations

	new size						=	GetArraySize(a_Menu_Talents);
	// all talents are now housed in a shared config file... taking our total down to like.. 14... sigh... is customization really worth that headache?
	// and I mean the headache for YOU, not the headache for me. This is easy. EASY. YOU CAN'T BREAK ME.
	//if (StrEqual(ConfigName, CONFIG_MENUSURVIVOR)) size			=	GetArraySize(a_Menu_Talents_Survivor);
	//else if (StrEqual(ConfigName, CONFIG_MENUINFECTED)) size	=	GetArraySize(a_Menu_Talents_Infected);
	
	// so if we're not equipping items to the action bar, we show them based on which submenu we've called.
	// these keys/values/section names match their talentmenu.cfg notations.
	new requiredTalentsRequiredToUnlock = 0;
	new requiredCopy = 0;
	for (new i = 0; i < size; i++) {
		MenuKeys[client]			= GetArrayCell(a_Menu_Talents, i, 0);
		MenuValues[client]			= GetArrayCell(a_Menu_Talents, i, 1);
		MenuSection[client]			= GetArrayCell(a_Menu_Talents, i, 2);

		GetArrayString(Handle:MenuSection[client], 0, TalentName, sizeof(TalentName));
		if (!bEquipSpells[client] && !TalentListingFound(client, MenuKeys[client], MenuValues[client], MenuName)) continue;
		AbilityTalent	=	GetKeyValueInt(MenuKeys[client], MenuValues[client], "is ability?");
		isSpecialAmmo	=	GetKeyValueInt(MenuKeys[client], MenuValues[client], "special ammo?");
		PlayerTalentPoints = GetTalentStrength(client, TalentName);

		if (bEquipSpells[client]) {
			if (AbilityTalent != 1 && isSpecialAmmo != 1) continue;
			if (PlayerTalentPoints < 1) continue;

			//Format(TalentName_Temp, sizeof(TalentName_Temp), "%T", TalentName, client);
			FormatKeyValue(text, sizeof(text), MenuKeys[client], MenuValues[client], "action bar name?");
			if (StrEqual(text, "-1")) SetFailState("%s missing action bar name", TalentName);
			Format(text, sizeof(text), "%T", text, client);
			AddMenuItem(menu, text, text);
			continue;
		}

		GetTranslationOfTalentName(client, TalentName, TalentName_Temp, sizeof(TalentName_Temp), true);
		Format(TalentName_Temp, sizeof(TalentName_Temp), "%T", TalentName_Temp, client);
		isSubMenu = GetKeyValueInt(MenuKeys[client], MenuValues[client], "is sub menu?");
		TalentLevelRequired = GetKeyValueInt(MenuKeys[client], MenuValues[client], "minimum level required?");
		// isSubMenu 3 is for a different operation, we do || instead of &&
		if (isSubMenu == 1 || isSubMenu == 2) {

			// We strictly show the menu option.
			if (isSubMenu == 1 && PlayerLevel[client] < TalentLevelRequired) Format(text, sizeof(text), "%T", "Submenu Locked", client, TalentName_Temp, TalentLevelRequired);
			else Format(text, sizeof(text), "%T", "Submenu Available", client, TalentName_Temp);
		}
		else {
			if (GetKeyValueInt(MenuKeys[client], MenuValues[client], "is item?") == 1) continue;	// ignore items.
			//AbilityInherited = GetKeyValueInt(MenuKeys[client], MenuValues[client], "ability inherited?");
			nodeUnlockCost = GetKeyValueInt(MenuKeys[client], MenuValues[client], "node unlock cost?", "1");	// we want to default the nodeUnlockCost to 1 if it's not set.
			if (!b_IsDirectorTalents[client]) {
				FormatKeyValue(sTalentsRequired, sizeof(sTalentsRequired), MenuKeys[client], MenuValues[client], "talents required?");
				if (GetKeyValueInt(MenuKeys[client], MenuValues[client], "show debug info?") == 1) PrintToChat(client, "%s", sTalentsRequired);
				requiredTalentsRequiredToUnlock = GetKeyValueInt(MenuKeys[client], MenuValues[client], "required talents required?");
				requiredCopy = requiredTalentsRequiredToUnlock;
				optionsRemaining = TalentRequirementsMet(client, sTalentsRequired, _, -1);
				if (requiredTalentsRequiredToUnlock > 0) requiredTalentsRequiredToUnlock = TalentRequirementsMet(client, sTalentsRequired, sTalentsRequired, sizeof(sTalentsRequired), requiredTalentsRequiredToUnlock);
				if (requiredTalentsRequiredToUnlock > 0) {
					bIsNotEligible = true;
					if (PlayerTalentPoints > 0) {
						FreeUpgrades[client] += nodeUnlockCost;
						PlayerUpgradesTotal[client] -= PlayerTalentPoints;
						AddTalentPoints(client, TalentName, 0);
					}
				}
				else {
					bIsNotEligible = false;
					if (PlayerTalentPoints > 1) {
						/*
						The player was on a server with different talent settings; specifically,
						it's clear some talents allowed greater values. Since this server doesn't,
						we set them to the maximum, refund the extra points.
						*/
						// dev note; we did this because players have saveable profiles and they can just load their server-specific profiles at any time.
						// instantly, and effortlessly, because it's an rpg and a common sense feature that should ALWAYS EXIST IN AN RPG.
						FreeUpgrades[client] += (PlayerTalentPoints - 1);
						PlayerUpgradesTotal[client] -= (PlayerTalentPoints - 1);
						AddTalentPoints(client, TalentName, (PlayerTalentPoints - 1));
					}
				}
			}
			else PlayerTalentPoints = GetTalentStrength(-1, TalentName);
			if (GetKeyValueInt(MenuKeys[client], MenuValues[client], "talent type?") <= 0) {
				if (bIsNotEligible) {
					if (iShowLockedTalents == 0) continue;
					if (requiredTalentsRequiredToUnlock > 1) {
						if (requiredCopy == optionsRemaining) Format(text, sizeof(text), "%T", "node locked by talents all (treeview)", client, TalentName_Temp, sTalentsRequired);
						else Format(text, sizeof(text), "%T", "node locked by talents multiple (treeview)", client, TalentName_Temp, sTalentsRequired, requiredTalentsRequiredToUnlock);
					} else {
						if (optionsRemaining == 1) Format(text, sizeof(text), "%T", "node locked by talents last one (treeview)", client, TalentName_Temp, sTalentsRequired);
						else Format(text, sizeof(text), "%T", "node locked by talents single (treeview)", client, TalentName_Temp, sTalentsRequired, requiredTalentsRequiredToUnlock);
					}
				}
				else if (PlayerTalentPoints < 1) {
					Format(text, sizeof(text), "%T", "node locked", client, TalentName_Temp, nodeUnlockCost);
				}
				else Format(text, sizeof(text), "%T", "node unlocked", client, TalentName_Temp);
			}
			else {
				Format(text, sizeof(text), "%T", TalentName_Temp, client);
			}
		}
		AddMenuItem(menu, text, text);
	}
	SetMenuExitBackButton(menu, true);
	DisplayMenu(menu, client, 0);
}

stock bool:TalentListingFound(client, Handle:Keys, Handle:Values, String:MenuName[], bool:IsAllowItems = false) {

	new size = GetArraySize(Keys);

	decl String:key[64];
	decl String:value[64];

	for (new i = 0; i < size; i++) {

		GetArrayString(Handle:Keys, i, key, sizeof(key));
		if (StrEqual(key, "part of menu named?")) {

			GetArrayString(Handle:Values, i, value, sizeof(value));
			if (!StrEqual(MenuName, value)) return false;
		}
		/*if (StrEqual(key, "is item?") && !IsAllowItems) { // can be true only in bestiary

			GetArrayString(Handle:Values, i, value, sizeof(value));
			if (StringToInt(value) == 1) return false;
		}*/
		// The following segment is no longer used. It was originally used when configs were not split based on team number.
		// It meant that server operators would fill a single, massive config with team data, and it would be parsed to a player based on this setting.
		// That's still an option that I'm looking at, for the future, but for now, it won't be the case.
		/*if (StrEqual(key, "team?")) {

			GetArrayString(Handle:Values, i, value, sizeof(value));
			if (strlen(value) > 0 && GetClientTeam(client) != StringToInt(value)) return false;
		}
		*/
		// If this value is set to anything other than "none" a player won't be able to view or select it unless they have at least one of the flags
		// provided. This allows server operators to experiment with new talents, publicly, while granting access to these talents to specific players.
		if (StrEqual(key, "flags?")) {

			GetArrayString(Handle:Values, i, value, sizeof(value));
			if (!StrEqual(value, "none", false) && !HasCommandAccess(client, value)) return false;
		}
	}
	return true;
}

public BuildSubMenuHandle(Handle:menu, MenuAction:action, client, slot)
{
	if (action == MenuAction_Select)
	{
		decl String:ConfigName[64];
		Format(ConfigName, sizeof(ConfigName), "%s", MenuSelection[client]);
		decl String:MenuName[64];
		Format(MenuName, sizeof(MenuName), "%s", OpenedMenu[client]);
		new pos							=	-1;

		BuildMenuTitle(client, menu);

		decl String:pct[4];

		decl String:TalentName[64];
		new isSubMenu = 0;


		new PlayerTalentPoints			=	0;

		decl String:SurvEffects[64];
		Format(SurvEffects, sizeof(SurvEffects), "0");

		Format(pct, sizeof(pct), "%");

		new size						=	GetArraySize(a_Menu_Talents);
		new TalentLevelRequired			= 0;
		new AbilityTalent				= 0;
		new isSpecialAmmo				= 0;
		//decl String:sClassAllowed[64];
		//decl String:sClassID[64];
		decl String:sTalentsRequired[64];
		//new nodeUnlockCost = 0;

		//new bool:bIsNotEligible = false;

		//new iSkyLevelReq = 0;

		//if (StrEqual(ConfigName, CONFIG_MENUSURVIVOR)) size			=	GetArraySize(a_Menu_Talents_Survivor);
		//else if (StrEqual(ConfigName, CONFIG_MENUINFECTED)) size	=	GetArraySize(a_Menu_Talents_Infected);

		for (new i = 0; i < size; i++) {

			MenuKeys[client]				= GetArrayCell(a_Menu_Talents, i, 0);
			MenuValues[client]				= GetArrayCell(a_Menu_Talents, i, 1);
			MenuSection[client]				= GetArrayCell(a_Menu_Talents, i, 2);

			GetArrayString(Handle:MenuSection[client], 0, TalentName, sizeof(TalentName));
			if (!bEquipSpells[client] && !TalentListingFound(client, MenuKeys[client], MenuValues[client], MenuName)) continue;
			AbilityTalent	=	GetKeyValueInt(MenuKeys[client], MenuValues[client], "is ability?");
			isSpecialAmmo	=	GetKeyValueInt(MenuKeys[client], MenuValues[client], "special ammo?");
			PlayerTalentPoints = GetTalentStrength(client, TalentName);
			if (bEquipSpells[client]) {
				if (AbilityTalent != 1 && isSpecialAmmo != 1) continue;
				if (PlayerTalentPoints < 1) continue;
			}

			isSubMenu = GetKeyValueInt(MenuKeys[client], MenuValues[client], "is sub menu?");
			TalentLevelRequired = GetKeyValueInt(MenuKeys[client], MenuValues[client], "minimum level required?");
			//iSkyLevelReq	=	GetKeyValueInt(MenuKeys[client], MenuValues[client], "sky level requirement?");
			//nodeUnlockCost = GetKeyValueInt(MenuKeys[client], MenuValues[client], "node unlock cost?", "1");
			
			FormatKeyValue(sTalentsRequired, sizeof(sTalentsRequired), MenuKeys[client], MenuValues[client], "talents required?");
			//if (!TalentRequirementsMet(client, sTalentsRequired)) continue;

			if (GetKeyValueInt(MenuKeys[client], MenuValues[client], "is item?") == 1) continue;
			pos++;

			FormatKeyValue(SurvEffects, sizeof(SurvEffects), MenuKeys[client], MenuValues[client], "survivor ability effects?");

			if (pos == slot) break;
		}

		if (isSubMenu == 1 || isSubMenu == 2) {

			/*if (isSubMenu == 2) {

				bEquipSpells[client] = true;
				FormatKeyValue(TalentName, sizeof(TalentName), MenuKeys[client], MenuValues[client], "target menu?");
			}
			else {
				if (bEquipSpells[client]) PrintToChat(client, "disabling equip spells.");
				bEquipSpells[client] = false;
			}*/

			if (PlayerLevel[client] < TalentLevelRequired) {

				BuildSubMenu(client, OpenedMenu[client], MenuSelection[client]);
			}
			else {



				// If the player is eligible we open a new sub-menu.
				BuildSubMenu(client, TalentName, MenuSelection[client], OpenedMenu[client]);
			}
		}
		else {

			PlayerTalentPoints = GetTalentStrength(client, TalentName);
			//if (AbilityTalent == 1 || PlayerLevel[client] >= TalentLevelRequired || bEquipSpells[client]) {// submenu 2 is to send to spell equip screen *Flex*
			if (PlayerLevel[client] >= TalentLevelRequired || bEquipSpells[client]) {// submenu 2 is to send to spell equip screen *Flex*

				PurchaseTalentName[client] = TalentName;
				PurchaseSurvEffects[client] = SurvEffects;
				PurchaseTalentPoints[client] = PlayerTalentPoints;

				if (bEquipSpells[client]) ShowTalentInfoScreen(client, TalentName, MenuKeys[client], MenuValues[client], true);
				else ShowTalentInfoScreen(client, TalentName, MenuKeys[client], MenuValues[client]);
			}
			else {

				decl String:TalentName_temp[64];
				Format(TalentName_temp, sizeof(TalentName_temp), "%T", TalentName, client);

				if (GetKeyValueInt(MenuKeys[client], MenuValues[client], "is survivor class role?") != 1) PrintToChat(client, "%T", "talent level requirement not met", client, orange, blue, TalentLevelRequired, orange, green, TalentName_temp);
				else PrintToChat(client, "%T", "class level requirement not met", client, orange, blue, TalentLevelRequired, orange, green, TalentName_temp);
				BuildSubMenu(client, OpenedMenu[client], MenuSelection[client]);
			}
		}
	}
	else if (action == MenuAction_Cancel) {

		if (slot == MenuCancel_ExitBack) {
			bEquipSpells[client] = false;
			BuildMenu(client);
		}
	}
	if (action == MenuAction_End)
	{
		CloseHandle(menu);
	}
}
// need to code in abilities as showing if bIsEquipSpells and requiring an upgrade point to enable.
stock ShowTalentInfoScreen(client, String:TalentName[], Handle:Keys, Handle:Values, bool:bIsEquipSpells = false) {

	PurchaseKeys[client] = Keys;
	PurchaseValues[client] = Values;
	Format(PurchaseTalentName[client], sizeof(PurchaseTalentName[]), "%s", TalentName);
	//new IsAbilityType = GetKeyValueInt(PurchaseKeys[client], PurchaseValues[client], "is ability?");
	//new IsSpecialAmmo = GetKeyValueInt(PurchaseKeys[client], PurchaseValues[client], "special ammo?");
	//PurchaseTalentName[client] = TalentName;
	// programming the logic is hard when baked :(
	//if (IsAbilityType == 1 || IsSpecialAmmo == 1 && bIsSprinting[client]) SendPanelToClientAndClose(TalentInfoScreen_Special(client), client, TalentInfoScreen_Special_Init, MENU_TIME_FOREVER);
	if (bIsEquipSpells) SendPanelToClientAndClose(TalentInfoScreen_Special(client), client, TalentInfoScreen_Special_Init, MENU_TIME_FOREVER);
	else SendPanelToClientAndClose(TalentInfoScreen(client), client, TalentInfoScreen_Init, MENU_TIME_FOREVER);
	//if (IsAbilityType == 0 || !bIsSprinting[client]) SendPanelToClientAndClose(TalentInfoScreen(client), client, TalentInfoScreen_Init, MENU_TIME_FOREVER);
	//else if (IsSpecialAmmo == 1 || IsAbilityType == 1) SendPanelToClientAndClose(TalentInfoScreen_Special(client), client, TalentInfoScreen_Special_Init, MENU_TIME_FOREVER);
}

stock Float:GetTalentInfo(client, Handle:Keys, Handle:Values, infotype = 0, bool:bIsNext = false, String:pTalentNameOverride[] = "none", target = 0, iStrengthOverride = 0) {

	new Float:f_Strength	= 0.0;
	decl String:TalentNameOverride[64];
	if (iStrengthOverride > 0) f_Strength = iStrengthOverride * 1.0;
	else {

		//if (!StrEqual(TalentNameOverride, "none")) f_Strength = GetTalentStrength(client, TalentNameOverride, target) * 1.0;
		if (StrEqual(pTalentNameOverride, "none")) Format(TalentNameOverride, sizeof(TalentNameOverride), "%s", PurchaseTalentName[client]);
		else Format(TalentNameOverride, sizeof(TalentNameOverride), "%s", pTalentNameOverride);
		f_Strength	=	GetTalentStrength(client, TalentNameOverride) * 1.0;
	}
	if (bIsNext) f_Strength++;

	if (f_Strength <= 0.0) return 0.0;

	new Float:f_StrengthPoint	= 0.0;
	//new Float:f_StrengthFirst	= 0.0;
	//new Float:f_StrengthT		= 0.0;
	//new Float:f_StrengthP		= 0.0;

	if (target == 0 || !IsLegitimateClient(target)) target = client;

	/*
		Server operators can make up their own custom attributes, and make them affect any node they want.
		This key "governing attribute?" lets me know what attribute multiplier to collect.
		If you don't want a node governed by an attribute, omit the field.
	*/
	decl String:text[64];
	FormatKeyValue(text, sizeof(text), Keys, Values, "governing attribute?");
	new Float:governingAttributeMultiplier = 0.0;
	if (!StrEqual(text, "-1")) governingAttributeMultiplier = GetAttributeMultiplier(client, text);

	//new Cons = GetTalentStrength(target, "constitution");
	//new Resi = GetTalentStrength(target, "resilience");
	//new Agil = GetTalentStrength(target, "agility");
	//new Tech = GetTalentStrength(target, "technique");
	//new Endu = GetTalentStrength(target, "endurance");
	//new Luck = GetTalentStrength(client, "luck");
	//new Float:f_StrEach = f_Strength - 1;
	//new Float:TheAbilityMultiplier = 0.0;
	
	//we want to add support for a "type" of talent.
	decl String:sTalentStrengthType[64];
	if (infotype == 0 || infotype == 1) FormatKeyValue(sTalentStrengthType, sizeof(sTalentStrengthType), Keys, Values, "talent upgrade strength value?", "1.0");
	else if (infotype == 2) FormatKeyValue(sTalentStrengthType, sizeof(sTalentStrengthType), Keys, Values, "talent active time strength value?", "1.0");
	else if (infotype == 3) FormatKeyValue(sTalentStrengthType, sizeof(sTalentStrengthType), Keys, Values, "talent cooldown strength value?", "1.0");
	new iExplodeCount = GetDelimiterCount(sTalentStrengthType, ",") + 1;
	//new bool:isInteger = (StrContains(sTalentStrengthType, ".") == -1)? false : true;
	decl String:sTalentStrengthLevels[iExplodeCount][512];
	if (iExplodeCount > 1) ExplodeString(sTalentStrengthType, ",", sTalentStrengthLevels, iExplodeCount, 512);
	else Format(sTalentStrengthLevels[0], sizeof(sTalentStrengthLevels[]), "%s", sTalentStrengthType);
	
	/* 1,2,3,3,4
	"talent point value?"							"0.01,0.03,0.05,0.1,0.15"	// new talent point system
	"talent last point scale?"						"1.25"						// new talent point system
	"talent tree category?"							"survival"					// new talent point system*/
	new istrength = RoundToCeil(f_Strength);
	new Float:f_StrengthIncrement = 0.0;
	for (new i = 0; i < istrength && i < iExplodeCount; i++) {
		f_StrengthIncrement = StringToFloat(sTalentStrengthLevels[i]);
		f_StrengthPoint += f_StrengthIncrement;
	}
	if (governingAttributeMultiplier > 0.0) {
		f_StrengthPoint += RoundToCeil(f_StrengthPoint * governingAttributeMultiplier);
	}
	if (infotype == 3) {
		decl String:sCooldownGovernor[64];
		new Float:cdReduction = 0.0;
		new acdReduction = GetArraySize(a_Menu_Talents);
		for (new i = 0; i < acdReduction; i++) {
			acdrKeys[client] = GetArrayCell(a_Menu_Talents, i, 0);
			acdrValues[client] = GetArrayCell(a_Menu_Talents, i, 1);
			FormatKeyValue(sCooldownGovernor, sizeof(sCooldownGovernor), acdrKeys[client], acdrValues[client], "governs cooldown of talent named?");
			//if (GetKeyValueInt(acdrKeys[client], acdrValues[client], "show debug info?") == 1) PrintToChat(client, "%s", sCooldownGovernor);
			if (!FoundCooldownReduction(TalentNameOverride, sCooldownGovernor)) continue;
			//if (StrContains(TalentNameOverride, sCooldownGovernor, false) == -1) continue;

			acdrSection[client] = GetArrayCell(a_Menu_Talents, i, 2);
			GetArrayString(acdrSection[client], 0, sCooldownGovernor, sizeof(sCooldownGovernor));
			cdReduction += GetTalentInfo(client, acdrKeys[client], acdrValues[client], _, _, sCooldownGovernor);
		}
		if (cdReduction > 0.0) f_StrengthPoint -= (f_StrengthPoint * cdReduction);
		if (f_StrengthPoint < 0.0) f_StrengthPoint = 0.0;	// can't have cooldowns that are less than 0.0 seconds.
	}

	new Float:TalentHardLimit = GetKeyValueFloat(Keys, Values, "talent hard limit?");
	if (infotype != 3 && f_StrengthPoint > TalentHardLimit && TalentHardLimit > 0.0) f_StrengthPoint = TalentHardLimit;

	return f_StrengthPoint;
}

public Handle:TalentInfoScreen (client) {
	new AbilityTalent			= GetKeyValueInt(PurchaseKeys[client], PurchaseValues[client], "is ability?");
	new IsSpecialAmmo = GetKeyValueInt(PurchaseKeys[client], PurchaseValues[client], "special ammo?");

	new Handle:menu = CreatePanel();
	BuildMenuTitle(client, menu, _, 0, true, true);

	decl String:TalentName[64];
	Format(TalentName, sizeof(TalentName), "%s", PurchaseTalentName[client]);

	new TalentPointAmount		= 0;
	if (!b_IsDirectorTalents[client]) TalentPointAmount = GetTalentStrength(client, TalentName);
	else TalentPointAmount = GetTalentStrength(-1, TalentName);

	new TalentType = GetKeyValueInt(PurchaseKeys[client], PurchaseValues[client], "talent type?");
	new nodeUnlockCost = GetKeyValueInt(PurchaseKeys[client], PurchaseValues[client], "node unlock cost?", "1");

	new Float:s_TalentPoints = GetTalentInfo(client, PurchaseKeys[client], PurchaseValues[client]);
	new Float:s_OtherPointNext = GetTalentInfo(client, PurchaseKeys[client], PurchaseValues[client], _, true);
	new Float:s_SoftCapCooldown = 0.0;

	decl String:pct[4];
	Format(pct, sizeof(pct), "%");
	
	new Float:f_CooldownNow = GetTalentInfo(client, PurchaseKeys[client], PurchaseValues[client], 3);
	new Float:f_CooldownNext = GetTalentInfo(client, PurchaseKeys[client], PurchaseValues[client], 3, true);

	decl String:TalentIdCode[64];
	decl String:TalentIdNum[64];
	FormatKeyValue(TalentIdNum, sizeof(TalentIdNum), PurchaseKeys[client], PurchaseValues[client], "id_number");

	Format(TalentIdCode, sizeof(TalentIdCode), "%T", "Talent Id Code", client);
	Format(TalentIdCode, sizeof(TalentIdCode), "%s: %s", TalentIdCode, TalentIdNum);

	//	We copy the talent name to another string so we can show the talent in the language of the player.
	
	decl String:TalentName_Temp[64];
	decl String:TalentNameTranslation[64];
	GetTranslationOfTalentName(client, TalentName, TalentNameTranslation, sizeof(TalentNameTranslation), true);
	Format(TalentName_Temp, sizeof(TalentName_Temp), "%T", TalentNameTranslation, client);
	decl String:text[512];
	if (AbilityTalent != 1) {

		if (FreeUpgrades[client] < 0) FreeUpgrades[client] = 0;
		Format(text, sizeof(text), "%T", "Talent Upgrade Title", client, TalentName_Temp, TalentPointAmount);
	}
	else Format(text, sizeof(text), "%s", TalentName_Temp);
	DrawPanelText(menu, text);

	decl String:governingAttribute[64];
	GetGoverningAttribute(client, TalentName, governingAttribute, sizeof(governingAttribute));
	if (!StrEqual(governingAttribute, "-1")) {
		Format(text, sizeof(text), "%T", governingAttribute, client);
		Format(text, sizeof(text), "%T", "Node Governing Attribute", client, text);
		DrawPanelText(menu, text);
	}

	decl String:TalentInfo[128];
	new AbilityType = 0;
	if (AbilityTalent != 1) {

		if (IsSpecialAmmo != 1) {

			if (TalentPointAmount == 0) Format(text, sizeof(text), "%T", "Talent Cooldown Info - No Points", client, s_SoftCapCooldown + f_CooldownNext);
			else Format(text, sizeof(text), "%T", "Talent Cooldown Info", client, s_SoftCapCooldown + f_CooldownNow, s_SoftCapCooldown + f_CooldownNext);
			if (f_CooldownNext > 0.0) DrawPanelText(menu, text);

			new Float:i_AbilityTime = GetTalentInfo(client, PurchaseKeys[client], PurchaseValues[client], 2);
			new Float:i_AbilityTimeNext = GetTalentInfo(client, PurchaseKeys[client], PurchaseValues[client], 2, true);

			/*
				ability type ONLY EXISTS for displaying different information to the players via menus.
				the EXCEPTION to this is type 3, where rpg_functions.sp line 2428 makes a check using it.

				Otherwise, it's just how we translate it for the player to understand.
			*/
			AbilityType = StringToInt(GetKeyValue(PurchaseKeys[client], PurchaseValues[client], "ability type?"));
			//if (TalentPointAmount > 0) s_PenaltyPoint = 0.0;
			if (TalentType <= 0) {

				
				if (TalentPointAmount < 1) {
					if (AbilityType == 0) Format(text, sizeof(text), "%T", "Ability Info Percent", client, s_TalentPoints * 100.0, pct, s_OtherPointNext * 100.0, pct);
					else if (AbilityType == 1) Format(text, sizeof(text), "%T", "Ability Info Time", client, i_AbilityTime, i_AbilityTimeNext);
					else if (AbilityType == 2) Format(text, sizeof(text), "%T", "Ability Info Distance", client, s_TalentPoints, s_OtherPointNext);
					else if (AbilityType == 3) Format(text, sizeof(text), "%T", "Ability Info Raw", client, RoundToCeil(s_TalentPoints), RoundToCeil(s_OtherPointNext));
				}
				else {
					if (AbilityType == 0) Format(text, sizeof(text), "%T", "Ability Info Percent Max", client, s_TalentPoints * 100.0, pct);
					else if (AbilityType == 1) Format(text, sizeof(text), "%T", "Ability Info Time Max", client, i_AbilityTime);
					else if (AbilityType == 2) Format(text, sizeof(text), "%T", "Ability Info Distance Max", client, s_TalentPoints);
					else if (AbilityType == 3) Format(text, sizeof(text), "%T", "Ability Info Raw Max", client, RoundToCeil(s_TalentPoints));
				}
				DrawPanelText(menu, text);
				//DrawPanelText(menu, TalentIdCode);
			}
		}
		else {


			/*if (FreeUpgrades[client] == 0) Format(text, sizeof(text), "%T", "Talent Upgrade Title", client, TalentName_Temp, TalentPointAmount, TalentPointMaximum);
			else Format(text, sizeof(text), "%T", "Talent Upgrade Title Free", client, TalentName_Temp, TalentPointAmount, TalentPointMaximum, FreeUpgrades[client]);
			SetPanelTitle(menu, text);*/

			new Float:fTimeCur = GetSpecialAmmoStrength(client, TalentName);
			new Float:fTimeNex = GetSpecialAmmoStrength(client, TalentName, 0, true);

			//new Float:flIntCur = GetSpecialAmmoStrength(client, TalentName, 4);
			//new Float:flIntNex = GetSpecialAmmoStrength(client, TalentName, 4, true);

			//if (flIntCur > fTimeCur) flIntCur = fTimeCur;
			//if (flIntNex > fTimeNex) flIntNex = fTimeNex;

			//Format(text, sizeof(text), "%T", "Special Ammo Interval", client, flIntCur, flIntNex);
			//DrawPanelText(menu, text);
			if (TalentPointAmount < 1) {
				Format(text, sizeof(text), "%T", "Special Ammo Time", client, fTimeNex);
				DrawPanelText(menu, text);
				Format(text, sizeof(text), "%T", "Special Ammo Cooldown", client, fTimeNex + GetSpecialAmmoStrength(client, TalentName, 1, true));
				DrawPanelText(menu, text);
				Format(text, sizeof(text), "%T", "Special Ammo Stamina", client, RoundToCeil(GetSpecialAmmoStrength(client, TalentName, 2, true)));
				DrawPanelText(menu, text);
				Format(text, sizeof(text), "%T", "Special Ammo Range", client, GetSpecialAmmoStrength(client, TalentName, 3, true));
				DrawPanelText(menu, text);
			}
			else {
				Format(text, sizeof(text), "%T", "Special Ammo Time Max", client, fTimeCur);
				DrawPanelText(menu, text);
				Format(text, sizeof(text), "%T", "Special Ammo Cooldown Max", client, fTimeCur + GetSpecialAmmoStrength(client, TalentName, 1));
				DrawPanelText(menu, text);
				Format(text, sizeof(text), "%T", "Special Ammo Stamina Max", client, RoundToCeil(GetSpecialAmmoStrength(client, TalentName, 2)));
				DrawPanelText(menu, text);
				Format(text, sizeof(text), "%T", "Special Ammo Range Max", client, GetSpecialAmmoStrength(client, TalentName, 3));
				DrawPanelText(menu, text);
			}
			//DrawPanelText(menu, TalentIdCode);
		}
	}

	if (TalentType <= 0 || AbilityTalent == 1) {

		if (TalentPointAmount == 0) {
			new ignoreLayerCount = GetKeyValueInt(PurchaseKeys[client], PurchaseValues[client], "ignore for layer count?");
			new bool:bIsLayerEligible = (PlayerCurrentMenuLayer[client] <= 1 || GetLayerUpgradeStrength(client, PlayerCurrentMenuLayer[client] - 1) >= PlayerCurrentMenuLayer[client]) ? true : false;
			if (bIsLayerEligible) bIsLayerEligible = ((ignoreLayerCount == 1 || GetLayerUpgradeStrength(client, PlayerCurrentMenuLayer[client]) < PlayerCurrentMenuLayer[client] + 1) && UpgradesAvailable[client] + FreeUpgrades[client] >= nodeUnlockCost) ? true : false;

			decl String:sTalentsRequired[64];
			decl String:formattedTalentsRequired[64];
			FormatKeyValue(sTalentsRequired, sizeof(sTalentsRequired), PurchaseKeys[client], PurchaseValues[client], "talents required?");
			new requirementsRemaining = GetKeyValueInt(PurchaseKeys[client], PurchaseValues[client], "required talents required?");
			new requiredCopy = requirementsRemaining;
			requirementsRemaining = TalentRequirementsMet(client, sTalentsRequired, formattedTalentsRequired, sizeof(formattedTalentsRequired), requirementsRemaining);
			new optionsRemaining = TalentRequirementsMet(client, sTalentsRequired, _, -1);	// -1 for size gets the count remaining
			if (bIsLayerEligible || requirementsRemaining >= 1) {
				if (requirementsRemaining <= 0) Format(text, sizeof(text), "%T", "Insert Talent Upgrade", client, 1);
				else if (requirementsRemaining >= 1) {
					if (requirementsRemaining > 1) {
						if (requiredCopy == optionsRemaining) Format(text, sizeof(text), "%T", "node locked by talents all (talentview)", client, formattedTalentsRequired);
						else Format(text, sizeof(text), "%T", "node locked by talents multiple (talentview)", client, formattedTalentsRequired, requirementsRemaining);
					} else {
						if (optionsRemaining == 1) Format(text, sizeof(text), "%T", "node locked by talents last one (talentview)", client, formattedTalentsRequired);
						else Format(text, sizeof(text), "%T", "node locked by talents single (talentview)", client, formattedTalentsRequired, requirementsRemaining);
					}
				}
				DrawPanelItem(menu, text);
			}
		}
		else {
			Format(text, sizeof(text), "%T", "Refund Talent Upgrade", client, 1);
			DrawPanelItem(menu, text);
		}
	}
	else if (TalentType > 0)  {

		// draw the talent type 1 leveling information and a return option only.
		new talentlevel = GetTalentLevel(client, TalentName);
		new talentexperience = GetTalentLevel(client, TalentName, true);
		new talentrequirement = CheckExperienceRequirementTalents(client, TalentName);
		Format(text, sizeof(text), "%T", "cartel experience screen", client, talentlevel, AddCommasToString(talentexperience), AddCommasToString(talentrequirement), TalentName_Temp, MenuExperienceBar(client, talentexperience, talentrequirement));
		DrawPanelText(menu, text);
	}
	Format(text, sizeof(text), "%T", "return to talent menu", client);
	DrawPanelItem(menu, text);

	if (GetKeyValueInt(PurchaseKeys[client], PurchaseValues[client], "hide translation?") != 1) {
		//	Talents now have a brief description of what they do on their purchase page.
		//	This variable is pre-determined and calls a translation file in the language of the player.
		GetTranslationOfTalentName(client, TalentName, TalentNameTranslation, sizeof(TalentNameTranslation));
		//Format(TalentInfo, sizeof(TalentInfo), "%s", GetTranslationOfTalentName(client, TalentName));
		new Float:rollChance = GetKeyValueFloat(PurchaseKeys[client], PurchaseValues[client], "roll chance?");
		if (TalentType <= 0 && rollChance > 0.0) {
			Format(text, sizeof(text), "%3.2f%s", rollChance * 100.0, pct);
			Format(TalentInfo, sizeof(TalentInfo), "%T", TalentNameTranslation, client, text);
		}
		else Format(TalentInfo, sizeof(TalentInfo), "%T", TalentNameTranslation, client);

		DrawPanelText(menu, TalentInfo);	// rawline means not a selectable option.
	}
	if (AbilityTalent == 1) {

		GetAbilityText(client, text, sizeof(text), PurchaseKeys[client], PurchaseValues[client]);
		if (!StrEqual(text, "-1")) DrawPanelText(menu, text);
		GetAbilityText(client, text, sizeof(text), PurchaseKeys[client], PurchaseValues[client], "passive effect?");
		if (!StrEqual(text, "-1")) DrawPanelText(menu, text);
		GetAbilityText(client, text, sizeof(text), PurchaseKeys[client], PurchaseValues[client], "toggle effect?");
		if (!StrEqual(text, "-1")) DrawPanelText(menu, text);
		GetAbilityText(client, text, sizeof(text), PurchaseKeys[client], PurchaseValues[client], "cooldown effect?");
		if (!StrEqual(text, "-1")) DrawPanelText(menu, text);
	}
	if (AbilityType == 1) {	// show the player what the buff shows as on the buff bar because we aren't monsters like Fatshark.
		FormatEffectOverTimeBuffs(client, text, sizeof(text), GetTalentPosition(client, TalentName));
		Format(text, sizeof(text), "%T", "buff visual display text", client, text);
		DrawPanelText(menu, text);
	}
	new isCompoundingTalent = GetKeyValueInt(PurchaseKeys[client], PurchaseValues[client], "compounding talent?");	// -1 if no value is provided.
	if (isCompoundingTalent >= 0) {
		if (isCompoundingTalent == 1) Format(text, sizeof(text), "%T", "compounding talent info", client);
		else Format(text, sizeof(text), "%T", "not compounding talent info", client);
		DrawPanelText(menu, text);
	}
	return menu;
}

stock GetAbilityText(client, String:TheString[], TheSize, Handle:Keys, Handle:Values, String:TheQuery[] = "active effect?") {

	decl String:text[512], String:text2[512], String:tDraft[512], String:AbilityType[64], String:TheMaximumMultiplier[64];
	new Float:TheAbilityMultiplier = 0.0;
	decl String:pct[4];
	Format(pct, sizeof(pct), "%");
	FormatKeyValue(text, sizeof(text), Keys, Values, TheQuery);
	if (StrEqual(text, "-1")) {

		Format(TheString, TheSize, "-1");
		return;
	}

	if (StrContains(TheQuery, "active", false) != -1) {

		Format(tDraft, sizeof(tDraft), "%T", "Active Effects", client);
		Format(AbilityType, sizeof(AbilityType), "Active Ability");
		TheAbilityMultiplier = GetKeyValueFloat(Keys, Values, "active strength?");

		Format(TheMaximumMultiplier, sizeof(TheMaximumMultiplier), "active");
	}
	else if (StrContains(TheQuery, "passive", false) != -1) {

		Format(tDraft, sizeof(tDraft), "%T", "Passive Effects", client);
		Format(AbilityType, sizeof(AbilityType), "Passive Ability");
		TheAbilityMultiplier = GetKeyValueFloat(Keys, Values, "passive strength?");

		Format(TheMaximumMultiplier, sizeof(TheMaximumMultiplier), "passive");
	}
	else if (StrContains(TheQuery, "cooldown", false) != -1) {

		Format(tDraft, sizeof(tDraft), "%T", "Cooldown Effects", client);
		Format(AbilityType, sizeof(AbilityType), "Cooldown Ability");
		TheAbilityMultiplier = GetKeyValueFloat(Keys, Values, "cooldown strength?");

		Format(TheMaximumMultiplier, sizeof(TheMaximumMultiplier), "cooldown");
	}
	else {

		Format(tDraft, sizeof(tDraft), "%T", "Toggle Effects", client);
		Format(AbilityType, sizeof(AbilityType), "Toggle Ability");
		TheAbilityMultiplier = GetKeyValueFloat(Keys, Values, "toggle strength?");
	}
	Format(text2, sizeof(text2), "%s %s", text, AbilityType);
	new isReactive = GetKeyValueInt(Keys, Values, "reactive ability?");
	if (isReactive == 1) {
		Format(text2, sizeof(text2), "%T", text2, client);
	}
	else {
		if (StrEqual(text, "C", true)) {

			Format(TheMaximumMultiplier, sizeof(TheMaximumMultiplier), "maximum %s multiplier?", TheMaximumMultiplier);
			new Float:MaxMult = GetKeyValueFloat(Keys, Values, TheMaximumMultiplier);
			Format(text2, sizeof(text2), "%T", text2, client, TheAbilityMultiplier * 100.0, pct, MaxMult * 100.0, pct);
		}
		else if (TheAbilityMultiplier > 0.0 || StrEqual(text, "S", true)) {

			Format(text2, sizeof(text2), "%T", text2, client, TheAbilityMultiplier * 100.0, pct);
		}
		else {

			Format(text2, sizeof(text2), "%s Disabled", text);
			Format(text2, sizeof(text2), "%T", text2, client);
		}
	}
	Format(tDraft, sizeof(tDraft), "%s\n%s", tDraft, text2);
	if (StrContains(TheQuery, "active", false) != -1) {

		FormatKeyValue(text, sizeof(text), Keys, Values, "cooldown?");

		TheAbilityMultiplier = GetAbilityMultiplier(client, "L");
		if (TheAbilityMultiplier != -1.0) {

			if (TheAbilityMultiplier < 0.0) TheAbilityMultiplier = 0.1;
			else if (TheAbilityMultiplier > 0.0) { //cooldowns are reduced

				Format(text, sizeof(text), "%3.0f", StringToFloat(text) - (StringToFloat(text) * TheAbilityMultiplier));
			}
		}

		//Format(text, sizeof(text), "%3.3f", StringToFloat(text))
		if (!StrEqual(text, "-1")) Format(text, sizeof(text), "%T", "Ability Cooldown", client, text);
		else Format(text, sizeof(text), "%T", "No Ability Cooldown", client);

		FormatKeyValue(text2, sizeof(text2), Keys, Values, "active time?");
		if (!StrEqual(text2, "-1")) Format(text2, sizeof(text2), "%T", "Ability Active Time", client, text2);
		else Format(text2, sizeof(text2), "%T", "Instant Ability", client);

		Format(TheString, TheSize, "%s\n%s\n%s", text, text2, tDraft);
	}
	else Format(TheString, TheSize, "%s", tDraft);
}

stock GetTalentLevel(client, String:TalentName[], bool:IsExperience = false) {

	new pos = GetTalentPosition(client, TalentName);
	new value = 0;

	if (IsExperience) {

		value = GetArrayCell(a_Database_PlayerTalents_Experience[client], pos);
		if (value < 0) {

			value = 0;
			SetArrayCell(a_Database_PlayerTalents_Experience[client], pos, value);
		}
	}
	else {

		value = GetArrayCell(a_Database_PlayerTalents[client], pos);
		if (value < 0) {

			value = 0;
			SetArrayCell(a_Database_PlayerTalents[client], pos, value);
		}
	}
	return value;
}

public Handle:TalentInfoScreen_Special (client) {

	decl String:TalentName[64];
	Format(TalentName, sizeof(TalentName), "%s", PurchaseTalentName[client]);

	new Handle:menu = CreatePanel();

	new AbilityTalent			= GetKeyValueInt(PurchaseKeys[client], PurchaseValues[client], "is ability?");
	new TalentPointAmount		= GetTalentStrength(client, TalentName);
	new TalentPointMaximum		= 1;

	decl String:TalentIdCode[64];
	decl String:theval[64];
	FormatKeyValue(theval, sizeof(theval), PurchaseKeys[client], PurchaseValues[client], "id_number");
	Format(TalentIdCode, sizeof(TalentIdCode), "%T", "Talent Id Code", client);
	Format(TalentIdCode, sizeof(TalentIdCode), "%s: %s", TalentIdCode, theval);

	

	//	We copy the talent name to another string so we can show the talent in the language of the player.
	
	decl String:TalentName_Temp[64];
	GetTranslationOfTalentName(client, TalentName, TalentName_Temp, sizeof(TalentName_Temp), _, true);
	Format(TalentName_Temp, sizeof(TalentName_Temp), "%T", TalentName_Temp, client);

	

	//	Talents now have a brief description of what they do on their purchase page.
	//	This variable is pre-determined and calls a translation file in the language of the player.
	
	decl String:TalentInfo[128], String:text[512];

	if (AbilityTalent != 1) {

		GetTranslationOfTalentName(client, TalentName, TalentInfo, sizeof(TalentInfo));

		//Format(TalentInfo, sizeof(TalentInfo), "%s", GetTranslationOfTalentName(client, TalentName));
		Format(TalentInfo, sizeof(TalentInfo), "%T", TalentInfo, client);

		if (FreeUpgrades[client] == 0) Format(text, sizeof(text), "%T", "Talent Upgrade Title", client, TalentName_Temp, TalentPointAmount, TalentPointMaximum);
		else Format(text, sizeof(text), "%T", "Talent Upgrade Title Free", client, TalentName_Temp, TalentPointAmount, TalentPointMaximum, FreeUpgrades[client]);
		SetPanelTitle(menu, text);

		new Float:fltime = GetSpecialAmmoStrength(client, TalentName);
		new Float:fltimen = GetSpecialAmmoStrength(client, TalentName, 0, true);

		Format(text, sizeof(text), "%T", "Special Ammo Time", client, fltime, fltimen);
		DrawPanelText(menu, text);
		//Format(text, sizeof(text), "%T", "Special Ammo Interval", client, GetSpecialAmmoStrength(client, TalentName, 4), GetSpecialAmmoStrength(client, TalentName, 4, true));
		//DrawPanelText(menu, text);
		Format(text, sizeof(text), "%T", "Special Ammo Cooldown", client, fltime + GetSpecialAmmoStrength(client, TalentName, 1), fltimen + GetSpecialAmmoStrength(client, TalentName, 1, true));
		DrawPanelText(menu, text);
		Format(text, sizeof(text), "%T", "Special Ammo Stamina", client, RoundToCeil(GetSpecialAmmoStrength(client, TalentName, 2)), RoundToCeil(GetSpecialAmmoStrength(client, TalentName, 2, true)));
		DrawPanelText(menu, text);
		Format(text, sizeof(text), "%T", "Special Ammo Range", client, GetSpecialAmmoStrength(client, TalentName, 3), GetSpecialAmmoStrength(client, TalentName, 3, true));
		DrawPanelText(menu, text);
		DrawPanelText(menu, TalentIdCode);
	}
	else {

		//decl String:tTalentStatus[64];
		GetTranslationOfTalentName(client, TalentName, TalentInfo, sizeof(TalentInfo), _, true);
		Format(TalentInfo, sizeof(TalentInfo), "%T", TalentInfo, client);
		//if (TalentPointAmount < 1) Format(tTalentStatus, sizeof(tTalentStatus), "%T", "ability locked translation", client);
		//else Format(tTalentStatus, sizeof(tTalentStatus), "%T", "ability unlocked translation", client);
		//Format(TalentInfo, sizeof(TalentInfo), "%s (%s)", TalentInfo, tTalentStatus);
		DrawPanelText(menu, TalentInfo);
	}

	// We only have the option to assign it to action bars, instead.
	decl String:ActionBarText[64], String:CommandText[64];
	GetConfigValue(CommandText, sizeof(CommandText), "action slot command?");
	new ActionBarSize = GetArraySize(Handle:ActionBar[client]);

	for (new i = 0; i < ActionBarSize; i++) {
		GetArrayString(Handle:ActionBar[client], i, ActionBarText, sizeof(ActionBarText));
		if (!IsTalentExists(ActionBarText)) Format(ActionBarText, sizeof(ActionBarText), "%T", "No Action Equipped", client);
		else {
			GetTranslationOfTalentName(client, ActionBarText, ActionBarText, sizeof(ActionBarText), _, true);
			Format(ActionBarText, sizeof(ActionBarText), "%T", ActionBarText, client);
		}
		Format(text, sizeof(text), "%T", "Assign to Action Bar", client, CommandText, i + 1, ActionBarText);
		DrawPanelItem(menu, text);
	}
	
	Format(text, sizeof(text), "%T", "return to talent menu", client);
	DrawPanelItem(menu, text);
	if (AbilityTalent == 1) {

		GetAbilityText(client, text, sizeof(text), PurchaseKeys[client], PurchaseValues[client]);
		if (!StrEqual(text, "-1")) DrawPanelText(menu, text);
		GetAbilityText(client, text, sizeof(text), PurchaseKeys[client], PurchaseValues[client], "passive effect?");
		if (!StrEqual(text, "-1")) DrawPanelText(menu, text);
		GetAbilityText(client, text, sizeof(text), PurchaseKeys[client], PurchaseValues[client], "toggle effect?");
		if (!StrEqual(text, "-1")) DrawPanelText(menu, text);
		GetAbilityText(client, text, sizeof(text), PurchaseKeys[client], PurchaseValues[client], "cooldown effect?");
		if (!StrEqual(text, "-1")) DrawPanelText(menu, text);
	}
	else DrawPanelText(menu, TalentInfo);	// rawline means not a selectable option.
	return menu;
}

public TalentInfoScreen_Init (Handle:topmenu, MenuAction:action, client, param2)
{
	if (action == MenuAction_Select)
	{
		new MaxPoints = 1;	// all talents have a minimum of 1 max points, including spells and abilities.
		new TalentStrength = GetTalentStrength(client, PurchaseTalentName[client]);
		decl String:TalentName[64];
		Format(TalentName, sizeof(TalentName), "%s", PurchaseTalentName[client]);
		new TalentType = GetKeyValueInt(PurchaseKeys[client], PurchaseValues[client], "talent type?");
		new AbilityTalent = GetKeyValueInt(PurchaseKeys[client], PurchaseValues[client], "is ability?");

		decl String:sTalentsRequired[64];
		FormatKeyValue(sTalentsRequired, sizeof(sTalentsRequired), PurchaseKeys[client], PurchaseValues[client], "talents required?");
		new requiredTalentsRequired = GetKeyValueInt(PurchaseKeys[client], PurchaseValues[client], "required talents required?");
		if (requiredTalentsRequired > 0) requiredTalentsRequired = TalentRequirementsMet(client, sTalentsRequired, _, _, requiredTalentsRequired);
		
		new nodeUnlockCost = GetKeyValueInt(PurchaseKeys[client], PurchaseValues[client], "node unlock cost?", "1");	// if the key is not found, return a default value of 1.
		new bool:isNodeCostMet = (UpgradesAvailable[client] + FreeUpgrades[client] >= nodeUnlockCost) ? true : false;
		new currentLayer = GetKeyValueInt(PurchaseKeys[client], PurchaseValues[client], "layer?");
		new ignoreLayerCount = GetKeyValueInt(PurchaseKeys[client], PurchaseValues[client], "ignore for layer count?");

		new bool:bIsLayerEligible = (TalentStrength > 0) ? true : false;
		if (!bIsLayerEligible) {
			bIsLayerEligible = (requiredTalentsRequired < 1 && (PlayerCurrentMenuLayer[client] <= 1 || GetLayerUpgradeStrength(client, PlayerCurrentMenuLayer[client] - 1) >= PlayerCurrentMenuLayer[client])) ? true : false;
			if (bIsLayerEligible) bIsLayerEligible = ((ignoreLayerCount == 1 || GetLayerUpgradeStrength(client, PlayerCurrentMenuLayer[client]) < PlayerCurrentMenuLayer[client] + 1) && UpgradesAvailable[client] + FreeUpgrades[client] >= nodeUnlockCost) ? true : false;
		}
		/*if (AbilityTalent == 1 && bActionBarMenuRequest) {

			new ActionBarSize = GetArraySize(Handle:ActionBar[client]);

			if (param2 > ActionBarSize) BuildSubMenu(client, OpenedMenu[client], MenuSelection[client]);
			else {

				if (!SwapActions(client, PurchaseTalentName[client], param2 - 1)) SetArrayString(Handle:ActionBar[client], param2 - 1, PurchaseTalentName[client]);
				SendPanelToClientAndClose(TalentInfoScreen(client), client, TalentInfoScreen_Init, MENU_TIME_FOREVER);
			}
			//SendPanelToClientAndClose(TalentInfoScreen(client), client, TalentInfoScreen_Init, MENU_TIME_FOREVER);
		}*/
		if (TalentType <= 0 || AbilityTalent == 1) {

			switch (param2)
			{
				case 1: {

					if (bIsLayerEligible) {
						if (TalentType <= 0) {
							if (TalentStrength == 0) {
								if (UpgradesAvailable[client] + FreeUpgrades[client] < nodeUnlockCost) BuildSubMenu(client, OpenedMenu[client], MenuSelection[client]);
								else if (isNodeCostMet && TalentStrength + 1 <= MaxPoints) {
								//else if ((UpgradesAvailable[client] > 0 || FreeUpgrades[client] > 0) && TalentStrength + 1 <= MaxPoints) {
									if (UpgradesAvailable[client] >= nodeUnlockCost) {
										TryToTellPeopleYouUpgraded(client);
										UpgradesAvailable[client] -= nodeUnlockCost;
										PlayerLevelUpgrades[client]++;
									}
									else if (FreeUpgrades[client] >= nodeUnlockCost) FreeUpgrades[client] -= nodeUnlockCost;
									else {
										nodeUnlockCost -= FreeUpgrades[client];
										UpgradesAvailable[client] -= nodeUnlockCost;
									}
									PlayerUpgradesTotal[client]++;
									PurchaseTalentPoints[client]++;
									AddTalentPoints(client, PurchaseTalentName[client], PurchaseTalentPoints[client]);
									SendPanelToClientAndClose(TalentInfoScreen(client), client, TalentInfoScreen_Init, MENU_TIME_FOREVER);
								}
							}
							else {
								PlayerUpgradesTotal[client]--;
								PurchaseTalentPoints[client]--;
								FreeUpgrades[client] += nodeUnlockCost;
								AddTalentPoints(client, PurchaseTalentName[client], PurchaseTalentPoints[client]);

								// Check if locking this node makes them ineligible for deeper trees, and remove points
								// in those talents if it's the case, locking the nodes.
								GetLayerUpgradeStrength(client, currentLayer, true);
								SendPanelToClientAndClose(TalentInfoScreen(client), client, TalentInfoScreen_Init, MENU_TIME_FOREVER);
							}
						}
						else {
							BuildSubMenu(client, OpenedMenu[client], MenuSelection[client]);
						}
					}
					else {

						BuildSubMenu(client, OpenedMenu[client], MenuSelection[client]);
					}
				}
				case 2: {

					BuildSubMenu(client, OpenedMenu[client], MenuSelection[client]);
				}
			}
		}
	}
	if (action == MenuAction_End)
	{
		CloseHandle(topmenu);
	}
	/*else if (topmenu != INVALID_HANDLE)
	{
		CloseHandle(topmenu);
	}*/
}

public TalentInfoScreen_Special_Init (Handle:topmenu, MenuAction:action, client, param2)
{
	if (action == MenuAction_Select)
	{
		new ActionBarSize = GetArraySize(Handle:ActionBar[client]);

		if (param2 > ActionBarSize) {

			BuildSubMenu(client, OpenedMenu[client], MenuSelection[client]);
		}
		else {
			//																	Abilities now require an upgrade point in their node in order to be used.
			if (!SwapActions(client, PurchaseTalentName[client], param2 - 1) && GetTalentStrength(client, PurchaseTalentName[client]) > 0) SetArrayString(Handle:ActionBar[client], param2 - 1, PurchaseTalentName[client]);
			SendPanelToClientAndClose(TalentInfoScreen_Special(client), client, TalentInfoScreen_Special_Init, MENU_TIME_FOREVER);
		}
		//CloseHandle(topmenu);
	}
	if (action == MenuAction_End) {

		CloseHandle(topmenu);
	}
}

bool:SwapActions(client, String:TalentName[], slot) {

	decl String:text[64], String:text2[64];

	new size = GetArraySize(ActionBar[client]);
	for (new i = 0; i < size; i++) {

		GetArrayString(Handle:ActionBar[client], i, text, sizeof(text));
		if (StrEqual(TalentName, text)) {

			GetArrayString(Handle:ActionBar[client], slot, text2, sizeof(text2));

			SetArrayString(Handle:ActionBar[client], i, text2);
			SetArrayString(Handle:ActionBar[client], slot, text);

			return true;
		}
	}
	return false;
}

stock TryToTellPeopleYouUpgraded(client) {

	if (FreeUpgrades[client] == 0 && GetConfigValueInt("display when players upgrade to team?") == 1) {

		decl String:text2[64];
		decl String:PlayerName[64];
		decl String:translationText[64];
		GetClientName(client, PlayerName, sizeof(PlayerName));
		GetTranslationOfTalentName(client, PurchaseTalentName[client], translationText, sizeof(translationText), true);
		for (new k = 1; k <= MaxClients; k++) {

			if (IsLegitimateClient(k) && !IsFakeClient(k) && GetClientTeam(k) == GetClientTeam(client)) {

				Format(text2, sizeof(text2), "%T", translationText, k);
				if (GetClientTeam(client) == TEAM_SURVIVOR) PrintToChat(k, "%T", "Player upgrades ability", k, blue, PlayerName, white, green, text2, white);
				else if (GetClientTeam(client) == TEAM_INFECTED) PrintToChat(k, "%T", "Player upgrades ability", k, orange, PlayerName, white, green, text2, white);
			}
		}
	}
}

stock FindTalentPoints(client, String:Name[]) {

	decl String:text[64];

	new a_Size							=	GetArraySize(a_Database_Talents);

	for (new i = 0; i < a_Size; i++) {

		GetArrayString(Handle:a_Database_Talents, i, text, sizeof(text));

		if (StrEqual(text, Name)) {

			if (client != -1) GetArrayString(Handle:a_Database_PlayerTalents[client], i, text, sizeof(text));
			else GetArrayString(Handle:a_Database_PlayerTalents_Bots, i, text, sizeof(text));
			return StringToInt(text);
		}
	}
	//return -1;	// this is to let us know to setfailstate.
	return 0;	// this will be removed. only for testing.
}

stock AddTalentPoints(client, String:Name[], TalentPoints) {

	if (!IsLegitimateClient(client)) return;
	
	decl String:text[64];
	new a_Size							=	GetArraySize(a_Database_Talents);

	for (new i = 0; i < a_Size; i++) {

		GetArrayString(Handle:a_Database_Talents, i, text, sizeof(text));

		if (StrEqual(text, Name)) {

			SetArrayCell(a_Database_PlayerTalents[client], i, TalentPoints);
			return;
		}
	}
}

stock UnlockTalent(client, String:Name[], bool:bIsEndOfMapRoll = false, bool:bIsLegacy = false) {

	decl String:text[64];
	decl String:PlayerName[64];
	GetClientName(client, PlayerName, sizeof(PlayerName));

	new size			= GetArraySize(a_Database_Talents);

	for (new i = 0; i < size; i++) {

		GetArrayString(Handle:a_Database_Talents, i, text, sizeof(text));
		if (StrEqual(text, Name)) {

			SetArrayCell(a_Database_PlayerTalents[client], i, 0);

			if (!bIsLegacy) {		// We advertise elsewhere if it's a legacy roll.

				for (new ii = 1; ii <= MaxClients; ii++) {

					if (IsClientInGame(ii) && !IsFakeClient(ii)) {

						Format(text, sizeof(text), "%T", Name, ii);
						if (!bIsEndOfMapRoll) PrintToChat(ii, "%T", "Locked Talent Award", ii, blue, PlayerName, white, orange, text, white);
						else PrintToChat(ii, "%T", "Locked Talent Award (end of map roll)", ii, blue, PlayerName, white, orange, text, white, white, orange, white);
					}
				}
			}
			break;
		}
	}
}

stock bool:IsTalentExists(String:Name[]) {

	decl String:text[64];
	new size			= GetArraySize(a_Database_Talents);
	for (new i = 0; i < size; i++) {

		GetArrayString(Handle:a_Database_Talents, i, text, sizeof(text));
		if (StrEqual(text, Name)) return true;
	}
	return false;
}

stock bool:IsTalentLocked(client, String:Name[]) {

	new value = 0;
	decl String:text[64];

	new size			= GetArraySize(a_Database_Talents);

	for (new i = 0; i < size; i++) {

		GetArrayString(Handle:a_Database_Talents, i, text, sizeof(text));
		if (StrEqual(text, Name)) {

			value = GetArrayCell(a_Database_PlayerTalents[client], i);

			if (value >= 0) return false;
			break;
		}
	}

	return true;
}

stock WipeTalentPoints(client) {

	if (!IsLegitimateClient(client) || IsFakeClient(client)) return;

	UpgradesAwarded[client] = 0;

	new size							= GetArraySize(a_Menu_Talents);

	new value = 0;

	for (new i = 0; i < size; i++) {	// We only reset talents a player has points in, so locked talents don't become unlocked.

		TalentTreeKeys[client]			= GetArrayCell(a_Menu_Talents, i, 0);
		TalentTreeValues[client]		= GetArrayCell(a_Menu_Talents, i, 1);
		if (GetKeyValueInt(TalentTreeKeys[client], TalentTreeValues[client], "talent type?") == 1) continue;	// we don't wipe attributes.
		if (GetKeyValueInt(TalentTreeKeys[client], TalentTreeValues[client], "is survivor class role?") == 1) continue;		// we don't wipe classes

		value = GetArrayCell(a_Database_PlayerTalents[client], i);
		if (value > 0)	SetArrayCell(a_Database_PlayerTalents[client], i, 0);
	}
}