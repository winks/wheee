# wheee, a wiki in lua

## Intro

A minimal wiki in Lua, made with Lua and
[PostgreSQL](http://www.postgresql.org/).

Requirements:

  * [`OpenResty`](http://openresty.org/) (1.9+)
  * [`Lapis`](http://leafo.net/lapis/) (1.5)
  * [`bcrypt`](https://github.com/mikejsavage/lua-bcrypt) (2.1-3)
  * either one of;
    * [`markdown.lua`](http://www.frykholm.se/files/markdown.lua) (0.32)
    * [`lunamark`](https://github.com/jgm/lunamark) (0.5.0-1)
  * [`PostgreSQL`](https://www.postgresql.org/)(9.x)

## Howto

  * install OpenResty (as per [their instructions](http://openresty.org/en/installation.html))
  * install luarocks 2.4 (as per the [openresty instructions](http://openresty.org/en/using-luarocks.html), although they call them outdated)
  * `cp config.lua.dist config.lua # then edit it`
  * check `helper.sh` and see if you need it
  * `LUAROCKS=/path/to/luarocks make deps`
  * `lapis server`

## Credits

Icons by the Tango project.

## License

See `LICENSE`
