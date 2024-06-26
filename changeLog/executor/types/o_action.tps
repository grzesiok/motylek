CREATE OR REPLACE TYPE o_action FORCE AUTHID CURRENT_USER AS OBJECT(
  key# VARCHAR2(30),
  --initialization process
  MEMBER PROCEDURE p_create,
  MEMBER PROCEDURE p_destroy,
  --execution process
  FINAL MEMBER PROCEDURE p_execbefore,
  MEMBER PROCEDURE p_exec,
  FINAL MEMBER PROCEDURE p_execafter,
  --object serialization
  FINAL STATIC FUNCTION f_serialize(i_bytecode IN OUT NOCOPY ANYDATA) RETURN o_action,
  FINAL STATIC FUNCTION f_deserialize(i_object IN OUT NOCOPY o_action) RETURN ANYDATA
) NOT FINAL NOT INSTANTIABLE;
GO