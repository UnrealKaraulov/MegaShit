#include <amxmodx>
#include <fakemeta>
#include <hamsandwich>
#include <reapi>
#include <easy_cfg>

#define PLUGIN  "MegaShit"
#define AUTHOR  "Karaulov"
#define VERSION "3.4"

// Класс сущностей
new const SHIT_MODEL_CLASSNAME[] = "megashit_model";
new const SHIT_SPRITE_CLASSNAME[] = "megashit_sprite";

// Магические числа :)
new const DEATH_EVENT_TASK_OFFSET = 10000;
new const SHIT_EVENT_TASK_OFFSET = 20000;

#define MAX_PHRASE_LEN 256

// Пути к моделям и звукам
new SHIT_MODEL1[64] = "models/megashit/megashit_model.mdl"
new SHIT_MODEL2[64] = "models/megashit/megashit_model2.mdl"

new SHIT_SPRITE1[64] = "sprites/megashit/megashit_muhi.spr"
new SHIT_SPRITE2[64] = "sprites/megashit/megashit_flame.spr"

new SHIT_SOUND_SHIT[64] = "megashit/megashit_pukpuk.wav"
new SHIT_SOUND_NO_SHIT[64] = "megashit/megashit_nelza.wav"
new SHIT_SOUND_PLACE_IT_HERE[64] = "megashit/megashit_place.wav"
new SHIT_SOUND_AMBIENT1[64] = "ambience/flies.wav"
new SHIT_SOUND_AMBIENT2[64] = "ambience/burning1.wav"
new SHIT_EAT_SOUND[64] = "leech/leech_bite2.wav"

// Индексы моделей
new SHIT_MODEL1_IDX = 0;
new SHIT_MODEL2_IDX = 0;
new SHIT_SPRITE1_IDX = 0;
new SHIT_SPRITE2_IDX = 0;

// Переменные игроков
new Float:g_vDeadOrigins1[MAX_PLAYERS+1][3];
new Float:g_vDeadOrigins2[MAX_PLAYERS+1][3];
new Float:g_fShitIntoTimeout[MAX_PLAYERS+1] = {0.0,...};
new g_iNumShit[MAX_PLAYERS+1] = {0,...}

// Переменные
new YOUR_SHIT_SERVER_NAME[128] = "^4SERVER_NAME^1";
new FLAGS_SHIT[32] = ""
new FLAGS_GIRL[32] = ""
new MAX_SHIT_COUNT = 3;
new Float:START_SHIT_TIME = 1.0;

new g_iEAT_HP_OWNER = 1;
new g_iEAT_HP_OTHER = 5;
new Float:g_fMAX_EAT_HP = 150.0;
new Float:g_fStepWait = 5.0;

// Состояния плагина
new g_bShitPluginActivated = 1;
new bool:g_bMEGASHIT_ACTIVE = false;
new bool:g_bOneShitCompleted = false;
new bool:g_bNeedRemoveShit = false

// Флаги доступа
new UFLAGS_SHIT = 0;
new UFLAGS_GIRL = 0;

// Идентификаторы фраз
enum {
	PHRASE_MALE_MALE_EAT = 0,
	PHRASE_FEMALE_MALE_EAT,
	PHRASE_MALE_FEMALE_EAT,
	PHRASE_FEMALE_FEMALE_EAT,
	PHRASE_MALE_MALE_STEP,
	PHRASE_FEMALE_FEMALE_STEP,
	PHRASE_FEMALE_MALE_STEP,
	PHRASE_MALE_FEMALE_STEP,
	PHRASE_MALE_NOSHIT,
	PHRASE_FEMALE_NOSHIT,
	PHRASE_MALE_SHIT1_SELF,
	PHRASE_FEMALE_SHIT1_SELF,
	PHRASE_MALE_SHIT2_SELF,
	PHRASE_FEMALE_SHIT2_SELF,
	PHRASE_MALE_EAT_SELF,
	PHRASE_FEMALE_EAT_SELF,
	PHRASE_FEMALE_FEMALE_SHIT1,
	PHRASE_FEMALE_FEMALE_SHIT2,
	PHRASE_MALE_FEMALE_SHIT1,
	PHRASE_MALE_FEMALE_SHIT2,
	PHRASE_FEMALE_MALE_SHIT1,
	PHRASE_FEMALE_MALE_SHIT2,
	PHRASE_MALE_MALE_SHIT1,
	PHRASE_MALE_MALE_SHIT2,
	PHRASE_ENUM_COUNT
}

// Имена секций для фраз
new const PHRASE_SECTIONS[PHRASE_ENUM_COUNT][] = {
	"PHRASE_MALE_MALE_EAT",
	"PHRASE_FEMALE_MALE_EAT",
	"PHRASE_MALE_FEMALE_EAT",
	"PHRASE_FEMALE_FEMALE_EAT",
	"PHRASE_MALE_MALE_STEP",
	"PHRASE_FEMALE_FEMALE_STEP",
	"PHRASE_FEMALE_MALE_STEP",
	"PHRASE_MALE_FEMALE_STEP",
	"PHRASE_MALE_NOSHIT",
	"PHRASE_FEMALE_NOSHIT",
	"PHRASE_MALE_SHIT1_SELF",
	"PHRASE_FEMALE_SHIT1_SELF",
	"PHRASE_MALE_SHIT2_SELF",
	"PHRASE_FEMALE_SHIT2_SELF",
	"PHRASE_MALE_EAT_SELF",
	"PHRASE_FEMALE_EAT_SELF",
	"PHRASE_FEMALE_FEMALE_SHIT1",
	"PHRASE_FEMALE_FEMALE_SHIT2",
	"PHRASE_MALE_FEMALE_SHIT1",
	"PHRASE_MALE_FEMALE_SHIT2",
	"PHRASE_FEMALE_MALE_SHIT1",
	"PHRASE_FEMALE_MALE_SHIT2",
	"PHRASE_MALE_MALE_SHIT1",
	"PHRASE_MALE_MALE_SHIT2"
}

// Массив для фраз
new Array:g_aPhrases[PHRASE_ENUM_COUNT];

#define AddFlag(%1,%2)       ( %1 |= ( 1 << (%2-1) ) )
//#define RemoveFlag(%1,%2)    ( %1 &= ~( 1 << (%2-1) ) )
#define CheckFlag(%1,%2)     ( %1 & ( 1 << (%2-1) ) )


public plugin_init() 
{
	register_plugin(PLUGIN, VERSION, AUTHOR);
	RegisterHookChain(RG_CBasePlayer_Spawn, "PlawerSpawn",  .post = true);
	RegisterHookChain(RG_CBasePlayer_Killed, "PlawerKilled", .post = true);
	RegisterHookChain(RG_PM_Move, "RG_PM_Move_post", .post = true);
	RegisterHookChain(RG_PM_AirMove, "RG_PM_Move_post", .post = true);
	RegisterHam(Ham_ObjectCaps, "info_target", "CBasePlayer_ObjectCaps_pre", false)
	
	create_cvar(PLUGIN, VERSION, (FCVAR_SERVER | FCVAR_SPONLY | FCVAR_UNLOGGED));
	
	set_task(START_SHIT_TIME,"MEGASHIT_ACTIVATE");
}

public MEGASHIT_ACTIVATE()
{
	g_bMEGASHIT_ACTIVE = true;
}

public PlawerSpawn(const id)
{
	g_fShitIntoTimeout[id] = 0.0;
	new iEnt = -1;
	
	// RESET DEAD ORIGINS
	g_vDeadOrigins1[id][0] = -8000.0;
	g_vDeadOrigins1[id][1] = -8000.0;
	g_vDeadOrigins1[id][2] = -8000.0;
	g_vDeadOrigins2[id][0] = -8000.0;
	g_vDeadOrigins2[id][1] = -8000.0;
	g_vDeadOrigins2[id][2] = -8000.0;
	
	if (g_bNeedRemoveShit)
	{
		g_bNeedRemoveShit = false
		
		while((iEnt = rg_find_ent_by_class(iEnt,SHIT_MODEL_CLASSNAME, .useHashTable = false)) != 0)
		{
			set_entvar(iEnt, var_nextthink, get_gametime());
			set_entvar(iEnt, var_flags, FL_KILLME);
			rh_emit_sound2(iEnt, 0, CHAN_BODY , SHIT_SOUND_AMBIENT1, VOL_NORM, ATTN_NORM, SND_STOP, PITCH_NORM );
			rh_emit_sound2(iEnt, 0, CHAN_WEAPON , SHIT_SOUND_AMBIENT2, VOL_NORM, ATTN_NORM, SND_STOP, PITCH_NORM );
		}
		
		iEnt = -1
		while((iEnt = rg_find_ent_by_class(iEnt,SHIT_SPRITE_CLASSNAME, .useHashTable = false)) != 0)
		{
			set_entvar(iEnt, var_nextthink, get_gametime());
			set_entvar(iEnt, var_flags, FL_KILLME);
		}
	}
	
	g_iNumShit[id] = MAX_SHIT_COUNT;
}

public plugin_precache() 
{
	read_shit_cfg();
	
	precache_sound(SHIT_SOUND_SHIT);
	precache_sound(SHIT_SOUND_NO_SHIT);
	precache_sound(SHIT_SOUND_AMBIENT1);
	precache_sound(SHIT_SOUND_AMBIENT2);
	precache_sound(SHIT_EAT_SOUND);
	precache_sound(SHIT_SOUND_PLACE_IT_HERE);
	
	SHIT_SPRITE1_IDX = precache_model(SHIT_SPRITE1);
	SHIT_SPRITE2_IDX = precache_model(SHIT_SPRITE2);
	SHIT_MODEL1_IDX = precache_model(SHIT_MODEL1);
	SHIT_MODEL2_IDX = precache_model(SHIT_MODEL2);
}

public plugin_end()
{
	for (new i = 0; i < sizeof(g_aPhrases); i++)
	{
		if (g_aPhrases[i] != Invalid_Array)
		{
			ArrayDestroy(g_aPhrases[i]);
		}
	}
}

public plugin_pause()
{
	for(new id = 1; id <= MAX_PLAYERS;id++)
	{
		if (is_user_connected(id))
		{
			if (task_exists(id + SHIT_EVENT_TASK_OFFSET))
			{
				rg_send_bartime(id,0);
				remove_task(id + SHIT_EVENT_TASK_OFFSET);
			}
		}
		else 
		{
			remove_task(id + SHIT_EVENT_TASK_OFFSET);
			remove_task(id + DEATH_EVENT_TASK_OFFSET);
		}
	}
}

public client_disconnected(id)
{
	remove_task(id + SHIT_EVENT_TASK_OFFSET);
	remove_task(id + DEATH_EVENT_TASK_OFFSET);
}

public RG_PM_Move_post(id)
{
	if (!g_bMEGASHIT_ACTIVE)
		return HC_CONTINUE;
		
	new buttons = get_entvar(id, var_button);
	new oldbuttons = get_entvar(id, var_oldbuttons);
	
	if(oldbuttons & IN_USE && !(buttons & IN_USE))
	{
		if (task_exists(id + SHIT_EVENT_TASK_OFFSET))
		{
			rg_send_bartime(id,0);
			remove_task(id + SHIT_EVENT_TASK_OFFSET);
		}
	}

	if(oldbuttons & IN_DUCK && !(buttons & IN_DUCK))
	{
		if (task_exists(id + SHIT_EVENT_TASK_OFFSET))
		{
			rg_send_bartime(id,0);
			remove_task(id + SHIT_EVENT_TASK_OFFSET);
		}
	}
	
	if(g_bShitPluginActivated && buttons & IN_USE && !(oldbuttons & IN_USE) && oldbuttons & IN_DUCK && (get_entvar(id, var_flags) & FL_ONGROUND))
	{
		if (is_user_alive(id) && ((UFLAGS_SHIT == 0 || get_user_flags(id) & UFLAGS_SHIT) || get_user_flags(id) & UFLAGS_GIRL))
		{
			rg_send_bartime(id,3);
			set_task(2.5,"StartMakeShit",id + SHIT_EVENT_TASK_OFFSET);
		}
	}
	
	return HC_CONTINUE;
}

public StartMakeShit(idx)
{
	new id = idx - SHIT_EVENT_TASK_OFFSET;
	
	if (is_user_alive(id))
	{
		if (g_iNumShit[id] > 0)
		{
			g_iNumShit[id]--;
			if (random(100) > 50)
			{
				if (get_user_flags(id) & UFLAGS_GIRL)
				{
					GENERATE_UNREAL_SHIT(id, SHIT_SPRITE2_IDX, SHIT_SPRITE2, SHIT_MODEL1_IDX, SHIT_MODEL1, false);
				}
				else
				{
					GENERATE_UNREAL_SHIT(id, SHIT_SPRITE1_IDX, SHIT_SPRITE1, SHIT_MODEL1_IDX, SHIT_MODEL1, false);
				}
			}
			else 
			{
				if (get_user_flags(id) & UFLAGS_GIRL)
				{
					GENERATE_UNREAL_SHIT(id, SHIT_SPRITE2_IDX, SHIT_SPRITE2, SHIT_MODEL2_IDX, SHIT_MODEL2);
				}
				else
				{
					GENERATE_UNREAL_SHIT(id, SHIT_SPRITE1_IDX, SHIT_SPRITE1, SHIT_MODEL2_IDX, SHIT_MODEL2);
				}
			}
			g_bNeedRemoveShit = true;
		}
		else
		{
			static name1[MAX_NAME_LENGTH];
			get_user_name(id,name1,charsmax(name1));
			
			rh_emit_sound2(id, 0, CHAN_WEAPON , SHIT_SOUND_NO_SHIT, 0.8, ATTN_STATIC);
			rh_emit_sound2(id, 0, CHAN_BODY , SHIT_SOUND_SHIT, 0.8, ATTN_STATIC);
			
			static phrase[MAX_PHRASE_LEN];
			if (get_user_flags(id) & UFLAGS_GIRL)
			{
				GetRandomPhrase(PHRASE_FEMALE_NOSHIT, phrase, charsmax(phrase));
			}
			else
			{
				GetRandomPhrase(PHRASE_MALE_NOSHIT, phrase, charsmax(phrase));
			}
			
			replace_all(phrase, charsmax(phrase), "[user1]", name1);
			
			client_print_color(0, print_team_red, "[%s]: %s", YOUR_SHIT_SERVER_NAME, phrase);
		}
	}
}

START_PLAYER_SHIT(shitent,id_target, bool:second_mdl)
{
	static name1[MAX_NAME_LENGTH];
	static name2[MAX_NAME_LENGTH];
	
	if (id_target >= 1 && id_target <= MAX_PLAYERS && !is_nullent(shitent) && is_user_connected(id_target))
	{
		if(TeamName:get_member(id_target, m_iTeam) != TEAM_CT && TeamName:get_member(id_target, m_iTeam) != TEAM_TERRORIST) 
		{
			return;
		}
		
		new id = get_entvar( shitent, var_owner ) 
		if (id != id_target && id != 0 && is_user_connected(id))
		{
			new Float:health = get_entvar(shitent, var_health );
			if (health > 0.0)
			{
				new playerflags = get_entvar(shitent, var_iuser3);
				if (!CheckFlag(playerflags,id_target))
				{
					AddFlag(playerflags,id_target);
					set_entvar(shitent, var_iuser3,playerflags);
					get_user_name(id,name1,charsmax(name1));
					get_user_name(id_target,name2,charsmax(name2));
					g_bOneShitCompleted = true;
					
					static phrase[MAX_PHRASE_LEN];
					if (get_user_flags(id_target) & UFLAGS_GIRL)
					{
						if (get_user_flags(id) & UFLAGS_GIRL)
						{
							if (second_mdl)
							{	
								GetRandomPhrase(PHRASE_FEMALE_FEMALE_SHIT2, phrase, charsmax(phrase));
							}
							else 
							{
								GetRandomPhrase(PHRASE_FEMALE_FEMALE_SHIT1, phrase, charsmax(phrase));
							}
						}
						else 
						{
							if (second_mdl)
							{	
								GetRandomPhrase(PHRASE_MALE_FEMALE_SHIT2, phrase, charsmax(phrase));
							}
							else 
							{
								GetRandomPhrase(PHRASE_MALE_FEMALE_SHIT1, phrase, charsmax(phrase));
							}
						}
					}
					else
					{
						if (get_user_flags(id) & UFLAGS_GIRL)
						{
							if (second_mdl)
							{
								GetRandomPhrase(PHRASE_FEMALE_MALE_SHIT2, phrase, charsmax(phrase));
							}
							else 
							{
								GetRandomPhrase(PHRASE_FEMALE_MALE_SHIT1, phrase, charsmax(phrase));
							}
						}
						else 
						{
							if (second_mdl)
							{	
								GetRandomPhrase(PHRASE_MALE_MALE_SHIT2, phrase, charsmax(phrase));
							}
							else 
							{
								GetRandomPhrase(PHRASE_MALE_MALE_SHIT1, phrase, charsmax(phrase));
							}
						}
					}
					
					replace_all(phrase, charsmax(phrase), "[user1]", name1);
					replace_all(phrase, charsmax(phrase), "[user2]", name2);
					
					client_print_color(0, print_team_red, "[%s]: %s", YOUR_SHIT_SERVER_NAME, phrase);
				}
			}
		}
	}
}

TRY_TO_START_PLAYER_SHITS( id, ent, bool:second_mdl )
{
	new iPlayers[ MAX_PLAYERS ], iNum;
	get_players( iPlayers, iNum  );

	new iPlayer;
	new Float:fOrigin[3];
	get_entvar( id, var_origin, fOrigin);
	

	g_bOneShitCompleted = false;
	static name1[MAX_NAME_LENGTH];
	get_user_name(id,name1,charsmax(name1));
	
	for( new i = 0; i < iNum; i++ )
	{
		iPlayer = iPlayers[ i ];
		if (iPlayer != id)
		{
			// Проверка дальности
			if (is_user_alive(iPlayer))
			{
				get_entvar(iPlayer,var_origin,g_vDeadOrigins1[iPlayer]);
				if(get_distance_f(fOrigin, g_vDeadOrigins1[iPlayer]) < 55)
				{
					START_PLAYER_SHIT(ent,iPlayer,second_mdl);
				}
			}
			else 
			{
				if(get_distance_f(fOrigin, g_vDeadOrigins1[iPlayer]) < 55)
				{
					START_PLAYER_SHIT(ent,iPlayer,second_mdl);
				}
				else if(get_distance_f(fOrigin, g_vDeadOrigins2[iPlayer]) < 55)
				{
					START_PLAYER_SHIT(ent,iPlayer,second_mdl);
				}
			}
		}
	}
	
	if (!g_bOneShitCompleted)
	{
		static phrase[MAX_PHRASE_LEN];
		if (get_user_flags(id) & UFLAGS_GIRL)
		{    
			if (second_mdl)
			{
				GetRandomPhrase(PHRASE_FEMALE_SHIT2_SELF, phrase, charsmax(phrase));
			}
			else
			{
				GetRandomPhrase(PHRASE_FEMALE_SHIT1_SELF, phrase, charsmax(phrase));
			}
		}
		else
		{
			if (second_mdl)
			{
				GetRandomPhrase(PHRASE_MALE_SHIT2_SELF, phrase, charsmax(phrase));
			}
			else
			{
				GetRandomPhrase(PHRASE_MALE_SHIT1_SELF, phrase, charsmax(phrase));
			}
		}
		
		replace_all(phrase, charsmax(phrase), "[user1]", name1);
		
		client_print_color(0, print_team_red, "[%s]: %s", YOUR_SHIT_SERVER_NAME, phrase);
	}
}

GENERATE_UNREAL_SHIT( id, idxSprite, const szSprite[ ], idxModel, const szModel[ ], bool:second_mdl = true) 
{
	new iShitModelEntity = rg_create_entity( "info_target", .useHashTable = false);
	if (!iShitModelEntity || is_nullent(iShitModelEntity))
	{
		return;
	}
	
	static Float:fOrigin[ 3 ];
	get_entvar( id, var_origin, fOrigin );
	
	static Float:mins[3] = {-3.0 , -3.0 , 1.0};
	static Float:maxs[3] = {3.0 , 3.0 , 10.0};

	set_entvar(iShitModelEntity, var_classname, SHIT_MODEL_CLASSNAME );
	
	static Float:fVelocity[3];
	fVelocity[0] = 0.0;
	fVelocity[1] = 0.0;
	fVelocity[2] = -75.0;
	
	rh_emit_sound2( id, 0, CHAN_BODY , SHIT_SOUND_SHIT, 0.9 , ATTN_STATIC);
	
	set_entvar(iShitModelEntity, var_model, szModel);
	set_entvar(iShitModelEntity, var_modelindex, idxModel);
	
	set_entvar(iShitModelEntity, var_gravity, 2.0 );
	set_entvar(iShitModelEntity, var_movetype, MOVETYPE_FLY );
	set_entvar(iShitModelEntity, var_solid, SOLID_TRIGGER );
	set_entvar(iShitModelEntity, var_owner, id );
	set_entvar(iShitModelEntity, var_health, 55.0 );
	set_entvar(iShitModelEntity, var_takedamage, DAMAGE_YES);
	
	set_entvar(iShitModelEntity, var_velocity, fVelocity);
	set_entvar(iShitModelEntity, var_origin, fOrigin);
	
	set_entvar(iShitModelEntity, var_mins, mins);
	set_entvar(iShitModelEntity, var_maxs, maxs);
	
	SetTouch(iShitModelEntity, "INTO_SHIT");
	SetUse(iShitModelEntity, "EAT_SHIT");
	
	TRY_TO_START_PLAYER_SHITS(id, iShitModelEntity, second_mdl );
	
	if (second_mdl)
	{
		if (get_user_flags(id) & UFLAGS_GIRL)
		{
			rh_emit_sound2(iShitModelEntity, 0, CHAN_BODY , SHIT_SOUND_AMBIENT1, VOL_NORM / 1.2, ATTN_STATIC);
			rh_emit_sound2(iShitModelEntity, 0, CHAN_WEAPON , SHIT_SOUND_AMBIENT2, VOL_NORM / 4, ATTN_STATIC);
		}
		else
		{
			rh_emit_sound2(iShitModelEntity, 0, CHAN_BODY , SHIT_SOUND_AMBIENT1, VOL_NORM / 1.2, ATTN_STATIC);
		}
		
		new iSpriteShitEntity = rg_create_entity( "env_sprite", .useHashTable = false);
		if (!iSpriteShitEntity || is_nullent(iShitModelEntity))
		{
			return;
		}
	
		set_entvar(iSpriteShitEntity, var_model, szSprite);
		set_entvar(iSpriteShitEntity, var_modelindex, idxSprite);
		
		set_entvar(iSpriteShitEntity, var_spawnflags, SF_SPRITE_STARTON);
		set_entvar(iSpriteShitEntity, var_framerate, 4.0);
		
		if (idxSprite == SHIT_SPRITE2_IDX)
		{
			mins[2] = -50.0;
			fOrigin[2] += 50.0;
			set_entvar(iSpriteShitEntity, var_scale, 0.3);
			set_entvar(iSpriteShitEntity, var_rendermode, kRenderTransAdd);
			set_entvar(iSpriteShitEntity, var_renderamt, 180.0);
			set_entvar(iSpriteShitEntity, var_framerate, 8.0);
		}
		else
		{
			mins[2] = -5.0;
			fOrigin[2] += 10.0;
			set_entvar(iSpriteShitEntity, var_scale, 0.8);
			set_entvar(iSpriteShitEntity, var_rendermode, kRenderTransAlpha);
			set_entvar(iSpriteShitEntity, var_renderamt, 255.0);
		}
		set_entvar(iShitModelEntity, var_origin, fOrigin);
			
		set_entvar(iShitModelEntity, var_mins, mins);
		set_entvar(iShitModelEntity, var_maxs, maxs);
		
		dllfunc(DLLFunc_Spawn, iSpriteShitEntity)
		
		set_entvar(iShitModelEntity, var_iuser4, iSpriteShitEntity);
		set_entvar(iSpriteShitEntity, var_health, 25.0 );
		set_entvar(iSpriteShitEntity, var_takedamage, DAMAGE_YES);
		
		set_entvar(iSpriteShitEntity, var_velocity, fVelocity);

		set_entvar(iSpriteShitEntity, var_gravity, 2.0 );
		
		set_entvar(iSpriteShitEntity, var_movetype, MOVETYPE_FOLLOW);
		set_entvar(iSpriteShitEntity, var_aiment, iShitModelEntity);
		
		set_entvar(iSpriteShitEntity, var_classname, SHIT_SPRITE_CLASSNAME );
		
	}
	else 
	{
		set_entvar(iShitModelEntity, var_iuser4, 0);
	}
} 

START_SHIT_EATING(const iShitModelEntity, const iCaller)
{
	if(is_nullent(iShitModelEntity) || iCaller < 1 || iCaller > MAX_PLAYERS || !is_user_alive(iCaller)) 
	{
		return;
	}
	
	if(TeamName:get_member(iCaller, m_iTeam) != TEAM_CT && TeamName:get_member(iCaller, m_iTeam) != TEAM_TERRORIST) 
	{
		return;
	}
	
	static Float:vOrigin[3], Float:vShitPos[3];
	get_entvar(iCaller, var_origin, vOrigin);
	get_entvar(iShitModelEntity, var_origin, vShitPos);
	static name1[MAX_NAME_LENGTH];
	get_user_name(iCaller,name1,charsmax(name1));
	
	new id = get_entvar( iShitModelEntity, var_owner ) ;
	rh_emit_sound2(iCaller, 0, CHAN_BODY , SHIT_EAT_SOUND, VOL_NORM, ATTN_STATIC);
	if (id != iCaller)
	{
		if (id != 0 && is_user_connected(id))
		{
			g_iNumShit[id]++;
			static name2[MAX_NAME_LENGTH];
			get_user_name(id,name2,charsmax(name2));
	
			static phrase[MAX_PHRASE_LEN];
			if (get_user_flags(iCaller) & UFLAGS_GIRL)
			{    
				new Float:nKiller_hp = get_entvar(iCaller,var_health);
				
				if (get_user_flags(id) & UFLAGS_GIRL)
				{    
					nKiller_hp+=g_iEAT_HP_OTHER*2;
					GetRandomPhrase(PHRASE_FEMALE_FEMALE_EAT, phrase, charsmax(phrase));
				}
				else 
				{
					nKiller_hp+=g_iEAT_HP_OTHER;
					GetRandomPhrase(PHRASE_FEMALE_MALE_EAT, phrase, charsmax(phrase));
				}
				
				if (nKiller_hp > g_fMAX_EAT_HP)
				{
					nKiller_hp = g_fMAX_EAT_HP;
				}
				set_entvar(iCaller,var_health, nKiller_hp);
			}
			else 
			{
				if (get_user_flags(id) & UFLAGS_GIRL)
				{    
					GetRandomPhrase(PHRASE_MALE_FEMALE_EAT, phrase, charsmax(phrase));
				}
				else 
				{
					GetRandomPhrase(PHRASE_MALE_MALE_EAT, phrase, charsmax(phrase));
				}
			}
			
			replace_all(phrase, charsmax(phrase), "[user1]", name1);
			replace_all(phrase, charsmax(phrase), "[user2]", name2);
						
			client_print_color(0, print_team_red, "[%s]: %s", YOUR_SHIT_SERVER_NAME, phrase);
		}
	}
	else
	{
		new Float:nKiller_hp = get_entvar(iCaller,var_health);
		
		g_iNumShit[iCaller]++;
			
		static phrase[MAX_PHRASE_LEN];
		if (get_user_flags(iCaller) & UFLAGS_GIRL)
		{   
			nKiller_hp+=g_iEAT_HP_OWNER*2;
			GetRandomPhrase(PHRASE_FEMALE_EAT_SELF, phrase, charsmax(phrase));
		}
		else 
		{
			nKiller_hp+=g_iEAT_HP_OWNER;
			GetRandomPhrase(PHRASE_MALE_EAT_SELF, phrase, charsmax(phrase));
		}
	 
		if (nKiller_hp > g_fMAX_EAT_HP)
		{
			nKiller_hp = g_fMAX_EAT_HP;
		}
		set_entvar(iCaller,var_health, nKiller_hp);
	   
		replace_all(phrase, charsmax(phrase), "[user1]", name1);
					
		client_print_color(0, print_team_red, "[%s]: %s", YOUR_SHIT_SERVER_NAME, phrase);
		
	}
	
	rh_emit_sound2(iShitModelEntity, 0, CHAN_BODY , SHIT_SOUND_AMBIENT1, VOL_NORM, ATTN_NORM, SND_STOP, PITCH_NORM );
	rh_emit_sound2(iShitModelEntity, 0, CHAN_WEAPON , SHIT_SOUND_AMBIENT2, VOL_NORM, ATTN_NORM, SND_STOP, PITCH_NORM );
	
	new iShitSpriteEntity = get_entvar(iShitModelEntity, var_iuser4 );
	if (iShitSpriteEntity != 0 && !is_nullent(iShitSpriteEntity))
	{
		set_entvar(iShitSpriteEntity, var_nextthink, get_gametime());
		set_entvar(iShitSpriteEntity, var_flags, FL_KILLME);
	}
	
	set_entvar(iShitModelEntity, var_nextthink, get_gametime());
	set_entvar(iShitModelEntity, var_flags, FL_KILLME);
}

public CBasePlayer_ObjectCaps_pre(iEnt)
{
	if (FClassnameIs(iEnt, SHIT_MODEL_CLASSNAME))
	{
		SetHamReturnInteger(FCAP_IMPULSE_USE);
		return HAM_OVERRIDE;
	}
	return HAM_IGNORED;
}

public PlawerKilled(id, iAttacker, iGib) 
{ 
	get_entvar(id,var_origin,g_vDeadOrigins2[id]);
	set_task(1.2,"get_real_origin_player",id + DEATH_EVENT_TASK_OFFSET);
}

public get_real_origin_player(idx)
{
	new id = idx - DEATH_EVENT_TASK_OFFSET;
	get_entvar(id,var_origin,g_vDeadOrigins1[id]);
}

public EAT_SHIT(const iEntity, const iActivator, const iCaller, USE_TYPE:useType, const Float:value)
{
	if (g_bShitPluginActivated)
		START_SHIT_EATING(iEntity,iCaller);
}

public INTO_SHIT(const shitent, const id_target)
{
	if (g_bShitPluginActivated && !is_nullent(shitent) && id_target >= 1 && id_target <= MAX_PLAYERS && get_gametime() - g_fShitIntoTimeout[id_target] > g_fStepWait)
	{
		new id = get_entvar( shitent, var_owner );
		if (id != id_target && id != 0 && is_user_connected(id) && is_user_connected(id_target))
		{
			g_fShitIntoTimeout[id_target] = get_gametime();
			static name1[MAX_NAME_LENGTH];
			static name2[MAX_NAME_LENGTH];
	
			get_user_name(id_target,name1,charsmax(name1));
			get_user_name(id,name2,charsmax(name2));
			
			rh_emit_sound2(shitent, 0, CHAN_BODY , SHIT_SOUND_PLACE_IT_HERE, VOL_NORM, ATTN_STATIC);
			
			static phrase[MAX_PHRASE_LEN];
			
			if (get_user_flags(id_target) & UFLAGS_GIRL)
			{
				if (get_user_flags(id) & UFLAGS_GIRL)
				{
					GetRandomPhrase(PHRASE_FEMALE_FEMALE_STEP, phrase, charsmax(phrase));
				}
				else 
				{
					GetRandomPhrase(PHRASE_FEMALE_MALE_STEP, phrase, charsmax(phrase));
				}
			}
			else
			{
				if (get_user_flags(id) & UFLAGS_GIRL)
				{
					GetRandomPhrase(PHRASE_MALE_FEMALE_STEP, phrase, charsmax(phrase));
				}
				else 
				{
					GetRandomPhrase(PHRASE_MALE_MALE_STEP, phrase, charsmax(phrase));
				}
			}
			
			replace_all(phrase, charsmax(phrase), "[user1]", name1);
			replace_all(phrase, charsmax(phrase), "[user2]", name2);
			
			client_print_color(0, print_team_red, "[%s]: %s", YOUR_SHIT_SERVER_NAME, phrase);
		}
	}
}

read_shit_cfg()
{
	cfg_set_path("plugins/unreal_megashit");

	// Чтение основных параметров
	cfg_read_str("SHITCONFIG","YOUR_SHIT_SERVER_NAME",YOUR_SHIT_SERVER_NAME,YOUR_SHIT_SERVER_NAME,charsmax(YOUR_SHIT_SERVER_NAME));
	cfg_read_str("SHITCONFIG","FLAGS_SHIT",FLAGS_SHIT,FLAGS_SHIT,charsmax(FLAGS_SHIT));
	cfg_read_str("SHITCONFIG","FLAGS_GIRL",FLAGS_GIRL,FLAGS_GIRL,charsmax(FLAGS_GIRL));
	cfg_read_str("SHITCONFIG","SHIT_MODEL1",SHIT_MODEL1,SHIT_MODEL1,charsmax(SHIT_MODEL1));
	cfg_read_str("SHITCONFIG","SHIT_MODEL2",SHIT_MODEL2,SHIT_MODEL2,charsmax(SHIT_MODEL2));
	cfg_read_str("SHITCONFIG","SHIT_SPRITE1",SHIT_SPRITE1,SHIT_SPRITE1,charsmax(SHIT_SPRITE1));
	cfg_read_str("SHITCONFIG","SHIT_SPRITE2",SHIT_SPRITE2,SHIT_SPRITE2,charsmax(SHIT_SPRITE2));
	cfg_read_str("SHITCONFIG","SHIT_SOUND_SHIT",SHIT_SOUND_SHIT,SHIT_SOUND_SHIT,charsmax(SHIT_SOUND_SHIT));
	cfg_read_str("SHITCONFIG","SHIT_SOUND_NO_SHIT",SHIT_SOUND_NO_SHIT,SHIT_SOUND_NO_SHIT,charsmax(SHIT_SOUND_NO_SHIT));
	cfg_read_str("SHITCONFIG","SHIT_SOUND_PLACE_IT_HERE",SHIT_SOUND_PLACE_IT_HERE,SHIT_SOUND_PLACE_IT_HERE,charsmax(SHIT_SOUND_PLACE_IT_HERE));
	cfg_read_str("SHITCONFIG","SHIT_SOUND_AMBIENT1",SHIT_SOUND_AMBIENT1,SHIT_SOUND_AMBIENT1,charsmax(SHIT_SOUND_AMBIENT1));
	cfg_read_str("SHITCONFIG","SHIT_SOUND_AMBIENT2",SHIT_SOUND_AMBIENT2,SHIT_SOUND_AMBIENT2,charsmax(SHIT_SOUND_AMBIENT2));
	cfg_read_str("SHITCONFIG","SHIT_EAT_SOUND",SHIT_EAT_SOUND,SHIT_EAT_SOUND,charsmax(SHIT_EAT_SOUND));
	
	cfg_read_int("SHITCONFIG","MAX_SHIT_COUNT",MAX_SHIT_COUNT,MAX_SHIT_COUNT);
	cfg_read_flt("SHITCONFIG","START_SHIT_TIME",START_SHIT_TIME,START_SHIT_TIME);
	
	cfg_read_int("SHITCONFIG","EAT_OWNER_HP",g_iEAT_HP_OWNER,g_iEAT_HP_OWNER);
	cfg_read_int("SHITCONFIG","EAT_OTHER_HP",g_iEAT_HP_OTHER,g_iEAT_HP_OTHER);
	cfg_read_flt("SHITCONFIG","MAX_EAT_HP",g_fMAX_EAT_HP,g_fMAX_EAT_HP);
	
	cfg_read_flt("SHITCONFIG", "STEP_WAIT_TIME",g_fStepWait,g_fStepWait);
	
	// Вывод конфига
	log_amx(" ");
	log_amx("====== UnrealMegaShit Config Loaded ======");
	log_amx("Server Name: %s", YOUR_SHIT_SERVER_NAME);
	log_amx("Access Flags: %s (main), %s (girls)", FLAGS_SHIT, FLAGS_GIRL);
	log_amx("Max Actions: %d", MAX_SHIT_COUNT);
	log_amx("Start Delay: %.1f sec", START_SHIT_TIME);
	log_amx("Models: %.64s, %.64s", SHIT_MODEL1, SHIT_MODEL2);
	log_amx("Sprites: %.64s, %.64s", SHIT_SPRITE1, SHIT_SPRITE2);
	log_amx("=========================================");
	log_amx(" ");
	

	replace_all(YOUR_SHIT_SERVER_NAME, charsmax(YOUR_SHIT_SERVER_NAME), "^^4", "^4");
	replace_all(YOUR_SHIT_SERVER_NAME, charsmax(YOUR_SHIT_SERVER_NAME), "^^3", "^3");
	replace_all(YOUR_SHIT_SERVER_NAME, charsmax(YOUR_SHIT_SERVER_NAME), "^^2", "^2");
	replace_all(YOUR_SHIT_SERVER_NAME, charsmax(YOUR_SHIT_SERVER_NAME), "^^1", "^1");
	
	// Инициализация массивов для фраз
	new phrases_loaded = 0;
	for (new i = 0; i < sizeof(g_aPhrases); i++)
	{
		g_aPhrases[i] = ArrayCreate(MAX_PHRASE_LEN);
		phrases_loaded += load_shit_phrase(PHRASE_SECTIONS[i], g_aPhrases[i]);
	}
	
	log_amx("Loaded %d phrase categories with total %d phrases", sizeof(g_aPhrases), phrases_loaded);
	
	bind_pcvar_num(create_cvar("shit_active", "1",
					.description = "Activate unreal mega shit"
	),    g_bShitPluginActivated);
	
	UFLAGS_SHIT = strlen(FLAGS_SHIT) > 0 ? read_flags(FLAGS_SHIT) : 0;
	UFLAGS_GIRL = strlen(FLAGS_GIRL) > 0 ? read_flags(FLAGS_GIRL) : 0;
	
	log_amx("Access flags parsed: %d (main), %d (girls)", UFLAGS_SHIT, UFLAGS_GIRL);
	log_amx("Plugin activation: %s", g_bShitPluginActivated ? "ENABLED" : "DISABLED");
}

// Загрузка фраз из конфига
load_shit_phrase(const phrase_id[], Array:aTarget)
{
	new iPhrasesNum = 0;
	static phrase[MAX_PHRASE_LEN] = {EOS,...};
	static tmpBuf[64];
	new bool:found = false;
	new loaded = 0;
	
	cfg_read_int(phrase_id, "COUNT", iPhrasesNum,iPhrasesNum);
	if (iPhrasesNum == 0)
	{
		log_error(AMX_ERR_NOTFOUND, "Not found phrases for %s", phrase_id);
		return 0;
	}
	
	for(new i = 1; i <= iPhrasesNum; i++)
	{
		formatex(tmpBuf, charsmax(tmpBuf), "PHRASE_%i", i);
		if (cfg_read_str(phrase_id, tmpBuf, phrase, phrase, charsmax(phrase)) && phrase[0] != EOS)
		{
			replace_all(phrase, charsmax(phrase), "^^4", "^4");
			replace_all(phrase, charsmax(phrase), "^^3", "^3");
			replace_all(phrase, charsmax(phrase), "^^2", "^2");
			replace_all(phrase, charsmax(phrase), "^^1", "^1");
			
			ArrayPushString(aTarget, phrase);
			found = true;
			loaded++;
		}
	}
	
	if (!found)
	{
		log_error(AMX_ERR_NOTFOUND, "Not found phrases for %s", phrase_id);
	}
	
	return loaded;
}

// Функция для получения случайной фразы из массива
stock GetRandomPhrase(phraseType, output[], len)
{
	if (phraseType < 0 || phraseType >= sizeof(g_aPhrases) || g_aPhrases[phraseType] == Invalid_Array)
	{
		output[0] = 0;
		log_error(AMX_ERR_NOTFOUND, "Not found phrases for %s type", PHRASE_SECTIONS[phraseType]);
		return;
	}
	
	new size = ArraySize(g_aPhrases[phraseType]);
	if (size == 0)
	{
		output[0] = 0;
		log_error(AMX_ERR_NOTFOUND, "Not found phrases for %s type",PHRASE_SECTIONS[phraseType]);
		return;
	}
	
	new index = random(size);
	ArrayGetString(g_aPhrases[phraseType], index, output, len);
}
