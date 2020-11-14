#include "tokens.religo"

type governance_entrypoints = 
   Set_fees_ratio(nat)
  | Add_token((string,address))
  | Remove_token(string)
  ;

let set_fees_ratio = ((s, value) : (tokens_storage, nat)): (list(operation), tokens_storage) => {
  (([]:list(operation)), {...s, fees_ratio:value});
};

// todo : check contract type
let add_token = ((s, p): (tokens_storage, (string, address))) : (list(operation), tokens_storage) => {
  let (id, contractAddress) = p;
  let updated_tokens = Map.update((id:string), Some(contractAddress), s.tokens);
  (([]:list(operation)), {...s, tokens:updated_tokens});
};

let remove_token = ((s, p): (tokens_storage, string)) : (list(operation), tokens_storage) => {
  let updated_tokens = Map.remove(p, s.tokens);
  (([]:list(operation)), {...s, tokens:updated_tokens});
};


let governance_main = ((p, s):(governance_entrypoints, tokens_storage)):(list(operation), tokens_storage) => {
  switch(p) {
    | Set_fees_ratio(n) => set_fees_ratio(s, n)
    | Add_token(n) => add_token(s, n)
    | Remove_token(n) => remove_token(s, n)
    ;
  };
};