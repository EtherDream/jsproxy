-- https://fetch.spec.whatwg.org/#statuses
local s = ngx.status
if not (s == 301 or s == 302 or s == 307 or s == 308) then
  return
end

-- 忽略 WebSocket
if ngx.header['upgrade'] then
  return
end

--[=[
  如果直接返回 30X 状态，fetch API 会继续请求新的 URL，
  不符合 req.redirect 为 manual 的情况。

  例如请求 google.com 会重定向到 www.google.com，
  如果最终获得的内容是后者，但地址栏显示的是前者，路径上就会出现问题。

  如果在 SW 里设置 req.redirect = manual，重定向后拿不到 location。
  所以这里对状态码 + 10 进行转义，SW 收到后再 -10。
]=]
ngx.status = s + 10
ngx.header['access-control-expose-headers'] = 'location'


-- local url = ngx.header['location']
-- if not url then
--   return
-- end

-- -- m = [, rhost, path]
-- local r = [[^https?://([^/]+)(.*)]]
-- local m = ngx.re.match(url, r, 'jo')
-- if not m then
--   return
-- end

-- -- rhost to vhost
-- ngx.var._rhost = m[1]
-- local vhost = ngx.var._rhost_to_vhost

-- url = 'https://' .. vhost .. m[2]

-- -- add flag
-- local sign = url:find('?', 1, true) and '&' or '?'
-- url = url .. sign .. 'flag__=' .. ngx.var._flag

-- -- update redir url
-- ngx.header['location'] = url