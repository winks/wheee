-- call with e.g. /opt/local/openresty-1.11.2.2/luajit/bin/luajit bcrypt.lua
local bcrypt = require("bcrypt")

local pass = "wheeeIsAwesome"
-- local salt = bcrypt.salt(5)
local log_rounds = 9
--local digest = bcrypt.digest(pass, salt)
local digest = bcrypt.digest(pass, log_rounds)

print(digest)

assert(bcrypt.verify(pass, digest))
