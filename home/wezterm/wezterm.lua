-- WezTerm Configuration

local wezterm = require("wezterm")
-- local act = wezterm.action

local config = wezterm.config_builder()

local is_macos = wezterm.target_triple:lower():find("darwin") ~= nil
local is_linux = wezterm.target_triple:lower():find("linux") ~= nil

-- Linux/Wayland specific settings from original config
if is_linux then
	config.enable_wayland = true
	config.use_ime = true
end

-- ────────────────────────────────
--  Graphics
-- ────────────────────────────────
config.max_fps = 120

-- ────────────────────────────────
--  Font
-- ────────────────────────────────
config.font = wezterm.font_with_fallback({
	{ family = "JetBrainsMono Nerd Font Mono", weight = "Regular" },
	{ family = "JetBrainsMono Nerd Font Mono", weight = "Bold", italic = true },
	is_macos and "Apple Color Emoji" or "Noto Color Emoji",
})
config.font_size = 13
config.line_height = 1

-- ────────────────────────────────
--  Color Scheme
-- ────────────────────────────────
config.color_scheme = "rose-pine-moon"
-- Bold & italic rendering
config.bold_brightens_ansi_colors = true

-- ────────────────────────────────
--  Window
-- ────────────────────────────────
config.window_background_opacity = 1.0
config.background = {
	{
		source = { File = wezterm.config_dir .. "/backgrounds/centered_cyber.png" },
		opacity = 0.95,
		hsb = { brightness = 1, saturation = 1 },
	},
}
if is_macos then
	config.macos_window_background_blur = 50 -- native macOS blur
	config.window_decorations = "INTEGRATED_BUTTONS|RESIZE"
else
	config.window_decorations = "TITLE|RESIZE"
end
config.window_frame = {
	font_size = 12,
	-- active_titlebar_bg = '#1e1e2e',
	-- inactive_titlebar_bg = '#1e1e2e',
}

-- ────────────────────────────────
--  Tab Bar
-- ────────────────────────────────
config.enable_tab_bar = true
config.use_fancy_tab_bar = true
config.hide_tab_bar_if_only_one_tab = false
config.colors = {
	tab_bar = {
		-- background = '#1e1e2e',
		active_tab = { bg_color = "#cba6f7", fg_color = "#1e1e2e", intensity = "Bold" },
	},
}

-- ────────────────────────────────
--  Cursor
-- ────────────────────────────────
config.default_cursor_style = "BlinkingBar"
config.cursor_blink_rate = 500

-- ────────────────────────────────
--  Keybindings (macOS CMD shortcuts)
-- ────────────────────────────────
config.keys = {
	-- Cmd + Left: Về đầu dòng (Ctrl+A)
	{ key = "LeftArrow", mods = "CMD", action = wezterm.action.SendKey({ key = "a", mods = "CTRL" }) },
	-- Cmd + Right: Về cuối dòng (Ctrl+E)
	{ key = "RightArrow", mods = "CMD", action = wezterm.action.SendKey({ key = "e", mods = "CTRL" }) },
	-- Cmd + Backspace / Delete: Xóa về đầu dòng (Ctrl+U)
	{ key = "Backspace", mods = "CMD", action = wezterm.action.SendKey({ key = "u", mods = "CTRL" }) },
}

-- ────────────────────────────────
--  Hyperlink Rules & URI Handler
-- ────────────────────────────────
config.hyperlink_rules = wezterm.default_hyperlink_rules()

-- Match IPv4 addresses with or without port (e.g., 127.0.0.1:8080 or 192.168.1.1)
table.insert(config.hyperlink_rules, {
	regex = [[\b(\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3})(?::(\d+))?\b]],
	format = "ip-link://$1:$2",
})

-- Match file paths with line numbers or ranges (e.g. src/main.rs:12, src/main.rs:12-30)
table.insert(config.hyperlink_rules, {
	regex = [[(?:^|[\s"'`(<\[{])((?:[a-zA-Z0-9_.~/-]+/)?(?:[a-zA-Z0-9_.-]+)):(\d+(?:-\d+)?)\b]],
	format = "file-line://$1:$2",
})

-- Match file paths with common extensions
table.insert(config.hyperlink_rules, {
	regex = [[(?:^|[\s"'`(<\[{])((?:[a-zA-Z0-9_.~/-]+/)?(?:[a-zA-Z0-9_.-]+)\.[a-zA-Z0-9_]+)\b]],
	format = "file-only://$1",
})

-- Match dotfiles (e.g. .bashrc, ~/.bashrc, .env)
table.insert(config.hyperlink_rules, {
	regex = [[(?:^|[\s"'`(<\[{])((?:[a-zA-Z0-9_.~/-]+/)?\.[a-zA-Z0-9_.-]+)\b]],
	format = "file-only://$1",
})

-- Helper to dynamically locate the herdr binary
local herdr_bin = (function()
	local success, stdout, stderr = wezterm.run_child_process({"sh", "-lc", "command -v herdr"})
	if success and stdout then
		local path = stdout:gsub("%s+$", "")
		if path ~= "" then
			return path
		end
	end
	return "herdr"
end)()
local DEBUG = false
local function log_debug(msg)
	if DEBUG then
		wezterm.log_info(msg)
		print("[wezterm-lua] " .. msg)
	end
end

-- Intercept URI opening to support opening file-line links in Neovim
wezterm.on("open-uri", function(window, pane, uri)
	log_debug("open-uri triggered with URI: " .. tostring(uri))

	-- 1. Handle IP links (e.g. 127.0.0.1:8080 or 127.0.0.1)
	local ip_prefix = "ip-link://"
	if uri:find(ip_prefix, 1, true) == 1 then
		local clean_ip = uri:sub(#ip_prefix + 1)
		local host, port = clean_ip:match("([^:]+):?(%d*)")
		local url
		if port and port ~= "" then
			url = "http://" .. host .. ":" .. port
		else
			url = "http://" .. host
		end
		log_debug("Opening IP URI: " .. url)
		wezterm.open_with(url)
		return false
	end

	-- 2. Handle File links
	local file_line_prefix = "file-line://"
	local file_only_prefix = "file-only://"
	local is_file_line = uri:find(file_line_prefix, 1, true) == 1
	local is_file_only = uri:find(file_only_prefix, 1, true) == 1

	if is_file_line or is_file_only then
		local clean_uri = uri
		local line = "1"
		if is_file_line then
			clean_uri = uri:sub(#file_line_prefix + 1)
			local path, ln = clean_uri:match("([^:]+):([^:]+)")
			if path and ln then
				clean_uri = path
				local start_line = ln:match("^(%d+)")
				if start_line then
					line = start_line
				end
			end
		else
			clean_uri = uri:sub(#file_only_prefix + 1)
		end

		-- Handle ~/ prefix by expanding it to $HOME
		local home = os.getenv("HOME") or wezterm.home_dir
		local full_path = clean_uri
		if clean_uri == "~" or clean_uri:match("^~/") then
			full_path = home .. clean_uri:sub(2)
		end

		-- Detect if we are inside herdr
		local is_herdr = false
		local herdr_pane_id = nil

		local proc_info = pane:get_foreground_process_info()
		if proc_info then
			local exec = tostring(proc_info.executable)
			local name = tostring(proc_info.name)
			if name == "herdr" or exec:match("/herdr$") or exec == "herdr" then
				is_herdr = true
			end
		end


		-- Build candidate paths based on CWD
		local paths_to_check = {}
		if not full_path:match("^/") then
			-- Native WezTerm CWD
			local wezterm_cwd = ""
			local cwd_url = pane:get_current_working_dir()
			if cwd_url then
				if type(cwd_url) == "string" then
					wezterm_cwd = cwd_url
				elseif type(cwd_url) == "userdata" or type(cwd_url) == "table" then
					local ok, val = pcall(function() return cwd_url.file_path or cwd_url.path end)
					if ok and val then
						wezterm_cwd = val
					else
						wezterm_cwd = tostring(cwd_url)
					end
				else
					wezterm_cwd = tostring(cwd_url)
				end
			end

			-- Strip file:// scheme, hostname, and decode percent-encoded chars (e.g., %20)
			if wezterm_cwd:find("^file://") then
				local ok, parsed = pcall(function()
					if wezterm.url and wezterm.url.parse then
						return wezterm.url.parse(wezterm_cwd)
					end
				end)
				if ok and parsed and parsed.file_path then
					wezterm_cwd = parsed.file_path
				else
					local path_part = wezterm_cwd:match("^file://[^/]*(/.*)")
					if path_part then
						wezterm_cwd = path_part
					else
						wezterm_cwd = wezterm_cwd:sub(8)
					end
				end
			end

			if is_herdr then
				-- Query the focused herdr pane's CWD
				local herdr_cwd = ""
				local handle = io.popen(herdr_bin .. " pane list 2>/dev/null")
				if handle then
					local json_str = handle:read("*a")
					handle:close()
					if json_str and json_str ~= "" then
						local ok, data = pcall(function() return wezterm.json_parse(json_str) end)
						if ok and data and data.result and data.result.panes then
							for _, p in ipairs(data.result.panes) do
								if p.focused then
									local h_cwd = p.foreground_cwd or p.cwd
									if h_cwd and h_cwd ~= "" then
										herdr_cwd = h_cwd
										log_debug("Found CWD from focused herdr pane: " .. herdr_cwd)
										break
									end
								end
							end
						end
					end
				end

				if herdr_cwd ~= "" then
					table.insert(paths_to_check, herdr_cwd .. "/" .. full_path)
				end
				if wezterm_cwd ~= "" then
					table.insert(paths_to_check, wezterm_cwd .. "/" .. full_path)
				end
			else
				-- If NOT in herdr, we ONLY check WezTerm CWD
				if wezterm_cwd ~= "" then
					table.insert(paths_to_check, wezterm_cwd .. "/" .. full_path)
				end
			end

			-- Fallback to relative path directly from current directory if both are empty
			if #paths_to_check == 0 then
				table.insert(paths_to_check, full_path)
			end
		else
			table.insert(paths_to_check, full_path)
		end

		-- Resolve the path
		local resolved_path = nil
		for _, p in ipairs(paths_to_check) do
			log_debug("Checking candidate path: " .. tostring(p))
			local f, err = io.open(p, "r")
			if f then
				f:close()
				resolved_path = p
				break
			else
				log_debug("Candidate path not found: " .. tostring(p) .. ", error: " .. tostring(err))
			end
		end

		if resolved_path then
			-- Query herdr_pane_id if inside herdr
			if is_herdr then
				local handle = io.popen(herdr_bin .. " pane list 2>/dev/null")
				if handle then
					local json_str = handle:read("*a")
					handle:close()
					if json_str and json_str ~= "" then
						local ok, data = pcall(function() return wezterm.json_parse(json_str) end)
						if ok and data and data.result and data.result.panes then
							for _, p in ipairs(data.result.panes) do
								if p.focused then
									herdr_pane_id = p.pane_id
									break
								end
							end
						end
					end
				end
			end

			if is_herdr and herdr_pane_id then
				log_debug("Inside Herdr! Splitting pane " .. herdr_pane_id .. " and running nvim")

				-- Run split command and open nvim on it
				local split_cmd = string.format(
					'%s pane split %s --direction right | python3 -c \'import sys,json; print(json.load(sys.stdin)["result"]["pane"]["pane_id"])\'',
					herdr_bin,
					herdr_pane_id
				)
				local sh_handle = io.popen(split_cmd)
				if sh_handle then
					local new_pane_id = sh_handle:read("*a")
					sh_handle:close()
					if new_pane_id then
						new_pane_id = new_pane_id:gsub("%s+", "") -- strip whitespaces
						if new_pane_id ~= "" then
							local nvim_cmd = string.format(
								'%s pane run %s \'nvim +%s "%s" ; exit\'',
								herdr_bin,
								new_pane_id,
								line,
								resolved_path
							)
							os.execute(nvim_cmd)
							return false
						end
					end
				end
			end

			-- Outside herdr or herdr fallback: Open in a new WezTerm tab
			log_debug("Opening file in new WezTerm tab: " .. resolved_path)
			window:perform_action(
				wezterm.action.SpawnCommandInNewTab({
					args = { "nvim", resolved_path, "+" .. line },
				}),
				pane
			)
			return false
		else
			log_debug("File does not exist or unreadable in any candidate paths for URI: " .. tostring(uri))
			return false
		end
	end

	-- 3. Handle standard file:// links (which may be generated by WezTerm default rules)
	local file_prefix = "file://"
	if uri:find(file_prefix, 1, true) == 1 then
		local clean_uri = uri:sub(#file_prefix + 1)
		local path_part = clean_uri:match("^[^/]*(/.*)")
		if path_part then
			clean_uri = path_part
		end

		local line = "1"
		local query_part = clean_uri:match("%?(.*)$")
		if query_part then
			clean_uri = clean_uri:match("^([^?]+)")
			local ln = query_part:match("line=(%d+)")
			if ln then
				line = ln
			end
		end

		-- URL decode percent-encoded characters (like %7E for ~)
		clean_uri = clean_uri:gsub("%%([%da-fA-F][%da-fA-F])", function(h)
			return string.char(tonumber(h, 16))
		end)

		-- Extract from '~' onwards only if it is a standalone path segment (e.g. ^~, ^~/, /~/ or /~$)
		if clean_uri:find("^~") then
			-- Already starts with '~'
		elseif clean_uri:find("/~") then
			local before, after_tilde = clean_uri:match("^(.-)/~(/.*)$")
			if after_tilde then
				clean_uri = "~" .. after_tilde
			else
				local before_end = clean_uri:match("^(.-)/~$")
				if before_end then
					clean_uri = "~"
				end
			end
		end

		local home = os.getenv("HOME") or wezterm.home_dir
		local full_path = clean_uri
		if clean_uri == "~" or clean_uri:match("^~/") then
			full_path = home .. clean_uri:sub(2)
		end

		local paths_to_check = {}
		if not full_path:match("^/") then
			local wezterm_cwd = ""
			local cwd_url = pane:get_current_working_dir()
			if cwd_url then
				if type(cwd_url) == "string" then
					wezterm_cwd = cwd_url
				elseif type(cwd_url) == "userdata" or type(cwd_url) == "table" then
					local ok, val = pcall(function() return cwd_url.file_path or cwd_url.path end)
					if ok and val then
						wezterm_cwd = val
					else
						wezterm_cwd = tostring(cwd_url)
					end
				else
					wezterm_cwd = tostring(cwd_url)
				end
			end
			if wezterm_cwd:find("^file://") then
				local ok, parsed = pcall(function()
					if wezterm.url and wezterm.url.parse then
						return wezterm.url.parse(wezterm_cwd)
					end
				end)
				if ok and parsed and parsed.file_path then
					wezterm_cwd = parsed.file_path
				else
					local path_part_cwd = wezterm_cwd:match("^file://[^/]*(/.*)")
					if path_part_cwd then
						wezterm_cwd = path_part_cwd
					else
						wezterm_cwd = wezterm_cwd:sub(8)
					end
				end
			end
			if wezterm_cwd ~= "" then
				table.insert(paths_to_check, wezterm_cwd .. "/" .. full_path)
			end
		else
			table.insert(paths_to_check, full_path)
		end

		local resolved_path = nil
		for _, p in ipairs(paths_to_check) do
			log_debug("Checking file:// candidate path: " .. tostring(p))
			local f, err = io.open(p, "r")
			if f then
				f:close()
				resolved_path = p
				break
			else
				log_debug("Candidate path not found: " .. tostring(p) .. ", error: " .. tostring(err))
			end
		end

		if resolved_path then
			-- Detect if we are inside herdr
			local is_herdr = false
			local herdr_pane_id = nil

			local proc_info = pane:get_foreground_process_info()
			if proc_info then
				local exec = tostring(proc_info.executable)
				local name = tostring(proc_info.name)
				if name == "herdr" or exec:match("/herdr$") or exec == "herdr" then
					is_herdr = true
				end
			end

			if is_herdr then
				local handle = io.popen(herdr_bin .. " pane list 2>/dev/null")
				if handle then
					local json_str = handle:read("*a")
					handle:close()
					if json_str and json_str ~= "" then
						local ok, data = pcall(function() return wezterm.json_parse(json_str) end)
						if ok and data and data.result and data.result.panes then
							for _, p in ipairs(data.result.panes) do
								if p.focused then
									herdr_pane_id = p.pane_id
									break
								end
							end
						end
					end
				end
			end

			if is_herdr and herdr_pane_id then
				log_debug("Inside Herdr! Splitting pane " .. herdr_pane_id .. " and running nvim")
				local split_cmd = string.format(
					'%s pane split %s --direction right | python3 -c \'import sys,json; print(json.load(sys.stdin)["result"]["pane"]["pane_id"])\'',
					herdr_bin,
					herdr_pane_id
				)
				local sh_handle = io.popen(split_cmd)
				if sh_handle then
					local new_pane_id = sh_handle:read("*a")
					sh_handle:close()
					if new_pane_id then
						new_pane_id = new_pane_id:gsub("%s+", "")
						if new_pane_id ~= "" then
							local nvim_cmd = string.format(
								'%s pane run %s \'nvim +%s "%s" ; exit\'',
								herdr_bin,
								new_pane_id,
								line,
								resolved_path
							)
							os.execute(nvim_cmd)
							return false
						end
					end
				end
			end

			log_debug("Opening file in new WezTerm tab: " .. resolved_path)
			window:perform_action(
				wezterm.action.SpawnCommandInNewTab({
					args = { "nvim", resolved_path, "+" .. line },
				}),
				pane
			)
			return false
		else
			log_debug("File does not exist or unreadable in any candidate paths for URI: " .. tostring(uri))
			return false
		end
	end
	return true
end)

return config
