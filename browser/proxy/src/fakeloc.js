import * as urlx from "./urlx";


/**
 * @param {string} url 
 */
function decOrigin(url) {
  const u = new URL(url)
  urlx.decUrlObj(u)
  return u.origin
}

function setup(obj, fakeLoc) {
  Reflect.defineProperty(obj, '__location', {
    get() {
      return fakeLoc
    },
    set(val) {
      console.log('[jsproxy] %s set location: %s', obj, val)
      fakeLoc.href = val
    }
  })
}

/**
 * @param {Window} win 
 */
export function init(win) {
  let loc = win.location

  // TODO: iframe 场合下存在问题
  // 比如 youtube 首页缺少这个判断会报错
  if (loc.href === 'about:blank') {
    loc = win.top.location
  }

  const fakeLoc = Object.setPrototypeOf({
    get href() {
      // console.log('[jsproxy] get location.href')
      return urlx.decUrlStr(loc.href)
    },

    get protocol() {
      // TODO: 未考虑非 https 的页面 URL
      return loc.protocol
    },

    get host() {
      // TODO: 未考虑带端口的页面 URL
      // console.log('[jsproxy] get location.host')
      return urlx.decHost(loc.host)
    },

    get hostname() {
      // console.log('[jsproxy] get location.hostname')
      return urlx.decHost(loc.hostname)
    },

    get port() {
      // TODO: 未考虑带端口的页面 URL
      return loc.port
    },

    get pathname() {
      return loc.pathname
    },

    get search() {
      return loc.search
    },

    get hash() {
      return loc.hash
    },

    get origin() {
      // console.log('[jsproxy] get location.origin')
      return decOrigin(loc.origin)
    },

    get ancestorOrigins() {
      // TODO: DOMStringList[]
      // console.log('[jsproxy] get location.ancestorOrigins')
      return [...loc.ancestorOrigins].map(decOrigin)
    },

    set href(val) {
      console.log('[jsproxy] set location.href:', val)
      loc.href = urlx.encUrlStr(val, loc)
    },

    set protocol(val) {
      const u = new URL(loc)
      // TODO: 
    },

    set host(val) {
      console.log('[jsproxy] set location.host:', val)
      // TODO:
    },

    set hostname(val) {
      console.log('[jsproxy] set location.hostname:', val)
      loc.hostname = urlx.encHost(val)
    },

    set port(val) {
      console.log('[jsproxy] set location.port:', val)
      // TODO:
    },

    set pathname(val) {
      loc.pathname = val
    },

    set search(val) {
      loc.search = val
    },

    set hash(val) {
      loc.hash = val
    },

    reload() {
      loc.reload(...arguments)
    },

    replace(val) {
      if (val) {
        console.log('[jsproxy] location.replace:', val)
        arguments[0] = urlx.encUrlStr(val, loc)
      }
      loc.replace(...arguments)
    },

    assign(val) {
      if (val) {
        console.log('[jsproxy] location.assign:', val)
        arguments[0] = urlx.encUrlStr(val, loc)
      }
      loc.assign(...arguments)
    },

    toString() {
      const val = loc.toString(...arguments)
      return urlx.decUrlStr(val)
    },

    toLocaleString() {
      const val = loc.toLocaleString(...arguments)
      return urlx.decUrlStr(val)
    },
  }, loc.constructor.prototype)


  setup(win, fakeLoc)
  setup(win.document, fakeLoc)
}
