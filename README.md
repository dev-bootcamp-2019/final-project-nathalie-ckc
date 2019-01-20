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


## Library Used
OpenZeppelin SafeMath
