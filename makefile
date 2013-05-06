INCLUDE = .
all: build
build:
install:
	mkdir -p $(DESTDIR)/usr/bin/
	mkdir -p $(DESTDIR)/usr/share/trantect/
	cp -r bin/* $(DESTDIR)/usr/bin/
	cp -r share/* $(DESTDIR)/usr/share/trantect/

