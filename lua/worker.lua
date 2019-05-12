local g = require('g')

-- run in master worker
if ngx.worker.id() ~= 0 then
  return
end

local function buildDevTrafficFn(dev)
  local regex = dev ..
    [[:\s+(\d+)\s+\d+\s+\d+\s+\d+\s+\d+\s+\d+\s+\d+\s+\d+\s+(\d+)]]
  --        0      1     2     3     4     5     6     7    | 8
  -- eth0: bytes packets errs drop fifo frame compress multi| bytes 

  local lastRxBytes = 0
  local lastTxBytes = 0

  return function(str)
    local m = ngx.re.match(str, regex, 'oi')
    if m == nil then
      return '0,0'
    end
    local sRxBytes = m[1]
    local sTxBytes = m[2]

    if sTxBytes == nil then
      return '0,0'
    end

    local nRxBytes = tonumber(sRxBytes)
    local nTxBytes = tonumber(sTxBytes)

    local rxBPS = nRxBytes - lastRxBytes
    local txBPS = nTxBytes - lastTxBytes

    lastRxBytes = nRxBytes
    lastTxBytes = nTxBytes

    return rxBPS .. ',' .. txBPS
  end
end


local fileStat = io.open('/proc/net/dev')
if fileStat == nil then
  ngx.log(ngx.ERR, 'open `/proc/net/dev` fail')
  return
end

local firstRun = true
local getDevTraffic = buildDevTrafficFn('eth0')


local function updateTraffic()
  local r, err = fileStat:seek('set')
  local out = fileStat:read('*all')

  local traffDev = getDevTraffic(out)

  if firstRun then
    firstRun = false
    return
  end

  g.syn()

  local traffHttp = g.update()
  local stat = traffDev .. ',' .. traffHttp

  g.setStat(stat)
end

ngx.timer.every(1, updateTraffic)