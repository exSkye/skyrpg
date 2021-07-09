stock BuildMenuTitle(client, Handle:menu, bot = 0, type = 0, bool:bIsPanel = false) {	// 0 is legacy type that appeared on all menus. 0 - Main Menu | 1 - Upgrades | 2 - Points

	decl String:text[512];
	new CurRPGMode = GetConfigValueInt("rpg mode?");

	if (bot == 0) {

		decl String:PointsText[64];
		Format(PointsText, sizeof(PointsText), "%T", "Points Text", client, Points[client]);

		new CheckRPGMode = GetConfigValueInt("rpg mode?");
		if (CheckRPGMode > 0) {

			decl String:TheClass[128];
			if (IsLegitimateClass(client)) Format(TheClass, sizeof(TheClass), "%T", ActiveClass[client], client);
			else Format(TheClass, sizeof(TheClass), "%T", "none", client);

			decl String:PlayerLevelText[256];
			Format(PlayerLevelText, sizeof(PlayerLevelText), "%T", "Player Level Text", client, PlayerLevel[client], AddCommasToString(ExperienceLevel[client]), MenuExperienceBar(client), AddCommasToString(CheckExperienceRequirement(client)));
			Format(text, sizeof(text), "%T", "Class Level Text", client, TheClass, AddCommasToString(CartelLevel(client)), AddCommasToString(Rating[client]));
			Format(PlayerLevelText, sizeof(PlayerLevelText), "%s\nR%s\nTruR%s", PlayerLevelText, AddCommasToString(Rating[client]), AddCommasToString(TruRating(client)));
			Format(PlayerLevelText, sizeof(PlayerLevelText), "%s\nClass: %s Lv.%s", PlayerLevelText, TheClass, AddCommasToString(CartelLevel(client)));

			if (CheckRPGMode != 0) Format(text, sizeof(text), "%T", "RPG Header", client, PlayerLevelText, UpgradesAvailable[client]);
			if (CheckRPGMode != 1) Format(text, sizeof(text), "%s\n%s", text, PointsText);

			decl String:text2[512];
			if (FreeUpgrades[client] > 0) {

				Format(text2, sizeof(text2), "%T", "Free Upgrades", client);
				Format(text, sizeof(text), "%s\n%s: %d", text, text2, FreeUpgrades[client]);
			}

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
			Format(text, sizeof(text), "%T", "Menu Header 1 Talents Bot", client, PlayerLevel_Bots, GetConfigValueInt("max level?"), AddCommasToString(ExperienceLevel_Bots), AddCommasToString(CheckExperienceRequirement(-1, true)), AddCommasToString(GetUpgradeExperienceCost(-1)));
		}
		else if (CurRPGMode == 2) {

			Format(text, sizeof(text), "%T", "Menu Header 2 Talents Bot", client, PlayerLevel_Bots, GetConfigValueInt("max level?"), AddCommasToString(ExperienceLevel_Bots), AddCommasToString(CheckExperienceRequirement(-1, true)), AddCommasToString(GetUpgradeExperienceCost(-1)), Points_Director);
		}
	}
	ReplaceString(text, sizeof(text), "PCT", "%%", true);
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

		if (IsLegitimateClass(client)) {

			Format(ProfileLoadQueue[client], sizeof(ProfileLoadQueue[]), "%s", key);
			SaveClassData(client);
		}
		else LoadProfileEx_Confirm(client, key);
	}
	/*else if (IsLegitimateClient(LoadTarget[client]) && client != LoadTarget[client]) {

		decl String:LoadName[64];
		GetClientName(LoadTarget[client], LoadName, sizeof(LoadName));

		PrintToChat(client, "%T", "sending profile request", client, orange, green, LoadName);
		LoadProfileEx_Request(client, LoadTarget[client], key);
	}*/
	/*else {

		PrintToChat(client, "%T", "cannot load in combat", client, orange);
	}*/
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
	PrintToChat(client, "%T", "loading profile", client, orange, green, key);

	Format(tquery, sizeof(tquery), "SELECT `steam_id`, `total upgrades` FROM `%s` WHERE (`steam_id` = '%s');", TheDBPrefix, key);
	// maybe set a value equal to the users steamid integer only, so if steam:0:1:23456, set the value of "client" equal to 23456 and then set the client equal to whatever client's steamid contains 23456?
	//LogMessage("Loading %N data: %s", client, tquery);
	SQL_TQuery(hDatabase, QueryResults_LoadEx, tquery, client);
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

		while (SQL_FetchRow(hndl))
		{
			SQL_FetchString(hndl, 0, key, sizeof(key));
			if (LoadTarget[owner] != owner && LoadTarget[owner] != -1 && (IsSurvivorBot(LoadTarget[owner]) || IsLegitimateClient(LoadTarget[owner]) && GetClientTeam(LoadTarget[owner]) != TEAM_INFECTED)) client = LoadTarget[owner];
			// check if the client is overriden by LoadProfileRequestName[client]
			//client = CheckLoadProfileRequest(owner);
			//if (LoadTarget[owner] != client) LoadTarget[owner] = client;

			if (!IsLegitimateClient(client)) return;

			ExplodeString(key, "+", result, 3, 64);
			if (!StrEqual(result[1], LoadoutName[owner], false)) Format(LoadoutName[client], sizeof(LoadoutName[]), "%s", result[1]);
			PushArrayString(TempAttributes[client], key);
			PushArrayCell(TempAttributes[client], SQL_FetchInt(hndl, 1));

			PlayerUpgradesTotal[client]	= SQL_FetchInt(hndl, 1);
			/*UpgradesAvailable[client]	= 0;
			FreeUpgrades[client] = (PlayerLevel[client] - 1) - PlayerUpgradesTotal[client];
			if (FreeUpgrades[client] < 0) FreeUpgrades[client] = 0;
			PurchaseTalentPoints[client] = PlayerUpgradesTotal[client];*/
		}
		decl String:tquery[512];
		//decl String:key[64];
		//GetClientAuthString(client, key, sizeof(key));

		LoadPos[client] = 0;

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

		if (!IsLegitimateClient(client)) return;

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
						GetKeyValueInt(TalentTreeKeys[client], TalentTreeValues[client], "is ability?") == 1) {

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

					Format(tquery, sizeof(tquery), "SELECT `steam_id`, `aclass` FROM `%s` WHERE (`steam_id` = '%s');", TheDBPrefix, key);
					SQL_TQuery(hDatabase, QueryResults_LoadTalentTreesEx, tquery, client);
					return;
				}
			}
			else {

				SQL_FetchString(hndl, 1, ActiveClass[client], sizeof(ActiveClass[]));
				GetClientAuthString(client, key, sizeof(key));	// this is necessary, because they might still be in the process of loading another users data. this is a backstop in-case the loader has switched targets mid-load. this is why we don't first check the value of LoadProfileRequestName[client].
				LoadTalentTrees(client, key, true);
			}
			new TalentMaximum				=	0;
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
				if (GetKeyValueInt(MenuKeys[client], MenuValues[client], "is ability?") == 1) continue;

				GetArrayString(Handle:MenuSection[client], 0, TalentName, sizeof(TalentName));

				TalentMaximum = GetKeyValueInt(MenuKeys[client], MenuValues[client], "maximum talent points allowed?");

				PlayerTalentPoints = GetTalentStrength(client, TalentName);
				if (PlayerTalentPoints > TalentMaximum) {

					FreeUpgrades[client] += (PlayerTalentPoints - TalentMaximum);
					PlayerUpgradesTotal[client] -= (PlayerTalentPoints - TalentMaximum);
					AddTalentPoints(client, TalentName, (PlayerTalentPoints - TalentMaximum));
				}
			}
		}
		if (IsSurvivorBot(client) && (PlayerLevel[client] < GetConfigValueInt("new player starting level?") || !IsLegitimateClass(client))) {

			CreateNewPlayerEx(client);
			return;
		}
		else {

			decl String:Name[64];
			if (GetConfigValueInt("rpg mode?") >= 1) {

				SetMaximumHealth(client);
				GiveMaximumHealth(client);
				ProfileEditorMenu(client);
				GetClientName(client, Name, sizeof(Name));
				PrintToChatAll("%t", "loaded profile", blue, Name, white, green, LoadoutName[client]);
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
	if (action == MenuAction_End) {

		CloseHandle(menu);
	}
}

stock LoadProfileTargetSurvivorBot(client) {

	new Handle:menu = CreateMenu(TargetSurvivorBotMenuHandle);
	ClearArray(Handle:RPGMenuPosition[client]);

	decl String:text[512];
	decl String:pos[512];

	decl String:theclassname[64];

	Format(text, sizeof(text), "%T", "select survivor bot", client);
	SetMenuTitle(menu, text);
	for (new i = 1; i <= MaxClients; i++) {

		if (IsLegitimateClient(i) && GetClientTeam(i) != TEAM_INFECTED) {

			Format(pos, sizeof(pos), "%d", i);
			PushArrayString(Handle:RPGMenuPosition[client], pos);
			GetClientName(i, pos, sizeof(pos));

			if (!StrEqual(ActiveClass[i], "none", false) && strlen(ActiveClass[i]) > 3) {

				Format(theclassname, sizeof(theclassname), "%T", ActiveClass[i], client);
				Format(pos, sizeof(pos), "%s [Rtg %d] Lv.%d %s", theclassname, Rating[i], PlayerLevel[i], pos);
			}
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
		if (StringToInt(text) < GetArraySize(PlayerProfiles[client])) {

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
	new ActionSlots = GetConfigValueInt("action bar slots?");
	if (GetArraySize(Handle:ActionBar[client]) != ActionSlots) ResizeArray(Handle:ActionBar[client], ActionSlots);

	// If the user doesn't meet the requirements or have the item it'll be unequipped here

	decl String:talentname[64];

	new size = GetConfigValueInt("action bar slots?");
	for (new i = 0; i < size; i++) {

		GetArrayString(Handle:ActionBar[client], i, talentname, sizeof(talentname));
		VerifyActionBar(client, talentname, i);
	}
}

stock ShowActionBar(client) {

	new Handle:menu = CreateMenu(ActionBarHandle);

	decl String:text[128], String:talentname[64];
	Format(text, sizeof(text), "Stamina: %d (Max: %d)", SurvivorStamina[client], GetPlayerStamina(client));
	SetMenuTitle(menu, text);
	new size = GetConfigValueInt("action bar slots?");
	new Float:AmmoCooldownTime = -1.0, Float:fAmmoCooldownTime = -1.0, Float:fAmmoCooldown = 0.0;

	decl String:acmd[10];
	GetConfigValue(acmd, sizeof(acmd), "action slot command?");
	new TalentStrength = 0;
	new bool:IsTalentExists_b = false;

	//decl String:TheValue[64];
	new bool:bIsAbility = false;
	new ManaCost = 0;
	new baseWeaponDamage = DataScreenWeaponDamage(client);
	new Float:TheAbilityMultiplier = 0.0;
	for (new i = 0; i < size; i++) {

		IsTalentExists_b = false;

		GetArrayString(Handle:ActionBar[client], i, talentname, sizeof(talentname));
		if (VerifyActionBar(client, talentname, i)) {

			// doesn't exist, or user has removed it.
			TalentStrength = GetTalentStrength(client, talentname);
		}

		if (TalentStrength > 0) {

			AmmoCooldownTime = GetAmmoCooldownTime(client, talentname);
			Format(text, sizeof(text), "%T", talentname, client);
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

				TheAbilityMultiplier = GetAbilityMultiplier(client, '0', _, talentname);
				baseWeaponDamage = RoundToCeil(baseWeaponDamage * TheAbilityMultiplier);

				Format(text, sizeof(text), "%s\nDamage: %d", text, baseWeaponDamage);
			}

			if (bIsAbility) {

				AmmoCooldownTime = GetAmmoCooldownTime(client, talentname, true);
				//PrintToChat(client, "%s %3.3f", talentname, AmmoCooldownTime);
			}
			else {

				AmmoCooldownTime = GetAmmoCooldownTime(client, talentname);
				fAmmoCooldownTime = AmmoCooldownTime;
				if (AmmoCooldownTime != -1.0) {

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
			// following broke; if it's not an ability it has to both be over 0.0 AND not be -1.0 , will do later (NOT DONE)
			if (bIsAbility && AmmoCooldownTime != -1.0 || !bIsAbility && (AmmoCooldownTime > 0.0 || AmmoCooldownTime == -1.0)) Format(text, sizeof(text), "%s\nActive: %3.2fs", text, AmmoCooldownTime);

			if (!bIsAbility) AmmoCooldownTime = fAmmoCooldownTime;
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

stock Float:CheckActiveAbility(client, thevalue, eventtype = 0, bool:IsPassive = false) {

	// we try to match up the eventtype with any ACTIVE talents on the action bar.
	// it is REALLY super simple, we have functions for everything. everythingggggg
	// get the size of the action bars first.
	new ActionBarSize = GetConfigValueInt("action bar slots?");	// having your own extensive api really helps.
	decl String:text[64], String:Effects[64], String:none[64];	// free guesses on what this one is for.
	Format(none, sizeof(none), "none");	// you guessed it.
	new pos = -1;
	new bool:IsMultiplier = false;
	new Float:MyMultiplier = 1.0;
	if (StrContains(ActiveClass[client], "adventurer", false) != -1) IsMultiplier = true;
	//new MyAttacker = L4D2_GetInfectedAttacker(client);

	for (new i = 0; i < ActionBarSize; i++) {

		GetArrayString(Handle:ActionBar[client], i, text, sizeof(text));
		if (!VerifyActionBar(client, text, i)) continue;	// not a real talent or has no points in it.
		if (!IsAbilityActive(client, text)) continue;

		pos = GetMenuPosition(client, text);
		if (pos < 0) continue;

		CheckAbilityKeys[client]		= GetArrayCell(a_Menu_Talents, pos, 0);
		CheckAbilityValues[client]		= GetArrayCell(a_Menu_Talents, pos, 1);

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
	//PrintToChatAll("Menu name: %s", MenuName);


	// Format(LastOpenedMenu[client], sizeof(LastOpenedMenu[]), "%s", MenuName);
	//VerifyUpgradeExperienceCost(client);
	VerifyMaxPlayerUpgrades(client);
	ClearArray(RPGMenuPosition[client]);

	// Build the base menu
	new Handle:menu		= CreateMenu(BuildMenuHandle);
	// Keep track of the position selected.
	decl String:pos[64];

	if (!b_IsDirectorTalents[client]) BuildMenuTitle(client, menu, _, 0);
	else BuildMenuTitle(client, menu, 1);

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
	new CurRPGMode = GetConfigValueInt("rpg mode?");
	//new ActionBarOption = -1;

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
		if (CurRPGMode == 1 && StrEqual(configname, CONFIG_POINTS)) continue;
		if (GetArraySize(a_Store) < 1 && StrEqual(configname, CONFIG_STORE)) continue;
		//if (StrEqual(configname, "respec", false) && bIsInCombat[client] && b_IsActiveRound) continue;

		// If director talent menu options is enabled by an admin, only specific options should show. We determine this here.
		if (b_IsDirectorTalents[client]) {

			if (StrEqual(configname, CONFIG_MENUTALENTS) || StrEqual(configname, CONFIG_POINTS) || b_IsDirectorTalents[client] && StrEqual(configname, "level up") || StrEqual(MenuName, c_MenuName, false)) {

				Format(pos, sizeof(pos), "%d", i);
				PushArrayString(Handle:RPGMenuPosition[client], pos);
			}
			else continue;
		}
		if (StrEqual(configname, "level up")) {

			//if (!b_IsDirectorTalents[client]) {

			if (PlayerUpgradesTotal[client] < MaximumPlayerUpgrades(client)) continue; //Format(text, sizeof(text), "%T", "level up unavailable", client, MaximumPlayerUpgrades(client) - PlayerUpgradesTotal[client]);
			else Format(text, sizeof(text), "%T", "level up available", client, AddCommasToString(CheckExperienceRequirement(client)));
			/*}
			else {

				if (PlayerLevelUpgrades_Bots < MaxUpgradesPerLevel()) Format(text, sizeof(text), "%T", "level up unavailable", client, MaxUpgradesPerLevel() - PlayerLevelUpgrades_Bots);
				else Format(text, sizeof(text), "%T", "level up available", client, AddCommasToString(CheckExperienceRequirement(-1)));
			}*/
		}
		else {

			GetArrayString(Handle:MenuSection[client], 0, text, sizeof(text));
			Format(text, sizeof(text), "%T", text, client);
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

		AddMenuItem(menu, text, text);
	}
	if (!StrEqual(MenuName, "main", false)) SetMenuExitBackButton(menu, true);
	else SetMenuExitBackButton(menu, false);
	DisplayMenu(menu, client, 0);
}

public BuildMenuHandle(Handle:menu, MenuAction:action, client, slot) {

	if (action == MenuAction_Select) {

		// Declare variables for target config, menu name (some submenu's require this information) and the ACTUAL position for a slot
		// (as pos won't always line up with slot since items can be hidden under special circumstances.)
		decl String:config[64];
		decl String:menuname[64];
		decl String:pos[4];

		decl String:t_MenuName[64];
		decl String:c_MenuName[64];

		// Get the real position to use based on the slot that was pressed.
		// This position was stored above in the accompanying menu function.
		GetArrayString(Handle:RPGMenuPosition[client], slot, pos, sizeof(pos));
		MenuKeys[client]			= GetArrayCell(a_Menu_Main, StringToInt(pos), 0);
		MenuValues[client]			= GetArrayCell(a_Menu_Main, StringToInt(pos), 1);
		MenuSection[client]			= GetArrayCell(a_Menu_Main, StringToInt(pos), 2);
		GetArrayString(Handle:MenuSection[client], 0, menuname, sizeof(menuname));

		// We want to know the value of the target config based on the keys and values pulled.
		// This will be used to determine where we send the player.
		FormatKeyValue(config, sizeof(config), MenuKeys[client], MenuValues[client], "config?");
		FormatKeyValue(t_MenuName, sizeof(t_MenuName), MenuKeys[client], MenuValues[client], "target menu?");
		FormatKeyValue(c_MenuName, sizeof(c_MenuName), MenuKeys[client], MenuValues[client], "menu name?");

		AddMenuStructure(client, c_MenuName);

		// I've set it to not require case-sensitivity in case some moron decides to get cute.
		if (!StrEqual(t_MenuName, "-1", false)) {

			//PrintToChatAll("Trying to open %s", t_MenuName);
			BuildMenu(client, t_MenuName);
		}
		else if (StrEqual(config, "level up", false)) {

			//if (!b_IsDirectorTalents[client]) ExperienceBuyLevel(client, true);
			BuildMenu(client);
		}
		else if (StrEqual(config, "profileeditor", false)) {

			ProfileEditorMenu(client);
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
			if (!StrEqual(t_MenuName, "-1", false)) BuildSubMenu(client, menuname, config, t_MenuName);
			else BuildSubMenu(client, menuname, config, c_MenuName);
			//PrintToChat(client, "buidling a sub menu. %s", t_MenuName);
		}
		else if (StrEqual(config, CONFIG_POINTS)) {

			// A much safer method for grabbing the current config value for the MenuSelection.
			Format(MenuSelection[client], sizeof(MenuSelection[]), "%s", config);
			BuildPointsMenu(client, menuname, config);
		}
		else if (StrEqual(config, "inventory", false)) {

			LoadInventory(client);
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

	new PTL = RoundToFloor((((PlayerUpgradesTotal[client] * 1.0) + FreeUpgrades[client]) / (MaxUpgradesPerLevel() * PlayerLevel[client])) * PlayerLevel[client]);
	if (PTL < 0) PTL = 0;

	return PTL;
	//return PlayerLevel[client];
}

stock Float:PlayerBuffLevel(client) {

	new Float:PBL = ((PlayerUpgradesTotal[client] * 1.0) + FreeUpgrades[client]) / (MaxUpgradesPerLevel() * PlayerLevel[client]);
	PBL = 1.0 - PBL;
	//PBL = PBL * 100.0;
	if (PBL < 0.0) PBL = 0.0; // This can happen if a player uses free upgrades, so, yeah...
	return PBL;
}

stock MaxUpgradesPerLevel() {

	return RoundToFloor(1.0 / GetConfigValueFloat("upgrade experience cost?"));
}

stock MaximumPlayerUpgrades(client) {

	if (GetConfigValueFloat("upgrade experience cost?") < 1.0) return MaxUpgradesPerLevel() * PlayerLevel[client];
	else return MaxUpgradesPerLevel() * (PlayerLevel[client] - 1);
}

stock VerifyMaxPlayerUpgrades(client) {

	if (PlayerUpgradesTotal[client] + FreeUpgrades[client] > MaximumPlayerUpgrades(client)) {

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

public Handle:ProfileEditorMenu(client) {

	new Handle:menu		= CreateMenu(ProfileEditorMenuHandle);

	decl String:text[64];
	Format(text, sizeof(text), "%T", "profile editor title", client, LoadoutName[client]);
	SetMenuTitle(menu, text);

	Format(text, sizeof(text), "%T", "Save Profile", client);
	AddMenuItem(menu, text, text);
	Format(text, sizeof(text), "%T", "Load Profile", client);
	AddMenuItem(menu, text, text);

	decl String:TheName[64];
	new thetarget = LoadProfileRequestName[client];
	if (thetarget == -1 || thetarget == client || !IsLegitimateClient(thetarget) || GetClientTeam(thetarget) != TEAM_SURVIVOR) thetarget = LoadTarget[client];
	if (IsSurvivorBot(thetarget) ||
		IsLegitimateClient(thetarget) && GetClientTeam(thetarget) != TEAM_INFECTED && thetarget != client) {

		decl String:theclassname[64];
		GetClientName(thetarget, TheName, sizeof(TheName));
		if (!StrEqual(ActiveClass[thetarget], "none", false) && strlen(ActiveClass[thetarget]) > 3) {

			Format(theclassname, sizeof(theclassname), "%T", ActiveClass[thetarget], client);
			Format(TheName, sizeof(TheName), "%s [Rtg %d] Lv.%d %s", theclassname, Rating[thetarget], PlayerLevel[thetarget], TheName);
		}
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

	decl String:tquery[512];
	decl String:t_Loadout[64];
	GetClientAuthString(client, t_Loadout, sizeof(t_Loadout));
	Format(t_Loadout, sizeof(t_Loadout), "%s+%s", t_Loadout, LoadoutName[client]);
	Format(tquery, sizeof(tquery), "DELETE FROM `%s` WHERE `steam_id` = '%s+SavedProfile%s';", TheDBPrefix, t_Loadout, PROFILE_VERSION);
	//PrintToChat(client, tquery);
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

			//ReadProfiles(client, "all");
			LoadProfileTargetSurvivorBot(client);
		}
		if (slot == 3) {

			DeleteProfile(client);
			ReadProfiles(client);
		}
		if (slot == 4) {

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
	new talentlevel = 0;
	new size = GetArraySize(a_Database_Talents);
	if (SaveType == 1) {

		//	A save doesn't exist for this steamid so we create one before saving anything.
		Format(tquery, sizeof(tquery), "INSERT INTO `%s` (`steam_id`) VALUES ('%s');", TheDBPrefix, key);
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
	Format(tquery, sizeof(tquery), "UPDATE `%s` SET `total upgrades` = '%d' WHERE `steam_id` = '%s';", TheDBPrefix, (PlayerLevel[client] - 1) - UpgradesAvailable[client] - FreeUpgrades[client], key);
	//LogMessage(tquery);
	SQL_TQuery(hDatabase, QueryResults, tquery, client);

	for (new i = 0; i < size; i++) {

		GetArrayString(a_Database_Talents, i, text, sizeof(text));
		TalentTreeKeys[client]			= GetArrayCell(a_Menu_Talents, i, 0);
		TalentTreeValues[client]		= GetArrayCell(a_Menu_Talents, i, 1);

		if (GetKeyValueInt(TalentTreeKeys[client], TalentTreeValues[client], "talent type?") == 1) continue;	// we don't save class attributes.
		if (GetKeyValueInt(TalentTreeKeys[client], TalentTreeValues[client], "is survivor class role?") == 1) continue;
		if (GetKeyValueInt(TalentTreeKeys[client], TalentTreeValues[client], "is sub menu?") == 1) continue;
		if (GetKeyValueInt(TalentTreeKeys[client], TalentTreeValues[client], "is ability?") == 1) continue;

		talentlevel = GetArrayCell(a_Database_PlayerTalents[client], i);// GetArrayString(a_Database_PlayerTalents[client], i, text2, sizeof(text2));
		Format(tquery, sizeof(tquery), "UPDATE `%s` SET `%s` = '%d' WHERE `steam_id` = '%s';", TheDBPrefix, text, talentlevel, key);
		SQL_TQuery(hDatabase, QueryResults, tquery, client);
	}
	Format(tquery, sizeof(tquery), "UPDATE `%s` SET `aclass` = '%s' WHERE `steam_id` = '%s';", TheDBPrefix, ActiveClass[client], key);
	SQL_TQuery(hDatabase, QueryResults, tquery, client);
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

	if (!StrEqual(target, "all", false)) Format(tquery, sizeof(tquery), "SELECT `steam_id` FROM `%s` WHERE `steam_id` LIKE '%s%s' AND `total upgrades` <= '%d';", TheDBPrefix, key, pct, (PlayerLevel[client] - 1));
	else Format(tquery, sizeof(tquery), "SELECT `steam_id` FROM `%s` WHERE `steam_id` LIKE '%s+SavedProfile%s' AND `total upgrades` <= '%d';", TheDBPrefix, pct, PROFILE_VERSION, (PlayerLevel[client] - 1));
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

	//PrintToChat(client, "loading");

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

			BuildMenuTitle(client, menu, _, 1);
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



	new TalentMaximum				=	0;
	new TalentLevelRequired			=	0;
	new PlayerTalentPoints			=	0;

	new AbilityInherited			=	0;
	new StorePurchaseCost			=	0;
	new ClassRole					=	0;
	new AbilityTalent				=	0;

	Format(pct, sizeof(pct), "%");

	new size						=	GetArraySize(a_Menu_Talents);

	//if (StrEqual(ConfigName, CONFIG_MENUSURVIVOR)) size			=	GetArraySize(a_Menu_Talents_Survivor);
	//else if (StrEqual(ConfigName, CONFIG_MENUINFECTED)) size	=	GetArraySize(a_Menu_Talents_Infected);

	for (new i = 0; i < size; i++) {

		MenuKeys[client]			= GetArrayCell(a_Menu_Talents, i, 0);
		MenuValues[client]			= GetArrayCell(a_Menu_Talents, i, 1);
		MenuSection[client]			= GetArrayCell(a_Menu_Talents, i, 2);

		GetArrayString(Handle:MenuSection[client], 0, TalentName, sizeof(TalentName));

		if (!TalentListingFound(client, MenuKeys[client], MenuValues[client], MenuName)) continue;

		isSubMenu = GetKeyValueInt(MenuKeys[client], MenuValues[client], "is sub menu?");
		TalentLevelRequired = GetKeyValueInt(MenuKeys[client], MenuValues[client], "minimum level required?");

		if (isSubMenu == 1) {

			// We strictly show the menu option.
			Format(TalentName_Temp, sizeof(TalentName_Temp), "%T", TalentName, client);
			if (PlayerLevel[client] < TalentLevelRequired) Format(text, sizeof(text), "%T", "Submenu Locked", client, TalentName_Temp, TalentLevelRequired);
			else Format(text, sizeof(text), "%T", "Submenu Available", client, TalentName_Temp);
		}
		else {

			ClassRole		=	GetKeyValueInt(MenuKeys[client], MenuValues[client], "is survivor class role?");
			AbilityTalent	=	GetKeyValueInt(MenuKeys[client], MenuValues[client], "is ability?");

			if (ClassRole != 1 && isSubMenu != 1 && AbilityTalent != 1) {

				//if (ActionBarSlot[client] != -1 && GetTalentStrength(client, TalentName) < 1) continue;	// we don't display items that the user has no talent points in.
				//if (GetTalentStrength(client, TalentName) < 1) continue;	// we don't display talents to players if they have no talent points in them (from gear)
			}

			TalentMaximum = GetKeyValueInt(MenuKeys[client], MenuValues[client], "maximum talent points allowed?");
			StorePurchaseCost = GetKeyValueInt(MenuKeys[client], MenuValues[client], "store purchase cost?");
			AbilityInherited = GetKeyValueInt(MenuKeys[client], MenuValues[client], "ability inherited?");

			if (ClassRole == 1 || AbilityTalent == 1) {

				PlayerTalentPoints = 0;
				TalentMaximum = 0;
			}
			else {

				if (!b_IsDirectorTalents[client]) {

					PlayerTalentPoints = GetTalentStrength(client, TalentName);
					if (PlayerTalentPoints > TalentMaximum) {

						/*

							The player was on a server with different talent settings; specifically,
							it's clear some talents allowed greater values. Since this server doesn't,
							we set them to the maximum, refund the extra points.
						*/
						FreeUpgrades[client] += (PlayerTalentPoints - TalentMaximum);
						PlayerUpgradesTotal[client] -= (PlayerTalentPoints - TalentMaximum);
						AddTalentPoints(client, TalentName, (PlayerTalentPoints - TalentMaximum));
					}
				}
				else PlayerTalentPoints = GetTalentStrength(-1, TalentName);
			}

			Format(TalentName_Temp, sizeof(TalentName_Temp), "%T", TalentName, client);

			if (ClassRole != 1 && AbilityTalent != 1) {

				if (AbilityInherited == 0 && PlayerTalentPoints < 0) Format(text, sizeof(text), "%T", "Ability Locked", client, TalentName_Temp, StorePurchaseCost);
				else if (PlayerLevel[client] < TalentLevelRequired) Format(text, sizeof(text), "%T", "Ability Restricted", client, TalentName_Temp, TalentLevelRequired);
				else {

					if (GetKeyValueInt(MenuKeys[client], MenuValues[client], "talent type?") <= 0) Format(text, sizeof(text), "%T", "Ability Available", client, TalentName_Temp, PlayerTalentPoints, TalentMaximum);
					else Format(text, sizeof(text), "%T", "Ability Available T1", client, TalentName_Temp, PlayerTalentPoints, TalentMaximum);
				}
			}
			else {

				if (PlayerLevel[client] < TalentLevelRequired) Format(text, sizeof(text), "%T", "Ability Restricted", client, TalentName_Temp, TalentLevelRequired);
				else Format(text, sizeof(text), "%s", TalentName_Temp);
			}
		}

		AddMenuItem(menu, text, text);
	}

	SetMenuExitBackButton(menu, true);
	DisplayMenu(menu, client, 0);
}

stock bool:TalentListingFound(client, Handle:Keys, Handle:Values, String:MenuName[]) {

	new size = GetArraySize(Keys);

	decl String:key[64];
	decl String:value[64];

	for (new i = 0; i < size; i++) {

		GetArrayString(Handle:Keys, i, key, sizeof(key));
		if (StrEqual(key, "part of menu named?")) {

			GetArrayString(Handle:Values, i, value, sizeof(value));
			if (!StrEqual(MenuName, value)) return false;
		}
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

		new StorePurchaseCost			=	0;
		decl String:SurvEffects[64];
		Format(SurvEffects, sizeof(SurvEffects), "0");

		Format(pct, sizeof(pct), "%");

		new ClassRole = 0;

		new size						=	GetArraySize(a_Menu_Talents);
		new TalentLevelRequired			= 0;
		new AbilityTalent				= 0;

		//if (StrEqual(ConfigName, CONFIG_MENUSURVIVOR)) size			=	GetArraySize(a_Menu_Talents_Survivor);
		//else if (StrEqual(ConfigName, CONFIG_MENUINFECTED)) size	=	GetArraySize(a_Menu_Talents_Infected);

		for (new i = 0; i < size; i++) {

			MenuKeys[client]				= GetArrayCell(a_Menu_Talents, i, 0);
			MenuValues[client]				= GetArrayCell(a_Menu_Talents, i, 1);
			MenuSection[client]				= GetArrayCell(a_Menu_Talents, i, 2);

			GetArrayString(Handle:MenuSection[client], 0, TalentName, sizeof(TalentName));
			if (!TalentListingFound(client, MenuKeys[client], MenuValues[client], MenuName)) continue;

			isSubMenu = GetKeyValueInt(MenuKeys[client], MenuValues[client], "is sub menu?");
			TalentLevelRequired = GetKeyValueInt(MenuKeys[client], MenuValues[client], "minimum level required?");

			ClassRole		=	GetKeyValueInt(MenuKeys[client], MenuValues[client], "is survivor class role?");
			AbilityTalent	=	GetKeyValueInt(MenuKeys[client], MenuValues[client], "is ability?");
			if (ClassRole != 1 && isSubMenu != 1 && AbilityTalent != 1) {

				//if (ActionBarSlot[client] != -1 && GetTalentStrength(client, TalentName) < 1) continue;	// we don't display items that the user has no talent points in.
			//	if (GetTalentStrength(client, TalentName) < 1) continue;	// we don't display talents to players if they have no talent points in them (from gear)
			}
			pos++;

			FormatKeyValue(SurvEffects, sizeof(SurvEffects), MenuKeys[client], MenuValues[client], "survivor ability effects?");
			StorePurchaseCost = GetKeyValueInt(MenuKeys[client], MenuValues[client], "store purchase cost?");

			if (pos == slot) break;
		}

		if (isSubMenu == 1) {

			if (PlayerLevel[client] < TalentLevelRequired) BuildSubMenu(client, OpenedMenu[client], MenuSelection[client]);
			else {

				// If the player is eligible we open a new sub-menu.
				BuildSubMenu(client, TalentName, MenuSelection[client], OpenedMenu[client]);
			}
		}
		else {

			PlayerTalentPoints = GetTalentStrength(client, TalentName);

			if (ClassRole != 1 && AbilityTalent != 1 && IsTalentLocked(client, TalentName) && SkyPoints[client] >= StorePurchaseCost) {

				SkyPoints[client] -= StorePurchaseCost;
				UnlockTalent(client, TalentName);
				BuildSubMenu(client, OpenedMenu[client], MenuSelection[client]);
			}
			else {

				if (AbilityTalent == 1 || PlayerLevel[client] >= TalentLevelRequired) {

					PurchaseTalentName[client] = TalentName;
					PurchaseSurvEffects[client] = SurvEffects;
					PurchaseTalentPoints[client] = PlayerTalentPoints;
					ShowTalentInfoScreen(client, TalentName, MenuKeys[client], MenuValues[client]);
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
	}
	else if (action == MenuAction_Cancel) {

		if (slot == MenuCancel_ExitBack) {

			BuildMenu(client);
		}
	}
	if (action == MenuAction_End)
	{
		CloseHandle(menu);
	}
}

stock ShowTalentInfoScreen(client, String:TalentName[], Handle:Keys, Handle:Values) {

	PurchaseKeys[client] = Keys;
	PurchaseValues[client] = Values;
	Format(PurchaseTalentName[client], sizeof(PurchaseTalentName[]), "%s", TalentName);
	new IsAbilityType = GetKeyValueInt(PurchaseKeys[client], PurchaseValues[client], "is ability?");
	new IsSpecialAmmo = GetKeyValueInt(PurchaseKeys[client], PurchaseValues[client], "special ammo?");
	//PurchaseTalentName[client] = TalentName;
	// programming the logic is hard when baked :(
	if (IsAbilityType == 1 || IsSpecialAmmo == 1 && bIsSprinting[client]) SendPanelToClientAndClose(TalentInfoScreen_Special(client), client, TalentInfoScreen_Special_Init, MENU_TIME_FOREVER);
	else SendPanelToClientAndClose(TalentInfoScreen(client), client, TalentInfoScreen_Init, MENU_TIME_FOREVER);
	//if (IsAbilityType == 0 || !bIsSprinting[client]) SendPanelToClientAndClose(TalentInfoScreen(client), client, TalentInfoScreen_Init, MENU_TIME_FOREVER);
	//else if (IsSpecialAmmo == 1 || IsAbilityType == 1) SendPanelToClientAndClose(TalentInfoScreen_Special(client), client, TalentInfoScreen_Special_Init, MENU_TIME_FOREVER);
}

stock Float:GetTalentInfo(client, Handle:Keys, Handle:Values, infotype = 0, bool:bIsNext = false, String:TalentNameOverride[] = "none") {

	new Float:f_Strength	= 0.0;
	if (!StrEqual(TalentNameOverride, "none")) f_Strength = GetTalentStrength(client, TalentNameOverride) * 1.0;
	else f_Strength	=	GetTalentStrength(client, PurchaseTalentName[client]) * 1.0;
	if (bIsNext) f_Strength++;

	if (f_Strength <= 0.0) return 0.0;

	new Float:f_StrengthPoint	= 0.0;
	new Float:f_StrengthFirst	= 0.0;
	new Float:f_StrengthT		= 0.0;
	//new Float:f_StrengthP		= 0.0;

	new Cons = GetTalentStrength(client, "constitution");
	new Agil = GetTalentStrength(client, "agility");
	new Resi = GetTalentStrength(client, "resilience");
	new Tech = GetTalentStrength(client, "technique");
	//new Endu = GetTalentStrength(client, "endurance");
	//new Luck = GetTalentStrength(client, "luck");
	new Float:f_StrEach = f_Strength - 1;
	new Float:TheAbilityMultiplier = 0.0;

	if (infotype == 0) {	// first point value

		f_StrengthPoint			= GetKeyValueFloat(Keys, Values, "first point value?");
		f_StrengthT				= GetConfigValueFloat("constitution ab multiplier?");
		f_StrengthT				+= f_StrengthT * Cons;
		f_StrengthPoint			+= (f_StrengthPoint * f_StrengthT);
	}
	else if (infotype == 1) {	// each point value

		f_StrengthPoint			= GetKeyValueFloat(Keys, Values, "increase per point?");
		f_StrengthT				= GetConfigValueFloat("agility ab multiplier?");
		f_StrengthT				+= f_StrengthT * Agil;
		
		f_StrengthPoint			+= (f_StrengthPoint * f_StrengthT);
		f_StrengthPoint			*= f_StrEach;
	}
	else if (infotype == 2) {	// ability time each point value

		f_StrengthPoint			= GetKeyValueFloat(Keys, Values, "ability time per point?");
		f_StrengthT				= GetConfigValueFloat("technique ab multiplier?");
		f_StrengthT				+= f_StrengthT * Tech;
		f_StrengthPoint			+= (f_StrengthPoint * f_StrengthT);
		f_StrengthPoint			*= f_StrEach;
	}
	else if (infotype == 3) {	// Cooldown time

		f_StrengthPoint			= GetKeyValueFloat(Keys, Values, "cooldown per point?");
		f_StrengthFirst			= GetKeyValueFloat(Keys, Values, "cooldown first point?");
		f_StrengthFirst			+= GetKeyValueFloat(Keys, Values, "cooldown start?");

		f_StrengthFirst = GetClassMultiplier(client, f_StrengthFirst, "ftCD");
		f_StrengthPoint = GetClassMultiplier(client, f_StrengthPoint, "etCD");

		f_StrengthFirst			+= f_StrengthFirst * (GetConfigValueFloat("constitution ab multiplier?") * Cons);
		f_StrengthPoint			+= f_StrengthPoint * (GetConfigValueFloat("agility ab multiplier?") * Agil);

		if (Cons > Resi) f_StrengthT = (GetConfigValueFloat("resilience ab multiplier?") * (Resi * 1.5));
		else f_StrengthT		= (GetConfigValueFloat("resilience ab multiplier?") * Resi);
		//f_StrengthT				*= f_Strength;


		TheAbilityMultiplier = GetAbilityMultiplier(client, 'L');
		if (TheAbilityMultiplier != -1.0) {

			if (TheAbilityMultiplier < 0.0) TheAbilityMultiplier = 0.1;
			else if (TheAbilityMultiplier > 0.0) { //cooldowns are reduced

				f_StrengthPoint		*= TheAbilityMultiplier;
				f_StrengthFirst		*= TheAbilityMultiplier;
			}
		}


		f_StrengthPoint			*= f_StrEach;
		f_StrengthPoint			+= f_StrengthFirst;

		f_StrengthPoint			-= f_StrengthT;

		if (f_StrengthPoint < GetKeyValueFloat(Keys, Values, "cooldown start?")) f_StrengthPoint = GetKeyValueFloat(Keys, Values, "cooldown start?");
		f_StrengthPoint			+= GetKeyValueFloat(Keys, Values, "cooldown start?");
	}

	if (StrEqual(TalentNameOverride, "none")) {

		decl String:talenteffects[64];
		Format(talenteffects, sizeof(talenteffects), "0");
		new counter = 0;
		while (StrEqual(talenteffects, "0", false) && counter < 5) {

			if (counter == 0) FormatKeyValue(talenteffects, sizeof(talenteffects), Keys, Values, "activator ability effects?");
			else if (counter == 1) FormatKeyValue(talenteffects, sizeof(talenteffects), Keys, Values, "witch ability effects?");
			else if (counter == 2) FormatKeyValue(talenteffects, sizeof(talenteffects), Keys, Values, "common ability effects?");
			else if (counter == 3) FormatKeyValue(talenteffects, sizeof(talenteffects), Keys, Values, "infected ability effects?");
			else if (counter == 4) FormatKeyValue(talenteffects, sizeof(talenteffects), Keys, Values, "survivor ability effects?");
			counter++;
		}
		Format(talenteffects, sizeof(talenteffects), "tS_%s", talenteffects);
		f_StrengthPoint = GetClassMultiplier(client, f_StrengthPoint, talenteffects);
	}

	new Float:TalentHardLimit = GetKeyValueFloat(Keys, Values, "talent hard limit?");
	if (infotype != 3 && f_StrengthPoint > TalentHardLimit && TalentHardLimit > 0.0) f_StrengthPoint = TalentHardLimit;

	return f_StrengthPoint;
}

public Handle:TalentInfoScreen (client) {

	new Handle:Keys = PurchaseKeys[client];
	new Handle:Values = PurchaseValues[client];
	decl String:TalentName[64];
	Format(TalentName, sizeof(TalentName), "%s", PurchaseTalentName[client]);

	new ClassRole = GetKeyValueInt(Keys, Values, "is survivor class role?");
	new AbilityTalent			= GetKeyValueInt(Keys, Values, "is ability?");
	new IsSpecialAmmo = GetKeyValueInt(Keys, Values, "special ammo?");

	new Handle:menu = CreatePanel();

	new TalentPointAmount		= 0;
	new TalentPointMaximum		= 0;
	if (ClassRole != 1 && AbilityTalent != 1) {

		if (!b_IsDirectorTalents[client]) TalentPointAmount = GetTalentStrength(client, TalentName);
		else TalentPointAmount = GetTalentStrength(-1, TalentName);
		TalentPointMaximum		= GetKeyValueInt(Keys, Values, "maximum talent points allowed?");
	}
	new TalentType = GetKeyValueInt(Keys, Values, "talent type?");

	new Float:s_FirstPoint = GetTalentInfo(client, Keys, Values);
	new Float:s_OtherPoint = GetTalentInfo(client, Keys, Values, 1);
	new Float:s_OtherPointNext = GetTalentInfo(client, Keys, Values, 1, true);
	new Float:s_PenaltyPoint = s_FirstPoint;
	new Float:s_SoftCapCooldown = 0.0;

	decl String:pct[4];
	Format(pct, sizeof(pct), "%");
	
	new Float:f_CooldownNow = GetTalentInfo(client, Keys, Values, 3);
	new Float:f_CooldownNext = GetTalentInfo(client, Keys, Values, 3, true);

	decl String:TalentIdCode[64];
	decl String:TalentIdNum[64];
	FormatKeyValue(TalentIdNum, sizeof(TalentIdNum), Keys, Values, "id_number");
	Format(TalentIdCode, sizeof(TalentIdCode), "%T", "Talent Id Code", client);
	Format(TalentIdCode, sizeof(TalentIdCode), "%s: %s", TalentIdCode, TalentIdNum);

	

	//	We copy the talent name to another string so we can show the talent in the language of the player.
	
	decl String:TalentName_Temp[64];
	Format(TalentName_Temp, sizeof(TalentName_Temp), "%T", TalentName, client);

	decl String:text[512];
	if (ClassRole != 1 && AbilityTalent != 1) {

		if (FreeUpgrades[client] <= 0) {

			if (FreeUpgrades[client] < 0) FreeUpgrades[client] = 0;
			Format(text, sizeof(text), "%T", "Talent Upgrade Title", client, TalentName_Temp, TalentPointAmount);
		}
		else Format(text, sizeof(text), "%T", "Talent Upgrade Title Free", client, TalentName_Temp, TalentPointAmount, FreeUpgrades[client]);
	}
	else Format(text, sizeof(text), "%s", TalentName_Temp);
	SetPanelTitle(menu, text);

	decl String:TalentInfo[128];

	if (ClassRole != 1 && AbilityTalent != 1) {

		if (IsSpecialAmmo != 1) {

			if (TalentPointAmount == 0) Format(text, sizeof(text), "%T", "Talent Cooldown Info - No Points", client, s_SoftCapCooldown + f_CooldownNext);
			else Format(text, sizeof(text), "%T", "Talent Cooldown Info", client, s_SoftCapCooldown + f_CooldownNow, s_SoftCapCooldown + f_CooldownNext);
			if (f_CooldownNext > 0.0 && ClassRole != 1) DrawPanelText(menu, text);

			new Float:i_AbilityTime = GetTalentInfo(client, Keys, Values, 2);
			new Float:i_AbilityTimeNext = GetTalentInfo(client, Keys, Values, 2, true);

			new AbilityType = StringToInt(GetKeyValue(Keys, Values, "ability type?"));
			if (TalentPointAmount > 0) s_PenaltyPoint = 0.0;
			//if (AbilityType == 0) Format(text, sizeof(text), "%T", "Ability Info Percent", client, ((s_FirstPoint - s_PenaltyPoint) * 100.0) + ((TalentPointAmount * s_OtherPoint) * 100.0), pct, (s_FirstPoint * 100.0) + (((TalentPointAmount + 1) * s_OtherPoint) * 100.0), pct);
			//else if (AbilityType == 1) Format(text, sizeof(text), "%T", "Ability Info Time", client, i_AbilityTime, i_AbilityTimeNext);
			//else if (AbilityType == 2) Format(text, sizeof(text), "%T", "Ability Info Distance", client, (s_FirstPoint - s_PenaltyPoint) + (TalentPointAmount * s_OtherPoint), s_FirstPoint + ((TalentPointAmount + 1) * s_OtherPoint));

			if (GetKeyValueInt(Keys, Values, "talent type?") <= 0) {
		 
				if (AbilityType == 0) Format(text, sizeof(text), "%T", "Ability Info Percent", client, ((s_FirstPoint - s_PenaltyPoint) * 100.0) + (s_OtherPoint * 100.0), pct, (s_FirstPoint * 100.0) + (s_OtherPointNext * 100.0), pct);
				else if (AbilityType == 1) Format(text, sizeof(text), "%T", "Ability Info Time", client, i_AbilityTime, i_AbilityTimeNext);
				else if (AbilityType == 2) Format(text, sizeof(text), "%T", "Ability Info Distance", client, (s_FirstPoint - s_PenaltyPoint) + s_OtherPoint, s_FirstPoint + s_OtherPointNext);
				
				if (ClassRole != 1) DrawPanelText(menu, text);
				//DrawPanelText(menu, TalentIdCode);
			}
		}
		else {

			Format(TalentInfo, sizeof(TalentInfo), "%s info", TalentName);
			Format(TalentInfo, sizeof(TalentInfo), "%T", TalentInfo, client);

			if (FreeUpgrades[client] == 0) Format(text, sizeof(text), "%T", "Talent Upgrade Title", client, TalentName_Temp, TalentPointAmount, TalentPointMaximum);
			else Format(text, sizeof(text), "%T", "Talent Upgrade Title Free", client, TalentName_Temp, TalentPointAmount, TalentPointMaximum, FreeUpgrades[client]);
			SetPanelTitle(menu, text);

			new Float:fTimeCur = GetSpecialAmmoStrength(client, TalentName);
			new Float:fTimeNex = GetSpecialAmmoStrength(client, TalentName, 0, true);

			//new Float:flIntCur = GetSpecialAmmoStrength(client, TalentName, 4);
			//new Float:flIntNex = GetSpecialAmmoStrength(client, TalentName, 4, true);

			//if (flIntCur > fTimeCur) flIntCur = fTimeCur;
			//if (flIntNex > fTimeNex) flIntNex = fTimeNex;

			Format(text, sizeof(text), "%T", "Special Ammo Time", client, fTimeCur, fTimeNex);
			DrawPanelText(menu, text);
			//Format(text, sizeof(text), "%T", "Special Ammo Interval", client, flIntCur, flIntNex);
			//DrawPanelText(menu, text);
			Format(text, sizeof(text), "%T", "Special Ammo Cooldown", client, fTimeCur + GetSpecialAmmoStrength(client, TalentName, 1), fTimeNex + GetSpecialAmmoStrength(client, TalentName, 1, true));
			DrawPanelText(menu, text);
			Format(text, sizeof(text), "%T", "Special Ammo Stamina", client, RoundToCeil(GetSpecialAmmoStrength(client, TalentName, 2)), RoundToCeil(GetSpecialAmmoStrength(client, TalentName, 2, true)));
			DrawPanelText(menu, text);
			Format(text, sizeof(text), "%T", "Special Ammo Range", client, GetSpecialAmmoStrength(client, TalentName, 3), GetSpecialAmmoStrength(client, TalentName, 3, true));
			DrawPanelText(menu, text);
			DrawPanelText(menu, TalentIdCode);
		}
	}

	if (ClassRole != 1) {

		if (TalentType <= 0 || AbilityTalent == 1) {

			Format(text, sizeof(text), "%T", "Insert Talent Upgrade", client, 1);
			DrawPanelItem(menu, text);
			Format(text, sizeof(text), "%T", "Insert Talent Upgrade", client, 5);
			DrawPanelItem(menu, text);
			Format(text, sizeof(text), "%T", "Insert Talent Upgrade", client, 10);
			DrawPanelItem(menu, text);
			Format(text, sizeof(text), "%T", "Refund Talent Upgrade", client, 1);
			DrawPanelItem(menu, text);
			Format(text, sizeof(text), "%T", "Refund Talent Upgrade", client, 5);
			DrawPanelItem(menu, text);
			Format(text, sizeof(text), "%T", "Refund Talent Upgrade", client, 10);
			DrawPanelItem(menu, text);
		}
		else if (TalentType > 0)  {

			// draw the talent type 1 leveling information and a return option only.
			new talentlevel = GetTalentLevel(client, TalentName);
			new talentexperience = GetTalentLevel(client, TalentName, true);
			new talentrequirement = CheckExperienceRequirementTalents(client, TalentName);
			Format(text, sizeof(text), "%T", "cartel experience screen", client, talentlevel, AddCommasToString(talentexperience), AddCommasToString(talentrequirement), TalentName_Temp, MenuExperienceBar(client, talentexperience, talentrequirement));
			DrawPanelText(menu, text);
		}
	}
	else if (ClassRole == 1) {

		if (StrEqual(ActiveClass[client], TalentName, false)) Format(text, sizeof(text), "%T", "Disable Class", client);
		else Format(text, sizeof(text), "%T", "Enable Class", client);
		DrawPanelItem(menu, text);
	}
	
	if (ClassRole != 1) {

		Format(text, sizeof(text), "%T", "return to talent menu", client);
		DrawPanelItem(menu, text);

		//	Talents now have a brief description of what they do on their purchase page.
		//	This variable is pre-determined and calls a translation file in the language of the player.
		
		Format(TalentInfo, sizeof(TalentInfo), "%s info", TalentName);
		Format(TalentInfo, sizeof(TalentInfo), "%T", TalentInfo, client);

		DrawPanelText(menu, TalentInfo);	// rawline means not a selectable option.
	}
	else if (ClassRole == 1) {

		if (bIsClassAbilities[client]) Format(text, sizeof(text), "%T", "view class abilities", client);
		else Format(text, sizeof(text), "%T", "view class experience", client);
		DrawPanelItem(menu, text);
		Format(text, sizeof(text), "%T", "return to talent menu", client);
		DrawPanelItem(menu, text);

		// Classes have their descriptions auto-generated based on their class effects.
		// This system allows for quick talent creation because we don't have to create separate translation files for each talent.

		if (!bIsClassAbilities[client]) DrawPanelText(menu, GetClassMultiplierText(client, GetKeyValue(Keys, Values, "class effect?"), TalentName));
		else DrawPanelText(menu, GetClassMultiplierText(client, GetKeyValue(Keys, Values, "cartel effect?"), TalentName, true));
	}
	/*else if (AbilityTalent == 1 && bActionBarMenuRequest) {

		decl String:ActionBarText[64], String:CommandText[64];
		GetConfigValue(CommandText, sizeof(CommandText), "action slot command?");
		new ActionBarSize = GetArraySize(Handle:ActionBar[client]);

		for (new i = 0; i < ActionBarSize; i++) {

			GetArrayString(Handle:ActionBar[client], i, ActionBarText, sizeof(ActionBarText));
			if (!IsTalentExists(ActionBarText)) Format(ActionBarText, sizeof(ActionBarText), "%T", "No Action Equipped", client);
			else Format(ActionBarText, sizeof(ActionBarText), "%T", ActionBarText, client);
			Format(text, sizeof(text), "%T", "Assign to Action Bar", client, CommandText, i + 1, ActionBarText);
			DrawPanelItem(menu, text);
		}

		Format(text, sizeof(text), "%T", "return to talent menu", client);
		DrawPanelItem(menu, text);
		GetAbilityText(client, text, sizeof(text), Keys, Values);
		if (!StrEqual(text, "-1")) DrawPanelText(menu, text);
		GetAbilityText(client, text, sizeof(text), Keys, Values, "passive effect?");
		if (!StrEqual(text, "-1")) DrawPanelText(menu, text);
		GetAbilityText(client, text, sizeof(text), Keys, Values, "toggle effect?");
		if (!StrEqual(text, "-1")) DrawPanelText(menu, text);
	}*/
	return menu;
}

stock String:GetAbilityText(client, String:TheString[], TheSize, Handle:Keys, Handle:Values, String:TheQuery[] = "active effect?") {

	decl String:text[512], String:text2[512], String:tDraft[512], String:TheEffect[2], String:AbilityType[64];
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
	}
	else if (StrContains(TheQuery, "passive", false) != -1) {

		Format(tDraft, sizeof(tDraft), "%T", "Passive Effects", client);
		Format(AbilityType, sizeof(AbilityType), "Passive Ability");
		TheAbilityMultiplier = GetKeyValueFloat(Keys, Values, "passive strength?");
	}
	else {

		Format(tDraft, sizeof(tDraft), "%T", "Toggle Effects", client);
		Format(AbilityType, sizeof(AbilityType), "Toggle Ability");
		TheAbilityMultiplier = GetKeyValueFloat(Keys, Values, "toggle strength?");
	}
	new size = strlen(text);
	for (new i = 0; i < size && size > 0; i++) {

		/*

			so apparently my initial design had the idea of using a string instead of a char so abilities could provide multiple active/passive effects.
			i didn't code the other end this way, it requires a char, but we'll come back to it at some point since the hard part is done.
		*/

		Format(TheEffect, sizeof(TheEffect), "%s", text[i]);

		if (TheAbilityMultiplier > 0.0 || StrContains(TheEffect, "S") != -1) {

			Format(text2, sizeof(text2), "%s %s", TheEffect, AbilityType);
			Format(text2, sizeof(text2), "%T", text2, client, TheAbilityMultiplier * 100.0, pct);
		}
		else {

			Format(text2, sizeof(text2), "%s Disabled", TheEffect);
			Format(text2, sizeof(text2), "%T", text2, client);
		}
		Format(tDraft, sizeof(tDraft), "%s\n%s", tDraft, text2);
	}
	if (StrContains(TheQuery, "active", false) != -1) {

		FormatKeyValue(text, sizeof(text), Keys, Values, "cooldown?");

		TheAbilityMultiplier = GetAbilityMultiplier(client, 'L');
		if (TheAbilityMultiplier != -1.0) {

			if (TheAbilityMultiplier < 0.0) TheAbilityMultiplier = 0.1;
			else if (TheAbilityMultiplier > 0.0) { //cooldowns are reduced

				Format(text, sizeof(text), "%3.3f", StringToFloat(text) - (StringToFloat(text) * TheAbilityMultiplier));
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

	new TalentPointAmount		= 0;
	if (AbilityTalent != 1) TalentPointAmount = GetTalentStrength(client, TalentName);

	new TalentPointMaximum		= GetKeyValueInt(PurchaseKeys[client], PurchaseValues[client], "maximum talent points allowed?");

	decl String:TalentIdCode[64];
	decl String:theval[64];
	FormatKeyValue(theval, sizeof(theval), PurchaseKeys[client], PurchaseValues[client], "id_number");
	Format(TalentIdCode, sizeof(TalentIdCode), "%T", "Talent Id Code", client);
	Format(TalentIdCode, sizeof(TalentIdCode), "%s: %s", TalentIdCode, theval);

	

	//	We copy the talent name to another string so we can show the talent in the language of the player.
	
	decl String:TalentName_Temp[64];
	Format(TalentName_Temp, sizeof(TalentName_Temp), "%T", TalentName, client);

	

	//	Talents now have a brief description of what they do on their purchase page.
	//	This variable is pre-determined and calls a translation file in the language of the player.
	
	decl String:TalentInfo[128], String:text[512];

	if (AbilityTalent != 1) {

		Format(TalentInfo, sizeof(TalentInfo), "%s info", TalentName);
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
		Format(text, sizeof(text), "%T", "Special Ammo Cooldown", client, fltime =GetSpecialAmmoStrength(client, TalentName, 1), fltimen + GetSpecialAmmoStrength(client, TalentName, 1, true));
		DrawPanelText(menu, text);
		Format(text, sizeof(text), "%T", "Special Ammo Stamina", client, RoundToCeil(GetSpecialAmmoStrength(client, TalentName, 2)), RoundToCeil(GetSpecialAmmoStrength(client, TalentName, 2, true)));
		DrawPanelText(menu, text);
		Format(text, sizeof(text), "%T", "Special Ammo Range", client, GetSpecialAmmoStrength(client, TalentName, 3), GetSpecialAmmoStrength(client, TalentName, 3, true));
		DrawPanelText(menu, text);
		DrawPanelText(menu, TalentIdCode);
	}
	else {

		Format(TalentInfo, sizeof(TalentInfo), "%T", TalentName, client);
		DrawPanelText(menu, TalentInfo);
	}

	// We only have the option to assign it to action bars, instead.
	decl String:ActionBarText[64], String:CommandText[64];
	GetConfigValue(CommandText, sizeof(CommandText), "action slot command?");
	new ActionBarSize = GetArraySize(Handle:ActionBar[client]);

	for (new i = 0; i < ActionBarSize; i++) {

		GetArrayString(Handle:ActionBar[client], i, ActionBarText, sizeof(ActionBarText));
		if (!IsTalentExists(ActionBarText)) Format(ActionBarText, sizeof(ActionBarText), "%T", "No Action Equipped", client);
		else Format(ActionBarText, sizeof(ActionBarText), "%T", ActionBarText, client);
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
	}
	else DrawPanelText(menu, TalentInfo);	// rawline means not a selectable option.
	return menu;
}

public TalentInfoScreen_Init (Handle:topmenu, MenuAction:action, client, param2)
{
	if (action == MenuAction_Select)
	{
		new MaxPoints = GetKeyValueInt(PurchaseKeys[client], PurchaseValues[client], "maximum talent points allowed?");
		new TalentStrength = GetTalentStrength(client, PurchaseTalentName[client]);
		decl String:TalentName[64];
		Format(TalentName, sizeof(TalentName), "%s", PurchaseTalentName[client]);
		new ClassRole = GetKeyValueInt(PurchaseKeys[client], PurchaseValues[client], "is survivor class role?");
		new TalentType = GetKeyValueInt(PurchaseKeys[client], PurchaseValues[client], "talent type?");
		new AbilityTalent = GetKeyValueInt(PurchaseKeys[client], PurchaseValues[client], "is ability?");

		/*if (ClassRole == 1) {

			switch (param2) {

				case 1: {

					if (IsLegitimateClass(client) && StrEqual(ActiveClass[client], TalentName)) SaveClassData(client);
					else {

						if (!IsLegitimateClass(client)) {

							decl String:key[64];
							GetClientAuthString(client, key, sizeof(key));
							Format(ActiveClass[client], sizeof(ActiveClass[]), "%s", TalentName);
							LoadTalentTrees(client, key, true);
						}
						else {

							Format(ClassLoadQueue[client], sizeof(ClassLoadQueue[]), "%s", TalentName);
							SaveClassData(client);
						}
					}
				}
				case 2: {

					if (bIsClassAbilities[client]) bIsClassAbilities[client] = false;
					else bIsClassAbilities[client] = true;
					SendPanelToClientAndClose(TalentInfoScreen(client), client, TalentInfoScreen_Init, MENU_TIME_FOREVER);
				}
				case 3: {

					BuildSubMenu(client, OpenedMenu[client], MenuSelection[client]);
				}
			}
		}*/
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

					if (ClassRole != 1 && AbilityTalent != 1) {

						if (TalentType <= 0) {

							if ((UpgradesAvailable[client] > 0 || FreeUpgrades[client] > 0) && TalentStrength + 1 <= MaxPoints) {

								if (FreeUpgrades[client] > 0) FreeUpgrades[client]--;
								else if (UpgradesAvailable[client] > 0) {

									TryToTellPeopleYouUpgraded(client);
									UpgradesAvailable[client]--;
									PlayerLevelUpgrades[client]++;
								}
								PlayerUpgradesTotal[client]++;
								PurchaseTalentPoints[client]++;
								AddTalentPoints(client, PurchaseTalentName[client], PurchaseTalentPoints[client]);
							}
							SendPanelToClientAndClose(TalentInfoScreen(client), client, TalentInfoScreen_Init, MENU_TIME_FOREVER);
						}
						else {

							BuildSubMenu(client, OpenedMenu[client], MenuSelection[client]);
						}
					}
					else if (ClassRole == 1) {

						if (IsLegitimateClass(client) && StrEqual(ActiveClass[client], TalentName)) SaveClassData(client);
						else {

							if (!IsLegitimateClass(client)) {

								decl String:key[64];
								GetClientAuthString(client, key, sizeof(key));
								Format(ActiveClass[client], sizeof(ActiveClass[]), "%s", TalentName);
								LoadTalentTrees(client, key, true);
							}
							else {

								Format(ClassLoadQueue[client], sizeof(ClassLoadQueue[]), "%s", TalentName);
								SaveClassData(client);
							}
						}
					}
					else {

						BuildSubMenu(client, OpenedMenu[client], MenuSelection[client]);
					}
				}
				case 2: {

					if (ClassRole != 1) {

						if ((UpgradesAvailable[client] >= 5 || FreeUpgrades[client] >= 5) && TalentStrength + 5 <= MaxPoints) {

							if (FreeUpgrades[client] >= 5) FreeUpgrades[client] -= 5;
							else if (UpgradesAvailable[client] >= 5) {

								TryToTellPeopleYouUpgraded(client);
								UpgradesAvailable[client] -= 5;
								PlayerLevelUpgrades[client] += 5;
							}
							PlayerUpgradesTotal[client] += 5;
							PurchaseTalentPoints[client] += 5;
							AddTalentPoints(client, PurchaseTalentName[client], PurchaseTalentPoints[client]);
						}
						SendPanelToClientAndClose(TalentInfoScreen(client), client, TalentInfoScreen_Init, MENU_TIME_FOREVER);
					}
					else {

						if (bIsClassAbilities[client]) bIsClassAbilities[client] = false;
						else bIsClassAbilities[client] = true;
						SendPanelToClientAndClose(TalentInfoScreen(client), client, TalentInfoScreen_Init, MENU_TIME_FOREVER);
					}
				}
				case 3: {

					if (ClassRole != 1) {

						if ((UpgradesAvailable[client] >= 10 || FreeUpgrades[client] >= 10) && TalentStrength + 10 <= MaxPoints) {

							if (FreeUpgrades[client] >= 10) FreeUpgrades[client] -= 10;
							else if (UpgradesAvailable[client] >= 10) {

								TryToTellPeopleYouUpgraded(client);
								UpgradesAvailable[client] -= 10;
								PlayerLevelUpgrades[client] += 10;
							}
							PlayerUpgradesTotal[client] += 10;
							PurchaseTalentPoints[client] += 10;
							AddTalentPoints(client, PurchaseTalentName[client], PurchaseTalentPoints[client]);
						}
						SendPanelToClientAndClose(TalentInfoScreen(client), client, TalentInfoScreen_Init, MENU_TIME_FOREVER);
					}
					else {

						BuildSubMenu(client, OpenedMenu[client], MenuSelection[client]);
					}
				}
				case 4: {

					if (TalentStrength >= 1) {

						PlayerUpgradesTotal[client]--;
						PurchaseTalentPoints[client]--;
						FreeUpgrades[client]++;
						AddTalentPoints(client, PurchaseTalentName[client], PurchaseTalentPoints[client]);
					}
					SendPanelToClientAndClose(TalentInfoScreen(client), client, TalentInfoScreen_Init, MENU_TIME_FOREVER);
				}
				case 5: {

					if (TalentStrength >= 5) {

						PlayerUpgradesTotal[client] -= 5;
						PurchaseTalentPoints[client] -= 5;
						FreeUpgrades[client] += 5;
						AddTalentPoints(client, PurchaseTalentName[client], PurchaseTalentPoints[client]);
					}
					SendPanelToClientAndClose(TalentInfoScreen(client), client, TalentInfoScreen_Init, MENU_TIME_FOREVER);
				}
				case 6: {

					if (TalentStrength >= 10) {

						PlayerUpgradesTotal[client] -= 10;
						PurchaseTalentPoints[client] -= 10;
						FreeUpgrades[client] += 10;
						AddTalentPoints(client, PurchaseTalentName[client], PurchaseTalentPoints[client]);
					}
					SendPanelToClientAndClose(TalentInfoScreen(client), client, TalentInfoScreen_Init, MENU_TIME_FOREVER);
				}
				case 7: {

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
		//new MaxPoints = GetKeyValueInt(PurchaseKeys[client], PurchaseValues[client], "maximum talent points allowed?");
		//new TalentStrength = GetTalentStrength(client, PurchaseTalentName[client]);
		new ActionBarSize = GetArraySize(Handle:ActionBar[client]);

		if (param2 > ActionBarSize) {

			BuildSubMenu(client, OpenedMenu[client], MenuSelection[client]);
		}
		else {

			if (!SwapActions(client, PurchaseTalentName[client], param2 - 1)) SetArrayString(Handle:ActionBar[client], param2 - 1, PurchaseTalentName[client]);
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
		GetClientName(client, PlayerName, sizeof(PlayerName));
		for (new k = 1; k <= MaxClients; k++) {

			if (IsLegitimateClient(k) && !IsFakeClient(k) && GetClientTeam(k) == GetClientTeam(client)) {

				Format(text2, sizeof(text2), "%T", PurchaseTalentName[client], k);
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