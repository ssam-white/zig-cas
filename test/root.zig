const std = @import("std");
const cas = @import("cas");
const Factory = cas.Factory;

pub const add = @import("simplification/add.zig");

test {
    std.testing.refAllDecls(@This());
}
