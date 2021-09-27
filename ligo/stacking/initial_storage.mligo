#include "./stacking_main.mligo"

let initial_storage : storage = {
    ledger = {
        total_supply = 0n;
        delegators = (Big_map.empty : (address,delegator) big_map)
    };
    fees = {
        default_fees = 25n;
        fees_per_cycles = Map.literal [(1n, 4n);(2n, 8n);(3n, 8n);(4n, 8n);(5n,16n);(6n,16n);(7n,16n);(8n,16n);(9n,16n);(10n,16n);(11n,16n);(12n,16n)];
        burn_address = ("tz1exrEuATYhFmVSXhkCkkFzY72T75hpsthj": address);
        blocks_per_cycle = 16n;
    };
    settings = {
        staked_token = ("KT1M6RSfdbWL6RH5tPdxekrZhtXUh67x2N9Y":address), 0n;
        reward_token = ("KT1M6RSfdbWL6RH5tPdxekrZhtXUh67x2N9Y":address), 0n;
        reserve_contract= ("tz1S792fHX5rvs6GYP49S1U58isZkp2bNmn6":address);
        duration= 86400n;
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
    metadata = Big_map.literal [("", (0x697066733a2f2f516d59756466614a365169756d59784a7173663736443473647863584b366d33654a4e766e364436534639706459:bytes))]
}