BUILD = build
SOURCE = source
EXTENSION = rst

MAKEFLAGS += -j

SOURCE_FILES := $(shell find $(SOURCE) -name "*.$(EXTENSION)")
OUTPUT_PDF_FILES = $(subst $(EXTENSION),pdf,$(subst $(SOURCE),$(BUILD),$(SOURCE_FILES)))
OUTPUT_HTML_FILES = $(subst $(EXTENSION),html,$(subst $(SOURCE),$(BUILD),$(SOURCE_FILES)))

HTMLCMD = rst2html.py
LATEXCMD = rst2latex.py --latex-preamble="\usepackage{fullpage} \usepackage{parskip} \usepackage{fancyhdr} \usepackage{graphicx} \pagestyle{fancy} \renewcommand{\headrulewidth}{0pt} \renewcommand{\footrulewidth}{0pt}" --documentoptions=letter --documentclass=article 
PDFCMD = pdflatex --interaction batchmode --output-directory $(BUILD)/

.PHONY: all clean cleanup builds setup
.DEFAULT_GOAL := help
.SECONDARY:

help:
	@echo "PDF, LaTeX and rST generator generator."
	@echo "Targets:"
	@echo ""
	@echo "     setup - builds targets for all files in source directory or directories."
	@echo "             (see bin/builder.py)"
	@echo "     all   - rebuild all PDFs from files in the '$(SOURCE)' directory with"
	@echo "             the '.$(EXTENSION)' extension."
	@echo ""
	@echo "     (other) - use 'make [filename-without-extension]' to rebuild only this file,"
	@echo "               after running 'make setup'"

setup:$(BUILD) makefile.generated logo.png
$(BUILD)/makefile.generated:bin/builder.py $(SOURCE_FILES)
	@./$<
	@echo [builder]: \(re\)generated \"makefile.generated\"
-include $(BUILD)/makefile.generated

all: logo.png $(BUILD) $(OUTPUT_PDF_FILES) $(OUTPUT_HTML_FILES) 

logo.png:
	curl http://docs.mongodb.org/logo-print.png >| $@

$(BUILD):
	@mkdir -p $@
	@echo [setup]: '$@' directory created.
$(BUILD)/%.html:$(SOURCE)/%.$(EXTENSION)
	@$(HTMLCMD) $< >$@
	@echo [rst2html]: converted $<
$(BUILD)/%.tex:$(SOURCE)/%.$(EXTENSION)
	@$(LATEXCMD) $< >$@
	@echo [rst2latex]: converted $<
$(BUILD)/%.pdf:$(BUILD)/%.tex
	@$(PDFCMD) '$<' >|$@.log
	@echo [pdflatex]: \(1/3\) built '$@'
	@$(PDFCMD) '$<' >>$@.log
	@echo [pdflatex]: \(2/3\) built '$@'
	@$(PDFCMD) '$<' >>$@.log
	@echo [pdflatex]: \(3/3\) built '$@'

cleanup:
	rm -f $(BUILD)/*.{aux,log,out}
clean:
	rm -rf $(BUILD)/
clean-logo:
	rm -f logo.png
