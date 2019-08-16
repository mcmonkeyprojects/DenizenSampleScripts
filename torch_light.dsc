# +----------------------
# |
# | T o r c h   L i g h t
# |
# | Light from your torch without placing it!
# |
# +----------------------
#
# @author mcmonkey
# @date 2019/08/16
# @denizen-build REL-1681
# @script-version 2.7
#
# Installation:
# Just put the script in your scripts folder and reload.
#
# Usage:
# Hold a torch and run around! Also works in your offhand!
#
# ---------------------------- END HEADER ----------------------------

torch_light_world:
    type: world
    debug: false
    items:
    # Add more material names here
    - torch
    - lantern
    - redstone_torch
    - glowstone
    subpaths:
        reset_delayed:
          - light <[1]> reset
        reset:
        - if <player.flag[torch_light_loc].simple||null> == <[loc].simple>:
          - stop
        - if <player.has_flag[torch_light_loc]>:
          - run locally subpaths.reset_delayed def:<player.flag[torch_light_loc]> delay:2t
          - flag player torch_light_loc:!
        update:
        - wait 1t
        - define loc <player.location.add[0,1,0]>
        - inject locally subpaths.reset
        - define held <list[<player.item_in_hand.material.name||null>|<player.item_in_offhand.material.name||null>]>
        - if <[held].contains_any[<script.yaml_key[items]>]>:
          - light <[loc]> 14
          - flag player torch_light_loc:<[loc]>
    events:
        on player holds item:
        - inject locally subpaths.update
        on player steps on block:
        - inject locally subpaths.update
        on player quits:
        - inject locally subpaths.reset