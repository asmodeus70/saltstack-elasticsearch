# saltstack-elasticsearch
Salt formula to deploy ELK stack 2.x

This formula was created to stand up an ELK stack quickly on a single system. There's no clustering or anything fancy and it does exactly what it says on the tin.

There are probably loads of bits that can be improved upon or generaly tidied up, but that's for a later date.

I've done a bit of work in this so that you no longer need to supply your own java zip file ;-)

It also now uses the Salt firewalld module to configure and run the firewall config. 

I should also say that the kibana login details are.....

User: admin


Password: letmein

You might want to change those...lol

Enjoy.
