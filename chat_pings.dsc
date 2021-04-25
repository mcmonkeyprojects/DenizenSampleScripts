# +--------------------
# |
# | C h a t   P i n g s
# |
# | Alerts when somebody says your name!
# |
# +--------------------
#
# @author mcmonkey
# @date 2021-04-25
# @denizen-build REL-1736
# @script-version 3.0
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
        after player chats:
        # You might prefer: contains[regex:\b<[player].name>\b]
        # As that will test "word borders" (ie, don't match if the name is in the middle of a word)
        - foreach <server.online_players.filter_tag[<context.message.contains[<[filter_value].name>]>]> as:player:
            - narrate targets:<[player]> "<&6><player.name><&b> mentioned you!"
            - playsound <[player]> sound:block_note_block_bell
            - toast targets:<[player]> "<&6><player.name><&b> mentioned you!" frame:goal
