CREATE OR REPLACE EDITIONABLE PACKAGE PKG_LOGGING AUTHID DEFINER IS

  C_JOB_STATUS_UNKNOWN CONSTANT job_status.job_status_code%TYPE := 'UN';
  C_JOB_STATUS_EXECUTING CONSTANT job_status.job_status_code%TYPE := 'EXEC';
  C_JOB_STATUS_SUCCESS CONSTANT job_status.job_status_code%TYPE := 'SU';
  C_JOB_STATUS_ERROR CONSTANT job_status.job_status_code%TYPE := 'ERROR';

  PROCEDURE log_job_start(
    i_job_name IN job_log.job_name%TYPE,
    i_plsql_unit IN job_log.plsql_unit%TYPE DEFAULT NULL,
    i_plsql_lineno IN job_log.plsql_lineno%TYPE DEFAULT NULL,
    i_PLSQL_OWNER IN job_log.PLSQL_OWNER%TYPE DEFAULT NULL
  );

  PROCEDURE log_job_end(
    i_status IN job_status.job_status_code%TYPE DEFAULT C_JOB_STATUS_SUCCESS,
    i_error_count IN job_file.error_count%TYPE DEFAULT NULL,
    i_record_count IN job_file.record_count%TYPE DEFAULT NULL,
    i_insert_count IN job_file.insert_count%TYPE DEFAULT NULL,
    i_update_count IN job_file.update_count%TYPE DEFAULT NULL,
    i_delete_count IN job_file.delete_count%TYPE DEFAULT NULL
  );
  
  C_JOB_MESSAGE_DEBUG CONSTANT job_message_type.job_message_type_code%TYPE := 'DEBUG';
  C_JOB_MESSAGE_INFO CONSTANT job_message_type.job_message_type_code%TYPE := 'INFO';
  C_JOB_MESSAGE_WARNING CONSTANT job_message_type.job_message_type_code%TYPE := 'WARN';
  C_JOB_MESSAGE_ERROR CONSTANT job_message_type.job_message_type_code%TYPE := 'ERR';
  C_JOB_MESSAGE_CRITICAL_ERROR CONSTANT job_message_type.job_message_type_code%TYPE := 'CERR';

  PROCEDURE log_message(
    i_message IN job_message.message%TYPE,
    i_message_type IN job_message_type.job_message_type_code%TYPE DEFAULT C_JOB_MESSAGE_INFO
  );
END pkg_logging;
GO