local lapis  = require('lapis')
local config = require('lapis.config').get()
local db     = require('lapis.db')
local Model  = require('lapis.db.model').Model
local schema = require('lapis.db.schema')
local etlua  = require 'etlua'
local wheee  = require 'wheee.main'

local Users = Model:extend('w_users')
local Pages = Model:extend('w_pages')
local Acls  = Model:extend('w_acl')
local app   = lapis.Application()
app:enable('etlua')
app.layout = require 'views.my_layout'


app:before_filter(function(self)
    if not self.session.current_user then
        wheee.logout(self)
    end
    wheee.app = app
    self.wheee = wheee
end)

app:get('index', '/', function(self)
    local page_name = 'wheee:index'
    local page = Pages:select('WHERE name = ? ORDER BY rev DESC LIMIT 1', page_name)[1]

    if page then
        self.bottom_raw = wheee.helpers.md_parse(page.body)
    else
        self.bottom_raw = wheee.helpers.md_parse('Welcome to *wheee*, a wiki written in Lapis ' .. require('lapis.version'))
    end

    return { render = '_index' }
end)

app:get('user_list', '/u', function(self)
    self.users = Users:select('ORDER BY username ASC')

    return { render = '_user_list' }
end)

app:get('page_list', '/w', function(self)
    local pages = db.query('SELECT DISTINCT ON (p.name) p.id, p.rev, p.name, p.created_at, p.author AS uid, u.username AS author FROM w_pages AS p, w_users AS u WHERE p.author = u.id ORDER BY p.name ASC, p.rev DESC')
    local user_acls = Acls:select("WHERE actor = '?' OR actor = '?' ORDER BY mode DESC, pattern ASC", self.session.current_user.id, 0)

    if #user_acls > 0 then
        self.pages = wheee.pages_filter_acl(pages, user_acls)
    else
        self.pages = {}
    end
    return { render = '_page_list' }
end)

app:get('user_show', '/u/:user', function(self)
    local user_name, format = wheee.extract_format(self.params.user)
    local user = Users:find({ username = user_name })
    if not user then
        return wheee.error(self, 404, 'User doesn\'t exist.')
    end

    self.user = wheee.clean_user(user)
    if format == 'md' then
        return wheee.render_md(self, self.user)
    elseif format == 'json' then
        return wheee.render_json(self, self.user)
    end

    local pages = Pages:select('WHERE author = ? ORDER BY id DESC', user.id )
    local user_acls = Acls:select("WHERE actor = '?' OR actor = '?' ORDER BY mode DESC, pattern ASC", self.session.current_user.id, 0)

    if #user_acls > 0 then
        self.pages = wheee.pages_filter_acl(pages, user_acls, true)
    else
        self.pages = {}
    end

    return { render = '_user_show' }
end)

app:get('page_show', '/w/:page', function(self)
    local page_name, format = wheee.extract_format(self.params.page)
    local page = Pages:select('WHERE name = ? ORDER BY rev DESC LIMIT 1', page_name)[1]
    local user_acls = Acls:select("WHERE actor = '?' OR actor = '?' ORDER BY mode DESC, pattern ASC", self.session.current_user.id, 0)

    local page_check
    if not page then
        page_check = { name = page_name }
    else
        page_check = page
    end
    local page_acl = wheee.page_filter_acl(page_check, user_acls)

    if not page_acl then
        return wheee.error(self, 401, 'Permission denied.<br>')
    end
    if not page then
        self.page = { name = page_name }
        return wheee.error(self, 404, '', '_page_notfound')
    end
    if format == 'md' then
        return wheee.render_md(self, page_acl)
    elseif format == 'json' then
        return wheee.render_json(self, page_acl)
    end
    local author = Users:find(page_acl.author)

    self.page = wheee.clean_page(page_acl)
    self.author = wheee.clean_user(author)

    return { render = '_page_show' }
end)

app:match('login', '/m/login', function(self)
    if 'GET' == ngx.var.request_method then
        return { render = '_login' }
    end
    local user = Users:find({ username = self.params.login.username })
    if user then
        wheee.login(self, user, self.params.login.password)
    else
        wheee.logout(self)
    end

    return { redirect_to = self:url_for('index') }
end)

app:match('logout', '/m/logout', function(self)
    wheee.logout(self)

    return { redirect_to = self:url_for('index') }
end)

app:match('user_edit', '/m/profile', function(self)
    if not wheee.helpers.is_logged_in(self.session) then
        return wheee.error(self, 401, 'Not allowed.')
    end
    if 'POST' == ngx.var.request_method then
        local p_username = self.params.user.username
        if not wheee.helpers.is_same_user(self.session, p_username) then
            return wheee.error(self, 401, 'Not allowed.')
        end
        local p_email    = self.params.user.email
        local p_url      = self.params.user.url
        local p_body     = wheee.helpers.clean_md(self.params.user.body)

        local user = Users:find(self.session.current_user.id)
        local new = {}
        local updates = 0
        if user.body ~= p_body then
          new.body = p_body
          updates = updates + 1
        end
        if user.email ~= p_email then
          new.email = p_email
          updates = updates + 1
        end
        if user.url ~= p_url then
          new.url = p_url
          updates = updates + 1
        end
        if updates > 0 then
            user:update(new)
        end

        return { redirect_to = self:url_for('user_show', { user = user.username }) }
    else
        local user = Users:find(self.session.current_user.id)

        self.crud = {
            url = self:url_for('user_edit'),
            headline = 'Edit Profile: ' .. user.username,
            submit = 'Submit changes',
        }
        self.user = user
        return { render = '_user_crud' }
    end
end)

app:match('page_edit', '/m/edit', function(self)
    if not wheee.helpers.is_logged_in(self.session) then
        return wheee.error(self, 401, 'Not allowed.')
    end
    local page_name = self.params.page.name or self.params.page
    local user_acls = Acls:select("WHERE actor = '?' OR actor = '?' ORDER BY mode DESC, pattern ASC", self.session.current_user.id, 0)
    page_check = wheee.page_filter_acl({ name = page_name, acl = user_acls }, user_acls)
    if #user_acls < 1 or not wheee.helpers.can_edit(page_check) then
        return wheee.error(self, 401, 'Not allowed.')
    end

    if 'POST' == ngx.var.request_method then
        local p_author = self.session.current_user.id
        local p_name   = self.params.page.name
        local p_rev    = tonumber(self.params.page.rev)
        local p_body   = wheee.helpers.clean_md(self.params.page.body)

        local page = Pages:create({
            rev = p_rev + 1,
            name = p_name,
            author = p_author,
            body = p_body,
        })
        return { redirect_to = self:url_for('page_show', { page = p_name }) }
    else
        local p_name = self.params.page
        local page = Pages:select('WHERE name = ? ORDER BY rev DESC LIMIT 1', p_name)[1]

        if not page then
            return wheee.error(self, 404, 'Not found.')
        end

        self.crud = {
            url = self:url_for('page_edit'),
            headline = 'Edit Page: '.. page.name .. ' (Revision ' .. page.rev .. ')',
            submit = 'Submit changes',
        }
        self.page = page
        return { render = '_page_crud' }
    end
end)

app:match('page_new', '/m/new', function(self)
    if not wheee.helpers.is_logged_in(self.session) then
        return wheee.error(self, 401, 'Not allowed.')
    end
    if 'POST' == ngx.var.request_method then
        local p_name   = self.params.page.name
        local p_author = self.session.current_user.id
        local p_body   = wheee.helpers.clean_md(self.params.page.body)

        local page = Pages:create({
            rev = 1,
            name = p_name,
            author = p_author,
            body = p_body,
        })
        return { redirect_to = self:url_for('page_show', { page = p_name }) }
    else
        local p_page = self.params.page
        if not p_page then
            return { render = '_page_new' }
        end
        local page = Pages:find({name = p_page})

        if not page then
            self.crud = {
                url = self:url_for('page_new'),
                headline = 'New Page: ' .. p_page,
                submit = 'Create Page',
            }
            self.page = { name = p_page, body = '', rev = 0 }
            return { render = '_crudpage' }
        else
            return wheee.index(self, 'Page already exists. <a href="' .. self:url_for('page_show', { page = p_page }) .. '">' .. p_page .. '</a>')
        end
    end
end)

app.default_route = function(self)
    ngx.log(ngx.NOTICE, 'User hit unknown path ' .. self.req.parsed_url.path)

    return wheee.error(self, 404, 'URL not found.')
end

return app
