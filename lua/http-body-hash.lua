if ngx.ctx._switched then
  local chunk = ngx.arg[1]
  ngx.arg[1] = #chunk .. ',' .. ngx.crc32_long(chunk)
  ngx.arg[2] = true
end