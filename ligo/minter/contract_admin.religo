#include "interface.religo"


type contract_admin_entrypoints = 
    Set_administrator(address)
    | Set_signer(address)
    | Pause_contract(bool)
    ;

let fail_if_not_admin = (s:contract_admin_storage) => 
  if(s.administrator != Tezos.sender) {
    failwith("NOT_ADMIN");
  };

let fail_if_not_signer = (s:contract_admin_storage) => 
  if(s.signer != Tezos.sender) {
    failwith("NOT_SIGNER");
  };

let fail_if_not_governance = (s:assets_storage) => 
  if(s.governance != Tezos.sender) {
    failwith("NOT_GOVERNANCE");
  };

let set_administrator = ((s, new_administrator):(contract_admin_storage, address)):(list(operation), contract_admin_storage) =>  {
  (([]:list(operation)), {...s, administrator: new_administrator});
};

let set_signer = ((s, new_signer):(contract_admin_storage, address)):(list(operation), contract_admin_storage) =>  {
  (([]:list(operation)), {...s, signer:new_signer});
};

let pause = ((s, p): (contract_admin_storage, bool)) => {
  (([]:list(operation), {...s, paused:p}));
};

let contract_admin_main = ((p, s):(contract_admin_entrypoints, contract_admin_storage)):(list(operation), contract_admin_storage) => {
  switch(p) {
    | Set_administrator(n) => set_administrator(s, n);
    | Set_signer(n) => set_signer(s, n);
    | Pause_contract(p) => pause(s, p);
  };
};