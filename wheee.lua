local wheee = {}

local util = require("lapis.util")
local bcrypt = require("bcrypt")

local lunamark  = require("lunamark")
local md_opts   = {}
local md_writer = lunamark.writer.html.new(md_opts)
local md_parse  = lunamark.reader.markdown.new(md_writer, md_opts)


function wheee.md_parse(s)
    return md_parse(s or "")
end

function wheee.login(self, user, pass)
    if wheee.auth(user, pass) then
        self.session.current_user = wheee.clean_user(user)
    else
        wheee.logout(self)
    end
end

function wheee.logout(self)
    self.session.current_user = nil
end

function wheee.auth(user, pass)
    return bcrypt.verify(pass, user.password)
end

function wheee.is_user(self, username)
    return self.session.current_user.username == username
end

function wheee.cloak_mail(s)
    return s and string.gsub(tostring(s), '[%a%d]', 'x') or ""
end

function wheee.clean_md(s)
    local md = s
    md = md:gsub("\r\n", "\n")
    md = md:gsub("\r", "\n")

    return util.trim(md)
end

function wheee.clean_user(user)
    local t = {}
    for k, v in pairs(user) do
        if k == 'password' then
        elseif k == 'email' then
            t.email_hidden = wheee.cloak_mail(v)
        elseif k == 'body' then
            t.body = v
            t.body_html = wheee.md_parse(v)
        else
            t[k] = v
        end
    end

    return t
end

function wheee.clean_page(page)
    local t = {}
    for k, v in pairs(page) do
        if k == 'body' then
            t.body =v
            t.body_html = wheee.md_parse(v)
        else
            t[k] = v
        end
    end

    return t
end

function wheee.error(self, code, msg)
    self.status_code = code
    self.preface = msg

    return { render = "_error" }
end

function wheee.index(self, msg)
    self.bottom_raw = msg

    return { render = "_index" }
end

function wheee.render_md(self, t)
    self.content = t.body

    return {
        content_type = 'text/x-markdown',
        layout = false,
        render = '_md',
    }
end

function wheee.render_json(self, t)
    if t.id then
        t.id = nil
    end
    return { json = t }
end

function wheee.extract_format(s)
    local format = 'html'
    if not s then
        return nil, format
    elseif s:sub(#s-2, #s) == ".md" then
        format = 'md'
        s = s:sub(0, #s-3)
    elseif s:sub(#s-4, #s) == ".json" then
        format = 'json'
        s = s:sub(0, #s-5)
    end

    return s, format
end

return wheee
