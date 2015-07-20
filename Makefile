sources = $(shell find src -print) Makefile config site.tmpl

update: $(sources)
	gostatic config -v

site: .NOTPARALLEL site-check site-build
site-check:
	git diff --exit-code $(sources)
site-build: $(sources) last-commit-message.txt
	rm -rf site/*
	gostatic config -v -f
	( cd site && git diff --exit-code >/dev/null || ( git add . && git commit -F ../last-commit-message.txt ) )

push: site
	git push
	( cd site && git push )

last-commit-message.txt: .FORCE
	git log --format=%B -n 1 > $@

.FORCE:
.NOTPARALLEL:
