const std = @import("std");
const Expression = @import("../expression.zig").Expression;
const Factory = @import("../factory.zig").Factory;

pub fn Div(comptime T: type) type {
    return struct {
        num: *Expression(T),
        den: *Expression(T),

        const Self = @This();

        pub fn initExp(num: *Expression(f32), den: *Expression(f32)) Expression(f32) {
            return .{ .Div = .{ .num = num, .den = den } };
        }
        
        pub fn eval(self: Self, args: Expression(T).Args) T {
            // return std.math.divExact(T, self.num.*.eval(args), self.den.*.eval(args)) catch unreachable;
            return self.num.*.eval(args) / self.den.*.eval(args);
        }

        pub fn print(self: Self) void {
            std.debug.print("( ", .{});
            self.num.*.print();
            std.debug.print("/", .{});
            self.den.*.print();
            std.debug.print(" )", .{});
        }

        pub fn d(self: Self, var_name: []const u8, factory: Factory(T)) !Expression(T) {
            const u = self.num.*;
            const u_prime = try u.d(var_name, factory);
            const v = self.den.*;
            const v_prime = try v.d(var_name, factory);

            const u_prime_v = try factory.mul(&.{ u_prime, v });
            const u_v_prime = try factory.mul(&.{ u, v_prime });

            const u_prime_v_sub_u_v_prime = try factory.subPtr(
                &.{ u_prime_v, u_v_prime }
            );
            const v_sqrd = try factory.powPtr(
                try factory.create(v),
                try factory.constantPtr(2)
            );

            return .div(u_prime_v_sub_u_v_prime, v_sqrd);
        }

        pub fn constantEval(self: Self) !T {
            std.debug.assert(
                self.num.* == .Const and
                self.den.* == .Const
            );
            return try std.math.divExact(T, self.num.*.Const.value, self.den.*.Const.value);
        }

        pub fn constantFold(self: Self, _: Factory(T)) !Expression(T) {
            return if (self.num.* == .Const and self.den.* == .Const)
                .constant( try self.constantEval() )
            else .{ .Div = self };
        }

        pub fn simplify(self: Self, factory: Factory(T)) !Expression(T) {
            const simple_num = try self.num.*.simplify(factory);
            const simple_den = try self.den.*.simplify(factory);

            return if (simple_den.eqlStructure(.constant(1)))
                self.num.*
            else if (simple_num.eqlStructure(.constant(0)))
                .constant(0)
            else
                .div(
                    try factory.create(simple_num),
                    try factory.create(simple_den)
                );
        }
        
        pub fn eqlStructure(self: Self, exp: Expression(T)) bool {
            if (exp != .Div) return false;

            const num_eql_structure = self.num.*.eqlStructure(exp.Div.num.*);
            const den_eql_structure = self.den.*.eqlStructure(exp.Div.den.*);

            return num_eql_structure and den_eql_structure;
        }

        pub fn asPow(self: Self, factory: Factory(T)) !Expression(T) {
            return .pow(
                self.den,
                try factory.negPtr(
                    self.num
                )
            );
        }

        pub const Factories = struct {
            pub fn divPtr(factory: Factory(T), num: *Expression(f32), den: *Expression(f32)) !*Expression(f32) {
                return try factory.create(.div(num, den));
            }
        };
    };
}
