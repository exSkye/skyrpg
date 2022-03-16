stock ProcessConfigFile(const String:file[])
{
	if (!FileExists(file)) {
		
		SetFailState("File not found: %s", file);
	}
	if (!ParseConfigFile(file)) {

		SetFailState("File formatted incorrectly: %s", file);
	}
}

stock bool:ParseConfigFile(const String:file[])
{
	new Handle:hParser = SMC_CreateParser();
	new String:error[128];
	new line = 0;
	new col = 0;

	ClearArray(Handle:a_KeyConfig);
	ClearArray(Handle:a_ValueConfig);

	SMC_SetReaders(hParser, Config_NewSection, Config_KeyValue, Config_EndSection);
	SMC_SetParseEnd(hParser, Config_End);

	new SMCError:result = SMC_ParseFile(hParser, file, line, col);
	CloseHandle(hParser);

	if (result != SMCError_Okay)
	{
		SMC_GetErrorString(result, error, sizeof(error));
		LogToFile(s_Log, "Problem reading %s, line %d, col %d - error: %s", file, line, col, error);
	}

	Now_IsLoadConfigForward();

	return (result == SMCError_Okay);
}

public SMCResult:Config_NewSection(Handle:parser, const String:section[], bool:quotes)
{
	/*if (StrEqual(section, "campaign")) b_IsSurvivalConfig = false;
	else if (StrEqual(section, "survival")) b_IsSurvivalConfig = true;
	else if (StrEqual(section, "campaign description")) b_IsSurvivalDescription = false;
	else if (StrEqual(section, "survival description")) b_IsSurvivalDescription = true;*/

	strcopy(s_SectionConfig, sizeof(s_SectionConfig), section);

	if (StoreKeys == 1) KeyCount++;

	return SMCParse_Continue;
}

public SMCResult:Config_KeyValue(Handle:parser, const String:key[], const String:value[], bool:ley_quotes, bool:value_quotes)
{
	decl String:lower[64];

	// Parse Modules

	if (b_IsParseConfig) {

		PushArrayString(a_KeyConfig, key);
		PushArrayString(a_ValueConfig, value);
		PushArrayString(a_SectionConfig, s_SectionConfig);

		return SMCParse_Continue;
	}

	// Parse the <gamemode>.cfg

	if (StrEqual(key, "halftime warmup?")) i_IsReadyUpHalftime = StringToInt(value);
	else if (StrEqual(key, "skip readyup period?")) i_IsReadyUpIgnored = StringToInt(value);
	else if (StrEqual(key, "disable hud?")) i_IsHudDisabled = StringToInt(value);
	else if (StrEqual(key, "preround alltalk?")) i_IsWarmupAllTalk = StringToInt(value);
	else if (StrEqual(key, "freeze players?")) i_IsFreeze = StringToInt(value);
	else if (StrEqual(key, "show loading?")) i_IsDisplayLoading = StringToInt(value);
	else if (StrEqual(key, "periodic countdown?")) i_IsPeriodicCountdown = StringToInt(value);
	else if (StrEqual(key, "coop finale rounds")) i_CoopMapRounds = StringToInt(value);
	else if (StrEqual(key, "ready up time?")) i_ReadyUpTime = StringToInt(value);
	else if (StrEqual(key, "first map ready up time?")) i_ReadyUpTimeFirst = StringToInt(value);
	else if (StrEqual(key, "survival game modes?")) Format(GamemodeSurvival, sizeof(GamemodeSurvival), "%s", value);
	else if (StrEqual(key, "coop game modes?")) Format(GamemodeCoop, sizeof(GamemodeCoop), "%s", value);
	else if (StrEqual(key, "versus game modes?")) Format(GamemodeVersus, sizeof(GamemodeVersus), "%s", value);
	else if (StrEqual(key, "scavenge game modes?")) Format(GamemodeScavenge, sizeof(GamemodeScavenge), "%s", value);
	else if (StrEqual(key, "connect message?")) i_IsConnectionMessage = StringToInt(value);
	else if (StrEqual(key, "load message?")) i_IsLoadedMessage = StringToInt(value);
	else if (StrEqual(key, "connection timeout delay")) i_IsConnectionTimeout = StringToInt(value);
	else if (StrEqual(key, "force start door open delay")) i_IsDoorForcedOpen = StringToInt(value);
	else if (StrEqual(key, "periodic countdown time")) i_IsPeriodicTime = StringToInt(value);
	else if (StrEqual(key, "forcestart command?")) strcopy(s_Cmd_ForceStart, sizeof(s_Cmd_ForceStart), value);
	else if (StrEqual(key, "togglehud command?")) strcopy(s_Cmd_ToggleHud, sizeof(s_Cmd_ToggleHud), value);
	else if (StrEqual(key, "toggleready command?")) strcopy(s_Cmd_ToggleReady, sizeof(s_Cmd_ToggleReady), value);
	else if (StrEqual(key, "majority ready enabled?")) i_IsMajority = StringToInt(value);
	else if (StrEqual(key, "majority ready timer?")) i_IsMajorityTimer = StringToInt(value);
	else if (StrEqual(key, "force start maps?")) Format(ForceStartMaps, sizeof(ForceStartMaps), "%s", value);
	else if (StrEqual(key, "header?")) {
	
		strcopy(s_rup, sizeof(s_rup), value);
		Format(s_rup, sizeof(s_rup), "\x04[\x03%s\x04] \x01", s_rup);
	}
	else {

		// Parse the maplist.cfg
	
		if (StrEqual(s_SectionConfig, "campaign")) {

			Format(lower, sizeof(lower), "%s", key);
			lower = LowerString(lower);
			PushArrayString(a_FirstMap, lower);

			Format(lower, sizeof(lower), "%s", value);
			lower = LowerString(lower);
			PushArrayString(a_FinalMap, lower);
		}
		else if (StrEqual(s_SectionConfig, "campaign description")) {

			Format(lower, sizeof(lower), "%s", key);
			lower = LowerString(lower);
			PushArrayString(a_CampaignMapDescriptionKey, lower);

			Format(lower, sizeof(lower), "%s", value);
			lower = LowerString(lower);
			PushArrayString(a_CampaignMapDescriptionValue, lower);
		}
		else if (StrEqual(s_SectionConfig, "survival")) {

			Format(lower, sizeof(lower), "%s", key);
			lower = LowerString(lower);
			PushArrayString(a_SurvivalMap, lower);

			Format(lower, sizeof(lower), "%s", value);
			lower = LowerString(lower);
			PushArrayString(a_SurvivalMapNext, lower);
		}
		else if (StrEqual(s_SectionConfig, "survival description")) {

			Format(lower, sizeof(lower), "%s", key);
			lower = LowerString(lower);
			PushArrayString(a_SurvivalMapDescriptionKey, lower);

			Format(lower, sizeof(lower), "%s", value);
			lower = LowerString(lower);
			PushArrayString(a_SurvivalMapDescriptionValue, lower);
		}
		
		/*if (!b_IsSurvivalConfig) {

			Format(lower, sizeof(lower), "%s", key);
			lower = LowerString(lower);
			PushArrayString(a_FirstMap, lower);

			Format(lower, sizeof(lower), "%s", value);
			lower = LowerString(lower);
			PushArrayString(a_FinalMap, lower);
		}
		else {

			Format(lower, sizeof(lower), "%s", key);
			lower = LowerString(lower);
			PushArrayString(a_SurvivalMap, lower);

			Format(lower, sizeof(lower), "%s", value);
			lower = LowerString(lower);
			PushArrayString(a_SurvivalMapNext, lower);
		}*/
	}

	return SMCParse_Continue;
}

stock String:LowerString(String:s[]) {

	decl String:s_[32];
	for (new i = 0; i <= strlen(s); i++) {

		if (!IsCharLower(s[i])) s_[i] = CharToLower(s[i]);
		else s_[i] = s[i];
	}
	return s_;
}

public SMCResult:Config_EndSection(Handle:parser) 
{
	return SMCParse_Continue;
}

public Config_End(Handle:parser, bool:halted, bool:failed) 
{
	if (failed)
	{
		SetFailState("Plugin configuration error");
	}
}  