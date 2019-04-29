local _M = {}
local traff = ngx.shared.traff

local nReq = 0


function _M.inc()
  nReq = nReq + 1
end

function _M.syn()
  traff:incr('nReq', nReq)
  nReq = 0
end

function _M.update()
  local nReq = traff:get('nReq')
  traff:set('nReq', 0)
  return nReq
end

function _M.getStat()
  return traff:get('stat')
end

function _M.setStat(stat)
  return traff:set('stat', stat)
end

function _M.reset()
  if traff:get('nReq') == nil then
    traff:add('nReq', 0)
    traff:add('stat', '')
  end
end

return _M