export const DELETE = {}
export const RETURN = {}

/**
 * @param {Window} win 
 */
export function createHook(win) {
  // const {
  //   Reflect,
  //   WeakMap,
  // } = win

  const {
    apply,
    getOwnPropertyDescriptor,
    defineProperty,
  } = Reflect

  const rawMap = new WeakMap()


  /**
   * hook function
   * 
   * @param {object} obj 
   * @param {string} key 
   * @param {Function} factory 
   */
  function func(obj, key, factory) {
    const oldFn = obj[key]
    if (!oldFn) {
      return false
    }
    const newFn = factory(oldFn)
    for (const k in oldFn) {
      newFn[k] = oldFn[k]
    }
    newFn.prototype = oldFn.prototype
    rawMap.set(newFn, oldFn)
    obj[key] = newFn
    return true
  }

  /**
   * hook property
   * 
   * @param {object} obj 
   * @param {string} key 
   * @param {Function} g 
   * @param {Function} s 
   */
  function prop(obj, key, g, s) {
    const desc = getOwnPropertyDescriptor(obj, key)
    if (!desc) {
      return false
    }
    if (g) {
      func(desc, 'get', g)
    }
    if (s) {
      func(desc, 'set', s)
    }
    defineProperty(obj, key, desc)
    return true
  }


  function hookElemProp(proto, name, onget, onset) {
    prop(proto, name,
      getter => function() {
        const val = getter.call(this)
        return onget.call(this, val)
      },
      setter => function(val) {
        const ret = onset.call(this, val)
        if (ret !== null) {
          val = ret
        }
        setter.call(this, val)
      }
    )
  }

  const toLCase = ''.toLocaleLowerCase
  const elemProto = win.Element.prototype
  const rawGetAttr = elemProto.getAttribute
  const rawSetAttr = elemProto.setAttribute

  const tagAttrHandlersMap = {}
  const tagTextHandlerMap = {}
  const tagKeySetMap = {}
  const tagKeyGetMap = {}


  function attr(tag, proto, ...handlers) {
    let hasBind, hasAttr
    let keySetMap, keyGetMap

    handlers.forEach(v => {
      // 划线转驼峰（'http-equiv' -> 'httpEquiv'）
      const name = v.name.replace(/-(\w)/g, (_, $1) => {
        return $1.toUpperCase()
      })
      hookElemProp(proto, name, v.onget, v.onset)

      // #text
      if (name === 'innerText') {
        tagTextHandlerMap[tag] = v
        return
      }

      // attribute
      if (tagAttrHandlersMap[tag]) {
        tagAttrHandlersMap[tag].push(v)
        hasBind = true
      } else {
        tagAttrHandlersMap[tag] = [v]
        tagKeySetMap[tag] = {}
        tagKeyGetMap[tag] = {}
      }

      if (!keySetMap) {
        keySetMap = tagKeySetMap[tag]
        keyGetMap = tagKeyGetMap[tag]
      }
      const key = toLCase.call(name)
      keySetMap[key] = v.onset
      keyGetMap[key] = v.onget
      hasAttr = true
    })

    if (hasBind || !hasAttr) {
      return
    }

    // 如果之前调用过 setAttribute，那么直接返回上次设置的值。
    // 如果没有调用过则回调 onget
    func(proto, 'getAttribute', oldFn => function(name) {
      const key = toLCase.call(name)
      const get = keyGetMap[key]
      if (get) {
        const lastVal = this['_k' + key]
        if (lastVal !== undefined) {
          return lastVal
        }
        const val = apply(oldFn, this, arguments)
        return get(val)
      }
      return apply(oldFn, this, arguments)
    })

    func(proto, 'setAttribute', oldFn => function(name, val) {
      const key = toLCase.call(name)
      const set = keySetMap[key]
      if (set) {
        this['_k' + key] = val

        const ret = set.call(this, val)
        if (ret === DELETE) {
          this.removeAttribute(key)
          return
        }
        if (ret === RETURN) {
          return
        }
        arguments[1] = ret
      }
      return apply(oldFn, this, arguments)
    })

    // TODO: setAttributeNode
    // ...
  }

  /**
   * @param {Text} node
   * @param {object} handler
   * @param {Element} elem 
   */
  function parseNewTextNode(node, handler, elem) {
    const val = node.nodeValue
    const ret = handler.onset.call(elem, val)
    if (ret === DELETE) {
      node.remove()
      return
    }
    if (ret === RETURN) {
      return
    }
    node.nodeValue = ret
  }

  /**
   * @param {Element} elem 
   * @param {object} handler
   */
  function parseNewElemNode(elem, handler) {
    const name = handler.name
    if (!elem.hasAttribute(name)) {
      return
    }
    const val = rawGetAttr.call(elem, name)
    const ret = handler.onset.call(elem, val)
    if (ret === DELETE) {
      elem.removeAttribute(name)
      return
    }
    if (ret === RETURN) {
      return
    }
    rawSetAttr.call(elem, name, ret)
  }

  /**
   * @param {MutationRecord[]} mutations 
   */
  function parseMutations(mutations) {
    mutations.forEach(mutation => {
      mutation.addedNodes.forEach(node => {
        switch (node.nodeType) {
        case 1:   // ELEMENT_NODE
          const handlers = tagAttrHandlersMap[node.tagName]
          handlers && handlers.forEach(v => {
            parseNewElemNode(node, v)
          })
          break
        case 3:   // TEXT_NODE
          const elem = node.parentElement
          if (elem) {
            const handler = tagTextHandlerMap[elem.tagName]
            if (handler) {
              parseNewTextNode(node, handler, elem)
            }
          }
          break
        }
      })
    })
  }


  const observer = new win.MutationObserver(parseMutations)
  observer.observe(win.document, {
    childList: true,
    subtree: true,
  })

  // win.addEventListener('DOMContentLoaded', e => {
  //   parseMutations(observer.takeRecords())
  //   observer.disconnect()
  // })

  // hide source code
  func(Function.prototype, 'toString', oldFn => function() {
    return apply(oldFn, rawMap.get(this) || this, arguments)
  })
  
  return {
    func,
    prop,
    attr,
  }
}