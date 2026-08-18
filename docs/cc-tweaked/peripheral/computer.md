<!-- fetched from https://tweaked.cc/peripheral/computer.html -->
# peripheral / computer

# computer

A computer or turtle wrapped as a peripheral.

This allows for basic interaction with adjacent computers. Computers wrapped as peripherals will have the type `computer` while turtles will be `turtle`.

| turnOn() | Turn the other computer on. |
| shutdown() | Shutdown the other computer. |
| reboot() | Reboot or turn on the other computer. |
| getID() | Get the other computer's ID. |
| isOn() | Determine if the other computer is on. |
| getLabel() | Get the other computer's label. |

### turnOn()
Turn the other computer on.

### shutdown()
Shutdown the other computer.

### reboot()
Reboot or turn on the other computer.

### getID()
Get the other computer's ID.

### Returns

- `number` The computer's ID.

### See also

- `os.getComputerID` To get your computer's ID.

### isOn()
Determine if the other computer is on.

### Returns

- `boolean` If the computer is on.

### getLabel()
Get the other computer's label.

### Returns

- `string` | nil The computer's label.

### See also

- `os.getComputerLabel` To get your label.
