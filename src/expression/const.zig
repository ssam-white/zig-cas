const std = @import("std");
const Expression = @import("../expression.zig").Expression;
const Factory = @import("../factory.zig").Factory;

pub fn Const(comptime T: type) type {
    return struct {
        value: T,

        const Self = @This();

        pub fn eval(self: Self, _: Expression(T).Args) T {
            return self.value;
        }

        pub fn print(self: Self) void {
            if (self.value < 0) {
                std.debug.print("( {d} )", .{ self.value });
            } else {
                std.debug.print("{d}", .{ self.value });
            }
        }

        pub fn d(_: Self, _: []const u8, _: Factory(T)) !Expression(T) {
            return .{ .Const = .{ .value = 0 } };
        }


        pub const Factories = struct {
            pub fn constant(value: T) Expression(T) {
                return .{ .Const = .{ .value = value } };
            }

            pub fn constantPtr(factory: Factory(T), value: T) !*Expression(T) {
                return try factory.create(.{ .Const = .{ .value = value } });
            }
        };
    };
}
