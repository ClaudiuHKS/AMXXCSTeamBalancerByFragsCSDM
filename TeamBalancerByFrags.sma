
/*** ----------------------------------------------------------------------------------------------------------------------- ***/

// Use "\"some quoted string inside a string\"" instead of "^"some quoted string inside a string^""
//
#pragma ctrlchar '\'

/*** ----------------------------------------------------------------------------------------------------------------------- ***/

#include < amxmodx > // register_cvar, ...
#include < cstrike > // cs_set_user_team, ...

native dllfunc( const nType, const any: ... ); /** Optional */ /// The game server does not need to have this function [ FAKEMETA MODULE ]

native spawn( const nEntity ); /** Optional */ /// The game server does not need to have this function [ FUN MODULE ]

native bool: csdm_active( ); /** Optional */ /// The game server does not need to have this function [ CSDM MODULE ]
native Float: csdm_get_spawnwait( ); /** Optional */ /// The game server does not need to have this function [ CSDM MODULE ]
native csdm_set_spawnwait( const Float: fTime ); /** Optional */ /// The game server does not need to have this function [ CSDM MODULE ]
native csdm_respawn( const nPlayer ); /** Optional */ /// The game server does not need to have this function [ CSDM MODULE ]

/*** ----------------------------------------------------------------------------------------------------------------------- ***/

// The plugin version
//
static const g_szPluginVersion[ ] = "8.0";

// The game sound directory name
//
static const g_szSoundDirectoryName[ ] = "sound";

// The wave audio file path (optional to be uploaded to the game server & then downloaded by the players)
//
static const g_szWaveAudioFilePath[ ] = "team_balancer_by_frags/transfer.wav";

// This is a negative number which represents a player that is not valid
//
static const g_nInvalidPlayer = -1;

// A random number
//
static const g_nRandomNumber = -7105824;

/*** ----------------------------------------------------------------------------------------------------------------------- ***/

// Check whether the server is running `CS:DM` (has valid `csdm_active` console variable)
//
static g_nCsdmActive;

// For performance, use a variable for `CS:DM` active status storage
//
static bool: g_bCsdmActive;

// Console variable to set the checking frequency in seconds
//
static g_nFrequency;

// Frequency value globally cached
//
static Float: g_fFrequency;

// Console variable to allow bots computation delay after humans are computed to avoid chat spamming (humans are computed first)
//
static g_nBotsDelay;

// Console variable to control whether or not the player should be respawned when transferred
//
static g_nRespawn;

// Console variable to control whether or not to use `csdm_respawn` function if it exists
//
static g_nRespawnType;

// Console variable to control the delay between the player respawn moment and the announcements and the screen fade execution
//
static g_nRespawnDelay;

// Console variable to set the maximum difference between terrorists and counter terrorists
//
static g_nDifference_TE;

// Console variable to set maximum difference between counter terrorists and terrorists
//
static g_nDifference_CT;

// Console variable to set whether these transferrings are made by low frags or by high frags
//
static g_nSetting;

// Cached for performance
//
static bool: g_bSetting;

// Console variable intended to store the plugin version
//
static g_nVersion;

// The plugin talk tag
//
static g_nTag;

// The plugin talk tag cached for performance
//
static g_szTag[ 64 ];

// Console variable to set whether this plugin auto decides if the player picked up for transfer has the lowest or the highest score (frags)
// from his team depending on the enemy team overall scoring
//
static g_nAuto;

// Cached for performance
//
static g_nAutoNum;

// Console variable to allow sorting (by using this feature we allow the game server to transfer the second or the third best player for example),
// in order to transfer the one that is the most appropiate based on their score (frags)
//
static g_nSorting;

// Cached for performance
//
static g_nSortingNum;

// Console variable to set whether or not to use audio alert when transferring a player
//
static g_nAudio;

// Cached for performance
//
static g_nAudioNum;

// Console variable to control how the audio alert is sent
//
// 0 speak into the transferred player ears only (a teleport like sound effect)
// 1 that player emits the sound (a teleport like sound effect) globally and other close positioned players are able to hear that too at a lower volume
// 2 speak into the transferred player ears only (a man speaking words "YOUR NOW [ T / C T ] FORCE")
//
static g_nAudioType;

// Cached for performance
//
static g_nAudioTypeNum;

// Console variable to control whether or not to consider bots humans
//
// 1 consider bots humans
// 0 bots are balanced half T force & half CT force
//
static g_nBots;

// For performance reasons cache the 'team_balancer_bots' value
//
static bool: g_bBotsAreLikeHumans;

// Console variable to allow a global chat message announcing the transfer
//
// 0 off
// 1 on
// 2 on & colored
//
static g_nAnnounceAll;

// Cached for performance
//
static g_nAnnounceAllNum;

// Console variable to announce the player on their screen when transferred
//
static g_nAnnounce;

// Cached for performance
//
static g_nAnnounceNum;

// Console variable to set the transferred player screen announce type
//
// 0 print_center (screen middle)
// 1 print_chat (print_talk [screen left bottom])
// 2 print_chat (print_talk [screen left bottom]) colored
//
static g_nAnnounceType;

// Cached for performance
//
static g_nAnnounceTypeNum;

// Console variable to set a screen fade for the transferred player
//
static g_nScreenFade;

// Console variable to set the duration for the screen fade
//
static g_nScreenFadeDuration;

// Console variable to set the hold time for the screen fade
//
static g_nScreenFadeHoldTime;

// Console variable to set the RGBA color for the terrorist force screen fade
//
static g_nScreenFadeRGBA_TE[ 4 ];

// Console variable to set the RGBA color for the counter terrorist force screen fade
//
static g_nScreenFadeRGBA_CT[ 4 ];

// The `ScreenFade` game message index
//
static g_nScreenFadeMsg;

// The `SayText` game message index
//
static g_nSayTextMsg;

// Console variable to set the immune admin flag
//
static g_nFlag;

// Variable to store the immune admin flag (for performance)
//
static g_nFlagNum;

// Total T team score (frags)
//
static g_nScoring_TE;

// Total CT team score (frags)
//
static g_nScoring_CT;

// Variable used to reveal whether or not the actual round has ended, useful if the `CS:DM` extension is disabled
//
static bool: g_bCanBalance;

// If enabled, balance only during round end if `CS:DM` is disabled
//
static g_nRoundEndOnly;

// Cached for performance
//
static bool: g_bRoundEndOnly;

// If enabled, when balancing the teams only during round end while the `CS:DM` extension is disabled or missing,
// ignore the `team_balancer_frequency` and `team_balancer_bots_delay` console variables and perform everything very quick
//
static g_nRoundEndQuick;

// Cached for performance
//
static bool: g_bRoundEndQuick;

// Do not respawn if the `CS:DM` extension is missing or disabled
//
static g_nNoRespawn;

// Executes after a map starts
//
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

    g_nFrequency = register_cvar( "team_balancer_frequency", "5.0" );
    g_nBotsDelay = register_cvar( "team_balancer_bots_delay", "2.5" );
    g_nDifference_TE = register_cvar( "team_balancer_te_difference", "1" );
    g_nDifference_CT = register_cvar( "team_balancer_ct_difference", "1" );
    g_nSetting = register_cvar( "team_balancer_by_low_frags", "1" );
    g_nAuto = register_cvar( "team_balancer_auto", "1" );
    g_nBots = register_cvar( "team_balancer_bots", "0" );
    g_nAnnounce = register_cvar( "team_balancer_announce", "1" );
    g_nAnnounceType = register_cvar( "team_balancer_announce_type", "0" );
    g_nAnnounceAll = register_cvar( "team_balancer_announce_all", "2" );
    g_nFlag = register_cvar( "team_balancer_admin_flag", "a" );
    g_nTag = register_cvar( "team_balancer_talk_tag", "[Team Balancer]" );
    g_nAudio = register_cvar( "team_balancer_audio", "1" );
    g_nAudioType = register_cvar( "team_balancer_audio_type", "0" );
    g_nScreenFade = register_cvar( "team_balancer_screen_fade", "1" );
    g_nScreenFadeDuration = register_cvar( "team_balancer_sf_duration", "1.0" );
    g_nScreenFadeHoldTime = register_cvar( "team_balancer_sf_hold_time", "0.1" );
    g_nSorting = register_cvar( "team_balancer_sorting", "1" );
    g_nRespawn = register_cvar( "team_balancer_respawn", "1" );
    g_nRespawnType = register_cvar( "team_balancer_respawn_type", "1" );
    g_nRespawnDelay = register_cvar( "team_balancer_respawn_delay", "0.25" );
    g_nRoundEndOnly = register_cvar( "team_balancer_round_end_only", "1" );
    g_nRoundEndQuick = register_cvar( "team_balancer_round_end_quick", "1" );
    g_nNoRespawn = register_cvar( "team_balancer_no_respawn", "1" );

    g_nScreenFadeRGBA_TE[ 0 ] = register_cvar( "team_balancer_sf_te_r", "200" ); /// Red
    g_nScreenFadeRGBA_TE[ 1 ] = register_cvar( "team_balancer_sf_te_g", "40" ); /// Green
    g_nScreenFadeRGBA_TE[ 2 ] = register_cvar( "team_balancer_sf_te_b", "0" ); /// Blue
    g_nScreenFadeRGBA_TE[ 3 ] = register_cvar( "team_balancer_sf_te_a", "240" ); /// Alpha

    g_nScreenFadeRGBA_CT[ 0 ] = register_cvar( "team_balancer_sf_ct_r", "0" ); /// Red
    g_nScreenFadeRGBA_CT[ 1 ] = register_cvar( "team_balancer_sf_ct_g", "40" ); /// Green
    g_nScreenFadeRGBA_CT[ 2 ] = register_cvar( "team_balancer_sf_ct_b", "200" ); /// Blue
    g_nScreenFadeRGBA_CT[ 3 ] = register_cvar( "team_balancer_sf_ct_a", "240" ); /// Alpha

    set_task( 0.25, "T_Install", get_systime( 0 ), "", 0, "", 0 );

    g_nCsdmActive = get_cvar_pointer( "csdm_active" );

    register_event( "HLTV", "E_OnRoundLaunch", "a", "1=0", "2=0" );
    {
        register_logevent( "LE_OnRoundBegin", 2, "1=Round_Start" );
        register_logevent( "LE_OnRoundEnd", 2, "1=Round_End" );
    }

    return PLUGIN_CONTINUE;
}

public E_OnRoundLaunch( )
{
    g_bCanBalance = false;
}

public LE_OnRoundBegin( )
{
    g_bCanBalance = false;
}

public LE_OnRoundEnd( )
{
    g_bCanBalance = true;
}

// Executes before `plugin_init`
//
public plugin_precache( )
{
    new szBuffer[ 256 ];
    {
        formatex( szBuffer, charsmax( szBuffer ), "%s/%s", g_szSoundDirectoryName, g_szWaveAudioFilePath );
        {
            if( file_exists( szBuffer ) )
            {
                precache_sound( g_szWaveAudioFilePath );
            }
        }
    }

    return PLUGIN_CONTINUE;
}

// Executes after `plugin_init`
//
public plugin_cfg( )
{
    g_nScreenFadeMsg = get_user_msgid( "ScreenFade" );
    g_nSayTextMsg = get_user_msgid( "SayText" );

    if( g_nVersion > 0 )
    {
        set_pcvar_string( g_nVersion, g_szPluginVersion );
    }

    return PLUGIN_CONTINUE;
}

// When a native is being computed
//
public Filter_Natives( const szNative[ ], const nNative, const bool: bFound )
{
    if( !bFound )
    {
        if( strcmp( szNative, "dllfunc", true ) == 0 || /** FAKEMETA */
            strcmp( szNative, "spawn", true ) == 0 || /** FUN */
            strcmp( szNative, "csdm_respawn", true ) == 0 || /** CSDM */
            strcmp( szNative, "csdm_active", true ) == 0 || /** CSDM */
            strcmp( szNative, "csdm_get_spawnwait", true ) == 0 || /** CSDM */
            strcmp( szNative, "csdm_set_spawnwait", true ) == 0) /** CSDM */
        {
            return PLUGIN_HANDLED; /** I understand that for some reason this native does not exist on the game server so don't throw any error to the logging system */
        }
    }

    return PLUGIN_CONTINUE;
}

// When the plugin computes the natives
//
public plugin_natives( )
{
    set_native_filter( "Filter_Natives" );

    return PLUGIN_CONTINUE;
}

// Get ready
//
public T_Install( const nTask )
{
    g_fFrequency = floatmax( get_pcvar_float( g_nFrequency ), 0.2 );
    {
        set_task( g_fFrequency, "T_CheckTeams", get_systime( 0 ), "", 0, "b", 0 ); // Repeat indefinitely
    }
}

// Check the teams
//
public T_CheckTeams( const nTask )
{
    // Data
    //
    static szName[ 32 ], szFlag[ 2 ], nPlayers_TE[ 32 ], nPlayers_CT[ 32 ], nNum_TE, nNum_CT, nPlayer, Float: fBotsDelay, Float: fTime, nUserId;

    // Cache global data for performance
    //
    g_bBotsAreLikeHumans = bool: get_pcvar_num( g_nBots );
    {
        g_nAnnounceTypeNum = get_pcvar_num( g_nAnnounceType );
        {
            g_nAnnounceNum = get_pcvar_num( g_nAnnounce );
            {
                g_nAudioTypeNum = get_pcvar_num( g_nAudioType );
                {
                    g_nAudioNum = get_pcvar_num( g_nAudio );
                    {
                        g_nAnnounceAllNum = get_pcvar_num( g_nAnnounceAll );
                        {
                            g_bRoundEndQuick = bool: get_pcvar_num( g_nRoundEndQuick );
                            {
                                g_bRoundEndOnly = bool: get_pcvar_num( g_nRoundEndOnly );
                                {
                                    g_bSetting = bool: get_pcvar_num( g_nSetting );
                                    {
                                        g_nAutoNum = get_pcvar_num( g_nAuto );
                                        {
                                            g_nSortingNum = get_pcvar_num( g_nSorting );
                                            {
                                                get_pcvar_string( g_nTag, g_szTag, charsmax( g_szTag ) );
                                                {
                                                    get_pcvar_string( g_nFlag, szFlag, charsmax( szFlag ) );
                                                    {
                                                        g_nFlagNum = read_flags( szFlag );
                                                    }

                                                    if( g_nCsdmActive > 0 )
                                                    {
                                                        g_bCsdmActive = ( get_pcvar_num( g_nCsdmActive ) && module_exists( "csdm" ) && csdm_active( ) );
                                                    }

                                                    else
                                                    {
                                                        g_bCsdmActive = false;
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    if( !g_bCsdmActive )
    {
        if( g_bRoundEndQuick )
        {
            if( g_bRoundEndOnly )
            {
                change_task( nTask, 0.2, 0 );
            }

            else
            {
                change_task( nTask, g_fFrequency, 0 );
            }
        }

        else
        {
            change_task( nTask, g_fFrequency, 0 );
        }

        if( !g_bCanBalance )
        {
            if( g_bRoundEndOnly )
            {
                return PLUGIN_CONTINUE;
            }
        }
    }

    else
    {
        change_task( nTask, g_fFrequency, 0 );
    }

    // Read terrorist team size in players count excluding hltv proxies
    //
    get_players( nPlayers_TE, nNum_TE, "eh", "TERRORIST" );

    // Read counter terrorist team size in players count excluding hltv proxies
    //
    get_players( nPlayers_CT, nNum_CT, "eh", "CT" );

    // Check whether the teams should be balanced
    //
    if( nNum_TE == nNum_CT )
    {
        goto BotsComputation;
    }

    // Is the difference between terrorists and counter terrorists higher than the specified value?
    //
    if( ( nNum_TE - nNum_CT ) > max( 1, get_pcvar_num( g_nDifference_TE ) ) )
    {
        // Get a terrorist
        //
        if( !g_nAutoNum )
        {
            nPlayer = FindPlayerByFrags( g_bSetting, CS_TEAM_T );
        }

        else
        {
            if( !g_nSortingNum )
            {
                g_nScoring_CT = CheckTeamScoring( CS_TEAM_CT );
                {
                    g_nScoring_TE = CheckTeamScoring( CS_TEAM_T );
                    {
                        nPlayer = FindPlayerByFrags( g_nScoring_CT >= g_nScoring_TE, CS_TEAM_T );
                    }
                }
            }

            else
            {
                g_nScoring_CT = CheckTeamScoring( CS_TEAM_CT );
                {
                    g_nScoring_TE = CheckTeamScoring( CS_TEAM_T );
                    {
                        nPlayer = FindSortedPlayer( CS_TEAM_T );
                    }
                }
            }
        }

        // Is this specified selected player a valid one?
        //
        if( nPlayer == g_nInvalidPlayer )
        {
            goto BotsComputation;
        }

        // Transfer them to the opposite team
        //
        cs_set_user_team( nPlayer, CS_TEAM_CT );

        // Should the player be respawned?
        //
        if( get_pcvar_num( g_nRespawn ) && ( !get_pcvar_num( g_nNoRespawn ) || g_bCsdmActive ) )
        {
            // Should this plugin use `csdm_respawn` if it exists?
            //
            if( g_bCsdmActive && get_pcvar_num( g_nRespawnType ) > 0 )
            {
                fTime = csdm_get_spawnwait( );
                {
                    if( fTime != 0.0 )
                    {
                        csdm_set_spawnwait( 0.0 );
                        {
                            csdm_respawn( nPlayer );
                        }
                        csdm_set_spawnwait( fTime );
                    }

                    else
                    {
                        csdm_respawn( nPlayer );
                    }
                }
            }

            else
            {
                if( module_exists( "fun" ) )
                {
                    spawn( nPlayer );
                }

                else if( module_exists( "fakemeta" ) )
                {
                    dllfunc( 1 /** DLLFunc_Spawn */, nPlayer );
                }

                else if( !is_user_alive( nPlayer ) )
                {
                    cs_user_spawn( nPlayer );
                }
            }

            nUserId = get_user_userid( nPlayer );
            {
                if( task_exists( nUserId + ( g_nRandomNumber ), 0 ) )
                {
                    remove_task( nUserId + ( g_nRandomNumber ), 0 );
                }

                set_task( floatmax( get_pcvar_float( g_nRespawnDelay ), 0.0 ), "T_OnceRespawned", nUserId + ( g_nRandomNumber ), "", 0, "", 0 );
            }

            goto BotsComputation;
        }

        // Announce them
        //
        if( g_nAnnounceNum )
        {
            if( g_nAnnounceTypeNum == 0 )
            {
                client_print( nPlayer, print_center, "You've joined the Counter-Terrorists" );
            }

            else if( g_nAnnounceTypeNum == 1 || g_nSayTextMsg < 1 )
            {
                client_print( nPlayer, print_chat, "%s You've joined the Counter-Terrorists", g_szTag );
            }

            else
            {
                sendSayText( nPlayer, 35 /** \x03 is blue */, "\x04%s\x01 You've joined the\x03 Counter-Terrorists", g_szTag );
            }
        }

        // Announce all
        //
        if( g_nAnnounceAllNum )
        {
            get_user_name( nPlayer, szName, charsmax( szName ) );
            {
                if( g_nAnnounceAllNum == 1 || g_nSayTextMsg < 1 )
                {
                    client_print( 0, print_chat, "%s %s joined the Counter-Terrorists", g_szTag, szName );
                }

                else
                {
                    sendSayText( 0, 35 /** \x03 is blue */, "\x04%s\x03 %s\x01 joined the\x03 Counter-Terrorists", g_szTag, szName );
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
        if( g_nAudioNum )
        {
            if( g_nAudioTypeNum == 0 )
            {
                client_cmd( nPlayer, "spk \"%s\"", g_szWaveAudioFilePath );
            }

            else if( g_nAudioTypeNum == 1 )
            {
                if( is_user_alive( nPlayer ) )
                {
                    emit_sound( nPlayer, CHAN_BODY, g_szWaveAudioFilePath, VOL_NORM, ATTN_NORM, 0, PITCH_NORM );
                }

                else
                {
                    client_cmd( nPlayer, "spk \"%s\"", g_szWaveAudioFilePath );
                }
            }

            else
            {
                client_cmd( nPlayer, "spk \"your now c team(e60) force\"" );
            }
        }
    }

    // Is the difference between counter terrorists and terrorists higher than the specified value?
    //
    else if( ( nNum_CT - nNum_TE ) > max( 1, get_pcvar_num( g_nDifference_CT ) ) )
    {
        // Get a counter terrorist
        //
        if( !g_nAutoNum )
        {
            nPlayer = FindPlayerByFrags( g_bSetting, CS_TEAM_CT );
        }

        else
        {
            if( !g_nSortingNum )
            {
                g_nScoring_TE = CheckTeamScoring( CS_TEAM_T );
                {
                    g_nScoring_CT = CheckTeamScoring( CS_TEAM_CT );
                    {
                        nPlayer = FindPlayerByFrags( g_nScoring_TE >= g_nScoring_CT, CS_TEAM_CT );
                    }
                }
            }

            else
            {
                g_nScoring_CT = CheckTeamScoring( CS_TEAM_CT );
                {
                    g_nScoring_TE = CheckTeamScoring( CS_TEAM_T );
                    {
                        nPlayer = FindSortedPlayer( CS_TEAM_CT );
                    }
                }
            }
        }

        // Is this specified selected player a valid one?
        //
        if( nPlayer == g_nInvalidPlayer )
        {
            goto BotsComputation;
        }

        // Transfer them to the opposite team
        //
        cs_set_user_team( nPlayer, CS_TEAM_T );

        // Should the player be respawned?
        //
        if( get_pcvar_num( g_nRespawn ) && ( !get_pcvar_num( g_nNoRespawn ) || g_bCsdmActive ) )
        {
            // Should this plugin use `csdm_respawn` if it exists?
            //
            if( g_bCsdmActive && get_pcvar_num( g_nRespawnType ) > 0 )
            {
                fTime = csdm_get_spawnwait( );
                {
                    if( fTime != 0.0 )
                    {
                        csdm_set_spawnwait( 0.0 );
                        {
                            csdm_respawn( nPlayer );
                        }
                        csdm_set_spawnwait( fTime );
                    }

                    else
                    {
                        csdm_respawn( nPlayer );
                    }
                }
            }

            else
            {
                if( module_exists( "fun" ) )
                {
                    spawn( nPlayer );
                }

                else if( module_exists( "fakemeta" ) )
                {
                    dllfunc( 1 /** DLLFunc_Spawn */, nPlayer );
                }

                else if( !is_user_alive( nPlayer ) )
                {
                    cs_user_spawn( nPlayer );
                }
            }

            nUserId = get_user_userid( nPlayer );
            {
                if( task_exists( nUserId + ( g_nRandomNumber ), 0 ) )
                {
                    remove_task( nUserId + ( g_nRandomNumber ), 0 );
                }

                set_task( floatmax( get_pcvar_float( g_nRespawnDelay ), 0.0 ), "T_OnceRespawned", nUserId + ( g_nRandomNumber ), "", 0, "", 0 );
            }

            goto BotsComputation;
        }

        // Announce them
        //
        if( g_nAnnounceNum )
        {
            if( g_nAnnounceTypeNum == 0 )
            {
                client_print( nPlayer, print_center, "You've joined the Terrorists" );
            }

            else if( g_nAnnounceTypeNum == 1 || g_nSayTextMsg < 1 )
            {
                client_print( nPlayer, print_chat, "%s You've joined the Terrorists", g_szTag );
            }

            else
            {
                sendSayText( nPlayer, 34 /** \x03 is red */, "\x04%s\x01 You've joined the\x03 Terrorists", g_szTag );
            }
        }

        // Announce all
        //
        if( g_nAnnounceAllNum )
        {
            get_user_name( nPlayer, szName, charsmax( szName ) );
            {
                if( g_nAnnounceAllNum == 1 || g_nSayTextMsg < 1 )
                {
                    client_print( 0, print_chat, "%s %s joined the Terrorists", g_szTag, szName );
                }

                else
                {
                    sendSayText( 0, 34 /** \x03 is red */, "\x04%s\x03 %s\x01 joined the\x03 Terrorists", g_szTag, szName );
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
        if( g_nAudioNum )
        {
            if( g_nAudioTypeNum == 0 )
            {
                client_cmd( nPlayer, "spk \"%s\"", g_szWaveAudioFilePath );
            }

            else if( g_nAudioTypeNum == 1 )
            {
                if( is_user_alive( nPlayer ) )
                {
                    emit_sound( nPlayer, CHAN_BODY, g_szWaveAudioFilePath, VOL_NORM, ATTN_NORM, 0, PITCH_NORM );
                }

                else
                {
                    client_cmd( nPlayer, "spk \"%s\"", g_szWaveAudioFilePath );
                }
            }

            else
            {
                client_cmd( nPlayer, "spk \"your now team(e60) force\"" );
            }
        }
    }

// Compute the bots in the end
//
BotsComputation:

    if( !g_bBotsAreLikeHumans )
    {
        fBotsDelay = floatclamp( get_pcvar_float( g_nBotsDelay ), 0.1, g_fFrequency / 2.0 );
        {
            set_task( ( ( g_bRoundEndQuick && g_bRoundEndOnly && !g_bCsdmActive && g_bCanBalance ) ? ( 0.1 ) : ( fBotsDelay ) ), "T_ManageBots", get_systime( 0 ), "", 0, "", 0 );
        }
    }

    return PLUGIN_CONTINUE;
}

public T_ManageBots( const nTask )
{
    static nPlayer, szName[ 32 ], nUserId, Float: fTime;

    if( ( BotsNum( CS_TEAM_T ) - BotsNum( CS_TEAM_CT ) ) > max( 1, get_pcvar_num( g_nDifference_TE ) ) )
    {
        // Get a terrorist bot
        //
        if( !g_nAutoNum )
        {
            nPlayer = FindBotByFrags( g_bSetting, CS_TEAM_T );
        }

        else
        {
            if( !g_nSortingNum )
            {
                nPlayer = FindBotByFrags( ( g_nScoring_CT = CheckTeamScoring( CS_TEAM_CT ) ) >= ( g_nScoring_TE = CheckTeamScoring( CS_TEAM_T ) ), CS_TEAM_T );
            }

            else
            {
                g_nScoring_CT = CheckTeamScoring( CS_TEAM_CT );
                {
                    g_nScoring_TE = CheckTeamScoring( CS_TEAM_T );
                    {
                        nPlayer = FindSortedBot( CS_TEAM_T );
                    }
                }
            }
        }

        // Is this specified selected bot a valid one?
        //
        if( nPlayer == g_nInvalidPlayer )
        {
            return PLUGIN_CONTINUE;
        }

        // Transfer them to the opposite team
        //
        cs_set_user_team( nPlayer, CS_TEAM_CT );

        // Should the player be respawned?
        //
        if( get_pcvar_num( g_nRespawn ) && ( !get_pcvar_num( g_nNoRespawn ) || g_bCsdmActive ) )
        {
            // Should this plugin use `csdm_respawn` if it exists?
            //
            if( g_bCsdmActive && get_pcvar_num( g_nRespawnType ) > 0 )
            {
                fTime = csdm_get_spawnwait( );
                {
                    if( fTime != 0.0 )
                    {
                        csdm_set_spawnwait( 0.0 );
                        {
                            csdm_respawn( nPlayer );
                        }
                        csdm_set_spawnwait( fTime );
                    }

                    else
                    {
                        csdm_respawn( nPlayer );
                    }
                }
            }

            else
            {
                if( module_exists( "fun" ) )
                {
                    spawn( nPlayer );
                }

                else if( module_exists( "fakemeta" ) )
                {
                    dllfunc( 1 /** DLLFunc_Spawn */, nPlayer );
                }

                else if( !is_user_alive( nPlayer ) )
                {
                    cs_user_spawn( nPlayer );
                }
            }

            nUserId = get_user_userid( nPlayer );
            {
                if( task_exists( nUserId + ( g_nRandomNumber ), 0 ) )
                {
                    remove_task( nUserId + ( g_nRandomNumber ), 0 );
                }

                set_task( floatmax( get_pcvar_float( g_nRespawnDelay ), 0.0 ), "T_OnceRespawned", nUserId + ( g_nRandomNumber ), "", 0, "", 0 );
            }

            return PLUGIN_CONTINUE;
        }

        // Announce all
        //
        if( g_nAnnounceAllNum )
        {
            get_user_name( nPlayer, szName, charsmax( szName ) );
            {
                if( g_nAnnounceAllNum == 1 || g_nSayTextMsg < 1 )
                {
                    client_print( 0, print_chat, "%s %s joined the Counter-Terrorists", g_szTag, szName );
                }

                else
                {
                    sendSayText( 0, 35 /** \x03 is blue */, "\x04%s\x03 %s\x01 joined the\x03 Counter-Terrorists", g_szTag, szName );
                }
            }
        }

        // Audio alert them if needed
        //
        if( g_nAudioNum )
        {
            if( g_nAudioTypeNum == 1 )
            {
                if( is_user_alive( nPlayer ) )
                {
                    emit_sound( nPlayer, CHAN_BODY, g_szWaveAudioFilePath, VOL_NORM, ATTN_NORM, 0, PITCH_NORM );
                }
            }
        }
    }

    else if( ( BotsNum( CS_TEAM_CT ) - BotsNum( CS_TEAM_T ) ) > max( 1, get_pcvar_num( g_nDifference_CT ) ) )
    {
        // Get a counter terrorist bot
        //
        if( !g_nAutoNum )
        {
            nPlayer = FindBotByFrags( g_bSetting, CS_TEAM_CT );
        }

        else
        {
            if( !g_nSortingNum )
            {
                nPlayer = FindBotByFrags( ( g_nScoring_TE = CheckTeamScoring( CS_TEAM_T ) ) >= ( g_nScoring_CT = CheckTeamScoring( CS_TEAM_CT ) ), CS_TEAM_CT );
            }

            else
            {
                g_nScoring_CT = CheckTeamScoring( CS_TEAM_CT );
                {
                    g_nScoring_TE = CheckTeamScoring( CS_TEAM_T );
                    {
                        nPlayer = FindSortedBot( CS_TEAM_CT );
                    }
                }
            }
        }

        // Is this specified selected bot a valid one?
        //
        if( nPlayer == g_nInvalidPlayer )
        {
            return PLUGIN_CONTINUE;
        }

        // Transfer them to the opposite team
        //
        cs_set_user_team( nPlayer, CS_TEAM_T );

        // Should the player be respawned?
        //
        if( get_pcvar_num( g_nRespawn ) && ( !get_pcvar_num( g_nNoRespawn ) || g_bCsdmActive ) )
        {
            // Should this plugin use `csdm_respawn` if it exists?
            //
            if( g_bCsdmActive && get_pcvar_num( g_nRespawnType ) > 0 )
            {
                fTime = csdm_get_spawnwait( );
                {
                    if( fTime != 0.0 )
                    {
                        csdm_set_spawnwait( 0.0 );
                        {
                            csdm_respawn( nPlayer );
                        }
                        csdm_set_spawnwait( fTime );
                    }

                    else
                    {
                        csdm_respawn( nPlayer );
                    }
                }
            }

            else
            {
                if( module_exists( "fun" ) )
                {
                    spawn( nPlayer );
                }

                else if( module_exists( "fakemeta" ) )
                {
                    dllfunc( 1 /** DLLFunc_Spawn */, nPlayer );
                }

                else if( !is_user_alive( nPlayer ) )
                {
                    cs_user_spawn( nPlayer );
                }
            }

            nUserId = get_user_userid( nPlayer );
            {
                if( task_exists( nUserId + ( g_nRandomNumber ), 0 ) )
                {
                    remove_task( nUserId + ( g_nRandomNumber ), 0 );
                }

                set_task( floatmax( get_pcvar_float( g_nRespawnDelay ), 0.0 ), "T_OnceRespawned", nUserId + ( g_nRandomNumber ), "", 0, "", 0 );
            }

            return PLUGIN_CONTINUE;
        }

        // Announce all
        //
        if( g_nAnnounceAllNum )
        {
            get_user_name( nPlayer, szName, charsmax( szName ) );
            {
                if( g_nAnnounceAllNum == 1 || g_nSayTextMsg < 1 )
                {
                    client_print( 0, print_chat, "%s %s joined the Terrorists", g_szTag, szName );
                }

                else
                {
                    sendSayText( 0, 34 /** \x03 is red */, "\x04%s\x03 %s\x01 joined the\x03 Terrorists", g_szTag, szName );
                }
            }
        }

        // Audio alert them if needed
        //
        if( g_nAudioNum )
        {
            if( g_nAudioTypeNum == 1 )
            {
                if( is_user_alive( nPlayer ) )
                {
                    emit_sound( nPlayer, CHAN_BODY, g_szWaveAudioFilePath, VOL_NORM, ATTN_NORM, 0, PITCH_NORM );
                }
            }
        }
    }

    return PLUGIN_CONTINUE;
}

// The player has been respawned right now or a few moments ago because they have been transferred
//
public T_OnceRespawned( const nTask )
{
    static nPlayer, szName[ 32 ], CsTeams: nTeam;
    {
        if( ( nPlayer = find_player( "k", nTask - ( g_nRandomNumber ) ) ) > 0 )
        {
            if( is_user_bot( nPlayer ) )
            {
                if( ( nTeam = cs_get_user_team( nPlayer ) ) == CS_TEAM_T )
                {
                    // Announce all
                    //
                    if( g_nAnnounceAllNum )
                    {
                        get_user_name( nPlayer, szName, charsmax( szName ) );
                        {
                            if( g_nAnnounceAllNum == 1 || g_nSayTextMsg < 1 )
                            {
                                client_print( 0, print_chat, "%s %s joined the Terrorists", g_szTag, szName );
                            }

                            else
                            {
                                sendSayText( 0, 34 /** \x03 is red */, "\x04%s\x03 %s\x01 joined the\x03 Terrorists", g_szTag, szName );
                            }
                        }
                    }

                    // Audio alert them if needed
                    //
                    if( g_nAudioNum )
                    {
                        if( g_nAudioTypeNum == 1 )
                        {
                            if( is_user_alive( nPlayer ) )
                            {
                                emit_sound( nPlayer, CHAN_BODY, g_szWaveAudioFilePath, VOL_NORM, ATTN_NORM, 0, PITCH_NORM );
                            }
                        }
                    }
                }

                else if( nTeam == CS_TEAM_CT )
                {
                    // Announce all
                    //
                    if( g_nAnnounceAllNum )
                    {
                        get_user_name( nPlayer, szName, charsmax( szName ) );
                        {
                            if( g_nAnnounceAllNum == 1 || g_nSayTextMsg < 1 )
                            {
                                client_print( 0, print_chat, "%s %s joined the Counter-Terrorists", g_szTag, szName );
                            }

                            else
                            {
                                sendSayText( 0, 35 /** \x03 is blue */, "\x04%s\x03 %s\x01 joined the\x03 Counter-Terrorists", g_szTag, szName );
                            }
                        }
                    }

                    // Audio alert them if needed
                    //
                    if( g_nAudioNum )
                    {
                        if( g_nAudioTypeNum == 1 )
                        {
                            if( is_user_alive( nPlayer ) )
                            {
                                emit_sound( nPlayer, CHAN_BODY, g_szWaveAudioFilePath, VOL_NORM, ATTN_NORM, 0, PITCH_NORM );
                            }
                        }
                    }
                }
            }

            else
            {
                if( ( nTeam = cs_get_user_team( nPlayer ) ) == CS_TEAM_T )
                {
                    // Announce them
                    //
                    if( g_nAnnounceNum )
                    {
                        if( g_nAnnounceTypeNum == 0 )
                        {
                            client_print( nPlayer, print_center, "You've joined the Terrorists" );
                        }

                        else if( g_nAnnounceTypeNum == 1 || g_nSayTextMsg < 1 )
                        {
                            client_print( nPlayer, print_chat, "%s You've joined the Terrorists", g_szTag );
                        }

                        else
                        {
                            sendSayText( nPlayer, 34 /** \x03 is red */, "\x04%s\x01 You've joined the\x03 Terrorists", g_szTag );
                        }
                    }

                    // Announce all
                    //
                    if( g_nAnnounceAllNum )
                    {
                        get_user_name( nPlayer, szName, charsmax( szName ) );
                        {
                            if( g_nAnnounceAllNum == 1 || g_nSayTextMsg < 1 )
                            {
                                client_print( 0, print_chat, "%s %s joined the Terrorists", g_szTag, szName );
                            }

                            else
                            {
                                sendSayText( 0, 34 /** \x03 is red */, "\x04%s\x03 %s\x01 joined the\x03 Terrorists", g_szTag, szName );
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
                    if( g_nAudioNum )
                    {
                        if( g_nAudioTypeNum == 0 )
                        {
                            client_cmd( nPlayer, "spk \"%s\"", g_szWaveAudioFilePath );
                        }

                        else if( g_nAudioTypeNum == 1 )
                        {
                            if( is_user_alive( nPlayer ) )
                            {
                                emit_sound( nPlayer, CHAN_BODY, g_szWaveAudioFilePath, VOL_NORM, ATTN_NORM, 0, PITCH_NORM );
                            }

                            else
                            {
                                client_cmd( nPlayer, "spk \"%s\"", g_szWaveAudioFilePath );
                            }
                        }

                        else
                        {
                            client_cmd( nPlayer, "spk \"your now team(e60) force\"" );
                        }
                    }
                }

                else if( nTeam == CS_TEAM_CT )
                {
                    // Announce them
                    //
                    if( g_nAnnounceNum )
                    {
                        if( g_nAnnounceTypeNum == 0 )
                        {
                            client_print( nPlayer, print_center, "You've joined the Counter-Terrorists" );
                        }

                        else if( g_nAnnounceTypeNum == 1 || g_nSayTextMsg < 1 )
                        {
                            client_print( nPlayer, print_chat, "%s You've joined the Counter-Terrorists", g_szTag );
                        }

                        else
                        {
                            sendSayText( nPlayer, 35 /** \x03 is blue */, "\x04%s\x01 You've joined the\x03 Counter-Terrorists", g_szTag );
                        }
                    }

                    // Announce all
                    //
                    if( g_nAnnounceAllNum )
                    {
                        get_user_name( nPlayer, szName, charsmax( szName ) );
                        {
                            if( g_nAnnounceAllNum == 1 || g_nSayTextMsg < 1 )
                            {
                                client_print( 0, print_chat, "%s %s joined the Counter-Terrorists", g_szTag, szName );
                            }

                            else
                            {
                                sendSayText( 0, 35 /** \x03 is blue */, "\x04%s\x03 %s\x01 joined the\x03 Counter-Terrorists", g_szTag, szName );
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
                    if( g_nAudioNum )
                    {
                        if( g_nAudioTypeNum == 0 )
                        {
                            client_cmd( nPlayer, "spk \"%s\"", g_szWaveAudioFilePath );
                        }

                        else if( g_nAudioTypeNum == 1 )
                        {
                            if( is_user_alive( nPlayer ) )
                            {
                                emit_sound( nPlayer, CHAN_BODY, g_szWaveAudioFilePath, VOL_NORM, ATTN_NORM, 0, PITCH_NORM );
                            }

                            else
                            {
                                client_cmd( nPlayer, "spk \"%s\"", g_szWaveAudioFilePath );
                            }
                        }

                        else
                        {
                            client_cmd( nPlayer, "spk \"your now c team(e60) force\"" );
                        }
                    }
                }
            }
        }
    }
}

// Read bots count in a team
//
static BotsNum( const CsTeams: nTeam )
{
    static nPlayers[ 32 ], nNum;
    {
        get_players( nPlayers, nNum, "deh", nTeam == CS_TEAM_T ? "TERRORIST" : "CT" );
    }

    return nNum;
}

// This function will return the player with the lowest/ highest frags from one team or `g_nInvalidPlayer`
//
static FindPlayerByFrags( const bool: bByLowFrags, const CsTeams: nTeam )
{
    static nWho, nPlayers[ 32 ], nNum, nPlayer, nIter, nMinMaxFrags, nFrags;

    if( g_bBotsAreLikeHumans )
    {
        get_players( nPlayers, nNum, g_bCsdmActive ? "eh" : "beh", nTeam == CS_TEAM_T ? "TERRORIST" : "CT" ); // Filter out hltv proxies
    }

    else
    {
        get_players( nPlayers, nNum, g_bCsdmActive ? "ceh" : "bceh", nTeam == CS_TEAM_T ? "TERRORIST" : "CT" ); // Filter out bots & hltv proxies
    }

    // The lowest/ highest number
    //
    nMinMaxFrags = bByLowFrags ? ( ( 2000000000 ) /* Highest */ ) : ( ( -2000000000 ) /* Lowest */ );

    for( nIter = 0, nWho = g_nInvalidPlayer; nIter < nNum; nIter++ )
    {
        nPlayer = nPlayers[ nIter ];

        if( g_nFlagNum > 0 )
        { /// Special access
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

// This function will return the bot with the lowest/ highest frags from one team or `g_nInvalidPlayer`
//
static FindBotByFrags( const bool: bByLowFrags, const CsTeams: nTeam )
{
    static nWho, nPlayers[ 32 ], nNum, nPlayer, nIter, nMinMaxFrags, nFrags;

    // Exclude human players & hltv proxies
    //
    get_players( nPlayers, nNum, g_bCsdmActive ? "deh" : "bdeh", nTeam == CS_TEAM_T ? "TERRORIST" : "CT" );

    // The lowest/ highest number
    //
    nMinMaxFrags = bByLowFrags ? ( ( 2000000000 ) /* Highest */ ) : ( ( -2000000000 ) /* Lowest */ );

    for( nIter = 0, nWho = g_nInvalidPlayer; nIter < nNum; nIter++ )
    {
        nPlayer = nPlayers[ nIter ];

        if( g_nFlagNum > 0 )
        { /// Special access
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

// This function will return the player with the most appropiate frags for transfer from one team or `g_nInvalidPlayer`
//
static FindSortedPlayer( const CsTeams: nTeam )
{
    static nPlayers[ 32 ], nNum, nPlayer, nWho, nFrags, nIter, nData[ 32 ][ 2 /** [ 0 ] = player index & [ 1 ] = extra */ ], nEntries, nTopDifference;

    if( g_bBotsAreLikeHumans )
    {
        get_players( nPlayers, nNum, g_bCsdmActive ? "eh" : "beh", nTeam == CS_TEAM_T ? "TERRORIST" : "CT" ); // Filter out hltv proxies
    }

    else
    {
        get_players( nPlayers, nNum, g_bCsdmActive ? "ceh" : "bceh", nTeam == CS_TEAM_T ? "TERRORIST" : "CT" ); // Filter out bots & hltv proxies
    }

    for( nIter = 0, nEntries = 0, nWho = g_nInvalidPlayer; nIter < nNum; nIter++ )
    {
        nPlayer = nPlayers[ nIter ];

        if( g_nFlagNum > 0 )
        { /// Special access
            if( get_user_flags( nPlayer ) & g_nFlagNum )
            {
                continue;
            }
        }

        nFrags = get_user_frags( nPlayer );
        {
            nData[ nEntries ][ 0 ] = nPlayer;
            {
                nData[ nEntries ][ 1 ] = ( ( nTeam == CS_TEAM_T ) ? ( abs( ( g_nScoring_TE - nFrags ) - ( g_nScoring_CT + nFrags ) ) ) : ( abs( ( g_nScoring_CT - nFrags ) - ( g_nScoring_TE + nFrags ) ) ) );
            }
        }

        nEntries++;
    }

    if( nEntries > 0 )
    {
        for( nIter = 0, nTopDifference = 2000000000 /** A huge number */; nIter < nEntries; nIter++ )
        {
            if( nData[ nIter ][ 1 ] < nTopDifference )
            {
                nWho = nData[ nIter ][ 0 ];
                {
                    nTopDifference = nData[ nIter ][ 1 ];
                }
            }
        }
    }

    return nWho;
}

// This function will return the bot with the most appropiate frags for transfer from one team or `g_nInvalidPlayer`
//
static FindSortedBot( const CsTeams: nTeam )
{
    static nPlayers[ 32 ], nNum, nPlayer, nWho, nFrags, nIter, nData[ 32 ][ 2 /** [ 0 ] = player index & [ 1 ] = extra */ ], nEntries, nTopDifference;

    // Exclude human players & hltv proxies
    //
    get_players( nPlayers, nNum, g_bCsdmActive ? "deh" : "bdeh", nTeam == CS_TEAM_T ? "TERRORIST" : "CT" );

    for( nIter = 0, nEntries = 0, nWho = g_nInvalidPlayer; nIter < nNum; nIter++ )
    {
        nPlayer = nPlayers[ nIter ];

        if( g_nFlagNum > 0 )
        { /// Special access
            if( get_user_flags( nPlayer ) & g_nFlagNum )
            {
                continue;
            }
        }

        nFrags = get_user_frags( nPlayer );
        {
            nData[ nEntries ][ 0 ] = nPlayer;
            {
                nData[ nEntries ][ 1 ] = ( ( nTeam == CS_TEAM_T ) ? ( abs( ( g_nScoring_TE - nFrags ) - ( g_nScoring_CT + nFrags ) ) ) : ( abs( ( g_nScoring_CT - nFrags ) - ( g_nScoring_TE + nFrags ) ) ) );
            }
        }

        nEntries++;
    }

    if( nEntries > 0 )
    {
        for( nIter = 0, nTopDifference = 2000000000 /** A huge number */; nIter < nEntries; nIter++ )
        {
            if( nData[ nIter ][ 1 ] < nTopDifference )
            {
                nWho = nData[ nIter ][ 0 ];
                {
                    nTopDifference = nData[ nIter ][ 1 ];
                }
            }
        }
    }

    return nWho;
}

// The total frags of a team
//
static CheckTeamScoring( const CsTeams: nTeam )
{
    static nPlayers[ 32 ], nNum, nPlayer, nIter, nFrags;

    get_players( nPlayers, nNum, "eh", nTeam == CS_TEAM_T ? "TERRORIST" : "CT" ); // Exclude hltv proxies

    if( nNum < 1 )
    {
        return 0;
    }

    for( nIter = 0, nFrags = 0; nIter < nNum; nIter++ )
    {
        nPlayer = nPlayers[ nIter ];
        {
            nFrags += get_user_frags( nPlayer );
        }
    }

    return nFrags;
}

// Send screen fade
//
static PerformPlayerScreenFade( const nPlayer, const CsTeams: nTeam )
{
    if( nPlayer > 0 )
    {
        message_begin( MSG_ONE_UNRELIABLE, g_nScreenFadeMsg, { 0, 0, 0 } /** Message origin */, nPlayer );
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
                        {
                            write_byte( clamp( get_pcvar_num( g_nScreenFadeRGBA_TE[ 3 ] ), 0, 255 ) ); /// Alpha
                        }
                    }

                    else
                    { /// Blue
                        write_byte( clamp( get_pcvar_num( g_nScreenFadeRGBA_CT[ 0 ] ), 0, 255 ) ); /// Red
                        write_byte( clamp( get_pcvar_num( g_nScreenFadeRGBA_CT[ 1 ] ), 0, 255 ) ); /// Green
                        write_byte( clamp( get_pcvar_num( g_nScreenFadeRGBA_CT[ 2 ] ), 0, 255 ) ); /// Blue
                        {
                            write_byte( clamp( get_pcvar_num( g_nScreenFadeRGBA_CT[ 3 ] ), 0, 255 ) ); /// Alpha
                        }
                    }
                }
            }
        }
        message_end( );
    }

    return PLUGIN_CONTINUE;
}

// Colored print_chat (print_talk) message in CS & CZ
//
// ------
// nIndex
// ------
//
// If `nIndex` is 33 => ('\x03' is grey)
// If `nIndex` is 34 => ('\x03' is red)
// If `nIndex` is 35 => ('\x03' is blue)
//
// If `nIndex` is % any other value % => ('\x03' is their team color)
//
static sendSayText( const nPlayer, const nIndex, const szIn[ ], const any: ... )
{
    static szMsg[ 256 ], nPlayers[ 32 ], nNum, nIter, nTo;
    {
        if( vformat( szMsg, charsmax( szMsg ), szIn, 4 ) > 0 )
        {
            if( nPlayer > 0 )
            {
                message_begin( MSG_ONE_UNRELIABLE, g_nSayTextMsg, { 0, 0, 0 } /** Message origin */, nPlayer );
                {
                    write_byte( ( ( ( nIndex > 32 ) && ( nIndex < 36 ) ) ? ( nIndex ) : ( nPlayer ) ) );
                    {
                        write_string( szMsg );
                    }
                }
                message_end( );
            }

            else
            {
                get_players( nPlayers, nNum, "ch", "" ); // No bots & hltv proxies
                {
                    if( nNum > 0 )
                    {
                        for( nIter = 0; nIter < nNum; nIter++ )
                        {
                            nTo = nPlayers[ nIter ];
                            {
                                message_begin( MSG_ONE_UNRELIABLE, g_nSayTextMsg, { 0, 0, 0 } /** Message origin */, nTo );
                                {
                                    write_byte( ( ( ( nIndex > 32 ) && ( nIndex < 36 ) ) ? ( nIndex ) : ( nTo ) ) );
                                    {
                                        write_string( szMsg );
                                    }
                                }
                                message_end( );
                            }
                        }
                    }
                }
            }
        }
    }

    return PLUGIN_CONTINUE;
}
