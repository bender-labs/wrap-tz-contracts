
(*
  `multi_asset` contract combines `multi_token` transfer API with
  `token_admin` API and `token_manager` API.  Input parameter type for the
  `multi_asset` contract is a union of `multi_token` and `token_admin` parameter
  types.
  The contract can pause individual tokens. If one of the tokens to be transferred
  is paused, whole transfer operation fails.
*)

#include "fa2_multi_token.mligo"
#include "multi_token_admin.mligo"
#include "token_manager.mligo"

type multi_asset_param =
  | Assets of fa2_entry_points
  | Admin of multi_token_admin
  | Tokens of token_manager

let main
    (param, s : multi_asset_param * multi_asset_storage)
    : return =
  match param with
  | Admin p ->  
    multi_token_admin_main (p, s)
  | Tokens p ->
    let _u1 = fail_if_not_minter s.admin in
    let ops, assets = token_manager (p, s.assets) in 
    let new_s = { s with
      assets = assets
    } in 
    (ops, new_s)

  | Assets p -> 
    let _u2 = fail_if_paused (s.admin, p) in
      
    let ops, assets = fa2_main (p, s.assets) in
    let new_s = { s with assets = assets } in
    (ops, new_s)
