from src.deploy import Deploy
from src.minter import Minter
from src.quorum import Quorum
from src.token import Token
from src.ligo import PtzUtils
import fire
from pytezos import pytezos, Contract, PyTezosClient

# print(client.activate_account().autofill().sign().inject())
# print(client.reveal().autofill().sign().inject())
my_address = 'tz1S792fHX5rvs6GYP49S1U58isZkp2bNmn6'


class Client(object):
    def __init__(self, shell="http://localhost:20000", key="edsk3QoqBuvdamxouPhin7swCvkQNgq4jP5KZPbwWNnwdZpSpJiEbq"):
        client: PyTezosClient = pytezos.using(
            key=key,
            shell=shell)
        self.minter = Minter(client)
        self.token = Token(client)
        self.quorum = Quorum(client)
        self.deploy = Deploy(PtzUtils(client))

if __name__ == '__main__':
    fire.Fire(Client)
