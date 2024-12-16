stock void Autoloot(client) {
	float myPos[3];
	GetClientAbsOrigin(client, myPos);
	char entityClassname[64];
	float pos[3];
	for (int i = 0; i < MAX_ENTITIES; i++) {
		if (!IsValidEntity(i)) continue;
		GetEntityClassname(i, entityClassname, sizeof(entityClassname));
		if (!StrBeginsWith(entityClassname, "physics")) continue;
		GetEntPropString(i, Prop_Data, "m_iName", entityClassname, sizeof(entityClassname));
		if (!StrBeginsWith(entityClassname, "loot")) continue;
		GetEntPropVector(i, Prop_Send, "m_vecOrigin", pos);
		if (GetVectorDistance(myPos, pos) > 64.0) continue;
		IsPlayerTryingToPickupLoot(client, false, entityClassname);
	}
}
// char[] string = "hello"

stock bool StrBeginsWith(char[] string, char[] prefix) {
	int len = strlen(prefix);
	if (strlen(string) < len) return false;

	for (int i = 0; i < len; i++) {
		if (string[i] != prefix[i]) return false;
	}
	return true;
}

stock bool StrEqualAtPos(char[] string, char[] prefix, int pos) {
	int len = strlen(prefix);
	if (strlen(string)-pos < len) return false;
	for (int i = pos, j = 0; j < len; i++, j++) {
		if (string[i] != prefix[j]) return false;
	}
	return true;
}

stock bool IsPlayerTryingToPickupLoot(client, bool isLootBag = true, char[] classname = "none") {
	char entityClassname[64];
	int entity = -1;
	if (isLootBag) {
		entity = GetClientAimTarget(client, false);
		if (entity == -1) return false;
		GetEntityClassname(entity, entityClassname, sizeof(entityClassname));
		if (!StrEqualAtPos(entityClassname, "physics", 5)) return false;	// not a loot object
		GetEntPropString(entity, Prop_Data, "m_iName", entityClassname, sizeof(entityClassname));

		if (!StrBeginsWith(entityClassname, "loot")) return false;		// not specifically loot (we will change this to allow types later, maybe)
		
		// okay, so it's a loot object. Is the player close enough to pick it up?
		float myPos[3];
		GetClientAbsOrigin(client, myPos);
		float lootPos[3];
		GetEntPropVector(entity, Prop_Send, "m_vecOrigin", lootPos);
		if (GetVectorDistance(myPos, lootPos) > 64.0) return false;			// no.
	}
	else Format(entityClassname, sizeof(entityClassname), "%s", classname);

	char name[64];
	GetClientName(client, name, sizeof(name));
	// int currentGameTime = GetTime();
	// if (lastItemTime + 5 < currentGameTime || !StrEqual(name, lastPlayerGrab)) {
	// 	Format(text, sizeof(text), "{B}%s {N}is searching a {O}bag...", name);
	// }
	// lastItemTime = currentGameTime;
	GetClientName(client, lastPlayerGrab, sizeof(lastPlayerGrab));
	bool skipClient[MAXPLAYERS+1];
	for (int i = 1; i <= MaxClients; i++) {
		if (!IsLegitimateClient(i) || IsFakeClient(i)) {
			skipClient[i] = true;
			continue;
		}
		//Client_PrintToChat(i, true, text);
		skipClient[i] = false;
	}
	int lootOwner = (isLootBag) ? -1 : client;
	if (lootOwner == -1) {
		for (int i = 1; i <= MaxClients; i++) {
			if (skipClient[i]) continue;
			char key[64];
			GetClientAuthId(i, AuthId_Steam2, key, 64);
			// check if the owner (entity classname) is the player trying to pick it up (key)
			if (!StrEqualAtPos(entityClassname, key, 5)) continue;
			lootOwner = i;
			break;
		}
	}
	if (lootOwner < 1 || GetArraySize(playerLootOnGround[lootOwner]) < 1) return false;
	char splitClassname[2][64];
	ExplodeString(entityClassname, "-", splitClassname, 2, 64);
	int lootBagPosition = thisAugmentArrayPos(lootOwner, StringToInt(splitClassname[0][FindDelim(splitClassname[0], "+")]));
	if (lootBagPosition == -1) return false;

	int lootPoolToDrawFrom = StringToInt(splitClassname[1]);

	int augmentActivatorRating = GetArrayCell(playerLootOnGround[lootOwner], lootBagPosition, 2);
	int augmentTargetRating = GetArrayCell(playerLootOnGround[lootOwner], lootBagPosition, 4);

	int lootReason = LOOTREASON_NOTSET;
	int clientToReceiveLoot = lootOwner;
	if (lootOwner != client) {
		bool lootCanBeStolen = (iForceFFALoot != 1 && (iDontAllowLootStealing[lootOwner] == 3 || iDontAllowLootStealing[client] == 3)) ? false : true;
		if (iForceFFALoot == 1) lootReason = LOOTREASON_FORCEDSHARING;
		else if (lootCanBeStolen) { // if the client picking up the loot has any type of ffa loot enabled
			if (iDontAllowLootStealing[lootOwner] == 1) { // only allow major/minor to be stolen
				if (augmentActivatorRating > 0 && augmentTargetRating > 0) lootCanBeStolen = false;
			}
			else if (iDontAllowLootStealing[lootOwner] == 0) { // only allow minor loot to be stolen
				if (augmentActivatorRating > 0 || augmentTargetRating > 0) lootCanBeStolen = false;
			}
			if (!lootCanBeStolen) lootReason = LOOTREASON_NOTSHARING;
		}
		if (!lootCanBeStolen && lootReason == LOOTREASON_NOTSET) {
			if (iDontAllowLootStealing[lootOwner] == 3) lootReason = LOOTREASON_NOTSHARING;
			else lootReason = LOOTREASON_CLIENTDOESNTWANTIT;
		}

		if (lootCanBeStolen) {
			int itemScoreRoll = GetArrayCell(playerLootOnGround[lootOwner], lootBagPosition);
			if (itemScoreRoll < iplayerSettingAutoDismantleScore[client]) {
				// the only players this can be true for are the players who are not the loot owner, so we give it to the loot owner
				// because it is guaranteed to be within the range of loot the loot owner wants.
				clientToReceiveLoot = lootOwner;
				lootReason = LOOTREASON_CLIENTDOESNTWANTIT;
				//return false;
			}
			else {
				clientToReceiveLoot = client;
				lootReason = LOOTREASON_CLIENTSTOLELOOT;
			}
		}
		else clientToReceiveLoot = lootOwner;
	}
	else lootReason = LOOTREASON_CLIENTISOWNER;

	if (lootReason == LOOTREASON_CLIENTDOESNTWANTIT) {
		Format(statusMessageToDisplay[client], 64, "You don't want this loot.");
		fStatusMessageDisplayTime[client] = GetEngineTime() + fDisplayLootPickupMessageTime;
		return false;
	}

	int clientInventorySize = GetArraySize(myAugmentIDCodes[clientToReceiveLoot]);
	int clientInventoryLimit = iInventoryLimit;
	if (bHasDonorPrivileges[clientToReceiveLoot]) clientInventoryLimit += iDonorInventoryIncrease;
	
	if (clientInventorySize < clientInventoryLimit) {
		Format(statusMessageToDisplay[clientToReceiveLoot], 64, "Inventory Size %d/%d", clientInventorySize+1, clientInventoryLimit);
		fStatusMessageDisplayTime[clientToReceiveLoot] = GetEngineTime() + fDisplayLootPickupMessageTime;
		char entityOwnername[64];
		Format(entityOwnername, sizeof(entityOwnername), "%s", baseName[lootOwner]);
		PickupAugment(clientToReceiveLoot, lootOwner, entityClassname, entityOwnername, lootBagPosition, lootPoolToDrawFrom, client, lootReason);
	}
	else {
		Format(statusMessageToDisplay[clientToReceiveLoot], 64, "Inventory Full.");
		fStatusMessageDisplayTime[clientToReceiveLoot] = GetEngineTime() + fDisplayLootPickupMessageTime;
		return false;
	}
	RemoveFromArray(playerLootOnGround[lootOwner], lootBagPosition);	// we remove from the list wherever this bag was - it may not be at the end.
	RemoveFromArray(playerLootOnGroundId[lootOwner], lootBagPosition);
	if (isLootBag && IsValidEntityEx(entity)) RemoveEntity(entity);//AcceptEntityInput(entity, "Kill");
	return true;
}

stock void PickupAugment(int client, int owner, char[] ownerSteamID = "none", char[] ownerName = "none", int pos, int lootPoolToDrawFrom, int clientWhoPickedUpTheAugment, int lootReason) {
	if (pos >= GetArraySize(playerLootOnGround[owner])) {
		augmentParts[owner]++;
		char text[512];
		Format(text, sizeof(text), "{G}+1 {O}Crafting {B}Materials");
		if (iFancyBorders == 1) {
			Format(text, sizeof(text), "{O}-----------------------\n%s\n{O}-----------------------", text);
		}
		Client_PrintToChat(owner, true, text);
		return;
	}

	int size = GetArraySize(myAugmentIDCodes[client]);
	ResizeArray(myAugmentIDCodes[client], size+1);
	ResizeArray(myAugmentCategories[client], size+1);
	ResizeArray(myAugmentOwners[client], size+1);
	ResizeArray(myAugmentOwnersName[client], size+1);
	ResizeArray(myAugmentInfo[client], size+1);
	ResizeArray(myAugmentActivatorEffects[client], size+1);
	ResizeArray(myAugmentTargetEffects[client], size+1);
	ResizeArray(myAugmentSavedProfiles[client], size+1);
	char nosaved[64];
	Format(nosaved, sizeof(nosaved), "none");
	SetArrayString(myAugmentSavedProfiles[client], size, nosaved);

	// [0] - category score roll
	// [1] - category position
	// [2] - activator score roll
	// [3] - activator position
	// [4] - target score roll
	// [5] = target position
	// [6] = handicap score bonus (used for upgrading later)
	//int pos = GetArraySize(playerLootOnGround[owner])-1;
	char sItemCode[64];
	GetArrayString(playerLootOnGroundId[owner], pos, sItemCode, sizeof(sItemCode));
	SetArrayString(myAugmentIDCodes[client], size, sItemCode);

	char buffedCategory[64];
	if (lootPoolToDrawFrom == 1) GetArrayString(myLootDropCategoriesAllowed[owner], GetArrayCell(playerLootOnGround[owner], pos, 1), buffedCategory, 64);
	else GetArrayString(myUnlockedLootDropCategoriesAllowed[owner], GetArrayCell(playerLootOnGround[owner], pos, 1), buffedCategory, 64);

	char menuText[64];
	int len = GetAugmentTranslation(client, buffedCategory, menuText);
	Format(menuText, 64, "%T", menuText, client);

	SetArrayString(myAugmentCategories[client], size, buffedCategory);

	int augmentItemScore = GetArrayCell(playerLootOnGround[owner], pos);
	char key[64];
	GetClientAuthId(client, AuthId_Steam2, key, sizeof(key));
	SetArrayString(myAugmentOwners[client], size, ownerSteamID);
	SetArrayString(myAugmentOwnersName[client], size, ownerName);
	SetArrayCell(myAugmentInfo[client], size, augmentItemScore);	// item rating (cell 4 is activatorRating and cell5 is targetRating)
	SetArrayCell(myAugmentInfo[client], size, 0, 1);			// item cost
	SetArrayCell(myAugmentInfo[client], size, 0, 2);			// is item for sale
	SetArrayCell(myAugmentInfo[client], size, -1, 3);			// which augment slot the item is equipped in - -1 for no slot.


	int augmentActivatorRating = -1;
	int augmentTargetRating = -1;
	char activatorEffects[64];
	char targetEffects[64];

	int maxpossibleroll = GetArrayCell(playerLootOnGround[owner], pos, 6);
	SetArrayCell(myAugmentInfo[client], size, maxpossibleroll, 6);

	int maxPossibleActivatorScore = 0;
	int maxPossibleTargetScore = 0;

	int apos = GetArrayCell(playerLootOnGround[owner], pos, 3);
	if (apos >= 0) {
		if (lootPoolToDrawFrom == 1) GetArrayString(myLootDropActivatorEffectsAllowed[owner], apos, activatorEffects, 64);
		else GetArrayString(myUnlockedLootDropActivatorEffectsAllowed[owner], apos, activatorEffects, 64);

		SetArrayString(myAugmentActivatorEffects[client], size, activatorEffects);
		augmentActivatorRating = GetArrayCell(playerLootOnGround[owner], pos, 2);
		maxPossibleActivatorScore = GetArrayCell(playerLootOnGround[owner], pos, 7);
		SetArrayCell(myAugmentInfo[client], size, maxPossibleActivatorScore, 7);
	}
	else {
		augmentActivatorRating = -1;
		Format(activatorEffects, 64, "-1");
		SetArrayString(myAugmentActivatorEffects[client], size, "-1");
		SetArrayCell(myAugmentInfo[client], size, -1, 7);
	}
	SetArrayCell(myAugmentInfo[client], size, augmentActivatorRating, 4);

	int tpos = GetArrayCell(playerLootOnGround[owner], pos, 5);
	if (tpos >= 0) {
		if (lootPoolToDrawFrom == 1) GetArrayString(myLootDropTargetEffectsAllowed[owner], tpos, targetEffects, 64);
		else GetArrayString(myUnlockedLootDropTargetEffectsAllowed[owner], tpos, targetEffects, 64);

		SetArrayString(myAugmentTargetEffects[client], size, targetEffects);
		augmentTargetRating = GetArrayCell(playerLootOnGround[owner], pos, 4);
		maxPossibleTargetScore = GetArrayCell(playerLootOnGround[owner], pos, 8);
		SetArrayCell(myAugmentInfo[client], size, maxPossibleTargetScore, 8);
	}
	else {
		augmentTargetRating = -1;
		Format(targetEffects, 64, "-1");
		SetArrayString(myAugmentTargetEffects[client], size, "-1");
		SetArrayCell(myAugmentInfo[client], size, -1, 8);
	}
	SetArrayCell(myAugmentInfo[client], size, augmentTargetRating, 5);
	char augmentStrengthText[64];
	if (augmentActivatorRating == -1 && augmentTargetRating == -1) {
		Format(augmentStrengthText, 64, "{B}Minor");
	}
	else {
		char majorname[64];
		char perfectname[64];
		GetAugmentSurname(client, size, majorname, sizeof(majorname), perfectname, sizeof(perfectname), false);
		if (!StrEqual(majorname, "-1")) Format(majorname, sizeof(majorname), "%t", majorname);
		if (!StrEqual(perfectname, "-1")) Format(perfectname, sizeof(perfectname), "%t", perfectname);
		if (!StrEqual(majorname, "-1") && !StrEqual(perfectname, "-1")) Format(augmentStrengthText, 64, "{B}Perfect {O}%s %s", majorname, perfectname);
		else if (!StrEqual(majorname, "-1")) Format(augmentStrengthText, 64, "{B}Major {O}%s", majorname);
		else Format(augmentStrengthText, 64, "{B}Major {O}%s", perfectname);
	}
	char text[512];
	// I need fast...
	if (lootReason == LOOTREASON_CLIENTISOWNER) {
		Format(text, sizeof(text), "{B}%s {N}looted a {B}+{OG}%3.1f{O}PCT %s {OG}%s {O}%s {B}gear drop", baseName[clientWhoPickedUpTheAugment], (augmentItemScore * fAugmentRatingMultiplier) * 100.0, augmentStrengthText, menuText, buffedCategory[len]);
	}
	else if (lootReason == LOOTREASON_FORCEDSHARING) {
		Format(text, sizeof(text), "{B}%s {N}looted {B}%s{N}'s {B}+{OG}%3.1f{O}PCT %s {OG}%s {O}%s {B}gear drop", baseName[clientWhoPickedUpTheAugment], baseName[owner], (augmentItemScore * fAugmentRatingMultiplier) * 100.0, augmentStrengthText, menuText, buffedCategory[len]);
	}
	else if (lootReason == LOOTREASON_NOTSHARING) {
		Format(text, sizeof(text), "{B}%s {N}picked up a {B}+{OG}%3.1f{O}PCT %s {OG}%s {O}%s {B}gear drop {N}for {B}%s", baseName[clientWhoPickedUpTheAugment], (augmentItemScore * fAugmentRatingMultiplier) * 100.0, augmentStrengthText, menuText, buffedCategory[len], baseName[owner]);
	}
	else if (lootReason == LOOTREASON_CLIENTSTOLELOOT) {
		Format(text, sizeof(text), "{B}%s {N}stole a {B}+{OG}%3.1f{O}PCT %s {OG}%s {O}%s {B}gear drop {N}from {B}%s{N}", baseName[clientWhoPickedUpTheAugment], (augmentItemScore * fAugmentRatingMultiplier) * 100.0, augmentStrengthText, menuText, buffedCategory[len], baseName[owner]);
	}
	ReplaceString(text, sizeof(text), "PCT", "%%", true);
	for (int i = 1; i <= MaxClients; i++) {
		if (!IsLegitimateClient(i) || IsFakeClient(i)) continue;
		Client_PrintToChat(i, true, text);
	}
	if (!StrEqual(serverKey, "-1")) Format(key, sizeof(key), "%s%s", serverKey, key);
	char tquery[512];
	Format(tquery, sizeof(tquery), "INSERT INTO `%s_loot` (`firstownername`, `firstowner`, `steam_id`, `itemid`, `rating`, `category`, `price`, `isforsale`, `isequipped`, `acteffects`, `actrating`, `tareffects`, `tarrating`, `maxscoreroll`, `maxactroll`, `maxtarroll`) VALUES ('%s', '%s', '%s', '%s', '%d', '%s', '%d', '%d', '%d', '%s', '%d', '%s', '%d', '%d', '%d', '%d');", TheDBPrefix, ownerName, ownerSteamID, key, sItemCode, augmentItemScore, buffedCategory, 0, 0, -1, activatorEffects, augmentActivatorRating, targetEffects, augmentTargetRating, maxpossibleroll, maxPossibleActivatorScore, maxPossibleTargetScore);
	SQL_TQuery(hDatabase, QueryResults, tquery);
}