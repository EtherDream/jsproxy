-- 功能：编码 HTTP 返回头
-- 阶段：header_filter_by_lua
-- 备注：
-- aceh = HTTP 返回头的 access-control-expose-headers 字段

-- 无论浏览器是否支持，aceh 始终包含 *
local expose = '*'

-- 该值为 true 表示浏览器不支持 aceh: *，需返回详细的头部列表
local detail = ngx.ctx._acehOld

-- 由于接口路径固定，为避免被缓存，以请求头的 --url 值区分缓存
local vary = '--url'


local function addHdr(k, v)
  ngx.header[k] = v
  if detail then
    expose = expose .. ',' .. k
  end
end


local function flushHdr()
  if detail then
    expose = expose .. ',--s'
    -- 该字段不在 aceh 中，如果浏览器能读取到，说明支持 * 通配
    ngx.header['--t'] = '1'
  end

  local status = ngx.status

  ngx.header['access-control-expose-headers'] = expose
  ngx.header['access-control-allow-origin'] = '*'
  ngx.header['vary'] = vary
  ngx.header['--s'] = status
  if
    status == 301 or
    status == 302 or
    status == 303 or
    status == 307 or
    status == 308
  then
    status = status + 10
  end
  ngx.status = status
end


local function addVary(v)
  if type(v) == 'table' then
    vary = vary .. ',' .. table.concat(v, ',')
  else
    vary = vary .. ',' .. v
  end
end


local function nodeSwitched()
  local status = ngx.status
  if status ~= 200 and status ~= 206 then
    return false
  end

  local level = ngx.ctx._level
  if level == nil or level == 0 then
    return false
  end

  if ngx.req.get_method() ~= 'GET' then
    return false
  end

  if ngx.header['set-cookie'] ~= nil then
    return false
  end

  local resLenStr = ngx.header['content-length']
  if resLenStr == nil then
    return false
  end

  -- 小于 400KB 的资源不走加速
  local resLenNum = tonumber(resLenStr)
  if resLenNum == nil or resLenNum < 1000 * 400 then
    return false
  end


  local addr = ngx.var.upstream_addr or ''
  local etag = ngx.header['etag'] or ''
  local last = ngx.header['last-modified'] or ''

  local info = addr .. '|' .. resLenStr .. '|' .. etag .. '|' .. last

  -- clear all res headers
  local h, err = ngx.resp.get_headers()
  for k, v in pairs(h) do
    ngx.header[k] = nil
  end

  addHdr('--raw-info', info)
  addHdr('--switched', '1')

  ngx.header['cache-control'] = 'no-cache'
  ngx.var._switched = resLenStr
  ngx.ctx._switched = true

  flushHdr()
  return true
end

-- 节点切换功能，目前还在测试中（demo 中已开启）
-- if nodeSwitched() then
--   return
-- end


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
      -- 重复的字段，例如 Set-Cookie
      -- 转换成 1-Set-Cookie, 2-Set-Cookie, ...
      for i = 1, #v do
        addHdr(i .. '-' .. k, v[i])
      end
    else
      addHdr('--' .. k, v)
    end
    ngx.header[k] = nil

  elseif k == 'vary' then
    addVary(v)

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

flushHdr()