#if !UTILS
#define UTILS

#include "errors.mligo"

let sub ((a, b):(nat * nat)): nat = 
    let res = a - b in
    match Michelson.is_nat res with
    | Some v -> v
    | None -> (failwith negative_balance:nat)

#endif