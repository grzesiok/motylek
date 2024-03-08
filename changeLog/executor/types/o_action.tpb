CREATE OR REPLACE TYPE BODY o_action AS

  MEMBER PROCEDURE p_create AS
  BEGIN
    NULL;
  END;

  MEMBER PROCEDURE p_destroy AS
  BEGIN
    NULL;
  END;

  FINAL MEMBER PROCEDURE p_execbefore AS
  BEGIN
    null;/*dbms_profiler.start_profiler(run_comment => SELF.key#||'_'||to_char(systimestamp, 'yyyymmddhh24missff'));*/
  END p_execbefore;
  
  MEMBER PROCEDURE p_exec AS
  BEGIN
    raise_application_error(-20000, 'Unimplemented feature');
  END p_exec;

  FINAL MEMBER PROCEDURE p_execafter AS
  BEGIN
    null;/*dbms_profiler.stop_profiler;*/
  END p_execafter;

  FINAL STATIC FUNCTION f_serialize(i_bytecode XMLTYPE) RETURN o_action AS
    l_cmd o_action;
  BEGIN
    i_bytecode.toobject(l_cmd);
    RETURN l_cmd;
  END f_serialize;

  FINAL STATIC FUNCTION f_deserialize(i_object o_action) RETURN XMLTYPE AS
  BEGIN
    RETURN XMLTYPE(i_object);
  END f_deserialize;

END;
GO