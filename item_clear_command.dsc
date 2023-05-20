# +------------------
# |
# | ItemClear Command
# |
# | A drop-in command script to clear out dropped items around you.
# |
# +------------------
#
# @author mcmonkey
# @date 2022-09-19
# @denizen-build REL-1777
# @script-version 1.0
#
# ItemClear is a simple command to clear out dropped items near you. This is a very common staff utility.
# This also stores a temporary copy of items deleted, so if you accidentally delete something important you can get it back.
# Temporary copies last 30 minutes before expiration, and can be accessed via clickable output from the command.
# There is a maximum limit of 540 stacks (10 invs) saved at a time (with a 108 stack (2 invs) leeway range).
# These times and limits can be configured via the config below this header.
#
# Installation:
# Just put the script in your scripts folder and reload.
#
# Usage:
# /itemclear (range)
# Range defaults to 100 if unspecified.
#
# For example: /itemclear
# Or: /itemclear 50
#
# Permission: dscript.itemclear
#
# ---------------------------- END HEADER ----------------------------

itemclear_config:
    type: data
    # Maximum item history storage. Set to 1d to be effectively-unlimited. Default: 10.
    expire_duration: 30m
    # Maximum inventories to save. Set to 99999 to be unlimited. Default: 10.
    max_invs_saved: 10
    # Default range when a player doesn't type one in. Set to 99999 to be unlimited. Default: 10.
    range: 100

# ---------------------------- END CONFIG ----------------------------

itemclear_command:
    type: command
    debug: false
    name: itemclear
    usage: /itemclear (range)
    description: Clears out dropped items near you. Optionally specify a range - defaults to 100.
    permission: dscript.itemclear
    aliases:
    - clearitems
    - cleardroppeditem
    - droppeditemclear
    script:
    - define def_range <script[itemclear_config].parsed_key[range]>
    - define range <context.args.first.if_null[<[def_range]>]>
    - if <context.args.size> > 1 || !<[range].is_decimal>:
        - narrate "<&[error]>/itemclear (range) <&[warning]>- range defaults to <[def_range]> if unspecified."
        - stop
    - define items_in_range <player.location.find_entities[dropped_item].within[<[range]>]>
    - if <[items_in_range].is_empty>:
        - narrate "<&[error]>No dropped items to clear."
        - stop
    - define itemdata <[items_in_range].parse[item]>
    - remove <[items_in_range]>
    - define gen_id <util.random_uuid>
    - define sets <[itemdata].sub_lists[54]>
    - define expire <script[itemclear_config].parsed_key[expire_duration]>
    - define limit <script[itemclear_config].parsed_key[max_invs_saved]>
    - if <[sets].size> > <[limit].add[2]>:
        - narrate "<&[warning]>Too many items - would fill <[sets].size.custom_color[emphasis]> inventories worth. Will only save <[limit].custom_color[emphasis]> inventories to avoid overload."
        - define sets <[sets].get[1].to[<[limit]>]>
    - flag player itemclear_itemsets.<[gen_id]>:<[sets]> expire:<[expire]>
    - clickable itemclear_viewset_task def.set_id:<[gen_id]> def.set_number:0 save:clickable until:<[expire]>
    - narrate "<&[base]>Removed <[itemdata].size.custom_color[emphasis]> dropped item stacks (<[itemdata].parse[quantity].sum.custom_color[emphasis]> total items)."
    - narrate <&[base]><element[<&[emphasis]><underline>Click here to view the items].on_click[<entry[clickable].command>]>.

itemclear_viewset_task:
    type: task
    debug: false
    definitions: set_id|set_number
    script:
    - if !<player.has_flag[itemclear_itemsets.<[set_id]>]>:
        - narrate "<&[error]>Sorry, that item clear history data has already expired."
        - stop
    - define data <player.flag[itemclear_itemsets.<[set_id]>]>
    - if <[set_number]> == 0:
        - if <[data].size> > 1:
            - define expire <script[itemclear_config].parsed_key[expire_duration]>
            - narrate "<&[base]>There are <[data].size.custom_color[emphasis]> inventories worth of items stored. Pick one:"
            - define options <player.flag[itemclear_itemoptlist.<[set_id]>].if_null[<list>]>
            - if <[options].is_empty>:
                - repeat <[data].size> as:num:
                    - clickable itemclear_viewset_task def.set_id:<[set_id]> def.set_number:<[num]> save:clickable until:<[expire]>
                    - define options:->:[<element[<[num]>].on_click[<entry[clickable].command>]>]
                - flag player itemclear_itemoptlist.<[set_id]>:<[options]> expire:<[expire]>
            - narrate <&[emphasis]><underline><[options].separated_by[<&[base]>, <&[emphasis]><underline>]>
            - stop
        - define set_number 1
    - define list <[data].get[<[set_number]>]>
    - define inventory <inventory[generic[size=54;title=Item Clear History]]>
    - inventory set o:<[list]> d:<[inventory]>
    - inventory open d:<[inventory]>
