@echo off

start "" c:\cygwin64\bin\mintty.exe
/bin/bash -l -c "cd /home/carl.james.a.benitez/empower-bank/empower-bank && ./batches/statement_report_batch.sh"

