#if !TOKENS
#define TOKENS

#include "../fa2/common/fa2_interface.mligo"
#include "ethereum_lib.mligo"
#include "storage.mligo"


let get_fa2_token_id (eth_contract, tokens : eth_address * (eth_address,token_address) map): token_address = 
  match Map.find_opt eth_contract tokens with
  | Some(n) -> n
  | None -> (failwith ("UNKNOWN_TOKEN"): token_address)

let get_nft_contract (eth_contract, tokens : eth_address * (eth_address,address) map): address = 
  match Map.find_opt eth_contract tokens with
  | Some(n) -> n
  | None -> (failwith ("UNKNOWN_TOKEN"): address)

let token_transfer_entrypoint(fa2 : address) : (transfer list) contract = 
  let fa2_entry : ((transfer list) contract) option =  Tezos.get_entrypoint_opt "%transfer" fa2 in
  match fa2_entry with
  | None -> (failwith "CANNOT CALLBACK FA2" : (transfer list) contract)
  | Some c -> c

let token_tokens_entry_point (token_contract_address:address): token_manager contract = 
  match (Tezos.get_entrypoint_opt "%tokens" token_contract_address : token_manager contract option) with
  | Some(n) -> n
  | None -> (failwith ("CONTRACT_NOT_COMPATIBLE"): token_manager contract)
  
let fail_if_amount (_v:unit) =
  if Tezos.amount > 0tez then failwith("FORBIDDEN_XTZ")


#endif