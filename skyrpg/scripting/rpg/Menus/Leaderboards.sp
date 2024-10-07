public Handle DisplayTheLeaderboards(client) {

	Handle menu = CreatePanel();

	char tquery[64];
	char text[512];

	char textFormatted[64];

	if (TheLeaderboardsPageSize[client] > 0) {
		TheLeaderboardsDataFirst[client]		= GetArrayCell(TheLeaderboards[client], 0, 0);
		TheLeaderboardsDataSecond[client]		= GetArrayCell(TheLeaderboards[client], 0, 1);
		for (int i = 0; i < TheLeaderboardsPageSize[client]; i++) {
			GetArrayString(TheLeaderboardsDataFirst[client], i, tquery, sizeof(tquery));
			Format(text, sizeof(text), "%s", tquery);
			GetArrayString(TheLeaderboardsDataSecond[client], i, tquery, sizeof(tquery));
			AddCommasToString(StringToInt(tquery), textFormatted, sizeof(textFormatted));
			if (!bIsMyRanking[client]) Format(text, sizeof(text), "#%d %s, %s", i+1, textFormatted, text);
			else Format(text, sizeof(text), "#--- %s, %s", textFormatted, text);

			DrawPanelText(menu, text);

			if (bIsMyRanking[client]) break;
		}
	}
	Format(text, sizeof(text), "%T", "Leaderboards Top Page", client);
	DrawPanelItem(menu, text);
	if (TheLeaderboardsPageSize[client] >= GetConfigValueInt("leaderboard players per page?")) {

		Format(text, sizeof(text), "%T", "Leaderboards Next Page", client);
		DrawPanelItem(menu, text);
	}
	Format(text, sizeof(text), "%T", "View My Ranking", client);
	DrawPanelItem(menu, text);
	Format(text, sizeof(text), "%T", "return to talent menu", client);
	DrawPanelItem(menu, text);

	return menu;
}

public DisplayTheLeaderboards_Init (Handle topmenu, MenuAction action, client, param2)
{
	if (action == MenuAction_Select)
	{
		switch (param2)
		{
			case 1:
			{
				bIsMyRanking[client] = false;
				LoadLeaderboards(client, 0);
			}
			case 2:
			{
				if (TheLeaderboardsPageSize[client] >= GetConfigValueInt("leaderboard players per page?")) {

					bIsMyRanking[client] = false;
					LoadLeaderboards(client, 1);
				}
				else {

					bIsMyRanking[client] = true;
					LoadLeaderboards(client, 0);
				}
			}
			case 3:
			{
				if (TheLeaderboardsPageSize[client] >= GetConfigValueInt("leaderboard players per page?")) {

					bIsMyRanking[client] = true;
					LoadLeaderboards(client, 0);
				}
				else {

					ClearArray(TheLeaderboards[client]);
					TheLeaderboardsPage[client] = 0;
					BuildMenu(client);
				}
			}
			case 4:
			{
				if (TheLeaderboardsPageSize[client] >= GetConfigValueInt("leaderboard players per page?")) {

					ClearArray(TheLeaderboards[client]);
					TheLeaderboardsPage[client] = 0;
					BuildMenu(client);
				}
			}
		}
	}
	if (action == MenuAction_End) {

		CloseHandle(topmenu);
	}
	// if (topmenu != INVALID_HANDLE)
	// {
	// 	CloseHandle(topmenu);
	// }
}