import * as util from './util.js'


/**
 * @param {string} code 
 */
export function parseSync(code) {
  // TODO: parse js ast
  let match
  code = code.replace(/(\b)location(\b)/g, (s, $1, $2) => {
    match = true
    return $1 + '__location' + $2
  })
  if (match) {
    return code
  }
}

/**
 * @param {Uint8Array} buf
 */
export async function parseBin(buf, charset) {
  const str = util.bytesToStr(buf, charset)
  const ret = parseSync(str)
  if (ret) {
    return util.strToBytes(ret)
  }
  if (!util.isUtf8(charset)) {
    return util.strToBytes(str)
  }
}