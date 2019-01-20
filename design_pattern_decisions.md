# Design Pattern Decisions

## Design Patterns Used

### Circuit breaker (Emergency stop)
If hack is detected, prevent any more widgets from being sold.

### Withdrawal
Don't send out funds from the contract.  Let the funds accumulate and then
allow a privileged user (Admin) to withdraw the funds to their account when
they choose to do so.

### Events

The contract emits events whenever a change of state occurs.

My front-end skills are very beginner, so I didn't do much with the events.  
However, having the events emitted would allow for the front-end to react
based on the emitted events.  And, I indexed parameters that I thought would
be useful, so that they can be used for filtering.

### Access restriction

Assign roles to certain accounts and they have access to only certain
functionality.  
e.g. The Admin is the one with ability to withdraw funds from contract.
e.g. The tester can only record test results.
