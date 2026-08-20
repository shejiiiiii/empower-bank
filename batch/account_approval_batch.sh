#!/bin/bash

# batch/account_approval_batch.sh
# Usage: ./batch/account_approval_batch.sh

DB_CONN="hr/password"

LOG_DIR="./tmp/logs"
TS=$(date +"%Y%m%d%H%M%S")

MAIN_LOG="$LOG_DIR/account_approval_${TS}.log"

mkdir -p "$LOG_DIR"

echo "Account Approval Batch Started" >> "$MAIN_LOG"
echo "Start Time: $(date)" >> "$MAIN_LOG"

sqlplus -s "$DB_CONN" << EOF >> "$MAIN_LOG"
SET SERVEROUTPUT ON
WHENEVER SQLERROR EXIT SQL.SQLCODE

@./database/procedures/prc_approve_accounts.sql

EXIT;
EOF

cmd_success=$?

if [ $cmd_success -ne 0 ]; then
	echo "ERROR: Account Approval Batch Failed." \
		| tee -a "$MAIN_LOG"
	exit 1
fi

echo "Account Approval Batch Completed" \ >> "$MAIN_LOG"
echo "End Time: $(date)" \ >> "$MAIN_LOG"
echo "Batch completed successfully."
echo "Log file: $MAIN_LOG"

