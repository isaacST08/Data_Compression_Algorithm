

all: algorithm-description all-tests all-implementations

all-implementations: zig-implementation

all-tests: zig-tests


algorithm-description:
	typst compile ./docs-src/main.typ ./Algorithm_Description.pdf

zig-implementation:
	zig run ./src/algorithm.zig

zig-tests:
	zig test ./src/algorithm.zig
