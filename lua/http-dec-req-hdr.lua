-- 还原 HTTP 请求头
-- 前端只保留简单字段（防止出现 preflight），
-- 其余字段及系统信息，存储在 Accept 字段里（JSON 格式）。

local cjson = require('cjson')
local hdrs, err = ngx.req.get_headers()
ngx.log(ngx.ALERT, 'accept:' .. hdrs['accept'])
local info = ngx.unescape_uri(hdrs['accept'])
local json = cjson.decode(info)

-- 系统信息
local sys = json['sys']

for k, v in pairs(sys) do
  if k == 'ver' then
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
  end
end

-- 原始 HTTP 字段
local ext = json['ext']
local hasRawAccept = false

for k, v in pairs(ext) do
  if k == 'accept' then
    hasRawAccept = true
  elseif k == 'referer' then
    ngx.var._ref = v
  end
  ngx.req.set_header(k, v)
end

if not hasRawAccept then
  ngx.req.clear_header('accept')
end

-- 删除 URL 的 '/http/' 前缀
ngx.var._url = ngx.var.request_uri:sub(7)