#import "@preview/mannot:0.3.1"
#import "@preview/wrap-it:0.1.1": wrap-content
#import "@preview/fletcher:0.5.8" as fletcher: cetz, diagram, edge, node

#set page(margin: (x: 18mm, y: 18mm), numbering: "1", paper: "a4")
#set math.equation(numbering: "(1)", supplement: "Eq.")
#set par(justify: true)
#set heading(numbering: "1.1")

#show link: set text(fill: rgb(0, 110, 210))

#show figure.caption: emph

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
+ The compressed data needs to be decompressable. An accompanying function that
  will decompress the data must exist.

== Goals

The first goal of this algorithm will be to compress the data by utilizing the
fact that it can be commonly expected that bytes will appear multiple times
sequentially. The main tactic will be to condense repeated sequential bytes
into an encoding of two bytes pairs where the first byte is the original value
and the second byte is the number of times in a row that byte was repeated.

The second goal will be that, even in the worse case scenario, this algorithm
will *not* increase the length of the data and at worst will result in a
compressed data length equal to the inputted data length ($mono("data_size")$)
when measured in bytes.


= Terms and Definitions

/ Sequential Byte: A _sequential byte_ is a set of bytes in a stream that
  appears twice or more in a row with the exact same value. An instance of a
  byte that appears twice or more in a row is called _sequential_.

/ Byte Multiplicity: When an instance of a byte is sequential, its
  _multiplicity_ is the _number of times_ that byte appears in a row. In the
  byte stream $(mono("0x64"), mono("0x4A"), mono("0x64"), mono("0x64"),
    mono("0x64"))$, the second instance of the byte $mono("0x64")$ has a
  _multiplicity_ of *3*. A byte that is _not sequential_ has a _multiplicity_
  of *1*.

/ Semi-Unique Byte Set: A set of bytes where order matters and each byte may
  appear more than once, but not more than once in a row.



= Algorithm

This algorithm will evaluate sequential bytes one at a time and encode them.


First, for all the bytes in the input buffer, the algorithm will group each
byte into a pair of values: The value of the byte itself, and the number of
times that byte appeared in a row --- its _multiplicity_. If the same byte
appears multiple times but is separated by one or more bytes of a different
value, then those same-bytes are treated as different _instances_ of that byte.

For example, consider the following input data buffer:
$
  (
    mono("0x03"),
    mono("0x74"),
    mono("0x1A"), mono("0x1A"),
    mono("0x64"), mono("0x64"), mono("0x64"), mono("0x64"),
    mono("0x00"), mono("0x00"), mono("0x00"), mono("0x00"), mono("0x00"),
    mono("0x1A")
  ).
$ <eq:stream_example_1>

This would become the array of 2-tuples:
$
  (
    (mono("0x03"), 1),
    (mono("0x74"), 1),
    (mono("0x1A"), 2),
    (mono("0x64"), 4),
    (mono("0x00"), 5),
    (mono("0x1A"), 1)
  ).
$ <eq:byte_multiplicity_example_1>

For each 2-tuple, the first value is the value of the data byte, and the second
value is its multiplicity.

#v(18pt)

#wrap-content(
  box(
    inset: (y: 0.1em),
    [
      #figure(
        rect(radius: 0.5em, inset: 3.4em, outset: 0em, stroke: 1pt, [
          #math.equation(
            $
              #let bit(val) = box(width: 9pt, height: 9pt, {
                place(center + bottom, dy: -0.4pt, if (val == none) [] else [$mono(#str(val))$])
                place(bottom + center, dy: 1pt, line(length: 5.5pt, stroke: (cap: "round", thickness: 0.9pt)))
              })
              mannot.markrect(
                #bit(1), tag: #<b0>,
                outset: #(x: -0.6pt, bottom: 3pt, top: 1.4pt),
                color: #(orange).darken(10%),
              )
              mannot.markrect(
                #bit(none)
                #bit(none)
                #bit(none)
                #bit(none)
                #bit(none)
                #bit(none)
                #bit(none),
                tag: #<data_bits>,
                outset: #(x: -0.6pt, bottom: 3pt, top: 1.4pt),
                color: #blue,
              )
              #mannot.annot(<b0>, dy: 2em, leader-connect: (bottom, top), annot-inset: 1pt)[
                #set align(center)
                Multiplicity \ Indicator
              ]
              #mannot.annot(<data_bits>, dy: -3em, dx: 2.6em, leader-connect: (top, left), annot-inset: 1pt)[Data Bits]
            $,
          )
          #v(2em)
        ]),
        caption: [Encoded Data Byte],
      )<eq:encoded_data_byte>
    ],
  ),
  [

    From here, the algorithm utilized the fact that the values for each data
    byte only range from $mono("0x00")$ to $mono("0x7F")$ and all have the same
    value for the top high-order-bit of their byte: "$mono("0")$".

    For each byte-instance in the array of 2-tuples, the encoding differs
    depending on whether the byte-instance has a multiplicity equal to 1, or a
    multiplicity equal to 2 or greater. In both cases, the 7 low-order bits of
    the data-byte are encoded into the matching 7 low-order bits of the
    encoded-data-byte. Now, if the multiplicity of the byte instance is equal
    to 1, then the _multiplicity indicator_ bit is set to "$mono("0")$" and the
    encoding is complete. Alternatively, if the multiplicity of the
    byte-instance is equal to 2 or greater, then the _multiplicity indicator_
    bit is set to "$mono("1")$" and the encoded-byte is written. In the
    _following_ byte, the value of the multiplicity for this byte-instance is
    written, where a value of $mono("0x00")$ encodes a multiplicity of 2, and
    $mono("0xFF")$ encodes a multiplicity of 257. Writing this
    value-multiplicity byte pair completes the encoding for this second case.

  ],
  align: top + right,
  column-gutter: 1.5em,
)

Since a value-multiplicity pair is only written when a given byte-instance has
a multiplicity greater than 1, the addition of the extra byte to encode the
multiplicity will never replace what was a single byte from the original data
with the pair of bytes, it will only ever replace sequences of the same byte
repeated twice or more with the pair. This insures that in the worst case
scenario --- where no byte in the input data is ever found more than twice in a
row --- the resulting compressed data buffer will not be of greater length than
the source data buffer. Thus, this satisfies our second goal.

= Example

Consider the following inputted array of bytes:

$
  ( quad & mono("0x03"), mono("0x74"), mono("0x04"), mono("0x04"), quad &
    & mono("0x04"), mono("0x35"), mono("0x35"), mono("0x64"), quad &
    & mono("0x64"), mono("0x64"), mono("0x64"), mono("0x00"), \
    & mono("0x00"), mono("0x00"), mono("0x00"), mono("0x00"), quad &
    & mono("0x56"), mono("0x45"), mono("0x56"), mono("0x56"), quad &
    & mono("0x56"), mono("0x09"), mono("0x09"), mono("0x09") & quad ).
$ <eq:main_example_stream>

This would become the array of value-multiplicity 2-tuples:
$
  ( quad & (mono("0x03"), 1),
           (mono("0x74"), 1),
           (mono("0x04"), 3),
           (mono("0x35"), 2),
           (mono("0x64"), 4), &        \
         & (mono("0x00"), 5),
           (mono("0x56"), 1),
           (mono("0x45"), 1),
           (mono("0x56"), 3),
           (mono("0x09"), 3)  & quad).
$ <eq:main_example_2_tuples>

By performing the compression algorithm, we get:
$
  ( quad & mono("0x03"), mono("0x03"),
           mono("0x74"), mono("0x74"),
           mono("0x04"), mono("0x04"),
           mono("0x35"), mono("0x35"),
           mono("0x64"), mono("0x64"), &        \
         & mono("0x00"), mono("0x00"),
           mono("0x56"), mono("0x56"),
           mono("0x45"), mono("0x45"),
           mono("0x56"), mono("0x56"),
           mono("0x09"), mono("0x09")  & quad).
$ <eq:main_example_2_tuples>


It can be pretty hard to read byte-by-byte and try to discern the changes. To
make it easier, here is a diagram that represents the process followed by the
algorithm for this example:

#align(center, figure(
  caption: [Algorithm Example],
  rect(radius: 10pt, stroke: 0.75pt, inset: 12pt, scale(94%, reflow: true, [
    #let value_color = blue.darken(15%)
    #let multi_color = red.darken(20%)
    #let gold = rgb("#D4AF37")

    #let bit(val, highlight: none) = box(width: 9pt, height: 9pt, {
      place(center + bottom, dy: -0.4pt, if (
        val == none
      ) [] else [$mono(#str(val))$])
      place(bottom + center, dy: 1pt, line(length: 5.5pt, stroke: (
        cap: "round",
        thickness: 0.9pt,
      )))
      if (highlight != none) {
        place(bottom + center, dy: 2.4pt, rect(
          stroke: highlight + 0.8pt,
          height: 100% + 2pt,
          width: 85%,
          radius: 1pt,
        ))
      }
    })

    #let byte_node(pos, byte, ..args) = node(
      pos,
      rect($mono("0x"#(if byte < 0x10 { 0 })#str(byte, base: 16))$),
      inset: 0pt,
      outset: 2pt,
      ..args,
    )

    #let bit_node(pos, byte, highlight_top_bit: none, ..args) = node(
      pos,
      rect(
        math.equation(
          for i in range(8) {
            bit(
              byte.bit-rshift(7 - i, logical: false).bit-and(1),
              highlight: if (
                i == 0
              ) { highlight_top_bit } else { none },
            )
          },
        ),
      ),
      inset: 0pt,
      outset: 2pt,
      ..args,
    )

    #let tuple_node(pos, byte, multiplicity, ..args) = node(
      pos,
      scale(
        140%,
        $vec(text(fill: #value_color, mono(byte)), text(fill: #multi_color, #str(multiplicity)))$,
        reflow: true,
      ),
      fill: none,
      ..args,
    )

    #let curvy_edge(start, end, bend: 10deg, ..args) = {
      edge(start, ((), 50%, end), "-", bend: -1 * bend, stroke: value_color)
      edge((start, 50%, end), end, "->", bend: bend, stroke: value_color)
    }

    #diagram(
      spacing: (2em, 0.5em),
      node-fill: white,

      byte_node((0, 00), 0x03, name: <byte00>),
      byte_node((0, 01), 0x74, name: <byte01>),
      byte_node((0, 02), 0x04, name: <byte02>),
      byte_node((0, 03), 0x04, name: <byte03>),
      byte_node((0, 04), 0x04, name: <byte04>),
      byte_node((0, 05), 0x35, name: <byte05>),
      byte_node((0, 06), 0x35, name: <byte06>),
      byte_node((0, 07), 0x64, name: <byte07>),
      byte_node((0, 08), 0x64, name: <byte08>),
      byte_node((0, 09), 0x64, name: <byte09>),
      byte_node((0, 10), 0x64, name: <byte10>),
      byte_node((0, 11), 0x00, name: <byte11>),
      byte_node((0, 12), 0x00, name: <byte12>),
      byte_node((0, 13), 0x00, name: <byte13>),
      byte_node((0, 14), 0x00, name: <byte14>),
      byte_node((0, 15), 0x00, name: <byte15>),
      byte_node((0, 16), 0x56, name: <byte16>),
      byte_node((0, 17), 0x45, name: <byte17>),
      byte_node((0, 18), 0x56, name: <byte18>),
      byte_node((0, 19), 0x56, name: <byte19>),
      byte_node((0, 20), 0x56, name: <byte20>),
      byte_node((0, 21), 0x09, name: <byte21>),
      byte_node((0, 22), 0x09, name: <byte22>),
      byte_node((0, 23), 0x09, name: <byte23>),


      // Input Bits.
      bit_node((1, 00), 0x03, name: <b00>),
      bit_node((1, 01), 0x74, name: <b01>),
      bit_node((1, 02), 0x04, name: <b02>),
      bit_node((1, 03), 0x04, name: <b03>),
      bit_node((1, 04), 0x04, name: <b04>),
      bit_node((1, 05), 0x35, name: <b05>),
      bit_node((1, 06), 0x35, name: <b06>),
      bit_node((1, 07), 0x64, name: <b07>),
      bit_node((1, 08), 0x64, name: <b08>),
      bit_node((1, 09), 0x64, name: <b09>),
      bit_node((1, 10), 0x64, name: <b10>),
      bit_node((1, 11), 0x00, name: <b11>),
      bit_node((1, 12), 0x00, name: <b12>),
      bit_node((1, 13), 0x00, name: <b13>),
      bit_node((1, 14), 0x00, name: <b14>),
      bit_node((1, 15), 0x00, name: <b15>),
      bit_node((1, 16), 0x56, name: <b16>),
      bit_node((1, 17), 0x45, name: <b17>),
      bit_node((1, 18), 0x56, name: <b18>),
      bit_node((1, 19), 0x56, name: <b19>),
      bit_node((1, 20), 0x56, name: <b20>),
      bit_node((1, 21), 0x09, name: <b21>),
      bit_node((1, 22), 0x09, name: <b22>),
      bit_node((1, 23), 0x09, name: <b23>),


      // Value-Multiplicity Pairs
      tuple_node((3, 0), "0x03", 1, name: <t0>),
      tuple_node((3, 1), "0x74", 1, name: <t1>),
      tuple_node((3, 3), "0x04", 3, name: <t2>),
      tuple_node((3, 5.5), "0x35", 2, name: <t3>),
      tuple_node((3, 8.5), "0x64", 4, name: <t4>),
      tuple_node((3, 13), "0x00", 5, name: <t5>),
      tuple_node((3, 15), "0x56", 1, name: <t6>),
      tuple_node((3, 17), "0x45", 1, name: <t7>),
      tuple_node((3, 19), "0x56", 3, name: <t8>),
      tuple_node((3, 22), "0x09", 3, name: <t9>),

      // Output Bits.
      bit_node((5, 00), 0x03, name: <cb0v>),
      // bit_node((6, 01), 0x01, name: <cb0m>),
      bit_node((5, 01), 0x74, name: <cb1v>),
      // bit_node((6, 03), 0x01, name: <cb1m>),
      bit_node(
        (5, 02),
        0x04 + 0x80,
        name: <cb2v>,
        highlight_top_bit: multi_color,
      ),
      bit_node((5, 03), 0x03, name: <cb2m>),
      bit_node(
        (5, 05),
        0x35 + 0x80,
        name: <cb3v>,
        highlight_top_bit: multi_color,
      ),
      bit_node((5, 06), 0x02, name: <cb3m>),
      bit_node(
        (5, 08),
        0x64 + 0x80,
        name: <cb4v>,
        highlight_top_bit: multi_color,
      ),
      bit_node((5, 09), 0x04, name: <cb4m>),
      bit_node(
        (5, 10),
        0x00 + 0x80,
        name: <cb5v>,
        highlight_top_bit: multi_color,
      ),
      bit_node((5, 11), 0x05, name: <cb5m>),
      bit_node((5, 12), 0x56, name: <cb6v>),
      // bit_node((6, 13), 0x01, name: <cb6m>),
      bit_node((5, 14), 0x45, name: <cb7v>),
      // bit_node((6, 15), 0x01, name: <cb7m>),
      bit_node(
        (5, 16),
        0x56 + 0x80,
        name: <cb8v>,
        highlight_top_bit: multi_color,
      ),
      bit_node((5, 17), 0x03, name: <cb8m>),
      bit_node(
        (5, 18),
        0x09 + 0x80,
        name: <cb9v>,
        highlight_top_bit: multi_color,
      ),
      bit_node((5, 19), 0x03, name: <cb9m>),

      // Output Bytes.
      byte_node((6, 00), 0x03, name: <c0v>),
      // byte_node((8, 01), 0x01, name: <c0m>),
      byte_node((6, 01), 0x74, name: <c1v>),
      // byte_node((8, 03), 0x01, name: <c1m>),
      byte_node((6, 02), 0x04 + 0x80, name: <c2v>),
      byte_node((6, 03), 0x03, name: <c2m>),
      byte_node((6, 04), 0x35 + 0x80, name: <c3v>),
      byte_node((6, 05), 0x02, name: <c3m>),
      byte_node((6, 06), 0x64 + 0x80, name: <c4v>),
      byte_node((6, 07), 0x04, name: <c4m>),
      byte_node((6, 08), 0x00 + 0x80, name: <c5v>),
      byte_node((6, 09), 0x05, name: <c5m>),
      byte_node((6, 10), 0x56, name: <c6v>),
      // byte_node((8, 13), 0x01, name: <c6m>),
      byte_node((6, 11), 0x45, name: <c7v>),
      // byte_node((8, 15), 0x01, name: <c7m>),
      byte_node((6, 12), 0x56 + 0x80, name: <c8v>),
      byte_node((6, 13), 0x03, name: <c8m>),
      byte_node((6, 14), 0x09 + 0x80, name: <c9v>),
      byte_node((6, 15), 0x03, name: <c9m>),


      // Groups.
      node((to: <byte00>, rel: (0, -3)), []),
      node(
        enclose: ((to: <byte00>, rel: (0, -3)), <byte23>),
        label: align(top + center, text(
          teal.darken(12%),
          size: 11pt,
        )[Input Bytes]),
        stroke: teal,
        fill: teal.lighten(90%),
      ),

      node((to: <t0>, rel: (0, -3)), []),
      node(
        enclose: ((to: <t0>, rel: (0, -3)), <t9>),
        label: align(top + center, text(
          purple.darken(12%),
          size: 11pt,
        )[2-Tuples]),
        stroke: purple,
        fill: purple.lighten(93%),
      ),

      node((to: <c0v>, rel: (0, -3)), []),
      node(
        enclose: ((to: <c0v>, rel: (0, -3)), <c9m>),
        label: align(top + center, text(
          gold.darken(12%),
          size: 11pt,
        )[Encoded Bytes]),
        stroke: gold,
        fill: gold.lighten(90%),
      ),

      // Edges.
      edge(<byte00>, <b00>, "->"),
      edge(<byte01>, <b01>, "->"),
      edge(<byte02>, <b02>, "->"),
      edge(<byte03>, <b03>, "->"),
      edge(<byte04>, <b04>, "->"),
      edge(<byte05>, <b05>, "->"),
      edge(<byte06>, <b06>, "->"),
      edge(<byte07>, <b07>, "->"),
      edge(<byte08>, <b08>, "->"),
      edge(<byte09>, <b09>, "->"),
      edge(<byte10>, <b10>, "->"),
      edge(<byte11>, <b11>, "->"),
      edge(<byte12>, <b12>, "->"),
      edge(<byte13>, <b13>, "->"),
      edge(<byte14>, <b14>, "->"),
      edge(<byte15>, <b15>, "->"),
      edge(<byte16>, <b16>, "->"),
      edge(<byte17>, <b17>, "->"),
      edge(<byte18>, <b18>, "->"),
      edge(<byte19>, <b19>, "->"),
      edge(<byte20>, <b20>, "->"),
      edge(<byte21>, <b21>, "->"),
      edge(<byte22>, <b22>, "->"),
      edge(<byte23>, <b23>, "->"),

      edge(<b00.east>, <t0>, "->"),
      edge(<b01.east>, <t1>, "->"),
      edge(<b02.east>, <t2>, "->"),
      edge(<b03.east>, <t2>, "->"),
      edge(<b04.east>, <t2>, "->"),
      edge(<b05.east>, <t3>, "->"),
      edge(<b06.east>, <t3>, "->"),
      edge(<b07.east>, <t4>, "->"),
      edge(<b08.east>, <t4>, "->"),
      edge(<b09.east>, <t4>, "->"),
      edge(<b10.east>, <t4>, "->"),
      edge(<b11.east>, <t5>, "->"),
      edge(<b12.east>, <t5>, "->"),
      edge(<b13.east>, <t5>, "->"),
      edge(<b14.east>, <t5>, "->"),
      edge(<b15.east>, <t5>, "->"),
      edge(<b16.east>, <t6>, "->"),
      edge(<b17.east>, <t7>, "->"),
      edge(<b18.east>, <t8>, "->"),
      edge(<b19.east>, <t8>, "->"),
      edge(<b20.east>, <t8>, "->"),
      edge(<b21.east>, <t9>, "->"),
      edge(<b22.east>, <t9>, "->"),
      edge(<b23.east>, <t9>, "->"),

      edge(<t0>, <cb0v.west>, "->", stroke: value_color),
      // edge(<t0>, <cb0m.west>, "->", stroke: multi_color),
      edge(<t1>, <cb1v.west>, "->", stroke: value_color),
      // edge(<t1>, <cb1m.west>, "->", stroke: multi_color),
      edge(<t2>, <cb2v.west>, "->", stroke: value_color),
      edge(<t2>, <cb2m.west>, "->", stroke: multi_color),
      edge(<t3>, <cb3v.west>, "->", stroke: value_color),
      edge(<t3>, <cb3m.west>, "->", stroke: multi_color),
      edge(<t4>, <cb4v.west>, "->", stroke: value_color),
      edge(<t4>, <cb4m.west>, "->", stroke: multi_color),
      edge(<t5>, <cb5v.west>, "->", stroke: value_color),
      edge(<t5>, <cb5m.west>, "->", stroke: multi_color),
      edge(<t6>, <cb6v.west>, "->", stroke: value_color),
      // edge(<t6>, <cb6m.west>, "->", stroke: multi_color),
      edge(<t7>, <cb7v.west>, "->", stroke: value_color),
      // edge(<t7>, <cb7m.west>, "->", stroke: multi_color),
      edge(<t8>, <cb8v.west>, "->", stroke: value_color),
      edge(<t8>, <cb8m.west>, "->", stroke: multi_color),
      edge(<t9>, <cb9v.west>, "->", stroke: value_color),
      edge(<t9>, <cb9m.west>, "->", stroke: multi_color),

      edge(<cb0v.east>, <c0v.west>, "->", stroke: value_color),
      // edge(<cb0m>, <c0m>, "->", stroke: multi_color),
      edge(<cb1v.east>, <c1v.west>, "->", stroke: value_color),
      // edge(<cb1m>, <c1m>, "->", stroke: multi_color),
      edge(<cb2v.east>, <c2v.west>, "->", stroke: value_color),
      edge(<cb2m.east>, <c2m.west>, "->", stroke: multi_color),
      edge(<cb3v.east>, <c3v.west>, "->", stroke: value_color),
      edge(<cb3m.east>, <c3m.west>, "->", stroke: multi_color),
      edge(<cb4v.east>, <c4v.west>, "->", stroke: value_color),
      edge(<cb4m.east>, <c4m.west>, "->", stroke: multi_color),
      edge(<cb5v.east>, <c5v.west>, "->", stroke: value_color),
      edge(<cb5m.east>, <c5m.west>, "->", stroke: multi_color),
      edge(<cb6v.east>, <c6v.west>, "->", stroke: value_color),
      // edge(<cb6m>, <c6m>, "->", stroke: multi_color),
      edge(<cb7v.east>, <c7v.west>, "->", stroke: value_color),
      // edge(<cb7m>, <c7m>, "->", stroke: multi_color),
      edge(<cb8v.east>, <c8v.west>, "->", stroke: value_color),
      edge(<cb8m.east>, <c8m.west>, "->", stroke: multi_color),
      edge(<cb9v.east>, <c9v.west>, "->", stroke: value_color),
      edge(<cb9m.east>, <c9m.west>, "->", stroke: value_color),
    )
  ])),
))

