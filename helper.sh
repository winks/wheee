#!/bin/bash
p="/usr/local/stow/openresty-1.9.7.4"
alias luarocks=${p}/luajit/bin/luarocks
alias lapis=${p}/luajit/bin/lapis
alias lua=${p}/luajit/bin/luajit

export LAPIS_OPENRESTY="${p}/nginx/sbin/nginx"

echo "Aliased 'lua', 'luarocks' and 'lapis' for you."
