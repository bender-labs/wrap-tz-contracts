#include "../storage.mligo"
#include "../fa2/fa2_lib.mligo"
#include "../common/utils.mligo"
#include "../common/errors.mligo"

type wallet_entrypoints = 
| Stake of nat
| Withdraw of nat


let stake ((amnt, ledger, token):(nat * ledger * token)): (operation list) * ledger = 
    let new_balance = 
        match Map.find_opt Tezos.sender ledger.balances with
        | Some bal -> bal+amnt
        | None -> amnt
        in
    let balances = Map.update Tezos.sender (Some new_balance) ledger.balances in
    let op = transfer_one (Tezos.sender, Tezos.self_address, token, amnt) in
    [op], {ledger with total_supply = ledger.total_supply + amnt; balances = balances}

let check_amnt (amnt:nat):nat =
    if amnt > 0n
    then amnt
    else (failwith bad_amount : nat)

let withdraw((amnt, ledger, token):(nat * ledger * token)): (operation list) * ledger = 
    let amnt = check_amnt amnt in
    let new_balance = 
        match Map.find_opt Tezos.sender ledger.balances with
        | Some bal -> sub(bal, amnt)
        | None -> (failwith negative_balance: nat)
        in
    let balances = Map.update Tezos.sender (Some new_balance) ledger.balances in
    let op = transfer_one (Tezos.self_address, Tezos.sender, token, amnt) in
    [op], {ledger with total_supply = sub(ledger.total_supply, amnt); balances = balances}

let wallet_main ((p, s): (wallet_entrypoints * storage)): contract_return = 
    match p with
    | Stake a -> 
        let (ops, ledger) = stake(a, s.ledger, s.settings.reward_token) in
        ops, { s with ledger = ledger}
    | Withdraw a -> 
        let (ops, ledger) = withdraw(a, s.ledger, s.settings.reward_token) in
        ops, { s with ledger = ledger}