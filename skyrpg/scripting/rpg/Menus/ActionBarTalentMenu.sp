public Handle TalentInfoScreen_Special(client) {
	char TalentName[64];
	Format(TalentName, sizeof(TalentName), "%s", PurchaseTalentName[client]);

	Handle menu = CreatePanel();
	int menuPos					= GetMenuPosition(client, TalentName);

	int AbilityTalent			= GetArrayCell(PurchaseValues[client], IS_TALENT_ABILITY);

	char TalentIdCode[64];
	char theval[64];
	FormatKeyValue(theval, sizeof(theval), PurchaseKeys[client], PurchaseValues[client], "id_number");
	Format(TalentIdCode, sizeof(TalentIdCode), "%T", "Talent Id Code", client);
	Format(TalentIdCode, sizeof(TalentIdCode), "%s: %s", TalentIdCode, theval);

	

	//	We copy the talent name to another string so we can show the talent in the language of the player.

	

	//	Talents now have a brief description of what they do on their purchase page.
	//	This variable is pre-determined and calls a translation file in the language of the player.
	
	char TalentInfo[128];
	char text[512];

	if (AbilityTalent != 1) {
		char TalentName_Temp[64];
		GetTranslationOfTalentName(client, TalentName, TalentName_Temp, sizeof(TalentName_Temp), _, true);
		Format(TalentName_Temp, sizeof(TalentName_Temp), "%T", TalentName_Temp, client);

		GetTranslationOfTalentName(client, TalentName, TalentInfo, sizeof(TalentInfo));

		Format(TalentInfo, sizeof(TalentInfo), "%T", TalentInfo, client);

		float fltime = GetSpecialAmmoStrength(client, TalentName, _, _, _, menuPos);
		float fltimen = GetSpecialAmmoStrength(client, TalentName, 0, true, _, menuPos);

		Format(text, sizeof(text), "%T", "Special Ammo Time", client, fltime, fltimen);
		DrawPanelText(menu, text);
		//Format(text, sizeof(text), "%T", "Special Ammo Interval", client, GetSpecialAmmoStrength(client, TalentName, 4), GetSpecialAmmoStrength(client, TalentName, 4, true));
		//DrawPanelText(menu, text);
		Format(text, sizeof(text), "%T", "Special Ammo Cooldown", client, fltime + GetSpecialAmmoStrength(client, TalentName, 1, _, _, menuPos), fltimen + GetSpecialAmmoStrength(client, TalentName, 1, true, _, menuPos));
		DrawPanelText(menu, text);
		Format(text, sizeof(text), "%T", "Special Ammo Stamina", client, RoundToCeil(GetSpecialAmmoStrength(client, TalentName, 2, _, _, menuPos)), RoundToCeil(GetSpecialAmmoStrength(client, TalentName, 2, true, _, menuPos)));
		DrawPanelText(menu, text);
		Format(text, sizeof(text), "%T", "Special Ammo Range", client, GetSpecialAmmoStrength(client, TalentName, 3, _, _, menuPos), GetSpecialAmmoStrength(client, TalentName, 3, true, _, menuPos));
		DrawPanelText(menu, text);
		DrawPanelText(menu, TalentIdCode);
	}
	else {
		GetTranslationOfTalentName(client, TalentName, TalentInfo, sizeof(TalentInfo), _, true);
		Format(TalentInfo, sizeof(TalentInfo), "%T", TalentInfo, client);
		DrawPanelText(menu, TalentInfo);
	}

	// We only have the option to assign it to action bars, instead.
	char ActionBarText[64];
	int ActionBarSize = GetArraySize(ActionBar[client]);
	for (int i = 0; i < ActionBarSize; i++) {
		GetArrayString(ActionBar[client], i, ActionBarText, sizeof(ActionBarText));
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
		GetAbilityText(client, text, sizeof(text), PurchaseKeys[client], PurchaseValues[client], ABILITY_PASSIVE_EFFECT);
		if (!StrEqual(text, "-1")) DrawPanelText(menu, text);
		GetAbilityText(client, text, sizeof(text), PurchaseKeys[client], PurchaseValues[client], ABILITY_TOGGLE_EFFECT);
		if (!StrEqual(text, "-1")) DrawPanelText(menu, text);
		GetAbilityText(client, text, sizeof(text), PurchaseKeys[client], PurchaseValues[client], ABILITY_COOLDOWN_EFFECT);
		if (!StrEqual(text, "-1")) DrawPanelText(menu, text);
	}
	else DrawPanelText(menu, TalentInfo);	// rawline means not a selectable option.
	return menu;
}

public TalentInfoScreen_Init (Handle topmenu, MenuAction action, client, param2)
{
	if (action == MenuAction_Select)
	{
		int MaxPoints = 1;	// all talents have a minimum of 1 max points, including spells and abilities.
		int TalentStrength = GetTalentStrength(client, PurchaseTalentName[client]);
		char TalentName[64];
		Format(TalentName, sizeof(TalentName), "%s", PurchaseTalentName[client]);
		int menuPos = GetMenuPosition(client, TalentName);

		//decl String:sTalentsRequired[64];
		//FormatKeyValue(sTalentsRequired, sizeof(sTalentsRequired), PurchaseKeys[client], PurchaseValues[client], "talents required?");
		int requiredTalentsRequired = GetArrayCell(PurchaseValues[client], NUM_TALENTS_REQ);
		if (requiredTalentsRequired > 0) requiredTalentsRequired = TalentRequirementsMet(client, PurchaseKeys[client], PurchaseValues[client], _, _, requiredTalentsRequired);
		
		int nodeUnlockCost = 1;
		bool isNodeCostMet = (UpgradesAvailable[client] + FreeUpgrades[client] >= nodeUnlockCost) ? true : false;
		int currentLayer = GetArrayCell(PurchaseValues[client], GET_TALENT_LAYER);
		//new ignoreLayerCount = GetKeyValueInt(PurchaseKeys[client], PurchaseValues[client], "ignore for layer count?");
		int ignoreLayerCount = (GetArrayCell(PurchaseValues[client], LAYER_COUNTING_IS_IGNORED) == 1) ? 1 : (GetArrayCell(PurchaseValues[client], IS_ATTRIBUTE) == 1) ? 1 : 0;	// attributes both count towards the layer requirements and can be unlocked when the layer requirements are met.

		bool bIsLayerEligible = (TalentStrength > 0) ? true : false;
		if (!bIsLayerEligible) {
			bIsLayerEligible = (requiredTalentsRequired < 1 && (PlayerCurrentMenuLayer[client] <= 1 || GetLayerUpgradeStrength(client, PlayerCurrentMenuLayer[client] - 1) >= RoundToCeil(GetLayerUpgradeStrength(client, PlayerCurrentMenuLayer[client] - 1, _, _, _, true, true) * fUpgradesRequiredPerLayer))) ? true : false;
			if (bIsLayerEligible) bIsLayerEligible = ((ignoreLayerCount == 1 || GetLayerUpgradeStrength(client, PlayerCurrentMenuLayer[client], _, _, _, _, true) < RoundToCeil(GetLayerUpgradeStrength(client, PlayerCurrentMenuLayer[client], _, _, _, true, true) * fUpgradesRequiredPerLayer)) && UpgradesAvailable[client] + FreeUpgrades[client] >= nodeUnlockCost) ? true : false;
		}
		switch (param2) {
			case 1: {
				if (bIsLayerEligible) {
					if (TalentStrength == 0) {
						if (UpgradesAvailable[client] + FreeUpgrades[client] < nodeUnlockCost) BuildSubMenu(client, OpenedMenu[client], MenuSelection[client]);
						else if (isNodeCostMet && TalentStrength + 1 <= MaxPoints) {
						//else if ((UpgradesAvailable[client] > 0 || FreeUpgrades[client] > 0) && TalentStrength + 1 <= MaxPoints) {
							if (UpgradesAvailable[client] >= nodeUnlockCost) {
								UpgradesAvailable[client] -= nodeUnlockCost;
								PlayerLevelUpgrades[client]++;
							}
							else if (FreeUpgrades[client] >= nodeUnlockCost) FreeUpgrades[client] -= nodeUnlockCost;
							else {
								nodeUnlockCost -= FreeUpgrades[client];
								UpgradesAvailable[client] -= nodeUnlockCost;
							}
							TryToTellPeopleYouUpgraded(client);
							PlayerUpgradesTotal[client]++;
							PurchaseTalentPoints[client]++;
							AddTalentPoints(client, menuPos, PurchaseTalentPoints[client]);
							SetClientTalentStrength(client);
							SendPanelToClientAndClose(TalentInfoScreen(client), client, TalentInfoScreen_Init, MENU_TIME_FOREVER);
						}
					}
					else if (!IsAmmoActive(client, PurchaseTalentName[client])) {
						PlayerUpgradesTotal[client]--;
						PurchaseTalentPoints[client]--;
						FreeUpgrades[client] += nodeUnlockCost;
						AddTalentPoints(client, menuPos, PurchaseTalentPoints[client]);

						// Check if locking this node makes them ineligible for deeper trees, and remove points
						// in those talents if it's the case, locking the nodes.
						GetLayerUpgradeStrength(client, currentLayer, true);
						SetClientTalentStrength(client);
						SendPanelToClientAndClose(TalentInfoScreen(client), client, TalentInfoScreen_Init, MENU_TIME_FOREVER);
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
	if (action == MenuAction_End)
	{
		CloseHandle(topmenu);
	}
	/*else if (topmenu != INVALID_HANDLE)
	{
		CloseHandle(topmenu);
	}*/
}

public TalentInfoScreen_Special_Init (Handle topmenu, MenuAction action, client, param2) {
	if (action == MenuAction_Select) {
		int ActionBarSize = GetArraySize(ActionBar[client]);
		if (param2 > ActionBarSize) BuildSubMenu(client, OpenedMenu[client], MenuSelection[client]);
		else {
			// don't let users replace an ability or spell that's currently on cooldown.
			char currentlyEquippedAction[64];
			GetArrayString(ActionBar[client], param2 - 1, currentlyEquippedAction, sizeof(currentlyEquippedAction));
			if (!SwapActions(client, PurchaseTalentName[client], param2 - 1)) {
				int menuPos = GetMenuPosition(client, PurchaseTalentName[client]);
				//	Prevent an ability (or spell) on cooldown from being removed from the action bar
				//	Abilities now require an upgrade point in their node in order to be used.
				if (!IsAmmoActive(client, currentlyEquippedAction) && GetTalentStrength(client, PurchaseTalentName[client], _, menuPos) > 0) {
					SetArrayString(ActionBar[client], param2 - 1, PurchaseTalentName[client]);
					SetArrayCell(ActionBarMenuPos[client], param2 - 1, menuPos);
				}
			}
			SendPanelToClientAndClose(TalentInfoScreen_Special(client), client, TalentInfoScreen_Special_Init, MENU_TIME_FOREVER);
		}
		//CloseHandle(topmenu);
	}
	if (action == MenuAction_End) {

		CloseHandle(topmenu);
	}
}

bool SwapActions(client, char[] TalentName, slot) {
	char text[64];
	char text2[64];

	int size = GetArraySize(ActionBar[client]);
	for (int i = 0; i < size; i++) {
		GetArrayString(ActionBar[client], i, text, sizeof(text));
		if (!StrEqual(TalentName, text)) continue;
		GetArrayString(ActionBar[client], slot, text2, sizeof(text2));

		SetArrayString(ActionBar[client], i, text2);
		SetArrayCell(ActionBarMenuPos[client], i, GetMenuPosition(client, text2));
		SetArrayString(ActionBar[client], slot, text);
		SetArrayCell(ActionBarMenuPos[client], slot, GetMenuPosition(client, text));
		return true;
	}
	return false;
}