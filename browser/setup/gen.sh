DST=../../server/www/__setup.html

html-minifier \
  --collapse-whitespace \
  --remove-comments \
  --remove-optional-tags \
  --remove-redundant-attributes \
  --remove-script-type-attributes \
  --remove-tag-whitespace \
  --use-short-doctype \
  --remove-attribute-quotes \
  --minify-css true \
  --minify-js '{"toplevel": true, "ie8": true}' \
  -o $DST \
  index.html

brotli -f $DST
