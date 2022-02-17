DIST?=build.tar

all: build

dist: build tarball

server:
	hugo server -D

build:
	hugo -d docs

tarball:
	rm -f $(DIST) $(DIST).xz
	tar -cf $(DIST) docs
	xz $(DIST)

deploy: dist
	mv $(DIST).xz ../ansible/files/$(DIST).xz
	cd ../nginx-configs && tar -cJf ../ansible/files/nginx.tar.xz *
	cd ../ansible && bash ./backup.sh blog
	cd ../ansible && ansible-playbook -i hosts blog.yml
