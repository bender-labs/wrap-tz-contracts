#if !FEES_COMMON
#define FEES_COMMON

type token_address = address * nat

type balance_sheet = {
    xtz: tez;
    tokens: (token_address, nat) map;
}

#endif