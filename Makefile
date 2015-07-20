update: $(shell find src -print)
	gostatic config -v
site: $(shell find src -print)
	git diff --exit-code
	rm -rf site/*
	gostatic config -v -f
	cd site
	git commit -m regenerate -a
push: site
	git push
	cd site
	git push
