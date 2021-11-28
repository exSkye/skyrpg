/**
 * =============================================================================
 * Left 4 Dead Stocks Library (C)2012 Michael "Sky" Toth
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

#if defined _wrap_included
 #endinput
#endif
#define _wrap_included

#include <sourcemod>

stock ForceServerCommand(const String:command[]) {
	
	new iFlags = GetCommandFlags(command);
	SetCommandFlags(command, iFlags & ~(FCVAR_CHEAT|FCVAR_LAUNCHER));
	ServerCommand("%s", command);
	ServerExecute();
	SetCommandFlags(command, iFlags);
	SetCommandFlags(command, iFlags | FCVAR_CHEAT);
}

stock OverrideCommand(const String:command[])
{
	new iFlags = GetCommandFlags(command);
	SetCommandFlags(command, iFlags & ~FCVAR_CHEAT);

	ServerCommand("%s", command);

	SetCommandFlags(command, iFlags);
	SetCommandFlags(command, iFlags | FCVAR_CHEAT);
}

stock String:SeparateString(String:text[], character, type) {
	
	decl String:rtext[64];
	decl String:stext[64];
	Format(stext, sizeof(stext), "%s", text);
	for (new i = 0; i <= strlen(text); i++) {

		if (type == 0) {

			if (StrEqual(text[i], character)) break;
			rtext[i] = text[i];
		}
		if (type == 1) {

			if (StrEqual(text[i], character)) {

				IntToString(i, rtext, sizeof(rtext));
				break;
			}
		}
	}
	return rtext;
}

stock ExecCheatCommand(client = 0,const String:command[],const String:parameters[] = "")
{
	new iFlags = GetCommandFlags(command);
	SetCommandFlags(command,iFlags & ~FCVAR_CHEAT);

	if(!IsClientActual(client))
	{
		ServerCommand("%s %s",command,parameters);
	}
	else
	{
		FakeClientCommand(client,"%s %s",command,parameters);
	}

	SetCommandFlags(command,iFlags);
	SetCommandFlags(command,iFlags|FCVAR_CHEAT);
}

stock bool:IsClientActual(client)
{
	if (client < 1 || client > MaxClients || !IsClientConnected(client)) return false;
	return true;
}

stock bool:IsClientBot(client)
{
	if (!IsClientActual(client)) return false;
	if (IsFakeClient(client)) return true;
	return false;
}

stock bool:IsClientHuman(client)
{
	if (IsClientActual(client) && IsClientInGame(client) && !IsFakeClient(client)) return true;
	return false;
}

stock bool:IsGhost(client)
{
	return bool:GetEntProp(client, Prop_Send, "m_isGhost", 1);
}

stock ReturnZombieClass(client) {

	if (client == 1) return 
}

#define ZOMBIECLASS_SMOKER											1
#define ZOMBIECLASS_BOOMER											2
#define ZOMBIECLASS_HUNTER											3
#define ZOMBIECLASS_SPITTER											4
#define ZOMBIECLASS_JOCKEY											5
#define ZOMBIECLASS_CHARGER											6
#define ZOMBIECLASS_TANK											8
#define ZOMBIECLASS_SURVIVOR										0

stock bool:HasCommandAccessEx(client, String:permissions[]) {

	if (!IsClientActual(client)) return false;
	decl flags;
	flags = GetUserFlagBits(client);
	decl cflags;
	cflags = ReadFlagString(permissions);
	
	if (flags & cflags) return true;
	return false;
}

stock ValidSurvivors()
{
	new count = 0;
	for (new i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && !IsFakeClient(i) && GetClientTeam(i) == TEAM_SURVIVOR && IsPlayerAlive(i)) count++;
	}
	return count;
}

stock PlayersInVicinity(client, Float:range) {
	
	new Float:pos[3];
	new Float:cpos[3];
	new count = 0;
	GetClientAbsOrigin(client, Float:cpos);

	for (new i = 1; i <= MaxClients; i++) {

		if (IsClientInGame(i) && !IsFakeClient(i) && GetClientTeam(i) == GetClientTeam(client) && i != client && IsPlayerAlive(i)) {

			GetClientAbsOrigin(i, Float:pos);
			if (GetVectorDistance(cpos, pos) <= range) count++;
		}
	}

	return count;
}

stock bool:PlayersOutOfRange(entity, Float:range)
{
	new Float:tPos[3];
	if (entity > 0 && IsValidEntity(entity)) {

		decl String:CName[128];
		GetEntityClassname(entity, CName, sizeof(CName));
		if (StrEqual(CName, "prop_door_rotating_checkpoint", false)) {

			GetEntPropVector(entity, Prop_Send, "m_vecOrigin", tPos);

			new Float:pPos[3];
			for (new i = 1; i <= MaxClients; i++)
			{
				if (!IsClientInGame(i) || IsFakeClient(i) || GetClientTeam(i) != TEAM_SURVIVOR || !IsPlayerAlive(i)) continue;
				GetClientAbsOrigin(i, Float:pPos);
				if (GetVectorDistance(pPos, tPos) > range) return true;
			}
			return false;
		}
		else {

			return false;
		}
	}
	return true;
}

stock bool:IsSurvival()
{
	decl String:GameType[128];
	GetConVarString(FindConVar("mp_gamemode"), GameType, 128);
	if (StrEqual(GameType, "survival")) return true;
	return false;
}

stock bool:IsIncapacitated(client)
{
	return bool:GetEntProp(client, Prop_Send, "m_isIncapacitated");
}