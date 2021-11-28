stock bool:StrExistsInArrayValue(String:text[], Handle:Array) {

	new size						=	GetArraySize(Array);
	new Handle:Values;

	decl String:target[64];

	Values							=	CreateArray(8);

	for (new i = 0; i < size; i++) {

		Values						=	GetArrayCell(Array, i, 1);
		new size2					=	GetArraySize(Values);

		for (new ii = 0; ii < size2; ii++) {

			GetArrayString(Handle:Values, ii, target, sizeof(target));
			if (StrEqual(text, target, false)) {

				CloseHandle(Values);
				return true;
			}
		}
	}
	CloseHandle(Values);
	return false;
}

BuildChatSettingsMenu(client) {

	new Handle:menu					=	CreateMenu(BuildChatSettingsHandle);

	decl String:text[512];
	Format(text, sizeof(text), "%T", "Chat Settings (Reserve)", client);
	SetMenuTitle(menu, text);
	
	decl String:key[64];
	decl String:Name[64];
	decl String:Name_Temp[64];
	
	new size						=	GetArraySize(a_ChatSettings);

	for (new i = 0; i < size; i++) {

		MenuKeys[client]			=	GetArrayCell(a_ChatSettings, i, 0);
		MenuValues[client]			=	GetArrayCell(a_ChatSettings, i, 1);
		MenuSection[client]			=	GetArrayCell(a_ChatSettings, i, 2);

		GetArrayString(Handle:MenuSection[client], 0, Name, sizeof(Name));
		if (!StrEqual(ChatSettingsName[client], "none", false) && !StrEqual(ChatSettingsName[client], Name, false)) continue;

		new size2					=	GetArraySize(MenuKeys[client]);

		if (!StrEqual(ChatSettingsName[client], "none", false)) {

			for (new ii = 0; ii < size2; ii++) {

				GetArrayString(Handle:MenuKeys[client], ii, key, sizeof(key));
				if (StrEqual(key, "EOM", false)) continue;
				Format(Name_Temp, sizeof(Name_Temp), "%T", key, client);
				AddMenuItem(menu, Name_Temp, Name_Temp);

			}
		}
		else {

			Format(Name_Temp, sizeof(Name_Temp), "%T", Name, client);
			AddMenuItem(menu, Name_Temp, Name_Temp);
		}
	}

	SetMenuExitBackButton(menu, true);
	SetMenuExitButton(menu, false);
	DisplayMenu(menu, client, 0);
}

public BuildChatSettingsHandle(Handle:menu, MenuAction:action, client, slot) {

	if (action == MenuAction_Select) {

		decl String:value[64];
		decl String:Name[64];

		new size					=	GetArraySize(a_ChatSettings);

		for (new i = 0; i < size; i++) {

			MenuValues[client]		=	GetArrayCell(a_ChatSettings, i, 1);
			MenuSection[client]		=	GetArrayCell(a_ChatSettings, i, 2);

			GetArrayString(Handle:MenuSection[client], 0, Name, sizeof(Name));

			if (StrEqual(ChatSettingsName[client], "none", false) && i == slot) {

				// When ChatSettingsName is "none" there are only options equal to the number of sections.
				Format(ChatSettingsName[client], sizeof(ChatSettingsName[]), "%s", Name);
				BuildChatSettingsMenu(client);
				return;
			}
			if (!StrEqual(ChatSettingsName[client], "none", false)) {

				new size2			=	GetArraySize(MenuKeys[client]);
				for (new ii = 0; ii < size2; ii++) {

					GetArrayString(Handle:MenuValues[client], ii, value, sizeof(value));
					if (StrEqual(value, "EOM", false)) continue;
					if (ii == slot) {

						if (StrEqual(ChatSettingsName[client], "tag colors", false)) SetArrayString(Handle:ChatSettings[client], 0, value);
						else if (StrEqual(ChatSettingsName[client], "chat colors", false)) SetArrayString(Handle:ChatSettings[client], 2, value);

						Format(ChatSettingsName[client], sizeof(ChatSettingsName[]), "none");
						BuildChatSettingsMenu(client);
						return;
					}
				}
			}
		}
	}
	else if (action == MenuAction_Cancel) {

		if (slot == MenuCancel_ExitBack) BuildMenu(client);
	}
	else if (action == MenuAction_End) {

		CloseHandle(menu);
	}
}