const std = @import("std");
const builtin = @import("builtin");

pub const MAX_COMMANDS: u8 = 10;
pub const MAX_OPTIONS: u8 = 20;

const Byte = u8;
const Slice = []const Byte;
const Slices = []const Slice;

/// Structires to represent the type of command
pub const command = struct {
    name: Slice, // Name of the command
    func: fnType, // Function to execute the command
    req: Slices = &.{}, // Required options
    opt: Slices = &.{}, // Optional options
    const fnType = *const fn ([]const option) bool;
};

/// Structure to represent the type of option
pub const option = struct {
    name: Slice, // Name of the option
    func: ?fnType = null, // Function to execute the option
    short: Byte, // Short form, e.g., -n|-N
    long: Slice, // Long form, e.g., --name
    value: Slice = "", // Value of the option
    const fnType = *const fn (Slice) bool;
};

/// Possible error during CLI execution
pub const Error = error {
    NoArgsProvided,
    UnknownCommand,
    UnknownOption,
    MissingRequiredOption,
    UnexpectedArgument,
    CommandExecutionFailed,
    TooManyCommands,
    TooManyOptions,
};

pub const Color = enum {
    Reset,
    Black,
    Red,
    Green,
    Yellow,
    Blue,
    Magenta,
    Cyan,
    White,

    pub fn ansi_code(self: Color) []const u8 {
        return switch (self) {
            .Reset => "\x1b[0m",
            .Black => "\x1b[30m",
            .Red => "\x1b[31m",
            .Green => "\x1b[32m",
            .Yellow => "\x1b[33m",
            .Blue => "\x1b[34m",
            .Magenta => "\x1b[35m",
            .Cyan => "\x1b[36m",
            .White => "\x1b[37m",
        };
    }
};

/// Start the CLI application
pub fn start(commands: []const command, options: []const option, debug: bool) !void {
    if (commands.len > MAX_COMMANDS) {
        return Error.TooManyCommands;
    }
    if (options.len > MAX_OPTIONS) {
        return Error.TooManyOptions;
    }

    // Create a general-purpose allocator for handling memory during execution
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    // Retrieve the command-line arguments in a cross-platform manner
    const args = try std.process.argsAlloc(allocator);
    defer std.process.argsFree(allocator, args);

    try start_with_args(commands, options, args, debug);
}

/// Starts the CLI application with provided arguments
pub fn start_with_args(commands: []const command, options: []const option, args: anytype, debug: bool) !void {
    const stdout = std.io.getStdOut().writer();

    if (args.len < 2) {
        if (debug) stdout.print("No command provided by user!\n", .{}) catch {};
        return Error.NoArgsProvided;
    }

    // Extract the name of the command (the second argument after program name)
    const command_name = args[1];
    var detected_command: ?command = null;

    // Search through the list of available commands to find a match
    for (commands) |cmd| {
        if (std.mem.eql(u8, cmd.name, command_name)) {
            detected_command = cmd;
            break;
        }
    }

    // If no matching command is found, return an error
    if (detected_command == null) {
        if (debug) stdout.print("Unknown command: {s}\n", .{command_name}) catch {};
        return Error.UnknownCommand;
    }

    // Retrieve the matched command from the optional variable
    const cmd = detected_command.?;

    if (debug) stdout.print("Detected command: {s}\n", .{cmd.name}) catch {};

    // Allocate memory for detected options based on remaining arguments
    var detected_options: [MAX_OPTIONS]option = undefined;
    var detected_len: usize = 0;
    var i: usize = 2;

    // Parsing options to capture their values
    while (i < args.len) {
        const arg = args[i];

        if (std.mem.startsWith(u8, arg, "-")) {
            const option_name = if (std.mem.startsWith(u8, arg[1..], "-")) arg[2..] else arg[1..];
            var matched_option: ?option = null;

            for (options) |opt| {
                if (std.mem.eql(u8, option_name, opt.long) or (option_name.len == 1 and option_name[0] == opt.short)) {
                    matched_option = opt;
                    break;
                }
            }

            if (matched_option == null) {
                if (debug) stdout.print("Unknown option: {s}\n", .{arg}) catch {};
                return Error.UnknownOption;
            }

            var opt = matched_option.?;

            // Detect the value for the option
            if (i + 1 < args.len and !std.mem.startsWith(u8, args[i + 1], "-")) {
                opt.value = args[i + 1];
                i += 1;
            } else {
                opt.value = "";
            }

            if (detected_len >= MAX_OPTIONS) {
                return Error.TooManyOptions;
            }

            detected_options[detected_len] = opt;
            detected_len += 1;
        } else {
            if (debug) stdout.print("Unexpected argument: {s}\n", .{arg}) catch {};
            return Error.UnexpectedArgument;
        }

        i += 1;
    }

    // Slice the detected options to the actual number of detected options
    const used_options = detected_options[0..detected_len];

    // Ensure all required options for the detected command are provided
    for (cmd.req) |req_option| {
        var found = false;

        for (used_options) |opt| {
            if (std.mem.eql(u8, req_option, opt.name)) {
                found = true;
                break;
            }
        }

        if (!found) {
            if (debug) stdout.print("Missing required option: {s}\n", .{req_option}) catch {};
            return Error.MissingRequiredOption;
        }
    }

    // Execute the command's associated function with the detected options
    if (!cmd.func(used_options)) {
        return Error.CommandExecutionFailed;
    } else {
        // Execute option functions
        for (used_options) |opt| {
            if (opt.func == null) continue;

            const result = opt.func.?(opt.value);

            if (!result) {
                if (debug) stdout.print("Option function execution failed: {s}\n", .{opt.name}) catch {};
                // return Error.CommandExecutionFailed;
            }
        }
    }

    // If execution reaches this point, the command was executed successfully
    if (debug) stdout.print("Command executed successfully: {s}\n", .{cmd.name}) catch {};
}

pub fn print_colored(color: Color, comptime fmt: []const u8, args: anytype) void {
    const stdout = std.io.getStdOut().writer();
    stdout.print("{s}" ++ fmt ++ "{s}", .{color.ansi_code()} ++ args ++ .{Color.Reset.ansi_code()}) catch {};
}

pub const Spinner = struct {
    frames: []const []const u8,
    current: usize = 0,
    message: []const u8,
    timer: std.time.Timer,

    pub fn init(message: []const u8) !Spinner {
        return Spinner {
            .frames = &[_][]const u8{ "⠋", "⠙", "⠹", "⠸", "⠼", "⠴", "⠦", "⠧", "⠇", "⠏" },
            .message = message,
            .timer = try std.time.Timer.start(),
            .current = 0,
        };
    }

    pub fn tick(self: *Spinner) void {
        const stdout = std.io.getStdOut().writer();
        _ = stdout.print("\r{s} {s}", .{self.frames[self.current], self.message}) catch {};
        self.current = (self.current + 1) % self.frames.len;
    }

    pub fn stop(_: *Spinner, message: []const u8) void {
        const stdout = std.io.getStdOut().writer();
        _ = stdout.print("\r✓ {s}\n", .{message}) catch {};
    }
};

pub const ProgressBar = struct {
    total: usize,
    current: usize = 0,
    width: usize = 40,
    message: []const u8,

    pub fn init(total: usize, message: []const u8, width: ?usize) ProgressBar {
        return ProgressBar {
            .message = message,
            .total = total,
            .current = 0,
            .width = width orelse 40,
        };
    }

    pub fn update(self: *ProgressBar, step: usize) void {
        const stdout = std.io.getStdOut().writer();
        // Unicode block characters
        const filled_block = "█";
        const empty_block = "░";

        self.current += step;
        if (self.current > self.total) self.current = self.total;

        const percent: f64 = @as(f64, @floatFromInt(self.current)) / @as(f64, @floatFromInt(self.total));
        const filled: usize = @intFromFloat(percent * @as(f64, @floatFromInt(self.width)));

        _ = stdout.print("\r{s} [", .{self.message}) catch {};

        for (0..self.width) |i| {
            if (i < filled) {
                _ = stdout.print("{s}", .{filled_block}) catch {};
            } else {
                _ = stdout.print("{s}", .{empty_block}) catch {};
            }
        }

        _ = stdout.print("] {d:3}%", .{@as(u8, @intFromFloat(percent * 100.0))}) catch {};
    }

    pub fn stop(self: *ProgressBar) void {
        self.current = self.total;
        self.update(0); // draw final bar
        const stdout = std.io.getStdOut().writer();
        _ = stdout.print("\n", .{}) catch {};
    }
};

