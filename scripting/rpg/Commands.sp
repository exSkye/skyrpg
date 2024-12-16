public Action CMD_BuyMenu(client, args) {
	if (iRPGMode < 0 || iRPGMode == 1 && b_IsActiveRound) return Plugin_Handled;
	BuildPointsMenu(client, "Buy Menu", "rpg/points.cfg");
	return Plugin_Handled;
}

public Action Cmd_debugrpg(client, args) {
	if (bIsDebugEnabled) {
		PrintToChatAll("\x04rpg debug disabled");
		bIsDebugEnabled = false;
	}
	else {
		PrintToChatAll("\x03rpg debug enabled");
		bIsDebugEnabled = true;
	}
	return Plugin_Handled;
}

public Action Cmd_ResetTPL(client, args) { PlayerLevelUpgrades[client] = 0; return Plugin_Handled; }

public Action CMD_TeamChatCommand(client, args) {
	if (QuickCommandAccess(client, args, true)) {

		// Set colors for chat
		if (ChatTrigger(client, args, true)) return Plugin_Continue;
		else return Plugin_Handled;
	}
	return Plugin_Handled;
}

public Action CMD_ChatCommand(client, args) {
	if (QuickCommandAccess(client, args, false)) {

		// Set Colors for chat
		if (ChatTrigger(client, args, false)) return Plugin_Continue;
		else return Plugin_Handled;
	}
	return Plugin_Handled;
}

public Action CMD_FireSword(client, args) {
	char Weapon[64];
	int g_iActiveWeaponOffset = 0;
	int iWeapon = 0;
	for (int i = 1; i <= MaxClients; i++) {
		if (!IsLegitimateClientAlive(i) || myCurrentTeam[i] != TEAM_SURVIVOR) continue;
		GetClientWeapon(i, Weapon, sizeof(Weapon));
		if (StrEqual(Weapon, "weapon_melee", false)) {
			g_iActiveWeaponOffset = FindSendPropInfo("CTerrorPlayer", "m_hActiveWeapon");
			iWeapon = GetEntDataEnt2(client, g_iActiveWeaponOffset);
		}
		else {
			if (StrContains(Weapon, "pistol", false) == -1) iWeapon = GetPlayerWeaponSlot(client, 0);
			else iWeapon = GetPlayerWeaponSlot(client, 1);
		}
		if (IsValidEntity(iWeapon)) {
			ExtinguishEntity(iWeapon);
			IgniteEntity(iWeapon, 30.0);
		}
	}
	return Plugin_Handled;
}

public Action CMD_LoadoutName(client, args) {

	if (args < 1) {

		PrintToChat(client, "!loadoutname <name identifier>");
		return Plugin_Handled;
	}
	GetCmdArg(1, LoadoutName[client], sizeof(LoadoutName[]));
	if (strlen(LoadoutName[client]) < 3 || strlen(LoadoutName[client]) > 20) {
		Format(LoadoutName[client], 64, "none");
		PrintToChat(client, "loadout name must be >= 3 && <= 20 characters long.");
		return Plugin_Handled;
	}
	if (StrContains(LoadoutName[client], "SavedProfile", false) != -1) {

		PrintToChat(client, "invalid loadout name, try again.");
		return Plugin_Handled;
	}
	ReplaceString(LoadoutName[client], sizeof(LoadoutName[]), "+", " ");	// this way the delimiter only shows where it's supposed to.
	SQL_EscapeString(hDatabase, LoadoutName[client], LoadoutName[client], sizeof(LoadoutName[]));
	Format(LoadoutName[client], sizeof(LoadoutName[]), "%s", LoadoutName[client]);
	PrintToChat(client, "%T", "loadout name set", client, orange, green, LoadoutName[client]);
	return Plugin_Handled;
}

public Action CMD_DataErase(client, args) {
	char arg[MAX_NAME_LENGTH];
	if (args > 0 && HasCommandAccess(client, sDeleteBotFlags)) {
		GetCmdArg(1, arg, sizeof(arg));
		int targetclient = FindTargetClient(client, arg);
		if (IsLegitimateClient(targetclient) && myCurrentTeam[targetclient] != TEAM_INFECTED) DeleteAndCreateNewData(targetclient);
	}
	else DeleteAndCreateNewData(client);
	return Plugin_Handled;
}

public Action CMD_DataEraseBot(client, args) {
	DeleteAndCreateNewData(client, true);
	return Plugin_Handled;
}

stock DeleteAndCreateNewData(client, bool IsBot = false) {
	char key[64];
	char tquery[1024];
	char pct[4];
	Format(pct, sizeof(pct), "%");
	if (!IsBot) {
		GetClientAuthId(client, AuthId_Steam2, key, sizeof(key));
		if (!StrEqual(serverKey, "-1")) Format(key, sizeof(key), "%s%s", serverKey, key);

		Format(tquery, sizeof(tquery), "DELETE FROM `%s` WHERE `steam_id` = '%s';", TheDBPrefix, key);
		SQL_TQuery(hDatabase, QueryResults, tquery, client);

		Format(tquery, sizeof(tquery), "DELETE FROM `%s_loot` WHERE `steam_id` = '%s';", TheDBPrefix, key);
		SQL_TQuery(hDatabase, QueryResults, tquery, client);

		int oldSkyPoints = SkyPoints[client];
		ResetData(client);
		CreateNewPlayerEx(client);
		SkyPoints[client] = oldSkyPoints;

		PrintToChat(client, "data erased, new data created.");	// not bothering with a translation here, since it's a debugging command.
	}
	else {
		if (HasCommandAccess(client, sDeleteBotFlags)) {
			for (int i = 1; i <= MaxClients; i++) {
				if (IsLegitimateClient(i) && IsFakeClient(i)) KickClient(i);
			}
			Format(tquery, sizeof(tquery), "DELETE FROM `%s` WHERE `steam_id` LIKE '%s%s%s';", TheDBPrefix, pct, sBotTeam, pct);
			SQL_TQuery(hDatabase, QueryResults, tquery, client);

			PrintToChatAll("%t", "bot data deleted", orange, blue);
		}
	}
}

public Action CMD_DirectorTalentToggle(client, args) {
	char thetext[64];
	GetConfigValue(thetext, sizeof(thetext), "director talent flags?");

	if (HasCommandAccess(client, thetext)) {
		if (b_IsDirectorTalents[client]) {
			b_IsDirectorTalents[client]			= false;
			PrintToChat(client, "%T", "Director Talents Disabled", client, white, green);
		}
		else {

			b_IsDirectorTalents[client]			= true;
			PrintToChat(client, "%T", "Director Talents Enabled", client, white, green);
		}
	}
	return Plugin_Handled;
}

public Action CMD_AutoDismantle(client, args) {
	int lootFindBonus = 0;
	if (GetArraySize(HandicapSelectedValues[client]) < 1) return Plugin_Handled;
	if (handicapLevel[client] > 0) lootFindBonus = GetArrayCell(HandicapSelectedValues[client], 2);
	if (args < 1) {
		PrintToChat(client, "\x04!autodismantle <score>\n\x03gear that roll under %d score will be auto-dismantled. \x04limit: \x03%d", iplayerSettingAutoDismantleScore[client], BestRating[client] + lootFindBonus);
		PrintToChat(client, "\x04!autodismantle clear/perfect/major/minor - \x03Deletes \x04all/perfect/major/minor gear \x03not equipped or favourited.");
		return Plugin_Handled;
	}

	char arg[64];
	GetCmdArg(1, arg, 64);
	char key[64];
	char tquery[512];
	int size = 0;
	int refunded = 0;
	char effects[64];
	int isEquipped = 0;
	int result = (StrEqual(arg, "clear")) ? 1 : (StrEqual(arg, "minor")) ? 2 : (StrEqual(arg, "major")) ? 3 : (StrEqual(arg, "perfect")) ? 4 : 0;
	if (b_IsActiveRound && result > 0) result = -1;
	if (result == 1) {
		GetClientAuthId(client, AuthId_Steam2, key, sizeof(key));
		if (!StrEqual(serverKey, "-1")) Format(key, sizeof(key), "%s%s", serverKey, key);
		Format(tquery, sizeof(tquery), "DELETE FROM `%s_loot` WHERE `isequipped` = '-1' AND `steam_id` = '%s';", TheDBPrefix, key);
		SQL_TQuery(hDatabase, QueryResults, tquery, client);

		size = GetArraySize(myAugmentInfo[client]);
		for (int i = size-1; i >= 0; i--) {
			isEquipped = GetArrayCell(myAugmentInfo[client], i, 3);
			if (isEquipped != -1) continue;

			RemoveFromArray(myAugmentIDCodes[client], i);
			RemoveFromArray(myAugmentCategories[client], i);
			RemoveFromArray(myAugmentOwners[client], i);
			RemoveFromArray(myAugmentOwnersName[client], i);
			RemoveFromArray(myAugmentInfo[client], i);
			RemoveFromArray(myAugmentTargetEffects[client], i);
			RemoveFromArray(myAugmentActivatorEffects[client], i);
			RemoveFromArray(myAugmentSavedProfiles[client], i);
			refunded++;
		}
		PrintToChat(client, "\x04Deleted \x03all \x04non-favourited, non-equipped gear.\n+\x03%d \x05scrap", refunded);
		augmentParts[client] += refunded;
	}
	else if (result == 2) {
		GetClientAuthId(client, AuthId_Steam2, key, sizeof(key));
		if (!StrEqual(serverKey, "-1")) Format(key, sizeof(key), "%s%s", serverKey, key);
		Format(tquery, sizeof(tquery), "DELETE FROM `%s_loot` WHERE `isequipped` = '-1' AND `acteffects` = '-1' AND `tareffects` = '-1' AND `steam_id` = '%s';", TheDBPrefix, key);
		SQL_TQuery(hDatabase, QueryResults, tquery, client);

		size = GetArraySize(myAugmentInfo[client]);
		for (int i = size-1; i >= 0; i--) {
			isEquipped = GetArrayCell(myAugmentInfo[client], i, 3);
			if (isEquipped != -1) continue;
			GetArrayString(myAugmentTargetEffects[client], i, effects, sizeof(effects));
			if (!StrEqual(effects, "-1")) continue;
			GetArrayString(myAugmentActivatorEffects[client], i, effects, sizeof(effects));
			if (!StrEqual(effects, "-1")) continue;
			RemoveFromArray(myAugmentTargetEffects[client], i);
			RemoveFromArray(myAugmentActivatorEffects[client], i);
			RemoveFromArray(myAugmentIDCodes[client], i);
			RemoveFromArray(myAugmentCategories[client], i);
			RemoveFromArray(myAugmentOwners[client], i);
			RemoveFromArray(myAugmentOwnersName[client], i);
			RemoveFromArray(myAugmentInfo[client], i);
			RemoveFromArray(myAugmentSavedProfiles[client], i);
			refunded++;
		}
		PrintToChat(client, "\x04Deleted all \x03Minor \x04non-favourited, non-equipped gear.\n+\x03%d \x05scrap", refunded);
		augmentParts[client] += refunded;
	}
	else if (result == 3) {
		GetClientAuthId(client, AuthId_Steam2, key, sizeof(key));
		if (!StrEqual(serverKey, "-1")) Format(key, sizeof(key), "%s%s", serverKey, key);
		Format(tquery, sizeof(tquery), "DELETE FROM `%s_loot` WHERE (`isequipped` = '-1' AND `acteffects` = '-1' AND `tareffects` != '-1' AND `steam_id` = '%s') OR (`isequipped` = '-1' AND `acteffects` != '-1' AND `tareffects` = '-1' AND `steam_id` = '%s');", TheDBPrefix, key, key);
		SQL_TQuery(hDatabase, QueryResults, tquery, client);
		char othereffects[64];
		size = GetArraySize(myAugmentInfo[client]);
		for (int i = size-1; i >= 0; i--) {
			isEquipped = GetArrayCell(myAugmentInfo[client], i, 3);
			if (isEquipped != -1) continue;
			GetArrayString(myAugmentTargetEffects[client], i, effects, sizeof(effects));
			GetArrayString(myAugmentActivatorEffects[client], i, othereffects, sizeof(othereffects));
			if (!StrEqual(effects, "-1") && !StrEqual(othereffects, "-1") ||
				StrEqual(effects, "-1") && StrEqual(othereffects, "-1")) continue;
			RemoveFromArray(myAugmentTargetEffects[client], i);
			RemoveFromArray(myAugmentActivatorEffects[client], i);
			RemoveFromArray(myAugmentIDCodes[client], i);
			RemoveFromArray(myAugmentCategories[client], i);
			RemoveFromArray(myAugmentOwners[client], i);
			RemoveFromArray(myAugmentOwnersName[client], i);
			RemoveFromArray(myAugmentInfo[client], i);
			RemoveFromArray(myAugmentSavedProfiles[client], i);
			refunded++;
		}
		PrintToChat(client, "\x04Deleted all \x03Major \x04non-favourited, non-equipped gear.\n+\x03%d \x05scrap", refunded);
		augmentParts[client] += refunded;
	}
	else if (result == 4) {
		GetClientAuthId(client, AuthId_Steam2, key, sizeof(key));
		if (!StrEqual(serverKey, "-1")) Format(key, sizeof(key), "%s%s", serverKey, key);
		Format(tquery, sizeof(tquery), "DELETE FROM `%s_loot` WHERE `isequipped` = '-1' AND `acteffects` != '-1' AND `tareffects` != '-1' AND `steam_id` = '%s';", TheDBPrefix, key, key);
		SQL_TQuery(hDatabase, QueryResults, tquery, client);
		char othereffects[64];
		size = GetArraySize(myAugmentInfo[client]);
		for (int i = size-1; i >= 0; i--) {
			isEquipped = GetArrayCell(myAugmentInfo[client], i, 3);
			if (isEquipped != -1) continue;
			GetArrayString(myAugmentTargetEffects[client], i, effects, sizeof(effects));
			GetArrayString(myAugmentActivatorEffects[client], i, othereffects, sizeof(othereffects));
			if (StrEqual(effects, "-1") || StrEqual(othereffects, "-1")) continue;
			RemoveFromArray(myAugmentTargetEffects[client], i);
			RemoveFromArray(myAugmentActivatorEffects[client], i);
			RemoveFromArray(myAugmentIDCodes[client], i);
			RemoveFromArray(myAugmentCategories[client], i);
			RemoveFromArray(myAugmentOwners[client], i);
			RemoveFromArray(myAugmentOwnersName[client], i);
			RemoveFromArray(myAugmentInfo[client], i);
			RemoveFromArray(myAugmentSavedProfiles[client], i);
			refunded++;
		}
		PrintToChat(client, "\x04Deleted all \x03Perfect \x04non-favourited, non-equipped gear.\n+\x03%d \x05scrap", refunded);
		augmentParts[client] += refunded;
	}
	if (result > 0) BuildMenu(client);
	if (result == 0) {
		int auto = StringToInt(arg);
		if (auto > 0 && auto <= BestRating[client] + lootFindBonus) {
			iplayerSettingAutoDismantleScore[client] = auto;
			PrintToChat(client, "\x04Dismantling gear that drops below \x03%d \x04score.", iplayerSettingAutoDismantleScore[client]);
		}
	}
	return Plugin_Handled;
}

public Action CMD_ReloadConfigs(client, args) {
	char thetext[64];
	GetConfigValue(thetext, sizeof(thetext), "reload configs flags?");

	if (HasCommandAccess(client, thetext)) {
		CreateTimer(1.0, Timer_ExecuteConfig, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
		PrintToChat(client, "Reloading Config.");
	}
	return Plugin_Handled;
}

public Action CMD_SharePoints(client, args) {
	if (args < 2) {
		char thetext[64];
		GetConfigValue(thetext, sizeof(thetext), "reload configs flags?");
		PrintToChat(client, "%T", "Share Points Syntax", client, orange, white, thetext);
		return Plugin_Handled;
	}

	char arg[MAX_NAME_LENGTH];
	char arg2[10];
	GetCmdArg(1, arg, sizeof(arg));
	GetCmdArg(2, arg2, sizeof(arg2));
	float SharePoints = 0.0;
	if (StrContains(arg2, ".", false) == -1) SharePoints = StringToInt(arg2) * 1.0;
	else SharePoints = StringToFloat(arg2);

	if (SharePoints > Points[client]) return Plugin_Handled;

	int targetclient = FindTargetClient(client, arg);
	if (!IsLegitimateClient(targetclient)) return Plugin_Handled;
	char Name[MAX_NAME_LENGTH];
	GetClientName(targetclient, Name, sizeof(Name));
	char GiftName[MAX_NAME_LENGTH];
	GetClientName(client, GiftName, sizeof(GiftName));
	Points[client] -= SharePoints;
	Points[targetclient] += SharePoints;

	PrintToChatAll("%t", "Share Points Given", blue, GiftName, white, green, SharePoints, white, blue, Name); 
	return Plugin_Handled;
}

public Action CMD_ActionBar(client, args) {
	if (!DisplayActionBar[client]) {
		PrintToChat(client, "%T", "action bar displayed", client, white, blue);
		DisplayActionBar[client] = true;
	}
	else {
		PrintToChat(client, "%T", "action bar hidden", client, white, orange);
		DisplayActionBar[client] = false;
		ActionBarSlot[client] = -1;
	}
	return Plugin_Handled;
}

public Action CMD_LoadAugments(client, args) {
	PrintToChat(client, "\x04Reloading your gear.");
	LoadClientAugments(client);
	return Plugin_Handled;
}

public Action CMD_GiveStorePoints(client, args) {
	char thetext[64];
	GetConfigValue(thetext, sizeof(thetext), "give store points flags?");
	if (!HasCommandAccess(client, thetext)) { PrintToChat(client, "You don't have access."); return Plugin_Handled; }
	if (args < 2) {
		PrintToChat(client, "%T", "Give Store Points Syntax", client, orange, white);
		return Plugin_Handled;
	}
	char arg[MAX_NAME_LENGTH];
	char arg2[4];
	GetCmdArg(1, arg, sizeof(arg));
	if (args > 1) {
		GetCmdArg(2, arg2, sizeof(arg2));
	}
	int targetclient = FindTargetClient(client, arg);
	char Name[MAX_NAME_LENGTH];
	GetClientName(targetclient, Name, sizeof(Name));
	SkyPoints[targetclient] += StringToInt(arg2);
	PrintToChat(client, "%T", "Store Points Award Given", client, white, green, arg2, white, orange, Name);
	PrintToChat(targetclient, "%T", "Store Points Award Received", client, white, green, arg2, white);
	return Plugin_Handled;
}

public Action CMD_CollectBonusExperience(client, args) {
	return Plugin_Handled;
}

public Action CMD_TogglePvP(client, args) {
	int TheTime = RoundToCeil(GetEngineTime());
	if (IsPvP[client] != 0) {
		if (IsPvP[client] + 30 <= TheTime) {
			IsPvP[client] = 0;
			PrintToChat(client, "%T", "PvP Disabled", client, white, orange);
		}
	}
	else {
		IsPvP[client] = TheTime + 30;
		PrintToChat(client, "%T", "PvP Enabled", client, white, blue);
	}
	return Plugin_Handled;
}

public Action CMD_SetAugmentPrice(client, args) {
	if (args < 2) {
		PrintToChat(client, "\x04!price <augmentId> <price>");
		return Plugin_Handled;
	}
	int size = GetArraySize(myAugmentIDCodes[client]);
	char arg[512];
	char arg2[64];
	GetCmdArg(1, arg, sizeof(arg));
	GetCmdArg(2, arg2, sizeof(arg2));
	int augmentSlotToModify = StringToInt(arg);
	if (augmentSlotToModify >= 0 && augmentSlotToModify < size) {
		int augmentPrice = StringToInt(arg2);
		if (augmentPrice > 10000) augmentPrice = 10000;
		if (augmentPrice < 0) augmentPrice = 0;
		SetArrayCell(myAugmentInfo[client], augmentSlotToModify, augmentPrice, 1);
		PrintToChat(client, "\x04augment price set: \x03%d", augmentPrice);
	}
	else PrintToChat(client, "\x04augment id could not be found. \x03no price adjustments were made.");
	return Plugin_Handled;
}

public Action CMD_GiveLevel(client, args) {
	char thetext[64];
	GetConfigValue(thetext, sizeof(thetext), "give player level flags?");
	if ((HasCommandAccess(client, thetext) || client == 0) && args > 1) {
		char arg[512];
		char arg2[64];
		char arg3[64];
		GetCmdArg(1, arg, sizeof(arg));
		GetCmdArg(2, arg2, sizeof(arg2));
		GetCmdArg(3, arg3, sizeof(arg3));
		int targetclient = 0;
		bool hasSTEAM = (StrContains(arg, "STEAM", true) != -1) ? true : false;
		if (!hasSTEAM) targetclient = FindTargetClient(client, arg);
		if (args < 3 || hasSTEAM) {
			if (hasSTEAM) {
				char tquery[512];
				Format(steamIdSearch[client], 64, "%s%s", serverKey, arg);
				PrintToChat(client, "looking up %s to see if it exists...", steamIdSearch[client]);
				Format(tquery, sizeof(tquery), "SELECT COUNT(*) FROM `%s` WHERE (`steam_id` = '%s');", TheDBPrefix, steamIdSearch[client]);
				//Format(steamIdSearch[client], 64, "%s", arg2);
				levelToSet[client] = StringToInt(arg2);
				if (levelToSet[client] > iMaxLevel) levelToSet[client] = iMaxLevel;
				SQL_TQuery(hDatabase, Query_FindDataAndApplyChange, tquery, client);
			}
			else {
				if (IsLegitimateClient(targetclient) && PlayerLevel[targetclient] != StringToInt(arg2)) {
					SetTotalExperienceByLevel(targetclient, StringToInt(arg2));
					char Name[64];
					GetClientName(targetclient, Name, sizeof(Name));
					PrintToChatAll("%t", "client level set", Name, green, white, blue, PlayerLevel[targetclient]);
					FormatPlayerName(targetclient);
				}
			}
		}
		else if (args == 3 && IsLegitimateClient(targetclient) && StrContains(arg2, "rating", false) != -1) {
			Rating[targetclient] = StringToInt(arg3);
			BestRating[targetclient] = StringToInt(arg3);
		}
		else if (args == 4 && IsLegitimateClient(targetclient) && StrContains(arg2, "proficiency", false) != -1) {
			char arg4[64];
			GetCmdArg(4, arg4, sizeof(arg4));
			SetProficiencyData(targetclient, StringToInt(arg3), StringToInt(arg4));
		}
	}
	return Plugin_Handled;
}

public Action CMD_DropWeapon(int client, int args) {
	int CurrentEntity			=	GetEntPropEnt(client, Prop_Data, "m_hActiveWeapon");
	if (!IsValidEntity(CurrentEntity) || CurrentEntity < 1) return Plugin_Handled;
	char EntityName[64];
	GetEdictClassname(CurrentEntity, EntityName, sizeof(EntityName));
	if (StrContains(EntityName, "melee", false) != -1) return Plugin_Handled;
	int Entity					=	CreateEntityByName(EntityName);
	if (!IsValidEntityEx(Entity)) return Plugin_Handled;
	DispatchSpawn(Entity);
	lastEntityDropped[client] = Entity;
	GetAbilityStrengthByTrigger(client, client, TRIGGER_dropitem, _, _, _, _, _, _, _, _, _, _, _, _, _, Entity);
	
	float Origin[3];
	GetClientAbsOrigin(client, Origin);
	Origin[2] += 64.0;
	TeleportEntity(Entity, Origin, NULL_VECTOR, NULL_VECTOR);
	SetEntityMoveType(Entity, MOVETYPE_VPHYSICS);
	if (GetWeaponSlot(Entity) < 2) SetEntProp(Entity, Prop_Send, "m_iClip1", GetEntProp(CurrentEntity, Prop_Send, "m_iClip1"));
	if (IsValidEntityEx(CurrentEntity)) RemoveEntity(CurrentEntity);//AcceptEntityInput(CurrentEntity, "Kill");
	return Plugin_Handled;
}

public Action CMD_IAmStuck(int client, int args) {
	int timeremaining = lastStuckTime[client] - GetTime();
	if (timeremaining <= 0 && !bIsInCombat[client] && L4D2_GetInfectedAttacker(client) == -1 && !AnyTanksNearby(client, 5096.0)) {
		int target = FindAnyRandomClient(true, client);
		if (target > 0) {
			GetClientAbsOrigin(target, DeathLocation[client]);
			TeleportEntity(client, DeathLocation[client], NULL_VECTOR, NULL_VECTOR);
			SetEntityMoveType(client, MOVETYPE_WALK);
			lastStuckTime[client] = GetTime() + iStuckDelayTime;
		}
		else PrintToChat(client, "\x04Can't find anyone to teleport you to, sorry bud.");
	}
	else {
		char text[64];
		Format(text, sizeof(text), "\x04You can't use this command right now.");
		if (timeremaining > 0) Format(text, sizeof(text), "%s \x04You must wait \x03%d \x04second(s).", text, timeremaining);
	}

	return Plugin_Handled;
}

stock void CMD_OpenRPGMenu(int client) {
	ClearArray(MenuStructure[client]);	// keeps track of the open menus.
	if (LoadProfileRequestName[client] != -1) {
		if (!IsLegitimateClient(LoadProfileRequestName[client])) LoadProfileRequestName[client] = -1;
	}
	iIsWeaponLoadout[client] = 0;
	bEquipSpells[client] = false;
	PlayerCurrentMenuLayer[client] = 1;
	ShowPlayerLayerInformation[client] = false;
	if (iAllowPauseLeveling != 1 && iIsLevelingPaused[client] == 1) iIsLevelingPaused[client] = 0;
	BuildMenu(client, "main");
}

public Action CMD_WITCHESCOUNT(int client, int args) {
	PrintToChat(client, "Witches: %d", GetArraySize(WitchList));
	return Plugin_Handled;
}

public Action CMD_FBEGIN(int client, int args) {
	ReadyUpEnd_Complete();
	return Plugin_Handled;
}

public Action CMD_DeleteProfiles(int client, int args) {
	if (DeleteAllProfiles(client)) PrintToChat(client, "all saved profiles are deleted.");
	return Plugin_Handled;
}
public Action CMD_BlockVotes(int client, int args) {
	return Plugin_Handled;
}

public Action CMD_BlockIfReadyUpIsActive(int client, int args) {
	if (!b_IsRoundIsOver) return Plugin_Continue;
	return Plugin_Handled;
}

public Action CMD_LoadProfileEx(client, args) {
	if (args < 1) {
		PrintToChat(client, "!loadprofile \"<id>\"\n\x04the quotes are required.");
		return Plugin_Handled;
	}
	char arg[512];
	GetCmdArg(1, arg, sizeof(arg));
	if (GetDelimiterCount(arg, "+") != 2) {
		PrintToChat(client, "!loadprofile \"<id>\"\n\x04the quotes are required.");
		return Plugin_Handled;
	}

	char result[3][64];
	ExplodeString(arg, "+", result, 3, 64);

	LoadProfileEx_Confirm(client, arg, result[1], true);
	return Plugin_Handled;
}

stock RegisterConsoleCommands() {
	char thetext[64];
	if (!b_IsFirstPluginLoad) {
		b_IsFirstPluginLoad = true;
		LoadMainConfig();
		if (hDatabase == INVALID_HANDLE) {
			MySQL_Init();
		}
		GetConfigValue(CommandText, sizeof(CommandText), "action slot command?");
		GetConfigValue(RPGMenuCommand, sizeof(RPGMenuCommand), "rpg menu command?");
		RPGMenuCommandExplode = GetDelimiterCount(RPGMenuCommand, ",") + 1;
		GetConfigValue(thetext, sizeof(thetext), "drop weapon command?");
		RegConsoleCmd(thetext, CMD_DropWeapon);
		GetConfigValue(thetext, sizeof(thetext), "director talent command?");
		RegConsoleCmd(thetext, CMD_DirectorTalentToggle);
		GetConfigValue(thetext, sizeof(thetext), "rpg data erase?");
		RegConsoleCmd(thetext, CMD_DataErase);
		GetConfigValue(thetext, sizeof(thetext), "rpg bot data erase?");
		RegConsoleCmd(thetext, CMD_DataEraseBot);
		GetConfigValue(thetext, sizeof(thetext), "give store points command?");
		RegConsoleCmd(thetext, CMD_GiveStorePoints);
		// GetConfigValue(thetext, sizeof(thetext), "give augment command?");
		// RegConsoleCmd(thetext, CMD_GiveInventoryItem);
		GetConfigValue(thetext, sizeof(thetext), "give level command?");
		RegConsoleCmd(thetext, CMD_GiveLevel);
		GetConfigValue(thetext, sizeof(thetext), "share points command?");
		RegConsoleCmd(thetext, CMD_SharePoints);
		GetConfigValue(thetext, sizeof(thetext), "buy menu command?");
		RegConsoleCmd(thetext, CMD_BuyMenu);
		GetConfigValue(thetext, sizeof(thetext), "abilitybar menu command?");
		RegConsoleCmd(thetext, CMD_ActionBar);
		//RegConsoleCmd("collect", CMD_CollectBonusExperience);
		GetConfigValue(thetext, sizeof(thetext), "load profile command?");
		RegConsoleCmd(thetext, CMD_LoadProfileEx);
		//RegConsoleCmd("backpack", CMD_Backpack);
		//etConfigValue(thetext, sizeof(thetext), "rpg data force save?");
		//RegConsoleCmd(thetext, CMD_SaveData);
	}
	ReadyUp_NtvGetHeader();
	GetConfigValue(thetext, sizeof(thetext), "item drop model?");
	PrecacheModel(thetext, true);
	GetConfigValue(thetext, sizeof(thetext), "backpack model?");
	PrecacheModel(thetext, true);
}