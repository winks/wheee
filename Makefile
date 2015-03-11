LUAROCKS?=/usr/local/stow/ngx_openresty-1.7.10.1-2/luajit/bin/luarocks

deps: markdown.lua
	$(LUAROCKS) install lapis
	$(LUAROCKS) install bcrypt
	

markdown.lua:
	wget http://www.frykholm.se/files/markdown.lua -o markdown.lua
