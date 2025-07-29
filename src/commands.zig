const std = @import("std");
const cli = @import("cli.zig");

pub const methods = struct {
    pub const commands = struct {
        // Handler for the "hello" command
        pub fn hello_fn(_options: []const cli.option) bool {
            const greeting: []const u8 = "Hello";
            var name: []const u8 = "World";

            // Extract options
            for (_options) |opt| {
                // if (std.mem.eql(u8, opt.name, "greeting")) {
                //    greeting = opt.value;
                //} else
                if (std.mem.eql(u8, opt.name, "name")) {
                    if (opt.value.len > 0) {
                        name = opt.value;
                    }
                }
            }

            cli.print_colored(.Green, "{s}, ", .{greeting});
            cli.print_colored(.Cyan, "{s}", .{name});
            cli.print_colored(.Yellow, "!\n", .{});
            return true;
        }

        // Handler for the help command
        pub fn help_fn(_: []const cli.option) bool {
            const stdout = std.io.getStdOut().writer();
            stdout.print(
                "Usage: zli <command> [options]\n" ++
                "Commands:\n" ++
                "  hello    Greet someone\n" ++
                "  help     Show this help message\n" ++
                "" ++
                "Options for hello:\n" ++
                "  -n, --name <value>     Name to greet\n"
                , .{}
            ) catch {};
            return true;
        }

        // Spinner command example
        pub fn long_running_command(_: []const cli.option) bool {
            var spinner = cli.Spinner.init("Processing...") catch |err| {
                std.debug.print("Failed to initialize spinner: {}\n", .{err});
                return false;
            };

            // Simulate work
            var i: usize = 0;
            while (i < 50) : (i += 1) {
                spinner.tick();
                std.time.sleep(100 * std.time.ns_per_ms);
            }

            spinner.stop("Done processing!");
            return true;
        }

        // progress bar example
        pub fn progress_bar_fn(_: []const cli.option) bool {
            var progress_bar = cli.ProgressBar.init(100, "Processing...", 100);

            // Simulate work
            var i: usize = 0;
            while (i <= 100) : (i += 1) {
                progress_bar.update(1);
            std.time.sleep(100 * std.time.ns_per_ms);
            }

            progress_bar.stop();
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

