const std = @import("std");
const Expression = @import("../expression.zig").Expression;
const Factory = @import("../factory.zig").Factory;

pub fn Variable(comptime T: type) type {
    return struct {
        name: []const u8,

        const Self = @This();
    
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
            return if (std.mem.eql(u8, self.name, var_name))
                .{ .Const = .{ .value = 1 } }
            else
                .{ .Const = .{ .value = 0 } };
        }

        pub const Factories = struct {
            pub fn variable(name: []const u8) Expression(T) {
                return .{ .Variable = .{ .name = name } };
            }

            pub fn variablePtr(factory: Factory(T), name: []const u8) !*Expression(T) {
                return try factory.create(.{ .Variable = .{ .name = name } });
            }
        };
    };
}
