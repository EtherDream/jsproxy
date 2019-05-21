-- ngx.arg[1] => chunk
-- ngx.arg[2] => eof


-- 大文件只返回首块 hash（用户从廉价带宽获取内容）
if ngx.ctx._switched then
  local chunk = ngx.arg[1]
  ngx.arg[1] = #chunk .. ',' .. ngx.crc32_long(chunk)
  ngx.arg[2] = true
  return
end


-- 计算 HTTP 返回数据的 hash（用于统计）
if ngx.ctx._sha256 == nil then
  local resty_sha256 = require 'resty.sha256'
  ngx.ctx._sha256 = resty_sha256:new()
end

if ngx.arg[2] then
  local digest = ngx.ctx._sha256:final()
  digest = digest:sub(1, 16)

  local str = require 'resty.string'
  ngx.var._bodyhash = str.to_hex(digest)
else
  ngx.ctx._sha256:update(ngx.arg[1])
end