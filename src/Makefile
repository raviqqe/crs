# crs - combat ready status
# See LICENSE file for copyright and license details.
# $() and ${} is equivalent, but the former is modern.
# variables undefined here: DESTDIR PREFIX MANPREFIX

PREFIX = /usr
MANPREFIX = /usr/share

VERSION = 0.01
BINDIR = $(DESTDIR)$(PREFIX)/bin
LIBDIR = $(DESTDIR)$(PREFIX)/lib
#LIBDIR = $(DESTDIR)$(PREFIX)/libexec
CONFDIR = $(DESTDIR)/etc
#CONFDIR = $(DESTDIR)$(PREFIX)/etc
REPOSDIR = $(DESTDIR)/var
MANDIR = $(DESTDIR)$(MANPREFIX)/man/man1

crs.conf:
	@echo "creating $@ in $(CONFDIR) from crs.conf.sample"
	@cp -fT crs.conf.sample $(CONFDIR)/$@
	@chmod 644 $(CONFDIR)/$@

clean:
	@echo 'nothing to be cleaned'

install: crs.conf 
	@echo "installing executable file to $(BINDIR)"
	@mkdir -p $(BINDIR)
	@cp -fT crs.sh $(BINDIR)/crs
	@chmod 755 $(BINDIR)/crs
	@echo "installing module files to $(LIBDIR)"
	@mkdir -p $(LIBDIR)/crs
	@cp -f mod_svn.sh $(LIBDIR)/crs
	@cp -f mod_git.sh $(LIBDIR)/crs
	@chmod 644 $(LIBDIR)/crs/*
	@echo "creating the directory of the repository copy to $(REPOSDIR)"
	@mkdir -p $(REPOSDIR)/crs
	@chmod 755 $(REPOSDIR)/crs
	@echo "installing manual page to $(MANDIR)"
	@mkdir -p $(MANDIR)
	@sed -e "s/VERSION/$(VERSION)/g" -e "s|CONFFILE|$(CONFDIR)/crs.conf|g" -e "s|VCSROOT|$(REPOSDIR)/crs|g" < crs.1 > crs.1.tmp
	@gzip -c crs.1.tmp > $(MANDIR)/crs.1.gz
	@chmod 644 $(MANDIR)/crs.1.gz
	@rm -f crs.1.tmp

uninstall:
	@echo "removing the repository copy from $(REPOSDIR)"
	@rm -rf $(REPOSDIR)/crs
	@echo "removing the configuration file from $(CONFDIR)"
	@rm -f $(CONFDIR)/crs.conf
	@echo "removing module files from $(LIBDIR)"
	@rm -rf $(LIBDIR)/crs
	@echo "removing executable file from $(BINDIR)"
	@rm -f $(BINDIR)/crs
	@echo "removing manual page from $(MANDIR)"
	@rm -f $(MANDIR)/crs.1.gz

.PHONY: crs.conf clean install uninstall
