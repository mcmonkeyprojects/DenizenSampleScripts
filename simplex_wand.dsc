# +----------------------
# |
# | S i m pl e x  N o i s e  R e p l a c e r  W a n d
# |
# | Handy tool to make simplex noise gradient patterns.
# |
# +----------------------
#
# @author mcmonkey
# @date 2022/04/01
# @denizen-build REL-1765
# @script-version 1.1
#
# Installation:
# Just put the script in your scripts folder and reload.
#
# Usage:
# Command syntax: /simplexreplacewand [block-matcher] [brush-size] [scale] [type_1] (type_2...)
# For example: /simplexreplacewand dirt|*stone 5 4 stone cobblestone dirt dirt dirt grass_block
# Or, here's one that turns the ground to rainbows: /simplexreplacewand grass_block|*stone|dirt 10 8 red_wool orange_wool yellow_wool green_wool cyan_wool blue_wool purple_wool
# Requires permission "dscript.simplexreplacewand"
#
# While holding the wand item and facing some blocks, right click to apply the gradient pattern.
#
# BE CAREFUL! This is an admin tool that replaces blocks without the ability to undo.
#
# ---------------------------- END HEADER ----------------------------

simplexreplacewand_command:
    type: command
    debug: false
    name: simplexreplacewand
    usage: /simplexreplacewand [block-matcher] [scale] [type_1] (type_2...)
    description: Generates a Simplex Noise replacer wand.
    permission: dscript.simplexreplacewand
    tab completions:
        2: 1|2|3|4|5|6|7|8|9
        3: 1|2|3|4|5|6|7|8|9
        default: <server.material_types.parse[name]>
    script:
    - if <context.args.size> < 4:
        - narrate "<&[error]>/simplexreplacewand [block-matcher] [brush-size] [scale] [type_1] (type_2...)"
        - narrate "<&[base]>For example: <&[warning]> /simplexreplacewand dirt|*stone 5 4 stone cobblestone dirt dirt dirt grass_block"
        - stop
    - define lore <list>
    - define applies_to <server.material_types.filter[advanced_matches[<context.args.first>]]>
    - define "lore:->:<&[base]>Applies to: <&[emphasis]><context.args.first>"
    - if <[applies_to].is_empty>:
        - narrate "<&[error]>Block input matcher has no valid inputs."
        - stop
    - define brush_size <context.args.get[2]>
    - define "lore:->:<&[base]>Brush Size: <&[emphasis]><[brush_size]>"
    - if !<[brush_size].is_integer> || <[brush_size]> < 1 || <[brush_size]> > 50:
        - narrate "<&[error]>Brush size is invalid. Should be an integer number like 1 or 5."
    - define scale <context.args.get[3]>
    - define "lore:->:<&[base]>Scale: <&[emphasis]><[scale]>"
    - if !<[scale].is_decimal> || <[scale]> < 0.1 || <[scale]> > 100:
        - narrate "<&[error]>Scale is invalid. Should be a decimal number like 1 or 5."
        - stop
    - define replace_types <list>
    - foreach <context.args.get[4].to[last]> as:replace_entry:
        - if !<[replace_entry].as_material.exists>:
            - narrate "<&[error]>Invalid pattern material '<[replace_entry]>'"
            - stop
        - define replace_types:->:<[replace_entry].as_material.name>
    - define "lore:->:<&[base]>Pattern: <&[emphasis]><[replace_types].deduplicate.space_separated>"
    - define wand <item[simplereplacewand_item].with_single[lore=<[lore]>].with_flag[scale:<[scale]>].with_flag[brush_size:<[brush_size]>].with_flag[applies_to:<context.args.first>].with_flag[replace_types:<[replace_types]>]>
    - give <[wand]>
    - narrate "<&[base]>Here you go! A <element[<&[emphasis]>Gradient Wand].on_hover[<[wand]>].type[show_item]>"

simplereplacewand_item:
    type: item
    debug: false
    material: golden_sword
    display name: <&[emphasis]>Gradient Wand
    enchantments:
    - luck_of_the_sea:1
    mechanisms:
        hides: all

simplexreplacewand_world:
    type: world
    debug: false
    events:
        on player right clicks block with:simplereplacewand_item:
        - define center <player.cursor_on[100]>
        - if <[center].material.name||air> == air:
            - stop
        - define scale <context.item.flag[scale]>
        - define replacements <context.item.flag[replace_types]>
        - define replacelen <[replacements].size>
        - foreach <[center].find_blocks[<context.item.flag[applies_to]>].within[<context.item.flag[brush_size]>]> as:block:
            - define old_type <[block].material>
            - define new_type <material[<[replacements].get[<[block].div[<[scale]>].simplex_3d.add[1].div[2].mul[<[replacelen]>].add[1].round_down>]>]>
            - modifyblock <[block]> <[new_type].with_map[<[old_type].property_map.filter_tag[<[old_type].supports[<[filter_key]>]>]>]>
