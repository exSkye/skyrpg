void MySQL_Init()
{
	if (hDatabase != INVALID_HANDLE) return;	// already connected.
	//hDatabase														=	INVALID_HANDLE;

	GetConfigValue(TheDBPrefix, sizeof(TheDBPrefix), "database prefix?");
	GetConfigValue(Hostname, sizeof(Hostname), "server name?");
	if (GetConfigValueInt("friendly fire enabled?") == 1) ReplaceString(Hostname, sizeof(Hostname), "{FF}", "FF ON");
	else ReplaceString(Hostname, sizeof(Hostname), "{FF}", "FF OFF");
	if (StrContains(Hostname, "{V}", true) != -1) ReplaceString(Hostname, sizeof(Hostname), "{V}", PLUGIN_VERSION);

	iServerLevelRequirement		= GetConfigValueInt("server level requirement?");
	RatingPerLevel				= GetConfigValueInt("rating level multiplier?");
	RatingPerTalentPoint		= GetConfigValueInt("rating per talent point multiplier?", 500);
	RatingPerTalentPointBots	= GetConfigValueInt("rating per talent point bots?", 100);
	RatingPerAugmentLevel		= GetConfigValueInt("rating per augment level multiplier?", 1);
	RatingPerLevelSurvivorBots	= GetConfigValueInt("rating level multiplier survivor bots?");
	InfectedTalentLevel			= GetConfigValueInt("talent level multiplier?");

	if (iServerLevelRequirement > 0) {

		if (StrContains(Hostname, "{RS}", true) != -1) {

			char HostLevels[64];
			//Format(HostLevels, sizeof(HostLevels), "Lv%s(TruR%s)", AddCommasToString(iServerLevelRequirement), AddCommasToString(iServerLevelRequirement * RatingPerLevel));
			Format(HostLevels, sizeof(HostLevels), "[%d+]", iServerLevelRequirement);
			ReplaceString(Hostname, sizeof(Hostname), "{RS}", HostLevels);
		}
	}
	//Format(sHostname, sizeof(sHostname), "%s", Hostname);

	GetConfigValue(RatingType, sizeof(RatingType), "db record?");
	if (StrEqual(RatingType, "-1")) {

		if (ReadyUp_GetGameMode() == 3) Format(RatingType, sizeof(RatingType), "%s", SURVRECORD_DB);
		else Format(RatingType, sizeof(RatingType), "%s", COOPRECORD_DB);
	}
	ServerCommand("hostname %s", Hostname);
	//SetSurvivorsAliveHostname();
	SQL_TConnect(DBConnect, TheDBPrefix);
}