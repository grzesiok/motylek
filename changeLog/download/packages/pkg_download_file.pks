CREATE OR REPLACE PACKAGE pkg_download_file AS 

  PROCEDURE pr_download_file(p_download_url download_file.download_url%TYPE);

END pkg_download_file;
GO