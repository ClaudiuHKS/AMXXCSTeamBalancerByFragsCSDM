# AMXXCSTeamBalancerByFragsCSDM
https://forums.alliedmods.net/showthread.php?t=161175

team_balancer_frequency 10 // Team check frequency in seconds (float, for example can be 9.125)

team_balancer_te_difference 1 // Maximum difference between terrorists team and counter-terrorists

team_balancer_ct_difference 1 // Maximum difference between counter-terrorists team and terrorists

team_balancer_admin_flag "a" // Admin flag to set admins immune. Examples: a, b, c, d

team_balancer_announce 1 // Announce the player by message if they were transferred

team_balancer_announce_type 0 // Announce type (0 = print_center, 1 = print_chat [print_talk] & 2 = print_chat [print_talk] colored)

team_balancer_announce_all 2 // Announce everyone (0 = no, 1 = yes print_chat [print_talk] & 2 = yes print_chat [print_talk] colored)

team_balancer_screen_fade 1 // Performs a screen fade effect on the player if not 0

team_balancer_sf_duration 1.0 // Screen fade duration seconds, if screen fade enabled (float)

team_balancer_sf_hold_time 0.0 // Screen fade hold time seconds, if screen fade enabled (float)

team_balancer_audio 1 // Audio alert to the transferred player

team_balancer_audio_type 0 // Audio alert type (0 = speak to transferred player ears a teleport like sound, 1 = that player emits that sound globally so players around him can still hear the sound at a lower volume depending on the distance between them [if the transferred player is dead 0 will be used instead] & 2 = like 0 but speak "YOUR NOW [ T / C T ] FORCE")

team_balancer_sf_te_r 200 // Red T

team_balancer_sf_te_g 40 // Green T

team_balancer_sf_te_b 0 // Blue T

team_balancer_sf_te_a 240 // Alpha T

team_balancer_sf_ct_r 0 // Red CT

team_balancer_sf_ct_g 40 // Green CT

team_balancer_sf_ct_b 200 // Blue CT

team_balancer_sf_ct_a 240 // Alpha CT

team_balancer_by_low_frags 1 // Transfer players having the lowest score (1) or highest score (0)

team_balancer_auto 1 // If the enemy team is better or equal (better or equal scoring [frags]) we send to them a player with low frags to perform the balance or a player with high frags otherwise
