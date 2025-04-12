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
            std.debug.assert(self.exponent.* == .Const);            

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
            const e_prod_ln_x = try factory.mul(&.{
                self.exponent.*,
                try factory.ln(self.base)
            });
            const e_prod_ln_x_prime = try e_prod_ln_x.d(var_name, factory);

            return try factory.mul(&.{
                .{ .Pow = self },
                e_prod_ln_x_prime
            });
        }

        pub fn d(self: Self, var_name: []const u8, factory: Factory(T)) !Expression(T) {
            return switch (self.exponent.*) {
                .Const => try self.powerRuleD(factory),
                else => try self.logD(var_name, factory)
            };
        }

        pub fn constantEval(self: Self) T {
            std.debug.assert(
                self.base.* == .Const and
                self.exponent.* == .Const
            );
            return std.math.pow(T, self.base.*.Const.value, self.exponent.*.Const.value);
        }
        
        pub fn constantFold(self: Self, _: Factory(T)) !Expression(T) {
            return if (self.base.* == .Const and self.exponent.* == .Const)
                .constant(self.constantEval())
            else .{ .Pow = self };
                
            
        }

        pub fn simplify(self: Self, factory: Factory(T)) !Expression(T) {
            const simple_b = try self.base.*.simplify(factory);
            const simple_e = try self.exponent.*.simplify(factory);

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

test "simplify x^0 == 1" {
    const f = try Factory(f32).init(std.testing.allocator);
    defer f.deinit();

    const exp = Expression(f32).pow(
        try f.variablePtr("x"),
        try f.constantPtr(0),
    );
    const r_exp = exp.simplify(f);

    const expected = Expression(f32).constant(1);

    try std.testing.expectEqual(r_exp, expected);
}

test "simplify x^1==x" {
    const factory = try Factory(f32).init(std.testing.allocator);
    defer factory.deinit();

    const exp = Expression(f32).pow(
        try factory.variablePtr("x"),
        try factory.constantPtr(1)
    );

    const r_exp = try exp.simplify(factory);
    const expected = Expression(f32).variable("x");

    const is_eql = r_exp.eqlStructure(expected);

    try std.testing.expect(is_eql);
}

test "simplify 0^x == 0" {
    const factory = try Factory(f32).init(std.testing.allocator);
    defer factory.deinit();

    const exp = Expression(f32).pow(
        try factory.constantPtr(0),
        try factory.variablePtr("x")
    );

    const r_exp = try exp.simplify(factory);
    const expected = Expression(f32).constant(0);
    const is_eql = r_exp.eqlStructure(expected);

    try std.testing.expect(is_eql);
}


test "simplify 1^x == 1" {
    const factory = try Factory(f32).init(std.testing.allocator);
    defer factory.deinit();

    const exp = Expression(f32).pow(
        try factory.constantPtr(1),
        try factory.variablePtr("x")
    );

    const r_exp = try exp.simplify(factory);
    const expected = Expression(f32).constant(1);
    const is_eql = r_exp.eqlStructure(expected);

    try std.testing.expect(is_eql);
}
