stock DisconnectDataReset(int client) {
	b_IsLoaded[client] = false;
	PlayerLevel[client] = 0;
	Format(baseName[client], sizeof(baseName[]), "[RPG DISCO]");
	if (IsFakeClient(client)) return;
	IsClearedToLoad(client, _, true);
	if (bIsInCombat[client]) IncapacitateOrKill(client, _, _, true, true, true);
	bTimersRunning[client] = false;
	staggerCooldownOnTriggers[client] = false;
	ISBILED[client] = false;
	DisplayActionBar[client] = false;
	IsPvP[client] = 0;
	b_IsFloating[client] = false;
	b_IsLoading[client] = false;
	b_HardcoreMode[client] = false;
	//WipeDebuffs(_, client, true);
	IsPlayerDebugMode[client] = 0;
	CleanseStack[client] = 0;
	CounterStack[client] = 0.0;
	MultiplierStack[client] = 0;
	LoadTarget[client] = -1;
	ImmuneToAllDamage[client] = false;
	bIsSettingsCheck = true;
}