public BuildMenuTitle(client, Handle:menu, String:translationName[]) {

	decl String:text[512];
	Format(text, sizeof(text), "%T", translationName, client);
	decl String:vendorName[64];
	Format(vendorName, sizeof(vendorName), "Main Menu");
	if (vendorOpened[client] != -1) {

		Format(vendorName, sizeof(vendorName), "%s", GetVendorName(vendorOpened[client]));
		if (!StrEqual(vendorName, "-1", false)) Format(vendorName, sizeof(vendorName), "%T", vendorName, client);
		else {

			Format(vendorName, sizeof(vendorName), "No vendor?");
		}
	}
	ReplaceString(text, sizeof(text), "{VN}", vendorName);
	ReplaceString(text, sizeof(text), "{XP}", AddCommasToString(v_experience[client]));
	ReplaceString(text, sizeof(text), "{TP}", AddCommasToString(v_talentPoints[client]));
	ReplaceString(text, sizeof(text), "{LV}", AddCommasToString(v_level[client]));
	ReplaceString(text, sizeof(text), "{LVM}", AddCommasToString(v_levelMax[client]));
	ReplaceString(text, sizeof(text), "{XPN}", AddCommasToString(CheckExperienceRequirement(client)));


	SetMenuTitle(menu, text);
}

public CheckExperienceRequirement(client) {

	a_Config_Keys = GetArrayCell(a_Config, 0, 1);
	a_Config_Values = GetArrayCell(a_Config, 0, 2);

	new experienceRequirement = StringToInt(GetConfigValue(client, a_Config_Keys, a_Config_Values, "experience start?"));
	new Float:experienceMultiplier = StringToFloat(GetConfigValue(client, a_Config_Keys, a_Config_Values, "experience multiplier?")) * (v_level[client] - 1);
	experienceMultiplier += (1.0 * (v_level[client] - 1));

	new experienceAddLevel = StringToInt(GetConfigValue(client, a_Config_Keys, a_Config_Values, "experience add level cap?"));
	if (v_level[client] - 1 <= experienceAddLevel) experienceAddLevel = v_level[client] - 1;

	experienceRequirement += (StringToInt(GetConfigValue(client, a_Config_Keys, a_Config_Values, "experience add level?")) * experienceAddLevel);

	experienceRequirement += RoundToCeil(experienceRequirement * experienceMultiplier);

	return experienceRequirement;
}

public SpawnVendors() {

	decl String:t_Section[512];
	decl String:t_Keys[512];
	decl String:t_Values[512];
	decl String:currentMap[64];

	new Handle:v_Section = CreateArray(64);
	new Handle:v_Keys = CreateArray(64);
	new Handle:v_Values = CreateArray(64);

	new size = GetArraySize(a_Vendors);
	new entity = 0;
	for (new i = 0; i < size; i++) {

		v_Section = GetArrayCell(a_Vendors, i, 0);
		GetArrayString(v_Section, 0, t_Section, sizeof(t_Section));

		// Check to see if the map is compatible with the vendor.
		GetCurrentMap(currentMap, sizeof(currentMap));

		v_Keys = GetArrayCell(a_Vendors, i, 1);
		v_Values = GetArrayCell(a_Vendors, i, 2);
		Format(t_Keys, sizeof(t_Keys), "%s", GetConfigValue(_, v_Keys, v_Values, "map?"));
		if (!StrEqual(currentMap, t_Keys, false)) continue;
		Format(t_Keys, sizeof(t_Keys), "%s", GetConfigValue(_, v_Keys, v_Values, "spawn chance?"));
		// Vendors have a "spawn chance" which is sometimes always. Here we determine if they spawn.
		if (GetRandomInt(1, RoundToCeil(1.0 / StringToFloat(GetConfigValue(_, v_Keys, v_Values, "spawn chance?")))) != 1) continue;

		entity = CreateEntityByName(t_Section);
		if (entity == -1 || !IsValidEntity(entity)) continue;
		DispatchAllValues(entity, v_Keys, v_Values);
		DispatchSpawn(entity);
		new Float:pos[3];
		pos[0] = StringToFloat(GetConfigValue(_, v_Keys, v_Values, "x?"));
		pos[1] = StringToFloat(GetConfigValue(_, v_Keys, v_Values, "y?"));
		pos[2] = StringToFloat(GetConfigValue(_, v_Keys, v_Values, "z?"));
		TeleportEntity(entity, pos, NULL_VECTOR, NULL_VECTOR);

		// We are essentially storing "entity id" "position in rpg_vendors array"
		// so we match the entity when opening the menu and assign the position held within it to
		// the players vendorOpened value. Cheating? Maybe, but I'm stoned so idgaf.
		PushArrayCell(a_VendorEntity_Keys, entity);
		PushArrayCell(a_VendorEntity_Values, i);

		//GetEntPropString(entity, Prop_Data, "m_iName", t_Values, sizeof(t_Values));
	}
	v_Section = CloneArray(a_Vendors);
	v_Keys = CloneArray(a_Vendors);
	v_Values = CloneArray(a_Vendors);
	ClearArray(v_Section);
	ClearArray(v_Keys);
	ClearArray(v_Values);

	/*

			Vendors are spawned. time to generate the available listings for each vendor this map.

	*/
	size = GetArraySize(a_MainMenu);
	decl String:vendorName[64];		// matching each menu item with the vendor matching its string.
	decl String:vendorItem[64];		// for the menu item.
	decl String:rarityItem[64];
	new rarityVendor;
	new random;
	new xpcost;
	new upgradeslots = 0;
	new upgradeslotsmax = 0;
	new Float:upgradeslotchance = 1.0;
	decl String:t_xpcost[64];
	decl String:t_upgradeslots[64];
	new Float:rarityReduction = 0.01;	// with each rarity above the first non-guaranteed, the rarity is less common by 1%, by default.
	new Float:rarityChance = 1.0;	// if no rarity chance is set, it assumes 100%, so if 3 is guaranteed but no chance is set, and rarity of the item is 4, it would have a 99% chance to roll, by default.
	for (new i = 0; i < size; i++) {

		v_Section	= GetArrayCell(a_MainMenu, i, 0);
		GetArrayString(v_Section, 0, t_Section, sizeof(t_Section));
		v_Keys		= GetArrayCell(a_MainMenu, i, 1);
		v_Values	= GetArrayCell(a_MainMenu, i, 2);

		Format(vendorName, sizeof(vendorName), "%s", GetConfigValue(_, v_Keys, v_Values, "vendor name?"));	// now we know the vendor associated with this item.

		Format(rarityItem, sizeof(rarityItem), "%s", GetConfigValue(_, v_Keys, v_Values, "rarity?"));
		rarityVendor	= StringToInt(GetVendorValue(vendorName, "guaranteed rarity?"));		// matches the vendor this item belongs to based on matching vendor names. very important! THEY MUST MATCH

		if (StrContains(rarityItem, ":", false) != -1) continue;	// the item has already been rolled : is added after it is rolled, so we still know its rarity.
		else {

			if (StringToInt(rarityItem) <= rarityVendor) Format(rarityItem, sizeof(rarityItem), ":%s", rarityItem);
			else {

				// the rarity of this item is greater than the guaranteed rarity this vendor allows.
				// It's unfortunate, but now we have to figure out if this menu option gets the ax.
				rarityChance		= StringToFloat(GetVendorValue(vendorName, "chance rarity?"));
				rarityReduction		= StringToFloat(GetVendorValue(vendorName, "rarity reduction?"));
				// I'm stoned, so I'm really sorry for not writing something other than "if I can write this stoned, why do you need a description?"
				random				= RoundToCeil(1.0 / (rarityChance - (rarityReduction * (StringToInt(rarityItem[1]) - rarityVendor))));
				random = GetRandomInt(1, random);
				if (random == 1) Format(rarityItem, sizeof(rarityItem), ":%s", rarityItem); // see u soon :) if (StrContains(value, ":", false) != -1 && StringToInt(value[1]) >= rarityMinimum) { figure it out }
				else Format(rarityItem, sizeof(rarityItem), ":-1");	// we don't care what the rarity is. the item is -1 and ignored by the vendor until next map.
			}
			SetConfigValue(v_Keys, v_Values, "rarity?", rarityItem);
			/*

				Rolling for the upgrade slots now. yay!

			*/
			xpcost			= StringToInt(GetConfigValue(_, v_Keys, v_Values, "xp cost?"));
			upgradeslots	= StringToInt(GetConfigValue(_, v_Keys, v_Values, "upgrade slots?"));
			upgradeslotsmax	= StringToInt(GetConfigValue(_, v_Keys, v_Values, "max upgrade slots?"));

			while (upgradeslots != upgradeslotsmax) {

				random		= RoundToCeil(1.0 / StringToFloat(GetConfigValue(_, v_Keys, v_Values, "upgrade slot chance?")));
				random		= GetRandomInt(1, random);
				if (random == 1) {

					upgradeslots++;
					xpcost	+= RoundToCeil(xpcost * StringToFloat(GetConfigValue(_, v_Keys, v_Values, "upgrade slot cost?")));
				}
				else upgradeslotsmax--;
			}
			Format(t_xpcost, sizeof(t_xpcost), "%d", xpcost);
			SetConfigValue(v_Keys, v_Values, "xp cost?", t_xpcost);
			Format(t_upgradeslots, sizeof(t_upgradeslots), "%d", upgradeslots);
			SetConfigValue(v_Keys, v_Values, "upgrade slots?", t_upgradeslots);
			SetArrayCell(a_MainMenu, i, v_Values, 2);
		}
	}
	v_Section = CloneArray(a_Vendors);
	v_Keys = CloneArray(a_Vendors);
	v_Values = CloneArray(a_Vendors);
	ClearArray(v_Section);
	ClearArray(v_Keys);
	ClearArray(v_Values);
}

public DispatchAllValues(entity, Handle:Keys, Handle:Values) {

	decl String:dav_k[64];
	decl String:dav_v[64];

	new size			= GetArraySize(Keys);

	for (new i = 0; i < size; i++) {

		GetArrayString(Handle:Keys, i, dav_k, sizeof(dav_k));
		GetArrayString(Handle:Values, i, dav_v, sizeof(dav_v));
		if (StrContains(dav_k, "?", false) == -1) {

			DispatchKeyValue(entity, dav_k, dav_v);
		}
	}
}

public BuildMenu(client) {

	ClearArray(RPGMenuPosition[client]);

	decl String:t_Section[512];
	decl String:t_Keys[512];
	decl String:t_Values[512];

	new Handle:menu = CreateMenu(BuildMenuHandle);
	decl String:menu_title[64];
	Format(menu_title, sizeof(menu_title), "%s_title", MenuOpened[client]);
	BuildMenuTitle(client, menu, menu_title);

	new size		= GetArraySize(a_MainMenu);
	decl String:pos[64];
	decl String:team[64];
	decl String:command[64];
	decl String:t_rarity[64];
	new xpcost;
	new upgradeslots;
	new unlockcost;
	new headertext;
	new isunlocked;
	new rarity;
	decl String:t_xpcost[64];
	decl String:t_upgradeslots[64];
	decl String:searchkey[64];
	Format(team, sizeof(team), "%d", GetClientTeam(client));

	decl String:vendorName[64];
	Call_StartForward(f_OnConfigParsed);
	Call_PushString(CONFIG_MAINMENU);
	Call_PushCell(a_MainMenu);
	Call_Finish();

	for (new i = 0; i < size; i++) {

		//a_Section[client]	= GetArrayCell(a_MainMenu, i, 0);
		//GetArrayString(a_Section[client], 0, t_Section, sizeof(t_Section));
		a_Keys[client]		= GetArrayCell(a_MainMenu, i, 1);
		a_Values[client]	= GetArrayCell(a_MainMenu, i, 2);

		Format(t_Values, sizeof(t_Values), "%s", GetConfigValue(client, a_Keys[client], a_Values[client], "team?"));
		if (StrContains(t_Values, team, false) == -1 && StringToInt(t_Values) > 0) continue;

		Format(t_Values, sizeof(t_Values), "%s", GetConfigValue(client, a_Keys[client], a_Values[client], "targetname?"));
		if (!StrEqual(t_Values, MenuOpened[client], false)) continue;

		upgradeslots = StringToInt(GetConfigValue(client, a_Keys[client], a_Values[client], "upgrade slots?"));

		if (vendorOpened[client] != -1) {

			Format(vendorName, sizeof(vendorName), "%s", GetConfigValue(client, a_Keys[client], a_Values[client], "vendor name?"));

			if (!StrEqual(GetVendorName(vendorOpened[client]), vendorName, false)) continue;	// because we dont want to show items that arent on THAT vendor.
			if (StringToInt(GetConfigValue(client, a_Keys[client], a_Values[client], "menu option?")) != 1) {

				if (upgradeslots < 1 && StringToInt(GetVendorValue(vendorName, "omit if no slots?")) == 1) continue;

				Format(t_rarity, sizeof(t_rarity), "%s", GetConfigValue(client, a_Keys[client], a_Values[client], "rarity?"));

				if (StrContains(t_rarity, ":", false) == -1 || StringToInt(t_rarity[1]) == -1) continue; // either the item has not rolled or it rolled -1, so it is not available.
				if (StringToInt(t_rarity[1]) < StringToInt(GetVendorValue(vendorName, "min rarity?")) ||
					StringToInt(t_rarity[1]) > StringToInt(GetVendorValue(vendorName, "max rarity?"))) continue; // there's an allowed range and this item doesn't meet it. It's not an unavailable item, just unavailable in this range.
			}
		}

		xpcost = StringToInt(GetConfigValue(client, a_Keys[client], a_Values[client], "xp cost?"));
		Format(command, sizeof(command), "%s", GetConfigValue(client, a_Keys[client], a_Values[client], "command?"));

		Format(pos, sizeof(pos), "%d", i);
		PushArrayString(Handle:RPGMenuPosition[client], pos);

		a_Section[client]	= GetArrayCell(a_MainMenu, i, 0);
		GetArrayString(a_Section[client], 0, t_Section, sizeof(t_Section));

		Format(t_Section, sizeof(t_Section), "%T", t_Section, client);

		headertext = StringToInt(GetConfigValue(client, a_Keys[client], a_Values[client], "header text?"));
		Format(searchkey, sizeof(searchkey), "%s", GetConfigValue(client, a_Keys[client], a_Values[client], "search key?"));

		Format(t_Keys, sizeof(t_Keys), "%s", GetConfigValue(client, a_Keys[client], a_Values[client], "menutext?", true), client);

		if (headertext == 1) Format(t_Section, sizeof(t_Section), "%s %s", t_Section, t_Keys);
		else Format(t_Section, sizeof(t_Section), "%s\n\t%s", t_Section, t_Keys);

		Format(searchkey, sizeof(searchkey), "%d", xpcost);
		Format(t_xpcost, sizeof(t_xpcost), "%s", AddCommasToString(xpcost));
		Format(t_upgradeslots, sizeof(t_upgradeslots), "%d", upgradeslots);
		ReplaceString(t_Section, sizeof(t_Section), "{XP}", t_xpcost);
		ReplaceString(t_Section, sizeof(t_Section), "{US}", t_upgradeslots);


		AddMenuItem(menu, t_Section, t_Section);
	}
	if (!StrEqual(MenuOpened[client], "MainMenu", false)) {

		Format(t_Section, sizeof(t_Section), "%T", "previous page", client);
		AddMenuItem(menu, t_Section, t_Section);
	}

	DisplayMenu(menu, client, 0);
	//ClearArray(a_MainMenu);
}

public BuildMenuHandle(Handle:menu, MenuAction:action, client, slot)
{
	if (action == MenuAction_Select)
	{
		decl String:pos[64];
		decl String:t_Section[512];
		decl String:t_Keys[512];
		decl String:t_Values[512];

		/*

				Why is RPGMenuPosition so great?
				Any requirements for the menu option to EVEN APPEAR have been met.
				We don't have to check again!

				If the user is spending experience or points, though, we'll have to double-check
				in-case the value changed to an insufficient amount in the interim before selecting
				a menu option.
		*/
		
		//		Figuring out which menu to send the player to after selecting the option is the last thing we do.
		if (slot < GetArraySize(RPGMenuPosition[client])) {

			GetArrayString(Handle:RPGMenuPosition[client], slot, pos, sizeof(pos));
			a_Section[client]	= GetArrayCell(a_MainMenu, StringToInt(pos), 0);
			GetArrayString(a_Section[client], 0, t_Section, sizeof(t_Section));
			a_Keys[client]		= GetArrayCell(a_MainMenu, StringToInt(pos), 1);
			a_Values[client]	= GetArrayCell(a_MainMenu, StringToInt(pos), 2);

			PushArrayString(MenuPrevious_h[client], MenuOpened[client]);
			Format(MenuOpened[client], sizeof(MenuOpened[]), "%s", GetConfigValue(client, a_Keys[client], a_Values[client], "target?"));


			if (GetArraySize(MenuPrevious_h[client]) > 0) GetArrayString(MenuPrevious_h[client], GetArraySize(MenuPrevious_h[client]) - 1, pos, sizeof(pos));
			if (StrEqual(pos, MenuOpened[client], false)) ResizeArray(MenuPrevious_h[client], GetArraySize(MenuPrevious_h[client]) - 1);

			//if (GetArraySize(MenuPrevious_h[client]) >= 1) GetArrayString(MenuPrevious_h[client], GetArraySize(MenuPrevious_h[client]) - 1, pos, sizeof(pos));
			//if (GetArraySize(MenuPrevious_h[client]) < 1 || !StrEqual(pos, MenuOpened[client], false)) PushArrayString(MenuPrevious_h[client], MenuOpened[client]);

			//Format(MenuOpened[client], sizeof(MenuOpened[]), "%s", GetConfigValue(client, a_Keys[client], a_Values[client], "target?"));
		}
		else {

			/*

					Previous page buttons are automatically added.


			*/
			GetArrayString(Handle:MenuPrevious_h[client], GetArraySize(MenuPrevious_h[client]) - 1, pos, sizeof(pos));
			ResizeArray(MenuPrevious_h[client], GetArraySize(MenuPrevious_h[client]) - 1);
			Format(MenuOpened[client], sizeof(MenuOpened[]), "%s", pos);
		}
		/*

				It's essential that when a purchase is made, the user be returned to that specific menu!
				But that's up to server operators to make sure they've properly set it up. If they haven't, that's on them, not me!
		*/
		//ClearArray(a_MainMenu);
		BuildMenu(client);//*/
	}
	else if (action == MenuAction_End)
	{
		CloseHandle(menu);
	}
}