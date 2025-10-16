-- title_focus\lua\title_focus\init.lua
local M={}

local config={
	posts_path = "",
	keymap = {
		open = nil,
	}
}

-- 获取所有md文件,现在按照LRU编辑顺序扫描,之后可以改
local function scan_md_files(root_path)
	-- arg3不自动补全后缀, arg4返回列表or字符串
	local files=vim.fn.globpath(root_path, '**/*.md', true, true)
	local file_list={}
	for _, filepath in ipairs(files) do
		local mtime=vim.fn.getftime(filepath)
		table.insert(file_list, {
			path=filepath,
			mtime=mtime,
		})
	end

	table.sort(file_list, 
		function(a, b)
			return a.mtime>b.mtime
		end
	)

	local sorted_files={}
	for _, item in ipairs(file_list) do
		table.insert(sorted_files, item.path)
	end

	return sorted_files
end

-- 从md文件中提取标题
local function extract_titles(filepath)
	local titles={}
	local lines=vim.fn.readfile(filepath)
  local total_lines=#lines
	local file_name=vim.fn.fnamemodify(filepath, ':t')
	for i, line in ipairs(lines) do
		local title=line:match('^##%s+(.+)$')
		if title then
			table.insert(titles,{
				title=title,
				filepath=filepath,
				file_name=file_name,
				line_num=i,
				jump_line=nil,
			})
		end
	end

	for i=1, #titles do
		if i < #titles then
			titles[i].jump_line=titles[i+1].line_num-1
		else
			titles[i].jump_line = total_lines
		end
	end

	return titles
end

-- 得到所有标题以及它们的信息
function M.get_all_titles()
	if vim.fn.isdirectory(config.posts_path) == 0 then
		vim.notify('posts directory not found', vim.log.levels.ERROR)
		return {}
	end
	
	local md_files=scan_md_files(config.posts_path)
	if #md_files == 0 then
		vim.notify('no md files in the directory', vim.log.levels.WARN)
		return {}
	end

	local all_titles={}
	for _, filepath in ipairs(md_files) do
		local titles = extract_titles(filepath)
		vim.list_extend(all_titles, titles)
	end
	
	return all_titles

end

-- 新的tab打开一个文件并跳转,现在还不会智能选择已有的相同tab,如果需要后面再改
function M.jump_to_title(title_info)
	vim.cmd('tabnew ' .. vim.fn.fnameescape(title_info.filepath))
	vim.api.nvim_win_set_cursor(0, {title_info.jump_line, 0})
	vim.cmd('normal! zz')
end

-- 悬浮窗的状态
local state = {
	search_buf=nil,
	search_win=nil,
	results_buf=nil,
	results_win=nil,
	all_titles={},
	filtered_titles={},
}

-- 关闭窗口
local function close_float()
	if state.search_win and vim.api.nvim_win_is_valid(state.search_win) then
		vim.api.nvim_win_close(state.search_win, true)
	end
	if state.results_win and vim.api.nvim_win_is_valid(state.results_win) then
		vim.api.nvim_win_close(state.results_win, true)
	end
	vim.cmd('stopinsert')
	state.results_buf=nil 
	state.search_buf=nil 
	state.search_win=nil 
	state.results_win=nil 
end

-- 过滤标题
local function filter_titles(query)
	if query == '' then
		state.filtered_titles=state.all_titles
	else
		state.filtered_titles={}
		local lower_query=query:lower()
		for _, title_info in ipairs(state.all_titles) do
			-- 从1开始, true即为文本而不是pattern
			if title_info.title:lower():find(lower_query, 1, true) then
				table.insert(state.filtered_titles, title_info)
			end
		end
	end
end

-- 更新过滤后的标题
local function update_results()
	if not state.results_buf or not	vim.api.nvim_buf_is_valid(state.results_buf) then
		return
	end
	local lines={}
	for i, title_info in ipairs(state.filtered_titles) do
		lines[i]=string.format('[%d] %s | %s', i, title_info.title, title_info.file_name)
	end

	if #lines==0 then
		lines={' 没有匹配的标题'}
	end
	-- 可编辑然后写入过滤后的结果然后禁止写入
	vim.api.nvim_set_option_value('modifiable', true, {buf = state.results_buf})
	vim.api.nvim_buf_set_lines(state.results_buf, 0, -1, false, lines)
	vim.api.nvim_set_option_value('modifiable', false, {buf = state.results_buf})
end

-- 搜索输入改变了就filter一次
local function on_filter_change()
	local lines = vim.api.nvim_buf_get_lines(state.search_buf, 0, 1, false)
	local query = lines[1] or ''
	filter_titles(query)
	update_results()
end

-- 选择并跳转
local function select_title()
	if not state.results_buf or #state.filtered_titles==0 then
		return
	end
	-- 当前光标
	local cursor_line=vim.api.nvim_win_get_cursor(state.results_win)[1]
	local selected=state.filtered_titles[cursor_line]

	if selected then
		close_float()
		M.jump_to_title(selected)
	end
end

function M.show_float()
	close_float()
	state.all_titles=M.get_all_titles()
	if #state.all_titles==0 then
		return
	end
	state.filtered_titles=state.all_titles
	local width=math.floor(vim.opt.columns:get() * 0.8)
	local height=math.floor(vim.opt.lines:get() * 0.6)
	local row=math.floor((vim.opt.lines:get() - height) / 2)
	local col=math.floor((vim.opt.columns:get() - width) / 2)
	-- 创建搜索缓冲区
	state.search_buf = vim.api.nvim_create_buf(false, false)
	vim.api.nvim_buf_set_option(state.search_buf, 'buftype', 'nofile')
	vim.api.nvim_buf_set_option(state.search_buf, 'bufhidden', 'wipe')
  -- 创建结果展示区
	state.results_buf = vim.api.nvim_create_buf(false, true)
	vim.api.nvim_buf_set_option(state.results_buf, 'buftype', 'nofile')
	vim.api.nvim_buf_set_option(state.results_buf, 'bufhidden', 'wipe')
	vim.api.nvim_buf_set_option(state.results_buf, 'modifiable', true)
	-- 搜索框窗口配置
	local search_opts = {
		relative = 'editor',
		width = width,
		height = 1,
		row = row,
		col = col,
		style = 'minimal',
		border = 'rounded',
		title = ' search bar ',
		title_pos = 'center',
	}

	-- 结果窗口配置
	local results_opts = {
		relative = 'editor',
		width = width,
		height = height - 3,
		row = row + 2,
		col = col,
		style = 'minimal',
		border = 'rounded',
		title = string.format('result'),
		title_pos = 'center',
	}

	-- 创建窗口
	state.search_win = vim.api.nvim_open_win(state.search_buf, true, search_opts)
	state.results_win = vim.api.nvim_open_win(state.results_buf, false, results_opts)

	-- 设置窗口选项
	vim.api.nvim_win_set_option(state.search_win, 'winhl', 'Normal:Normal,FloatBorder:FloatBorder')
	vim.api.nvim_win_set_option(state.results_win, 'winhl', 'Normal:Normal,FloatBorder:FloatBorder')
	vim.api.nvim_win_set_option(state.results_win, 'cursorline', true)

	-- 初始化显示
	update_results()

	-- 搜索框按键映射
	local search_opts_map = { noremap = true, silent = true, buffer = state.search_buf }
	vim.keymap.set('i', '<CR>', function()
		-- 切换到结果窗口
		vim.cmd('stopinsert')
		vim.api.nvim_set_current_win(state.results_win)
	end, search_opts_map)

	vim.keymap.set('i', '<Down>', 
		function()
			vim.cmd('stopinsert')
			vim.api.nvim_set_current_win(state.results_win)
		end
		, search_opts_map)

	vim.keymap.set('i', '<Esc>', close_float, search_opts_map)

	-- 结果窗口按键映射
	local results_opts_map = { noremap = true, silent = true, buffer = state.results_buf }
	vim.keymap.set('n', '<CR>', select_title, results_opts_map)
	vim.keymap.set('n', '<Esc>', close_float, results_opts_map)
	vim.keymap.set('n', 'q', close_float, results_opts_map)
	-- 任何会返回搜索框的操作都自动进入插入模式
	vim.keymap.set('n', 'i', function()
		vim.api.nvim_set_current_win(state.search_win)
		vim.cmd('startinsert!')
	end, results_opts_map)
	
	-- 监听搜索框内容变化
	vim.api.nvim_buf_attach(state.search_buf, false, {
		on_lines = function()
			vim.schedule(on_filter_change)
		end,
	})

	-- 启动插入模式
	vim.cmd('startinsert!')
	
end

function M.setup(opts)
	opts = opts or {}
	
	-- 检查必需的配置
	if not opts.posts_path or opts.posts_path == "" then
		vim.notify('TitleFocus setup 错误: 必须配置 posts_path 参数！\n示例: require("title_focus").setup({ posts_path = "/path/to/posts" })', 
			vim.log.levels.ERROR)
		return
	end
	
	-- 合并用户配置
	config = vim.tbl_deep_extend('force', config, opts)
	
	-- 创建命令
	vim.api.nvim_create_user_command('TitleFocus', function()
		M.show_float()
	end, {})
	if config.keymaps and config.keymaps.open then
		vim.keymap.set('n', config.keymaps.open, function()
			M.show_float()
		end, {
			noremap = true,
			silent = true,
		})
	end
end

-- 以下是测试函数
function M.test()
	local titles=M.get_all_titles()
	local total=#titles
	print('Found '..#titles)
	if total==0 then
		return
	end
	local start_index=math.max(total-19, 1)
	for i=start_index, total do
		local t=titles[i]
		print(string.format("[%d] %s (%s:%d)", i, t.title, t.file_name, t.line_num))
	end
end

function M.test_jump()
	print('test jump function, jump to first titles')
	local titles=M.get_all_titles()
  if #titles == 0 then
		print('no title found')
		return
	end
	
	print("jump to: ".. titles[1].title)
	M.jump_to_title(titles[1])

end

-- M.select_title = select_title
return M




