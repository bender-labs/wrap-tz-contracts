import unittest

from pytezos import Key, michelson
from pytezos.michelson.micheline import michelson_to_micheline
from pytezos.michelson.pack import pack

from src.ligo import LigoContract

minter_ep = """ (or %entry_point
                 (unit %add_token_by_signers)
                 (pair %mint_token
                    (pair (nat %amount) (address %owner))
                    (pair (string %token_id) (string %tx_id))))""".replace("\n", "")
payload_type = michelson_to_micheline(f"(pair (pair chain_id address) (pair {minter_ep} address))")

# ugly. There is no way to patch the repl with SELF address. So here is the one it
# generates the first time it is called
repl_generated_contract_address = "KT1BEqzn5Wx8uJrZNvuS9DVHmLvG9td3fDLi"


class MyTestCase(unittest.TestCase):

    @classmethod
    def setUpClass(cls) -> None:
        cls.contract = LigoContract("../ligo/quorum/multisig.religo", "main").get_contract()

    def test_accepts_valid_signature(self):
        owner = "tz1S792fHX5rvs6GYP49S1U58isZkp2bNmn6"
        minter_contract = "KT1VUNmGa1JYJuNxNS4XDzwpsc9N1gpcCBN2%signer"
        amount = 10000000
        token_id = "contract_on_eth"
        tx_id = "txId"
        chain_id = "NetXm8tYqnMWky1"
        mint = f"(Right (Pair (Pair {amount} \"{owner}\") (Pair \"{token_id}\" \"{tx_id}\")))"
        payload_value = michelson_to_micheline(f"(Pair "
                                               f"   (Pair \"{chain_id}\" \"{repl_generated_contract_address}\")"
                                               f"   (Pair {mint} \"{minter_contract}\")"
                                               f")")
        packed = pack(payload_value, payload_type)

        key = Key.generate(curve=b'sp', export=False)
        mint_dict = {"amount": amount, "owner": owner, "token_id": token_id,
                     "tx_id": tx_id}
        params = {
            "signatures": [["ipns1", key.sign(packed)]],
            "action": {"entry_point": {"mint_token": mint_dict}, "target": f"{minter_contract}"}
        }
        self.contract.address = "tz1S792fHX5rvs6GYP49S1U58isZkp2bNmn6"
        self.contract.minter.address = "tz1S792fHX5rvs6GYP49S1U58isZkp2bNmn6"

        res = self.contract.minter(params).interpret(storage=storage(key),
                                                     sender=key.public_key_hash(),
                                                     chain_id=chain_id)

        self.assertEqual(1, len(res.operations))
        user_mint = res.operations[0]
        self.assertEqual(minter_contract, user_mint["destination"])
        self.assertEqual(michelson_to_micheline(mint),
                         user_mint['parameters']['value'])


def storage(key: Key):
    return {
        "admin": key.public_key_hash(),
        "threshold": 1,
        "signers": {
            "ipns1": key.public_key()
        }
    }


if __name__ == '__main__':
    unittest.main()
