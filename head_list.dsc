# +------------------
# |
# | H e a d   L i s t
# |
# | An in-game usable list of custom head items.
# |
# +------------------
#
# @author mcmonkey
# @date 2020/11/24
# @updated 2021/11/17
# @denizen-build REL-1751
# @script-version 1.1
#
# Installation:
# - Put the script in your scripts folder.
# - Add a list of heads to plugins/Denizen/data/head_list.yml (key name 'heads', list of maps with keys 'title', 'uuid', 'value')
# If you need a heads list, here's a list file of about 35 thousand heads from minecraft-heads.com: https://cdn.discordapp.com/attachments/351925110866968576/830475926981705768/head_list.yml
# - Restart server (or reload and then '/ex run heads_list_load')
#
# Usage:
# Type "/heads" in-game, optionally with a search like "/heads monkey".
# There will be tab completed suggestions for tag names, but you don't have to use those.
# You will need permission "denizen.heads" to use the command.
# You can just grab heads right out of the opened inventory.
# For large searches, click the left/right arrows freely to move through pages (45 heads per page). There will be up to 1000 results listed for any search.
# Note that searches will cache, meaning the first time you search something might take a second to load. The cache resets when the server restarts.
#
# ---------------------------- END HEADER ----------------------------

head_list_command:
    type: command
    debug: false
    name: heads
    usage: /heads (search)
    description: Searches a list of heads.
    permission: denizen.heads
    tab completions:
        1: <yaml[head_cache].list_keys[tags]>
    script:
    - define search <context.raw_args>
    - if <context.args.is_empty>:
        - define heads <yaml[head_cache].read[_!_default]>
        - narrate "<&[base]>Showing first 5000 heads..."
    - else if <yaml[head_cache].contains[tags.<[search].escaped>]>:
        - define heads <yaml[head_cache].read[tags.<[search].escaped>]>
        - narrate "<&[base]>Showing <&[emphasis]><[heads].size><&[base]> heads in that tag..."
    - else:
        - if <yaml[head_cache].contains[<[search].escaped>]>:
            - define heads <yaml[head_cache].read[<[search].escaped>]>
        - else:
            - define heads <list>
            - foreach <yaml[head_list].read[heads]> as:one_head_map:
                - if <[one_head_map.title].contains[<[search]>]> || <[one_head_map.tags].contains[<[search]>]>:
                    - define heads:->:<[one_head_map].proc[head_get_item_proc]>
                    - if <[heads].size> >= 1000:
                        - foreach stop
                # Performance: wait 1t every thousand heads checked to avoid server freeze from large search
                - wait 1t if:<[loop_index].mod[1000].equals[999]>
            - yaml set id:head_cache <[search].escaped>:<[heads]>
        - if <[heads].is_empty>:
            - narrate "<&[error]>No matches for that search."
            - stop
        - if <[heads].size> == 1000:
            - narrate "<&[base]>Showing first <&[emphasis]>1000<&[base]> matching heads..."
        - else:
            - narrate "<&[base]>Showing <&[emphasis]><[heads].size><&[base]> matching heads..."
    - run head_list_inventory_open_task def.heads:<[heads]> def.page:1

head_list_arrow_left_item:
    type: item
    debug: false
    material: player_head
    display name: <&f>Previous Page
    mechanisms:
        skull_skin: 6d9cb85a-2b76-4e1f-bccc-941978fd4de0|eyJ0ZXh0dXJlcyI6eyJTS0lOIjp7InVybCI6Imh0dHA6Ly90ZXh0dXJlcy5taW5lY3JhZnQubmV0L3RleHR1cmUvYTE4NWM5N2RiYjgzNTNkZTY1MjY5OGQyNGI2NDMyN2I3OTNhM2YzMmE5OGJlNjdiNzE5ZmJlZGFiMzVlIn19fQ==

head_list_arrow_right_item:
    type: item
    debug: false
    material: player_head
    display name: <&f>Next Page
    mechanisms:
        skull_skin: 3cd9b7a3-c8bc-4a05-8cb9-0b6d4673bca9|eyJ0ZXh0dXJlcyI6eyJTS0lOIjp7InVybCI6Imh0dHA6Ly90ZXh0dXJlcy5taW5lY3JhZnQubmV0L3RleHR1cmUvMzFjMGVkZWRkNzExNWZjMWIyM2Q1MWNlOTY2MzU4YjI3MTk1ZGFmMjZlYmI2ZTQ1YTY2YzM0YzY5YzM0MDkxIn19fQ

head_list_inventory:
    type: inventory
    debug: false
    inventory: chest
    title: Heads
    size: 54

head_list_inventory_open_task:
    type: task
    debug: false
    definitions: heads|page
    script:
    - flag player current_head_list:<[heads]>
    - flag player current_head_page:<[page]>
    - define inv <inventory[head_list_inventory]>
    - inventory set d:<[inv]> o:<[heads].get[<[page].sub[1].mul[45].max[1]>].to[<[page].mul[45]>]>
    - if <[page]> > 1:
        - inventory set d:<[inv]> o:head_list_arrow_left_item slot:46
    - if <[heads].size> > <[page].mul[45]>:
        - inventory set d:<[inv]> o:head_list_arrow_right_item slot:54
    - inventory open d:<[inv]>

head_get_item_proc:
    type: procedure
    debug: false
    definitions: one_head_map
    script:
    # Use a map to avoid glitches like the title having a format code in it
    - definemap mechs:
        skull_skin: <[one_head_map].get[uuid]>|<[one_head_map].get[value]>
        display: <[one_head_map].get[title]>
    - determine <item[player_head].with_map[<[mechs]>]>

heads_list_load:
    type: task
    debug: false
    script:
    - if <yaml.list.contains[head_list]>:
        - yaml unload id:head_list
        - yaml unload id:head_cache
    - ~yaml load:data/head_list.yml id:head_list
    - if !<yaml.list.contains[head_list]>:
        - debug error "Head list cannot load: you are missing your head list file! Check the install instructions and get a reference heads list file at https://forum.denizenscript.com/resources/in-game-custom-head-item-list.9/"
        - stop
    - yaml create id:head_cache
    - wait 1t
    - define headmegalist <yaml[head_list].read[heads]>
    - wait 1t
    - yaml set id:head_cache _!_default:<[headmegalist].get[1].to[5000].parse[proc[head_get_item_proc]]>
    - wait 1t
    - foreach <[headmegalist]> as:one_head_map:
        - wait 1t if:<[loop_index].mod[500].equals[499]>
        - foreach <[one_head_map].get[tags].if_null[<list>]> as:tag:
            - if <[tag].length> > 0:
                - yaml set id:head_cache tags.<[tag].trim>:->:<[one_head_map].proc[head_get_item_proc]>
    - debug log "Heads list loaded, <[headmegalist].size> heads."

head_list_world:
    type: world
    debug: false
    events:
        after server start:
        - run heads_list_load
        # Block players adding items into the head list inv
        on player clicks item in head_list_inventory with:!air priority:1:
        # Only cancel if they clicked the scripted inventory (as opposed to their own playe rinventory)
        - if <context.clicked_inventory.script.exists>:
            - determine cancelled
        # Handle page arrows
        on player clicks head_list_arrow_left_item in head_list_inventory:
        - determine passively cancelled
        - if !<player.has_flag[current_head_list]>:
            - stop
        - run head_list_inventory_open_task def.heads:<player.flag[current_head_list]> def.page:<player.flag[current_head_page].sub[1]>
        on player clicks head_list_arrow_right_item in head_list_inventory:
        - determine passively cancelled
        - if !<player.has_flag[current_head_list]>:
            - stop
        - run head_list_inventory_open_task def.heads:<player.flag[current_head_list]> def.page:<player.flag[current_head_page].add[1]>
        # Cleanup the flag when needed
        on player joins flagged:current_head_page:
        - flag player current_head_page:!
        - flag player current_head_page:!
