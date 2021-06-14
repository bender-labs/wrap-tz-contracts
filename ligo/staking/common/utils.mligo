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

let pow (x, p: nat*nat):nat = 
    let rec rec_pow (num, p, value: nat * nat * nat) : nat =
        if p = 0n then value
        else if p = 1n then num * value
        else
            match ediv p 2n with
            | Some (q,r)->
                if r = 0n then rec_pow(num * num, q, value)
                else rec_pow(num * num, abs(p-1n)/2n, value * num)
            | None -> (failwith "bad_scale" : nat)
        
    in
    rec_pow(x, p, 1n)

let scale(amnt,exp, target:nat*nat*nat):nat = 
    let diff = target - exp in
    match is_nat diff with
    | Some v -> 
        amnt * pow(10n, v)
    | None -> 
        amnt / pow(10n, abs(diff))

let scale_precise(amnt,exp, target:nat*nat*nat):nat*nat = 
    let diff = target - exp in
    match is_nat diff with
    | Some v -> 
        amnt * pow(10n, v) , 0n
    | None -> (
        let p = pow(10n, abs(diff)) in
        match ediv amnt p with
        | Some v -> v
        | None -> (failwith "bad_exponent":nat * nat))

#endif