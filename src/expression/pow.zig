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

        fn powerRuleD(self: Self, factory: Factory(T)) !Expression(T) {
            const c = self.exponent.*.Const;

            return try factory.mul(&.{
                self.exponent.*,
                Factory(T).pow(
                    try factory.create(self.base.*),
                    try factory.constantPtr(c.value - 1)
                )
            });
        }

        fn logD(self: Self, var_name: []const u8, factory: Factory(T)) !Expression(T) {
            const f = self.base.*;
            const f_prime = try f.d(var_name, factory);
            const g = self.exponent.*;
            const g_prime = try g.d(var_name, factory);

            const f_pow_g = Factory(T).pow(
                try factory.create(f),
                try factory.create(g)
            );

            const g_prime_ln_f = try factory.mul(&.{
                g_prime,
                try factory.ln(try factory.create(f))
            });

            const g_f_prime_div_f = try factory.mul(&.{
                g,
                Factory(T).div(
                    try factory.create(f_prime),
                    try factory.create(f)
                )
            });

            return try factory.mul(&.{
                f_pow_g,
                try factory.add(&.{
                    g_prime_ln_f,
                    g_f_prime_div_f
                })
            });
        }

        pub fn d(self: Self, var_name: []const u8, factory: Factory(T)) !Expression(T) {
            return switch (self.exponent.*) {
                .Const => try self.powerRuleD(factory),
                else => try self.logD(var_name, factory)
            };
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
