/**
 * jsproxy cfworker api
 * https://github.com/EtherDream/jsproxy/
 */
'use strict'

const JS_VER = 4

const PREFLIGHT_INIT = {
  status: 204,
  headers: new Headers({
    'access-control-allow-origin': '*',
    'access-control-allow-methods': 'GET,POST,PUT,PATCH,TRACE,DELETE,HEAD,OPTIONS',
    'access-control-allow-headers': '--raw-info,--level,--url,--referer,--cookie,--origin,--ext,--aceh,--ver,--type,--mode,accept,accept-charset,accept-encoding,accept-language,accept-datetime,authorization,cache-control,content-length,content-type,date,if-match,if-modified-since,if-none-match,if-range,if-unmodified-since,max-forwards,pragma,range,te,upgrade,upgrade-insecure-requests,x-requested-with,chrome-proxy,purpose',
    'access-control-max-age': '1728000',
  }),
}


addEventListener('fetch', e => {
  const ret = handler(e.request)
  e.respondWith(ret)
})


/**
 * @param {Request} req
 */
async function handler(req) {
  const reqHdrRaw = req.headers
  if (reqHdrRaw.has('x-jsproxy')) {
    return Response.error()
  }

  // preflight
  if (req.method === 'OPTIONS' &&
      reqHdrRaw.has('access-control-request-headers')
  ) {
    return new Response(null, PREFLIGHT_INIT)
  }

  let urlObj = null
  let extHdrs = null
  let acehOld = false
  let rawSvr = ''
  let rawLen = ''
  let rawEtag = ''

  const reqHdrNew = new Headers(reqHdrRaw)
  reqHdrNew.set('x-jsproxy', '1')

  for (const [k, v] of reqHdrRaw.entries()) {
    if (!k.startsWith('--')) {
      continue
    }
    reqHdrNew.delete(k)

    const k2 = k.substr(2)
    switch (k2) {
    case 'url':
      urlObj = new URL(v)
      break
    case 'aceh':
      acehOld = true
      break
    case 'raw-info':
      [rawSvr, rawLen, rawEtag] = v.split('|')
      break
    case 'level':
    case 'mode':
    case 'type':
      break
    case 'ext':
      extHdrs = JSON.parse(v)
      break
    default:
      if (v) {
        reqHdrNew.set(k2, v)
      } else {
        reqHdrNew.delete(k2)
      }
      break
    }
  }
  if (extHdrs) {
    for (const [k, v] of Object.entries(extHdrs)) {
      reqHdrNew.set(k, v)
    }
  }
  const reqInit = {
    method: req.method,
    headers: reqHdrNew,
  }
  return proxy(urlObj, reqInit, acehOld, rawLen, 0)
}


/**
 * 
 * @param {URL} urlObj 
 * @param {RequestInit} reqInit 
 * @param {number} retryTimes 
 */
async function proxy(urlObj, reqInit, acehOld, rawLen, retryTimes) {
  const res = await fetch(urlObj.href, reqInit)
  const resHdrOld = res.headers
  const resHdrNew = new Headers(resHdrOld)

  let expose = '*'
  let vary = '--url'
  
  for (const [k, v] of resHdrOld.entries()) {
    if (k === 'access-control-allow-origin' ||
        k === 'access-control-expose-headers' ||
        k === 'location' ||
        k === 'set-cookie'
    ) {
      const x = '--' + k
      resHdrNew.set(x, v)
      if (acehOld) {
        expose = expose + ',' + x
      }
      resHdrNew.delete(k)
    }
    else if (k === 'vary') {
      vary = vary + ',' + v
    }
    else if (acehOld &&
      k !== 'cache-control' &&
      k !== 'content-language' &&
      k !== 'content-type' &&
      k !== 'expires' &&
      k !== 'last-modified' &&
      k !== 'pragma'
    ) {
      expose = expose + ',' + k
    }
  }

  if (acehOld) {
    expose = expose + ',--s'
    resHdrNew.set('--t', '1')
  }

  resHdrNew.set('access-control-expose-headers', expose)
  resHdrNew.set('access-control-allow-origin', '*')
  resHdrNew.set('vary', vary)
  resHdrNew.set('--s', res.status)

  // verify
  const newLen = resHdrOld.get('content-length') || ''
  const badLen = (rawLen !== newLen)

  let status = 200
  let body = res.body

  if (badLen) {
    if (retryTimes < 1) {
      urlObj = await parseYtVideoRedir(urlObj, newLen, res)
      if (urlObj) {
        return proxy(urlObj, reqInit, acehOld, rawLen, retryTimes + 1)
      }
    }
    status = 400
    body = `bad len (old: ${rawLen} new: ${newLen})`
    resHdrNew.set('cache-control', 'no-cache')
  }

  resHdrNew.set('--retry', retryTimes)
  resHdrNew.set('--ver', JS_VER)

  return new Response(body, {
    status,
    headers: resHdrNew,
  })
}


/**
 * @param {URL} urlObj 
 */
function isYtUrl(urlObj) {
  return (
    urlObj.host.endsWith('.googlevideo.com') &&
    urlObj.pathname.startsWith('/videoplayback')
  )
}

/**
 * @param {URL} urlObj 
 * @param {number} newLen 
 * @param {Response} res 
 */
async function parseYtVideoRedir(urlObj, newLen, res) {
  if (newLen > 2000) {
    return null
  }
  if (!isYtUrl(urlObj)) {
    return null
  }
  try {
    const data = await res.text()
    urlObj = new URL(data)
  } catch (err) {
    return null
  }
  if (!isYtUrl(urlObj)) {
    return null
  }
  return urlObj
}