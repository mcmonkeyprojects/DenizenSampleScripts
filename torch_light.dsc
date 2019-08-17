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
# @denizen-build REL-1681
# @script-version 2.9
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

torch_light_world:
    type: world
    debug: false
    items:
    # =============== Add more material names here ===============
    - torch
    - lantern
    - redstone_torch
    - glowstone
    - glowstone_dust
    levels:
      # =============== Add alternate levels here ===============
      redstone_torch: 8
      glowstone_dust: 6
    # =============== end of editable section ===============
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
        - wait 1t
        - define loc <player.location.add[0,1,0]>
        - inject locally subpaths.reset
        - if <script.yaml_key[items].contains[<player.item_in_hand.material.name||null>]>:
          - light <[loc]> <script.yaml_key[levels.<player.item_in_hand.material.name>]||14>
          - flag player torch_light_loc:<[loc]>
        - else if <script.yaml_key[items].contains[<player.item_in_offhand.material.name||null>]>:
          - light <[loc]> <script.yaml_key[levels.<player.item_in_offhand.material.name>]||14>
          - flag player torch_light_loc:<[loc]>
    events:
        on player holds item:
        - inject locally subpaths.update
        on player steps on block:
        - inject locally subpaths.update
        on player quits:
        - inject locally subpaths.reset
