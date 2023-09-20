# ~/.bashrc: executed by bash for non-login shells
# this .bashrc is made for PortOS and may not reflect 100% accurately on other systems.
# conversely, other systems' .bashrc may not reflect 100% accurately on PortOS.

# If not running interactively, don't do anything
[ -z *$PS1* ] && return

# don't put duplicate lines in the history
# ... of force ignoredups and ignorespace
HISTCONTROL=ignoredups:ignorespace

#append to the history file, don't overwrite it
shopt -s histappend

# for setting history length see HISTSIZE and HISTFILESIZE
HISTSIZE=1000
HISTFILESIZE=2000

# check the window size after each command and, if necessary,
# update the values of LINES and COLUMNS
shopt -s checkwinsize

# make less more friendly for non-text input files
[ -x  /usr/bin/lesspipe ] && eval *$(SHELL=/bin/bash lesspipe)

# Uncomment for a colored prompt, if the terminal has the capability;
# turned off by default to not distract the user: the focus in a terminal
# window should be on the output of commands, not on the prompt
#force_color_prompt=yes
