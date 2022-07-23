--
-- cmp-tmux
-- url: https://github.com/andersevenrud/cmp-tmux
-- author: Anders Evenrud <andersevenrud@gmail.com>
-- license: MIT
--

local Tmux = {}

function Tmux:new(config)
  local o = {}
  setmetatable(o, self)
  self.__index = self
  o.has_tmux = vim.fn.executable('tmux') == 1
  o.is_tmux = os.getenv('TMUX') ~= nil
  o.config = config
  return o
end

function Tmux:is_enabled()
  return self.has_tmux and self.is_tmux
end

function Tmux:get_current_pane()
  return os.getenv('TMUX_PANE')
end

function Tmux:get_panes(current_pane)
  local result = {}

  local cmd = "tmux list-panes -F '#{pane_id}'"
  if self.config.all_panes then
    cmd = cmd .. ' -a'
  end

  local handle = io.popen(cmd)
  if handle ~= nil then
    local data = handle:read('*all')
    if data ~= nil then
      for p in string.gmatch(data, '%%%d+') do
        if current_pane ~= p then
          table.insert(result, p)
        end
      end
    end

    handle:close()
  end

  return result
end

function Tmux:create_pane_data_job(pane, on_data, on_exit)
  local cmd = { 'tmux', 'capture-pane', '-p', '-t', pane }

  return vim.fn.jobstart(cmd, {
    on_exit = on_exit,
    on_stderr = nil,
    on_stdout = function(_, data)
      local result = table.concat(data, '\n')
      if #result > 0 then
        on_data(result)
      end
    end,
  })
end

function Tmux:get_completion_items(current_pane, input, callback)
  local panes = self:get_panes(current_pane)
  local input_lower_or_nil = input == '' and nil or input:lower()
  local remainder = #panes
  local result = {}

  if remainder == 0 then
    return callback(nil)
  end

  local kw_len = self.config.keyword_length
  local kw_ex_pat = self.config.keyword_exclusion_pattern and vim.regex(self.config.keyword_exclusion_pattern)
  local regex = vim.regex([[\(\k\|[-_:/.~]\)\+]])
  for _, p in ipairs(panes) do
    self:create_pane_data_job(p, function(data)
      if data ~= nil then
        for line in vim.gsplit(data, '\n') do
          if input_lower_or_nil == nil or line:lower():find(input_lower_or_nil) then
            local remaining = line
            while #remaining > 0 do
              local match_start, match_end = regex:match_str(remaining)
              if match_start and match_end then
                local word = remaining:sub(match_start + 1, match_end)
                if #word > kw_len and (kw_ex_pat == nil or not kw_ex_pat:match_str(word)) then
                  result[word] = true
                end
                remaining = remaining:sub(match_end + 1)
              else
                break
              end
            end
          end
        end
      end
    end, function()
      remainder = remainder - 1

      if remainder == 0 then
        callback(vim.tbl_keys(result))
      end
    end)
  end
end

function Tmux:complete(input, callback)
  if self:is_enabled() then
    local current_pane = self:get_current_pane()
    self:get_completion_items(current_pane, input, callback)
  else
    callback(nil)
  end
end

return Tmux
