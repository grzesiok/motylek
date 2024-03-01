CREATE OR REPLACE PACKAGE pkg_actions AUTHID CURRENT_USER AS

  PROCEDURE p_exec(i_action o_action);

END pkg_actions;
/