/*  SM Franug AutoSlay
 *
 *  Copyright (C) 2019 Francisco 'Franc1sco' García
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

#define ENGLISH // multi language pending to do

Handle c_Slay;
bool _bSlay[MAXPLAYERS + 1];

#define DATA "1.0"

public Plugin myinfo = 
{
	name = "SM Franug AutoSlay",
	author = "Franc1sco franug",
	description = "",
	version = DATA,
	url = "http://steamcommunity.com/id/franug"
};

public void OnPluginStart()
{
	CreateConVar("sm_franugautoslay_version", DATA, "", FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	
	c_Slay = RegClientCookie("franugASlay", "franugASlay", CookieAccess_Private);
	
	RegAdminCmd("sm_aslay", Command_Set, ADMFLAG_SLAY);
	RegAdminCmd("sm_noaslay", Command_noSet, ADMFLAG_SLAY);
	HookEvent("player_spawn", PlayerSpawn);

	for(int i = 1; i <= MaxClients; i++)
		if(IsClientInGame(i) && AreClientCookiesCached(i))
		{
			OnClientCookiesCached(i);
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
		ReplyToCommand(client, "[SM] use: sm_aslay <#userid|name>");
		#else
		ReplyToCommand(client, "[SM] usa: sm_aslay <#userid|name>");
		#endif
		return Plugin_Handled;
	}
	char arg[32];
	GetCmdArg(1, arg, sizeof(arg));
	
	int target;
	if((target = FindTarget(client, arg, true, true)) == -1)
	{
		#if defined ENGLISH
		ReplyToCommand(client, "Player not found");
		#else
		ReplyToCommand(client, "Jugador no encontrado");
		#endif
		return Plugin_Handled; // Target not found...
	}
	if(_bSlay[target])
	{
		#if defined ENGLISH
		ReplyToCommand(client, "%N already have a pending slay", target);
		#else
		ReplyToCommand(client, "%N ya tiene un autoslay pendiente", target);
		#endif
		return Plugin_Handled;
	}
	#if defined ENGLISH
	ShowActivity2(client, "[Franug-AutoSlay] ", "%N will be slayed in the next spawn.", target);
	#else
	ShowActivity2(client, "[Franug-AutoSlay] ", "%N será slayeado en su siguiente aparición.", target);
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
		ReplyToCommand(client, "[SM] use: sm_noaslay <#userid|name>");
		#else
		ReplyToCommand(client, "[SM] usa: sm_noaslay <#userid|name>");
		#endif
		return Plugin_Handled;
	}
	char arg[32];
	GetCmdArg(1, arg, sizeof(arg));
	
	int target;
	if((target = FindTarget(client, arg, true, true)) == -1)
	{
		#if defined ENGLISH
		ReplyToCommand(client, "Player not found");
		#else
		ReplyToCommand(client, "Jugador no encontrado");
		#endif
		return Plugin_Handled;
	}
	if(!_bSlay[target])
	{
		#if defined ENGLISH
		ReplyToCommand(client, "%N dont have a pending slay", target);
		#else
		ReplyToCommand(client, "%N no tiene un autoslay pendiente", target);
		#endif
		return Plugin_Handled;
	}
	#if defined ENGLISH
	ShowActivity2(client, "[Franug-AutoSlay] ", "%N will NOT be slayed in the next spawn.", target);
	#else
	ShowActivity2(client, "[Franug-AutoSlay] ", "%N NO será slayeado en su siguiente aparición.", target);
	#endif
	_bSlay[target] = false;
	SetClientCookie(target, c_Slay, "0");
	
	return Plugin_Handled;
}

public Action PlayerSpawn(Handle event, const char[] name, bool dontBroadcast)
{
	CreateTimer(2.0, Timer_CheckSlay, GetEventInt(event, "userid"), TIMER_FLAG_NO_MAPCHANGE);
}

public Action Timer_CheckSlay(Handle timer, int id)
{
	int client = GetClientOfUserId(id);
	
	if(!client || !IsClientInGame(client) || !_bSlay[client] || !IsPlayerAlive(client))
		return;
		
	ForcePlayerSuicide(client);
	_bSlay[client] = false;
	SetClientCookie(client, c_Slay, "0");
	
	#if defined ENGLISH
	PrintToChatAll("[Franug-AutoSlay] %N has been slayed for a pending slay.", client);
	#else
	PrintToChatAll("[Franug-AutoSlay] %N ha sido slayeado porque tenia un slay pendiente.", client);
	#endif
}