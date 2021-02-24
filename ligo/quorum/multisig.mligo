#include "../minter/signer_interface.mligo"
#include "../minter/oracle_interface.mligo"
#include "../minter/signer_ops_interface.mligo"

type signer_id = string

type counter = nat

type metadata = (string, bytes) big_map

type storage = {
    admin: address;
    threshold: nat;
    signers: (signer_id, key) map;
    metadata: metadata;
    counters: (signer_id, nat) map;
}

type contract_invocation = {
    entrypoint: signer_entrypoints;
    target: address;
}

type signatures = (signer_id * signature) list

type signer_action = {
    signatures: signatures;
    action: contract_invocation;
}

type admin_action = 
| Change_quorum of nat * (signer_id, key) map
| Change_threshold of nat

type t1 = chain_id * address
type payload = t1 * contract_invocation

let get_key ((id, signers): (signer_id * (signer_id, key) map)) : key = 
    match Map.find_opt id signers with
    | Some(n) -> n
    | None -> (failwith ("SIGNER_UNKNOWN"): key)

let check_threshold ((signatures, threshold):(signatures * nat)): unit =
    if List.length(signatures) < threshold then 
        failwith ("MISSING_SIGNATURES")
    
let check_signature ((p, signatures, threshold, signers) : (bytes * signatures * nat * (signer_id, key) map)) : unit = 
    let iter : (nat * (signer_id * signature)) -> nat = 
        fun ((acc, (i, signature))  : (nat * (signer_id * signature))) ->
            let key = get_key(i, signers) in
            if Crypto.check key signature p then 
                acc+1n
            else 
                acc
        in
    
    let r: nat = List.fold iter signatures 0n in
    if r<threshold then
        failwith ("BAD_SIGNATURE")


let get_contract (addr: address) : signer_entrypoints contract = 
    match (Tezos.get_entrypoint_opt "%signer" addr: (signer_entrypoints contract) option) with
    | Some(n) -> n
    | None -> (failwith ("BAD_CONTRACT_TARGET"): signer_entrypoints contract)

let apply_minter ((p, s) : (signer_action * storage)): operation list = 
    let f = check_threshold(p.signatures, s.threshold) in
    let payload : payload  = ((Tezos.chain_id, Tezos.self_address), p.action) in
    let bytes = Bytes.pack(payload) in
    let f = check_signature(bytes, p.signatures, s.threshold, s.signers) in
    let action = p.action in
    let contract = get_contract(action.target) in
    [Tezos.transaction action.entrypoint Tezos.amount contract]


let fail_if_not_admin (s:storage) =
    if s.admin <> Tezos.sender then 
        failwith("NOT_ADMIN")
    

let check_new_quorum(p: nat * (signer_id, key) map): unit = 
    let (t, signers) = p in
    if t > Map.size signers || t < 1n 
    then (failwith "BAD_QUORUM":unit)
    else
        let unique = 
            Map.fold (fun (acc, v: (key_hash set * (string * key))) -> Set.add (Crypto.hash_key v.1) acc)
            signers
            (Set.empty : key_hash set)
            in
        if Set.size unique <> Map.size signers
        then (failwith "BAD_QUORUM":unit)

let apply_admin ((action, s):(admin_action * storage)) : storage = 
    let f = fail_if_not_admin(s) in
    match action with 
    | Change_quorum(v) -> 
        let ignore = check_new_quorum(v) in
        let (t, signers) = v in
        {s with threshold=t; signers=signers}
    | Change_threshold(t) -> 
        if t > Map.size s.signers || t < 1n
        then (failwith "BAD_QUORUM": storage)
        else {s with threshold=t}

type payment_address_parameter = {
    minter_contract: address;
    signer_id: string;
    signature: signature;
}

type distribute_tokens_parameter = {
    minter_contract: address;
    tokens: (address * nat) list
}

type fees_entrypoints = 
| Distribute_tokens_with_quorum of distribute_tokens_parameter
| Distribute_xtz_with_quorum of address


type parameter = 
| Admin of admin_action
| Minter of signer_action
| Fees of fees_entrypoints
| Set_signer_payment_address of payment_address_parameter

type return = (operation list) * storage

let fail_if_amount (v:unit) =
  if Tezos.amount > 0tez then failwith("FORBIDDEN_XTZ")

let get_fees_contract (addr: address) : oracle_entrypoint contract = 
    match (Tezos.get_entrypoint_opt "%oracle" addr: (oracle_entrypoint contract) option) with
    | Some(n) -> n
    | None -> (failwith ("BAD_CONTRACT_TARGET"): oracle_entrypoint contract)

let get_ops_contract (addr: address) : signer_ops_entrypoint contract = 
    match (Tezos.get_entrypoint_opt "%signer_ops" addr: (signer_ops_entrypoint contract) option) with
    | Some(n) -> n
    | None -> (failwith ("BAD_CONTRACT_TARGET"): signer_ops_entrypoint contract)

let signers_keys_hash(s:storage) : key_hash list =
    let folded = fun (acc, j : key_hash list * (string * key) ) -> (Crypto.hash_key j.1) :: acc in
    Map.fold folded s.signers ([]: key_hash list)


type set_payment_address_payload = t1 * (nat * (address * address))

let set_payment_address (p, s: payment_address_parameter * storage): return =
    let signer_key = 
        match Map.find_opt p.signer_id s.signers with
        | Some v -> v
        | None -> (failwith "UNKNOWN_SIGNER": key)
        in
    
    let signer_counter = 
        match Map.find_opt p.signer_id s.counters with
        | Some n -> n
        | None -> 0n
    in
    let payload:set_payment_address_payload = (Tezos.chain_id, Tezos.self_address), (signer_counter, (p.minter_contract, Tezos.sender)) in
    let packed = Bytes.pack payload in
    
    if not Crypto.check signer_key p.signature packed 
    then (failwith "BAD_SIGNATURE":return)
    else
        let target = get_ops_contract(p.minter_contract) in
        let call  = Set_payment_address ({
            signer = Crypto.hash_key signer_key;
            payment_address = Tezos.sender;
        }) in
        let op = Tezos.transaction call 0tez target in 
        [op], {s with counters = Map.update p.signer_id (Some (signer_counter + 1n)) s.counters }

let fees_main (p, s: fees_entrypoints * storage): return =
    match p with
    | Distribute_tokens_with_quorum p -> 
        let keys =  signers_keys_hash(s) in
        let target = get_fees_contract(p.minter_contract) in
        let call = Distribute_tokens ({signers=keys;tokens=p.tokens}) in
        let op = Tezos.transaction call 0tez target in 
        [op], s
    | Distribute_xtz_with_quorum p -> 
        let keys =  signers_keys_hash(s) in
        let target = get_fees_contract(p) in
        let call = Distribute_xtz (keys) in
        let op = Tezos.transaction call 0tez target in 
        [op], s


let main ((p, s): (parameter * storage)): return = 
    match p with 
    | Admin v -> 
        let f = fail_if_amount() in
        (([]: operation list), apply_admin(v, s))
    | Minter a -> (apply_minter(a, s), s)
    | Fees p -> 
        let ignore = fail_if_amount() in
        fees_main(p, s)
    | Set_signer_payment_address p ->
        let ignore = fail_if_amount() in
        set_payment_address(p, s)