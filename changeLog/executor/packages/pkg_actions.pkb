CREATE OR REPLACE PACKAGE BODY pkg_actions AS

  PROCEDURE p_exec(i_action o_action) AS
    l_action o_action := i_action;
  BEGIN
    IF(l_action IS NULL) THEN
      RETURN;
    END IF;
    l_action.p_create;
    l_action.p_execbefore;
    l_action.p_exec;
    l_action.p_execafter;
    l_action.p_destroy;
  END;

END pkg_actions;
/