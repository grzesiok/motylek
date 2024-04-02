create or replace TYPE BODY o_download_file_action AS

  CONSTRUCTOR FUNCTION o_download_file_action(i_url VARCHAR2, i_max_retries NUMBER, i_wait_time NUMBER) RETURN SELF AS RESULT AS
  BEGIN
    SELF.key# := 'df_odfa';
    SELF.l_download_url := i_url;
    SELF.l_max_retries := i_max_retries;
    SELF.l_wait_time := i_wait_time;
    RETURN;
  END o_download_file_action;

  OVERRIDING MEMBER PROCEDURE p_exec AS
  BEGIN
    PKG_DOWNLOAD_FILE.pr_download_file(p_download_url => SELF.l_download_url);
  END;

END;
GO