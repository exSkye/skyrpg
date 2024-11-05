stock LoadAttributesMenu(client) {
	Handle menu = CreateMenu(LoadAttributesMenuHandle);
	ClearArray(RPGMenuPosition[client]);

	for (int i = ATTRIBUTE_CONSTITUTION; i <= ATTRIBUTE_LUCK; i++) {
		char text[64];
		char theExperienceBar[64];
		char currAmount[64];
		char currTarget[64];

		int attributeLevel = GetArrayCell(attributeData[client], i);
		int currentExperience = GetArrayCell(attributeData[client], i, 1);
		int currentRequirement = GetArrayCell(attributeData[client], i, 2);

		if (i == ATTRIBUTE_CONSTITUTION) Format(text, sizeof(text), "%T", "constitution", client);
		else if (i == ATTRIBUTE_AGILITY) Format(text, sizeof(text), "%T", "agility", client);
		else if (i == ATTRIBUTE_RESILIENCE) Format(text, sizeof(text), "%T", "resilience", client);
		else if (i == ATTRIBUTE_TECHNIQUE) Format(text, sizeof(text), "%T", "technique", client);
		else if (i == ATTRIBUTE_ENDURANCE) Format(text, sizeof(text), "%T", "endurance", client);
		else if (i == ATTRIBUTE_LUCK) Format(text, sizeof(text), "%T", "luck", client);
		
		MenuExperienceBar(client, currentExperience, currentRequirement, theExperienceBar, sizeof(theExperienceBar));
		AddCommasToString(currentExperience, currAmount, sizeof(currAmount));
		AddCommasToString(currentRequirement, currTarget, sizeof(currTarget));
		Format(text, sizeof(text), "%T", "attribute info", client, text, attributeLevel, currAmount, currTarget, theExperienceBar);
		AddMenuItem(menu, text, text, ITEMDRAW_DISABLED);
	}
	SetMenuExitBackButton(menu, true);
	DisplayMenu(menu, client, 0);
}

public LoadAttributesMenuHandle(Handle menu, MenuAction action, client, slot) {

	if (action == MenuAction_Select) { }
	else if (action == MenuAction_Cancel) {
		if (slot == MenuCancel_ExitBack) BuildMenu(client);
	}
	if (action == MenuAction_End) CloseHandle(menu);
}