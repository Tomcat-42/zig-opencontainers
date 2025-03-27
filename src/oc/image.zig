pub const Manifest = @import("image/Manifest.zig");

pub const Descriptor = @import("image/Descriptor.zig");

pub const Digest = @import("image/Digest.zig");

pub const Index = @import("image/Index.zig");

pub const Platform = @import("image/Platform.zig");

pub const SchemaVersion = enum(isize) {
    @"1" = 1,
    @"2" = 2,
    _,

    pub fn jsonStringify(this: @This(), jws: anytype) !void {
        try jws.print("{d}", .{@intFromEnum(this)});
    }
};

pub const MediaType = enum {
    @"application/vnd.oci.descriptor.v1+json",
    @"application/vnd.oci.layout.header.v1+json",
    @"application/vnd.oci.image.index.v1+json",
    @"application/vnd.oci.image.manifest.v1+json",
    @"application/vnd.oci.image.config.v1+json",
    @"application/vnd.oci.empty.v1+json",
    @"application/vnd.oci.image.layer.v1.tar",
    @"application/vnd.oci.image.layer.v1.tar+gzip",
    @"application/vnd.oci.image.layer.v1.tar+zstd",
    @"application/vnd.oci.image.layer.nondistributable.v1.tar",
    @"application/vnd.oci.image.layer.nondistributable.v1.tar+gzip",
    @"application/vnd.oci.image.layer.nondistributable.v1.tar+zstd",
    @"application/vnd.example.sbom.v1",
};
