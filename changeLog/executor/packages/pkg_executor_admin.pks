create or replace PACKAGE pkg_executor_admin AS

  PROCEDURE p_callback(CONTEXT RAW,
                       reginfo SYS.aq$_reg_info,
                       DESCR SYS.aq$_descriptor,
                       payload RAW,
                       payloadl NUMBER);

  PROCEDURE p_start;
  
  PROCEDURE p_stop;
  
  PROCEDURE p_recreate_structures;

END pkg_executor_admin;
GO