#include "./types.mligo"
#include "./fa2.mligo"
#include "../fa2_modules/simple_admin.mligo"
#include "./oracle.mligo"
#include "./token_manager.mligo"

type param =
  | Assets of fa2_entry_points
  | Admin of token_admin
  | Oracle of oracle_entry_points
  | Tokens of token_manager

let main (p, s : param * storage) : return = 
    if Tezos.amount > 0tez
    then (failwith "FORBIDDEN_XTZ": return)
    else    
        match p with 
        | Assets p -> 
            let u2 = fail_if_paused (s.admin) in
            fa2_main(p, s)
        | Admin p ->  
            let ops, admin = simple_admin (p, s.admin) in
            let new_s = { s with admin = admin; } in
            (ops, new_s)
        | Oracle p -> 
            oracle_main(p, s)    
        | Tokens p ->
            let u1 = fail_if_not_minter s.admin in
            token_manager (p, s)