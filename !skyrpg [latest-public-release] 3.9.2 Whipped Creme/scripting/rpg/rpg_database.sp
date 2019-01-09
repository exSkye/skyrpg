MySQL_Init()
{
	if (hDatabase != INVALID_HANDLE) return;	// already connected.
	//hDatabase														=	INVALID_HANDLE;
	SQL_TConnect(DBConnect, GetConfigValue("database prefix?"));
}

public DBConnect(Handle:owner, Handle:hndl, const String:error[], any:data)
{
	if (hndl == INVALID_HANDLE)
	{
		LogMessage("Unable to connect to database: %s", error);
		SetFailState("%s", error);
	}

	hDatabase = hndl;
	LogMessage("RPG DB FOUND");
	
	if (StringToInt(GetConfigValue("generate database?")) == 1) {

		LogMessage("TRYING TO CREATE ROWS");

		SQL_FastQuery(hDatabase, "SET NAMES \"UTF8\"");

		decl String:tquery[PLATFORM_MAX_PATH];
		decl String:text[64];

		Format(tquery, sizeof(tquery), "CREATE TABLE IF NOT EXISTS `%s` (`steam_id` varchar(32) NOT NULL, PRIMARY KEY (`steam_id`)) ENGINE=MyISAM;", GetConfigValue("database prefix?"));
		SQL_TQuery(hDatabase, QueryResults, tquery);

		Format(tquery, sizeof(tquery), "ALTER TABLE `%s` ADD `player name` varchar(32) NOT NULL DEFAULT 'none';", GetConfigValue("database prefix?"));
		SQL_TQuery(hDatabase, QueryResults, tquery);

		Format(tquery, sizeof(tquery), "ALTER TABLE `%s` ADD `strength` int(32) NOT NULL DEFAULT '0';", GetConfigValue("database prefix?"));
		SQL_TQuery(hDatabase, QueryResults, tquery);
		Format(tquery, sizeof(tquery), "ALTER TABLE `%s` ADD `luck` int(32) NOT NULL DEFAULT '0';", GetConfigValue("database prefix?"));
		SQL_TQuery(hDatabase, QueryResults, tquery);
		Format(tquery, sizeof(tquery), "ALTER TABLE `%s` ADD `agility` int(32) NOT NULL DEFAULT '0';", GetConfigValue("database prefix?"));
		SQL_TQuery(hDatabase, QueryResults, tquery);
		Format(tquery, sizeof(tquery), "ALTER TABLE `%s` ADD `technique` int(32) NOT NULL DEFAULT '0';", GetConfigValue("database prefix?"));
		SQL_TQuery(hDatabase, QueryResults, tquery);
		Format(tquery, sizeof(tquery), "ALTER TABLE `%s` ADD `endurance` int(32) NOT NULL DEFAULT '0';", GetConfigValue("database prefix?"));
		SQL_TQuery(hDatabase, QueryResults, tquery);

		Format(tquery, sizeof(tquery), "ALTER TABLE `%s` ADD `experience` int(32) NOT NULL DEFAULT '0';", GetConfigValue("database prefix?"));
		SQL_TQuery(hDatabase, QueryResults, tquery);
		Format(tquery, sizeof(tquery), "ALTER TABLE `%s` ADD `experience overall` int(32) NOT NULL DEFAULT '0';", GetConfigValue("database prefix?"));
		SQL_TQuery(hDatabase, QueryResults, tquery);
		Format(tquery, sizeof(tquery), "ALTER TABLE `%s` ADD `upgrade cost` int(32) NOT NULL DEFAULT '0';", GetConfigValue("database prefix?"));
		SQL_TQuery(hDatabase, QueryResults, tquery);
		Format(tquery, sizeof(tquery), "ALTER TABLE `%s` ADD `level` int(32) NOT NULL DEFAULT '1';", GetConfigValue("database prefix?"));
		SQL_TQuery(hDatabase, QueryResults, tquery);
		Format(tquery, sizeof(tquery), "ALTER TABLE `%s` ADD `%s` int(32) NOT NULL DEFAULT '0';", GetConfigValue("database prefix?"), GetConfigValue("sky points menu name?"));
		SQL_TQuery(hDatabase, QueryResults, tquery);
		Format(tquery, sizeof(tquery), "ALTER TABLE `%s` ADD `time played` int(32) NOT NULL DEFAULT '0';", GetConfigValue("database prefix?"));
		SQL_TQuery(hDatabase, QueryResults, tquery);
		Format(tquery, sizeof(tquery), "ALTER TABLE `%s` ADD `talent points` int(32) NOT NULL DEFAULT '0';", GetConfigValue("database prefix?"));
		SQL_TQuery(hDatabase, QueryResults, tquery);
		Format(tquery, sizeof(tquery), "ALTER TABLE `%s` ADD `total upgrades` int(32) NOT NULL DEFAULT '0';", GetConfigValue("database prefix?"));
		SQL_TQuery(hDatabase, QueryResults, tquery);
		Format(tquery, sizeof(tquery), "ALTER TABLE `%s` ADD `free upgrades` int(32) NOT NULL DEFAULT '0';", GetConfigValue("database prefix?"));
		SQL_TQuery(hDatabase, QueryResults, tquery);
		Format(tquery, sizeof(tquery), "ALTER TABLE `%s` ADD `slate points` int(32) NOT NULL DEFAULT '0';", GetConfigValue("database prefix?"));
		SQL_TQuery(hDatabase, QueryResults, tquery);
		Format(tquery, sizeof(tquery), "ALTER TABLE `%s` ADD `handicap` int(32) NOT NULL DEFAULT '0';", GetConfigValue("database prefix?"));
		SQL_TQuery(hDatabase, QueryResults, tquery);
		Format(tquery, sizeof(tquery), "ALTER TABLE `%s` ADD `rested time` int(32) NOT NULL DEFAULT '0';", GetConfigValue("database prefix?"));
		SQL_TQuery(hDatabase, QueryResults, tquery);
		Format(tquery, sizeof(tquery), "ALTER TABLE `%s` ADD `rested experience` int(32) NOT NULL DEFAULT '0';", GetConfigValue("database prefix?"));
		SQL_TQuery(hDatabase, QueryResults, tquery);
		Format(tquery, sizeof(tquery), "ALTER TABLE `%s` ADD `last play length` int(32) NOT NULL DEFAULT '0';", GetConfigValue("database prefix?"));
		SQL_TQuery(hDatabase, QueryResults, tquery);
		Format(tquery, sizeof(tquery), "ALTER TABLE `%s` ADD `resr` int(32) NOT NULL DEFAULT '0';", GetConfigValue("database prefix?"));
		SQL_TQuery(hDatabase, QueryResults, tquery);
		Format(tquery, sizeof(tquery), "ALTER TABLE `%s` ADD `pri` int(32) NOT NULL DEFAULT '1';", GetConfigValue("database prefix?"));
		SQL_TQuery(hDatabase, QueryResults, tquery);
		Format(tquery, sizeof(tquery), "ALTER TABLE `%s` ADD `tcolour` varchar(32) NOT NULL DEFAULT 'none';", GetConfigValue("database prefix?"));
		SQL_TQuery(hDatabase, QueryResults, tquery);
		Format(tquery, sizeof(tquery), "ALTER TABLE `%s` ADD `tname` varchar(32) NOT NULL DEFAULT 'none';", GetConfigValue("database prefix?"));
		SQL_TQuery(hDatabase, QueryResults, tquery);
		Format(tquery, sizeof(tquery), "ALTER TABLE `%s` ADD `ccolour` varchar(32) NOT NULL DEFAULT 'none';", GetConfigValue("database prefix?"));
		SQL_TQuery(hDatabase, QueryResults, tquery);

		Format(tquery, sizeof(tquery), "ALTER TABLE `%s` ADD `xpdebt` int(32) NOT NULL DEFAULT '0';", GetConfigValue("database prefix?"));
		SQL_TQuery(hDatabase, QueryResults, tquery);
		Format(tquery, sizeof(tquery), "ALTER TABLE `%s` ADD `upav` int(32) NOT NULL DEFAULT '0';", GetConfigValue("database prefix?"));
		SQL_TQuery(hDatabase, QueryResults, tquery);
		Format(tquery, sizeof(tquery), "ALTER TABLE `%s` ADD `upawarded` int(32) NOT NULL DEFAULT '0';", GetConfigValue("database prefix?"));
		SQL_TQuery(hDatabase, QueryResults, tquery);

		/*new size			=	GetArraySize(a_Database_Talents);

		for (new i = 0; i < size; i++) {

			GetArrayString(Handle:a_Database_Talents, i, text, sizeof(text));
			Format(tquery, sizeof(tquery), "ALTER TABLE `%s` ADD `%s` int(32) NOT NULL DEFAULT '0';", GetConfigValue("database prefix?"), text);
			SQL_TQuery(hDatabase, QueryResults, tquery);
		}*/

		ClearArray(Handle:a_Database_Talents_Defaults);
		ClearArray(Handle:a_Database_Talents_Defaults_Name);

		new size2			=	0;
		decl String:key[64];
		decl String:value[64];

		new size			=	GetArraySize(a_Menu_Talents);
		for (new i = 0; i < size; i++) {

			DatabaseKeys			=	GetArrayCell(a_Menu_Talents, i, 0);
			DatabaseValues			=	GetArrayCell(a_Menu_Talents, i, 1);
			DatabaseSection			=	GetArrayCell(a_Menu_Talents, i, 2);

			GetArrayString(Handle:DatabaseSection, 0, text, sizeof(text));
			PushArrayString(Handle:a_Database_Talents_Defaults_Name, text);
			//LogMessage("Pos: %d , Section: %s", i, text);

			size2					=	GetArraySize(DatabaseKeys);
			for (new ii = 0; ii < size2; ii++) {

				GetArrayString(Handle:DatabaseKeys, ii, key, sizeof(key));
				GetArrayString(Handle:DatabaseValues, ii, value, sizeof(value));

				if (StrEqual(key, "ability inherited?")) {

					PushArrayString(Handle:a_Database_Talents_Defaults, value);

					if (StringToInt(value) == 1) Format(tquery, sizeof(tquery), "ALTER TABLE `%s` ADD `%s` int(32) NOT NULL DEFAULT '0';", GetConfigValue("database prefix?"), text);
					else Format(tquery, sizeof(tquery), "ALTER TABLE `%s` ADD `%s` int(32) NOT NULL DEFAULT '-1';", GetConfigValue("database prefix?"), text);
					SQL_TQuery(hDatabase, QueryResults, tquery);

					break;
				}
			}
		}

		size				=	GetArraySize(a_DirectorActions);

		for (new i = 0; i < size; i++) {

			DatabaseSection			=	GetArrayCell(a_DirectorActions, i, 2);
			GetArrayString(Handle:DatabaseSection, 0, text, sizeof(text));
			Format(tquery, sizeof(tquery), "ALTER TABLE `%s` ADD `%s` int(32) NOT NULL DEFAULT '0';", GetConfigValue("database prefix?"), text);
			SQL_TQuery(hDatabase, QueryResults, tquery);
		}

		size				=	GetArraySize(a_Store);

		for (new i = 0; i < size; i++) {

			DatabaseSection			=	GetArrayCell(a_Store, i, 2);
			GetArrayString(Handle:DatabaseSection, 0, text, sizeof(text));
			Format(tquery, sizeof(tquery), "ALTER TABLE `%s` ADD `%s` int(32) NOT NULL DEFAULT '0';", GetConfigValue("database prefix?"), text);
			SQL_TQuery(hDatabase, QueryResults, tquery);
		}
	}

	new size = GetArraySize(a_Database_Talents);

	ResizeArray(Handle:a_Database_PlayerTalents_Bots, size);
	ResizeArray(Handle:PlayerAbilitiesCooldown_Bots, size);
	ResizeArray(Handle:PlayerAbilitiesImmune_Bots, size);

	//IsSaveDirectorPriority = false;		// By default, director priorities ARE NOT saved. Must be toggled by an admin.

	//Format(CurrentTalentLoading_Bots, sizeof(CurrentTalentLoading_Bots), "-1");
	//ClearAndLoadBot();
}

public QueryResults(Handle:owner, Handle:hndl, const String:error[], any:client) { }

public ClearAndLoadBot() {

	if (hDatabase == INVALID_HANDLE || b_IsLoadingInfectedBotData) return;
	b_IsLoadingInfectedBotData = true;

	decl String:tquery[512];
	decl String:key[64];
	LoadPos_Bots = 0;
	Format(key, sizeof(key), "%s", GetConfigValue("director steam id?"));
	Format(CurrentTalentLoading_Bots, sizeof(CurrentTalentLoading_Bots), "-1");

	Format(tquery, sizeof(tquery), "SELECT `strength`, `luck`, `agility`, `technique`, `endurance`, `experience`, `experience overall`, `upgrade cost`, `level`, `talent points` FROM `%s` WHERE (`steam_id` = '%s');", GetConfigValue("database prefix?"), key);
	//LogMessage("Loading Director Data: %s", tquery);
	SQL_TQuery(hDatabase, QueryResults_LoadBot, tquery, FindAnyRandomClient());

	LoadDirectorActions();
}

stock ResetData(client) {

	RefreshSurvivor(client);
	Points[client]					= 0.0;
	SlatePoints[client]				= 0;
	FreeUpgrades[client]			= 0;
	b_IsDirectorTalents[client]		= false;
	b_IsJumping[client]				= false;
	ModifyGravity(client);
	ResetCoveredInBile(client);
	SpeedMultiplierBase[client]		= 1.0;
	if (IsLegitimateClientAlive(client) && !IsGhost(client)) SetEntPropFloat(client, Prop_Send, "m_flLaggedMovementValue", SpeedMultiplierBase[client]);
	TimePlayed[client]				= 0;
	t_Distance[client]				= 0;
	t_Healing[client]				= 0;
	b_IsBlind[client]				= false;
	b_IsImmune[client]				= false;
	GravityBase[client]				= 1.0;
	CommonKills[client]				= 0;
	CommonKillsHeadshot[client]		= 0;
	bIsMeleeCooldown[client]		= false;
	ClearArray(Handle:InfectedHealth[client]);
}

stock ClearAndLoad(String:key[]) {

	if (hDatabase == INVALID_HANDLE) return;
	new client = FindClientWithAuthString(key);

	if (b_IsLoading[client]) return;
	b_IsLoading[client] = true;
	ResetData(client);

	LoadPos[client] = 0;

	new size = GetArraySize(Handle:a_Database_Talents);

	if (!b_IsArraysCreated[client]) {

		b_IsArraysCreated[client]			= true;
	}

	if (GetArraySize(a_Database_PlayerTalents[client]) != size) {

		ResizeArray(a_Database_PlayerTalents[client], size);
		ResizeArray(PlayerAbilitiesCooldown[client], size);
		ResizeArray(PlayerAbilitiesImmune[client], size);
	}

	if (GetArraySize(a_Store_Player[client]) != GetArraySize(a_Store)) {

		ResizeArray(a_Store_Player[client], GetArraySize(a_Store));
	}

	for (new i = 0; i < GetArraySize(a_Store); i++) {

		SetArrayString(a_Store_Player[client], i, "0");				// We clear all players arrays for the store.
	}
	ResizeArray(Handle:ChatSettings[client], 3);
	decl String:tquery[1024];
	Format(tquery, sizeof(tquery), "none");
	SetArrayString(Handle:ChatSettings[client], 0, tquery);
	SetArrayString(Handle:ChatSettings[client], 1, tquery);
	SetArrayString(Handle:ChatSettings[client], 2, tquery);

	Format(tquery, sizeof(tquery), "SELECT `steam_id`, `strength`, `luck`, `agility`, `technique`, `endurance`, `experience`, `experience overall`, `upgrade cost`, `level`, `%s`, `time played`, `talent points`, `total upgrades`, `free upgrades`, `slate points`, `handicap`, `rested time`, `rested experience`, `last play length`, `resr`, `pri`, `tcolour`, `tname`, `ccolour`, `xpdebt`, `upav`, `upawarded` FROM `%s` WHERE (`steam_id` = '%s');", GetConfigValue("sky points menu name?"), GetConfigValue("database prefix?"), key);
	// maybe set a value equal to the users steamid integer only, so if steam:0:1:23456, set the value of "client" equal to 23456 and then set the client equal to whatever client's steamid contains 23456?
	//LogMessage("Loading %N data: %s", client, tquery);
	SQL_TQuery(hDatabase, QueryResults_Load, tquery, client);
}

public Query_CheckIfDataExistsBot(Handle:owner, Handle:hndl, const String:error[], any:client) {

	if (hndl == INVALID_HANDLE) {

		LogMessage("Query_CheckIfDataExistsBot Error: %s", error);
		return;
	}
	decl String:key[64];
	decl String:tquery[1024];
	new count = 0;
	Format(key, sizeof(key), "%s", GetConfigValue("director steam id?"));
	while (SQL_FetchRow(hndl)) {

		count = SQL_FetchInt(hndl, 0);

		if (count < 1) {

			LogMessage("Infected Bot data does not exist, creating and inserting");
			Strength_Bots				=	StringToInt(GetConfigValue("strength?"));
			Luck_Bots					=	StringToInt(GetConfigValue("luck?"));
			Agility_Bots				=	StringToInt(GetConfigValue("agility?"));
			Technique_Bots				=	StringToInt(GetConfigValue("technique?"));
			Endurance_Bots				=	StringToInt(GetConfigValue("endurance?"));
			ExperienceLevel_Bots		=	0;
			ExperienceOverall_Bots		=	0;
			PlayerLevelUpgrades_Bots	=	0;
			PlayerLevel_Bots			=	1;
			TotalTalentPoints_Bots		=	0;

			new size = GetArraySize(Handle:a_Database_Talents);
			for (new i = 0; i < size; i++) {

				SetArrayString(a_Database_PlayerTalents_Bots, i, "0");
			}
			Format(tquery, sizeof(tquery), "INSERT INTO `%s` (`steam_id`, `strength`, `luck`, `agility`, `technique`, `endurance`, `experience`, `experience overall`, `upgrade cost`, `level`, `talent points`) VALUES ('%s', '%d', '%d', '%d', '%d', '%d', '%d', '%d', '%d', '%d', '%d');", GetConfigValue("database prefix?"), GetConfigValue("director steam id?"), Strength_Bots, Luck_Bots, Agility_Bots, Technique_Bots, Endurance_Bots, ExperienceLevel_Bots, ExperienceOverall_Bots, PlayerLevelUpgrades_Bots, PlayerLevel_Bots, TotalTalentPoints_Bots);
			SQL_TQuery(hDatabase, QueryResults, tquery, FindAnyRandomClient());
		}
		else {

			LogMessage("Infected bot data found: %d rows, loading data", count);
			ClearAndLoadBot();
		}
	}
}

public Query_CheckIfDataExists(Handle:owner, Handle:hndl, const String:error[], any:client) {

	if (hndl == INVALID_HANDLE) {

		LogMessage("Query_ChecKIfDataExists Error: %s", error);
		return;
	}
	decl String:key[64];
	decl String:tquery[512];
	new count	= 0;
	if (!IsClientConnected(client)) return;
	GetClientAuthString(client, key, sizeof(key));
	while (SQL_FetchRow(hndl)) {

		//SQL_FetchString(hndl, 0, key, sizeof(key));
		count	= SQL_FetchInt(hndl, 0);

		//client	= FindClientWithAuthString(key);
		if (count < 1) {

			CheckServerLevelRequirements(client);

			LogMessage("No data rows for %N with steamid: %s, could be found, creating new player data.", client, key);
			Strength[client]				=	StringToInt(GetConfigValue("strength?"));
			Luck[client]					=	StringToInt(GetConfigValue("luck?"));
			Agility[client]					=	StringToInt(GetConfigValue("agility?"));
			Technique[client]				=	StringToInt(GetConfigValue("technique?"));
			Endurance[client]				=	StringToInt(GetConfigValue("endurance?"));
			ExperienceDebt[client]			=	0;
			ExperienceLevel[client]			=	0;
			ExperienceOverall[client]		=	0;
			PlayerLevelUpgrades[client]		=	0;
			PlayerLevel[client]				=	1;
			SkyPoints[client]				=	0;
			TotalTalentPoints[client]		=	0;
			TimePlayed[client]				=	0;
			PlayerUpgradesTotal[client]		=	0;
			FreeUpgrades[client]			=	0;
			SlatePoints[client]				=	StringToInt(GetConfigValue("new player slate points?"));
			HandicapLevel[client]			=	-1;		// Handicap starts disabled.

			new size = GetArraySize(Handle:a_Database_Talents);

			ResizeArray(PlayerAbilitiesCooldown[client], size);
			ResizeArray(a_Database_PlayerTalents[client], size);
			ResizeArray(PlayerAbilitiesImmune[client], size);

			decl String:text[64];

			for (new i = 0; i < size; i++) {

				GetArrayString(a_Database_Talents_Defaults, i, text, sizeof(text));
				Format(text, sizeof(text), "%d", StringToInt(text) - 1);
				SetArrayString(a_Database_PlayerTalents[client], i, text);
			}

			if (GetArraySize(a_Store_Player[client]) != GetArraySize(a_Store)) {

				ResizeArray(a_Store_Player[client], GetArraySize(a_Store));
			}

			for (new i = 0; i < GetArraySize(a_Store); i++) {

				SetArrayString(a_Store_Player[client], i, "0");				// We clear all players arrays for the store.
			}

			decl String:TagColour[64];
			decl String:TagName[64];
			decl String:ChatColour[64];

			Format(TagColour, sizeof(TagColour), "none");
			Format(TagName, sizeof(TagName), "none");
			Format(ChatColour, sizeof(ChatColour), "none");

			Format(tquery, sizeof(tquery), "INSERT INTO `%s` (`steam_id`, `strength`, `luck`, `agility`, `technique`, `endurance`, `experience`, `experience overall`, `upgrade cost`, `level`, `%s`, `time played`, `talent points`, `total upgrades`, `free upgrades`, `slate points`, `handicap`, `tcolour`, `tname`, `ccolour`) VALUES ('%s', '%d', '%d', '%d', '%d', '%d', '%d', '%d', '%d', '%d', '%d', '%d', '%d', '%d', '%d', '%d', '%d', '%s', '%s', '%s');", GetConfigValue("database prefix?"), GetConfigValue("sky points menu name?"), key, Strength[client], Luck[client], Agility[client], Technique[client], Endurance[client], ExperienceLevel[client], ExperienceOverall[client], PlayerLevelUpgrades[client], PlayerLevel[client], SkyPoints[client], TimePlayed[client], TotalTalentPoints[client], PlayerUpgradesTotal[client], FreeUpgrades[client], SlatePoints[client], HandicapLevel[client], TagColour, TagName, ChatColour);
			SQL_TQuery(hDatabase, QueryResults, tquery, client);
		}
		else {

			LogMessage("%d Data rows found for %N with steamid: %s, loading player data.", count, client, key);
			ClearAndLoad(key);
		}
	}
}

stock CreateNewInfectedBot() {

	if (hDatabase == INVALID_HANDLE) return;
	decl String:tquery[512];
	decl String:key[64];

	LogMessage("Checking to see if Infected Bot data already exists");
	Format(key, sizeof(key), "%s", GetConfigValue("director steam id?"));

	Format(tquery, sizeof(tquery), "SELECT COUNT(*) FROM `%s` WHERE (`steam_id` = '%s');", GetConfigValue("database prefix?"), key);
	SQL_TQuery(hDatabase, Query_CheckIfDataExistsBot, tquery, FindAnyRandomClient());
}

stock CreateNewPlayer(client) {

	if (hDatabase == INVALID_HANDLE) return;
	decl String:tquery[512];
	decl String:key[64];

	LogMessage("Looking up player %N in Database before creating new data.", client);
	GetClientAuthString(client, key, sizeof(key));

	Format(tquery, sizeof(tquery), "SELECT COUNT(*) FROM `%s` WHERE (`steam_id` = '%s');", GetConfigValue("database prefix?"), key);
	SQL_TQuery(hDatabase, Query_CheckIfDataExists, tquery, client);
}

stock SaveAndClear(client, bool:b_IsTrueDisconnect = false) {

	// if the database isn't connected, we don't try to save data, because that'll just throw errors.
	// If the player didn't participate, or if they are currently saving data, we don't save as well.
	// It's possible (but not likely) for a player to try to save data while saving, due to their ability to call the function at any time through commands.
	if (hDatabase == INVALID_HANDLE || bSaveData[client]) return;
	if (PlayerLevel[client] < 1) return;

	if (b_IsTrueDisconnect) resr[client] = 1;
	else resr[client] = 0;

	bSaveData[client] = true;

	decl String:tquery[1024];
	decl String:key[64];
	decl String:text[1024];
	decl String:text2[1024];

	if (!b_IsRoundIsOver || HandicapLevel[client] < StringToInt(GetConfigValue("handicap breadth?"))) {

		// Client leaves mid-round, so we give them 1 incap so they can't activate hardcore mode the next round they play.
		PreviousRoundIncaps[client] = 1;
	}
	else PreviousRoundIncaps[client] = RoundIncaps[client];

	new size = GetArraySize(a_Database_Talents);

	b_IsDirectorTalents[client] = false;
	GetClientAuthString(client, key, sizeof(key));
	/*if (PlayerUpgradesTotal[client] == 0 && FreeUpgrades[client] == 0 && PlayerLevel[client] <= 1) {

		Format(tquery, sizeof(tquery), "DELETE FROM `%s` WHERE `steam_id` = '%s';", GetConfigValue("database prefix?"), key);
		SQL_TQuery(hDatabase, QueryResults, tquery, client);
		bSaveData[client] = false;
		return;
	}*/

	decl String:Name[64];
	GetClientName(client, Name, sizeof(Name));

	//if (PlayerLevel[client] < 1) return;		// Clearly, their data hasn't loaded, so we don't save.
	Format(tquery, sizeof(tquery), "UPDATE `%s` SET `strength` = '%d', `luck` = '%d', `agility` = '%d', `technique` = '%d', `endurance` = '%d', `experience` = '%d', `experience overall` = '%d', `upgrade cost` = '%d', `level` = '%d', `%s` = '%d', `time played` = '%d', `talent points` = '%d', `total upgrades` = '%d', `free upgrades` = '%d', `slate points` = '%d', `handicap` = '%d', `xpdebt` = '%d' WHERE `steam_id` = '%s';", GetConfigValue("database prefix?"), Strength[client], Luck[client], Agility[client], Technique[client], Endurance[client], ExperienceLevel[client], ExperienceOverall[client], PlayerLevelUpgrades[client], PlayerLevel[client], GetConfigValue("sky points menu name?"), SkyPoints[client], TimePlayed[client], TotalTalentPoints[client], PlayerUpgradesTotal[client], FreeUpgrades[client], SlatePoints[client], HandicapLevel[client], ExperienceDebt[client], key);
	LogMessage(tquery);
	SQL_TQuery(hDatabase, QueryResults, tquery, client);

	Format(tquery, sizeof(tquery), "UPDATE `%s` SET `upav` = '%d', `upawarded` = '%d' WHERE `steam_id` = '%s';", GetConfigValue("database prefix?"), UpgradesAvailable[client], UpgradesAwarded[client], key);
	SQL_TQuery(hDatabase, QueryResults, tquery, client);

	Format(tquery, sizeof(tquery), "UPDATE `%s` SET `player name` = '%s' WHERE `steam_id` = '%s';", GetConfigValue("database prefix?"), Name, key);
	SQL_TQuery(hDatabase, QueryResults, tquery, client);

	Format(tquery, sizeof(tquery), "UPDATE `%s` SET `rested time` = '%d', `rested experience` = '%d', `last play length` = '%d', `resr` = '%d', `pri` = '%d' WHERE `steam_id` = '%s';", GetConfigValue("database prefix?"), GetTime(), RestedExperience[client], LastPlayLength[client], resr[client], PreviousRoundIncaps[client], key);
	SQL_TQuery(hDatabase, QueryResults, tquery, client);

	for (new i = 0; i < size; i++) {

		GetArrayString(a_Database_Talents, i, text, sizeof(text));
		GetArrayString(a_Database_PlayerTalents[client], i, text2, sizeof(text2));
		Format(tquery, sizeof(tquery), "UPDATE `%s` SET `%s` = '%s' WHERE `steam_id` = '%s';", GetConfigValue("database prefix?"), text, text2, key);
		SQL_TQuery(hDatabase, QueryResults, tquery, client);
	}

	size				=	GetArraySize(a_Store);

	for (new i = 0; i < size; i++) {

		SaveSection[client]			=	GetArrayCell(a_Store, i, 2);
		GetArrayString(Handle:SaveSection[client], 0, text, sizeof(text));
		GetArrayString(a_Store_Player[client], i, text2, sizeof(text2));
		Format(tquery, sizeof(tquery), "UPDATE `%s` SET `%s` = '%s' WHERE `steam_id` = '%s';", GetConfigValue("database prefix?"), text, text2, key);
		SQL_TQuery(hDatabase, QueryResults, tquery, client);
	}

	decl String:TagColour[64];
	decl String:TagName[64];
	decl String:ChatColour[64];
	GetArrayString(Handle:ChatSettings[client], 0, TagColour, sizeof(TagColour));
	GetArrayString(Handle:ChatSettings[client], 1, TagName, sizeof(TagName));
	GetArrayString(Handle:ChatSettings[client], 2, ChatColour, sizeof(ChatColour));

	Format(tquery, sizeof(tquery), "UPDATE `%s` SET `tcolour` = '%s', `tname` = '%s', `ccolour` = '%s' WHERE `steam_id` = '%s';", GetConfigValue("database prefix?"), TagColour, TagName, ChatColour, key);
	LogMessage(tquery);
	SQL_TQuery(hDatabase, QueryResults, tquery, client);

	LogMessage("Saving Data for %N where steamid: %s", client, key);
	bSaveData[client] = false;
}

stock SaveInfectedBotData() {
	
	if (hDatabase == INVALID_HANDLE || b_IsSavingInfectedBotData) return;
	decl String:key[64];
	decl String:tquery[1024];
	decl String:text[1024];
	decl String:text2[1024];
	new size = 0;
	if (StringToInt(GetConfigValue("director save priority?")) == 1) {

		b_IsSavingInfectedBotData = true;

		if (PlayerLevel_Bots >= 1) {

			Format(key, sizeof(key), "%s", GetConfigValue("director steam id?"));
			Format(tquery, sizeof(tquery), "UPDATE `%s` SET `strength` = '%d', `luck` = '%d', `agility` = '%d', `technique` = '%d', `endurance` = '%d', `experience` = '%d', `experience overall` = '%d', `upgrade cost` = '%d', `level` = '%d', `talent points` = '%d' WHERE `steam_id` = '%s';", GetConfigValue("database prefix?"), Strength_Bots, Luck_Bots, Agility_Bots, Technique_Bots, Endurance_Bots, ExperienceLevel_Bots, ExperienceOverall_Bots, PlayerLevelUpgrades_Bots, PlayerLevel_Bots, TotalTalentPoints_Bots, key);
			LogMessage("Saving Infected Bot Data: %s", tquery);
			SQL_TQuery(hDatabase, QueryResults, tquery, FindAnyRandomClient());

			size = GetArraySize(a_Database_Talents);
			for (new i = 0; i < size; i++) {

				GetArrayString(a_Database_Talents, i, text, sizeof(text));
				GetArrayString(a_Database_PlayerTalents_Bots, i, text2, sizeof(text2));
				Format(tquery, sizeof(tquery), "UPDATE `%s` SET `%s` = '%s' WHERE `steam_id` = '%s';", GetConfigValue("database prefix?"), text, text2, key);
				//LogMessage("Infected bot talent save: %s", tquery);
				SQL_TQuery(hDatabase, QueryResults, tquery, FindAnyRandomClient());
			}
			size				=	GetArraySize(a_DirectorActions);

			decl String:key_t[64];
			decl String:value_t[64];

			for (new i = 0; i < size; i++) {

				BotSaveKeys				=	GetArrayCell(a_DirectorActions, i, 0);
				BotSaveValues			=	GetArrayCell(a_DirectorActions, i, 1);
				BotSaveSection			=	GetArrayCell(a_DirectorActions, i, 2);

				GetArrayString(Handle:BotSaveSection, 0, text, sizeof(text));
				new size2		=	GetArraySize(BotSaveKeys);
				for (new ii = 0; ii < size2; ii++) {

					GetArrayString(Handle:BotSaveKeys, ii, key_t, sizeof(key_t));
					GetArrayString(Handle:BotSaveValues, ii, value_t, sizeof(value_t));

					if (StrEqual(key_t, "priority?")) {

						Format(tquery, sizeof(tquery), "UPDATE `%s` SET `%s` = '%d' WHERE `steam_id` = '%s';", GetConfigValue("database prefix?"), text, StringToInt(value_t), key);
						//LogMessage("Priority save: %s", tquery);
						SQL_TQuery(hDatabase, QueryResults, tquery, FindAnyRandomClient());
					}
				}
			}
			LogMessage("Saving Infected Bot Data.");
			
		} else {

			LogMessage("Cannot save data, Infected Bots Level is Less than 1");
		}

		b_IsSavingInfectedBotData = false;
	}
}

stock LoadDirectorActions() {

	if (hDatabase == INVALID_HANDLE) return;
	decl String:key[64];
	decl String:section_t[64];
	decl String:tquery[1024];
	Format(key, sizeof(key), "%s", GetConfigValue("director steam id?"));
	LoadPos_Director = 0;

	LoadDirectorSection					=	GetArrayCell(a_DirectorActions, LoadPos_Director, 2);
	GetArrayString(Handle:LoadDirectorSection, 0, section_t, sizeof(section_t));

	Format(tquery, sizeof(tquery), "SELECT `%s` FROM `%s` WHERE (`steam_id` = '%s');", section_t, GetConfigValue("database prefix?"), key);
	//LogMessage("Loading Director Priorities: %s", tquery);
	SQL_TQuery(hDatabase, QueryResults_LoadDirector, tquery, -1);
}

public QueryResults_LoadDirector(Handle:owner, Handle:hndl, const String:error[], any:client) {

	if (hndl != INVALID_HANDLE) {

		decl String:text[64];
		decl String:key[64];
		decl String:key_t[64];
		decl String:value_t[64];
		decl String:section_t[64];
		decl String:tquery[512];

		new bool:NoLoad						=	false;

		Format(key, sizeof(key), "%s", GetConfigValue("director steam id?"));

		while (SQL_FetchRow(hndl)) {

			SQL_FetchString(hndl, 0, text, sizeof(text));

			if (StrEqual(text, "0")) NoLoad = true;
			if (LoadPos_Director < GetArraySize(a_DirectorActions)) {

				QueryDirectorSection						=	GetArrayCell(a_DirectorActions, LoadPos_Director, 2);
				GetArrayString(Handle:QueryDirectorSection, 0, section_t, sizeof(section_t));

				QueryDirectorKeys							=	GetArrayCell(a_DirectorActions, LoadPos_Director, 0);
				QueryDirectorValues							=	GetArrayCell(a_DirectorActions, LoadPos_Director, 1);

				new size							=	GetArraySize(QueryDirectorKeys);

				for (new i = 0; i < size && !NoLoad; i++) {

					GetArrayString(Handle:QueryDirectorKeys, i, key_t, sizeof(key_t));
					GetArrayString(Handle:QueryDirectorValues, i, value_t, sizeof(value_t));

					if (StrEqual(key_t, "priority?")) {

						SetArrayString(Handle:QueryDirectorValues, i, text);
						SetArrayCell(Handle:a_DirectorActions, LoadPos_Director, QueryDirectorValues, 1);
						break;
					}
				}
				LoadPos_Director++;
				if (LoadPos_Director < GetArraySize(a_DirectorActions) && !NoLoad) {

					QueryDirectorSection						=	GetArrayCell(a_DirectorActions, LoadPos_Director, 2);
					GetArrayString(Handle:QueryDirectorSection, 0, section_t, sizeof(section_t));

					Format(tquery, sizeof(tquery), "SELECT `%s` FROM `%s` WHERE (`steam_id` = '%s');", section_t, GetConfigValue("database prefix?"), key);
					LogMessage("Loading Director Priorities: %s", tquery);
					SQL_TQuery(hDatabase, QueryResults_LoadDirector, tquery, -1);
				}
				else if (NoLoad) FirstUserDirectorPriority();
			}
		}
	}
}

stock FirstUserDirectorPriority() {

	new size						=	GetArraySize(a_Points);

	new sizer						=	0;

	decl String:s_key[64];
	decl String:s_value[64];

	for (new i = 0; i < size; i++) {

		FirstDirectorKeys						=	GetArrayCell(a_Points, i, 0);
		FirstDirectorValues						=	GetArrayCell(a_Points, i, 1);
		FirstDirectorSection					=	GetArrayCell(a_Points, i, 2);

		new size2					=	GetArraySize(FirstDirectorKeys);
		for (new ii = 0; ii < size2; ii++) {

			GetArrayString(Handle:FirstDirectorKeys, ii, s_key, sizeof(s_key));
			GetArrayString(Handle:FirstDirectorValues, ii, s_value, sizeof(s_value));

			if (StrEqual(s_key, "model?")) PrecacheModel(s_value, false);
			else if (StrEqual(s_key, "director option?") && StrEqual(s_value, "1")) {

				sizer				=	GetArraySize(a_DirectorActions);

				ResizeArray(a_DirectorActions, sizer + 1);
				SetArrayCell(a_DirectorActions, sizer, FirstDirectorKeys, 0);
				SetArrayCell(a_DirectorActions, sizer, FirstDirectorValues, 1);
				SetArrayCell(a_DirectorActions, sizer, FirstDirectorSection, 2);

				ResizeArray(a_DirectorActions_Cooldown, sizer + 1);
				SetArrayString(a_DirectorActions_Cooldown, sizer, "0");						// 0 means not on cooldown. 1 means on cooldown. This resets every map.
			}
		}
	}
}

stock FindClientWithAuthString(String:key[]) {

	decl String:AuthId[64];
	for (new i = 1; i <= MaxClients; i++) {

		if (IsClientInGame(i)) {

			GetClientAuthString(i, AuthId, sizeof(AuthId));
			if (StrEqual(key, AuthId)) return i;
		}
	}
	return -1;
}

stock bool:IsReserve(client) {

	if (HasCommandAccess(client, GetConfigValue("reserve player flags?"))) return true;
	return false;
}

stock bool:HasCommandAccess(client, String:accessflags[]) {

	decl String:flagpos[2];

	// We loop through the access flags passed to this function to see if the player has any of them and return the result.
	// This means flexibility for anything in RPG that allows custom flags, such as reserve player access or director menu access.
	for (new i = 0; i < strlen(accessflags); i++) {

		flagpos[0] = accessflags[i];
		flagpos[1] = 0;
		if (HasCommandAccessEx(client, flagpos)) return true;
	}
	// Old Method -> if (HasCommandAccess(client, "z") || HasCommandAccess(client, "a")) return true;
	return false;
}

public QueryResults_Load(Handle:owner, Handle:hndl, const String:error[], any:client)
{
	if ( hndl != INVALID_HANDLE )
	{
		decl String:key[64];
		decl String:text[64];
		new RestedTime		= 0;
		while (SQL_FetchRow(hndl))
		{
			SQL_FetchString(hndl, 0, key, sizeof(key));
			client = FindClientWithAuthString(key);
			if (!IsClientActual(client) || !IsClientInGame(client)) return;

			Strength[client]			=	SQL_FetchInt(hndl, 1);
			Luck[client]				=	SQL_FetchInt(hndl, 2);
			Agility[client]				=	SQL_FetchInt(hndl, 3);
			Technique[client]			=	SQL_FetchInt(hndl, 4);
			Endurance[client]			=	SQL_FetchInt(hndl, 5);
			ExperienceLevel[client]		=	SQL_FetchInt(hndl, 6);
			ExperienceOverall[client]	=	SQL_FetchInt(hndl, 7);
			PlayerLevelUpgrades[client]	=	SQL_FetchInt(hndl, 8);
			PlayerLevel[client]			=	SQL_FetchInt(hndl, 9);
			SkyPoints[client]			=	SQL_FetchInt(hndl, 10);
			TimePlayed[client]			=	SQL_FetchInt(hndl, 11);
			TotalTalentPoints[client]	=	SQL_FetchInt(hndl, 12);
			PlayerUpgradesTotal[client]	=	SQL_FetchInt(hndl, 13);
			FreeUpgrades[client]		=	SQL_FetchInt(hndl, 14);
			SlatePoints[client]			=	SQL_FetchInt(hndl, 15);
			HandicapLevel[client]		=	SQL_FetchInt(hndl, 16);
			RestedTime					=	SQL_FetchInt(hndl, 17);
			RestedExperience[client]	=	SQL_FetchInt(hndl, 18);
			LastPlayLength[client]		=	SQL_FetchInt(hndl, 19);
			resr[client]				=	SQL_FetchInt(hndl, 20);
			PreviousRoundIncaps[client]	=	SQL_FetchInt(hndl, 21);
			SQL_FetchString(hndl, 22, text, sizeof(text));
			SetArrayString(Handle:ChatSettings[client], 0, text);
			SQL_FetchString(hndl, 23, text, sizeof(text));
			SetArrayString(Handle:ChatSettings[client], 1, text);
			SQL_FetchString(hndl, 24, text, sizeof(text));
			SetArrayString(Handle:ChatSettings[client], 2, text);
			ExperienceDebt[client]		=	SQL_FetchInt(hndl, 25);
			UpgradesAvailable[client]	=	SQL_FetchInt(hndl, 26);
			UpgradesAwarded[client]		=	SQL_FetchInt(hndl, 27);
		}
		if (PlayerLevel[client] > 0) {

			/*

				"experience start?" can be modified at any time in the config.
				In order to properly adjust player levels, we use this to check.
			*/

			if (RestedTime > 0) {

				RestedTime					=	GetTime() - RestedTime;
				if (RestedTime > LastPlayLength[client]) RestedTime = LastPlayLength[client];

				while (RestedTime >= StringToInt(GetConfigValue("rested experience required seconds?"))) {

					RestedTime -= StringToInt(GetConfigValue("rested experience required seconds?"));
					if (IsReserve(client)) RestedExperience[client] += StringToInt(GetConfigValue("rested experience earned donator?"));
					else RestedExperience[client] += StringToInt(GetConfigValue("rested experience earned non-donator?"));
				}
				new RestedExperienceMaximum = StringToInt(GetConfigValue("rested experience maximum?"));
				if (RestedExperienceMaximum < 1) RestedExperienceMaximum = CheckExperienceRequirement(client);
				if (RestedExperience[client] > RestedExperienceMaximum) {

					RestedExperience[client] = RestedExperienceMaximum;
				}
			}
			if (resr[client] == 1) {

				resr[client] = 0;
				LastPlayLength[client] = 0;
			}
			if (HandicapLevel[client] <= 0) HandicapLevel[client] = -1;

			//if (HandicapLevel[client] <= 0 || HandicapLevel[client] > StringToInt(GetConfigValue("handicap breadth?"))) HandicapLevel[client] = -1;				// We disable the handicap level if one is not set.
			//if (HandicapLevel[client] != -1) CheckMaxAllowedHandicap(client);
			SetSpeedMultiplierBase(client);

			// Now load their talents. Because the database is modular; i.e. it loads and saves talents that are created modularly, we have to be sly about how we do this!
			LoadTalentTrees(client, key);
		}
		else {

			ResetData(client);
			CreateNewPlayer(client);
		}
		b_IsLoading[client] = false;
		CheckServerLevelRequirements(client);
		//if (!bFound && IsLegitimateClient(client)) {
	}
	else
	{
		SetFailState("Error: %s PREFIX IS: %s", error, GetConfigValue("database prefix?"));
		return;
	}
}

public QueryResults_LoadTalentTrees(Handle:owner, Handle:hndl, const String:error[], any:client) {

	if (hndl != INVALID_HANDLE) {

		decl String:text[512];
		decl String:tquery[512];

		while (SQL_FetchRow(hndl)) {

			decl String:key[64];
			SQL_FetchString(hndl, 0, key, sizeof(key));
			client = FindClientWithAuthString(key);
			if (!IsClientActual(client) || !IsClientInGame(client)) return;

			if (LoadPos[client] < GetArraySize(a_Database_Talents)) {

				SQL_FetchString(hndl, 1, text, sizeof(text));
				SetArrayString(a_Database_PlayerTalents[client], LoadPos[client], text);

				LoadPos[client]++;
				if (LoadPos[client] < GetArraySize(a_Database_Talents)) {

					GetArrayString(Handle:a_Database_Talents, LoadPos[client], text, sizeof(text));
					Format(tquery, sizeof(tquery), "SELECT `steam_id`, `%s` FROM `%s` WHERE (`steam_id` = '%s');", text, GetConfigValue("database prefix?"), key);
					SQL_TQuery(hDatabase, QueryResults_LoadTalentTrees, tquery, client);
				}
				else {

					b_IsLoadingTrees[client] = false;
					if (PlayerLevel[client] > 1) {

						new iLevel		= 1;

						new iExperienceOverall = ExperienceOverall[client];
						new iExperienceRequirement = CheckExperienceRequirement(client, false, iLevel);
						while (iExperienceOverall >= iExperienceRequirement) {

							iExperienceOverall -= iExperienceRequirement;
							iLevel++;
							iExperienceRequirement = CheckExperienceRequirement(client, false, iLevel);
						}
						if (iLevel != PlayerLevel[client]) {

							UpgradesAvailable[client] = 0;
							PlayerUpgradesTotal[client] = 0;
							PurchaseTalentPoints[client] = 0;

							ExperienceLevel[client] = iExperienceOverall;
							PlayerLevel[client] = iLevel;
							ChallengeEverything(client);
						}
					}
					LoadStoreData(client, key);
				}
			}
			else {

				b_IsLoadingTrees[client] = false;
				LoadStoreData(client, key);
			}
		}
	}
	else {
		
		SetFailState("Error: %s", error);
		return;
	}
}

public QueryResults_LoadTalentTreesBot(Handle:owner, Handle:hndl, const String:error[], any:client) {

	if (hndl != INVALID_HANDLE) {

		decl String:text[512];
		decl String:text2[512];
		decl String:tquery[512];
		decl String:key[64];
		Format(key, sizeof(key), "%s", GetConfigValue("director steam id?"));

		while (SQL_FetchRow(hndl)) {

			if (LoadPos_Bots < GetArraySize(a_Database_Talents)) {

				SQL_FetchString(hndl, 0, text, sizeof(text));
				SetArrayString(a_Database_PlayerTalents_Bots, LoadPos_Bots, text);
				GetArrayString(Handle:a_Database_Talents, LoadPos_Bots, text2, sizeof(text2));

				//LogMessage("LoadPos_Bots: %d (Size is %d) Talent: %s Value: %s", LoadPos_Bots, GetArraySize(a_Database_Talents), text2, text);
				LoadPos_Bots++;
				if (LoadPos_Bots < GetArraySize(a_Database_Talents)) {

					GetArrayString(Handle:a_Database_Talents, LoadPos_Bots, text, sizeof(text));
					Format(tquery, sizeof(tquery), "SELECT `%s` FROM `%s` WHERE (`steam_id` = '%s');", text, GetConfigValue("database prefix?"), key);
					//LogMessage("Loading bot talent tree: %s", tquery);
					SQL_TQuery(hDatabase, QueryResults_LoadTalentTreesBot, tquery, FindAnyRandomClient());
				}
				else b_IsLoadingInfectedBotData = false;
			}
			else b_IsLoadingInfectedBotData = false;
		}
	}
	else {
		
		SetFailState("Error: %s", error);
		return;
	}
}

stock LoadTalentTreesBot() {

	decl String:text[64];
	decl String:tquery[512];
	decl String:key[64];

	Format(key, sizeof(key), "%s", GetConfigValue("director steam id?"));
	LoadPos_Bots = 0;

	GetArrayString(Handle:a_Database_Talents, 0, text, sizeof(text));
	Format(tquery, sizeof(tquery), "SELECT `%s` FROM `%s` WHERE (`steam_id` = '%s');", text, GetConfigValue("database prefix?"), key);
	//LogMessage("Loading bot talent tree: %s", tquery);
	SQL_TQuery(hDatabase, QueryResults_LoadTalentTreesBot, tquery, FindAnyRandomClient());
}

stock LoadTalentTrees(client, String:key[]) {

	client = FindClientWithAuthString(key);
	if (!IsLegitimateClient(client)) return;

	decl String:text[64];
	decl String:tquery[512];
	//decl String:key[64];
	//GetClientAuthString(client, key, sizeof(key));

	b_IsLoadingTrees[client] = true;
	LoadPos[client] = 0;

	GetArrayString(Handle:a_Database_Talents, 0, text, sizeof(text));
	Format(tquery, sizeof(tquery), "SELECT `steam_id`, `%s` FROM `%s` WHERE (`steam_id` = '%s');", text, GetConfigValue("database prefix?"), key);
	SQL_TQuery(hDatabase, QueryResults_LoadTalentTrees, tquery, client);
}

stock LoadStoreData(client, String:key[]) {

	client = FindClientWithAuthString(key);
	if (!IsLegitimateClient(client)) return;

	if (GetArraySize(a_Store_Player[client]) != GetArraySize(a_Store)) ResizeArray(a_Store_Player[client], GetArraySize(a_Store));

	decl String:text[64];
	decl String:tquery[512];
	//decl String:key[64];
	//GetClientAuthString(client, key, sizeof(key));

	b_IsLoadingStore[client] = true;
	LoadPosStore[client] = 0;

	LoadStoreSection[client]		=	GetArrayCell(a_Store, 0, 2);
	GetArrayString(Handle:LoadStoreSection[client], 0, text, sizeof(text));
	Format(tquery, sizeof(tquery), "SELECT `steam_id`, `%s` FROM `%s` WHERE (`steam_id` = '%s');", text, GetConfigValue("database prefix?"), key);
	SQL_TQuery(hDatabase, QueryResults_LoadStoreData, tquery, client);
}

public QueryResults_LoadStoreData(Handle:owner, Handle:hndl, const String:error[], any:client) {

	if (hndl != INVALID_HANDLE) {

		decl String:text[512];
		decl String:tquery[512];

		while (SQL_FetchRow(hndl)) {

			decl String:key[64];
			SQL_FetchString(hndl, 0, key, sizeof(key));
			client = FindClientWithAuthString(key);
			if (!IsClientActual(client) || !IsClientInGame(client)) return;

			if (LoadPosStore[client] == 0) {

				for (new i = 0; i < GetArraySize(a_Store); i++) {

					SetArrayString(a_Store_Player[client], i, "0");
				}
			}

			if (LoadPosStore[client] < GetArraySize(a_Store)) {

				SQL_FetchString(hndl, 1, text, sizeof(text));
				SetArrayString(a_Store_Player[client], LoadPosStore[client], text);

				LoadPosStore[client]++;
				if (LoadPosStore[client] < GetArraySize(a_Store)) {

					LoadStoreSection[client]		=	GetArrayCell(a_Store, LoadPosStore[client], 2);
					GetArrayString(Handle:LoadStoreSection[client], 0, text, sizeof(text));
					Format(tquery, sizeof(tquery), "SELECT `steam_id`, `%s` FROM `%s` WHERE (`steam_id` = '%s');", text, GetConfigValue("database prefix?"), key);
					SQL_TQuery(hDatabase, QueryResults_LoadStoreData, tquery, client);
				}
				else {

					b_IsLoadingStore[client] = false;
				}
			}
			else {

				b_IsLoadingStore[client] = false;
			}
		}
	}
	else {
		
		SetFailState("Error: %s", error);
		return;
	}
}

/*stock TryLoadTalents(client, String:tquery[], String:key[]) {

	SQL_TQuery(hDatabase, QueryResults_Load, tquery, client);
}*/

public QueryResults_LoadBot(Handle:owner, Handle:hndl, const String:error[], any:client)
{
	if ( hndl != INVALID_HANDLE )
	{
		decl String:text[64];
		decl String:key[64];
		Format(key, sizeof(key), "%s", GetConfigValue("director steam id?"));
		while ( SQL_FetchRow(hndl) )
		{
			SQL_FetchString(hndl, 0, text, sizeof(text));
			Strength_Bots			=	StringToInt(text);
			SQL_FetchString(hndl, 1, text, sizeof(text));
			Luck_Bots				=	StringToInt(text);
			SQL_FetchString(hndl, 2, text, sizeof(text));
			Agility_Bots			=	StringToInt(text);
			SQL_FetchString(hndl, 3, text, sizeof(text));
			Technique_Bots			=	StringToInt(text);
			SQL_FetchString(hndl, 4, text, sizeof(text));
			Endurance_Bots			=	StringToInt(text);
			SQL_FetchString(hndl, 5, text, sizeof(text));
			ExperienceLevel_Bots	=	StringToInt(text);
			SQL_FetchString(hndl, 6, text, sizeof(text));
			ExperienceOverall_Bots	=	StringToInt(text);
			SQL_FetchString(hndl, 7, text, sizeof(text));
			PlayerLevelUpgrades_Bots	=	StringToInt(text);
			SQL_FetchString(hndl, 8, text, sizeof(text));
			PlayerLevel_Bots			=	StringToInt(text);
			//SQL_FetchString(hndl, 9, text, sizeof(text));
			//SkyPoints_Bots			=	StringToInt(text);
			SQL_FetchString(hndl, 9, text, sizeof(text));
			TotalTalentPoints_Bots	=	StringToInt(text);

			LogMessage("Infected Bot Data has loaded successfully. The Infected Bot Level is %d", PlayerLevel_Bots);

			//if (PlayerLevel_Bots == 0) CreateNewPlayer(-1, true);
			//else LoadTalentTreesBot();
		}
		if (PlayerLevel_Bots == 0) {

			LogMessage("Infected Bot Data could not be found, creating new data.");
			CreateNewInfectedBot();
			b_IsLoadingInfectedBotData = false;
		}
		else LoadTalentTreesBot();
	}
	else
	{
		SetFailState("Error: %s", error);
		return;
	}
}

public OnClientDisconnect(client)
{
	if (IsClientInGame(client) && !IsFakeClient(client) && b_IsArraysCreated[client]) {

		bIsMeleeCooldown[client] = false;
		b_IsInSaferoom[client] = false;
		b_IsArraysCreated[client] = false;
		ResetData(client);
		PlayerLevel[client] = 0;
		b_IsHooked[client] = false;
		SDKUnhook(client, SDKHook_OnTakeDamage, OnTakeDamage);
		//HandicapLevel[client] = -1;
	}
}

public ReadyUp_IsClientLoaded(client) {

	b_IsInSaferoom[client] = false;
	//b_ActiveThisRound[client] = false;
	PreviousRoundIncaps[client] = 1;
	Points[client] = 0.0;
	b_HasDeathLocation[client] = false;
	PlayerLevel[client] = 0;
	UpgradesAvailable[client] = 0;
	UpgradesAwarded[client] = 0;
	b_IsHooked[client] = false;
	if (!b_IsCheckpointDoorStartOpened) {

		bIsEligibleMapAward[client] = false;
		b_HandicapLocked[client] = false;
	}
	else {

		b_HandicapLocked[client] = true;
		bIsEligibleMapAward[client] = true;
	}
	CreateTimer(1.0, Timer_LoadData, client, TIMER_FLAG_NO_MAPCHANGE);
}