# .bash_profile

# Get the aliases and functions
if [ -f ~/.bashrc ]; then
	. ~/.bashrc
fi

# User specific environment and startup programs

PATH=$PATH:$HOME/.local/bin:$HOME/bin

export PATH

export PS1="\[\e[1;34m\]\u\[\e[1m\]@\[\e[1;34m\]\h\[\e[0m\]:\[\e[1;35m\]\w\[\e[m\]\$ " 
