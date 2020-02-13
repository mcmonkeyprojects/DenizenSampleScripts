# +--------------------
# |
# | C h a t   P i n g s
# |
# | Alerts when somebody says your name!
# |
# +----------------------
#
# @author mcmonkey
# @date 2019/03/01
# @denizen-build REL-1679
# @script-version 2.1
#
# Installation:
# Just put the script in your scripts folder and reload.
#
# Usage:
# Just say someone's name, everything is automatic.
#
# ---------------------------- END HEADER ----------------------------

chat_pings_world:
    type: world
    debug: false
    events:
        on player chats:
        # Pure-tag pre-check to avoid unneeded processing
        - if <context.message.contains_any[<server.list_online_players.parse[name]>]>:
            - foreach <server.list_online_players> as:player:
                # Prevents the user from pinging himself
                - if <[player].uuid> == <player.uuid>:
                    - stop
                # You might prefer: contains[regex:\b<[player].name>\b]
                # As that will test "word borders" (ie, don't match if the name is in the middle of a word)
                - if <context.message.contains[<[player].name>]>:
                    - narrate targets:<[player]> "<&e><player.name><&b> mentioned you!"
                    - playsound <[player]> sound:block_note_block_bell
                    - flag server pingSender:<player.uuid>
                    - toast targets:<[player]> "<&e><player.name><&b> mentioned you!" frame:goal icon:PingHead

pingHead:
  type: item
  material: player_head[skull_skin=<server.flag[pingSender]>]
