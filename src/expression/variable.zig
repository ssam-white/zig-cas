const std = @import("std");
const Expression = @import("../expression.zig").Expression;
const Factory = @import("../factory.zig").Factory;

pub fn Variable(comptime T: type) type {
    return struct {
        name: []const u8,

        const Self = @This();
    

        pub fn initExp(name: []const u8) Expression(T) {
            return .{ .Variable = .{ .name = name } };
        }

        pub fn eval(self: Self, args: Expression(T).Args) T {
            for (args) |arg| {
                if (std.mem.eql(u8, arg[0], self.name)) {
                    return arg[1].eval(args);
                }
            }
            return 0;
        }

        pub fn print(self: Self) void {
            std.debug.print("{s}", .{ self.name });
        }

        pub fn d(self: Self, var_name: []const u8, _: Factory(T)) !Expression(T) {
            return if (std.mem.eql(u8, self.name, var_name)) .constant(1)
            else .constant(0);
        }

        pub fn constantFold(self: Self, _: Factory(T)) !Expression(T) {
            return .{ .Variable = self };
        }

        pub fn simplify(self: Self, _: Factory(T)) !Expression(T) {
            return .{ .Variable = self };
        }

        pub fn eqlStructure(self: Self, exp: Expression(T)) bool {
            return exp == .Variable and std.mem.eql(u8, self.name, exp.Variable.name);
        }

        pub const Factories = struct {
            pub fn variablePtr(factory: Factory(T), name: []const u8) !*Expression(T) {
                return try factory.create(.variable(name));
            }
        };
    };
}
