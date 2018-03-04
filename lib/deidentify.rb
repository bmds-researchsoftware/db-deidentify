# Entry point for deidentifying the live temporary db. Called from main.rb
def deidentify!
  # Make sure that tmp_db looks like a db created by this tool
  hex_32_str = /\A[0-9a-f]{32}\z/
  unless hex_32_str.match(TMP_DB)
    raise ArgumentError.new("Refusing to deidentify database named #{TMP_DB}")
    return
  end
  # Load project-specfic deidentification config into a struct
  fields = YAML.load_file(pf 'fields.yml').remove!('ignore')
  # Iterate of each field (top-level map) in fields.yml and alter records
  fields.each do |field|
    # Dot notation is more fun than hash notation
    field = OpenStruct.new(field).freeze
    alter(field)
  end
end

def alter(field)
  sql = build_sql(field)
  execute(sql)
end

def primary_keys(field)
  sql = "SELECT #{field.primary_key_col} from #{field.table} "
  sql += "#{where_and(sql)} #{field.column} IS NOT NULL " if field.leave_null
  field.select_on.each_pair do |column, value|
    sql += "#{where_and(sql)} #{column} = #{value} "
  end
  sql += "ORDER BY #{field.primary_key_col};"
  # sql += "ORDER BY #{field.primary_key_col} ASC LIMIT 500;"
  execute(sql).split("\n")
end

def build_sql(field)
  statement_sql = ''
  keys = primary_keys(field)
  puts "      Altering #{keys.length} records for: #{field.name} => #{field.output}".blue
  keys.each do |primary_key|
    record_sql = "UPDATE #{field.table} "
    record_sql += "SET #{field.column} = #{out_val(field)} "
    record_sql += "#{where_and(record_sql)} #{field.primary_key_col} = #{primary_key};\n"
    statement_sql += record_sql
  end 
  # puts statement_sql
  statement_sql
end

def out_val(field)
  if field.output == 'random' 
    "'#{SecureRandom.hex[1..10]}'"
  end
end

# Starts a WHERE clause unless we're already in one, then uses AND
def where_and(str)
  str.include?('WHERE') ? 'AND' : 'WHERE'
end

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
