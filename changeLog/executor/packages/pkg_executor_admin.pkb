create or replace PACKAGE BODY pkg_executor_admin AS

  c_queue_state_notexists CONSTANT VARCHAR2(1) := 'N';
  c_queue_state_notstarted CONSTANT VARCHAR2(1) := 'S';
  c_queue_state_running CONSTANT VARCHAR2(1) := 'R';

  c_queue_subscriber_created CONSTANT VARCHAR2(1) := 'C';
  c_queue_subscriber_notexists CONSTANT VARCHAR2(1) := 'N';

  FUNCTION fn_get_queue_state(p_queue_name VARCHAR2) RETURN VARCHAR2
  AS
    l_cnt NUMBER;
  BEGIN
    SELECT COUNT(*) INTO l_cnt
    FROM user_queues
    WHERE NAME = p_queue_name;
    IF(l_cnt = 0) THEN
      RETURN c_queue_state_notexists;
    END IF;
    SELECT COUNT(*) INTO l_cnt
    FROM user_queues
    WHERE NAME = p_queue_name
      AND (TRIM(enqueue_enabled) = 'YES'
        OR TRIM(dequeue_enabled) = 'YES');
    IF(l_cnt = 0) THEN
      RETURN c_queue_state_notstarted;
    END IF;
    RETURN c_queue_state_running;
  END fn_get_queue_state;
  
  FUNCTION fn_get_queue_subscriber_state(p_queue_name VARCHAR2,
                                         p_consumer_name VARCHAR2) RETURN VARCHAR2
  AS
    l_cnt NUMBER;
  BEGIN
    SELECT COUNT(*) INTO l_cnt
    FROM user_queue_subscribers
    WHERE queue_name = p_queue_name
      AND consumer_name = p_consumer_name;
    IF(l_cnt > 0) THEN
      RETURN c_queue_subscriber_created;
    END IF;
    RETURN c_queue_subscriber_notexists;
  END fn_get_queue_subscriber_state;

  PROCEDURE p_callback(CONTEXT RAW,
                       reginfo SYS.aq$_reg_info,
                       DESCR SYS.aq$_descriptor,
                       payload RAW,
                       payloadl NUMBER) AS
    l_dequeue_options dbms_aq.dequeue_options_t;
    l_message_properties dbms_aq.message_properties_t;
    l_msgid RAW(16);
    l_payload ANYDATA;
    l_action o_action;
  BEGIN
    app_logging.pkg_logging.log_job_start(i_job_name => DESCR.consumer_name||'['||DESCR.msg_id||']');
    l_dequeue_options.msgid := DESCR.msg_id;
    l_dequeue_options.consumer_name := DESCR.consumer_name;
    app_logging.pkg_logging.log_message(i_message => 'Dequeue message '||DESCR.msg_id||' ...');
    dbms_aq.DEQUEUE(queue_name => DESCR.queue_name,
                    dequeue_options => l_dequeue_options,
                    message_properties => l_message_properties,
                    msgid => l_msgid,
                    payload => l_payload);
    app_logging.pkg_logging.log_message(i_message => 'Serialize object '||l_payload.gettypename||' for message '||DESCR.msg_id||' ...');
    l_action := o_action.f_serialize(l_payload);
    app_logging.pkg_logging.log_message(i_message => 'Execute action '||l_action.key#||' ...');
    pkg_executor_api.p_exec(i_action => l_action,
                            i_mode => pkg_executor_api.c_action_mode_synchronous);
    COMMIT;
    app_logging.pkg_logging.log_job_end;
  EXCEPTION
    WHEN OTHERS THEN
      app_logging.pkg_logging.log_job_end(i_status => app_logging.pkg_logging.c_job_status_error);
      raise_application_error(-20000, 'Error during processing data!', TRUE);
  END;

  PROCEDURE p_start
  AS
  BEGIN
    app_logging.pkg_logging.log_job_start(i_job_name => 'EXECUTOR_QUEUE_START');
    IF(fn_get_queue_state(p_queue_name => pkg_executor_constants.c_queue_name) = c_queue_state_notstarted) THEN
      app_logging.pkg_logging.log_message(i_message => 'Starting queue '||pkg_executor_constants.c_queue_name||' ...');
      dbms_aqadm.start_queue(queue_name => $$plsql_unit_owner||'.'||pkg_executor_constants.c_queue_name);
      app_logging.pkg_logging.log_message(i_message => 'Starting queue '||pkg_executor_constants.c_queue_name||' DONE');
    ELSE
      app_logging.pkg_logging.log_message(i_message => 'Queue '||pkg_executor_constants.c_queue_name||' already started.');
    END IF;
    IF(fn_get_queue_subscriber_state(p_queue_name => pkg_executor_constants.c_queue_name,
                                     p_consumer_name => pkg_executor_constants.c_consumer_name) = c_queue_subscriber_notexists) THEN
      app_logging.pkg_logging.log_message(i_message => 'Creating subscriber '||pkg_executor_constants.c_consumer_name||' ...');
      dbms_aqadm.add_subscriber(queue_name => $$plsql_unit_owner||'.'||pkg_executor_constants.c_queue_name,
                                subscriber => SYS.aq$_agent(NAME => pkg_executor_constants.c_consumer_name,
                                                            address => NULL,
                                                            PROTOCOL => NULL));
      dbms_aq.REGISTER(reg_list => SYS.aq$_reg_info_list(SYS.aq$_reg_info(NAME => $$plsql_unit_owner||'.'||pkg_executor_constants.c_queue_name||':'||pkg_executor_constants.c_consumer_name,
                                                                          NAMESPACE => dbms_aq.namespace_aq,
                                                                          callback => 'plsql://'||$$plsql_unit_owner||'.'||$$plsql_unit||'.p_callback?PR=1',
                                                                          CONTEXT => NULL)),
                       reg_count => 1);
      app_logging.pkg_logging.log_message(i_message => 'Creating subscriber '||pkg_executor_constants.c_consumer_name||' DONE');
    ELSE
      app_logging.pkg_logging.log_message(i_message => 'Subscriber '||pkg_executor_constants.c_consumer_name||' already created.');
    END IF;
    app_logging.pkg_logging.log_job_end;
  END p_start;
  
  PROCEDURE p_stop
  AS
  BEGIN
    app_logging.pkg_logging.log_job_start(i_job_name => 'EXECUTOR_QUEUE_STOP');
    IF(fn_get_queue_subscriber_state(p_queue_name => pkg_executor_constants.c_queue_name,
                                     p_consumer_name => pkg_executor_constants.c_consumer_name) = c_queue_subscriber_created) THEN
      app_logging.pkg_logging.log_message(i_message => 'Removing subscriber '||pkg_executor_constants.c_consumer_name||' ...');
      dbms_aq.unregister(reg_list => SYS.aq$_reg_info_list(SYS.aq$_reg_info(NAME => $$plsql_unit_owner||'.'||pkg_executor_constants.c_queue_name||':'||pkg_executor_constants.c_consumer_name,
                                                                            NAMESPACE => dbms_aq.namespace_aq,
                                                                            callback => 'plsql://'||$$plsql_unit_owner||'.'||$$plsql_unit||'.p_callback?PR=1',
                                                                            CONTEXT => NULL)),
                         reg_count => 1);
      dbms_aqadm.remove_subscriber(queue_name => $$plsql_unit_owner||'.'||pkg_executor_constants.c_queue_name,
                                   subscriber => SYS.aq$_agent(NAME => pkg_executor_constants.c_consumer_name,
                                                               address => NULL,
                                                               PROTOCOL => NULL));
      app_logging.pkg_logging.log_message(i_message => 'Removing subscriber '||pkg_executor_constants.c_consumer_name||' DONE');
    ELSE
      app_logging.pkg_logging.log_message(i_message => 'Subscriber '||pkg_executor_constants.c_consumer_name||' already removed.');
    END IF;
    IF(fn_get_queue_state(p_queue_name => pkg_executor_constants.c_queue_name) = c_queue_state_running) THEN
      app_logging.pkg_logging.log_message(i_message => 'Stopping queue '||pkg_executor_constants.c_queue_name||' ...');
      dbms_aqadm.stop_queue(queue_name => $$plsql_unit_owner||'.'||pkg_executor_constants.c_queue_name);
      app_logging.pkg_logging.log_message(i_message => 'Stopping queue '||pkg_executor_constants.c_queue_name||' DONE');
    ELSE
      app_logging.pkg_logging.log_message(i_message => 'Queue '||pkg_executor_constants.c_queue_name||' already stopped.');
    END IF;
    app_logging.pkg_logging.log_job_end;
  END p_stop;
  
  PROCEDURE p_recreate_structures
  AS
  BEGIN
    app_logging.pkg_logging.log_job_start(i_job_name => 'EXECUTOR_QUEUE_RECREATE');
    p_stop;
    IF(fn_get_queue_state(p_queue_name => pkg_executor_constants.c_queue_name) = c_queue_state_notstarted) THEN
      app_logging.pkg_logging.log_message(i_message => 'Dropping queue '||pkg_executor_constants.c_queue_name||' ...');
      dbms_aqadm.drop_queue(queue_name => pkg_executor_constants.c_queue_name);
      dbms_aqadm.drop_queue_table(queue_table => pkg_executor_constants.c_queue_table_name);
      app_logging.pkg_logging.log_message(i_message => 'Dropping queue '||pkg_executor_constants.c_queue_name||' DONE');
    ELSE
      app_logging.pkg_logging.log_message(i_message => 'Queue '||pkg_executor_constants.c_queue_name||' not exists.');
    END IF;
    IF(fn_get_queue_state(p_queue_name => pkg_executor_constants.c_queue_name) = c_queue_state_notexists) THEN
      app_logging.pkg_logging.log_message(i_message => 'Creating queue '||pkg_executor_constants.c_queue_name||' ...');
      dbms_aqadm.create_queue_table(queue_table => pkg_executor_constants.c_queue_table_name,
                                    queue_payload_type => 'SYS.ANYDATA',
                                    sort_list => 'priority,enq_time',
                                    multiple_consumers => TRUE);
      dbms_aqadm.create_queue(queue_name => pkg_executor_constants.c_queue_name,
                              queue_table => pkg_executor_constants.c_queue_table_name,
                              max_retries => 1);
      app_logging.pkg_logging.log_message(i_message => 'Creating queue '||pkg_executor_constants.c_queue_name||' DONE');
    END IF;
    p_start;
    app_logging.pkg_logging.log_job_end;
  END p_recreate_structures;

END pkg_executor_admin;
GO