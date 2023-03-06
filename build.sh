esbuild \
	app.js \
--bundle --minify --format=esm --legal-comments=none --outfile=dist/app.min.js --charset=utf8 $1

# parcel-css --minify --bundle --targets '>= 0.25%' dist/styles.css -o dist/styles.min.css