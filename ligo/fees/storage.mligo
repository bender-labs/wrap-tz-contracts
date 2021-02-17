#if !FEES_CONTRACT_STORAGE
#define FEES_CONTRACT_STORAGE

type minter_storage = {
    contract: address;
    listed_tokens: address set;
}

type quorum_storage = {
    contract: address;
    signers: (key_hash, address) map;
}

type ledger_storage = {
    to_distribute: balance_sheet;
    distribution: (address, balance_sheet) big_map;
}

type governance_storage = {
    contract: address;
    dev_pool: address;
    staking: address;
    dev_fees: nat;
    staking_fees: nat;
    signers_fees: nat;
}

type storage = {
    quorum: quorum_storage;
    ledger: ledger_storage;
    governance: governance_storage;
    minter: minter_storage;
}

type contract_return = operation list * storage

#endif