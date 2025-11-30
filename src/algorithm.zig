const std = @import("std");

const print = std.debug.print;

// ----- CONSTANTS -----
const MAX_MULTIPLICITY = 257;

pub fn main() !void {
    print("Data Compression Algorithm implemented in Zig\n\n", .{});

    const data_size: u32 = 24;
    var data = [data_size]u8{ 0x03, 0x74, 0x04, 0x04, 0x04, 0x35, 0x35, 0x64, 0x64, 0x64, 0x64, 0x00, 0x00, 0x00, 0x00, 0x00, 0x56, 0x45, 0x56, 0x56, 0x56, 0x09, 0x09, 0x09 };
    const data_ptr = &data;

    print("Input data size: {d}\n", .{data_size});
    print("Input data: {any}\n", .{data_ptr[0..data_size]});

    const compressed_data_size: u32 = byteCompress(data_ptr, data_size);

    print("\nCompressed data size: {d}\n", .{compressed_data_size});
    print("Compressed data: {any}\n", .{data_ptr[0..compressed_data_size]});

    const decompressed_data_size: u32 = try byteDecompress(data_ptr, compressed_data_size, data.len);

    print("\nDecompressed data size: {d}\n", .{decompressed_data_size});
    print("Decompressed data: {any}\n", .{data_ptr[0..decompressed_data_size]});
}

pub fn byteCompress(data_ptr: [*]u8, data_size: u32) u32 {
    // This is the index of the inputted byte buffer at which the data will be
    // read from.
    var input_data_index: u32 = 0;

    // This is the index that the encoded data will be written to onto the data
    // buffer.
    var output_data_index: u32 = 0;

    // Compress and Encode the data.
    while (input_data_index < data_size and output_data_index < data_size) : (input_data_index += 1) {
        // Get the next byte from the input array.
        // All data values range from 0x00 to 0x7F, so we only need to record
        // the value as a u7.
        const input_byte: u7 = @truncate(data_ptr[input_data_index]);

        // Calculate the multiplicity of the byte-instance.
        var multiplicity: u9 = 1;
        while (multiplicity < MAX_MULTIPLICITY and input_data_index + 1 < data_size and data_ptr[input_data_index + 1] == input_byte) {
            input_data_index += 1;
            multiplicity += 1;
        }

        // Encode the data output byte.
        // If the byte is sequential, set the highest bit to 1 to indicate that
        // a multiplicity byte is to follow.
        const output_byte: u8 = if (multiplicity > 1) 0b10000000 | @as(u8, input_byte) else @as(u8, input_byte);

        // Write the encoded data-byte.
        data_ptr[output_data_index] = output_byte;
        output_data_index += 1;

        // If this byte-instance is sequential, encode and write it's
        // multiplicity to the following byte.
        if (multiplicity >= 2) {
            data_ptr[output_data_index] = @truncate(multiplicity - 2);
            output_data_index += 1;
        }
    }

    // Wipe the trailing bytes of the data buffer that are not required after
    // the compression.
    for (output_data_index..data_size) |i| {
        data_ptr[i] = 0;
    }

    // Return the size of the data buffer after compression.
    return output_data_index;
}

pub fn byteDecompress(compressed_data_ptr: [*]u8, compressed_data_size: u32, max_data_size: u32) !u32 {
    var gpa = std.heap.GeneralPurposeAllocator(.{}).init;
    const allocator = gpa.allocator();

    // Create a buffer to store the decompressed data.
    var data_output = try allocator.alloc(u8, max_data_size);
    defer allocator.free(data_output);

    var input_data_index: u32 = 0;
    var output_data_index: u32 = 0;

    // Decompress the data.
    while (input_data_index < compressed_data_size and output_data_index < max_data_size) : (input_data_index += 1) {
        const encoded_byte: u8 = compressed_data_ptr[input_data_index];

        // Decode the multiplicity of the data byte.
        var multiplicity: u9 = 1;
        if (encoded_byte >> 7 == 1 and input_data_index + 1 < compressed_data_size) {
            input_data_index += 1;
            multiplicity = compressed_data_ptr[input_data_index] + 2;
        }

        // Decode the data from the encoded byte.
        const data_byte: u7 = @truncate(encoded_byte);

        // Write the decoded data back into its original form.
        while (multiplicity > 0 and output_data_index < max_data_size) : ({
            multiplicity -= 1;
            output_data_index += 1;
        }) {
            data_output[output_data_index] = @intCast(data_byte);
        }
    }

    // Transfer the data from the internal buffer to the data source buffer.
    for (0..output_data_index) |i| {
        compressed_data_ptr[i] = data_output[i];
    }

    // Return the size of the uncompressed data.
    return output_data_index;
}

// **=====================================**
// ||          <<<<< TESTS >>>>>          ||
// **=====================================**

test "Compression Test 1 :: Compression Size" {
    const data_size: u32 = 24;
    var data = [data_size]u8{ 0x03, 0x74, 0x04, 0x04, 0x04, 0x35, 0x35, 0x64, 0x64, 0x64, 0x64, 0x00, 0x00, 0x00, 0x00, 0x00, 0x56, 0x45, 0x56, 0x56, 0x56, 0x09, 0x09, 0x09 };
    const data_ptr = &data;

    const compressed_data_size: u32 = byteCompress(data_ptr, data_size);

    try std.testing.expect(compressed_data_size == 16);
}

test "Compression Test 2 :: Compression Content" {
    const data_size: u32 = 24;
    var data = [data_size]u8{
        0x03,
        0x74,
        0x04,
        0x04,
        0x04,
        0x35,
        0x35,
        0x64,
        0x64,
        0x64,
        0x64,
        0x00,
        0x00,
        0x00,
        0x00,
        0x00,
        0x56,
        0x45,
        0x56,
        0x56,
        0x56,
        0x09,
        0x09,
        0x09,
    };
    const data_ptr = &data;

    const compressed_data_size: u32 = byteCompress(data_ptr, data_size);

    const expected_compressed_data_size = 16;
    const expected_compressed_data = [expected_compressed_data_size]u8{
        0x03,
        0x74,
        0x84,
        0x01,
        0xB5,
        0x00,
        0xE4,
        0x02,
        0x80,
        0x03,
        0x56,
        0x45,
        0xd6,
        0x01,
        0x89,
        0x01,
    };

    try std.testing.expect(compressed_data_size == expected_compressed_data_size);
    try std.testing.expectEqualSlices(u8, expected_compressed_data[0..expected_compressed_data.len], data[0..compressed_data_size]);
}

test "Compression Test 3 :: Decompression" {
    const compressed_data_size = 16;
    const compressed_data = [compressed_data_size]u8{ 0x03, 0x74, 0x84, 0x01, 0xB5, 0x00, 0xE4, 0x02, 0x80, 0x03, 0x56, 0x45, 0xd6, 0x01, 0x89, 0x01 };

    const expected_data_size: u32 = 24;
    const expected_data = [expected_data_size]u8{ 0x03, 0x74, 0x04, 0x04, 0x04, 0x35, 0x35, 0x64, 0x64, 0x64, 0x64, 0x00, 0x00, 0x00, 0x00, 0x00, 0x56, 0x45, 0x56, 0x56, 0x56, 0x09, 0x09, 0x09 };

    var data: [expected_data_size]u8 = undefined;
    for (compressed_data, 0..) |compressed_byte, i| {
        data[i] = compressed_byte;
    }

    const actual_data_size: u32 = try byteDecompress(&data, compressed_data_size, expected_data_size);

    try std.testing.expectEqual(expected_data_size, actual_data_size);
    try std.testing.expectEqualSlices(u8, expected_data[0..expected_data.len], data[0..data.len]);
}

test "Compression Test 4 :: Compression-Decompression Cycle" {
    const data_size: u32 = 24;
    const source_data = [data_size]u8{
        0x03,
        0x74,
        0x04,
        0x04,
        0x04,
        0x35,
        0x35,
        0x64,
        0x64,
        0x64,
        0x64,
        0x00,
        0x00,
        0x00,
        0x00,
        0x00,
        0x56,
        0x45,
        0x56,
        0x56,
        0x56,
        0x09,
        0x09,
        0x09,
    };

    const expected_compressed_data_size = 16;
    const expected_compressed_data = [expected_compressed_data_size]u8{
        0x03,
        0x74,
        0x84,
        0x01,
        0xB5,
        0x00,
        0xE4,
        0x02,
        0x80,
        0x03,
        0x56,
        0x45,
        0xd6,
        0x01,
        0x89,
        0x01,
    };

    var data: [source_data.len]u8 = undefined;
    for (source_data, 0..) |byte, i| {
        data[i] = byte;
    }

    const compressed_data_size: u32 = byteCompress(&data, data_size);

    try std.testing.expectEqual(expected_compressed_data_size, compressed_data_size);
    try std.testing.expectEqualSlices(u8, expected_compressed_data[0..expected_compressed_data_size], data[0..compressed_data_size]);

    const decompressed_data_size: u32 = try byteDecompress(&data, compressed_data_size, data.len);

    try std.testing.expectEqual(data_size, decompressed_data_size);
    try std.testing.expectEqualSlices(u8, source_data[0..data_size], data[0..decompressed_data_size]);
}
