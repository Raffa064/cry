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

# must be runned inside workdir
function cry/generate() {
  import cry.fetch

  echo "Generating..."
  source ../$CRY_FILE

  # store a copy of cry file to check for modifications
  rm .cache >/dev/null 2>&1
  cp "../$CRY_FILE" .cache
}

# must be runned inside workdir
function cry/run() {
  if [ "../$CRY_FILE" -nt ".cache" ]; then
    cry/generate # auto generate
  fi

  local cmd_name="$1"
  local echo_cmd=1

  # check for -e flag
  if [ "$1" == "-e" ]; then
    cmd_name="$2"
    echo_cmd=0
  fi

  # check if command exists
  if [ ! -f "$workdir/$cmd_name" ]; then
    echo "Unknon command '$cmd_name'"
    return 1
  fi

  # load cached command
  declare -A cmd && source ./$cmd_name

  # using cookies
  local cookies=""
  if [ -n "${cmd[cookies]}" ]; then
    local file="${cmd[cookies]:1}"
    cookies=" -c cookies/$file -b cookies/$file"

    mkdir -p cookies
  fi

  local args="${cmd[X]}${cmd[url]}${cookies}${cmd[H]}${cmd[d]}"
  local cmd="curl -s -i -w '%{http_code}' -o ./tmp/body$args"

  # Ask for required fields
  for req in ${cmd[require]}; do
    echo -en "Enter value for \e[34m'$req'\e[0m: "
    read opt

    # Replace % variables
    cmd=$(echo "$cmd" | sed "s/%$req/$opt/g")
  done

  if [ $echo_cmd -eq 0 ]; then
    echo "$cmd" # print curl command
  else
    mkdir -p tmp # create tmp dir

    status_code=$(eval "$cmd") # run curl

    echo -e "\e[33m"
    cat "./tmp/body" # print response
    echo -e "\e[0m\n"

    if [ "$status_code" -eq "200" ]; then
      echo -e "\e[32mStatus: $status_code\e[0m"
    else
      echo -e "\e[31mStatus: $status_code\e[0m"
    fi

    rm -rf tmp # remove tmo dir
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
