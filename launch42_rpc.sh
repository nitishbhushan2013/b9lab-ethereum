
#geth --datadir ~/Library/Ethereum/net42 --networkid 42 console 

geth --datadir ~/Library/Ethereum/net42 --networkid 42 --rpc --rpcaddr 0.0.0.0 --rpcport 8545 --rpccorsdomain "*" --rpcapi "eth,web3,net" 