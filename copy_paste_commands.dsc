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
# Use "/selundo" to undo your last "/selpaste". Can config undo tracker size via the config below.
# Use "/selredo" to redo something that you undid.
#
# Permissions are in the format "dscript.selcopy" for each command (so also "dscript.selpaste", etc.)
#
# Supplies custom event id 'selpaste_pasted', with context 'selection_area' as an AreaObject of the area of the paste
#
# ---------------------------- END HEADER ----------------------------

# + CONFIG: Configure settings here.
selcopy_config:
    type: data
    debug: false
    # How many recent undoable actions to retain. 0 to disable.
    max_undos: 10

# ---------------------------- END CONFIG ----------------------------

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
    - define location <player.location.block>
    - define area <schematic[<player.uuid>_copy].cuboid[<[location]>]>
    - inject selcopy_undo_inject
    - narrate <&[base]>Pasting...
    - if <context.args.first||null> == noair:
        - ~schematic paste name:<player.uuid>_copy <[location]> noair delayed entities max_delay_ms:25
    - else:
        - ~schematic paste name:<player.uuid>_copy <[location]> delayed entities max_delay_ms:25
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

selcopy_undo_inject:
    type: task
    debug: false
    definitions: location|area
    script:
    - define undos <script[selcopy_config].data_key[max_undos]>
    - if <[undos]> > 0:
        - narrate "<&[base]>Making an undo copy..."
        - define history <player.flag[selcopypaste.undos]||<list>>
        - if <[history].size> > <[undos]>:
            - schematic unload name:selcopy_backup_<[history].first.get[id]>
            - define history[1]:<-
        - definemap backup:
            id: <util.random_uuid>
            location: <[location]>
            area: <[area]>
            time: <util.time_now>
        - define history:->:<[backup]>
        - flag <player> selcopypaste.undos:<[history]> expire:1d
        - ~schematic create name:selcopy_backup_<[backup.id]> <[location]> area:<[area]> delayed flags entities max_delay_ms:25

selundo_command:
    type: command
    debug: false
    name: selundo
    usage: /selundo
    description: Undoes your last paste.
    permission: dscript.selundo
    aliases:
    - cundo
    script:
    - define history <player.flag[selcopypaste.undos]||<list>>
    - if <[history].is_empty>:
        - narrate "<&[error]>You have nothing left to undo."
        - stop
    - define to_undo <[history].last>
    - flag <player> selcopypaste.undos[last]:<-
    - if !<schematic[selcopy_backup_<[to_undo.id]>].exists>:
        - flag <player> selcopypaste.undos:!
        - narrate "<&[error]>The server has restarted since your last paste, cannot undo."
        - stop
    - define text_time <[to_undo.time].from_now.formatted_words.custom_color[emphasis]>
    - define text_location <&[emphasis]><[to_undo.location].simple.replace_text[,].with[<&[base]>,<&[emphasis]>]><&[base]>
    - narrate "<&[base]>Will undo your paste from <[text_time]> ago at <[text_location]>, making backup..."
    - definemap redo:
        id: <util.random_uuid>
        location: <[to_undo.location]>
        area: <[to_undo.area]>
    - ~schematic create name:selcopy_backup_<[redo.id]> <[to_undo.location]> area:<[to_undo.area]> delayed flags entities max_delay_ms:25
    - narrate "<&[base]>Backup made, performing undo..."
    - ~schematic paste name:selcopy_backup_<[to_undo.id]> <[to_undo.location]> delayed entities max_delay_ms:25
    - schematic unload name:selcopy_backup_<[to_undo.id]>
    - narrate "<&[base]>Undone! If you didn't mean to undo, you can <&[emphasis]>/selredo<&[base]>."
    - flag <player> selcopypaste.redo:<[redo]> expire:1h

selredo_command:
    type: command
    debug: false
    name: selredo
    usage: /selredo
    description: Redoes your last undone paste.
    permission: dscript.selredo
    aliases:
    - credo
    script:
    - if !<player.has_flag[selcopypaste.redo]>:
        - narrate "<&[error]>You have nothing to redo."
        - stop
    - define to_redo <player.flag[selcopypaste.redo]>
    - flag <player> selcopypaste.redo:!
    - if !<schematic[selcopy_backup_<[to_redo.id]>].exists>:
        - narrate "<&[error]>The server has restarted since your last undo, cannot redo."
        - stop
    - narrate <&[base]>Redoing...
    - ~schematic paste name:selcopy_backup_<[to_redo.id]> <[to_redo.location]> delayed entities max_delay_ms:25
    - schematic unload name:selcopy_backup_<[to_redo.id]>
    - narrate "<&[base]>Redone. Warning: not currently an option to undo again."
