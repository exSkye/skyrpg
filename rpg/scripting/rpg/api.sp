new Handle:f_OnConfigParsed = INVALID_HANDLE;
new Handle:f_OnEventTriggered = INVALID_HANDLE;
#define PLUGIN_LIBRARY "jesshend_rpg v0.1"

public APLRes:AskPluginLoad2(Handle:g_Me, bool:b_IsLate, String:s_Error[], s_ErrorMaxSize) {

	if (LibraryExists(PLUGIN_LIBRARY)) {

		strcopy(s_Error, s_ErrorMaxSize, "Plugin Already Loaded");
		return APLRes_SilentFailure;
	}
	
	if (!IsDedicatedServer()) {

		strcopy(s_Error, s_ErrorMaxSize, "Listen Server Not Supported");
		return APLRes_Failure;
	}

	decl String:s_GameFolder[32];
	GetGameFolderName(s_GameFolder, sizeof(s_GameFolder));
	if (!StrEqual(s_GameFolder, "left4dead2", false)) {

		strcopy(s_Error, s_ErrorMaxSize, "Game Not Supported");
		return APLRes_Failure;
	}

	RegPluginLibrary(PLUGIN_LIBRARY);
	f_OnConfigParsed = CreateGlobalForward("RPG_FWD_OnConfigParsed", ET_Event, Param_String, Param_Cell);
	f_OnEventTriggered = CreateGlobalForward("RPG_FWD_OnEventTriggered", ET_Event, Param_Cell, Param_String, Param_Cell, Param_Cell);

	CreateNative("RPG_NTV_OnConfigModified", nativeOnConfigModified);
	CreateNative("RPG_NTV_OnMenuOpened", nativeOnMenuOpened);
	CreateNative("RPG_NTV_OnSortTriggers", nativeOnSortTriggers);

	return APLRes_Success;
}

public nativeOnConfigModified(Handle:plugin, params) {

	decl String:text[64];
	GetNativeString(1, text, sizeof(text));
	if (StrContains(text, CONFIG_MAINMENU, false) != -1) {

		a_MainMenu = GetNativeCell(2);
	}
	else if (StrContains(text, CONFIG_EVENTS, false) != -1) {

		a_Events = GetNativeCell(2);
	}
}

public nativeOnMenuOpened(Handle:plugin, params) {

	new client = GetNativeCell(1);
	if (!IsClient(client)) return;
	decl String:t_menu[64];
	GetNativeString(2, t_menu, sizeof(t_menu));
	Format(MenuOpened[client], sizeof(MenuOpened[]), "%s", t_menu);
	BuildMenu(client);
}

public nativeOnSortTriggers(Handle:plugin, params) {

	decl String:t_Triggers[64], String:t_EventName[64];
	new client = GetNativeCell(1);
	new victim = GetNativeCell(2);
	GetNativeString(3, t_Triggers, sizeof(t_Triggers));
	GetNativeString(4, t_EventName, sizeof(t_EventName));
	new Handle:event = GetNativeCell(5);

	OnTryAbilityTriggers(client, victim, t_Triggers, t_EventName, event);
}