#if !UPDATE_POOL
#define UPDATE_POOL

#include "../storage.mligo"

let scale = 1_000_000n

let last_block_applicable (r: reward) = 
    if Tezos.level > r.period_end then r.period_end else Tezos.level

let update_reward(r, supply: reward * nat): reward = 
    if supply = 0n 
    then r
    else
        let multiplier = abs(last_block_applicable(r) - r.last_block_update) in
        let acc = r.accumulated_reward_per_token + multiplier * r.reward_per_block * scale / supply in
        {r with accumulated_reward_per_token = acc}

let update_last_block(r: reward): reward = 
    {r with last_block_update = last_block_applicable(r)}

let update_pool (s: storage): storage = 
    let reward = s.reward in
    let reward = update_reward(reward, s.ledger.total_supply) in
    {s with reward = update_last_block (reward)}

#endif