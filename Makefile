update: $(shell find src -print)
	gostatic config -v
site: site-check site-build
site-check:
	git diff --exit-code src Makefile config site.tmpl
site-build: $(shell find src -print) Makefile config site.tmpl last-commit-message.txt
	rm -rf site/*
	gostatic config -v -f
	cd site
	git add .
	git commit -F ../last-commit-message.txt
push: site
	git push
	cd site
	git push
last-commit-message.txt:
	git log --format=%B -n 1
