HOST=""

declare -gA curr_cmd

function host() {
  HOST="$1"
}

function begin() {
  curr_cmd=(
    [name]="$1"  
  )
}

function use-template() {
  local cloned_cmd="$1"
  local cloned_source=$(cat $cloned_cmd)
  local cmd_name="${curr_cmd[name]}"
  local -n cmd=curr_cmd
  eval $cloned_source
  curr_cmd[name]="$cmd_name"
}

methods=(get post delete put patch update head options trace connect)
for m in "${methods[@]}"; do
eval 'function '$m'() { curr_cmd[X]="-X '${m^^}'"; curr_cmd[url]="$HOST$1"; }'
done

function require() {
  curr_cmd[require]+=" $@"
}

function header() {
  curr_cmd[H]+=' -H "'$1': '$2'"'
}

function body() {
  curr_cmd[d]="-d '$1'"
}

function end() {
  local cmd_name=${curr_cmd[name]}

  if [ -f "$cmd_name" ]; then
    rm "$cmd_name"
  fi

  required="${curr_cmd[require]}"
  unsolved_req=""

  declare -A R
  for req in $required; do
    if [ -n "${!req}" ]; then
      R[$req]="${!req}"
      unset $req
    else
      unsolved_req+=" $req"
    fi
  done

  curr_cmd[require]="$unsolved_req"

  for key in "${!curr_cmd[@]}"; do
    local value="${curr_cmd[$key]}"
    value=$(echo $value | sed 's/"/\\"/g')
    
    for r in "${!R[@]}"; do
      value=$(echo "$value" | sed "s/%$r/${R[$r]}/g")
    done

    echo "cmd[$key]=\" $value\"" >> "$cmd_name"
  done
}
