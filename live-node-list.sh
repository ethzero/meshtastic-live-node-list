#!/bin/bash

LOGGING_ID="live-node-list"

check_rc_file() {
  local rc_file="$1"
  # Check if file exists in home directory
  if [ -f "$HOME/$rc_file" ]; then
    echo "$HOME/$rc_file"
  else
    # Check if file exists in current directory
    if [ -f "$rc_file" ]; then
      echo "$rc_file"
    else
      echo "Configuration resource file not found: $rc_file [$HOME]" >&2
      exit 1
    fi
  fi
}

get_connection_string() {
  local node="$1"

  # Check if the key exists in LOCAL_IP_ADDRESS
  if [[ -v LOCAL_IP_ADDRESS["$node"] ]]; then
      echo "--host ${LOCAL_IP_ADDRESS["$node"]}"
  # Check if the key exists in LOCAL_SERIAL_PORT
  elif [[ -v LOCAL_SERIAL_PORT["$node"] ]]; then
      echo "--port ${LOCAL_SERIAL_PORT["$node"]}"
  else
      echo "No connection method found; ABORTING" | logger -t $LOGGING_ID
      exit 1
  fi
}


rc_file=".live-node-list.rc"
rc_path=$(check_rc_file "$rc_file")

declare -A NODE_NAME
declare -A LOCAL_NODE_DUMP_FILE
declare -A REMOTE_HTML_FILE
declare -A LOCAL_PORT
source $rc_path

mkdir -p ${LOCAL_UPLOAD_FILES}

echo "Updating Mesh Node List(s)..." | logger -t $LOGGING_ID
echo "Copying supporting web files to ${LOCAL_UPLOAD_FILES}" | logger -t $LOGGING_ID
cp ${TEMPLATE_HTML_PATH}/live-node-list* ${LOCAL_UPLOAD_FILES}

for key in ${!NODE_NAME[@]}
do
  echo "Gathering \"${NODE_NAME[${key}]}\" node list..." | logger -t $LOGGING_ID

  # Connect to node and dump the neighbour node list to a file, add node, timestamp, HTML preamble
  connection_string=$(get_connection_string ${key})
  if [ $? -eq 1 ]; then
      echo "... received a subshell ABORT."
      exit 1
  fi
  echo "Using connection method: ${connection_string}" | logger -t $LOGGING_ID

  ${HOME}/.local/bin/meshtastic $connection_string --nodes | \
    sed "s|Connected to radio|<div id="node-metainfo"><h2 id="node-name">Node: ${NODE_NAME[${key}]}</h2><p id="node-generated">Generated: `date`</p></div><pre>|" \
    > "${LOCAL_UPLOAD_FILES}/${LOCAL_NODE_DUMP_FILE[${key}]}"

  # If node dump file is not empty, upload it to the webserver and remotely generate the HTML page 
  if [[ -s "${LOCAL_UPLOAD_FILES}/${LOCAL_NODE_DUMP_FILE[${key}]}" ]]; then
    echo "Creating \"${NODE_NAME[${key}]}\" HTML pages..." | logger -t $LOGGING_ID
    cat \
      ${TEMPLATE_HTML_PATH}/${TEMPLATE_HTML_HEADER} \
      ${LOCAL_UPLOAD_FILES}/${LOCAL_NODE_DUMP_FILE[${key}]} \
      ${TEMPLATE_HTML_PATH}/${TEMPLATE_HTML_FOOTER} \
      > ${LOCAL_UPLOAD_FILES}/${REMOTE_HTML_FILE[${key}]}

    echo "Uploading ${REMOTE_HTML_FILE[${key}]} to ${REMOTE_HOST}..." | logger -t $LOGGING_ID

sftp -q ${REMOTE_USERNAME}@${REMOTE_HOST}:${REMOTE_PATH} <<EOF
put -r ${LOCAL_UPLOAD_FILES}/*
EOF

  else
    echo "${LOCAL_NODE_DUMP_FILE[${key}]} is blank. Possible dump error occured"
  fi

  echo "Completed: \"${NODE_NAME[${key}]}\"" | logger -t $LOGGING_ID
done

echo "Completed updating nodes list." | logger -t $LOGGING_ID
