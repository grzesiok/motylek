CREATE OR REPLACE PACKAGE BODY pkg_executor_api AS

  PROCEDURE p_exec(i_action IN OUT NOCOPY o_action,
                   i_mode action_mode_t) AS
    l_enqueue_options dbms_aq.enqueue_options_t;
    l_message_properties dbms_aq.message_properties_t;
    l_msgid RAW(16);
    l_payload ANYDATA;
  BEGIN
    IF(i_action IS NULL) THEN
      RETURN;
    END IF;
    IF(i_mode = c_action_mode_synchronous) THEN
      app_logging.pkg_logging.log_job_start(i_job_name => i_action.key#);
      i_action.p_create;
      i_action.p_execbefore;
      i_action.p_exec;
      i_action.p_execafter;
      i_action.p_destroy;
      app_logging.pkg_logging.log_job_end;
      COMMIT;
    ELSIF (i_mode = c_action_mode_asynchronous) THEN
      l_payload := o_action.f_deserialize(i_action);
      dbms_aq.ENQUEUE(queue_name => $$plsql_unit_owner||'.'||pkg_executor_constants.c_queue_name,
                      enqueue_options => l_enqueue_options,
                      message_properties => l_message_properties,
                      msgid => l_msgid,
                      payload => l_payload);
    END IF;
  EXCEPTION
    WHEN OTHERS THEN
      IF(i_mode = c_action_mode_synchronous) THEN
        app_logging.pkg_logging.log_job_end(i_status => app_logging.pkg_logging.c_job_status_error);
      END IF;
      raise_application_error(-20000, 'Error during processing data!', TRUE);
  END;

END pkg_executor_api;
GO