# About this project 

This toolkit will be a suite of utilities for manipulating large
monolithic sudoers files, inspired by the needs of one of my clients.

## About the naming convention

In the spirit of my love for martial arts, I've decided to name
this toolkit "sudo ninja" with the individual utilities named
after either a tool, art, or technique during development. 

While the art I practice is Tae Kwan Do, I decided to go with a
ninjutsu theme because ninja terminology is better known in
popular culture and the vocabulary is more expansive.

These were working names during the development cycle but now are in beta, being
mostly feature-complete. The utilities that are included in the initial (v0.9)
release have been renamed to their final name. 

Work on sudo chōhō will come later, with details TBA. chōhō will be primarily 
a read-only utility designed for reporting.

### Renaming the utilities

Now that this utility is about to enter production the utilities have been
renamed according to purpose and role. 

# sudo-chop.sh

Not this file.

Chops, slices, dices, splits, and reassembles sudoer files, and flattens multiline 
sudoer rules, and also removes expired rules. 

This utility takes multiline sudoers aliases and rules and flattens them, splits
the file into shunks for further processing by sudo-cleanup, and deletes 
expired rules, and leverages visudo to verify syntactic integrity of the file.

# sudo-cleanup.sh

Also not this file. ;) 

Seeks, relocates, destroys. 

This utility can delete an individual user or batch delete users by comparing 
against an active account list. It can also strip comments from a sudoers file 
and will also clean up any orphaned aliases or rules, and leverages visudo to 
verify syntactic integrity of the file. 

# README.md

This file you are reading right now. ;)

# Roadmap / Coming features

**--expirenewer** _YYYY-MM-DD_ 

This will define the earliest date that the utility will reap -- this is 
to help organizations with very old, unmaintained monolithic sudoers file, from
inadvertently deleting contractors who have been hired on as permanent employees,
or deleting long-term contractors who are still on board.

**--expireolder** _YYYY-MM-DD_

Currently the utility is expecting an EXP YYYY-MM-DD string in a comment preceding
the block of rules that the expiration applies to. --expire would ideally accept
a string so that the tag could be "Expire" or "END" or whatever locale-specific
language you choose to use to precede the expiry date. 

**--expire** _EXPIRATION_TAG_

Currently **--expire** assumes expiration tags are indicated by the string "EXP"
followed by a date (e.g., "EXP 2025-11-15"). If no argument to **--expire** is
provided, the tool will use "EXP" as the default,


Man pages and RPM will be coming by the end of the year.

## About Coding style 

I tend to append semicolons to the end of each line - with my history as a release
engineer it was habit, and also many of my utilities started out as one-liners, and
I regularly pull code snippets out of longer scripts/programs and compress them 
into one-liners when I was a sysadmin at a large hosting company. So, I decided 
to write my utilities with semicolons at the end of commands whenever possible, 
so that if you, the end user, ever find a need to pull some of the code and 
compress it into a one-liner (such as in a cron job for example, or to fix a 
customer's box) it's that much easier for you use a code snippet in a one-liner
script.

I also make use of camel notation with the first "word" being a typing hint, 
because even though bash does not enforce type, it does make the code relatively
self-documenting and more understandable when taking a snippet and repurposing
it.

Also: I_LOATHE_ALL_CAPS_CONSTANTS_OR_VARIABLES_BECAUSE_WHY_ARE_WE_YELLING?



# Current Status: 

The utility is entering production but development will be ongoing for some 
weeks to come. 


