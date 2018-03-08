START_TIME = Time.now
# Called by the get_dump executable
# All non-deidentifying tasks are handled here
# Deidentification is handled in the call to deidentify! See ./lib
# Paths are not Windows-friendly

# Soft assurance that the user-supplied project name has already been validated
exit unless ARGV[0] == 'name_ok'
puts

require 'ostruct'
require 'csv'
require 'net/ssh'
require 'net/scp'
require 'yaml'
Dir['./lib/*.rb'].each {|file| require file }

# Struct containing all fake libraries. call like: FakeLib.female_names.sample
fake_lib = {}
Dir['./fake_libs/*.fake_lib_csv'].each do |name|
	basename = File.basename(name, '.*')
	fake_lib[basename] = CSV.read(name)[0]
end
FakeLib = OpenStruct.new(fake_lib).freeze

project_name = ARGV[1]
@project_path = "./projects/#{project_name}"

# Load project-specific content
DB_CONFIG = YAML.load_file(project_file 'db_conf.yml')

# The ssh connection object
C = ssh_connect!

# Used for tmp db name and tmp dump filename
TMP_DB = SecureRandom.hex

# Set up temporary database
TMP_DIR = './.tmp'
cputs "Taking snapshot and populating temporary database #{TMP_DB}"
C.exec! "mkdir -p #{TMP_DIR}"
C.exec! "pg_dump -Fc #{DB_CONFIG['db_name']} > #{TMP_DIR}/#{TMP_DB}.dump"
C.exec! "createdb #{TMP_DB}"
C.exec! "pg_restore -d #{TMP_DB} #{TMP_DIR}/#{TMP_DB}.dump"

cputs 'Deidentifying data'
begin
  deidentified = deidentify!
rescue => error
  eputs(error)
end

# Dump deidentified database and clean up
dump_type = deidentified ? 'deidentified' : 'raw'
dump_name = Time.now.strftime("#{project_name}_#{dump_type}_%Y-%m-%d_%H%M%S.dump")
cputs "Creating #{dump_name} and cleaning up"
C.exec! 'mkdir -p deidentified_snapshots'
C.exec! "pg_dump -Fc #{TMP_DB} > ./deidentified_snapshots/#{dump_name}"
C.exec! "dropdb #{TMP_DB}"
C.exec! "rm #{TMP_DIR}/#{TMP_DB}.dump"
C.close
cputs 'SSH session closed'

# Retreive the dump
dump_path = "#{@project_path}/dumps"
cputs "Secure-copying dump file to #{@project_path}/#{dump_name}" 
`mkdir -p #{dump_path}`
scp_download!("./deidentified_snapshots/#{dump_name}", "#{dump_path}/#{dump_name}")
END_TIME = Time.now
cputs "Elapsed time #{Time.at(END_TIME - START_TIME).utc.strftime("%H:%M:%S")}"
puts
