# ConsensysDevAcademyQ4CY18_project

## Idea
ACME Widget Company is a manufacturer that puts its widgets through a barrage of testing before each widget is sold.  Based on the testing, the widgets are "binned" so that widgets that meet better functionality and performance levels can be sold at a higher price (e.g. If widget 12345 can meet max performance from -50C to +150C, it is binned as a more expensive grade than if it could only meet max performance from -25C to +100C).  

ACME has factories, testing teams, and sales distributors worldwide.  So, it can be tricky to keep track of which widgets came from which factory and passed/failed what tests.  

Aside from knowing how to bin the widgets for pricing, keeping track of the test results long-term is an important problem because a small number of widgets may fail after they have been deployed "in the wild" by ACME's customers.  The ACME distributors would want to be able to look back at which factory, which test site, and what tests passed/failed for those widgets that failed "in the wild" and analyze that data in the context of the widget use case of their customer.

Using a DApp to track these widgets is an ideal application of the blockchain, because we want to co-ordinate information across multiple parties and also have an immutable record of the test results.

ACME is not concerned about publishing their widget test data on a public blockchain because their products are manufactured with the highest quality and their company has a core value of transparency to their customers.

## User Stories

For the scope of this project, we'll just test with 2 Admins (deployer + another Admin), 1 Tester, 1 Sales distributor, and a  Customer.

### Admin
Admin registers individuals in role of Tester, Sales distributor, or Customer.

Admin can trigger the circuit breaker if it looks like a customer is trying to steal widgets by hacking.

### Tester
Tester records factory the widget came from, the test site, and the test results.

### Sales distributor
Sales distributor has the ability to update the unit price for each bin and the test mask that maps test results into a given bin.

### Customer
Customers buy widgets with Ether.

## How to set up the Truffle project on local dev server

### Prerequisites

This is what I tested with.  If you test with a different system, your mileage may vary:
* VirtualBox VM running Ubuntu 18.10 with 4MB RAM, 64 MB video memory
* NodeJS v11.2.0
* npm 6.4.1
* truffle v4.1.14
* Ganache CLI v6.2.3 (ganache-core: 2.3.1)
* Web browser with MetaMask

### Steps

#### Local development server

##### 1) Clone the repository
```
git clone https://github.com/nathalie-ckc/ConsensysDevAcademyQ4CY18_project.git
```

##### 2) Get into the folder and make sure you are on master branch
```
cd ConsensysDevAcademyQ4CY18_project/
git checkout master
```

##### 3) Use NPM to install the necessary packages
```
npm install
```

##### 4) Start Ganache CLI
Open a new terminal in the project directory
```
ganache-cli
```
My project assumes that it's set up for port 8545 (per the course project requirements).  You should see this line in your Ganache CLI terminal:
```
Listening on 127.0.0.1:8545
```

##### 5) Run the automated truffle tests
```
truffle test
```
You should see transactions and blocks being reported in your Ganache CLI terminal.  The test results should look something like this:
![Truffle test results screenshot](images/truffle_test_results.png "Sample truffle test results")

##### 6) Interact manually with the User Interface in a web browser
If you look at the project directory before running the next command, it will look like:
![Project dir before truffle compile](images/ls_before.png "ls Before truffle compile")
Now, compile the project in truffle.  (The earlier 'truffle test' did a cleanroom test, so we don't have the build artifacts from that lying around.)
```
truffle compile
```
Now you will see a 'build' directory appear in the project directory:
![Project dir after truffle compile](images/ls_after.png "ls After truffle compile")
Next, we will deploy the dapp to the Ganache CLI development blockchain.
```
truffle migrate
```
The output should look something like this:
![Truffle migrate output](images/truffle_migrate_output.png "Sample truffle migrate output")
Next, we will use lite-server to serve up the web User Interface.
```
npm run dev
```
The web browser will pop up and Metamask will ask you to log in.
![Metamask login](images/metamask_login.png "Metamask login screen pops up")
Then Metamask will ask for your approval. Click Approve button.
![Metamask approval](images/metamask_approval.png "Metamask approval screen pops up")

#### Rinkeby

.env file

Infura

Accounts 1 to 5 based on the mnemonic in your .env with Rinkeby testnet ether (Can request the max from faucet to one account & then send it to the other accounts).  Account 1 should have the max, and it's probably sufficient to transfer just 2 ETH to each of the others, for basic testing.

## Library Used
OpenZeppelin SafeMath
