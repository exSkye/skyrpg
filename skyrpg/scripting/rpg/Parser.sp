public Action Timer_ExecuteConfig(Handle timer) {
	if (ReadyUp_NtvConfigProcessing() == 0) {
		// These are processed one-by-one in a defined-by-dependencies order, but you can place them here in any order you want.
		// I've placed them here in the order they load for uniformality.
		ReadyUp_ParseConfig(CONFIG_MAIN);
		ReadyUp_ParseConfig(CONFIG_EVENTS);
		ReadyUp_ParseConfig(CONFIG_SURVIVORTALENTS);
		SetTalentConfigs();
		for (int i = 0; i < GetArraySize(TalentMenuConfigs); i++) {
			char configname[64];
			GetArrayString(TalentMenuConfigs, i, configname, 64);
			ReadyUp_ParseConfig(configname);
		}
		ReadyUp_ParseConfig(CONFIG_POINTS);
		ReadyUp_ParseConfig(CONFIG_STORE);
		ReadyUp_ParseConfig(CONFIG_TRAILS);
		ReadyUp_ParseConfig(CONFIG_MAINMENU);
		ReadyUp_ParseConfig(CONFIG_WEAPONS);
		ReadyUp_ParseConfig(CONFIG_COMMONAFFIXES);
		ReadyUp_ParseConfig(CONFIG_HANDICAP);
		//ReadyUp_ParseConfig(CONFIG_CLASSNAMES);
		return Plugin_Stop;
	}
	return Plugin_Continue;
}

public ReadyUp_LoadFromConfigEx(Handle key, Handle value, Handle section, char[] configname, keyCount) {
	//PrintToChatAll("Size: %d config: %s", GetArraySize(Handle:key), configname);
	if (!StrEqual(configname, CONFIG_MAIN) &&
		!StrEqual(configname, CONFIG_EVENTS) &&
		!StrEqual(configname, CONFIG_SURVIVORTALENTS) &&
		!IsTalentConfig(configname) &&
		!StrEqual(configname, CONFIG_MAINMENU) &&
		!StrEqual(configname, CONFIG_POINTS) &&
		!StrEqual(configname, CONFIG_STORE) &&
		!StrEqual(configname, CONFIG_TRAILS) &&
		!StrEqual(configname, CONFIG_WEAPONS) &&
		!StrEqual(configname, CONFIG_COMMONAFFIXES) &&
		!StrEqual(configname, CONFIG_HANDICAP)) return;// &&
		//!StrEqual(configname, CONFIG_CLASSNAMES)) return;
	bool configIsForTalents = (IsTalentConfig(configname) || StrEqual(configname, CONFIG_SURVIVORTALENTS));
	char s_key[64];
	char s_value[64];
	char s_section[64];
	if (StrEqual(configname, CONFIG_MAIN)) {
		int a_Size						= GetArraySize(key);
		for (int i = 0; i < a_Size; i++) {
			GetArrayString(key, i, s_key, sizeof(s_key));
			GetArrayString(value, i, s_value, sizeof(s_value));
			PushArrayString(MainKeys, s_key);
			PushArrayString(MainValues, s_value);
			if (!StrEqual(s_key, "rpg mode?")) continue;
			CurrentRPGMode = StringToInt(s_value);
		}
		RegisterConsoleCommands();
		return;
	}
	if (configIsForTalents) TalentKeys		=					CreateArray(16);
	else					TalentKeys		=					CreateArray(16);
	if (configIsForTalents) TalentValues	=					CreateArray(16);
	else					TalentValues	=					CreateArray(16);
	if (configIsForTalents) TalentSections	=					CreateArray(16);
	else 					TalentSections	=					CreateArray(16);
	if (keyCount > 0) {
		if (configIsForTalents) ResizeArray(a_Menu_Talents, keyCount);
		else if (StrEqual(configname, CONFIG_MAINMENU)) ResizeArray(a_Menu_Main, keyCount);
		else if (StrEqual(configname, CONFIG_EVENTS)) ResizeArray(a_Events, keyCount);
		else if (StrEqual(configname, CONFIG_POINTS)) ResizeArray(a_Points, keyCount);
		else if (StrEqual(configname, CONFIG_STORE)) ResizeArray(a_Store, keyCount);
		else if (StrEqual(configname, CONFIG_TRAILS)) ResizeArray(a_Trails, keyCount);
		else if (StrEqual(configname, CONFIG_WEAPONS)) ResizeArray(a_WeaponDamages, keyCount);
		else if (StrEqual(configname, CONFIG_COMMONAFFIXES)) ResizeArray(a_CommonAffixes, keyCount);
		else if (StrEqual(configname, CONFIG_HANDICAP)) ResizeArray(a_HandicapLevels, keyCount);
		//else if (StrEqual(configname, CONFIG_CLASSNAMES)) ResizeArray(a_Classnames, keyCount);
	}
	int a_Size						= GetArraySize(key);
	int talentsLoaded = 0;
	bool bFirst = true;
	while (a_Size > 0) {
		GetArrayString(key, 0, s_key, sizeof(s_key));
		GetArrayString(value, 0, s_value, sizeof(s_value));
		if (bFirst) {
			GetArrayString(section, 0, s_section, sizeof(s_section));
			bFirst = false;
		}
		a_Size--;
		RemoveFromArray(key, 0);
		RemoveFromArray(value, 0);
		if (!StrEqual(s_key, "EOM")) {
			PushArrayString(TalentKeys, s_key);
			PushArrayString(TalentValues, s_value);
			RemoveFromArray(section, 0);
			continue;
		}
		RemoveFromArray(section, 0);
		PushArrayString(TalentSections, s_section);

		if (configIsForTalents) SetConfigArrays(configname, a_Menu_Talents, TalentKeys, TalentValues, TalentSections, GetArraySize(a_Menu_Talents));
		else if (StrEqual(configname, CONFIG_MAINMENU)) SetConfigArrays(configname, a_Menu_Main, TalentKeys, TalentValues, TalentSections, GetArraySize(a_Menu_Main));
		else if (StrEqual(configname, CONFIG_EVENTS)) SetConfigArrays(configname, a_Events, TalentKeys, TalentValues, TalentSections, GetArraySize(a_Events));
		else if (StrEqual(configname, CONFIG_POINTS)) SetConfigArrays(configname, a_Points, TalentKeys, TalentValues, TalentSections, GetArraySize(a_Points));
		else if (StrEqual(configname, CONFIG_STORE)) SetConfigArrays(configname, a_Store, TalentKeys, TalentValues, TalentSections, GetArraySize(a_Store));
		else if (StrEqual(configname, CONFIG_TRAILS)) SetConfigArrays(configname, a_Trails, TalentKeys, TalentValues, TalentSections, GetArraySize(a_Trails));
		else if (StrEqual(configname, CONFIG_WEAPONS)) SetConfigArrays(configname, a_WeaponDamages, TalentKeys, TalentValues, TalentSections, GetArraySize(a_WeaponDamages));
		else if (StrEqual(configname, CONFIG_COMMONAFFIXES)) SetConfigArrays(configname, a_CommonAffixes, TalentKeys, TalentValues, TalentSections, GetArraySize(a_CommonAffixes));
		else if (StrEqual(configname, CONFIG_HANDICAP)) SetConfigArrays(configname, a_HandicapLevels, TalentKeys, TalentValues, TalentSections, GetArraySize(a_HandicapLevels));
		//else if (StrEqual(configname, CONFIG_CLASSNAMES)) SetConfigArrays(configname, a_Classnames, TalentKeys, TalentValues, tTalentSection, GetArraySize(a_Classnames));
		if (configIsForTalents) {
			talentsLoaded++;
		}
		ClearArray(TalentKeys);
		ClearArray(TalentValues);
		ClearArray(TalentSections);
		bFirst = true;
	}

	if (StrEqual(configname, CONFIG_POINTS)) {
		if (a_DirectorActions != INVALID_HANDLE) ClearArray(a_DirectorActions);
		a_DirectorActions			=	CreateArray(3);
		if (a_DirectorActions_Cooldown != INVALID_HANDLE) ClearArray(a_DirectorActions_Cooldown);
		a_DirectorActions_Cooldown	=	CreateArray(4);
		int size						=	GetArraySize(a_Points);
		Handle Keys					=	CreateArray(11);
		Handle Values				=	CreateArray(11);
		Handle Section				=	CreateArray(10);
		int sizer						=	0;
		for (int i = 0; i < size; i++) {
			Keys						=	GetArrayCell(a_Points, i, 0);
			Values						=	GetArrayCell(a_Points, i, 1);
			Section						=	GetArrayCell(a_Points, i, 2);
			int size2					=	GetArraySize(Keys);
			for (int ii = 0; ii < size2; ii++) {
				GetArrayString(Keys, ii, s_key, sizeof(s_key));
				GetArrayString(Values, ii, s_value, sizeof(s_value));
				if (StrEqual(s_key, "model?")) PushArrayString(ModelsToPrecache, s_value); //PrecacheModel(s_value, true);
				else if (StrEqual(s_key, "director option?") && StrEqual(s_value, "1")) {
					sizer				=	GetArraySize(a_DirectorActions);
					ResizeArray(a_DirectorActions, sizer + 1);
					SetArrayCell(a_DirectorActions, sizer, Keys, 0);
					SetArrayCell(a_DirectorActions, sizer, Values, 1);
					SetArrayCell(a_DirectorActions, sizer, Section, 2);
					ResizeArray(a_DirectorActions_Cooldown, sizer + 1);
					SetArrayString(a_DirectorActions_Cooldown, sizer, "0");						// 0 means not on cooldown. 1 means on cooldown. This resets every map.
				}
			}
		}
	}
	if (StrEqual(configname, CONFIG_EVENTS)) SubmitEventHooks(1);
	ReadyUp_NtvGetHeader();
	/*

		We need to preload an array full of all the positions of item drops.
		Faster than searching every time.
	*/
	if (StrEqual(configname, CONFIG_COMMONAFFIXES) && GetArraySize(ModelsToPrecache) > 0) {
		CreateTimer(10.0, Timer_PrecacheReset, _, TIMER_FLAG_NO_MAPCHANGE);
	}
}

stock SetConfigArrays(char[] Config, Handle Main, Handle Keys, Handle Values, Handle Section, int size, bool setConfigArraysDebugger = false) {
	bool configIsForTalents = (IsTalentConfig(Config) || StrEqual(Config, CONFIG_SURVIVORTALENTS));
	char text[64];
	if (configIsForTalents) TalentKey		=					CreateArray(16);
	else					TalentKey		=					CreateArray(16);
	if (configIsForTalents) TalentValue		=					CreateArray(16);
	else					TalentValue		=					CreateArray(16);
	if (configIsForTalents) TalentSection 	= 					CreateArray(16);
	else					TalentSection 	= 					CreateArray(16);
	// if (configIsForTalents) {
	// 	TalentTriggers	= CreateArray(8);
	// }

	char key[64];
	char value[64];
	int a_Size = GetArraySize(Keys);
	//setConfigArraysDebugger = true;
	for (int i = 0; i < a_Size; i++) {
		GetArrayString(Keys, i, key, sizeof(key));
		GetArrayString(Values, i, value, sizeof(value));
		PushArrayString(TalentKey, key);
		PushArrayString(TalentValue, value);
	}
	int pos = 0;
	int sortSize = 0;
	// Sort the keys/values for TALENTS ONLY /w.
	if (configIsForTalents) {
		if (FindStringInArray(TalentKey, "ability trigger?") == -1) {
			PushArrayString(TalentKey, "ability trigger?");
			PushArrayString(TalentValue, "-1");
		}
		if (FindStringInArray(TalentKey, "active ability trigger?") == -1) {
			PushArrayString(TalentKey, "active ability trigger?");
			PushArrayString(TalentValue, "-1");
		}
		if (FindStringInArray(TalentKey, "active effect interval?") == -1) {
			PushArrayString(TalentKey, "active effect interval?");
			PushArrayString(TalentValue, "-1.0");
		}
		if (FindStringInArray(TalentKey, "multiply limit?") == -1) {
			PushArrayString(TalentKey, "multiply limit?");
			PushArrayString(TalentValue, "-1");
		}
		if (FindStringInArray(TalentKey, "require same hitbox?") == -1) {
			PushArrayString(TalentKey, "require same hitbox?");
			PushArrayString(TalentValue, "-1");
		}
		if (FindStringInArray(TalentKey, "weapon name required?") == -1) {
			PushArrayString(TalentKey, "weapon name required?");
			PushArrayString(TalentValue, "-1");
		}
		if (FindStringInArray(TalentKey, "time since last activator attack?") == -1) {
			PushArrayString(TalentKey, "time since last activator attack?");
			PushArrayString(TalentValue, "-1.0");
		}
		if (FindStringInArray(TalentKey, "target must be in ammo?") == -1) {
			PushArrayString(TalentKey, "target must be in ammo?");
			PushArrayString(TalentValue, "-1");
		}
		if (FindStringInArray(TalentKey, "activator must be in ammo?") == -1) {
			PushArrayString(TalentKey, "activator must be in ammo?");
			PushArrayString(TalentValue, "-1");
		}
		if (FindStringInArray(TalentKey, "target status effect required?") == -1) {
			PushArrayString(TalentKey, "target status effect required?");
			PushArrayString(TalentValue, "-1");
		}
		if (FindStringInArray(TalentKey, "ability category?") == -1) {
			PushArrayString(TalentKey, "ability category?");
			PushArrayString(TalentValue, "-1");
		}
		if (FindStringInArray(TalentKey, "talent cooldown minimum value?") == -1) {
			PushArrayString(TalentKey, "talent cooldown minimum value?");
			PushArrayString(TalentValue, "0.0");
		}
		if (FindStringInArray(TalentKey, "require ally on fire?") == -1) {
			PushArrayString(TalentKey, "require ally on fire?");
			PushArrayString(TalentValue, "-1");
		}
		if (FindStringInArray(TalentKey, "enemy in coherency is target?") == -1) {
			PushArrayString(TalentKey, "enemy in coherency is target?");
			PushArrayString(TalentValue, "-1");
		}
		if (FindStringInArray(TalentKey, "require enemy in coherency range?") == -1) {
			PushArrayString(TalentKey, "require enemy in coherency range?");
			PushArrayString(TalentValue, "-1");
		}
		if (FindStringInArray(TalentKey, "target must be ally ensnarer?") == -1) {
			PushArrayString(TalentKey, "target must be ally ensnarer?");
			PushArrayString(TalentValue, "-1");
		}
		if (FindStringInArray(TalentKey, "require ensnared ally?") == -1) {
			PushArrayString(TalentKey, "require ensnared ally?");
			PushArrayString(TalentValue, "-1");
		}
		if (FindStringInArray(TalentKey, "require ally below health percentage?") == -1) {
			PushArrayString(TalentKey, "require ally below health percentage?");
			PushArrayString(TalentValue, "-1.0");
		}
		if (FindStringInArray(TalentKey, "require ally with adrenaline?") == -1) {
			PushArrayString(TalentKey, "require ally with adrenaline?");
			PushArrayString(TalentValue, "-1");
		}
		if (FindStringInArray(TalentKey, "skip talent for augment roll?") == -1) {
			PushArrayString(TalentKey, "skip talent for augment roll?");
			PushArrayString(TalentValue, "-1");
		}
		if (FindStringInArray(TalentKey, "must be unhurt by si or witch?") == -1) {
			PushArrayString(TalentKey, "must be unhurt by si or witch?");
			PushArrayString(TalentValue, "-1");
		}
		if (FindStringInArray(TalentKey, "must be within coherency of talent?") == -1) {
			PushArrayString(TalentKey, "must be within coherency of talent?");
			PushArrayString(TalentValue, "-1");
		}
		if (FindStringInArray(TalentKey, "target ability trigger to call?") == -1) {
			PushArrayString(TalentKey, "target ability trigger to call?");
			PushArrayString(TalentValue, "-1");
		}
		if (FindStringInArray(TalentKey, "no augment modifiers?") == -1) {
			PushArrayString(TalentKey, "no augment modifiers?");
			PushArrayString(TalentValue, "-1");
		}
		if (FindStringInArray(TalentKey, "multiply strength ensnared allies?") == -1) {
			PushArrayString(TalentKey, "multiply strength ensnared allies?");
			PushArrayString(TalentValue, "-1.0");
		}
		if (FindStringInArray(TalentKey, "multiply strength downed allies?") == -1) {
			PushArrayString(TalentKey, "multiply strength downed allies?");
			PushArrayString(TalentValue, "-1.0");
		}
		if (FindStringInArray(TalentKey, "health cost on activation?") == -1) {
			PushArrayString(TalentKey, "health cost on activation?");
			PushArrayString(TalentValue, "-1.0");
		}
		if (FindStringInArray(TalentKey, "health percentage remaining required?") == -1) {
			PushArrayString(TalentKey, "health percentage remaining required?");
			PushArrayString(TalentValue, "-1.0");
		}
		if (FindStringInArray(TalentKey, "activator status effect required?") == -1) {
			PushArrayString(TalentKey, "activator status effect required?");
			PushArrayString(TalentValue, "-1");
		}
		if (FindStringInArray(TalentKey, "active effect allows all classes?") == -1) {
			PushArrayString(TalentKey, "active effect allows all classes?");
			PushArrayString(TalentValue, "-1");
		}
		if (FindStringInArray(TalentKey, "active effect allows all hitgroups?") == -1) {
			PushArrayString(TalentKey, "active effect allows all hitgroups?");
			PushArrayString(TalentValue, "-1");
		}
		if (FindStringInArray(TalentKey, "active effect allows all weapons?") == -1) {
			PushArrayString(TalentKey, "active effect allows all weapons?");
			PushArrayString(TalentValue, "-1");
		}
		if (FindStringInArray(TalentKey, "mult str div same headshots?") == -1) {
			PushArrayString(TalentKey, "mult str div same headshots?");
			PushArrayString(TalentValue, "-1");
		}
		if (FindStringInArray(TalentKey, "mult str max same headshots?") == -1) {
			PushArrayString(TalentKey, "mult str max same headshots?");
			PushArrayString(TalentValue, "-1");
		}
		if (FindStringInArray(TalentKey, "mult str by same headshots?") == -1) {
			PushArrayString(TalentKey, "mult str by same headshots?");
			PushArrayString(TalentValue, "-1");
		}
		if (FindStringInArray(TalentKey, "require consecutive headshots?") == -1) {
			PushArrayString(TalentKey, "require consecutive headshots?");
			PushArrayString(TalentValue, "-1");
		}
		if (FindStringInArray(TalentKey, "weapon slot required?") == -1) {
			PushArrayString(TalentKey, "weapon slot required?");
			PushArrayString(TalentValue, "-1");
		}
		if (FindStringInArray(TalentKey, "activator ability trigger to call?") == -1) {
			PushArrayString(TalentKey, "activator ability trigger to call?");
			PushArrayString(TalentValue, "-1");
		}
		if (FindStringInArray(TalentKey, "hide talent strength display?") == -1) {
			PushArrayString(TalentKey, "hide talent strength display?");
			PushArrayString(TalentValue, "-1.0");
		}
		if (FindStringInArray(TalentKey, "give player this item on trigger?") == -1) {
			PushArrayString(TalentKey, "give player this item on trigger?");
			PushArrayString(TalentValue, "-1");
		}
		if (FindStringInArray(TalentKey, "contribution cost required?") == -1) {
			PushArrayString(TalentKey, "contribution cost required?");
			PushArrayString(TalentValue, "-1");
		}
		if (FindStringInArray(TalentKey, "contribution category required?") == -1) {
			PushArrayString(TalentKey, "contribution category required?");
			PushArrayString(TalentValue, "-1");
		}
		if (FindStringInArray(TalentKey, "mult str div same hits?") == -1) {
			PushArrayString(TalentKey, "mult str div same hits?");
			PushArrayString(TalentValue, "-1");
		}
		if (FindStringInArray(TalentKey, "mult str max same hits?") == -1) {
			PushArrayString(TalentKey, "mult str max same hits?");
			PushArrayString(TalentValue, "-1");
		}
		if (FindStringInArray(TalentKey, "mult str by same hits?") == -1) {
			PushArrayString(TalentKey, "mult str by same hits?");
			PushArrayString(TalentValue, "-1");
		}
		if (FindStringInArray(TalentKey, "last hit must be headshot?") == -1) {
			PushArrayString(TalentKey, "last hit must be headshot?");
			PushArrayString(TalentValue, "-1");
		}
		if (FindStringInArray(TalentKey, "event type?") == -1) {
			PushArrayString(TalentKey, "event type?");
			PushArrayString(TalentValue, "-1");
		}
		if (FindStringInArray(TalentKey, "activator neither high or low ground?") == -1) {
			PushArrayString(TalentKey, "activator neither high or low ground?");
			PushArrayString(TalentValue, "-1");
		}
		if (FindStringInArray(TalentKey, "target high ground?") == -1) {
			PushArrayString(TalentKey, "target high ground?");
			PushArrayString(TalentValue, "-1");
		}
		if (FindStringInArray(TalentKey, "activator high ground?") == -1) {
			PushArrayString(TalentKey, "activator high ground?");
			PushArrayString(TalentValue, "-1");
		}
		if (FindStringInArray(TalentKey, "target must be last target?") == -1) {
			PushArrayString(TalentKey, "target must be last target?");
			PushArrayString(TalentValue, "-1");
		}
		if (FindStringInArray(TalentKey, "target must be outside range required?") == -1) {
			PushArrayString(TalentKey, "target must be outside range required?");
			PushArrayString(TalentValue, "-1");
		}
		if (FindStringInArray(TalentKey, "target range required?") == -1) {
			PushArrayString(TalentKey, "target range required?");
			PushArrayString(TalentValue, "-1.0");
		}
		if (FindStringInArray(TalentKey, "target class must be last target class?") == -1) {
			PushArrayString(TalentKey, "target class must be last target class?");
			PushArrayString(TalentValue, "-1");
		}
		if (FindStringInArray(TalentKey, "toggle strength?") == -1) {
			PushArrayString(TalentKey, "toggle strength?");
			PushArrayString(TalentValue, "-1.0");
		}
		if (FindStringInArray(TalentKey, "special ammo?") == -1) {
			PushArrayString(TalentKey, "special ammo?");
			PushArrayString(TalentValue, "-1");
		}
		if (FindStringInArray(TalentKey, "does damage?") == -1) {
			PushArrayString(TalentKey, "does damage?");
			PushArrayString(TalentValue, "-1");
		}
		if (FindStringInArray(TalentKey, "cooldown end ability trigger?") == -1) {
			PushArrayString(TalentKey, "cooldown end ability trigger?");
			PushArrayString(TalentValue, "-1");
		}
		if (FindStringInArray(TalentKey, "active end ability trigger?") == -1) {
			PushArrayString(TalentKey, "active end ability trigger?");
			PushArrayString(TalentValue, "-1");
		}
		if (FindStringInArray(TalentKey, "secondary ept only?") == -1) {
			PushArrayString(TalentKey, "secondary ept only?");
			PushArrayString(TalentValue, "-1");
		}
		if (FindStringInArray(TalentKey, "activate effect per tick?") == -1) {
			PushArrayString(TalentKey, "activate effect per tick?");
			PushArrayString(TalentValue, "-1");
		}
		if (FindStringInArray(TalentKey, "cooldown?") == -1) {
			PushArrayString(TalentKey, "cooldown?");
			PushArrayString(TalentValue, "-1.0");
		}
		if (FindStringInArray(TalentKey, "toggle effect?") == -1) {
			PushArrayString(TalentKey, "toggle effect?");
			PushArrayString(TalentValue, "-1");
		}
		if (FindStringInArray(TalentKey, "cannot be ensnared?") == -1) {
			PushArrayString(TalentKey, "cannot be ensnared?");
			PushArrayString(TalentValue, "-1");
		}
		if (FindStringInArray(TalentKey, "active time?") == -1) {
			PushArrayString(TalentKey, "active time?");
			PushArrayString(TalentValue, "-1.0");
		}
		if (FindStringInArray(TalentKey, "reactive type?") == -1) {
			PushArrayString(TalentKey, "reactive type?");
			PushArrayString(TalentValue, "-1");
		}
		if (FindStringInArray(TalentKey, "inactive trigger?") == -1) {
			PushArrayString(TalentKey, "inactive trigger?");
			PushArrayString(TalentValue, "-1");
		}
		if (FindStringInArray(TalentKey, "cooldown trigger?") == -1) {
			PushArrayString(TalentKey, "cooldown trigger?");
			PushArrayString(TalentValue, "-1");
		}
		if (FindStringInArray(TalentKey, "is aura instead?") == -1) {
			PushArrayString(TalentKey, "is aura instead?");
			PushArrayString(TalentValue, "-1");
		}
		if (FindStringInArray(TalentKey, "is sub menu?") == -1) {
			PushArrayString(TalentKey, "is sub menu?");
			PushArrayString(TalentValue, "-1");
		}
		if (FindStringInArray(TalentKey, "buff bar text?") == -1) {
			PushArrayString(TalentKey, "buff bar text?");
			PushArrayString(TalentValue, "-1");
		}
		if (FindStringInArray(TalentKey, "diminishing returns?") == -1) {
			PushArrayString(TalentKey, "diminishing returns?");
			PushArrayString(TalentValue, "-1");
		}
		if (FindStringInArray(TalentKey, "diminishing multiplier?") == -1) {
			PushArrayString(TalentKey, "diminishing multiplier?");
			PushArrayString(TalentValue, "-1.0");
		}
		if (FindStringInArray(TalentKey, "base multiplier?") == -1) {
			PushArrayString(TalentKey, "base multiplier?");
			PushArrayString(TalentValue, "-1.0");
		}
		if (FindStringInArray(TalentKey, "use these multipliers?") == -1) {
			PushArrayString(TalentKey, "use these multipliers?");
			PushArrayString(TalentValue, "-1");
		}
		if (FindStringInArray(TalentKey, "attribute?") == -1) {
			PushArrayString(TalentKey, "attribute?");
			PushArrayString(TalentValue, "-1");
		}
		if (FindStringInArray(TalentKey, "passive draw delay?") == -1) {
			PushArrayString(TalentKey, "passive draw delay?");
			PushArrayString(TalentValue, "-1.0");
		}
		if (FindStringInArray(TalentKey, "draw effect delay?") == -1) {
			PushArrayString(TalentKey, "draw effect delay?");
			PushArrayString(TalentValue, "-1.0");
		}
		if (FindStringInArray(TalentKey, "draw delay?") == -1) {
			PushArrayString(TalentKey, "draw delay?");
			PushArrayString(TalentValue, "-1.0");
		}
		if (FindStringInArray(TalentKey, "is single target?") == -1) {
			PushArrayString(TalentKey, "is single target?");
			PushArrayString(TalentValue, "-1");
		}
		if (FindStringInArray(TalentKey, "passive only?") == -1) {
			PushArrayString(TalentKey, "passive only?");
			PushArrayString(TalentValue, "-1");
		}
		if (FindStringInArray(TalentKey, "passive strength?") == -1) {
			PushArrayString(TalentKey, "passive strength?");
			PushArrayString(TalentValue, "-1.0");
		}
		if (FindStringInArray(TalentKey, "passive requires ensnare?") == -1) {
			PushArrayString(TalentKey, "passive requires ensnare?");
			PushArrayString(TalentValue, "-1");
		}
		if (FindStringInArray(TalentKey, "passive ignores cooldown?") == -1) {
			PushArrayString(TalentKey, "passive ignores cooldown?");
			PushArrayString(TalentValue, "-1");
		}
		if (FindStringInArray(TalentKey, "active strength?") == -1) {
			PushArrayString(TalentKey, "active strength?");
			PushArrayString(TalentValue, "-1.0");
		}
		if (FindStringInArray(TalentKey, "active requires ensnare?") == -1) {
			PushArrayString(TalentKey, "active requires ensnare?");
			PushArrayString(TalentValue, "-1");
		}
		if (FindStringInArray(TalentKey, "maximum active multiplier?") == -1) {
			PushArrayString(TalentKey, "maximum active multiplier?");
			PushArrayString(TalentValue, "-1.0");
		}
		if (FindStringInArray(TalentKey, "maximum passive multiplier?") == -1) {
			PushArrayString(TalentKey, "maximum passive multiplier?");
			PushArrayString(TalentValue, "-1.0");
		}
		if (FindStringInArray(TalentKey, "cooldown strength?") == -1) {
			PushArrayString(TalentKey, "cooldown strength?");
			PushArrayString(TalentValue, "-1.0");
		}
		if (FindStringInArray(TalentKey, "teams allowed?") == -1) {
			PushArrayString(TalentKey, "teams allowed?");
			PushArrayString(TalentValue, "-1");
		}
		if (FindStringInArray(TalentKey, "reactive ability?") == -1) {
			PushArrayString(TalentKey, "reactive ability?");
			PushArrayString(TalentValue, "-1");
		}
		if (FindStringInArray(TalentKey, "cooldown effect?") == -1) {
			PushArrayString(TalentKey, "cooldown effect?");
			PushArrayString(TalentValue, "-1");
		}
		if (FindStringInArray(TalentKey, "passive effect?") == -1) {
			PushArrayString(TalentKey, "passive effect?");
			PushArrayString(TalentValue, "-1");
		}
		if (FindStringInArray(TalentKey, "active effect?") == -1) {
			PushArrayString(TalentKey, "active effect?");
			PushArrayString(TalentValue, "-1");
		}
		if (FindStringInArray(TalentKey, "effect multiplier?") == -1) {
			PushArrayString(TalentKey, "effect multiplier?");
			PushArrayString(TalentValue, "-1.0");
		}
		if (FindStringInArray(TalentKey, "ammo effect?") == -1) {
			PushArrayString(TalentKey, "ammo effect?");
			PushArrayString(TalentValue, "-1");
		}
		if (FindStringInArray(TalentKey, "interval per point?") == -1) {
			PushArrayString(TalentKey, "interval per point?");
			PushArrayString(TalentValue, "-1.0");
		}
		if (FindStringInArray(TalentKey, "interval first point?") == -1) {
			PushArrayString(TalentKey, "interval first point?");
			PushArrayString(TalentValue, "-1.0");
		}
		if (FindStringInArray(TalentKey, "range per point?") == -1) {
			PushArrayString(TalentKey, "range per point?");
			PushArrayString(TalentValue, "-1.0");
		}
		if (FindStringInArray(TalentKey, "range first point value?") == -1) {
			PushArrayString(TalentKey, "range first point value?");
			PushArrayString(TalentValue, "-1.0");
		}
		if (FindStringInArray(TalentKey, "stamina per point?") == -1) {
			PushArrayString(TalentKey, "stamina per point?");
			PushArrayString(TalentValue, "-1");
		}
		if (FindStringInArray(TalentKey, "base stamina required?") == -1) {
			PushArrayString(TalentKey, "base stamina required?");
			PushArrayString(TalentValue, "-1");
		}
		if (FindStringInArray(TalentKey, "cooldown per point?") == -1) {
			PushArrayString(TalentKey, "cooldown per point?");
			PushArrayString(TalentValue, "-1");
		}
		if (FindStringInArray(TalentKey, "cooldown first point?") == -1) {
			PushArrayString(TalentKey, "cooldown first point?");
			PushArrayString(TalentValue, "-1");
		}
		if (FindStringInArray(TalentKey, "cooldown start?") == -1) {
			PushArrayString(TalentKey, "cooldown start?");
			PushArrayString(TalentValue, "-1");
		}
		if (FindStringInArray(TalentKey, "active time per point?") == -1) {
			PushArrayString(TalentKey, "active time per point?");
			PushArrayString(TalentValue, "-1");
		}
		if (FindStringInArray(TalentKey, "active time first point?") == -1) {
			PushArrayString(TalentKey, "active time first point?");
			PushArrayString(TalentValue, "-1");
		}
		if (FindStringInArray(TalentKey, "roll chance?") == -1) {
			PushArrayString(TalentKey, "roll chance?");
			PushArrayString(TalentValue, "-1");
		}
		if (FindStringInArray(TalentKey, "hide translation?") == -1) {
			PushArrayString(TalentKey, "hide translation?");
			PushArrayString(TalentValue, "-1");
		}
		if (FindStringInArray(TalentKey, "is attribute?") == -1) {
			PushArrayString(TalentKey, "is attribute?");
			PushArrayString(TalentValue, "-1");
		}
		if (FindStringInArray(TalentKey, "ignore for layer count?") == -1) {
			PushArrayString(TalentKey, "ignore for layer count?");
			PushArrayString(TalentValue, "-1");
		}
		if (FindStringInArray(TalentKey, "effect strength?") == -1) {
			PushArrayString(TalentKey, "effect strength?");
			PushArrayString(TalentValue, "-1.0");
		}
		if (FindStringInArray(TalentKey, "is effect over time?") == -1) {
			PushArrayString(TalentKey, "is effect over time?");
			PushArrayString(TalentValue, "-1");
		}
		if (FindStringInArray(TalentKey, "talent hard limit?") == -1) {
			PushArrayString(TalentKey, "talent hard limit?");
			PushArrayString(TalentValue, "-1.0");
		}
		if (FindStringInArray(TalentKey, "governs cooldown of talent named?") == -1) {
			PushArrayString(TalentKey, "governs cooldown of talent named?");
			PushArrayString(TalentValue, "-1");
		}
		if (FindStringInArray(TalentKey, "talent active time strength value?") == -1) {
			PushArrayString(TalentKey, "talent active time strength value?");
			PushArrayString(TalentValue, "-1.0");
		}
		if (FindStringInArray(TalentKey, "talent cooldown strength value?") == -1) {
			PushArrayString(TalentKey, "talent cooldown strength value?");
			PushArrayString(TalentValue, "-1.0");
		}
		if (FindStringInArray(TalentKey, "talent upgrade strength value?") == -1) {
			PushArrayString(TalentKey, "talent upgrade strength value?");
			PushArrayString(TalentValue, "-1.0");
		}
		if (FindStringInArray(TalentKey, "required talents required?") == -1) {
			PushArrayString(TalentKey, "required talents required?");
			PushArrayString(TalentValue, "-1");
		}
		if (FindStringInArray(TalentKey, "action bar name?") == -1) {
			PushArrayString(TalentKey, "action bar name?");
			PushArrayString(TalentValue, "-1");
		}
		if (FindStringInArray(TalentKey, "is ability?") == -1) {
			PushArrayString(TalentKey, "is ability?");
			PushArrayString(TalentValue, "-1");
		}
		if (FindStringInArray(TalentKey, "layer?") == -1) {
			PushArrayString(TalentKey, "layer?");
			PushArrayString(TalentValue, "-1");
		}
		if (FindStringInArray(TalentKey, "part of menu named?") == -1) {
			PushArrayString(TalentKey, "part of menu named?");
			PushArrayString(TalentValue, "-1");
		}
		if (FindStringInArray(TalentKey, "talent tree category?") == -1) {
			PushArrayString(TalentKey, "talent tree category?");
			PushArrayString(TalentValue, "-1");
		}
		if (FindStringInArray(TalentKey, "governing attribute?") == -1) {
			PushArrayString(TalentKey, "governing attribute?");
			PushArrayString(TalentValue, "-1");
		}
		if (FindStringInArray(TalentKey, "translation?") == -1) {
			PushArrayString(TalentKey, "translation?");
			PushArrayString(TalentValue, "-1");
		}
		if (FindStringInArray(TalentKey, "talent name?") == -1) {
			PushArrayString(TalentKey, "talent name?");
			PushArrayString(TalentValue, "-1");
		}
		if (FindStringInArray(TalentKey, "secondary aoe?") == -1) {
			PushArrayString(TalentKey, "secondary aoe?");
			PushArrayString(TalentValue, "-1.0");
		}
		if (FindStringInArray(TalentKey, "primary aoe?") == -1) {
			PushArrayString(TalentKey, "primary aoe?");
			PushArrayString(TalentValue, "-1.0");
		}
		if (FindStringInArray(TalentKey, "target is self?") == -1) {
			PushArrayString(TalentKey, "target is self?");
			PushArrayString(TalentValue, "-1");
		}
		if (FindStringInArray(TalentKey, "secondary ability trigger?") == -1) {
			PushArrayString(TalentKey, "secondary ability trigger?");
			PushArrayString(TalentValue, "-1");
		}
		if (FindStringInArray(TalentKey, "health percentage required missing max?") == -1) {
			PushArrayString(TalentKey, "health percentage required missing max?");
			PushArrayString(TalentValue, "-1.0");
		}
		if (FindStringInArray(TalentKey, "health percentage required missing?") == -1) {
			PushArrayString(TalentKey, "health percentage required missing?");
			PushArrayString(TalentValue, "-1.0");
		}
		if (FindStringInArray(TalentKey, "no effect if damage time is not met?") == -1) {
			PushArrayString(TalentKey, "no effect if damage time is not met?");
			PushArrayString(TalentValue, "-1.0");
		}
		if (FindStringInArray(TalentKey, "strength increase while holding fire?") == -1) {
			PushArrayString(TalentKey, "strength increase while holding fire?");
			PushArrayString(TalentValue, "-1.0");
		}
		if (FindStringInArray(TalentKey, "no effect if zoom time is not met?") == -1) {
			PushArrayString(TalentKey, "no effect if zoom time is not met?");
			PushArrayString(TalentValue, "-1");
		}
		if (FindStringInArray(TalentKey, "strength increase time required?") == -1) {
			PushArrayString(TalentKey, "strength increase time required?");
			PushArrayString(TalentValue, "-1.0");
		}
		if (FindStringInArray(TalentKey, "strength increase time cap?") == -1) {
			PushArrayString(TalentKey, "strength increase time cap?");
			PushArrayString(TalentValue, "-1.0");
		}
		if (FindStringInArray(TalentKey, "strength increase while zoomed?") == -1) {
			PushArrayString(TalentKey, "strength increase while zoomed?");
			PushArrayString(TalentValue, "-1.0");
		}
		if (FindStringInArray(TalentKey, "multiply type?") == -1) {
			PushArrayString(TalentKey, "multiply type?");
			PushArrayString(TalentValue, "-1");
		}
		if (FindStringInArray(TalentKey, "multiply range?") == -1) {
			PushArrayString(TalentKey, "multiply range?");
			PushArrayString(TalentValue, "-1.0");
		}
		if (FindStringInArray(TalentKey, "status effect multiplier?") == -1) {
			PushArrayString(TalentKey, "status effect multiplier?");
			PushArrayString(TalentValue, "-1");
		}
		if (FindStringInArray(TalentKey, "background talent?") == -1) {
			PushArrayString(TalentKey, "background talent?");
			PushArrayString(TalentValue, "-1");
		}
		if (FindStringInArray(TalentKey, "require consecutive hits?") == -1) {
			PushArrayString(TalentKey, "require consecutive hits?");
			PushArrayString(TalentValue, "-1");
		}
		if (FindStringInArray(TalentKey, "target class required?") == -1) {
			PushArrayString(TalentKey, "target class required?");
			PushArrayString(TalentValue, "-1");
		}
		if (FindStringInArray(TalentKey, "cannot target self?") == -1) {
			PushArrayString(TalentKey, "cannot target self?");
			PushArrayString(TalentValue, "-1");
		}
		if (FindStringInArray(TalentKey, "target stagger required?") == -1) {
			PushArrayString(TalentKey, "target stagger required?");
			PushArrayString(TalentValue, "-1");
		}
		if (FindStringInArray(TalentKey, "activator stagger required?") == -1) {
			PushArrayString(TalentKey, "activator stagger required?");
			PushArrayString(TalentValue, "-1");
		}
		if (FindStringInArray(TalentKey, "requires limbshot?") == -1) {
			PushArrayString(TalentKey, "requires limbshot?");
			PushArrayString(TalentValue, "-1");
		}
		if (FindStringInArray(TalentKey, "requires headshot?") == -1) {
			PushArrayString(TalentKey, "requires headshot?");
			PushArrayString(TalentValue, "-1");
		}
		if (FindStringInArray(TalentKey, "passive ability?") == -1) {
			PushArrayString(TalentKey, "passive ability?");
			PushArrayString(TalentValue, "-1");
		}
		if (FindStringInArray(TalentKey, "player state required?") == -1) {
			PushArrayString(TalentKey, "player state required?");
			PushArrayString(TalentValue, "-1");
		}
		if (FindStringInArray(TalentKey, "combat state required?") == -1) {
			PushArrayString(TalentKey, "combat state required?");
			PushArrayString(TalentValue, "-1");
		}
		if (FindStringInArray(TalentKey, "requires zoom?") == -1) {
			PushArrayString(TalentKey, "requires zoom?");
			PushArrayString(TalentValue, "-1");
		}
		if (FindStringInArray(TalentKey, "activator class required?") == -1) {
			PushArrayString(TalentKey, "activator class required?");
			PushArrayString(TalentValue, "-1");
		}
		if (FindStringInArray(TalentKey, "health percentage missing required target?") == -1) {
			PushArrayString(TalentKey, "health percentage missing required target?");
			PushArrayString(TalentValue, "-1.0");
		}
		if (FindStringInArray(TalentKey, "health percentage remaining required target?") == -1) {
			PushArrayString(TalentKey, "health percentage remaining required target?");
			PushArrayString(TalentValue, "-1.0");
		}
		if (FindStringInArray(TalentKey, "coherency required?") == -1) {
			PushArrayString(TalentKey, "coherency required?");
			PushArrayString(TalentValue, "-1");
		}
		if (FindStringInArray(TalentKey, "coherency max?") == -1) {
			PushArrayString(TalentKey, "coherency max?");
			PushArrayString(TalentValue, "-1");
		}
		if (FindStringInArray(TalentKey, "coherency range?") == -1) {
			PushArrayString(TalentKey, "coherency range?");
			PushArrayString(TalentValue, "-1.0");
		}
		if (FindStringInArray(TalentKey, "health percentage required?") == -1) {
			PushArrayString(TalentKey, "health percentage required?");
			PushArrayString(TalentValue, "-1.0");
		}
		if (FindStringInArray(TalentKey, "weapons permitted?") == -1) {
			PushArrayString(TalentKey, "weapons permitted?");
			PushArrayString(TalentValue, "-1");
		}
		if (FindStringInArray(TalentKey, "secondary effects?") == -1) {
			PushArrayString(TalentKey, "secondary effects?");
			PushArrayString(TalentValue, "-1");
		}
		if (FindStringInArray(TalentKey, "target ability effects?") == -1) {
			PushArrayString(TalentKey, "target ability effects?");
			PushArrayString(TalentValue, "-1");
		}
		if (FindStringInArray(TalentKey, "activator ability effects?") == -1) {
			PushArrayString(TalentKey, "activator ability effects?");
			PushArrayString(TalentValue, "-1");
		}
		if (FindStringInArray(TalentKey, "compound with?") == -1) {
			PushArrayString(TalentKey, "compound with?");
			PushArrayString(TalentValue, "-1");
		}
		if (FindStringInArray(TalentKey, "compounding talent?") == -1) {
			PushArrayString(TalentKey, "compounding talent?");
			PushArrayString(TalentValue, "-1");
		}
		if (FindStringInArray(TalentKey, "ability type?") == -1) {
			PushArrayString(TalentKey, "ability type?");
			PushArrayString(TalentValue, "-1");
		}
		sortSize = GetArraySize(TalentKey);
		pos = 0;
		while (pos < sortSize) {
			GetArrayString(TalentKey, pos, text, sizeof(text));
			if (
			pos == 0 && !StrEqual(text, "ability type?") ||
			pos == 1 && !StrEqual(text, "compounding talent?") ||
			pos == 2 && !StrEqual(text, "compound with?") ||
			pos == 3 && !StrEqual(text, "activator ability effects?") ||
			pos == 4 && !StrEqual(text, "target ability effects?") ||
			pos == 5 && !StrEqual(text, "secondary effects?") ||
			pos == 6 && !StrEqual(text, "weapons permitted?") ||
			pos == 7 && !StrEqual(text, "health percentage required?") ||
			pos == 8 && !StrEqual(text, "coherency range?") ||
			pos == 9 && !StrEqual(text, "coherency max?") ||
			pos == 10 && !StrEqual(text, "coherency required?") ||
			pos == 11 && !StrEqual(text, "health percentage remaining required target?") ||
			pos == 12 && !StrEqual(text, "health percentage missing required target?") ||
			pos == 13 && !StrEqual(text, "activator class required?") ||
			pos == 14 && !StrEqual(text, "requires zoom?") ||
			pos == 15 && !StrEqual(text, "combat state required?") ||
			pos == 16 && !StrEqual(text, "player state required?") ||
			pos == 17 && !StrEqual(text, "passive ability?") ||
			pos == 18 && !StrEqual(text, "requires headshot?") ||
			pos == 19 && !StrEqual(text, "requires limbshot?") ||
			pos == 20 && !StrEqual(text, "activator stagger required?") ||
			pos == 21 && !StrEqual(text, "target stagger required?") ||
			pos == 22 && !StrEqual(text, "cannot target self?") ||
			pos == 23 && !StrEqual(text, "target class required?") ||
			pos == 24 && !StrEqual(text, "require consecutive hits?") ||
			pos == 25 && !StrEqual(text, "background talent?") ||
			pos == 26 && !StrEqual(text, "status effect multiplier?") ||
			pos == 27 && !StrEqual(text, "multiply range?") ||
			pos == 28 && !StrEqual(text, "multiply type?") ||
			pos == 29 && !StrEqual(text, "strength increase while zoomed?") ||
			pos == 30 && !StrEqual(text, "strength increase time cap?") ||
			pos == 31 && !StrEqual(text, "strength increase time required?") ||
			pos == 32 && !StrEqual(text, "no effect if zoom time is not met?") ||
			pos == 33 && !StrEqual(text, "strength increase while holding fire?") ||
			pos == 34 && !StrEqual(text, "no effect if damage time is not met?") ||
			pos == 35 && !StrEqual(text, "health percentage required missing?") ||
			pos == 36 && !StrEqual(text, "health percentage required missing max?") ||
			pos == 37 && !StrEqual(text, "secondary ability trigger?") ||
			pos == 38 && !StrEqual(text, "target is self?") ||
			pos == 39 && !StrEqual(text, "primary aoe?") ||
			pos == 40 && !StrEqual(text, "secondary aoe?") ||
			pos == 41 && !StrEqual(text, "talent name?") ||
			pos == 42 && !StrEqual(text, "translation?") ||
			pos == 43 && !StrEqual(text, "governing attribute?") ||
			pos == 44 && !StrEqual(text, "talent tree category?") ||
			pos == 45 && !StrEqual(text, "part of menu named?") ||
			pos == 46 && !StrEqual(text, "layer?") ||
			pos == 47 && !StrEqual(text, "is ability?") ||
			pos == 48 && !StrEqual(text, "action bar name?") ||
			pos == 49 && !StrEqual(text, "required talents required?") ||
			pos == 50 && !StrEqual(text, "talent upgrade strength value?") ||
			pos == 51 && !StrEqual(text, "talent cooldown strength value?") ||
			pos == 52 && !StrEqual(text, "talent active time strength value?") ||
			pos == 53 && !StrEqual(text, "governs cooldown of talent named?") ||
			pos == 54 && !StrEqual(text, "talent hard limit?") ||
			pos == 55 && !StrEqual(text, "is effect over time?") ||
			pos == 56 && !StrEqual(text, "effect strength?") ||
			pos == 57 && !StrEqual(text, "ignore for layer count?") ||
			pos == 58 && !StrEqual(text, "is attribute?") ||
			pos == 59 && !StrEqual(text, "hide translation?") ||
			pos == 60 && !StrEqual(text, "roll chance?")) {
				// ResizeArray(TalentKey, sortSize+1);
				// ResizeArray(TalentValue, sortSize+1);
				PushArrayString(TalentKey, text);
				GetArrayString(TalentValue, pos, text, sizeof(text));
				PushArrayString(TalentValue, text);
				RemoveFromArray(TalentKey, pos);
				RemoveFromArray(TalentValue, pos);
				continue;
			}	// had to split this argument up due to internal compiler error on arguments exceeding 80
			else if (
			pos == 61 && !StrEqual(text, "interval per point?") ||
			pos == 62 && !StrEqual(text, "interval first point?") ||
			pos == 63 && !StrEqual(text, "range per point?") ||
			pos == 64 && !StrEqual(text, "range first point value?") ||
			pos == 65 && !StrEqual(text, "stamina per point?") ||
			pos == 66 && !StrEqual(text, "base stamina required?") ||
			pos == 67 && !StrEqual(text, "cooldown per point?") ||
			pos == 68 && !StrEqual(text, "cooldown first point?") ||
			pos == 69 && !StrEqual(text, "cooldown start?") ||
			pos == 70 && !StrEqual(text, "active time per point?") ||
			pos == 71 && !StrEqual(text, "active time first point?") ||
			pos == 72 && !StrEqual(text, "ammo effect?") ||
			pos == 73 && !StrEqual(text, "effect multiplier?") ||
			pos == 74 && !StrEqual(text, "active effect?") ||
			pos == 75 && !StrEqual(text, "passive effect?") ||
			pos == 76 && !StrEqual(text, "cooldown effect?") ||
			pos == 77 && !StrEqual(text, "reactive ability?") ||
			pos == 78 && !StrEqual(text, "teams allowed?") ||
			pos == 79 && !StrEqual(text, "cooldown strength?") ||
			pos == 80 && !StrEqual(text, "maximum passive multiplier?") ||
			pos == 81 && !StrEqual(text, "maximum active multiplier?") ||
			pos == 82 && !StrEqual(text, "active requires ensnare?") ||
			pos == 83 && !StrEqual(text, "active strength?") ||
			pos == 84 && !StrEqual(text, "passive ignores cooldown?") ||
			pos == 85 && !StrEqual(text, "passive requires ensnare?") ||
			pos == 86 && !StrEqual(text, "passive strength?") ||
			pos == 87 && !StrEqual(text, "passive only?") ||
			pos == 88 && !StrEqual(text, "is single target?") ||
			pos == 89 && !StrEqual(text, "draw delay?") ||
			pos == 90 && !StrEqual(text, "draw effect delay?") ||
			pos == 91 && !StrEqual(text, "passive draw delay?") ||
			pos == 92 && !StrEqual(text, "attribute?") ||
			pos == 93 && !StrEqual(text, "use these multipliers?") ||
			pos == 94 && !StrEqual(text, "base multiplier?") ||
			pos == 95 && !StrEqual(text, "diminishing multiplier?") ||
			pos == 96 && !StrEqual(text, "diminishing returns?") ||
			pos == 97 && !StrEqual(text, "buff bar text?") ||
			pos == 98 && !StrEqual(text, "is sub menu?") ||
			pos == 99 && !StrEqual(text, "is aura instead?") ||
			pos == 100 && !StrEqual(text, "cooldown trigger?") ||
			pos == 101 && !StrEqual(text, "inactive trigger?") ||
			pos == 102 && !StrEqual(text, "reactive type?") ||
			pos == 103 && !StrEqual(text, "active time?") ||
			pos == 104 && !StrEqual(text, "cannot be ensnared?") ||
			pos == 105 && !StrEqual(text, "toggle effect?") ||
			pos == 106 && !StrEqual(text, "cooldown?") ||
			pos == 107 && !StrEqual(text, "activate effect per tick?") ||
			pos == 108 && !StrEqual(text, "secondary ept only?") ||
			pos == 109 && !StrEqual(text, "active end ability trigger?") ||
			pos == 110 && !StrEqual(text, "cooldown end ability trigger?") ||
			pos == 111 && !StrEqual(text, "does damage?") ||
			pos == 112 && !StrEqual(text, "special ammo?")) {
				PushArrayString(TalentKey, text);
				GetArrayString(TalentValue, pos, text, sizeof(text));
				PushArrayString(TalentValue, text);
				RemoveFromArray(TalentKey, pos);
				RemoveFromArray(TalentValue, pos);
				continue;
			}
			else if (
			pos == 113 && !StrEqual(text, "toggle strength?") ||
			pos == 114 && !StrEqual(text, "target class must be last target class?") ||
			pos == 115 && !StrEqual(text, "target range required?") ||
			pos == 116 && !StrEqual(text, "target must be outside range required?") ||
			pos == 117 && !StrEqual(text, "target must be last target?") ||
			pos == 118 && !StrEqual(text, "activator high ground?") ||
			pos == 119 && !StrEqual(text, "target high ground?") ||
			pos == 120 && !StrEqual(text, "activator neither high or low ground?") ||
			pos == 121 && !StrEqual(text, "event type?") ||
			pos == 122 && !StrEqual(text, "last hit must be headshot?") ||
			pos == 123 && !StrEqual(text, "mult str by same hits?") ||
			pos == 124 && !StrEqual(text, "mult str max same hits?") ||
			pos == 125 && !StrEqual(text, "mult str div same hits?") ||
			pos == 126 && !StrEqual(text, "contribution category required?") ||
			pos == 127 && !StrEqual(text, "contribution cost required?") ||
			pos == 128 && !StrEqual(text, "give player this item on trigger?") ||
			pos == 129 && !StrEqual(text, "hide talent strength display?") ||
			pos == 130 && !StrEqual(text, "activator ability trigger to call?") ||
			pos == 131 && !StrEqual(text, "weapon slot required?") ||
			pos == 132 && !StrEqual(text, "require consecutive headshots?") ||
			pos == 133 && !StrEqual(text, "mult str by same headshots?") ||
			pos == 134 && !StrEqual(text, "mult str max same headshots?") ||
			pos == 135 && !StrEqual(text, "mult str div same headshots?") ||
			pos == 136 && !StrEqual(text, "active effect allows all weapons?") ||
			pos == 137 && !StrEqual(text, "active effect allows all hitgroups?") ||
			pos == 138 && !StrEqual(text, "active effect allows all classes?") ||
			pos == 139 && !StrEqual(text, "activator status effect required?") ||
			pos == 140 && !StrEqual(text, "health percentage remaining required?") ||
			pos == 141 && !StrEqual(text, "health cost on activation?") ||
			pos == 142 && !StrEqual(text, "multiply strength downed allies?") ||
			pos == 143 && !StrEqual(text, "multiply strength ensnared allies?") ||
			pos == 144 && !StrEqual(text, "no augment modifiers?") ||
			pos == 145 && !StrEqual(text, "target ability trigger to call?") ||
			pos == 146 && !StrEqual(text, "must be within coherency of talent?") ||
			pos == 147 && !StrEqual(text, "must be unhurt by si or witch?") ||
			pos == 148 && !StrEqual(text, "skip talent for augment roll?") ||
			pos == 149 && !StrEqual(text, "require ally with adrenaline?") ||
			pos == 150 && !StrEqual(text, "require ally below health percentage?") ||
			pos == 151 && !StrEqual(text, "require ensnared ally?") ||
			pos == 152 && !StrEqual(text, "target must be ally ensnarer?") ||
			pos == 153 && !StrEqual(text, "require enemy in coherency range?") ||
			pos == 154 && !StrEqual(text, "enemy in coherency is target?") ||
			pos == 155 && !StrEqual(text, "require ally on fire?") ||
			pos == 156 && !StrEqual(text, "talent cooldown minimum value?") ||
			pos == 157 && !StrEqual(text, "ability category?") ||
			pos == 158 && !StrEqual(text, "target status effect required?") ||
			pos == 159 && !StrEqual(text, "activator must be in ammo?") ||
			pos == 160 && !StrEqual(text, "target must be in ammo?") ||
			pos == 161 && !StrEqual(text, "time since last activator attack?") ||
			pos == 162 && !StrEqual(text, "weapon name required?") ||
			pos == 163 && !StrEqual(text, "require same hitbox?") ||
			pos == 164 && !StrEqual(text, "multiply limit?") ||
			pos == 165 && !StrEqual(text, "active effect interval?") ||
			pos == 166 && !StrEqual(text, "active ability trigger?") ||
			pos == 167 && !StrEqual(text, "ability trigger?")) {
				PushArrayString(TalentKey, text);
				GetArrayString(TalentValue, pos, text, sizeof(text));
				PushArrayString(TalentValue, text);
				RemoveFromArray(TalentKey, pos);
				RemoveFromArray(TalentValue, pos);
				continue;
			}
			pos++;
		}
		for (int i = 0; i < sortSize; i++) {
			if (i == TALENT_IS_EFFECT_OVER_TIME || i == ACTIVATOR_CLASS_REQ || i == TARGET_CLASS_REQ || i == ABILITY_TYPE ||
			i == IF_EOT_ACTIVE_ALLOW_ALL_ENEMIES || i == COMBAT_STATE_REQ || i == CONTRIBUTION_TYPE_CATEGORY ||
			i == CONTRIBUTION_COST || i == TALENT_WEAPON_SLOT_REQUIRED || i == LAST_KILL_MUST_BE_HEADSHOT ||
			i == COHERENCY_RANGE || i == COHERENCY_MAX || i == COHERENCY_REQ ||
			i == HEALTH_PERCENTAGE_REQ_TAR_REMAINING || i == HEALTH_PERCENTAGE_REQ_TAR_MISSING || i == HEALTH_PERCENTAGE_REQ_ACT_REMAINING ||
			i == REQUIRES_ZOOM || i == IF_EOT_ACTIVE_ALLOW_ALL_HITGROUPS || i == REQUIRES_HEADSHOT ||
			i == REQUIRES_LIMBSHOT || i == HEALTH_PERCENTAGE_ACTIVATION_COST ||
			i == TALENT_NO_AUGMENT_MODIFIERS || i == REQUIRE_ENEMY_IN_COHERENCY_RANGE || i == ENEMY_IN_COHERENCY_IS_TARGET) {// || i == UNHURT_BY_SPECIALINFECTED_OR_WITCH) {
				GetArrayString(TalentValue, i, text, sizeof(text));
				if (StrContains(text, ".") != -1) SetArrayCell(TalentValue, i, StringToFloat(text));	//float
				else SetArrayCell(TalentValue, i, StringToInt(text));	//int
			}
			else if (i == ACTIVATOR_STAGGER_REQ || i == TARGET_STAGGER_REQ ||
			i == CANNOT_TARGET_SELF || i == REQ_CONSECUTIVE_HITS ||
			i == REQ_CONSECUTIVE_HEADSHOTS || i == MULT_STR_CONSECUTIVE_HITS || i == MULT_STR_CONSECUTIVE_MAX ||
			i == MULT_STR_CONSECUTIVE_DIV || i == MULT_STR_CONSECUTIVE_HEADSHOTS ||
			i == MULT_STR_CONSECUTIVE_HEADSHOTS_MAX || i == MULT_STR_CONSECUTIVE_HEADSHOTS_DIV ||
			i == BACKGROUND_TALENT || i == STATUS_EFFECT_MULTIPLIER || i == MULTIPLY_RANGE ||
			i == MULTIPLY_TYPE || i == STRENGTH_INCREASE_ZOOMED || i == STRENGTH_INCREASE_TIME_CAP ||
			i == STRENGTH_INCREASE_TIME_REQ || i == ZOOM_TIME_HAS_MINIMUM_REQ ||
			i == HOLDING_FIRE_STRENGTH_INCREASE || i == STRENGTH_INCREASE_TIME_CAP ||
			i == DAMAGE_TIME_HAS_MINIMUM_REQ || i == HEALTH_PERCENTAGE_REQ_MISSING ||
			i == HEALTH_PERCENTAGE_REQ_MISSING_MAX ||
			i == TALENT_ACTIVE_STRENGTH_VALUE || i == PRIMARY_AOE || i == SECONDARY_AOE) {
				GetArrayString(TalentValue, i, text, sizeof(text));
				if (StrContains(text, ".") != -1) SetArrayCell(TalentValue, i, StringToFloat(text));	//float
				else SetArrayCell(TalentValue, i, StringToInt(text));	//int
			}
			else if (i == GET_TALENT_LAYER || i == IS_ATTRIBUTE || i == LAYER_COUNTING_IS_IGNORED ||
			i == ATTRIBUTE_BASE_MULTIPLIER || i == IS_SUB_MENU_OF_TALENTCONFIG ||
			i == IS_AURA_INSTEAD ||
			i == ABILITY_IS_REACTIVE || i == IS_TALENT_ABILITY || i == ABILITY_COOLDOWN_STRENGTH ||
			i == ABILITY_MAXIMUM_PASSIVE_MULTIPLIER || i == ABILITY_MAXIMUM_ACTIVE_MULTIPLIER ||
			i == SPELL_ACTIVE_TIME_PER_POINT || i == SPELL_COOLDOWN_START || i == SPELL_COOLDOWN_FIRST_POINT ||
			i == SPELL_COOLDOWN_PER_POINT || i == SPELL_BASE_STAMINA_REQ || i == SPELL_STAMINA_PER_POINT ||
			i == SPELL_RANGE_FIRST_POINT || i == SPELL_RANGE_PER_POINT || i == SPELL_INTERVAL_FIRST_POINT ||
			i == SPELL_INTERVAL_PER_POINT || i == ABILITY_REQ_NO_ENSNARE || i == ABILITY_ACTIVE_TIME ||
			i == ABILITY_REACTIVE_TYPE || i == ABILITY_DRAW_DELAY || i == ABILITY_IS_SINGLE_TARGET ||
			i == ABILITY_PASSIVE_ONLY) {
				GetArrayString(TalentValue, i, text, sizeof(text));
				if (StrContains(text, ".") != -1) SetArrayCell(TalentValue, i, StringToFloat(text));	//float
				else SetArrayCell(TalentValue, i, StringToInt(text));	//int
			}
			else if (i == ACTIVE_EFFECT_INTERVAL || i == MULTIPLY_LIMIT || i == REQUIRE_SAME_HITBOX || i == TIME_SINCE_LAST_ACTIVATOR_ATTACK ||
			i == ABILITY_EVENT_TYPE || i == TALENT_IS_SPELL || i == NUM_TALENTS_REQ ||
			i == HIDE_TALENT_STRENGTH_DISPLAY || i == HIDE_TRANSLATION || i == ABILITY_ACTIVE_DRAW_DELAY ||
			i == ABILITY_PASSIVE_DRAW_DELAY || i == TALENT_ROLL_CHANCE || i == SPECIAL_AMMO_TALENT_STRENGTH ||
			i == ABILITY_TOGGLE_STRENGTH || i == ABILITY_COOLDOWN || i == SPELL_EFFECT_MULTIPLIER || i == COMPOUNDING_TALENT ||
			i == MULT_STR_NEARBY_DOWN_ALLIES || i == MULT_STR_NEARBY_ENSNARED_ALLIES || i == REQUIRE_TARGET_HAS_ENSNARED_ALLY ||
			i == REQUIRE_ENSNARED_ALLY || i == SKIP_TALENT_FOR_AUGMENT_ROLL || i == REQUIRE_ALLY_WITH_ADRENALINE || i == REQUIRE_ALLY_BELOW_HEALTH_PERCENTAGE ||
			i == REQUIRE_ALLY_ON_FIRE || i == TALENT_MINIMUM_COOLDOWN_TIME || i == ABILITY_CATEGORY) {
				GetArrayString(TalentValue, i, text, sizeof(text));
				if (StrContains(text, ".") != -1) SetArrayCell(TalentValue, i, StringToFloat(text));	//float
				else SetArrayCell(TalentValue, i, StringToInt(text));	//int
			}
			else if (i == TALENT_ABILITY_TRIGGER || i == TALENT_ACTIVE_ABILITY_TRIGGER) {
				GetArrayString(TalentValue, i, text, sizeof(text));
				int trigger = ConvertTriggerToInt(text);
				SetArrayCell(TalentValue, i, trigger);
			}
			else if (i == TARGET_AND_LAST_TARGET_CLASS_MATCH || i == TARGET_RANGE_REQUIRED || i == TARGET_RANGE_REQUIRED_OUTSIDE ||
			i == TARGET_MUST_BE_LAST_TARGET || i == TARGET_IS_SELF || i == ACTIVATOR_STATUS_EFFECT_REQUIRED  || i == TARGET_STATUS_EFFECT_REQUIRED ||
			i == ACTIVATOR_MUST_HAVE_HIGH_GROUND || i == TARGET_MUST_HAVE_HIGH_GROUND || i == ACTIVATOR_TARGET_MUST_EVEN_GROUND ||
			i == IF_EOT_ACTIVE_ALLOW_ALL_WEAPONS || i == WEAPONS_PERMITTED || i == HEALTH_PERCENTAGE_REQ ||
			i == ABILITY_ACTIVE_STATE_ENSNARE_REQ || i == ABILITY_ACTIVE_STRENGTH || i == ABILITY_PASSIVE_IGNORES_COOLDOWN ||
			i == ABILITY_PASSIVE_STATE_ENSNARE_REQ || i == ABILITY_PASSIVE_STRENGTH || i == SPELL_ACTIVE_TIME_FIRST_POINT) {
				GetArrayString(TalentValue, i, text, sizeof(text));
				if (StrContains(text, ".") != -1) SetArrayCell(TalentValue, i, StringToFloat(text));	//float
				else SetArrayCell(TalentValue, i, StringToInt(text));	//int
			}
		}

		// for (int client = 1; client <= MAXPLAYERS; client++) {
		// 	ResizeArray(PlayerAbilitiesCooldown[client], ASize);
		// 	ResizeArray(a_Database_PlayerTalents[client], ASize);
		// 	ResizeArray(a_Database_PlayerTalents_Experience[client], ASize);
		// 	for (int i = 0; i < ASize; i++) {
		// 		SetArrayCell(a_Database_PlayerTalents[client], i, 0);
		// 		SetArrayString(PlayerAbilitiesCooldown[client], i, "0");
		// 		SetArrayCell(a_Database_PlayerTalents_Experience[client], i, 0);
		// 	}
		// }
	}
	else if (StrEqual(Config, CONFIG_EVENTS)) {
		if (FindStringInArray(TalentKey, "entered saferoom?") == -1) {
			PushArrayString(TalentKey, "entered saferoom?");
			PushArrayString(TalentValue, "-1");
		}
		if (FindStringInArray(TalentKey, "bulletimpact?") == -1) {
			PushArrayString(TalentKey, "bulletimpact?");
			PushArrayString(TalentValue, "-1");
		}
		if (FindStringInArray(TalentKey, "shoved?") == -1) {
			PushArrayString(TalentKey, "shoved?");
			PushArrayString(TalentValue, "-1");
		}
		if (FindStringInArray(TalentKey, "multiplier exp?") == -1) {
			PushArrayString(TalentKey, "multiplier exp?");
			PushArrayString(TalentValue, "-1");
		}
		if (FindStringInArray(TalentKey, "multiplier points?") == -1) {
			PushArrayString(TalentKey, "multiplier points?");
			PushArrayString(TalentValue, "-1");
		}
		if (FindStringInArray(TalentKey, "distance?") == -1) {
			PushArrayString(TalentKey, "distance?");
			PushArrayString(TalentValue, "-1");
		}
		if (FindStringInArray(TalentKey, "origin?") == -1) {
			PushArrayString(TalentKey, "origin?");
			PushArrayString(TalentValue, "-1");
		}
		if (FindStringInArray(TalentKey, "tag ability?") == -1) {
			PushArrayString(TalentKey, "tag ability?");
			PushArrayString(TalentValue, "-1");
		}
		if (FindStringInArray(TalentKey, "abilities?") == -1) {
			PushArrayString(TalentKey, "abilities?");
			PushArrayString(TalentValue, "-1");
		}
		if (FindStringInArray(TalentKey, "damage award?") == -1) {
			PushArrayString(TalentKey, "damage award?");
			PushArrayString(TalentValue, "-1");
		}
		if (FindStringInArray(TalentKey, "health?") == -1) {
			PushArrayString(TalentKey, "health?");
			PushArrayString(TalentValue, "-1");
		}
		if (FindStringInArray(TalentKey, "damage type?") == -1) {
			PushArrayString(TalentKey, "damage type?");
			PushArrayString(TalentValue, "-1");
		}
		if (FindStringInArray(TalentKey, "victim ability trigger?") == -1) {
			PushArrayString(TalentKey, "victim ability trigger?");
			PushArrayString(TalentValue, "-1");
		}
		if (FindStringInArray(TalentKey, "victim team required?") == -1) {
			PushArrayString(TalentKey, "victim team required?");
			PushArrayString(TalentValue, "-1");
		}
		if (FindStringInArray(TalentKey, "perpetrator ability trigger?") == -1) {
			PushArrayString(TalentKey, "perpetrator ability trigger?");
			PushArrayString(TalentValue, "-1");
		}
		if (FindStringInArray(TalentKey, "perpetrator team required?") == -1) {
			PushArrayString(TalentKey, "perpetrator team required?");
			PushArrayString(TalentValue, "-1");
		}
		if (FindStringInArray(TalentKey, "same team event trigger?") == -1) {
			PushArrayString(TalentKey, "same team event trigger?");
			PushArrayString(TalentValue, "-1");
		}
		if (FindStringInArray(TalentKey, "victim?") == -1) {
			PushArrayString(TalentKey, "victim?");
			PushArrayString(TalentValue, "-1");
		}
		if (FindStringInArray(TalentKey, "perpetrator?") == -1) {
			PushArrayString(TalentKey, "perpetrator?");
			PushArrayString(TalentValue, "-1");
		}
		sortSize = GetArraySize(TalentKey);
		pos = 0;
		while (pos < sortSize) {
			GetArrayString(TalentKey, pos, text, sizeof(text));
			if (
			pos == 0 && !StrEqual(text, "perpetrator?") ||
			pos == 1 && !StrEqual(text, "victim?") ||
			pos == 2 && !StrEqual(text, "same team event trigger?") ||
			pos == 3 && !StrEqual(text, "perpetrator team required?") ||
			pos == 4 && !StrEqual(text, "perpetrator ability trigger?") ||
			pos == 5 && !StrEqual(text, "victim team required?") ||
			pos == 6 && !StrEqual(text, "victim ability trigger?") ||
			pos == 7 && !StrEqual(text, "damage type?") ||
			pos == 8 && !StrEqual(text, "health?") ||
			pos == 9 && !StrEqual(text, "damage award?") ||
			pos == 10 && !StrEqual(text, "abilities?") ||
			pos == 11 && !StrEqual(text, "tag ability?") ||
			pos == 12 && !StrEqual(text, "origin?") ||
			pos == 13 && !StrEqual(text, "distance?") ||
			pos == 14 && !StrEqual(text, "multiplier points?") ||
			pos == 15 && !StrEqual(text, "multiplier exp?") ||
			pos == 16 && !StrEqual(text, "shoved?") ||
			pos == 17 && !StrEqual(text, "bulletimpact?") ||
			pos == 18 && !StrEqual(text, "entered saferoom?")) {
				PushArrayString(TalentKey, text);
				GetArrayString(TalentValue, pos, text, sizeof(text));
				PushArrayString(TalentValue, text);
				RemoveFromArray(TalentKey, pos);
				RemoveFromArray(TalentValue, pos);
				continue;
			}
			pos++;
		}
		/*
			server operators can set triggers in the events that can fire, so instead of calling and calculating them every time they fire which can be spammy...
		*/
		char abilityTriggerActivator[64];
		char abilityTriggerTarget[64];
		
		GetArrayString(TalentValue, EVENT_PERPETRATOR_ABILITY_TRIGGER, abilityTriggerActivator, sizeof(abilityTriggerActivator));
		int activatorTriggerInt = ConvertTriggerToInt(abilityTriggerActivator);
		SetArrayCell(TalentValue, EVENT_PERPETRATOR_ABILITY_TRIGGER, activatorTriggerInt);
		
		GetArrayString(TalentValue, EVENT_VICTIM_ABILITY_TRIGGER, abilityTriggerTarget, sizeof(abilityTriggerTarget));
		int targetTriggerInt = ConvertTriggerToInt(abilityTriggerTarget);
		SetArrayCell(TalentValue, EVENT_VICTIM_ABILITY_TRIGGER, targetTriggerInt);

		for (int i = 0; i < sortSize; i++) {
			if (i == EVENT_DAMAGE_AWARD || i == EVENT_IS_PLAYER_NOW_IT || i == EVENT_IS_ORIGIN ||
			i == EVENT_IS_DISTANCE || i == EVENT_MULTIPLIER_POINTS || i == EVENT_MULTIPLIER_EXPERIENCE ||
			i == EVENT_IS_SHOVED || i == EVENT_IS_BULLET_IMPACT || i == EVENT_ENTERED_SAFEROOM ||
			i == EVENT_SAMETEAM_TRIGGER) {
				GetArrayString(TalentValue, i, text, sizeof(text));
				if (StrContains(text, ".") != -1) SetArrayCell(TalentValue, i, StringToFloat(text));	//float
				else SetArrayCell(TalentValue, i, StringToInt(text));	//int
			}
		}
	}
	else if (StrEqual(Config, CONFIG_COMMONAFFIXES)) {
		if (FindStringInArray(TalentKey, "require bile?") == -1) {
			PushArrayString(TalentKey, "require bile?");
			PushArrayString(TalentValue, "-1");
		}
		if (FindStringInArray(TalentKey, "raw player strength?") == -1) {
			PushArrayString(TalentKey, "raw player strength?");
			PushArrayString(TalentValue, "-1");
		}
		if (FindStringInArray(TalentKey, "raw common strength?") == -1) {
			PushArrayString(TalentKey, "raw common strength?");
			PushArrayString(TalentValue, "-1");
		}
		if (FindStringInArray(TalentKey, "raw strength?") == -1) {
			PushArrayString(TalentKey, "raw strength?");
			PushArrayString(TalentValue, "-1");
		}
		if (FindStringInArray(TalentKey, "strength special?") == -1) {
			PushArrayString(TalentKey, "strength special?");
			PushArrayString(TalentValue, "-1.0");
		}
		if (FindStringInArray(TalentKey, "onfire interval?") == -1) {
			PushArrayString(TalentKey, "onfire interval?");
			PushArrayString(TalentValue, "-1.0");
		}
		if (FindStringInArray(TalentKey, "onfire max time?") == -1) {
			PushArrayString(TalentKey, "onfire max time?");
			PushArrayString(TalentValue, "-1.0");
		}
		if (FindStringInArray(TalentKey, "onfire level?") == -1) {
			PushArrayString(TalentKey, "onfire level?");
			PushArrayString(TalentValue, "-1.0");
		}
		if (FindStringInArray(TalentKey, "onfire base time?") == -1) {
			PushArrayString(TalentKey, "onfire base time?");
			PushArrayString(TalentValue, "-1.0");
		}
		if (FindStringInArray(TalentKey, "enemy multiplication?") == -1) {
			PushArrayString(TalentKey, "enemy multiplication?");
			PushArrayString(TalentValue, "-1");
		}
		if (FindStringInArray(TalentKey, "damage effect?") == -1) {
			PushArrayString(TalentKey, "damage effect?");
			PushArrayString(TalentValue, "-1");
		}
		if (FindStringInArray(TalentKey, "force model?") == -1) {
			PushArrayString(TalentKey, "force model?");
			PushArrayString(TalentValue, "-1");
		}
		if (FindStringInArray(TalentKey, "level required?") == -1) {
			PushArrayString(TalentKey, "level required?");
			PushArrayString(TalentValue, "-1");
		}
		if (FindStringInArray(TalentKey, "death multiplier?") == -1) {
			PushArrayString(TalentKey, "death multiplier?");
			PushArrayString(TalentValue, "-1.0");
		}
		if (FindStringInArray(TalentKey, "death interval?") == -1) {
			PushArrayString(TalentKey, "death interval?");
			PushArrayString(TalentValue, "-1.0");
		}
		if (FindStringInArray(TalentKey, "death max time?") == -1) {
			PushArrayString(TalentKey, "death max time?");
			PushArrayString(TalentValue, "-1.0");
		}
		if (FindStringInArray(TalentKey, "death base time?") == -1) {
			PushArrayString(TalentKey, "death base time?");
			PushArrayString(TalentValue, "-1.0");
		}
		if (FindStringInArray(TalentKey, "death effect?") == -1) {
			PushArrayString(TalentKey, "death effect?");
			PushArrayString(TalentValue, "-1");
		}
		if (FindStringInArray(TalentKey, "chain reaction?") == -1) {
			PushArrayString(TalentKey, "chain reaction?");
			PushArrayString(TalentValue, "-1");
		}
		if (FindStringInArray(TalentKey, "name?") == -1) {
			PushArrayString(TalentKey, "name?");
			PushArrayString(TalentValue, "-1");
		}
		if (FindStringInArray(TalentKey, "health per level?") == -1) {
			PushArrayString(TalentKey, "health per level?");
			PushArrayString(TalentValue, "-1.0");
		}
		if (FindStringInArray(TalentKey, "base health?") == -1) {
			PushArrayString(TalentKey, "base health?");
			PushArrayString(TalentValue, "-1");
		}
		if (FindStringInArray(TalentKey, "glow colour?") == -1) {
			PushArrayString(TalentKey, "glow colour?");
			PushArrayString(TalentValue, "-1");
		}
		if (FindStringInArray(TalentKey, "glow range?") == -1) {
			PushArrayString(TalentKey, "glow range?");
			PushArrayString(TalentValue, "-1.0");
		}
		if (FindStringInArray(TalentKey, "glow?") == -1) {
			PushArrayString(TalentKey, "glow?");
			PushArrayString(TalentValue, "-1");
		}
		if (FindStringInArray(TalentKey, "model size?") == -1) {
			PushArrayString(TalentKey, "model size?");
			PushArrayString(TalentValue, "-1.0");
		}
		if (FindStringInArray(TalentKey, "fire immunity?") == -1) {
			PushArrayString(TalentKey, "fire immunity?");
			PushArrayString(TalentValue, "-1");
		}
		if (FindStringInArray(TalentKey, "draw type?") == -1) {
			PushArrayString(TalentKey, "draw type?");
			PushArrayString(TalentValue, "-1");
		}
		if (FindStringInArray(TalentKey, "chance?") == -1) {
			PushArrayString(TalentKey, "chance?");
			PushArrayString(TalentValue, "-1.0");
		}
		if (FindStringInArray(TalentKey, "level strength?") == -1) {
			PushArrayString(TalentKey, "level strength?");
			PushArrayString(TalentValue, "-1.0");
		}
		if (FindStringInArray(TalentKey, "strength target?") == -1) {
			PushArrayString(TalentKey, "strength target?");
			PushArrayString(TalentValue, "-1.0");
		}
		if (FindStringInArray(TalentKey, "aura strength?") == -1) {
			PushArrayString(TalentKey, "aura strength?");
			PushArrayString(TalentValue, "-1");
		}
		if (FindStringInArray(TalentKey, "cooldown?") == -1) {
			PushArrayString(TalentKey, "cooldown?");
			PushArrayString(TalentValue, "-1.0");
		}
		if (FindStringInArray(TalentKey, "range max?") == -1) {
			PushArrayString(TalentKey, "range max?");
			PushArrayString(TalentValue, "-1.0");
		}
		if (FindStringInArray(TalentKey, "range player level?") == -1) {
			PushArrayString(TalentKey, "range player level?");
			PushArrayString(TalentValue, "-1.0");
		}
		if (FindStringInArray(TalentKey, "range minimum?") == -1) {
			PushArrayString(TalentKey, "range minimum?");
			PushArrayString(TalentValue, "-1.0");
		}
		if (FindStringInArray(TalentKey, "aura effect?") == -1) {
			PushArrayString(TalentKey, "aura effect?");
			PushArrayString(TalentValue, "-1");
		}
		if (FindStringInArray(TalentKey, "max allowed?") == -1) {
			PushArrayString(TalentKey, "max allowed?");
			PushArrayString(TalentValue, "-1");
		}
		sortSize = GetArraySize(TalentKey);
		pos = 0;
		while (pos < sortSize) {
			GetArrayString(TalentKey, pos, text, sizeof(text));
			if (
			pos == 0 && !StrEqual(text, "max allowed?") ||
			pos == 1 && !StrEqual(text, "aura effect?") ||
			pos == 2 && !StrEqual(text, "range minimum?") ||
			pos == 3 && !StrEqual(text, "range player level?") ||
			pos == 4 && !StrEqual(text, "range max?") ||
			pos == 5 && !StrEqual(text, "cooldown?") ||
			pos == 6 && !StrEqual(text, "aura strength?") ||
			pos == 7 && !StrEqual(text, "strength target?") ||
			pos == 8 && !StrEqual(text, "level strength?") ||
			pos == 9 && !StrEqual(text, "chance?") ||
			pos == 10 && !StrEqual(text, "draw type?") ||
			pos == 11 && !StrEqual(text, "fire immunity?") ||
			pos == 12 && !StrEqual(text, "model size?") ||
			pos == 13 && !StrEqual(text, "glow?") ||
			pos == 14 && !StrEqual(text, "glow range?") ||
			pos == 15 && !StrEqual(text, "glow colour?") ||
			pos == 16 && !StrEqual(text, "base health?") ||
			pos == 17 && !StrEqual(text, "health per level?") ||
			pos == 18 && !StrEqual(text, "name?") ||
			pos == 19 && !StrEqual(text, "chain reaction?") ||
			pos == 20 && !StrEqual(text, "death effect?") ||
			pos == 21 && !StrEqual(text, "death base time?") ||
			pos == 22 && !StrEqual(text, "death max time?") ||
			pos == 23 && !StrEqual(text, "death interval?") ||
			pos == 24 && !StrEqual(text, "death multiplier?") ||
			pos == 25 && !StrEqual(text, "level required?") ||
			pos == 26 && !StrEqual(text, "force model?") ||
			pos == 27 && !StrEqual(text, "damage effect?") ||
			pos == 28 && !StrEqual(text, "enemy multiplication?") ||
			pos == 29 && !StrEqual(text, "onfire base time?") ||
			pos == 30 && !StrEqual(text, "onfire level?") ||
			pos == 31 && !StrEqual(text, "onfire max time?") ||
			pos == 32 && !StrEqual(text, "onfire interval?") ||
			pos == 33 && !StrEqual(text, "strength special?") ||
			pos == 34 && !StrEqual(text, "raw strength?") ||
			pos == 35 && !StrEqual(text, "raw common strength?") ||
			pos == 36 && !StrEqual(text, "raw player strength?") ||
			pos == 37 && !StrEqual(text, "require bile?")) {
				PushArrayString(TalentKey, text);
				GetArrayString(TalentValue, pos, text, sizeof(text));
				PushArrayString(TalentValue, text);
				RemoveFromArray(TalentKey, pos);
				RemoveFromArray(TalentValue, pos);
				continue;
			}
			pos++;
		}
		for (int i = 0; i < sortSize; i++) {
			if (i == SUPER_COMMON_REQ_BILED_SURVIVORS || i == SUPER_COMMON_MAX_ALLOWED || i == SUPER_COMMON_SPAWN_CHANCE ||
			i == SUPER_COMMON_MODEL_SIZE || i == SUPER_COMMON_AURA_STRENGTH || i == SUPER_COMMON_STRENGTH_TARGET || i == SUPER_COMMON_LEVEL_STRENGTH ||
			i == SUPER_COMMON_RANGE_MAX || i == SUPER_COMMON_DEATH_MULTIPLIER || i == SUPER_COMMON_DEATH_BASE_TIME || i == SUPER_COMMON_DEATH_INTERVAL ||
			i == SUPER_COMMON_DEATH_MAX_TIME || i == SUPER_COMMON_LEVEL_REQ || i == SUPER_COMMON_BASE_HEALTH || i == SUPER_COMMON_DRAW_TYPE || i == SUPER_COMMON_ENEMY_MULTIPLICATION ||
			i == SUPER_COMMON_RAW_COMMON_STRENGTH || i == SUPER_COMMON_RAW_PLAYER_STRENGTH || i == SUPER_COMMON_HEALTH_PER_LEVEL || i == SUPER_COMMON_STRENGTH_SPECIAL ||
			i == SUPER_COMMON_RANGE_PLAYER_LEVEL || i == SUPER_COMMON_RANGE_MIN || i == SUPER_COMMON_ONFIRE_BASE_TIME || i == SUPER_COMMON_ONFIRE_LEVEL ||
			i == SUPER_COMMON_ONFIRE_MAX_TIME) {
				GetArrayString(TalentValue, i, text, sizeof(text));
				if (StrContains(text, ".") != -1) SetArrayCell(TalentValue, i, StringToFloat(text));	//float
				else SetArrayCell(TalentValue, i, StringToInt(text));	//int
			}
			if (StrContains(text, ".mdl") == -1) continue;
			PushArrayString(ModelsToPrecache, text);
		}
	}
	else if (StrEqual(Config, CONFIG_HANDICAP)) {
		if (FindStringInArray(TalentKey, "translation?") == -1) {
			PushArrayString(TalentKey, "translation?");
			PushArrayString(TalentValue, "-1");
		}
		if (FindStringInArray(TalentKey, "damage bonus?") == -1) {
			PushArrayString(TalentKey, "damage bonus?");
			PushArrayString(TalentValue, "-1.0");
		}
		if (FindStringInArray(TalentKey, "health bonus?") == -1) {
			PushArrayString(TalentKey, "health bonus?");
			PushArrayString(TalentValue, "-1.0");
		}
		if (FindStringInArray(TalentKey, "loot find?") == -1) {
			PushArrayString(TalentKey, "loot find?");
			PushArrayString(TalentValue, "-1");
		}
		if (FindStringInArray(TalentKey, "score required?") == -1) {
			PushArrayString(TalentKey, "score required?");
			PushArrayString(TalentValue, "-1");
		}
		if (FindStringInArray(TalentKey, "score multiplier?") == -1) {
			PushArrayString(TalentKey, "score multiplier?");
			PushArrayString(TalentValue, "-1.0");
		}
		sortSize = GetArraySize(TalentKey);
		pos = 0;
		while (pos < sortSize) {
			GetArrayString(TalentKey, pos, text, sizeof(text));
			if (
			pos == 0 && !StrEqual(text, "translation?") ||
			pos == 1 && !StrEqual(text, "damage bonus?") ||
			pos == 2 && !StrEqual(text, "health bonus?") ||
			pos == 3 && !StrEqual(text, "loot find?") ||
			pos == 4 && !StrEqual(text, "score required?") ||
			pos == 5 && !StrEqual(text, "score multiplier?")) {
				PushArrayString(TalentKey, text);
				GetArrayString(TalentValue, pos, text, sizeof(text));
				PushArrayString(TalentValue, text);
				RemoveFromArray(TalentKey, pos);
				RemoveFromArray(TalentValue, pos);
				continue;
			}
			pos++;
		}
		for (int i = 0; i < sortSize; i++) {
			GetArrayString(TalentValue, i, text, sizeof(text));
			//if (StrEqual(text, "EOM")) continue;
			if (i == HANDICAP_TRANSLATION) continue;
			if (StrContains(text, ".") != -1) SetArrayCell(TalentValue, i, StringToFloat(text));	//float
			else SetArrayCell(TalentValue, i, StringToInt(text));	//int
		}
	}
	else if (StrEqual(Config, CONFIG_WEAPONS)) {
		if (FindStringInArray(TalentKey, "damage") == -1) {
			PushArrayString(TalentKey, "damage");
			PushArrayString(TalentValue, "-1");
		}
		if (FindStringInArray(TalentKey, "range") == -1) {
			PushArrayString(TalentKey, "range");
			PushArrayString(TalentValue, "-1.0");
		}
		if (FindStringInArray(TalentKey, "offset") == -1) {
			PushArrayString(TalentKey, "offset");
			PushArrayString(TalentValue, "-1");
		}
		if (FindStringInArray(TalentKey, "ammo") == -1) {
			PushArrayString(TalentKey, "ammo");
			PushArrayString(TalentValue, "-1");
		}
		if (FindStringInArray(TalentKey, "effective range") == -1) {
			PushArrayString(TalentKey, "effective range");
			PushArrayString(TalentValue, "-1.0");
		}
		sortSize = GetArraySize(TalentKey);
		pos = 0;
		while (pos < sortSize) {
			GetArrayString(TalentKey, pos, text, sizeof(text));
			if (
			pos == 0 && !StrEqual(text, "damage") ||
			pos == 1 && !StrEqual(text, "offset") ||
			pos == 2 && !StrEqual(text, "ammo") ||
			pos == 3 && !StrEqual(text, "range") ||
			pos == 4 && !StrEqual(text, "effective range")) {
				PushArrayString(TalentKey, text);
				GetArrayString(TalentValue, pos, text, sizeof(text));
				PushArrayString(TalentValue, text);
				RemoveFromArray(TalentKey, pos);
				RemoveFromArray(TalentValue, pos);
				continue;
			}
			pos++;
		}
		for (int i = 0; i < sortSize; i++) {
			GetArrayString(TalentValue, i, text, sizeof(text));
			//if (StrEqual(text, "EOM")) continue;
			if (StrContains(text, ".") != -1) SetArrayCell(TalentValue, i, StringToFloat(text));	//float
			else SetArrayCell(TalentValue, i, StringToInt(text));	//int
		}
	}
	GetArrayString(Section, 0, text, sizeof(text));
	PushArrayString(TalentSection, text);

	ResizeArray(Main, size + 1);
	SetArrayCell(Main, size, TalentKey, 0);
	SetArrayCell(Main, size, TalentValue, 1);
	SetArrayCell(Main, size, TalentSection, 2);
	
	if (configIsForTalents) {
		PushArrayString(a_Database_Talents, text);
		//SetArrayCell(Main, size, TalentTriggers, 3);
	}
}

public ReadyUp_ParseConfigFailed(char[] config, char[] error) {

	if (StrEqual(config, CONFIG_MAIN) ||
		StrEqual(config, CONFIG_EVENTS) ||
		StrEqual(config, CONFIG_SURVIVORTALENTS) ||
		IsTalentConfig(config) ||
		StrEqual(config, CONFIG_MAINMENU) ||
		StrEqual(config, CONFIG_POINTS) ||
		StrEqual(config, CONFIG_STORE) ||
		StrEqual(config, CONFIG_TRAILS) ||
		StrEqual(config, CONFIG_WEAPONS) ||
		StrEqual(config, CONFIG_COMMONAFFIXES) ||
		StrEqual(config, CONFIG_HANDICAP)) {// ||
		//StrEqual(config, CONFIG_CLASSNAMES)) {

		SetFailState("%s , %s", config, error);
	}
}

bool IsTalentConfig(char[] configname) {
	int size = GetArraySize(TalentMenuConfigs);
	for (int i = 0; i < size; i++) {
		char talentconfig[64];
		GetArrayString(TalentMenuConfigs, i, talentconfig, 64);
		if (StrEqual(configname, talentconfig)) return true;
	}
	return false;
}

bool SetTalentConfigs() {
	int size = GetArraySize(MainKeys);
	//char result[64];
	//int len = -1;
	ClearArray(TalentMenuConfigs);
	for (int i = 0; i < size; i++) {
		char configname[64];
		GetArrayString(MainKeys, i, configname, 64);
		if (!StrEqual(configname, "talent config?")) continue;
		GetArrayString(MainValues, i, configname, 64);
		PushArrayString(TalentMenuConfigs, configname);
	}
	// ClearArray(SetKeys);
	// ClearArray(SetVals);
	if (GetArraySize(TalentMenuConfigs) > 0) return true;
	return false;
}