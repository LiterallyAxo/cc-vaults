<!-- fetched from https://cccbridge.kleinbox.dev/guides/positioningAnimatronicAnalog/ -->
# CC:C Bridge / guides-positioningAnimatronicAnalog

# Using Animatronics: The Analog Way

Animatronics are normally controlled by a Computer. However, people like map makers might not want to use yet another Computer, just to position it once. Others might not know how to use CC: Tweaked at all and can't use it because of that.

But the Animatronic can actually be used without a Computer using Minecraft commands.

## Viewing Rotation

To take a look at the current pose of an Animatronic, simply run the following command in Minecraft:

```lua
data get block <x> <y> <z>

```

 The coordinates here represent where the Animatronic is standing.

## Changing Rotation

To change the rotation of a body part, you can run a similar command in Minecraft:

```lua
data modify block <x> <y> <z> <body_part> set value [<rot_x>, <rot_y>, <rot_z>]

```

- Again, the coordinates here represent where the Animatronic is standing.
- `<body_part>` is either `"leftArmPose"`, `"rightArmPose"`, `"bodyPose"` or `"headPose"`.
- `[<rot_x>, <rot_y>, <rot_z>]` is the new rotation of that body part.

After entering this command, you can see how the Animatronic applies that position.
