stock void BuildMenuTitle(int client, Handle menu, int bot = 0, int type = 0, bool bIsPanel = false, bool ShowLayerEligibility = false, int typeOfDataToShow = 0) {	// 0 is legacy type that appeared on all menus. 0 - Main Menu | 1 - Upgrades | 2 - Points

	char text[512];
	int CurRPGMode = iRPGMode;

	char currExperience[64];
	char targExperience[64];
	char ratingFormatted[64];
	char scrap[64];
	char avgAugLvl[64];

	if (bot == 0) {
		AddCommasToString(ExperienceLevel[client], currExperience, sizeof(currExperience));
		AddCommasToString(CheckExperienceRequirement(client), targExperience, sizeof(targExperience));
		AddCommasToString(Rating[client], ratingFormatted, sizeof(ratingFormatted));
		AddCommasToString(augmentParts[client], scrap, 64);
		AddCommasToString(playerCurrentAugmentAverageLevel[client], avgAugLvl, 64);

		char PointsText[64];
		Format(PointsText, sizeof(PointsText), "%T", "Points Text", client, Points[client]);

		int CheckRPGMode = iRPGMode;
		if (CheckRPGMode > 0) {

			bool bIsLayerEligible = (PlayerCurrentMenuLayer[client] <= 1 || GetLayerUpgradeStrength(client, PlayerCurrentMenuLayer[client] - 1) >= RoundToCeil(GetLayerUpgradeStrength(client, PlayerCurrentMenuLayer[client] - 1, _, _, _, true, true) * fUpgradesRequiredPerLayer)) ? true : false;

			int TotalPoints = TotalPointsAssigned(client);
			char PlayerLevelText[256];
			if (typeOfDataToShow == 0) {
				MenuExperienceBar(client, _, _, PlayerLevelText, sizeof(PlayerLevelText));
				if (typeOfDataToShow == 0) Format(PlayerLevelText, sizeof(PlayerLevelText), "%T", "Player Level Text", client, PlayerLevel[client], iMaxLevel, currExperience, PlayerLevelText, targExperience, ratingFormatted, scrap, avgAugLvl, GetArraySize(myAugmentIDCodes[client]), iInventoryLimit);
				else if (typeOfDataToShow == 1) Format(PlayerLevelText, sizeof(PlayerLevelText), "%T", "Player Level Text minor", client, PlayerLevel[client], iMaxLevel, currExperience, PlayerLevelText, targExperience, ratingFormatted, scrap, avgAugLvl, GetArraySize(myAugmentIDCodes[client]), iInventoryLimit);
				if (SkyLevel[client] > 0) Format(PlayerLevelText, sizeof(PlayerLevelText), "%T", "Prestige Level Text", client, SkyLevel[client], iSkyLevelMax, PlayerLevelText);
			}
			int maximumPlayerUpgradesToShow = (iShowTotalNodesOnTalentTree == 1) ? MaximumPlayerUpgrades(client, true) : MaximumPlayerUpgrades(client);
			if (CheckRPGMode != 0) {
				//decl String:upgradeCap[64];
				//(iMaxServerUpgrades < 1) ? Format(upgradeCap, sizeof(upgradeCap), "N/A") : Format(upgradeCap, sizeof(upgradeCap), "%d", iMaxServerUpgrades);
				if (typeOfDataToShow == 0) Format(text, sizeof(text), "%T", "RPG Header", client, PlayerLevelText, TotalPoints, maximumPlayerUpgradesToShow, UpgradesAvailable[client] + FreeUpgrades[client]);
				else if (typeOfDataToShow == 1) Format(text, sizeof(text), "%T", "RPG Header minor", client, TotalPoints, maximumPlayerUpgradesToShow, UpgradesAvailable[client] + FreeUpgrades[client]);
				if (ShowLayerEligibility) {
					if (bIsLayerEligible) {
						int strengthOfCurrentLayer = GetLayerUpgradeStrength(client, PlayerCurrentMenuLayer[client], _, _, _, _, true);
						//int allUpgradesThisLayer = GetLayerUpgradeStrength(client, PlayerCurrentMenuLayer[client], _, _, true);//true for skip attributes, too?
						//int totalPossibleNodesThisLayer = GetLayerUpgradeStrength(client, PlayerCurrentMenuLayer[client], _, _, _, true);
						int totalPossibleNodesThisLayerWithoutAttributes = GetLayerUpgradeStrength(client, PlayerCurrentMenuLayer[client], _, _, _, true, true);
						int upgradesRequiredThisLayer = RoundToCeil(totalPossibleNodesThisLayerWithoutAttributes * fUpgradesRequiredPerLayer);
						if (strengthOfCurrentLayer > upgradesRequiredThisLayer) {
							strengthOfCurrentLayer = 0;
							WipeTalentPoints(client);
						}
						Format(text, sizeof(text), "%T", "RPG Layer Eligible", client, text, PlayerCurrentMenuLayer[client], strengthOfCurrentLayer, upgradesRequiredThisLayer);
					}
					else Format(text, sizeof(text), "%T", "RPG Layer Not Eligible", client, text, PlayerCurrentMenuLayer[client]);
				}
			}
			if (CheckRPGMode != 1) Format(text, sizeof(text), "%s\n%s", text, PointsText);
			if (ExperienceDebt[client] > 0 && iExperienceDebtEnabled == 1 && PlayerLevel[client] >= iExperienceDebtLevel) {
				AddCommasToString(ExperienceDebt[client], currExperience, sizeof(currExperience));
				Format(text, sizeof(text), "%T", "Menu Experience Debt", client, text, currExperience, RoundToCeil(100.0 * fExperienceDebtPenalty));
			}
		}
		else if (CurRPGMode == 0) Format(text, sizeof(text), "%s", PointsText);
		else Format(text, sizeof(text), "Control Panel");
	}
	else {
		AddCommasToString(ExperienceLevel_Bots, currExperience, sizeof(currExperience));
		AddCommasToString(CheckExperienceRequirement(-1, true), targExperience, sizeof(targExperience));
		AddCommasToString(GetUpgradeExperienceCost(-1), ratingFormatted, sizeof(ratingFormatted));

		if (CurRPGMode == 0 || bot == -1) Format(text, sizeof(text), "%T", "Menu Header 0 Director", client, Points_Director);
		else if (CurRPGMode == 1) {

			// Bots level up strictly based on experience gain. Honestly, I have been thinking about removing talent-based leveling.
			Format(text, sizeof(text), "%T", "Menu Header 1 Talents Bot", client, PlayerLevel_Bots, iMaxLevel, currExperience, targExperience, ratingFormatted);
		}
		else if (CurRPGMode == 2) {

			Format(text, sizeof(text), "%T", "Menu Header 2 Talents Bot", client, PlayerLevel_Bots, iMaxLevel, currExperience, targExperience, ratingFormatted, Points_Director);
		}
	}
	ReplaceString(text, sizeof(text), "PCT", "%%", true);
	Format(text, sizeof(text), "\n \n%s\n \n", text);
	if (!bIsPanel) SetMenuTitle(menu, text);
	else DrawPanelText(menu, text);
}