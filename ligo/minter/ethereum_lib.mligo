#if !ETHEREUM
#define ETHEREUM

type eth_address = bytes

type eth_event_id = {
    block_hash : bytes;
    log_index : nat;
}

#endif