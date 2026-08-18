#!/bin/bash

LOG_DIR="./logs"

TS=$(date +"%Y%m%d%H%M%S")

CREATE_LOG="$LOG_DIR/create_${TS}.log"

mkdir -p "$LOG_DIR"

sqlplus -silent hr/password << EOF >> "$CREATE_LOG"

@account_request_table.sql
@registered_info_table.sql
@transaction_info_table.sql
@reject_table.sql
@request_id_seq.sql
@is_valid_date_function.sql

EOF

cmd_success=$?

if [ $cmd_success -eq 0 ]; then
	echo "Database created successfully."
else
	echo "Database creation failed. Please check: $CREATE_LOG"
fi

