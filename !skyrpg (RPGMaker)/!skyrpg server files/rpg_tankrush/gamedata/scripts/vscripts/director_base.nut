//======== Copyright (c) 2009, Valve Corporation, All rights reserved. ========
//
//=============================================================================

printl( "Initializing Director's script" );

// this is temp and  will be an enum from gamecode

FINALE_GAUNTLET_1 <- 0
FINALE_HORDE_ATTACK_1 <- 1
FINALE_HALFTIME_BOSS <- 2
FINALE_GAUNTLET_2 <- 3
FINALE_HORDE_ATTACK_2 <- 4
FINALE_FINAL_BOSS <- 5
FINALE_HORDE_ESCAPE <- 6
FINALE_CUSTOM_PANIC <- 7
FINALE_CUSTOM_TANK <- 8
FINALE_CUSTOM_SCRIPTED <- 9
FINALE_CUSTOM_DELAY <- 10
FINALE_GAUNTLET_START <- 11
FINALE_GAUNTLET_HORDE <- 12
FINALE_GAUNTLET_HORDE_BONUSTIME <- 13
FINALE_GAUNTLET_BOSS_INCOMING <- 14
FINALE_GAUNTLET_BOSS <- 15
FINALE_GAUNTLET_ESCAPE <- 16

DirectorOptions <-
{

	finaleStageList = []
	OnChangeFinaleMusic	= ""

	function OnChangeFinaleStage( from, to)
	{
		OnChangeFinaleMusic = finaleStageList[to];
	}

	MaxSpecials = 30
	MaxMinions = 30
}

// temporarily leaving stage strings as diagnostic for gauntlet mode
DirectorOptions.finaleStageList.insert( FINALE_GAUNTLET_1, "FINALE_GAUNTLET_1" );
DirectorOptions.finaleStageList.insert( FINALE_HORDE_ATTACK_1, "Event.FinaleStart" );
DirectorOptions.finaleStageList.insert( FINALE_HALFTIME_BOSS, "Event.TankMidpoint" );
DirectorOptions.finaleStageList.insert( FINALE_GAUNTLET_2, "FINALE_GAUNTLET_2" );
DirectorOptions.finaleStageList.insert( FINALE_HORDE_ATTACK_2, "Event.FinaleWave4" );
DirectorOptions.finaleStageList.insert( FINALE_FINAL_BOSS, "Event.TankBrothers" );
DirectorOptions.finaleStageList.insert( FINALE_HORDE_ESCAPE, "" );
DirectorOptions.finaleStageList.insert( FINALE_CUSTOM_PANIC, "FINALE_CUSTOM_PANIC" );
DirectorOptions.finaleStageList.insert( FINALE_CUSTOM_TANK, "Event.TankMidpoint" );
DirectorOptions.finaleStageList.insert( FINALE_CUSTOM_SCRIPTED, "FINALE_CUSTOM_SCRIPTED" );
DirectorOptions.finaleStageList.insert( FINALE_CUSTOM_DELAY, "FINALE_CUSTOM_DELAY" );
DirectorOptions.finaleStageList.insert( FINALE_GAUNTLET_START, "Event.FinaleStart" );
DirectorOptions.finaleStageList.insert( FINALE_GAUNTLET_HORDE, "FINALE_GAUNTLET_HORDE" );
DirectorOptions.finaleStageList.insert( FINALE_GAUNTLET_HORDE_BONUSTIME, "FINALE_GAUNTLET_HORDE_BONUSTIME" );
DirectorOptions.finaleStageList.insert( FINALE_GAUNTLET_BOSS_INCOMING, "Event.TankMidpoint" );
DirectorOptions.finaleStageList.insert( FINALE_GAUNTLET_BOSS, "FINALE_GAUNTLET_BOSS" );
DirectorOptions.finaleStageList.insert( FINALE_GAUNTLET_ESCAPE, "" );
	

function GetDirectorOptions()
{
	local result;
	if ( "DirectorOptions" in DirectorScript )
	{
		result = DirectorScript.DirectorOptions;
	}
	
	if ( DirectorScript.MapScript.rawin( "DirectorOptions") )
	{
		if ( result != null )
		{
				delegate result : DirectorScript.MapScript.DirectorOptions;
		}
		result = DirectorScript.MapScript.DirectorOptions;
	}

	if ( DirectorScript.MapScript.LocalScript.rawin( "DirectorOptions") )
	{
		if ( result != null )
		{
			delegate result : DirectorScript.MapScript.LocalScript.DirectorOptions;
		}
		result = DirectorScript.MapScript.LocalScript.DirectorOptions;
	}

	if ( DirectorScript.ChallengeScript.rawin( "DirectorOptions") )
	{
		if ( result != null )
		{
			delegate result : DirectorScript.ChallengeScript.DirectorOptions;
		}
		result = DirectorScript.ChallengeScript.DirectorOptions;
	}
	
	return result;
}

