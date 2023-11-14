PACKAGES=\
	apocos-base apocos-desktop apocos-awesome apocos-hack apocos-sdr

.ONESHELL:

all:

build/chroots:
	mkdir -p build/chroots

build/chroots/apocos.mirrorlist: | build/chroots
	cat << 'EOF' > $@
		# Apocalypse OS Mirrors
		Server = https://prepperarch.github.io/apocos-repo/$$arch
	EOF

build/chroots/pacman.conf: | build/chroots
	cat /etc/pacman.conf - <<- EOF > $@
		[apocos]
		SigLevel = Optional TrustAll
		Include = $(CURDIR)/build/chroots/apocos.mirrorlist
	EOF

build/chroots/pacman_chroot.conf: | build/chroots
	cat /etc/pacman.conf - <<- EOF > $@
		[apocos]
		SigLevel = Optional TrustAll
		Include = /etc/pacman.d/apocos.mirrorlist
	EOF

build/chroots/root: | build/chroots/apocos.mirrorlist build/chroots/pacman.conf
	mkarchroot -C $(CURDIR)/build/chroots/pacman.conf $(CURDIR)/build/chroots/root base-devel

setup-root-mirrors: | build/chroots/root build/chroots/pacman_chroot.conf build/chroots/apocos.mirrorlist
	sudo install -Dm0644 build/chroots/pacman_chroot.conf build/chroots/root/etc/pacman.conf
	sudo install -Dm0644 build/chroots/apocos.mirrorlist build/chroots/root/etc/pacman.d

build/Packages:
	git clone https://github.com/PrepperArch/Packages build/Packages

update-packages: build/Packages
	cd $(CURDIR)/build/Packages && git pull

build-package-%: | update-packages setup-root-mirrors
	sudo rm -rf build/chroots/$*
	cd $(CURDIR)/build/Packages/$* \
		&& makechrootpkg -c -u -r $(CURDIR)/build/chroots -l$* -- makepkg -sdc \
		&& (cp -n *.zst $(CURDIR)/any | true)

build-sdr-package-%: | update-packages setup-root-mirror
	cd $(CURDIR)/build/Packages/sdr/$* \
		&& makechrootpkg -c -u -r $(CURDIR)/build/chroots -l$* -- makepkg -sc \
		&& (cp -n *.zst $(CURDIR)/x86_64 | true)

update-repo-%:
	repo-add --prevent-downgrade --new \
		$(CURDIR)/$*/apocos.db.tar.gz $(CURDIR)/$*/*.zst \
		&& repo-add --remove $(CURDIR)/$*/apocos.db.tar.gz
	rm $(CURDIR)/$*/apocos.db \
		&& mv $(CURDIR)/$*/apocos.db.tar.gz $(CURDIR)/$*/apocos.db \
		&& ln -s apocos.db $(CURDIR)/$*/apocos.db.tar.gz
	rm $(CURDIR)/$*/apocos.files \
		&& mv $(CURDIR)/$*/apocos.files.tar.gz $(CURDIR)/$*/apocos.files \
		&& ln -s apocos.files $(CURDIR)/$*/apocos.files.tar.gz

update-repo: update-repo-any update-repo-x86_64

clean:
	sudo rm -rf build

