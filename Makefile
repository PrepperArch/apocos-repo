PACKAGES=apocos-base apocos-desktop apocos-awesome apocos-hack apocos-sdr

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

apocos-%: | clean-packages build/chroots/root
	git clone https://github.com/PrepperArch/apocos-$*.git build/apocos-$* \
		&& cd $(CURDIR)/build/apocos-$* \
		&& makechrootpkg -c -u -r $(CURDIR)/build/chroots -lapocos-$* -- makepkg -s \
		&& (cp -n *.zst $(CURDIR)/any | true)

build-all: $(PACKAGES) update-repo

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
