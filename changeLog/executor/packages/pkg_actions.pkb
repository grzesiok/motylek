CREATE OR REPLACE PACKAGE BODY pkg_actions AS

  PROCEDURE p_exec(i_action o_action) AS
    l_action o_action := i_action;
  BEGIN
    IF(l_action IS NULL) THEN
      RETURN;
    END IF;
    app_logging.pkg_logging.log_job_start(i_job_name => i_action.key#);
    l_action.p_create;
    l_action.p_execbefore;
    l_action.p_exec;
    l_action.p_execafter;
    l_action.p_destroy;
    app_logging.pkg_logging.log_job_end;
    COMMIT;
  EXCEPTION
    WHEN OTHERS THEN
      app_logging.pkg_logging.log_job_end(i_status => app_logging.pkg_logging.C_JOB_STATUS_ERROR);
      RAISE;
  END;

END pkg_actions;
GO