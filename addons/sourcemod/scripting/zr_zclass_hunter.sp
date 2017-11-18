#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <zr_tools>
#include <zombiereloaded>
#include <emitsoundany>

public Plugin myinfo =
{
	name        	= "[ZR] Zombie Class: Hunter",
	author      	= "Extr1m (Michail)",
	description 	= "Adds a unique class of zombies",
	version     	= "1.0",
	url         	= "https://sourcemod.net/"
}

ConVar gB_PEnabled;
ConVar gB_PLeapCooldown;
ConVar gB_PLeapPower;

new Float:g_LeapLastTime[MAXPLAYERS + 1];
new bool:g_LeapClassEnable[MAXPLAYERS + 1]

stock const char g_sound[] = "zr/hunter_jump.mp3";

public OnMapStart()
{
	PrecacheSoundAny(g_sound); 

	for (new i = 1; i <= MaxClients; i++)
	{
		g_LeapLastTime[i] = INVALID_HANDLE;
	}
}

public void OnPluginStart()
{	
	gB_PEnabled 		= 	CreateConVar("sm_hunter_enabled", "1", "Responsible for the operation of the class on the server");
	gB_PLeapCooldown 	= 	CreateConVar("sm_hunter_cooldown", "6.0", "The time between each jump");
	gB_PLeapPower		= 	CreateConVar("sm_hunter_leappower", "650.0", "The power of the jump");
}

public ZR_OnClientInfected(client, attacker, bool:motherInfect, bool:respawnOverride, bool:respawn)
{
	decl String:buffer[64];
	ZRT_GetClientAttributeString(client, "class_zombie", buffer, sizeof(buffer));
	
	if(StrEqual(buffer, "hunter", false))
		g_LeapClassEnable[client] = true;
	else
		g_LeapClassEnable[client] = false;
}

public Action:OnPlayerRunCmd(client, &buttons, &impulse, Float:vel[3], Float:angles[3], &weapon, &subtype, &cmdnum, &tickcount, &seed, mouse[2])
{	
	if (gB_PEnabled.BoolValue && IsPlayerAlive(client) && ZR_IsClientZombie(client))
	{
		if(g_LeapClassEnable[client])
		{
			if (!(buttons & (IN_USE | IN_DUCK) == (IN_USE | IN_DUCK)))
				return Plugin_Continue;
		
			if (GetGameTime() - g_LeapLastTime[client] < gB_PLeapCooldown.FloatValue) 
			{
				PrintHintText(client, "Reloading - %.1f", gB_PLeapCooldown.FloatValue - (GetGameTime() - g_LeapLastTime[client]));
				return Plugin_Continue;
			}		
			
			if (!(GetEntityFlags(client) & FL_ONGROUND) || RoundToNearest(GetVectorLength(vel)) < 80)
				return Plugin_Continue;
				
			static Float:fwd[3];
			static Float:velocity[3];
			static Float:up[3];
			GetAngleVectors(angles, fwd, velocity, up);
			NormalizeVector(fwd, velocity);
			ScaleVector(velocity, gB_PLeapPower.FloatValue);

			float fOriginClient[3];
			GetClientAbsOrigin( client, fOriginClient );
			
			EmitAmbientSoundAny(g_sound, fOriginClient);
			SetEntPropVector(client, Prop_Data, "m_vecBaseVelocity", velocity);

			g_LeapLastTime[client] = GetGameTime();
		}
	}
	return Plugin_Continue;
}		