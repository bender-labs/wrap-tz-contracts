#include "interface.religo"

type bps = nat;

type governance_entrypoints = 
   Set_fees_ratio(bps)
  | Set_fees_contract(address)
  | Set_governance(address)
  ;

// todo : adds a minimum check ?
let set_fees_ratio = ((s, value) : (assets_storage, nat)): assets_storage => {
  {...s, fees_ratio:value};
};

let set_governance = ((s, new_governance):(assets_storage, address)): assets_storage =>  {
  {...s, governance:new_governance};
};

let set_fees_contract = ((s, new_fees_contract):(assets_storage, address)): assets_storage =>  {
  {...s, fees_contract:new_fees_contract};
};

let governance_main = ((p, s):(governance_entrypoints, assets_storage)):(list(operation), assets_storage) => {
  switch(p) {
    | Set_fees_ratio(n) => ([]:list(operation), set_fees_ratio(s, n));
    | Set_fees_contract(a) => ([]:list(operation), set_fees_contract(s, a));
    | Set_governance(a) =>([]:list(operation), set_governance(s, a));
  };
};