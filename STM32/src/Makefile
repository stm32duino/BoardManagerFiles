SHELL = /bin/sh

.SUFFIXES: .tar.bz2

ROOT_PATH := .
TOOLS_PATH := ../tools
CORE_PATH := ../packages
DOWNLOAD_PATH := download

OS ?=$(shell uname -s)

# -----------------------------------------------------------------------------
ifeq (postpackaging_core,$(findstring $(MAKECMDGOALS),postpackaging_core))
  PACKAGE_FILENAME=$(PACKAGE_NAME)-$(PACKAGE_VERSION).tar.bz2
  PACKAGE_CHKSUM := $(firstword $(shell shasum -a 256 "$(PACKAGE_FILENAME)"))
  PACKAGE_SIZE := $(firstword $(shell wc -c "$(PACKAGE_FILENAME)"))
endif

ifeq (postpackaging_tools,$(findstring $(MAKECMDGOALS),postpackaging_tools))
  PACKAGE_WIN_FILENAME=$(PACKAGE_NAME)-$(PACKAGE_VERSION)-windows.tar.bz2
  PACKAGE_LINUX_FILENAME=$(PACKAGE_NAME)-$(PACKAGE_VERSION)-linux.tar.bz2
  PACKAGE_MAC_FILENAME=$(PACKAGE_NAME)-$(PACKAGE_VERSION)-mac.tar.bz2

  PACKAGE_WIN_CHKSUM := $(firstword $(shell shasum -a 256 "$(PACKAGE_WIN_FILENAME)"))
  PACKAGE_LINUX_CHKSUM := $(firstword $(shell shasum -a 256 "$(PACKAGE_LINUX_FILENAME)"))
  PACKAGE_MAC_CHKSUM := $(firstword $(shell shasum -a 256 "$(PACKAGE_MAC_FILENAME)"))

  PACKAGE_WIN_SIZE := $(firstword $(shell wc -c "$(PACKAGE_WIN_FILENAME)"))
  PACKAGE_LINUX_SIZE := $(firstword $(shell wc -c "$(PACKAGE_LINUX_FILENAME)"))
  PACKAGE_MAC_SIZE := $(firstword $(shell wc -c "$(PACKAGE_MAC_FILENAME)"))
endif

# -----------------------------------------------------------------------------

.PHONY: all clean tools print_info postpackaging

all: core tools

core: PACKAGE_NAME := STM32
core: PACKAGE_FOLDER := Arduino_Core_STM32
core: PACKAGE_VERSION := $(shell git --git-dir=$(PACKAGE_FOLDER)/.git describe --tags)
core: PACKAGE_DATE := $(firstword $(shell git --git-dir=$(PACKAGE_FOLDER)/.git log -1 --pretty=format:%ci))
core: clean print_info
	@echo ----------------------------------------------------------
	@echo "Packaging $@..."
	@git --git-dir=$(PACKAGE_FOLDER)/.git show HEAD --pretty=short --no-patch  > $(PACKAGE_FOLDER)/package_version.txt
	@tar --mtime='$(PACKAGE_DATE)' \
		--exclude=.git \
		--exclude=.gitattributes \
		--exclude=.github \
		--exclude=.gitignore \
		--transform "s|$(PACKAGE_FOLDER)|$(PACKAGE_NAME)|" \
		-cjf "$(PACKAGE_NAME)-$(PACKAGE_VERSION).tar.bz2" "$(PACKAGE_FOLDER)"
	@-$(RM) $(PACKAGE_FOLDER)/package_version.txt
	@git --git-dir=$(PACKAGE_FOLDER)/.git checkout .
	$(MAKE) PACKAGE_NAME=$(PACKAGE_NAME) PACKAGE_VERSION=$(PACKAGE_VERSION) PACKAGE_FOLDER=$(PACKAGE_FOLDER) --no-builtin-rules postpackaging_core -C .
	@echo ----------------------------------------------------------

tools: PACKAGE_NAME := STM32Tools
tools: PACKAGE_FOLDER := Arduino_Tools
tools: PACKAGE_VERSION := $(shell git --git-dir=$(PACKAGE_FOLDER)/.git describe --tags)
tools: PACKAGE_DATE := $(firstword $(shell git --git-dir=$(PACKAGE_FOLDER)/.git log -1 --pretty=format:%ci))
tools: clean print_info
	@echo ----------------------------------------------------------
	@echo "Packaging $@..."
	@git --git-dir=$(PACKAGE_FOLDER)/.git show HEAD --pretty=short --no-patch  > $(PACKAGE_FOLDER)/package_version.txt
	@tar --mtime='$(PACKAGE_DATE)' \
		--exclude=.git \
		--exclude=.gitattributes \
		--exclude=.github \
		--exclude=.gitignore \
		--exclude=linux \
		--exclude=linux64 \
		--exclude=macosx \
		--transform "s|$(PACKAGE_FOLDER)|$(PACKAGE_NAME)|" \
		-cjf "$(PACKAGE_NAME)-$(PACKAGE_VERSION)-windows.tar.bz2" "$(PACKAGE_FOLDER)"
	@tar --mtime='$(PACKAGE_DATE)' \
		--exclude=.git \
		--exclude=.gitattributes \
		--exclude=.github \
		--exclude=.gitignore \
		--exclude=macosx \
		--exclude=win \
		--transform "s|$(PACKAGE_FOLDER)|$(PACKAGE_NAME)|" \
		-cjf "$(PACKAGE_NAME)-$(PACKAGE_VERSION)-linux.tar.bz2" "$(PACKAGE_FOLDER)"
	@tar --mtime='$(PACKAGE_DATE)' \
		--exclude=.git \
		--exclude=.gitattributes \
		--exclude=.github \
		--exclude=.gitignore \
		--exclude=linux \
		--exclude=linux64 \
		--exclude=win \
		--transform "s|$(PACKAGE_FOLDER)|$(PACKAGE_NAME)|" \
		-cjf "$(PACKAGE_NAME)-$(PACKAGE_VERSION)-mac.tar.bz2" "$(PACKAGE_FOLDER)"
	@-$(RM) $(PACKAGE_FOLDER)/package_version.txt
	$(MAKE) PACKAGE_NAME=$(PACKAGE_NAME) PACKAGE_VERSION=$(PACKAGE_VERSION) --no-builtin-rules postpackaging_tools -C .
	@echo ----------------------------------------------------------

clean:
	@echo ----------------------------------------------------------
	@echo  Cleanup
	-$(RM) *.tar.bz2 package_*.json
	-$(RM) -r $(DOWNLOAD_PATH)
	@echo ----------------------------------------------------------

print_info:
	@echo ----------------------------------------------------------
	@echo Building $(PACKAGE_NAME) using
	@echo "CURDIR              = $(CURDIR)"
	@echo "OS                  = $(OS)"
	@echo "SHELL               = $(SHELL)"
	@echo "PACKAGE_NAME        = $(PACKAGE_NAME)"
	@echo "PACKAGE_FOLDER      = $(PACKAGE_FOLDER)"
	@echo "PACKAGE_VERSION     = $(PACKAGE_VERSION)"


postpackaging_core:
	@echo "PACKAGE_CHKSUM      = $(PACKAGE_CHKSUM)"
	@echo "PACKAGE_SIZE        = $(PACKAGE_SIZE)"
	@echo "PACKAGE_FILENAME    = $(PACKAGE_FILENAME)"
	@BOARDS_LIST=`grep -E "^[^\.]+\.name=" $(PACKAGE_FOLDER)/boards.txt | cut -d'=' -f2 | awk '{print "            {\"name\": \""$$0"\"},"}'`; \
	BOARDS_LIST=$${BOARDS_LIST::-1}; \
	cat templates/package_core_index.json | sed s/%%VERSION%%/$(PACKAGE_VERSION)/ | sed s/%%FILENAME%%/$(PACKAGE_FILENAME)/ | sed s/%%CHECKSUM%%/$(PACKAGE_CHKSUM)/ | sed s/%%SIZE%%/$(PACKAGE_SIZE)/ | sed -e "s/%%BOARDSLIST%%/$${BOARDS_LIST//$$'\n'/\\n}/" > package_$(PACKAGE_NAME)_$(PACKAGE_VERSION)_index.json
	@mv $(PACKAGE_FILENAME) $(CORE_PATH)/
	@echo "package_$(PACKAGE_NAME)_$(PACKAGE_VERSION)_index.json created"

postpackaging_tools:
	@echo "PACKAGE_WIN_FILENAME    = $(PACKAGE_WIN_FILENAME)"
	@echo "PACKAGE_WIN_SIZE        = $(PACKAGE_WIN_SIZE)"
	@echo "PACKAGE_WIN_CHKSUM      = $(PACKAGE_WIN_CHKSUM)"
	@echo "PACKAGE_LINUX_FILENAME  = $(PACKAGE_LINUX_FILENAME)"
	@echo "PACKAGE_LINUX_SIZE      = $(PACKAGE_LINUX_SIZE)"
	@echo "PACKAGE_LINUX_CHKSUM    = $(PACKAGE_LINUX_CHKSUM)"
	@echo "PACKAGE_MAC_FILENAME    = $(PACKAGE_MAC_FILENAME)"
	@echo "PACKAGE_MAC_SIZE        = $(PACKAGE_MAC_SIZE)"
	@echo "PACKAGE_MAC_CHKSUM      = $(PACKAGE_MAC_CHKSUM)"
	@cat templates/package_tools_index.json | sed s/%%PACKAGENAME%%/$(PACKAGE_NAME)/ | sed s/%%VERSION%%/$(PACKAGE_VERSION)/ | sed s/%%FILENAMEWIN%%/$(PACKAGE_WIN_FILENAME)/ | sed s/%%CHECKSUMWIN%%/$(PACKAGE_WIN_CHKSUM)/ | sed s/%%SIZEWIN%%/$(PACKAGE_WIN_SIZE)/ | sed s/%%FILENAMEMAC%%/$(PACKAGE_MAC_FILENAME)/ | sed s/%%CHECKSUMMAC%%/$(PACKAGE_MAC_CHKSUM)/ | sed s/%%SIZEMAC%%/$(PACKAGE_MAC_SIZE)/ | sed s/%%FILENAMELINUX%%/$(PACKAGE_LINUX_FILENAME)/ | sed s/%%CHECKSUMLINUX%%/$(PACKAGE_LINUX_CHKSUM)/ | sed s/%%SIZELINUX%%/$(PACKAGE_LINUX_SIZE)/ > package_$(PACKAGE_NAME)_$(PACKAGE_VERSION)_index.json
	@mv $(PACKAGE_WIN_FILENAME) $(PACKAGE_LINUX_FILENAME) $(PACKAGE_MAC_FILENAME) $(TOOLS_PATH)/
	@echo "package_$(PACKAGE_NAME)_$(PACKAGE_VERSION)_index.json created"
