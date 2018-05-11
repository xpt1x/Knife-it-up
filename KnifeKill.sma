/* A Plugin from http://www.csindia.tech */
#include <amxmodx>
#include <fun>
#include <hamsandwich>
#if AMXX_VERSION_NUM < 183
	#include <colorchat>
	#define client_disconnected client_disconnect
#endif

#define VERSION "3.0.5"
#define MAXSOUNDS 30

new songlist[MAXSOUNDS][64]
new songcount = 0

new bool:g_bHasSpeed[33];
new bool:b_sound[33]
new csi_kkb_hp, csi_kkb_frag, csi_kkb_prefix, csi_kkb_glow;
new csi_kkb_speed, csi_kkb_speed_time, csi_kkb_hud , csi_kkb_dir
new szprefix[32], hudObj, szDir[64]

public plugin_init() 
{    
    register_plugin("Knife It UP", VERSION, "DiGiTaL")  
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
  
    get_pcvar_string(csi_kkb_prefix, szprefix, charsmax(szprefix))
    server_cmd("sv_maxspeed 1000.0") // Comment if not required

    hudObj = CreateHudSyncObj()
}

public plugin_precache()
{
	csi_kkb_dir = register_cvar("csi_kkb_dir", "sound/knife")
	get_pcvar_string(csi_kkb_dir, szDir, charsmax(szDir))

	new songsfile, namefull[64], allsongs[64], nameext[32]
	songsfile = open_dir(szDir, namefull, 63)
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
		format(allsongs, 63, "%s/%s.mp3", szDir, songlist[i])
		precache_generic(allsongs)
	}
	return PLUGIN_CONTINUE
}

public client_putinserver(id) b_sound[id] = true

public onDeathMsgEvent()
{
	new id = read_data(1);
	new szWeapon[32];
	read_data(4, szWeapon, charsmax(szWeapon));
	
	if(equal(szWeapon, "knife") && is_user_alive(id))
	{
		new szName[32], szName2[32], players[32], iPlayer, num, r
		get_user_name(id, szName, charsmax(szName));
		get_user_name(read_data(2), szName2, charsmax(szName2))

		new Float: gSpeed = get_pcvar_float(csi_kkb_speed)
		new gHP = get_pcvar_num(csi_kkb_hp)
		new gFrag = get_pcvar_num(csi_kkb_frag)

		r = random_num(0,songcount-1)		

		get_players(players, num)
		for(new i; i < num; i++) {
			iPlayer = players[i]
			if(b_sound[iPlayer]) client_cmd(iPlayer, "mp3 play %s/%s", szDir, songlist[r])
		}
		
		set_user_health(id, clamp(get_user_health( id ) + gHP, 1, 100))
		set_user_frags( id, get_user_frags( id ) + gFrag);
		
		if(get_pcvar_num(csi_kkb_glow)){
			new iTeam = get_user_team(id)
			switch(iTeam) {
				case 1: set_user_rendering(id,kRenderFxGlowShell,255,0,0,kRenderNormal,25)
				case 2: set_user_rendering(id,kRenderFxGlowShell,0,0,255,kRenderNormal,25)
			}
		}

		if(gSpeed > 250.0) client_print_color(0, 0, "^1[^4%s^1] ^3%s ^1knifed ^3%s ^1& gained ^3%d ^1HP, ^3%d ^1Frags and ^3Speed", szprefix, szName, szName2, gHP, gFrag);
		else client_print_color(0, 0, "^1[^4%s^1] ^3%s ^1knifed ^3%s ^1& gained ^3%d ^1HP and ^3%d ^1Frags", szprefix, szName, szName2, gHP, gFrag);
		
		if(get_pcvar_num(csi_kkb_hud)){
			set_hudmessage(random(256), random(256), random(256), 0.041, 0.67, 1, 1.00, 3.00, 0.10, 0.20, -1);
			ShowSyncHudMsg(0, hudObj, "%s has just Knifed %s", szName, szName2)
		}
		
		if (gSpeed > 250.0){
			g_bHasSpeed[id] = true;
			remove_task(id + 6969);
			set_task(get_pcvar_float(csi_kkb_speed_time), "taskRemoveSpeed", id + 6969);
			set_user_maxspeed(id, gSpeed);     
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
	client_print_color(id, -2, "^1[^4%s^1] Your Bonus speed has been ^3Removed", szprefix)
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
	b_sound[id] = b_sound[id] ? false : true
	client_print_color(id, -2, "^1[^4%s^1] Sounds are now %s.", szprefix, b_sound[id] ? "^4ON" : "^3OFF")
}

public client_disconnected(id) remove_task(id + 6969); 
