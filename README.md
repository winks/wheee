# wheee, a wiki in lua

## Intro

A minimal wiki in Lua, made with Lua and
[PostgreSQL](http://www.postgresql.org/) 9.1.

Requirements:

  * [`OpenResty`](http://openresty.org/) (1.7.10.1)
  * [`Lapis`](http://leafo.net/lapis/) (1.0.4)
  * [`bcrypt`](https://github.com/mikejsavage/lua-bcrypt) (1.5-1)
  * either one of;
    * [`markdown.lua`](http://www.frykholm.se/files/markdown.lua) (0.32)
    * [`lunamark`](https://github.com/jgm/lunamark) (0.3.2-1)

## Howto

  * install OpenResty (as per their instructions)
  * install luarocks 2.0.13 (as per the openresty instructions)
  * `LUAROCKS=/path/to/luarocks make deps`
  * `cp config.lua.dist config.lua # then edit it`
  * check `helper.sh` and see if you need it
  * `lapis server`

## Credits

Icons by the Tango project.

## License

See `LICENSE`
