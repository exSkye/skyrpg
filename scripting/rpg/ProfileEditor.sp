public void ProfileEditorMenu(client) {

	Handle menu		= CreateMenu(ProfileEditorMenuHandle);

	char text[512];
	Format(text, sizeof(text), "%T", "profile editor title", client, LoadoutName[client]);
	SetMenuTitle(menu, text);

	Format(text, sizeof(text), "%T", "Save Profile", client);
	AddMenuItem(menu, text, text);
	Format(text, sizeof(text), "%T", "Load Profile", client);
	AddMenuItem(menu, text, text);
	Format(text, sizeof(text), "%T", "Load All", client);
	AddMenuItem(menu, text, text);

	char TheName[64];
	int thetarget = LoadProfileRequestName[client];
	if (thetarget == -1 || thetarget == client || !IsLegitimateClient(thetarget) || myCurrentTeam[thetarget] != TEAM_SURVIVOR) thetarget = LoadTarget[client];
	if (IsLegitimateClient(thetarget) && myCurrentTeam[thetarget] != TEAM_INFECTED && thetarget != client) {

		//decl String:theclassname[64];
		GetClientName(thetarget, TheName, sizeof(TheName));
		char ratingText[64];
		AddCommasToString(Rating[thetarget], ratingText, sizeof(ratingText));
		Format(text, sizeof(text), "%s\t\tScore: %s", TheName, ratingText);
	}
	else {

		LoadTarget[client] = -1;
		Format(TheName, sizeof(TheName), "%T", "Yourself", client);
	}
	Format(text, sizeof(text), "%T", "Select Load Target", client, text);
	AddMenuItem(menu, text, text);
	Format(text, sizeof(text), "%T", "Delete Profile", client);
	AddMenuItem(menu, text, text);

	int Requester = CheckRequestStatus(client);
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

stock CheckRequestStatus(client, bool CancelRequest = false) {

	char TargetName[64];

	for (int i = 1; i <= MaxClients; i++) {

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

stock void AddProfilesToAugments(int client, char[] profileName, char[] fullProfileName) {
	for (int i = 0; i < iNumAugments; i++) {
		char currentlyEquippedAugment[64];
		GetArrayString(equippedAugmentsIDCodes[client], i, currentlyEquippedAugment, sizeof(currentlyEquippedAugment));

		int augmentPos = FindAugmentPosByIDCode(client, currentlyEquippedAugment);
		if (augmentPos < 0) continue;	// this augment doesn't exist anymore.

		char profiles[512];
		GetArrayString(myAugmentSavedProfiles[client], augmentPos, profiles, sizeof(profiles));
		// don't add the profile to the augment if it's already stored on the augment.
		if (StrContains(profiles, profileName, false) != -1) continue;
		if (StrEqual(profiles, "none")) {
			Format(profiles, sizeof(profiles), "%s", fullProfileName);
		}
		else Format(profiles, sizeof(profiles), "%s\n%s", profiles, fullProfileName);
		SetArrayString(myAugmentSavedProfiles[client], augmentPos, profiles);
	}
}

stock void RemoveProfileFromAugments(int client, char[] profileName, bool skipEquippedAugments = false, int specificAugmentOnly = -1) {
	int size = GetArraySize(myAugmentSavedProfiles[client]);
	char newProfiles[512];
	for (int i = (specificAugmentOnly == -1) ? 0 : specificAugmentOnly; i < size; i++) {
		int isEquipped = GetArrayCell(myAugmentInfo[client], i, 3);
		// This switch is so when a new profile is saved, I can call:
		// AddProfilesToAugments(client, newProfileName);
		// and then call
		// RemoveProfileFromAugments(client, newProfileName, true);
		// afterwards, to quickly remove the newly-saved profile from augments that are not attached to its lists, if it's an overwrite, if those augments were previously saved to that profile.
		if (skipEquippedAugments && isEquipped >= 0) continue;

		char profiles[512];
		GetArrayString(myAugmentSavedProfiles[client], i, profiles, sizeof(profiles));
		
		int ExplodeCount = GetDelimiterCount(profiles, "\n") + 1;
		if (ExplodeCount == 1) {
			if (StrContains(profiles, profileName, false) == -1) Format(newProfiles, sizeof(newProfiles), "%s", profiles);
			else {
				Format(newProfiles, sizeof(newProfiles), "none");
				// augments not tied to profiles are unlocked for autodismantle if they are not equipped.
				if (isEquipped >= 0) continue;

				char augmentID[64];
				GetArrayString(myAugmentIDCodes[client], i, augmentID, sizeof(augmentID));
				
				char sql[512];
				Format(sql, sizeof(sql), "UPDATE `%s_loot` SET `isequipped` = '-1' WHERE (`itemid` = '%s');", TheDBPrefix, augmentID);
 				SQL_TQuery(hDatabase, QueryResults, sql, client);
			}
		}
		else {
			char[][] profileNames = new char[ExplodeCount][64];
			ExplodeString(profiles, "\n", profileNames, ExplodeCount, 64);
			int count = 0;
			for (int pos = 0; pos < ExplodeCount; pos++) {
				if (StrContains(profileNames[pos], profileName, false) != -1) continue;
				if (count > 0) Format(newProfiles, sizeof(newProfiles), "%s\n%s", newProfiles, profileNames[pos]);
				else Format(newProfiles, sizeof(newProfiles), "%s", profileNames[pos]);
				count++;
			}
		}
		SetArrayString(myAugmentSavedProfiles[client], i, newProfiles);
		if (specificAugmentOnly >= 0) break;
	}
}

stock DeleteProfile(client, bool DisplayToClient = true) {

	if (strlen(LoadoutName[client]) < 3) return;

	char tquery[512];
	char t_Loadout[64];
	char pct[4];
	Format(pct, sizeof(pct), "%");
	GetClientAuthId(client, AuthId_Steam2, t_Loadout, sizeof(t_Loadout));
	if (!StrEqual(serverKey, "-1")) Format(t_Loadout, sizeof(t_Loadout), "%s%s", serverKey, t_Loadout);
	Format(t_Loadout, sizeof(t_Loadout), "%s+%s", t_Loadout, LoadoutName[client]);
	Format(tquery, sizeof(tquery), "DELETE FROM `%s_profiles` WHERE `steam_id` LIKE '%s%s' AND `steam_id` LIKE '%s%s';", TheDBPrefix, t_Loadout, pct, pct, pct);
	SQL_TQuery(hDatabase, QueryResults, tquery, client);
	RemoveProfileFromAugments(client, LoadoutName[client]);
	if (DisplayToClient) {

		PrintToChat(client, "%T", "loadout deleted", client, orange, green, LoadoutName[client]);
		Format(LoadoutName[client], sizeof(LoadoutName[]), "none");
	}
}

stock bool DeleteAllProfiles(client) {
	char tquery[512];
	char pct[4];
	Format(pct, sizeof(pct), "%");
	char key[64];
	GetClientAuthId(client, AuthId_Steam2, key, sizeof(key));
	Format(tquery, sizeof(tquery), "DELETE FROM `%s_profiles` WHERE `steam_id` LIKE '%s%s%s';", TheDBPrefix, pct, key, pct);
	SQL_TQuery(hDatabase, QueryResults, tquery, client);
	return true;
}

public ProfileEditorMenuHandle(Handle menu, MenuAction action, client, slot) {

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

			int Requester = CheckRequestStatus(client);

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

	if (StrEqual(LoadoutName[client], "none") || strlen(LoadoutName[client]) < 3) {
		PrintToChat(client, "\x04Please set a valid !loadoutname before trying again.");
		return;
	}

	char tquery[512];
	char key[512];
	char pct[4];
	Format(pct, sizeof(pct), "%");

	GetClientAuthId(client, AuthId_Steam2, key, sizeof(key));
	if (!StrEqual(serverKey, "-1")) Format(key, sizeof(key), "%s%s", serverKey, key);
	Format(key, sizeof(key), "%s+", key);
	if (SaveType != 0) {

		if (SaveType == 1) PrintToChat(client, "%T", "new save", client, orange, green, LoadoutName[client]);
		else PrintToChat(client, "%T", "update save", client, orange, green, LoadoutName[client]);

		int tpa = TotalPointsAssigned(client);
		if (StrContains(LoadoutName[client], "Lv.", false) == -1) Format(key, sizeof(key), "%s%s Lv.%d+%s", key, LoadoutName[client], tpa, PROFILE_VERSION);
		else Format(key, sizeof(key), "%s%s+%s", key, LoadoutName[client], PROFILE_VERSION);
		SaveProfileEx(client, key, SaveType);

		char LoadoutNameFull[512];
		Format(LoadoutNameFull, sizeof(LoadoutNameFull), "%s Lv.%d", LoadoutName[client], tpa);

		AddProfilesToAugments(client, LoadoutName[client], LoadoutNameFull);
		RemoveProfileFromAugments(client, LoadoutName[client], true);
	}
	else {

		Format(tquery, sizeof(tquery), "SELECT COUNT(*) FROM `%s_profiles` WHERE `steam_id` LIKE '%s%s';", TheDBPrefix, key, pct);
		SQL_TQuery(hDatabase, Query_CheckIfProfileLimit, tquery, client);
	}
}

stock SaveProfileEx(client, char[] key, SaveType) {

	char tquery[1024];
	char text[512];
	char ActionBarText[64];

	char sPrimary[64];
	char sSecondary[64];
	GetArrayString(hWeaponList[client], 0, sPrimary, sizeof(sPrimary));
	GetArrayString(hWeaponList[client], 1, sSecondary, sizeof(sSecondary));

	int talentlevel = 0;
	int size = GetArraySize(a_Database_Talents);
	int isDisab = 0;
	if (DisplayActionBar[client]) isDisab = 1;
	if (SaveType == 1) {

		//	A save doesn't exist for this steamid so we create one before saving anything.
		Format(tquery, sizeof(tquery), "INSERT INTO `%s_profiles` (`steam_id`) VALUES ('%s');", TheDBPrefix, key);
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
	Format(tquery, sizeof(tquery), "UPDATE `%s_profiles` SET `total upgrades` = '%d' WHERE `steam_id` = '%s';", TheDBPrefix, PlayerLevel[client] - UpgradesAvailable[client] - FreeUpgrades[client], key);
	SQL_TQuery(hDatabase, QueryResults, tquery, client);

	Format(tquery, sizeof(tquery), "UPDATE `%s_profiles` SET `primarywep` = '%s', `secondwep` = '%s' WHERE `steam_id` = '%s';", TheDBPrefix, sPrimary, sSecondary, key);
	SQL_TQuery(hDatabase, QueryResults, tquery, client);

	for (int i = 0; i < size; i++) {

		GetArrayString(a_Database_Talents, i, text, sizeof(text));
		TalentTreeValues[client]		= GetArrayCell(a_Menu_Talents, i, 1);

		if (GetArrayCell(TalentTreeValues[client], IS_SUB_MENU_OF_TALENTCONFIG) == 1) continue;

		talentlevel = GetArrayCell(a_Database_PlayerTalents[client], i);// GetArrayString(a_Database_PlayerTalents[client], i, text2, sizeof(text2));
		Format(tquery, sizeof(tquery), "UPDATE `%s_profiles` SET `%s` = '%d' WHERE `steam_id` = '%s';", TheDBPrefix, text, talentlevel, key);
		SQL_TQuery(hDatabase, QueryResults, tquery, client);
	}

	for (int i = 0; i < iActionBarSlots; i++) {	// isnt looping?
		GetArrayString(ActionBar[client], i, ActionBarText, sizeof(ActionBarText));
		int menuPos = GetArrayCell(ActionBarMenuPos[client], i);

		//if (StrEqual(ActionBarText, "none")) continue;
		if (menuPos < 0 || !IsAbilityTalent(client, menuPos) && (!IsTalentExists(ActionBarText) || GetTalentStrength(client, ActionBarText, _, menuPos) < 1)) Format(ActionBarText, sizeof(ActionBarText), "none");
		Format(tquery, sizeof(tquery), "UPDATE `%s_profiles` SET `aslot%d` = '%s' WHERE (`steam_id` = '%s');", TheDBPrefix, i+1, ActionBarText, key);
		SQL_TQuery(hDatabase, QueryResults, tquery);
	}
	Format(tquery, sizeof(tquery), "UPDATE `%s_profiles` SET `disab` = '%d' WHERE (`steam_id` = '%s');", TheDBPrefix, isDisab, key);
	SQL_TQuery(hDatabase, QueryResults, tquery);

	for (int i = 0; i < iNumAugments; i++) {
		char currentIDCode[64];
		GetArrayString(equippedAugmentsIDCodes[client], i, currentIDCode, sizeof(currentIDCode));
		Format(tquery, sizeof(tquery), "UPDATE `%s_profiles` SET `augment%d` = '%s' WHERE (`steam_id` = '%s');", TheDBPrefix, i+1, currentIDCode, key);
		SQL_TQuery(hDatabase, QueryResults, tquery);
	}
}

stock ReadProfiles(client, char[] target = "none") {

	if (bIsTalentTwo[client]) {

		BuildMenu(client);
		return;
	}

	if (hDatabase == INVALID_HANDLE) return;
	char key[64];
	if (StrEqual(target, "none", false)) GetClientAuthId(client, AuthId_Steam2, key, sizeof(key));// GetClientAuthString(client, key, sizeof(key));
	else Format(key, sizeof(key), "%s", target);
	if (!StrEqual(serverKey, "-1")) Format(key, sizeof(key), "%s%s", serverKey, key);
	Format(key, sizeof(key), "%s+", key);
	char tquery[512];
	char pct[4];
	Format(pct, sizeof(pct), "%");

	int owner = client;
	if (LoadTarget[owner] != -1 && LoadTarget[owner] != owner && IsLegitimateClient(LoadTarget[owner])) client = LoadTarget[owner];

	// If we want specialty servers that limit the # of upgrades that can be used (like a low level tutorial server)
	int maxPlayerUpgrades = MaximumPlayerUpgrades(client);

	if (!StrEqual(target, "all", false)) Format(tquery, sizeof(tquery), "SELECT `steam_id` FROM `%s_profiles` WHERE `steam_id` LIKE '%s%s' AND `total upgrades` <= '%d';", TheDBPrefix, key, pct, maxPlayerUpgrades);
	else Format(tquery, sizeof(tquery), "SELECT `steam_id` FROM `%s_profiles` WHERE `steam_id` LIKE '%s+%s' AND `total upgrades` <= '%d';", TheDBPrefix, pct, PROFILE_VERSION, maxPlayerUpgrades);
	//PrintToChat(client, tquery);
	//decl String:tqueryE[512];
	//SQL_EscapeString(Handle:hDatabase, tquery, tqueryE, sizeof(tqueryE));
	// maybe set a value equal to the users steamid integer only, so if steam:0:1:23456, set the value of "client" equal to 23456 and then set the client equal to whatever client's steamid contains 23456?
	ClearArray(PlayerProfiles[owner]);
	if (!StrEqual(target, "all", false)) SQL_TQuery(hDatabase, ReadProfiles_Generate, tquery, owner);
	else SQL_TQuery(hDatabase, ReadProfiles_GenerateAll, tquery, owner);
}

stock LoadProfileEx(client, char[] key, char[] menuFacingProfileName = "none") {
	int target = LoadTarget[client];
	LoadTarget[client] = -1;
	if (target == -1) target = client;
	else if (!IsLegitimateClient(target) || myCurrentTeam[target] != TEAM_SURVIVOR) {
		PrintToChat(client, "\x04Your load target is not valid.");
		return;
	}
	LoadProfileEx_Confirm(target, key, menuFacingProfileName);
}

stock LoadProfileEx_Confirm(client, char[] key, char[] menuFacingProfileName = "none", bool isCommandLoad = false) {
	if (!IsLegitimateClient(client) || StrEqual(key, "-1")) return;

	char tquery[512];
	if (hDatabase == null) {

		LogMessage("Database couldn't be found, cannot save for %N", client);
		return;
	}
	ClearArray(TempAttributes[client]);

	//if (HasCommandAccess(client, GetConfigValue("director talent flags?"))) PrintToChat(client, "%T", "loading profile ex", client, orange, key);
	//else
	char myName[64];
	GetClientName(client, myName, sizeof(myName));
	if (!StrEqual(menuFacingProfileName, "none")) {
		if (!isCommandLoad) PrintToChatAll("%t", "loading profile", blue, myName, white, blue, menuFacingProfileName, white, green, key, white);
		else PrintToChatAll("%t", "loading profile command", blue, myName, white, blue, menuFacingProfileName, white, green, key, white);
	}

	// track players who are loading a profile.
	bIsLoadingCustomProfile[client] = true;
	//b_IsLoading[client] = false;
	Format(tquery, sizeof(tquery), "SELECT `steam_id`, `total upgrades` FROM `%s_profiles` WHERE (`steam_id` = '%s');", TheDBPrefix, key);
	Format(customProfileKey[client], sizeof(customProfileKey[]), "%s", key);
	// maybe set a value equal to the users steamid integer only, so if steam:0:1:23456, set the value of "client" equal to 23456 and then set the client equal to whatever client's steamid contains 23456?
	//LogMessage("Loading %N data: %s", client, tquery);
	SQL_TQuery(hDatabase, QueryResults_LoadEx, tquery, client);
}

public void QueryResults_LoadEx(Handle howner, Handle hndl, const char[] error, any client) {
	if (hndl == null) {
		LogMessage("QueryResults_LoadEx no database handle found.");
		return;
	}
	char key[64];
	char text[64];
	char result[3][64];
	bool rowsFound = false;
	while (SQL_FetchRow(hndl))
	{
		SQL_FetchString(hndl, 0, key, sizeof(key));
		rowsFound = true;	// not sure how else to verify this without running a count query first.
		if (!IsLegitimateClient(client)) return;

		ExplodeString(key, "+", result, 3, 64);
		PushArrayString(TempAttributes[client], key);
		PushArrayCell(TempAttributes[client], SQL_FetchInt(hndl, 1));

		PlayerUpgradesTotal[client]	= SQL_FetchInt(hndl, 1);
		UpgradesAvailable[client]	= 0;
		FreeUpgrades[client] = PlayerLevel[client] - PlayerUpgradesTotal[client];
		if (FreeUpgrades[client] < 0) FreeUpgrades[client] = 0;
		PurchaseTalentPoints[client] = PlayerUpgradesTotal[client];
	}
	if (!rowsFound || !IsLegitimateClient(client)) {
		b_IsLoading[client] = false;
		return;
	}
	char tquery[512];
	//decl String:key[64];
	//GetClientAuthId(client, AuthId_Steam2, key, sizeof(key));

	LoadPos[client] = 0;
	if (!b_IsLoadingTrees[client]) b_IsLoadingTrees[client] = true;
	GetArrayString(a_Database_Talents, 0, text, sizeof(text));
	Format(tquery, sizeof(tquery), "SELECT `steam_id`, `%s` FROM `%s_profiles` WHERE (`steam_id` = '%s');", text, TheDBPrefix, key);
	SQL_TQuery(hDatabase, QueryResults_LoadTalentTreesEx, tquery, client);
}

public void QueryResults_LoadTalentTreesEx(Handle owner, Handle hndl, const char[] error, any client) {
	if (hndl == null) {
		LogMessage("QueryResults_LoadTalentTreesEx Error: %s", error);
		return;
	}
	char text[512];
	char tquery[512];
	int talentlevel = 0;
	int size = GetArraySize(a_Menu_Talents);
	char key[64];
	char skey[64];

	if (!IsLegitimateClient(client)) return;
	int dbsize = GetArraySize(a_Menu_Talents);
	if (GetArraySize(a_Database_PlayerTalents[client]) != dbsize) ResizeArray(a_Database_PlayerTalents[client], dbsize);
	while (SQL_FetchRow(hndl)) {
		SQL_FetchString(hndl, 0, key, sizeof(key));
		if (LoadPos[client] >= 0 && LoadPos[client] < dbsize) {

			talentlevel = SQL_FetchInt(hndl, 1);
			//SetArrayString(TempTalents[client], LoadPos[client], text);
			SetArrayCell(a_Database_PlayerTalents[client], LoadPos[client], talentlevel);

			LoadPos[client]++;
			while (LoadPos[client] < GetArraySize(a_Database_Talents)) {
				TalentTreeValues[client]		= GetArrayCell(a_Menu_Talents, LoadPos[client], 1);

				if (GetArrayCell(TalentTreeValues[client], IS_SUB_MENU_OF_TALENTCONFIG) == 1) {

					LoadPos[client]++;
					continue;	// we don't load class attributes because we're loading another players talent specs. don't worry... we'll load the CARTEL for the user, after.
				}
				break;
			}
			if (LoadPos[client] < GetArraySize(a_Database_Talents)) {

				GetArrayString(a_Database_Talents, LoadPos[client], text, sizeof(text));
				Format(tquery, sizeof(tquery), "SELECT `steam_id`, `%s` FROM `%s_profiles` WHERE (`steam_id` = '%s');", text, TheDBPrefix, key);
				SQL_TQuery(hDatabase, QueryResults_LoadTalentTreesEx, tquery, client);
				return;
			}
			else {

				/*Format(tquery, sizeof(tquery), "SELECT `steam_id`, `primarywep`, `secondwep` FROM `%s` WHERE (`steam_id` = '%s');", TheDBPrefix, key);
				//PrintToChat(client, "%s", tquery);
				LoadPos[client] = -2;
				SQL_TQuery(hDatabase, QueryResults_LoadTalentTreesEx, tquery, client);
				return;*/

				int ActionSlots = iActionBarSlots;
				Format(tquery, sizeof(tquery), "SELECT `steam_id`");
				for (int i = 0; i < ActionSlots; i++) {
					Format(tquery, sizeof(tquery), "%s, `aslot%d`", tquery, i+1);
				}
				Format(tquery, sizeof(tquery), "%s, `disab`, `primarywep`, `secondwep`", tquery);
				Format(tquery, sizeof(tquery), "%s FROM `%s_profiles` WHERE (`steam_id` = '%s');", tquery, TheDBPrefix, key);
				SQL_TQuery(hDatabase, QueryResults_LoadActionBar, tquery, client);
				LoadPos[client] = 0;
				return;
			}
		}
		else if (LoadPos[client] == -2) {
			FreeUpgrades[client]		=	MaximumPlayerUpgrades(client) - TotalPointsAssigned(client);
			UpgradesAvailable[client]	=	0;
			if (GetArraySize(hWeaponList[client]) != 2) {

				ClearArray(hWeaponList[client]);
				ResizeArray(hWeaponList[client], 2);
			}
			else if (GetArraySize(hWeaponList[client]) > 0) {

				SQL_FetchString(hndl, 1, text, sizeof(text));
				SetArrayString(hWeaponList[client], 0, text);
				
				SQL_FetchString(hndl, 2, text, sizeof(text));
				SetArrayString(hWeaponList[client], 1, text);

				GiveProfileItems(client);
			}
			//PrintToChat(client, "ABOUT TO LOAD %s", text);
			//}

			GetClientAuthId(client, AuthId_Steam2, skey, sizeof(skey));	// this is necessary, because they might still be in the process of loading another users data. this is a backstop in-case the loader has switched targets mid-load. this is why we don't first check the value of LoadProfileRequestName[client].
			if (!StrEqual(serverKey, "-1")) Format(skey, sizeof(skey), "%s%s", serverKey, skey);
			LoadPos[client] = 0;
			LoadTalentTrees(client, skey, true, key);
		}
		for (int i = 0; i < size; i++) {
			int PlayerTalentPoints = GetArrayCell(MyTalentStrength[client], i);
			if (PlayerTalentPoints > 1) {
				FreeUpgrades[client] += (PlayerTalentPoints - 1);
				PlayerUpgradesTotal[client] -= (PlayerTalentPoints - 1);
				AddTalentPoints(client, i, (PlayerTalentPoints - 1));
			}
		}
	}
	// if isfakeclient zoozoo
	if (PlayerLevel[client] < iPlayerStartingLevel) {
		b_IsLoading[client] = false;
		bIsTalentTwo[client] = false;
		b_IsLoadingTrees[client] = false;
		CreateNewPlayerEx(client);
		return;
	}
	else {

		char Name[64];
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
				if (bIsNewPlayer[client]) bIsNewPlayer[client] = false;
					//SaveAndClear(client);
					//ReadProfiles(client, "all");	// new players are given an option on what they want to play.
				//}
			}
			else SetTotalExperienceByLevel(client, iPlayerStartingLevel);
			//EquipBackpack(client);
			return;
		}
	}
}

stock LoadProfile_Confirm(client, char[] ProfileName, char[] menuFacingProfileName) {

	//new Handle:menu = CreateMenu(LoadProfile_ConfirmHandle);
	//decl String:text[64];
	//decl String:result[2][64];
	LoadProfileEx(client, ProfileName, menuFacingProfileName);
}

stock LoadProfileEx_Request(client, target) {

	LoadProfileRequestName[target] = client;

	Handle menu = CreateMenu(LoadProfileRequestHandle);
	char text[512];
	char ClientName[64];
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

public LoadProfileRequestHandle(Handle menu, MenuAction action, client, slot) {

	if (action == MenuAction_Select) {

		char TargetName[64];
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
	if (action == MenuAction_End) {// && menu != INVALID_HANDLE) {

		CloseHandle(menu);
	}
}

stock LoadProfileTargetSurvivorBot(client) {

	Handle menu = CreateMenu(TargetSurvivorBotMenuHandle);
	ClearArray(RPGMenuPosition[client]);

	char text[512];
	char pos[512];
	char ratingText[64];

	Format(text, sizeof(text), "%T", "select survivor bot", client);
	SetMenuTitle(menu, text);
	for (int i = 1; i <= MaxClients; i++) {

		if (IsLegitimateClient(i) && myCurrentTeam[i] != TEAM_INFECTED) {

			Format(pos, sizeof(pos), "%d", i);
			PushArrayString(RPGMenuPosition[client], pos);
			GetClientName(i, pos, sizeof(pos));
			AddCommasToString(Rating[i], ratingText, sizeof(ratingText));
			Format(pos, sizeof(pos), "%s\t\tScore: %s", pos, ratingText);
			AddMenuItem(menu, pos, pos);
		}
	}
	SetMenuExitBackButton(menu, true);
	DisplayMenu(menu, client, 0);
}

public TargetSurvivorBotMenuHandle(Handle menu, MenuAction action, client, slot) {

	if (action == MenuAction_Select) {

		char text[64];
		GetArrayString(RPGMenuPosition[client], slot, text, sizeof(text));
		int target = StringToInt(text);
		if (IsLegitimateClient(LoadTarget[client]) && IsLegitimateClient(LoadProfileRequestName[LoadTarget[client]]) && client == LoadProfileRequestName[LoadTarget[client]]) LoadProfileRequestName[LoadTarget[client]] = -1;
		if (target == client) {

			LoadTarget[client] = -1;
		}
		else {
			if (IsLegitimateClient(target) && IsFakeClient(target) || HasCommandAccess(client, loadProfileOverrideFlags)) LoadTarget[client] = target;
			else {
				LoadProfileEx_Request(client, target);
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
	Handle menu = CreateMenu(ReadProfilesMenuHandle);
	ClearArray(RPGMenuPosition[client]);

	char text[512];
	char pos[10];
	char result[3][64];

	Format(text, sizeof(text), "%T", "profile editor title", client, LoadoutName[client]);
	SetMenuTitle(menu, text);

	int size = GetArraySize(PlayerProfiles[client]);
	if (size < 1) {

		PrintToChat(client, "%T", "no profiles to load", client, orange);
		ProfileEditorMenu(client);
		return;
	}
	for (int i = 0; i < size; i++) {

		GetArrayString(PlayerProfiles[client], i, text, sizeof(text));
		ExplodeString(text, "+", result, 3, 64);
		AddMenuItem(menu, result[1], result[1]);

		Format(pos, sizeof(pos), "%d", i);
		PushArrayString(RPGMenuPosition[client], pos);
	}
	SetMenuExitBackButton(menu, true);
	DisplayMenu(menu, client, 0);
}

public ReadProfilesMenuHandle(Handle menu, MenuAction action, client, slot) {

	if (action == MenuAction_Select) {

		char text[512];
		GetArrayString(RPGMenuPosition[client], slot, text, sizeof(text));
		int pos = StringToInt(text);

		//new target = client;
		//if (LoadTarget[client] != -1 && LoadTarget[client] != client) target = LoadTarget[client]; 
		// && (IsSurvivorBot(LoadTarget[client]) || !bIsInCombat[LoadTarget[client]]))

		if (pos < GetArraySize(PlayerProfiles[client])) {
			//(!bIsInCombat[client] || target != client) &&

			GetArrayString(PlayerProfiles[client], pos, text, sizeof(text));
			char result[3][64];
			ExplodeString(text, "+", result, 3, 64);
			LoadProfile_Confirm(client, text, result[1]);
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

public void SpawnLoadoutEditor(client) {
	if (GetArraySize(hWeaponList[client]) != 2) ResizeArray(hWeaponList[client], 2);

	Handle menu		= CreateMenu(SpawnLoadoutEditorHandle);

	char text[512];
	Format(text, sizeof(text), "%T", "profile editor title", client, LoadoutName[client]);
	SetMenuTitle(menu, text);

	GetArrayString(hWeaponList[client], 0, text, sizeof(text));
	if (!QuickCommandAccessEx(client, text, _, _, true)) Format(text, sizeof(text), "%T", "No Weapon Equipped", client);
	else Format(text, sizeof(text), "%T", text, client);
	Format(text, sizeof(text), "%T", "Primary Weapon", client, text);
	AddMenuItem(menu, text, text);

	GetArrayString(hWeaponList[client], 1, text, sizeof(text));
	if (!QuickCommandAccessEx(client, text, _, _, true)) Format(text, sizeof(text), "%T", "No Weapon Equipped", client);
	else Format(text, sizeof(text), "%T", text, client);
	Format(text, sizeof(text), "%T", "Secondary Weapon", client, text);
	AddMenuItem(menu, text, text);

	SetMenuExitBackButton(menu, true);
	DisplayMenu(menu, client, 0);
}

public SpawnLoadoutEditorHandle(Handle menu, MenuAction action, client, slot) {

	if (action == MenuAction_Select) {

		char menuname[64];
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

stock void GetProfileLoadoutConfig(int client, char[] TheString, int thesize) {

	char config[64];
	int size = GetArraySize(a_Menu_Main);

	for (int i = 0; i < size; i++) {

		LoadoutConfigKeys[client]		= GetArrayCell(a_Menu_Main, i, 0);
		LoadoutConfigValues[client]		= GetArrayCell(a_Menu_Main, i, 1);
		LoadoutConfigSection[client]	= GetArrayCell(a_Menu_Main, i, 2);

		FormatKeyValue(config, sizeof(config), LoadoutConfigKeys[client], LoadoutConfigValues[client], "config?");
		if (!StrEqual(sProfileLoadoutConfig, config)) continue;

		GetArrayString(LoadoutConfigSection[client], 0, TheString, thesize);
		break;
	}
	return;
}

stock bool IsProfileLevelTooHigh(client) {
	if (PlayerUpgradesTotal[client] + FreeUpgrades[client] > MaximumPlayerUpgrades(client)) return true;
	return false;
}