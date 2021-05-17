#if !UTILS
#define UTILS

#include "errors.mligo"

let sub ((a, b):(nat * nat)): nat = 
    let res = a - b in
    match Michelson.is_nat res with
    | Some v -> v
    | None -> (failwith negative_balance:nat)

let check_amnt (amnt:nat):nat =
    if amnt > 0n
    then amnt
    else (failwith bad_amount : nat)

#endif