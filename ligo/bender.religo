#include "fa.2.interface.religo"
#include "ethereum.religo"
#include "contract_admin.religo"
#include "governance.religo"
#include "signer.religo"
#include "assets_admin.religo"


type storage = {
  admin: contract_admin_storage,
  assets: assets_storage
};

type burn_parameters = {
  token_id: string,
  amount: nat,
  destination: eth_address
};

type entry_points = 
  Mint(signer_entrypoints)
  | Burn(burn_parameters)
  | Contract_admin(contract_admin_entrypoints)
  | Governance(governance_entrypoints)
  | Assets_admin(assets_admin_entrypoints)
  ;

type return = (list(operation), storage);

let burn = ((p, s) : (burn_parameters, assets_storage)):(list(operation), assets_storage) => {
  // todo: check ethAddr
  let burn_entrypoint = token_tokens_entry_point(p.token_id, s.tokens);
  (([Tezos.transaction(Burn_tokens([{owner:Tezos.source, amount:p.amount}]), 0mutez, burn_entrypoint)]), s);
};

// todo: refuser le dépôt de fond
let main = ((p, s):(entry_points, storage)):return => {
  switch(p) {
    | Mint(n) => {
      fail_if_not_signer(s.admin);
      let (ops, new_storage) = signer_main(n, s.assets);
      (ops, {...s, assets:new_storage});
    }
    | Burn(n) => {
      let (ops, new_storage) = burn(n, s.assets);
      (ops, {...s, assets:new_storage});
    }
    | Contract_admin(n)=> {
      fail_if_not_admin(s.admin);
      let (ops, new_storage) = contract_admin_main(n, s.admin);
      (ops:list(operation), {...s, admin:new_storage});
    }
    | Governance(n) => {
      fail_if_not_governance(s.admin);
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