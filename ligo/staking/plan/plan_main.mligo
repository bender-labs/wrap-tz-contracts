#include "../storage.mligo"
#include "../common/errors.mligo"
#include "../reserve/reserve_api.mligo"
#include "../pool/update_pool.mligo"
#include "../common/constants.mligo"
#include "../common/utils.mligo"

type update_plan = nat

type plan_entrypoints = 
| Update_plan of update_plan
| Change_duration of nat

let get_reserve_contract_claim_fees_ep (addr:address): claim_fees_param contract = 
    match (Tezos.get_entrypoint_opt "%claim_fees" addr : claim_fees_param contract option) with
    | Some v -> v
    | None -> failwith "not_reserve_contract"


let new_plan (amnt, s: nat * storage): nat * nat = 
    let amnt = scale(amnt, s.reward.exponent, target_exponent)  + s.reward.reward_remainder in
    match ediv amnt s.settings.duration with
    | Some (q, r) -> q, r
    | None -> (failwith "Bad amount": nat * nat)


let update_plan(amnt, s: nat * storage): storage = 
    if Tezos.level < s.reward.period_end then
        (failwith distribution_running : storage)
    else
        let (reward_per_block, r) = new_plan(amnt, s) in
        let reward = {s.reward with 
            last_block_update = Tezos.level;
            period_end = s.settings.duration + Tezos.level;
            reward_per_block = reward_per_block;
            reward_remainder = r
            }
            in
        {s with reward = reward}

let claim_fees_operation (amnt, s: nat * storage): operation =
    let reserve = get_reserve_contract_claim_fees_ep(s.settings.reserve_contract) in
    Tezos.transaction amnt 0tez reserve


let update_plan (amnt, s : nat * storage): contract_return =
    let s = update_pool(s) in
    let s = update_plan(amnt, s) in
    let op = claim_fees_operation(amnt, s) in
    [op], s

let plan_main (p, s: plan_entrypoints * storage) : contract_return =
    match p with
    | Update_plan a -> 
        let a = check_amount(a, bad_amount) in
        update_plan(a, s)
    | Change_duration d ->
        let d = check_amount(d, bad_duration) in
        ([]:operation list), {s with settings = {s.settings with duration = d}}