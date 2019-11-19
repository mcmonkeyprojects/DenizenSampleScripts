# Allows a player to set an npc's skin with a url using /npc skin [-u/--url] <url> (slim)
# Just drop this file into the Denizen/scripts folder and you're done!

skin_url_handler:
    type: world
    debug: false
    events:
        on npc command:
            - if <c.args.get[1].to_lowercase||null> != skin:
                - queue clear
            - if !<li@-u|--url.contains[<c.args.get[2].to_lowercase||null>]>:
                - queue clear
            - determine passively fulfilled

            - define url <c.args.get[3]||null>
            - define model <c.args.get[4].to_lowercase||empty>
            - if <c.server>:
                - define npc <server.selected_npc||null>
            - else:
                - define npc <player.selected_npc||null>

            - if <def[npc]> == null:
                - narrate "<&a>You must have an NPC selected to execute that command."
                - queue clear
            - if <def[npc].entity_type> != PLAYER:
                - narrate "<&a>You must have a player-type NPC selected."
                - queue clear
            - if <def[url]> == null:
                - narrate "<&a>You must specify a valid skin URL."
                - queue clear
            - if <def[model]> != empty && <def[model]> != slim:
                - narrate "<&e><def[model]><&a> is not a valid skin model. Must be <&e>slim<&a> or empty."
                - queue clear

            - narrate "<&a>Retrieving the requested skin..."
            - define key <util.random.uuid>

            # Our own custom ~5s timeout since the builtin hangs
            - run skin_url_task def:<def[key]>|<def[url]>|<def[model]> id:<def[key]> instantly
            - while <queue.exists[<def[key]>]>:
                - if <def[loop_index]> > 20:
                    - queue q@<def[key]> clear
                    - narrate "<&a>The request timed out. Is the url valid?"
                    - queue clear
                - wait 5t

            # Quick sanity check - ideally this should never be true
            - if !<server.has_flag[<def[key]>]>:
                - queue clear

            - if <server.flag[<def[key]>]> == null:
                - narrate "<&a>Failed to retrieve the skin from the provided link. Is the url valid?"
                - flag server <def[key]>:!
                - queue clear

            - yaml loadtext:<server.flag[<def[key]>]> id:response

            - if !<yaml[response].contains[data.texture]>:
                - narrate "<&a>An unexpected error occurred while retrieving the skin data. Please try again."
            - else:
                - narrate "<&e><def[npc].name><&a>'s skin set to <&e><def[url]><&a>."
                - adjust <def[npc]> skin_blob:<yaml[response].read[data.texture.value]>;<yaml[response].read[data.texture.signature]>

            - flag server <def[key]>:!
            - yaml unload id:response

skin_url_task:
    type: task
    debug: false
    definitions: key|url|model
    script:
        - define req "https://api.mineskin.org/generate/url"
        - if <def[model]> == slim:
            - define req "<def[req]>?model=slim"
        - ~webget <def[req]> "post:url=<def[url]>" timeout:5s save:res
        - flag server <def[key]>:<entry[res].result||null>
