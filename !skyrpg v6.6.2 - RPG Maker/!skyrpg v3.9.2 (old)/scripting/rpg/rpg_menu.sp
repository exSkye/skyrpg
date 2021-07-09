stock BuildMenuTitle(client, Handle:menu, bot = 0, type = 0) {	// 0 is legacy type that appeared on all menus. 0 - Main Menu | 1 - Upgrades | 2 - Points

	decl String:text[512];

	if (bot == 0) {

		decl String:PointsText[64];
		Format(PointsText, sizeof(PointsText), "%T", "Points Text", client, Points[client]);

		new CheckRPGMode = StringToInt(GetConfigValue("rpg mode?"));
		decl String:PlayerLevelText[64];
		Format(PlayerLevelText, sizeof(PlayerLevelText), "%T", "Player Level Text", client, PlayerLevel[client], AddCommasToString(ExperienceLevel[client]), MenuExperienceBar(client), AddCommasToString(CheckExperienceRequirement(client)));
		if (CheckRPGMode != 0) Format(text, sizeof(text), "%T", "RPG Header", client, UpgradesUsed(client), PlayerLevelText, UpgradesAvailable[client], AddCommasToString(GetUpgradeExperienceCost(client)), SkyPoints[client]);
		if (CheckRPGMode != 1) Format(text, sizeof(text), "%s\n%s", text, PointsText);

		decl String:text2[512];
		if (FreeUpgrades[client] > 0) {

			Format(text2, sizeof(text2), "%T", "Free Upgrades", client);
			Format(text, sizeof(text), "%s\n%s: %d", text, text2, FreeUpgrades[client]);
		}

		new RestedExperienceMaximum = StringToInt(GetConfigValue("rested experience maximum?"));
		if (RestedExperienceMaximum < 1) RestedExperienceMaximum = CheckExperienceRequirement(client);
		if (RestedExperience[client] > 0) Format(text, sizeof(text), "%T", "Menu Rested Experience", client, text, AddCommasToString(RestedExperience[client]), AddCommasToString(RestedExperienceMaximum), RoundToCeil(100.0 * StringToFloat(GetConfigValue("rested experience multiplier?"))));
		if (ExperienceDebt[client] > 0 && StringToInt(GetConfigValue("experience debt enabled?")) == 1 && PlayerLevel[client] >= StringToInt(GetConfigValue("experience debt level?"))) {

			Format(text, sizeof(text), "%T", "Menu Experience Debt", client, text, AddCommasToString(ExperienceDebt[client]), RoundToCeil(100.0 * StringToFloat(GetConfigValue("experience debt penalty?"))));
		}
	}
	else {

		if (StringToInt(GetConfigValue("rpg mode?")) == 0 || StringToInt(GetConfigValue("rpg mode?")) == 2 && bot == -1) Format(text, sizeof(text), "%T", "Menu Header 0 Director", client, Points_Director);
		else if (StringToInt(GetConfigValue("rpg mode?")) == 1) {

			// Bots level up strictly based on experience gain. Honestly, I have been thinking about removing talent-based leveling.
			Format(text, sizeof(text), "%T", "Menu Header 1 Talents Bot", client, PlayerLevel_Bots, StringToInt(GetConfigValue("max level?")), AddCommasToString(ExperienceLevel_Bots), AddCommasToString(CheckExperienceRequirement(-1, true)), AddCommasToString(GetUpgradeExperienceCost(-1)));
		}
		else if (StringToInt(GetConfigValue("rpg mode?")) == 2) {

			Format(text, sizeof(text), "%T", "Menu Header 2 Talents Bot", client, PlayerLevel_Bots, StringToInt(GetConfigValue("max level?")), AddCommasToString(ExperienceLevel_Bots), AddCommasToString(CheckExperienceRequirement(-1, true)), AddCommasToString(GetUpgradeExperienceCost(-1)), Points_Director);
		}
	}
	ReplaceString(text, sizeof(text), "PCT", "%%", true);
	SetMenuTitle(menu, text);
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
	if (EnemyCombatantsWithinRange(client, StringToFloat(GetConfigValue("out of combat distance?")))) return false;

	// If not adding a kill position, it means we need to check the clients current position against all positions in the list, and see if any are within the config value.
	// If they are, we return true, otherwise false.
	// If we are adding a position, we check to see if the size is greater than the max value in the config. If it is, we remove the oldest entry, and add the newest entry.
	// We can do this by removing from array, or just resizing the array to the config value after adding the value.

	new Float:Origin[3];
	GetClientAbsOrigin(client, Origin);
	decl String:coords[64];

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
			if (GetVectorDistance(Origin, Last_Origin) <= StringToFloat(GetConfigValue("anti farm kill distance?"))) return true;
		}
	}
	else {

		new newsize = GetArraySize(h_KilledPosition_X[client]);

		ResizeArray(h_KilledPosition_X[client], newsize + 1);
		Format(coords, sizeof(coords), "%3.3f", Origin[0]);
		SetArrayString(h_KilledPosition_X[client], newsize, coords);

		ResizeArray(h_KilledPosition_Y[client], newsize + 1);
		Format(coords, sizeof(coords), "%3.3f", Origin[1]);
		SetArrayString(h_KilledPosition_Y[client], newsize, coords);

		ResizeArray(h_KilledPosition_Z[client], newsize + 1);
		Format(coords, sizeof(coords), "%3.3f", Origin[2]);
		SetArrayString(h_KilledPosition_Z[client], newsize, coords);

		while (GetArraySize(h_KilledPosition_X[client]) > StringToInt(GetConfigValue("anti farm kill max locations?"))) {

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

stock BuildMenu(client, String:MenuName[] = "main") {

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

	for (new i = 0; i < size; i++) {

		// Pull data from the parsed config.
		MenuKeys[client]		= GetArrayCell(a_Menu_Main, i, 0);
		MenuValues[client]		= GetArrayCell(a_Menu_Main, i, 1);
		MenuSection[client]		= GetArrayCell(a_Menu_Main, i, 2);

		Format(t_MenuName, sizeof(t_MenuName), "%s", GetKeyValue(MenuKeys[client], MenuValues[client], "target menu?"));
		Format(c_MenuName, sizeof(c_MenuName), "%s", GetKeyValue(MenuKeys[client], MenuValues[client], "menu name?"));
		if (!StrEqual(MenuName, c_MenuName, false)) continue;
		
		// Reset data in display requirement variables to default values.
		Format(teamsAllowed, sizeof(teamsAllowed), "123");			// 1 (Spectator) 2 (Survivor) 3 (Infected) players allowed.
		Format(gamemodesAllowed, sizeof(gamemodesAllowed), "123");	// 1 (Coop) 2 (Versus) 3 (Survival) game mode variants allowed.
		Format(flagsAllowed, sizeof(flagsAllowed), "-1");			// -1 means no flag requirements specified.
		
		// Collect the display requirement variables values.
		Format(teamsAllowed, sizeof(teamsAllowed), "%s", GetKeyValue(MenuKeys[client], MenuValues[client], "team?", teamsAllowed));
		Format(gamemodesAllowed, sizeof(gamemodesAllowed), "%s", GetKeyValue(MenuKeys[client], MenuValues[client], "gamemode?", gamemodesAllowed));
		Format(flagsAllowed, sizeof(flagsAllowed), "%s", GetKeyValue(MenuKeys[client], MenuValues[client], "flags?", flagsAllowed));
		Format(configname, sizeof(configname), "%s", GetKeyValue(MenuKeys[client], MenuValues[client], "config?"));
		Format(s_TalentDependency, sizeof(s_TalentDependency), "%s", GetKeyValue(MenuKeys[client], MenuValues[client], "talent dependency?"));

		// If a talent dependency is found AND the player has NO upgrades in said talent, the category is not displayed.
		if (StringToInt(s_TalentDependency) != -1 && !HasTalentUpgrades(client, s_TalentDependency)) continue;

		// If the player doesn't meet the requirements to have access to this menu option, we skip it.
		/*if (StrContains(teamsAllowed, clientTeam, false) == -1 || StrContains(gamemodesAllowed, currentGamemode, false) == -1 ||
			(!StrEqual(flagsAllowed, "-1", false) && !HasCommandAccess(client, flagsAllowed))) continue;*/

		if ((StrContains(teamsAllowed, clientTeam, false) == -1 && !b_IsDirectorTalents[client] || StrEqual(teamsAllowed, "2", false) && b_IsDirectorTalents[client]) ||
			!b_IsDirectorTalents[client] && (StrContains(gamemodesAllowed, currentGamemode, false) == -1 ||
			(!StrEqual(flagsAllowed, "-1", false) && !HasCommandAccess(client, flagsAllowed)))) continue;

		// Some menu options display only under specific circumstances, regardless of the new mainmenu.cfg structure.
		if (StringToInt(GetConfigValue("rpg mode?")) == 0 && !StrEqual(configname, CONFIG_POINTS)) continue;
		if (StringToInt(GetConfigValue("rpg mode?")) == 1 && StrEqual(configname, CONFIG_POINTS)) continue;
		if (GetArraySize(a_Store) < 1 && StrEqual(configname, CONFIG_STORE)) continue;
		if ((StringToInt(GetConfigValue("handicap enabled?")) == 0 || b_IsMissionFailed || PlayerLevel[client] < StringToInt(GetConfigValue("player level required handicap?"))) && StrEqual(configname, "handicap")) continue;

		// If director talent menu options is enabled by an admin, only specific options should show. We determine this here.
		if (b_IsDirectorTalents[client]) {

			if (StrEqual(configname, CONFIG_MENUTALENTS) || StrEqual(configname, CONFIG_POINTS) || b_IsDirectorTalents[client] && StrEqual(configname, "level up") || StrEqual(MenuName, c_MenuName, false)) {

				Format(pos, sizeof(pos), "%d", i);
				PushArrayString(Handle:RPGMenuPosition[client], pos);
			}
			else continue;
		}
		if (StrEqual(configname, "level up")) {

			if (!b_IsDirectorTalents[client]) {

				if (PlayerUpgradesTotal[client] < MaximumPlayerUpgrades(client)) continue; //Format(text, sizeof(text), "%T", "level up unavailable", client, MaximumPlayerUpgrades(client) - PlayerUpgradesTotal[client]);
				else Format(text, sizeof(text), "%T", "level up available", client, AddCommasToString(CheckExperienceRequirement(client)));
			}
			else {

				if (PlayerLevelUpgrades_Bots < MaxUpgradesPerLevel()) Format(text, sizeof(text), "%T", "level up unavailable", client, MaxUpgradesPerLevel() - PlayerLevelUpgrades_Bots);
				else Format(text, sizeof(text), "%T", "level up available", client, AddCommasToString(CheckExperienceRequirement(-1)));
			}
		}
		else {

			GetArrayString(Handle:MenuSection[client], 0, text, sizeof(text));
			Format(text, sizeof(text), "%T", text, client);
		}
		// important that this specific statement about hiding/displaying menus is last, due to potential conflicts with director menus.
		if (!b_IsDirectorTalents[client]) {

			if ((HasCommandAccess(client, GetConfigValue("chat settings flags?")) || StringToInt(GetConfigValue("all players chat settings?")) == 1) || !StrEqual(configname, CONFIG_CHATSETTINGS)) {

				Format(pos, sizeof(pos), "%d", i);
				PushArrayString(Handle:RPGMenuPosition[client], pos);
			}
			else continue;
		}

		AddMenuItem(menu, text, text);
	}
	SetMenuExitBackButton(menu, true);
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

		// Get the real position to use based on the slot that was pressed.
		// This position was stored above in the accompanying menu function.
		GetArrayString(Handle:RPGMenuPosition[client], slot, pos, sizeof(pos));
		MenuKeys[client]			= GetArrayCell(a_Menu_Main, StringToInt(pos), 0);
		MenuValues[client]			= GetArrayCell(a_Menu_Main, StringToInt(pos), 1);
		MenuSection[client]			= GetArrayCell(a_Menu_Main, StringToInt(pos), 2);
		GetArrayString(Handle:MenuSection[client], 0, menuname, sizeof(menuname));

		// We want to know the value of the target config based on the keys and values pulled.
		// This will be used to determine where we send the player.
		Format(config, sizeof(config), "%s", GetKeyValue(MenuKeys[client], MenuValues[client], "config?"));
		Format(t_MenuName, sizeof(t_MenuName), "%s", GetKeyValue(MenuKeys[client], MenuValues[client], "target menu?"));

		// I've set it to not require case-sensitivity in case some moron decides to get cute.
		if (!StrEqual(t_MenuName, "-1", false)) {

			//PrintToChatAll("Trying to open %s", t_MenuName);
			BuildMenu(client, t_MenuName);
		}
		else if (StrEqual(config, "level up", false)) {

			if (!b_IsDirectorTalents[client]) ExperienceBuyLevel(client, true);
			BuildMenu(client);
		}
		else if (StrEqual(config, "slate", false)) {

			SendPanelToClientAndClose(SlateMenu(client), client, SlateHandle, MENU_TIME_FOREVER);
		}
		else if (GetArraySize(a_Store) > 0 && StrEqual(config, CONFIG_STORE)) {

			BuildStoreMenu(client);
		}
		else if (StrEqual(config, "handicap", false) && !b_IsMissionFailed && PlayerLevel[client] >= StringToInt(GetConfigValue("player level required handicap?"))) {

			SendPanelToClientAndClose(PlayerHandicapMenu(client), client, PlayerHandicapHandle, MENU_TIME_FOREVER);
		}
		else if (StrEqual(config, CONFIG_CHATSETTINGS)) {

			Format(ChatSettingsName[client], sizeof(ChatSettingsName[]), "none");
			BuildChatSettingsMenu(client);
		}
		else if (StrEqual(config, CONFIG_MENUTALENTS)) {

			// In previous versions of RPG, players could see, but couldn't open specific menus if the director talents were active.
			// In this version, if director talents are active, you just can't see a talent with "activator class required?" that is strictly 0.
			// However, values that are, say, "01" will show, as at least 1 infected class can use the talent.
			BuildSubMenu(client, menuname, config);
		}
		else if (StrEqual(config, CONFIG_POINTS)) {

			// A much safer method for grabbing the current config value for the MenuSelection.
			Format(MenuSelection[client], sizeof(MenuSelection[]), "%s", config);
			BuildPointsMenu(client, menuname, config);
		}
		else {

			BuildMenu(client);
		}
	}
	else if (action == MenuAction_End) {

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

	return RoundToFloor(1.0 / StringToFloat(GetConfigValue("upgrade experience cost?")));
}

stock MaximumPlayerUpgrades(client) {

	if (StringToFloat(GetConfigValue("upgrade experience cost?")) < 1.0) return MaxUpgradesPerLevel() * PlayerLevel[client];
	else return MaxUpgradesPerLevel() * (PlayerLevel[client] - 1);
}

stock VerifyMaxPlayerUpgrades(client) {

	if (PlayerUpgradesTotal[client] + FreeUpgrades[client] > MaximumPlayerUpgrades(client)) {

		FreeUpgrades[client]								=	MaximumPlayerUpgrades(client);
		UpgradesAvailable[client]							=	0;
		PlayerUpgradesTotal[client]							=	0;
		RespecSlate(client);
		WipeTalentPoints(client);
	}
}

stock RespecSlate(client) {

	SlatePoints[client] = SlatePoints[client] + Strength[client] + Luck[client] + Agility[client] + Technique[client] + Endurance[client];
	Strength[client] = 0;
	Luck[client] = 0;
	Agility[client] = 0;
	Technique[client] = 0;
	Endurance[client] = 0;
}

stock String:UpgradesUsed(client) {

	decl String:text[512];
	Format(text, sizeof(text), "%T", "Upgrades Used", client);
	Format(text, sizeof(text), "(%s: %d / %d)", text, PlayerUpgradesTotal[client], MaximumPlayerUpgrades(client));
	return text;
}

public Handle:PlayerHandicapMenu(client) {

	new Handle:menu			= CreatePanel();

	decl String:text[512];
	if (HandicapLevel[client] != -1) {

		decl String:s_InfectedDamageIncrease[64];

		Format(text, sizeof(text), "%T", "player handicap", client, HandicapLevel[client]);
		DrawPanelText(menu, text);

		Format(text, sizeof(text), "%T", "player handicap bonus", client, (HandicapLevel[client] * StringToFloat(GetConfigValue("handicap experience bonus?"))) * 100.0);
		ReplaceString(text, sizeof(text), "PCT", "%", true);
		DrawPanelText(menu, text);
		Format(text, sizeof(text), "%T", "increase handicap", client);
		DrawPanelItem(menu, text);
		Format(text, sizeof(text), "%T", "decrease handicap", client);
		DrawPanelItem(menu, text);
		Format(text, sizeof(text), "%T", "reset handicap", client);
		DrawPanelItem(menu, text);
		Format(text, sizeof(text), "%T", "disable handicap", client);
		DrawPanelItem(menu, text);
		Format(text, sizeof(text), "%T", "damage increase commons", client, (HandicapLevel[client] * StringToFloat(GetConfigValue("commons damage increase?"))) * 100.0);
		ReplaceString(text, sizeof(text), "PCT", "%", true);
		DrawPanelText(menu, text);
		Format(s_InfectedDamageIncrease, sizeof(s_InfectedDamageIncrease), "(%d) damage increase?", ZOMBIECLASS_TANK);
		Format(text, sizeof(text), "%T", "damage increase tank", client, (HandicapLevel[client] * StringToFloat(GetConfigValue(s_InfectedDamageIncrease))) * 100.0);
		ReplaceString(text, sizeof(text), "PCT", "%", true);
		DrawPanelText(menu, text);
		Format(s_InfectedDamageIncrease, sizeof(s_InfectedDamageIncrease), "(%d) damage increase?", ZOMBIECLASS_CHARGER);
		Format(text, sizeof(text), "%T", "damage increase charger", client, (HandicapLevel[client] * StringToFloat(GetConfigValue(s_InfectedDamageIncrease))) * 100.0);
		ReplaceString(text, sizeof(text), "PCT", "%", true);
		DrawPanelText(menu, text);
		Format(s_InfectedDamageIncrease, sizeof(s_InfectedDamageIncrease), "(%d) damage increase?", ZOMBIECLASS_SPITTER);
		Format(text, sizeof(text), "%T", "damage increase spitter", client, (HandicapLevel[client] * StringToFloat(GetConfigValue(s_InfectedDamageIncrease))) * 100.0);
		ReplaceString(text, sizeof(text), "PCT", "%", true);
		DrawPanelText(menu, text);
		Format(s_InfectedDamageIncrease, sizeof(s_InfectedDamageIncrease), "(%d) damage increase?", ZOMBIECLASS_HUNTER);
		Format(text, sizeof(text), "%T", "damage increase hunter", client, (HandicapLevel[client] * StringToFloat(GetConfigValue(s_InfectedDamageIncrease))) * 100.0);
		ReplaceString(text, sizeof(text), "PCT", "%", true);
		DrawPanelText(menu, text);
		Format(s_InfectedDamageIncrease, sizeof(s_InfectedDamageIncrease), "(%d) damage increase?", ZOMBIECLASS_SMOKER);
		Format(text, sizeof(text), "%T", "damage increase smoker", client, (HandicapLevel[client] * StringToFloat(GetConfigValue(s_InfectedDamageIncrease))) * 100.0);
		ReplaceString(text, sizeof(text), "PCT", "%", true);
		DrawPanelText(menu, text);
		Format(s_InfectedDamageIncrease, sizeof(s_InfectedDamageIncrease), "(%d) damage increase?", ZOMBIECLASS_JOCKEY);
		Format(text, sizeof(text), "%T", "damage increase jockey", client, (HandicapLevel[client] * StringToFloat(GetConfigValue(s_InfectedDamageIncrease))) * 100.0);
		ReplaceString(text, sizeof(text), "PCT", "%", true);
		DrawPanelText(menu, text);
		Format(s_InfectedDamageIncrease, sizeof(s_InfectedDamageIncrease), "(%d) damage increase?", ZOMBIECLASS_BOOMER);
		Format(text, sizeof(text), "%T", "damage increase boomer", client, (HandicapLevel[client] * StringToFloat(GetConfigValue(s_InfectedDamageIncrease))) * 100.0);
		ReplaceString(text, sizeof(text), "PCT", "%", true);
		DrawPanelText(menu, text);
		Format(s_InfectedDamageIncrease, sizeof(s_InfectedDamageIncrease), "witch damage increase?");
		Format(text, sizeof(text), "%T", "damage increase witch", client, (HandicapLevel[client] * StringToFloat(GetConfigValue(s_InfectedDamageIncrease))) * 100.0);
		ReplaceString(text, sizeof(text), "PCT", "%", true);
		DrawPanelText(menu, text);
		Format(s_InfectedDamageIncrease, sizeof(s_InfectedDamageIncrease), "handicap health increase?");
		Format(text, sizeof(text), "%T", "handicap health increase", client, (HandicapLevel[client] * StringToFloat(GetConfigValue(s_InfectedDamageIncrease))) * 100.0);
		ReplaceString(text, sizeof(text), "PCT", "%", true);
		DrawPanelText(menu, text);
	}
	else {

		Format(text, sizeof(text), "%T", "handicap disabled", client);
		DrawPanelText(menu, text);
		Format(text, sizeof(text), "%T", "enable handicap", client);
		DrawPanelItem(menu, text);
	}
	Format(text, sizeof(text), "%T", "main menu", client);
	DrawPanelItem(menu, text);

	return menu;
}

public PlayerHandicapHandle(Handle:topmenu, MenuAction:action, client, param2) {

	if (action == MenuAction_Select) {

		switch (param2) {

			case 1:
			{
				if (!b_HandicapLocked[client] && HandicapLevel[client] != -1 && IsPlayerAlive(client)) {

					if (PlayerLevel[client] >= StringToInt(GetConfigValue("player level required handicap?")) * (HandicapLevel[client] + 1)) {

						HandicapLevel[client]++;
						SetClientMovementSpeed(client);
					}
				}
				else if (!b_HandicapLocked[client] && PlayerLevel[client] >= StringToInt(GetConfigValue("player level required handicap?")) && IsPlayerAlive(client)) {

					HandicapLevel[client] = 1;
					SetClientMovementSpeed(client);
				}
				SendPanelToClientAndClose(PlayerHandicapMenu(client), client, PlayerHandicapHandle, MENU_TIME_FOREVER);
			}
			case 2:
			{
				if (HandicapLevel[client] != -1 && !h_PreviousDeath[client]) {

					if (HandicapLevel[client] > 1) {

						HandicapLevel[client]--;
						SetClientMovementSpeed(client);
					}
					SendPanelToClientAndClose(PlayerHandicapMenu(client), client, PlayerHandicapHandle, MENU_TIME_FOREVER);
				}
				else BuildMenu(client);
			}
			case 3:
			{
				if (HandicapLevel[client] != -1 && HandicapLevel[client] >= 1 && !b_HandicapLocked[client] && !h_PreviousDeath[client]) {

					HandicapLevel[client] = 1;
				}
				SetClientMovementSpeed(client);
				SendPanelToClientAndClose(PlayerHandicapMenu(client), client, PlayerHandicapHandle, MENU_TIME_FOREVER);
			}
			case 4:
			{
				if (HandicapLevel[client] != -1 && HandicapLevel[client] >= 1) {

					HandicapLevel[client] = -1;
				}
				SetClientMovementSpeed(client);
				SendPanelToClientAndClose(PlayerHandicapMenu(client), client, PlayerHandicapHandle, MENU_TIME_FOREVER);
			}
			case 5:
			{
				if (HandicapLevel[client] != -1) BuildMenu(client);
			}
		}
	}
	if (topmenu != INVALID_HANDLE) {

		CloseHandle(topmenu);
	}
}

public Handle:SlateMenu(client) {

	new Handle:menu = CreatePanel();
	decl String:text[512];
	Format(text, sizeof(text), "%T", "Slate Points", client, SlatePoints[client]);
	DrawPanelText(menu, text);
	Format(text, sizeof(text), "%T", "strength slate", client, Strength[client], StringToInt(GetConfigValue("slate category maximum?")));
	DrawPanelItem(menu, text);
	Format(text, sizeof(text), "%T", "luck slate", client, Luck[client], StringToInt(GetConfigValue("slate category maximum?")));
	DrawPanelItem(menu, text);
	Format(text, sizeof(text), "%T", "agility slate", client, Agility[client], StringToInt(GetConfigValue("slate category maximum?")));
	DrawPanelItem(menu, text);
	Format(text, sizeof(text), "%T", "technique slate", client, Technique[client], StringToInt(GetConfigValue("slate category maximum?")));
	DrawPanelItem(menu, text);
	Format(text, sizeof(text), "%T", "endurance slate", client, Endurance[client], StringToInt(GetConfigValue("slate category maximum?")));
	DrawPanelItem(menu, text);
	Format(text, sizeof(text), "%T", "main menu", client);
	DrawPanelItem(menu, text);

	return menu;
}

public SlateHandle(Handle:topmenu, MenuAction:action, client, param2) {

	if (action == MenuAction_Select) {

		new SlateMax		= StringToInt(GetConfigValue("slate category maximum?"));
		switch (param2) {

			case 1: {

				if (SlatePoints[client] > 0 && Strength[client] < SlateMax) {

					SlatePoints[client]--;
					Strength[client]++;
				}
				SendPanelToClientAndClose(SlateMenu(client), client, SlateHandle, MENU_TIME_FOREVER);
			}
			case 2: {

				if (SlatePoints[client] > 0 && Luck[client] < SlateMax) {

					SlatePoints[client]--;
					Luck[client]++;
				}
				SendPanelToClientAndClose(SlateMenu(client), client, SlateHandle, MENU_TIME_FOREVER);
			}
			case 3: {

				if (SlatePoints[client] > 0 && Agility[client] < SlateMax) {

					SlatePoints[client]--;
					Agility[client]++;
				}
				SendPanelToClientAndClose(SlateMenu(client), client, SlateHandle, MENU_TIME_FOREVER);
			}
			case 4: {

				if (SlatePoints[client] > 0 && Technique[client] < SlateMax) {

					SlatePoints[client]--;
					Technique[client]++;
				}
				SendPanelToClientAndClose(SlateMenu(client), client, SlateHandle, MENU_TIME_FOREVER);
			}
			case 5: {

				if (SlatePoints[client] > 0 && Endurance[client] < SlateMax) {

					SlatePoints[client]--;
					Endurance[client]++;
				}
				SendPanelToClientAndClose(SlateMenu(client), client, SlateHandle, MENU_TIME_FOREVER);
			}
			case 6: {

				if (GetClientTeam(client) != TEAM_SPECTATOR) BuildMenu(client);
			}
		}
	}
	if (topmenu != INVALID_HANDLE) {

		CloseHandle(topmenu);
	}
}

stock BuildSubMenu(client, String:MenuName[], String:ConfigName[]) {

	// Each talent has a defined "menu name" ("part of menu named?") and will list under that menu. Genius, right?

	new Handle:menu					=	CreateMenu(BuildSubMenuHandle);
	decl String:OpenedMenu_t[64];
	Format(OpenedMenu_t, sizeof(OpenedMenu_t), "%s", MenuName);
	OpenedMenu[client]				=	OpenedMenu_t;

	decl String:MenuSelection_t[64];
	Format(MenuSelection_t, sizeof(MenuSelection_t), "%s", ConfigName);
	MenuSelection[client]			=	MenuSelection_t;

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

	decl String:TalentName[64];
	decl String:TalentName_Temp[64];



	new TalentMaximum				=	0;
	new TalentLevelRequired			=	0;
	new PlayerTalentPoints			=	0;

	new AbilityInherited			=	0;
	new StorePurchaseCost			=	0;

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

		TalentMaximum = StringToInt(GetKeyValue(MenuKeys[client], MenuValues[client], "maximum talent points allowed?"));
		TalentLevelRequired = StringToInt(GetKeyValue(MenuKeys[client], MenuValues[client], "minimum level required?"));
		StorePurchaseCost = StringToInt(GetKeyValue(MenuKeys[client], MenuValues[client], "store purchase cost?"));
		AbilityInherited = StringToInt(GetKeyValue(MenuKeys[client], MenuValues[client], "ability inherited?"));


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

		Format(TalentName_Temp, sizeof(TalentName_Temp), "%T", TalentName, client);
		if (AbilityInherited == 0 && PlayerTalentPoints < 0) Format(text, sizeof(text), "%T", "Ability Locked", client, TalentName_Temp, StorePurchaseCost);
		else if (PlayerLevel[client] < TalentLevelRequired) Format(text, sizeof(text), "%T", "Ability Restricted", client, TalentName_Temp, TalentLevelRequired);
		else Format(text, sizeof(text), "%T", "Ability Available", client, TalentName_Temp, PlayerTalentPoints, TalentMaximum);

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


		new PlayerTalentPoints			=	0;

		new StorePurchaseCost			=	0;
		decl String:SurvEffects[64];
		Format(SurvEffects, sizeof(SurvEffects), "0");

		Format(pct, sizeof(pct), "%");




		new size						=	GetArraySize(a_Menu_Talents);

		//if (StrEqual(ConfigName, CONFIG_MENUSURVIVOR)) size			=	GetArraySize(a_Menu_Talents_Survivor);
		//else if (StrEqual(ConfigName, CONFIG_MENUINFECTED)) size	=	GetArraySize(a_Menu_Talents_Infected);

		for (new i = 0; i < size; i++) {

			MenuKeys[client]				= GetArrayCell(a_Menu_Talents, i, 0);
			MenuValues[client]				= GetArrayCell(a_Menu_Talents, i, 1);
			MenuSection[client]				= GetArrayCell(a_Menu_Talents, i, 2);

			GetArrayString(Handle:MenuSection[client], 0, TalentName, sizeof(TalentName));
			if (!TalentListingFound(client, MenuKeys[client], MenuValues[client], MenuName)) continue;
			pos++;


			Format(SurvEffects, sizeof(SurvEffects), "%s", GetKeyValue(MenuKeys[client], MenuValues[client], "survivor ability effects?"));
			StorePurchaseCost = StringToInt(GetKeyValue(MenuKeys[client], MenuValues[client], "store purchase cost?"));

			if (pos == slot) break;
		}

		if (b_IsDirectorTalents[client]) PlayerTalentPoints = GetTalentStrength(-1, TalentName);
		else PlayerTalentPoints = GetTalentStrength(client, TalentName);

		if (!b_IsDirectorTalents[client] && IsTalentLocked(client, TalentName)) {

			if (SkyPoints[client] >= StorePurchaseCost) {

				SkyPoints[client] -= StorePurchaseCost;
				UnlockTalent(client, TalentName);
				BuildSubMenu(client, OpenedMenu[client], MenuSelection[client]);
			}

		}
		else {

			PurchaseTalentName[client] = TalentName;
			PurchaseSurvEffects[client] = SurvEffects;
			PurchaseTalentPoints[client] = PlayerTalentPoints;
			ShowTalentInfoScreen(client, TalentName, MenuKeys[client], MenuValues[client]);
		}
	}
	else if (action == MenuAction_End)
	{
		CloseHandle(menu);
	}
}

stock ShowTalentInfoScreen(client, String:TalentName[], Handle:Keys, Handle:Values) {

	PurchaseKeys[client] = Keys;
	PurchaseValues[client] = Values;
	Format(PurchaseTalentName[client], sizeof(PurchaseTalentName[]), "%s", TalentName);
	//PurchaseTalentName[client] = TalentName;

	SendPanelToClientAndClose(TalentInfoScreen(client), client, TalentInfoScreen_Init, MENU_TIME_FOREVER);
}

public Handle:TalentInfoScreen (client)
{

	new Handle:Keys = PurchaseKeys[client];
	new Handle:Values = PurchaseValues[client];
	decl String:TalentName[64];
	Format(TalentName, sizeof(TalentName), "%s", PurchaseTalentName[client]);

	new Handle:menu = CreatePanel();

	new TalentPointAmount		= 0;
	if (!b_IsDirectorTalents[client]) TalentPointAmount = GetTalentStrength(client, TalentName);
	else TalentPointAmount = GetTalentStrength(-1, TalentName);
	new TalentPointMaximum		= StringToInt(GetKeyValue(Keys, Values, "maximum talent points allowed?"));

	new Float:s_FirstPoint = StringToFloat(GetKeyValue(Keys, Values, "first point value?"));

	new Float:s_OtherPoint = StringToFloat(GetKeyValue(Keys, Values, "increase per point?"));
	new Float:s_PenaltyPoint = s_FirstPoint;

	new Float:s_SoftCapCooldown = 0.0;

	decl String:pct[4];
	Format(pct, sizeof(pct), "%");
	
	new Float:f_CooldownNow = 0.0;
	new Float:f_CooldownNext = 0.0;
	f_CooldownNow = TalentPointAmount * 1.0;
	f_CooldownNext = (TalentPointAmount + 1) * 1.0;
	if (TalentPointAmount == 0) f_CooldownNow = StringToFloat(GetKeyValue(Keys, Values, "cooldown start?")) + StringToFloat(GetKeyValue(Keys, Values, "cooldown per point?"));
	else f_CooldownNow = StringToFloat(GetKeyValue(Keys, Values, "cooldown start?")) + (StringToFloat(GetKeyValue(Keys, Values, "cooldown per point?")) * f_CooldownNow);
	f_CooldownNext = StringToFloat(GetKeyValue(Keys, Values, "cooldown start?")) + (StringToFloat(GetKeyValue(Keys, Values, "cooldown per point?")) * f_CooldownNext);

	decl String:TalentIdCode[64];
	Format(TalentIdCode, sizeof(TalentIdCode), "%T", "Talent Id Code", client);
	Format(TalentIdCode, sizeof(TalentIdCode), "%s: %s", TalentIdCode, GetKeyValue(Keys, Values, "id_number"));

	/*

		We copy the talent name to another string so we can show the talent in the language of the player.
	*/
	decl String:TalentName_Temp[64];
	Format(TalentName_Temp, sizeof(TalentName_Temp), "%T", TalentName, client);

	/*

		Talents now have a brief description of what they do on their purchase page.
		This variable is pre-determined and calls a translation file in the language of the player.
	*/
	decl String:TalentInfo[128];
	Format(TalentInfo, sizeof(TalentInfo), "%s info", TalentName);
	Format(TalentInfo, sizeof(TalentInfo), "%T", TalentInfo, client);

	decl String:text[64];
	if (FreeUpgrades[client] == 0) Format(text, sizeof(text), "%T", "Talent Upgrade Title", client, TalentName_Temp, TalentPointAmount, TalentPointMaximum);
	else Format(text, sizeof(text), "%T", "Talent Upgrade Title Free", client, TalentName_Temp, TalentPointAmount, TalentPointMaximum, FreeUpgrades[client]);
	SetPanelTitle(menu, text);

	if (TalentPointAmount == 0) Format(text, sizeof(text), "%T", "Talent Cooldown Info - No Points", client, s_SoftCapCooldown + f_CooldownNext);
	else Format(text, sizeof(text), "%T", "Talent Cooldown Info", client, s_SoftCapCooldown + f_CooldownNow, s_SoftCapCooldown + f_CooldownNext);
	if (f_CooldownNext > 0.0) DrawPanelText(menu, text);

	new AbilityType = StringToInt(GetKeyValue(Keys, Values, "ability type?"));
	if (TalentPointAmount > 0) s_PenaltyPoint = 0.0;
	if (AbilityType == 0) Format(text, sizeof(text), "%T", "Ability Info Percent", client, ((s_FirstPoint - s_PenaltyPoint) * 100.0) + ((TalentPointAmount * s_OtherPoint) * 100.0), pct, (s_FirstPoint * 100.0) + (((TalentPointAmount + 1) * s_OtherPoint) * 100.0), pct);
	else if (AbilityType == 1) Format(text, sizeof(text), "%T", "Ability Info Time", client, (s_FirstPoint - s_PenaltyPoint) + (TalentPointAmount * s_OtherPoint), s_FirstPoint + ((TalentPointAmount + 1) * s_OtherPoint));
	else if (AbilityType == 2) Format(text, sizeof(text), "%T", "Ability Info Distance", client, (s_FirstPoint - s_PenaltyPoint) + (TalentPointAmount * s_OtherPoint), s_FirstPoint + ((TalentPointAmount + 1) * s_OtherPoint));
	DrawPanelText(menu, text);
	DrawPanelText(menu, TalentIdCode);

	/*if (b_IsCheckpointDoorStartOpened && IsPlayerAlive(client) && GetClientTeam(client) != TEAM_SPECTATOR) {

		

			The round has already begun so we don't allow ANYONE to assign talent points.
			This stops players from joining spectator during a live game, or going afk to assign talent points.
		
		Format(text, sizeof(text), "%T", "return to talent menu", client);
		DrawPanelItem(menu, text);
	}*/
	if (b_IsDirectorTalents[client] || FreeUpgrades[client] == 0) {

		Format(text, sizeof(text), "%T", "Insert Talent Upgrade", client);
		DrawPanelItem(menu, text);
		Format(text, sizeof(text), "%T", "return to talent menu", client);
		DrawPanelItem(menu, text);
	}
	else {

		Format(text, sizeof(text), "%T", "Insert One Upgrade", client);
		DrawPanelItem(menu, text);
		if (FreeUpgrades[client] <= 9) {

			Format(text, sizeof(text), "%T", "return to talent menu", client);
			DrawPanelItem(menu, text);
		}
		if (FreeUpgrades[client] >= 10) {

			Format(text, sizeof(text), "%T", "Insert Ten Upgrade", client);
			DrawPanelItem(menu, text);
			if (FreeUpgrades[client] < TalentPointMaximum - TalentPointAmount) {

				Format(text, sizeof(text), "%T", "return to talent menu", client);
				DrawPanelItem(menu, text);
			}
		}
		if (FreeUpgrades[client] >= TalentPointMaximum - TalentPointAmount) {

			Format(text, sizeof(text), "%T", "Fill Her Up", client);
			DrawPanelItem(menu, text);
			Format(text, sizeof(text), "%T", "return to talent menu", client);
			DrawPanelItem(menu, text);
		}
	}
	DrawPanelText(menu, TalentInfo);	// rawline means not a selectable option.
	return menu;
}

public TalentInfoScreen_Init (Handle:topmenu, MenuAction:action, client, param2)
{
	if (action == MenuAction_Select)
	{
		switch (param2)
		{
			case 1: {

				/*if (b_IsCheckpointDoorStartOpened && IsPlayerAlive(client) && GetClientTeam(client) != TEAM_SPECTATOR) {

					BuildSubMenu(client, OpenedMenu[client], MenuSelection[client]);
				}*/
				if (b_IsDirectorTalents[client] || FreeUpgrades[client] == 0) {

					if (!b_IsDirectorTalents[client]) {

						/*if (ExperienceLevel[client] >= GetUpgradeExperienceCost(client, false) && PlayerUpgradesTotal[client] < MaximumPlayerUpgrades(client) && GetTalentStrength(client, PurchaseTalentName[client]) < StringToInt(GetKeyValue(MenuKeys[client], MenuValues[client], "maximum talent points allowed?"))) {

							TryToTellPeopleYouUpgraded(client);
							PurchaseTalentPoints[client]++;
							AddTalentPoints(client, PurchaseTalentName[client], PurchaseTalentPoints[client]);
							ExperienceLevel[client] -= GetUpgradeExperienceCost(client, false);
							PlayerLevelUpgrades[client]++;
							PlayerUpgradesTotal[client]++;
						}*/
						if (UpgradesAvailable[client] > 0 && GetTalentStrength(client, PurchaseTalentName[client]) < StringToInt(GetKeyValue(MenuKeys[client], MenuValues[client], "maximum talent points allowed?"))) {

							TryToTellPeopleYouUpgraded(client);
							PurchaseTalentPoints[client]++;
							AddTalentPoints(client, PurchaseTalentName[client], PurchaseTalentPoints[client]);
							UpgradesAvailable[client]--;
							PlayerLevelUpgrades[client]++;
							PlayerUpgradesTotal[client]++;
						}
					}
					else {

						if (ExperienceLevel_Bots >= GetUpgradeExperienceCost(-1, false) && GetTalentStrength(-1, PurchaseTalentName[client]) < StringToInt(GetKeyValue(MenuKeys[client], MenuValues[client], "maximum talent points allowed?"))) {

							PurchaseTalentPoints[client]++;
							AddTalentPoints(-1, PurchaseTalentName[client], PurchaseTalentPoints[client]);
							ExperienceLevel_Bots -= GetUpgradeExperienceCost(-1, false);
							PlayerLevelUpgrades_Bots++;
						}
					}
				}
				else if (GetTalentStrength(client, PurchaseTalentName[client]) < StringToInt(GetKeyValue(MenuKeys[client], MenuValues[client], "maximum talent points allowed?"))) {

					AddTalentPoints(client, PurchaseTalentName[client], PurchaseTalentPoints[client] + 1);
					PlayerUpgradesTotal[client]++;
					PurchaseTalentPoints[client]++;
					FreeUpgrades[client]--;
				}
				SendPanelToClientAndClose(TalentInfoScreen(client), client, TalentInfoScreen_Init, MENU_TIME_FOREVER);
			}
			case 2: {

				if (b_IsDirectorTalents[client] || FreeUpgrades[client] <= 9) {

					BuildSubMenu(client, OpenedMenu[client], MenuSelection[client]);
				}
				else {

					/*

						Only shows up if the user has free upgrades and director talents are disabled.
					*/
					if (!b_IsDirectorTalents[client] && FreeUpgrades[client] >= 10 && GetTalentStrength(client, PurchaseTalentName[client]) + 10 <= StringToInt(GetKeyValue(MenuKeys[client], MenuValues[client], "maximum talent points allowed?"))) {

						PlayerUpgradesTotal[client] += 10;
						PurchaseTalentPoints[client] += 10;
						FreeUpgrades[client] -= 10;
						AddTalentPoints(client, PurchaseTalentName[client], PurchaseTalentPoints[client]);
					}
					SendPanelToClientAndClose(TalentInfoScreen(client), client, TalentInfoScreen_Init, MENU_TIME_FOREVER);
				}
			}
			case 3: {

				/*

					This case only exists if director talents are disabled and the user has free upgrades.
				*/
				if (!b_IsDirectorTalents[client] && FreeUpgrades[client] >= StringToInt(GetKeyValue(MenuKeys[client], MenuValues[client], "maximum talent points allowed?")) - GetTalentStrength(client, PurchaseTalentName[client])) {

					PurchaseTalentPoints[client] += (StringToInt(GetKeyValue(MenuKeys[client], MenuValues[client], "maximum talent points allowed?")) - GetTalentStrength(client, PurchaseTalentName[client]));
					PlayerUpgradesTotal[client] += (StringToInt(GetKeyValue(MenuKeys[client], MenuValues[client], "maximum talent points allowed?")) - GetTalentStrength(client, PurchaseTalentName[client]));
					FreeUpgrades[client] -= (StringToInt(GetKeyValue(MenuKeys[client], MenuValues[client], "maximum talent points allowed?")) - GetTalentStrength(client, PurchaseTalentName[client]));
					AddTalentPoints(client, PurchaseTalentName[client], PurchaseTalentPoints[client]);
					SendPanelToClientAndClose(TalentInfoScreen(client), client, TalentInfoScreen_Init, MENU_TIME_FOREVER);
				}
				else BuildSubMenu(client, OpenedMenu[client], MenuSelection[client]);
			}
			case 4: {

				BuildSubMenu(client, OpenedMenu[client], MenuSelection[client]);
			}
		}
	}
	if (topmenu != INVALID_HANDLE)
	{
		CloseHandle(topmenu);
	}
}

stock TryToTellPeopleYouUpgraded(client) {

	if (FreeUpgrades[client] == 0 && StringToInt(GetConfigValue("display when players upgrade to team?")) == 1) {

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
	
	decl String:text[64];
	new a_Size							=	GetArraySize(a_Database_Talents);

	for (new i = 0; i < a_Size; i++) {

		GetArrayString(Handle:a_Database_Talents, i, text, sizeof(text));

		if (StrEqual(text, Name)) {

			Format(text, sizeof(text), "%d", TalentPoints);
			if (client != -1) SetArrayString(a_Database_PlayerTalents[client], i, text);
			else SetArrayString(a_Database_PlayerTalents_Bots, i, text);
			break;
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

			SetArrayString(a_Database_PlayerTalents[client], i, "0");

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

	decl String:text[64];

	new size			= GetArraySize(a_Database_Talents);

	for (new i = 0; i < size; i++) {

		GetArrayString(Handle:a_Database_Talents, i, text, sizeof(text));
		if (StrEqual(text, Name)) {

			GetArrayString(a_Database_PlayerTalents[client], i, text, sizeof(text));

			if (StringToInt(text) >= 0) return false;
			break;
		}
	}

	return true;
}

stock WipeTalentPoints(client) {

	UpgradesAwarded[client] = 0;

	new size							= GetArraySize(a_Database_Talents);

	decl String:value[64];

	for (new i = 0; i < size; i++) {	// We only reset talents a player has points in, so locked talents don't become unlocked.

		GetArrayString(a_Database_PlayerTalents[client], i, value, sizeof(value));
		if (StringToInt(value) > 0)	SetArrayString(a_Database_PlayerTalents[client], i, "0");
	}
}