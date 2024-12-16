stock void LoadLeaderboards(int client, int count) {

	if (count == 0) {

		if (TheLeaderboardsPageSize[client] >= leaderboardPageCount) {
			TheLeaderboardsPage[client] -= leaderboardPageCount;
			if (TheLeaderboardsPage[client] < 0) TheLeaderboardsPage[client] = 0;
		}
		else TheLeaderboardsPage[client] = 0;
	}
	else if (TheLeaderboardsPageSize[client] >= leaderboardPageCount) {		// if a page didn't load 10 entries, we don't increment. If a page exactly 10 entries, the next page will be empty and only have a return option.

		TheLeaderboardsPage[client] += leaderboardPageCount;
	}
	char tquery[1024];
	char Mapname[64];
	GetCurrentMap(Mapname, sizeof(Mapname));

	Format(tquery, sizeof(tquery), "SELECT `tname`, `steam_id`, `%s` FROM `%s` ORDER BY `%s` DESC;", RatingType, TheDBPrefix, RatingType);
	SQL_TQuery(hDatabase, LoadLeaderboardsQuery, tquery, client);
}

public void LoadLeaderboardsQuery(Handle owner, Handle hndl, const char[] error, any data)
{
	if (!IsLegitimateClient(data)) return;
	if (hndl == INVALID_HANDLE)
	{
		LogMessage("[LoadLeaderboardsQuery] %s", error);
		return;
	}
	int i = 0;
	//new count = 0;
	int counter = 0;
	Handle LeadName = CreateArray(16);
	Handle LeadRating = CreateArray(16);

	if (!bIsMyRanking[data]) {

		ResizeArray(LeadName, leaderboardPageCount);
		ResizeArray(LeadRating, leaderboardPageCount);
	}
	else {

		ResizeArray(LeadName, 1);
		ResizeArray(LeadRating, 1);
	}
	char text[64];
	//decl String:tquery[1024];
	int Pint = 0;
	int IgnoreRating = scoreRequiredForLeaderboard;
	char SteamID[64];
	//GetClientAuthId(data, AuthId_Steam2, SteamID, sizeof(SteamID));
	GetClientAuthId(data, AuthId_Steam2, SteamID, sizeof(SteamID));
	if (!StrEqual(serverKey, "-1")) Format(SteamID, sizeof(SteamID), "%s%s", serverKey, SteamID);
	ClearArray(TheLeaderboards[data]);		// reset the data held when a page is loaded.

	while (i < leaderboardPageCount && SQL_FetchRow(hndl))
	{	// bots don't have STEAM_ in their authIDs, so this will prevent bots from showing on the leaderboard.
		SQL_FetchString(hndl, 1, text, sizeof(text));
		if (StrContains(text, "STEAM_", true) == -1) continue;
		if (bIsMyRanking[data] && !StrEqual(text, SteamID, false)) {

			counter++;
			continue;
		}

		//count++;
		counter++;
		// +1 prevents every nth being a duplicate on the following page
		if (counter < TheLeaderboardsPage[data]+1) continue;

		Pint = SQL_FetchInt(hndl, 2);
		if (Pint < IgnoreRating || Pint < 2) {

			//count--;
			counter--;
			continue;	// players can un-set their name to hide themselves on the leaderboards.
		}

		/*SQL_FetchString(hndl, 2, text, sizeof(text));
		if (bIsMyRanking[data] && !StrEqual(text, SteamID, false)) {// ||
			//StrContains(text, "STEAM_", true) == -1) {

			count--;
			//if (StrContains(text, "STEAM_", true) == -1)
			//counter--;
			continue;	// will not display bots rating in the leaderboards.
		}*/

		SQL_FetchString(hndl, 0, text, sizeof(text));
		SetArrayString(LeadName, i, text);

		Pint = SQL_FetchInt(hndl, 2);
		Format(text, sizeof(text), "%d", Pint);
		SetArrayString(LeadRating, i, text);

		i++;
		if (bIsMyRanking[data]) break;
	}
	//bIsMyRanking[data] = false;

	//new size = GetArraySize(TheLeaderboards[data]);

	if (!bIsMyRanking[data]) {

		ResizeArray(LeadName, i);
		ResizeArray(LeadRating, i);
	}
	TheLeaderboardsPageSize[data] = i;

	ResizeArray(TheLeaderboards[data], 1);
	SetArrayCell(TheLeaderboards[data], 0, LeadName, 0);
	SetArrayCell(TheLeaderboards[data], 0, LeadRating, 1);

	if (GetArraySize(TheLeaderboards[data]) > 0) SendPanelToClientAndClose(DisplayTheLeaderboards(data), data, DisplayTheLeaderboards_Init, MENU_TIME_FOREVER);
	else BuildMenu(data);

	CloseHandle(LeadName);
	CloseHandle(LeadRating);
}