# +-------------------
# |
# | NPC Skin Save/Load
# |
# | A drop-in helper for saving/loading skins for reuse.
# |
# +----------------------
#
# @author mcmonkey
# @date 2019/08/26
# @denizen-build REL-1700
# @script-version 1.0
#
# Installation:
# Just put the script in your scripts folder and reload.
#
# Usage:
# Select an NPC and use command "/saveskin" or "/loadskin"
# You can do:
# /saveskin [name]       - Saves the NPC's skin to the name you specify.
# /loadskin [name]       - Gives the NPC the skin saved for the name you used.
#
# Uses permission "denizen.saveskin"
#
# ---------------------------- END HEADER ----------------------------

npc_skin_save_command:
    type: command
    debug: false
    name: saveskin
    usage: /saveskin [name]
    description: Saves ye skin
    permission: denizen.saveskin
    script:
    - inject npc_saveskin_command_validate
    - flag server npc_skins.<context.args.get[1].escaped>:<player.selected_npc.skin_blob>;<player.selected_npc.name>
    - narrate "<green>Skin saved."

npc_skin_load_command:
    type: command
    debug: false
    name: loadskin
    usage: /loadskin [name]
    description: Loads ye skin
    permission: denizen.saveskin
    script:
    - inject npc_saveskin_command_validate
    - if !<server.has_flag[npc_skins.<context.args.get[1].escaped>]>:
      - narrate "<red>No skin found for the name specified."
      - stop
    - adjust <player.selected_npc> skin_blob:<server.flag[npc_skins.<context.args.get[1].escaped>]>
    - narrate "<green>Skin loaded!"

npc_saveskin_command_validate:
    type: task
    debug: false
    script:
    - if <context.args.size> == 0:
      - narrate "<red>Must specify a skin name."
      - stop
    - if <player.selected_npc||null> == null:
      - narrate "<red>Must select an NPC!"
      - stop
