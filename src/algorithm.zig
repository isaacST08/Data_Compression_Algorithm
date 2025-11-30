const std = @import("std");

const print = std.debug.print;

// ----- CONSTANTS -----
const MAX_MULTIPLICITY = 257;

pub fn main() void {
    print("Data Compression Algorithm implemented in Zig\n\n", .{});

    const data_size: u32 = 24;
    var data = [data_size]u8{ 0x03, 0x74, 0x04, 0x04, 0x04, 0x35, 0x35, 0x64, 0x64, 0x64, 0x64, 0x00, 0x00, 0x00, 0x00, 0x00, 0x56, 0x45, 0x56, 0x56, 0x56, 0x09, 0x09, 0x09 };
    const data_ptr = &data;

    print("Input data size: {d}\n", .{data_size});
    print("Input data: {any}\n", .{data_ptr[0..data_size]});

    const compressed_data_size: u32 = byteCompress(data_ptr, data_size);

    print("\nCompressed data size: {d}\n", .{compressed_data_size});
    print("Compressed data: {any}\n", .{data_ptr[0..compressed_data_size]});
}

pub fn byteCompress(data_ptr: [*]u8, data_size: u32) u32 {
    // This is the index of the inputted byte buffer at which the data will be
    // read from.
    var input_data_index: u32 = 0;

    // This is the index that the encoded data will be written to onto the data
    // buffer.
    var output_data_index: u32 = 0;

    // Compress and Encode the data.
    while (input_data_index < data_size and output_data_index < data_size) {
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

        // Increment to read the next byte.
        input_data_index += 1;
    }

    // Wipe the trailing bytes of the data buffer that are not required after
    // the compression.
    for (output_data_index..data_size) |i| {
        data_ptr[i] = 0;
    }

    // Return the size of the data buffer after compression.
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
