#include "interface.religo"

type bps = nat;

type governance_entrypoints = 
   Set_wrapping_fees(bps)
  | Set_unwrapping_fees(bps)
  | Set_fees_contract(address)
  | Set_governance(address)
  ;

let fail_if_not_governance = (s:governance_storage) => 
  if(s.contract != Tezos.sender) {
    failwith("NOT_GOVERNANCE");
  };

let set_wrapping_fees = ((s, value) : (governance_storage, nat)): governance_storage => {
  {...s, wrapping_fees:value};
};

let set_unwrapping_fees = ((s, value) : (governance_storage, nat)): governance_storage => {
  {...s, unwrapping_fees:value};
};

let set_governance = ((s, new_governance):(governance_storage, address)): governance_storage =>  {
  {...s, contract:new_governance};
};

let set_fees_contract = ((s, new_fees_contract):(governance_storage, address)): governance_storage =>  {
  {...s, fees_contract:new_fees_contract};
};

let governance_main = ((p, s):(governance_entrypoints, governance_storage)):(list(operation), governance_storage) => {
  switch(p) {
    | Set_wrapping_fees(n) => ([]:list(operation), set_wrapping_fees(s, n));
    | Set_unwrapping_fees(n) => ([]:list(operation), set_unwrapping_fees(s, n));
    | Set_fees_contract(a) => ([]:list(operation), set_fees_contract(s, a));
    | Set_governance(a) =>([]:list(operation), set_governance(s, a));
  };
};