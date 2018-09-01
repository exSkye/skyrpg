#include <sourcemod>
#define PLUGIN_VERSION "1.0.0"
#define CVAR_SHOW			FCVAR_NOTIFY | FCVAR_PLUGIN
#undef REQUIRE_PLUGIN
#include "rpg.inc"

public OnPluginStart() { RegConsoleCmd("pos", getpos); }

public Action:getpos(client, args) {

	new Float:pos[3];
	GetClientAbsOrigin(client, pos);
	PrintToChatAll("%3.3f %3.3f %3.3f", pos[0], pos[1], pos[2]);
}

public RPG_FWD_OnConfigParsed(String:ConfigName[], Handle:Array) {

	PrintToChatAll("==========================================");
	PrintToChatAll("=\tCONFIG: %s", ConfigName);
	PrintToChatAll("=\tARRAY SIZE: %d", GetArraySize(Array));
	new Handle:Section = CreateArray(64);
	new Handle:Keys = CreateArray(64);
	new Handle:Values = CreateArray(64);
	decl String:t_section[64], String:t_keys[64], String:t_values[64];
	for (new i = 0; i < GetArraySize(Array); i++) {

		Section = GetArrayCell(Array, i, 0);
		Keys = GetArrayCell(Array, i, 1);
		Values = GetArrayCell(Array, i, 2);
		GetArrayString(Handle:Section, 0, t_section, sizeof(t_section));
		PrintToChatAll("=\t\"%s\"", t_section);
		PrintToChatAll("=\t(");
		for (new ii = 0; ii < GetArraySize(Keys); ii++) {

			GetArrayString(Handle:Keys, ii, t_keys, sizeof(t_keys));
			GetArrayString(Handle:Values, ii, t_values, sizeof(t_values));
			PrintToChatAll("=\t\t\"%s\"\t\"%s\"", t_keys, t_values);
		}
		PrintToChatAll("=\t)");
	}
}