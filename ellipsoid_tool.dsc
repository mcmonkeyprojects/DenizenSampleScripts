# +----------------------------
# |
# | E l l i p s o i d   T o o l
# |
# | Handy tool to make noted ellipsoids.
# |
# +----------------------------
#
# @author mcmonkey
# @date 2020/06/18
# @denizen-build REL-1733
# @script-version 1.0
#
# Installation:
# Just put the script in your scripts folder and reload.
#
# Usage:
# Type command "/elliptool" to get an ellipsoid selector tool.
# While holding the tool, left click to start a selection and right click to expand the selection.
# Requires permission "ellipsoidtool.elliptool"
#
# Use "/ellipnote [name]" to note your selected ellipsoid as the name. For example, "/ellipnote myshop" adds noted ellipsoid 'myshop'.
# Requires permission "ellipsoidtool.ellipnote"
#
# Use "/ellipshow" to show your current ellipsoid selection.
# Requirers permission "ellipsoidtool.ellipshow"
#
# In a script or "/ex" command, use "<player.has_flag[elliptool_selection]>" to check if the player has a selection.
# and "<ellipsoid[<player.flag[elliptool_selection]>]>" to get the selected ellipsoid.
#
# ---------------------------- END HEADER ----------------------------

ellipsoid_tool_item:
    type: item
    debug: false
    material: blaze_rod
    display name: <gold><bold>Ellipsoid Tool
    enchantments:
    - vanishing_curse:1
    mechanisms:
        flags: HIDE_ENCHANTS
    lore:
    - Left click to start a selection.
    - Right click to expand the selection.

elliptool_command:
    type: command
    debug: false
    name: elliptool
    aliases:
    - ellipsoidtool
    - etool
    permission: ellipsoidtool.elliptool
    description: Gets an ellipsoid tool.
    usage: /elliptool
    script:
    - give ellipsoid_tool_item
    - narrate "<green>Here's your ellipsoid tool!"

ellipnote_command:
    type: command
    debug: false
    name: ellipnote
    aliases:
    - ellipsoidnote
    - enote
    permission: ellipsoidtool.ellipnote
    description: Notes your selected ellipsoid.
    usage: /ellipnote [name]
    script:
    - if !<player.has_flag[elliptool_selection]>:
        - narrate "<red>You don't have any ellipsoid selected."
        - stop
    - if <context.args.size> != 1:
        - narrate "/ellipnote [name]"
        - stop
    - note <player.flag[elliptool_selection]> as:<context.args.get[1]>
    - inject ellipsoid_tool_status_task
    - narrate "<green>Ellipsoid <aqua><context.args.get[1]><green> noted with <[message]>."

ellipshow_command:
    type: command
    debug: false
    name: ellipshow
    aliases:
    - ellipsoidshow
    - eshow
    permission: ellipsoidtool.ellipshow
    description: Shows your selected ellipsoid.
    usage: /ellipshow
    script:
    - if !<player.has_flag[elliptool_selection]>:
        - narrate "<red>You don't have any ellipsoid selected."
        - stop
    - inject ellipsoid_tool_status_task
    - narrate <[message]>

ellipsoid_tool_status_task:
    type: task
    debug: false
    script:
    - define ellipsoid <ellipsoid[<player.flag[elliptool_selection]>]>
    - define loc "<aqua><[ellipsoid].location.block.xyz.replace_text[.0].replace_text[,].with[<gray>, <aqua>]><green>"
    - define size_text "<aqua><[ellipsoid].size.block.xyz.replace_text[.0].replace_text[,].with[<gray>, <aqua>]><green>"
    - define message "<green>Ellipsoid selection: at <[loc]>, size <[size_text]>"
    - actionbar <[message]>
    - playeffect effect:flame at:<[ellipsoid].shell> offset:0 targets:<player>
    - define size <[ellipsoid].size>
    - define y_subellipse <[ellipsoid].with_size[<[size].with_y[0.5]>]>
    - define y_shrunkellipse <[ellipsoid].with_size[<[size].x.sub[1]>,1,<[size].z.sub[1]>]>
    - playeffect effect:barrier at:<[y_subellipse].shell.exclude[<[y_shrunkellipse].shell>]> offset:0 targets:<player>
    - define x_subellipse <[ellipsoid].with_size[<[size].with_x[0.5]>]>
    - define x_shrunkellipse <[ellipsoid].with_size[1,<[size].y.sub[1]>,<[size].z.sub[1]>]>
    - playeffect effect:barrier at:<[x_subellipse].shell.exclude[<[x_shrunkellipse].shell>]> offset:0 targets:<player>
    - define z_subellipse <[ellipsoid].with_size[<[size].with_z[0.5]>]>
    - define z_shrunkellipse <[ellipsoid].with_size[<[size].x.sub[1]>,<[size].y.sub[1]>,1]>
    - playeffect effect:barrier at:<[z_subellipse].shell.exclude[<[z_shrunkellipse].shell>]> offset:0 targets:<player>

ellipsoid_tool_world:
    type: world
    debug: false
    events:
        # Basic usage logic
        on player left clicks block with:ellipsoid_tool_item:
        - if <context.location.material.name||air> == air:
            - stop
        - flag player elliptool_selection:<ellipsoid[<context.location.xyz>,<context.location.world>,1,1,1]>
        - inject ellipsoid_tool_status_task
        - determine cancelled
        on player right clicks block with:ellipsoid_tool_item:
        - if <context.location.material.name||air> == air:
            - stop
        - if <player.has_flag[elliptool_selection]>:
            - flag player elliptool_selection:<ellipsoid[<player.flag[elliptool_selection]>].include[<context.location>]>
        - else:
            - flag player elliptool_selection:<ellipsoid[<context.location.xyz>,<context.location.world>,1,1,1]>
        - inject ellipsoid_tool_status_task
        - determine cancelled
        # Prevent misuse
        on player drops ellipsoid_tool_item:
        - remove <context.entity>
        on player clicks in inventory with:ellipsoid_tool_item:
        - inject ellipsoid_tool_world.abuse_prevention_click
        on player drags ellipsoid_tool_item in inventory:
        - inject ellipsoid_tool_world.abuse_prevention_click
    abuse_prevention_click:
        - if <context.inventory.inventory_type> == player:
            - stop
        - if <context.inventory.inventory_type> == crafting:
            - if <context.raw_slot||<context.raw_slots.numerical.first>> >= 6:
                - stop
        - determine passively cancelled
        - inventory update
