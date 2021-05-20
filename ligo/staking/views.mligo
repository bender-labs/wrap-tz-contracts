#include "./storage.mligo"
#include "./wallet/wallet_lib.mligo"

type get_earned_parameter = address

type get_earned_return = nat


let get_earned_view ((p,s):(get_earned_parameter * storage)) : get_earned_return = 
    let s = update_pool(s) in
    let current_balance = get_balance(p, s.ledger.balances) in
    let delegator = get_delegator(p, s.delegators) in
    earned(current_balance, delegator, s.reward)

let get_earned_main ((p,s):(get_earned_parameter * storage)) : (operation list * storage) = (([]:operation list), s)