const std = @import("std");
const Expression = @import("../expression.zig").Expression;
const Factory = @import("../factory.zig").Factory;

const Allocator = std.mem.Allocator;

pub fn Log(comptime T: type) type {
    return struct {
        b: *Expression(T),
        x: *Expression(T),

        const Self = @This();
        
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
            return switch (self.b.*) {
                .Const => |c|
                    if (c.value == std.math.e) 
                        Factory(T).div(
                            try factory.constantPtr(1),
                            try factory.create(self.x.*)
                        )
                    else
                        Factory(T).div(
                            try factory.logEPtr(self.x),
                            try factory.logEPtr(self.b)
                        ).d(var_name, factory),
                else =>
                    Factory(T).div(
                        try factory.logEPtr(self.x),
                        try factory.logEPtr(self.b)
                    ).d(var_name, factory)
            };
        }

        pub const Factories = struct {
            pub fn log(b: *Expression(T), x: *Expression(T)) Expression(T) {
                return .{ .Log = .{ .b = b, .x = x } };
            }

            pub fn logPtr(factory: Factory(T), b: *Expression(T), x: *Expression(T)) !*Expression(T) {
                return try factory.create(.{ .Log = .{ .b = b, .x = x } });
            }

            pub fn logEPtr(factory: Factory(T), x: *Expression(T)) !*Expression(T) {
                const e = try factory.constantPtr(std.math.e);
                return try factory.logPtr(e, x);
            }
        };
    };
}
