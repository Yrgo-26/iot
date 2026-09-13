# Build every code example that has a Makefile, and run its tests.
build:
	@bash ci/build.sh

# Format all C/C++ files (clang-format) in place.
format:
	@bash ci/format.sh

# Check formatting without modifying any files; fails if something isn't formatted.
format-check:
	@bash ci/format.sh --check

# Check the course material: every relative link resolves, and the copies of the hardware
# class's contract documents still match the originals (skipped if that repo isn't next door).
docs-check:
	@bash ci/links.sh
	@bash ci/contract.sh

# Check only the contract copies. Set CONTRACT_SRC to point at the hardware repo's project/.
contract-check:
	@bash ci/contract.sh

# Build the course book, one chapter per lecture (needs LuaLaTeX; see book/README.md).
# The CAN book lives in its own repository: https://github.com/Yrgo-26/can-book
book:
	@command -v lualatex >/dev/null || \
	    (echo "error: lualatex not found; see book/README.md for what to install." >&2; exit 1)
	@$(MAKE) --no-print-directory -C book

# Remove build artifacts from every code example that has a Makefile.
clean:
	@$(MAKE) --no-print-directory -C book clean
	@find lectures exam lab -iname Makefile -print0 2>/dev/null \
		| xargs -0 -r -n1 dirname | xargs -r -n1 make clean -C

.PHONY: build format format-check docs-check contract-check book clean
