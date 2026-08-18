<!-- fetched from https://tweaked.cc/peripheral/printer.html -->
# peripheral / printer

# printer

The printer peripheral allows printing text onto pages. These pages can then be crafted together into printed pages or books.

Printers require ink (one of the coloured dyes) and paper in order to function. Once loaded, a new page can be started with `newPage`. Then the printer can be used similarly to a normal terminal; text can be written, and the cursor moved. Once all text has been printed, `endPage` should be called to finally print the page.

## Recipes
 Printer

 Printed Pages

 Printed Book

### Usage

-

Print a page titled "Hello" with a small message on it.

```lua
local printer = peripheral.find("printer")

-- Start a new page, or print an error.
if not printer.newPage() then
 error("Cannot start a new page. Do you have ink and paper?")
end

-- Write to the page
printer.setPageTitle("Hello")
printer.write("This is my first page")
printer.setCursorPos(1, 3)
printer.write("This is two lines below.")

-- And finally print the page!
if not printer.endPage() then
 error("Cannot end the page. Is there enough space?")
end
```

### See also

- `cc.strings.wrap` To wrap text before printing it.

| write(text) | Writes text to the current page. |
| getCursorPos() | Returns the current position of the cursor on the page. |
| setCursorPos(x, y) | Sets the position of the cursor on the page. |
| getPageSize() | Returns the size of the current page. |
| newPage() | Starts printing a new page. |
| endPage() | Finalizes printing of the current page and outputs it to the tray. |
| setPageTitle([title]) | Sets the title of the current page. |
| getInkLevel() | Returns the amount of ink left in the printer. |
| getPaperLevel() | Returns the amount of paper left in the printer. |

### write(text)
Writes text to the current page.

### Parameters

- text `string` The value to write to the page.

### Throws

-

If any values couldn't be converted to a string, or if no page is started.

### getCursorPos()
Returns the current position of the cursor on the page.

### Returns

- `number` The X position of the cursor.
- `number` The Y position of the cursor.

### Throws

-

If a page isn't being printed.

### setCursorPos(x, y)
Sets the position of the cursor on the page.

### Parameters

- x `number` The X coordinate to set the cursor at.
- y `number` The Y coordinate to set the cursor at.

### Throws

-

If a page isn't being printed.

### getPageSize()
Returns the size of the current page.

### Returns

- `number` The width of the page.
- `number` The height of the page.

### Throws

-

If a page isn't being printed.

### newPage()
Starts printing a new page.

### Returns

- `boolean` Whether a new page could be started.

### endPage()
Finalizes printing of the current page and outputs it to the tray.

### Returns

- `boolean` Whether the page could be successfully finished.

### Throws

-

If a page isn't being printed.

### setPageTitle([title])
Sets the title of the current page.

### Parameters

- title? `string` The title to set for the page.

### Throws

-

If a page isn't being printed.

### getInkLevel()
Returns the amount of ink left in the printer.

### Returns

- `number` The amount of ink available to print with.

### getPaperLevel()
Returns the amount of paper left in the printer.

### Returns

- `number` The amount of paper available to print with.
