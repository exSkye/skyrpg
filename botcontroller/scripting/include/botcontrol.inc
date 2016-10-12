/**
 * =============================================================================
 * Bot Controller Framework - Library (C)2015 Jessica "jess" Henderson
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

#if defined _botcontrol_included_
  #endinput
#endif
#define _botcontrol_included_

public SharedPlugin:__pl_rup = 
{
	name = "botcontroller",
	file = "botcontroller.smx",
#if defined REQUIRE_PLUGIN
	required = 1,
#else
	required = 0,
#endif
};

/*
 *  Calling this native will force the plugin to regulate the survivor bots based
 *  on whatever the current survivor minimum and maximum requirements are.
 *  
 */
native OnRegulateSurvivorBots();

/*
 *  Forces the player to attempt to join the survivor team - or create bots. See params.
 *
 * @param client        If set to 0, will create a bot but not assign a player to it.
 *                      Will do nothing if the survivor limit has been reached.
 *
 */
native OnJoinSurvivorTeam(client);

/*
 *  Sets the Survivor Minimum and Maximum requirements. OnRegulateSurvivorBots() will not
 *  be called if BotRegulation override is enabled.
 *
 *  @param min          The minimum number of survivors that MUST exist. Humans + Bots.
 *  @param max          The maximum number of survivors that CAN exist.
 *
 */
native OnSetSurvivorRequirements(min, max);

/*
 *  Will block BotControl core from running any Survivor Bot Restriction Regulation functions.
 *  If the function is blocked, the OnRegulateSurvivorBots() native must be called for these
 *  functions to be performed.
 *
 */
native OnBlockSurvivorBotRegulation();

/*
 *
 *  Will allow BotControl core to run all Survivor Bot Restriction Regulation functions.
 *  This is the default setting. Don't forget to call this OnPluginEnd() if your plugin
 *  blocks the functionality!!!
 *
 */
native OnAllowSurvivorBotRegulation();

/*
 *
 *	Will allow survivor bots to be in-game even if there are no human survivors in-game.
 *
 */
native OnAllowSoloSurvivorBots();

/*
 *
 *	Will not allow survivor bots to be in-game if there are no human survivors in-game.
 *
 */
native OnBlockSoloSurvivorBots();

/*
 *
 *  Allows the creation of a custom number of survivor bots.
 *  Important:  Disable SurvivorBotRegulation by the core plugin before using this native.
 *
 *  @param count        The number of Survivor Bots to create.
 *
 */
native OnCreateSurvivorBots(count);

/*
 *
 *  Allows the destruction of a custom number of survivor bots.
 *  Important:  This will not remove bots that are tied to idle players.
 *
 *  @param count        The number of Survivor Bots to destroy.
 *
 */
native OnDestroySurvivorBots(count);

/*
 *
 *	Allows the setting and management of both infected and survivor team limits.
 *
 *	@param survivorLimit	Must be a value greater than 0 or will be ignored.
 *	@param infectedLimit	Must be a value greater or equal to 0 or will be ignored.
 *
 */
native OnSlotManagement(survivorLimit, infectedLimit);

/*
 *
 *	Adjusts the values, permanently, of reserve slots.
 *
 *	@param reserveslots		The number of non-playable (unless under special circumstances) slots on the server.
 *	@param maximumslots		The number of maximum always-playable slots on the server. Make sure maxplayers is reserveslots + maximumslots.
 *	@param kickdelay		The time in seconds (int) until the player is removed (if there are reserve slots available for the connecting player)
 *							otherwise the player receives no notice and is removed immediately for the connecting player.
 *
 */
native OnReserveSlotManagement(reserveslots, maximumslots, kickdelay);

/*
 *
 *	Enables reserve slots management on the server. Note, this DOES NOT set the reserve slots, the maximum slots, and the kick delay.
 *	You MUST call OnReserveSlotManagement native (above) and set the values before enabling this (or all hell will break loose)
 *
 */
native OnAllowReserveSlots();

/*
 *
 *	The opposite of enabling.
 *
 */
native OnBlockReserveSlots();

/*
 *
 *	Provides plugins more detailed / selective options for WHICH survivor bots to remove.
 *	Hope to find a way to add more than a static number of options.
 *
 *	@param count		The plugin will kick UP TO this amount of bots (if applicable)
 *	@param reqs			1 - Only one condition must pass on a bot to remove it. 2 - All received conditions must pass to remove the bot.
 *	@param param1		Currently, the native supports UP TO 3 UNIQUE params. Your options are, for example:
 *
 *						".mdl" in a param will check the param string against the bot survivor model.
 *						"!dead" as a param will require bots to be not dead.
 *						"dead" as a param will require bots to be dead.
 *						*NOTE* -> You could use 3 different models as your params, if for example, you wanted to remove bots of all those
 *								  models. However, for that to work, reqs would have to be set to 1.
 *
 *						I'd really love to add more, or, if possible, IF GetNativeArray will allow me to pass an ADT Array...
 *						!-- IMPORTANT --!
 *						Because this native is expected to be used under special circumstances, it DOES NOT adjust the survivor bot minimum
 *						requirement after kicking bots in this way, in the assumption that an author will do something with the forward that
 *						immediately follows, OnDestroySurvivorBotsFwd.
 *
 */
native OnDestroySurvivorBotsEx(count, reqs, String:param1[], String:param2[], String:param3[]);

/*
 *
 *	The only purpose of this native is to request whether Bot Regulation is enabled or disabled on the core plugin.
 *	Will shoot off the OnRequestSurvivorBotRegulationFwd forward.
 *
 */
native OnRequestSurvivorBotRegulation();

/*
 *
 *	When a new bot is created, sends out information about the bot and new client.
 *	Requested by DeathChaos25
 *
 *	@Param client		The Client ID of the player who will be taking ownership of the bot.
 *	@Param cnetp		The net prop ID of the bot.
 *	@Param cmodel		The character model of the bot.
 *
 */
forward OnBotCreatedFwd(client, cnetp, String:cmodel[]);

/*
 *
 *	After all eligible bots have been removed, this forward fires, notifying plugins of the number
 *	of bots that were removed - it's possible the number may differ from the value the plugin that
 *	triggered this forward requested be removed.
 *
 *	@Param count		The number of survivor bots that were kicked through OnDestroySurvivorBotsEx native.
 *
 */
forward OnDestroySurvivorBotsFwd(count);

/*
 *
 *	This forward is called when OnRequestSurvivorBotRegulation native is called. It will notify any listening
 *	plugins on whether or not Bot Regulation is automated through the plugin or not.
 *
 *	@Bool IsEnabled		0 for disabled, 1 for enabled.
 *
 */
forward OnRequestSurvivorBotRegulationFwd(bool:IsEnabled);

/*
 *
 *	This forward is called when the first client loads into the game.
 *
 */
forward OnFirstClientLoadedFwd();

/*
 *
 *	This forward fires when a player goes idle and is moved to the spectator team.
 *
 *	@Param client		The client ID.
 *	@Param PrmWpn		The String of the Primary weapon. Is -1 if no weapon found.
 *	@Param PrmUp		The upgrades for the Primary weapon. Is -1 if no weapon.
 *	@Param SecWpn		The String of the Secondary weapon. Is -1 if no weapon found.
 *	@Param SecUp		The upgrades for the Secondary weapon. Is -1 if no weapon.
 *	@Param GrnWpn		The grenade the player is holding, -1 if not found.
 *	@Param AidWpn		The First Aid item the player is holding, -1 if not found.
 *	@Param PillsWpn		The Pills item the player is holding, -1 if not found.
 *
 */
forward OnSurvivorIdleFwd(client, String:PrmWpn[], PrmUp, String:SecWpn[], SecUp, String:GrnWpn[], String:AidWpn[], String:PillsWpn[]);

/*
 *
 *    This forward fires when a player who was an idle Survivor has rejoined the game.
 *
 *    @Param client        The client ID.
 *
 */
forward OnSurvivorIdleEndFwd(client);

/*
 *
 *		After a player has successfully cleared the reserve slots check, broadcast it.
 *		Bot Controller doesn't handle players joining on its own - so another plugin has to do it.
 *
 *		@Param client		The client ID.
 *
 */
forward OnAnyClientLoaded(client);