const std = @import("std");
const mem = std.mem;
const json = std.json;
const io = std.io;

const oc = @import("oc");
const image = oc.image;

mediaType: image.MediaType = .@"application/vnd.oci.descriptor.v1+json",
digest: image.Digest,
size: isize,
urls: ?[]const []const u8 = null,
annotations: ?json.ArrayHashMap([]const u8) = null,
data: ?[]const u8 = null,
artifactType: ?image.MediaType = null,
platform: ?image.Platform = null,

test "parse" {
    const expectEqualDeep = std.testing.expectEqualDeep;

    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    const descriptors = [_][]const u8{
        \\{
        \\  "mediaType": "application/vnd.oci.image.manifest.v1+json",
        \\  "size": 7682,
        \\  "digest": "sha256:5b0bcabd1ed22e9fb1310cf6c2dec7cdef19f0ad69efa1f392e94a4333501270"
        \\}
        ,
        \\{
        \\  "mediaType": "application/vnd.oci.image.manifest.v1+json",
        \\  "size": 7682,
        \\  "digest": "sha256:5b0bcabd1ed22e9fb1310cf6c2dec7cdef19f0ad69efa1f392e94a4333501270",
        \\  "urls": [
        \\    "https://example.com/example-manifest"
        \\  ]
        \\}
        ,
        \\{
        \\  "mediaType": "application/vnd.oci.image.manifest.v1+json",
        \\  "size": 123,
        \\  "digest": "sha256:87923725d74f4bfb94c9e86d64170f7521aad8221a5de834851470ca142da630",
        \\  "artifactType": "application/vnd.example.sbom.v1"
        \\}
        ,
    };

    const expected = [descriptors.len]@This(){
        .{
            .mediaType = .@"application/vnd.oci.image.manifest.v1+json",
            .size = 7682,
            .digest = .{
                .algorithm = .sha256,
                .data = "5b0bcabd1ed22e9fb1310cf6c2dec7cdef19f0ad69efa1f392e94a4333501270",
            },
        },
        .{
            .mediaType = .@"application/vnd.oci.image.manifest.v1+json",
            .size = 7682,
            .digest = .{
                .algorithm = .sha256,
                .data = "5b0bcabd1ed22e9fb1310cf6c2dec7cdef19f0ad69efa1f392e94a4333501270",
            },
            .urls = &[_][]const u8{"https://example.com/example-manifest"},
        },
        .{
            .mediaType = .@"application/vnd.oci.image.manifest.v1+json",
            .size = 123,
            .digest = .{
                .algorithm = .sha256,
                .data = "87923725d74f4bfb94c9e86d64170f7521aad8221a5de834851470ca142da630",
            },
            .artifactType = .@"application/vnd.example.sbom.v1",
        },
    };

    var actual: [descriptors.len]@This() = undefined;
    inline for (0..descriptors.len) |i| {
        const parsed = try json.parseFromSlice(@This(), allocator, descriptors[i], .{});
        actual[i] = parsed.value;
    }

    try expectEqualDeep(expected, actual);
}

test "stringify" {
    const expectEqualDeep = std.testing.expectEqualDeep;

    const allocator = std.testing.allocator;

    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();

    const descriptors = [_]@This(){
        .{
            .mediaType = .@"application/vnd.oci.image.manifest.v1+json",
            .size = 7682,
            .digest = .{
                .algorithm = .sha256,
                .data = "5b0bcabd1ed22e9fb1310cf6c2dec7cdef19f0ad69efa1f392e94a4333501270",
            },
        },
        .{
            .mediaType = .@"application/vnd.oci.image.manifest.v1+json",
            .size = 7682,
            .digest = .{
                .algorithm = .sha256,
                .data = "5b0bcabd1ed22e9fb1310cf6c2dec7cdef19f0ad69efa1f392e94a4333501270",
            },
            .urls = &[_][]const u8{"https://example.com/example-manifest"},
        },
        .{
            .mediaType = .@"application/vnd.oci.image.manifest.v1+json",
            .size = 123,
            .digest = .{
                .algorithm = .sha256,
                .data = "87923725d74f4bfb94c9e86d64170f7521aad8221a5de834851470ca142da630",
            },
            .artifactType = .@"application/vnd.example.sbom.v1",
        },
    };

    const expected = [_][]const u8{
        \\{
        \\  "mediaType": "application/vnd.oci.image.manifest.v1+json",
        \\  "digest": "sha256:5b0bcabd1ed22e9fb1310cf6c2dec7cdef19f0ad69efa1f392e94a4333501270",
        \\  "size": 7682
        \\}
        ,
        \\{
        \\  "mediaType": "application/vnd.oci.image.manifest.v1+json",
        \\  "digest": "sha256:5b0bcabd1ed22e9fb1310cf6c2dec7cdef19f0ad69efa1f392e94a4333501270",
        \\  "size": 7682,
        \\  "urls": [
        \\    "https://example.com/example-manifest"
        \\  ]
        \\}
        ,
        \\{
        \\  "mediaType": "application/vnd.oci.image.manifest.v1+json",
        \\  "digest": "sha256:87923725d74f4bfb94c9e86d64170f7521aad8221a5de834851470ca142da630",
        \\  "size": 123,
        \\  "artifactType": "application/vnd.example.sbom.v1"
        \\}
        ,
    };

    var actual: [descriptors.len][]u8 = undefined;
    defer for (actual) |a| allocator.free(a);

    inline for (0..descriptors.len) |i|
        actual[i] = try json.stringifyAlloc(allocator, descriptors[i], .{
            .whitespace = .indent_2,
            .emit_null_optional_fields = false,
        });

    try expectEqualDeep(expected, actual);
}
