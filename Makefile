LUAROCKS?=/usr/local/stow/openresty-1.9.7.4/luajit/bin/luarocks

deps: markdown.lua
	$(LUAROCKS) install lapis
	$(LUAROCKS) install bcrypt
	$(LUAROCKS) install lunamark

markdown.lua:
	wget http://www.frykholm.se/files/markdown.lua -o markdown.lua
