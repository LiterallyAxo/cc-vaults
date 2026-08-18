<!-- fetched from https://tweaked.cc/ -->
# CC: Tweaked index

#

CC: Tweaked is a mod for Minecraft which adds programmable computers, turtles and more to the game. A fork of the much-beloved ComputerCraft, it continues its legacy with improved performance and stability, along with a wealth of new features.

CC: Tweaked can be installed from Modrinth. It runs on both Minecraft Forge and Fabric.

## Features

Controlled using the Lua programming language, CC: Tweaked's computers provides all the tools you need to start writing code and automating your Minecraft world.

While computers are incredibly powerful, they're rather limited by their inability to move about. Turtles are the solution here. They can move about the world, placing and breaking blocks, swinging a sword to protect you from zombies, or whatever else you program them to!

Not all problems can be solved with a pickaxe though, and so CC: Tweaked also provides a bunch of additional peripherals for your computers. You can play a tune with speakers, display text or images on a monitor, connect all your computers together with modems, and much more.

Computers can now also interact with inventories such as chests, allowing you to build complex inventory and item management systems.

## Getting Started

While ComputerCraft is lovely for both experienced programmers and for people who have never coded before, it can be a little daunting getting started. Thankfully, there's several fantastic tutorials out there:

- Direwolf20's ComputerCraft tutorials
- Sethbling's ComputerCraft series
- Lyqyd's Computer Basics 1

Once you're a little more familiar with the mod, the sidebar and links below provide more detailed documentation on the various APIs and peripherals provided by the mod.

## Community
 If you need help getting started with CC: Tweaked, want to show off your latest project, or just want to chat about ComputerCraft, do check out our GitHub discussions page! There's also a fairly populated, albeit quiet IRC channel on EsperNet, if that's more your cup of tea. You can join `#computercraft` through your desktop client, or online using KiwiIRC.

## Get Involved

CC: Tweaked lives on GitHub. If you've got any ideas, feedback or bugs please do create an issue.

## Globals

| _G | Functions in the global environment, defined in `bios.lua`. |
| colors | Constants and functions for colour values, suitable for working with `term` and `redstone`. |
| colours | An alternative version of `colors` for lovers of British spelling. |
| commands | Execute Minecraft commands and gather data from the results from a command computer. |
| disk | Interact with disk drives. |
| fs | Interact with the computer's files and filesystem, allowing you to manipulate files, directories and paths. |
| gps | Use modems to locate the position of the current turtle or computers. |
| help | Find help files on the current computer. |
| http | Make HTTP requests, sending and receiving data to a remote web server. |
| io | Emulates Lua's standard io library. |
| keys | Constants for all keyboard "key codes", as queued by the `key` event. |
| multishell | Multishell allows multiple programs to be run at the same time. |
| os | The `os` API allows interacting with the current computer. |
| paintutils | Utilities for drawing more complex graphics, such as pixels, lines and images. |
| parallel | A simple way to run several functions at once. |
| peripheral | Find and control peripherals attached to this computer. |
| pocket | Control the current pocket computer, adding or removing upgrades. |
| rednet | Communicate with other computers by using modems. |
| redstone | Get and set redstone signals adjacent to this computer. |
| settings | Read and write configuration options for CraftOS and your programs. |
| shell | The shell API provides access to CraftOS's command line interface. |
| term | Interact with a computer's terminal or monitors, writing text and drawing ASCII graphics. |
| textutils | Helpful utilities for formatting and manipulating strings. |
| turtle | Turtles are a robotic device, which can break and place blocks, attack mobs, and move about the world. |
| vector | A basic 3D vector type and some common vector operations. |
| window | A terminal redirect occupying a smaller area of an existing terminal. |

## Modules

| cc.audio.dfpwm | Convert between streams of DFPWM audio data and a list of amplitudes. |
| cc.base64 | The `cc.base64` module provides functions for converting binary data to and from Base64. |
| cc.completion | A collection of helper methods for working with input completion, such as that require by `_G.read`. |
| cc.expect | The `cc.expect` library provides helper functions for verifying that function arguments are well-formed and of the correct type. |
| cc.image.nft | Read and draw nft ("Nitrogen Fingers Text") images. |
| cc.pretty | A pretty printer for rendering data structures in an aesthetically pleasing manner. |
| cc.require | A pure Lua implementation of the builtin `require` function and `package` library. |
| cc.shell.completion | A collection of helper methods for working with shell completion. |
| cc.strings | Various utilities for working with strings and text. |

## Peripherals

| command | This peripheral allows you to interact with command blocks. |
| computer | A computer or turtle wrapped as a peripheral. |
| drive | Disk drives are a peripheral which allow you to read and write to floppy disks and other "mountable media" (such as computers or turtles). |
| modem | Modems allow you to send messages between computers over long distances. |
| monitor | Monitors are a block which act as a terminal, displaying information on one side. |
| printer | The printer peripheral allows printing text onto pages. |
| redstone_relay | The redstone relay is a peripheral that allows reading and outputting redstone signals. |
| speaker | The speaker peripheral allows your computer to play notes and other sounds. |

## Generic Peripherals

| energy_storage | Methods for interacting with blocks which store energy. |
| fluid_storage | Methods for interacting with tanks and other fluid storage blocks. |
| inventory | Methods for interacting with inventories. |

## Events

| alarm | The `alarm` event is fired when an alarm started with `os.setAlarm` completes. |
| char | The `char` event is fired when a character is typed on the keyboard. |
| computer_command | The `computer_command` event is fired when the `/computercraft queue` command is run for the current command computer. |
| disk | The `disk` event is fired when a disk is inserted into an adjacent or networked disk drive. |
| disk_eject | The `disk_eject` event is fired when a disk is removed from an adjacent or networked disk drive. |
| file_transfer | The `file_transfer` event is queued when a user drags-and-drops a file on an open computer. |
| http_check | The `http_check` event is fired when a URL check finishes. |
| http_failure | The `http_failure` event is fired when an HTTP request fails. |
| http_success | The `http_success` event is fired when an HTTP request returns successfully. |
| key | This event is fired when any key is pressed while the terminal is focused. |
| key_up | Fired whenever a key is released (or the terminal is closed while a key was being pressed). |
| modem_message | The `modem_message` event is fired when a message is received on an open channel on any `modem`. |
| monitor_resize | The `monitor_resize` event is fired when an adjacent or networked monitor's size is changed. |
| monitor_touch | The `monitor_touch` event is fired when an adjacent or networked Advanced Monitor is right-clicked. |
| mouse_click | This event is fired when the terminal is clicked with a mouse. |
| mouse_drag | This event is fired every time the mouse is moved while a mouse button is being held. |
| mouse_scroll | This event is fired when a mouse wheel is scrolled in the terminal. |
| mouse_up | This event is fired when a mouse button is released or a held mouse leaves the computer's terminal. |
| paste | The `paste` event is fired when text is pasted into the computer through Ctrl-V (or ⌘V on Mac). |
| peripheral | The `peripheral` event is fired when a peripheral is attached on a side or to a modem. |
| peripheral_detach | The `peripheral_detach` event is fired when a peripheral is detached from a side or from a modem. |
| rednet_message | The `rednet_message` event is fired when a message is sent over Rednet. |
| redstone | The `redstone` event is fired whenever any redstone inputs on the computer or relay change. |
| setting_changed | The `setting_changed` event is fired when a setting is modified with the `settings` API. |
| speaker_audio_empty | Return Values |
| task_complete | The `task_complete` event is fired when an asynchronous task completes. |
| term_resize | The `term_resize` event is fired when the main terminal is resized. |
| terminate | The `terminate` event is fired when Ctrl-T is held down. |
| timer | The `timer` event is fired when a timer started with `os.startTimer` completes. |
| turtle_inventory | The `turtle_inventory` event is fired when a turtle's inventory is changed. |
| websocket_closed | The `websocket_closed` event is fired when an open WebSocket connection is closed. |
| websocket_failure | The `websocket_failure` event is fired when a WebSocket connection request fails. |
| websocket_message | The `websocket_message` event is fired when a message is received on an open WebSocket connection. |
| websocket_success | The `websocket_success` event is fired when a WebSocket connection request returns successfully. |

## Guides

| Setting up GPS | The `gps` API allows a computer to find its current position using a wireless modem. |
| Allowing access to local IPs | By default, ComputerCraft blocks access to local IP addresses for security. |
| Playing audio with speakers | CC: Tweaked's speaker peripheral provides a powerful way to play any audio you like with the `speaker.playAudio` method. |
| Running programs on computer startup | It's often useful to automatically start running a program when a computer is turned on, such as when running a GPS host... |
| Reusing code with require | A library is a collection of useful functions and other definitions which is stored separately to your main program. |

## Reference

| Block details | Several functions in CC: Tweaked, such as `turtle.inspect` and `commands.getBlockInfo` provide a way to get information about a block in the world. |
| Incompatibilities between versions | CC: Tweaked tries to remain as compatible between versions as possible, meaning most programs written for older versions... |
| The /computercraft command | CC: Tweaked provides a `/computercraft` command for server owners to manage running computers on a server. |
| Entity details | Some functions in CC: Tweaked (such as `commands.getEntities`) provide a way to get information about an entity. |
| CraftOS's exception protocol | By default, Lua represents errors are plain strings. |
| Lua 5.2/5.3 features in CC: Tweaked | CC: Tweaked is based off of the Cobalt Lua runtime, which uses Lua 5. |
| Item details | Several functions in CC: Tweaked, such as `turtle.getItemDetail` and `inventory.getItemDetail` provide a way to get information about an item stack. |
| Computer startup | When a computer turns on, it searches for files to run as part of the startup process. |
