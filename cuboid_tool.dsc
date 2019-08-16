# +----------------------
# |
# | C u b o i d   T o o l
# |
# | Handy tool to make notable cuboids.
# |
# +----------------------
#
# @author mcmonkey
# @date 2019/07/25
# @denizen-build REL-1679
# @script-version 1.0
#
# Installation:
# Just put the script in your scripts folder and reload.
#
# Usage:
# Type command "/ctool" to get a cuboid selector tool.
# While holding the tool, left click to start a selection and right click to expand the selection.
# Requires permission "cuboidtool.ctool"
#
# Use "/cnote [name]" to note your selected cuboid as the name. For example, "/cnote myshop" adds notable cuboid 'myshop'.
# Requires permission "cuboidtool.cnote"
#
# Use "/cshow" to show your current cuboid selection.
# Requirers permission "cuboidtool.cshow"
#
# In a script or "/ex" command, use "<player.has_flag[ctool_selection]>" to check if the player has a selection
# and "<player.flag[ctool_selection].as_cuboid>" to get the selected cuboid.
#
# ---------------------------- END HEADER ----------------------------

cuboid_tool_item:
    type: item
    debug: false
    material: blaze_rod
    display name: <gold><bold>Cuboid Tool
    enchantments:
    - vanishing_curse:1
    mechanisms:
        flags: HIDE_ENCHANTS
    lore:
    - Left click to start a selection.
    - Right click to expand the selection.

ctool_command:
    type: command
    debug: false
    name: ctool
    aliases:
    - cuboidtool
    permission: cuboidtool.ctool
    description: Gets a cuboid tool.
    usage: /ctool
    script:
    - give cuboid_tool_item
    - narrate "<green>Here's your cuboid tool!"

cnote_command:
    type: command
    debug: false
    name: cnote
    aliases:
    - cuboidnote
    permission: cuboidtool.cnote
    description: Notes your selected cuboid.
    usage: /cnote [name]
    script:
    - if !<player.has_flag[ctool_selection]>:
        - narrate "<red>You don't have any cuboid selected."
        - stop
    - if <context.args.size> != 1:
        - narrate "/cnote [name]"
        - stop
    - note <player.flag[ctool_selection]> as:<context.args.get[1]>
    - inject cuboid_tool_status_task
    - narrate "<green>Cuboid <aqua><context.args.get[1]><green> noted with <[message]>."

cshow_command:
    type: command
    debug: false
    name: cshow
    aliases:
    - cuboidshow
    permission: cuboidtool.cshow
    description: Shows your selected cuboid.
    usage: /cshow
    script:
    - if !<player.has_flag[ctool_selection]>:
        - narrate "<red>You don't have any cuboid selected."
        - stop
    - inject cuboid_tool_status_task
    - narrate <[message]>

cuboid_tool_status_task:
    type: task
    debug: false
    script:
    - define cuboid <player.flag[ctool_selection]>
    - define min "<aqua><[cuboid].min.simple.replace[,].with[<gray>, <aqua>]><green>"
    - define max "<aqua><[cuboid].max.simple.replace[,].with[<gray>, <aqua>]><green>"
    - define size "<aqua><[cuboid].size.simple.replace[,].with[<gray>, <aqua>]><green>"
    - define volume <aqua><[cuboid].volume><green>
    - define message "<green>Cuboid selection: from <[min]> to <[max]> (size <[size]>, volume <[volume]>)"
    - actionbar <[message]>
    - playeffect effect:flame at:<[cuboid].shell> offset:0 targets:<player>
    - playeffect effect:barrier at:<[cuboid].outline> offset:0 targets:<player>

cuboid_tool_world:
    type: world
    debug: false
    events:
        # Basic usage logic
        on player left clicks block with cuboid_tool_item:
        - if <context.location.material.name||air> == air:
            - stop
        - flag player ctool_selection:cu@<context.location>|<context.location>
        - inject cuboid_tool_status_task
        - determine cancelled
        on player right clicks block with cuboid_tool_item:
        - if <context.location.material.name||air> == air:
            - stop
        - if <player.has_flag[ctool_selection]>:
            - flag player ctool_selection:<player.flag[ctool_selection].as_cuboid.include[<context.location>]>
        - else:
            - flag player ctool_selection:cu@<context.location>|<context.location>
        - inject cuboid_tool_status_task
        - determine cancelled
        # Prevent misuse
        on player drops cuboid_tool_item:
        - remove <context.entity>
        on player clicks in inventory with cuboid_tool_item:
        - inject locally abuse_prevention_click
        on player drags in inventory with cuboid_tool_item:
        - inject locally abuse_prevention_click
    abuse_prevention_click:
        - if <context.inventory.inventory_type> == player:
            - stop
        - if <context.inventory.inventory_type> == crafting:
            - if <context.raw_slot||<context.raw_slots.numerical.first>> >= 6:
                - stop
        - determine passively cancelled
        - inventory update
