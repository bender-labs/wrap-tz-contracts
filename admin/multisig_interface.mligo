#if !MULTISIG
#define MULTISIG

type change_keys = 
[@layout:comb]
{
    threshold: nat;
    keys: key list;
}

type action = 
[@layout:comb]
| Operation of unit -> operation list
| Change_keys of change_keys

type payload = ((chain_id * address) * (nat * action))

type entry_point = ((nat * action) * signature option list)

let multisig_main (p, s: entry_point * unit) : operation list * unit= 
    ([]: operation list), s

#endif