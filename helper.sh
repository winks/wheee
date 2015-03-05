#!/bin/bash
p="/usr/local/stow/ngx_openresty-1.7.10.1-2"
alias luarocks=${p}/luajit/bin/luarocks
alias lapis=${p}/luajit/bin/lapis
alias lua=${p}/luajit/bin/luajit-2.1.0-alpha

export LAPIS_OPENRESTY=${p}/nginx/sbin/nginx

echo "Aliased 'lua', 'luarocks' and 'lapis' for you."
