const ENC = new TextEncoder()

/**
 * @param {string} str 
 */
export function strToBytes(str) {
  return ENC.encode(str)
}

/**
 * @param {BufferSource} bytes 
 * @param {string} charset 
 */
export function bytesToStr(bytes, charset = 'utf-8') {
  return new TextDecoder(charset).decode(bytes)
}

/**
 * @param {string} label 
 */
export function isUtf8(label) {
  return /^utf-?8$/i.test(label)
}
