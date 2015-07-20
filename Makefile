update: $(shell find src -print)
	gostatic config -v
site: site-check site-build
site-build: $(shell find src -print) Makefile config site.tmpl
	rm -rf site/*
	gostatic config -v -f
	cd site
	git commit -m regenerate -a
site-check: $(shell find src -print) Makefile config site.tmpl
	git diff --exit-code src Makefile config site.tmpl
push: site
	git push
	cd site
	git push
