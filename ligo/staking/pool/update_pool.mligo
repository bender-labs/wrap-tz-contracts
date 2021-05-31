#if !UPDATE_POOL
#define UPDATE_POOL

#include "../storage.mligo"

let scale = 1_000_000n

let last_block_applicable (r: reward) = 
    if Tezos.level > r.period_end then r.period_end else Tezos.level

let update_reward(r, supply: reward * nat): reward = 
    let last = last_block_applicable(r) in
    let multiplier = abs(last - r.last_block_update) in
    if supply = 0n 
    then {r with last_block_update = last ; reward_remainder = r.reward_remainder + multiplier * r.reward_per_block }
    else
        let acc = r.accumulated_reward_per_token + multiplier * r.reward_per_block * scale / supply in
        {r with accumulated_reward_per_token = acc; last_block_update = last}

let update_pool (s: storage): storage = 
    let reward = s.reward in
    let reward = update_reward(reward, s.ledger.total_supply) in
    {s with reward = reward}

#endif