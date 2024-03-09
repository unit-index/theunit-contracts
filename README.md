The Unit Contracts for Testnets

### How to Deploy

1. Deploy UN - MULTISIG=<Address> npm run deploy:token:sepolia
2. Mint UN - TO=<Address> AMOUNT=<amount(ether)> npm run mint:token:sepolia
3. Bridge UN to Arbitrum Sepolia - https://bridge.arbitrum.io
4. Set bridgedUN to the bridged address in Base.s.sol
5. Deploy a test collateral token on Arbitrum Sepolia - TO=<Address> AMOUNT=<amount(ether)> npm run deploy:collateral:arbitrumSepolia
6. Set WBTC_TEST_ARBITRUM_SEPOLIA to the address deployed at step 5. 
7. npm run deploy:vault:arbitrumSepolia to deploy the TINU, price feed and the vault contract
8. Set the eth and btc price feed in frontend cron and config
9. npm run deploy:ticket:arbitrumSepolia to deploy the TicketFactory for bridged UN
9. npm run generate:arbitrumSepolia to generate the contracts.json needed in frontend