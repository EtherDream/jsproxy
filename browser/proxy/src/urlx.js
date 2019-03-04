import {MY_ROOT, HOST_LIST} from './hostlist.js'

const MY_ROOT_DOT = '.' + MY_ROOT
const MY_EXT = 'ext' + MY_ROOT_DOT
const MY_EXT_DOT = '.' + MY_EXT

const HOST_ENC_MAP = {}
const HOST_DEC_MAP = {}

HOST_LIST.forEach(([alias, rHost]) => {
  HOST_ENC_MAP[rHost] = alias
  HOST_DEC_MAP[alias] = rHost
})


export function getMyRootHost() {
  return MY_ROOT
}

export function getMyExtHost() {
  return MY_EXT
}

function makeReg(tmpl, map, suffix = '') {
  const list = Object.keys(map)
    .join('|')
    .replace(/\./g, '\\.')

  const [a, b, c] = tmpl.raw
  if (suffix) {
    suffix = suffix.replace(/\./g, '\\.') + c
  }
  return RegExp(a + list + b + suffix)
}

const R_HOST_ENC = makeReg`^([\w-]+\.)??(${HOST_ENC_MAP})$`
const R_HOST_DEC = makeReg`^([\w-]+\.)??(${HOST_DEC_MAP})${MY_ROOT_DOT}$`


/**
 * encode host (rHost to vHost)
 * 
 * @param {string} rHost
 * @example
 *  'twitter.com' -> 'tw.mysite.net'
 *  'www.google.com' -> 'www.gg.mysite.net'
 *  'www.google.com.hk' -> 'www.gk.mysite.net'
 *  'unsupport.com' -> 'unsupport-dot-com.mysite.net'
 *  'not-support.com' -> 'not-support-dot-com.mysite.net'
 *  '*.mysite.net' -> '*.mysite.net'
 *  'mysite.net' -> 'mysite.net'
 */
function _encHost(rHost) {
  if (isMyHost(rHost)) {
    return rHost
  }
  // 内置域名（替换成短别名）
  const m = rHost.match(R_HOST_ENC)
  if (m) {
    const [, sub, root] = m
    const vHost = HOST_ENC_MAP[root]
    if (vHost) {
      return (sub || '') + vHost + MY_ROOT_DOT
    }
  }
  // 外置域名（将 `.` 替换成 `-dot-`）
  if (rHost.includes('-dot-')) {
    console.warn('invalid host:', rHost)
    return rHost
  }
  return rHost.replace(/\./g, '-dot-') + MY_EXT_DOT
}

/**
 * decode host (vHost to rHost)
 * 
 * @param {string} vHost
 * @returns {string}
 *  return *null* if vHost not ends with `HOST_SUFFIX`
 *  or not in `HOST_LIST`
 * 
 * @example
 *  'gg.mysite.net' -> 'google.com'
 *  'www.gg.mysite.net' -> 'www.google.com'
 *  'not-support-dot-com.mysite.net' -> 'not-support.com'
 *  'www-dot-mysite-dot-net.mysite.net' -> 'www.mysite.net'
 *  'www.google.com' -> null
 *  'x.mysite.net' -> null
 */
function _decHost(vHost) {
  if (isMyExtHost(vHost)) {
    return vHost
      .slice(0, -MY_EXT_DOT.length)
      .replace(/-dot-/g, '.')
  }
  const m = vHost.match(R_HOST_DEC)
  if (m) {
    const [, sub, root] = m
    const rHost = HOST_DEC_MAP[root]
    if (rHost) {
      return (sub || '') + rHost
    }
  }
  return null
}

const encCache = {}
const decCache = {}

/**
 * @param {string} rHost 
 */
export function encHost(rHost) {
  let ret = encCache[rHost]
  if (!ret) {
    ret = _encHost(rHost)
    encCache[rHost] = ret
  }
  return ret
}

export function decHost(vHost) {
  let ret = decCache[vHost]
  if (!ret) {
    ret = _decHost(vHost)
    decCache[vHost] = ret
  }
  return ret
}


/**
 * @param {string} host 
 */
export function isMyHost(host) {
  return isMyRootHost(host) || isMySubHost(host)
}

/**
 * @param {string} host 
 */
export function isMyRootHost(host) {
  return host === MY_ROOT
}

/**
 * @param {string} host 
 */
export function isMySubHost(host) {
  return host.endsWith(MY_ROOT_DOT)
}

/**
 * @param {string} host 
 */
export function isMyExtHost(host) {
  return host.endsWith(MY_EXT_DOT)
}


/**
 * @param {string} path 
 */
export function isHttpProto(path) {
  return /^https?:/.test(path)
}


/**
 * encode urlObj.hostname to vHost
 * 
 * @param {URL} urlObj
 */
export function encUrlObj(urlObj) {
  urlObj.hostname = encHost(urlObj.hostname)
}


/**
 * @param {URL} urlObj
 * @returns {boolean}
 */
export function decUrlObj(urlObj) {
  const host = decHost(urlObj.hostname)
  if (host) {
    urlObj.hostname = host
  }
  return !!host
}


/**
 * @param {string} url 
 *  需编码的 URL 字符串，可以是完整 URL，或相对路径、相对协议。
 * 
 * @param {string | URL} baseUrl
 *  如果 url 不完整，需指定一个基地址。
 *  如果未指定基地址，并且 url 不完整，则返回 url 本身。
 */
export function encUrlStr(url, baseUrl) {
  if (!url) {
    return url
  }
  try {
    var urlObj = new URL(url, baseUrl)
  } catch (err) {
    return url
  }
  encUrlObj(urlObj)
  return urlObj.href
}


/**
 * @param {string} url 
 */
export function decUrlStr(url) {
  if (!url) {
    return url
  }
  try {
    var urlObj = new URL(url)
  } catch (err) {
    return url
  }
  return decUrlObj(urlObj) ? urlObj.href : url
}


/**
 * @param {URL} urlObj
 * @param {boolean} hasSw
 * @param {boolean} hasCors
 */
export function pack(urlObj, hasSw, hasCors) {
  let unsafe = false

  switch (urlObj.protocol) {
  case 'https:':
    break
  case 'wss:':
    break
  case 'http:':
    unsafe = true
    urlObj.protocol = 'https:'
    break
  case 'ws:':
    unsafe = true
    urlObj.protocol = 'wss:'
    break
  default:
    // 例如 chrome-extension:
    return
  }

  encUrlObj(urlObj)

  const port = urlObj.port

  // 都未设置，则不加 flag
  if (!hasSw && !unsafe && !hasCors && !port) {
    return
  }

  if (port && port !== '443') {
    urlObj.port = '443'
  }

  let flag = '' +
    (+hasSw) +
    (+unsafe) +
    (+hasCors) +
    port

  //
  // 使用 urlObj.searchParams 设置参数会对已有参数进行编码，例如：
  // new URL('https://s.yimg.com/zz/combo?yui:/3.12.0/yui/yui-min.js')
  // 设置参数后 :/ 等字符会被编码，导致资源无法加载。
  //
  let args = urlObj.search

  urlObj.search = args.replace(/&flag__=[^&]*|$/, _ => {
    // 出现 ?&flag= 也没事，后端用同样的方法删除该标记
    return (args ? '' : '?') + '&flag__=' + flag
  })
}

// /**
//  * @param {URL} urlObj 
//  */
// export function delFlag(urlObj) {
//   urlObj.search = urlObj.search.replace(/&flag__=[^&]*/, '')
// }

/**
 * @param {URL} urlObj 
 */
export function unpack(urlObj) {
  const flag = urlObj.searchParams.get('flag__')
  if (!flag) {
    return
  }
  const unsafe = (flag[1] === '1')
  const port = flag.substr(3)

  switch (urlObj.protocol) {
  case 'https:':
    if (unsafe) {
      urlObj.protocol = 'http:'
    }
    break
  case 'wss:':
    if (unsafe) {
      urlObj.protocol = 'ws:'
    }
    break
  default:
    console.warn('unpack:', urlObj)
    return
  }
  if (port) {
    urlObj.port = port
  }

  decUrlObj(urlObj)
}