.ONESHELL:

all:

build/chroots:
	mkdir -p build/chroots

build/chroots/pacman.conf: | build/chroots
	cat /etc/pacman.conf - <<- EOF > $@
		[apocos]
		SigLevel = Optional TrustAll
		Server = https://raw.github.com/PrepperArch/apocos-repo/main/any
	EOF

build/chroots/root: | build/chroots/pacman.conf
	mkarchroot -C $(CURDIR)/build/chroots/pacman.conf $(CURDIR)/build/chroots/root base-devel

apocos-base: clean-packages | build/chroots/root
	git clone https://github.com/PrepperArch/apocos-base.git build/apocos-base \
		&& cd $(CURDIR)/build/apocos-base \
		&& makechrootpkg -c -u -r $(CURDIR)/build/chroots -lapocos-base -- makepkg -s \
		&& mv *.zst $(CURDIR)/any

update-repo:
	repo-add --prevent-downgrade --new \
		$(CURDIR)/any/apocos.db.tar.gz $(CURDIR)/any/*.zst \
	&& repo-add --remove $(CURDIR)/any/apocos.db.tar.gz
	rm $(CURDIR)/any/apocos.db \
		&& mv $(CURDIR)/any/apocos.db.tar.gz $(CURDIR)/any/apocos.db \
		&& ln -s apocos.db $(CURDIR)/any/apocos.db.tar.gz
	rm $(CURDIR)/any/apocos.files \
		&& mv $(CURDIR)/any/apocos.files.tar.gz $(CURDIR)/any/apocos.files \
		&& ln -s apocos.files $(CURDIR)/any/apocos.files.tar.gz

clean:
	sudo rm -rf build/chroots

clean-packages:
	rm -rf build/apocos*
