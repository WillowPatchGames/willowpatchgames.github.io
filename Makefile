DIST?=build.tar

all: build

dist: build tarball

server:
	hugo server -D

build:
	hugo

tarball:
	rm -f $(DIST) $(DIST).xz
	tar -cf $(DIST) public
	xz $(DIST)

deploy: dist
	mv $(DIST).xz ../ansible/files/$(DIST).xz
	cd ../nginx-configs && tar -cJf ../ansible/files/nginx.tar.xz *
	cd ../ansible && ansible-playbook -i hosts blog-setup.yml
