local lapis  = require("lapis")
local config = require("lapis.config").get()
local db     = require("lapis.db")
local Model  = require("lapis.db.model").Model
local schema = require("lapis.db.schema")
local etlua  = require 'etlua'
local wheee  = require 'wheee'

local Users = Model:extend("w_users")
local Pages = Model:extend("w_pages")
local app   = lapis.Application()
app:enable("etlua")
app.layout = require 'views.my_layout'


app:get('index', "/", function(self)
    local p_name = "_index"
    local page = Pages:select("WHERE name = ? ORDER BY rev DESC LIMIT 1", p_name)[1]

    if page then
        self.bottom_raw = wheee.md_parse(page.body)
    else
        self.bottom_raw = wheee.md_parse("Welcome to *wheee*, a wiki written in Lapis " .. require("lapis.version"))
    end

    return { render = "_index" }
end)

app:get('userlist', "/u", function(self)
    self.users = Users:select("ORDER BY username ASC")

    return { render = "_userlist" }
end)

app:get('pagelist', "/w", function(self)
    self.pages = db.query("SELECT DISTINCT ON (name) id, rev, name FROM w_pages ORDER BY name ASC, rev DESC")

    return { render = "_pagelist" }
end)

app:get("/u/:user", function(self)
    local u_name, format = wheee.extract_format(self.params.user)
    local user = Users:find({ username = u_name })
    if not user then
        return wheee.error(self, 404, 'User doesn\'t exist.')
    end
    local pages = Pages:select("WHERE author = ? ORDER BY id DESC", user.id )

    self.user = wheee.clean_user(user)
    if format == 'md' then
        return wheee.render_md(self, self.user)
    elseif format == 'json' then
        return wheee.render_json(self, self.user)
    end
    self.pages = pages

    return { render = '_user' }
end)

app:get("/w/:page", function(self)
    local p_name, format = wheee.extract_format(self.params.page)
    local page = Pages:select("WHERE name = ? ORDER BY rev DESC LIMIT 1", p_name)[1]
    if not page then
        local msg = table.concat({
            'Page doesn\'t exist. <a href="',
            self:url_for("page_new"),
            '?page=', p_name,
            '">Create page named \'', p_name, '\'</a><br>',
        })
        return wheee.error(self, 404, msg)
    end
    if format == 'md' then
        return wheee.render_md(self, page)
    elseif format == 'json' then
        return wheee.render_json(self, page)
    end
    local author = Users:find(page.author)

    self.page = wheee.clean_page(page)
    self.author = wheee.clean_user(author)

    return { render = "_page" }
end)

app:match('login', "/m/login", function(self)
    if 'GET' == ngx.var.request_method then
        return { render = "_login" }
    end
    local user = Users:find({ username = self.params.login.username })
    if user then
        wheee.login(self, user, self.params.login.password)
    else
        wheee.logout(self)
    end

    return { redirect_to = self:url_for("index") }
end)

app:match('logout', "/m/logout", function(self)
    wheee.logout(self)

    return { redirect_to = self:url_for("index") }
end)

app:match('user_edit', "/m/profile", function(self)
    if not self.session.current_user then
        return wheee.error(self, 401, 'Not allowed.')
    end
    if 'POST' == ngx.var.request_method then
        local p_username = self.params.user.username
        if not wheee.is_user(self, p_username) then
            return wheee.error(self, 401, 'Not allowed.')
        end
        local p_email    = self.params.user.email
        local p_url      = self.params.user.url
        local p_body     = wheee.clean_md(self.params.user.body)

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

        return { redirect_to = "/u/" .. user.username }
    else
        local user = Users:find(self.session.current_user.id)

        self.crud = {
            url = "/m/profile",
            status = "Edit Profile: ",
            status2 = "",
            submit = "Submit changes",
        }
        self.user = user
        return { render = "_cruduser" }
    end
end)

app:match('page_edit', "/m/edit", function(self)
    if not self.session.current_user then
        return wheee.error(self, 401, 'Not allowed.')
    end
    if 'POST' == ngx.var.request_method then
        local p_author = self.session.current_user.id
        local p_name   = self.params.page.name
        local p_rev    = tonumber(self.params.page.rev)
        local p_body   = wheee.clean_md(self.params.page.body)

        local page = Pages:create({
            rev = p_rev + 1,
            name = p_name,
            author = p_author,
            body = p_body,
        })
        return { redirect_to = "/w/" .. p_name }
    else
        local p_name = self.params.page
        local page = Pages:select("WHERE name = ? ORDER BY rev DESC LIMIT 1", p_name)[1]

        if not page then
            return wheee.error(self, 404, 'Not found.')
        end

        self.crud = {
            url = "/m/edit",
            status = "Edit Page: ",
            status2 = " (Revision " .. page.rev .. ")",
            submit = "Submit changes",
        }
        self.page = page
        return { render = "_crudpage" }
    end
end)

app:match('page_new', "/m/new", function(self)
    if not self.session.current_user then
        return wheee.error(self, 401, 'Not allowed.')
    end
    if 'POST' == ngx.var.request_method then
        local p_name   = self.params.page.name
        local p_author = self.session.current_user.id
        local p_body   = wheee.clean_md(self.params.page.body)

        local page = Pages:create({
            rev = 1,
            name = p_name,
            author = p_author,
            body = p_body,
        })
        return { redirect_to = "/w/" .. p_name }
    else
        local p_page = self.params.page
        if not p_page then
            return { render = "_newpage" }
        end
        local page = Pages:find({name = p_page})

        if not page then
            self.crud = {
                url = "/m/new",
                status = "New Page: ",
                status2 = "",
                submit = "Create Page",
            }
            self.page = { name = p_page, body = "", rev = 0 }
            return { render = "_crudpage" }
        else
            return wheee.index(self, 'Page already exists. <a href="/w/' .. p_page .. '">' .. p_page .. '</a>')
        end
    end
end)

app.default_route = function(self)
    ngx.log(ngx.NOTICE, "User hit unknown path " .. self.req.parsed_url.path)

    return wheee.error(self, 404, "URL not found.")
end

return app
