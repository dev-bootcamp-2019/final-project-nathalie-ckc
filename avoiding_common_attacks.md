# Avoiding Common Attacks

## Reentrancy

Use withdrawal design pattern.  

Use address.transfer() instead of address.call.value() to limit the gas to any
fallback function.

## Overflow/underflow
Use OpenZeppelin SafeMath library.

# Additional security measures

* Circuit breaker
* Access restriction by role
* Require() statements to check input data

# Future work

I have some other ideas to improve the security, which I didn't have time
to implement:

* Lock: We don't want buying of widgets and changing of unit price to be
happening at the same time.  Or, having multiple customers trying to buy
widgets from the same bin when there isn't enough stock to fulfill all the
purchases isn't good either.  Could try to add a lock, so that the other
transactions have to wait for the one in progress to complete.

* Separate Finance role: The Admin role is very powerful, so a target of
hacking.  Separate out the ability to withdraw funds into a finance role.
This spreads out the power among accounts.

* Input validation in the UI: Currently, input validation only takes place at
the contract level, using "require()" statements.  Stop bad data before it even
gets to try to interact with the blockchain. For example, the Admin role enters
strings.  An improvement would be to limit the length of the string in the UI.

* Run security analysis tools and find out what vulnerabilities I wasn't
aware of.
