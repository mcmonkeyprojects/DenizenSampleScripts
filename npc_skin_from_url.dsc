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
#
# If you have a local file you want to use,
# consider uploading it to an image host like imgur.
# If you do, be sure to use the direct image URL (ends with ".png") as opposed to the album URL.
#
# Examples:
# /npc skin --url https://gamepedia.cursecdn.com/minecraft_gamepedia/3/37/Steve_skin.png
# /npc skin --url https://gamepedia.cursecdn.com/minecraft_gamepedia/f/f2/Alex_skin.png
#
# ---------------------------- END HEADER ----------------------------

skin_url_handler:
    type: world
    debug: false
    events:
        on npc command:
        - if <context.args.get[1]||null> != skin || <context.args.get[2]||null> != "--url":
            - stop
        - determine passively fulfilled
        - if <context.server>:
            - define npc <server.selected_npc||null>
        - else:
            - define npc <player.selected_npc||null>
        - if <[npc]> == null:
            - narrate "<&c>You must have an NPC selected to execute that command."
            - stop
        - if <[npc].entity_type> != PLAYER:
            - narrate "<&c>You must have a player-type NPC selected."
            - stop
        - define url <context.args.get[3]||null>
        - if <[url]> == null:
            - narrate "<&c>You must specify a valid skin URL."
            - stop
        - if !<[url].ends_with[.png]>:
            - narrate "<&c>That URL isn't likely to be valid. Make sure you have a direct image URL, ending with '.png'."
        - narrate "<&a>Retrieving the requested skin..."
        - run skin_url_task def:<[url]> save:newQueue
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
    definitions: url
    script:
    - ~webget "https://api.mineskin.org/generate/url" post:url=<[url]> timeout:5s save:webResult
    - determine <entry[webResult].result||null>
