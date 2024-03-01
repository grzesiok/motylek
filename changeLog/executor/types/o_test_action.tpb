CREATE OR REPLACE TYPE BODY o_test_action AS

  CONSTRUCTOR FUNCTION o_test_action(i_key VARCHAR2) RETURN SELF AS RESULT AS
  BEGIN
    SELF.key# := i_key;
    RETURN;
  END;

  OVERRIDING MEMBER PROCEDURE p_exec AS
  BEGIN
    dbms_output.put_line(SELF.key#);
  END;
END;
/