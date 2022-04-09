# +-------------------------------
# |
# | C o p y / P a s t e  T o o l s
# |
# | Handy tool for copying and pasting areas.
# |
# +-------------------------------
#
# @author mcmonkey
# @date 2020/12/16
# @updated 2022-04-08
# @denizen-build REL-1765
# @script-version 2.0
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
# Use "/ccopy" to copy your selected area (relative to where you stand).
# Use "/crotate [90/180/270]" or "/cflip [x/z]" to rotate/flip the copy.
# Use "/cpreview [time] [noair]" to show a temporary preview of how it will paste.
# Use "/cpaste [noair]" to actually paste the copy in (relative to where you stand).
# Use "/csave [name]" to save the copy to file and "/cload [name]" to load it back.
#
# ---------------------------- END HEADER ----------------------------

ccopy_command:
    type: command
    debug: false
    name: ccopy
    usage: /ccopy
    description: Copies a place.
    permission: dscript.ccopy
    script:
    - if !<player.has_flag[seltool_selection]>:
        - narrate "<&[error]>You need a <&[emphasis]>/seltool <&[error]>selection to use this command."
        - stop
    - if <schematic[<player.uuid>_copy].exists>:
        - narrate "<&[error]>Forgetting previously copied area."
        - schematic unload name:<player.uuid>_copy
    - narrate <&[base]>Copying...
    - flag player copying duration:1d
    - ~schematic create name:<player.uuid>_copy <player.location.block> area:<player.flag[seltool_selection]> delayed flags
    - flag player copying:!
    - narrate <&[base]>Copied.

cpaste_command:
    type: command
    debug: false
    name: cpaste
    usage: /cpaste [noair]
    description: Pastes what you copy.
    permission: dscript.cpaste
    script:
    - if !<schematic[<player.uuid>_copy].exists>:
        - narrate "<&[error]>You must copy something with <&[emphasis]>/ccopy <&[base]>or <&[emphasis]>/cload <&[base]>first."
        - stop
    - if <player.has_flag[copying]>:
        - narrate "<&[error]>You must wait until the copying is complete before you can paste."
        - stop
    - narrate <&[base]>Pasting...
    - if <context.args.first||null> == noair:
        - ~schematic paste name:<player.uuid>_copy <player.location.block> noair delayed
    - else:
        - ~schematic paste name:<player.uuid>_copy <player.location.block> delayed
    - narrate <&[base]>Pasted.

cpreview_command:
    type: command
    debug: false
    name: cpreview
    usage: /cpreview [time] [noair]
    description: Previews an available paste.
    permission: dscript.cpreview
    script:
    - if !<schematic[<player.uuid>_copy].exists>:
        - narrate "<&[error]>You must copy something with <&[emphasis]>/ccopy <&[base]>or <&[emphasis]>/cload <&[base]>first."
        - stop
    - if <player.has_flag[copying]>:
        - narrate "<&[error]>You must wait until the copying is complete before you can paste."
        - stop
    - narrate <&[base]>Pasting...
    - define duration <context.args.first||10s>
    - if <duration[<[duration]>]||null> == null:
        - narrate "<&[error]>That preview duration is invalid."
        - stop
    - if <context.args.get[2]> == noair:
        - ~schematic paste name:<player.uuid>_copy <player.location.block> noair delayed fake_to:<player.location.find_players_within[200]> fake_duration:<[duration]>
    - else:
        - ~schematic paste name:<player.uuid>_copy <player.location.block> delayed fake_to:<player.location.find_players_within[200]> fake_duration:<[duration]>
    - narrate <&[base]>Pasted.

cload_command:
    type: command
    debug: false
    name: cload
    usage: /cload [name]
    description: Loads a saved area copy.
    permission: dscript.cload
    script:
    - if <context.args.is_empty>:
        - narrate "<&[error]>/cload [name]"
        - stop
    - define name <context.args.first.escaped>
    - if !<server.has_file[schematics/<[name]>.schem]>:
        - narrate "<&[error]>Unknown area save."
        - stop
    - if <schematic[<player.uuid>_copy].exists>:
        - narrate "<&[error]>Forgetting previously copied area."
        - schematic unload name:<player.uuid>_copy
    - ~schematic load name:<player.uuid>_copy filename:<[name]> delayed
    - narrate <&[base]>Loaded.

csave_command:
    type: command
    debug: false
    name: csave
    usage: /csave [name]
    description: Saves your copied area to file.
    permission: dscript.csave
    script:
    - if <context.args.is_empty>:
        - narrate "<&[error]>/csave [name]"
        - stop
    - if !<schematic[<player.uuid>_copy].exists>:
        - narrate "<&[error]>You must copy something with <&[emphasis]>/ccopy <&[base]>or <&[emphasis]>/cload <&[base]>first."
        - stop
    - define name <context.args.first.escaped>
    - if <server.has_file[schematics/<[name]>.schem]>:
        - narrate "<&[error]>Overwriting existing area save."
    - ~schematic save name:<player.uuid>_copy filename:<[name]> delayed
    - narrate <&[base]>Saved.

cflip_command:
    type: command
    debug: false
    name: cflip
    usage: /cflip [x/z]
    description: Flips your copied area.
    permission: dscript.cflip
    script:
    - if !<schematic[<player.uuid>_copy].exists>:
        - narrate "<&[error]>You must copy something with <&[emphasis]>/ccopy <&[base]>or <&[emphasis]>/cload <&[base]>first."
        - stop
    - choose <context.args.first||null>:
        - case x:
            - ~schematic name:<player.uuid>_copy flip_x delayed
            - narrate "<&[base]>Flipped your copy around the X axis."
        - case z:
            - ~schematic name:<player.uuid>_copy flip_z delayed
            - narrate "<&[base]>Flipped your copy around the Z axis."
        - default:
            - narrate "<&[error]>/cflip [x/z]"

crotate_command:
    type: command
    debug: false
    name: crotate
    usage: /crotate [90/180/270]
    description: Rotates your copied area.
    permission: dscript.crotate
    script:
    - if !<schematic[<player.uuid>_copy].exists>:
        - narrate "<&[error]>You must copy something with <&[emphasis]>/ccopy <&[base]>or <&[emphasis]>/cload <&[base]>first."
        - stop
    - if !<list[90|180|270].contains[<context.args.first||null>]>:
        - narrate "<&[error]>/crotate [90/180/270]"
        - stop
    - ~schematic name:<player.uuid>_copy rotate angle:<context.args.first> delayed
    - narrate "<&[base]>Rotated your copy by <&[emphasis]><context.args.first><&[base]>."
