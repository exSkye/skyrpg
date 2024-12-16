public Action Timer_ThreatSystem(Handle timer) {

	static cThreatTarget			= -1;
	static cThreatOld				= -1;
	static cThreatLevel				= 0;
	static cThreatEnt				= -1;
	static count					= 0;
	static char temp[64];
	static float vPos[3];

	if (!b_IsActiveRound) {
		iSurvivalCounter = -1;

		for (int i = 1; i <= MaxClients; i++) {

			if (IsLegitimateClient(i)) {

				iThreatLevel_temp[i] = 0;
				iThreatLevel[i] = 0;
			}
		}

		count = 0;
		cThreatLevel = 0;
		iTopThreat = 0;
		// it happens due to ent shifting
		//if (!IsLegitimateClient(cThreatEnt) && cThreatEnt != -1 && EntRefToEntIndex(cThreatEnt) != INVALID_ENT_REFERENCE) AcceptEntityInput(cThreatEnt, "Kill");
		if (!IsLegitimateClient(cThreatEnt) && IsValidEntityEx(cThreatEnt)) RemoveEntity(cThreatEnt);//AcceptEntityInput(cThreatEnt, "Kill");
		cThreatEnt = -1;

		return Plugin_Stop;
	}
	if (ScenarioEndConditionsMet()) {
		ExecCheatCommand(FindAHumanClient(), "scenario_end");
		return Plugin_Continue;
	}
	for (int i = 1; i <= MaxClients; i++) {
		if (!IsLegitimateClientAlive(i) || IsFakeClient(i) || myCurrentTeam[i] == TEAM_SPECTATOR) continue;
		skyPointsAwardTime[i]--;
		if (skyPointsAwardTime[i] > 0) continue;
		if (skyPointsAwardTime[i] == 0) {	// new players start @ -1
			SkyPoints[i] += iSkyPointsAwardAmount;
			char spname[64];
			Format(spname, sizeof(spname), "%t", spmn);
			PrintToChatAll("%t", "player awarded sky points", blue, baseName[i], white, green, iSkyPointsAwardAmount, orange, spname);
		}

		if (!bHasDonorPrivileges[i]) skyPointsAwardTime[i] = iSkyPointsTimeRequired * 60;
		else skyPointsAwardTime[i] = iSkyPointsTimeRequiredDonator * 60;
	}
	//if (IsLegitimateClient(cThreatEnt)) cThreatEnt = -1;
	iSurvivalCounter++;
	SortThreatMeter();
	count++;

	cThreatOld = cThreatTarget;
	cThreatLevel = 0;
	

	if (GetArraySize(hThreatMeter) < 1) {

		for (int i = 1; i <= MaxClients; i++) {

			if (IsLegitimateClient(i) && myCurrentTeam[i] == TEAM_SURVIVOR) {

				if (!IsPlayerAlive(i)) {

					iThreatLevel_temp[i] = 0;
					iThreatLevel[i] = 0;
					
					continue;
				}
				if (iThreatLevel[i] > cThreatLevel) {

					cThreatTarget = i;
					cThreatLevel = iThreatLevel[i];
				}
			}
		}
	}
	else {

		//GetArrayString(Handle:hThreatMeter, 0, temp, sizeof(temp));
		//ExplodeString(temp, "+", iThreatInfo, 2, 64);
		//client+threat
		cThreatTarget = GetArrayCell(hThreatMeter, 0, 0);
		//cThreatTarget = StringToInt(iThreatInfo[0]);
		
		//GetClientName(iClient, text, sizeof(text));
		//iThreatTarget = StringToInt(iThreatInfo[1]);
		cThreatLevel = iThreatLevel[cThreatTarget];
	}

	iTopThreat = cThreatLevel;	// when people use taunt, it sets iTopThreat + 1;
	if (cThreatOld != cThreatTarget || count >= 20) {

		count = 0;
		if (IsValidEntityEx(cThreatEnt)) RemoveEntity(cThreatEnt);//AcceptEntityInput(cThreatEnt, "Kill");
		cThreatEnt = -1;
	}

	if (cThreatEnt == -1 && IsLegitimateClientAlive(cThreatTarget)) {

		cThreatEnt = CreateEntityByName("info_goal_infected_chase");
		if (IsValidEntityEx(cThreatEnt)) {
			cThreatEnt = EntIndexToEntRef(cThreatEnt);

			DispatchSpawn(cThreatEnt);
			//new Float:vPos[3];
			GetClientAbsOrigin(cThreatTarget, vPos);
			vPos[2] += 20.0;
			TeleportEntity(cThreatEnt, vPos, NULL_VECTOR, NULL_VECTOR);

			SetVariantString("!activator");
			AcceptEntityInput(cThreatEnt, "SetParent", cThreatTarget);

			//decl String:temp[32];
			Format(temp, sizeof temp, "OnUser4 !self:Kill::20.0:-1");
			SetVariantString(temp);
			AcceptEntityInput(cThreatEnt, "AddOutput");
			AcceptEntityInput(cThreatEnt, "FireUser4");
		}
	}

	return Plugin_Continue;
}

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