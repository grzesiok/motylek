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
    l_url_already_downloaded NUMBER;
    l_blob BLOB;
    l_max_retries NUMBER;
    l_wait_time NUMBER;
    l_current_retry NUMBER := 1;
    l_hash RAW(16);
    l_download_time TIMESTAMP;

    FUNCTION f_download(p_url VARCHAR2) RETURN BLOB IS
      l_http_request utl_http.req;
      l_http_response utl_http.resp;
      l_raw RAW(2000);
      l_blob BLOB;
    BEGIN
      app_logging.pkg_logging.log_message(i_message => 'download file => '||p_url);
      -- Initialize the BLOB.
      dbms_lob.createtemporary(l_blob, FALSE, dbms_lob.CALL);
      -- Make a HTTP request and get the response.
      l_http_request := utl_http.begin_request(p_url);
      BEGIN
        l_http_response := utl_http.get_response(l_http_request);
        IF(l_http_response.status_code != utl_http.http_ok) THEN
          utl_http.end_response(l_http_response);
          app_logging.pkg_logging.log_message(i_message => 'HTTP_VERSION='||l_http_response.http_version||' '||
                                                           'STATUS_CODE='||l_http_response.status_code||' '||
                                                           'REASON_PHRASE='||l_http_response.reason_phrase,
                                              i_message_type => app_logging.pkg_logging.C_JOB_MESSAGE_ERROR);
          raise_application_error(-20000, 'HTTP_VERSION='||l_http_response.http_version||' '||
                                          'STATUS_CODE='||l_http_response.status_code||' '||
                                          'REASON_PHRASE'||l_http_response.reason_phrase);
        END IF;
        -- Copy the response into the BLOB.
        BEGIN
          LOOP
            utl_http.read_raw(l_http_response, l_raw, 2000);
            dbms_lob.APPEND(l_blob, to_blob(l_raw));
          END LOOP;
        EXCEPTION
          WHEN utl_http.end_of_body THEN
            utl_http.end_response(l_http_response);
        END;
        RETURN l_blob;
      EXCEPTION
        WHEN OTHERS
          THEN utl_http.end_response(l_http_response);
               dbms_lob.freetemporary(l_blob);
               RAISE;
      END;
    END;
  BEGIN
    SELECT COUNT(*) INTO l_url_already_downloaded
    FROM download_file
    WHERE download_url = SELF.l_download_url;
    IF(l_url_already_downloaded > 0) THEN
      RETURN;
    END IF;
    app_logging.pkg_logging.log_job_start(i_job_name => SELF.key#);
    <<try_again>>
    BEGIN
      l_download_time := systimestamp;
      l_blob := f_download(SELF.l_download_url);
    EXCEPTION
      WHEN utl_http.transfer_timeout THEN
        IF(l_current_retry < l_max_retries) THEN
          l_current_retry := l_current_retry + 1;
          dbms_session.sleep(l_wait_time);
          GOTO try_again;
        END IF;
        app_logging.pkg_logging.log_job_end(i_status => app_logging.pkg_logging.C_JOB_STATUS_ERROR);
        RAISE;
      WHEN OTHERS THEN
        app_logging.pkg_logging.log_job_end(i_status => app_logging.pkg_logging.C_JOB_STATUS_ERROR);
        RAISE;
    END;
    l_hash := dbms_crypto.HASH(src => l_blob, typ => dbms_crypto.hash_md5);
    INSERT INTO download_file(download_file_id, download_time, download_url, file_content, file_md5_sum)
      VALUES (seq_download_file.nextval, l_download_time, SELF.l_download_url, l_blob, l_hash);
    app_logging.pkg_logging.log_job_end(i_record_count => 1,
                                        i_insert_count => 1);
  END;

END;
GO