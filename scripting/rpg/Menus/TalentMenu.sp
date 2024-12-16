stock BuildSubMenu(client, char[] MenuName, char[] ConfigName, char[] ReturnMenu = "none") {
	bIsClassAbilities[client] = false;
	// Each talent has a defined "menu name" ("part of menu named?") and will list under that menu. Genius, right?
	Handle menu					=	CreateMenu(BuildSubMenuHandle);
	// So that back buttons work properly we need to know the previous menu; Store the current menu.
	if (!StrEqual(ReturnMenu, "none", false)) Format(OpenedMenu[client], sizeof(OpenedMenu[]), "%s", ReturnMenu);
	Format(OpenedMenu_p[client], sizeof(OpenedMenu_p[]), "%s", OpenedMenu[client]);
	Format(OpenedMenu[client], sizeof(OpenedMenu[]), "%s", MenuName);
	Format(MenuSelection_p[client], sizeof(MenuSelection_p[]), "%s", MenuSelection[client]);
	Format(MenuSelection[client], sizeof(MenuSelection[]), "%s", ConfigName);

	bool configIsForTalents = (IsTalentConfig(ConfigName) || StrEqual(ConfigName, CONFIG_SURVIVORTALENTS));

	if (!b_IsDirectorTalents[client]) {

		if (configIsForTalents) {

			BuildMenuTitle(client, menu, _, 1, _, ShowPlayerLayerInformation[client]);
		}
		else if (StrEqual(ConfigName, CONFIG_POINTS)) {

			BuildMenuTitle(client, menu, _, 2, _, false);
		}
	}
	else BuildMenuTitle(client, menu, 1);

	char text[PLATFORM_MAX_PATH];
	char pct[4];
	char TalentName[128];
	char TalentName_Temp[128];
	int isSubMenu = 0;
	int PlayerTalentPoints			=	0;
	//new AbilityInherited			=	0;
	//new StorePurchaseCost			=	0;
	int AbilityTalent				=	0;
	int isSpecialAmmo				=	0;
	//decl String:sClassAllowed[64];
	//decl String:sClassID[64];
	char sTalentsRequired[512];
	bool bIsNotEligible = false;
	//new iSkyLevelReq = 0;//deprecated for now
	//new nodeUnlockCost = 0;
	int optionsRemaining = 0;
	Format(pct, sizeof(pct), "%");//required for translations

	int size						=	GetArraySize(a_Menu_Talents);
	// all talents are now housed in a shared config file... taking our total down to like.. 14... sigh... is customization really worth that headache?
	// and I mean the headache for YOU, not the headache for me. This is easy. EASY. YOU CAN'T BREAK ME.
	//if (StrEqual(ConfigName, CONFIG_MENUSURVIVOR)) size			=	GetArraySize(a_Menu_Talents_Survivor);
	//else if (StrEqual(ConfigName, CONFIG_MENUINFECTED)) size	=	GetArraySize(a_Menu_Talents_Infected);
	
	// so if we're not equipping items to the action bar, we show them based on which submenu we've called.
	// these keys/values/section names match their talentmenu.cfg notations.
	int requiredTalentsRequiredToUnlock = 0;
	int requiredCopy = 0;
	bool isClientSurvivor = (myCurrentTeam[client] == TEAM_SURVIVOR || myCurrentTeam[client] == TEAM_SPECTATOR) ? true : false;
	bool isClientInfected = (myCurrentTeam[client] == TEAM_INFECTED) ? true : false;
	for (int i = 0; i < size; i++) {
		MenuValues[client]			= GetArrayCell(a_Menu_Talents, i, 1);
		int activatorClassesAllowed = GetArrayCell(MenuValues[client], ACTIVATOR_CLASS_REQ);
		if (activatorClassesAllowed > -1) {
			bool isSurvivorTalent		= (activatorClassesAllowed % 2 == 1) ? true : false;
			bool isInfectedTalent		= (activatorClassesAllowed > 1) ? true : false;
			if (isSurvivorTalent && !isClientSurvivor) continue;
			if (isInfectedTalent && !isClientInfected) continue;
		}

		MenuKeys[client]			= GetArrayCell(a_Menu_Talents, i, 0);
		//MenuSection[client]			= GetArrayCell(a_Menu_Talents, i, 2);

		GetArrayString(a_Database_Talents, i, TalentName, sizeof(TalentName));
		if (!bEquipSpells[client] && !TalentListingFound(client, MenuValues[client], MenuName)) continue;
		AbilityTalent	=	GetArrayCell(MenuValues[client], IS_TALENT_ABILITY);
		isSpecialAmmo	=	GetArrayCell(MenuValues[client], TALENT_IS_SPELL);
		PlayerTalentPoints = GetArrayCell(MyTalentStrength[client], i);

		if (bEquipSpells[client]) {
			if (AbilityTalent != 1 && isSpecialAmmo != 1) continue;
			if (PlayerTalentPoints < 1) continue;

			//Format(TalentName_Temp, sizeof(TalentName_Temp), "%T", TalentName, client);
			GetArrayString(MenuValues[client], ACTION_BAR_NAME, text, sizeof(text));
			if (StrEqual(text, "-1")) SetFailState("%s missing action bar name", TalentName);
			Format(text, sizeof(text), "%T", text, client);
			AddMenuItem(menu, text, text);
			continue;
		}

		GetTranslationOfTalentName(client, TalentName, TalentName_Temp, sizeof(TalentName_Temp), true);
		Format(TalentName_Temp, sizeof(TalentName_Temp), "%T", TalentName_Temp, client);
		isSubMenu = GetArrayCell(MenuValues[client], IS_SUB_MENU_OF_TALENTCONFIG);
		// isSubMenu 3 is for a different operation, we do || instead of &&
		if (isSubMenu == 1 || isSubMenu == 2) {

			// We strictly show the menu option.
			Format(text, sizeof(text), "%T", "Submenu Available", client, TalentName_Temp);
		}
		else {
			//AbilityInherited = GetKeyValueInt(MenuKeys[client], MenuValues[client], "ability inherited?");
			//nodeUnlockCost = GetKeyValueInt(MenuKeys[client], MenuValues[client], "node unlock cost?", "1");	// we want to default the nodeUnlockCost to 1 if it's not set.
			if (!b_IsDirectorTalents[client]) {
				//FormatKeyValue(sTalentsRequired, sizeof(sTalentsRequired), MenuKeys[client], MenuValues[client], "talents required?");
				//if (GetKeyValueInt(MenuKeys[client], MenuValues[client], "show debug info?") == 1) PrintToChat(client, "%s", sTalentsRequired);
				requiredTalentsRequiredToUnlock = GetArrayCell(MenuValues[client], NUM_TALENTS_REQ);
				requiredCopy = requiredTalentsRequiredToUnlock;
				optionsRemaining = TalentRequirementsMet(client, MenuKeys[client], MenuValues[client], _, -1);
				if (requiredTalentsRequiredToUnlock > 0) requiredTalentsRequiredToUnlock = TalentRequirementsMet(client, MenuKeys[client], MenuValues[client], sTalentsRequired, sizeof(sTalentsRequired), requiredTalentsRequiredToUnlock);
				if (requiredTalentsRequiredToUnlock > 0) {
					bIsNotEligible = true;
					if (PlayerTalentPoints > 0) {
						FreeUpgrades[client]++;// += nodeUnlockCost;
						PlayerUpgradesTotal[client] -= PlayerTalentPoints;
						AddTalentPoints(client, i, 0);
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
						AddTalentPoints(client, i, (PlayerTalentPoints - 1));
					}
				}
			}
			else PlayerTalentPoints = GetTalentStrength(-1, _, _, i);
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
				Format(text, sizeof(text), "%T", "node locked", client, TalentName_Temp, 1);
			}
			else Format(text, sizeof(text), "%T", "node unlocked", client, TalentName_Temp);
		}
		AddMenuItem(menu, text, text);
	}
	SetMenuExitBackButton(menu, true);
	DisplayMenu(menu, client, 0);
}

public BuildSubMenuHandle(Handle menu, MenuAction action, client, slot)
{
	if (action == MenuAction_Select)
	{
		char ConfigName[64];
		Format(ConfigName, sizeof(ConfigName), "%s", MenuSelection[client]);
		char MenuName[64];
		Format(MenuName, sizeof(MenuName), "%s", OpenedMenu[client]);
		int pos							=	-1;

		BuildMenuTitle(client, menu);

		char pct[4];

		char TalentName[64];
		int isSubMenu = 0;


		int PlayerTalentPoints			=	0;

		char SurvEffects[64];
		Format(SurvEffects, sizeof(SurvEffects), "0");

		Format(pct, sizeof(pct), "%");

		int size						=	GetArraySize(a_Menu_Talents);
		int TalentLevelRequired			= 0;
		int AbilityTalent				= 0;
		int isSpecialAmmo				= 0;
		//decl String:sClassAllowed[64];
		//decl String:sClassID[64];
		//decl String:sTalentsRequired[64];
		//new nodeUnlockCost = 0;

		//new bool:bIsNotEligible = false;

		//new iSkyLevelReq = 0;

		//if (StrEqual(ConfigName, CONFIG_MENUSURVIVOR)) size			=	GetArraySize(a_Menu_Talents_Survivor);
		//else if (StrEqual(ConfigName, CONFIG_MENUINFECTED)) size	=	GetArraySize(a_Menu_Talents_Infected);
		bool isClientSurvivor = (myCurrentTeam[client] == TEAM_SURVIVOR || myCurrentTeam[client] == TEAM_SPECTATOR) ? true : false;
		bool isClientInfected = (myCurrentTeam[client] == TEAM_INFECTED) ? true : false;
		for (int i = 0; i < size; i++) {
			MenuValues[client]				= GetArrayCell(a_Menu_Talents, i, 1);
			int activatorClassesAllowed = GetArrayCell(MenuValues[client], ACTIVATOR_CLASS_REQ);
			if (activatorClassesAllowed > -1) {
				bool isSurvivorTalent		= (activatorClassesAllowed % 2 == 1) ? true : false;
				bool isInfectedTalent		= (activatorClassesAllowed > 1) ? true : false;
				if (isSurvivorTalent && !isClientSurvivor) continue;
				if (isInfectedTalent && !isClientInfected) continue;
			}

			MenuKeys[client]				= GetArrayCell(a_Menu_Talents, i, 0);
			//MenuSection[client]				= GetArrayCell(a_Menu_Talents, i, 2);

			GetArrayString(a_Database_Talents, i, TalentName, sizeof(TalentName));
			if (!bEquipSpells[client] && !TalentListingFound(client, MenuValues[client], MenuName)) continue;
			AbilityTalent	=	GetArrayCell(MenuValues[client], IS_TALENT_ABILITY);
			isSpecialAmmo	=	GetArrayCell(MenuValues[client], TALENT_IS_SPELL);
			PlayerTalentPoints = GetArrayCell(MyTalentStrength[client], i);
			if (bEquipSpells[client]) {
				if (AbilityTalent != 1 && isSpecialAmmo != 1) continue;
				if (PlayerTalentPoints < 1) continue;
			}
			isSubMenu = GetArrayCell(MenuValues[client], IS_SUB_MENU_OF_TALENTCONFIG);
			//iSkyLevelReq	=	GetKeyValueInt(MenuKeys[client], MenuValues[client], "sky level requirement?");
			//nodeUnlockCost = GetKeyValueInt(MenuKeys[client], MenuValues[client], "node unlock cost?", "1");
			//FormatKeyValue(sTalentsRequired, sizeof(sTalentsRequired), MenuKeys[client], MenuValues[client], "talents required?");
			//if (!TalentRequirementsMet(client, sTalentsRequired)) continue;
			pos++;
			//FormatKeyValue(SurvEffects, sizeof(SurvEffects), MenuKeys[client], MenuValues[client], "survivor ability effects?");
			if (pos == slot) break;
		}

		if (isSubMenu == 1 || isSubMenu == 2) {
			BuildSubMenu(client, TalentName, MenuSelection[client], OpenedMenu[client]);
		}
		else {
			//PlayerTalentPoints = GetArrayCell(MyTalentStrength[client], i);
			//if (AbilityTalent == 1 || PlayerLevel[client] >= TalentLevelRequired || bEquipSpells[client]) {// submenu 2 is to send to spell equip screen *Flex*
			if (PlayerLevel[client] >= TalentLevelRequired || bEquipSpells[client]) {// submenu 2 is to send to spell equip screen *Flex*

				PurchaseTalentName[client] = TalentName;
				PurchaseTalentPoints[client] = PlayerTalentPoints;

				if (bEquipSpells[client]) ShowTalentInfoScreen(client, TalentName, MenuKeys[client], MenuValues[client], true);
				else ShowTalentInfoScreen(client, TalentName, MenuKeys[client], MenuValues[client]);
			}
			else {
				char TalentName_temp[64];
				Format(TalentName_temp, sizeof(TalentName_temp), "%T", TalentName, client);

				PrintToChat(client, "%T", "talent level requirement not met", client, orange, blue, TalentLevelRequired, orange, green, TalentName_temp);
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

stock ShowTalentInfoScreen(client, char[] TalentName, Handle Keys, Handle Values, bool bIsEquipSpells = false) {

	PurchaseKeys[client] = Keys;
	PurchaseValues[client] = Values;
	Format(PurchaseTalentName[client], sizeof(PurchaseTalentName[]), "%s", TalentName);

	if (bIsEquipSpells) SendPanelToClientAndClose(TalentInfoScreen_Special(client), client, TalentInfoScreen_Special_Init, MENU_TIME_FOREVER);
	else SendPanelToClientAndClose(TalentInfoScreen(client), client, TalentInfoScreen_Init, MENU_TIME_FOREVER);
}

public Handle TalentInfoScreen(client) {
	int AbilityTalent			= GetArrayCell(PurchaseValues[client], IS_TALENT_ABILITY);
	int IsSpecialAmmo = GetArrayCell(PurchaseValues[client], TALENT_IS_SPELL);

	Handle menu = CreatePanel();
	BuildMenuTitle(client, menu, _, 0, true, true, 1);

	char TalentName[64];
	Format(TalentName, sizeof(TalentName), "%s", PurchaseTalentName[client]);
	int menuPos = GetMenuPosition(client, TalentName);

	int TalentPointAmount		= 0;
	if (!b_IsDirectorTalents[client]) TalentPointAmount = GetTalentStrength(client, TalentName, _, menuPos);
	else TalentPointAmount = GetTalentStrength(-1, TalentName, _, menuPos);

	int nodeUnlockCost = 1;

	float s_TalentPoints = GetTalentInfo(client, PurchaseValues[client]);
	float s_OtherPointNext = GetTalentInfo(client, PurchaseValues[client], _, true);

	char pct[4];
	Format(pct, sizeof(pct), "%");
	
	float f_CooldownNow = GetTalentInfo(client, PurchaseValues[client], 3);
	float f_CooldownNext = GetTalentInfo(client, PurchaseValues[client], 3, true);

	float spellCooldownReduction = GetAbilityMultiplier(client, "L");
	if (spellCooldownReduction > 0.0) {
		f_CooldownNow -= (f_CooldownNow * spellCooldownReduction);
		f_CooldownNext -= (f_CooldownNext * spellCooldownReduction);
	}

	char TalentIdCode[64];
	char TalentIdNum[64];
	FormatKeyValue(TalentIdNum, sizeof(TalentIdNum), PurchaseKeys[client], PurchaseValues[client], "id_number");

	Format(TalentIdCode, sizeof(TalentIdCode), "%T", "Talent Id Code", client);
	Format(TalentIdCode, sizeof(TalentIdCode), "%s: %s", TalentIdCode, TalentIdNum);

	//	We copy the talent name to another string so we can show the talent in the language of the player.
	
	char TalentName_Temp[64];
	char TalentNameTranslation[64];
	GetTranslationOfTalentName(client, TalentName, TalentNameTranslation, sizeof(TalentNameTranslation), true);
	Format(TalentName_Temp, sizeof(TalentName_Temp), "%T", TalentNameTranslation, client);
	char text[1024];
	if (FreeUpgrades[client] < 0) FreeUpgrades[client] = 0;
	// if (AbilityTalent != 1) {
	// 	Format(text, sizeof(text), "%T", "Talent Upgrade Title", client, TalentName_Temp, TalentPointAmount);
	// }
	// else Format(text, sizeof(text), "%s", TalentName_Temp);
	// DrawPanelText(menu, text);

	char governingAttribute[64];
	GetGoverningAttribute(client, governingAttribute, sizeof(governingAttribute), menuPos);
	if (!StrEqual(governingAttribute, "-1")) {
		Format(text, sizeof(text), "%T", governingAttribute, client);
		Format(text, sizeof(text), "%T", "Node Governing Attribute", client, text);
		DrawPanelText(menu, text);
	}
	float AoEEffectRange = GetArrayCell(PurchaseValues[client], PRIMARY_AOE);
	if (AoEEffectRange > 0.0) {
		Format(text, sizeof(text), "%T", "primary aoe range", client, AoEEffectRange);
		DrawPanelText(menu, text);
	}
	AoEEffectRange = GetArrayCell(PurchaseValues[client], SECONDARY_AOE);
	if (AoEEffectRange > 0.0) {
		Format(text, sizeof(text), "%T", "secondary aoe range", client, AoEEffectRange);
		DrawPanelText(menu, text);
	}
	AoEEffectRange = GetArrayCell(PurchaseValues[client], MULTIPLY_RANGE);
	if (AoEEffectRange > 0.0) {
		Format(text, sizeof(text), "%T", "multiply aoe range", client, AoEEffectRange);
		DrawPanelText(menu, text);
	}
	bool IsEffectOverTime = (GetArrayCell(PurchaseValues[client], TALENT_IS_EFFECT_OVER_TIME) == 1) ? true : false;

	char TalentInfo[512];
	int AbilityType = 0;
	bool bIsAttribute = (GetArrayCell(PurchaseValues[client], IS_ATTRIBUTE) == 1) ? true : false;
	int iContributionCategoryRequired = -1;
	if (AbilityTalent != 1) {
		if (IsSpecialAmmo != 1) {
			if (f_CooldownNext > 0.0) {
				if (TalentPointAmount == 0) Format(text, sizeof(text), "%T", "Talent Cooldown Info - No Points", client, f_CooldownNext);
				else Format(text, sizeof(text), "%T", "Talent Cooldown Info", client, f_CooldownNow, f_CooldownNext);
				DrawPanelText(menu, text);
			}
			//else Format(text, sizeof(text), "%T", "No Talent Cooldown Info", client);

			float i_AbilityTime = GetTalentInfo(client, PurchaseValues[client], 2);
			float i_AbilityTimeNext = GetTalentInfo(client, PurchaseValues[client], 2, true);
			/*
				ability type ONLY EXISTS for displaying different information to the players via menus.
				the EXCEPTION to this is type 3, where rpg_functions.sp line 2428 makes a check using it.

				Otherwise, it's just how we translate it for the player to understand.
			*/
			AbilityType = GetArrayCell(PurchaseValues[client], ABILITY_TYPE);
			int hideStrengthDisplayFromPlayer = GetArrayCell(PurchaseValues[client], HIDE_TALENT_STRENGTH_DISPLAY);
			if (AbilityType < 0) AbilityType = 0;	// if someone forgets to set this, we have to set it to the default value.
			//if (TalentPointAmount > 0) s_PenaltyPoint = 0.0;
			int multiplyCount = (GetArrayCell(PurchaseValues[client], STATUS_EFFECT_MULTIPLIER) >= 1) ? MyStatusEffects[client] : 1;
			int iMultiplyLimit = GetArrayCell(PurchaseValues[client], MULTIPLY_LIMIT);
			if (multiplyCount < 1) multiplyCount = 1;
			if (iMultiplyLimit < 0) iMultiplyLimit = 0;
			if (iMultiplyLimit > 1 && multiplyCount > iMultiplyLimit) multiplyCount = iMultiplyLimit;

			if (hideStrengthDisplayFromPlayer != 1) {
				if (TalentPointAmount < 1) {
					if (AbilityType == 0) {
						Format(text, sizeof(text), "%T", "Ability Info Percent", client, (multiplyCount * s_TalentPoints) * 100.0, pct, (multiplyCount * s_OtherPointNext) * 100.0, pct);
						if (iMultiplyLimit > 0) Format(text, sizeof(text), "%s\nTalent Max Strength: %3.3f%s", text, (s_OtherPointNext * 100.0) * iMultiplyLimit, pct);
					}
					else if (AbilityType == 1) {
						Format(text, sizeof(text), "%T", "Ability Info Time", client, multiplyCount * i_AbilityTime, multiplyCount * i_AbilityTimeNext);
						if (iMultiplyLimit > 0) Format(text, sizeof(text), "%s\nTalent Max Strength: %d sec(s)", text, i_AbilityTimeNext * iMultiplyLimit);
					}
					else if (AbilityType == 2) {
						Format(text, sizeof(text), "%T", "Ability Info Distance", client, multiplyCount * s_TalentPoints, multiplyCount * s_OtherPointNext);
						if (iMultiplyLimit > 0) Format(text, sizeof(text), "%s\nTalent Max Strength: %3.3f unit(s)", text, (s_OtherPointNext * 100.0) * iMultiplyLimit);
					}
					else if (AbilityType == 3) {
						Format(text, sizeof(text), "%T", "Ability Info Raw", client, multiplyCount * RoundToCeil(s_TalentPoints), multiplyCount * RoundToCeil(s_OtherPointNext));
						if (iMultiplyLimit > 0) Format(text, sizeof(text), "%s\nTalent Max Strength: %d", text, RoundToCeil(s_TalentPoints) * iMultiplyLimit);
					}
				}
				else {
					if (AbilityType == 0) {
						Format(text, sizeof(text), "%T", "Ability Info Percent Max", client, (multiplyCount * s_TalentPoints) * 100.0, pct);
						if (iMultiplyLimit > 0) Format(text, sizeof(text), "%s\nTalent Max Strength: %3.3f%s", text, (s_TalentPoints * 100.0) * iMultiplyLimit, pct);
					}
					else if (AbilityType == 1) {
						Format(text, sizeof(text), "%T", "Ability Info Time Max", client, multiplyCount * i_AbilityTime);
						if (iMultiplyLimit > 0) Format(text, sizeof(text), "%s\nTalent Max Strength: %d sec(s)", text, i_AbilityTime * iMultiplyLimit);
					}
					else if (AbilityType == 2) {
						Format(text, sizeof(text), "%T", "Ability Info Distance Max", client, multiplyCount * s_TalentPoints);
						if (iMultiplyLimit > 0) Format(text, sizeof(text), "%s\nTalent Max Strength: %3.3f unit(s)", text, s_TalentPoints * iMultiplyLimit);
					}
					else if (AbilityType == 3) {
						Format(text, sizeof(text), "%T", "Ability Info Raw Max", client, multiplyCount * RoundToCeil(s_TalentPoints));
						if (iMultiplyLimit > 0) Format(text, sizeof(text), "%s\nTalent Max Strength: %d", text, RoundToCeil(s_TalentPoints) * iMultiplyLimit);
					}
				}
			}
			else Format(text, sizeof(text), "");
			// new Float:rollChance = GetArrayCell(PurchaseValues[client], TALENT_ROLL_CHANCE);
			// if (rollChance > 0.0) {
			// 	decl String:rollChanceText[64];
			// 	Format(rollChanceText, sizeof(rollChanceText), "%T", "Roll Chance Talent Info", client, rollChance * 100.0, pct);
			// 	Format(text, sizeof(text), "%s\n%s", rollChanceText, text);
			// }
			iContributionCategoryRequired = GetArrayCell(PurchaseValues[client], CONTRIBUTION_TYPE_CATEGORY);
			if (iContributionCategoryRequired >= 0) {
				char contributionRequired[64];
				AddCommasToString(GetArrayCell(PurchaseValues[client], CONTRIBUTION_COST), contributionRequired, sizeof(contributionRequired));
				if (hideStrengthDisplayFromPlayer != 1) {
					if (iContributionCategoryRequired == 0) Format(text, sizeof(text), "%s\nHealing Required: %s", text, contributionRequired);
					else if (iContributionCategoryRequired == 1) Format(text, sizeof(text), "%s\nDamage Required: %s", text, contributionRequired);
					else if (iContributionCategoryRequired == 2) Format(text, sizeof(text), "%s\nTanking Required: %s", text, contributionRequired);
				}
				else {
					if (iContributionCategoryRequired == 0) Format(text, sizeof(text), "Healing Required: %s", contributionRequired);
					else if (iContributionCategoryRequired == 1) Format(text, sizeof(text), "Damage Required: %s", contributionRequired);
					else if (iContributionCategoryRequired == 2) Format(text, sizeof(text), "Tanking Required: %s", contributionRequired);
					DrawPanelText(menu, text);
				}
			}
			if (hideStrengthDisplayFromPlayer != 1) DrawPanelText(menu, text);
			//DrawPanelText(menu, TalentIdCode);
			if (IsEffectOverTime) {
				// Effects over time ALWAYS show the period of time.
				if (TalentPointAmount < 1) Format(text, sizeof(text), "%T", "Ability Info Time", client, i_AbilityTime, i_AbilityTimeNext);
				else Format(text, sizeof(text), "%T", "Ability Info Time Max", client, i_AbilityTime);
				DrawPanelText(menu, text);
			}
			float healthPercentageReqActRemaining = GetArrayCell(PurchaseValues[client], HEALTH_PERCENTAGE_REQ_ACT_REMAINING);
			if (healthPercentageReqActRemaining > 0.0) {
				Format(text, sizeof(text), "%T", "Activator Health Required", client, healthPercentageReqActRemaining * 100.0, pct);
				DrawPanelText(menu, text);
			}
			healthPercentageReqActRemaining = GetArrayCell(PurchaseValues[client], HEALTH_PERCENTAGE_ACTIVATION_COST);
			if (healthPercentageReqActRemaining > 0.0) {
				Format(text, sizeof(text), "%T", "Activator Health Cost", client, healthPercentageReqActRemaining * 100.0, pct, RoundToCeil(healthPercentageReqActRemaining * GetMaximumHealth(client)));
				DrawPanelText(menu, text);
			}
			healthPercentageReqActRemaining = GetArrayCell(PurchaseValues[client], MULT_STR_NEARBY_DOWN_ALLIES);
			if (healthPercentageReqActRemaining > 0.0) {
				Format(text, sizeof(text), "%T", "Multiply Strength Nearby Downed Allies", client, healthPercentageReqActRemaining * 100.0, pct);
				DrawPanelText(menu, text);
			}
		}
		else {


			/*if (FreeUpgrades[client] == 0) Format(text, sizeof(text), "%T", "Talent Upgrade Title", client, TalentName_Temp, TalentPointAmount, TalentPointMaximum);
			else Format(text, sizeof(text), "%T", "Talent Upgrade Title Free", client, TalentName_Temp, TalentPointAmount, TalentPointMaximum, FreeUpgrades[client]);
			SetPanelTitle(menu, text);*/

			float fTimeCur = GetSpecialAmmoStrength(client, TalentName, _, _, _, menuPos);
			float fTimeNex = GetSpecialAmmoStrength(client, TalentName, 0, true, _, menuPos);

			//new Float:flIntCur = GetSpecialAmmoStrength(client, TalentName, 4);
			//new Float:flIntNex = GetSpecialAmmoStrength(client, TalentName, 4, true);

			//if (flIntCur > fTimeCur) flIntCur = fTimeCur;
			//if (flIntNex > fTimeNex) flIntNex = fTimeNex;

			//Format(text, sizeof(text), "%T", "Special Ammo Interval", client, flIntCur, flIntNex);
			//DrawPanelText(menu, text);
			if (TalentPointAmount < 1) {
				Format(text, sizeof(text), "%T", "Special Ammo Time", client, fTimeNex);
				DrawPanelText(menu, text);
				Format(text, sizeof(text), "%T", "Special Ammo Cooldown", client, fTimeNex + GetSpecialAmmoStrength(client, TalentName, 1, true, _, menuPos));
				DrawPanelText(menu, text);
				Format(text, sizeof(text), "%T", "Special Ammo Stamina", client, RoundToCeil(GetSpecialAmmoStrength(client, TalentName, 2, true, _, menuPos)));
				DrawPanelText(menu, text);
				Format(text, sizeof(text), "%T", "Special Ammo Range", client, GetSpecialAmmoStrength(client, TalentName, 3, true, _, menuPos));
				DrawPanelText(menu, text);
			}
			else {
				Format(text, sizeof(text), "%T", "Special Ammo Time Max", client, fTimeCur);
				DrawPanelText(menu, text);
				Format(text, sizeof(text), "%T", "Special Ammo Cooldown Max", client, fTimeCur + GetSpecialAmmoStrength(client, TalentName, 1, _, _, menuPos));
				DrawPanelText(menu, text);
				Format(text, sizeof(text), "%T", "Special Ammo Stamina Max", client, RoundToCeil(GetSpecialAmmoStrength(client, TalentName, 2, _, _, menuPos)));
				DrawPanelText(menu, text);
				Format(text, sizeof(text), "%T", "Special Ammo Range Max", client, GetSpecialAmmoStrength(client, TalentName, 3, _, _, menuPos));
				DrawPanelText(menu, text);
			}
			float fSpecialAmmoEffectStrength = GetValueFloat(client, menuPos, SPECIAL_AMMO_TALENT_STRENGTH);
			float fSpellBuffStrUp = GetAbilityStrengthByTrigger(client, _, TRIGGER_spellbuff, _, _, _, _, RESULT_strengthup, 0, true);
			if (fSpellBuffStrUp > 0.0) fSpecialAmmoEffectStrength += (fSpecialAmmoEffectStrength * fSpellBuffStrUp);
			
			Format(text, sizeof(text), "%T", "Special Ammo Effect Strength", client, fSpecialAmmoEffectStrength * 100.0, pct);
			DrawPanelText(menu, text);
			//DrawPanelText(menu, TalentIdCode);
		}
	}

	if (TalentPointAmount == 0) {
		int ignoreLayerCount = (GetArrayCell(PurchaseValues[client], LAYER_COUNTING_IS_IGNORED) == 1) ? 1 : (bIsAttribute) ? 1 : 0;
		// GetLayerUpgradeStrength(client, PlayerCurrentMenuLayer[client] - 1) >= RoundToCeil(GetLayerUpgradeStrength(client, PlayerCurrentMenuLayer[client] - 1, _, _, true) * fUpgradesRequiredPerLayer)
		int thisLayerUpgradeStrength = GetLayerUpgradeStrength(client, PlayerCurrentMenuLayer[client] - 1);
		bool bIsLayerEligible = (PlayerCurrentMenuLayer[client] <= 1 || fUpgradesRequiredPerLayer > 1.0 && thisLayerUpgradeStrength >= RoundToCeil(fUpgradesRequiredPerLayer) || fUpgradesRequiredPerLayer <= 1.0 && thisLayerUpgradeStrength >= RoundToCeil(GetLayerUpgradeStrength(client, PlayerCurrentMenuLayer[client] - 1, _, _, _, true, true) * fUpgradesRequiredPerLayer)) ? true : false;
		if (bIsLayerEligible) {
			int theNextLayerUpgradeStrength = GetLayerUpgradeStrength(client, PlayerCurrentMenuLayer[client], _, _, _, _, true);
			bIsLayerEligible = ((ignoreLayerCount == 1 || fUpgradesRequiredPerLayer > 1.0 && theNextLayerUpgradeStrength < RoundToCeil(fUpgradesRequiredPerLayer) || fUpgradesRequiredPerLayer <= 1.0 && theNextLayerUpgradeStrength < RoundToCeil(GetLayerUpgradeStrength(client, PlayerCurrentMenuLayer[client], _, _, _, true, true) * fUpgradesRequiredPerLayer)) && UpgradesAvailable[client] + FreeUpgrades[client] >= nodeUnlockCost) ? true : false;
		}
		//decl String:sTalentsRequired[64];
		char formattedTalentsRequired[64];
		//FormatKeyValue(sTalentsRequired, sizeof(sTalentsRequired), PurchaseKeys[client], PurchaseValues[client], "talents required?");
		int requirementsRemaining = GetArrayCell(PurchaseValues[client], NUM_TALENTS_REQ);
		int requiredCopy = requirementsRemaining;
		requirementsRemaining = TalentRequirementsMet(client, PurchaseKeys[client], PurchaseValues[client], formattedTalentsRequired, sizeof(formattedTalentsRequired), requirementsRemaining);
		int optionsRemaining = TalentRequirementsMet(client, PurchaseKeys[client], PurchaseValues[client], _, -1);	// -1 for size gets the count remaining
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
	int talentCombatStatesAllowed = GetArrayCell(PurchaseValues[client], COMBAT_STATE_REQ);
	if (talentCombatStatesAllowed >= 0) {
		if (talentCombatStatesAllowed == 1) Format(text, sizeof(text), "%T", "in combat state required", client);
		else Format(text, sizeof(text), "%T", "no combat state required", client);
		DrawPanelText(menu, text);
	}
	Format(text, sizeof(text), "%T", "return to talent menu", client);
	DrawPanelItem(menu, text);

	if (AbilityTalent != 1 && GetArrayCell(PurchaseValues[client], HIDE_TRANSLATION) != 1) {
		//	Talents now have a brief description of what they do on their purchase page.
		//	This variable is pre-determined and calls a translation file in the language of the player.
		GetTranslationOfTalentName(client, TalentName, TalentNameTranslation, sizeof(TalentNameTranslation));
		//Format(TalentInfo, sizeof(TalentInfo), "%s", GetTranslationOfTalentName(client, TalentName));
		float fPercentageHealthRequired = GetArrayCell(PurchaseValues[client], HEALTH_PERCENTAGE_REQ_MISSING);
		float fPercentageHealthRequiredBelow = GetArrayCell(PurchaseValues[client], HEALTH_PERCENTAGE_REQ);
		float fCoherencyRange = GetArrayCell(PurchaseValues[client], COHERENCY_RANGE);
		float fPercentageHealthAllyMissingRequired = GetArrayCell(PurchaseValues[client], REQUIRE_ALLY_BELOW_HEALTH_PERCENTAGE);
		float fTargetRangeRequired = GetArrayCell(PurchaseValues[client], TARGET_RANGE_REQUIRED);
		int iCoherencyMax = GetArrayCell(PurchaseValues[client], COHERENCY_MAX);

		int consecutiveHitsRequired = GetArrayCell(PurchaseValues[client], REQ_CONSECUTIVE_HITS);
		int consecutiveHeadshotsRequired = GetArrayCell(PurchaseValues[client], REQ_CONSECUTIVE_HEADSHOTS);

		int multiplyStrengthConsecutiveHits = GetArrayCell(PurchaseValues[client], MULT_STR_CONSECUTIVE_HITS);
		int multiplyStrengthConsecutiveMax = GetArrayCell(PurchaseValues[client], MULT_STR_CONSECUTIVE_MAX);
		int multiplyStrengthConsecutiveDiv = GetArrayCell(PurchaseValues[client], MULT_STR_CONSECUTIVE_DIV);

		int multiplyStrengthHeadshotHits = GetArrayCell(PurchaseValues[client], MULT_STR_CONSECUTIVE_HEADSHOTS);
		int multiplyStrengthHeadshotMax = GetArrayCell(PurchaseValues[client], MULT_STR_CONSECUTIVE_HEADSHOTS_MAX);
		int multiplyStrengthHeadshotDiv = GetArrayCell(PurchaseValues[client], MULT_STR_CONSECUTIVE_HEADSHOTS_DIV);
		float fTimeSinceLastAttack = GetArrayCell(PurchaseValues[client], TIME_SINCE_LAST_ACTIVATOR_ATTACK);

		int multiplierCountRequired = GetArrayCell(PurchaseValues[client], STATUS_EFFECT_MULTIPLIER);
		int multiplyLimitForBonus = GetArrayCell(PurchaseValues[client], MULTIPLY_LIMIT);

		if (multiplierCountRequired >= 1 || fTimeSinceLastAttack > 0.0 || consecutiveHitsRequired > 0 || consecutiveHeadshotsRequired ||
			fPercentageHealthRequired > 0.0 || fPercentageHealthRequiredBelow > 0.0 || fCoherencyRange > 0.0 || fPercentageHealthAllyMissingRequired > 0.0 || fTargetRangeRequired > 0.0 ||
			multiplyStrengthConsecutiveHits == 1 && (multiplyStrengthConsecutiveMax > 1 || multiplyStrengthConsecutiveDiv > 1) ||
			multiplyStrengthHeadshotHits == 1 && (multiplyStrengthHeadshotMax > 1 || multiplyStrengthHeadshotDiv > 1)) {
			float fPercentageHealthRequiredMax = GetArrayCell(PurchaseValues[client], HEALTH_PERCENTAGE_REQ_MISSING_MAX);
			// {1:3.2f},{2:s},{3:3.2f},{4:s},{5:3.2f},{6:s},{7:3.2f},{8:i},{9:3.2f},{10:i},{11:i},{12:i}
			Format(TalentInfo, sizeof(TalentInfo), "%T", TalentNameTranslation, client, fPercentageHealthRequired * 100.0, pct, fPercentageHealthRequiredMax * 100.0, pct,
				   fPercentageHealthRequiredBelow * 100.0, pct, fCoherencyRange, iCoherencyMax, fTargetRangeRequired,
				   (consecutiveHitsRequired < 2) ? multiplyStrengthConsecutiveMax : multiplyStrengthConsecutiveMax / consecutiveHitsRequired, multiplyStrengthConsecutiveDiv, multiplyStrengthHeadshotMax, multiplyStrengthHeadshotDiv,
				   consecutiveHitsRequired, consecutiveHeadshotsRequired, fPercentageHealthAllyMissingRequired * 100.0, pct, fTimeSinceLastAttack, multiplierCountRequired, multiplyLimitForBonus);
		}
		else Format(TalentInfo, sizeof(TalentInfo), "%T", TalentNameTranslation, client);

		DrawPanelText(menu, TalentInfo);	// rawline means not a selectable option.
	}
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
	//int isCompoundingTalent = GetArrayCell(PurchaseValues[client], COMPOUNDING_TALENT);	// -1 if no value is provided.
	if (iContributionCategoryRequired >= 0) {
		Format(text, sizeof(text), "%T", "contribution required notice", client);
		DrawPanelText(menu, text);
	}
	// if (isCompoundingTalent == 1) {
	// 	Format(text, sizeof(text), "%T", "compounding talent info", client);
	// 	DrawPanelText(menu, text);
	// }
	if (IsEffectOverTime) {
		Format(text, sizeof(text), "%T", "effect over time talent info", client);
		DrawPanelText(menu, text);
	}
	if (bIsAttribute) {
		// going to list talents on the current layer that this attribute affects.
		//PlayerCurrentMenuLayer
		char talentList[64];
		int count = 0;
		int size = GetArraySize(a_Menu_Talents);
		char talentAttribute[64];
		GetArrayString(PurchaseValues[client], ATTRIBUTE_MULTIPLIER, talentAttribute, sizeof(talentAttribute));
		for (int i = 0; i < size; i++) {
			MenuValues[client]	= GetArrayCell(a_Menu_Talents, i, 1);

			if (GetArrayCell(MenuValues[client], GET_TALENT_LAYER) != PlayerCurrentMenuLayer[client]) continue;
			if (GetArrayCell(MenuValues[client], IS_ATTRIBUTE) == 1) continue;
			GetArrayString(MenuValues[client], GOVERNING_ATTRIBUTE, talentList, sizeof(talentList));
			if (!StrEqual(talentList, talentAttribute)) continue;
			GetArrayString(MenuValues[client], GET_TALENT_NAME, talentList, sizeof(talentList));
			//GetTranslationOfTalentName(client, talentList, talentList, sizeof(talentList), true);
			Format(talentList, sizeof(talentList), "%T", talentList, client);
			if (count > 0) Format(text, sizeof(text), "%s\n%s", text, talentList);
			else Format(text, sizeof(text), "Talents governed by this attribute on this layer:\n \n%s", talentList);
			count++;
		}
		if (count == 0) Format(text, sizeof(text), "No Talents governed by this attribute on this layer.");
		DrawPanelText(menu, text);
	}
	return menu;
}