#!/bin/bash

# batch/setup_database.sh
# Usage: ./batch/setup_database.sh

LOG_DIR="./tmp/logs"

TS=$(date +"%Y%m%d%H%M%S")

CREATE_LOG="$LOG_DIR/create_${TS}.log"

mkdir -p "$LOG_DIR"

sqlplus -silent hr/password << EOF >> "$CREATE_LOG"

@./database/install.sql

EOF

cmd_success=$?

if [ $cmd_success -eq 0 ]; then
	echo "Database created successfully."
else
	echo "Database creation failed. Please check: $CREATE_LOG"
fi

