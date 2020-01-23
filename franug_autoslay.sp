/*  SM Franug AutoSlay
 *
 *  Copyright (C) 2019-2020 Francisco 'Franc1sco' García and Edyone
 * 
 * This program is free software: you can redistribute it and/or modify it
 * under the terms of the GNU General Public License as published by the Free
 * Software Foundation, either version 3 of the License, or (at your option) 
 * any later version.
 *
 * This program is distributed in the hope that it will be useful, but WITHOUT 
 * ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS 
 * FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License along with 
 * this program. If not, see http://www.gnu.org/licenses/.
 */

#include <sourcemod>
#include <sdktools>
#include <clientprefs>
#include <colorvariables>
#undef REQUIRE_PLUGIN
#include <franug_deadgames>
#define REQUIRE_PLUGIN


#define ENGLISH // multi language pending to do

Handle c_Slay;
bool _bSlay[MAXPLAYERS + 1];
bool gp_bDeadGames;

#define DATA "1.3"

public Plugin myinfo = 
{
	name = "SM Franug AutoSlay",
	author = "Franc1sco franug and Edyone",
	description = "",
	version = DATA,
	url = "http://steamcommunity.com/id/franug"
};

public void OnPluginStart()
{
	LoadTranslations("common.phrases.txt");
	
	CreateConVar("sm_franugautoslay_version", DATA, "", FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	
	c_Slay = RegClientCookie("franugASlay", "franugASlay", CookieAccess_Private);
	
	RegAdminCmd("sm_aslay", Command_Set, ADMFLAG_SLAY);
	RegAdminCmd("sm_noaslay", Command_noSet, ADMFLAG_SLAY);
	HookEvent("player_spawn", PlayerSpawn);

	gp_bDeadGames = LibraryExists("franug_deadgames");
	
	for(int i = 1; i <= MaxClients; i++)
		if(IsClientInGame(i) && AreClientCookiesCached(i))
		{
			OnClientCookiesCached(i);
		}
}

public void OnLibraryRemoved(const char[] name)
{
	if (StrEqual(name, "franug_deadgames"))
	{
		gp_bDeadGames = false;
	}
}

public void OnLibraryAdded(const char[] name)
{
	if (StrEqual(name, "franug_deadgames"))
	{
		gp_bDeadGames = true;
	}
}

public void OnClientCookiesCached(int client)
{
	char slayString[12];
	GetClientCookie(client, c_Slay, slayString, sizeof(slayString));
	_bSlay[client]  = (StringToInt(slayString) == 1)?true:false;
}
	

public Action Command_Set(int client, int args)
{
	if(args < 1) // Not enough parameters
	{
		#if defined ENGLISH
		CReplyToCommand(client, "{green}[Franug-AutoSlay]{lightgreen} use: sm_aslay <#userid|name>");
		#else
		CReplyToCommand(client, "{green}[Franug-AutoSlay]{lightgreen} usa: sm_aslay <#userid|name>");
		#endif
		return Plugin_Handled;
	}
	char arg[32];
	GetCmdArg(1, arg, sizeof(arg));
	
	int target;
	if((target = FindTarget(client, arg, true, true)) == -1)
	{
		return Plugin_Handled; // Target not found...
	}
	if(_bSlay[target])
	{
		#if defined ENGLISH
		CReplyToCommand(client, "{green}[Franug-AutoSlay]{lightgreen} %N already have a pending slay", target);
		#else
		CReplyToCommand(client, "{green}[Franug-AutoSlay]{lightgreen} %N ya tiene un autoslay pendiente", target);
		#endif
		return Plugin_Handled;
	}
	#if defined ENGLISH
	CShowActivity2(client, "{green}[Franug-AutoSlay]{lightgreen} ", "{lightgreen}%N will be slayed in the next spawn.", target);
	#else
	CShowActivity2(client, "{green}[Franug-AutoSlay]{lightgreen} ", "{lightgreen}%N será slayeado en su siguiente aparición.", target);
	#endif
	_bSlay[target] = true;
	SetClientCookie(target, c_Slay, "1");
	
	
	return Plugin_Handled;
}

public Action Command_noSet(int client, int args)
{
	if(args < 1) // Not enough parameters
	{
		#if defined ENGLISH
		CReplyToCommand(client, "{green}[Franug-AutoSlay]{lightgreen} use: sm_noaslay <#userid|name>");
		#else
		CReplyToCommand(client, "{green}[Franug-AutoSlay]{lightgreen} usa: sm_noaslay <#userid|name>");
		#endif
		return Plugin_Handled;
	}
	char arg[32];
	GetCmdArg(1, arg, sizeof(arg));
	
	int target;
	if((target = FindTarget(client, arg, true, true)) == -1)
	{
		return Plugin_Handled;
	}
	if(!_bSlay[target])
	{
		#if defined ENGLISH
		CReplyToCommand(client, "{green}[Franug-AutoSlay]{lightgreen} %N dont have a pending slay", target);
		#else
		CReplyToCommand(client, "{green}[Franug-AutoSlay]{lightgreen} %N no tiene un autoslay pendiente", target);
		#endif
		return Plugin_Handled;
	}
	#if defined ENGLISH
	CShowActivity2(client, "{green}[Franug-AutoSlay]{lightgreen} ", "{lightgreen}%N will NOT be slayed in the next spawn.", target);
	#else
	CShowActivity2(client, "{green}[Franug-AutoSlay]{lightgreen} ", "{lightgreen}%N NO será slayeado en su siguiente aparición.", target);
	#endif
	_bSlay[target] = false;
	SetClientCookie(target, c_Slay, "0");
	
	return Plugin_Handled;
}

public Action PlayerSpawn(Handle event, const char[] name, bool dontBroadcast)
{
	CreateTimer(0.5, Timer_CheckSlay, GetEventInt(event, "userid"), TIMER_FLAG_NO_MAPCHANGE);
}

public Action Timer_CheckSlay(Handle timer, int id)
{
	int client = GetClientOfUserId(id);
	
	if(!client || !IsClientInGame(client) || !_bSlay[client] || !IsPlayerAlive(client))
		return;
		
	if (gp_bDeadGames && DeadGames_IsOnGame(client))return;
	
	ForcePlayerSuicide(client);
	_bSlay[client] = false;
	SetClientCookie(client, c_Slay, "0");
	
	if(IsPlayerAlive(client)) // double check for a csgo issue where player dont die sometimes
	{
		int team = GetClientTeam(client);
		ChangeClientTeam(client, 1);
		ChangeClientTeam(client, team);
	}
	
	#if defined ENGLISH
	CPrintToChatAll("{green}[Franug-AutoSlay]{lightgreen} %N has been slayed for a pending slay.", client);
	#else
	CPrintToChatAll("{green}[Franug-AutoSlay]{lightgreen} %N ha sido slayeado porque tenia un slay pendiente.", client);
	#endif
}