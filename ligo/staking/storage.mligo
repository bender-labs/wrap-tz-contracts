#if !STORAGE
#define STORAGE

type token = (address * nat)

type delegator = {
    unpaid: nat;
    reward_per_token_paid: nat;
}

type ledger = {
    total_supply: nat;
    balances : (address, nat) big_map
}

type settings = {
    reward_token: token;
    staked_token: token;
    duration: nat;
    reserve_contract: address;
}

type reward = {
    last_block_update: nat;
    period_end: nat;
    accumulated_reward_per_token: nat;
    reward_per_block: nat;
}

type admin = {
    address: address;
    pending_admin: address option;
}

type storage = {
    ledger : ledger;
    delegators: (address, delegator) big_map;
    settings: settings;
    reward: reward;
    admin: admin;
    metadata:(string, bytes) big_map;
}

type contract_return = (operation list) * storage

#endif