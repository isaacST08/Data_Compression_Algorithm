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

== Goals

The first goal of this algorithm will be to compress the data by utilizing the
fact that it can be commonly expected that bytes will appear multiple times
sequentially. The main tactic will be to condense repeated sequential bytes
into an encoding of two bytes where the first byte is the original value and
the second byte is the number of times in a row that byte was repeated.

The second goal will be that, even in the worse case scenario, this algorithm
will *not* increase the length of the data and at worst will result in a
compressed data length equal to the inputted data length ($mono("data_size")$)
when measured in bytes.


= Terms and Definitions

/ Sequential Byte: A _sequential byte_ is a set of bytes in a stream that
  appears twice or more in a row with the exact same value. An instance of a
  byte that appears twice or more in a row is called _sequential_.

/ Byte Multiplicity: When an instance of a byte is sequential, its _multiplicity_
  is the _number of times_ that byte appears in a row. In the byte stream
  $(mono("0x64"), mono("0x4A"), mono("0x64"), mono("0x64"), mono("0x64"))$,
  the second instance of the byte $mono("0x64")$ has a _multiplicity_ of *3*.
  A byte that is _not sequential_ has a _multiplicity_ of *1*.

/ Semi-Unique Byte Set: A set of bytes where order matters and each byte may
  appear more than once, but not more than once in a row.



= Algorithm

This algorithm will compare chunks of 7 _semi-unique_ bytes at a time, starting
from the $0^"th"$ byte of the byte array. First, the initial byte is recorded,
the algorithm then scans each subsequent byte until a byte of a different value
is found. At that point, the quantity of the first byte, and it's value, are
recorded as the _first_ of the _7 byte chunk_, and then the algorithm continues
for the next byte (the one that ended the sequential streak of the first byte).
The process is repeated until 7, semi-unique, bytes are found. If the algorithm
comes across a byte that is already present as a previous value in the _7 byte
chunk_, then it treats it _no differently_ than if it was completely new. The
algorithm only cares about separating and condensing the sequential streams of
bytes (bytes that all have the same value and appear in a row). It does not
care if the _7 byte chunk_ consists of only two different bytes, alternating
back and forth.

If the input data buffer does not have enough bytes to fill the _7-byte-chunk_,
then any remaining slots are filled with entries containing a data value of "$mono("0xFF")$"
and a multiplicity value of 0. This combo of impossible values depicts that
the end of the data has been reached.

Now that the _7 byte chunk_ has been filled, the algorithm will handle two
cases differently:
#enum(
  numbering: "1)",
  indent: 10pt,
  [When their exists at least one sequential byte that appears with a multiplicity of 3 or more, *or* the 7-byte-chunk
    has trailing values with multiplicity 0.],
  [Otherwise.],
)

In both cases, a header byte will be used to facilitate the decoding process.
#link(<case1>)[Case 1] will use a full header byte while #link(<case2>)[case 2]
will use a partial header byte (details explained below). Despite their
differences, the two cases use a single high order bit to declare to the
decoder which type of compression was used for the following block of bytes. A
high order bit of value "$mono("0")$" indicates that the sub-algorithm defined
in case 1 is used, while a high order bit of value "$mono("1")$" indicates that
the sub-algorithm defined in case 2 is used.

The two cased are defined as follows:

== Case 1: Sub-Algorithm 1<case1>

This case occurs when at least one of the bytes in the _7 byte chunk_ occurred
*three times or more* _sequentially_ #underline[*or*] the number of bytes
remaining in the input buffer is not enough to fill the _7-byte-chunk_ (i.e.
EOF).

For example, consider the following streams:
$
  (mono("0x04"), mono("0x11"), mono("0x11"), mono("0x11"), ...),
$ <eq:stream_example_1>
$
  (mono("0x04"), mono("0x11"), mono("0x04"), mono("0x51"), ...),
$ <eq:stream_example_2>
$
  (mono("0x04"), mono("0x11"), mono("0x04"), mono("0x51")),
$ <eq:stream_example_3>
and
$
  (mono("0x6C"), mono("0x39"), mono("0x6C"), mono("0x6C"), mono("0x44"), ...).
$ <eq:stream_example_4>

The first stream (@eq:stream_example_1) would include the byte $mono("0x11")$
with a multiplicity of *3* as the second byte type of its 7-byte-chunk. This
stream would qualify to use the sub-algorithm of this case.

The second stream (@eq:stream_example_2) would include the byte $mono("0x04")$
with a multiplicity of *1* as the first byte type of its 7-byte-chunk, and
would include the (same) byte $mono("0x04")$ with a multiplicity of *1* as the
third byte type of its 7-byte-chunk. This stream would *not* qualify (without
knowing the hidden bytes) for this conditional case (see #link(<case2>)[case 2]
where it would qualify).

The third stream (@eq:stream_example_3) (which is the same as the second
stream, but with more information) would not have enough bytes to fill the
_7-byte-chunk_ and would thus qualify for this case.

The fourth stream (@eq:stream_example_4) would include the byte $mono("0x6C")$
with a quantity of *1* as the first byte type of its 7-byte-chunk, the byte
$mono("0x39")$ with a quantity of *1* as the second byte type, and the byte
$mono("0x6C")$ with a quantity of *2* as the third byte type of its
7-byte-chunk. Note how the bytes $mono("0x6C")$ are *not* aggregated into one.
This stream would *not* qualify for this conditional case (see
#link(<case2>)[case 2] where it would qualify).

#v(12pt)

=== Header Byte

This case uses a header byte to provide information about the following set of
bytes. This header byte is a full header byte, meaning that all the bits of the
header are used to convey information other than the data. This header byte has
the following encoding:

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
  #mannot.annot(<b1>, dy: -0.4pt)[#text(size: 6.1pt, [$0$])]
  #mannot.annot(<b2>, dy: -0.4pt)[#text(size: 6.1pt, [$1$])]
  #mannot.annot(<b3>, dy: -0.4pt)[#text(size: 6.1pt, [$2$])]
  #mannot.annot(<b4>, dy: -0.4pt)[#text(size: 6.1pt, [$3$])]
  #mannot.annot(<b5>, dy: -0.4pt)[#text(size: 6.1pt, [$4$])]
  #mannot.annot(<b6>, dy: -0.4pt)[#text(size: 6.1pt, [$5$])]
  #mannot.annot(<b7>, dy: -0.4pt)[#text(size: 6.1pt, [$6$])]
$ <eq:case1:headerbyte>
#v(2em)

The _*Compression Type Bit*_ indicates that the following set of bytes is
encoded using the case-1 sub-algorithm.

Each bit of the _*Repeated Byte Indicators*_ encode whether the byte at that
positional index is a sequential byte or not.

If the bit at position 0 (on @eq:case1:headerbyte) is set to "$mono("0")$",
then the byte is an individual byte and does not have any multiplicity
($M_"ultiplicity"<= 1$). Otherwise, if the bit is set to "$mono("1")$", then
this indicates that the byte _does_ have multiplicity ($M_"ultiplicity">= 2$)
and the pair of bytes at that relative index should be considered: The first
byte of the pair is the data value of the byte. The second byte of the pair is
the number of times this byte appears sequentially in the original data. This
repeats for all the other indices of _repeated byte indicators_. This is
repeated for every index of the _7-byte-chunk_.

=== Encoding

Data bytes are encoded depending on their multiplicity as well as if there are
more bytes to follow.

For each byte instance from the _7-byte-chunk_, if the byte has a multiplicity
of 2 or greater, then the bit at its index inside the header byte
(@eq:case1:headerbyte) is set to "$mono("1")$" and is encoded as a pair of
bytes where the first byte is the data value and the second byte is its
multiplicity minus 2 (since this is the minimum value for this pair format). If
the byte instance instead has a multiplicity exactly 1, then the bit at its
index inside the header byte (@eq:case1:headerbyte) is set to "$mono("0")$" and
is encoded as a solo byte representing just the data value. If the byte
instance has a multiplicity of 0 (i.e. it does not exist and indicates the end
of the source data buffer) then it is excluded and not encoded into the output
buffer.

Since the input data values only range from $mono("0x00")$ to $mono("0x7F")$,
this means that the top high order bit is always set to "$mono("0")$" for every
encoded data byte. Since this bit can is not important to the actual data
value, we instead will use it to indicate whether there is another data byte to
follow (whether it's a pair or solo), or if the end of the buffer has been
reached. If there is a data byte to follow the current data byte, then this top
bit is set to "$mono("1")$", if there is not a byte to follow, then this top
bit is set to "$mono("0")$". If the current data byte (pair or solo) is the
7#super([th]) and final data byte, then this top high order bit is ignored.

Note: There will never be a case where a 7-byte-chunk consists of all void
bytes, thus we do not need to worry about the first byte not existing (i.e.
each byte set will always include at least one data byte).




=== Encoding Example

As an example, the stream
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
$ <eq:stream_example_5>
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
    ( mono("0x56"), 1 )
  ).
$<eq:7_byte_chunk_1>
When encoded back into a byte array, using this algorithm, we would get:
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
that the _multiplicity bytes_ do not match the values found in the corresponding
7-byte-chunk (@eq:7_byte_chunk_1). In fact, they are all a value of 2 lower
than what might have been expected. This is because in the header byte, we
already indicate when a pair of bytes will be present, and this only occurs
when the byte value has a multiplicity of at least 2. Thus, we can set the
multiplicity byte to start counting at 2 (represented by the value 0) so that
we can store a byte with a multiplicity of up to 257 instead of only up to a
multiplicity of 255; slightly increasing our potential for compression.

=== Worst Case Scenario

For this case of the algorithm to run, the _7-byte-chunk_ must at least have
one sequential byte with a multiplicity of 3. In the worst case scenario, there
is one singular byte with a multiplicity of 3, and all other bytes have a
multiplicity of 1 or 2.

The first byte outputted is the header info byte, this increases the output
buffer length by 1.

For all the bytes of multiplicity 1, they are not encoded, and their byte is
simply re-added to the stream at their appropriate index. Thus, for each of
these bytes, the length of the output remains the same.

For all the bytes of multiplicity 2, they first output the byte of their own
value, then followed by the byte encoding the quantity of bytes condensed.
Since two bytes were encoded back into two bytes, the length of the output
remains the same.

For the singular byte of multiplicity 3, this byte is encoded just the same as
was done for bytes of multiplicity 2, except the quantity byte has a value of
\3. Thus, we encoded 3 bytes from the input down to 2 bytes in the output,
resulting in an output buffer length decrease of 1.

The decrease of 1 byte from the singular multiplicity 3 byte counteracts the
increase of 1 byte from the header info byte, resulting in a final output
buffer length equal to that of the input buffer length.

Thus, even in the worse case scenario, this component of the algorithm does not
produce a compressed data buffer with a length greater than the uncompressed
data buffer.





== Case 2: 2 or Less Sequential Bytes Found<case2>

This case occurs when all the bytes in the _7-byte-chunk_ are of multiplicity
1 or 2.

Since there are no sequential bytes from the 7-byte-chunk that can be
compressed by encoding their multiplicity, this sub-algorithm uses the fact
that every data byte of the source data has values from
$mono("0x00")$ to only $mono("0x7F")$ to _condense_ the data by removing the unused
high-order-bit from every data byte. This sub-algorithm becomes more efficient
when it can condense more bytes at once so it can aggregate all the "saved"
high-order-bits together into the saving of an entire byte. To do this, after
meeting the condition for using this sub-algorithm from the contents of the
_7-byte-chunk_, it will look for additional bytes _past_ those in the
7-byte-chunk to determine if there are more
bytes with a multiplicity of less than three that can be encoded into this
byte set with the desired result of saving an entire byte. Since there are
only certain multiples of bytes that result in saving whole bytes, the number
of bytes additionally collected into this encoding are specifically chosen
and are outlined #link(<tbl:extension_codes>)[below].


=== Header Byte

Like case 1, this case also uses a header byte to provide information about the
following set of bytes. This header byte is a _partial_ header byte, meaning
that a portion of the bits are used to encode information, and the rest are
used to store data.

This header byte is encoded as follows:
#v(1.5em)
$
  #let bit(val) = box(width: 8pt, height: 9pt, {
    place(center + bottom, dy: -0.4pt, if (val == none) [] else [$mono(#str(val))$])
    place(bottom + center, dy: 1pt, line(length: 5.5pt, stroke: (cap: "round", thickness: 0.9pt)))
  })
  mannot.mark(#bit(1), tag: #<b0>, outset: #2pt)
  overbrace(
    mannot.mark(#bit(none), tag: #<b1>, outset: #2pt)
    mannot.mark(#bit(none), tag: #<b2>, outset: #2pt),
    #place(center + bottom, text([Extension \ Code]))
  )
  mannot.markrect(
    mannot.mark(#bit(none), tag: #<b3>, outset: #2pt)
    mannot.mark(#bit(none), tag: #<b4>, outset: #2pt)
    mannot.mark(#bit(none), tag: #<b5>, outset: #2pt)
    mannot.mark(#bit(none), tag: #<b6>, outset: #2pt)
    mannot.mark(#bit(none), tag: #<b7>, outset: #2pt),
    tag: #<data_bits>,
    outset: #(x: 0pt, bottom: 3pt, top: 1.4pt),
    color: #blue,
  )
  #mannot.annot(<b0>, dy: 1em, dx: -4.3em, leader-connect: (bottom, right), annot-inset: 1pt)[Compression Type Bit]
  #mannot.annot(<b1>, dy: -0.4pt)[#text(size: 6.1pt, [$0$])]
  #mannot.annot(<b2>, dy: -0.4pt)[#text(size: 6.1pt, [$1$])]
  #mannot.annot(<data_bits>, dy: -3em, dx: 2.6em, leader-connect: (top, left), annot-inset: 1pt)[Data Bits]
  // #mannot.annot(<b3>, dy: -0.4pt)[#text(size: 6.1pt, [$3$])]
  // #mannot.annot(<b4>, dy: -0.4pt)[#text(size: 6.1pt, [$4$])]
  // #mannot.annot(<b5>, dy: -0.4pt)[#text(size: 6.1pt, [$5$])]
  // #mannot.annot(<b6>, dy: -0.4pt)[#text(size: 6.1pt, [$6$])]
  // #mannot.annot(<b7>, dy: -0.4pt)[#text(size: 6.1pt, [$7$])]
$ <eq:case2:headerbyte>
#v(2em)

The _*Compression Type Bit*_ indicates that the following set of bytes is
encoded using the _case-2 sub-algorithm_.

The _*Extension Code*_ is the encoding that indicates how many _extra_ bytes
will be included in this byte set. Since only certain quantities of input bytes
accumulate to result in saving a whole byte, these encodings map to specific
values (#link(<tbl:extension_codes>)[see below]).

The _*Data Bits*_ are the initial bits of the compressed bytes from the
original data. That is, the high order bits of the first byte of the
7-byte-chunk, excluding the first bit that is uniformly "$mono("0")$" among all
the source data bytes.

// #v(12pt)


==== Extension Codes<tbl:extension_codes>
#align(center, {
  set par(justify: false)
  box(
    width: 90%,
    table(
      columns: (3.7em, 3.7em, 3.9em, 4.6em, 5.0em, auto),
      align: center + horizon,
      fill: (x, y) => if (y < 2) { rgb("#BBDDD1").lighten(5%) },

      table.header(
        level: 1,
        table.cell([Extension Code], colspan: 2),
        table.cell([\# Input Bytes], rowspan: 2),
        table.cell([\# Output Bytes], rowspan: 2),
        table.cell([Trailing Spare Bits], rowspan: 2),
        table.cell([Explanation], rowspan: 2),
        [Bit 0],
        [Bit 1],
      ),

      [$mono("0")$],
      [$mono("0")$],
      [7],
      [7],
      [4],
      [
        This is the default encoding. This is the encoding that insures that
        this algorithm does not increase the number of bytes in the resulting
        output buffer compared to the length of the input buffer.
      ],

      [$mono("0")$],
      [$mono("1")$],
      [11],
      [10],
      [0],
      [
        This is the number of input bytes required to save *1* whole byte in the
        output.
      ],

      [$mono("1")$],
      [$mono("0")$],
      [18],
      [16],
      [0],
      [
        This is the number of input bytes required to save *2* whole bytes in the
        output.
      ],

      [$mono("1")$],
      [$mono("1")$],
      [25],
      [22],
      [0],
      [
        This is the number of input bytes required to save *3* whole bytes in the
        output.
      ],
    ),
  )
})


=== Encoding Example

==== Example 1

Consider the input byte array of
$
   ( quad & \
          & mono("0x03"), mono("0x74"), mono("0x04"), mono("0x1A"), \
          & mono("0x1A"), mono("0x35"), mono("0x64"), mono("0x00"), \
  ). quad &
$ <eq:stream_example_6>

From this, the first _7-byte-chunk_ of 2-tuples (_value_, _multiplicity_) would be
constructed as:
$
  (
    ( mono("0x03"), 1 ),
    ( mono("0x74"), 1 ),
    ( mono("0x04"), 1 ),
    ( mono("0x1A"), 2 ),
    ( mono("0x35"), 1 ),
    ( mono("0x64"), 1 ),
    ( mono("0x00"), 5 ),
    ( mono("0x56"), 1 )
  ).
$<eq:7_byte_chunk_2>

Since no byte instance of the _7-byte-chunk_ (@eq:7_byte_chunk_2) has a
multiplicity of 3 or greater, this byte set qualifies for this case.

==== Example 2


$
   ( quad & \
          & mono("0x03"), mono("0x74"), mono("0x04"), mono("0x1A"), \
          & mono("0x1A"), mono("0x35"), mono("0x64"), mono("0x00"), \
          & mono("0x35"), mono("0x35"), mono("0x56"), mono("0x0C"), \
          & mono("0x1B"), mono("0x1B"), mono("0x1B"), mono("0x0C"), \
          & mono("0x1B") \
  ). quad &
$ <eq:stream_example_7>






