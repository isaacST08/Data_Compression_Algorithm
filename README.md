# Algorithm Version 1

This is the first version of a data compression algorithm. During its
development I thought of a different algorithm that will be simpler but will
probably have less potential for compression density. However, this algorithm
(v1) will have limitations on how many bytes can be compressed at a time,
specifically, when certain quantities of bytes are compressed (especially if the
number is bellow 7), then it could result in compressed data taking up more
bytes than the uncompressed data. If the number of bytes to be compressed is
assumed to be high then this could be noted as one of the assumptions and could
be accounted for but as it stands I would like to diverge and explore the more
simple algorithm instead.

The new algorithm can be found under the `algorithm_v2` branch.
