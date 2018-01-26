# wepower-contracts

WePower Ethereum smart contracts

# Deployment Procedure
Kovan Deployed Contracts

Contracts can be deployed in this order.

1. MiniMe TokenFactory

https://kovan.etherscan.io/address/0xB0bdcfAd10d28Bb31069770AF89Aae4a8A38e31e

2. WCT2

https://kovan.etherscan.io/address/0x588214e66ac44088756cF76D3D7Fbc1B3DfD7e7F

3. Investor Wallet Factory

https://kovan.etherscan.io/address/0xa9887449Ed55e141Ec8Aeaa6EC0451fe28600AF7

4. WCT1

https://kovan.etherscan.io/address/0x1F39a761abB2E6A27F1364615158f8861fC5898e

5. WPR

https://kovan.etherscan.io/address/0xD26AEFea68E44A9EC99318BAFc8d27aF69794185

6. Contribution

https://kovan.etherscan.io/address/0x19A2a93388783bcEf588070FE15E7eD883117e32

7. Exchanger

https://kovan.etherscan.io/address/0x2658C4517FA026Cd90FafaFDfC533A75e3Cf6145

8. Team Token Holder

https://kovan.etherscan.io/address/0x39314D580dFF71f3FED0eC385Dc43C65F3Fb0E4C

9. Future Token Holder

https://kovan.etherscan.io/address/0xdDF16b9d7AfeC54239B9c43b2b16B52bbA71293F

## Setup

Investor Wallets should be created before the crowdsale is initialized. Once the Contribution is finalized, ownership of the WPR token is transferred to the owner of Contribution contract. The owner should then `unpause` the WPR token so that the investor wallets can `collectTokens` after their vesting period is over.

### Create Investor Wallets

- Call changeController on the WCT2 token and change the controller to the address of the Investor Wallet Factory
- Call createInvestorWallet on the Investor Wallet Factory

### Initialize Crowdsale

- Call setExchanger on the Investor Wallet Factory with the address of the deployed Exchanger contract
- Call transferOwnership on the WPR token and set the newOwner to the address of the Contribution contract
- Call initialize on the Contribution contract to start the crowdsale

## Notes

- Investor wallets can not collect their tokens until the Contribution has been finalized. The WPR token will be paused, so the owner must `unpause` the token before the investor wallets will be able to collect tokens.

