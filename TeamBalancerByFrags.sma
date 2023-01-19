
// Use "\"some quoted string inside a string\"" instead of "^"some quoted string inside a string^""
//
#pragma ctrlchar '\'

#include < amxmodx > // register_cvar, ...
#include < cstrike > // cs_set_user_team, ...

// The plugin version
//
new const g_szPluginVersion[ ] = "6.0";

// The left - right slashed game sound directory name
//
new const g_szSlashedSoundDirectoryName[ ] = "/sound/";

// The wave audio file path (optional to be uploaded to the game server & then downloaded by the players)
//
new const g_szWaveAudioFilePath[ ] = "team_balancer_by_frags/teleport.wav";

// The plugin talk tag
//
new const g_szPluginTalkTag[ ] = "[Team Balancer]";

// This is a negative number
//
new const g_nInvalidPlayer = -1;

// Check whether the server is running `CS:DM` (has valid `csdm_active` console variable)
//
new g_nCsdmActive;

// For performance, use a variable for `CS:DM` active status storage
//
new bool: g_bCsdmActive;

// Console variable to set the checking frequency in seconds
//
new g_nFrequency;

// Console variable to set the maximum difference between terrorists and counter terrorists
//
new g_nDifference_TE;

// Console variable to set maximum difference between counter terrorists and terrorists
//
new g_nDifference_CT;

// Console variable to set whether these transferrings are made by low frags or by high frags
//
new g_nSetting;

// Console variable intended to store the plugin version
//
new g_nVersion;

// Console variable to set whether this plugin auto decides if the player picked up for transfer has the lowest or the highest score (frags)
// from his team depending on the enemy team overall scoring
//
new g_nAuto;

// Console variable to set whether or not to use audio alert when transferring a player
//
new g_nAudio;

// Console variable to control how the audio alert is sent
//
// 0 speak into the transferred player ears only (a teleport like sound effect)
// 1 that player emits the sound (a teleport like sound effect) globally and other close positioned players are able to hear that too
// 2 speak into the transferred player ears only (a man speaking words "YOUR NOW [ T / C T ] FORCE")
//
new g_nAudioType;

// Console variable to allow a global chat message announcing the transfer
//
// 0 off
// 1 on
// 2 on & colored
//
new g_nAnnounceAll;

// Console variable to announce the player on their screen when transferred
//
new g_nAnnounce;

// Console variable to set the transferred player screen announce type
//
// 0 print_center (screen middle)
// 1 print_chat (print_talk [screen left bottom])
// 2 print_chat (print_talk [screen left bottom]) colored
//
new g_nAnnounceType;

// Console variable to set a screen fade for the transferred player
//
new g_nScreenFade;

// Console variable to set the duration for the screen fade
//
new g_nScreenFadeDuration;

// Console variable to set the hold time for the screen fade
//
new g_nScreenFadeHoldTime;

// Console variable to set the RGBA color for the terrorist force screen fade
//
new g_nScreenFadeRGBA_TE[ 4 ];

// Console variable to set the RGBA color for the counter terrorist force screen fade
//
new g_nScreenFadeRGBA_CT[ 4 ];

// The `ScreenFade` game message index
//
new g_nScreenFadeMsg;

// Console variable to set the immune admin flag
//
new g_nFlag;

// Variable to store the immune admin flag (for performance)
//
new g_nFlagNum;

public plugin_init( )
{
    register_plugin( "Team Balancer by Frags", g_szPluginVersion, "Hattrick (claudiuhks)" );
    {
        /// FCVAR_SERVER | FCVAR_SPONLY
        //
        /// https://github.com/alliedmodders/amxmodx/blob/master/amxmodx/meta_api.cpp#L132
        //
        g_nVersion = register_cvar( "team_balancer_by_frags", g_szPluginVersion, FCVAR_SERVER | FCVAR_SPONLY );
    }

    g_nFrequency = register_cvar( "team_balancer_frequency", "10" );
    g_nDifference_TE = register_cvar( "team_balancer_te_difference", "1" );
    g_nDifference_CT = register_cvar( "team_balancer_ct_difference", "1" );
    g_nSetting = register_cvar( "team_balancer_by_low_frags", "1" );
    g_nAuto = register_cvar( "team_balancer_auto", "1" );
    g_nAnnounce = register_cvar( "team_balancer_announce", "1" );
    g_nAnnounceType = register_cvar( "team_balancer_announce_type", "0" );
    g_nAnnounceAll = register_cvar( "team_balancer_announce_all", "2" );
    g_nFlag = register_cvar( "team_balancer_admin_flag", "a" );
    g_nAudio = register_cvar( "team_balancer_audio", "1" );
    g_nAudioType = register_cvar( "team_balancer_audio_type", "0" );
    g_nScreenFade = register_cvar( "team_balancer_screen_fade", "1" );
    g_nScreenFadeDuration = register_cvar( "team_balancer_sf_duration", "1.0" );
    g_nScreenFadeHoldTime = register_cvar( "team_balancer_sf_hold_time", "0.0" );

    g_nScreenFadeRGBA_TE[ 0 ] = register_cvar( "team_balancer_sf_te_r", "200" ); /// Red
    g_nScreenFadeRGBA_TE[ 1 ] = register_cvar( "team_balancer_sf_te_g", "40" ); /// Green
    g_nScreenFadeRGBA_TE[ 2 ] = register_cvar( "team_balancer_sf_te_b", "0" ); /// Blue
    g_nScreenFadeRGBA_TE[ 3 ] = register_cvar( "team_balancer_sf_te_a", "240" ); /// Alpha

    g_nScreenFadeRGBA_CT[ 0 ] = register_cvar( "team_balancer_sf_ct_r", "0" ); /// Red
    g_nScreenFadeRGBA_CT[ 1 ] = register_cvar( "team_balancer_sf_ct_g", "40" ); /// Green
    g_nScreenFadeRGBA_CT[ 2 ] = register_cvar( "team_balancer_sf_ct_b", "200" ); /// Blue
    g_nScreenFadeRGBA_CT[ 3 ] = register_cvar( "team_balancer_sf_ct_a", "240" ); /// Alpha

    set_task( get_pcvar_float( g_nFrequency ), "Task_CheckTeams", .flags = "b" /** Repeat */ );

    g_nCsdmActive = get_cvar_pointer( "csdm_active" );
}

// Executes before `plugin_init`
//
public plugin_precache( )
{
    new szBuffer[ 256 ];
    {
        get_modname( szBuffer, charsmax( szBuffer ) );
        {
            add( szBuffer, charsmax( szBuffer ), g_szSlashedSoundDirectoryName );
            {
                add( szBuffer, charsmax( szBuffer ), g_szWaveAudioFilePath );
                {
                    new nFile = fopen( szBuffer, "r" );
                    {
                        if( nFile )
                        {
                            fclose( nFile );
                            {
                                precache_sound( g_szWaveAudioFilePath );
                            }
                        }
                    }
                }
            }
        }
    }
}

// Executes after `plugin_init`
//
public plugin_cfg( )
{
    g_nScreenFadeMsg = get_user_msgid( "ScreenFade" );

    if( g_nVersion )
    {
        set_pcvar_string( g_nVersion, g_szPluginVersion );
    }
}

public Task_CheckTeams( )
{
    static szName[ 32 ], szFlag[ 2 ], nPlayers_TE[ 32 ], nPlayers_CT[ 32 ], nNum_TE, nNum_CT, nPlayer, nAudioType, nAnnounceType, nAnnounceAllType;

    get_players( nPlayers_TE, nNum_TE, "e", "TERRORIST" );

    // Check whether the teams should be balanced
    //
    if( nNum_TE < 1 )
    {
        return;
    }

    get_players( nPlayers_CT, nNum_CT, "e", "CT" );

    // Check whether the teams should be balanced
    //
    if( nNum_TE == nNum_CT || nNum_CT < 1 )
    {
        return;
    }

    get_pcvar_string( g_nFlag, szFlag, charsmax( szFlag ) );
    {
        g_nFlagNum = read_flags( szFlag );
    }

    if( g_nCsdmActive > 0 )
    {
        g_bCsdmActive = bool: get_pcvar_num( g_nCsdmActive );
    }

    else
    {
        g_bCsdmActive = false;
    }

    // Is the difference between terrorists and counter terrorists higher than the specified value?
    //
    if( nNum_TE - nNum_CT > max( 1, get_pcvar_num( g_nDifference_TE ) ) )
    {
        // Get a terrorist
        //
        if( !get_pcvar_num( g_nAuto ) )
        {
            nPlayer = FindPlayerByFrags( bool: get_pcvar_num( g_nSetting ), CS_TEAM_T );
        }

        else
        {
            nPlayer = FindPlayerByFrags( CheckTeamScoring( CS_TEAM_CT ) > CheckTeamScoring( CS_TEAM_T ), CS_TEAM_T );
        }

        // Is this specified selected player a valid one?
        //
        if( nPlayer == g_nInvalidPlayer )
        {
            return;
        }

        // Transfer them to the opposite team
        //
        cs_set_user_team( nPlayer, CS_TEAM_CT );

        // Announce them
        //
        if( get_pcvar_num( g_nAnnounce ) )
        {
            if( ( nAnnounceType = get_pcvar_num( g_nAnnounceType ) ) == 0 )
            {
                client_print( nPlayer, print_center, "You've joined the Counter-Terrorists" );
            }

            else if( nAnnounceType == 1 )
            {
                client_print( nPlayer, print_chat, "* %s You've joined the Counter-Terrorists", g_szPluginTalkTag );
            }

            else
            {
                client_print_color( nPlayer, print_team_blue, "\x01*\x04 %s\x01 You've joined the\x03 Counter-Terrorists", g_szPluginTalkTag );
            }
        }

        // Announce all
        //
        if( ( nAnnounceAllType = get_pcvar_num( g_nAnnounceAll ) ) )
        {
            get_user_name( nPlayer, szName, charsmax( szName ) );
            {
                if( nAnnounceAllType == 1 )
                {
                    client_print( 0, print_chat, "* %s %s joined the Counter-Terrorists", g_szPluginTalkTag, szName );
                }

                else
                {
                    client_print_color( 0, print_team_blue, "\x01*\x04 %s\x03 %s\x01 joined the\x03 Counter-Terrorists", g_szPluginTalkTag, szName );
                }
            }
        }

        // Screen fade them
        //
        if( g_nScreenFadeMsg > 0 )
        {
            if( get_pcvar_num( g_nScreenFade ) )
            {
                PerformPlayerScreenFade( nPlayer, CS_TEAM_CT );
            }
        }

        // Audio alert them
        //
        if( get_pcvar_num( g_nAudio ) )
        {
            if( ( nAudioType = get_pcvar_num( g_nAudioType ) ) == 0 )
            {
                client_cmd( nPlayer, "spk \"%s\"", g_szWaveAudioFilePath );
            }

            else if( nAudioType == 1 )
            {
                emit_sound( nPlayer, CHAN_BODY, g_szWaveAudioFilePath, VOL_NORM, ATTN_NORM, 0, PITCH_NORM );
            }

            else
            {
                client_cmd( nPlayer, "spk \"your now c team(e60) force\"" );
            }
        }

        // Make sure the difference between players is alright
        //
        Task_CheckTeams( );
    }

    // Is the difference between counter terrorists and terrorists higher than the specified value?
    //
    else if( nNum_CT - nNum_TE > max( 1, get_pcvar_num( g_nDifference_CT ) ) )
    {
        // Get a counter-terrorist
        //
        if( !get_pcvar_num( g_nAuto ) )
        {
            nPlayer = FindPlayerByFrags( bool: get_pcvar_num( g_nSetting ), CS_TEAM_CT );
        }

        else
        {
            nPlayer = FindPlayerByFrags( CheckTeamScoring( CS_TEAM_T ) > CheckTeamScoring( CS_TEAM_CT ), CS_TEAM_CT );
        }

        // Is this specified selected player a valid one?
        //
        if( nPlayer == g_nInvalidPlayer )
        {
            return;
        }

        // Transfer them to the opposite team
        //
        cs_set_user_team( nPlayer, CS_TEAM_T );

        // Announce them
        //
        if( get_pcvar_num( g_nAnnounce ) )
        {
            if( ( nAnnounceType = get_pcvar_num( g_nAnnounceType ) ) == 0 )
            {
                client_print( nPlayer, print_center, "You've joined the Terrorists" );
            }

            else if( nAnnounceType == 1 )
            {
                client_print( nPlayer, print_chat, "* %s You've joined the Terrorists", g_szPluginTalkTag );
            }

            else
            {
                client_print_color( nPlayer, print_team_red, "\x01*\x04 %s\x01 You've joined the\x03 Terrorists", g_szPluginTalkTag );
            }
        }

        // Announce all
        //
        if( ( nAnnounceAllType = get_pcvar_num( g_nAnnounceAll ) ) )
        {
            get_user_name( nPlayer, szName, charsmax( szName ) );
            {
                if( nAnnounceAllType == 1 )
                {
                    client_print( 0, print_chat, "* %s %s joined the Terrorists", g_szPluginTalkTag, szName );
                }

                else
                {
                    client_print_color( 0, print_team_red, "\x01*\x04 %s\x03 %s\x01 joined the\x03 Terrorists", g_szPluginTalkTag, szName );
                }
            }
        }

        // Screen fade them
        //
        if( g_nScreenFadeMsg > 0 )
        {
            if( get_pcvar_num( g_nScreenFade ) )
            {
                PerformPlayerScreenFade( nPlayer, CS_TEAM_T );
            }
        }

        // Audio alert them
        //
        if( get_pcvar_num( g_nAudio ) )
        {
            if( ( nAudioType = get_pcvar_num( g_nAudioType ) ) == 0 )
            {
                client_cmd( nPlayer, "spk \"%s\"", g_szWaveAudioFilePath );
            }

            else if( nAudioType == 1 )
            {
                emit_sound( nPlayer, CHAN_BODY, g_szWaveAudioFilePath, VOL_NORM, ATTN_NORM, 0, PITCH_NORM );
            }

            else
            {
                client_cmd( nPlayer, "spk \"your now team(e60) force\"" );
            }
        }

        // Make sure the difference between players is alright
        //
        Task_CheckTeams( );
    }
}

// This function will return the player with the lowest/ highest frags from one team or `INVALID_PLAYER`
//
FindPlayerByFrags( bool: bByLowFrags, CsTeams: nTeam )
{
    static nWho, nPlayers[ 32 ], nNum, nPlayer, n, nMinMaxFrags, nFrags;

    get_players( nPlayers, nNum, g_bCsdmActive ? "e" : "be", nTeam == CS_TEAM_T ? "TERRORIST" : "CT" );

    // The lowest/ highest number
    //
    nMinMaxFrags = bByLowFrags ? ( ( 67108864 ) /* Highest */ ) : ( ( -67108864 ) /* Lowest */ );

    // Invalid player stamp
    //
    nWho = g_nInvalidPlayer;

    for( n = 0; n < nNum; n++ )
    {
        nPlayer = nPlayers[ n ];

        if( g_nFlagNum > 0 )
        {
            if( get_user_flags( nPlayer ) & g_nFlagNum )
            {
                continue;
            }
        }

        nFrags = get_user_frags( nPlayer );

        if( bByLowFrags )
        {
            if( nFrags < nMinMaxFrags )
            {
                nMinMaxFrags = nFrags;
                {
                    nWho = nPlayer;
                }
            }
        }

        else
        {
            if( nFrags > nMinMaxFrags )
            {
                nMinMaxFrags = nFrags;
                {
                    nWho = nPlayer;
                }
            }
        }
    }

    return nWho;
}

// The total frags of a team
//
CheckTeamScoring( CsTeams: nTeam )
{
    static nPlayers[ 32 ], nNum, nPlayer, n, nFrags;

    get_players( nPlayers, nNum, "e", nTeam == CS_TEAM_T ? "TERRORIST" : "CT" );

    if( nNum < 1 )
    {
        return 0;
    }

    for( n = 0, nFrags = 0; n < nNum; n++ )
    {
        nPlayer = nPlayers[ n ];
        {
            nFrags += get_user_frags( nPlayer );
        }
    }

    return nFrags;
}

PerformPlayerScreenFade( nPlayer, CsTeams: nTeam )
{
    message_begin( MSG_ONE_UNRELIABLE, g_nScreenFadeMsg, .player = nPlayer );
    {
        write_short( floatround( 4096.0 /** UNIT_SECOND = ( 1 << 12 ) */ * floatabs( get_pcvar_float( g_nScreenFadeDuration ) ), floatround_round ) ); /// Duration
        write_short( floatround( 4096.0 /** UNIT_SECOND = ( 1 << 12 ) */ * floatabs( get_pcvar_float( g_nScreenFadeHoldTime ) ), floatround_round ) ); /// Hold time
        {
            write_short( 0 /** FFADE_IN = 0x0000 */ ); /// Fade type
            {
                if( nTeam == CS_TEAM_T )
                { /// Red
                    write_byte( clamp( get_pcvar_num( g_nScreenFadeRGBA_TE[ 0 ] ), 0, 255 ) ); /// Red
                    write_byte( clamp( get_pcvar_num( g_nScreenFadeRGBA_TE[ 1 ] ), 0, 255 ) ); /// Green
                    write_byte( clamp( get_pcvar_num( g_nScreenFadeRGBA_TE[ 2 ] ), 0, 255 ) ); /// Blue
                    write_byte( clamp( get_pcvar_num( g_nScreenFadeRGBA_TE[ 3 ] ), 0, 255 ) ); /// Alpha
                }

                else
                { /// Blue
                    write_byte( clamp( get_pcvar_num( g_nScreenFadeRGBA_CT[ 0 ] ), 0, 255 ) ); /// Red
                    write_byte( clamp( get_pcvar_num( g_nScreenFadeRGBA_CT[ 1 ] ), 0, 255 ) ); /// Green
                    write_byte( clamp( get_pcvar_num( g_nScreenFadeRGBA_CT[ 2 ] ), 0, 255 ) ); /// Blue
                    write_byte( clamp( get_pcvar_num( g_nScreenFadeRGBA_CT[ 3 ] ), 0, 255 ) ); /// Alpha
                }
            }
        }
    }
    message_end( );
}
