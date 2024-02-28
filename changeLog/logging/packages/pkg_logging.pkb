CREATE OR REPLACE EDITIONABLE PACKAGE BODY PKG_LOGGING is

  g_last_job_log_id job_log.job_log_id%type;

  /* INTERNALS */
  procedure assert(i_expr boolean, i_message varchar2) as
  begin
    if(i_expr) then
      raise_application_error(-20000, i_message||' st='||DBMS_UTILITY.FORMAT_ERROR_BACKTRACE(), true);
    end if;
  end;

  /* TEST NULL AND SET */
  procedure p_operator_tnas(i_out in out number, i_imm number) as
  begin
    i_out := nvl(i_out, i_imm);
  end;

  procedure p_operator_add(i_out in out number, i_imm number) as
  begin
    i_out := nvl(i_out, 0)+nvl(i_imm, 0);
  end;

  /* API */

  procedure log_job_start(
    i_job_name in job_metadata.job_name%type,
    i_plsql_unit in job_log.plsql_unit%type default null,
    i_plsql_lineno in job_log.plsql_lineno%type default null,
    i_PLSQL_OWNER in job_log.PLSQL_OWNER%type default null
  ) is
    pragma autonomous_transaction;
    l_job_log job_log%rowtype;
    l_plsql_unit job_log.plsql_unit%type;
    l_plsql_lineno job_log.plsql_lineno%type;
    l_plsql_owner job_log.PLSQL_OWNER%type;
    l_caller_t varchar2(200);
  begin
    owa_util.who_called_me(
      l_plsql_owner,
      l_plsql_unit,
      l_plsql_lineno,
      l_caller_t
    );

    if i_plsql_unit is null then
      owa_util.who_called_me(
        l_plsql_owner,
        l_plsql_unit,
        l_plsql_lineno,
        l_caller_t
      );
    end if;
    select job_metadata_id into l_job_log.job_metadata_id
    from job_metadata
    where job_name = i_job_name;
    l_job_log.job_log_id := seq_job_log_id.nextval;
    l_job_log.parent_job_log_id := g_last_job_log_id;
    l_job_log.job_status_code := C_JOB_STATUS_EXECUTING;
    l_job_log.log_time := systimestamp;
    l_job_log.start_time := systimestamp;
    l_job_log.database_name := sys_context('USERENV', 'DB_NAME');
    l_job_log.session_user := sys_context('USERENV', 'SESSION_USER');
    l_job_log.os_user := sys_context('USERENV', 'OS_USER');
    l_job_log.session_id := sys_context('USERENV', 'SESSIONID');
    l_job_log.plsql_unit := nvl(i_plsql_unit, l_plsql_unit);
    l_job_log.plsql_lineno := nvl(i_plsql_lineno, l_plsql_lineno);
    l_job_log.plsql_owner := nvl(i_plsql_owner, l_plsql_owner);

    insert into job_log values l_job_log
    returning job_log_id into g_last_job_log_id;
    commit;
  end log_job_start;

  procedure log_job_end(
    i_status in job_status.job_status_code%type default C_JOB_STATUS_SUCCESS,
    i_error_count in job_file.error_count%type default null,
    i_record_count in job_file.record_count%type default null,
    i_insert_count in job_file.insert_count%type default null,
    i_update_count in job_file.update_count%type default null,
    i_delete_count in job_file.delete_count%type default null
  ) is
    pragma autonomous_transaction;
    l_job_log_id number;
    l_job_file job_file%rowtype;
  begin
    if(i_error_count is not null or
       i_record_count is not null or
       i_insert_count is not null or
       i_update_count is not null or
       i_delete_count is not null) then
      l_job_file.job_file_id := seq_job_file_id.nextval;
      l_job_file.job_log_id := g_last_job_log_id;
      l_job_file.error_count := nvl(i_error_count, 0);
      l_job_file.record_count := nvl(i_record_count, 0);
      l_job_file.insert_count := nvl(i_insert_count, 0);
      l_job_file.update_count := nvl(i_update_count, 0);
      l_job_file.delete_count := nvl(i_delete_count, 0);
      insert into job_file values l_job_file;
    end if;
    update job_log
      set end_time=systimestamp,
          job_status_code = i_status
    where job_log_id = g_last_job_log_id
    returning parent_job_log_id into g_last_job_log_id;
    commit;
  END log_job_end;

  procedure log_message(
    i_message in job_message.message%type,
    i_message_type in job_message_type.job_message_type_code%type default C_JOB_MESSAGE_INFO
  ) as
    pragma autonomous_transaction;
    l_job_message job_message%rowtype;
    l_include_stacktrace job_message_type.include_stacktrace%type;
  begin
    /*if(g_job_logs.count=0) then
      return;
    end if;*/
    assert((g_last_job_log_id is null), 'JOB must be started before.');
    l_job_message.job_message_id := seq_job_message_id.nextval;
    l_job_message.job_log_Id := g_last_job_log_id;
    --l_job_message.filenr:=get_filenr();
    l_job_message.log_time:=systimestamp;
    l_job_message.job_message_type_code:=i_message_type;
    l_job_message.message:=i_message;
    select include_stacktrace into l_include_stacktrace
    from job_message_type
    where job_message_type_code = i_message_type;
    if(l_include_stacktrace = 'Y') then
      l_job_message.error_stack:=dbms_utility.format_error_stack;
      l_job_message.error_backtrace:=dbms_utility.format_error_backtrace;
    end if;
    insert into job_message values l_job_message;
    commit;
  end log_message;
end pkg_logging;
GO