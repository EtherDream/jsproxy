import * as urlx from './urlx.js';

/**
 * page navigate intercept
 * 
 * @param {Window} win 
 * @param {Hook} hook 
 */
export function init(win, hook) {
  const {
    location,
    Reflect,
  } = win

  const {
    apply,
  } = Reflect

  const linkProto = win.HTMLAnchorElement.prototype
  const areaProto = win.HTMLAreaElement.prototype
  const formProto = win.HTMLFormElement.prototype

  function hookNavAttr(tag, proto, name) {
    hook.attr(tag, proto, {
      name,
      onget(val) {
        const u = new URL(val, location)
        urlx.unpack(u)
        return u.href
      },
      onset(val) {
        const u = new URL(val, location)
        urlx.pack(u, false, false)
        return u.href
      }
    })
  }
  hookNavAttr('A', linkProto, 'href')
  hookNavAttr('AREA', areaProto, 'href')
  hookNavAttr('FORM', formProto, 'action')


  // TODO:
  function hookLinkProp(proto) {
    hook.prop(proto, 'hostname',
      getter => function() {
        const val = getter.call(this)
        return val
      },
      setter => function(val) {
        console.log('[jsproxy] set link hostname:', val)
        setter.call(this, val)
      }
    )

    hook.prop(proto, 'host',
      getter => function() {
        const val = getter.call(this)
        return val
      },
      setter => function(val) {
        console.log('[jsproxy] set link host:', val)
        setter.call(this, val)
      }
    )

    hook.prop(proto, 'protocol',
      getter => function() {
        const val = getter.call(this)
        return val
      },
      setter => function(val) {
        console.log('[jsproxy] set link protocol:', val)
        setter.call(this, val)
      }
    )

    hook.prop(proto, 'port',
      getter => function() {
        const val = getter.call(this)
        return val
      },
      setter => function(val) {
        console.log('[jsproxy] set link port:', val)
        setter.call(this, val)
      }
    )

    hook.prop(proto, 'search',
      getter => function() {
        const val = getter.call(this)
        return val
      },
      setter => function(val) {
        console.log('[jsproxy] set link search:', val)
        setter.call(this, val)
      }
    )
  }
  hookLinkProp(linkProto)
  hookLinkProp(areaProto)

  /**
   * @param {HTMLAnchorElement | HTMLAreaElement | HTMLFormElement} el 
   * @param {string} prop 
   */
  function processElem(el, prop) {
    const urlStr = el[prop]
    if (urlStr) {
      el[prop] = urlStr
    }
  }

  function linkClickHook(oldFn) {
    return function() {
      processElem(this, 'href')
      return apply(oldFn, this, arguments)
    }
  }
  hook.func(linkProto, 'click', linkClickHook)
  hook.func(areaProto, 'click', linkClickHook)
  hook.func(formProto, 'submit', oldFn => function() {
    processElem(this, 'action')
    return apply(oldFn, this, arguments)
  })


  // hook window.open()
  hook.func(win, 'open', oldFn => function(url) {
    if (url) {
      const u = new URL(url, location)
      urlx.pack(u, false, false)
      arguments[0] = u.href
    }
    return apply(oldFn, this, arguments)
  })


  //
  // hook <base>
  //
  const baseProto = win.HTMLBaseElement.prototype

  hook.attr('BASE', baseProto, {
    name: 'href',
    onget(val) {
      return urlx.decUrlStr(val)
    },
    onset(val) {
      // console.log('[jsproxy] set base.href:', val)
      // val = getFinalUrl(val)
      return urlx.encUrlStr(val, location)
    }
  })

  //
  // hook <meta>
  //
  const metaProto = win.HTMLMetaElement.prototype

  hook.attr('META', metaProto, {
    name: 'http-equiv',
    onget(val) {
      // TODO: 
      return val
    },
    onset(val) {
      return val
    }
  })
}