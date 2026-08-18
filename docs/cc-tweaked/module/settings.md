<!-- fetched from https://tweaked.cc/module/settings.html -->
# module / settings

# settings

Read and write configuration options for CraftOS and your programs.

When a computer starts, it reads the current value of settings from the `/.settings` file. These values then may be read or modified.

Any modifications to a settings, either from loading a file (`settings.load`) or directly setting it (`settings.set`, `settings.unset`) will queue a `setting_changed` event. This may be listened to by programs to reload settings while running.

##### ⚠ warning

Calling `settings.set` does not update the settings file by default. You must call `settings.save` to persist values.

### Usage

-

Define an basic setting `123` and read its value.

```lua
settings.define("my.setting", {
 description = "An example setting",
 default = 123,
 type = "number",
})
print("my.setting = " .. settings.get("my.setting")) -- 123
```

You can then use the `set` program to change its value (e.g. `set my.setting 456`), and then re-run the `example` program to check it has changed.

### See also

- `setting_changed`

### Changes

- New in version 1.78
- Changed in version 1.87.0: `setting_changed` event is now queued when settings are changed.

| define(name [, options]) | Define a new setting, optional specifying various properties about it. |
| undefine(name) | Remove a definition of a setting. |
| set(name, value) | Set the value of a setting. |
| get(name [, default]) | Get the value of a setting. |
| getDetails(name) | Get details about a specific setting. |
| unset(name) | Remove the value of a setting, setting it to the default. |
| clear() | Resets the value of all settings. |
| getNames() | Get the names of all currently defined settings. |
| load([path=".settings"]) | Load settings from the given file. |
| save([path=".settings"]) | Save settings to the given file. |

### define(name [, options])
Define a new setting, optional specifying various properties about it.

While settings do not have to be added before being used, doing so allows you to provide defaults and additional metadata.

### Parameters

- name `string` The name of this option
- options? { description? = `string`, default? = `any`, type? = `string` }

Options for this setting. This table accepts the following fields:

 - `description`: A description which may be printed when running the `set` program.
 - `default`: A default value, which is returned by `settings.get` if the setting has not been changed.
 - `type`: Require values to be of this type. Setting the value to another type will error. Must be one of: `"number"`, `"string"`, `"boolean"`, or `"table"`.

### Changes

- New in version 1.87.0

### undefine(name)
Remove a definition of a setting.

If a setting has been changed, this does not remove its value. Use `settings.unset` for that.

### Parameters

- name `string` The name of this option

### Changes

- New in version 1.87.0

### set(name, value)
Set the value of a setting.

##### ⚠ warning

Calling `settings.set` does not update the settings file by default. You must call `settings.save` to persist values.

### Parameters

- name `string` The name of the setting to set
- value The setting's value. This cannot be `nil`, and must be serialisable by `textutils.serialize`.

### Throws

-

If this value cannot be serialised

### See also

- `settings.unset`

### get(name [, default])
Get the value of a setting.

### Parameters

- name `string` The name of the setting to get.
- default? The value to use should there be pre-existing value for this setting. If not given, it will use the setting's default value if given, or `nil` otherwise.

### Returns

- The setting's, or the default if the setting has not been changed.

### Changes

- Changed in version 1.87.0: Now respects default value if pre-defined and `default` is unset.

### getDetails(name)
Get details about a specific setting.

### Parameters

- name `string` The name of the setting to get.

### Returns

- { description? = `string`, default? = `any`, type? = `string`, value? = `any` } Information about this setting. This includes all information from `settings.define`, as well as this setting's value.

### Changes

- New in version 1.87.0

### unset(name)
Remove the value of a setting, setting it to the default.

`settings.get` will return the default value until the setting's value is set, or the computer is rebooted.

### Parameters

- name `string` The name of the setting to unset.

### See also

- `settings.set`
- `settings.clear`

### clear()
Resets the value of all settings. Equivalent to calling `settings.unset` on every setting.

### See also

- `settings.unset`

### getNames()
Get the names of all currently defined settings.

### Returns

- { `string` } An alphabetically sorted list of all currently-defined settings.

### load([path=".settings"])
Load settings from the given file.

Existing settings will be merged with any pre-existing ones. Conflicting entries will be overwritten, but any others will be preserved.

### Parameters

- path? `string` = `".settings"` The file to load from.

### Returns

- `boolean` Whether settings were successfully read from this file. Reasons for failure may include the file not existing or being corrupted.

### See also

- `settings.save`

### Changes

- Changed in version 1.87.0: `path` is now optional.

### save([path=".settings"])
Save settings to the given file.

This will entirely overwrite the pre-existing file. Settings defined in the file, but not currently loaded will be removed.

### Parameters

- path? `string` = `".settings"` The path to save settings to.

### Returns

- `boolean` If the settings were successfully saved.

### See also

- `settings.load`

### Changes

- Changed in version 1.87.0: `path` is now optional.
