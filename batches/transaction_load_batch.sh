#!/bin/bash

# batches/transaction_load_batch.sh

DB_CONN="hr/password"

CSV_FILE=$1
CTL_FILE="./ctl/transactions.ctl"

LOG_DIR="./logs"
BAD_DIR="./bad"
DISC_DIR="./discard"

TS=$(date +"%Y%m%d%H%M%S")

MAIN_LOG="$LOG_DIR/transaction_load_${TS}.log"
SQLLDR_LOG="$LOG_DIR/transaction_sqlldr_${TS}.log"
BAD_FILE="$BAD_DIR/transaction_${TS}.bad"
DISC_FILE="$DISC_DIR/transaction_${TS}.dis"

mkdir -p "$LOG_DIR" "$BAD_DIR" "$DISC_DIR"

echo "Program Started at $(date)" > "$MAIN_LOG"

if [ $# -ne 1 ]; then
	echo  "ERROR: Missing CSV file parameter." \ | tee -a "$MAIN_LOG"
	exit 1
fi

if [ ! -f "$CSV_FILE" ]; then
	echo "ERROR: CSV file does not exist." \ | tee -a "$MAIN_LOG"
	exit 1
fi

echo "Creating staging table..." \ | tee -a "$MAIN_LOG"

sqlplus -s "$DB_CONN" << EOF >> "$MAIN_LOG"
@./database/staging/create_transaction_info_stg.sql
EXIT;
EOF

if [ $? -ne 0 ]; then
	echo "ERROR: Failed to create staging table." \ | tee -a "$MAIN_LOG"
	exit 1
fi

echo "Running SQL Loader..." \ | tee -a "$MAIN_LOG"

sqlldr "$DB_CONN" control="$CTL_FILE" data="$CSV_FILE" log="$SQLLDR_LOG" bad="$BAD_FILE" discard="$DISC_FILE"

if [ $? -ne 0 ]; then
	echo "WARNING: SQL Loader completed with errors." \ | tee -a "$MAIN_LOG"
fi

echo "Processing transactions..." \ | tee -a "$MAIN_LOG"

sqlplus -s "$DB_CONN" << EOF >> "$MAIN_LOG"
SET SERVEROUTPUT ON
WHENEVER SQLERROR EXIT SQL.SQLCODE

@./database/procedures/prc_load_transactions.sql

EXIT;
EOF

if [ $? -ne 0 ]; then
	echo "ERROR: Transation processing failed." \ | tee -a "$MAIN_LOG"
	exit 1
fi

sqlplus -s "$DB_CONN" << EOF >> "$MAIN_LOG"
@./database/staging/drop_transaction_info_stg.sql
EXIT;
EOF

echo "Program Ended at $(date)" \ | tee -a "$MAIN_LOG"
echo "Transaction Batch Completed Successfully." \ | tee -a "$MAIN_LOG"

