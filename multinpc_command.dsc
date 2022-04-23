# +----------------------------
# |
# | M u l t i N P C   C o m m a n d
# |
# | Tool to allow NPC command execution on multiple NPCs simultaneously.
# |
# +----------------------------
#
# @author mcmonkey
# @date 2021/11/06
# @updated 2022/03/21
# @denizen-build REL-1762
# @script-version 1.1
#
# Installation:
# Just put the script in your scripts folder and reload.
#
# Usage:
# Type command "/multinpc" to get usage info in-game.
#
# You can select NPCs via "/multinpc select" and deselect them with "/multinpc deselect"
# You can also use "/multinpc tool" to get an item that can be used to quickly select/deselect NPCs by clickng them.
#
# You can view your current selection of NPCs via "/multinpc show"
#
# You can save/load NPC selection sets via "/multinpc save [name]" and "/multinpc load [name]"
# Note that saved sets are global - meaning, they are automatically shared with other staff.
#
# You can then execute any common "/npc" commands by simplying using them through "/multinpc"
# For example, to use "npc sneak" on all your selected NPCs, use "/multinpc sneak"
# You can also use the /Trait and /Waypoints command, for example "/trait sentinel" is ran like "/multinpc trait sentinel"
# If you have Sentinel, you can use Sentinel commands, for example "/multinpc sentinel damage 5"
#
# By default, runs in 'quiet' mode - meaning, it will try to shorten and conglomerate message output.
# If something has gone wrong, you can use "/multinpc loud" to enable 'loud' mode - meaning, it will show ALL output.
# Use "/multinpc quiet" to go back into quiet mode.
#
# ---------------------------- END HEADER ----------------------------


multinpc_command:
    type: command
    debug: false
    name: multinpc
    description: Executes commands on multiple NPCs simultaneously.
    usage: /multinpc [command]
    permission: dscript.multinpc
    tab complete:
    - define result <list>
    - if <context.raw_args.trim> == <empty> || ( <context.args.size> == 1 && !<context.raw_args.ends_with[<&sp>]> ):
        - if <plugin[sentinel].exists> && <element[sentinel].starts_with[<context.args.first||>]>:
            - define result:->:sentinel
        - define result:|:select|deselect|tool|show|save|load|quiet|loud
    - else:
        - choose <context.args.first>:
            - case select sel deselect desel unselect unsel:
                - define result <server.npcs.parse[id].include[all]>
            - case save load:
                - define result <server.flag[multinpcs_selections_saved].keys.parse[unescaped]||<list>>
            - case sentinel:
                - if <plugin[Sentinel].exists>:
                    - define initial <player.tab_completions[<context.raw_args>]>
            - case trait:
                - define initial <player.tab_completions[<context.raw_args>]>
    - if !<[initial].exists>:
        - define initial "<player.tab_completions[npc <context.raw_args>]>"
    - determine <[result].filter[starts_with[<context.args.last||>]].include[<[initial]>]>
    script:
    - if <context.args.is_empty> || <context.args.first> == help:
        - narrate "<&[error]>/multiNPC <&[warning]>- lets you run commands over multiple NPCs simultaneously."
        - narrate "<&[error]>/multiNPC select (id/all) <&[warning]>- adds your nearest NPC (or given ID # or 'all') to your selection set."
        - narrate "<&[error]>/multiNPC deselect (id/all) <&[warning]>- removes your nearest NPC (or given ID # or 'all') from your selection set."
        - narrate "<&[error]>/multiNPC tool <&[warning]>- gives you a tool to quickly select/deselect NPCs."
        - narrate "<&[error]>/multiNPC show <&[warning]>- shows your current NPC selections."
        - narrate "<&[error]>/multiNPC save [name] <&[warning]>- saves your current NPC selection group."
        - narrate "<&[error]>/multiNPC load [name] <&[warning]>- loads an NPC selection group that was previously saved."
        - narrate "<&[error]>/multiNPC quiet/loud <&[warning]>- 'quiet' silences output, 'loud' spams you with all output."
        - stop
    # Cleanup any removed NPCs to be safe
    - foreach <player.flag[multinpc_selection]||<list>> as:npc:
        - if <npc[<[npc]>]||null> == null:
            - flag player multinpc_selection:<-:<[npc]>
    - choose <context.args.first>:
        - case quiet:
            - flag player multinpc_loud:!
            - narrate "<&[base]>MultiNPC set to quiet mode."
        - case loud:
            - flag player multinpc_loud
            - narrate "<&[base]>MultiNPC set to loud mode."
        - case select sel:
            - if <context.args.get[2].is_integer||false>:
                - define target <npc[<context.args.get[2]>].if_null[null]>
                - if <[target]> == null:
                    - narrate "<&[error]>That NPC ID appears to be invalid."
                    - stop
            - else if <context.args.get[2]||null> == all:
                - flag player multinpc_selection:<server.npcs>
                - narrate "<&[base]>Selected all <&[emphasis]><server.npcs.size><&[base]> NPC(s)."
                - stop
            - else:
                - define target <player.location.find_npcs_within[50].first.if_null[null]>
                - if <[target]> == null:
                    - narrate "<&[error]>No nearby NPCs."
                    - stop
            - if <player.flag[multinpc_selection].contains[<[target]>]||false>:
                - narrate "<&[error]>That NPC is already selected."
                - stop
            - flag player multinpc_selection:->:<[target]>
            - narrate "<&[base]>Added NPC <&[emphasis]><[target].id> <&[base]>(<&[emphasis]><[target].name><&[base]>) to your selection. Now at <&[emphasis]><player.flag[multinpc_selection].size><&[base]> selected NPC(s)."
        - case deselect desel unselect unsel:
            - if <context.args.get[2].is_integer||false>:
                - define target <npc[<context.args.get[2]>].if_null[null]>
                - if <[target]> == null:
                    - narrate "<&[error]>That NPC ID appears to be invalid."
                    - stop
            - else if <context.args.get[2]||null> == all:
                - narrate "<&[base]>Deselected all <&[emphasis]><player.flag[multinpc_selection].size||0><&[base]> NPC(s)."
                - flag player multinpc_selection:!
                - stop
            - else:
                - define target <player.location.find_npcs_within[50].first.if_null[null]>
                - if <[target]> == null:
                    - narrate "<&[error]>No nearby NPCs."
                    - stop
            - if !<player.flag[multinpc_selection].contains[<[target]>]||false>:
                - narrate "<&[error]>That NPC already isn't selected."
                - stop
            - flag player multinpc_selection:<-:<[target]>
            - narrate "<&[base]>Removed NPC <&[emphasis]><[target].id> <&[base]>(<&[emphasis]><[target].name><&[base]>) from your selection. Now at <&[emphasis]><player.flag[multinpc_selection].size||0><&[base]> selected NPC(s)."
        - case tool wand:
            - if <player.inventory.contains_item[multinpc_wand_item]>:
                - narrate "<&[error]>You already have the multi-NPC selector wand in your inventory."
                - stop
            - give multinpc_wand_item
            - narrate "<&[base]>Here's your selector tool. Right click an NPC to add it to your selection, left click or shift-right click to remove an NPC."
        - case show:
            - if <player.flag[multinpc_selection].is_empty||true>:
                - narrate "<&[base]>You don't have any NPCs currently selected."
                - stop
            - define formatted "<player.flag[multinpc_selection].parse_tag[<&[emphasis]><[parse_value].id> <&[base]>(<&[emphasis]><[parse_value].name><&[base]>)].formatted>"
            - narrate "<&[base]>You have <&[emphasis]><player.flag[multinpc_selection].size><&[base]> NPCs selected: <[formatted]>"
        - case save:
            - if <context.args.size> == 1:
                - narrate "<&[error]>/multiNPC save [name] <&[warning]>- saves your current NPC selection group."
                - narrate "<&[warning]>Note that this group name is shared globally, so other staff can use it too."
                - stop
            - if <player.flag[multinpc_selection].is_empty||true>:
                - narrate "<&[base]>You don't have any NPCs currently selected."
                - stop
            - define savename <context.args.get[2].escaped>
            - if <server.has_flag[multinpcs_selections_saved.<[savename]>]>:
                - narrate "<&[warning]>Overwriting pre-existing save name <&[emphasis]><[savename].unescaped>"
            - flag server multinpcs_selections_saved.<[savename]>:<player.flag[multinpc_selection]>
            - narrate "<&[base]>Saved your selection as <&[emphasis]><[savename].unescaped>"
        - case load:
            - if <context.args.size> == 1:
                - narrate "<&[error]>/multiNPC load [name] <&[warning]>- loads an NPC selection group that was previously saved."
                - stop
            - define savename <context.args.get[2].escaped>
            - if !<server.has_flag[multinpcs_selections_saved.<[savename]>]>:
                - narrate "<&[warning]>That save name does not exist."
                - stop
            - flag player multinpc_selection:<server.flag[multinpcs_selections_saved.<[savename]>].filter_tag[<npc[<[filter_value]>].exists>]>
            - narrate "<&[base]>Loaded that selection - contains <&[emphasis]><player.flag[multinpc_selection].size||0><&[base]> NPCs."
        - default:
            - if <player.flag[multinpc_selection].is_empty||true>:
                - narrate "<&[base]>You don't have any NPCs currently selected."
                - stop
            - define all_outputs <list>
            - define cmd "npc <context.raw_args>"
            - if <context.args.first> == trait || <context.args.first> == waypoints || ( <context.args.first> == sentinel && <plugin[Sentinel].exists> ):
                - define cmd <context.raw_args>
            - if <player.has_flag[multinpc_loud]>:
                - foreach <player.flag[multinpc_selection]> as:npc:
                    - execute as_player "<[cmd]> --id <[npc].id>"
            - else:
                - flag player multinpc_output_record:!
                - foreach <player.flag[multinpc_selection]> as:npc:
                    - flag player multinpc_record:<[npc]> expire:1t
                    - execute as_player "<[cmd]> --id <[npc].id>"
                - flag player multinpc_record:!
                - define output <player.flag[multinpc_output_record].deduplicate>
                - flag player multinpc_output_record:!
                - if <[output].size> > 5:
                    - narrate "<&[base]>Received <&[emphasis]><[output].size><&[base]> unique outputs. First 3:<n><&[base]><[output].get[1].to[3].separated_by[<n><&[base]>]>"
                - else if <[output].size> == 1:
                    - narrate <&[base]><[output].first>
                - else:
                    - narrate "<&[base]>Received <&[emphasis]><[output].size><&[base]> unique output(s):<n><&[base]><[output].separated_by[<n><&[base]>]>"

multinpc_wand_item:
    type: item
    debug: false
    material: blaze_rod
    display name: <&[item]>MultiNPC Selector Wand
    lore:
    - <&[lore]>Right click to add an NPC to your selection.
    - <&[lore]>Left click or shift-right click to remove an NPC.
    enchantments:
    - luck:1
    mechanisms:
        hides: all

multinpc_world:
    type: world
    debug: false
    events:
        after player right clicks npc with:multinpc_wand_item:
        - ratelimit <player> 1t
        - if <player.is_sneaking>:
            - if !<player.flag[multinpc_selection].contains[<npc>]||false>:
                - actionbar "<&[error]>That NPC already isn't selected."
            - else:
                - flag <player> multinpc_selection:<-:<npc>
                - actionbar "<&[base]>NPC <&[emphasis]><npc.id><&[base]> removed from your selection."
        - else:
            - if <player.flag[multinpc_selection].contains[<npc>]||false>:
                - actionbar "<&[error]>That NPC is already selected."
            - else:
                - flag <player> multinpc_selection:->:<npc>
                - actionbar "<&[base]>NPC <&[emphasis]><npc.id><&[base]> added to your selection."
        after player damages npc with:multinpc_wand_item ignorecancelled:true:
        - ratelimit <player> 1t
        - if !<player.flag[multinpc_selection].contains[<npc>]||false>:
            - actionbar "<&[error]>That NPC already isn't selected."
        - else:
            - flag <player> multinpc_selection:<-:<npc>
            - actionbar "<&[base]>NPC <&[emphasis]><npc.id><&[base]> removed from your selection."
        after player drops multinpc_wand_item:
        - remove <context.entity>
        on player receives message flagged:multinpc_record:
        - flag player multinpc_output_record:->:<context.message.strip_color.replace_text[<player.flag[multinpc_record].name.strip_color>].with[<&[emphasis]>(NAME)<&[base]>].replace_text[<player.flag[multinpc_record].id>].with[<&[emphasis]>(ID)<&[base]>]>
        - determine cancelled
