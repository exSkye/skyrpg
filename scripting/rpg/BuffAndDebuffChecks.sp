bool IsPlayerWithinBuffRange(client, char[] effectName) {
	ClearArray(TalentPositionsWithEffectName[client]);
	int size = GetArraySize(a_Menu_Talents);
	char result[64];
	for (int i = 0; i < size; i++) {
		PlayerBuffVals[client]		= GetArrayCell(a_Menu_Talents, i, 1);
		GetArrayString(PlayerBuffVals[client], ACTIVATOR_ABILITY_EFFECTS, result, sizeof(result));
		if (!StrEqual(result, effectName)) continue;
		PushArrayCell(TalentPositionsWithEffectName[client], i);
	}
	size = GetArraySize(TalentPositionsWithEffectName[client]);
	float cpos[3];
	GetClientAbsOrigin(client, cpos);
	for (int i = 1; i <= MaxClients; i++) {
		// skip client, dead players, and players not on clients team
		if (i == client || !IsLegitimateClientAlive(i) || myCurrentTeam[i] != myCurrentTeam[client]) continue;
		float ipos[3];
		GetClientAbsOrigin(i, ipos);
		for (int ii = 0; ii < size; ii++) {
			int pos = GetArrayCell(TalentPositionsWithEffectName[client], ii);
			float fRange = GetStrengthByKeyValueFloat(i, ACTIVATOR_ABILITY_EFFECTS, effectName, COHERENCY_RANGE, pos);
			if (fRange <= 0.0) continue;	// no talents with this specification found.
			if (GetVectorDistance(cpos, ipos) > fRange) continue;	// if the client is not within player i's coherency range
			return true;
		}
	}
	return false;	// client is not within range of this talent for any player on their team that has it.
}

stock int PlayerHasWeakness(client) {	// order of least-intensive calculations to most.
	if (bForcedWeakness[client]) return 3;
	if (iCurrentIncapCount[client] >= iMaxIncap || IsSpecialCommonInRange(client, 'w')) return 1;
	if (IsClientInRangeSpecialAmmo(client, "W")) return 2;
	return 0;
}