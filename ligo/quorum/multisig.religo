#include "../minter/signer.religo"

type signer_id = bytes;

type counter = nat;

type storage = {
    admin: address,
    threshold: nat,
    signers: map(signer_id, key)
};

type contract_invocation = {
    entry_point: signer_entrypoints,
    target: address
};

type signatures = list((signer_id, signature));

type signer_action = {
    signatures: signatures,
    action: contract_invocation,
};
    
type admin_action = Change_quorum(list((signer_id, key)));

type t1 = (chain_id, address);
type payload = (t1, contract_invocation);

let get_key = ((id, signers): (signer_id, map(signer_id, key))) : key => {
    switch(Map.find_opt(id, signers)) {
        | Some(n) => n;
        | None => (failwith ("SIGNER_UNKNOWN"): key)
    };
}

let check_threshold = ((signatures, threshold):(signatures, nat)): unit =>
    if(List.length(signatures) < threshold) {
        failwith ("MISSING_SIGNATURES");
    };

let check_signature = ((p, signatures, signers) : (bytes, signatures, map(signer_id, key))) : unit => (
    let iter = ((acc, (i, signature))  : (bool, (signer_id, signature))) => {
        let key = get_key(i, signers);
        acc && Crypto.check(key, signature, p);
    };
    let r: bool = List.fold(iter, signatures, true);
    if(!r) {
        failwith ("BAD_SIGNATURE");
    }
)

let get_contract = (addr: address) : contract(signer_entrypoints) => {
    switch(Tezos.get_contract_opt(addr): option(contract(signer_entrypoints))) {
    | Some(n) => n
    | None => (failwith ("BAD_CONTRACT_TARGET"):contract(signer_entrypoints))
  };
}

let apply_signer_operation = (op: contract_invocation) : list(operation) => {
    let contract = get_contract(op.target);
    [Tezos.transaction(op.entry_point, 0mutez, contract)];
};

let apply_minter = ((p, s):(signer_action, storage)): list(operation) => {
    check_threshold(p.signatures, s.threshold);
    let payload :payload  = ((Tezos.chain_id, Tezos.self_address), p.action);
    let bytes = Bytes.pack(payload);
    check_signature(bytes, p.signatures, s.signers);
    apply_signer_operation(p.action);
};

type parameter = 
    | Admin(admin_action)
    | Minter(signer_action);

type return = (list(operation), storage);

let main = ((p, s): (parameter, storage)): return => {

    switch(p) {
        | Admin v => (failwith("NOT_IMPLEMENTED"):return);
        | Minter a => (apply_minter(a, s), s);
    };
};