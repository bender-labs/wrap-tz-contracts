#include "../storage.mligo"
#include "../common/errors.mligo"
#include "../reserve/reserve_api.mligo"
#include "../pool/update_pool.mligo"

type update_plan = nat

type plan_entrypoints = 
| Update_plan of update_plan
| Change_duration of nat

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
    let s = update_pool(s) in
    let s = update_plan(amnt, s) in
    let op = claim_fees_operation(amnt, s) in
    [op], s

let check_amount (a,e:nat * string):nat = 
    if a = 0n 
    then (failwith e:nat)
    else a

let plan_main (p, s: plan_entrypoints * storage) : contract_return =
    match p with
    | Update_plan a -> 
        let a = check_amount(a, bad_amount) in
        claim_fees(a, s)
    | Change_duration d ->
        let d = check_amount(d, bad_duration) in
        ([]:operation list), {s with settings = {s.settings with duration = d}}