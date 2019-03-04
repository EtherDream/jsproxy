import * as urlx from "./urlx";
import * as util from './util.js'
import * as jsfilter from './jsfilter.js'


const RES_HOST = urlx.getMyRootHost()
const HELPER_URL = `//${RES_HOST}/x.js`

// 为了简化注入位置的分析，这里直接插到 HTML 开头
// 所以页面里会出现两个 <!DOCTYPE>
const HTML_BEG = util.strToBytes(
  `<!DOCTYPE html><script src="${HELPER_URL}"></script>`
)

// Worker 
const WORKER_BEG = util.strToBytes(
  `importScripts('${HELPER_URL}');`
)


/**
 * @param {Response} res
 * @param {Object} resOpt
 */
export function htmlRemote(res, resOpt) {
  const reader = res.body.getReader()
  let injected

  const stream = new ReadableStream({
    async pull(controller) {
      if (!injected) {
        injected = true
        controller.enqueue(HTML_BEG)
      }
      const r = await reader.read()
      if (r.done) {
        controller.close()
        return
      }
      controller.enqueue(r.value)
    }
  })
  return new Response(stream, resOpt)
}


// 处理 data、blob 协议的页面
export function htmlLocal(uri) {
  // TODO:
}


/**
 * @param {Response} res
 * @param {Object} resOpt
 */
export async function jsRemote(res, resOpt, charset) {
  // 之后会分析语法树，所以不使用流模式
  const buf = await res.arrayBuffer()
  const ret = await jsfilter.parseBin(buf, charset)
  if (ret) {
    resOpt.headers = new Headers(resOpt.headers)
    resOpt.headers.set('content-type', 'text/javascript')
  }
  return new Response(ret || buf, resOpt)
}


export function workerRemote(res, resOpt, charset) {
  // TODO: 
}


// 处理 data、blob 协议的 Worker
export function workerLocal(data) {
  // TODO: 
}