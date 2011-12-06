#include <sourcemod>

#define GETVERSION "0.1"

new bool:votedTeamOne = false;
new String:votedConfig[64];
new votedTeam = 0;

new Handle:sm_tvc_prefix     = INVALID_HANDLE
new Handle:sm_tvc_exec_delay = INVALID_HANDLE

//Plugin Info
public Plugin:myinfo = 
{
	name = "Team Vote Config Loader",
	author = "Comrade Bulkin",
	description = "Executes config by Team Vote",
	version = GETVERSION,
	url = "http://forum.teamserver.ru"
}

public OnPluginStart()
{
	CreateConVar("sm_tvc_version", GETVERSION, "Version of Sourcemod Config Loader plugin", FCVAR_SPONLY|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	
	sm_tvc_prefix     = CreateConVar("sm_tvc_prefix", "", "Prefix of config which will be added to its name.");
	sm_tvc_exec_delay = CreateConVar("sm_tvc_exec_delay", "3.0", "Delay to start voted config.");
	
	AutoExecConfig(true, "tvc")
	
	RegConsoleCmd("cplay", ConfigSuggest);
	RegConsoleCmd("load", ConfigSuggest);
	RegConsoleCmd("confirm", ConfigConfirm);
}

//Command that a player can use to vote for a config
public Action:ConfigSuggest(suggester, args)
{
	
	new voterTeam;
	new String:newVotedConfig[64];

	//Open the vote menu for the client if they arent using the server console
	if(suggester < 1)
	{
		PrintToServer("\x03[TVC] \x05You cannot suggest a config from the server console, use the in-game chat");
	}
	else 
	{
		/* Начинаем обратабтывать запрос
		 * 
		 * !play 
		 * - Если votedTeamOne пустая, значит голосования еще не было.
		 *   votedTeam = команда игрока
		 *   votedTeamOne = true
		 *     
		 *   
		 * - Если не пустая - значит это ответ на предложение.
		 *   Сравниваем команду игрока - если не совпадает с teamOne,
		 *   то сравниваем ответный конфиг. Если совпадает, запускаем его. 
		 *   Если нет - votedTeam = ClientTeam. votedTeamOne = true
		 *   Если команда совпадает, выводим сообщение, что его команда
		 *   уже проголосовала.
		 * 
		 */		
		voterTeam = GetClientTeam(suggester);
		// Сначала убедиться, что игрок в команде
		if (voterTeam > 1)
		{
			/* Получаем имя конфига */
			GetCmdArg(1, newVotedConfig, sizeof(newVotedConfig));			
			
			// Если еще не было голосования
			if ( votedTeamOne == false ){
				votedTeamOne = true;
				votedTeam    = voterTeam;
				votedConfig  = newVotedConfig;
				PrintToChatAll("\x03[TVC] \x05Suggested config: %s.", votedConfig);
				PrintToChatAll("\x03[TVC] \x05Waiting for the other team to confirm.");
			}
			else
			// Если конфиг уже предложен другой командой
			if ( votedTeamOne == true && votedTeam != voterTeam ){
				
				if ( strcmp(newVotedConfig, votedConfig, false) != 0 ){
					
					votedTeamOne = true;
					votedTeam    = voterTeam;
					votedConfig  = newVotedConfig;
					
					PrintToChatAll("\x03[TVC] \x05The other team suggested another config: %s.", votedConfig);
					PrintToChatAll("\x03[TVC] \x05Waiting for the other team to confirm.");
				}
				else
				{
					// Reset vars
					votedTeamOne = false;
					votedTeam = 0;
					
					PrintToChatAll("\x03[TVC] \x05Will start %s config in %d seconds.", votedConfig, sm_tvc_exec_delay);
					
					new Float:fdelay = GetConVarFloat(sm_tvc_exec_delay);
					CreateTimer(fdelay, StartConfig);
				}
				
			}
			else
			// Если конфиг уже предложен своей командой
			if (votedTeam == voterTeam)
			{
				PrintToChat(suggester, "\x03[TVC] \x05Your team already suggested a config: %s", votedConfig);
			}
		}
		else
		{
			PrintToChat(suggester, "\x03[TVC] \x05You must be in team to suggest a config");
		}
	}
		
}

//Command that a player can use to confirm a config
public Action:ConfigConfirm(suggester, args)
{
	new voterTeam;
	
	//Open the vote menu for the client if they arent using the server console
	if(suggester < 1)
	{
		PrintToServer("\x03[TVC] \x05You cannot confirm a config from the server console, use the in-game chat");
	}
	else
	{
		/*
		 * !confirm
		 * - Сравниваем команду игрока - если не совпадает с teamOne,
		 *   то запускаем конфиг. Иначе вывести сообщение, что его команда
		 *   уже проголосовала. 
		 */
		
		voterTeam   = GetClientTeam(suggester);
		
		// Сначала убедиться, что игрок в команде 		
		if ( voterTeam > 1){
			// Если еще не было голосования
			if ( votedTeamOne == false ){
				PrintToChat(suggester, "\x03[TVC] \x05None of configs is suggested. You can suggest one by commnad !play <config>.");
			}
			else
			// Если конфиг уже предложен другой командой
			if ( votedTeamOne == true && votedTeam != voterTeam ){
				// Reset vars
				votedTeamOne = false;
				votedTeam = 0;
				
				PrintToChatAll("\x03[TVC] \x05Will start %s config in %d seconds.", votedConfig, sm_tvc_exec_delay);
				
				new Float:fdelay = GetConVarFloat(sm_tvc_exec_delay);
				CreateTimer(fdelay, StartConfig);
										
			}
			else
			// Если конфиг уже предложен своей командой
			if (votedTeam == voterTeam)
			{
				PrintToChat(suggester, "\x03[TVC] \x05You can't confirm as your team already");
				PrintToChat(suggester, "          \x05suggested a config: %s", votedConfig);
			}
		}
		else
		{
			PrintToChat(suggester, "\x03[TVC] \x05You must be in team to suggest a config");
		}
	}
}


public Action:StartConfig(Handle:timer)
{
	if ( strlen(sm_tvc_prefix) > 0)
	{
		ServerCommand("exec %s_%s.cfg", sm_tvc_prefix, votedConfig);
	}
	else
	{
		ServerCommand("exec %s.cfg", votedConfig);
	}
	
	// Reset votedConfig
	votedConfig = "";
	
}