# kernighanlin
 kernighan lin TSP solving demonstrated in Processing

https://en.wikipedia.org/wiki/Kernighan%E2%80%93Lin_algorithm

Find a short line through a set of points.

For any set of points {...a,b....c,d...} measure if {...a,c...b,d...} is shorter.
if more than one shorter route is found, pick the one that makes the greatest impact.
the picked route then reverses section b through c {...a,c....b,d...}.
Repeat until there are no more ways to shorten the set.