const std = @import("std");
const fs = std.fs;
const Build = std.Build;
const Step = Build.Step;
const Module = Build.Module;
const Import = Module.Import;
const builtin = @import("builtin");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    // Modules and Deps
    const oci_mod = b.createModule(.{
        .root_source_file = b.path("src/oci.zig"),
        .target = target,
        .optimize = optimize,
    });
    const runz_mod = b.createModule(.{
        .root_source_file = b.path("src/runz.zig"),
        .target = target,
        .optimize = optimize,
    });

    const oci_deps: []const Import = &.{
        .{ .name = "oci", .module = oci_mod },
    };
    for (oci_deps) |dep| oci_mod.addImport(dep.name, dep.module);

    const runz_deps: []const Import = &.{
        .{ .name = "oci", .module = oci_mod },
    };
    for (runz_deps) |dep| runz_mod.addImport(dep.name, dep.module);

    // Targets
    const oci = b.addLibrary(.{
        .linkage = .static,
        .name = "oci",
        .root_module = oci_mod,
    });
    const oci_tests = b.addTest(.{
        .root_module = oci_mod,
    });
    const oci_check = b.addLibrary(.{
        .name = "oci_check",
        .root_module = oci_mod,
    });
    const runz = b.addExecutable(.{
        .linkage = .static,
        .link_libc = true,
        .name = "oci",
        .root_module = runz_mod,
    });
    const runz_tests = b.addTest(.{
        .root_module = runz_mod,
    });
    const runz_check = b.addExecutable(.{
        .name = "runz_check",
        .root_module = runz_mod,
    });

    // Install
    b.installArtifact(oci);
    b.installArtifact(runz);

    // Run
    const run_cmd = b.addRunArtifact(runz);
    run_cmd.step.dependOn(b.getInstallStep());
    if (b.args) |args| run_cmd.addArgs(args);
    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);

    // Test
    const run_oci_tests = b.addRunArtifact(oci_tests);
    const run_runz_tests = b.addRunArtifact(runz_tests);
    const test_step = b.step("test", "Run unit tests");
    test_step.dependOn(&run_oci_tests.step);
    test_step.dependOn(&run_runz_tests.step);

    // Clean
    const clean_step = b.step("clean", "Remove build artifacts");
    clean_step.dependOn(&b.addRemoveDirTree(b.path(fs.path.basename(b.install_path))).step);
    if (builtin.os.tag != .windows)
        clean_step.dependOn(&b.addRemoveDirTree(b.path(".zig-cache")).step);

    // Check Step
    const check_step = b.step("check", "Check that the build artifacts are up-to-date");
    check_step.dependOn(&oci_check.step);
    check_step.dependOn(&runz_check.step);
}
