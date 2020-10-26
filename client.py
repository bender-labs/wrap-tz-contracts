from io import TextIOWrapper
from subprocess import Popen, PIPE
from src.bender import Bender
from src.token import Token

import fire
from pytezos import pytezos, Contract, PyTezosClient

# print(client.activate_account().autofill().sign().inject())
# print(client.reveal().autofill().sign().inject())
my_address = 'tz1S792fHX5rvs6GYP49S1U58isZkp2bNmn6'


class Client(object):
    def __init__(self):
        client: PyTezosClient = pytezos.using(
            key='~/workspaces/tezos/wallets/tz1S792fHX5rvs6GYP49S1U58isZkp2bNmn6.json',
            shell='delphinet')
        self.bender = Bender(client)
        self.token = Token(client)


if __name__ == '__main__':
    fire.Fire(Client)
