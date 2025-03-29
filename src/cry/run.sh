import cry.cmd

# Must be runned inside .cry dir
function cry/run() {
  if [ "../$CRY_FILE" -nt ".cache" ]; then
    cry/cmd-gen # auto generate
  fi

  local cmd_name="$1"
  local echo_cmd=1

  # check for -e flag
  if [ "$1" == "-e" ]; then
    cmd_name="$2"
    echo_cmd=0
  fi

  # check if command exists
  if [ ! -f "./commands/$cmd_name" ]; then
    echo "Unknon command '$cmd_name'"
    return 1
  fi

  # load cached command
  declare -A cmd && source ./commands/$cmd_name

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
