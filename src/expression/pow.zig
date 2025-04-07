const std = @import("std");
const Expression = @import("../expression.zig").Expression;
const Factory = @import("../factory.zig").Factory;

pub fn Pow(comptime T: type) type {
    return struct {
        base: *Expression(T),
        exponent: *Expression(T),

        const Self = @This();

        pub fn initExp(base: *Expression(T), exponent: *Expression(T)) Expression(T) {
            return .{ .Pow = .{ .base = base, .exponent = exponent } };
        }

        pub fn eval(self: Self, args: Expression(T).Args) T {
            return std.math.pow(T,
                self.base.*.eval(args),
                self.exponent.*.eval(args)
            );
        }

        pub fn print(self: Self) void {
            std.debug.print("( ", .{});
            self.base.print();
            std.debug.print("^", .{});
            self.exponent.print();
            std.debug.print(" )", .{});
        }

        fn powerRuleD(self: Self, factory: Factory(T)) !Expression(T) {
            const c = self.exponent.*.Const;

            return try factory.mul(&.{
                self.exponent.*,
                .pow(
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

            const f_pow_g = Expression(T).pow(
                try factory.create(f),
                try factory.create(g)
            );

            const g_prime_ln_f = try factory.mul(&.{
                g_prime,
                try factory.ln(try factory.create(f))
            });

            const g_f_prime_div_f = try factory.mul(&.{
                g,
                .div(
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

        pub fn rewrite(self: Self, factory: Factory(T)) !Expression(T) {
            const simple_b = try self.base.*.rewrite(factory);
            const simple_e = try self.exponent.*.rewrite(factory);

            return if (
                simple_b.eqlStructure(.constant(1)) or
                simple_b.eqlStructure(.constant(0)) or
                simple_e.eqlStructure(.constant(1))
            )
                simple_b
            else if (simple_e.eqlStructure(.constant(0)))
                .constant(1)
            else .{ .Pow = self };
        }

        pub fn eqlStructure(self: Self, exp: Expression(T)) bool {
            if (exp != .Pow) return false;
            
            const eql_base_structure = self.base.*.eqlStructure(exp.Pow.base.*);
            const eql_exponent_structure = self.exponent.*.eqlStructure(exp.Pow.exponent.*);
            return eql_base_structure and eql_exponent_structure;
        }

        pub const Factories = struct {
            pub fn powPtr(factory: Factory(T), base: *Expression(T), exponent: *Expression(T)) !*Expression(T) {
                return try factory.create(.pow(base, exponent));
            }
        };
    };
}

test "power rule of differentiation" {
    const f = try Factory(f32).init(std.testing.allocator);
    defer f.deinit();

    const exp = Expression(f32).pow(
        try f.variablePtr("x"),
        try f.constantPtr(2)
    );

    const d_exp = try exp.d("x", f);

    const expected = try f.mul(&.{
        .constant(2),
        .pow(
            try f.variablePtr("x"),
            try f.constantPtr(1)
        )
    });

    const is_eql = d_exp.eqlStructure(expected);

    try std.testing.expect(is_eql);
}

test "x^0 == 1" {
    const f = try Factory(f32).init(std.testing.allocator);
    defer f.deinit();

    const exp = Expression(f32).pow(
        try f.variablePtr("x"),
        try f.constantPtr(0),
    );
    const r_exp = exp.rewrite(f);

    const expected = Expression(f32).constant(1);

    try std.testing.expectEqual(r_exp, expected);
}
