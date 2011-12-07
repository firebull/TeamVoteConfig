#include <sourcemod>

#define GETVERSION "0.1.5"

new bool:votedTeamOne = false;
new String:votedConfig[64];
new votedTeam = 0;

new Handle:sm_tvc_prefix     = INVALID_HANDLE;
new Handle:sm_tvc_exec_delay = INVALID_HANDLE;

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
	LoadTranslations("common.phrases");
	LoadTranslations("teamvoteconfig.phrases");
		
	CreateConVar("sm_tvc_version", GETVERSION, "Version of Sourcemod Config Loader plugin", FCVAR_SPONLY|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	
	sm_tvc_prefix     = CreateConVar("sm_tvc_prefix", "", "Prefix of config which will be added to its name.");
	sm_tvc_exec_delay = CreateConVar("sm_tvc_exec_delay", "3.0", "Delay to start voted config.");
	
	AutoExecConfig(true, "tvc")
	
	RegConsoleCmd("cplay", ConfigSuggest);
	RegConsoleCmd("cfg", ConfigSuggest);
	RegConsoleCmd("confirm", ConfigConfirm);
	RegAdminCmd("forceplay", ForcePlay, ADMFLAG_CONFIG);
}

/* !cplay
 * Command that a player can use to vote for a config
 * Команда, позволяющая предложить игровой конфиг
 */
public Action:ConfigSuggest(suggester, args)
{
	
	new voterTeam;
	new String:newVotedConfig[64];

	//Open the vote menu for the client if they arent using the server console
	if(suggester < 1)
	{
		PrintToServer("\x03[TVC] \x05%T", "Command is in-game only", LANG_SERVER);
	}
	else 
	{
		/* Начинаем обрабатывать запрос
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
		
		// Let's check that player is in team
		if (voterTeam > 1)
		{
			// Get the name of config
			GetCmdArg(1, newVotedConfig, sizeof(newVotedConfig));			
			
			// If no config entered
			if ( strlen(newVotedConfig) == 0)
			{
				PrintToChat(suggester, "\x03[TVC] \x05%t", "NoConfig");
			}
			else
			// Если еще не было голосования
			if ( votedTeamOne == false ){
				votedTeamOne = true;
				votedTeam    = voterTeam;
				votedConfig  = newVotedConfig;
				PrintToChatAll("\x03[TVC] \x05%t", "SuggestedConfig", votedConfig);
				PrintToChatAll("\x03[TVC] \x05%t", "WaitingConfirm");
			}
			else
			// Если конфиг уже предложен другой командой
			if ( votedTeamOne == true && votedTeam != voterTeam ){
				
				if ( strcmp(newVotedConfig, votedConfig, false) != 0 ){
					
					votedTeamOne = true;
					votedTeam    = voterTeam;
					votedConfig  = newVotedConfig;
					
					PrintToChatAll("\x03[TVC] \x05%t", "OtherConfigSuggested", votedConfig);
					PrintToChatAll("\x03[TVC] \x05%t", "WaitingConfirm");
				}
				else
				{
					new Float:fdelay = GetConVarFloat(sm_tvc_exec_delay);
					
					// Reset vars
					votedTeamOne = false;
					votedTeam = 0;
					
					PrintToChatAll("\x03[TVC] \x05%t", "StartTimer", votedConfig, RoundFloat(fdelay));
					
					// Start the config
					CreateTimer(fdelay, StartConfig);
				}
				
			}
			else
			// Если конфиг уже предложен своей командой
			if (votedTeam == voterTeam)
			{
				PrintToChat(suggester, "\x03[TVC] \x05%t", "PlayerTeamConfigSuggested", votedConfig);
			}
		}
		else
		{
			PrintToChat(suggester, "\x03[TVC] \x05%t", "NotInTeam");
		}
	}
		
}

/* !confirm
 * Command that a player can use to confirm a config
 * Подверждение конфига противоположной командой
 */
public Action:ConfigConfirm(suggester, args)
{
	new voterTeam;
	
	//Open the vote menu for the client if they arent using the server console
	if(suggester < 1)
	{
		PrintToServer("\x03[TVC] \x05%T", "Command is in-game only", LANG_SERVER);
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
		
		// Let's check that player is in team		
		if ( voterTeam > 1){
			// Если еще не было голосования
			if ( votedTeamOne == false ){
				PrintToChat(suggester, "\x03[TVC] \x05%t", "ConfirmNoConfig");
			}
			else
			// Если конфиг уже предложен другой командой
			if ( votedTeamOne == true && votedTeam != voterTeam ){
				
				new Float:fdelay = GetConVarFloat(sm_tvc_exec_delay);
				
				// Reset vars
				votedTeamOne = false;
				votedTeam = 0;																					
				
				PrintToChatAll("\x03[TVC] \x05%t", "StartTimer", votedConfig, RoundFloat(fdelay));
				
				// Start the config
				CreateTimer(fdelay, StartConfig);
										
			}
			else
			// If a config already suggested by player's team
			if (votedTeam == voterTeam)
			{
				PrintToChat(suggester, "\x03[TVC] \x05%t", "AlreadySuggested", votedConfig);
			}
		}
		else
		{
			PrintToChat(suggester, "\x03[TVC] \x05%t", "NotInTeam");
		}
	}
}


/* !forceplay
 * Admin force command
 * Принудительный запуск конфига админом
 */
public Action:ForcePlay(admin, args)
{
	new String:forcedConfig[64];
	
	//Open the vote menu for the client if they arent using the server console
	if(admin < 1)
	{
		PrintToServer("\x03[TVC] \x05%T", "Command is in-game only", LANG_SERVER);
	}
	else 
	{
		// Get the name of config
		GetCmdArg(1, forcedConfig, sizeof(forcedConfig));			
		
		// If no config entered
		if ( strlen(forcedConfig) == 0)
		{
			PrintToChat(admin, "\x03[TVC] \x05%t", "NoConfig");
		}
		else
		{
			new Float:fdelay = GetConVarFloat(sm_tvc_exec_delay);
			
			// Reset vars
			votedTeamOne = false;
			votedTeam    = 0;
			votedConfig  = forcedConfig;
			
			PrintToChatAll("\x03[TVC] \x05%t", "StartTimer", votedConfig, RoundFloat(fdelay));
			
			// Start the config
			CreateTimer(fdelay, StartConfig);
		}
		
		
		
		
	}
	
}

// Start the config
public Action:StartConfig(Handle:timer)
{
	new String:prefix[64];
	GetConVarString(sm_tvc_prefix, prefix, sizeof(prefix));
	
	PrintToChatAll("\x03[TVC] \x05%t", "Starting", votedConfig);
	
	if ( strlen(prefix) > 0)
	{
		ServerCommand("exec %s_%s.cfg", prefix, votedConfig);
	}
	else
	{
		ServerCommand("exec %s.cfg", votedConfig);
	}
	
	// Reset votedConfig
	votedConfig = "";
	
}