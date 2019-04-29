local traff = ngx.shared.traff

if traff:get('nReq') == nil then
  traff:add('nReq', 0)
  traff:add('stat', '')
end