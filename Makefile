# not all dependencies are in here, you need to 'make clean' sometimes.

PROFILE = #-g #-pg
# FIXME: autodetect python version to build against (instead of 2.3)
CFLAGS = $(PROFILE) -O3 `pkg-config --cflags gtk+-2.0 pygtk-2.0` -Wall -Werror -I/usr/include/python2.3/ -I.
LDFLAGS = $(PROFILE) -O3 `pkg-config --libs gtk+-2.0 pygtk-2.0` -Wall -Werror
DEFSDIR = `pkg-config --variable=defsdir pygtk-2.0`

all:	mydrawwidget.so

brushsettings.h:	generate.py brushsettings.py
	./generate.py

gtkmydrawwidget.o:	brushsettings.h gtkmydrawwidget.c gtkmydrawwidget.h
	cc $(CFLAGS) -c -o $@ gtkmydrawwidget.c

gtkmybrush.o:	brushsettings.h gtkmybrush.c gtkmybrush.h
	cc $(CFLAGS) -c -o $@ gtkmybrush.c

clean:
	rm *.o *.so brushsettings.h mydrawwidget.defs mydrawwidget.defs.c

mydrawwidget.defs.c: mydrawwidget.defs mydrawwidget.override
	pygtk-codegen-2.0 --prefix mydrawwidget \
	--register $(DEFSDIR)/gdk-types.defs \
	--register $(DEFSDIR)/gtk-types.defs \
	--override mydrawwidget.override \
	mydrawwidget.defs > mydrawwidget.defs.c

mydrawwidget.defs: gtkmydrawwidget.h gtkmybrush.h surface.h Makefile
	/usr/share/pygtk/2.0/codegen/h2def.py gtkmydrawwidget.h gtkmybrush.h > mydrawwidget.defs
	./caller_owns_return.py mydrawwidget.defs get_nonwhite_as_pixbuf get_as_pixbuf

mydrawwidget.so: mydrawwidget.defs.c mydrawwidgetmodule.c gtkmydrawwidget.o surface.o gtkmybrush.o brush_dab.o helpers.o
	$(CC) $(LDFLAGS) $(CFLAGS) -shared $^ -o $@

PREFIX=/home/martin/testprefix
install: all
	install -d $(PREFIX)/lib/mypaint
	install *.py $(PREFIX)/lib/mypaint/
	install mydrawwidget.so $(PREFIX)/lib/mypaint/
	install -d $(PREFIX)/share/mypaint
	install -d $(PREFIX)/share/mypaint/brushes
	install brushes/*  $(PREFIX)/share/mypaint/brushes/
	install mypaint $(PREFIX)/bin/
	python -c "f = '$(PREFIX)/bin/mypaint'; s = open(f).read().replace('prefix = None', 'prefix = \"$(PREFIX)\"') ; open(f, 'w').write(s)"
