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

		int FireCount = GetClientStatusEffect(client, STATUS_EFFECT_BURN);
		int AcidCount = GetClientStatusEffect(client, STATUS_EFFECT_ACID);
		Format(theStringToStoreItIn, theSizeOfTheString, "[-]");
		if (DoomTimer != 0) Format(theStringToStoreItIn, theSizeOfTheString, "%s[Dm%d]", theStringToStoreItIn, iDoomTimer - DoomTimer);
		if (bIsSurvivorFatigue[client]) Format(theStringToStoreItIn, theSizeOfTheString, "%s[Fa]", theStringToStoreItIn);

		if (FireCount > 0) {
			iNumStatusEffects++;
			Format(theStringToStoreItIn, theSizeOfTheString, "%s[Bu]", theStringToStoreItIn);
		}

		if (AcidCount > 0) {
			iNumStatusEffects++;
			Format(theStringToStoreItIn, theSizeOfTheString, "%s[Ab]", theStringToStoreItIn);
		}

		Count = GetClientStatusEffect(client, STATUS_EFFECT_REFLECT);
		if (Count > 0) {
			iNumStatusEffects++;
			Format(theStringToStoreItIn, theSizeOfTheString, "%s[Re]", theStringToStoreItIn);
		}

		if (ISEXPLODE[client] != INVALID_HANDLE || IsClientInRangeSpecialAmmo(client, "x") > 0.0) {

			Format(theStringToStoreItIn, theSizeOfTheString, "%s[Ex]", theStringToStoreItIn);
			iNumStatusEffects++;
		}
		if (FreezerInRange[client]) {

			Format(theStringToStoreItIn, theSizeOfTheString, "%s[Fr]", theStringToStoreItIn);
			iNumStatusEffects++;
		}
		if (FreezerInRange[client] && FireCount > 0) {

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
		
		if (bHasWeakness[client] > 0) {
			Format(theStringToStoreItIn, theSizeOfTheString, "%s[Wk]", theStringToStoreItIn);
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
		if ((clientFlags & FL_ONGROUND) && (clientButtons & IN_DUCK)) {

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