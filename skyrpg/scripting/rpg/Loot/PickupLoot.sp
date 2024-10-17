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
		IsPlayerTryingToPickupLoot(client, i, entityClassname);
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

stock bool IsPlayerTryingToPickupLoot(client, int entity = -1, char[] classname = "none") {
	char entityClassname[64];
	if (entity == -1) {
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
	int lootOwner = -1;
	for (int i = 1; i <= MaxClients; i++) {
		if (skipClient[i]) continue;
		char key[64];
		GetClientAuthId(i, AuthId_Steam2, key, 64);
		// check if the owner (entity classname) is the player trying to pick it up (key)
		if (StrContains(entityClassname, key) == -1) continue;
		lootOwner = i;
		break;
	}
	if (GetArraySize(playerLootOnGround[lootOwner]) < 1) return false;
	char splitClassname[2][64];
	ExplodeString(entityClassname, "-", splitClassname, 2, 64);
	int lootBagPosition = thisAugmentArrayPos(lootOwner, StringToInt(splitClassname[0][FindDelim(splitClassname[0], "+")]));
	if (lootBagPosition == -1) return false;

	int lootPoolToDrawFrom = StringToInt(splitClassname[1]);

	int augmentActivatorRating = GetArrayCell(playerLootOnGround[lootOwner], lootBagPosition, 2);
	int augmentTargetRating = GetArrayCell(playerLootOnGround[lootOwner], lootBagPosition, 4);

	bool lootCanBeStolen = false;	// i know it starts false, i just prefer how it looks

	if (client != lootOwner && iDontAllowLootStealing[client] < 3) { // if the client picking up the loot has any type of ffa loot enabled
		if (iDontAllowLootStealing[lootOwner] == 2) {	// all tiers
			lootCanBeStolen = true;
		}
		else if (iDontAllowLootStealing[lootOwner] == 1) { // only allow major/minor to be stolen
			if (augmentActivatorRating < 1 || augmentTargetRating < 1) lootCanBeStolen = true;
		}
		else if (iDontAllowLootStealing[lootOwner] == 0) { // only allow minor loot to be stolen
			if (augmentActivatorRating == -1 && augmentTargetRating == -1) lootCanBeStolen = true;
		}
	}

	int clientToReceiveLoot = (!lootCanBeStolen) ? lootOwner : client;
	int itemScoreRoll = GetArrayCell(playerLootOnGround[lootOwner], lootBagPosition);
	if (itemScoreRoll < iplayerSettingAutoDismantleScore[clientToReceiveLoot]) {
		// the only players this can be true for are the players who are not the loot owner, so we give it to the loot owner
		// because it is guaranteed to be within the range of loot the loot owner wants.
		clientToReceiveLoot = lootOwner;
	}
	if (GetArraySize(myAugmentIDCodes[clientToReceiveLoot]) < iInventoryLimit) {
		char entityOwnername[64];
		Format(entityOwnername, sizeof(entityOwnername), "%s", baseName[lootOwner]);
		PickupAugment(clientToReceiveLoot, lootOwner, entityClassname, entityOwnername, lootBagPosition, lootPoolToDrawFrom);
	}
	else {
		augmentParts[lootOwner]++;
	}
	RemoveFromArray(playerLootOnGround[lootOwner], lootBagPosition);	// we remove from the list wherever this bag was - it may not be at the end.
	RemoveFromArray(playerLootOnGroundId[lootOwner], lootBagPosition);
	AcceptEntityInput(entity, "Kill");
	return true;
}