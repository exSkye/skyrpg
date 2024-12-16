/* put the line below after all of the includes!
#pragma newdecls required
*/

stock void BuildDirectorPriorityMenu(int client) {
	Handle menu						=	CreateMenu(BuildDirectorPriorityMenuHandle);
	int size							=	GetArraySize(a_DirectorActions);
	char Name[64];
	char Name_t[64];
	for (int i = 0; i < size; i++) {
		MenuValues[client]							=	GetArrayCell(a_DirectorActions, i, 1);
		MenuSection[client]							=	GetArrayCell(a_DirectorActions, i, 2);

		GetArrayString(MenuSection[client], 0, Name, sizeof(Name));
		Format(Name_t, sizeof(Name_t), "%T", Name, client);

		int thisActionDirectorPriority = GetArrayCell(MenuValues[client], POINTS_PRIORITY);
		if (thisActionDirectorPriority != 1) continue;

		Format(Name_t, sizeof(Name_t), "%s (%d / %d)", Name_t, thisActionDirectorPriority, MaximumPriority);
		AddMenuItem(menu, Name_t, Name_t);
	}
	SetMenuExitBackButton(menu, false);
	DisplayMenu(menu, client, 0);
}

public BuildDirectorPriorityMenuHandle(Handle menu, MenuAction action, int client, int slot) {
	if (action == MenuAction_Select) {
		MenuValues[client]							=	GetArrayCell(a_DirectorActions, slot, 1);

		int thisActionDirectorPriority = GetArrayCell(MenuValues[client], POINTS_PRIORITY);
		if (thisActionDirectorPriority < MaximumPriority) thisActionDirectorPriority++;
		else thisActionDirectorPriority = 1;

		SetArrayCell(MenuValues[client], POINTS_PRIORITY, thisActionDirectorPriority);
		SetArrayCell(a_DirectorActions, slot, MenuValues[client], 1);

		BuildDirectorPriorityMenu(client);
	}
	else if (action == MenuAction_End) {
		CloseHandle(menu);
	}
}