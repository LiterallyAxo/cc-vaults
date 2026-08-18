<!-- fetched from https://tweaked.cc/module/pocket.html -->
# module / pocket

# pocket

Control the current pocket computer, adding or removing upgrades.

This API is only available on pocket computers. As such, you may use its presence to determine what kind of computer you are using:

```lua
if pocket then
 print("On a pocket computer")
else
 print("On something else")
end
```

## Recipes
 Pocket Computer

 Advanced Pocket Computer

| equipBack() | Search the player's inventory for another upgrade, replacing the existing one with that item if found. |
| unequipBack() | Remove the pocket computer's current upgrade. |

### equipBack()
Search the player's inventory for another upgrade, replacing the existing one with that item if found.

This inventory search starts from the player's currently selected slot, allowing you to prioritise upgrades.

### Returns

- `boolean` If an item was equipped.
- `string` | nil The reason an item was not equipped.

### unequipBack()
Remove the pocket computer's current upgrade.

### Returns

- `boolean` If the upgrade was unequipped.
- `string` | nil The reason an upgrade was not unequipped.
