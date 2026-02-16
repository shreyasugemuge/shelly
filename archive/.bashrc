#!/bin/bash
# Author: Shreyas Ugemuge
# Email: shreyas@ugemuge.com

# Default editor, set to emacs because
# that is the only CLI editor you should
# be using
export NVM_DIR="$HOME/.nvm"
  . "/usr/local/opt/nvm/nvm.sh"

pwd_mongo="ACtbJRdvcUld9Tan"

export EDITOR="/usr/local/bin/emacs"
export LANGUAGE="ENGLISH"
export GPG_TTY=$(tty)

#hk-auto
alias ha_ec2="ssh ec2-user@35.171.157.34"
alias kali="ssh -i \"uge_mac.pem\" root@ec2-13-235-68-207.ap-south-1.compute.amazonaws.com"

# Prompt Building and setting
# Colored braces
lBrace="\[\e[0;37m\]["
rBrace="\[\e[0;37m\]]"
# Part 1
# Display [-_-] in green if previous command was successful (error code=0)
# Display [O_O] in red if previous command was successful (error code!=0)
codeZero="\$? = 0"
zeroFace="\[\e[33m\]-_-\[\e[0m\]"
errFace="\[\e[31m\]O_O\[\e[0m\]"
face="\`if [ "$codeZero" ]; then echo "$zeroFace"; else echo "$errFace"; fi\`"
part1=""$lBrace""$face""$rBrace""
# Part 2
# Display [current directory]
curDir="\[\e[0;36m\]\w"
part2=""$lBrace""$curDir""$rBrace""
# Part 3
# Display [Host:user]
hostHelp="\[\e[0;32m\]\H"
userHelp="\[\e[0;33m\]\u"
part3=""$lBrace""$hostHelp"\[\e[0;36m\]:"$userHelp""$rBrace""
# Part 4
# A $ on the next line
part4="\n\$ \[\e[0m\]"
# put together and export prompt
PROMPTHELPER=""$part1""$part2""$part3""$part4""
export PS1=$PROMPTHELPER

# shortcut for bashrepo
alias bashgit='open https://github.com/shreyasugemuge/bash -a safari'

# yell
alias yell='figlet'

#script
alias dload='~/scripts/download-site.sh'

# push this to the repo
# the repopath can be changed
REPOPATH="/Users/shreyasugemuge/some_git_repos/bash"
BRC=".bashrc"
BNT=".bash_net"
function updaterc()
{
    echo "Copying files to local repo folder"
    cat $BRC > $REPOPATH/.bashrc
    cat $BNT > $REPOPATH/.bash_net
    echo "Staging files"
    cd $REPOPATH
    git add .
    git commit 
    git push
    cd ~

}

# open this
alias bashrc='emacs ~/.bashrc'
alias bashnet='emacs ~/.bash_net'

# fancy stuff
#figlet -c hello shreyas | pv -qL 550 | lolcat
#fortune -s | cowsay -f tux
alias ItsSanketsBirthday='./scripts/sanket.sh'

# directory shortcut
alias ntwrkprog='cd /Users/shreyasugemuge/Desktop/collegestuff/network\ prog\ -\ CSE\ 4232' 

# quick hacks
alias ..='cd ..'
alias rm='rm -ir'
alias refresh='source ~/.bashrc'
function pan()
{ # opens a man Page in a pdf in preview
   man -t "$1" | open -f -a /Applications/Preview.app
}

#ls commands
alias ls='ls -h'
alias la='ls -ah'
alias ll='ls -lh'

#SSH
alias code01='ssh -x sugemuge2014@code01.fit.edu'

#GMAIL smtp 
alias gsauth='~/scripts/GSauthentication.sh'
alias gsnotify='~/scripts/GSnotify.sh'

#Network Statistics
alias globip='echo "public ip: $(curl -s ipinfo.io/ip)"'
alias localiphelp="ifconfig | sed -En 's/127.0.0.1//;s/.*inet (addr:)?(([0-9]*\.){3}[0-9]*).*/\2/p'"
alias locip='echo "local ip and Broadcast: $(localiphelp)"'
alias myip='globip && locip'
alias wifistat='ifconfig en0'

#JAVA
alias openjar='java -jar'
alias javabin='javac -d bin/'

#TMUX aliases
alias a_tmux='tmux attach -t'
alias l_tmux='tmux ls'
alias n_tmux='tmux new -s'

#TOP
alias mytop='top -o mem -O cpu'

#nav
alias netmode='source ~/.bash_net'

#web
SESHECHO="Opening Gmail and Rediffmailpro in safari"
SUBMITSERVER="https://cs.fit.edu/Portal/modules/submitServer/"
MAIL2="https://gmail.com"
MAIL1="https://www.rediffmailpro.com/cgi-bin/login.cgi"
BROWSER="safari"
alias submit='open $SUBMITSERVER -a $BROWSER'
alias canvas='open $CANVAS -a $BROWSER'
alias mail1='open $MAIL1 -a $BROWSER'
alias mail2='open $MAIL2 -a $BROWSER'
alias sesh='echo $SESHECHO && mail1 && mail2'

# common spell errors
alias celar='clear'
alias vlear='clear'
alias cls='clear'

# git
alias gitget='git fetch && git pull'
alias gitsend='git commit && git push'
alias gitlog='git log -10 --pretty'

#aws
alias ddb='java -Djava.library.path=./DynamoDBLocal_lib -jar DynamoDBLocal.jar -sharedDb -inMemory'
