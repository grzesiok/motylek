CREATE PLUGGABLE DATABASE prod ADMIN USER pdb_adm IDENTIFIED BY pdb_adm;
alter pluggable database prod open;
alter session set container = prod;
create tablespace users;
alter user pdb_adm default tablespace users;
alter user pdb_adm quota unlimited on users;
grant create tablespace to pdb_adm;
grant create user to pdb_adm;
grant alter user to pdb_adm;
grant create table to pdb_adm;
grant grant any privilege to pdb_adm;
grant grant any role to pdb_adm;
grant execute on utl_http to pdb_adm with grant option;
grant execute on dbms_network_acl_admin to pdb_adm;
grant execute on dbms_aqadm to pdb_adm with grant option;
grant execute on dbms_aq to pdb_adm with grant option;
grant execute on dbms_crypto to pdb_adm with grant option;
BEGIN
  dbms_network_acl_admin.append_host_ace (
    HOST       => 'api.nbp.pl',
    lower_port => 80,
    upper_port => 80,
    ace        => xs$ace_type(privilege_list => xs$name_list('http'),
                              principal_name => 'app_download',
                              principal_type => xs_acl.ptype_db)); 
END;
/