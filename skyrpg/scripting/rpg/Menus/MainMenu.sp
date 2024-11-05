stock BuildMenu(client, char[] TheMenuName = "none") {

	if (b_IsLoading[client]) {

		PrintToChat(client, "%T", "loading data cannot open menu", client, orange);
		return;
	}

	char MenuName[64];
	if (StrEqual(TheMenuName, "none", false) && GetArraySize(MenuStructure[client]) > 0) {

		GetArrayString(MenuStructure[client], GetArraySize(MenuStructure[client]) - 1, MenuName, sizeof(MenuName));
		RemoveFromArray(MenuStructure[client], GetArraySize(MenuStructure[client]) - 1);
	}
	else Format(MenuName, sizeof(MenuName), "%s", TheMenuName);
	ShowPlayerLayerInformation[client] = (StrEqual(MenuName, "talentsmenu")) ? true : false;
	VerifyMaxPlayerUpgrades(client);
	ClearArray(RPGMenuPosition[client]);

	// Build the base menu
	Handle menu		= CreateMenu(BuildMenuHandle);
	// Keep track of the position selected.
	char pos[64];

	if (!b_IsDirectorTalents[client]) BuildMenuTitle(client, menu, _, 0, _, ShowPlayerLayerInformation[client]);
	else BuildMenuTitle(client, menu, 1, _, _, ShowPlayerLayerInformation[client]);

	char text[PLATFORM_MAX_PATH];
	// declare the variables for requirements to display in menu.
	char teamsAllowed[64];
	char gamemodesAllowed[64];
	char flagsAllowed[64];
	char currentGamemode[4];
	char clientTeam[4];
	char configname[64];

	char t_MenuName[64];
	char c_MenuName[64];

	//PrintToChatAll("Menu named: %s", MenuName);


	char s_TalentDependency[64];
	// Collect player team and server gamemode.
	Format(currentGamemode, sizeof(currentGamemode), "%d", ReadyUpGameMode);
	Format(clientTeam, sizeof(clientTeam), "%d", myCurrentTeam[client]);

	int size	= GetArraySize(a_Menu_Main);
	int CurRPGMode = iRPGMode;
	int XPRequired = CheckExperienceRequirement(client);
	//new ActionBarOption = -1;

	char pct[4];
	Format(pct, sizeof(pct), "%");

	int iIsReadMenuName = 0;
	int iHasLayers = 0;
	int strengthOfCurrentLayer = 0;

	char sCvarRequired[64];
	char sCatRepresentation[64];

	char translationInfo[64];

	char formattedText[64];
	float fPercentageHealthRequired;
	float fPercentageHealthRequiredMax;
	float fPercentageHealthRequiredBelow;
	float fCoherencyRange;
	int iCoherencyMax = 0;
	for (int i = 0; i < size; i++) {

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
		bool configIsForTalents = (IsTalentConfig(configname) || StrEqual(configname, CONFIG_SURVIVORTALENTS));
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
		if (StrEqual(configname, "level up") && PlayerLevel[client] == iMaxLevel) continue;
		if (StrEqual(configname, "autolevel toggle") && iAllowPauseLeveling != 1) continue;
		if (StrEqual(configname, "prestige") && (SkyLevel[client] >= iSkyLevelMax || PlayerLevel[client] < iMaxLevel)) continue;
		// if (StrEqual(configname, "handicap") && PlayerLevel[client] < iLevelRequiredToEarnScore) continue;
		//if (StrEqual(configname, "respec", false) && bIsInCombat[client] && b_IsActiveRound) continue;

		// If director talent menu options is enabled by an admin, only specific options should show. We determine this here.
		if (b_IsDirectorTalents[client]) {
			if (configIsForTalents ||
			StrEqual(configname, CONFIG_POINTS) ||
			b_IsDirectorTalents[client] && StrEqual(configname, "level up") ||
			PlayerLevel[client] >= iMaxLevel && StrEqual(configname, "prestige") ||
			StrEqual(MenuName, c_MenuName, false)) {
				Format(pos, sizeof(pos), "%d", i);
				PushArrayString(RPGMenuPosition[client], pos);
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
			else if (StrEqual(configname, "lootmode toggle")) {
				if (iForceFFALoot == 1) continue;
				if (iDontAllowLootStealing[client] == 3) Format(text, sizeof(text), "%T", "ffa loot (disabled)", client);
				else if (iDontAllowLootStealing[client] == 2) Format(text, sizeof(text), "%T", "ffa loot (all)", client);
				else if (iDontAllowLootStealing[client] == 1) Format(text, sizeof(text), "%T", "ffa loot (major)", client);
				else if (iDontAllowLootStealing[client] == 0) Format(text, sizeof(text), "%T", "ffa loot (minor)", client);
			}
			else if (StrEqual(configname, "lootdrop toggle")) {
				int curUpgrades = GetArraySize(possibleLootPool[client]);
				if (iLootDropsForUnlockedTalentsOnly[client] == 1 && curUpgrades >= iUpgradesRequiredForLoot) Format(text, sizeof(text), "%T", "priority loot mode", client);
				else {
					Format(text, sizeof(text), "%T", "unlocked loot mode", client);
					if (curUpgrades < iUpgradesRequiredForLoot) Format(text, sizeof(text), "%T", "note about unlocking priority loot mode", client, text, iUpgradesRequiredForLoot - curUpgrades);
				}
			}
			else if (StrEqual(configname, "level up")) {

				//if (!b_IsDirectorTalents[client]) {

				//if (PlayerUpgradesTotal[client] < MaximumPlayerUpgrades(client)) continue; //Format(text, sizeof(text), "%T", "level up unavailable", client, MaximumPlayerUpgrades(client) - PlayerUpgradesTotal[client]);
				if (iIsLevelingPaused[client] == 1) {

					if (ExperienceLevel[client] >= XPRequired) {
						AddCommasToString(XPRequired, formattedText, sizeof(formattedText));
						Format(text, sizeof(text), "%T", "level up available", client, formattedText);
					}
					else {
						AddCommasToString(XPRequired - ExperienceLevel[client], formattedText, sizeof(formattedText));
						Format(text, sizeof(text), "%T", "level up unavailable", client, formattedText);
					}
				}
				else continue;
			}
			else if (StrEqual(configname, "prestige") && SkyLevel[client] < iSkyLevelMax && PlayerLevel[client] == iMaxLevel) {// we now require players to be max level to see the prestige information.
				Format(text, sizeof(text), "%T", "prestige up available", client, GetPrestigeLevelNodeUnlocks(SkyLevel[client]));
			}
			else if (StrEqual(configname, "showtreelayers")) {
				int[] upgradesRequiredToUnlockThisLayer = new int[iMaxLayers+1];
				for (int currentLayer = 1; currentLayer <= iMaxLayers; currentLayer++) {
					int totalNodesThisLayer = GetLayerUpgradeStrength(client, currentLayer, _, _, _, true);
					if (totalNodesThisLayer < 1) continue;
					strengthOfCurrentLayer = GetLayerUpgradeStrength(client, currentLayer);
					int totalUpgradesRequiredToUnlockNextLayer = (fUpgradesRequiredPerLayer <= 1.0) ? RoundToCeil(totalNodesThisLayer * fUpgradesRequiredPerLayer) : RoundToCeil(fUpgradesRequiredPerLayer);
					upgradesRequiredToUnlockThisLayer[currentLayer] = (totalUpgradesRequiredToUnlockNextLayer > strengthOfCurrentLayer)
														? totalUpgradesRequiredToUnlockNextLayer - strengthOfCurrentLayer
														: 0;
					int totalUpgradesRequiredThisLayer = 0;
					for (int layer = 1; layer < currentLayer; layer++) totalUpgradesRequiredThisLayer += upgradesRequiredToUnlockThisLayer[layer];
					if (currentLayer == 1 || totalUpgradesRequiredThisLayer == 0) {
						Format(text, sizeof(text), "%T", "show tree layers", client, currentLayer, strengthOfCurrentLayer, totalUpgradesRequiredToUnlockNextLayer, totalNodesThisLayer);
					}
					else {
						if (totalUpgradesRequiredThisLayer == 1) Format(text, sizeof(text), "%T", "show tree layers single (locked)", client, currentLayer, totalNodesThisLayer, totalUpgradesRequiredThisLayer);
						else Format(text, sizeof(text), "%T", "show tree layers (locked)", client, currentLayer, totalNodesThisLayer, totalUpgradesRequiredThisLayer);
					}
					AddMenuItem(menu, text, text);
					Format(pos, sizeof(pos), "%d", i);
					PushArrayString(RPGMenuPosition[client], pos);
				}
				continue;
			}
			else if (StrEqual(configname, "layerup")) {
				//if (PlayerCurrentMenuLayer[client] <= 1) Format(text, sizeof(text), "%T", "lowest layer reached", client);
				//else
				if (PlayerCurrentMenuLayer[client] > 1) Format(text, sizeof(text), "%T", "layer move", client, PlayerCurrentMenuLayer[client] - 1);
				else continue;
			}
			else if (StrEqual(configname, "layerdown")) {
				//if (PlayerCurrentMenuLayer[client] >= iMaxLayers) Format(text, sizeof(text), "%T", "highest layer reached", client);
				//else {
				if (PlayerCurrentMenuLayer[client] < iMaxLayers) {
					if (PlayerCurrentMenuLayer[client] < 1) PlayerCurrentMenuLayer[client] = 1;
					strengthOfCurrentLayer = GetLayerUpgradeStrength(client, PlayerCurrentMenuLayer[client]);
					int layerUpgradesRequired = GetLayerUpgradeStrength(client, PlayerCurrentMenuLayer[client], _, _, _, true);
					layerUpgradesRequired = (fUpgradesRequiredPerLayer <= 1.0) ? RoundToCeil(layerUpgradesRequired * fUpgradesRequiredPerLayer) : RoundToCeil(fUpgradesRequiredPerLayer);
					if (strengthOfCurrentLayer >= layerUpgradesRequired) Format(text, sizeof(text), "%T", "layer move", client, PlayerCurrentMenuLayer[client] + 1);
					else Format(text, sizeof(text), "%T", "layer move locked", client, PlayerCurrentMenuLayer[client] + 1, PlayerCurrentMenuLayer[client], layerUpgradesRequired - strengthOfCurrentLayer);
				}
				else continue;
			}
		}
		else {
			GetArrayString(MenuSection[client], 0, text, sizeof(text));
			//if (iHasLayers < 1) {
			Format(text, sizeof(text), "%T", text, client);
			/*}
			else {
				Format(text, sizeof(text), "%T", text, PlayerCurrentMenuLayer[client], client);
			}*/
		}
		FormatKeyValue(sCatRepresentation, sizeof(sCatRepresentation), MenuKeys[client], MenuValues[client], "talent tree category?");
		if (!StrEqual(sCatRepresentation, "-1")) {
			int iMaxCategoryStrength = 0;
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
			Format(pos, sizeof(pos), "%d", i);
			PushArrayString(RPGMenuPosition[client], pos);
		}
		if (!StrEqual(translationInfo, "-1")) {
			fPercentageHealthRequired = GetArrayCell(MenuValues[client], HEALTH_PERCENTAGE_REQ_MISSING);
			fPercentageHealthRequiredBelow = GetArrayCell(MenuValues[client], HEALTH_PERCENTAGE_REQ);
			fCoherencyRange = GetArrayCell(MenuValues[client], COHERENCY_RANGE);
			iCoherencyMax = GetArrayCell(PurchaseValues[client], COHERENCY_MAX);
			if (fPercentageHealthRequired > 0.0 || fPercentageHealthRequiredBelow > 0.0 || fCoherencyRange > 0.0) {
				fPercentageHealthRequiredMax = GetArrayCell(MenuValues[client], HEALTH_PERCENTAGE_REQ_MISSING_MAX);
				Format(translationInfo, sizeof(translationInfo), "%T", translationInfo, client, fPercentageHealthRequired * 100.0, pct, fPercentageHealthRequiredMax * 100.0, pct, fPercentageHealthRequiredBelow * 100.0, pct, fCoherencyRange, iCoherencyMax);
			}
			else Format(translationInfo, sizeof(translationInfo), "%T", translationInfo, client);
			Format(text, sizeof(text), "%s\n%s", text, translationInfo);
		}
		int addLayerToTranslation = GetKeyValueInt(MenuKeys[client], MenuValues[client], "add layer to menu option?");
		if (addLayerToTranslation == 1) Format(text, sizeof(text), "%s %d", text, PlayerCurrentMenuLayer[client]);

		AddMenuItem(menu, text, text);
	}
	if (!StrEqual(MenuName, "main", false)) SetMenuExitBackButton(menu, true);
	else SetMenuExitBackButton(menu, false);
	DisplayMenu(menu, client, 0);
}

public BuildMenuHandle(Handle menu, MenuAction action, int client, int slot) {

	if (action == MenuAction_Select)
	{
		// Declare variables for target config, menu name (some submenu's require this information) and the ACTUAL position for a slot
		// (as pos won't always line up with slot since items can be hidden under special circumstances.)
		char config[64];
		char menuname[64];
		char pos[4];

		char t_MenuName[64];
		char c_MenuName[64];

		char Name[64];

		char sCvarRequired[64];

		int XPRequired = CheckExperienceRequirement(client);
		int iIsIgnoreHeader = 0;
		int iHasLayers = 0;
		//new isSubMenu = 0;

		// Get the real position to use based on the slot that was pressed.
		// This position was stored above in the accompanying menu function.
		GetArrayString(RPGMenuPosition[client], slot, pos, sizeof(pos));
		MenuKeys[client]			= GetArrayCell(a_Menu_Main, StringToInt(pos), 0);
		MenuValues[client]			= GetArrayCell(a_Menu_Main, StringToInt(pos), 1);
		MenuSection[client]			= GetArrayCell(a_Menu_Main, StringToInt(pos), 2);
		GetArrayString(MenuSection[client], 0, menuname, sizeof(menuname));

		int showLayerInfo = GetKeyValueInt(MenuKeys[client], MenuValues[client], "show layer info?");

		// We want to know the value of the target config based on the keys and values pulled.
		// This will be used to determine where we send the player.
		FormatKeyValue(config, sizeof(config), MenuKeys[client], MenuValues[client], "config?");
		bool configIsForTalents = (IsTalentConfig(config) || StrEqual(config, CONFIG_SURVIVORTALENTS));
		FormatKeyValue(t_MenuName, sizeof(t_MenuName), MenuKeys[client], MenuValues[client], "target menu?");
		FormatKeyValue(c_MenuName, sizeof(c_MenuName), MenuKeys[client], MenuValues[client], "menu name?");

		iIsIgnoreHeader = GetKeyValueInt(MenuKeys[client], MenuValues[client], "ignore header name?");
		iHasLayers = GetKeyValueInt(MenuKeys[client], MenuValues[client], "layers?");

		FormatKeyValue(sCvarRequired, sizeof(sCvarRequired), MenuKeys[client], MenuValues[client], "cvar_required?");
		//isSubMenu = GetKeyValueInt(MenuKeys[client], MenuValues[client], "is sub menu?");
		// we only modify the value if it's set, otherwise it's grandfathered.
		ShowPlayerLayerInformation[client] = (showLayerInfo == 1) ? true : false;
		// if (showLayerInfo == 1) ShowPlayerLayerInformation[client] = true;
		// else if (showLayerInfo == 0) ShowPlayerLayerInformation[client] = false;
		
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
		else if (StrEqual(config, "lootmode toggle", false)) {
			if (iDontAllowLootStealing[client] == 3) iDontAllowLootStealing[client] = 0;
			else iDontAllowLootStealing[client]++;
			BuildMenu(client);
		}
		else if (StrEqual(config, "lootdrop toggle")) {
			if (iLootDropsForUnlockedTalentsOnly[client] == 0 && GetArraySize(possibleLootPool[client]) >= iUpgradesRequiredForLoot) iLootDropsForUnlockedTalentsOnly[client] = 1;
			else iLootDropsForUnlockedTalentsOnly[client] = 0;
			BuildMenu(client);
		}
		else if (StrEqual(config, "inv_augments", false)) {
			if (GetArraySize(myAugmentIDCodes[client]) > 0) Augments_Inventory(client);
			else BuildMenu(client);
		}
		else if (StrEqual(config, "level up", false) && PlayerLevel[client] < iMaxLevel) {

			if (iIsLevelingPaused[client] == 1 && ExperienceLevel[client] >= XPRequired) ConfirmExperienceAction(client, _, true);
			BuildMenu(client);
		}
		else if (StrEqual(config, "showtreelayers")) {
			PlayerCurrentMenuLayer[client] = slot+1;
			BuildMenu(client, t_MenuName);
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
			if (PlayerLevel[client] >= iMaxLevel && SkyLevel[client] < iSkyLevelMax) {
				PlayerLevel[client] = 1;
				SkyLevel[client]++;
				ExperienceLevel[client] = 0;
				GetClientName(client, Name, sizeof(Name));
				PrintToChatAll("%t", "player sky level up", green, white, blue, Name, SkyLevel[client]);
				ChallengeEverything(client);
				SavePlayerData(client);
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
		else if (StrEqual(config, "handicap", false)) {
			HandicapMenu(client);
		}
		else if (StrEqual(config, "leaderboards", false)) {

			bIsMyRanking[client] = true;
			TheLeaderboardsPage[client] = 0;
			LoadLeaderboards(client, 0);
		}
		else if (StrEqual(config, "respec", false)) {

			ChallengeEverything(client);
			iLootDropsForUnlockedTalentsOnly[client] = 0;
			BuildMenu(client);
		}
		else if (StrEqual(config, "threatmeter", false)) {

			//ShowThreatMenu(client);
			bIsHideThreat[client] = false;
		}
		else if (GetArraySize(a_Store) > 0 && StrEqual(config, CONFIG_STORE)) {

			BuildStoreMenu(client);
		}
		else if (configIsForTalents) {

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
		else if (StrEqual(config, "proficiency", false)) {
			LoadProficiencyData(client);
		}
		else if (StrEqual(config, "attributes", false)) {
			LoadAttributesMenu(client);
		}
		else if (StrEqual(config, "nohandicap", false) && handicapLevel[client] >= 0) {
			handicapLevel[client] = -1;
			BuildMenu(client);
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