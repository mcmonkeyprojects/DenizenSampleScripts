# +----------------------
# |
# | NPC Skin From URL
# |
# | Citizens extension to set NPC skins from a direct image URL.
# |
# +----------------------
#
# @original-author Mergu
# @updated-by mcmonkey
# @date 2019/11/19
# @denizen-build REL-1690
# @script-version 1.5
#
# Installation:
# Just put the script in your scripts folder and reload.
#
# Usage:
# Type command: /npc skin --url (url here)
# For slim ("Alex") model NPCs, use /npc skin --url (url here) slim
#
# Examples:
# /npc skin --url https://i.imgur.com/Pgu9R1s.png
# /npc skin --url https://i.imgur.com/6l1i0uB.png slim
#
# ---------------------------- END HEADER ----------------------------

skin_url_handler:
    type: world
    debug: false
    events:
        on npc command:
        - if <context.args.get[1].to_lowercase||null> != skin:
            - stop
        - if !<li@-u|--url.contains[<context.args.get[2].to_lowercase||null>]>:
            - stop
        - determine passively fulfilled

        - define url <context.args.get[3]||null>
        - define model <context.args.get[4].to_lowercase||empty>
        - if <context.server>:
            - define npc <server.selected_npc||null>
        - else:
            - define npc <player.selected_npc||null>

        - if <[npc]> == null:
            - narrate "<&a>You must have an NPC selected to execute that command."
            - stop
        - if <[npc].entity_type> != PLAYER:
            - narrate "<&a>You must have a player-type NPC selected."
            - stop
        - if <[url]> == null:
            - narrate "<&a>You must specify a valid skin URL."
            - stop
        - if <[model]> != empty && <[model]> != slim:
            - narrate "<&e><[model]><&a> is not a valid skin model. Must be <&e>slim<&a> or empty."
            - stop
        - narrate "<&a>Retrieving the requested skin..."
        - run skin_url_task def:<[url]>|<[model]> save:newQueue
        - while <entry[newQueue].created_queue.state> == running:
            - if <[loop_index]> > 20:
                - queue <entry[newQueue].created_queue> clear
                - narrate "<&c>The request timed out. Is the url valid?"
                - stop
            - wait 5t
        - if <entry[newQueue].created_queue.determination.first||null> == null:
            - narrate "<&c>Failed to retrieve the skin from the provided link. Is the url valid?"
            - stop
        - define yamlid <[npc].uuid>_skin_from_url
        - yaml loadtext:<entry[newQueue].created_queue.determination[result].first> id:<[yamlid]>
        - if !<yaml[<[yamlid]>].contains[data.texture]>:
            - narrate "<&c>An unexpected error occurred while retrieving the skin data. Please try again."
        - else:
            - adjust <[npc]> skin_blob:<yaml[<[yamlid]>].read[data.texture.value]>;<yaml[<[yamlid]>].read[data.texture.signature]>
            - narrate "<&e><[npc].name><&a>'s skin set to <&e><[url]><&a>."
        - yaml unload id:<[yamlid]>

skin_url_task:
    type: task
    debug: false
    definitions: url|model
    script:
    - define requestUrl "https://api.mineskin.org/generate/url"
    - if <[model]> == slim:
        - define requestUrl "<[requestUrl]>?model=slim"
    - ~webget <[requestUrl]> "post:url=<[url]>" timeout:5s save:webResult
    - determine <entry[webResult].result||null>
