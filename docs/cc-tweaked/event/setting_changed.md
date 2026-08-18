<!-- fetched from https://tweaked.cc/event/setting_changed.html -->
# event / setting changed

# setting_changed

The `setting_changed` event is fired when a setting is modified with the `settings` API.

## Return Values

- `string`: The event name.
- `string`: The name of the setting that was changed.
- `any`: The value the setting was set to.
- `any`: The previous value of the setting.

## Example

Update a setting, and then wait for the corresponding `setting_changed` event.

```lua
settings.set("my.setting", 123)
print(os.pullEvent("setting_changed"))
```

### See also

- `settings`
