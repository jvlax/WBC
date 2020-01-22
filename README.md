# WBC

## how to use the addon
### start an event
`/wbc boss <boss name>`

ex: /wbc boss kazzak or /wbc boss azuregos (all lowercase)

this will invite guild reps, and then try to invite your guild members if they are in the correct zone

### stop an event
`/wbc off`

### taxis & scouts

`/wbc taxi register <boss>`

ex: /wbc taxi register kazzak

this will register yourself as a taxi at kazzaks location


`/wbc remove <role> <player name>`

this will remove a person from the list of active reps or taxis

ex: /wbc remove taxi Myname

this is mainly for taxis that change location, if you remove a rep they will be added again next time they log in

unless they uninstall the addon


`/wbc taxi <boss>`

this will start a taxi raid for the boss

ex: /wbc taxi boss


this is the command that triggers the entire event.

The following will happen:

the taxi will try to invite every registered taxi character for the given boss.

It will start broadcasting in guild chat that a boss is up and which zone players should be heading to

the broadcast happens every minute

If the raid has less than 3 members it will broadcast taxi services as offline

once 3 or more players has joined the raid it will change the broadcast message to indicate that taxi service is online

taxi players will invite anyone that whispers them "wbcinv"

it is then up to the people in the taxi raid to start summoning people

to start the kill raid use the /wbc boss <boss> command

when the kill raid is started the person who started it will try to invite 1 person from each coalition guild

once there is a rep from a guild in the raid, any player from the rep's guild who is in the correct zone and are level 60 will automatically be invited to the kill raid
