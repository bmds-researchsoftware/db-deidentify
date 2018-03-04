START_TIME = Time.now
# Called by the get_dump executable
# All non-deidentifying tasks are handed here
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

# Struct containing all fake libraries. call like: FakeLib.woman_names.sample
fake_libs = Dir['./lib/*.fake_lib_csv']
if fake_libs.any?
	fake_lib = {}
	fake_libs.each do |name|
		basename = File.basename(name, '.*')
		fake_lib[basename] = CSV.read(name)[0]
	end
	FakeLib = OpenStruct.new(fake_lib).freeze
	cputs FakeLib.last_names
end

exit

@project_path = ARGV[1]
project_name = @project_path.split('/').last

# Load project-specific content
DB_CONFIG = YAML.load_file(pf 'db_config.yml')

# The ssh connection object
C = ssh_connect!

# Used for tmp db name and tmp dump filename
# TMP_DB = SecureRandom.hex
TMP_DB = 'c16ba942d1dc227164bf1f1ade574e40'

# Set up temporary database
TMP_DIR = './.tmp'
# cputs "Taking snapshot and populating temporary database #{TMP_DB}"
# C.exec! "mkdir -p #{TMP_DIR}"
# C.exec! "pg_dump -Fc #{DB_CONFIG['db_name']} > #{TMP_DIR}/#{TMP_DB}.dump"
# C.exec! "createdb #{TMP_DB}"
# C.exec! "pg_restore -d #{TMP_DB} #{TMP_DIR}/#{TMP_DB}.dump"

# Deidentify tempoaray database - this is where the work gets done
cputs 'Deidentifying data'
begin
  deidentify!
rescue => error
  eputs(error)
end

# Dump deidentified database and clean up
dump_name = Time.now.strftime("#{project_name}_deidentified_%Y-%m-%d_%H%M%S.dump")
# cputs "Creating #{dump_name} and cleaning up"
# C.exec! 'mkdir -p deidentified_snapshots'
# C.exec! "pg_dump -Fc #{TMP_DB} > ./deidentified_snapshots/#{dump_name}"
# C.exec! "dropdb #{TMP_DB}"
# C.exec! "rm #{TMP_DIR}/#{TMP_DB}.dump"
C.close
cputs 'SSH session closed'

# Retreive the dump
# cputs "Secure-copying dump file to ./my_dumps/#{dump_name}" 
# scp_download!  "./deidentified_snapshots/#{dump_name}", "./my_dumps/#{dump_name}"
END_TIME = Time.now
cputs "Elapsed time #{Time.at(END_TIME - START_TIME).utc.strftime("%H:%M:%S")}"
puts
