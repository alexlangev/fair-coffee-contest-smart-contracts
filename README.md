# Blockchain-based Coffee chain Contest system

## Technologies Used

### Development
- The smart contracts aure written in Solidity v0.8.18.
- Foundry is used as the Solidity framework used in development and testing.
- OpenZeppelin contracts are used for the token implementation and access control logic.
- The foundry-devops library is used for streamlining deployment in test environments.

### Layer 2?
- Chainlink Datafeeds is used to get the latest eth/usd conversion price. 
- Chainlink VRF is used to get a source of randomness. This is used to determine is users either instantly win small prizes or win the daily lottery.
- Chainlink automation is used to perform the time-based actions such as picker a daily lottery winner and reseting the lottery for the next one and also closing the contest after 30 days.

### testing
- All unit and intergration test use Foundry.
- Fuzz test are written with Echidna.
- Static analysis was performed with Slither.

## Features
1. Users can buy one to five coffees per transaction. Coffees are alway 1.50$ USD and the smart contract uses a chainlin procefeed to convert this in Ether.

2. Buying a coffee gives the user a contest participation. Under the hood, this is a random word provided by a Chainlink VRF.

3. Users that want to paricipate to the contest can then redeem their participations. Doing this this, they have a 10% chance to instantly win a free coffee token and 10% chance to win a free Donut token.

4. There free coffee and free donut token are ERC20 token with a finite suply of 50 000. Once the supplies are gone, no user can win aymore.

5. Users that are not winners of a free coffee or free donut automatically enter a daily lottery. 

6. Each 24h, a winner is selected from the daily lottery participants and is awarded 5% of the daily coffee purchases total. 

7. Users can choose when they want to redeem their coffees meaning they can buy a coffee on monday but only redeem their participation on saturday, as long asthe contest is still running.

8. Each instant win for a free donut and free coffee is equiprobable for users at 10% each and they can't win both at the same time. When the supllies of free coffe and donuts run out, only the daily lottery will be active. 

9. Once the contest is closed after 30 days no users can redeem participations.

## Setup and Installation

forge install
forge compile

## Usage

## Testing

forge test

## Future improvements/Features

1. First and foremost, a good frontend is needed.

2. I would like to lottery winners to have to accept their prizes within a certain timeframe. If they do not accept in time, another user will be selected as winner. This way, if a user looses its keys and win, the funds are not lost but go to someone else.

3. Instead of having a ether prize for the daily lottery, I would add a stablecoin prize instead. This way, if the market varies during the contest, all users would theortically gain the same prize value.

## Acknowledgements
openzeppelin for standerdizing how to build web3.
chainlink for building cool stuff.
patrick alpha.
trail of bits for build great security tools.
  
## License
MIT, do want you want with it!