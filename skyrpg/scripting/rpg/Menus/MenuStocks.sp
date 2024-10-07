/* put the line below after all of the includes!
#pragma newdecls required
*/

stock bool CheckKillPositions(client, bool b_AddPosition = false) {

	// If the finale is active, we don't do anything here, and always return false.
	//if (!b_IsFinaleActive) return false;
	// If there are enemy combatants within range - and thus the player is fighting - don't save locations.
	//if (EnemyCombatantsWithinRange(client, StringToFloat(GetConfigValue("out of combat distance?")))) return false;

	// If not adding a kill position, it means we need to check the clients current position against all positions in the list, and see if any are within the config value.
	// If they are, we return true, otherwise false.
	// If we are adding a position, we check to see if the size is greater than the max value in the config. If it is, we remove the oldest entry, and add the newest entry.
	// We can do this by removing from array, or just resizing the array to the config value after adding the value.

	float Origin[3];
	GetClientAbsOrigin(client, Origin);
	char coords[64];

	if (!b_AddPosition) {

		float Last_Origin[3];
		int size				= GetArraySize(h_KilledPosition_X[client]);
		
		for (int i = 0; i < size; i++) {

			GetArrayString(h_KilledPosition_X[client], i, coords, sizeof(coords));
			Last_Origin[0]		= StringToFloat(coords);
			GetArrayString(h_KilledPosition_Y[client], i, coords, sizeof(coords));
			Last_Origin[1]		= StringToFloat(coords);
			GetArrayString(h_KilledPosition_Z[client], i, coords, sizeof(coords));
			Last_Origin[2]		= StringToFloat(coords);

			// If the players current position is too close to any stored positions, return true
			if (GetVectorDistance(Origin, Last_Origin) <= fAntiFarmDistance) return true;
		}
	}
	else {

		int newsize = GetArraySize(h_KilledPosition_X[client]);

		ResizeArray(h_KilledPosition_X[client], newsize + 1);
		Format(coords, sizeof(coords), "%3.4f", Origin[0]);
		SetArrayString(h_KilledPosition_X[client], newsize, coords);

		ResizeArray(h_KilledPosition_Y[client], newsize + 1);
		Format(coords, sizeof(coords), "%3.4f", Origin[1]);
		SetArrayString(h_KilledPosition_Y[client], newsize, coords);

		ResizeArray(h_KilledPosition_Z[client], newsize + 1);
		Format(coords, sizeof(coords), "%3.4f", Origin[2]);
		SetArrayString(h_KilledPosition_Z[client], newsize, coords);

		while (GetArraySize(h_KilledPosition_X[client]) > iAntiFarmMax) {
			RemoveFromArray(h_KilledPosition_X[client], 0);
			RemoveFromArray(h_KilledPosition_Y[client], 0);
			RemoveFromArray(h_KilledPosition_Z[client], 0);
		}
	}
	return false;
}
/*
int TheTalentStrength = GetArrayCell(MyTalentStrength[client], i);
			if (TheTalentStrength < 1) continue;
			*/
stock bool HasTalentUpgrades(client, char[] TalentName) {

	if (IsLegitimateClient(client)) {

		int a_Size			=	0;

		a_Size		= GetArraySize(a_Menu_Talents);

		char TalentName_Compare[64];

		for (int i = 0; i < a_Size; i++) {
			if (GetArrayCell(MyTalentStrength[client], i) < 1) continue;
			GetArrayString(a_Database_Talents, i, TalentName_Compare, sizeof(TalentName_Compare));
			if (StrEqual(TalentName, TalentName_Compare, false)) return true;
		}
	}
	return false;
}

bool SetPlayerDatabaseArray(client, bool override = false) {
	int size = GetArraySize(a_Menu_Talents);
	if (override ||
		GetArraySize(a_Database_PlayerTalents[client]) != size ||
		GetArraySize(PlayerAbilitiesCooldown[client]) != size ||
		GetArraySize(a_Database_PlayerTalents_Experience[client]) != size ||
		GetArraySize(PlayerActiveAbilitiesCooldown[client]) != size) {
		ResizeArray(PlayerAbilitiesCooldown[client], size);
		ResizeArray(a_Database_PlayerTalents[client], size);
		ResizeArray(a_Database_PlayerTalents_Experience[client], size);
		ResizeArray(PlayerActiveAbilitiesCooldown[client], size);
		for (int i = 0; i < size; i++) {
			SetArrayCell(a_Database_PlayerTalents[client], i, 0);
			SetArrayCell(PlayerAbilitiesCooldown[client], i, 0);
			SetArrayCell(a_Database_PlayerTalents_Experience[client], i, 0);
			SetArrayCell(PlayerActiveAbilitiesCooldown[client], i, 0);
		}
		return true;
	}
	return false;
}

stock AddMenuStructure(client, char[] MenuName) {

	ResizeArray(MenuStructure[client], GetArraySize(MenuStructure[client]) + 1);
	SetArrayString(MenuStructure[client], GetArraySize(MenuStructure[client]) - 1, MenuName);
}

stock GetNodesInExistence() {
	if (nodesInExistence > 0) return nodesInExistence;
	int size			=	GetArraySize(a_Menu_Talents);
	nodesInExistence	=	0;
	int nodeLayer		=	0;	// this will hide nodes not currently available from players total node count.
	for (int i = 0; i < size; i++) {
		//SetNodesKeys			=	GetArrayCell(a_Menu_Talents, i, 0);
		SetNodesValues			=	GetArrayCell(a_Menu_Talents, i, 1);
		if (GetArrayCell(SetNodesValues, IS_SUB_MENU_OF_TALENTCONFIG) == 1) continue;
		nodeLayer = GetArrayCell(SetNodesValues, GET_TALENT_LAYER);
		if (nodeLayer >= 1 && nodeLayer <= iMaxLayers) nodesInExistence++;
	}
	if (StrContains(Hostname, "{N}", true) != -1) {
		char nodetext[10];
		Format(nodetext, sizeof(nodetext), "%d", nodesInExistence);
		ReplaceString(Hostname, sizeof(Hostname), "{N}", nodetext);
		ServerCommand("hostname %s", Hostname);
	}
	return nodesInExistence;
}

stock PlayerTalentLevel(client) {

	int PTL = RoundToFloor((((PlayerUpgradesTotal[client] * 1.0) + FreeUpgrades[client]) / PlayerLevel[client]) * PlayerLevel[client]);
	if (PTL < 0) PTL = 0;

	return PTL;
	//return PlayerLevel[client];
}

stock float PlayerBuffLevel(client) {

	float PBL = ((PlayerUpgradesTotal[client] * 1.0) + FreeUpgrades[client]) / PlayerLevel[client];
	PBL = 1.0 - PBL;
	//PBL = PBL * 100.0;
	if (PBL < 0.0) PBL = 0.0; // This can happen if a player uses free upgrades, so, yeah...
	return PBL;
}

stock MaximumPlayerUpgrades(client, bool getNodeCountInstead = false) {

	if (!getNodeCountInstead) {
		if (SkyLevel[client] < 1 || iSkyLevelMax < 1) return (iMaxServerUpgrades < 0 || PlayerLevel[client] + iStartingPlayerUpgrades < iMaxServerUpgrades)
																? PlayerLevel[client] + iStartingPlayerUpgrades
																: iMaxServerUpgrades;
		int count = 0;
		for (int i = 1; i < SkyLevel[client] + 1; i++) {
			count += GetPrestigeLevelNodeUnlocks(i);
		}
		int upgradesAllowed = count + PlayerLevel[client] + iStartingPlayerUpgrades;
		return (iMaxServerUpgrades < 0 || upgradesAllowed <= iMaxServerUpgrades) ? upgradesAllowed : iMaxServerUpgrades;
	}
	return nodesInExistence;
}

stock VerifyMaxPlayerUpgrades(client) {

	if (PlayerUpgradesTotal[client] + FreeUpgrades[client] > MaximumPlayerUpgrades(client)) {
		//PrintToChat(client, "resetting talents: %d of %d (%d)", PlayerUpgradesTotal[client], FreeUpgrades[client], MaximumPlayerUpgrades(client));
		FreeUpgrades[client]								=	MaximumPlayerUpgrades(client);
		UpgradesAvailable[client]							=	0;
		PlayerUpgradesTotal[client]							=	0;
		WipeTalentPoints(client);
	}
}

stock UpgradesUsed(client, char[] text, size) {
	Format(text, size, "%T", "Upgrades Used", client);
	Format(text, size, "(%s: %d / %d)", text, PlayerUpgradesTotal[client], MaximumPlayerUpgrades(client));
}

stock bool TalentListingFound(client, Handle Values, char[] MenuName, bool IsAllowItems = false) {
	char value[64];
	GetArrayString(Values, PART_OF_MENU_NAMED, value, sizeof(value));
	if (!StrEqual(MenuName, value)) return false;
	return true;
}

// Need to convert the points module to the new memoized structure, but until then...
stock bool TalentListingFoundForPoints(client, Handle Keys, Handle Values, char[] MenuName, bool IsAllowItems = false) {

	int size = GetArraySize(Keys);

	char key[64];
	char value[64];

	for (int i = 0; i < size; i++) {

		GetArrayString(Keys, i, key, sizeof(key));
		if (StrEqual(key, "part of menu named?")) {

			GetArrayString(Values, i, value, sizeof(value));
			if (!StrEqual(MenuName, value)) return false;
		}
		if (StrEqual(key, "flags?")) {

			GetArrayString(Values, i, value, sizeof(value));
			if (!StrEqual(value, "none", false) && !HasCommandAccess(client, value)) return false;
		}
	}
	return true;
}

stock GetTalentLevel(client, char[] TalentName, bool IsExperience = false) {

	int pos = GetTalentPosition(client, TalentName);
	int value = 0;

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

stock TryToTellPeopleYouUpgraded(client) {

	if (FreeUpgrades[client] == 0 && GetConfigValueInt("display when players upgrade to team?") == 1) {

		char text2[512];
		char PlayerName[64];
		char translationText[512];
		GetFormattedPlayerName(client, PlayerName, sizeof(PlayerName));
		GetTranslationOfTalentName(client, PurchaseTalentName[client], translationText, sizeof(translationText), true);
		Format(text2, sizeof(text2), "%t", translationText);
		Format(text2, sizeof(text2), "%t", "Player upgrades ability", PlayerName, text2);
		for (int i = 1; i <= MaxClients; i++) {
			if (!IsLegitimateClient(i) || IsFakeClient(i)) continue;
			Client_PrintToChat(i, true, text2);
		}
	}
}

stock FindTalentPoints(client, char[] Name) {

	char text[64];

	int a_Size							=	GetArraySize(a_Database_Talents);

	for (int i = 0; i < a_Size; i++) {

		GetArrayString(a_Database_Talents, i, text, sizeof(text));

		if (StrEqual(text, Name)) {

			if (client != -1) GetArrayString(a_Database_PlayerTalents[client], i, text, sizeof(text));
			else GetArrayString(a_Database_PlayerTalents_Bots, i, text, sizeof(text));
			return StringToInt(text);
		}
	}
	//return -1;	// this is to let us know to setfailstate.
	return 0;	// this will be removed. only for testing.
}

stock AddTalentPoints(client, int menuPos, TalentPoints) {
	if (!IsLegitimateClient(client)) return;
	char text[64];
	SetArrayCell(a_Database_PlayerTalents[client], menuPos, TalentPoints);
	GetTalentKeyValue(client, IS_TALENT_ABILITY, text, sizeof(text), menuPos);
	if (StringToInt(text) == 1) return;

	if (TalentPoints == 0) RemoveTalentFromPossibleLootPool(client, menuPos);
	else if (TalentPoints == 1) PushArrayCell(possibleLootPool[client], menuPos);
}

stock RemoveTalentFromPossibleLootPool(client, value) {
	for (int i = 0; i < GetArraySize(possibleLootPool[client]); i++) {
		if (GetArrayCell(possibleLootPool[client], i) != value) continue;
		RemoveFromArray(possibleLootPool[client], i);
		break;
	}
}

stock UnlockTalent(client, char[] Name, bool bIsEndOfMapRoll = false, bool bIsLegacy = false) {

	char text[64];
	char PlayerName[64];
	GetClientName(client, PlayerName, sizeof(PlayerName));

	int size			= GetArraySize(a_Database_Talents);

	for (int i = 0; i < size; i++) {

		GetArrayString(a_Database_Talents, i, text, sizeof(text));
		if (StrEqual(text, Name)) {

			SetArrayCell(a_Database_PlayerTalents[client], i, 0);

			if (!bIsLegacy) {		// We advertise elsewhere if it's a legacy roll.

				for (int ii = 1; ii <= MaxClients; ii++) {

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

stock bool IsTalentExists(char[] Name) {

	char text[64];
	int size			= GetArraySize(a_Database_Talents);
	for (int i = 0; i < size; i++) {

		GetArrayString(a_Database_Talents, i, text, sizeof(text));
		if (StrEqual(text, Name)) return true;
	}
	return false;
}

stock bool IsTalentLocked(client, char[] Name) {

	int value = 0;
	char text[64];

	int size			= GetArraySize(a_Database_Talents);

	for (int i = 0; i < size; i++) {

		GetArrayString(a_Database_Talents, i, text, sizeof(text));
		if (StrEqual(text, Name)) {

			value = GetArrayCell(a_Database_PlayerTalents[client], i);

			if (value >= 0) return false;
			break;
		}
	}

	return true;
}

stock WipeTalentPoints(client) {
	int size = GetArraySize(a_Menu_Talents);
	if (!IsLegitimateClient(client) || GetArraySize(a_Database_PlayerTalents[client]) != size) return;
	UpgradesAwarded[client] = 0;
	int value = 0;
	for (int i = 0; i < size; i++) {
		value = GetArrayCell(a_Database_PlayerTalents[client], i);
		if (value > 0) SetArrayCell(a_Database_PlayerTalents[client], i, 0);
	}
	ClearArray(possibleLootPool[client]);
	ClearArray(unlockedLootPool[client]);
	SetClientTalentStrength(client);
}