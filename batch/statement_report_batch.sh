#!/bin/bash

# batch/statement_report_batch.sh
# Usage: ./batch/statement_report_batch.sh

DB_CONN="hr/password"

REPORT_DIR="./tmp/reports"
LOG_DIR="./tmp/logs"

mkdir -p "$REPORT_DIR" "$LOG_DIR"

TS=$(date +"%Y%m%d%H%M%S")

MAIN_LOG="$LOG_DIR/statement_report_${TS}.log"

echo "========================================" > "$MAIN_LOG"
echo "Statement Report Started: $(date)" >> "$MAIN_LOG"
echo "========================================" >> "$MAIN_LOG"

validate_date() {

sqlplus -s "$DB_CONN" <<EOF
SET PAGESIZE 0
SET FEEDBACK OFF
SET VERIFY OFF
SET HEADING OFF

SELECT IS_VALID_DATE('$1')
FROM DUAL;

EXIT;
EOF

}

while true
do

clear
echo ""
echo "========================================"
echo "      EMPOWER BANK REPORT MENU"
echo "========================================"
echo "1. Search by Account Number"
echo "2. Search by Transaction Range"
echo "3. Exit"
echo "========================================"

read -p "Select Option: " OPTION

case $OPTION in

1)
	read -p "Enter Account Number: " ACC_NO

	if [ -z "$ACC_NO" ]; then
		echo "ERROR: Missing Account Number."
		read -n 1 -s -r -p "Press any key to continue..."

		continue
	fi

	ACCOUNT_EXISTS=$(sqlplus -s "$DB_CONN" <<EOF
SET PAGESIZE 0
SET FEEDBACK OFF
SET VERIFY OFF
SET HEADING OFF

SELECT COUNT(*)
FROM REGISTEREDINFO
WHERE ACCOUNT_NUMBER='$ACC_NO';

EXIT;
EOF
)

	ACCOUNT_EXISTS=$(echo "$ACCOUNT_EXISTS" | tr -d '[:space:]')

	if [ "$ACCOUNT_EXISTS" = "0" ]; then

		echo ""
		echo "Account Number is not registered in the bank."

		echo "Invalid Account Attempt: $ACC_NO" \ >> "$MAIN_LOG"
		read -n 1 -s -r -p "Press any key to continue..."

		continue

	fi

	REPORT_FILE="$REPORT_DIR/account_${ACC_NO}_${TS}.csv"

	echo "AccountNo,FullName,TransactionDate,Amount,Interest,TransactionType" \ > "$REPORT_FILE"

	sqlplus -s "$DB_CONN" <<EOF >> "$REPORT_FILE"
SET PAGESIZE 0
SET FEEDBACK OFF
SET VERIFY OFF
SET HEADING OFF
SET COLSEP ','

SELECT
R.ACCOUNT_NUMBER,
R.TITLE || ' ' || R.FIRSTNAME || ' ' || R.LASTNAME,
TO_CHAR(T.TRANSACTIONDATE,'DD/MM/YYYY'),
T.AMOUNT,
T.INTEREST,
T.TRANSACTION_TYPE
FROM REGISTEREDINFO R
JOIN TRANSACTIONINFO T
ON R.ACCOUNT_NUMBER = T.ACCOUNT_NUMBER
WHERE R.ACCOUNT_NUMBER = '$ACC_NO';

EXIT;
EOF

	RECORD_COUNT=$(sqlplus -s "$DB_CONN" <<EOF
SET PAGESIZE 0
SET FEEDBACK OFF
SET VERIFY OFF
SET HEADING OFF

SELECT COUNT(*)
FROM TRANSACTIONINFO
WHERE ACCOUNT_NUMBER='$ACC_NO';

EXIT;
EOF
)

	RECORD_COUNT=$(echo "$RECORD_COUNT" | tr -d '[:space:]')
	if [ "$RECORD_COUNT" = "0" ]; then
		echo ""
		echo "No transactions found for account $ACC_NO."
		echo "No transactions found for account: $ACC_NO." \ >> "$MAIN_LOG"

		rm -f "$REPORT_FILE"
		read -n 1 -s -r -p "Press any key to continue..."
		continue
	fi

	echo ""
	echo "Report Generated Successfully:"
	echo "$REPORT_FILE"

	echo "Account Report Generated: $REPORT_FILE" \ >> "$MAIN_LOG"

	echo "Records Returned: $RECORD_COUNT" \ >> "$MAIN_LOG"

	read -n 1 -s -r -p "Press any key to continue..."
	continue
;;

2)
	read -p "Enter From Date (DD/MM/YYYY): " FROM_DATE
	read -p "Enter To Date (DD/MM/YYYY): " TO_DATE

	if [ -z "$FROM_DATE" ] || [ -z "$TO_DATE" ]; then
		echo "ERROR: Missing Date Input."
		read -n 1 -s -r -p "Press any key to continue..."

		continue
	fi

	FROM_VALID=$(validate_date "$FROM_DATE")
	TO_VALID=$(validate_date "$TO_DATE")

	FROM_VALID=$(echo "$FROM_VALID" | tr -d '[:space:]')
	TO_VALID=$(echo "$TO_VALID" | tr -d '[:space:]')

	if [ "$FROM_VALID" != "1" ] || [ "$TO_VALID" != "1" ]; then
		echo "ERROR: Invalid Date Format."
		read -n 1 -s -r -p "Press any key to continue..."

		continue
	fi

	DATE_COMPARE=$(sqlplus -s "$DB_CONN" <<EOF
SET PAGESIZE 0
SET FEEDBACK OFF
SET VERIFY OFF
SET HEADING OFF

SELECT CASE
	WHEN TO_DATE('$FROM_DATE','DD/MM/YYYY') <= TO_DATE('$TO_DATE','DD/MM/YYYY')
	THEN 1
	ELSE 0
END
FROM DUAL;

EXIT;
EOF
)

	DATE_COMPARE=$(echo "$DATE_COMPARE" | tr -d '[:space:]')

	if [ "$DATE_COMPARE" != "1" ]; then
		echo "ERROR: FROM_DATE must be less than or equal TO_DATE."
		read -n 1 -s -r -p "Press any key to continue..."

		continue
	fi

	REPORT_FILE="$REPORT_DIR/range_${TS}.csv"

	echo "AccountNo,FullName,TransactionDate,Amount,Interest,TransactionType" \ > "$REPORT_FILE"

	sqlplus -s "$DB_CONN" <<EOF >> "$REPORT_FILE"
SET PAGESIZE 0
SET FEEDBACK OFF
SET VERIFY OFF
SET HEADING OFF
SET COLSEP ','

SELECT
R.ACCOUNT_NUMBER,
R.TITLE || ' ' || R.FIRSTNAME || ' ' || R.LASTNAME,
TO_CHAR(T.TRANSACTIONDATE,'DD/MM/YYYY'),
T.AMOUNT,
T.INTEREST,
T.TRANSACTION_TYPE
FROM REGISTEREDINFO R
JOIN TRANSACTIONINFO T
ON R.ACCOUNT_NUMBER = T.ACCOUNT_NUMBER
WHERE T.TRANSACTIONDATE BETWEEN
TO_DATE('$FROM_DATE','DD/MM/YYYY')
AND
TO_DATE('$TO_DATE','DD/MM/YYYY');

EXIT;
EOF

	RECORD_COUNT=$(sqlplus -s "$DB_CONN" <<EOF
SET PAGESIZE 0
SET FEEDBACK OFF
SET VERIFY OFF
SET HEADING OFF

SELECT COUNT(*)
FROM TRANSACTIONINFO
WHERE TRANSACTIONDATE BETWEEN
TO_DATE('$FROM_DATE','DD/MM/YYYY')
AND
TO_DATE('$TO_DATE','DD/MM/YYYY');

EXIT;
EOF
)

	RECORD_COUNT=$(echo "$RECORD_COUNT" | tr -d '[:space:]')
	if [ "$RECORD_COUNT" = "0" ]; then
		echo ""
		echo "No transactions found within date range."
		echo "No transactions found from $FROM_DATE to $TO_DATE" \ >> "$MAIN_LOG"

		rm -f "$REPORT_FILE"
		read -n 1 -s -r -p "Press any key to continue..."
		continue
	fi

	echo ""
	echo "Report Generated Successfully:"
	echo "$REPORT_FILE"

	echo "Date Range Report Generated: $REPORT_FILE" \ >> "$MAIN_LOG"

	echo "Records Returned: $RECORD_COUNT" \ >> "$MAIN_LOG"
	
	read -n 1 -s -r -p "Press any key to continue..."
	continue
;;

3)
	echo ""
	echo "Exiting..."

	echo "========================================" \ >> "$MAIN_LOG"

	echo "Statement Report Ended: $(date)" \ >> "$MAIN_LOG"

	echo "========================================" \ >> "$MAIN_LOG"
	clear
	exit 0

;;

*)
	echo "ERROR: Invalid Menu Option."
	read -n 1 -s -r -p "Press any key to continue..."
	continue
;;

esac

done
