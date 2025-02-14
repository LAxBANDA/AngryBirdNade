/* Plugin generated by AMXX-Studio */

#include <amxmodx>
#include <amxmisc>
#include <fakemeta>
#include <zombiekillergalaxy>
#include <hamsandwich>
#include <fakemeta_util>
#include <fun>
#include <engine>


#define PLUGIN "Nowy Plugin"
#define VERSION "1.0"
#define AUTHOR "Sn!ff3r"

new const NADE_TYPE_KILLBOMB = 9000
new const sprite_grenade_trail[] = "sprites/laserbeam.spr"
new const model_grenade_infect[] = "models/zpre4/v_angry_bird.mdl"

new g_AngryBomb[33]
new cvar_enabled
new g_trailSpr, g_msgScoreInfo, g_msgDeathMsg, g_msgScoreAttrib
new g_msgSayText 
new explo

new const model_nade_fire[] = "models/zpre4/w_angry_bird.mdl" 

public plugin_init() 
{
	register_plugin(PLUGIN, VERSION, AUTHOR)
	
	RegisterHam(Ham_Think, "grenade", "fw_ThinkGrenade")
	RegisterHam(Ham_Killed, "player", "fw_PlayerKilled")
	
	register_forward(FM_SetModel, "fw_SetModel")	
	
	register_message(get_user_msgid("CurWeapon"), "message_cur_weapon")
	
	cvar_enabled = register_cvar("zp_kill_bomb","1")
	g_msgScoreInfo = get_user_msgid("ScoreInfo")
	g_msgDeathMsg = get_user_msgid("DeathMsg")
	g_msgScoreAttrib = get_user_msgid("ScoreAttrib")
	g_msgSayText = get_user_msgid("SayText")
}

public plugin_precache()
{
	g_trailSpr = engfunc(EngFunc_PrecacheModel, sprite_grenade_trail)
	explo = precache_model("sprites/zpre4/exp_mmissile.spr")
	engfunc(EngFunc_PrecacheModel,model_nade_fire)	
	engfunc(EngFunc_PrecacheModel, model_grenade_infect)
}

public plugin_natives()
{
	register_native("zp_get_user_angrybird", "native_get_user_angrybird", 1)
}

public client_disconnect(id)
{
	g_AngryBomb[id] = 0
}

public native_get_user_angrybird(player)
{
	client_cmd( player, "weapon_smokegrenade")
	g_AngryBomb[player] = 1	
	fm_strip_user_gun(player,9)
	fm_give_item(player,"weapon_smokegrenade")
	say(player, "^x04[ZK Galaxy]^x01 Haz comprado la bomba^x03 ANGRY BIRD.")
}

public fw_PlayerKilled(victim, attacker, shouldgib)
{
	g_AngryBomb[victim] = 0	
}

public fw_ThinkGrenade(entity)
{	
	if(!pev_valid(entity))
		return HAM_IGNORED
		
	static Float:dmgtime	
	pev(entity, pev_dmgtime, dmgtime)
	
	if (dmgtime > get_gametime())
		return HAM_IGNORED	
	
	if(pev(entity, pev_flTimeStepSound) == NADE_TYPE_KILLBOMB)
		kill_explode(entity)
	
	return HAM_SUPERCEDE
}

public fw_SetModel(entity, const model[])
{
	if(!get_pcvar_num(cvar_enabled))
		return	
	
	static Float:dmgtime
	pev(entity, pev_dmgtime, dmgtime)
	
	if (dmgtime == 0.0)
		return
	
	if (equal(model[7], "w_sm", 4))
	{		
		new owner = pev(entity, pev_owner)		
		
		if(!zp_get_user_zombie(owner) && g_AngryBomb[owner]) 
		{		
			fm_set_rendering(entity, kRenderFxGlowShell, 0, 0, 255, kRenderNormal, 32)
			
			message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
			write_byte(TE_BEAMFOLLOW) // TE id
			write_short(entity) // entity
			write_short(g_trailSpr) // sprite
			write_byte(10) // life
			write_byte(4) // width
			write_byte(0) // r
			write_byte(0) // g
			write_byte(255) // b
			write_byte(255) // brightness
			message_end()
			
			engfunc ( EngFunc_SetModel, entity, model_nade_fire )		

			set_pev(entity, pev_flTimeStepSound, NADE_TYPE_KILLBOMB)
		}
	}
	
}


public kill_explode(ent)
{
	if (!zp_has_round_started()) return
	
	static Float:originF[3]
	pev(ent, pev_origin, originF)
	
	create_blast(originF)	
	
	//engfunc(EngFunc_EmitSound, ent, CHAN_WEAPON, grenade_infect[random_num(0, sizeof grenade_infect - 1)], 1.0, ATTN_NORM, 0, PITCH_NORM)
	
	static attacker
	attacker = pev(ent, pev_owner)
	
	g_AngryBomb[attacker] = 0
	
	jp_radius_damage(ent)
	
	engfunc(EngFunc_RemoveEntity, ent)
}

public create_blast(const Float:originF[3])
{
	engfunc(EngFunc_MessageBegin, MSG_PVS, SVC_TEMPENTITY, originF, 0)	
	write_byte(TE_EXPLOSION)
	engfunc(EngFunc_WriteCoord, originF[0]) // x
	engfunc(EngFunc_WriteCoord, originF[1]) // y
	engfunc(EngFunc_WriteCoord, originF[2]) // z
	write_short(explo)
	write_byte(30)
	write_byte(15)
	write_byte(0)
	message_end()
	
	engfunc(EngFunc_MessageBegin, MSG_PVS, SVC_TEMPENTITY, originF, 0)
	write_byte(TE_DLIGHT) // TE id
	engfunc(EngFunc_WriteCoord, originF[0]) // x
	engfunc(EngFunc_WriteCoord, originF[1]) // y
	engfunc(EngFunc_WriteCoord, originF[2]) // z
	write_byte(50) // radius
	write_byte(255) // red
	write_byte(255) // green
	write_byte(128) // blue
	write_byte(30) // life
	write_byte(45) // decay rate
	message_end()
}

public UpdateFrags(attacker, victim, frags, deaths, scoreboard)
{
	set_pev(attacker, pev_frags, float(pev(attacker, pev_frags) + frags))
	
	fm_set_user_deaths(victim, fm_get_user_deaths(victim) + deaths)
	
	if (scoreboard)
	{	
		message_begin(MSG_BROADCAST, g_msgScoreInfo)
		write_byte(attacker) // id
		write_short(pev(attacker, pev_frags)) // frags
		write_short(fm_get_user_deaths(attacker)) // deaths
		write_short(0) // class?
		write_short(fm_get_user_team(attacker)) // team
		message_end()
		
		message_begin(MSG_BROADCAST, g_msgScoreInfo)
		write_byte(victim) // id
		write_short(pev(victim, pev_frags)) // frags
		write_short(fm_get_user_deaths(victim)) // deaths
		write_short(0) // class?
		write_short(fm_get_user_team(victim)) // team
		message_end()
	}
}

stock fm_set_user_deaths(id, value)
{
	set_pdata_int(id, 444, value, 5)
}

stock fm_get_user_deaths(id)
{
	return get_pdata_int(id, 444, 5)
}


stock fm_get_user_team(id)
{
	return get_pdata_int(id, 114, 5)
}

public SendDeathMsg(attacker, victim)
{
	message_begin(MSG_BROADCAST, g_msgDeathMsg)
	write_byte(attacker) // killer
	write_byte(victim) // victim
	write_byte(1) // headshot flag
	write_string("grenade") // killer's weapon
	message_end()
}

public FixDeadAttrib(id)
{
	message_begin(MSG_BROADCAST, g_msgScoreAttrib)
	write_byte(id) // id
	write_byte(0) // attrib
	message_end()
}

public replace_models(id)
{
	if (!is_user_alive(id))
		return
	
	if(get_user_weapon(id) == CSW_SMOKEGRENADE && g_AngryBomb[id])
	{
		set_pev(id, pev_viewmodel2, model_grenade_infect)
		
	}
}

public message_cur_weapon(msg_id, msg_dest, msg_entity)
{
	replace_models(msg_entity)
}


stock client_printcolor(const id, const input[], any:...)
{
	new iCount = 1, iPlayers[32]
	
	static szMsg[191]
	vformat(szMsg, charsmax(szMsg), input, 3)
	
	replace_all(szMsg, 190, "/g", "^4") // green txt
	replace_all(szMsg, 190, "/y", "^1") // orange txt
	replace_all(szMsg, 190, "/ctr", "^3") // team txt
	replace_all(szMsg, 190, "/w", "^0") // team txt
	
	if(id) iPlayers[0] = id
	else get_players(iPlayers, iCount, "ch")
		
	for (new i = 0; i < iCount; i++)
	{
		if (is_user_connected(iPlayers[i]))
		{
			message_begin(MSG_ONE_UNRELIABLE, g_msgSayText, _, iPlayers[i])
			write_byte(iPlayers[i])
			write_string(szMsg)
			message_end()
		}
	}
}


stock jp_radius_damage(entity) 
{
	new id = entity_get_edict(entity,EV_ENT_owner)
	for(new i = 1; i < 33; i++) 
	{
		if(is_user_alive(i) && !zp_get_user_nodamage(i)) 
		{
			new dist = floatround(entity_range(entity,i))
			
			if(dist <= 600) {
				new hp = get_user_health(i)
				new Float:damage = 4000-4000/600*float(dist)
				
				new Origin[3]
				get_user_origin(i,Origin)
				
				if(zp_get_user_zombie(id) != zp_get_user_zombie(i))
				{
						if(hp > damage)
							jp_take_damage(i,floatround(damage),Origin,DMG_BLAST)
						else
							log_kill(id,i,"Angry Bird",0)
					}
			}
		}
	}
}

stock log_kill(killer, victim, weapon[], headshot)
{
// code from MeRcyLeZZ
	set_msg_block(get_user_msgid("DeathMsg"), BLOCK_SET)
	ExecuteHamB(Ham_Killed, victim, killer, 2) // set last param to 2 if you want victim to gib
	set_msg_block(get_user_msgid("DeathMsg"), BLOCK_NOT)

	
	message_begin(MSG_BROADCAST, get_user_msgid("DeathMsg"))
	write_byte(killer)
	write_byte(victim)
	write_byte(headshot)
	write_string(weapon)
	message_end()
	
	if(get_user_team(killer)!=get_user_team(victim))
		set_user_frags(killer,get_user_frags(killer) +1)
	if(get_user_team(killer)==get_user_team(victim))
		set_user_frags(killer,get_user_frags(killer) -1)
		
	/*new kname[32], vname[32], kauthid[32], vauthid[32], kteam[10], vteam[10]

	get_user_name(killer, kname, 31)
	get_user_team(killer, kteam, 9)
	get_user_authid(killer, kauthid, 31)
 
	get_user_name(victim, vname, 31)
	get_user_team(victim, vteam, 9)
	get_user_authid(victim, vauthid, 31)
		
	log_message("^"%s<%d><%s><%s>^" killed ^"%s<%d><%s><%s>^" with ^"%s^"", 
	kname, get_user_userid(killer), kauthid, kteam, 
 	vname, get_user_userid(victim), vauthid, vteam, weapon)
*/
 	return PLUGIN_CONTINUE;
}

stock jp_take_damage(victim,damage,origin[3],bit) {
	message_begin(MSG_ONE,get_user_msgid("Damage"),{0,0,0},victim)
	write_byte(21)
	write_byte(20)
	write_long(bit)
	write_coord(origin[0])
	write_coord(origin[1])
	write_coord(origin[2])
	message_end()
	
	set_user_health(victim,get_user_health(victim)-damage)
}

public say(id, const msg[], any:...) {
    
	static buffer[512], msg_SayText = 0
    
	if(!msg_SayText) msg_SayText = get_user_msgid("SayText")
        
	vformat(buffer, charsmax(buffer), msg, 3)
            
	message_begin(MSG_ONE_UNRELIABLE, msg_SayText, _, id)
	write_byte(id)
	write_string(buffer)
	message_end()
}
