test: solve.zig solve2.zig
	test1
	test2

run: solve.zig solve2.zig
	run1
	run2

solve: solve.zig solve2.zig
	solve1
	solve2

test1: solve.zig
	zig build-exe solve.zig
	./solve test
	rm solve

solve1: solve.zig
	zig build-exe solve.zig
	./solve solve
	rm solve

run1: solve.zig
	zig build-exe solve.zig
	./solve
	rm solve

test2: solve2.zig
	zig build-exe solve2.zig
	./solve2 test
	rm solve2

solve2: solve2.zig
	zig build-exe solve2.zig
	./solve2 solve
	rm solve2

run2: solve2.zig
	zig build-exe solve2.zig
	./solve2
	rm solve2

clean:
	rm solve solve2
