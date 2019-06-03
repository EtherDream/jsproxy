-- 功能：还原 WebSocket 的 HTTP 请求头
-- 阶段：access_by_lua
-- 备注：JS 无法设置 ws 的头部，因此信息存储于 query

local query, err = ngx.req.get_uri_args()

for k, v in pairs(query) do
  if k == 'url__' then
    ngx.var._url = v
  elseif k == 'ver__' then
    ngx.var._ver = v
  else
    ngx.req.set_header(k, v)
  end
end