THIS_MAKEFILE_PATH := $(abspath $(lastword $(MAKEFILE_LIST)))
THIS_MAKEFILE_DIR := $(patsubst %/,%,$(dir $(THIS_MAKEFILE_PATH)))

all: install

bin:
	@mkdir -p "${HOME}/.bin"
	@cp "${THIS_MAKEFILE_DIR}/bin/fzf-notes-bin" "${HOME}/.bin/fzf-notes-bin"

install: bin
	@cp "${THIS_MAKEFILE_DIR}/shell/fzf-notes.zsh" "${HOME}/.fzf-notes.zsh"
	@echo "Done."
	@echo "Please source ~/.fzf-notes.zsh"


.PHONY: bin install all
