# NOTE: Every command must be runned inside .cry/ dir

function cry/cmd-gen() {
  import cry.generator

  echo "Generating..."
  source ../$CRY_FILE

  # store a copy of cry file to check for modifications
  rm .cache >/dev/null 2>&1
  cp "../$CRY_FILE" .cache
}

function cry/cmd-edit() {
  if [ -n "$EDITOR" ]; then
    $EDITOR ../$CRY_FILE
  else
    echo "No \$EDITOR specified."
  fi
}

function cry/cmd-list() {
  ls ./commands
}
