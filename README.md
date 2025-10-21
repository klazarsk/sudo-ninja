# About this project 

This toolkit will be a suite of utilities for manipulating large
monolithic sudoers files, inspired by the needs of one of my clients.

## About the naming convention

In the spirit of my love for martial arts, I've decided to name
this toolkit "sudo ninja" with the individual utilities named
after either a tool, art, or technique.

While the art I practice is Tae Kwan Do, I decided to go with a
ninjutsu theme because ninja terminology is better known in
popular culture and the vocabulary is more expansive.

## About my coding style 

I tend to append semicolons to the end of each line - with my history as a release
engineer it was habit, and also many of my utilities started out as one-liners, and
I regularly pull code snippets out of longer scripts/programs and compress them 
into one-liners when I was a sysadmin at a large hosting company. So, I decided 
to write my utilities with semicolons at the end of commands whenever possible, 
so that if you, the end user, ever find a need to pull some of the code and 
compress it into a one-liner (such as in a cron job for example, or to fix a 
customer's box, it's that much easier for you use a code snippet in a one-liner
script.

I also make use of camel notation with the first "word" being a typing hint, 
because even though bash does not enforce type, it does make the code relatively
self-documenting and more understandable when taking a snippet and repurposing
it.

Also: I_LOATHE_ALL_CAPS_CONSTANTS_OR_VARIABLES_BECAUSE_WHY_ARE_WE_YELLING?

# sudo-katana

Not this file.

Chops, slices, dices, splits, and reassembles sudoer files, and flattens multiline 
sudoer rules, and also removes expired rules. 

# sudo-taijutsu.sh

Also not this file. ;) 

Seeks, relocates, destroys. 

# sudo-choho.sh

Named for the Ninja art of chōhō, or espionage.

Sudo espionage! Analyze, report on, and dink around 
with sudoer files. Do nifty stuff like count how many times
a user appears in the sudoers file! 

..and you guessed it. Also not this README.md file.

This is currently GNDN (goes nowhere, does nothing); I only threw a few code 
fragments in for a placeholder for reporting ideas I've been kicking around.
This utility will/may come later but is out of scope for the project which 
inspired this toolkit.

# README.md

This file you are reading right now. 



# Current Status: 

Right now these utilities are very dangerous at times and should not be used for 
anything except for effing up a system. Realistically, sudo-chopper works very well on 
initial checkin, but: 

a) not all features are implemented yet

b) Some upcoming feature changes will temporarily break things horribly

# Bottom Line:

As I am making it extremely clear that these utilities are not yet feature-complete 
and I am working against the main branch because this was inspired by a specific project,
no one else is using these and therefore there is no risk in checking in broken code at
this time.

How to determine whether or not you are sane: Are you using this utility before I let you 
know it's ready for testing? Whether or not you are sane, is the inverse of this question. 

Actual documentation will be forthcoming later in the project. 

