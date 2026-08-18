<!-- fetched from https://tweaked.cc/module/disk.html -->
# module / disk

# disk

Interact with disk drives.

These functions can operate on locally attached or remote disk drives. To use a locally attached drive, specify “side” as one of the six sides (e.g. `left`); to use a remote disk drive, specify its name as printed when enabling its modem (e.g. `drive_0`).

##### tip

All computers (except command computers), turtles and pocket computers can be placed within a disk drive to access it's internal storage like a disk.

### Changes

- New in version 1.2

| isPresent(name) | Checks whether any item at all is in the disk drive |
| getLabel(name) | Get the label of the floppy disk, record, or other media within the given disk drive. |
| setLabel(name, label) | Set the label of the floppy disk or other media |
| hasData(name) | Check whether the current disk provides a mount. |
| getMountPath(name) | Find the directory name on the local computer where the contents of the current floppy disk (or other mount) can be found. |
| hasAudio(name) | Whether the current disk is a music disk as opposed to a floppy disk or other item. |
| getAudioTitle(name) | Get the title of the audio track from the music record in the drive. |
| playAudio(name) | Starts playing the music record in the drive. |
| stopAudio(name) | Stops the music record in the drive from playing, if it was started with `disk.playAudio`. |
| eject(name) | Ejects any item currently in the drive, spilling it into the world as a loose item. |
| getID(name) | Returns a number which uniquely identifies the disk in the drive. |

### isPresent(name)
Checks whether any item at all is in the disk drive

### Parameters

- name `string` The name of the disk drive.

### Returns

- `boolean` If something is in the disk drive.

### Usage

-

```lua
disk.isPresent("top")
```

### getLabel(name)
Get the label of the floppy disk, record, or other media within the given disk drive.

If there is a computer or turtle within the drive, this will set the label as read by `os.getComputerLabel`.

### Parameters

- name `string` The name of the disk drive.

### Returns

- `string` | nil The name of the current media, or `nil` if the drive is not present or empty.

### See also

- `disk.setLabel`

### setLabel(name, label)
Set the label of the floppy disk or other media

### Parameters

- name `string` The name of the disk drive.
- label `string` | nil The new label of the disk

### hasData(name)
Check whether the current disk provides a mount.

This will return true for disks and computers, but not records.

### Parameters

- name `string` The name of the disk drive.

### Returns

- `boolean` If the disk is present and provides a mount.

### See also

- `disk.getMountPath`

### getMountPath(name)
Find the directory name on the local computer where the contents of the current floppy disk (or other mount) can be found.

### Parameters

- name `string` The name of the disk drive.

### Returns

- `string` | nil The mount's directory, or `nil` if the drive does not contain a floppy or computer.

### See also

- `disk.hasData`

### hasAudio(name)
Whether the current disk is a music disk as opposed to a floppy disk or other item.

If this returns true, you will can play the record.

### Parameters

- name `string` The name of the disk drive.

### Returns

- `boolean` If the disk is present and has audio saved on it.

### getAudioTitle(name)
Get the title of the audio track from the music record in the drive.

This generally returns the same as `disk.getLabel` for records.

### Parameters

- name `string` The name of the disk drive.

### Returns

- `string` | false | nil The track title, `false` if there is not a music record in the drive or `nil` if no drive is present.

### playAudio(name)
Starts playing the music record in the drive.

If any record is already playing on any disk drive, it stops before the target drive starts playing. The record stops when it reaches the end of the track, when it is removed from the drive, when `disk.stopAudio` is called, or when another record is started.

### Parameters

- name `string` The name of the disk drive.

### Usage

-

```lua
disk.playAudio("bottom")
```

### stopAudio(name)
Stops the music record in the drive from playing, if it was started with `disk.playAudio`.

### Parameters

- name `string` The name o the disk drive.

### eject(name)
Ejects any item currently in the drive, spilling it into the world as a loose item.

### Parameters

- name `string` The name of the disk drive.

### Usage

-

```lua
disk.eject("bottom")
```

### getID(name)
Returns a number which uniquely identifies the disk in the drive.

Note, unlike `disk.getLabel`, this does not return anything for other media, such as computers or turtles.

### Parameters

- name `string` The name of the disk drive.

### Returns

- `string` | nil The disk ID, or `nil` if the drive does not contain a floppy disk.

### Changes

- New in version 1.4
