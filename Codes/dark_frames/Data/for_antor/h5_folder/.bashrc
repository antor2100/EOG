# .bashrc

# Source global definitions
if [ -f /etc/bashrc ]; then
	. /etc/bashrc
fi

# Uncomment the following line if you don't like systemctl's auto-paging feature:
# export SYSTEMD_PAGER=

# User specific aliases and functions

export IDL_PATH='<IDL_DEFAULT>:'/eog/data/reference_share/pro:/eog/data/reference_share/pro/viirs_flag

export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/eog/reference/lib
export PATH=$PATH:/eog/reference/bin:/usr/local/bin

# Add RVM to PATH for scripting. Make sure this is the last PATH variable change.
export PATH="$PATH:$HOME/.rvm/bin"

export RVM_HOME=/eog/reference/rvm
export rvm_path=/eog/reference/rvm/.rvm
[[ -s "$HOME/.rvm/scripts/rvm" ]] && source "$RVM_HOME/.rvm/scripts/rvm" # Load RVM into a shell session *as a function*
[[ -s "$HOME/.rvmrc" ]] && source "$RVM_HOME/.rvmrc"
[[ -s "${rvm_path-$HOME/.rvm}/scripts/rvm" ]] && source "$RVM_HOME/.rvm/scripts/rvm"
# Add RVM to PATH for scripting. Make sure this is the last PATH variable change.
export PATH="$PATH:$RVM_HOME/.rvm/bin"
#rvm use ruby 1.8.7-p374
