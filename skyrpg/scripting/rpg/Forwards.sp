public int ReadyUp_SetSurvivorMinimum(int minSurvs) {
	iMinSurvivors = minSurvs;
}

public void ReadyUp_GetMaxSurvivorCount(int count) {
	// if (count <= 1) bIsSoloHandicap = true;
	// else bIsSoloHandicap = false;
}

public int ReadyUp_TrueDisconnect(int client) {
	if (b_IsLoaded[client]) SavePlayerData(client, true);
	// only set to false if a REAL player leaves - this way bots don't repeatedly load their data.
	b_IsLoaded[client] = false;
	// the best redundancy check to tower over all others. no more collisions when a player connects on a client that is not yet timed out to a crashed player!
	Format(currentClientSteamID[client], sizeof(currentClientSteamID[]), "-1");
	myCurrentWeaponPos[client] = -1;
	myPrimaryWeaponPos[client] = -1;
	DisconnectDataReset(client);
}

public ReadyUp_GetCampaignStatus(mapposition) {
	CurrentMapPosition = mapposition;
}

public ReadyUp_FwdGetHeader(const char[] header) {
	strcopy(s_rup, sizeof(s_rup), header);
}

public ReadyUp_FwdGetCampaignName(const char[] mapname) {
	strcopy(currentCampaignName, sizeof(currentCampaignName), mapname);
}

public ReadyUp_CoopMapFailed(iGamemode) {
	if (!b_IsMissionFailed) {
		b_IsMissionFailed	= true;
		Points_Director = 0.0;
	}
}

public ReadyUp_FirstClientLoaded() {
	RefreshSurvivorBots();
	ReadyUpGameMode = ReadyUp_GetGameMode();
}

public ReadyUp_CampaignComplete() {
	if (!b_IsCampaignComplete) {
		b_IsCampaignComplete			= true;
		CallRoundIsOver();
		WipeDebuffs(true);
	}
}

public ReadyUp_RoundIsOver(gamemode) {
	CallRoundIsOver();
}

public int ReadyUp_GroupMemberStatus(int client, int groupStatus) {

	if (IsLegitimateClient(client)) {
		if (HasCommandAccess(client, sDonatorFlags) || groupStatus == 1) IsGroupMember[client] = true;
		else IsGroupMember[client] = false;

		CheckGroupStatus(client);
	}
	return 0;
}