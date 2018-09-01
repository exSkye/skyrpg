/*
 * =============================================================================
 * RPG Core (C)2016 Jessica "jess" Henderson
 * =============================================================================
 *
 * This program is free software; you can redistribute it and/or modify it under
 * the terms of the GNU General Public License, version 3.0, as published by the
 * Free Software Foundation.
 * 
 * This program is distributed in the hope that it will be useful, but WITHOUT
 * ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
 * FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more
 * details.
 *
 * You should have received a copy of the GNU General Public License along with
 * this program.  If not, see <http://www.gnu.org/licenses/>.
 *
 * As a special exception, AlliedModders LLC gives you permission to link the
 * code of this program (as well as its derivative works) to "Half-Life 2," the
 * "Source Engine," the "SourcePawn JIT," and any Game MODs that run on software
 * by the Valve Corporation.  You must obey the GNU General Public License in
 * all respects for all other code used.  Additionally, AlliedModders LLC grants
 * this exception to all derivative works.  AlliedModders LLC defines further
 * exceptions, found in LICENSE.txt (as of this writing, version JULY-31-2007),
 * or <http://www.sourcemod.net/license.php>.
 */

 /*


 		WHAT MAKES RPG 2 SO UNIQUE?

 		Ability activation identifiers are defined by the user instead of
 		hard-coded. The following keys are available in events now:

 		"survivor ability identifiers" and "infected ability identifiers"

 		For any survivor or infected player involved, for each character (upper/lower matters!) found, the plugin
 		will trigger an attempt on that ability. It's important to note that it's the server operator's
 		responsibility, as a result, to make sure there is an ability with the identifier attached to it, or
 		no ability for that identifier will be attempted, because it won't exist.

 		WHY IS THIS AWESOME?

 		Using forwards and natives, I can let other plugins know which abilities are currently being
 		requested, as well as allow them, using natives, to call its own triggers, etc., or make changes, etc.
 		to abilities on the fly, or whatever else someone decides to do.
 		And, there are natives and forwards setup for allowing other plugins to add-on to menus, general gameplay
 		and whatever, really.

 		2016-06-02

 		Players can find and equip equipment in the game that modifies their statistics, or gives bonuses like:
 		+Amount <Random Talent> - Increases the said talent by x levels when this item is equipped.
 		+Amount <Random Stat> - Increases the said statistic by x when this item is equipped. (Crit Bonus, etc.)
 		+Amount <Armor> - Increases armor by x amount when this item is equipped. Lowers the amount of damage a player takes, because RPG allows increased damage.


 		In the new leveling system:

 		Physical Rank
 		- Reaching the Physical XP Goal rewards the player with 1 skill point.
 		- The Physical XP Goal is the combined XP requirement of all skills in the category.

 		Survivor Rank
 		- Survivor Rank XP is earned when dealing damage to a special infected.
 		- Reaching the Survivor XP Goal rewards the player with 1 survivor point.
 		- Survivor points can upgrade survivor talents.
 		- Survivor Rank XP is hindered when dealing damage to a special infected with a lower Infected Rank than their Survivor Rank.

 		2016-06-07

 		Talents can be either found on gear (gear-based)

 		AUGUST 14 2016****
 		Loot shooter: Weapons w/ mods can drop from specials (and commons) , which can have talents of their own (like the scope mod and magazine mod could have separate talents.
 		The potential strength of an item drop is based on the level range of player participants against that special infected; against common infected, it's a private drop pool, based on your level.
 		All loot obtained from special infected can be shared with anyone who helped kill said special infected.

 		Option for the passive talent system from all my previous RPGS, or a mixture of it and the one above.
 		Also, a class system, where leveling up strengthens your class (scalar values are set in config for each class / level) which could be used alone, or with any of the above 3 talent structures.

 		Talent?
 		LANDMINE: On grenade explosion, create a landmine x Units, which detonates hitting players for y damage.
 		x is a range based on the level of all participants, and y is a range as well.

 		HEALING AURA: Creates a healing aura, using a green circle, around the player (survivor or infected) which heals aliies within it.
 		The player is immobilized and receives double damage while channeling.

 		SHIELD AURA: Creates a shielding aura, using a blue circle, around the player (survivor or infected) which shields teammates within the
 		area from damage. The percentage mitigated is based on the level.
 */

#define TEAM3		3
#define TEAM2		2
#define TEAM1	 	1

#define PLUGIN_VERSION "rpg reloaded"
#define CONFIG_MAINMENU "rpg_menu.cfg"
#define CONFIG_EVENTS "rpg_events.cfg"
#define CONFIG_ABILITIES "rpg_abilities.cfg"
#define CONFIG_VENDORS "rpg_vendors.cfg"
#define CONFIG_GENERAL "rpg_config.cfg"

#include <sourcemod>
#include <sdkhooks>
#include <sdktools>

public Plugin:myinfo = { name = "rpg reloaded", author = "url", description = "rpg remake", version = PLUGIN_VERSION, url = "0.01", };

/*


							We need to create the handles that will handle each forward. And potentially, handle me.
							I need to figure out a way to create these dynamically.


*/
new String:cfgPath[64];
new String:cfgPathEx[64];
new String:MenuOpened[MAXPLAYERS+1][64];
new vendorOpened[MAXPLAYERS+1];
new String:MenuPrevious[MAXPLAYERS+1][64];
new Handle:MenuPrevious_h[MAXPLAYERS + 1];

/*

		The following handles are arrays used to hold text data like menus, talents, player data, etc.
		Each Handle is followed by a integer variable, so we don't parse a file if nothing has changed.

*/

new Handle:RPGMenuPosition[MAXPLAYERS+1];
new Handle:a_Section[MAXPLAYERS+1];
new Handle:a_Keys[MAXPLAYERS+1];
new Handle:a_Values[MAXPLAYERS+1];
new Handle:fs_Header;
new Handle:fs_Keys;
new Handle:fs_Values;

new Handle:a_MainMenu;
new Handle:a_SearchKeys[MAXPLAYERS+1];
new Handle:a_SearchKeys_List;
new Handle:a_Events;
new Handle:a_Config;
new Handle:a_Config_Keys;
new Handle:a_Config_Values;
new Handle:a_Vendors;
new Handle:a_VendorEntity_Keys;
new Handle:a_VendorEntity_Values;

new ft_MainMenu;

new Float:Points[MAXPLAYERS+1];
new Handle:a_Backpack[MAXPLAYERS + 1];

/*


		Create some basic experience vars so we can setup the menu.


*/
new v_experience[MAXPLAYERS+1];		// players earn experience for killing shit.
new v_talentPoints[MAXPLAYERS+1];	// players earn talent points for leveling up.
new v_level[MAXPLAYERS+1];			// player level determines max gear-level drop.
new v_levelMax[MAXPLAYERS+1];		// players max level achieved. possible to de-level in my default build, and talent points are only obtained for surpassing your max-achieved level.

/*
Survivor SLATE:

Perception	 (As Survivor, you'll be notified if infected players come within a certain distance of you. Distance detection rises with each point.)
				As Infected, your Perception rating will lower any nearby survivors Perception rating, and if yours is GREATER than theirs, they will not detect you at all.)
Luck		   (As both Survivor & Infected, uses each talents "luck modifier?" to determine the bonus roll chance.
				Weight of the bonus is based on the difference in Luck rating between the two players.
Awareness	  (As Survivor, increased likelihood of enemy special infected dropping items if you land the killing blow.
				As Infected, increased chance of critical hits, or double-damage, which also increase the experience earned.
Intelligence	(Anything that costs experience, costs a little bit less.
*/

#include "rpg/api.sp"
#include "rpg_functions.inc"

/*

		OnPluginStart() is used to initialize the arrays before data is placed inside of them.

*/

public OnPluginStart() {

	CreateConVar("rpg_version", "In-Development", PLUGIN_LIBRARY);

	fs_Header			= CreateArray(64);
	fs_Keys				= CreateArray(64);
	fs_Values			= CreateArray(64);
	a_MainMenu			= CreateArray(3);
	a_SearchKeys_List	= CreateArray(64);
	a_Events			= CreateArray(3);
	a_Config			= CreateArray(3);
	a_Config_Keys		= CreateArray(64);
	a_Config_Values		= CreateArray(64);
	a_Vendors			= CreateArray(3);
	a_VendorEntity_Keys	= CreateArray(64);
	a_VendorEntity_Values = CreateArray(64);

	for (new i=1; i<=MAXPLAYERS; i++) {

		RPGMenuPosition[i]		= CreateArray(64);
		a_Section[i]			= CreateArray(64);
		a_Keys[i]				= CreateArray(64);
		a_Values[i]				= CreateArray(64);
		a_SearchKeys[i]			= CreateArray(64);
		Points[i]				= 0.0;
		a_Backpack[i]			= CreateArray(64);
		MenuPrevious_h[i]		= CreateArray(64);		// trying something.
		v_level[i] = 50;

	}

	RegConsoleCmd("rpg", cmd_MainMenu);
	LoadTranslations("rpg.phrases");
}

public OnMapEnd() {

	for (new i=1; i<=MAXPLAYERS; i++) {

		ClearArray(RPGMenuPosition[i]);
		ClearArray(a_Section[i]);
		ClearArray(a_Keys[i]);
		ClearArray(a_Values[i]);
		ClearArray(a_SearchKeys[i]);
		ClearArray(a_Backpack[i]);
		ClearArray(MenuPrevious_h[i]);
	}
}

public Action:cmd_MainMenu(client, args) {

	ClearArray(MenuPrevious_h[client]);
	Format(MenuOpened[client], sizeof(MenuOpened[]), "MainMenu");
	vendorOpened[client] = -1;
	BuildMenu(client);
	Call_StartForward(f_OnConfigParsed);
	Call_PushString(CONFIG_VENDORS);
	Call_PushCell(a_Vendors);
	Call_Finish();
}

/*


			OnConfigsExecuted is used, in this particular case, to parse a config file which details which
			gamemodes should be recognized as which game types. It checks if the config exists, and if it
			doesn't, attempts to create it. If this fails, we SetFailState, otherwise we continue as planned.


*/

public OnConfigsExecuted() {

	BuildPath(Path_SM, cfgPath, sizeof(cfgPath), "configs/");
	ClearArray(Handle:a_MainMenu);
	ClearArray(Handle:a_SearchKeys_List);
	ClearArray(Handle:a_Events);
	ClearArray(Handle:a_Config);
	ClearArray(Handle:a_Config_Keys);
	ClearArray(Handle:a_Config_Values);
	ClearArray(Handle:a_Vendors);
	ClearArray(Handle:a_VendorEntity_Keys);
	ClearArray(Handle:a_VendorEntity_Values);

	Format(cfgPathEx, sizeof(cfgPathEx), "%s%s", cfgPath, CONFIG_MAINMENU);
	if (!ParseConfigFile(cfgPathEx)) SetFailState("%s Improperly formatted.", cfgPathEx);
	Call_StartForward(f_OnConfigParsed);
	Call_PushString(CONFIG_MAINMENU);
	Call_PushCell(a_MainMenu);
	Call_Finish();
	Format(cfgPathEx, sizeof(cfgPathEx), "%s%s", cfgPath, CONFIG_EVENTS);
	if (!ParseConfigFile(cfgPathEx)) SetFailState("%s Improperly formatted.", cfgPathEx);
	Call_StartForward(f_OnConfigParsed);
	Call_PushString(CONFIG_EVENTS);
	Call_PushCell(a_Events);
	Call_Finish();
	Format(cfgPathEx, sizeof(cfgPathEx), "%s%s", cfgPath, CONFIG_VENDORS);
	if (!ParseConfigFile(cfgPathEx)) SetFailState("%s Improperly formatted.", cfgPathEx);
	Call_StartForward(f_OnConfigParsed);
	Call_PushString(CONFIG_VENDORS);
	Call_PushCell(a_Vendors);
	Call_Finish();
	Format(cfgPathEx, sizeof(cfgPathEx), "%s%s", cfgPath, CONFIG_GENERAL);
	if (!ParseConfigFile(cfgPathEx)) SetFailState("%s Improperly formatted.", cfgPathEx);
	Call_StartForward(f_OnConfigParsed);
	Call_PushString(CONFIG_GENERAL);
	Call_PushCell(a_Config);
	Call_Finish();
	/*

			Now we get to execute all the cool stuff we worked the back-end so hard for!

	*/
	SpawnVendors();
}

public bool:IsItemUnlocked(client, String:searchkey[]) {

	decl String:text[64];

	new size = GetArraySize(a_SearchKeys_List);
	for (new i = 0; i < size; i++) {

		GetArrayString(a_SearchKeys_List, i, text, sizeof(text));
		if (!StrEqual(text, searchkey, false)) continue;

		GetArrayString(a_SearchKeys[client], i, text, sizeof(text));

		break;
	}

	if (StringToInt(text) == 1) return true;
	return false;
}

stock bool:ParseConfigFile(const String:file[]) {

	new Handle:hParser = SMC_CreateParser();
	new String:error[128];
	new line = 0;
	new col = 0;

	SMC_SetReaders(hParser, Config_NewSection, Config_KeyValue, Config_EndSection);
	SMC_SetParseEnd(hParser, Config_End);

	new SMCError:result = SMC_ParseFile(hParser, file, line, col);
	CloseHandle(hParser);

	if (result != SMCError_Okay) {

		SMC_GetErrorString(result, error, sizeof(error));
		SetFailState("Problem reading %s, line %d, col %d - error: %s", file, line, col, error);
	}

	return (result == SMCError_Okay);
}

public SMCResult:Config_NewSection(Handle:parser, const String:section[], bool:quotes) {

	/*

			When a new section begins, wipe the header, and all keys/values.
			These arrays are only wiped after their values have been stored in other arrays.

	*/
	//ClearArray(Handle:fs_Keys);
	//ClearArray(Handle:fs_Values);
	//ClearArray(Handle:fs_Header);

	/*
			Multi-dimensional arrays formatted to have 3 slots: Section Header, Key Strings, Value Strings.
	*/
	PushArrayString(fs_Header, section); /* Don't push it if not specific configs? */
	//SetArrayCell(a_MainMenu, GetArraySize(a_MainMenu), fs_Header, 0);
	return SMCParse_Continue;
}

public SMCResult:Config_KeyValue(Handle:parser, const String:key[], const String:value[], bool:ley_quotes, bool:value_quotes) {

	PushArrayString(fs_Keys, key);
	PushArrayString(fs_Values, value);
	
	return SMCParse_Continue;
}

public SMCResult:Config_EndSection(Handle:parser) {

	/*

			There will be no more keys or values added to the arrays, so we store their values because
			these global arrays will be wiped when the next section begins.

	*/
	new size = 0;
	new Handle:th_values = CloneArray(fs_Values);
	new Handle:th_keys = CloneArray(fs_Keys);
	new Handle:th_section = CloneArray(fs_Header);
	if (StrContains(cfgPathEx, CONFIG_MAINMENU, false) != -1) {

		size = GetArraySize(a_MainMenu);
		ResizeArray(a_MainMenu, size + 1);
		SetArrayCell(a_MainMenu, size, th_section, 0);
		SetArrayCell(a_MainMenu, size, th_keys, 1);
		SetArrayCell(a_MainMenu, size, th_values, 2);	
	}
	else if (StrContains(cfgPathEx, CONFIG_EVENTS, false) != -1) {

		size = GetArraySize(a_Events);
		ResizeArray(a_Events, size + 1);
		SetArrayCell(a_Events, size, th_section, 0);
		SetArrayCell(a_Events, size, th_keys, 1);
		SetArrayCell(a_Events, size, th_values, 2);
	}
	else if (StrContains(cfgPathEx, CONFIG_VENDORS, false) != -1) {

		size = GetArraySize(a_Vendors);
		ResizeArray(a_Vendors, size + 1);
		SetArrayCell(a_Vendors, size, th_section, 0);
		SetArrayCell(a_Vendors, size, th_keys, 1);
		SetArrayCell(a_Vendors, size, th_values, 2);
	}
	else if (StrContains(cfgPathEx, CONFIG_GENERAL, false) != -1) {

		size = GetArraySize(a_Config);
		ResizeArray(a_Config, size + 1);
		SetArrayCell(a_Config, size, th_section, 0);
		SetArrayCell(a_Config, size, th_keys, 1);
		SetArrayCell(a_Config, size, th_values, 2);
	}
	ClearArray(Handle:fs_Keys);
	ClearArray(Handle:fs_Values);
	ClearArray(Handle:fs_Header);
	return SMCParse_Continue;
}

public Config_End(Handle:parser, bool:halted, bool:failed) {

	if (failed) { SetFailState("Plugin configuration error"); }
}

stock RegisterEvents(bool:b_IsUnregister) {

	new Handle:h_Section = CreateArray(64);
	new Handle:h_Keys = CreateArray(64);
	new Handle:h_Values = CreateArray(64);
	decl String:t_event[64];

	for (new i = 0; i < GetArraySze(a_Events); i++) {

		h_Section = GetArrayCell(a_Events, i, 0);
		GetArrayString(Handle:h_Section, 0, t_event, sizeof(t_event));
		h_Keys = GetArrayCell(a_Events, i, 1);
		h_Values = GetArrayCell(a_Events, i, 2);

		if (StringToInt(GetConfigValue(0, h_Keys, h_Values, "event_hookmode_pre", false, false)) == 1) {

			if (b_IsUnregister) UnhookEvent(t_event, OnEventTriggered, EventHookMode_Pre);
			else HookEvent(t_event, OnEventTriggered, EventHookMode_Pre);
		}
		else {

			if (b_IsUnregister) UnhookEvent(t_event, OnEventTriggered);
			else HookEvent(t_event, OnEventTriggered);
		}
	}
}

public FindTargetVendor(client, entid) {

	new entity = 0;

	new size = GetArraySize(a_VendorEntity_Keys);
	for (new i = 0; i < size; i++) {

		entity = GetArrayCell(Handle:a_VendorEntity_Keys, i);
		if (entity == entid) {

			entity = GetArrayCell(Handle:a_VendorEntity_Values, i);
			return entity;	// return the position in the vendor array for this vendor. that way we can pull the inventory available to the player based on the vendor they're talking to.
		}
	}
	return -1;

}

public Action:OnPlayerRunCmd(client, &buttons) {

	if (buttons & IN_USE) {

		decl String:EName[64];
		new delim = 0;

		new entity = GetClientAimTarget(client, false);

		if (entity != -1) {

			GetEntPropString(entity, Prop_Data, "m_iName", EName, sizeof(EName));

			new Float:PPos[3];
			GetEntPropVector(client, Prop_Send, "m_vecOrigin", PPos);
			new Float:EPos[3];
			GetEntPropVector(entity, Prop_Send, "m_vecOrigin", EPos);
			new Float:Distance = GetVectorDistance(PPos, EPos);

			if (Distance <= 64) {

				if (StrContains(EName, ":", false) != -1) {

					delim = FindDelim(EName);
					decl String:t_value[64];
					if (GetArraySize(MenuPrevious_h[client]) > 0) GetArrayString(MenuPrevious_h[client], 0, t_value, sizeof(t_value));
					// a command is within this items name.
					if (StrContains(EName, "openmenu", false) != -1 && (!StrEqual(MenuOpened[client], EName[delim], false) || vendorOpened[client] != FindTargetVendor(client, entity)) &&
						(GetArraySize(MenuPrevious_h[client]) < 1 || !StrEqual(EName[delim], t_value))) {

						// openmenu command is found.
						Format(MenuOpened[client], sizeof(MenuOpened[]), EName[delim]);
						vendorOpened[client] = FindTargetVendor(client, entity);
						BuildMenu(client);
					}
				}
			}
		}
	}
	/*if (client > 0 && IsPlayerAlive(client)) {

		decl String:AbilityEffects[10];
		new zombieclass = 0;

		if (GetClientTeam(client) == 3) {

			zombieclass = GetEntProp(client, Prop_Send, "m_zombieClass");

			if (buttons & IN_ATTACK2) {

				Format(AbilityEffects, sizeof(AbilityEffects), "%s", GetEffectsOfTrigger(client, zombieclass, 'a'));
				If (!StrEqual(AbilityEffects, "-1")) ActivateEffects(client, zombieclass, AbilityEffects);

				if (L4D2_GetSurvivorVictim(client) != -1) {

					Format(AbilityEffects, sizeof(AbilityEffects), "%s", GetEffectsOfTrigger(client, zombieclass, 'A'));
					if (!StrEqual(AbilityEffects, "-1")) ActivateEffects(client, zombieclass, AbilityEffects);
				}
			}
		}
	}*/

	return Plugin_Continue;
}


#include "rpg/menu.sp"
#include "rpg/events.sp"