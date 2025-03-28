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
  local template_cmd="$1" # which command will be used as template
  
  # Prevent overriding command name
  local cmd_name="${curr_cmd[name]}"
  
  local template_source=$(cat $template_cmd) # load temaplte file contents
  
  local -n cmd=curr_cmd
  eval $template_source # load template data into current command

  curr_cmd[name]="$cmd_name" # Restore command name
}

methods=(get post delete put patch update head options trace connect)
for m in "${methods[@]}"; do
  eval 'function '$m'() {
    curr_cmd[X]="-X '${m^^}'";
    curr_cmd[url]="$HOST$1";
  }'
done

function require() {
  curr_cmd[require]+=" $@"
}

function header() {
  curr_cmd[H]+=' -H "'$1': '$2'"'
}

function use-cookies() {
  curr_cmd[cookies]="$1"
}

function body() {
  curr_cmd[d]="-d '$1'"
}

function end() {
  local cmd_name=${curr_cmd[name]}

  required_fields="${curr_cmd[require]}"
  curr_cmd[require]="" # Clear required fields

  declare -A solved_fields
  for field in $required_fields; do
    if [ -n "${!field}" ]; then # check for global variable with the field's name
      solved_fields[$field]="${!field}"
      unset $field # remove global variable
    else
      curr_cmd[require]+=" $field" # keep unsolved fields
    fi
  done

  if [ -f "$cmd_name" ]; then
    rm "$cmd_name" # erase exiting command file
  fi

  # Iterate over current command properties, and store them into command's file 
  for key in "${!curr_cmd[@]}"; do
    local value="${curr_cmd[$key]}"
    value=$(echo $value | sed 's/"/\\"/g') # sanitize quotes
    
    for field in "${!solved_fields[@]}"; do
      value=$(echo "$value" | sed "s/%$field/${solved_fields[$field]}/g") # replace %variables (inject required fields)
    done

    echo "cmd[$key]=\" $value\"" >> "$cmd_name"
  done
}
