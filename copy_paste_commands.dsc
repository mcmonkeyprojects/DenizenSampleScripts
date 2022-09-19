# +-------------------------------
# |
# | C o p y / P a s t e  T o o l s
# |
# | Handy tool for copying and pasting areas.
# |
# +-------------------------------
#
# @author mcmonkey
# @date 2020-12-16
# @updated 2022-09-19
# @denizen-build REL-1777
# @script-version 2.4
#
# Dependencies:
# Selector Tool script - https://forum.denizenscript.com/resources/area-selector-tool.1/
#
# Installation:
# Just put this script and the selector tool script in your scripts folder and reload.
#
# Usage:
# Refer to the selector tool info for how to get and use a SelTool.
#
# Use "/selcopy" to copy your selected area (relative to where you stand).
# Use "/selrotate [90/180/270]" or "/selflip [x/z]" to rotate/flip the copy.
# Use "/selpreview [time] [noair]" to show a temporary preview of how it will paste.
# Use "/selpaste [noair]" to actually paste the copy in (relative to where you stand).
# Use "/selsave [name]" to save the copy to file and "/selload [name]" to load it back.
#
# Supplies custom event id 'selpaste_pasted', with context 'selection_area' as an AreaObject of the area of the paste
#
# ---------------------------- END HEADER ----------------------------

selcopy_command:
    type: command
    debug: false
    name: selcopy
    usage: /selcopy
    description: Copies a place.
    permission: dscript.selcopy
    aliases:
    - ccopy
    script:
    - if !<player.has_flag[seltool_selection]>:
        - narrate "<&[error]>You need a <&[emphasis]>/seltool <&[error]>selection to use this command."
        - stop
    - if <schematic[<player.uuid>_copy].exists>:
        - narrate "<&[error]>Forgetting previously copied area."
        - schematic unload name:<player.uuid>_copy
    - narrate <&[base]>Copying...
    - flag player copying duration:1d
    - ~schematic create name:<player.uuid>_copy <player.location.block> area:<player.flag[seltool_selection]> delayed flags entities max_delay_ms:25
    - flag player copying:!
    - narrate <&[base]>Copied.

selpaste_command:
    type: command
    debug: false
    name: selpaste
    usage: /selpaste [noair]
    description: Pastes what you copy.
    permission: dscript.selpaste
    aliases:
    - cpaste
    tab completions:
        1: noair
    script:
    - if !<schematic[<player.uuid>_copy].exists>:
        - narrate "<&[error]>You must copy something with <&[emphasis]>/selcopy <&[base]>or <&[emphasis]>/selload <&[base]>first."
        - stop
    - if <player.has_flag[copying]>:
        - narrate "<&[error]>You must wait until the copying is complete before you can paste."
        - stop
    - narrate <&[base]>Pasting...
    - define area <schematic[<player.uuid>_copy].cuboid[<player.location.block>]>
    - if <context.args.first||null> == noair:
        - ~schematic paste name:<player.uuid>_copy <player.location.block> noair delayed entities max_delay_ms:25
    - else:
        - ~schematic paste name:<player.uuid>_copy <player.location.block> delayed entities max_delay_ms:25
    - definemap context:
        selection_area: <[area]>
    - customevent id:selpaste_pasted context:<[context]>
    - narrate <&[base]>Pasted.

selpreview_command:
    type: command
    debug: false
    name: selpreview
    usage: /selpreview [time] [noair]
    description: Previews an available paste.
    permission: dscript.selpreview
    aliases:
    - cpreview
    tab completions:
        1: 10s|30s|1m|5m|10m
        2: noair
    script:
    - if !<schematic[<player.uuid>_copy].exists>:
        - narrate "<&[error]>You must copy something with <&[emphasis]>/selcopy <&[base]>or <&[emphasis]>/selload <&[base]>first."
        - stop
    - if <player.has_flag[copying]>:
        - narrate "<&[error]>You must wait until the copying is complete before you can paste."
        - stop
    - narrate <&[base]>Pasting...
    - define duration <context.args.first||10s>
    - if <duration[<[duration]>]||null> == null:
        - narrate "<&[error]>That preview duration is invalid."
        - stop
    - if <context.args.get[2]||null> == noair:
        - ~schematic paste name:<player.uuid>_copy <player.location.block> noair delayed fake_to:<player.location.find_players_within[200]> fake_duration:<[duration]>
    - else:
        - ~schematic paste name:<player.uuid>_copy <player.location.block> delayed fake_to:<player.location.find_players_within[200]> fake_duration:<[duration]>
    - narrate <&[base]>Pasted.

selload_command:
    type: command
    debug: false
    name: selload
    usage: /selload [name]
    description: Loads a saved area copy.
    permission: dscript.selload
    aliases:
    - cload
    tab completions:
        1: <list>
    script:
    - if <context.args.is_empty>:
        - narrate "<&[error]>/selload [name]"
        - stop
    - define name <context.args.first.escaped>
    - if !<util.has_file[schematics/<[name]>.schem]>:
        - narrate "<&[error]>Unknown area save."
        - stop
    - if <schematic[<player.uuid>_copy].exists>:
        - narrate "<&[error]>Forgetting previously copied area."
        - schematic unload name:<player.uuid>_copy
    - ~schematic load name:<player.uuid>_copy filename:<[name]> delayed
    - narrate <&[base]>Loaded.

selsave_command:
    type: command
    debug: false
    name: selsave
    usage: /selsave [name]
    description: Saves your copied area to file.
    permission: dscript.selsave
    aliases:
    - csave
    tab completions:
        1: <list>
    script:
    - if <context.args.is_empty>:
        - narrate "<&[error]>/selsave [name]"
        - stop
    - if !<schematic[<player.uuid>_copy].exists>:
        - narrate "<&[error]>You must copy something with <&[emphasis]>/selcopy <&[base]>or <&[emphasis]>/selload <&[base]>first."
        - stop
    - define name <context.args.first.escaped>
    - if <util.has_file[schematics/<[name]>.schem]>:
        - narrate "<&[error]>Overwriting existing area save."
    - ~schematic save name:<player.uuid>_copy filename:<[name]> delayed
    - narrate <&[base]>Saved.

selflip_command:
    type: command
    debug: false
    name: selflip
    usage: /selflip [x/z]
    description: Flips your copied area.
    permission: dscript.selflip
    aliases:
    - cflip
    tab completions:
        1: x|z
    script:
    - if !<schematic[<player.uuid>_copy].exists>:
        - narrate "<&[error]>You must copy something with <&[emphasis]>/selcopy <&[base]>or <&[emphasis]>/selload <&[base]>first."
        - stop
    - choose <context.args.first||null>:
        - case x:
            - ~schematic name:<player.uuid>_copy flip_x delayed
            - narrate "<&[base]>Flipped your copy around the X axis."
        - case z:
            - ~schematic name:<player.uuid>_copy flip_z delayed
            - narrate "<&[base]>Flipped your copy around the Z axis."
        - default:
            - narrate "<&[error]>/selflip [x/z]"

selrotate_command:
    type: command
    debug: false
    name: selrotate
    usage: /selrotate [90/180/270]
    description: Rotates your copied area.
    permission: dscript.selrotate
    aliases:
    - crotate
    tab completions:
        1: 90|180|270
    script:
    - if !<schematic[<player.uuid>_copy].exists>:
        - narrate "<&[error]>You must copy something with <&[emphasis]>/selcopy <&[base]>or <&[emphasis]>/selload <&[base]>first."
        - stop
    - if !<list[90|180|270].contains[<context.args.first||null>]>:
        - narrate "<&[error]>/selrotate [90/180/270]"
        - stop
    - ~schematic name:<player.uuid>_copy rotate angle:<context.args.first> delayed
    - narrate "<&[base]>Rotated your copy by <&[emphasis]><context.args.first><&[base]>."
