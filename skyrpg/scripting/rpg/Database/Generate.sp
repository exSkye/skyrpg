public void DBConnect(Handle owner, Handle hndl, const char[] error, any data)
{
	if (hndl == INVALID_HANDLE)
	{
		LogMessage("Unable to connect to database: %s", error);
		SetFailState("%s", error);
	}
	LogMessage("Connected to RPG Database!");

	hDatabase = hndl;

	int GenerateDB = GetConfigValueInt("generate database?");
	
	char tquery[PLATFORM_MAX_PATH];
	char text[64];
	
	if (GenerateDB == 1) {

		//Format(tquery, sizeof(tquery), "SET NAMES 'UTF8';");
		//SQL_TQuery(hDatabase, QueryResults, tquery);
		//Format(tquery, sizeof(tquery), "SET CHARACTER SET utf8;");
		//SQL_TQuery(hDatabase, QueryResults, tquery);

		//Format(tquery, sizeof(tquery), "CREATE TABLE IF NOT EXISTS `%s_maps` (`mapname` varchar(64) NOT NULL, PRIMARY KEY (`mapname`)) ENGINE=MyISAM;", TheDBPrefix);
		//SQL_TQuery(hDatabase, QueryResults, tquery);

		Format(tquery, sizeof(tquery), "CREATE TABLE IF NOT EXISTS `%s` (`steam_id` varchar(64) NOT NULL, PRIMARY KEY (`steam_id`)) ENGINE=InnoDB;", TheDBPrefix);
		SQL_TQuery(hDatabase, QueryResults, tquery);
		Format(tquery, sizeof(tquery), "ALTER TABLE `%s` CHARACTER SET utf8 COLLATE utf8_general_ci;", TheDBPrefix);
		SQL_TQuery(hDatabase, QueryResults, tquery);
		Format(tquery, sizeof(tquery), "ALTER TABLE `%s` ADD `primarywep` varchar(32) NOT NULL DEFAULT 'none';", TheDBPrefix);
		SQL_TQuery(hDatabase, QueryResults, tquery);
		Format(tquery, sizeof(tquery), "ALTER TABLE `%s` ADD `secondwep` varchar(32) NOT NULL DEFAULT 'none';", TheDBPrefix);
		SQL_TQuery(hDatabase, QueryResults, tquery);
		Format(tquery, sizeof(tquery), "ALTER TABLE `%s` ADD `exp` int(32) NOT NULL DEFAULT '0';", TheDBPrefix);
		SQL_TQuery(hDatabase, QueryResults, tquery);
		Format(tquery, sizeof(tquery), "ALTER TABLE `%s` ADD `expov` int(32) NOT NULL DEFAULT '0';", TheDBPrefix);
		SQL_TQuery(hDatabase, QueryResults, tquery);
		Format(tquery, sizeof(tquery), "ALTER TABLE `%s` ADD `upgrade cost` int(32) NOT NULL DEFAULT '0';", TheDBPrefix);
		SQL_TQuery(hDatabase, QueryResults, tquery);
		Format(tquery, sizeof(tquery), "ALTER TABLE `%s` ADD `level` int(32) NOT NULL DEFAULT '1';", TheDBPrefix);
		SQL_TQuery(hDatabase, QueryResults, tquery);
		Format(tquery, sizeof(tquery), "ALTER TABLE `%s` ADD `skylevel` int(32) NOT NULL DEFAULT '0';", TheDBPrefix);
		SQL_TQuery(hDatabase, QueryResults, tquery);
		Format(tquery, sizeof(tquery), "ALTER TABLE `%s` ADD `augmentparts` int(32) NOT NULL DEFAULT '0';", TheDBPrefix);
		SQL_TQuery(hDatabase, QueryResults, tquery);
		Format(tquery, sizeof(tquery), "ALTER TABLE `%s` ADD `dismantlescore` int(32) NOT NULL DEFAULT '0';", TheDBPrefix);
		SQL_TQuery(hDatabase, QueryResults, tquery);
		Format(tquery, sizeof(tquery), "ALTER TABLE `%s` ADD `dismantleminor` int(4) NOT NULL DEFAULT '0';", TheDBPrefix);
		SQL_TQuery(hDatabase, QueryResults, tquery);

		GetConfigValue(text, sizeof(text), "sky points menu name?");
		Format(tquery, sizeof(tquery), "ALTER TABLE `%s` ADD `%s` int(32) NOT NULL DEFAULT '0';", TheDBPrefix, text);
		SQL_TQuery(hDatabase, QueryResults, tquery);
		Format(tquery, sizeof(tquery), "ALTER TABLE `%s` ADD `time played` int(32) NOT NULL DEFAULT '0';", TheDBPrefix);
		SQL_TQuery(hDatabase, QueryResults, tquery);
		Format(tquery, sizeof(tquery), "ALTER TABLE `%s` ADD `talent points` int(32) NOT NULL DEFAULT '0';", TheDBPrefix);
		SQL_TQuery(hDatabase, QueryResults, tquery);
		Format(tquery, sizeof(tquery), "ALTER TABLE `%s` ADD `total upgrades` int(32) NOT NULL DEFAULT '0';", TheDBPrefix);
		SQL_TQuery(hDatabase, QueryResults, tquery);
		Format(tquery, sizeof(tquery), "ALTER TABLE `%s` ADD `free upgrades` int(32) NOT NULL DEFAULT '0';", TheDBPrefix);
		SQL_TQuery(hDatabase, QueryResults, tquery);
		Format(tquery, sizeof(tquery), "ALTER TABLE `%s` ADD `restt` int(32) NOT NULL DEFAULT '0';", TheDBPrefix);
		SQL_TQuery(hDatabase, QueryResults, tquery);
		Format(tquery, sizeof(tquery), "ALTER TABLE `%s` ADD `restexp` int(32) NOT NULL DEFAULT '0';", TheDBPrefix);
		SQL_TQuery(hDatabase, QueryResults, tquery);
		Format(tquery, sizeof(tquery), "ALTER TABLE `%s` ADD `lpl` int(32) NOT NULL DEFAULT '0';", TheDBPrefix);
		SQL_TQuery(hDatabase, QueryResults, tquery);
		Format(tquery, sizeof(tquery), "ALTER TABLE `%s` ADD `resr` int(32) NOT NULL DEFAULT '0';", TheDBPrefix);
		SQL_TQuery(hDatabase, QueryResults, tquery);
		Format(tquery, sizeof(tquery), "ALTER TABLE `%s` ADD `dals` int(32) NOT NULL DEFAULT '0';", TheDBPrefix);
		SQL_TQuery(hDatabase, QueryResults, tquery);
		Format(tquery, sizeof(tquery), "ALTER TABLE `%s` ADD `lootprio` int(32) NOT NULL DEFAULT '0';", TheDBPrefix);
		SQL_TQuery(hDatabase, QueryResults, tquery);
		Format(tquery, sizeof(tquery), "ALTER TABLE `%s` ADD `survpoints` varchar(32) NOT NULL DEFAULT '0.0';", TheDBPrefix);
		SQL_TQuery(hDatabase, QueryResults, tquery);
		Format(tquery, sizeof(tquery), "ALTER TABLE `%s` ADD `bec` int(32) NOT NULL DEFAULT '0';", TheDBPrefix);
		SQL_TQuery(hDatabase, QueryResults, tquery);
		Format(tquery, sizeof(tquery), "ALTER TABLE `%s` ADD `rem` varchar(32) NOT NULL DEFAULT '0.0';", TheDBPrefix);
		SQL_TQuery(hDatabase, QueryResults, tquery);
		Format(tquery, sizeof(tquery), "ALTER TABLE `%s` ADD `%s` int(32) NOT NULL DEFAULT '0';", TheDBPrefix, COOPRECORD_DB);
		SQL_TQuery(hDatabase, QueryResults, tquery);
		Format(tquery, sizeof(tquery), "ALTER TABLE `%s` ADD `%s` int(32) NOT NULL DEFAULT '0';", TheDBPrefix, SURVRECORD_DB);
		SQL_TQuery(hDatabase, QueryResults, tquery);
		GetConfigValue(text, sizeof(text), "db record?");
		if (!StrEqual(text, "-1")) {

			Format(tquery, sizeof(tquery), "ALTER TABLE `%s` ADD `%s` int(32) NOT NULL DEFAULT '0';", TheDBPrefix, text);
			SQL_TQuery(hDatabase, QueryResults, tquery);
		}
		Format(tquery, sizeof(tquery), "ALTER TABLE `%s` ADD `myrating %s` int(32) NOT NULL DEFAULT '0';", TheDBPrefix, RatingType);
		SQL_TQuery(hDatabase, QueryResults, tquery);
		Format(tquery, sizeof(tquery), "ALTER TABLE `%s` ADD `handicaplevel %s` int(32) NOT NULL DEFAULT '0';", TheDBPrefix, RatingType);
		SQL_TQuery(hDatabase, QueryResults, tquery);
		Format(tquery, sizeof(tquery), "ALTER TABLE `%s` ADD `pri` int(32) NOT NULL DEFAULT '1';", TheDBPrefix);
		SQL_TQuery(hDatabase, QueryResults, tquery);
		Format(tquery, sizeof(tquery), "ALTER TABLE `%s` ADD `tname` varchar(32) NOT NULL DEFAULT 'none';", TheDBPrefix);
		SQL_TQuery(hDatabase, QueryResults, tquery);
		//Format(tquery, sizeof(tquery), "ALTER TABLE `%s` ADD `mapname` varchar(32) NOT NULL DEFAULT 'none';", TheDBPrefix);
		//SQL_TQuery(hDatabase, QueryResults, tquery);

		Format(tquery, sizeof(tquery), "ALTER TABLE `%s` ADD `xpdebt` int(32) NOT NULL DEFAULT '0';", TheDBPrefix);
		SQL_TQuery(hDatabase, QueryResults, tquery);
		Format(tquery, sizeof(tquery), "ALTER TABLE `%s` ADD `upav` int(32) NOT NULL DEFAULT '0';", TheDBPrefix);
		SQL_TQuery(hDatabase, QueryResults, tquery);
		Format(tquery, sizeof(tquery), "ALTER TABLE `%s` ADD `upawarded` int(32) NOT NULL DEFAULT '0';", TheDBPrefix);
		SQL_TQuery(hDatabase, QueryResults, tquery);

		Format(tquery, sizeof(tquery), "ALTER TABLE `%s` ADD `companionname` varchar(32) NOT NULL DEFAULT 'survivor';", TheDBPrefix);
		SQL_TQuery(hDatabase, QueryResults, tquery);
		Format(tquery, sizeof(tquery), "ALTER TABLE `%s` ADD `companionowner` varchar(32) NOT NULL DEFAULT 'survivor';", TheDBPrefix);
		SQL_TQuery(hDatabase, QueryResults, tquery);

		Format(tquery, sizeof(tquery), "ALTER TABLE `%s` ADD `lastserver` varchar(64) NOT NULL DEFAULT 'none';", TheDBPrefix);
		SQL_TQuery(hDatabase, QueryResults, tquery);
		Format(tquery, sizeof(tquery), "ALTER TABLE `%s` ADD `myseason` varchar(32) NOT NULL DEFAULT 'none';", TheDBPrefix);
		SQL_TQuery(hDatabase, QueryResults, tquery);

		Format(tquery, sizeof(tquery), "ALTER TABLE `%s` ADD `lvlpaused` int(32) NOT NULL DEFAULT '0';", TheDBPrefix);
		SQL_TQuery(hDatabase, QueryResults, tquery);
		Format(tquery, sizeof(tquery), "ALTER TABLE `%s` ADD `itrails` int(32) NOT NULL DEFAULT '0';", TheDBPrefix);
		SQL_TQuery(hDatabase, QueryResults, tquery);

		/*
			weapon levels
			\\rewarding players who use a specific weapon category with increased proficiency in that category.
		*/
		Format(tquery, sizeof(tquery), "ALTER TABLE `%s` ADD `pistol_xp` int(32) NOT NULL DEFAULT '0';", TheDBPrefix);
		SQL_TQuery(hDatabase, QueryResults, tquery);
		Format(tquery, sizeof(tquery), "ALTER TABLE `%s` ADD `melee_xp` int(32) NOT NULL DEFAULT '0';", TheDBPrefix);
		SQL_TQuery(hDatabase, QueryResults, tquery);
		Format(tquery, sizeof(tquery), "ALTER TABLE `%s` ADD `uzi_xp` int(32) NOT NULL DEFAULT '0';", TheDBPrefix);
		SQL_TQuery(hDatabase, QueryResults, tquery);
		/*
			has both pump and auto shotgun tiers
		*/
		Format(tquery, sizeof(tquery), "ALTER TABLE `%s` ADD `shotgun_xp` int(32) NOT NULL DEFAULT '0';", TheDBPrefix);
		SQL_TQuery(hDatabase, QueryResults, tquery);
		Format(tquery, sizeof(tquery), "ALTER TABLE `%s` ADD `sniper_xp` int(32) NOT NULL DEFAULT '0';", TheDBPrefix);
		SQL_TQuery(hDatabase, QueryResults, tquery);
		Format(tquery, sizeof(tquery), "ALTER TABLE `%s` ADD `assault_xp` int(32) NOT NULL DEFAULT '0';", TheDBPrefix);
		SQL_TQuery(hDatabase, QueryResults, tquery);

		Format(tquery, sizeof(tquery), "ALTER TABLE `%s` ADD `medic_xp` int(32) NOT NULL DEFAULT '0';", TheDBPrefix);
		SQL_TQuery(hDatabase, QueryResults, tquery);
		Format(tquery, sizeof(tquery), "ALTER TABLE `%s` ADD `grenade_xp` int(32) NOT NULL DEFAULT '0';", TheDBPrefix);
		SQL_TQuery(hDatabase, QueryResults, tquery);

		Format(tquery, sizeof(tquery), "ALTER TABLE `%s` ADD `con` int(32) NOT NULL DEFAULT '0';", TheDBPrefix);
		SQL_TQuery(hDatabase, QueryResults, tquery);
		Format(tquery, sizeof(tquery), "ALTER TABLE `%s` ADD `agi` int(32) NOT NULL DEFAULT '0';", TheDBPrefix);
		SQL_TQuery(hDatabase, QueryResults, tquery);
		Format(tquery, sizeof(tquery), "ALTER TABLE `%s` ADD `res` int(32) NOT NULL DEFAULT '0';", TheDBPrefix);
		SQL_TQuery(hDatabase, QueryResults, tquery);
		Format(tquery, sizeof(tquery), "ALTER TABLE `%s` ADD `tec` int(32) NOT NULL DEFAULT '0';", TheDBPrefix);
		SQL_TQuery(hDatabase, QueryResults, tquery);
		Format(tquery, sizeof(tquery), "ALTER TABLE `%s` ADD `end` int(32) NOT NULL DEFAULT '0';", TheDBPrefix);
		SQL_TQuery(hDatabase, QueryResults, tquery);
		Format(tquery, sizeof(tquery), "ALTER TABLE `%s` ADD `luc` int(32) NOT NULL DEFAULT '0';", TheDBPrefix);
		SQL_TQuery(hDatabase, QueryResults, tquery);


		Format(tquery, sizeof(tquery), "CREATE TABLE IF NOT EXISTS `%s_loot` (`itemid` varchar(64) NOT NULL, PRIMARY KEY (`itemid`)) ENGINE=InnoDB;", TheDBPrefix);
		SQL_TQuery(hDatabase, QueryResults, tquery);
		Format(tquery, sizeof(tquery), "ALTER TABLE `%s_loot` CHARACTER SET utf8 COLLATE utf8_general_ci;", TheDBPrefix);
		SQL_TQuery(hDatabase, QueryResults, tquery);
		Format(tquery, sizeof(tquery), "ALTER TABLE `%s_loot` ADD `steam_id` varchar(32) NOT NULL DEFAULT '0';", TheDBPrefix);
		SQL_TQuery(hDatabase, QueryResults, tquery);
		Format(tquery, sizeof(tquery), "ALTER TABLE `%s_loot` ADD `firstowner` varchar(32) NOT NULL DEFAULT 'none';", TheDBPrefix);
		SQL_TQuery(hDatabase, QueryResults, tquery);
		Format(tquery, sizeof(tquery), "ALTER TABLE `%s_loot` ADD `firstownername` varchar(32) NOT NULL DEFAULT 'none';", TheDBPrefix);
		SQL_TQuery(hDatabase, QueryResults, tquery);
		Format(tquery, sizeof(tquery), "ALTER TABLE `%s_loot` ADD `rating` int(32) NOT NULL DEFAULT '1';", TheDBPrefix);
		SQL_TQuery(hDatabase, QueryResults, tquery);
		Format(tquery, sizeof(tquery), "ALTER TABLE `%s_loot` ADD `category` varchar(32) NOT NULL DEFAULT '0';", TheDBPrefix);
		SQL_TQuery(hDatabase, QueryResults, tquery);
		Format(tquery, sizeof(tquery), "ALTER TABLE `%s_loot` ADD `price` int(32) NOT NULL DEFAULT '0';", TheDBPrefix);
		SQL_TQuery(hDatabase, QueryResults, tquery);
		Format(tquery, sizeof(tquery), "ALTER TABLE `%s_loot` ADD `isforsale` int(4) NOT NULL DEFAULT '0';", TheDBPrefix);
		SQL_TQuery(hDatabase, QueryResults, tquery);
		Format(tquery, sizeof(tquery), "ALTER TABLE `%s_loot` ADD `isequipped` int(4) NOT NULL DEFAULT '-1';", TheDBPrefix);
		SQL_TQuery(hDatabase, QueryResults, tquery);
		Format(tquery, sizeof(tquery), "ALTER TABLE `%s_loot` ADD `acteffects` varchar(32) NOT NULL DEFAULT 'none';", TheDBPrefix);
		SQL_TQuery(hDatabase, QueryResults, tquery);
		Format(tquery, sizeof(tquery), "ALTER TABLE `%s_loot` ADD `actrating` int(32) NOT NULL DEFAULT '-1';", TheDBPrefix);
		SQL_TQuery(hDatabase, QueryResults, tquery);
		Format(tquery, sizeof(tquery), "ALTER TABLE `%s_loot` ADD `tareffects` varchar(32) NOT NULL DEFAULT 'none';", TheDBPrefix);
		SQL_TQuery(hDatabase, QueryResults, tquery);
		Format(tquery, sizeof(tquery), "ALTER TABLE `%s_loot` ADD `tarrating` int(32) NOT NULL DEFAULT '-1';", TheDBPrefix);
		SQL_TQuery(hDatabase, QueryResults, tquery);
		Format(tquery, sizeof(tquery), "ALTER TABLE `%s_loot` ADD `maxscoreroll` int(32) NOT NULL DEFAULT '0';", TheDBPrefix);
		SQL_TQuery(hDatabase, QueryResults, tquery);
		Format(tquery, sizeof(tquery), "ALTER TABLE `%s_loot` ADD `maxactroll` int(32) NOT NULL DEFAULT '0';", TheDBPrefix);
		SQL_TQuery(hDatabase, QueryResults, tquery);
		Format(tquery, sizeof(tquery), "ALTER TABLE `%s_loot` ADD `maxtarroll` int(32) NOT NULL DEFAULT '0';", TheDBPrefix);
		SQL_TQuery(hDatabase, QueryResults, tquery);

		Format(tquery, sizeof(tquery), "CREATE TABLE IF NOT EXISTS `%s_profiles` (`steam_id` varchar(128) NOT NULL, PRIMARY KEY (`steam_id`)) ENGINE=InnoDB;", TheDBPrefix);
		SQL_TQuery(hDatabase, QueryResults, tquery);
		Format(tquery, sizeof(tquery), "ALTER TABLE `%s_profiles` CHARACTER SET utf8 COLLATE utf8_general_ci;", TheDBPrefix);
		SQL_TQuery(hDatabase, QueryResults, tquery);
		
		int counter = iActionBarSlots;
		for (int i = 0; i < counter; i++) {
			Format(tquery, sizeof(tquery), "ALTER TABLE `%s` ADD `aslot%d` VARCHAR(32) NOT NULL DEFAULT 'None';", TheDBPrefix, i+1);
			SQL_TQuery(hDatabase, QueryResults, tquery);
			Format(tquery, sizeof(tquery), "ALTER TABLE `%s_profiles` ADD `aslot%d` VARCHAR(32) NOT NULL DEFAULT 'None';", TheDBPrefix, i+1);
			SQL_TQuery(hDatabase, QueryResults, tquery);
		}
		Format(tquery, sizeof(tquery), "ALTER TABLE `%s` ADD `disab` INT(4) NOT NULL DEFAULT '0';", TheDBPrefix);
		SQL_TQuery(hDatabase, QueryResults, tquery);
		Format(tquery, sizeof(tquery), "ALTER TABLE `%s_profiles` ADD `disab` INT(4) NOT NULL DEFAULT '0';", TheDBPrefix);
		SQL_TQuery(hDatabase, QueryResults, tquery);

		
		
		Format(tquery, sizeof(tquery), "ALTER TABLE `%s_profiles` ADD `primarywep` varchar(32) NOT NULL DEFAULT 'none';", TheDBPrefix);
		SQL_TQuery(hDatabase, QueryResults, tquery);
		Format(tquery, sizeof(tquery), "ALTER TABLE `%s_profiles` ADD `secondwep` varchar(32) NOT NULL DEFAULT 'none';", TheDBPrefix);
		SQL_TQuery(hDatabase, QueryResults, tquery);
		Format(tquery, sizeof(tquery), "ALTER TABLE `%s_profiles` ADD `talent points` int(32) NOT NULL DEFAULT '0';", TheDBPrefix);
		SQL_TQuery(hDatabase, QueryResults, tquery);
		Format(tquery, sizeof(tquery), "ALTER TABLE `%s_profiles` ADD `total upgrades` int(32) NOT NULL DEFAULT '0';", TheDBPrefix);
		SQL_TQuery(hDatabase, QueryResults, tquery);
		Format(tquery, sizeof(tquery), "ALTER TABLE `%s_profiles` ADD `free upgrades` int(32) NOT NULL DEFAULT '0';", TheDBPrefix);
		SQL_TQuery(hDatabase, QueryResults, tquery);
		for (int i = 0; i < iNumAugments; i++) {
			Format(tquery, sizeof(tquery), "ALTER TABLE `%s_profiles` ADD `augment%d` varchar(32) NOT NULL DEFAULT 'none';", TheDBPrefix, i+1);
			SQL_TQuery(hDatabase, QueryResults, tquery);
		}

		Format(tquery, sizeof(tquery), "CREATE TABLE IF NOT EXISTS `%s_mail` (`steam_id` varchar(64) NOT NULL, PRIMARY KEY (`steam_id`)) ENGINE=InnoDB;", TheDBPrefix);
		SQL_TQuery(hDatabase, QueryResults, tquery);
		Format(tquery, sizeof(tquery), "ALTER TABLE `%s_mail` CHARACTER SET utf8 COLLATE utf8_general_ci;", TheDBPrefix);
		SQL_TQuery(hDatabase, QueryResults, tquery);
		Format(tquery, sizeof(tquery), "ALTER TABLE `%s_mail` ADD `message` varchar(64) NOT NULL DEFAULT 'none';", TheDBPrefix);
		SQL_TQuery(hDatabase, QueryResults, tquery);
		Format(tquery, sizeof(tquery), "ALTER TABLE `%s_mail` ADD `currency` varchar(32) NOT NULL DEFAULT 'none';", TheDBPrefix);
		SQL_TQuery(hDatabase, QueryResults, tquery);
		Format(tquery, sizeof(tquery), "ALTER TABLE `%s_mail` ADD `expiration` int(32) NOT NULL DEFAULT '-1';", TheDBPrefix);

		/*new size			=	GetArraySize(a_Database_Talents);

		for (new i = 0; i < size; i++) {

			GetArrayString(Handle:a_Database_Talents, i, text, sizeof(text));
			Format(tquery, sizeof(tquery), "ALTER TABLE `%s` ADD `%s` int(32) NOT NULL DEFAULT '0';", TheDBPrefix, text);
			SQL_TQuery(hDatabase, QueryResults, tquery);
		}*/
	}

	ClearArray(a_Database_Talents_Defaults);
	ClearArray(a_Database_Talents_Defaults_Name);
	//ClearArray(Handle:a_ClassNames);

	char NewValue[64];

	int size			=	GetArraySize(a_Menu_Talents);
	for (int i = 0; i < size; i++) {

		DatabaseKeys			=	GetArrayCell(a_Menu_Talents, i, 0);
		DatabaseValues			=	GetArrayCell(a_Menu_Talents, i, 1);
		if (GetArrayCell(DatabaseValues, IS_SUB_MENU_OF_TALENTCONFIG) == 1) continue;

		DatabaseSection			=	GetArrayCell(a_Menu_Talents, i, 2);

		GetArrayString(DatabaseSection, 0, text, sizeof(text));
		PushArrayString(a_Database_Talents_Defaults_Name, text);
		if (GenerateDB == 1) {

			Format(tquery, sizeof(tquery), "ALTER TABLE `%s` ADD `%s` int(32) NOT NULL DEFAULT '0';", TheDBPrefix, text);
			SQL_TQuery(hDatabase, QueryResults, tquery);
			Format(tquery, sizeof(tquery), "ALTER TABLE `%s_profiles` ADD `%s` int(32) NOT NULL DEFAULT '0';", TheDBPrefix, text);
			SQL_TQuery(hDatabase, QueryResults, tquery);
		}

		//if (StringToInt(NewValue) < 0) Format(NewValue, sizeof(NewValue), "0");
		PushArrayString(a_Database_Talents_Defaults, NewValue);
	}

	if (GenerateDB == 1) {

		GenerateDB = 0;

		size				=	GetArraySize(a_DirectorActions);

		for (int i = 0; i < size; i++) {

			DatabaseSection			=	GetArrayCell(a_DirectorActions, i, 2);
			GetArrayString(DatabaseSection, 0, text, sizeof(text));
			Format(tquery, sizeof(tquery), "ALTER TABLE `%s` ADD `%s` int(32) NOT NULL DEFAULT '0';", TheDBPrefix, text);
			SQL_TQuery(hDatabase, QueryResults, tquery);
		}

		size				=	GetArraySize(a_Store);

		for (int i = 0; i < size; i++) {

			DatabaseSection			=	GetArrayCell(a_Store, i, 2);
			GetArrayString(DatabaseSection, 0, text, sizeof(text));
			Format(tquery, sizeof(tquery), "ALTER TABLE `%s` ADD `%s` int(32) NOT NULL DEFAULT '0';", TheDBPrefix, text);
			SQL_TQuery(hDatabase, QueryResults, tquery);
		}
	}

	size = GetArraySize(a_Database_Talents);

	ResizeArray(a_Database_PlayerTalents_Bots, size);
	ResizeArray(PlayerAbilitiesCooldown_Bots, size);
	ResizeArray(PlayerAbilitiesImmune_Bots, size);

	GetNodesInExistence();
}