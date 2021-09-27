#if !WALLET_LIB
#define WALLET_LIB

#include "../storage.mligo"
#include "../fa2/fa2_lib.mligo"
#include "../common/utils.mligo"
#include "../common/errors.mligo"
#include "../pool/update_pool.mligo"
#include "../common/constants.mligo"


let get_delegator(addr, delegators: address * delegators): delegator =
    match Map.find_opt addr delegators with
    | Some d -> d
    | None -> {unpaid = 0n; reward_per_token_paid = 0n; counter = 0n; balance = 0n; stakes = (Map.empty: (nat, stake) map) }

let get_balance (addr, balances: address * delegators): nat = 
    let delegator = get_delegator(addr, balances) in
    delegator.balance

let earned (delegator, reward:  delegator * reward): nat =
    let r = delegator.balance * sub(reward.accumulated_reward_per_token, delegator.reward_per_token_paid) in
    delegator.unpaid + r

let update_earned(delegator, s : delegator * storage):delegator = 
    let unpaid = earned(delegator, s.reward) in
    {delegator with unpaid = unpaid; reward_per_token_paid = s.reward.accumulated_reward_per_token}

let update_delegator_and_pool(s: storage):(delegator * storage) = 
    let s = update_pool(s) in
    let delegator = get_delegator(Tezos.sender, s.ledger.delegators) in
    let delegator = update_earned(delegator, s) in
    delegator, s

let fees_level(level, fees: nat * fees): nat =
    let cycles = (sub(Tezos.level, level) / fees.blocks_per_cycle) + 1n in
    match Map.find_opt cycles fees.fees_per_cycles with
    | Some v -> v
    | None -> fees.default_fees
        

let withdrawal_fees (level, amnt, fees: nat * nat * fees): nat * nat =
    let fee = fees_level(level, fees) in
    let to_burn = 
        if fee = 0n then 0n
        else amnt / fee
        in
    sub(amnt, to_burn), to_burn 

#endif