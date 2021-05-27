#if !UTILS
#define UTILS

#include "errors.mligo"

let sub ((a, b):(nat * nat)): nat = 
    let res = a - b in
    match Michelson.is_nat res with
    | Some v -> v
    | None -> (failwith negative_balance:nat)

let check_amount (a,e:nat * string):nat = 
    if a = 0n 
    then (failwith e:nat)
    else a

#endif