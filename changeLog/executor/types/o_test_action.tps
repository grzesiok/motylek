CREATE OR REPLACE TYPE o_test_action FORCE UNDER o_action(
  CONSTRUCTOR FUNCTION o_test_action(i_key VARCHAR2) RETURN SELF AS RESULT,
  OVERRIDING MEMBER PROCEDURE p_exec
);
GO