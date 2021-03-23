
on edo : KT1NEwCNbdz27XZpuhZhzECR97yBpxfo83Am

Helpers to administrate the different smart contracts that Bender labs manages.

## Requirements

* ligo
* make version >= 4

## Usage

The multisignature contract is a generic one. So the the goal of this helpers is to :
* create the proper `LAMBDA`
* generate the payload to signe
* generate the call to the multisig

Each managable entry point follows the same logic : 

1. call `make <entrypoint_name>_params`
2. fill the gaps generated in `build/<entrypoint_name>.mligo`
3. call `make <entrypoint_name>_payload`
4. send the payload to other signers, and make them sign:
    * `tezos-client sign bytes "<actual bytes>" for <key alias>`
5. gather the signatures, and fill the gap in `build/<entrypoint_name>.mligo`
6. call `make <entrypoint_name>_call`
7. invoke the multisig `tezos-client call <multisig address> from <key alias> --entrypoint main --arg "$(cat build/<entrypoint_name>.tz)"`

## Variables

Some variables can/must be set in order for the place holder to be a little less empty:
* contract_address : this is the multisig address
* target_address: contract to be managed
* counter: actual counter value in the storage
* chain_id: chain_id to target

for instance :
`make contract_address=KT… target_address=KT… quorum_change_threshold_params`

## Originating the multisig

`tezos-client originate contract GenericMultisig transferring 0 from <key alias> running generic_multisig.tz --init '(Pair 0 (Pair 1 {"<key 1>";"<key 2>"}))' --burn-cap <proper value>`