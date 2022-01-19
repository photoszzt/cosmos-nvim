local M = {}

local function is_module_available(name)
  if package.loaded[name] then
    return true
  else
    for _, searcher in ipairs(package.searchers or package.loaders) do
      local loader = searcher(name)
      if type(loader) == 'function' then
        package.preload[name] = loader
        return true
      end
    end
    return false
  end
end

function M.safe_require(pkg_name, cbk, opts)
  opts = opts or {}
  local pkg_names = {}
  if type(pkg_name) == 'table' then
    pkg_names = pkg_name
  else
    pkg_names = { pkg_name }
  end

  local pkgs = {}
  for i, pkg_name_ in ipairs(pkg_names) do
    if is_module_available(pkg_name_) then
      pkgs[i] = require(pkg_name_)
    else
      if not opts.silent then
        print('WARNING: package ' .. pkg_name_ .. ' is not found')
      end
      return
    end
  end

  if #pkgs == #pkg_names then
      return cbk(unpack(pkgs))
  end
end

function M.index_of(tbl, val, cmp)
  cmp = cmp or function(a, b) return a == b end
  for i, v in ipairs(tbl) do
    if cmp(v, val) then
      return i
    end
  end
  return -1
end

function M.reload(module)
  return M.safe_require('plenary.reload', function(plenary)
    plenary.reload_module(module)
    require(module)
  end)
end

function M.t(str)
  return vim.api.nvim_replace_termcodes(str, true, true, true)
end

local function get_layers(layers)
  local res = {}
  for _, layer in ipairs(layers) do
    if type(layer) == 'string' then
      layer = { name = layer, options = {} }
    elseif type(layer) == 'table' then
      local name = table.remove(layer, 1) or layer.name
      if layer.options == nil then
        layer = { name = name, options = layer }
      end
    end
    res[#res + 1] = layer
  end
  return res
end

local _user_config

function M.get_user_config()
  if _user_config then
    return _user_config
  end
  local options = require('core.options')
  local ok, __user_config = pcall(dofile, options.user_config_path)
  if not ok then
    if not string.find(__user_config, 'No such file or directory') then
      print('WARNING: user config file is invalid')
      print(__user_config)
    end
    local sample_config_file = io.open(options.cosmos_configs_root .. '/.cosmos-nvim.sample.lua', 'r')
    local sample_config = sample_config_file:read('*a')
    sample_config_file:close()
    local user_config_file = io.open(options.user_config_path, 'w')
    user_config_file:write(sample_config)
    user_config_file:close()
    __user_config = dofile(options.user_config_path)
  end
  _user_config = vim.deepcopy(__user_config)
  if _user_config.layers == nil then
    _user_config.layers = {
      'editor',
      'ui',
      'git',
      'completion',
    }
  end
  _user_config.layers = get_layers(_user_config.layers)
  if _user_config.options == nil then
    _user_config.options = {}
  end
  if _user_config.before_setup == nil then
    _user_config.before_setup = function()
    end
  end
  if _user_config.after_setup == nil then
    _user_config.after_setup = function()
    end
  end
  return _user_config
end

function M.reset_user_config()
  _user_config = nil
end

function M.fill_options(dest_options, new_options)
  for k, v in pairs(new_options) do
    local old_v = dest_options[k]
    if type(v) == 'table' and type(old_v) == 'table' then
      dest_options[k] = vim.tbl_deep_extend('force', old_v, v)
    else
      dest_options[k] = v
    end
  end
end

function M.file_exists(name)
   local f = io.open(name, 'r')
   if f ~= nil then
    io.close(f)
    return true
  else
    return false
  end
end

M.set_keymap = vim.api.nvim_set_keymap

local function _map(mode, shortcut, command)
  M.set_keymap(mode, shortcut, command, { noremap = true, silent = true })
end

function M.map(shortcut, command)
  _map('', shortcut, command)
end

function M.nmap(shortcut, command)
  _map('n', shortcut, command)
end

function M.imap(shortcut, command)
  _map('i', shortcut, command)
end

function M.vmap(shortcut, command)
  _map('v', shortcut, command)
end

function M.cmap(shortcut, command)
  _map('c', shortcut, command)
end

function M.tmap(shortcut, command)
  _map('t', shortcut, command)
end

return M
