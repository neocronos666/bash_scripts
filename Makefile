.PHONY: check syntax shellcheck

check:
	bash tests/run.sh

syntax:
	find . -path './.git' -prune -o -path './.deprecated' -prune -o \
		-type f -name '*.sh' -exec bash -n {} +

shellcheck:
	shellcheck --severity=error -x $$(find . -path './.git' -prune -o \
		-path './.deprecated' -prune -o -type f -name '*.sh' -print)
