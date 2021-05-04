#if !STORAGE
#define STORAGE

type token = (address * nat)

type ledger = {
    total_supply: nat;
    balances : (address, nat) big_map
}

type settings = {
    reward_token: token;
    period: nat;
}

type storage = {
    ledger : ledger;
    settings: settings;
}

type contract_return = (operation list) * storage

#endif