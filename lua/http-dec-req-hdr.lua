-- 还原 HTTP 请求头
local hasRawRefer = false

local hdrs = ngx.req.get_headers()
local refer = hdrs['referer']
local query = refer:sub(refer:find('?', 10, true) + 1)
local param = ngx.decode_args(query)


for k, v in pairs(param) do
  if k:sub(1, 2) == '--' then
    k = k:sub(3)

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
  else
    ngx.req.set_header(k, v)

    if k == 'referer' then
      hasRawRefer = true
      ngx.var._ref = v
    end
  end
end

if not hasRawRefer then
  ngx.req.clear_header('referer')
end

-- 删除 URL 的 '/http/' 前缀
ngx.var._url = ngx.var.request_uri:sub(7)