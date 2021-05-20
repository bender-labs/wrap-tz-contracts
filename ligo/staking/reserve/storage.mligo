
type admin = {
    address: address;
    pending_admin: address option;
}

type token = address * nat

type farms = (address, token) big_map

type storage = {
    admin: admin;
    farms: farms;
    minter_contract: address;   
}

type contract_return = operation list * storage