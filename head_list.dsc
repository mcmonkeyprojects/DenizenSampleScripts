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
# @denizen-build REL-1735
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
    name: heads
    debug: false
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
            - define headmegalist <yaml[head_list].read[heads]>
            - foreach <[headmegalist]> as:one_head_map:
                - define title <[one_head_map].get[title]>
                - define tags <[one_head_map].get[tags]>
                - if <[title].contains[<[search]>]> || <[tags].contains[<[search]>]>:
                    - define heads:->:<[one_head_map].proc[head_get_item_proc]>
                    - if <[heads].size> > 1000:
                        - foreach stop
                - if <[loop_index].mod[1000]> == 999:
                    - wait 1t
            - yaml set id:head_cache <[search]>:!|:<[heads]>
        - if <[heads].is_empty>:
            - narrate "<&[error]>No matches for that search."
            - stop
        - if <[heads].size> == 1001:
            - narrate "<&[base]>Showing first 1000 matching heads..."
        - else:
            - narrate "<&[base]>Showing <&[emphasis]><[heads].size><&[base]> matching heads..."
    - run head_list_inventory_open_task def:<list_single[<[heads]>].include[1]>

head_list_arrow_left_item:
    type: item
    material: player_head
    display name: Previous Page
    mechanisms:
        skull_skin: 6d9cb85a-2b76-4e1f-bccc-941978fd4de0|eyJ0ZXh0dXJlcyI6eyJTS0lOIjp7InVybCI6Imh0dHA6Ly90ZXh0dXJlcy5taW5lY3JhZnQubmV0L3RleHR1cmUvYTE4NWM5N2RiYjgzNTNkZTY1MjY5OGQyNGI2NDMyN2I3OTNhM2YzMmE5OGJlNjdiNzE5ZmJlZGFiMzVlIn19fQ==

head_list_arrow_right_item:
    type: item
    material: player_head
    display name: Next Page
    mechanisms:
        skull_skin: 3cd9b7a3-c8bc-4a05-8cb9-0b6d4673bca9|eyJ0ZXh0dXJlcyI6eyJTS0lOIjp7InVybCI6Imh0dHA6Ly90ZXh0dXJlcy5taW5lY3JhZnQubmV0L3RleHR1cmUvMzFjMGVkZWRkNzExNWZjMWIyM2Q1MWNlOTY2MzU4YjI3MTk1ZGFmMjZlYmI2ZTQ1YTY2YzM0YzY5YzM0MDkxIn19fQ

head_list_inventory:
    type: inventory
    inventory: chest
    debug: false
    title: Heads
    size: 54
    slots:
    - [] [] [] [] [] [] [] [] []
    - [] [] [] [] [] [] [] [] []
    - [] [] [] [] [] [] [] [] []
    - [] [] [] [] [] [] [] [] []
    - [] [] [] [] [] [] [] [] []
    - [] [] [] [] [] [] [] [] []

head_list_inventory_open_task:
    type: task
    definitions: heads|page
    debug: false
    script:
    - flag player current_head_list:!|:<[heads]>
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
    - define item <item[player_head].with[skull_skin=<[one_head_map].get[uuid]>|<[one_head_map].get[value]>]>
    - adjust def:item display_name:<[one_head_map].get[title]>
    - determine <[item]>

heads_list_load:
    type: task
    debug: false
    script:
    - if <yaml.list.contains[head_list]>:
        - yaml unload id:head_list
        - yaml unload id:head_cache
    - ~yaml load:data/head_list.yml id:head_list
    - yaml create id:head_cache
    - wait 1t
    - define headmegalist <yaml[head_list].read[heads]>
    - yaml set id:head_cache _!_default:<[headmegalist].get[1].to[5000].parse[proc[head_get_item_proc]]>
    - wait 1t
    - foreach <[headmegalist]> as:one_head_map:
        - if <[loop_index].mod[1000]> == 1:
            - wait 1t
        - foreach <[one_head_map].get[tags]> as:tag:
            - if <[tag].length> > 0:
                - yaml set id:head_cache tags.<[tag].trim>:->:<[one_head_map].proc[head_get_item_proc]>
    - debug log "Heads list loaded, <[headmegalist].size> heads."

head_list_world:
    type: world
    debug: false
    events:
        on server start:
        - run heads_list_load
        on player clicks in head_list_inventory priority:1:
        - if <context.raw_slot||100> < 55 && <context.cursor_item.material.name||air> != air:
            - determine cancelled
        on player clicks head_list_arrow_left_item in head_list_inventory:
        - determine passively cancelled
        - if !<player.has_flag[current_head_list]>:
            - stop
        - run head_list_inventory_open_task def:<list_single[<player.flag[current_head_list]>].include[<player.flag[current_head_page].sub[1]>]>
        on player clicks head_list_arrow_right_item in head_list_inventory:
        - determine passively cancelled
        - if !<player.has_flag[current_head_list]>:
            - stop
        - run head_list_inventory_open_task def:<list_single[<player.flag[current_head_list]>].include[<player.flag[current_head_page].add[1]>]>
