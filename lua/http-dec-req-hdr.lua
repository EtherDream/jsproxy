-- 功能：还原 HTTP 请求头
-- 阶段：access_by_lua

local hdrs, err = ngx.req.get_headers()
local extHdrs

for k, v in pairs(hdrs) do
  if k:sub(1, 2) ~= '--' then
    goto continue
  end

  ngx.req.clear_header(k)
  k = k:sub(3)

  if k == 'url' then
    ngx.var._url = v
  elseif k == 'ver' then
    ngx.var._ver = v
  elseif k == 'type' then
    ngx.var._type = v
  elseif k == 'mode' then
    ngx.var._mode = v
  elseif k == 'aceh' then
    ngx.ctx._acehOld = true
  elseif k == 'level' then
    ngx.var._level = v
    ngx.ctx._level = tonumber(v)
  elseif k == 'ext' then
    extHdrs = require('cjson').decode(v)
  else
    if k == 'referer' then
      ngx.var._ref = v
    end
    ngx.req.set_header(k, v)
  end

  ::continue::
end

if extHdrs then
  for k, v in pairs(extHdrs) do
    ngx.req.set_header(k, v)
  end
end