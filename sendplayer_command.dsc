# +-------------------
# |
# | SendPlayer Command
# |
# | A drop-in command script to send a player to another server on a bungee network.
# |
# +-------------------
#
# @author mcmonkey
# @date 2020/04/06
# @denizen-build REL-1706
# @script-version 1.0
#
# Installation:
# Just put the script in your scripts folder and reload.
#
# Usage:
# /sendplayer [player] [server]
# When typed in-game, is used like: /sendplayer mcmonkey4eva myservernamehere
# Very useful for something like an NPC right-click command, like: /npc command add sendplayer <p> myserver
# NOTE: in modern Citizens, there is built-in support for /npc command add -p server myserver
#
# Has the permission "denizen.sendplayer", but is generally meant to be executed as the server.
#
# ---------------------------- END HEADER ----------------------------

sendplayer_command:
    type: command
    debug: false
    name: sendplayer
    description: This is a server (or op) command to send players to a different Bungee server. Useful for '/npc command add sendplayer <&lt>p<&gt> myserver'.
    usage: /sendplayer [player] [server]
    permission: denizen.sendplayer
    script:
    - if <context.args.size> < 2:
        - narrate "<red>/sendplayer [player] [server]"
        - stop
    - define target <server.match_player[<context.args.get[1]>]||null>
    - if <[target]> == null:
        - narrate "<red>Invalid player name specified."
        - stop
    - adjust <[target]> send_to:<context.args.get[2]>
    - narrate "<green>Sent <[target].name> to server '<context.args.get[2]>'."
