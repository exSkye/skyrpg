/**
 * =============================================================================
 * Ready Up - Reloaded - Core Library (C)2015 Jessica "jess" Henderson
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

#if defined _readyup_included_
  #endinput
#endif
#define _readyup_included_

public SharedPlugin:__pl_rup = 
{
	name = "rur_core",
	file = "rur_core.smx",
#if defined REQUIRE_PLUGIN
	required = 1,
#else
	required = 0,
#endif
};

/*
 *
 *		THE ORDER THE FORWARDS ARE FIRED IN IS AS FOLLOWS:
 *
 *		OnFirstClientLoaded()
 *		OnAllClientsLoaded()
 *		OnReadyUpStart()*
 *		OnReadyUpEnd()*
 *		OnRoundStart()
 *		OnRoundEnd()
 *    OnMapAboutToEnd()**
 *		*	These can be forced by their respective Ex native; for example, OnReadyUpStartEx.
 *			However, they can only be forced if they have not yet been called by the core plugin
 *			and OnReadyUpEnd cannot be forced until OnReadyUpStart has been called. OnReadyUpStart
 *			can be called as soon as the plugin has loaded - even before the first client, if desired.
 *			OnReadyUpStart also fires as soon as teams swap in versus game modes.
 *			Note:	OnRoundStart always fires when the first survivor leaves the safe area/safe room
 *					after either and only at this point. However, it cannot fire until OnReadyUpEnd has
 *					fired. Please keep this in mind as failing to call OnReadyUpEnd could cause the round
 *					to halt, but this only occurs if another plugin is preventing the readyup period from
 *					instantly ending (triggering OnRoundStart) when the first survivor leaves the safe area
 *					after OnAllClientsLoaded has been called.
 *    ** This fires immediately after OnRoundEnd if it's the last round of the map, or when the survivors
 *       in coop have successfully completed a level.
 *
 */

/*
 *
 *		This forward is triggered, immediately, when any survivor player leaves the safe area
 *		for the first time, but ONLY after OnReadyUpEnd has fired. Otherwise the player will just be
 *		teleported back into the safe area.
 *
 */
forward OnRoundStart();

/*
 *
 *		When the survivors successfully clear a level in campaign, as well as when a round ends
 *		in versus or survival, this forward will be called.
 *
 */
forward OnRoundEnd();

/*
 *
 *		Triggers when the first connected user triggers OnClientPostAdminCheck on a new map.
 *		This will only trigger ONE TIME per map, and will not trigger for a user that disconnects
 *		prior to this stage.
 *
 */
forward OnFirstClientLoaded();

/*
 *
 *		Triggers when the last connecting client successfully clears OnClientPostAdminCheck. When
 *		a client disconnects from the server, if OnAllClientsLoaded hasn't already been called, it
 *		will check to see if all clients have loaded.
 *
 */
forward OnAllClientsLoaded();

/*
 *
 *		This forward is triggered when all clients have successfully loaded or, in versus game-types
 *		after a round ends, and when teams have switched sides. This forward fires BEFORE OnRoundStart().
 *		NOTE:	This forward can be forced by another plugin using the OnReadyUpStartEx native, and can be
 *				forced at any time, even before OnFirstClientLoaded has fired.
 *
 */
forward OnReadyUpStart();

 /*
  *
  *		This forward is fired when the first survivor player leaves the safe area AFTER OnReadyUpEnd has fired.
  *		Note:	It will ALWAYS fire before OnRoundStart, but immediately before if the core plugin is allowed to fire
  *				OnReadyUpEnd. However, if another plugin called OnReadyUpEndBlock, this forward will only fire when
  *				another plugin calls it, so it's important that a plugin actually call it if the core plugin is blocked
  *				from calling it, itself, otherwise the ready up period will never end.
  *
  */
forward OnReadyUpEnd();

/*
 *
 *    This forward is called when the last round is completed on a map in versus, or when the survivors in coop
 *    successfully clear the level.
 *
 */
forward OnMapAboutToEnd();

 /*
  *
  *		This native allows a plugin to force OnreadyUpStart to fire in the core plugin.
  *		Note:	Forcing it in this way only works if it hasn't already been called by the core plugin.
  *
  */
 native OnReadyUpStartEx();

 /*
  *
  *		This native allows a plugin to force OnReadyUpEnd to fire. This is useful if a plugin has disabled the core plugins
  *		ability to fire OnReadyUpEnd. Correction, it's not useful in this scenario, it's required.
  *
  */
 native OnReadyUpEndEx();

 /*
  *
  *		This native allows a plugin to prevent the core ready up plugin from being able to end the ready up period. This means
  *		that another plugin must call OnReadyUpEndEx to end the ready up period at some point, or the round will obviously never begin.
  *
  */
 native OnReadyUpEndBlock();

 /*
  *
  *		No explanation needed, here... It really just gives the ready up core plugin back the ability to end the ready up period without
  *		another plugin having to force it to fire. If a plugin takes away ready up core's ability to do this, it's important to call this
  *		native if a plugin that blocks it unloads, for any reason.
  *
  */
 native OnReadyUpEndAllow();