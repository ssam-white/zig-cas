const std = @import("std");
const Expression = @import("../expression.zig").Expression;
const Factory = @import("../factory.zig").Factory;

const Allocator = std.mem.Allocator;

pub fn Log(comptime T: type) type {
    return struct {
        b: *Expression(T),
        x: *Expression(T),

        const Self = @This();
        
        pub fn deinit(self: Self, alloc: Allocator) void {
            self.b.*.deinit(alloc);
            alloc.destroy(self.b);
            self.x.*.deinit(alloc);
            alloc.destroy(self.x);
        }

        pub fn eval(self: Self, args: Expression(T).Args) T {
            const b = self.b.*.eval(args);
            const x = self.x.*.eval(args);
            return std.math.log(T, b, x);
        }

        pub fn print(self: Self) void {
            std.debug.print("Log(", .{});
            self.b.*.print();
            std.debug.print(", ", .{});
            self.x.*.print();
            std.debug.print(")", .{});
        }


        pub fn d(self: Self, var_name: []const u8, factory: Factory(T)) !Expression(T) {
            _ = self; _ = var_name; _ = factory;
            return .{ .Const = .{ .value = 9999 } };
        }
    };
}
