<!-- fetched from https://tweaked.cc/event/file_transfer.html -->
# event / file transfer

# file_transfer

The `file_transfer` event is queued when a user drags-and-drops a file on an open computer.

This event contains a single argument of type `TransferredFiles`, which can be used to get the files to be transferred. Each file returned is a binary file handle with an additional getName method.

## Return values

- `string`: The event name
- `TransferredFiles`: The list of transferred files.

## Example

Waits for a user to drop files on top of the computer, then prints the list of files and the size of each file.

```lua
local _, files = os.pullEvent("file_transfer")
for _, file in ipairs(files.getFiles()) do
 -- Seek to the end of the file to get its size, then go back to the beginning.
 local size = file.seek("end")
 file.seek("set", 0)

 print(file.getName() .. " " .. size)
end
```

## Example

Save each transferred file to the computer's storage.

```lua
local _, files = os.pullEvent("file_transfer")
for _, file in ipairs(files.getFiles()) do
 local handle = fs.open(file.getName(), "wb")
 handle.write(file.readAll())

 handle.close()
 file.close()
end
```

### Changes

- New in version 1.101.0

### Types

### TransferredFiles

A list of files that have been transferred to this computer.

### TransferredFiles.getFiles()
All the files that are being transferred to this computer.

### Returns

- { `file_transfer.TransferredFile`... } The list of files.

### TransferredFile

A binary file handle that has been transferred to this computer.

This inherits all methods of binary file handles, meaning you can use the standard read functions to access the contents of the file.

### See also

- `fs.ReadHandle`

### TransferredFile.getName()
Get the name of this file being transferred.

### Returns

- `string` The file's name.
