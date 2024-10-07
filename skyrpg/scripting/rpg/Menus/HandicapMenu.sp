stock HandicapMenu(client) {
	Handle menu = CreateMenu(HandicapMenu_Handle);
	char pct[4];
	Format(pct, 4, "%");
	int size = GetArraySize(a_HandicapLevels);
	char text[512];
	if (handicapLevel[client] > 0) Format(text, 512, "Handicap Level: %d", handicapLevel[client]);
	else Format(text, 512, "Handicap Disabled");
	SetMenuTitle(menu, text);
	for (int i = 0; i < size; i++) {
		HandicapValues[client]	= GetArrayCell(a_HandicapLevels, i, 1);
		char menuName[64];
		GetArrayString(HandicapValues[client], HANDICAP_TRANSLATION, menuName, 64);
		float handicapDamage = GetArrayCell(HandicapValues[client], HANDICAP_DAMAGE);
		float handicapHealth = GetArrayCell(HandicapValues[client], HANDICAP_HEALTH);
		int lootFindBonus	 = GetArrayCell(HandicapValues[client], HANDICAP_LOOTFIND);
		int scoreRequired	 = GetArrayCell(HandicapValues[client], HANDICAP_SCORE_REQUIRED);
		float scoreMult		 = GetArrayCell(HandicapValues[client], HANDICAP_SCORE_MULTIPLIER);
		int scoreMissing	 = (Rating[client] >= scoreRequired) ? 0 : scoreRequired - Rating[client];
		char damage[10];
		AddCommasToString(RoundToCeil(handicapDamage * 100.0), damage, 10);
		char health[10];
		AddCommasToString(RoundToCeil(handicapHealth * 100.0), health, 10);
		char lootfind[10];
		AddCommasToString(RoundToCeil((lootFindBonus * fAugmentRatingMultiplier) * 100.0), lootfind, 10);
		char scorebonus[10];
		AddCommasToString(RoundToCeil(scoreMult * 100.0), scorebonus, 10);
		if (scoreMissing == 0) Format(text, sizeof(text), "%T", "handicap level unlocked", client, menuName, damage, pct, health, pct, lootfind, pct, pct, scorebonus);
		else {
			AddCommasToString(scoreMissing, text, sizeof(text));
			Format(text, sizeof(text), "%T", "handicap level locked", client, menuName, damage, pct, health, pct, lootfind, pct, text, pct, scorebonus);
		}
		AddMenuItem(menu, text, text);
	}
	SetMenuExitBackButton(menu, true);
	DisplayMenu(menu, client, 0);
}

stock void SetClientHandicapValues(client, bool skipArrayCheck = false) {
	if (skipArrayCheck || GetArraySize(HandicapSelectedValues[client]) != 4) ResizeArray(HandicapSelectedValues[client], 4);
	if (IsFakeClient(client)) return;
	if (handicapLevel[client] < 1 || handicapLevel[client]-1 > GetArraySize(a_HandicapLevels)) {
		handicapLevel[client] = -1;
		SetArrayCell(HandicapSelectedValues[client], 0, 0.0);
		SetArrayCell(HandicapSelectedValues[client], 1, 0.0);
		SetArrayCell(HandicapSelectedValues[client], 2, 0);
		SetArrayCell(HandicapSelectedValues[client], 3, fNoHandicapScoreMultiplier);
		return;
	}
	SetHandicapValues[client]	= GetArrayCell(a_HandicapLevels, handicapLevel[client]-1, 1);
	if (BestRating[client] < GetArrayCell(SetHandicapValues[client], HANDICAP_SCORE_REQUIRED)) {
		// useful for if a server operator ever changes handicap scores and so players who are no longer eligible would be affected here.
		handicapLevel[client] = -1;
		SetArrayCell(HandicapSelectedValues[client], 0, 0.0);
		SetArrayCell(HandicapSelectedValues[client], 1, 0.0);
		SetArrayCell(HandicapSelectedValues[client], 2, 0);
		SetArrayCell(HandicapSelectedValues[client], 3, fNoHandicapScoreMultiplier);
		return;
	}
	float handicapDamage = GetArrayCell(SetHandicapValues[client], HANDICAP_DAMAGE);
	float handicapHealth = GetArrayCell(SetHandicapValues[client], HANDICAP_HEALTH);
	int lootFindBonus	 = GetArrayCell(SetHandicapValues[client], HANDICAP_LOOTFIND);
	float scoreMult		 = GetArrayCell(SetHandicapValues[client], HANDICAP_SCORE_MULTIPLIER);

	SetArrayCell(HandicapSelectedValues[client], 0, handicapDamage);
	SetArrayCell(HandicapSelectedValues[client], 1, handicapHealth);
	SetArrayCell(HandicapSelectedValues[client], 2, lootFindBonus);
	SetArrayCell(HandicapSelectedValues[client], 3, scoreMult);

	// make sure the bot handicaps are set to the highest handicap player in the server.
	for (int i = 1; i <= MaxClients; i++) {
		if (!IsLegitimateClient(i) || !IsFakeClient(i) || myCurrentTeam[i] != TEAM_SURVIVOR) continue;
		if (handicapLevel[i] >= handicapLevel[client]) continue;
		handicapLevel[i] = handicapLevel[client];
		if (GetArraySize(HandicapSelectedValues[i]) != 4) ResizeArray(HandicapSelectedValues[i], 4);
		SetArrayCell(HandicapSelectedValues[i], 0, handicapDamage);
		SetArrayCell(HandicapSelectedValues[i], 1, handicapHealth);
		SetArrayCell(HandicapSelectedValues[i], 2, lootFindBonus);
		SetArrayCell(HandicapSelectedValues[i], 3, scoreMult);
	}
}

stock void SetBotClientHandicapValues(int clientToIgnore = 0) {
	int client = -1;
	for (int i = 1; i <= MaxClients; i++) {
		if (!IsLegitimateClient(i) || IsFakeClient(i) || myCurrentTeam[i] != TEAM_SURVIVOR || handicapLevel[i] < 1) continue;
		if (clientToIgnore > 0 && i == clientToIgnore) continue;
		if (client == -1 || handicapLevel[i] > handicapLevel[client]) client = i;
	}
	if (client == -1) {
		for (int i = 1; i <= MaxClients; i++) {
			if (!IsLegitimateClient(i) || !IsFakeClient(i) || myCurrentTeam[i] != TEAM_SURVIVOR) continue;
			if (GetArraySize(HandicapSelectedValues[i]) != 4) ResizeArray(HandicapSelectedValues[i], 4);
			SetArrayCell(HandicapSelectedValues[i], 0, 0.0);
			SetArrayCell(HandicapSelectedValues[i], 1, 0.0);
			SetArrayCell(HandicapSelectedValues[i], 2, 0);
			SetArrayCell(HandicapSelectedValues[i], 3, 0.0);
		}
		return;
	}
	if (handicapLevel[client]-1 > GetArraySize(a_HandicapLevels)) {
		handicapLevel[client] = 1;
	}
	SetHandicapValues[client]	= GetArrayCell(a_HandicapLevels, handicapLevel[client]-1, 1);
	float handicapDamage = GetArrayCell(SetHandicapValues[client], HANDICAP_DAMAGE);
	float handicapHealth = GetArrayCell(SetHandicapValues[client], HANDICAP_HEALTH);
	int lootFindBonus	 = GetArrayCell(SetHandicapValues[client], HANDICAP_LOOTFIND);
	float scoreMult		 = GetArrayCell(SetHandicapValues[client], HANDICAP_SCORE_MULTIPLIER);
	for (int i = 1; i <= MaxClients; i++) {
		if (!IsLegitimateClient(i) || !IsFakeClient(i) || myCurrentTeam[i] != TEAM_SURVIVOR) continue;
		if (handicapLevel[i] >= handicapLevel[client]) continue;
		handicapLevel[i] = handicapLevel[client];
		if (GetArraySize(HandicapSelectedValues[i]) != 4) ResizeArray(HandicapSelectedValues[i], 4);
		SetArrayCell(HandicapSelectedValues[i], 0, handicapDamage);
		SetArrayCell(HandicapSelectedValues[i], 1, handicapHealth);
		SetArrayCell(HandicapSelectedValues[i], 2, lootFindBonus);
		SetArrayCell(HandicapSelectedValues[i], 3, scoreMult);
	}
}

public HandicapMenu_Handle(Handle menu, MenuAction action, client, slot) {
	if (action == MenuAction_Select) {
		HandicapValues[client]	= GetArrayCell(a_HandicapLevels, slot, 1);
		int scoreRequired	 = GetArrayCell(HandicapValues[client], HANDICAP_SCORE_REQUIRED);
		if (Rating[client] >= scoreRequired && (handicapLevel[client] > slot+1 || !b_IsActiveRound)) {
			handicapLevel[client] = slot+1;
			SetClientHandicapValues(client);
			FormatPlayerName(client);
		}
		HandicapMenu(client);
	}
	else if (action == MenuAction_Cancel) {
		if (slot == MenuCancel_ExitBack) BuildMenu(client);
	}
	if (action == MenuAction_End) CloseHandle(menu);
}