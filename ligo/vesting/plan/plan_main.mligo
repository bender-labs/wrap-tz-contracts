#include "../storage.mligo"
#include "../common/errors.mligo"
#include "../pool/update_pool.mligo"
#include "../common/constants.mligo"
#include "../common/utils.mligo"

type update_plan = nat

type plan_entrypoints = 
| Update_plan of update_plan


let new_plan (amnt, s: nat * storage): nat * nat = 
    let amnt = scale(amnt, s.reward.exponent, target_exponent)  + s.reward.reward_remainder in
    match ediv amnt s.settings.duration with
    | Some (q, r) -> q, r
    | None -> (failwith "Bad amount": nat * nat)


let update_plan(amnt, s: nat * storage): contract_return = 
    if Tezos.level < s.reward.period_end then
        (failwith distribution_running : contract_return)
    else
        let (reward_per_block, r) = new_plan(amnt, s) in
        if reward_per_block = 0n then ([]:operation list), s
        else
            let reward = {s.reward with 
                last_block_update = Tezos.level;
                period_end = s.settings.duration + Tezos.level;
                reward_per_block = reward_per_block;
                reward_remainder = r
                }
                in
            ([]:operation list),{s with reward = reward}


let update_plan (amnt, s : nat * storage): contract_return =
    let s = update_pool(s) in
    update_plan(amnt, s)

let plan_main (p, s: plan_entrypoints * storage) : contract_return =
    match p with
    | Update_plan a -> 
        let a = check_amount(a, bad_amount) in
        update_plan(a, s)