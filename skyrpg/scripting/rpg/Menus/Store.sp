stock BuildStoreInventory(int client) {
	Handle menu					=	CreateMenu(BuildStoreInventoryHandle);
	BuildMenuTitle(client, menu);
	ClearArray(StoreMenuPosition[client]);

	int size = GetArraySize(a_Store);
	for (int i = 0; i < size; i++) {
		int itemAmountHeld = GetArrayCell(StoreInventory[client], i);
		if (itemAmountHeld < 1) continue;

		MenuSection[client] = GetArrayCell(a_Store, i, 2);

		char text[64];
		GetArrayString(MenuSection[client], 0, text, sizeof(text));
		Format(text, sizeof(text), "%T", text, client);
		ReplaceString(text, sizeof(text), "{PCT}", "%", true);
		Format(text, sizeof(text), "%s (%d)", text, itemAmountHeld);

		PushArrayCell(StoreMenuPosition[client], i);
		AddMenuItem(menu, text, text);
	}
	SetMenuExitBackButton(menu, true);
	DisplayMenu(menu, client, 0);
}

public BuildStoreInventoryHandle(Handle menu, MenuAction action, client, slot) {
	if (action == MenuAction_Select) {
		//int inventoryItem = GetArrayCell(StoreMenuPosition[client], slot);
		StoreInventoryConfirmation(client, slot);
	}
	else if (action == MenuAction_Cancel) {
		if (slot == MenuCancel_ExitBack) {
			BuildMenu(client);
		}
	}
	if (action == MenuAction_End) {
		CloseHandle(menu);
	}
}

stock StoreInventoryConfirmation(int client, int slot) {
	Handle menu					=	CreateMenu(StoreInventoryConfirmationHandle);
	BuildMenuTitle(client, menu);
	
	int pos = GetArrayCell(StoreMenuPosition[client], slot);
	ClearArray(StoreMenuPosition[client]);
	PushArrayCell(StoreMenuPosition[client], pos);
	int itemAmountHeld = GetArrayCell(StoreInventory[client], pos);

	MenuSection[client] = GetArrayCell(a_Store, pos, 2);

	char text[64];
	GetArrayString(MenuSection[client], 0, text, sizeof(text));
	Format(text, sizeof(text), "%T", text, client);
	ReplaceString(text, sizeof(text), "{PCT}", "%", true);
	Format(text, sizeof(text), "%T", "withdraw store item confirmation", client, text, itemAmountHeld);
	AddMenuItem(menu, text, text);

	SetMenuExitBackButton(menu, true);
	DisplayMenu(menu, client, 0);
}

public StoreInventoryConfirmationHandle(Handle menu, MenuAction action, client, slot) {
	if (action == MenuAction_Select) {
		int pos = GetArrayCell(StoreMenuPosition[client], 0);
		int itemAmountHeld = GetArrayCell(StoreInventory[client], pos);

		MenuSection[client] = GetArrayCell(a_Store, pos, 2);

		char text[64];
		GetArrayString(MenuSection[client], 0, text, sizeof(text));
		Format(text, sizeof(text), "%T", text, client);	//{1}You withdraw {2}{3} {4}and have {5}{6} {7}remaining.
		
		char pct[4];
		Format(pct, sizeof(pct), "%");
		ReplaceString(text, sizeof(text), "{PCT}", "%", true);
		PrintToChat(client, "%T", "withdraw store item", client, white, blue, text, white, green, itemAmountHeld-1, orange);

		SetArrayCell(StoreInventory[client], pos, itemAmountHeld-1);

		MenuValues[client] = GetArrayCell(a_Store, pos, 1);
		int rewardType = GetArrayCell(MenuValues[client], STORE_REWARD_TYPE);
		if (rewardType == STORE_ITEM_TYPE_IS_XPBOOSTER) {
			float fAmount = GetArrayCell(MenuValues[client], STORE_REWARD_AMOUNT);
			float oldMult = RoundExperienceMultiplier[client];
			RoundExperienceMultiplier[client] += fAmount;//{1}Round Survival Multiplier: {2}{3}{4}{5} {6}-> {7}{8}{9}{10}
			PrintToChat(client, "%T", "store xpbooster add", client, orange, blue, oldMult * 100.0, orange, pct, white, blue, RoundExperienceMultiplier[client] * 100.0, orange, pct);
		}
		else if (rewardType == STORE_ITEM_TYPE_IS_MATERIALS) {
			int iAmount = GetArrayCell(MenuValues[client], STORE_REWARD_AMOUNT);
			int oldParts = augmentParts[client];
			augmentParts[client] += iAmount;
			PrintToChat(client, "%T", "store crafting material add", client, orange, blue, oldParts, white, blue, augmentParts[client]);
		}
		else if (rewardType == STORE_ITEM_TYPE_IS_ITEMGIVE) {
			char itemToGive[64];
			GetArrayString(MenuValues[client], STORE_ITEM_TO_GIVE, itemToGive, sizeof(itemToGive));
			ExecCheatCommand(client, "give", itemToGive);
			PrintToChat(client, "%T", "store item give", client, orange, blue, itemToGive);
		}
		else if (rewardType == STORE_ITEM_TYPE_IS_VENDING_MACHINE) {
			
		}
		if (itemAmountHeld-1 > 0) BuildStoreInventory(client);
		else BuildMenu(client, _, 2);
	}
	else if (action == MenuAction_Cancel) {
		if (slot == MenuCancel_ExitBack) {
			BuildMenu(client);
		}
	}
	if (action == MenuAction_End) {
		CloseHandle(menu);
	}
}

stock BuildStore(int client) {
	Handle menu					=	CreateMenu(BuildStoreHandle);
	BuildMenuTitle(client, menu);

	int size = GetArraySize(a_Store);
	for (int i = 0; i < size; i++) {
		MenuSection[client] = GetArrayCell(a_Store, i, 2);
		char text[64];
		GetArrayString(MenuSection[client], 0, text, sizeof(text));
		Format(text, sizeof(text), "%T", text, client);

		MenuValues[client] = GetArrayCell(a_Store, i, 1);
		int skyPointCost = GetArrayCell(MenuValues[client], STORE_SKYPOINT_COST);

		ReplaceString(text, sizeof(text), "{PCT}", "%", true);
		Format(text, sizeof(text), "%T", "store item listing", client, text, skyPointCost);

		AddMenuItem(menu, text, text);
	}
	SetMenuExitBackButton(menu, true);
	DisplayMenu(menu, client, 0);
}

public BuildStoreHandle(Handle menu, MenuAction action, client, slot) {
	if (action == MenuAction_Select) {
		MenuValues[client] = GetArrayCell(a_Store, slot, 1);
		int skyPointCost = GetArrayCell(MenuValues[client], STORE_SKYPOINT_COST);
		//int inventoryItem = GetArrayCell(StoreMenuPosition[client], slot);
		if (SkyPoints[client] >= skyPointCost) StoreConfirmation(client, slot);
		else BuildStore(client);
	}
	else if (action == MenuAction_Cancel) {
		if (slot == MenuCancel_ExitBack) {
			BuildMenu(client);
		}
	}
	if (action == MenuAction_End) {
		CloseHandle(menu);
	}
}

stock StoreConfirmation(int client, int slot) {
	Handle menu					=	CreateMenu(BuildStoreConfirmationHandle);
	BuildMenuTitle(client, menu);
	ClearArray(StoreMenuPosition[client]);
	PushArrayCell(StoreMenuPosition[client], slot);

	MenuSection[client] = GetArrayCell(a_Store, slot, 2);
	char text[64];
	GetArrayString(MenuSection[client], 0, text, sizeof(text));
	Format(text, sizeof(text), "%T", text, client);

	MenuValues[client] = GetArrayCell(a_Store, slot, 1);
	int skyPointCost = GetArrayCell(MenuValues[client], STORE_SKYPOINT_COST);
	
	ReplaceString(text, sizeof(text), "{PCT}", "%", true);
	Format(text, sizeof(text), "%T", "store item confirmation", client, text, skyPointCost);
	AddMenuItem(menu, text, text);

	SetMenuExitBackButton(menu, true);
	DisplayMenu(menu, client, 0);
}

public BuildStoreConfirmationHandle(Handle menu, MenuAction action, client, slot) {
	if (action == MenuAction_Select) {
		int pos = GetArrayCell(StoreMenuPosition[client], 0);
		MenuValues[client] = GetArrayCell(a_Store, pos, 1);
		int skyPointCost = GetArrayCell(MenuValues[client], STORE_SKYPOINT_COST);
		SkyPoints[client] -= skyPointCost;

		int currentInventory = GetArrayCell(StoreInventory[client], pos);
		SetArrayCell(StoreInventory[client], pos, currentInventory+1);

		MenuSection[client] = GetArrayCell(a_Store, pos, 2);

		char text[64];
		GetArrayString(MenuSection[client], 0, text, sizeof(text));
		Format(text, sizeof(text), "%T", text, client);
		ReplaceString(text, sizeof(text), "{PCT}", "%", true);

		PrintToChat(client, "%T", "store item purchased", client, orange, blue, text, white, orange);
		BuildStore(client);
	}
	else if (action == MenuAction_Cancel) {
		if (slot == MenuCancel_ExitBack) {
			BuildMenu(client);
		}
	}
	if (action == MenuAction_End) {
		CloseHandle(menu);
	}
}