type distribute_param = 
[@layout:comb]
{
    signers: key_hash list;
    tokens: (address * nat) list;
}

type oracle_entrypoint =
| Distribute_tokens of distribute_param
| Distribute_xtz of key_hash list