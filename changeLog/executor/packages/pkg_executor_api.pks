create or replace PACKAGE pkg_executor_api AUTHID DEFINER AS

  SUBTYPE action_mode_t IS VARCHAR2(1);
  c_action_mode_synchronous action_mode_t := 'S';
  c_action_mode_asynchronous action_mode_t := 'A';

  PROCEDURE p_exec(i_action IN OUT NOCOPY o_action,
                   i_mode action_mode_t);

END pkg_executor_api;
GO