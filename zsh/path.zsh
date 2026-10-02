export GOPATH=$HOME/go
export ANDROID_HOME=$HOME/Data/sdk
export ANDROID_SDK_ROOT=$ANDROID_HOME
export JAVA_HOME=$(/usr/libexec/java_home -v 17 2>/dev/null)

# (N-/) drops directories that don't exist on this machine
path=(
  $DOTFILES/bin
  /Library/TeX/texbin(N-/)
  $HOME/Library/Python/3.12/bin(N-/)
  /usr/local/bin
  $GOPATH/bin(N-/)
  $path
  $HOME/.pub-cache/bin(N-/)
  $HOME/.local/bin(N-/)
)
