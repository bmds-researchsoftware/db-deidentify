# db-deidentify
local deidentified pg\_dumps for remote postgres databases.

## getting started
there are no prerequisites other than ruby and the bundler gem.
* clone the repo to your machine
* run `bundle install`
* create a project directory for the target database, such
as `./projects/my_project/`. in that directory, create a file called `db_conf.yml`. everything in
`./projects/` is ignored by git.
<pre>
host: <b><i>remote_host_name</i></b>
user: <b><i>remote_host_user</i></b>
db_name: <b><i>target_database_name</i></b>
</pre>
* provide a public key from a local key pair to someone who has the needed privileges on the remote
host. once this key is in place, you can generate deidentified dumps of the target database.
* run the program using the `get_dump` executable and provide the project name as an argument, like
`./get_dump my_project`. dump files will be placed in `./projects/my_project/dumps`. 
when using a dump file, `pg_restore` may complain about roles and privileges, but the
restored database should work. :pray:

## fields.yml
in your project's directory, create a file called `fields.yml`, or get a copy from a team member for
already-configured projects. This file defines the database fields that will be deidentified. The
top-level structure of the file is a sequence that is loaded into an array at runtime. Each map in
the sequence corresponds to a particular database field (table-column combination) that needs to be
deidentified. Any top-level map with the key `ignore:` will be ignored at runtime, so you can put
any YAML content there, such as anchors. Here is an example where an anchor serves as a template for
a group of similar fields, defining the attributes that they have in common.
<pre>
- ignore:
    # Answer templates
    simple_string: &simple_string
      table: answers
      column: string
      primary_key_col: id
      type: individual
      leave_null: true
</pre>

Each field must define the following key-value pairs:
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

Optionally, each field may have a nested map with the key `where:`. This map is used to
generate WHERE clauses in the resulting SQL. Each key is a column name, and each value is
the value that the WHERE clause will filter on. In the example below, only records where
question\_id is 155 are altered. This example also uses the `simple_string` template defined above.
<pre>
- name: Medical record number
  <<: *simple_string
  output_type: random
  where:
    question_id: 155
</pre>

## Postgres setup on the remote server (for db admins)
These instructions are for setups that use peer authentication.
* Create a distinct user on the target host for deidentification actions, and add that user to any
groups required for ssh login.
  <pre>
  sudo -i
  useradd -m deidentify
  usermod -a -G sshlogin deidentify
  </pre>
* Using a role that has `createrole` privileges ("postgres" by default), create a role for the
user.
  <pre>
  sudo -i -u postgres
  createuser deidentify
  </pre>
* Grant `createddb` privileges to the new role in psql:
  <pre>
  ALTER ROLE <b><i>role_name</i></b> WITH createdb;
  </pre>
* Grant the new role select privileges for the target database. Connect to the target database for
this step. Note the distinction between ***creating\_role*** and ***role***.
***creating\_role*** owns the target database.
  <pre>
  GRANT SELECT ON ALL TABLES IN SCHEMA public TO <b><i>role</i></b>;
  ALTER DEFAULT PRIVILEGES FOR ROLE <b><i>creating_role</i></b> IN SCHEMA public GRANT SELECT ON TABLES TO <b><i>role</i></b>;
  GRANT SELECT ON ALL SEQUENCES IN SCHEMA public TO <b><i>role</i></b>;
  ALTER DEFAULT PRIVILEGES FOR ROLE <b><i>creating_role</i></b> IN SCHEMA public GRANT SELECT ON SEQUENCES TO <b><i>role</i></b>;
  </pre>
