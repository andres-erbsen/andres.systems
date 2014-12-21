update: $(shell find src -print)
	gostatic config -v
site: $(shell find src -print)
	rm -rf site
	gostatic config -v -f
rsync-athena: site
	rsync -zaruv --delete site/. athena:web_scripts/.
