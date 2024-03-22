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
    NULL;/*dbms_profiler.start_profiler(run_comment => SELF.key#||'_'||to_char(systimestamp, 'yyyymmddhh24missff'));*/
  END p_execbefore;
  
  MEMBER PROCEDURE p_exec AS
  BEGIN
    raise_application_error(-20000, 'Unimplemented feature');
  END p_exec;

  FINAL MEMBER PROCEDURE p_execafter AS
  BEGIN
    NULL;/*dbms_profiler.stop_profiler;*/
  END p_execafter;

  FINAL STATIC FUNCTION f_serialize(i_bytecode IN OUT NOCOPY ANYDATA) RETURN o_action AS
    l_cmd o_action;
    l_ret PLS_INTEGER;
  BEGIN
    l_ret := i_bytecode.getobject(l_cmd);
    IF(l_ret != dbms_types.SUCCESS) THEN
      raise_application_error(-20000, 'Problem with serialization');
    END IF; 
    RETURN l_cmd;
  END f_serialize;

  FINAL STATIC FUNCTION f_deserialize(i_object IN OUT NOCOPY o_action) RETURN ANYDATA AS
  BEGIN
    RETURN ANYDATA.convertobject(i_object);
  END f_deserialize;

END;
GO