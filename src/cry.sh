import cry.cmd
import cry.run

CRY_FILE="cry.sh"

function cry/locate_workdir() {
  local dir="$(pwd)"

  while :; do
    local parent="$(dirname $dir)"

    if [ -f "./$CRY_FILE" ]; then
      echo "$dir/.cry" # output workdir path
      return 
    fi

    if [ "$dir" == "$parent" ]; then
      return # reached system root
    fi

    dir="$parent"
  done
}

function cry/main() {
  local workdir="$(cry/locate_workdir)"

  if [ -z "$workdir" ]; then
    echo "Can't locate configuration file"
    return 1
  fi

  # Create necessary dirs
  mkdir -p $workdir/commands
  mkdir -p $workdir/cookies

  cd $workdir

  local sub_cmd="cry/cmd-$1"

  if declare -f $sub_cmd >/dev/null; then
    shift # remove command name from argument list
    $sub_cmd $@
    return $?
  else
    cry/run $@
    return $?
  fi
}
