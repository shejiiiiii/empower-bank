#!/bin/bash

# Empower Bank main menu
# Run this file from the project root or from any location.

set -u

PROJECT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$PROJECT_DIR" || exit 1

# Override at runtime if needed:
# DB_CONN="username/password@service" ./empower_bank_menu.sh
DB_CONN="${DB_CONN:-hr/password}"
STATE_FILE="$PROJECT_DIR/.empower_bank_initialized"

find_script() {
    local name="$1"

    if [ -f "$PROJECT_DIR/$name" ]; then
        printf '%s\n' "$PROJECT_DIR/$name"
        return 0
    fi

    if [ -f "$PROJECT_DIR/batch/$name" ]; then
        printf '%s\n' "$PROJECT_DIR/batch/$name"
        return 0
    fi

    return 1
}

run_script() {
    local name="$1"
    shift
    local path

    if ! path="$(find_script "$name")"; then
        echo "ERROR: Cannot find $name in the project root or batch directory."
        return 1
    fi

    bash "$path" "$@"
}

pause_menu() {
    echo
    read -r -n 1 -s -p "Press any key to continue. Please wait for the menu to refresh..."
    echo
}

clean_sql_value() {
    tr -d '\r' | sed '/^[[:space:]]*$/d' | tr -d '[:space:]'
}

database_exists() {
    local result

    result=$(sqlplus -s "$DB_CONN" <<'SQL'
SET PAGESIZE 0 FEEDBACK OFF VERIFY OFF HEADING OFF ECHO OFF
WHENEVER SQLERROR EXIT FAILURE
SELECT COUNT(*)
FROM USER_TABLES
WHERE TABLE_NAME IN (
    'ACCOUNTREQUEST',
    'ACCOUNTREQUEST_REJECTED',
    'REGISTEREDINFO',
    'TRANSACTIONINFO'
);
EXIT;
SQL
    ) || return 1

    result=$(printf '%s\n' "$result" | clean_sql_value)
    [ "$result" = "4" ]
}

refresh_database_state() {
    if database_exists; then
        touch "$STATE_FILE"
        return 0
    fi

    rm -f "$STATE_FILE"
    return 1
}

show_table() {
    local table="$1"
    local order_by="$2"

    echo
    echo "Showing all rows from $table"
    echo "============================================================"

    sqlplus -s "$DB_CONN" <<SQL
SET LINESIZE 250
SET PAGESIZE 1000
SET FEEDBACK ON
SET VERIFY OFF
SET TRIMSPOOL ON
COLUMN ACCOUNT_NUMBER FORMAT A14
COLUMN ACCOUNT_TYPE FORMAT A12
COLUMN FIRSTNAME FORMAT A15
COLUMN LASTNAME FORMAT A15
COLUMN STATUS FORMAT A10
COLUMN REJECT_REASON FORMAT A45
COLUMN EMAIL FORMAT A30
COLUMN TRANSACTION_TYPE FORMAT A5
ALTER SESSION SET NLS_DATE_FORMAT = 'DD/MM/YYYY';
SELECT * FROM $table ORDER BY $order_by;
EXIT;
SQL
}

setup_database() {
    echo
    echo "Setting up the Empower Bank database..."

    if run_script "setup_database.sh"; then
        if refresh_database_state; then
            echo "Database setup completed and verified."
            return 0
        fi

        echo "ERROR: The setup script ended, but the required tables were not found."
        return 1
    fi

    echo "ERROR: Database setup failed."
    return 1
}

reset_database() {
    local answer

    echo
    echo "WARNING: This will remove Empower Bank tables, sequences, functions, and data."
    read -r -p "Type RESET to continue: " answer

    if [ "$answer" != "RESET" ]; then
        echo "Reset cancelled."
        return 0
    fi

    if run_script "reset_database.sh"; then
        rm -f "$STATE_FILE"
        echo "Database reset completed."
        echo "The setup option will be shown the next time this menu starts."
        return 0
    fi

    echo "ERROR: Database reset failed."
    return 1
}

account_request_menu() {
    local choice csv_path

    while true; do
        clear
        echo "============================================================"
        echo "                 ACCOUNT REQUEST MENU"
        echo "============================================================"
        echo "1. Send account requests from CSV"
        echo "2. View ACCOUNTREQUEST"
        echo "3. View ACCOUNTREQUEST_REJECTED"
        echo "4. Back"
        echo "============================================================"
        read -r -p "Select option: " choice

        case "$choice" in
            1)
                read -r -p "Enter account-request CSV path: " csv_path
                if [ -z "$csv_path" ]; then
                    echo "ERROR: CSV path is required."
                elif [ ! -f "$csv_path" ]; then
                    echo "ERROR: File not found: $csv_path"
                else
                    run_script "account_requests_batch.sh" "$csv_path"
                fi
                pause_menu
                ;;
            2)
                show_table "ACCOUNTREQUEST" "REQUESTID"
                pause_menu
                ;;
            3)
                show_table "ACCOUNTREQUEST_REJECTED" "ROWID"
                pause_menu
                ;;
            4) return 0 ;;
            *)
                echo "ERROR: Invalid option."
                pause_menu
                ;;
        esac
    done
}

account_approval_menu() {
    local choice

    while true; do
        clear
        echo "============================================================"
        echo "                 ACCOUNT APPROVAL MENU"
        echo "============================================================"
        echo "1. Run account approval batch"
        echo "2. View REGISTEREDINFO"
        echo "3. Back"
        echo "============================================================"
        read -r -p "Select option: " choice

        case "$choice" in
            1)
                run_script "account_approval_batch.sh"
                pause_menu
                ;;
            2)
                show_table "REGISTEREDINFO" "ACCOUNT_NUMBER"
                pause_menu
                ;;
            3) return 0 ;;
            *)
                echo "ERROR: Invalid option."
                pause_menu
                ;;
        esac
    done
}

transaction_menu() {
    local choice csv_path

    while true; do
        clear
        echo "============================================================"
        echo "                 TRANSACTION MENU"
        echo "============================================================"
        echo "1. Load transactions from CSV"
        echo "2. View TRANSACTIONINFO"
        echo "3. View TRANSACTIONINFO_REJECTED"
        echo "4. Back"
        echo "============================================================"
        read -r -p "Select option: " choice

        case "$choice" in
            1)
                read -r -p "Enter transaction CSV path: " csv_path
                if [ -z "$csv_path" ]; then
                    echo "ERROR: CSV path is required."
                elif [ ! -f "$csv_path" ]; then
                    echo "ERROR: File not found: $csv_path"
                else
                    run_script "transaction_load_batch.sh" \
                        "$csv_path"
                fi
                pause_menu
                ;;
            2)
                show_table \
                    "TRANSACTIONINFO" \
                    "TRANSACTIONID"
                pause_menu
                ;;
            3)
                show_table \
                    "TRANSACTIONINFO_REJECTED" \
                    "REJECT_DATE"

                pause_menu
                ;;
            4)
                return 0
                ;;
            *)
                echo "ERROR: Invalid option."
                pause_menu
                ;;
        esac
    done
}

initial_setup_menu() {
    local choice

    while ! refresh_database_state; do
        clear
        echo "============================================================"
        echo "             EMPOWER BANK INITIAL SETUP"
        echo "============================================================"
        echo "The required database objects were not detected."
        echo
        echo "1. Set up database"
        echo "2. Exit"
        echo "============================================================"
        read -r -p "Select option: " choice

        case "$choice" in
            1)
                setup_database
                pause_menu
                ;;
            2) exit 0 ;;
            *)
                echo "ERROR: Invalid option."
                pause_menu
                ;;
        esac
    done
}

main_menu() {
    local choice

    while true; do
        if ! refresh_database_state; then
            initial_setup_menu
        fi

        clear
        echo "============================================================"
        echo "                 EMPOWER BANK SYSTEM"
        echo "============================================================"
        echo "Database status: READY"
        echo
        echo "1. Account requests"
        echo "2. Account approval"
        echo "3. Load transactions"
        echo "4. Search / statement report"
        echo "5. Reset database"
        echo "6. Exit"
        echo "============================================================"
        read -r -p "Select option: " choice

        case "$choice" in
            1) account_request_menu ;;
            2) account_approval_menu ;;
            3) transaction_menu ;;
            4)
                run_script "statement_report_batch.sh"
                pause_menu
                ;;
            5)
                reset_database
                pause_menu
                ;;
            6)
                echo "Exiting Empower Bank System."
                exit 0
                ;;
            *)
                echo "ERROR: Invalid option."
                pause_menu
                ;;
        esac
    done
}

initial_setup_menu
main_menu
