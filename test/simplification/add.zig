const std = @import("std");
const zig_cas = @import("cas");
const Factory = zig_cas.Factory;

test "x + x + x = 3x" {
    const f = try Factory(f32).init(std.testing.allocator);
    defer f.deinit();

    const e = try  f.add(&.{
        .variable("x"),
        .variable("x"),
        .variable("x")
    });

    const es = try e.simplify(f);

    const expected = try f.mul(&.{
        .variable("x"),
        .constant(3)
    });

    try std.testing.expect(es.eqlStructure(expected));
}
