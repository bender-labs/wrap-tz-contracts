#if !MINTER_TYPE
#define MINTER_TYPE

type bps = nat

type metadata = (string, bytes) big_map

type token_address = address * nat

#endif