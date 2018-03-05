# db-deidentify
Creates a local deidentified pg\_dump of a remote postgres database.

## Getting started
There are no prerequisites other than Ruby and the bundler gem.
* Clone the repo to your machine
* Run `bundle install`
* Create a file called `db_conf.yml` in your target project directory, such as
`./projects/nautilus/db_conf.yml`. This file is ignored by git and has the following format. 
<pre>
host: <b><i>remote_host_name</i></b>
user: <b><i>remote_host_user</i></b>
db_name: <b><i>target_database_name</i></b>
</pre>
* run the program using the `get_dump` executable and provide the project name as an argument, like
`./get_dump nautilus`. Dump files will be placed in the `my_dumps` directory and will be ignored
by git. When using a dump file, `pg_restore` may complain about roles and privileges, but there
are no known consepquences of these warnings for local database functioning :pray:

## fields.yml
All project-specific configuration occurs in this file. Each project has a `fields.yml` file in
its project directory. The top-level structure of the file is a sequence. This sequence is loaded into 
an array at runtime. Each map in the sequence corresponds to a particular database field
(table-column combination) that needs to be deidentified. The first map is a special case. It is
ignored by the application, so you can put any YAML content inside of it, such as anchors.

Each field must have the following key-value pairs
* `name:` Any text you like to describe the field
* `table:` The database table containing the field
* `column:` The column containing the field
* `primary_key_col:` The primary key column for the table
* `type:` Currently `individual` is the only supported type. A `bulk` type for collections is
planned.
* `leave_null:` `true` or `false` indicating whether or not to ignore null values. If `false`, then
nulls will be replaced with program output.
* `output_type:` Currently the following types are supported:
  * `random` a random eleven-character hex string
  * `first_name` a random first name, not gender-specific
  * `female_first_name` a random female first name
  * `male_first_name` a random male first name
  * `last_name` a random surname
  * `email` a random email address such as 45e8fa@15103e.com

Optionally, each field may have a nested map with the key `where:` This map is used to
generate WHERE clauses in the resulting SQL. Each key is a column name, and each value is
the value that the WHERE clause will filter on. In the example below, only recrods where
question\_id is 155 are altered.
<pre>
- name: Medical record number (pregnancy_mrn)
  <<: *simple_string
  output_type: random
  where:
    question_id: 155
</pre>

## Postgres setup on the remote server (for db admins)
* Create a distinct user on the target host for this application
* Create a postgres role for this user name on the target host for this application
* Grant that role createdb privileges
  <pre>
  ALTER ROLE <b><i>role_name</i></b> WITH createdb;
  </pre>
* Grant the user select privileges for the target database. You must be connected to the
target database for this step. Note the distinction between ***creating\_role*** and ***role***.
***creating\_role*** owns the target database.
  <pre>
  GRANT SELECT ON ALL TABLES IN SCHEMA public TO <b><i>role</i></b>;
  ALTER DEFAULT PRIVILEGES FOR ROLE <b><i>creating_role</i></b> IN SCHEMA public GRANT SELECT ON TABLES TO <b><i>role</i></b>;
  GRANT SELECT ON ALL SEQUENCES IN SCHEMA public TO <b><i>role</i></b>;
  ALTER DEFAULT PRIVILEGES FOR ROLE <b><i>creating_role</i></b> IN SCHEMA public GRANT SELECT ON SEQUENCES TO <b><i>role</i></b>;
  </pre>
