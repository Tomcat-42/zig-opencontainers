const std = @import("std");
const mem = std.mem;
const json = std.json;

const oc = @import("oc");
const image = oc.image;

schemaVersion: image.SchemaVersion = .@"2",
mediaType: image.MediaType = .@"application/vnd.oci.image.manifest.v1+json",
artifactType: ?image.MediaType = null,
config: image.Descriptor,
layers: []const image.Descriptor,
subject: ?image.Descriptor = null,
annotations: ?json.ArrayHashMap([]const u8) = null,

test "parse" {
    const expectEqualDeep = std.testing.expectEqualDeep;

    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    const manifest =
        \\{
        \\  "schemaVersion": 2,
        \\  "mediaType": "application/vnd.oci.image.manifest.v1+json",
        \\  "config": {
        \\    "mediaType": "application/vnd.oci.image.config.v1+json",
        \\    "digest": "sha256:b5b2b2c507a0944348e0303114d8d93aaaa081732b86451d9bce1f432a537bc7",
        \\    "size": 7023
        \\  },
        \\  "layers": [
        \\    {
        \\      "mediaType": "application/vnd.oci.image.layer.v1.tar+gzip",
        \\      "digest": "sha256:9834876dcfb05cb167a5c24953eba58c4ac89b1adf57f28f2f9d09af107ee8f0",
        \\      "size": 32654
        \\    },
        \\    {
        \\      "mediaType": "application/vnd.oci.image.layer.v1.tar+gzip",
        \\      "digest": "sha256:3c3a4604a545cdc127456d94e421cd355bca5b528f4a9c1905b15da2eb4a4c6b",
        \\      "size": 16724
        \\    },
        \\    {
        \\      "mediaType": "application/vnd.oci.image.layer.v1.tar+gzip",
        \\      "digest": "sha256:ec4b8955958665577945c89419d1af06b5f7636b4ac3da7f12184802ad867736",
        \\      "size": 73109
        \\    }
        \\  ],
        \\  "subject": {
        \\    "mediaType": "application/vnd.oci.image.manifest.v1+json",
        \\    "digest": "sha256:5b0bcabd1ed22e9fb1310cf6c2dec7cdef19f0ad69efa1f392e94a4333501270",
        \\    "size": 7682
        \\  },
        \\  "annotations": {
        \\    "com.example.key1": "value1",
        \\    "com.example.key2": "value2"
        \\  }
        \\}
    ;

    const parsed = try json.parseFromSlice(@This(), allocator, manifest, .{});

    const expected: @This() = .{
        .schemaVersion = .@"2",
        .mediaType = .@"application/vnd.oci.image.manifest.v1+json",
        .config = .{
            .mediaType = .@"application/vnd.oci.image.config.v1+json",
            .digest = .{
                .algorithm = .sha256,
                .data = "b5b2b2c507a0944348e0303114d8d93aaaa081732b86451d9bce1f432a537bc7",
            },
            .size = 7023,
        },
        .layers = &.{
            .{
                .mediaType = .@"application/vnd.oci.image.layer.v1.tar+gzip",
                .digest = .{
                    .algorithm = .sha256,
                    .data = "9834876dcfb05cb167a5c24953eba58c4ac89b1adf57f28f2f9d09af107ee8f0",
                },
                .size = 32654,
            },
            .{
                .mediaType = .@"application/vnd.oci.image.layer.v1.tar+gzip",
                .digest = .{
                    .algorithm = .sha256,
                    .data = "3c3a4604a545cdc127456d94e421cd355bca5b528f4a9c1905b15da2eb4a4c6b",
                },
                .size = 16724,
            },
            .{
                .mediaType = .@"application/vnd.oci.image.layer.v1.tar+gzip",
                .digest = .{
                    .algorithm = .sha256,
                    .data = "ec4b8955958665577945c89419d1af06b5f7636b4ac3da7f12184802ad867736",
                },
                .size = 73109,
            },
        },
        .subject = .{
            .mediaType = .@"application/vnd.oci.image.manifest.v1+json",
            .digest = .{
                .algorithm = .sha256,
                .data = "5b0bcabd1ed22e9fb1310cf6c2dec7cdef19f0ad69efa1f392e94a4333501270",
            },
            .size = 7682,
        },
        .annotations = parsed.value.annotations,
    };

    const actual = parsed.value;
    try expectEqualDeep(expected, actual);
}
