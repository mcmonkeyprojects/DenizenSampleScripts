# +----------------------
# |
# | T o r c h   L i g h t
# |
# | Light from your torch without placing it!
# |
# +----------------------
#
# @author mcmonkey
# @date 2019/08/17
# @denizen-build REL-1723
# @script-version 3.0
#
# Installation:
# Just put the script in your scripts folder and reload.
#
# Configuration
# You can add extra items and/or change their levels at the marked section below.
#
# Usage:
# Hold a torch and run around! Also works in your offhand!
#
# ---------------------------- END HEADER ----------------------------

torch_light_config:
    type: data
    items:
    # =============== Add more material names here ===============
    - torch
    - lantern
    - redstone_torch
    - glowstone
    - glowstone_dust
    - soul_lantern
    levels:
      # =============== Add alternate levels here ===============
      redstone_torch: 8
      glowstone_dust: 6
      soul_lantern: 6
    # =============== end of editable section ===============

torch_light_world:
    type: world
    debug: false
    subpaths:
        reset_delayed:
        - light <[1]> reset
        reset:
        - if <player.has_flag[torch_light_loc]>:
            - if <player.flag[torch_light_loc].as_location.simple> == <[loc].simple||null>:
                - stop
            - run locally subpaths.reset_delayed def:<player.flag[torch_light_loc]> delay:2t
            - flag player torch_light_loc:!
        update:
        - define loc <player.location.add[0,1,0]>
        - if <script[torch_light_config].data_key[items].contains[<player.item_in_hand.material.name||null>]>:
            - inject locally subpaths.reset
            - light <[loc]> <script[torch_light_config].data_key[levels.<player.item_in_hand.material.name>]||14>
            - flag player torch_light_loc:<[loc]>
        - else if <script[torch_light_config].data_key[items].contains[<player.item_in_offhand.material.name||null>]>:
            - inject locally subpaths.reset
            - light <[loc]> <script[torch_light_config].data_key[levels.<player.item_in_offhand.material.name>]||14>
            - flag player torch_light_loc:<[loc]>
        - else:
            - define loc:!
            - inject locally subpaths.reset
    events:
        after player drops item:
        - inject locally subpaths.update
        after player holds item:
        - inject locally subpaths.update
        after player steps on block:
        - inject locally subpaths.update
        on player quits:
        - inject locally subpaths.reset
