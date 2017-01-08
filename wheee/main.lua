local wheee = {}

local bcrypt = require('bcrypt')

wheee.helpers = require 'wheee.helpers'

function wheee.login(self, user, pass)
    if wheee.auth(user, pass) then
        self.session.current_user = wheee.clean_user(user)
    else
        wheee.logout(self)
    end
end

function wheee.logout(self)
    self.session.current_user = { id = 0, username = 'guest' }
end

function wheee.auth(user, pass)
    return bcrypt.verify(pass, user.password)
end

function wheee.clean_user(user)
    local t = {}
    for k, v in pairs(user) do
        if k == 'password' then
        elseif k == 'email' then
            t.email_hidden = wheee.helpers.cloak_mail(v)
        elseif k == 'body' then
            t.body = v
            t.body_html = wheee.helpers.md_parse(v)
        elseif k == 'id' then
            t[k] = tonumber(v)
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
            t.body_html = wheee.helpers.md_parse(v)
        else
            t[k] = v
        end
    end

    return t
end

function wheee.error(self, code, message, template)
    self.status_code = code
    self.preface = message

    return { render = template or '_error' }
end

function wheee.index(self, msg)
    self.bottom_raw = msg

    return { render = '_index' }
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
    elseif s:sub(#s-2, #s) == '.md' then
        format = 'md'
        s = s:sub(0, #s-3)
    elseif s:sub(#s-4, #s) == '.json' then
        format = 'json'
        s = s:sub(0, #s-5)
    end

    return s, format
end

function wheee.pages_filter_acl(pages, acls, revisions)
    local result = {}
    for _, page in pairs(pages) do
        page = wheee.page_filter_acl(page, acls, revisions)
        if page then
            result[#result+1] = page
        end
    end

    return result
end

function wheee.page_filter_acl(page, acls, revisions)
    local separator = ':'
    local acl_match = nil
    local parts_match = {}

    for _, acl in pairs(acls) do
        local parts = wheee.helpers.split(acl.pattern, separator)
        if page.name:match('^' .. acl.pattern) then
            if not acl_match or #parts > #parts_match then
                acl_match = acl
                parts_match = parts
            end
        end
    end

    if not acl_match or acl_match.mode < 1 then
        page = nil
    else
        page.acl = acl_match
    end

    return page
end

return wheee
