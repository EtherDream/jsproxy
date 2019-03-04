import * as urlx from './urlx.js'
import * as util from './util.js'
import * as inject from './inject.js'

const TYPE_HTML = 1
const TYPE_JS = 2
const TYPE_WORKER = 2


/**
 * 
 * @param {Request} req 
 * @param {URL} urlObj 
 */
async function forward(req, urlObj, redirNum = 0) {
  const hasCors = (req.mode === 'cors')
  urlx.pack(urlObj, true, hasCors)

  let reqType = 0
  if (req.mode === 'navigate') {
    reqType = TYPE_HTML
  } else {
    const dest = req.destination
    if (dest === 'script') {
      reqType = TYPE_JS
    } else if (dest === 'worker') {
      reqType = TYPE_WORKER
    }
  }

  const reqOpt = {
    // mode: reqType ? 'cors' : req.mode,
    mode: 'cors',
    method: req.method,
    headers: req.headers,
    credentials: req.credentials,
    signal: req.signal,
    // referrerPolicy: 'no-referrer',
    referrer: req.referrer,
  }

  if (req.method === 'POST') {
    // TODO: 解决 stream is lock 的错误
    const buf = await req.arrayBuffer()
    if (buf.byteLength > 0) {
      reqOpt.body = buf
    }
  }

  const res = await fetch(urlObj, reqOpt)
  const resStatus = res.status


  // https://fetch.spec.whatwg.org/#statuses
  const isEmpty =
    (resStatus === 101) ||
    (resStatus === 204) ||
    (resStatus === 205) ||
    (resStatus === 304)

  if (isEmpty) {
    return res
  }

  const resHdr = res.headers
  const resOpt = {
    status: resStatus,
    statusText: res.statusText,
    headers: resHdr,
  }

  // fake redirect
  const isRedir =
    (resStatus === 311) ||
    (resStatus === 312) ||
    (resStatus === 317) ||
    (resStatus === 318)

  if (isRedir) {
    const newUrl = resHdr.get('location')
    if (newUrl) {
      // 重定向到相对路径，是基于请求的 URL 计算（不是页面的 URL）
      const u = new URL(newUrl, urlObj)
      if (req.redirect === 'follow') {
        if (redirNum > 5) {
          return new Response('TOO_MUCH_REDIR')
        }
        return forward(req, u, redirNum + 1)
      }
      urlx.encUrlObj(u)
      // urlx.delFlag(u)
      resOpt.headers = new Headers(resHdr)
      resOpt.headers.set('location', u)
    }
    resOpt.status = resStatus - 10
    return new Response(res.body, resOpt)
  }

  if (reqType === 0) {
    return res
  }

  // content-type: text/html; ...; charset="gbk"
  const ctVal = resHdr.get('content-type') || ''
  const [, mime, charset] = ctVal
    .toLocaleLowerCase()
    .match(/([^;]*)(?:.*?charset=['"]?([^'"]+))?/)

  // if (charset && !util.isUtf8(charset)) {
  //   console.warn('[jsproxy] charset:', charset, urlObj.href)
  // }

  if (reqType === TYPE_HTML) {
    if (mime === 'text/html') {
      return inject.htmlRemote(res, resOpt)
    }
  } else if (reqType === TYPE_JS) {
    return inject.jsRemote(res, resOpt, charset)
  }
  return res
}


async function proxy(e, urlObj) {
  // TODO: 读取本地缓存的资源，以及从本地 CDN 加速
  try {
    return await forward(e.request, urlObj)
  } catch (err) {
    console.warn('[jsproxy] forward err:', err)
  }
}


self.onfetch = function(e) {
  const u = new URL(e.request.url)

  // internal resource (helper.js)
  if (urlx.isMyRootHost(u.host)) {
    return
  }
  if (urlx.isHttpProto(u.protocol)) {
    e.respondWith(proxy(e, u))
  } else {
    console.log('ignore non-http res:', u.href)
  }
}


self.onactivate = function() {
	clients.claim()
}

console.log('[jsproxy] sw inited')
