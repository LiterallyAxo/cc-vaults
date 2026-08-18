<!-- fetched from https://tweaked.cc/event/http_check.html -->
# event / http check

# http_check

The `http_check` event is fired when a URL check finishes.

This event is normally handled inside `http.checkURL`, but it can still be seen when using `http.checkURLAsync`.

## Return Values

- `string`: The event name.
- `string`: The URL requested to be checked.
- `boolean`: Whether the check succeeded.
- `string`|`nil`: If the check failed, a reason explaining why the check failed.

### See also

- `http.checkURLAsync` To check a URL asynchronously.
