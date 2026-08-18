<!-- fetched from https://tweaked.cc/module/fs.html -->
# module / fs

# fs

Interact with the computer's files and filesystem, allowing you to manipulate files, directories and paths. This includes:

- Reading and writing files: Call `open` to obtain a file "handle", which can be used to read from or write to a file.
- Path manipulation: `combine`, `getName` and `getDir` allow you to manipulate file paths, joining them together or extracting components.
- Querying paths: For instance, checking if a file exists, or whether it's a directory. See `getSize`, `exists`, `isDir`, `isReadOnly` and `attributes`.
- File and directory manipulation: For instance, moving or copying files. See `makeDir`, `move`, `copy` and `delete`.

##### 🛈 note

All functions in the API work on absolute paths, and do not take the current directory into account. You can use `shell.resolve` to convert a relative path into an absolute one.

## Mounts

While a computer can only have one hard drive and filesystem, other filesystems may be "mounted" inside it. For instance, the drive peripheral mounts its disk's contents at `"disk/"`, `"disk1/"`, etc...

You can see which mount a path belongs to with the `getDrive` function. This returns `"hdd"` for the computer's main filesystem (`"/"`), `"rom"` for the rom (`"rom/"`).

Most filesystems have a limited capacity, operations which would cause that capacity to be reached (such as writing an incredibly large file) will fail. You can see a mount's capacity with `getCapacity` and the remaining space with `getFreeSpace`.

| complete(...) | Provides completion for a file or directory name, suitable for use with `_G.read`. |
| find(path) | Searches for files matching a string with wildcards. |
| isDriveRoot(path) | Returns true if a path is mounted to the parent filesystem. |
| list(path) | Returns a list of files in a directory. |
| combine(path, ...) | Combines several parts of a path into one full path, adding separators as needed. |
| getName(path) | Returns the file name portion of a path. |
| getDir(path) | Returns the parent directory portion of a path. |
| getSize(path) | Returns the size of the specified file. |
| exists(path) | Returns whether the specified path exists. |
| isDir(path) | Returns whether the specified path is a directory. |
| isReadOnly(path) | Returns whether a path is read-only. |
| makeDir(path) | Creates a directory, and any missing parents, at the specified path. |
| move(path, dest) | Moves a file or directory from one path to another. |
| copy(path, dest) | Copies a file or directory to a new path. |
| delete(path) | Deletes a file or directory. |
| open(path, mode) | Opens a file for reading or writing at a path. |
| getDrive(path) | Returns the name of the mount that the specified path is located on. |
| getFreeSpace(path) | Returns the amount of free space available on the drive the path is located on. |
| getCapacity(path) | Returns the capacity of the drive the path is located on. |
| attributes(path) | Get attributes about a specific file or folder. |

### complete(...)
Provides completion for a file or directory name, suitable for use with `_G.read`.

When a directory is a possible candidate for completion, two entries are included - one with a trailing slash (indicating that entries within this directory exist) and one without it (meaning this entry is an immediate completion candidate). `include_dirs` can be set to `false` to only include those with a trailing slash.

### Parameters

- path `string` The path to complete.
- location `string` The location where paths are resolved from.
- include_files? `boolean` = `true` When `false`, only directories will be included in the returned list.
- include_dirs? `boolean` = `true` When `false`, "raw" directories will not be included in the returned list.

#### Or

- path `string` The path to complete.
- location `string` The location where paths are resolved from.
- options { include_dirs? = `boolean`, include_files? = `boolean`, include_hidden? = `boolean` }

This table form is an expanded version of the previous syntax. The `include_files` and `include_dirs` arguments from above are passed in as fields.

This table also accepts the following options:

 - `include_hidden`: Whether to include hidden files (those starting with `.`) by default. They will still be shown when typing a `.`.

### Returns

- { `string`... } A list of possible completion candidates.

### Usage

-

Complete files in the root directory.

```lua
read(nil, nil, function(str)
 return fs.complete(str, "", true, false)
end)
```

-

Complete files in the root directory, hiding hidden files by default.

```lua
read(nil, nil, function(str)
 return fs.complete(str, "", {
 include_files = true,
 include_dirs = false,
 include_hidden = false,
 })
end)
```

### Changes

- New in version 1.74
- Changed in version 1.101.0

### find(path)
Searches for files matching a string with wildcards.

This string looks like a normal path string, but can include wildcards, which can match multiple paths:

- "?" matches any single character in a file name.
- "*" matches any number of characters.

For example, `rom/*/command*` will look for any path starting with `command` inside any subdirectory of `/rom`.

Note that these wildcards match a single segment of the path. For instance `rom/*.lua` will include `rom/startup.lua` but not include `rom/programs/list.lua`.

### Parameters

- path `string` The wildcard-qualified path to search for.

### Returns

- { `string`... } A list of paths that match the search string.

### Throws

-

If the supplied path was invalid.

### Usage

-

List all Markdown files in the help folder

```lua
fs.find("rom/help/*.md")
```

### Changes

- New in version 1.6
- Changed in version 1.106.0: Added support for the `?` wildcard.

### isDriveRoot(path)
Returns true if a path is mounted to the parent filesystem.

The root filesystem "/" is considered a mount, along with disk folders and the rom folder.

### Parameters

- path `string` The path to check.

### Returns

- `boolean` If the path is mounted, rather than a normal file/folder.

### Throws

-

If the path does not exist.

### See also

- `getDrive`

### Changes

- New in version 1.87.0

### list(path)
Returns a list of files in a directory.

### Parameters

- path `string` The path to list.

### Returns

- { `string`... } A table with a list of files in the directory.

### Throws

-

If the path doesn't exist.

### Usage

-

List all files under `/rom/`

```lua
local files = fs.list("/rom/")
for i = 1, #files do
 print(files[i])
end
```

### combine(path, ...)
Combines several parts of a path into one full path, adding separators as needed.

### Parameters

- path `string` The first part of the path. For example, a parent directory path.
- ... `string` Additional parts of the path to combine.

### Returns

- `string` The new path, with separators added between parts as needed.

### Throws

-

On argument errors.

### Usage

-

Combine several file paths together

```lua
fs.combine("/rom/programs", "../apis", "parallel.lua")
-- => rom/apis/parallel.lua
```

### Changes

- Changed in version 1.95.0: Now supports multiple arguments.

### getName(path)
Returns the file name portion of a path.

### Parameters

- path `string` The path to get the name from.

### Returns

- `string` The final part of the path (the file name).

### Usage

-

Get the file name of `rom/startup.lua`

```lua
fs.getName("rom/startup.lua")
-- => startup.lua
```

### Changes

- New in version 1.2

### getDir(path)
Returns the parent directory portion of a path.

### Parameters

- path `string` The path to get the directory from.

### Returns

- `string` The path with the final part removed (the parent directory).

### Usage

-

Get the directory name of `rom/startup.lua`

```lua
fs.getDir("rom/startup.lua")
-- => rom
```

### Changes

- New in version 1.63

### getSize(path)
Returns the size of the specified file.

### Parameters

- path `string` The file to get the file size of.

### Returns

- `number` The size of the file, in bytes.

### Throws

-

If the path doesn't exist.

### Changes

- New in version 1.3

### exists(path)
Returns whether the specified path exists.

### Parameters

- path `string` The path to check the existence of.

### Returns

- `boolean` Whether the path exists.

### isDir(path)
Returns whether the specified path is a directory.

### Parameters

- path `string` The path to check.

### Returns

- `boolean` Whether the path is a directory.

### isReadOnly(path)
Returns whether a path is read-only.

### Parameters

- path `string` The path to check.

### Returns

- `boolean` Whether the path cannot be written to.

### makeDir(path)
Creates a directory, and any missing parents, at the specified path.

### Parameters

- path `string` The path to the directory to create.

### Throws

-

If the directory couldn't be created.

### move(path, dest)
Moves a file or directory from one path to another.

Any parent directories are created as needed.

### Parameters

- path `string` The current file or directory to move from.
- dest `string` The destination path for the file or directory.

### Throws

-

If the file or directory couldn't be moved.

### copy(path, dest)
Copies a file or directory to a new path.

Any parent directories are created as needed.

### Parameters

- path `string` The file or directory to copy.
- dest `string` The path to the destination file or directory.

### Throws

-

If the file or directory couldn't be copied.

### delete(path)
Deletes a file or directory.

If the path points to a directory, all of the enclosed files and subdirectories are also deleted.

### Parameters

- path `string` The path to the file or directory to delete.

### Throws

-

If the file or directory couldn't be deleted.

### open(path, mode)
Opens a file for reading or writing at a path.

The `mode` string can be any of the following:

- "r": Read mode.
- "w": Write mode.
- "a": Append mode.
- "r+": Update mode (allows reading and writing), all data is preserved.
- "w+": Update mode, all data is erased.

The mode may also have a "b" at the end, which opens the file in "binary mode". This changes `fs.ReadHandle.read` and `fs.WriteHandle.write` to read/write single bytes as numbers rather than strings.

### Parameters

- path `string` The path to the file to open.
- mode `string` The mode to open the file with.

### Returns

- `table` A file handle object for the file.

#### Or

- nil If the file does not exist, or cannot be opened.
- `string` | nil A message explaining why the file cannot be opened.

### Throws

-

If an invalid mode was specified.

### Usage

-

Read the contents of a file.

```lua
local file = fs.open("/rom/help/intro.txt", "r")
local contents = file.readAll()
file.close()

print(contents)
```

-

Open a file and read all lines into a table. `io.lines` offers an alternative way to do this.

```lua
local file = fs.open("/rom/motd.txt", "r")
local lines = {}
while true do
 local line = file.readLine()

 -- If line is nil then we've reached the end of the file and should stop
 if not line then break end

 lines[#lines + 1] = line
end

file.close()

print(lines[math.random(#lines)]) -- Pick a random line and print it.
```

-

Open a file and write some text to it. You can run `edit out.txt` to see the written text.

```lua
local file = fs.open("out.txt", "w")
file.write("Just testing some code")
file.close() -- Remember to call close, otherwise changes may not be written!
```

### Changes

- Changed in version 1.109.0: Add support for update modes (`r+` and `w+`).
- Changed in version 1.109.0: Opening a file in non-binary mode now uses the raw bytes of the file rather than encoding to UTF-8.

### getDrive(path)
Returns the name of the mount that the specified path is located on.

### Parameters

- path `string` The path to get the drive of.

### Returns

- `string` | nil The name of the drive that the file is on; e.g. `hdd` for local files, or `rom` for ROM files.

### Throws

-

If the path doesn't exist.

### Usage

-

Print the drives of a couple of mounts:

```lua
print("/: " .. fs.getDrive("/"))
print("/rom/: " .. fs.getDrive("rom"))
```

### getFreeSpace(path)
Returns the amount of free space available on the drive the path is located on.

### Parameters

- path `string` The path to check the free space for.

### Returns

- `number` | "unlimited" The amount of free space available, in bytes, or "unlimited".

### Throws

-

If the path doesn't exist.

### See also

- `getCapacity` To get the capacity of this drive.

### Changes

- New in version 1.4

### getCapacity(path)
Returns the capacity of the drive the path is located on.

### Parameters

- path `string` The path of the drive to get.

### Returns

- `number` | nil This drive's capacity. This will be nil for "read-only" drives, such as the ROM or treasure disks.

### Throws

-

If the capacity cannot be determined.

### See also

- `getFreeSpace` To get the free space available on this drive.

### Changes

- New in version 1.87.0

### attributes(path)
Get attributes about a specific file or folder.

The returned attributes table contains information about the size of the file, whether it is a directory, when it was created and last modified, and whether it is read only.

The creation and modification times are given as the number of milliseconds since the UNIX epoch. This may be given to `os.date` in order to convert it to more usable form.

### Parameters

- path `string` The path to get attributes for.

### Returns

- { size = `number`, isDir = `boolean`, isReadOnly = `boolean`, created = `number`, modified = `number` } The resulting attributes.

### Throws

-

If the path does not exist.

### See also

- `getSize` If you only care about the file's size.
- `isDir` If you only care whether a path is a directory or not.

### Changes

- New in version 1.87.0
- Changed in version 1.91.0: Renamed `modification` field to `modified`.
- Changed in version 1.95.2: Added `isReadOnly` to attributes.

### Types

### ReadWriteHandle

A file handle opened for reading and writing with `fs.open`.

### ReadWriteHandle.read([count])
Read a number of bytes from this file.

### Parameters

- count? `number` The number of bytes to read. This may be 0 to determine we are at the end of the file. When absent, a single byte will be read.

### Returns

- nil If we are at the end of the file.

#### Or

- `number` The value of the byte read. This is returned if the file is opened in binary mode and `count` is absent

#### Or

- `string` The bytes read as a string. This is returned when the `count` is given.

### Throws

-

When trying to read a negative number of bytes.

-

If the file has been closed.

### Changes

- Changed in version 1.80pr1: Now accepts an integer argument to read multiple bytes, returning a string instead of a number.

### ReadWriteHandle.readAll()
Read the remainder of the file.

### Returns

- `string` | nil The remaining contents of the file, or `nil` in the event of an error.

### Throws

-

If the file has been closed.

### Changes

- New in version 1.80pr1
- Changed in version 1.109.0: Binary-mode handles are now consistent with non-binary files, and return an empty string at the end of the file, rather than `nil`.

### ReadWriteHandle.readLine([withTrailing])
Read a line from the file.

### Parameters

- withTrailing? `boolean` Whether to include the newline characters with the returned string. Defaults to `false`.

### Returns

- `string` | nil The read line or `nil` if at the end of the file.

### Throws

-

If the file has been closed.

### Changes

- New in version 1.80pr1.9
- Changed in version 1.81.0: `\r` is now stripped.

### ReadWriteHandle.seek([whence [, offset]])
Seek to a new position within the file, changing where bytes are written to. The new position is an offset given by `offset`, relative to a start position determined by `whence`:

- `"set"`: `offset` is relative to the beginning of the file.
- `"cur"`: Relative to the current position. This is the default.
- `"end"`: Relative to the end of the file.

In case of success, `seek` returns the new file position from the beginning of the file.

### Parameters

- whence? `string` Where the offset is relative to.
- offset? `number` The offset to seek to.

### Returns

- `number` The new position.

#### Or

- nil If seeking failed.
- `string` The reason seeking failed.

### Throws

-

If the file has been closed.

### Changes

- New in version 1.80pr1.9
- Changed in version 1.109.0: Now available on all file handles, not just binary-mode handles.

### ReadWriteHandle.write(...)
Write a string or byte to the file.

### Parameters

- contents `string` The string to write.

#### Or

- charcode `number` The byte to write, if the file was opened in binary mode.

### Throws

-

If the file has been closed.

### Changes

- Changed in version 1.80pr1: Now accepts a string to write multiple bytes.

### ReadWriteHandle.writeLine(text)
Write a string of characters to the file, following them with a new line character.

### Parameters

- text `string` The text to write to the file.

### Throws

-

If the file has been closed.

### ReadWriteHandle.flush()
Save the current file without closing it.

### Throws

-

If the file has been closed.

### ReadWriteHandle.close()
Close this file, freeing any resources it uses.

Once a file is closed it may no longer be read or written to.

### Throws

-

If the file has already been closed.

### WriteHandle

A file handle opened for writing by `fs.open`.

### WriteHandle.write(...)
Write a string or byte to the file.

### Parameters

- contents `string` The string to write.

#### Or

- charcode `number` The byte to write, if the file was opened in binary mode.

### Throws

-

If the file has been closed.

### Changes

- Changed in version 1.80pr1: Now accepts a string to write multiple bytes.

### WriteHandle.writeLine(text)
Write a string of characters to the file, following them with a new line character.

### Parameters

- text `string` The text to write to the file.

### Throws

-

If the file has been closed.

### WriteHandle.flush()
Save the current file without closing it.

### Throws

-

If the file has been closed.

### WriteHandle.seek([whence [, offset]])
Seek to a new position within the file, changing where bytes are written to. The new position is an offset given by `offset`, relative to a start position determined by `whence`:

- `"set"`: `offset` is relative to the beginning of the file.
- `"cur"`: Relative to the current position. This is the default.
- `"end"`: Relative to the end of the file.

In case of success, `seek` returns the new file position from the beginning of the file.

### Parameters

- whence? `string` Where the offset is relative to.
- offset? `number` The offset to seek to.

### Returns

- `number` The new position.

#### Or

- nil If seeking failed.
- `string` The reason seeking failed.

### Throws

-

If the file has been closed.

### Changes

- New in version 1.80pr1.9
- Changed in version 1.109.0: Now available on all file handles, not just binary-mode handles.

### WriteHandle.close()
Close this file, freeing any resources it uses.

Once a file is closed it may no longer be read or written to.

### Throws

-

If the file has already been closed.

### ReadHandle

A file handle opened for reading with `fs.open`.

### ReadHandle.read([count])
Read a number of bytes from this file.

### Parameters

- count? `number` The number of bytes to read. This may be 0 to determine we are at the end of the file. When absent, a single byte will be read.

### Returns

- nil If we are at the end of the file.

#### Or

- `number` The value of the byte read. This is returned if the file is opened in binary mode and `count` is absent

#### Or

- `string` The bytes read as a string. This is returned when the `count` is given.

### Throws

-

When trying to read a negative number of bytes.

-

If the file has been closed.

### Changes

- Changed in version 1.80pr1: Now accepts an integer argument to read multiple bytes, returning a string instead of a number.

### ReadHandle.readAll()
Read the remainder of the file.

### Returns

- `string` | nil The remaining contents of the file, or `nil` in the event of an error.

### Throws

-

If the file has been closed.

### Changes

- New in version 1.80pr1
- Changed in version 1.109.0: Binary-mode handles are now consistent with non-binary files, and return an empty string at the end of the file, rather than `nil`.

### ReadHandle.readLine([withTrailing])
Read a line from the file.

### Parameters

- withTrailing? `boolean` Whether to include the newline characters with the returned string. Defaults to `false`.

### Returns

- `string` | nil The read line or `nil` if at the end of the file.

### Throws

-

If the file has been closed.

### Changes

- New in version 1.80pr1.9
- Changed in version 1.81.0: `\r` is now stripped.

### ReadHandle.seek([whence [, offset]])
Seek to a new position within the file, changing where bytes are written to. The new position is an offset given by `offset`, relative to a start position determined by `whence`:

- `"set"`: `offset` is relative to the beginning of the file.
- `"cur"`: Relative to the current position. This is the default.
- `"end"`: Relative to the end of the file.

In case of success, `seek` returns the new file position from the beginning of the file.

### Parameters

- whence? `string` Where the offset is relative to.
- offset? `number` The offset to seek to.

### Returns

- `number` The new position.

#### Or

- nil If seeking failed.
- `string` The reason seeking failed.

### Throws

-

If the file has been closed.

### Changes

- New in version 1.80pr1.9
- Changed in version 1.109.0: Now available on all file handles, not just binary-mode handles.

### ReadHandle.close()
Close this file, freeing any resources it uses.

Once a file is closed it may no longer be read or written to.

### Throws

-

If the file has already been closed.
