#include "../bender/signer.religo"

type signer_id = string;

type counter = nat;

type storage = {
    counter: counter,
    threshold: nat,
    signers: map(signer_id, key)
};

type contract_invocation = {
    parameter: signer_entrypoints,
    target: address
}

type multisig_action = 
     Signer_operation(contract_invocation)
    |Change_keys;



type parameter = {
    counter: nat,
    multisig_action: multisig_action,
    signatures: list((signer_id, signature))
};

type t1 = (chain_id, address);
type t2 = (counter, multisig_action);
type payload = (t1, t2);

let get_key = ((id, signers): (signer_id, map(signer_id, key))) : key => {
    switch(Map.find_opt(id, signers)) {
        | Some(n) => n;
        | None => (failwith ("SIGNER_UNKNOWN"): key)
    };
}

let check_signature = ((p, signatures, signers) : (bytes, list((signer_id, signature)), map(signer_id, key))) : unit => {
    let iter = ((acc, (i, signature))  : (bool, (signer_id, signature))) => {
        let key = get_key(i, signers);
        acc && Crypto.check(key, signature, p);
    };
    let r: bool = List.fold(iter, signatures, true);
    if(!r) {
        failwith ("BAD_SIGNATURE");
    }
}

let get_contract = (addr: address) : contract(signer_entrypoints) => {
    switch(Tezos.get_contract_opt(addr): option(contract(signer_entrypoints))) {
    | Some(n) => n
    | None => (failwith ("NOT_BENDER_CONTRACT"):contract(signer_entrypoints))
  };
}

let apply_signer_operation = (op: contract_invocation) : list(operation) => {
    let contract = get_contract(op.target);
    [Tezos.transaction(op.parameter, 0mutez, contract)];
};

let main = ((p, s): (parameter, storage)): (list(operation), storage) => {
    let payload :payload  = ((Tezos.chain_id, Tezos.self_address), (p.counter, p.multisig_action));
    let bytes = Bytes.pack(payload);
    check_signature(bytes, p.signatures, s.signers);
    switch(p.multisig_action) {
        | Signer_operation(op) => (apply_signer_operation(op), s);
        | Change_keys => (failwith("NOT_IMPLEMENTTED") :(list(operation), storage));
    };
};