public Handle ShowThreatMenu(client) {

	Handle menu = CreatePanel();

	char text[512];
	//GetArrayString(Handle:hThreatMeter, 0, text, sizeof(text));
	int iTotalThreat = GetTotalThreat();
	int iThreatTarget = -1;
	float iThreatPercent = 0.0;

	char tBar[64];
	int iBar = 0;

	char tClient[64];

	char threatLevelText[64];

	Format(text, sizeof(text), "%T", "threat meter title", client);
	//new pos = GetThreatPos(client);
	if (iThreatLevel[client] > 0) {

		//GetArrayString(Handle:hThreatMeter, pos, text, sizeof(text));
		//ExplodeString(text, "+", iThreatInfo, 2, 64);
		//iThreatTarget = StringToInt(text[FindDelim(text, "+")]);
		//if (iThreatTarget > 0) {

		iThreatPercent = ((1.0 * iThreatLevel[client]) / (1.0 * iTotalThreat));
		iBar = RoundToFloor(iThreatPercent / 0.05);
		if (iBar > 0) {

			for (int ii = 0; ii < iBar; ii++) {

				if (ii == 0) Format(tBar, sizeof(tBar), "~");
				else Format(tBar, sizeof(tBar), "%s~", tBar);
			}
			Format(tBar, sizeof(tBar), "%s>", tBar);
		}
		else Format(tBar, sizeof(tBar), ">");
		GetClientName(client, tClient, sizeof(tClient));
		AddCommasToString(iThreatLevel[client], threatLevelText, sizeof(threatLevelText));
		Format(tBar, sizeof(tBar), "%s%s %s", tBar, threatLevelText, tClient);
		Format(text, sizeof(text), "%s\nYou:\n%s\n\t\nTeam:", text, tBar);
		//}
	}
	SetPanelTitle(menu, text);

	int size = GetArraySize(hThreatMeter);
	int iClient = 0;
	if (size > 0) {

		for (int i = 0; i < size; i++) {
		
			//GetArrayString(Handle:hThreatMeter, i, text, sizeof(text));
			//ExplodeString(text, "+", iThreatInfo, 2, 64);
			//client+threat
			iClient = GetArrayCell(hThreatMeter, i, 0);
			//iClient = StringToInt(iThreatInfo[0]);
			if (client == iClient) continue;			// the menu owner data is shown in the title so not here.
			if (!IsLegitimateClientAlive(iClient)) continue;
			GetClientName(iClient, text, sizeof(text));
			iThreatTarget = GetArrayCell(hThreatMeter, i, 1);
			//iThreatTarget = StringToInt(iThreatInfo[1]);

			if (iThreatTarget < 1) continue;	// we don't show players who have no threat on the table.

			iThreatPercent = ((1.0 * iThreatTarget) / (1.0 * iTotalThreat));
			iBar = RoundToFloor(iThreatPercent / 0.05);
			if (iBar > 0) {

				for (int ii = 0; ii < iBar; ii++) {

					if (ii == 0) Format(tBar, sizeof(tBar), "~");
					else Format(tBar, sizeof(tBar), "%s~", tBar);
				}
				Format(tBar, sizeof(tBar), "%s>", tBar);
			}
			else Format(tBar, sizeof(tBar), ">");
			AddCommasToString(iThreatTarget, threatLevelText, sizeof(threatLevelText));
			Format(tBar, sizeof(tBar), "%s%s %s", tBar, threatLevelText, text);
			DrawPanelText(menu, tBar);
		}
	}
	Format(text, sizeof(text), "%T", "return to talent menu", client);
	DrawPanelItem(menu, text);
	return menu;
}

public ShowThreatMenu_Init (Handle topmenu, MenuAction action, client, param2)
{
	if (action == MenuAction_Select)
	{
		switch (param2)
		{
			case 1:
			{
				//bIsMyRanking[client] = false;
				//LoadLeaderboards(client, 0);
				bIsHideThreat[client] = true;
				BuildMenu(client);
			}
		}
	}
	if (action == MenuAction_End) {
		CloseHandle(topmenu);
	}
	
	/*if (action == MenuAction_Cancel) {

		//if (action == MenuCancel_ExitBack) {

		bIsHideThreat[client] = true;
		BuildMenu(client);
		//}
	}
	if (action == MenuAction_End) {

		bIsHideThreat[client] = true;
		CloseHandle(topmenu);
	}
	if (topmenu != INVALID_HANDLE)
	{
		//bIsHideThreat[client] = true;
		CloseHandle(topmenu);
	}*/
}

stock GetTotalThreat() {

	int iThreatAmount = 0;
	for (int i = 1; i <= MaxClients; i++) {

		if (IsLegitimateClientAlive(i) && myCurrentTeam[i] == TEAM_SURVIVOR) {

			iThreatAmount += iThreatLevel[i];
		}
	}
	return iThreatAmount;
}