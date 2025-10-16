# title-focus

This plugin originated from my personal practice of using markdown files for various writings, typically starting headings with `##`. To facilitate management and quickly jump to a specific heading—by identifying all `##` headings across multiple markdown files and selecting the desired one to jump to—this plugin was created.

## How to Use

First, **clone this repository** into a directory within Neovim's runtime path. For example, my personal plugin folder is: `C:\Users\WH\AppData\Local\nvim\pack\myown\start`.

Next, **configure your `init.lua` file** as shown below. There are two main parameters: the directory where your markdown files are stored, and the keybinding to open the search window.

```lua
require('title-focus').setup({
    posts_path = "D:/anaouse.github.io/posts",  -- dir stores md files path
    keymaps = {
        open = "<F4>",
    }
})
```

After opening the search window using the configured keybinding, the plugin will retrieve all titles starting with ` ##  ` from the markdown files located in the specified path.

  * Use the **up and down arrow keys** in the lower window to select a title.
  * Press **Enter** to open the corresponding file in a **new tab** and jump the cursor to that title.
  * Press **`i`** or **`a`** to enter insert mode, which will return the focus to the input field, allowing you to **type words to search and filter** the titles.
  * Finally, press **Esc** to close the entire window.


