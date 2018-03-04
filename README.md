# db-deidentify
A database de-identification utility

## Postgres setup
Assumes you are useing peer authentication
1. Create a distinct user on the target host for this application
1. Create role for this user name on the target host for this application
1. Grant that role createdb privileges
  <pre>
  ALTER ROLE <b><i>role_name</i></b> WITH createdb;
  </pre>
1. Grant that user select privileges for the target database<br />
  * must be connected to the target\_db
  * note the distinction between ***creating\_role*** and ***role***

  ```sql
  GRANT SELECT ON ALL TABLES IN SCHEMA public TO role;
  ALTER DEFAULT PRIVILEGES FOR ROLE creating_role IN SCHEMA public GRANT SELECT ON TABLES TO role;
  GRANT SELECT ON ALL SEQUENCES IN SCHEMA public TO role;
  ALTER DEFAULT PRIVILEGES FOR ROLE creating_role IN SCHEMA public GRANT SELECT ON SEQUENCES TO role;````
