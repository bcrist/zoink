
test Grid_Region {
    const empty: [7][14]bool = .{ .{ false } ** 14 } ** 7;

    var data = empty;

    Grid_Region.apply(.all, 14, 7, &data, true);
    try expect_grid_eql(14, 7, data,
        \\oooooooooooooo
        \\oooooooooooooo
        \\oooooooooooooo
        \\oooooooooooooo
        \\oooooooooooooo
        \\oooooooooooooo
        \\oooooooooooooo
        \\
    );

    Grid_Region.apply(.{ .ring = .{
        .dist_from_edges = 1,
        .thickness = 2,
    }}, 14, 7, &data, false);
    try expect_grid_eql(14, 7, data,
        \\oooooooooooooo
        \\o............o
        \\o............o
        \\o..oooooooo..o
        \\o............o
        \\o............o
        \\oooooooooooooo
        \\
    );

    data = empty;
    Grid_Region.apply(.{ .ring = .{
        .dist_from_edges = 2,
        .thickness = 4,
    }}, 14, 7, &data, true);
    try expect_grid_eql(14, 7, data,
        \\..............
        \\..............
        \\..oooooooooo..
        \\..oooooooooo..
        \\..oooooooooo..
        \\..............
        \\..............
        \\
    );

    data = empty;
    Grid_Region.apply(.{ .ring = .{
        .dist_from_edges = 0,
        .thickness = 1,
    }}, 14, 7, &data, true);
    try expect_grid_eql(14, 7, data,
        \\oooooooooooooo
        \\o............o
        \\o............o
        \\o............o
        \\o............o
        \\o............o
        \\oooooooooooooo
        \\
    );

    data = empty;
    Grid_Region.apply(.{ .rows = .{
        .dist_from_top = 1,
        .row_count = 3,
        .mirror = .none,
    }}, 14, 7, &data, true);
    try expect_grid_eql(14, 7, data,
        \\..............
        \\oooooooooooooo
        \\oooooooooooooo
        \\oooooooooooooo
        \\..............
        \\..............
        \\..............
        \\
    );

    data = empty;
    Grid_Region.apply(.{ .rows = .{
        .dist_from_top = 0,
        .row_count = 2,
        .mirror = .ns,
    }}, 14, 7, &data, true);
    try expect_grid_eql(14, 7, data,
        \\oooooooooooooo
        \\oooooooooooooo
        \\..............
        \\..............
        \\..............
        \\oooooooooooooo
        \\oooooooooooooo
        \\
    );

    data = empty;
    Grid_Region.apply(.{ .cols = .{
        .dist_from_left = 0,
        .col_count = 2,
        .mirror = .none,
    }}, 14, 7, &data, true);
    try expect_grid_eql(14, 7, data,
        \\oo............
        \\oo............
        \\oo............
        \\oo............
        \\oo............
        \\oo............
        \\oo............
        \\
    );

    data = empty;
    Grid_Region.apply(.{ .cols = .{
        .dist_from_left = 2,
        .col_count = 3,
        .mirror = .we,
    }}, 14, 7, &data, true);
    try expect_grid_eql(14, 7, data,
        \\..ooo....ooo..
        \\..ooo....ooo..
        \\..ooo....ooo..
        \\..ooo....ooo..
        \\..ooo....ooo..
        \\..ooo....ooo..
        \\..ooo....ooo..
        \\
    );

    data = empty;
    Grid_Region.apply(.{ .corners = .{
        .width = 4,
        .height = 2,
    }}, 14, 7, &data, true);
    try expect_grid_eql(14, 7, data,
        \\oooo......oooo
        \\oooo......oooo
        \\..............
        \\..............
        \\..............
        \\oooo......oooo
        \\oooo......oooo
        \\
    );

    data = empty;
    Grid_Region.apply(.{ .individual = .{
        .row = 2,
        .col = 5,
        .mirror = .none,
    }}, 14, 7, &data, true);
    try expect_grid_eql(14, 7, data,
        \\..............
        \\..............
        \\.....o........
        \\..............
        \\..............
        \\..............
        \\..............
        \\
    );

    data = empty;
    Grid_Region.apply(.{ .individual = .{
        .row = 2,
        .col = 5,
        .mirror = .ns,
    }}, 14, 7, &data, true);
    try expect_grid_eql(14, 7, data,
        \\..............
        \\..............
        \\.....o........
        \\..............
        \\.....o........
        \\..............
        \\..............
        \\
    );

    data = empty;
    Grid_Region.apply(.{ .individual = .{
        .row = 2,
        .col = 5,
        .mirror = .we,
    }}, 14, 7, &data, true);
    try expect_grid_eql(14, 7, data,
        \\..............
        \\..............
        \\.....o..o.....
        \\..............
        \\..............
        \\..............
        \\..............
        \\
    );

    data = empty;
    Grid_Region.apply(.{ .individual = .{
        .row = 2,
        .col = 5,
        .mirror = .both,
    }}, 14, 7, &data, true);
    try expect_grid_eql(14, 7, data,
        \\..............
        \\..............
        \\.....o........
        \\..............
        \\........o.....
        \\..............
        \\..............
        \\
    );

    data = empty;
    Grid_Region.apply(.{ .individual = .{
        .row = 2,
        .col = 5,
        .mirror = .all,
    }}, 14, 7, &data, true);
    try expect_grid_eql(14, 7, data,
        \\..............
        \\..............
        \\.....o..o.....
        \\..............
        \\.....o..o.....
        \\..............
        \\..............
        \\
    );
}

fn expect_grid_eql(comptime Width: usize, comptime Height: usize, grid: [Height][Width]bool, expected: []const u8) !void {
    var temp: std.ArrayList(u8) = .empty;
    defer temp.deinit(std.testing.allocator);

    for (grid) |row| {
        for (row) |ball| {
            try temp.append(std.testing.allocator, if (ball) 'o' else '.');
        }
        try temp.append(std.testing.allocator, '\n');
    }

    try std.testing.expectEqualStrings(expected, temp.items);
}

const Grid_Region = zoink.footprints.Grid_Region;
const zoink = @import("zoink");
const std = @import("std");
