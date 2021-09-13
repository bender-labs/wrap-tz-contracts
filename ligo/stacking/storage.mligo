#if !STORAGE
#define STORAGE

type token = (address * nat)

type stake = {
    amount: nat;
    level: nat;
}

type delegator = {
    unpaid: nat;
    reward_per_token_paid: nat;
    counter:nat;
    balance: nat;
    stakes: (nat, stake) map;
}

type delegators = (address, delegator) big_map

type ledger = {
    delegators: delegators;
    total_supply: nat;
}

type settings = {
    staked_token: token;
    reward_token: token;
    reserve_contract: address;
    duration: nat;
}

type reward = {
    last_block_update: nat;
    period_end: nat;
    accumulated_reward_per_token: nat;
    reward_per_block: nat;
    reward_remainder: nat;
    exponent: nat;
}

type fees = {
    blocks_per_cycle: nat;
    default_fees: nat;
    burn_address: address;
    fees_per_cycles: (nat, nat) map;
}

type admin = {
    address: address;
    pending_admin: address option;
}

type storage = {
    ledger: ledger;
    fees: fees;
    settings: settings;
    reward: reward;
    admin: admin;
    metadata:(string, bytes) big_map;
}

type contract_return = (operation list) * storage

#endif