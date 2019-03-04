function main() {
  if ('onclick' in self) {
    // page env
    return require('./page.js')
  }
  if ('onfetch' in self) {
    // sw env
    return require('./sw.js')
  }
  return require('./worker.js')
}

main()