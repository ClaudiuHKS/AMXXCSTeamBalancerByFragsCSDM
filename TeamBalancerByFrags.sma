
#include < amxmodx >
#include < cstrike >

// This is a negative number to define `INVALID_PLAYER`
//
#define INVALID_PLAYER (-1)

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

// Console variable to announce the player when transferred
//
new g_nAnnounce;

// Console variable to set the announce type
//
new g_nAnnounceType;

// Console variable to set a screen fade
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
    register_plugin( "Team Balancer by Frags", "5.0", "Hattrick (claudiuhks)" );

    g_nFrequency = register_cvar( "team_balancer_frequency", "10" );
    g_nDifference_TE = register_cvar( "team_balancer_te_difference", "1" );
    g_nDifference_CT = register_cvar( "team_balancer_ct_difference", "1" );
    g_nSetting = register_cvar( "team_balancer_by_low_frags", "1" );
    g_nAnnounce = register_cvar( "team_balancer_announce", "0" );
    g_nAnnounceType = register_cvar( "team_balancer_announce_type", "0" );
    g_nFlag = register_cvar( "team_balancer_admin_flag", "" );
    g_nScreenFade = register_cvar( "team_balancer_screen_fade", "0" );
    g_nScreenFadeDuration = register_cvar( "team_balancer_sf_duration", "0.5" );
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

// Executes after `plugin_init`
//
public plugin_cfg( )
{
    g_nScreenFadeMsg = get_user_msgid( "ScreenFade" );
}

public Task_CheckTeams( )
{
    static szFlag[ 2 ], nPlayers_TE[ 32 ], nPlayers_CT[ 32 ], nNum_TE, nNum_CT, nPlayer;

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
        nPlayer = FindPlayerByFrags( bool: get_pcvar_num( g_nSetting ), CsTeams: CS_TEAM_T );

        // Is this specified target a valid one?
        //
        if( nPlayer == INVALID_PLAYER )
        {
            return;
        }

        // Transfer him to the opposite team
        //
        cs_set_user_team( nPlayer, CsTeams: CS_TEAM_CT );

        // Announce
        //
        if( get_pcvar_num( g_nAnnounce ) )
        {
            client_print( nPlayer, !get_pcvar_num( g_nAnnounceType ) ? print_center : print_chat, "You've joined the Counter-Terrorists" );
        }

        if( g_nScreenFadeMsg > 0 )
        {
            if( get_pcvar_num( g_nScreenFade ) )
            {
                PerformPlayerScreenFade( nPlayer, CS_TEAM_CT );
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
        nPlayer = FindPlayerByFrags( bool: get_pcvar_num( g_nSetting ), CsTeams: CS_TEAM_CT );

        // Is this specified target a valid one?
        //
        if( nPlayer == INVALID_PLAYER )
        {
            return;
        }

        // Transfer him to the opposite team
        //
        cs_set_user_team( nPlayer, CsTeams: CS_TEAM_T );

        // Announce
        //
        if( get_pcvar_num( g_nAnnounce ) )
        {
            client_print( nPlayer, !get_pcvar_num( g_nAnnounceType ) ? print_center : print_chat, "You've joined the Terrorists" );
        }

        if( g_nScreenFadeMsg > 0 )
        {
            if( get_pcvar_num( g_nScreenFade ) )
            {
                PerformPlayerScreenFade( nPlayer, CS_TEAM_CT );
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
    nWho = INVALID_PLAYER;

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
