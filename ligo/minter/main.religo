#include "fa.2.interface.religo"
#include "interface.religo"
#include "contract_admin.religo"
#include "governance.religo"
#include "signer.religo"
#include "assets_admin.religo"


type unwrap_parameters = {
  token_id: eth_address,
  amount: nat,
  destination: eth_address
};

type entry_points = 
  Signer(signer_entrypoints)
  | Unwrap(unwrap_parameters)
  | Contract_admin(contract_admin_entrypoints)
  | Governance(governance_entrypoints)
  | Assets_admin(assets_admin_entrypoints)
  ;


let unwrap = ((p, s) : (unwrap_parameters, assets_storage)):(list(operation), assets_storage) => {
  // todo: check ethAddr
  let token_id = token_id(p.token_id, s.tokens);
  let burn_entrypoint = token_tokens_entry_point(s);
  (([Tezos.transaction(Burn_tokens([{owner:Tezos.source, token_id: token_id, amount:p.amount}]), 0mutez, burn_entrypoint)]), s);
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
      let (ops, new_storage) = signer_main(n, s.assets);
      (ops, {...s, assets:new_storage});
    }
    | Unwrap(n) => {
      fail_if_paused(s.admin);
      let (ops, new_storage) = unwrap(n, s.assets);
      (ops, {...s, assets:new_storage});
    }
    | Contract_admin(n)=> {
      fail_if_not_admin(s.admin);
      let (ops, new_storage) = contract_admin_main(n, s.admin);
      (ops:list(operation), {...s, admin:new_storage});
    }
    | Governance(n) => {
      fail_if_not_governance(s.assets);
      let (ops, new_storage) = governance_main(n, s.assets);
      (ops, {...s, assets: new_storage});
    }
    | Assets_admin(n) => {
      fail_if_not_admin(s.admin);
      let (ops, new_storage) = assets_admin_main(n, s.assets);
      (ops, {...s, assets: new_storage});
    }
    ;
  };
};