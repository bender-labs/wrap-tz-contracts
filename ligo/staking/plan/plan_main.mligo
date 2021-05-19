#include "../storage.mligo"
#include "../common/errors.mligo"
#include "../reserve/reserve_api.mligo"

type update_plan = nat

let get_reserve_contract (addr:address): claim_fees contract = 
    match (Tezos.get_entrypoint_opt "%claim_fees" addr : claim_fees contract option) with
    | Some v -> v
    | None -> failwith "not_reserve_contract"

let update_plan(amnt, s: nat * storage): storage = 
    if Tezos.level < s.reward.period_end then
        (failwith distribution_running : storage)
    else
        let reward = {s.reward with 
            last_block_update = Tezos.level;
            period_end = s.settings.duration + Tezos.level;
            reward_per_block = amnt / s.settings.duration}
            in
        {s with reward = reward}

let claim_fees_operation (amnt, s: nat * storage): operation =
    let reserve = get_reserve_contract(s.settings.reserve_contract) in
    let (token_contract, token_id) = s.settings.reward_token in
    Tezos.transaction {amount=amnt ; token_contract=token_contract ; token_id=token_id} 0tez reserve


let claim_fees (amnt, s : nat * storage): contract_return =
    let s = update_plan(amnt, s) in
    let op = claim_fees_operation(amnt, s) in
    [op], s

let plan_main (p, s: update_plan * storage) : contract_return =
    claim_fees(p, s)