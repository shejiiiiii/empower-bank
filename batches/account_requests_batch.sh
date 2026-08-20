#!/bin/bash

# batches/account_requests_batch.sh
# Usage: ./account_requests_batch.sh filename.csv

DB_CONN="hr/password"

CSV_FILE=$1
CTL_FILE="./ctl/account_request.ctl"

LOG_DIR="./logs"
BAD_DIR="./bad"
DISC_DIR="./discard"

TS=$(date +"%Y%m%d%H%M%S")

MAIN_LOG="$LOG_DIR/account_request_${TS}.log"
SQLLDR_LOG="$LOG_DIR/sqlldr_account_request_${TS}.log"
BAD_FILE="$BAD_DIR/account_request_${TS}.bad"
DISC_FILE="$DISC_DIR/account_request_${TS}.dis"

mkdir -p "$LOG_DIR" "$BAD_DIR" "$DISC_DIR"

echo "Program Started at $(date)" > "$MAIN_LOG"

if [ $# -ne 1 ]; then
	echo "ERROR: Missing CSV file parameter." | tee -a "$MAIN_LOG"
	echo "Usage: ./account_requests_batch.sh <file.csv>" | tee -a "$MAIN_LOG"
	exit 1
fi

if [ ! -f "$CSV_FILE" ]; then
	echo "ERROR: CSV file $CSV_FILE does not exist." | tee -a "$MAIN_LOG"
	exit 1
fi

echo "Creating staging table..." | tee -a "$MAIN_LOG"

sqlplus -s "$DB_CONN" << EOF >> "$MAIN_LOG"

@./database/staging/create_account_requests_stg.sql

EOF

if [ $? -ne 0 ]; then
	echo "ERROR: Failed to create staging table." | tee -a "$MAIN_LOG"
	exit 1
fi

echo "Running SQL Loader..." | tee -a "$MAIN_LOG"

sqlldr "$DB_CONN" control="$CTL_FILE" data="$CSV_FILE" log="$SQLLDR_LOG" bad="$BAD_FILE" discard="$DISC_FILE"

if [ $? -ne 0 ]; then
	echo "WARNING: SQL Loader completed with errors. Check $SQLLDR_LOG and $BAD_FILE." | tee -a "$MAIN_LOG"
else
	echo "SQL Loader completed successfully." | tee -a "$MAIN_LOG"
fi

echo "Running validation and insert process..."

sqlplus -s "$DB_CONN" << EOF >> "$MAIN_LOG"
SET SERVEROUTPUT ON
WHENEVER SQLERROR EXIT SQL.SQLCODE

@./database/procedures/prc_process_account_requests.sql

EXIT;
EOF

if [ $? -ne 0 ]; then
	echo "ERROR: Validation process failed." | tee -a "$MAIN_LOG"
	exit 1
fi

echo "Dropping staging table..." | tee -a "$MAIN_LOG"

sqlplus -s "$DB_CONN" << EOF >> "$MAIN_LOG"
SET SERVEROUTPUT ON
WHENEVER SQLERROR EXIT SQL.SQLCODE

@./database/staging/drop_account_requests_stg.sql

EXIT;
EOF

echo "Program Ended at $(date)" | tee -a "$MAIN_LOG"
echo "Script executed successfully. Check log file: $MAIN_LOG"
