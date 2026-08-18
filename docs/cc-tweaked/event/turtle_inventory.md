<!-- fetched from https://tweaked.cc/event/turtle_inventory.html -->
# event / turtle inventory

# turtle_inventory

The `turtle_inventory` event is fired when a turtle's inventory is changed.

## Return values

- `string`: The event name.

## Example

Prints a message when the inventory is changed:

```lua
while true do
 os.pullEvent("turtle_inventory")
 print("The inventory was changed.")
end
```
