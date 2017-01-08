local helpers = {}

local util = require("lapis.util")
local lunamark  = require("lunamark")
local md_opts   = {}
local md_writer = lunamark.writer.html.new(md_opts)
local md_parse  = lunamark.reader.markdown.new(md_writer, md_opts)

function helpers.is_same_user(session, username)
    return session.current_user.username == username
end

function helpers.is_logged_in(session)
    return session.current_user.id > 0
end

function helpers.cloak_mail(s)
    return s and string.gsub(tostring(s), '[%a%d]', 'x') or ""
end

--- Split a string using a pattern.
-- @param str The string to search in
-- @param pat The pattern to search with
-- @see http://lua-users.org/wiki/SplitJoin
function helpers.split(str, pat)
  local t = {}  -- NOTE: use {n = 0} in Lua-5.0
  local fpat = '(.-)' .. pat
  local last_end = 1
  local s, e, cap = str:find(fpat, 1)
  while s do
    if s ~= 1 or cap ~= '' then
      t[#t+1] = cap
    end
    last_end = e+1
    s, e, cap = str:find(fpat, last_end)
  end
  if last_end <= #str then
    cap = str:sub(last_end)
    t[#t+1] = cap
  end
  return t
end

function helpers.md_parse(s)
    return md_parse(s or "")
end

function helpers.clean_md(s)
    local md = s
    md = md:gsub("\r\n", "\n")
    md = md:gsub("\r", "\n")

    return util.trim(md)
end

function helpers.show_date(s)
    if not s then return "" end
    local m, x = string.match(s, '(%d+-%d+-%d+ %d+:%d+:%d+).(%d+)')
    return m and m or s
end

return helpers
