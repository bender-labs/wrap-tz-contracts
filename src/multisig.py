from io import TextIOWrapper
from subprocess import Popen, PIPE

from pytezos import Contract, PyTezosClient


def compile_contract():
    command = f"ligo compile-contract ./ligo/multisig/multisig.religo main"
    compiled_michelson = _ligo_to_michelson(command)
    return Contract.from_michelson(compiled_michelson)


def _ligo_to_michelson(command):
    with Popen(command, stdout=PIPE, stderr=PIPE, shell=True) as p:
        with TextIOWrapper(p.stdout) as out, TextIOWrapper(p.stderr) as err:
            michelson = out.read()
            if not michelson:
                msg = err.read()
                raise Exception(msg)
            else:
                return michelson


class Multisig(object):
    def __init__(self, client: PyTezosClient):
        self.client = client

    def originate(self, signer1, signer2):
        app = compile_contract()
        print(app.storage)
        initial_storage = app.storage.encode({
            "counter": 0,
            "threshold": 1,
            "signers": {
                "deux": signer1,
                "un": signer2
            }
        })
        print(initial_storage)
        opg = self.client.origination(script={'code': app.code, 'storage': initial_storage}).autofill().sign()
        contract_id = opg.result()[0].originated_contracts[0]
        opg.inject()
        print(
            f'Successfully originated {contract_id}\n'
            f'Check out the contract at https://you.better-call.dev/delphinet/{contract_id}')

    def mint(self, contract_id, signature):
        contract = self.client.contract(contract_id)
        mint = {"amount": 100, "owner": "tz1S792fHX5rvs6GYP49S1U58isZkp2bNmn6", "token_id": "contract_on_eth",
                "tx_id": "txId"}
        print(contract.call)
        op = contract \
            .call(counter=0, signatures=[["deux", signature]], multisig_action={"signer_operation": {
            "parameter": {"mint_token": mint}, "target": "KT1VUNmGa1JYJuNxNS4XDzwpsc9N1gpcCBN2%signer"}}) \
            .inject()
        print(op)
