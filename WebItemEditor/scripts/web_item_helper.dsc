
staff_item_edit_command:
    type: command
    debug: false
    name: webedititem
    usage: /webedititem
    description: Lets you open a webpage to edit the item in your hand.
    permission: dscript.webedititem
    aliases:
    - itemwebedit
    - webitemedit
    - edititemweb
    script:
    - if <player.item_in_hand.material.name> == air:
        - narrate "<&[error]>Cannot edit AIR. Please hold an item to edit."
        - stop
    - define new_session <util.random_uuid>
    - definemap session_data:
        item: <player.item_in_hand>
    - flag player web_edit_item_session.<[new_session]>:<player.item_in_hand> expire:1d
    - define url <script[webtools_config].parsed_key[url_base]>web_edit_item?user=<player.uuid>&session=<[new_session]>
    - narrate "<&[base]>Please open <element[<&[emphasis]>this link].on_click[<[url]>].type[open_url].on_hover[Click me!]>."

webedititem_invalid_sess:
    type: task
    debug: false
    script:
    - determine code:403 passively
    - determine headers:[Content-Type=text/plain] passively
    - determine "raw_text_content:Invalid access session. Use the command in-game to generate a session link."

webedititem_session_validate:
    type: task
    debug: false
    script:
    - define user <context.query.get[user]||null>
    - define session <context.query.get[session]||null>
    - if <[user]> == null || <[session]> == null:
        - inject webedititem_invalid_sess
    - define charset 0123456789abcdef-
    - if !<[user].matches_character_set[<[charset]>]> || !<[session].matches_character_set[<[charset]>]>:
        - inject webedititem_invalid_sess
    - if !<server.online_players.parse[uuid].contains[<[user]>]>:
        - inject webedititem_invalid_sess
    - define player <player[<[user]>]>
    - if !<[player].has_flag[web_edit_item_session.<[session]>]>:
        - inject webedititem_invalid_sess
    - define item <[player].flag[web_edit_item_session.<[session]>]>
    # General backup safety check
    - if <[item].material.name||air> == air:
        - inject webedititem_invalid_sess

webserver_webitemedit_world:
    type: world
    debug: false
    events:
        on server start:
        - flag server webedititem_cache_ench:<server.enchantments.parse[key.after[:]].alphabetical>
        on player quits flagged:web_edit_item_session:
        - flag player web_edit_item_session:!
        on webserver web request path:/web_edit_item method:get:
        - inject webedititem_session_validate
        - determine code:200 passively
        - determine headers:[Content-Type=text/html] passively
        - determine cached_file:web_edit_item.htm
        on webserver web request path:/web_edit_item.json method:post:
        - inject webedititem_session_validate
        - determine code:200 passively
        - determine headers:[Content-Type=application/json] passively
        - definemap out_data:
            material: <[item].material.name>
            display: <[item].display.replace_text[<&ss>].with[&]||>
            lore: <[item].lore.separated_by[<n>].replace_text[<&ss>].with[&]||>
            enchantments: <[item].enchantment_map||<map>>
            available_ench_types: <server.flag[webedititem_cache_ench]>
            hides: <[item].hides.any>
        - determine raw_text_content:<[out_data].to_json>
        on webserver web request path:/web_edit_item_upload method:post:
        - inject webedititem_session_validate
        - determine code:200 passively
        - define data <util.parse_yaml[<context.body>]>
        - definemap alterations:
            hides: <[data].get[hides].if_true[all].if_false[]>
            display: <[data].get[display].parse_color>
            lore: <[data].get[lore].parse_color.lines_to_colored_list>
            enchantments: <[data].get[enchantments]>
        - define inv <inventory[webitemedit]>
        - give <[item].with_map[<[alterations]>]> to:<[inv]>
        - inventory open player:<[player]> d:<[inv]>
        - determine raw_text_content:Accepted.
        on webserver web request path:/js/webedititem.js method:get:
        - determine code:200 passively
        - determine headers:[Content-Type=application/javascript] passively
        - determine cached_file:/js/webedititem.js
        on webserver web request path:/font/minecraft* method:get:
        - if <context.path.after[/font/minecraft]> not in .tff|.woff|.woff2:
            - stop
        - determine code:200 passively
        - determine cached_file:<context.path>

webitemedit:
    type: inventory
    debug: false
    inventory: chest
    size: 9
    title: Here's your web item!
