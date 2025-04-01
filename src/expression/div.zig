const std = @import("std");
const Expression = @import("../expression.zig").Expression;
const Factory = @import("../factory.zig").Factory;

pub fn Div(comptime T: type) type {
    return struct {
        num: *Expression(T),
        den: *Expression(T),

        const Self = @This();
        
        pub fn eval(self: Self, args: Expression(T).Args) T {
            // return std.math.divExact(T, self.num.*.eval(args), self.den.*.eval(args)) catch unreachable;
            return self.num.*.eval(args) / self.den.*.eval(args);
        }

        pub fn print(self: Self) void {
            std.debug.print("( ", .{});
            self.num.*.print();
            std.debug.print(" / ", .{});
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

            return Factory(T).div(u_prime_v_sub_u_v_prime, v_sqrd);
        }

        pub const Factories = struct {
            pub fn div(num: *Expression(f32), den: *Expression(f32)) Expression(f32) {
                return .{ .Div = .{ .num = num, .den = den } };
            }

            pub fn divPtr(factory: Factory(T), num: *Expression(f32), den: *Expression(f32)) !*Expression(f32) {
                return try factory.create(.{ .Div = .{ .num = num, .den = den } });
            }
        };
    };
}
