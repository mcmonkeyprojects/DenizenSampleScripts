# +--------------------
# |
# | N P C   C l i c k C o m m a n d
# |
# | A drop-in helper for making NPCs that execute commands.
# |
# +--------------------
#
# @author mcmonkey
# @date 2019/08/16
# @denizen-build REL-1700
# @script-version 1.2
#
# Installation:
# Just put the script in your scripts folder and reload.
#
# Usage:
# Select an NPC and use command "/npccommand"
# You can do:
# /npccommand               - Display help info
# /npccommand off           - Disables command running
# /npccommand set [command] - Sets the NPC to run a specific command
# /npccommand add [command] - Adds a command for the NPC to randomly execute
# You can prefix commands with "player:" to execute as the player, otherwise will execute as the server.
# Use prefix "op:" to execute the command as the player (with operator privileges).
# Add multiple commands to execute at the same time via " - "
# For example: /npccommand set player:summon lightning_bolt - say "shocking!" - player:summon bat
#
# You can use tags. For example: /npccommand add effect give <player.name> speed
#
# Players can right-click the NPC at any time to have a command run.
#
# ---------------------------- END HEADER ----------------------------

npc_command_assignment:
    type: assignment
    debug: false
    actions:
        on assignment:
        - trigger name:click state:true
        on click:
        - foreach "<npc.flag[commands].random.split[ - ].escape_contents>" as:command:
            - if <[command].unescaped.starts_with[player:]>:
                - execute as_player <[command].unescaped.after[player:].parsed>
            - else if <[command].unescaped.starts_with[op:]>:
                - execute as_op <[command].unescaped.after[op:].parsed>
            - else:
                - execute as_server <[command].unescaped.parsed>

npc_command_command:
    type: command
    debug: false
    name: npccommand
    usage: /npccommand
    description: Makes an NPC execute commands!
    permission: script.npccommand
    script:
    - if !<list[set|add|off].contains[<context.args.get[1]||null>]>:
        - narrate "<&c>/npccommand off - Disable command running"
        - narrate "<&c>/npccommand set [command] - Set the command to run"
        - narrate "<&c>/npccommand add [command] - Add a single command (to choose randomly from many)"
        - narrate "<&c>Use 'player<&co>' to run as player, otherwise runs as server. Separate multiple commands to execute at once with ' - '."
        - narrate "<&c>For example: /npccommand set player:summon lightning_bolt - say 'shocking!' - player:summon bat"
        - stop
    - if <player.selected_npc||null> == null:
        - narrate "<&c>Please select an NPC!"
        - stop
    - if <context.args.get[1]> == off:
        - if <npc.script.name||null> != npc_command_assignment:
            - narrate "<&c>That NPC is not a command runner."
            - stop
        - assignment remove
        - flag <npc> commands:!
        - narrate "<&a>Successfully removed command running."
        - stop
    - assignment set script:npc_command_assignment npc:<player.selected_npc>
    - if <context.args.get[1]> == set:
        - flag <player.selected_npc> commands:<context.raw_args.after[set].trim>
        - narrate "<&a>Command set."
    - else if <context.args.get[1]> == add:
        - flag <player.selected_npc> commands:->:<context.raw_args.after[add].trim>
        - narrate "<&a>Command added."
