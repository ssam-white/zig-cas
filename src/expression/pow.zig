const std = @import("std");
const Expression = @import("../expression.zig").Expression;
const Factory = @import("../factory.zig").Factory;

pub fn Pow(comptime T: type) type {
    return struct {
        base: *Expression(T),
        exponent: *Expression(T),

        const Self = @This();

        pub fn eval(self: Self, args: Expression(T).Args) T {
            return std.math.pow(T,
                self.base.*.eval(args),
                self.exponent.*.eval(args)
            );
        }

        pub fn print(self: Self) void {
            std.debug.print("( ", .{});
            self.base.print();
            std.debug.print(" ^ ", .{});
            self.exponent.print();
            std.debug.print(" )", .{});
        }

        pub fn d(self: Self, var_name: []const u8, factory: Factory(T)) !Expression(T) {
            switch (self.exponent.*) {
                .Const => |c| {
                    const operands = try factory.allocAll(&.{
                        self.exponent.*,
                        Factory(T).pow(
                            try factory.create(self.base.*),
                            try factory.constantPtr(c.value - 1)
                        )
                    });

                    return .{ .Mul = .{ .operands = operands } };
                },
                else => {
                    const expLogBaseProd = try factory.mulPtr(&.{
                        self.exponent.*,
                        Factory(T).log(
                            try factory.constantPtr(std.math.e),
                            try factory.create(self.base.*)
                        )
                    });

                    const operands = try factory.allocAll(&.{
                        expLogBaseProd.*,
                        try expLogBaseProd.d(var_name, factory)
                    });

                    return .{ .Mul = .{ .operands = operands } };
                }
            }
        }

        pub const Factories = struct {
            pub fn pow(base: *Expression(f32), exponent: *Expression(f32)) Expression(f32) {
                return .{ .Pow = .{ .base = base, .exponent = exponent } };
            }

            pub fn powPtr(factory: Factory(T), base: *Expression(T), exponent: *Expression(T)) !*Expression(T) {
                return try factory.create(.{ .Pow = .{ .base = base, .exponent = exponent } });
            }
        };
    };
}
