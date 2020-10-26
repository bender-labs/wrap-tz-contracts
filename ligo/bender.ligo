#include "fa.1.2_interface.ligo"
type storage is
    record [
        administrator: address;
        feesContract : address;
        tokens : big_map(string, address);
        mints : big_map(string, bool);
    ]


type mintParameters is record [tokenId : string; destination : address; value : nat];
type burnParameters is record [sender: address ; value: nat ] ;

type action is
| Mint of mintParameters
| Burn
| SetAdministrator of address

type return is list(operation) * storage;

function is_allowed(const administrator: address): bool is 
  administrator = Tezos.sender

function mint (var s : storage ; const p : mintParameters) : return is
  block { 
    if(is_allowed(s.administrator)) then skip else {
      failwith("Sender is not administrator.")
    };
    const tokenAddress : address = case s.tokens[p.tokenId] of 
      Some (n) -> n
      | None -> (failwith ("Unknown token.") :address)
    end;

    
    const mint : contract(token_contract_mint) = case (Tezos.get_entrypoint_opt("%mint", tokenAddress) : option(contract(token_contract_mint))) of
      Some (n) -> n
      | None -> (failwith ("Token contract is not mintable"): contract(token_contract_mint))
    end;
    const mintOperation:operation = Tezos.transaction((p.destination, p.value), 0mutez,mint);
  } with ((list mintOperation;end : list(operation)), s);

function setAdministrator(const s : storage; const newAdministrator: address ) is 
  block {
    if(is_allowed(s.administrator)) then skip else {
      failwith("Sender is not administrator.")
    };
  } with ((nil: list(operation)), s with record [administrator = newAdministrator]);

function main (const p : action ; const s : storage) :
  return is
  case p of
   Mint(n) -> mint(s, n)
  | Burn -> (failwith("not implemented"):return)
  | SetAdministrator(n) -> setAdministrator(s, n)
  end;
