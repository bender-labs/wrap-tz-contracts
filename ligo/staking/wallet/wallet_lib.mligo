#if !WALLET_LIB
#define WALLET_LIB

#include "../storage.mligo"
#include "../fa2/fa2_lib.mligo"
#include "../common/utils.mligo"
#include "../common/errors.mligo"
#include "../pool/update_pool.mligo"
#include "../common/constants.mligo"


let get_balance (addr, balances: address * (address, nat) big_map): nat = 
    match Map.find_opt addr balances with 
    | Some v -> v
    | None -> 0n

let get_delegator(addr, delegators: address * (address, delegator) big_map): delegator =
    match Map.find_opt addr delegators with
    | Some d -> d
    | None -> {unpaid = 0n; reward_per_token_paid = 0n}

let earned (current_balance, delegator, reward: nat * delegator * reward): nat =
    let r = current_balance * sub(reward.accumulated_reward_per_token, delegator.reward_per_token_paid) in
    delegator.unpaid + r // scale(r, target_exponent, reward.exponent)

let update_earned(current_balance, s : nat * storage):storage = 
    let delegator = get_delegator(Tezos.sender, s.delegators) in
    let unpaid = earned(current_balance, delegator, s.reward) in
    let delegators = 
        Map.update 
            Tezos.sender 
            (Some {delegator with unpaid = unpaid; reward_per_token_paid = s.reward.accumulated_reward_per_token}) 
            s.delegators in
    {s with delegators = delegators}

let update_delegator_and_pool(s: storage):(nat * storage) = 
    let s = update_pool(s) in
    let current_balance = get_balance(Tezos.sender, s.ledger.balances) in
    let s = update_earned(current_balance, s) in
    current_balance, s

#endif