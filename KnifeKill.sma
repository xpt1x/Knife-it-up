/* A Plugin from http://www.csindia.tech */
#include <amxmodx>
#include <fun>
#include <hamsandwich>

#define VERSION "3.0.4"
#define MAXSOUNDS 30

new songlist[MAXSOUNDS][64]
new songcount = 0

new bool:g_bHasSpeed[33];
new bool:b_sound = true;
new csi_kkb_hp, csi_kkb_frag, csi_kkb_prefix, csi_kkb_glow;
new csi_kkb_speed, csi_kkb_speed_time, csi_kkb_hud;

public plugin_init() 
{    
    register_plugin("Knife It UP", VERSION, "DiGiTaL")  /* Source from : Flicker, DiGiTaL */
    register_cvar("cskk_version", VERSION, FCVAR_SERVER)
    
    csi_kkb_prefix = register_cvar ("csi_kkb_prefix", "Knife")
    csi_kkb_speed = register_cvar ("csi_kkb_speed","550.0");
    csi_kkb_speed_time = register_cvar ("csi_kkb_speed_time","8.0");
    csi_kkb_hp = register_cvar ("csi_kkb_hp","15");
    csi_kkb_frag = register_cvar ("csi_kkb_frag","2");
    csi_kkb_glow = register_cvar("csi_kkb_glow", "1");
    csi_kkb_hud = register_cvar("csi_kkb_hud", "1");

    RegisterHam(Ham_Spawn, "player", "playerSpawn", 1);
    register_clcmd("say /sound", "soundSwitch");
    register_event("DeathMsg", "onDeathMsgEvent", "a");
    register_event("CurWeapon", "onCurWeaponEvent", "be", "1=1");
    server_cmd("sv_maxspeed 1000.0") // Comment if not required
}

public plugin_precache()
{
	new songsfile, namefull[64], allsongs[64], nameext[32]
	songsfile = open_dir("sound/knife", namefull, 63)
	do {
		strtok(namefull, allsongs, 63, nameext, 31, '.')
		if(equali(nameext, "mp3")){
			songlist[songcount] = allsongs
			songcount++
		}
	}
	while(songcount < MAXSOUNDS && next_file(songsfile, namefull, 63))
	close_dir(songsfile)
	for(new i=0;i<songcount;i++){
		format(allsongs, 63, "sound/knife/%s.mp3",songlist[i])
		precache_generic(allsongs)
	}
	return PLUGIN_CONTINUE
}

public onDeathMsgEvent()
{
	new id = read_data(1);
	new szWeapon[32];
	read_data(4, szWeapon, charsmax(szWeapon));
	
	if(equal(szWeapon, "knife") && is_user_alive(id))
	{
		new szName[32], szName2[32], i, szprefix[32]
		get_pcvar_string(csi_kkb_prefix, szprefix, charsmax(szprefix))
		get_user_name(id, szName, charsmax(szName));
		get_user_name(read_data(2), szName2, charsmax(szName2))
		
		i = random_num(0,songcount-1)
		client_cmd(0, "mp3 play sound/knife/%s",songlist[i])
		
		set_user_health(id, get_user_health( id ) + get_pcvar_num(csi_kkb_hp) )
		if(get_user_health(id) > 100) set_user_health(id, 100)
		set_user_frags( id, get_user_frags( id ) + get_pcvar_num(csi_kkb_frag) );
		
		if(get_pcvar_num(csi_kkb_glow)){
			if(get_user_team(id) == 1) set_user_rendering(id,kRenderFxGlowShell,255,0,0,kRenderNormal,25)
			else if(get_user_team(id) == 2) set_user_rendering(id,kRenderFxGlowShell,0,0,255,kRenderNormal,25)
		}
		
		if(get_pcvar_float(csi_kkb_speed) > 250.0) printColored(0, "^4[%s] ^3%s ^1knifed ^3%s ^1& gained ^3%d ^1HP, ^3%d ^1Frags and ^3Speed", szprefix, szName, szName2, get_pcvar_num(csi_kkb_hp),get_pcvar_num(csi_kkb_frag));
		else printColored(0, "^4[%s] ^3%s ^1knifed ^3%s ^1& gained ^3%d ^1HP and ^3%d ^1Frags", szprefix, szName, szName2, get_pcvar_num(csi_kkb_hp),get_pcvar_num(csi_kkb_frag));
		if(get_pcvar_num(csi_kkb_hud)){
			set_hudmessage(random(256), random(256), random(256), 0.041, 0.67, 1, 1.00, 3.00, 0.10, 0.20, -1);
			show_hudmessage(0, "%s has just Knifed %s", szName, szName2);
		}
		
		if (get_pcvar_float(csi_kkb_speed) > 250.0){
			g_bHasSpeed[id] = true;
			remove_task(id + 6969);
			set_task(get_pcvar_float(csi_kkb_speed_time), "taskRemoveSpeed", id + 6969);
			set_user_maxspeed(id, get_pcvar_float(csi_kkb_speed));     
		}        
	}
}

public playerSpawn(id) stateReset(id)

public onCurWeaponEvent(id){
    if(get_pcvar_float(csi_kkb_speed) > 250.0 && g_bHasSpeed[id])
        set_user_maxspeed(id, get_pcvar_float(csi_kkb_speed));
}

public taskRemoveSpeed(id){ 
	id -= 6969;
	stateReset(id)
	set_user_maxspeed(id, 250.0);
	printColored(id, "^4[Knife] ^1Your Bonus speed has been ^3Removed")
}

public stateReset(id){
    if (is_user_connected(id) && is_user_alive(id)){
       if(get_pcvar_num(csi_kkb_glow))
    		set_user_rendering(id,kRenderFxGlowShell,0,0,0,kRenderNormal,25) 
    }
    g_bHasSpeed[id] = false;
    remove_task(id + 6969);
}
public soundSwitch(id){
	new szprefix[32]
	get_pcvar_string(csi_kkb_prefix, szprefix, charsmax(szprefix))
	if(b_sound == false) { client_cmd(id, "mp3volume 1") ; b_sound = true ; }
	else if(b_sound == true) { client_cmd(id, "mp3volume 0") ; b_sound = false ; }
	printColored(id, "^4[%s] ^1Sounds are now ^3%s.", szprefix, !b_sound ? "OFF" : "ON")
}

#if AMXX_VERSION_NUM < 183
public client_disconnect(id) remove_task(id + 6969);
#else 
public client_disconnected(id) remove_task(id + 6969); 
#endif

stock printColored(const id, const input[], any:...) 
{ 
	new count = 1, players[32]; 
	static msg[191]; 
	vformat(msg, 190, input, 3); 

	replace_all(msg, 190, "^4", "^x04");
	replace_all(msg, 190, "^1", "^x01");
	replace_all(msg, 190, "^3", "^x03");

	if (id) players[0] = id; else get_players(players, count, "ch"); 
	{ 
		for (new i = 0; i < count; i++) 
		{ 
			if (is_user_connected(players[i])) 
			{ 
				message_begin(MSG_ONE_UNRELIABLE, get_user_msgid("SayText"), _, players[i]); 
				write_byte(players[i]); 
				write_string(msg); 
				message_end(); 
			} 
		} 
	} 
}