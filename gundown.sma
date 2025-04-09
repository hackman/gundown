// vim: set ts=4 sw=4 tw=99 noet:
//
// AMX Mod X, based on AMX Mod by Aleksander Naszko ("OLO").
// Copyright (C) The AMX Mod X Development Team.
//
// This software is licensed under the GNU General Public License, version 3 or higher.
// Additional exceptions apply. For full license details, see LICENSE.txt or visit:
//     https://alliedmods.net/amxmodx-license

//
// Gundown restriction plugin
//
// When a player has more then 15 frags and has less then frag/3 deaths, 
// prevent him from buying anything except the top 3 guns.
// This rule applies only if the player is on the winning team.

#include <amxmodx>
#include <cstrike>
// needed for Ham
#include <fakemeta>
#include <hamsandwich>

#define TEAM_T 1
#define TEAM_CT 2
#define MIN_FRAGS 15
#define MAX_PLAYERS 32

new const gundown[] = "Gundown Restrictions";
new const gundown_version[] = "1.7"

// Array to store Steam IDs
new player_limited[MAX_PLAYERS + 1][35]; // 32 players, each Steam ID max 34 chars + null

public plugin_init() {
	register_plugin(gundown, gundown_version, "hackman");
	RegisterHam(Ham_Spawn, "player", "player_spawn", 1);
}

public player_spawn(player) {
	if (!is_user_alive(player)) return;
	if (is_not_player_on_winning_team(player)) return;

	// Force player to drop the current weapon
	new weapon_id = get_user_weapon(player);

	if (prevent_weapon(player) && weapon_id != CSW_KNIFE && weapon_id != CSW_C4 && weapon_id != 1 && weapon_id != 16 && weapon_id != 17) { 
		client_print(player, print_chat, "Gundown: You are not allowed this weapon!");
		client_cmd(player, "drop");
	}
}

public CS_OnBuyAttempt(player, itemid) {
	if (is_not_player_on_winning_team(player)) return PLUGIN_CONTINUE;

	if (prevent_weapon(player) && disallowed_weapon(player, itemid)) {
		client_print(player, print_chat, "Gundown winning team: This item is restricted for you!");
		return PLUGIN_HANDLED;
	}

	return PLUGIN_CONTINUE;
}

// Checks if the player is on the winning team
public bool:is_not_player_on_winning_team(player) {
	new CsTeams:winning_team = get_winning_team();

	if (winning_team == CS_TEAM_UNASSIGNED)
		return false; // No winner yet

	return (cs_get_user_team(player) == winning_team);
}

// Returns the current winning team based on score
CsTeams:get_winning_team() {
    new t_score  = get_team_score(TEAM_T);
    new ct_score = get_team_score(TEAM_CT);

    if (t_score > ct_score)
        return CS_TEAM_T;
    else if (ct_score > t_score)
        return CS_TEAM_CT;

    return CS_TEAM_UNASSIGNED; // Tie or round not decided
}

// Retrieves team score
stock get_team_score(team_id) {
    new score = 0;
    switch(team_id) {
        case TEAM_T:  score = get_cvar_num("mp_tscore");
        case TEAM_CT: score = get_cvar_num("mp_ctscore");
    }
    return score;
}

public bool:disallowed_weapon(player, itemid) {
	// Pistols
	//   17 9x19mm Sidearm Terorist pistol
	//   16 KM .45 Tactical CT Pistol UPS 
	//    1 229 Compact
	// Equipment
	//    4 HE Granade
	//    9 Smoke Granade
	//   25 Flashbang
	//   31 Kevlar
	//   32 Kevlar+Helmet
	//   33 Defuse Kit
	//   34 Night vision
	//   36 Primary Ammo
	//   37 Secondary Ammo

	if (itemid == 1 || itemid == 4 || itemid == 9 || itemid == 16 || itemid == 17 || itemid == 25 || itemid == 31 || itemid == 32 || itemid == 33 || itemid == 34 || itemid == 36 || itemid == 37) {
		return false;
	} else {
		client_print(player, print_chat, "Gundown: This item is restricted for you!");
		return true;
	}
}

public bool:prevent_weapon(player) {
	new frags  = get_user_frags(player);
	new deaths = get_user_deaths(player);

	new steam_id[35];
	get_user_authid(player, steam_id, charsmax(steam_id));

	if (is_player_limited(steam_id))
		return true;

	if (frags >= MIN_FRAGS && frags/3 >= deaths) {
		get_user_authid(player, player_limited[player], charsmax(player_limited[]));
		return true;
	}

	return false;
}

// Function to check if a given Steam ID is already limited
bool:is_player_limited(const steam_id[]) {
	for (new i = 1; i <= MAX_PLAYERS; i++) {
		if (equal(player_limited[i], steam_id)) {
			return true;
		}
	}
	return false;
}
