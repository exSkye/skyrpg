// effecttype 0 -> negative
// effecttype 1 -> positive
stock GetStatusEffects(client, EffectType = 0, char[] theStringToStoreItIn, theSizeOfTheString) {

	int Count = 0;
	int iNumStatusEffects = 0;
	// NEGATIVE effects
	//new printClient = client;

	//char TargetName[64];
	//GetClientAimTargetEx(client, TargetName, sizeof(TargetName), true);
	//client = StringToInt(TargetName);
	//if (!IsLegitimateClientAlive(client) || myCurrentTeam[client] != GetClientTeam(printClient)) client = printClient;
	int clientFlags = GetEntityFlags(client);
	int clientButtons = GetEntProp(client, Prop_Data, "m_nButtons");
	if (EffectType == 0) {

		//new AcidCount = GetClientStatusEffect(client, Handle:EntityOnFire, "acid");
		int FireCount = GetClientStatusEffect(client, "burn");
		int AcidCount = GetClientStatusEffect(client, "acid");
		Format(theStringToStoreItIn, theSizeOfTheString, "[-]");
		if (DoomTimer != 0) Format(theStringToStoreItIn, theSizeOfTheString, "%s[Dm%d]", theStringToStoreItIn, iDoomTimer - DoomTimer);
		if (bIsSurvivorFatigue[client]) Format(theStringToStoreItIn, theSizeOfTheString, "%s[Fa]", theStringToStoreItIn);

		//Count = GetClientStatusEffect(client, "burn");
		if (FireCount > 0) iNumStatusEffects++;
		if (FireCount >= 3) Format(theStringToStoreItIn, theSizeOfTheString, "%s[Bu++]", theStringToStoreItIn);
		else if (FireCount >= 2) Format(theStringToStoreItIn, theSizeOfTheString, "%s[Bu++]", theStringToStoreItIn);
		else if (FireCount > 0) Format(theStringToStoreItIn, theSizeOfTheString, "%s[Bu]", theStringToStoreItIn);

		//Count = GetClientStatusEffect(client, "acid");
		if (AcidCount > 0) iNumStatusEffects++;
		if (AcidCount >= 3) Format(theStringToStoreItIn, theSizeOfTheString, "%s[Ab++]", theStringToStoreItIn);
		else if (AcidCount >= 2) Format(theStringToStoreItIn, theSizeOfTheString, "%s[Ab+]", theStringToStoreItIn);
		else if (AcidCount > 0) Format(theStringToStoreItIn, theSizeOfTheString, "%s[Ab]", theStringToStoreItIn);

		Count = GetClientStatusEffect(client, "reflect");
		if (Count > 0) iNumStatusEffects++;
		if (Count >= 3) Format(theStringToStoreItIn, theSizeOfTheString, "%s[Re++]", theStringToStoreItIn);
		else if (Count >= 2) Format(theStringToStoreItIn, theSizeOfTheString, "%s[Re+]", theStringToStoreItIn);
		else if (Count > 0) Format(theStringToStoreItIn, theSizeOfTheString, "%s[Re]", theStringToStoreItIn);

		if (ISBLIND[client] != INVALID_HANDLE) {

			Format(theStringToStoreItIn, theSizeOfTheString, "%s[Bl]", theStringToStoreItIn);
			iNumStatusEffects++;
		}
		if (ISEXPLODE[client] != INVALID_HANDLE || IsClientInRangeSpecialAmmo(client, "x") > 0.0) {

			Format(theStringToStoreItIn, theSizeOfTheString, "%s[Ex]", theStringToStoreItIn);
			iNumStatusEffects++;
		}
		if (ISFROZEN[client] != INVALID_HANDLE) {

			Format(theStringToStoreItIn, theSizeOfTheString, "%s[Fr]", theStringToStoreItIn);
			iNumStatusEffects++;
		}
		float isSlowSpeed = IsClientInRangeSpecialAmmo(client, "s");
		if (ISSLOW[client] || isSlowSpeed > 0.0) {
			if (isSlowSpeed > 0.0) playerInSlowAmmo[client] = true;
			else playerInSlowAmmo[client] = false;
			if (fSlowSpeed[client] == 1.0) {
				if (ISSLOW[client]) ISSLOW[client] = false;
			}
			else {
				if (fSlowSpeed[client] < 1.0) Format(theStringToStoreItIn, theSizeOfTheString, "%s[Sl]", theStringToStoreItIn);
				else Format(theStringToStoreItIn, theSizeOfTheString, "%s[Sp]", theStringToStoreItIn);
				iNumStatusEffects++;
			}
		}
		//if (ISSLOW[client] != INVALID_HANDLE) Format(theStringToStoreItIn, theSizeOfTheString, "[Sl]%s", theStringToStoreItIn);
		
		if (ISFROZEN[client] != INVALID_HANDLE && FireCount > 0) {

			Format(theStringToStoreItIn, theSizeOfTheString, "%s[St]", theStringToStoreItIn);
			iNumStatusEffects++;
		}
		if (FireCount > 0 && AcidCount > 0) {

			Format(theStringToStoreItIn, theSizeOfTheString, "%s[Sc]", theStringToStoreItIn);
			iNumStatusEffects++;
		}
		if (!(clientFlags & FL_ONGROUND)) {

			Format(theStringToStoreItIn, theSizeOfTheString, "%s[Fl]", theStringToStoreItIn);
			iNumStatusEffects++;
		}
		if (bIsInCombat[client]) Format(theStringToStoreItIn, theSizeOfTheString, "%s[Ic]", theStringToStoreItIn);
		if (ISBILED[client]) {

			Format(theStringToStoreItIn, theSizeOfTheString, "%s[Bi]", theStringToStoreItIn);
			iNumStatusEffects++;
		}
		if (ISDAZED[client] > GetEngineTime()) {

			Format(theStringToStoreItIn, theSizeOfTheString, "%s[Dz]", theStringToStoreItIn);
			iNumStatusEffects++;
		}
		
		if (bHasWeakness[client] > 0) {

			if (bHasWeakness[client] < 3) Format(theStringToStoreItIn, theSizeOfTheString, "%s[Wk]", theStringToStoreItIn);
			else Format(theStringToStoreItIn, theSizeOfTheString, "%s[Shadow]", theStringToStoreItIn);
			iNumStatusEffects++;
		}
		
		if (IsSpecialCommonInRange(client, 'd')) {

			Format(theStringToStoreItIn, theSizeOfTheString, "%s[Re]", theStringToStoreItIn);
			iNumStatusEffects++;
		}
	}
	else if (EffectType == 1) {		// POSITIVE EFFECTS

		Format(theStringToStoreItIn, theSizeOfTheString, "[+]");
		if (!bIsInCombat[client]) Format(theStringToStoreItIn, theSizeOfTheString, "%s[Oc]", theStringToStoreItIn);
		if ((clientButtons & IN_DUCK)) {

			Format(theStringToStoreItIn, theSizeOfTheString, "%s[Cr]", theStringToStoreItIn);
			iNumStatusEffects++;
		}
		if (HasAdrenaline(client)) {
			// we need to add a boolean here as well so methods that need this information don't loop in perpetuity.
			playerHasAdrenaline[client] = true;
			Format(theStringToStoreItIn, theSizeOfTheString, "%s[Ad]", theStringToStoreItIn);
			iNumStatusEffects++;
		}
		else playerHasAdrenaline[client] = false;
		if (clientFlags & FL_INWATER) {

			Format(theStringToStoreItIn, theSizeOfTheString, "%s[Wa]", theStringToStoreItIn);
			iNumStatusEffects++;
		}
	}
	Format(ClientStatusEffects[client][EffectType], 64, "%s", theStringToStoreItIn);

	if (IsPvP[client] != 0) Format(theStringToStoreItIn, theSizeOfTheString, "%s[PvP]", theStringToStoreItIn);

	MyStatusEffects[client] = iNumStatusEffects;
}