#include "../fa2/fa.2.interface.religo"
#include "interface.religo"
#include "contract_admin.religo"
#include "governance.religo"
#include "signer.religo"
#include "assets_admin.religo"


type unwrap_parameters = {
  token_id: eth_address,
  amount: nat,
  fees: nat,
  destination: eth_address
};

type entry_points = 
  Signer(signer_entrypoints)
  | Unwrap(unwrap_parameters)
  | Contract_admin(contract_admin_entrypoints)
  | Governance(governance_entrypoints)
  | Assets_admin(assets_admin_entrypoints)
  ;

let check_fees_high_enough = ((v, min):(nat, nat)) => 
  if(v < min) {
    failwith("FEES_TOO_LOW");
  };

let check_amount_large_enough = (v:nat) =>
  if(v < 1n) {
    failwith("AMOUNT_TOO_SMALL");
  }

let unwrap = ((p, g, s) : (unwrap_parameters, governance_storage, assets_storage)):(list(operation), assets_storage) => {
  // todo: check ethAddr
  let token_id = token_id(p.token_id, s.tokens);
  let mint_burn_entrypoint = token_tokens_entry_point(s);
  let min_fees:nat = p.amount * g.unwrapping_fees / 10_000n;
  check_amount_large_enough(min_fees);
  check_fees_high_enough(p.fees, min_fees);
  let burn = Tezos.transaction(Burn_tokens([{owner:Tezos.source, token_id: token_id, amount:p.amount+p.fees}]), 0mutez, mint_burn_entrypoint);
  let mint = Tezos.transaction(Mint_tokens([{owner:g.fees_contract, token_id: token_id, amount:p.fees}]), 0mutez, mint_burn_entrypoint);
  (([burn, mint]), s);
};

let fail_if_paused = (s:contract_admin_storage) =>
  if(s.paused) {
    failwith("CONTRACT_PAUSED");
  };

// todo: refuser le dépôt de fond
let main = ((p, s):(entry_points, storage)):return => {
  switch(p) {
    | Signer(n) => {
      fail_if_not_signer(s.admin);
      fail_if_paused(s.admin);
      let (ops, new_storage) = signer_main(n,s.governance, s.assets);
      (ops, {...s, assets:new_storage});
    }
    | Unwrap(n) => {
      fail_if_paused(s.admin);
      let (ops, new_storage) = unwrap(n, s.governance, s.assets);
      (ops, {...s, assets:new_storage});
    }
    | Contract_admin(n)=> {
      fail_if_not_admin(s.admin);
      let (ops, new_storage) = contract_admin_main(n, s.admin);
      (ops:list(operation), {...s, admin:new_storage});
    }
    | Governance(n) => {
      fail_if_not_governance(s.governance);
      let (ops, new_storage) = governance_main(n, s.governance);
      (ops, {...s, governance: new_storage});
    }
    | Assets_admin(n) => {
      fail_if_not_admin(s.admin);
      let (ops, new_storage) = assets_admin_main(n, s.assets);
      (ops, {...s, assets: new_storage});
    }
    ;
  };
};