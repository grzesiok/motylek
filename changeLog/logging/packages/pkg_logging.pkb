CREATE OR REPLACE PACKAGE BODY pkg_logging IS

  /* INTERNALS */
  PROCEDURE assert(i_expr BOOLEAN, i_message VARCHAR2) AS
  BEGIN
    IF(i_expr) THEN
      raise_application_error(-20000, i_message||' st='||dbms_utility.format_error_backtrace(), TRUE);
    END IF;
  END;

  /* TEST NULL AND SET */
  PROCEDURE p_operator_tnas(i_out IN OUT NUMBER, i_imm NUMBER) AS
  BEGIN
    i_out := nvl(i_out, i_imm);
  END;

  PROCEDURE p_operator_add(i_out IN OUT NUMBER, i_imm NUMBER) AS
  BEGIN
    i_out := nvl(i_out, 0)+nvl(i_imm, 0);
  END;
  
  /* INTERNAL API */
  
  FUNCTION fn_get_last_job_log_id RETURN job_log.job_log_id%TYPE
  AS
    l_job_log_id job_log.job_log_id%TYPE;
  BEGIN
    SELECT T.job_log_id INTO l_job_log_id
    FROM (SELECT jl.job_log_id, LEVEL lvl, MAX(LEVEL) OVER () AS max_lvl
          FROM job_log jl
          WHERE session_id = sys_context('USERENV', 'SESSIONID')
            AND job_status_code = 'EXEC'
          CONNECT BY NOCYCLE PRIOR jl.job_log_id = jl.parent_job_log_id
          START WITH jl.parent_job_log_id IS NULL) T
    WHERE T.lvl = T.max_lvl;
    RETURN l_job_log_id;
  EXCEPTION
    WHEN no_data_found THEN
      RETURN NULL;
  END;

  /* API */

  PROCEDURE log_job_start(
    i_job_name IN job_log.job_name%TYPE,
    i_plsql_unit IN job_log.plsql_unit%TYPE DEFAULT NULL,
    i_plsql_lineno IN job_log.plsql_lineno%TYPE DEFAULT NULL,
    i_plsql_owner IN job_log.plsql_owner%TYPE DEFAULT NULL
  ) IS
    PRAGMA autonomous_transaction;
    l_job_log job_log%rowtype;
    l_plsql_unit job_log.plsql_unit%TYPE;
    l_plsql_lineno job_log.plsql_lineno%TYPE;
    l_plsql_owner job_log.plsql_owner%TYPE;
    l_caller_t VARCHAR2(200);
    l_current_timestamp TIMESTAMP := systimestamp;
  BEGIN
    owa_util.who_called_me(l_plsql_owner,
                           l_plsql_unit,
                           l_plsql_lineno,
                           l_caller_t);
    l_job_log.job_name := i_job_name;
    l_job_log.job_log_id := seq_job_log_id.NEXTVAL;
    l_job_log.parent_job_log_id := fn_get_last_job_log_id;
    l_job_log.job_status_code := c_job_status_executing;
    l_job_log.log_time := l_current_timestamp;
    l_job_log.start_time := l_current_timestamp;
    l_job_log.database_name := sys_context('USERENV', 'DB_NAME');
    l_job_log.session_user := sys_context('USERENV', 'SESSION_USER');
    l_job_log.os_user := sys_context('USERENV', 'OS_USER');
    l_job_log.session_id := sys_context('USERENV', 'SESSIONID');
    l_job_log.plsql_unit := nvl(i_plsql_unit, l_plsql_unit);
    l_job_log.plsql_lineno := nvl(i_plsql_lineno, l_plsql_lineno);
    l_job_log.plsql_owner := nvl(i_plsql_owner, l_plsql_owner);

    INSERT INTO job_log VALUES l_job_log;
    COMMIT;
  END log_job_start;

  PROCEDURE log_job_end(
    i_status IN job_status.job_status_code%TYPE DEFAULT c_job_status_success,
    i_error_count IN job_file.error_count%TYPE DEFAULT NULL,
    i_record_count IN job_file.record_count%TYPE DEFAULT NULL,
    i_insert_count IN job_file.insert_count%TYPE DEFAULT NULL,
    i_update_count IN job_file.update_count%TYPE DEFAULT NULL,
    i_delete_count IN job_file.delete_count%TYPE DEFAULT NULL
  ) IS
    PRAGMA autonomous_transaction;
    l_job_log_id job_log.job_log_id%TYPE;
    l_job_file job_file%rowtype;
  BEGIN
    IF(i_error_count IS NOT NULL OR
       i_record_count IS NOT NULL OR
       i_insert_count IS NOT NULL OR
       i_update_count IS NOT NULL OR
       i_delete_count IS NOT NULL) THEN
      l_job_file.job_file_id := seq_job_file_id.NEXTVAL;
      l_job_file.job_log_id := fn_get_last_job_log_id;
      l_job_file.error_count := nvl(i_error_count, 0);
      l_job_file.record_count := nvl(i_record_count, 0);
      l_job_file.insert_count := nvl(i_insert_count, 0);
      l_job_file.update_count := nvl(i_update_count, 0);
      l_job_file.delete_count := nvl(i_delete_count, 0);
      INSERT INTO job_file VALUES l_job_file;
    END IF;
    l_job_log_id := fn_get_last_job_log_id;
    UPDATE job_log
      SET end_time=systimestamp,
          job_status_code = i_status
    WHERE job_log_id = l_job_log_id;
    COMMIT;
  END log_job_end;

  PROCEDURE log_message(
    i_message IN job_message.message%TYPE,
    i_message_type IN job_message_type.job_message_type_code%TYPE DEFAULT c_job_message_info
  ) AS
    PRAGMA autonomous_transaction;
    l_job_message job_message%rowtype;
    l_include_stacktrace job_message_type.include_stacktrace%TYPE;
  BEGIN
    l_job_message.job_message_id := seq_job_message_id.NEXTVAL;
    l_job_message.job_log_id := fn_get_last_job_log_id;
    l_job_message.log_time:=systimestamp;
    l_job_message.job_message_type_code:=i_message_type;
    l_job_message.message:=i_message;
    SELECT include_stacktrace INTO l_include_stacktrace
    FROM job_message_type
    WHERE job_message_type_code = i_message_type;
    IF(l_include_stacktrace = 'Y') THEN
      l_job_message.error_stack:=dbms_utility.format_error_stack;
      l_job_message.error_backtrace:=dbms_utility.format_error_backtrace;
    END IF;
    INSERT INTO job_message VALUES l_job_message;
    COMMIT;
  END log_message;
END pkg_logging;
GO