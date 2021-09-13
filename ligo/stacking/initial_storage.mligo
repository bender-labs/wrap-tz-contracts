#include "./stacking_main.mligo"

let initial_storage : storage = {
    ledger = {
        total_supply = 0n;
        delegators = (Big_map.empty : (address,delegator) big_map)
    };
    fees = {
        default_fees = 25n;
        fees_per_cycles = Map.literal [(1n, 4n);(2n,8n);(3n,10n)];
        burn_address = ("tz1exrEuATYhFmVSXhkCkkFzY72T75hpsthj": address);
        blocks_per_cycle = 16n;
    };
    settings = {
        staked_token = ("KT1M6RSfdbWL6RH5tPdxekrZhtXUh67x2N9Y":address), 0n;
        reward_token = ("KT1M6RSfdbWL6RH5tPdxekrZhtXUh67x2N9Y":address), 0n;
        reserve_contract= ("tz1S792fHX5rvs6GYP49S1U58isZkp2bNmn6":address);
        duration= 2880n;
    };
    reward = {
        last_block_update= 0n;
        period_end= 0n;
        accumulated_reward_per_token= 0n;
        reward_per_block = 0n;
        reward_remainder = 0n;
        exponent= 8n;
    };
    admin = {
        address = ("tz1S792fHX5rvs6GYP49S1U58isZkp2bNmn6":address);
        pending_admin = (None : address option);
    };
    metadata = Big_map.literal [("", (0x68747470733a2f2f676973742e67697468756275736572636f6e74656e742e636f6d2f426f647953706c6173682f35636633643336333739393839653430336264306536373631346236323166312f7261772f76657374696e672e6a736f6e:bytes))]
}