stock BuildDirectorPriorityMenu(client) {

	new Handle:menu						=	CreateMenu(BuildDirectorPriorityMenuHandle);

	new size							=	GetArraySize(a_DirectorActions);
	decl String:Name[64];
	decl String:Name_t[64];

	decl String:key[64];
	decl String:value[64];

	new Priority						=	0;

	for (new i = 0; i < size; i++) {

		MenuKeys[client]							=	GetArrayCell(a_DirectorActions, i, 0);
		MenuValues[client]							=	GetArrayCell(a_DirectorActions, i, 1);
		MenuSection[client]							=	GetArrayCell(a_DirectorActions, i, 2);

		GetArrayString(Handle:MenuSection[client], 0, Name, sizeof(Name));
		Format(Name_t, sizeof(Name_t), "%T", Name, client);

		new size2						=	GetArraySize(MenuKeys[client]);
		for (new ii = 0; ii < size2; ii++) {

			GetArrayString(Handle:MenuKeys[client], ii, key, sizeof(key));
			GetArrayString(Handle:MenuValues[client], ii, value, sizeof(value));

			if (StrEqual(key, "priority?")) Priority		=	StringToInt(value);
		}
		Format(Name_t, sizeof(Name_t), "%s (%d / %d)", Name_t, Priority, GetConfigValueInt("director priority maximum?"));
		AddMenuItem(menu, Name_t, Name_t);
	}
	SetMenuExitBackButton(menu, false);
	DisplayMenu(menu, client, 0);
}

public BuildDirectorPriorityMenuHandle(Handle:menu, MenuAction:action, client, slot) {

	if (action == MenuAction_Select) {

		decl String:key[64];
		decl String:value[64];

		decl String:Priority[64];
		Format(Priority, sizeof(Priority), "0");
		new PriorityMaximum				=	GetConfigValueInt("director priority maximum?");

		MenuKeys[client]							=	GetArrayCell(a_DirectorActions, slot, 0);
		MenuValues[client]							=	GetArrayCell(a_DirectorActions, slot, 1);

		new size						=	GetArraySize(MenuKeys[client]);

		for (new i = 0; i < size; i++) {

			GetArrayString(Handle:MenuKeys[client], i, key, sizeof(key));
			GetArrayString(Handle:MenuValues[client], i, value, sizeof(value));

			if (StrEqual(key, "priority?")) {

				Format(Priority, sizeof(Priority), "%s", value);

				if (StringToInt(Priority) < PriorityMaximum) Format(Priority, sizeof(Priority), "%d", StringToInt(Priority) + 1);
				else Format(Priority, sizeof(Priority), "1");

				SetArrayString(Handle:MenuValues[client], i, Priority);
				SetArrayCell(Handle:a_DirectorActions, slot, MenuValues[client], 1);
				break;
			}
		}
		BuildDirectorPriorityMenu(client);
	}
	else if (action == MenuAction_End) {

		CloseHandle(menu);
	}
}