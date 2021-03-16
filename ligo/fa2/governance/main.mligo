#include "./types.mligo"
#include "./fa2.mligo"
#include "../fa2_modules/token_admin.mligo"
#include "./base_dao.mligo"
#include "./bender.mligo"
#include "./swap.mligo"
#include "./token_manager.mligo"

type param =
  | Assets of fa2_entry_points
  | Admin of token_admin
  | Dao of base_dao_entry_points
  | Bender of bender_entry_points
  | Swap of swap_entry_points
  | Tokens of token_manager

let main (p, s : param * storage) : return = 
    if Tezos.amount > 0tez
    then (failwith "FORBIDDEN_XTZ": return)
    else    
        match p with 
        | Assets p -> 
            let u2 = fail_if_paused (s.admin, p) in
            fa2_main(p, s)
        | Admin p ->  
            let ops, admin = token_admin (p, s.admin) in
            let new_s = { s with admin = admin; } in
            (ops, new_s)
        | Dao p ->
            base_dao_main (p, s)
        | Bender p -> 
            bender_main(p, s)    
        | Swap p -> 
            swap_main(p, s)
        | Tokens p ->
            let u1 = fail_if_not_admin s.admin in
            token_manager (p, s)