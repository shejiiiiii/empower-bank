-- database/install.sql

@./database/tables/create_account_request.sql
@./database/tables/create_registered_info.sql
@./database/tables/create_transaction_info.sql
@./database/tables/create_account_request_rejected.sql
@./database/tables/create_transaction_info_rejected.sql

@./database/sequences/create_request_id_seq.sql
@./database/sequences/create_transaction_id_seq.sql

@./database/functions/fn_is_valid_date.sql
@./database/functions/fn_calculate_interest.sql

EXIT;
