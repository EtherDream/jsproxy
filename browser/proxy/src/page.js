import {createHook} from './hook.js'
import * as urlx from './urlx.js'
import * as util from './util.js'
import * as nav from './nav.js'
import * as jsfilter from './jsfilter.js'
import * as fakeloc from './fakeloc.js'


/**
 * @param {Window} win 
 */
function initWin(win) {
  if (!win) {
    return
  }
  try {
    if (win.Math.__flag) {
      return  // setuped
    }
    win.Math.__flag = 1
  } catch (err) {
    return    // not same origin
  }

  const {
    // WeakSet,
    // Reflect,
    // RegExp,
    // URL,
    // Proxy,
    document,
    location,
    navigator,
  } = win

  const {
    apply,
    construct,
  } = Reflect

  const isExtPageMode = urlx.isMyExtHost(location.hostname)

  // hook Function
  // hook.func(window, 'Function', oldFn => function() {
  //   return apply(oldFn, this, arguments)
  // })

  const hook = createHook(win)
  nav.init(win, hook)

  // hook window/document.location
  fakeloc.init(win, hook)


  // hook document.domain
  const docProto = win.Document.prototype

  hook.prop(docProto, 'domain',
    getter => function() {
      const val = getter.call(this)
      return urlx.decHost(val)
    },
    setter => function(val) {
      if (isExtPageMode) {
        console.warn('[jsproxy] unsafe domain')
        val = urlx.getMyExtHost()
      } else {
        val = urlx.encHost(val)
      }
      setter.call(this, val)
    }
  )

  // hook document.cookie
  const R_COOKIE_DOMAIN = /(?<=;\s*domain=)[^;]+/i

  hook.prop(docProto, 'cookie', null,
    setter => function(val) {
      val = val.replace(R_COOKIE_DOMAIN, rHost => {
        if (isExtPageMode) {
          return ''
        }
        if (rHost[0] === '.') {
          rHost = rHost.substr(1)
        }
        const vHost = urlx.encHost(rHost)
        if (urlx.isMyRootHost(vHost)) {
          console.warn('[jsproxy] invalid cookie domain:', rHost, vHost)
        }
        return vHost
      })
      setter.call(this, val)
    }
  )

  // uri api
  function getUriHook(getter) {
    return function() {
      const val = getter.call(this)
      return urlx.decUrlStr(val)
    }
  }
  hook.prop(docProto, 'referrer', getUriHook)
  hook.prop(docProto, 'URL', getUriHook)
  hook.prop(docProto, 'documentURI', getUriHook)
  hook.prop(win.Node.prototype, 'baseURI', getUriHook)


  // disable ServiceWorker
  const swProto = win.ServiceWorkerContainer.prototype
  if (swProto) {
    hook.func(swProto, 'register', oldFn => function() {
      console.warn('access serviceWorker.register blocked')
      return new Promise(function() {})
    })
    hook.func(swProto, 'getRegistration', oldFn => function() {
      console.warn('access serviceWorker.getRegistration blocked')
      return new Promise(function() {})
    })
    hook.func(swProto, 'getRegistrations', oldFn => function() {
      console.warn('access serviceWorker.getRegistrations blocked')
      return new Promise(function() {})
    })
  }

  //
  // hook history
  //
  function historyStateHook(oldFn) {
    return function(_0, _1, url) {
      if (url) {
        arguments[2] = urlx.encUrlStr(url, location)
      }
      // console.log('[jsproxy] history.replaceState', url)
      return apply(oldFn, this, arguments)
    }
  }
  const historyProto = win.History.prototype
  hook.func(historyProto, 'pushState', historyStateHook)
  hook.func(historyProto, 'replaceState', historyStateHook)


  //
  hook.func(navigator, 'registerProtocolHandler', oldFn => function(_0, url, _1) {
    console.log('registerProtocolHandler:', arguments)
    return apply(oldFn, this, arguments)
  })
  

  // hook Performance API
  hook.prop(win.PerformanceEntry.prototype, 'name', getUriHook)

  //
  // hook iframe
  //
  const iframeProto = win.HTMLIFrameElement.prototype
  hook.prop(iframeProto, 'contentWindow',
    getter => function() {
      const win = getter.call(this)
      initWin(win)
      return win
    }
  )

  hook.prop(iframeProto, 'contentDocument',
    getter => function() {
      const doc = getter.call(this)
      if (doc) {
        initWin(doc.defaultView)
      }
      return doc
    }
  )

  
  hook.attr('IFRAME', iframeProto, {
    name: 'src',
    onget(val) {
      return urlx.decUrlStr(val)
    },
    onset(val) {
      val = urlx.encUrlStr(val, location)
      console.log('[jsproxy] set <iframe> src', val)
      return val
    }
  })


  const embedProto = win.HTMLEmbedElement.prototype
  hook.attr('EMBED', embedProto, {
    name: 'src',
    onget(val) {
      console.log('[jsproxy] get <embed> src:', val)
      return val
    },
    onset(val) {
      console.log('[jsproxy] set <embed> src:', val)
      return val
    }
  })


  const objectProto = win.HTMLObjectElement.prototype
  hook.attr('OBJECT', objectProto, {
    name: 'data',
    onget(val) {
      console.log('[jsproxy] get <object> src:', val)
      return val
    },
    onset(val) {
      console.log('[jsproxy] set <object> src:', val)
      return val
    }
  })


  const frames = win.frames

  win.frames = new Proxy(frames, {
    get(_, key) {
      if (typeof key === 'number') {
        console.log('get frames index:', key)
        const win = frames[key]
        initWin(win)
        return win
      } else {
        return frames[key]
      }
    }
  })

  //
  // hook message origin
  //
  hook.func(win, 'postMessage', oldFn => function(msg, origin) {
    // origin 必须是完整的 URL（不接受 // 开头的相对协议）
    if (origin && origin !== '*') {
      arguments[1] = urlx.encUrlStr(origin)
    }
    return apply(oldFn, this, arguments)
  })

  hook.prop(win.MessageEvent.prototype, 'origin', getUriHook)

  //
  // hook xhr
  //
  const xhrProto = win.XMLHttpRequest.prototype
  hook.func(xhrProto, 'open', oldFn => function(_0, url, async) {
    if (url) {
      arguments[1] = urlx.encUrlStr(url, location)
    }
    if (async === false) {
      console.log('[jsproxy] sync xhr is disabled')
      arguments[2] = true
    }
    return apply(oldFn, this, arguments)
  })


  hook.func(win, 'fetch', oldFn => function(v) {
    if (v && v.url) {
      // v is Request
      url = urlx.encUrlStr(url)
      arguments[0] = new Request(url, v)
    } else {
      // v is string
      arguments[0] = urlx.encUrlStr(v, location)
    }
    return apply(oldFn, this, arguments)
  })


  // hook Worker
  function workHook(oldFn) {
    return function(url) {
      if (url) {
        console.log('[jsproxy] new worker:', url)
        arguments[0] = urlx.encUrlStr(url, location)
      }
      return construct(oldFn, arguments)
    }
  }
  hook.func(win, 'Worker', workHook)
  hook.func(win, 'SharedWorker', workHook)


  // hook WebSocket
  hook.func(win, 'WebSocket', oldFn => function(url) {
    if (url) {
      const u = new URL(url)
      urlx.pack(u, true, true)
      arguments[0] = u.href
    }
    return construct(oldFn, arguments)
  })


  const scriptProto = win.HTMLScriptElement.prototype

  hook.attr('SCRIPT', scriptProto,
  // 强制使用 utf-8 编码，方便 SW 编码
  {
    name: 'charset',
    onget(val) {
      return this._charset || val
    },
    onset(val) {
      if (!util.isUtf8(val)) {
        val = 'utf-8'
      }
      this._charset = val
      return val
    }
  },
  // 禁止设置内容校验
  {
    name: 'integrity',
    onget(val) {
      return this._integrity
    },
    onset(val) {
      this._integrity = val
      return ''
    }
  },
  {
    name: 'innerText',
    onget(val) {
      return val
    },
    onset(val) {
      updateScript(this)
      return val
    }
  })

  // text 属性只有 prop 没有 attr
  let scriptTextSetter

  function scriptGetJs(getter) {
    return function() {
      return getter.call(this)
    }
  }
  function scriptSetJs(setter) {
    scriptTextSetter = setter

    return function(val) {
      updateScript(this)
      setter.call(this, val)
    }
  }
  hook.prop(scriptProto, 'text', scriptGetJs, scriptSetJs)

  const JS_MIME = {
    '': true,
    'text/javascript': true,
    'application/javascript': true,
    'module': true,
  }
  
  /**
   * @param {HTMLScriptElement} elem 
   */
  function updateScript(elem) {
    const type = elem.type
    if (!JS_MIME[type]) {
      return
    }
    const code = elem.text
    if (!code) {
      return
    }
    if (elem.__parsed) {
      return
    }
    const ret = jsfilter.parseSync(code)
    if (ret) {
      scriptTextSetter.call(elem, ret)
    }
    elem.__parsed = true
  }
}

initWin(self)

if (self !== parent) {
  parent.postMessage('__READY', '*')
}

document.currentScript.remove()
console.log('[jsproxy] helper inited', location.href)
