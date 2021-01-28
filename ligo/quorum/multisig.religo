#include "../minter/signer.religo"

type signer_id = string;

type counter = nat;

type metadata = big_map(string, bytes);

type storage = {
    admin: address,
    threshold: nat,
    signers: map(signer_id, key),
    metadata: metadata
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

type admin_action = 
Change_quorum((nat, map(signer_id, key)))
|Change_threshold(nat);

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

let check_signature = ((p, signatures, threshold, signers) : (bytes, signatures, nat, map(signer_id, key))) : unit => (
    let iter = ((acc, (i, signature))  : (nat, (signer_id, signature))) => {
        let key = get_key(i, signers);
        if(Crypto.check(key, signature, p)) {
            acc+1n;
        } else {
            acc;
        }
    };
    let r: nat = List.fold(iter, signatures, 0n);
    if(r<threshold) {
        failwith ("BAD_SIGNATURE");
    }
)

let get_contract = (addr: address) : contract(signer_entrypoints) => {
    switch(Tezos.get_contract_opt(addr): option(contract(signer_entrypoints))) {
    | Some(n) => n
    | None => (failwith ("BAD_CONTRACT_TARGET"):contract(signer_entrypoints))
  };
}

let apply_minter = ((p, s):(signer_action, storage)): list(operation) => {
    check_threshold(p.signatures, s.threshold);
    let payload :payload  = ((Tezos.chain_id, Tezos.self_address), p.action);
    let bytes = Bytes.pack(payload);
    check_signature(bytes, p.signatures, s.threshold, s.signers);
    let action = p.action;
    let contract = get_contract(action.target);
    [Tezos.transaction(action.entry_point, 0mutez, contract)];
};


let fail_if_not_admin = (s:storage) => 
    if(s.admin != Tezos.sender) {
        failwith("NOT_ADMIN");
    };

let apply_admin = ((action, s):(admin_action, storage)):storage => {
    fail_if_not_admin(s);
    switch(action) {
        | Change_quorum(v) => 
         let (t, signers) = v;
         {...s, threshold:t, signers:signers};
        | Change_threshold(t) => {...s, threshold:t};
    }
};

type parameter = 
    | Admin(admin_action)
    | Minter(signer_action);

type return = (list(operation), storage);

let main = ((p, s): (parameter, storage)): return => {
    switch(p) {
        | Admin v => ([]:list(operation), apply_admin(v, s));
        | Minter a => (apply_minter(a, s), s);
    };
};