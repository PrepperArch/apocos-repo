all:

update:
	repo-add --prevent-downgrade --new \
		$(CURDIR)/any/apocos.db.tar.gz $(CURDIR)/any/*.zst \
	&& repo-add --remove $(CURDIR)/any/apocos.db.tar.gz
	rm $(CURDIR)/any/apocos.db \
		&& mv $(CURDIR)/any/apocos.db.tar.gz $(CURDIR)/any/apocos.db \
		&& ln -s apocos.db $(CURDIR)/any/apocos.db.tar.gz
	rm $(CURDIR)/any/apocos.files \
		&& mv $(CURDIR)/any/apocos.files.tar.gz $(CURDIR)/any/apocos.files \
		&& ln -s apocos.files $(CURDIR)/any/apocos.files.tar.gz
