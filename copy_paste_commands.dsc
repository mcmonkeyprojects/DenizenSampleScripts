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
# @denizen-build REL-1736
# @script-version 1.0
#
# Dependencies:
# Cuboid Tool script - https://forum.denizenscript.com/resources/cuboid-selector-tool.1/
#
# Installation:
# Just put this script and the cuboid tool script in your scripts folder and reload.
#
# Usage:
# Refer to the cuboid tool info for how to get and use a CTool.
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
    - if !<player.has_flag[ctool_selection]>:
        - narrate "<&c>You need a <&b>/ctool <&c>selection to use this command."
        - stop
    - if <schematic[<player.uuid>_copy].exists>:
        - narrate "<&c>Forgetting previously copied area."
        - schematic unload name:<player.uuid>_copy
    - narrate <&2>Copying...
    - flag player copying duration:1d
    - ~schematic create name:<player.uuid>_copy <player.location.block> <player.flag[ctool_selection]> delayed flags
    - flag player copying:!
    - narrate <&2>Copied.

cpaste_command:
    type: command
    debug: false
    name: cpaste
    usage: /cpaste [noair]
    description: Pastes what you copy.
    permission: dscript.cpaste
    script:
    - if !<schematic[<player.uuid>_copy].exists>:
        - narrate "<&c>You must copy something with <&b>/copy <&2>or <&b>/cload <&2>first."
        - stop
    - if <player.has_flag[copying]>:
        - narrate "<&c>You must wait until the copying is complete before you can paste."
        - stop
    - narrate <&2>Pasting...
    - if <context.args.first||null> == noair:
        - ~schematic paste name:<player.uuid>_copy <player.location.block> noair delayed
    - else:
        - ~schematic paste name:<player.uuid>_copy <player.location.block> delayed
    - narrate <&2>Pasted.

cpreview_command:
    type: command
    debug: false
    name: cpreview
    usage: /cpreview [time] [noair]
    description: Previews an available paste.
    permission: dscript.cpreview
    script:
    - if !<schematic[<player.uuid>_copy].exists>:
        - narrate "<&c>You must copy something with <&b>/copy <&2>or <&b>/cload <&2>first."
        - stop
    - if <player.has_flag[copying]>:
        - narrate "<&c>You must wait until the copying is complete before you can paste."
        - stop
    - narrate <&2>Pasting...
    - define duration <context.args.first||10s>
    - if <duration[<[duration]>]||null> == null:
        - narrate "<&c>That preview duration is invalid."
        - stop
    - if <context.args.get[2]> == noair:
        - ~schematic paste name:<player.uuid>_copy <player.location.block> noair delayed fake_to:<player.location.find.players.within[200]> fake_duration:<[duration]>
    - else:
        - ~schematic paste name:<player.uuid>_copy <player.location.block> delayed fake_to:<player.location.find.players.within[200]> fake_duration:<[duration]>
    - narrate <&2>Pasted.

cload_command:
    type: command
    debug: false
    name: cload
    usage: /cload [name]
    description: Loads a saved area copy.
    permission: dscript.cload
    script:
    - if <context.args.is_empty>:
        - narrate "<&c>/cload [name]"
        - stop
    - define name <context.args.first.escaped>
    - if !<server.has_file[schematics/<[name]>.schem]>:
        - narrate "<&c>Unknown area save."
        - stop
    - if <schematic[<player.uuid>_copy].exists>:
        - narrate "<&c>Forgetting previously copied area."
        - schematic unload name:<player.uuid>_copy
    - ~schematic load name:<player.uuid>_copy filename:<[name]> delayed
    - narrate <&2>Loaded.

csave_command:
    type: command
    debug: false
    name: csave
    usage: /csave [name]
    description: Saves your copied area to file.
    permission: dscript.csave
    script:
    - if <context.args.is_empty>:
        - narrate "<&c>/csave [name]"
        - stop
    - if !<schematic[<player.uuid>_copy].exists>:
        - narrate "<&c>You must copy something with <&b>/copy <&2>or <&b>/cload <&2>first."
        - stop
    - define name <context.args.first.escaped>
    - if <server.has_file[schematics/<[name]>.schem]>:
        - narrate "<&c>Overwriting existing area save."
    - ~schematic save name:<player.uuid>_copy filename:<[name]> delayed
    - narrate <&2>Saved.

cflip_command:
    type: command
    debug: false
    name: cflip
    usage: /cflip [x/z]
    description: Flips your copied area.
    permission: dscript.cflip
    script:
    - if !<schematic[<player.uuid>_copy].exists>:
        - narrate "<&c>You must copy something with <&b>/copy <&2>or <&b>/cload <&2>first."
        - stop
    - choose <context.args.first||null>:
        - case x:
            - ~schematic name:<player.uuid>_copy flip_x delayed
            - narrate "<&2>Flipped your copy around the X axis."
        - case z:
            - ~schematic name:<player.uuid>_copy flip_z delayed
            - narrate "<&2>Flipped your copy around the Z axis."
        - default:
            - narrate "<&c>/cflip [x/z]"

crotate_command:
    type: command
    debug: false
    name: crotate
    usage: /crotate [90/180/270]
    description: Rotates your copied area.
    permission: dscript.crotate
    script:
    - if !<schematic[<player.uuid>_copy].exists>:
        - narrate "<&c>You must copy something with <&b>/copy <&2>or <&b>/cload <&2>first."
        - stop
    - if !<list[90|180|270].contains[<context.args.first||null>]>:
        - narrate "<&c>/crotate [90/180/270]"
        - stop
    - ~schematic name:<player.uuid>_copy rotate angle:<context.args.first> delayed
    - narrate "<&2>Rotated your copy by <&b><context.args.first><&2>."
