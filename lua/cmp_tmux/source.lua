--
-- cmp-tmux
-- url: https://github.com/andersevenrud/cmp-tmux
-- author: Anders Evenrud <andersevenrud@gmail.com>
-- license: MIT
--

local config = require('cmp.config')
local Tmux = require('cmp_tmux.tmux')

local Source = {}

local default_config = {
  all_panes = false,
  keyword_length = 0,
  keyword_pattern = [[\k\+]],
  keyword_exclusion_pattern = nil,
}

local function create_config()
  local source_config = config.get_source_config('tmux') or {}
  return vim.tbl_extend('force', default_config, source_config.option or {})
end

function Source:new()
  local o = {}
  setmetatable(o, self)
  self.__index = self
  o.config = create_config()
  o.tmux = Tmux:new(o.config)
  return o
end

function Source:get_debug_name()
  return 'tmux'
end

function Source:is_available()
  return self.tmux:is_enabled()
end

function Source:get_keyword_pattern()
  return self.config.keyword_pattern
end

function Source:complete(request, callback)
  local word = string.sub(request.context.cursor_before_line, request.offset)

  self.tmux:complete(word, function(words)
    if words == nil then
      return callback()
    end

    local items = vim.tbl_map(function(w)
      return {
        label = w,
        dup = 0,
        empty = 0,
      }
    end, words)

    callback(items)
  end)
end

function Source:resolve(completion_item, callback)
  callback(completion_item)
end

function Source:execute(completion_item, callback)
  callback(completion_item)
end

return Source
