const std = @import("std");
const Expression = @import("../expression.zig").Expression;
const Factory = @import("../factory.zig").Factory;

pub fn Neg(comptime T: type) type {
    return struct {
        exp: *Expression(T),

        const Self = @This();

        pub fn initExp(exp: *Expression(T)) Expression(T) {
            return .{ .Neg = .{ .exp = exp } };
        }

        pub fn eval(self: Self, args: Expression(T).Args) T {
            return -( self.exp.eval(args) );
        }

        pub fn print(self: Self) void {
            std.debug.print("-", .{});
            self.exp.print();
        }

        pub fn d(self: Self, var_name: []const u8, factory: Factory(T)) !Expression(T) {
            const d_exp = try self.exp.*.d(var_name, factory);
            const d_exp_ptr = try factory.create(d_exp);
            return .neg(d_exp_ptr);
        }

        pub fn constantFold(self: Self, _: Factory(T)) !Expression(T) {
            return if (self.exp.* == .Const)
                .constant(-self.exp.*.Const.value)
            else .{ .Neg = self };
        }

        pub fn simplify(self: Self, factory: Factory(T)) !Expression(T) {
            const new_exp = try self.exp.*.simplify(factory);
            return .neg(try factory.create(new_exp));
        }

        pub fn eqlStructure(self: Self, exp: Expression(T)) bool {
            if (exp != .Neg) return false;
            return self.exp.*.eqlStructure(exp.Neg.exp.*);
        }

        pub const Factories = struct {
            pub fn negPtr(factory: Factory(T), exp: *Expression(T)) !*Expression(T) {
                return try factory.create(.neg(exp));
            }
        };
    };
}
