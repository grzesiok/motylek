CREATE OR REPLACE TYPE o_download_file_action UNDER app_executor.o_action(
  l_download_url VARCHAR2(4000),
  l_max_retries NUMBER,
  l_wait_time NUMBER,
  CONSTRUCTOR FUNCTION o_download_file_action(i_url VARCHAR2, i_max_retries NUMBER, i_wait_time NUMBER) RETURN SELF AS RESULT,
  OVERRIDING MEMBER PROCEDURE p_exec
);
GO