# Test and build a hApp
#
# Building requires a nix-shell, so either prefix your desired target with `make nix-...`, or enter
# a `nix-shell` and then run `make ...`

SHELL		= bash
DNANAME		= happ-example
DNA		= dist/$(DNANAME).dna.json

# External targets; Uses a nix-shell environment to obtain Holochain runtimes, run tests, etc.
.PHONY: all
all: nix-test

# nix-test, nix-install, ...
nix-%:
	nix-shell --pure --run "make $*"

# Internal targets; require a Nix environment in order to be deterministic.
# - Uses the version of `hc`, `holochain` on the system PATH.
# - Normally called from within a Nix environment, eg. run `nix-shell`
.PHONY:		rebuild install build test test-unit test-e2e
rebuild:	clean build

install:	build

build:		$(DNA)

# Build the DNA; Specifying a custom --output requires the path to exist
# However, if the name of the directory within which `hc` is run matches the
# DNA's name, then this name is used by default, and the output directory is
# created automatically.
$(DNA):
	hc package --strip-meta

test:		test-unit test-e2e

# test-unit -- Run Rust unit tests via Cargo
test-unit:
	RUST_BACKTRACE=1 cargo test \
	    --manifest-path zomes/example/code/Cargo.toml \
	    -- --nocapture

# test-e2e -- Uses dist/holofuel.dna.json; install test JS dependencies, and run end-to-end tests
test-e2e:	$(DNA)
	( cd test && npm install ) \
	  && RUST_BACKTRACE=1 hc test \
	    | test/node_modules/faucet/bin/cmd.js


# Generic targets; does not require a Nix environment
.PHONY: clean
clean:
	rm -rf \
	    dist \
	    test/node_modules \
	    .cargo \
	    target \
	    zomes/example/code/target
