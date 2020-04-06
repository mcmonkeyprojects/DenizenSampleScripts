# +--------------------------
# |
# | M a g i c   S i d e b a r
# |
# | Provides a working live-updating per-player sidebar!
# |
# +--------------------------
#
# @author mcmonkey
# @date 2019/03/01
# @denizen-build REL-1700
# @script-version 1.0
#
# Installation:
# 1. Put the script in your scripts folder.
# 2. Edit the config script below to your liking.
# 3. Reload
#
# Usage:
# Type "/sidebar" in-game to toggle the sidebar on or off.
#
# ---------------------------- END HEADER ----------------------------

# ------------------------- Begin configuration -------------------------
magic_sidebar_config:
    type: yaml data
    # How many updates per second (acceptable values: 1, 2, 4, 5, 10)
    per_second: 5
    # Set this to your sidebar title.
    title: <&b><&l>Player Info
    # Set this to the list of sidebar lines you want to display.
    # Start a line with "[scroll:#/#]" to make it automatically scroll
    # with a specified width and scroll speed (characters shifted per second).
    # Note that width must always be less than the line's actual length.
    # There should also be at least one normal line that's as wide as the width, to prevent the sidebar resizing constantly.
    lines:
    - "[scroll:20/5]<&a>Welcome to <&6>my server<&a>, <&b><player.name><&a>!"
    - "<&8>-----------------------"
    - "Ping: <&b><player.ping>"
    - "Location: <&b><player.location.simple.before_last[,].replace[,].with[<&f>,<&b>]>"
    - "Online Players: <&b><server.list_online_players.size><&f>/<&b><server.max_players>"
# ------------------------- End of configuration -------------------------

magic_sidebar_world:
    type: world
    debug: false
    events:
        on delta time secondly:
        - define per_second <script[magic_sidebar_config].yaml_key[per_second]>
        - define wait_time <element[1].div[<[per_second]>]>s
        - define players <server.list_online_players.filter[has_flag[sidebar_disabled].not]>
        - define title <script[magic_sidebar_config].yaml_key[title]>
        - repeat <[per_second]>:
            - sidebar title:<[title].parsed> values:<proc[magic_sidebar_lines_proc]> players:<[players]> per_player
            - wait <[wait_time]>

magic_sidebar_lines_proc:
    type: procedure
    debug: false
    script:
    - define list <script[magic_sidebar_config].yaml_key[lines]>
    - foreach <[list]> as:line:
        - define list_index <[loop_index]>
        - define line <[line].parsed>
        - if <[line].starts_with[<&lb>scroll<&co>]>:
            - define width <[line].after[<&co>].before[/]>
            - define rate <[line].after[/].before[<&rb>]>
            - define line <[line].after[<&rb>]>
            - define index <server.current_time_millis.div[1000].mul[<[rate]>].round.mod[<[line].strip_color.length>].add[1]>
            - define end <[index].add[<[width]>]>
            - repeat <[line].length> as:charpos:
                - if <[line].char_at[<[charpos]>]> == <&ss>:
                    - define index <[index].add[2]>
                - if <[index]> <= <[charpos]>:
                    - repeat stop
            - define start_color <[line].substring[0,<[index]>].last_color>
            - if <[end]> > <[line].strip_color.length>:
                - define end <[end].sub[<[line].strip_color.length>]>
                - repeat <[line].length> as:charpos:
                    - if <[line].char_at[<[charpos]>]> == <&ss>:
                        - define end <[end].add[2]>
                    - if <[end]> < <[charpos]>:
                        - repeat stop
                - define line "<[start_color]><[line].substring[<[index]>]> <&f><[line].substring[0,<[end]>]>"
            - else:
                - repeat <[line].length> as:charpos:
                    - if <[line].char_at[<[charpos]>]> == <&ss>:
                        - define end <[end].add[2]>
                    - if <[end]> < <[charpos]>:
                        - repeat stop
                - define line <[start_color]><[line].substring[<[index]>,<[end]>]>
        - define list <[list].set[<[line]>].at[<[list_index]>]>
    - determine <[list]>

magic_sidebar_command:
    type: command
    debug: false
    name: sidebar
    usage: /sidebar
    description: Toggles your sidebar on or off.
    script:
    - if <player.has_flag[sidebar_disabled]>:
        - flag player sidebar_disabled:!
        - narrate "<&b>Sidebar enabled."
    - else:
        - flag player sidebar_disabled
        - narrate "<&b>Sidebar disabled."
        - wait 1
        - sidebar remove players:<player>
