# +----------------------
# |
# | N P C   C h a t t e r
# |
# | A drop-in helper for making chatting NPCs.
# |
# +----------------------
#
# @author mcmonkey
# @date 2019-03-01
# @denizen-build REL-1700
# @script-version 1.0
#
# Installation:
# Just put the script in your scripts folder and reload.
#
# Usage:
# Select an NPC and use command "/npcchatter"
# You can do:
# /npcchatter               - Display help info
# /npcchatter off           - Disables chatterishness
# /npcchatter set [message] - Sets the NPC to say a specific message
# /npcchatter add [message] - Adds a message for the NPC to randomly say
#
# You can use tags. For example: /npcchatter add Hello <&b><player.name>!
#
# Players can right-click the NPC at any time to see a message.
#
# ---------------------------- END HEADER ----------------------------

npc_chatter_assignment:
    type: assignment
    debug: false
    actions:
        on assignment:
        - trigger name:click state:true
        on click:
        - narrate <npc.flag[message].random.parsed>

npc_chatter_command:
    type: command
    debug: false
    name: npcchatter
    usage: /npcchatter set [message]
    description: Makes an NPC be chatty!
    permission: script.npcchatter
    script:
    - if !<list[set|add|off].contains[<context.args.get[1]||null>]>:
        - narrate "<&[error]>/npcchatter off <&[warning]>- Disable chatterishness"
        - narrate "<&[error]>/npcchatter set [message] <&[warning]>- Set the message"
        - narrate "<&[error]>/npcchatter add [message] <&[warning]>- Add a single message (to choose randomly from many)"
        - stop
    - if <player.selected_npc||null> == null:
        - narrate "<&[error]>Please select an NPC!"
        - stop
    - if <context.args.get[1]> == off:
        - if <npc.script.name||null> != npc_chatter_assignment:
            - narrate "<&[error]>That NPC is not a chatter."
            - stop
        - assignment remove
        - flag <npc> message:!
        - narrate "<&[base]>Successfully removed chatterishness."
        - stop
    - assignment set script:npc_chatter_assignment npc:<player.selected_npc>
    - if <context.args.get[1]> == set:
        - flag <player.selected_npc> message:<context.raw_args.after[set].trim>
        - narrate "<&[base]>Message set."
    - else if <context.args.get[1]> == add:
        - flag <player.selected_npc> message:->:<context.raw_args.after[add].trim>
        - narrate "<&[base]>Message added."
