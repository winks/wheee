#!/bin/bash
p="/opt/local/openresty-1.11.2.2"
alias luarocks=${p}/luajit/bin/luarocks
alias lapis=${p}/luajit/bin/lapis
alias lua=${p}/luajit/bin/luajit

export LAPIS_OPENRESTY="${p}/nginx/sbin/nginx"

echo "Aliased 'lua', 'luarocks' and 'lapis' for you."
