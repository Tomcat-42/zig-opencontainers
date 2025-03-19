const std = @import("std");
const mem = std.mem;
const fmt = std.fmt;
const process = std.process;
const linux = std.os.linux;
const log = std.log;
const posix = std.posix;

const clap = @import("clap");

const runz = @import("runz");
const util = runz.util;

const params = clap.parseParamsComptime(
    \\-h, --help         Print this message and exit
    \\-e, --env <str>... The environment variables to pass to the container (can be repeated)
    \\<str>              The container image
    \\<str>...           The cmd (and its arguments) to run in the container
);
const Args = clap.ResultEx(clap.Help, &params, clap.parsers.default);

allocator: mem.Allocator,
path: [*:0]const u8,
cmd: [*:null]const ?[*:0]const u8,
env: [*:null]const ?[*:0]const u8,

pub fn init(allocator: mem.Allocator, args: *process.ArgIterator) !@This() {
    var options = clap.parseEx(
        clap.Help,
        &params,
        clap.parsers.default,
        args,
        .{
            .diagnostic = null,
            .allocator = allocator,
        },
    ) catch usage();
    defer options.deinit();

    if (options.args.help != 0) help();
    const path = options.positionals[0] orelse usage();
    if (options.positionals[1].len == 0) usage();

    return @This(){
        .allocator = allocator,
        .path = try allocator.dupeZ(u8, path),
        .cmd = cmd: {
            const cmd = try allocator.allocSentinel(?[*:0]const u8, options.positionals[1].len, null);
            for (0..options.positionals[1].len) |i| cmd[i] = try allocator.dupeZ(u8, options.positionals[1][i]);
            break :cmd cmd;
        },
        .env = env: {
            const env = try allocator.allocSentinel(?[*:0]const u8, options.args.env.len, null);
            for (0..options.args.env.len) |i| env[i] = try allocator.dupeZ(u8, options.args.env[i]);
            break :env env;
        },
    };
}

pub fn deinit(this: *@This()) void {
    const path = mem.span(this.path);
    defer this.allocator.free(path);

    const cmd = mem.span(this.cmd);
    defer this.allocator.free(cmd);
    for (cmd) |c| this.allocator.free(mem.span(c.?));

    const env = mem.span(this.env);
    defer this.allocator.free(env);
    for (env) |e| this.allocator.free(mem.span(e.?));
}

pub fn run(this: *const @This()) !void {
    const pid = try util.syscall(
        linux.syscall2,
        .{
            linux.SYS.clone3,
            @intFromPtr(&util.sys.clone_args{
                .flags = linux.CLONE.NEWUSER |
                    linux.CLONE.NEWPID |
                    linux.CLONE.NEWNS |
                    linux.CLONE.NEWUTS |
                    linux.CLONE.NEWIPC |
                    linux.CLONE.NEWNET |
                    linux.CLONE.NEWCGROUP,
                .exit_signal = linux.SIG.CHLD,
            }),
            @sizeOf(util.sys.clone_args),
        },
    );
    if (pid != 0) {
        var status: u32 = undefined;
        const waitpid = try util.syscall(linux.waitpid, .{ @as(linux.pid_t, @intCast(pid)), &status, 0 });
        log.debug("waitpid({d}, &status, 0) -> {d}, status {d}", .{ pid, waitpid, status });

        return;
    }

    // Ensure no shared propagation
    _ = try util.syscall(linux.mount, .{ "", "/", null, linux.MS.PRIVATE, 0 });

    // Ensure that this.path is a mount point
    _ = try util.syscall(linux.mount, .{ this.path, this.path, null, linux.MS.BIND, 0 });

    // Make this.path/.oldrootfs
    const old_root = try fmt.allocPrintZ(this.allocator, "{s}/{s}", .{ this.path, ".oldrootfs" });
    defer this.allocator.free(old_root);
    _ = try util.syscall(linux.mkdir, .{ old_root, 0o755 });

    // Change the root filesystem to this.path
    _ = try util.syscall(
        linux.syscall2,
        .{
            linux.SYS.pivot_root,
            @as(usize, @intFromPtr(this.path)),
            @as(usize, @intFromPtr(@as([*:0]const u8, @ptrCast(old_root)))),
        },
    );
    _ = try util.syscall(linux.chdir, .{"/"});
    _ = try util.syscall(linux.umount2, .{
        "/.oldrootfs",
        linux.MNT.DETACH,
    });
    _ = try util.syscall(linux.rmdir, .{"/.oldrootfs"});

    // If the PATH environment variable is inherited from the parent process,
    // the execvpe() will search in the HOST's PATH, not the container's PATH.
    _ = try util.syscall(util.sys.unsetenv, .{"PATH"});

    // Echo the PATH environment variable
    const path = posix.getenv("PATH");
    log.debug("getenv(\"PATH\") -> {?s}", .{path});

    const execve = posix.execvpeZ(this.cmd[0].?, this.cmd, this.env);
    log.err("execvpe({?s}, {?any}, {?any}) -> {!}", .{ this.cmd[0], this.cmd, this.env, execve });
}

const stdout = std.io.getStdOut().writer();
const stderr = std.io.getStdErr().writer();

inline fn usage() noreturn {
    clap.usage(stderr, clap.Help, &params) catch @panic("failed to write usage message");
    stderr.writeByte('\n') catch @panic("failed to write newline");
    process.exit(0);
}

inline fn help() noreturn {
    clap.help(stdout, clap.Help, &params, .{
        .markdown_lite = false,
        .spacing_between_parameters = 1,
        .description_on_new_line = true,
        .description_indent = 2,
        .indent = 2,
    }) catch @panic("failed to write help message");
    stdout.writeByte('\n') catch @panic("failed to write newline");
    process.exit(0);
}
