# Empower Bank E-Banking Batch Processing System

Developed Using Oracle SQL, PL/SQL, SQL Loader and Unix Shell Scripting.

Features:

- Customer Account Request Processing
- Account Approval Automation
- Account Number Generation
- Transaction Processing
- Loan Interest Calculation
- Statement of Account Reporting
- Data Validation and Error Handling
- Batch Logging

## Overview

The Empower Bank E-Banking Batch Processing System is an Oracle-based batch application that processes customer account requests, account approvals, transactions, and statement-of-account generation through CSV files and shell scripts. The application was developed using Oracle SQL, PL/SQL, SQL Loader, and Unix Shell Scripting. 【1-a33689】

---

# Technologies Used

- Oracle Database 11g
- SQL Developer
- SQL Loader
- Cygwin
- Unix Shell Scripting
- PL/SQL
- Oracle SQL

【1-a33689】

---

# Project Structure

```text
empower-bank
│
├── batches
│   ├── account_requests_batch.sh
│   ├── account_approval_batch.sh
│   ├── transaction_load_batch.sh
│   ├── statement_report_batch.sh
│
├── ctl
│   ├── account_request.ctl
│   ├── transactions.ctl
│
├── database
│   ├── tables
│   ├── sequences
│   ├── functions
│   ├── procedures
│   └── staging
│
├── input
│   ├── sample_account_requests.csv
│   ├── sample_transactions.csv
│
├── logs
│
├── output
│   └── reports
│
├── setup_database.sh
│
└── README.md
```

---

# Setup Instructions

## 1. Configure Database Credentials

Update the following variable in all shell scripts:

```bash
DB_CONN="username/password"
```

Example:

```bash
DB_CONN="hr/hr"
```

---

## 2. Build Database Objects

Run:

```bash
./setup_database.sh
```

This script creates:

- Tables
- Sequences
- Functions

Required database tables:

- ACCOUNTREQUEST
- ACCOUNTREQUEST_REJECTED
- REGISTEREDINFO
- TRANSACTIONINFO

【1-a33689】

---

# Module 1: Account Request Processing

## Purpose

Loads customer account requests from a CSV file.

Validation Rules:

- Account Type must be Savings or Current
- Title must be Mr, Mrs, or Ms
- Birthday must be DD/MM/YYYY
- Birthday cannot be a future date
- Valid Email Format
- Valid Phone Numbers
- Valid ZIP Code
- First Name is required
- Last Name is required

【1-a33689】

---

## Execute

```bash
./account_requests_batch.sh input/sample_account_requests.csv
```

---

## Results

Valid records:

```text
ACCOUNTREQUEST
```

Rejected records:

```text
ACCOUNTREQUEST_REJECTED
```

---

# Module 2: Account Approval Batch

## Purpose

Processes account requests with status:

```text
Entered
```

and moves them to:

```text
REGISTEREDINFO
```

【1-a33689】

---

## Execute

```bash
./account_approval_batch.sh
```

---

## Approval Rules

- Only process Entered records
- Prevent duplicate approved accounts
- Generate Account Number
- Change status to Approved

【1-a33689】

---

## Account Number Format

Format:

```text
PREFIX + NAME + SEQUENCE
```

Examples:

```text
SAVFESY00001
CURROBD00002
SAVCARL00003
```

Where:

```text
SAV = Savings
CUR = Current
```

The sequence is generated using the current maximum account number plus one.

【1-a33689】

---

# Module 3: Transaction Processing

## Purpose

Loads transaction data from a CSV file into the banking system.

【1-a33689】

---

## Execute

```bash
./transaction_load_batch.sh input/sample_transactions.csv
```

---

## Validation Rules

- Account Number must exist
- Transaction Date must be DD/MM/YYYY
- Transaction Type must be TR or LN
- Amount must not be null
- Amount must be greater than zero

【1-a33689】

---

## Interest Calculation

Only Loan transactions:

```text
LN
```

earn interest.

Formula:

```text
Interest = Amount × 10%
```

【1-a33689】

---

## Example

Input:

```csv
20/08/2026,SAVCARL00001,10000,LN
```

Result:

```text
Interest = 1000
```

---

# Module 4: Statement of Account

## Purpose

Generate transaction reports in CSV format.

【1-a33689】

---

## Execute

```bash
./statement_report_batch.sh
```

---

## Available Menu Options

### Option 1

```text
Search by Account Number
```

Produces:

```csv
AccountNo,
FullName,
TransactionDate,
Amount,
Interest,
TransactionType
```

---

### Option 2

```text
Search by Transaction Range
```

Requires:

```text
FROM_DATE
TO_DATE
```

Rules:

- DD/MM/YYYY format
- No missing dates
- FROM_DATE <= TO_DATE

【1-a33689】

---

## Generated Reports

Location:

```text
output/reports
```

Example:

```text
account_SAVCARL00001_20260820153000.csv

range_20260820_20260820154500.csv
```

---

# Log Files

Logs are generated for all batch executions.

Location:

```text
logs
```

Examples:

```text
account_request.log

account_approval.log

transaction_load.log

statement_report.log
```

【1-a33689】

---

# Validation Summary

| Validation | Implemented |
|------------|-------------|
| Account Type | Yes |
| Title | Yes |
| Birthday Format | Yes |
| Future Birthday | Yes |
| Email Format | Yes |
| Phone Validation | Yes |
| ZIP Validation | Yes |
| Missing Name Validation | Yes |
| Duplicate Approved Account | Yes |
| Valid Transaction Account | Yes |
| Transaction Type Validation | Yes |
| Positive Amount Validation | Yes |
| Statement Date Validation | Yes |

---

# Sample Workflow

Step 1:

```bash
./setup_database.sh
```

Step 2:

```bash
./account_requests_batch.sh input/sample_account_requests.csv
```

Step 3:

```bash
./account_approval_batch.sh
```

Step 4:

```bash
./transaction_load_batch.sh input/sample_transactions.csv
```

Step 5:

```bash
./statement_report_batch.sh
```

---

