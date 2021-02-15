#if !FEES_CONTRACT_STORAGE
#define FEES_CONTRACT_STORAGE

type minter_storage = {
    contract: address;
    tokens: address set;
}

type quorum_storage = {
    contract: address;
    signers: (key_hash, address) map;
    ledger: (address, balance_sheet) map;
    pending_signers: (key_hash, balance_sheet) map;
    cash: balance_sheet;
}

type governance_storage = {
    contract: address;
    dev_pool: address;
    staking: address;
    dev_fees: nat;
    wrap_fees: nat;
    signers_fees: nat;
}

type storage = {
    quorum: quorum_storage;
    governance: governance_storage;
    minter: minter_storage;
}

#endif