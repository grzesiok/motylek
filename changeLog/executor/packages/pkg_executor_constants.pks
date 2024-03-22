CREATE OR REPLACE PACKAGE pkg_executor_constants AS

  c_queue_name CONSTANT VARCHAR2(128) := 'EXECUTOR_Q';
  c_queue_table_name CONSTANT VARCHAR2(128) := 'EXECUTOR_QT';
  c_consumer_name CONSTANT VARCHAR2(128) := 'EXECUTOR_CONSUMER';

END pkg_executor_constants;
GO