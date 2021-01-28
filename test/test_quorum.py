import unittest
from pathlib import Path

from pytezos import Key
from pytezos.michelson.micheline import michelson_to_micheline
from pytezos.michelson.pack import pack
from pytezos.repl.parser import MichelsonRuntimeError

from src.ligo import LigoContract

owner = "tz1S792fHX5rvs6GYP49S1U58isZkp2bNmn6"
minter_contract = "KT1VUNmGa1JYJuNxNS4XDzwpsc9N1gpcCBN2%signer"
chain_id = "NetXm8tYqnMWky1"
minter_ep = """(or 
                   (pair %add_token
                      (bytes %eth_contract)
                      (pair %metadata (nat %token_id) (map %extras string bytes)))
                   (pair %mint_token
                      (pair (nat %amount) (pair %event_id (bytes %block_hash) (nat %log_index)))
                      (pair (address %owner) (bytes %token_id))))"""

first_signer_id = "k51qzi5uqu5dilfdi6xt8tfbw4zmghwewcvvktm7z9fk4ktsx4z7wn0mz2glje"
second_signer_id = "k51qzi5uqu5dhuc1pto6x98woksrqgwhq6d1lff2hfymxmlk4qd7vqgtf980yl"
first_signer_key = Key.generate(curve=b'sp', export=False)
second_signer_key = Key.generate(curve=b'sp', export=False)
payload_type = michelson_to_micheline(f"(pair (pair chain_id address) (pair {minter_ep} address))")

# ugly. There is no way to patch the repl with SELF address. So here is the one it
# generates the first time it is called
repl_generated_contract_address = "KT1BEqzn5Wx8uJrZNvuS9DVHmLvG9td3fDLi"


class QuorumContractTest(unittest.TestCase):

    @classmethod
    def setUpClass(cls) -> None:
        root_dir = Path(__file__).parent.parent / "ligo"
        cls.contract = LigoContract(root_dir / "quorum" / "multisig.religo", "main").get_contract()

    def test_accepts_valid_signature(self):
        amount = 10000000
        token_id = b"contract_on_eth"
        block_hash = b"txId"
        log_index = 5
        packed = packed_payload(amount, token_id, block_hash, log_index)
        params = forge_params(amount, token_id, block_hash, log_index,
                              [[first_signer_id, first_signer_key.sign(packed)]])

        res = self.contract.minter(params).interpret(storage=storage(),
                                                     sender=first_signer_key.public_key_hash(),
                                                     chain_id=chain_id)

        self.assertEqual(1, len(res.operations))
        user_mint = res.operations[0]
        self.assertEqual(minter_contract, user_mint["destination"])
        self.assertEqual(michelson_to_micheline(minter_call(amount, token_id, block_hash, log_index)),
                         user_mint['parameters']['value'])

    def test_accepts_several_valid_signature(self):
        amount = 10000000
        token_id = b"contract_on_eth"
        block_hash = b"txId"
        log_index = 3

        packed = packed_payload(amount, token_id, block_hash, log_index)
        params = forge_params(amount, token_id, block_hash, log_index, [
            [first_signer_id, first_signer_key.sign(packed)],
            [second_signer_id, second_signer_key.sign(packed)]
        ])

        res = self.contract.minter(params).interpret(storage=storage_with_two_keys(),
                                                     sender=first_signer_key.public_key_hash(),
                                                     chain_id=chain_id)

        self.assertEqual(1, len(res.operations))
        user_mint = res.operations[0]
        self.assertEqual(minter_contract, user_mint["destination"])
        self.assertEqual(michelson_to_micheline(minter_call(amount, token_id, block_hash, log_index)),
                         user_mint['parameters']['value'])

    def test_accepts_minting_even_with_bad_signature_if_threshold_is_reached(self):
        amount = 10000000
        token_id = b"contract_on_eth"
        block_hash = b"txId"
        log_index = 3

        packed = packed_payload(amount, token_id, block_hash, log_index)
        bad = packed_payload(amount, token_id, block_hash, log_index + 1)
        params = forge_params(amount, token_id, block_hash, log_index, [
            [first_signer_id, first_signer_key.sign(packed)],
            [second_signer_id, second_signer_key.sign(bad)]
        ])

        res = self.contract.minter(params).interpret(storage=storage_with_two_keys(threshold=1),
                                                     sender=first_signer_key.public_key_hash(),
                                                     chain_id=chain_id)

        self.assertEqual(1, len(res.operations))
        user_mint = res.operations[0]
        self.assertEqual(minter_contract, user_mint["destination"])
        self.assertEqual(michelson_to_micheline(minter_call(amount, token_id, block_hash, log_index)),
                         user_mint['parameters']['value'])

    def test_rejects_bad_signature(self):
        with self.assertRaises(MichelsonRuntimeError) as context:
            token_id = b"contract_on_eth"
            block_hash = b"txId"
            log_index = 3
            packed = packed_payload(10, token_id, block_hash, log_index)
            params = forge_params(299, token_id, block_hash, log_index,
                                  [[first_signer_id, first_signer_key.sign(packed)]])

            self.contract.minter(params).interpret(storage=storage(),
                                                   sender=first_signer_key.public_key_hash(),
                                                   chain_id=chain_id)
        self.assertEquals("BAD_SIGNATURE", context.exception.message)

    def test_rejects_unknown_minter(self):
        with self.assertRaises(MichelsonRuntimeError) as context:
            token_id = b"contract_on_eth"
            block_hash = b"txId"
            log_index = 3
            packed = packed_payload(10, token_id, block_hash, log_index)
            params = forge_params(299, token_id, block_hash, log_index,
                                  [[second_signer_id, first_signer_key.sign(packed)]])

            self.contract.minter(params).interpret(storage=storage(),
                                                   sender=first_signer_key.public_key_hash(),
                                                   chain_id=chain_id)
        self.assertEquals("SIGNER_UNKNOWN", context.exception.message)

    def test_rejects_threshold(self):
        with self.assertRaises(MichelsonRuntimeError) as context:
            token_id = b"contract_on_eth"
            block_hash = b"txId"
            log_index = 3
            packed = packed_payload(10, token_id, block_hash, log_index)

            params = forge_params(299, token_id, block_hash, log_index,
                                  [[first_signer_id, first_signer_key.sign(packed)]])

            self.contract.minter(params).interpret(storage=storage_with_two_keys(),
                                                   sender=first_signer_key.public_key_hash(),
                                                   chain_id=chain_id)
        self.assertEquals("MISSING_SIGNATURES", context.exception.message)

    def test_admin_can_change_quorum(self):
        new_quorum = [2, {second_signer_id: second_signer_key.public_key()}]
        res = self.contract.change_quorum(new_quorum).interpret(
            storage=storage(),
            sender=first_signer_key.public_key_hash())

        self.assertEquals({second_signer_id: second_signer_key.public_key()}, res.storage['signers'])
        self.assertEquals(2, res.storage['threshold'])

    def test_non_admin_cant_change_quorum(self):
        with self.assertRaises(MichelsonRuntimeError) as context:
            new_quorum = [1, {second_signer_id: second_signer_key.public_key()}]
            self.contract.change_quorum(new_quorum).interpret(
                storage=storage(),
                sender=second_signer_key.public_key_hash())
        self.assertEquals("NOT_ADMIN", context.exception.message)

    def test_admin_can_change_threshold(self):
        res = self.contract.change_threshold(2).interpret(
            storage=storage_with_two_keys(),
            sender=first_signer_key.public_key_hash())

        self.assertEqual(2, res.storage["threshold"])

    def test_rejets_transaction_with_amount(self):
        with self.assertRaises(MichelsonRuntimeError) as context:
            new_quorum = [2, {second_signer_id: second_signer_key.public_key()}]
            self.contract.change_quorum(new_quorum).interpret(
                storage=storage(),
                sender=first_signer_key.public_key_hash(),
                amount=10)
        self.assertEquals("FORBIDDEN_XTZ", context.exception.message)

def forge_params(amount, token_id, block_hash, log_index, signatures):
    mint_dict = {"amount": amount, "owner": owner, "token_id": token_id,
                 "event_id": {"block_hash": block_hash, "log_index": log_index}}
    return {
        "signatures": signatures,
        "action": {"entry_point": {"mint_token": mint_dict}, "target": f"{minter_contract}"}
    }


def minter_call(amount, token_id, block_hash, log_index):
    return f"(Right (Pair (Pair {amount} (Pair 0x{block_hash.hex()} {log_index})) (Pair \"{owner}\" 0x{token_id.hex()})))"


def packed_payload(amount, token_id, block_hash, log_index):
    call = minter_call(amount, token_id, block_hash, log_index)
    payload_value = michelson_to_micheline(f"(Pair "
                                           f"   (Pair \"{chain_id}\" \"{repl_generated_contract_address}\")"
                                           f"   (Pair {call} \"{minter_contract}\")"
                                           f")")
    return pack(payload_value, payload_type)


def storage():
    return {
        "admin": first_signer_key.public_key_hash(),
        "threshold": 1,
        "signers": {
            first_signer_id: first_signer_key.public_key()
        },
        "metadata": {}
    }


def storage_with_two_keys(threshold=2):
    return {
        "admin": first_signer_key.public_key_hash(),
        "threshold": threshold,
        "signers": {
            first_signer_id: first_signer_key.public_key(),
            second_signer_id: second_signer_key.public_key()
        },
        "metadata": {}
    }


if __name__ == '__main__':
    unittest.main()
