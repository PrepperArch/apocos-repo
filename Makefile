PACKAGES=\
	apocos-base apocos-desktop apocos-awesome apocos-hack apocos-sdr

.ONESHELL:

all:

build/chroots:
	mkdir -p build/chroots

build/chroots/pacman.conf: | build/chroots
	cat /etc/pacman.conf - <<- 'EOF' > $@
		[apocos]
		SigLevel = Optional TrustAll
		Server = https://raw.github.com/PrepperArch/apocos-repo/main/$$arch
	EOF

build/chroots/root: | build/chroots/pacman.conf
	mkarchroot -C $(CURDIR)/build/chroots/pacman.conf $(CURDIR)/build/chroots/root base-devel

build/Packages:
	git clone https://github.com/PrepperArch/Packages  build/Packages

update-packages: build/Packages
	cd $(CURDIR)/build/Packages && git pull

build-package-%: | update-packages build/chroots/root
	cd $(CURDIR)/build/Packages/$* \
		&& makechrootpkg -c -u -r $(CURDIR)/build/chroots -l$* -- makepkg -s \
		&& (cp -n *.zst $(CURDIR)/any | true)

build-sdr-package-%: | update-packages build/chroots/root
	cd $(CURDIR)/build/Packages/sdr/$* \
		&& makechrootpkg -c -u -r $(CURDIR)/build/chroots -l$* -- makepkg -s \
		&& (cp -n *.zst $(CURDIR)/x86_64 | true)

update-repo-%:
	repo-add --prevent-downgrade --new \
		$(CURDIR)/any/apocos.db.tar.gz $(CURDIR)/$*/*.zst \
		&& repo-add --remove $(CURDIR)/$*/apocos.db.tar.gz
	rm $(CURDIR)/$*/apocos.db \
		&& mv $(CURDIR)/$*/apocos.db.tar.gz $(CURDIR)/$*/apocos.db \
		&& ln -s apocos.db $(CURDIR)/$*/apocos.db.tar.gz
	rm $(CURDIR)/$*/apocos.files \
		&& mv $(CURDIR)/$*/apocos.files.tar.gz $(CURDIR)/$*/apocos.files \
		&& ln -s apocos.files $(CURDIR)/$*/apocos.files.tar.gz

clean:
	sudo rm -rf build

