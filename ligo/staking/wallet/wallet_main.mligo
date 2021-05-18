#include "../storage.mligo"
#include "../fa2/fa2_lib.mligo"
#include "../common/utils.mligo"
#include "../common/errors.mligo"
#include "../pool/update_pool.mligo"

type wallet_entrypoints = 
| Stake of nat
| Withdraw of nat
| Claim


let get_balance (addr, balances: address * (address, nat) big_map): nat = 
    match Map.find_opt addr balances with 
    | Some v -> v
    | None -> 0n

let get_delegator(addr, delegators: address * (address, delegator) big_map): delegator =
    match Map.find_opt addr delegators with
    | Some d -> d
    | None -> {unpaid = 0n; reward_per_token_paid = 0n}

let earned (current_balance, delegator, reward: nat * delegator * reward): nat =
    delegator.unpaid + current_balance * sub(reward.accumulated_reward_per_token, delegator.reward_per_token_paid) / scale


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

let increase_balance (current, amnt, ledger: nat * nat * ledger) : ledger = 
    let balances = Map.update Tezos.sender (Some (current + amnt)) ledger.balances in
    {ledger with total_supply = ledger.total_supply + amnt ; balances = balances}

let stake(amnt, s : nat * storage): (operation list) * storage = 
    let amnt = check_amnt(amnt) in
    let (current_balance, s) = update_delegator_and_pool(s) in
    let ledger = increase_balance(current_balance, amnt, s.ledger) in
    let op = transfer_one (Tezos.sender, Tezos.self_address, s.settings.staked_token, amnt) in
    [op], {s with ledger = ledger}

let decrease_balance (current, amnt, ledger: nat * nat * ledger) : ledger = 
    let balances = Map.update Tezos.sender (Some (sub(current, amnt))) ledger.balances in
    {ledger with total_supply = sub(ledger.total_supply, amnt) ; balances = balances}

let withdraw(amnt, s : nat * storage) : (operation list) * storage = 
    let amnt = check_amnt amnt in
    let (current_balance, s) = update_delegator_and_pool(s) in
    let ledger = decrease_balance(current_balance, amnt, s.ledger) in
    let op = transfer_one (Tezos.self_address, Tezos.sender, s.settings.staked_token, amnt) in
    [op], {s with ledger = ledger }

let claim(s: storage): contract_return = 
    let s = update_pool(s) in
    let current_balance = get_balance(Tezos.sender, s.ledger.balances) in
    let delegator = get_delegator(Tezos.sender, s.delegators) in
    let reward = earned(current_balance, delegator, s.reward) in
    let delegators = Map.update Tezos.sender (Some {delegator with unpaid = 0n ; reward_per_token_paid = s.reward.accumulated_reward_per_token}) s.delegators in
    let op  = transfer_one(s.settings.reserve_contract, Tezos.sender, s.settings.reward_token, reward) in
    [op], {s with delegators = delegators }

let wallet_main ((p, s): (wallet_entrypoints * storage)): contract_return = 
    match p with
    | Stake a ->  stake(a, s) 
    | Withdraw a -> withdraw(a, s)
    | Claim -> claim(s)