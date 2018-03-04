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
  fields.each do |f|
    puts "      #{f['name']} => #{f['output']}".blue
    alter(field)
  end
end

def alter(field)
  primary_keys(field).each do |primary_key|
    perform_update(field, primary_key)
  end 
end

def primary_keys(field)
  str = "UPDATE #{field['table']} "
  str += "#{where_and(str)} #{field} IS NOT NULL " if field['leave_null']
  field['select_on'].each do |column, value|
    str += "#{where_and(str)} #{column]} = #{value} "
  end
  str += "SET #{field['column']} = #{out_val(field['output'])}"
end

# def primary_keys(field)
#   str = "UPDATE #{field['table']} "
#   str += "#{where_and(str)} #{field} IS NOT NULL " if field['leave_null']
#   field['select_on'].each do |column, value|
#     str += "#{where_and(str)} #{column]} = #{value} "
#   end
#   str += "SET #{field['column']} = #{out_val(field['output'])}"
# end

def out_val(type)
  if type == 'random' 
    SecureRandom.hex[0..10]
  end
end

# Starts a WHERE clause unless we're already in one, then uses AND
def where_and(str)
  str.include?('WHERE') ? 'AND' : 'WHERE'
end
