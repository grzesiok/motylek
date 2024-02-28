CREATE OR REPLACE EDITIONABLE PACKAGE PKG_LOGGING authid definer is

  C_JOB_STATUS_UNKNOWN constant job_status.job_status_code%type := 'UN';
  C_JOB_STATUS_EXECUTING constant job_status.job_status_code%type := 'EXEC';
  C_JOB_STATUS_SUCCESS constant job_status.job_status_code%type := 'SU';
  C_JOB_STATUS_ERROR constant job_status.job_status_code%type := 'ERROR';

  procedure log_job_start(
    i_job_name in job_metadata.job_name%type,
    i_plsql_unit in job_log.plsql_unit%type default null,
    i_plsql_lineno in job_log.plsql_lineno%type default null,
    i_PLSQL_OWNER in job_log.PLSQL_OWNER%type default null
  );

  procedure log_job_end(
    i_status in job_status.job_status_code%type default C_JOB_STATUS_SUCCESS,
    i_error_count in job_file.error_count%type default null,
    i_record_count in job_file.record_count%type default null,
    i_insert_count in job_file.insert_count%type default null,
    i_update_count in job_file.update_count%type default null,
    i_delete_count in job_file.delete_count%type default null
  );
  
  C_JOB_MESSAGE_DEBUG constant job_message_type.job_message_type_code%type := 'DEBUG';
  C_JOB_MESSAGE_INFO constant job_message_type.job_message_type_code%type := 'INFO';
  C_JOB_MESSAGE_WARNING constant job_message_type.job_message_type_code%type := 'WARN';
  C_JOB_MESSAGE_ERROR constant job_message_type.job_message_type_code%type := 'ERR';
  C_JOB_MESSAGE_CRITICAL_ERROR constant job_message_type.job_message_type_code%type := 'CERR';

  procedure log_message(
    i_message in job_message.message%type,
    i_message_type in job_message_type.job_message_type_code%type default C_JOB_MESSAGE_INFO
  );
end pkg_logging;
GO