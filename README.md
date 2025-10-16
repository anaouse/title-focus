# title-focus

[README-en.md](./README-en.md)

这个插件出现的原因是因为我个人使用markdown文件写各种东西的时候一般都是使用`##`作为一个标题的开头,然后为了方便管理跳转到特定的开头,也就是识别很多个markdown文件中所有的`##`并选择跳转到对于的末尾,就有了这个插件

## how to use

把本仓库git clone到neovim的runtimepath文件夹下,我是`C:\Users\WH\AppData\Local\nvim\`,这其中有一个我存放自己的插件的文件夹:`C:\Users\WH\AppData\Local\nvim\pack\myown\start`

然后配置`init.lua`文件如下:

就两个参数,一个是存放md文件的文件夹,一个是打开搜索窗口的快捷键

```lua
require('title-focus').setup({
    posts_path = "D:/anaouse.github.io/posts",  -- dir stores md files path
    keymaps = {
        open = "<F4>",
    }
})
```

使用以上设置的参数打开搜索窗后,可以获得文件路径下的所有md文件中`## `开头的标题.

* 使用上下方向键在下方窗口选择标题,enter选中后就会用新的tab打开对应文件并跳转光标
* `i`或者`a`进入插入模式后就会回到输入栏,输入词语可以搜索过滤标题
* 最后使用esc关闭整个窗口
