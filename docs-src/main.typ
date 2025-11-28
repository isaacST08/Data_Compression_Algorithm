#import "@preview/mannot:0.3.1"

#set page(margin: (x: 18mm, y: 18mm), numbering: "1", paper: "a4")
#set math.equation(numbering: "(1)", supplement: "Eq.")
#set par(justify: true)
#set heading(numbering: "1.1")

#show link: set text(fill: rgb(0, 110, 210))

#show "7 byte chunk": "7-byte-chunk"

// **=====================================**
// ||          <<<<< TITLE >>>>>          ||
// **=====================================**

#[
  #v(-9pt)
  #box(text(size: 25pt, weight: 700, smallcaps(
    [Data Compression Algorithm Design],
  )))
  #v(-5pt)
  #line(length: 100%)
  #v(-6pt)
  #align(
    left,
    [
      / Author\:: _Isaac Shiells Thomas_
      / Email\:: #link("mailto:isaacshiellsthomas.work@proton.me")
      // / Repo\:: #link(
      //   )
    ],
  )
  #v(-5pt)
  #line(length: 100%)
  #v(-10.5pt)
  #line(length: 100%)
]


// **=================================================**
// ||          <<<<< TABLE OF CONTENTS >>>>>          ||
// **=================================================**

#v(0pt)

#outline()

#v(12pt)
#align(center, line(length: 70%, stroke: (cap: "round", paint: luma(50%))))
#v(8pt)



// **=======================================**
// ||          <<<<< CONTENT >>>>>          ||
// **=======================================**

= Context

This is an algorithm designed to compress a given buffer of data in the form of
a byte array.

The algorithm lives within a function. This function is called with two
arguments; a pointer to a data buffer in the form of a byte array
($mono("data_ptr")$), and the number of bytes to compress in the form of an
integer ($mono("data_size")$). After the function executes, the data in the
buffer will be modified and the size of the modified buffer will be returned.

It is not expected for the algorithm to reallocate memory for the new size of
the buffer. The space after the requested number of bytes to be compressed will
not be altered, and the trailing space --- the space saved by the compression
--- will be zeroed.

== Assumptions
+ The $mono("data_ptr")$ will point to an array of bytes. Each byte will
  contain a number from $0$ to $127$ ($mono("0x00")$ to $mono("0x7F")$).
  Additionally, it is common for the data in the buffer to have the same value
  repeated multiple times in a row.
+ The compressed data needs to be decompressable. A accompanying function that
  will decompress the data must exist.


= Algorithm

This algorithm will compare chunks of 7 _semi-unique_ bytes at a time, starting
from the $0^"th"$ byte of the byte array. First, the initial byte is recorded,
the algorithm then scans the each subsequent byte until a byte of a different
value is found. At that point, the quantity of the first byte, and it's value,
are recorded as the _first_ of the _7 byte chunk_, and then the algorithm
continues for the next byte (the one that ended the sequential streak of the
first byte). The process is repeated until 7 bytes are found. If the algorithm
comes across a byte that is already present as a previous value in the _7 byte
chunk_, then it treats it _no differently_ than if it was completely new. The
algorithm only cares about separating and condensing the sequential streams of
bytes (bytes that all have the same value and appear in a row). It does not
care if the _7 byte chunk_ consists of only two different bytes, alternating
back and forth.

Now that the _7 byte chunk_ has been filled, the algorithm will handle two
cases differently: 1) When their exists at least one byte that appears three or
more times in a row, and 2) when there doesn't.

In both cases, a header byte will be used to facilitate the decoding process.
#link(<case1>)[Case 1] will use a full header byte while #link(<case2>)[case 2]
will use a partial header byte (details explained below). Despite their
differences, the two cases use a single high order bit to declare to the
decoder which type of compression was used for the following block of bytes. A
high order bit of value "$mono("0")$" indicates that the sub-algorithm defined
in case 1 is used, while a high order bit of value "$mono("1")$" indicates that
the sub-algorithm defined in case 2 is used.

The two cased are defined as follows:

== Case 1: 3 or More Sequential Bytes Found <case1>

This case occurs when at least one of the bytes in the _7 byte chunk_ occurred
*three times or more* _sequentially_. Bytes of equal value within the _7 byte
chunk_ but are immediately preceded and followed by bytes of differing values,
as well as like bytes that appear in pairs *do not* qualify for this case.

For example, consider the following streams:
$
  (mono("0x04"), mono("0x11"), mono("0x11"), mono("0x11"), ...),
$ <eq:stream_example_1>
$
  (mono("0x04"), mono("0x11"), mono("0x04"), mono("0x51"), ...),
$ <eq:stream_example_2>
and
$
  (mono("0x6C"), mono("0x39"), mono("0x6C"), mono("0x6C"), mono("0x44"), ...).
$ <eq:stream_example_3>

The first stream (@eq:stream_example_1) would include the byte $mono("0x11")$
with a quantity of *3* as the second byte type of its 7-byte-chunk. This stream
would qualify for this case.

The second stream (@eq:stream_example_2) would include the byte $mono("0x04")$
with a quantity of *1* as the first byte type of its 7-byte-chunk, and would
include the (same) byte $mono("0x04")$ with a quantity of *1* as the third byte
type of its 7-byte-chunk. This stream would *not* qualify for this conditional
case (see #link(<case2>)[case 2] where it would qualify).

The third stream (@eq:stream_example_3) would include the byte $mono("0x6C")$
with a quantity of *1* as the first byte type of its 7-byte-chunk, the byte
$mono("0x39")$ with a quantity of *1* as the second byte type, and the byte
$mono("0x6C")$ with a quantity of *2* as the third byte type of its
7-byte-chunk. Note how the bytes $mono("0x6C")$ are *not* aggregated into one.
This stream would *not* qualify
for this conditional case (see #link(<case2>)[case 2] where it would qualify).

#v(12pt)

This case uses a header byte to provide information about the following set of
bytes. This header byte is a full header byte, meaning that all of the bits of
the header are used to convey information other than the data. This header byte
has the following encoding:

#v(0.5em)
$
  #let bit(val) = box(width: 8pt, height: 9pt, {
    place(center + bottom, dy: -0.4pt, if (val == none) [] else [$mono(#str(val))$])
    place(bottom + center, dy: 1pt, line(length: 5.5pt, stroke: (cap: "round", thickness: 0.9pt)))
  })
  mannot.mark(#bit(0), tag: #<b0>, outset: #2pt)
  overbrace(
    mannot.mark(#bit(none), tag: #<b1>, outset: #2pt)
    mannot.mark(#bit(none), tag: #<b2>, outset: #2pt)
    mannot.mark(#bit(none), tag: #<b3>, outset: #2pt)
    mannot.mark(#bit(none), tag: #<b4>, outset: #2pt)
    mannot.mark(#bit(none), tag: #<b5>, outset: #2pt)
    mannot.mark(#bit(none), tag: #<b6>, outset: #2pt)
    mannot.mark(#bit(none), tag: #<b7>, outset: #2pt),
    "Repeated Byte" \ "Indicators"
  )
  #mannot.annot(<b0>, dy: 1em, dx: -4.3em, leader-connect: (bottom, right), annot-inset: 1pt)[Compression Type Bit]
  #mannot.annot(<b1>, dy: -0.4pt)[#text(size: 6.1pt, [$1$])]
  #mannot.annot(<b2>, dy: -0.4pt)[#text(size: 6.1pt, [$2$])]
  #mannot.annot(<b3>, dy: -0.4pt)[#text(size: 6.1pt, [$3$])]
  #mannot.annot(<b4>, dy: -0.4pt)[#text(size: 6.1pt, [$4$])]
  #mannot.annot(<b5>, dy: -0.4pt)[#text(size: 6.1pt, [$5$])]
  #mannot.annot(<b6>, dy: -0.4pt)[#text(size: 6.1pt, [$6$])]
  #mannot.annot(<b7>, dy: -0.4pt)[#text(size: 6.1pt, [$7$])]
$ <eq:case1:headerbyte>
#v(2em)

The _Compression Type Bit_ indicates that is following set of bytes is encoded
using the sub-algorithm of this case. Each bit of the _Repeated Byte
Indicators_ encode whether the byte at that positional index is a sequential
encoded byte or not.

If the bit at position 1 (on @eq:case1:headerbyte) is set to "$mono("0")$",
then the byte is an individual byte and does not have any multiplicity.
Otherwise, if the bit is set to "$mono("1")$", then this indicates that the
byte _does_ have multiplicity and the pair of bytes at that relative index
should be considered: The first byte of the pair is the actual value of the
byte. The second byte of the pair is the number of times this byte appears
sequentially in the original data.

For example, the stream
$
  (
    mono("0x03"),
    mono("0x74"),
    mono("0x04"), mono("0x04"),
    mono("0x35"), mono("0x35"),
    mono("0x64"), mono("0x64"), mono("0x64"), mono("0x64"),
    mono("0x00"), mono("0x00"), mono("0x00"), mono("0x00"), mono("0x00"),
    mono("0x56")
  )
$ <eq:stream_example_4>
would become the _7-byte-chunk_ represented by the array of 2-tuples where the
first value of each 2-tuple represents the byte value, and the second value
represents the multiplicity of that byte (the number of times it occurred in a
row). The position of the 2-tuple in the array represents position of that byte
relative to the other 2-tuples in the _7-byte-chunk_. As follows:
$
  (
    ( mono("0x03"), 1 ),
    ( mono("0x74"), 1 ),
    ( mono("0x04"), 2 ),
    ( mono("0x35"), 2 ),
    ( mono("0x64"), 4 ),
    ( mono("0x00"), 5 ),
    ( mono("0x56"), 1 ),
  )
$<eq:7_byte_chunk_1>
when encoded back into a byte array, using this algorithm, we would get:
$
  (
    mono("0b00011110"),
    mono("0x03"),
    mono("0x74"),
    mono("0x04"), mono("0x00"),
    mono("0x35"), mono("0x00"),
    mono("0x64"), mono("0x02"),
    mono("0x00"), mono("0x03"),
    mono("0x56")
  ).
$<eq:compressed_bytes_1>

This resulting compressed data is 12 bytes in length, whereas the original
stream of data was 16 bytes in length. That's a 25% decrease, and thus a
successful compression.

You may notice that in the compressed stream of bytes (@eq:compressed_bytes_1)
that the multiplicity bytes do not match the values found in the corresponding
7-byte-chunk (@eq:7_byte_chunk_1). In fact, they are all a value of 2 lower
than what might have been expected. This is because in the header byte, we
already indicate when a pair of bytes will be present, and this only occurs
when the byte value has a multiplicity of at least 2. Thus, we can set the
multiplicity byte to start counting at 2 (represented by the value 0) so that
we can store a byte with a multiplicity of up to 257 instead of only up to a
multiplicity of 255; slightly increasing our potential for compression.






== Case 2: 2 or Less Sequential Bytes Found <case2>

In the

