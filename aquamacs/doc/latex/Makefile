fname=aquamacs.tex
fpdf=aquamacs.pdf
finalpdf=Aquamacs\ Manual.pdf
cname=changes.tex
pdfdir=$(shell pwd)
srcdir=$(shell pwd)
newdir=$(srcdir)/aquamacs
destdir=$(srcdir)/../AquamacsHelp
indexer=/Developer/Applications/Utilities/Help\ Indexer.app/Contents/MacOS/Help\ Indexer

phrase=''
newphrase=''

all: pdf html


pdf: aquamacs.tex changelog.tex changes.tex *.pdf
	echo "Making PDF";					   \
	cd $(pdfdir);						   \
	pdflatex -interaction=nonstopmode $(cname)		   ; \
	echo "Running pdflatex on $(cname)..."			   ; \
	echo "Running pdflatex on $(fname)..."			   ; \
	pdflatex -interaction=nonstopmode $(fname)		   ; \
	echo "Running pdflatex again to update references..."	   ; \
	pdflatex -interaction=nonstopmode $(fname)		   ; \
	echo cp $(pdfdir)/$(fpdf) $(pdfdir)/$(finalpdf)	   ; \
	cp $(pdfdir)/$(fpdf) $(pdfdir)/$(finalpdf)	   ; \
	echo "PDF conversion completed, PDF renamed to $(finalpdf)."


html: aquamacs.tex *.pdf
	echo "Running latex2html on $(fname)...";				     \
	latex2html -init_file l2hconf-local.pm -local_icons -html_version=4.1 $(fname) ; \
	echo "$(fname) converted to HTML."					     ; \
	cp aquamacs.css $(newdir)/aquamacs.css					     ; \
	echo "Applying Apple Help tags..."					     ; \
	echo "Apple Help tags applied. HTML conversion completed."		     ; \
	echo $(phrase) ; \
	sed 's/<META NAME="description" CONTENT="Aquamacs Emacs/<META NAME="AppleTitle" content="Aquamacs Help"><META NAME="AppleFont" content="Lucida Grande,Helvetica"><META NAME="description" CONTENT="Aquamacs Emacs - /' <$(newdir)/index.html >$(newdir)/index2.html	     ; \
	mv $(newdir)/index2.html $(newdir)/index.html
	rm -rf $(destdir)
	echo	mv $(newdir) ../AquamacsHelp				     ; \
	mv $(newdir) $(destdir) ; \
	cp "AquamacsHelp idx" $(destdir)/					     ; \
	echo "Making new Aquamacs Help directory, copying new help files."	     ; \
	echo 	cp $(wildcard $(srcdir)/*.png) $(destdir)/						     ; \
	cp $(srcdir)/*.png $(destdir)/						     ; \
	rm $(destdir)/WARNINGS
	echo "Help files copied." ; \
	$(indexer) $(destdir) -PantherIndexing NO -Tokenizer 1 -ShowProgress YES -UseRemoteRoot NO -GenerateSummaries YES -LogStyle 1


