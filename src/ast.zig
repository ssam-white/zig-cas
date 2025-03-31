const std = @import("std");
const Expression = @import("expression.zig").Expression;

pub fn Ast(comptime T: type) type {
    return struct {
        exp: *Expression(T),
        alloc: std.mem.Allocator,

        const Self = @This();
    
        pub fn init(alloc: std.mem.Allocator, exp: *Expression(T)) Self {
            return .{ .exp = exp, .alloc = alloc, };
        }

        pub fn deinit(self: Self) void {
            self.exp.*.deinit(self.alloc);
            self.alloc.destroy(self.exp);
        }
    };
}
