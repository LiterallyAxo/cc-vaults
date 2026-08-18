<!-- fetched from https://tweaked.cc/peripheral/drive.html -->
# peripheral / drive

# drive

Disk drives are a peripheral which allow you to read and write to floppy disks and other "mountable media" (such as computers or turtles). They also allow you to play records.

When a disk drive attaches some mount (such as a floppy disk or computer), it attaches a folder called `disk`, `disk2`, etc... to the root directory of the computer. This folder can be used to interact with the files on that disk.

When a disk is inserted, a `disk` event is fired, with the side peripheral is on. Likewise, when the disk is detached, a `disk_eject` event is fired.

## Recipe
 Disk Drive

| isDiskPresent() | Returns whether a disk is currently inserted in the drive. |
| getDiskLabel() | Returns the label of the disk in the drive if available. |
| setDiskLabel([label]) | Sets or clears the label for a disk. |
| hasData() | Returns whether a disk with data is inserted. |
| getMountPath() | Returns the mount path for the inserted disk. |
| hasAudio() | Returns whether a disk with audio is inserted. |
| getAudioTitle() | Returns the title of the inserted audio disk. |
| playAudio() | Plays the audio in the inserted disk, if available. |
| stopAudio() | Stops any audio that may be playing. |
| ejectDisk() | Ejects any disk that may be in the drive. |
| getDiskID() | Returns the ID of the disk inserted in the drive. |

### isDiskPresent()
Returns whether a disk is currently inserted in the drive.

### Returns

- `boolean` Whether a disk is currently inserted in the drive.

### getDiskLabel()
Returns the label of the disk in the drive if available.

### Returns

- `string` | nil The label of the disk, or `nil` if either no disk is inserted or the disk doesn't have a label.

### setDiskLabel([label])
Sets or clears the label for a disk.

If no label or `nil` is passed, the label will be cleared.

If the inserted disk's label can't be changed (for example, a record), an error will be thrown.

### Parameters

- label? `string` The new label of the disk, or `nil` to clear.

### Throws

-

If the disk's label can't be changed.

### hasData()
Returns whether a disk with data is inserted.

### Returns

- `boolean` Whether a disk with data is inserted.

### getMountPath()
Returns the mount path for the inserted disk.

### Returns

- `string` | nil The mount path for the disk, or `nil` if no data disk is inserted.

### hasAudio()
Returns whether a disk with audio is inserted.

### Returns

- `boolean` Whether a disk with audio is inserted.

### getAudioTitle()
Returns the title of the inserted audio disk.

### Returns

- `string` | nil | false The title of the audio, `false` if no disk is inserted, or `nil` if the disk has no audio.

### playAudio()
Plays the audio in the inserted disk, if available.

### stopAudio()
Stops any audio that may be playing.

### See also

- `playAudio`

### ejectDisk()
Ejects any disk that may be in the drive.

### getDiskID()
Returns the ID of the disk inserted in the drive.

### Returns

- `number` | nil The ID of the disk in the drive, or `nil` if no disk with an ID is inserted.

### Changes

- New in version 1.4
