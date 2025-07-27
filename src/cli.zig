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
    req: Slices = &. {}, // Required options
    opt: Slices = &. {}, // Optional options
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

