# +------------------------
# |
# | P o l y g o n   T o o l
# |
# | Handy tool to make noted polygons.
# |
# +------------------------
#
# @author mcmonkey
# @date 2021/01/22
# @denizen-build REL-1733
# @script-version 1.0
#
# Installation:
# Just put the script in your scripts folder and reload.
#
# Usage:
# Type command "/ptool" to get a polygon selector tool.
# While holding the tool, left click to start a selection and right click to expand the selection.
# Requires permission "polygontool.pool"
#
# Use "/pheight (y)" to expand the Y range of the polygon.
# Requires permission "polygontool.pheight"
#
# Use "/pnote [name]" to note your selected polygon as the name. For example, "/pnote myshop" adds noted polygon 'myshop'.
# Requires permission "polygontool.pnote"
#
# Use "/pshow" to show your current polygon selection.
# Requirers permission "polygontool.pshow"
#
# In a script or "/ex" command, use "<player.has_flag[ptool_selection]>" to check if the player has a selection.
# and "<player.flag[ptool_selection]>" to get the selected polygon.
#
# ---------------------------- END HEADER ----------------------------

polygon_tool_item:
    type: item
    debug: false
    material: blaze_rod
    display name: <gold><bold>Polygon Tool
    enchantments:
    - vanishing_curse:1
    mechanisms:
        hides: ENCHANTS
    lore:
    - <&7>Left click to start a polygon selection.
    - <&7>Right click to add a corner to the polygon.
    - <&7>Use <&b>/pheight <&7>to expand the vertical height.

ptool_command:
    type: command
    debug: false
    name: ptool
    aliases:
    - polygontool
    permission: polygontool.ptool
    description: Gets a polygon tool.
    usage: /ptool
    script:
    - give polygon_tool_item
    - narrate "<green>Here's your polygon tool!"

pheight_command:
    type: command
    debug: false
    name: pheight
    aliases:
    - polygonheight
    permission: polygontool.pheight
    description: Sets the vertical range of your polygon to include the specified Y-height (or your own height).
    usage: /pheight (y)
    script:
    - if !<player.has_flag[ptool_selection]>:
        - narrate "<red>You don't have any polygon selected."
        - stop
    - define y <context.args.get[1]||<player.location.y>>
    - if !<[y].is_decimal>:
        - narrate "<red>Y value must be a numbers."
        - stop
    - flag player ptool_selection:<player.flag[ptool_selection].include_y[<[y]>]>
    - inject polygon_tool_status_task
    - narrate "<green>Polygon heights updated to min <player.flag[ptool_selection].min_y.round_to[2]> max <player.flag[ptool_selection].max_y.round_to[2]>."

pnote_command:
    type: command
    debug: false
    name: pnote
    aliases:
    - polygonnote
    permission: polygontool.pnote
    description: Notes your selected polygon.
    usage: /pnote [name]
    script:
    - if !<player.has_flag[ptool_selection]>:
        - narrate "<red>You don't have any polygon selected."
        - stop
    - if <context.args.size> != 1:
        - narrate "<red>/pnote [name]"
        - stop
    - if <player.flag[ptool_selection].corners.size> < 3:
        - narrate "<red>Your polygon needs more corners."
        - stop
    - note <player.flag[ptool_selection]> as:<context.args.get[1]>
    - inject polygon_tool_status_task
    - narrate "<green>Polygon <aqua><context.args.get[1]><green> noted with <[message]>."

pshow_command:
    type: command
    debug: false
    name: pshow
    aliases:
    - polygonshow
    permission: polygontool.pshow
    description: Shows your selected polygon.
    usage: /pshow
    script:
    - if !<player.has_flag[ptool_selection]>:
        - narrate "<red>You don't have any polygon selected."
        - stop
    - inject polygon_tool_status_task
    - narrate <[message]>

polygon_tool_status_task:
    type: task
    debug: false
    script:
    - define polygon <player.flag[ptool_selection]>
    - define message "<green>Polygon selection: in <[polygon].world.name> from Y <[polygon].min_y.round_to[2]> to <[polygon].max_y.round_to[2]> with <[polygon].corners.size> corners"
    - actionbar <[message]>
    - if <[polygon].corners.size> >= 3:
        # Loose approximation of the polygon's scale to prevent trying to spawn a trillion particles
        - define approx_scale <[polygon].bounding_box.max.sub[<[polygon].bounding_box.min>].vector_length>
        - if <[approx_scale]> < 200:
            - playeffect effect:flame at:<[polygon].shell> offset:0 targets:<player> visibility:32
        - if <[approx_scale]> < 1000:
            - playeffect effect:barrier at:<[polygon].outline> offset:0 targets:<player> visibility:32

polygon_tool_world:
    type: world
    debug: false
    events:
        # Basic usage logic
        on player left clicks block with:polygon_tool_item:
        - if <context.location.material.name||air> == air:
            - stop
        - flag player ptool_selection:<list[<context.location>].to_polygon.include_y[<context.location.y.add[2]>]>
        - inject polygon_tool_status_task
        - determine cancelled
        on player right clicks block with:polygon_tool_item:
        - if <context.location.material.name||air> == air:
            - stop
        - if <player.has_flag[ptool_selection]>:
            - if <player.flag[ptool_selection].world.name> != <context.location.world.name>:
                - narrate "<&c>You must restart your selection by left clicking."
                - stop
            - flag player ptool_selection:<player.flag[ptool_selection].with_corner[<context.location>].include_y[<context.location.y>]>
        - else:
            - flag player ptool_selection:<list[<context.location>].to_polygon.include_y[<context.location.y.add[2]>]>
        - inject polygon_tool_status_task
        - determine cancelled
        # Prevent misuse
        after player drops polygon_tool_item:
        - remove <context.entity>
        on player clicks in inventory with:polygon_tool_item:
        - inject polygon_tool_world.abuse_prevention_click
        on player drags polygon_tool_item in inventory:
        - inject polygon_tool_world.abuse_prevention_click
    abuse_prevention_click:
        - if <context.inventory.inventory_type> == player:
            - stop
        - if <context.inventory.inventory_type> == crafting:
            - if <context.raw_slot||<context.raw_slots.numerical.first>> >= 6:
                - stop
        - determine passively cancelled
        - inventory update
