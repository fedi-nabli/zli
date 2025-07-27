const std = @import("std");
const cli = @import("cli.zig");

pub const methods = struct {
    pub const commands = struct {
        // Handler for the "hello" command
        pub fn hello_fn(_options: []const cli.option) bool {
            const stdout = std.io.getStdOut().writer();
            stdout.print("Hello, ", .{});

            // Loop for a "name" option
            for (_options) |opt| {
                if (std.mem.eql(u8, opt.name, "name")) {
                    if (opt.value.len > 0) {
                        stdout.print("{s}", .{opt.value});
                    } else {
                        stdout.print("World", .{});
                    }
                    break;
                }
            }

            stdout.print("!\n", .{});
            return true;
        }

        // Handler for the help command
        pub fn help_fn(_: []const cli.option) bool {
            stdout.print(
                "Usage: zli <command> [options]\n" ++
                "Commands:\n" ++
                "  hello    Greet someone\n" ++
                "  help     Show this help message\n" ++
                "" ++
                "Options for hello:\n" ++
                "  -n, --name <value>     Name to greet\n"
                , .{}
            );
            return true;
        }
    };

    pub const options = struct {
        // Handler for te "name" option
        pub fn name_fn(_: []const u8) bool {
            // Option-specific logic goes here
            return true;
        }
    };
};

