const std = @import("std");
const cli = @import("cli.zig");
const cmd = @import("commands.zig");

pub fn main() !void {
    // Define available commands
    const commands = [_]cli.command{
        cli.command{
            .name = "hello",
            .func = &cmd.methods.commands.hello_fn,
            .opt = &.{"name"}, // "name" is optional for the hello command
        },
        cli.command{
            .name = "help",
            .func = &cmd.methods.commands.help_fn,
        },
        cli.command{
            .name = "spinner",
            .func = &cmd.methods.commands.long_running_command,
        },
        cli.command{
            .name = "progress",
            .func = &cmd.methods.commands.progress_bar_fn,
        },
    };

    // Define available options
    const options = [_]cli.option{
        cli.option{
            .name = "name",
            .short = 'n',
            .long = "name",
            .func = &cmd.methods.options.name_fn,
        },
    };

    // Starrt with CLI application
    try cli.start(&commands, &options, true);
}

