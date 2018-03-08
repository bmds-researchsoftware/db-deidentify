# Entry point for deidentifying the live temporary db. Called from main.rb
def deidentify!
  # Make sure that tmp_db looks like a db created by this tool
  hex_32_str = /\A[0-9a-f]{32}\z/
  unless hex_32_str.match(TMP_DB)
    raise ArgumentError.new("Refusing to deidentify database named #{TMP_DB}")
    return
  end
  # Load project-specfic deidentification config into a struct
  fields = YAML.load_file(pf 'fields.yml')
  # If nothing is found in the file, YAML will return false
  if fields
    fields = fields.remove!('ignore')
  else
    eputs 'NO FIELDS TO DEIDENTIFY. RETREIVING RAW DUMP.'
    return false
  end
  # Iterate of each field (top-level map) in fields.yml and alter records
  fields.each do |field|
    field = OpenStruct.new(field).freeze
    alter(field)
  end
  true
end

# Builds and executes the SQL for a field
def alter(field)
  sql = build_sql(field)
  execute(sql)
end

# Gets the primary keys for the records to be altered for a given field
def primary_keys(field)
  sql = "SELECT #{field.primary_key_col} from #{field.table} "
  sql += "#{where_and(sql)} #{field.column} IS NOT NULL " if field.leave_null
  field.where&.each_pair do |column, value|
    sql += "#{where_and(sql)} #{column} = #{value} "
  end
  sql += "ORDER BY #{field.primary_key_col};"
  execute(sql).split("\n")
end

# Builds a list of alter statements, one for each record in a field
def build_sql(field)
  statement_sql = ''
  keys = primary_keys(field)
  puts "      Altering #{keys.length} records for: #{field.name} => #{field.output_type}".blue
  keys.each do |primary_key|
    record_sql = "UPDATE #{field.table} "
    record_sql += "SET #{field.column} = '#{out_val(field)}' "
    record_sql += "#{where_and(record_sql)} #{field.primary_key_col} = #{primary_key};\n"
    statement_sql += record_sql
  end 
  statement_sql
end

# Returns an ouput value for a given record
def out_val(field)
  output_type = field.output_type.to_sym
  return "'#{SecureRandom.hex[1..10]}'" if output_type == :random
	if FakeLib.methods(false).include?(output_type)
    return FakeLib.send(output_type).sample
  end
end

# Starts a WHERE clause unless we're already in one, then uses AND
def where_and(str)
  str.include?('WHERE') ? 'AND' : 'WHERE'
end

# Executes sql on the remote server
def execute(sql)
  tmp = Digest::MD5.hexdigest(sql)
  tmp_path = "#{TMP_DIR}/#{tmp}"
  File.write tmp_path, sql 
  scp_upload! tmp_path, tmp_path 
  result = C.exec! "psql -A -t -d #{TMP_DB} -f #{tmp_path}"
  C.exec! "rm #{tmp_path}"
  File.delete tmp_path
  result
end
