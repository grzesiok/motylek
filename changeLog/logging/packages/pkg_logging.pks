CREATE OR REPLACE PACKAGE pkg_logging AUTHID DEFINER IS

  c_job_status_unknown CONSTANT job_status.job_status_code%TYPE := 'UN';
  c_job_status_executing CONSTANT job_status.job_status_code%TYPE := 'EXEC';
  c_job_status_success CONSTANT job_status.job_status_code%TYPE := 'SU';
  c_job_status_error CONSTANT job_status.job_status_code%TYPE := 'ERROR';

  PROCEDURE log_job_start(
    i_job_name IN job_log.job_name%TYPE,
    i_plsql_unit IN job_log.plsql_unit%TYPE DEFAULT NULL,
    i_plsql_lineno IN job_log.plsql_lineno%TYPE DEFAULT NULL,
    i_plsql_owner IN job_log.plsql_owner%TYPE DEFAULT NULL
  );

  PROCEDURE log_job_end(
    i_status IN job_status.job_status_code%TYPE DEFAULT c_job_status_success,
    i_error_count IN job_file.error_count%TYPE DEFAULT NULL,
    i_record_count IN job_file.record_count%TYPE DEFAULT NULL,
    i_insert_count IN job_file.insert_count%TYPE DEFAULT NULL,
    i_update_count IN job_file.update_count%TYPE DEFAULT NULL,
    i_delete_count IN job_file.delete_count%TYPE DEFAULT NULL
  );
  
  c_job_message_debug CONSTANT job_message_type.job_message_type_code%TYPE := 'DEBUG';
  c_job_message_info CONSTANT job_message_type.job_message_type_code%TYPE := 'INFO';
  c_job_message_warning CONSTANT job_message_type.job_message_type_code%TYPE := 'WARN';
  c_job_message_error CONSTANT job_message_type.job_message_type_code%TYPE := 'ERR';
  c_job_message_critical_error CONSTANT job_message_type.job_message_type_code%TYPE := 'CERR';

  PROCEDURE log_message(
    i_message IN job_message.message%TYPE,
    i_message_type IN job_message_type.job_message_type_code%TYPE DEFAULT c_job_message_info
  );
END pkg_logging;
GO