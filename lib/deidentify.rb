# Entry point for deidentifying the live temporary db. Called from main.rb
def deidentify!
  # Make sure that tmp_db looks like a db created by this tool
  hex_32_str = /\A[0-9a-f]{32}\z/
  unless hex_32_str.match(TMP_DB)
    raise ArgumentError.new("Refusing to deidentify database named #{TMP_DB}")
    return
  end
  # Load project-specfic deidentification config
  fields = YAML.load_file(pf 'fields.yml').remove!('ignore')
  fields.each do |field|
    puts "      #{field['name']} => #{field['output']}".blue
    alter(field)
  end
end

def alter(field)
  primary_keys(field).each do |primary_key|
    perform_update(field, primary_key)
  end 
end

def primary_keys(field)
  sql = "SELECT #{field['primary_key_col']} from #{field['table']} "
  sql += "#{where_and(sql)} #{field['column']} IS NOT NULL " if field['leave_null']
  field['select_on'].each_pair do |column, value|
    sql += "#{where_and(sql)} #{column} = #{value} "
  end
  sql += "ORDER BY #{field['primary_key_col']} ASC LIMIT 10;"
  execute(sql).split("\n")
end

def perform_update(field, primary_key)
  puts primary_key
  sql = "UPDATE #{field['table']} "
  sql += "SET #{field['column']} = #{out_val(field)} "
  sql += "#{where_and(sql)} #{field['primary_key_col']} = #{primary_key};"
  execute(sql)
end

def out_val(field)
  if field['output'] == 'random' 
    "'#{SecureRandom.hex[1..10]}'"
  end
end

# Starts a WHERE clause unless we're already in one, then uses AND
def where_and(str)
  str.include?('WHERE') ? 'AND' : 'WHERE'
end

def execute(sql)
  C.exec! "echo \"#{sql}\" | psql -A -t -d #{TMP_DB} -f -"
end
