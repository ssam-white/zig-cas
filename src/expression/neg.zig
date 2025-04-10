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
            return .neg( try self.exp.*.d(var_name, factory) );
        }

        pub fn rewrite(self: Self, factory: Factory(T)) !Expression(T) {
            return .neg( try self.exp.*.rewrite(factory) );
        }

        pub fn eqlStructure(self: Self, exp: Expression(T)) bool {
            if (exp != .Neg) return false;
            return self.exp.*.eqlStructure(exp.Neg.exp.*);
        }

        pub const Factories = struct {
            pub fn negPtr(factory: Factory(T), exp: *Expression(T)) !Expression(T) {
                return try factory.create(.neg(exp));
            }
        };
    };
}
