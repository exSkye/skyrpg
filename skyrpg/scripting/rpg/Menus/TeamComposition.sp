stock GetTeamComposition(client) {

	Handle menu = CreateMenu(TeamCompositionMenuHandle);
	ClearArray(RPGMenuPosition[client]);

	char text[512];
	char ratingText[64];

	for (int i = 1; i <= MaxClients; i++) {

		if (!IsLegitimateClient(i) || myCurrentTeam[client] != myCurrentTeam[i]) continue;

		GetClientName(i, text, sizeof(text));

		AddCommasToString(Rating[i], ratingText, sizeof(ratingText));
		Format(text, sizeof(text), "%s\t\tScore: %s", text, ratingText);
		AddMenuItem(menu, text, text);
	}
	SetMenuExitBackButton(menu, true);
	DisplayMenu(menu, client, 0);
}

public TeamCompositionMenuHandle(Handle menu, MenuAction action, client, slot) {

	if (action == MenuAction_Select) {

		GetTeamComposition(client);
	}
	else if (action == MenuAction_Cancel) {

		if (slot == MenuCancel_ExitBack) {

			BuildMenu(client, "main");
		}
	}
	if (action == MenuAction_End) {

		//LoadTarget[client] = -1;
		CloseHandle(menu);
	}
}