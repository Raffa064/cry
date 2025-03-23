import cry.fetch

CRY_FILE="cry.sh"

function cry/locate_workdir() {
  local dir="$(pwd)"

  while :; do
    local parent="$(dirname pwd)"

    if [ -f "./$CRY_FILE" ]; then
      echo "$dir/.cry"
      return 
    fi

    if [ "$dir" == "$parent" ]; then
      return # reached system root
    fi

    dir="$parent"
  done
}

function cry/generate() {
  source ../$CRY_FILE
}

function cry/run() {
  local cmd_name="$1"

  if [ ! -f "$workdir/$cmd_name" ]; then
    echo "Unknon command '$cmd_name'"
    return 1
  fi

  local echo_cmd=1
  if [ "$1" == "-e" ]; then
    cmd_name="$2"
    echo_cmd=0
  fi

  declare -A cmd
  source ./$cmd_name
  local cmd="curl${cmd[X]}${cmd[url]}${cmd[H]}${cmd[d]}"

  for req in ${cmd[require]}; do
    echo -en "Enter value for \e[34m'$req'\e[0m: "
    read opt
    cmd=$(echo "$cmd" | sed "s/%$req/$opt/g")
  done

  if [ $echo_cmd -eq 0 ]; then
    echo $cmd
  else
    eval "$cmd"
  fi
}

function cry/main() {
  local workdir="$(cry/locate_workdir)"

  if [ -z "$workdir" ]; then
    echo "Can't locate configuration file"
    return 1
  fi

  mkdir -p $workdir
  cd $workdir

  case $1 in
    gen)
      cry/generate
      ;;
    list)
      ls
      ;;
    edit)
      if [ -n "$EDITOR" ]; then
        $EDITOR ../$CRY_FILE
      else
        echo "No \$EDITOR specified."
      fi
      ;;
    *)
      cry/run $@
  esac
}
