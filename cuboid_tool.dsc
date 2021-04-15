# +----------------------
# |
# | C u b o i d   T o o l
# |
# | Handy tool to make noted cuboids.
# |
# +----------------------
#
# @author mcmonkey
# @date 2020/06/01
# @denizen-build REL-1733
# @script-version 1.4
#
# Installation:
# Just put the script in your scripts folder and reload.
#
# Usage:
# Type command "/ctool" to get a cuboid selector tool.
# While holding the tool, left click to start a selection and right click to expand the selection.
# Requires permission "cuboidtool.ctool"
#
# Use "/cnote [name]" to note your selected cuboid as the name. For example, "/cnote myshop" adds noted cuboid 'myshop'.
# Requires permission "cuboidtool.cnote"
#
# Use "/cshow" to show your current cuboid selection.
# Requirers permission "cuboidtool.cshow"
#
# In a script or "/ex" command, use "<player.has_flag[ctool_selection]>" to check if the player has a selection.
# and "<player.flag[ctool_selection]>" to get the selected cuboid.
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
        hides: ENCHANTS
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
    - define min "<aqua><[cuboid].min.xyz.replace[,].with[<gray>, <aqua>]><green>"
    - define max "<aqua><[cuboid].max.xyz.replace[,].with[<gray>, <aqua>]><green>"
    - define size "<aqua><[cuboid].size.xyz.replace[,].with[<gray>, <aqua>]><green>"
    - define volume <aqua><[cuboid].volume><green>
    - define message "<green>Cuboid selection: from <[min]> to <[max]> (size <[size]>, volume <[volume]>)"
    - actionbar <[message]>
    # Loose approximation of the cuboid's scale to prevent trying to spawn a trillion particles
    - define approx_scale <[cuboid].max.sub[<[cuboid].min>].vector_length>
    - if <[approx_scale]> < 200:
        - playeffect effect:flame at:<[cuboid].shell.parse[center]> offset:0 targets:<player> visibility:32
    - if <[approx_scale]> < 1000:
        - playeffect effect:barrier at:<[cuboid].outline.parse[center]> offset:0 targets:<player> visibility:32

cuboid_tool_world:
    type: world
    debug: false
    events:
        # Basic usage logic
        on player left clicks block with:cuboid_tool_item:
        - if <context.location.material.name||air> == air:
            - stop
        - flag player ctool_selection:<context.location.to_cuboid[<context.location>]>
        - inject cuboid_tool_status_task
        - determine cancelled
        on player right clicks block with:cuboid_tool_item:
        - if <context.location.material.name||air> == air:
            - stop
        - if <player.has_flag[ctool_selection]>:
            - if <player.flag[ctool_selection].min.world.name> != <context.location.world.name>:
                - narrate "<&c>You must restart your selection by left clicking."
                - stop
            - flag player ctool_selection:<player.flag[ctool_selection].include[<context.location>]>
        - else:
            - flag player ctool_selection:<context.location.to_cuboid[<context.location>]>
        - inject cuboid_tool_status_task
        - determine cancelled
        # Prevent misuse
        on player drops cuboid_tool_item:
        - remove <context.entity>
        on player clicks in inventory with:cuboid_tool_item:
        - inject cuboid_tool_world.abuse_prevention_click
        on player drags cuboid_tool_item in inventory:
        - inject cuboid_tool_world.abuse_prevention_click
    abuse_prevention_click:
        - if <context.inventory.inventory_type> == player:
            - stop
        - if <context.inventory.inventory_type> == crafting:
            - if <context.raw_slot||<context.raw_slots.numerical.first>> >= 6:
                - stop
        - determine passively cancelled
        - inventory update
