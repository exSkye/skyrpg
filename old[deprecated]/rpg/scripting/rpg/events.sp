/*
 * =============================================================================
 * RPG - Events (C)2015 Jessica "jess" Henderson
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

public Action:OnEventTriggered(Handle:event, String:NameOfEvent[], bool:dontBroadcast) {

	decl String:NameOfSearch[64];
	new Handle:a_NameOfEvent = CreateArray(64);

	new pos = OnEventSearch(NameOfEvent);
	if (pos == -1) return;

	new Handle:h_Keys = CreateArray(64), Handle:h_Values = CreateArray(64);
	h_Keys = GetArrayCell(a_Events, pos, 1);
	h_Values = GetArrayCell(a_Events, pos, 2);

	/*

			Send out the information about the event.
	*/
	Call_StartForward(f_OnEventTriggered);
	Call_PushCell(event);
	Call_PushString(NameOfEvent);
	Call_PushCell(h_Keys);
	Call_PushCell(h_Values);
	Call_Finish();

	ClearArray(Handle:h_Keys);
	ClearArray(Handle:h_Values);
}

/*

		Talent ability triggers / ability strings support multiple options, so this function
		servers to cycle through all of the available options and attempting to trigger
		each one.

		This function doesn't control whether an attempted trigger is successful.
*/
public OnTryAbilityTriggers(client, victim, String:t_AbilityActivators[], String:t_EventName[], Handle:event) {

	for (new i = 0; i < strlen(t_AbilityActivators); i++) {

		OnTryAbilityTriggersEx(client, victim, t_AbilityActivators[i], event);
	}
}

/*


		This function rolls ability chances, and if successful, will then officially
		activate the ability.
*/
public OnTryAbilityTriggersEx(client, victim, ability, Handle:event) {

	
}



stock FindAbilityByTrigger(activator, target = 0, ability, zombieclass = 0, d_Damage) {

	if (IsLegitimateClient(activator) && ((IsFakeClient(activator) && GetClientTeam(activator) == TEAM_INFECTED) || !IsFakeClient(activator))) {

		new a_Size			=	0;

		if (zombieclass == 0) a_Size		=	GetArraySize(a_Menu_Talents_Survivor);
		else a_Size	=	GetArraySize(a_Menu_Talents_Infected);

		//new b_Size			=	0;

		decl String:TalentName[64];
		//decl String:s_key[64];
		//decl String:s_value[64];

		for (new i = 0; i < a_Size; i++) {

			if (!IsFakeClient(activator) && (GetClientTeam(activator) == TEAM_SURVIVOR || zombieclass == 0)) {

				TriggerKeys[activator]				=	GetArrayCell(a_Menu_Talents_Survivor, i, 0);
				TriggerValues[activator]			=	GetArrayCell(a_Menu_Talents_Survivor, i, 1);
				TriggerSection[activator]			=	GetArrayCell(a_Menu_Talents_Survivor, i, 2);
			}
			else if (GetClientTeam(activator) == TEAM_INFECTED) {

				TriggerKeys[activator]				=	GetArrayCell(a_Menu_Talents_Infected, i, 0);
				TriggerValues[activator]			=	GetArrayCell(a_Menu_Talents_Infected, i, 1);
				TriggerSection[activator]			=	GetArrayCell(a_Menu_Talents_Infected, i, 2);
			}
			else {

				LogMessage("Could not determine which talent section to pull from, cancelling ability trigger.");
				return;
			}

			GetArrayString(Handle:TriggerSection[activator], 0, TalentName, sizeof(TalentName));

			if (FindCharInString(GetKeyValue(TriggerKeys[activator], TriggerValues[activator], "ability trigger?"), ability) != -1) {

				ActivateAbility(activator, target, i, d_Damage, FindZombieClass(activator), TriggerKeys[activator], TriggerValues[activator], TalentName, ability);
			}

			/*b_Size			=	GetArraySize(TriggerKeys[client]);
			for (new ii = 0; ii < b_Size; ii++) {

				GetArrayString(Handle:TriggerKeys[client], ii, s_key, sizeof(s_key));
				GetArrayString(Handle:TriggerValues[client], ii, s_value, sizeof(s_value));

				if (StrEqual(s_key, "ability trigger?") && FindCharInString(s_value, ability) != -1) {

					ActivateAbility(client, victim, i, d_Damage, FindZombieClass(client), TriggerKeys[client], TriggerValues[client], TalentName, ability);
				}
			}*/
		}
	}
}

public FindDelim(String:EntityName[]) {

	for (new i = 0; i <= strlen(EntityName); i++) {

		if (StrContains(EntityName[i], ":", false) == -1) {

			// Found it!
			return i;
		}
	}
	return -1;
}