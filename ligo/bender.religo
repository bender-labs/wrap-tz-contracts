#include "fa.2.interface.religo"
#include "admin.religo"
#include "governance.religo"
#include "signer.religo"


type storage = {
  admin: admin_storage,
  assets: assets_storage
};

type eth_address = string;

type burnParameters = {
  tokenId: string,
  amount: nat,
  destination: eth_address
};

type entry_points = 
  Mint(signer_entrypoints)
  | Burn(burnParameters)
  | Admin(admin_entrypoints)
  | Governance(governance_entrypoints)
  | ChangeTokensAdministrator
  ;

type return = (list(operation), storage);

let burn = ((s, p) : (assets_storage, burnParameters)):(list(operation), assets_storage) => {
  // todo: check ethAddr
  let burnEntryPoint = token_tokens_entry_point(p.tokenId, s.tokens);
  (([Tezos.transaction(Burn_tokens([{owner:Tezos.source, amount:p.amount}]), 0mutez, burnEntryPoint)]), s);
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
      let (ops, new_storage) = burn(s.assets, n);
      (ops, {...s, assets:new_storage});
    }
    | Admin(n)=> {
      fail_if_not_admin(s.admin);
      let (ops, new_storage) = admin_main(n, s.admin);
      (ops:list(operation), {...s, admin:new_storage});
    }
    | Governance(n) => {
      fail_if_not_governance(s.admin);
      let (ops, new_storage) = governance_main(n, s.assets);
      (ops, {...s, assets: new_storage});
    }
    | ChangeTokensAdministrator => (failwith ("Not implemented"):return)
    ;
  };
};