# saltstack-elasticsearch
Salt formula to deploy ELK stack 2.x

This formula was created to stand up an ELK stack quickly on a single system. There's no clustering or anything fancy and it does exactly what it says on the tin.

There are probably loads of bits that can be improved upon or generaly tidied up, but that's for a later date.

At the moment this formula relies on a zip file being located in "elasticsearch/files" directory in order to install java. The zip file has been ommited from this project because it will get outdated very quickly and it was rather large!

So you can either modify the init.sls to pull the latest version from the web or just download your version of choice and modify the init.sls accordingly.

I should also say that the kibana login details are.....

User: admin


Password: letmein

You might want to change those...lol

Enjoy.
