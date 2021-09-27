#include "./storage.mligo"
#include "./wallet/wallet_lib.mligo"
#include "./common/constants.mligo"
#include "./common/utils.mligo"

type get_earned_parameter = address

type get_earned_return = nat


let get_earned_view ((p,s):(get_earned_parameter * storage)) : get_earned_return = 
    let s = update_pool(s) in
    let delegator = get_delegator(p, s.ledger.delegators) in
    let (r, _) = unscale(earned(delegator, s.reward), target_exponent, s.reward.exponent) in
    r

let get_earned_main ((_,s):(get_earned_parameter * get_earned_return)) : (operation list * get_earned_return) = (([]:operation list), s)

type get_balance_parameter = address

type get_balance_return = nat

let get_balance_view (p,s: get_balance_parameter * storage) : get_balance_return = 
    get_balance(p, s.ledger.delegators)

let get_balance_main(_,s:get_balance_parameter * get_balance_return): operation list * get_balance_return = ([]:operation list), s

type stake_view = 
[@layout:comb]
{
    id: nat;
    amount: nat;
    fees_ratio: nat;
    level: nat;
}

type get_stakes_return =  stake_view list

type get_stakes_parameter = address

let get_stakes_view (a, s: address * storage): get_stakes_return =
    let fold = 
        fun (acc, (idx, stake): get_stakes_return * (nat * stake)) ->
            let {amount=amnt ; level} = stake in
            let fees_ratio = fees_level(level, s.fees) in
            {id=idx;amount=amnt;fees_ratio=fees_ratio;level=level} :: acc
    in            
    let delegator = get_delegator(a, s.ledger.delegators) in
    Map.fold fold delegator.stakes ([]:get_stakes_return)


let get_stakes_main (_,s:get_stakes_parameter * get_stakes_return): (operation list * get_stakes_return) = ([]:operation list), s

type total_supply_return = nat

let total_supply_view  (s :  storage): total_supply_return =
    s.ledger.total_supply
    

let total_supply_main  (_, s : unit * total_supply_return): operation list * total_supply_return = ([]:operation list), s