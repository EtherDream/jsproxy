-- 功能：编码 HTTP 返回头
-- 阶段：header_filter_by_lua
-- 备注：
-- aceh = HTTP 返回头的 access-control-expose-headers 字段


-- 无论浏览器是否支持，aceh 始终包含 *
local expose = '*'

-- 该值为 true 表示浏览器不支持 aceh: *，需返回详细的头部列表
local detail = (ngx.ctx._aceh == 1)

-- 由于接口路径固定，为避免被缓存，以请求头的 --url 值区分缓存
local vary = '--url'

local h, err = ngx.resp.get_headers()
for k, v in pairs(h) do
  if
    -- 这些头有特殊意义，需要转义 --
    k == 'access-control-allow-origin' or
    k == 'access-control-expose-headers' or
    k == 'location' or
    k == 'set-cookie'
  then
    if type(v) == 'table' then
      for i = 1, #v do
        local x = i .. '-' .. k
        ngx.header[x] = v[i]

        if detail then
          expose = expose .. ',' .. x
        end
      end
    else
      local x = '--' .. k
      ngx.header[x] = v

      if detail then
        expose = expose .. ',' .. x
      end
    end
    ngx.header[k] = nil

  elseif k == 'vary' then
    if type(v) == 'table' then
      vary = vary .. ',' .. table.concat(v, ',')
    else
      vary = vary .. ',' .. v
    end

  elseif detail and
    -- 非简单头无法被 fetch 读取，需添加到 aceh 列表 --
    -- https://developer.mozilla.org/en-US/docs/Glossary/Simple_response_header
    k ~= 'cache-control' and
    k ~= 'content-language' and
    k ~= 'content-type' and
    k ~= 'expires' and
    k ~= 'last-modified' and
    k ~= 'pragma'
  then
    expose = expose .. ',' .. k
  end
end

if detail then
  expose = expose .. ',--s'
  ngx.header['--t'] = '1'
end

ngx.header['access-control-expose-headers'] = expose
ngx.header['access-control-allow-origin'] = '*'
ngx.header['vary'] = vary
ngx.header['--s'] = ngx.status
ngx.status = 200