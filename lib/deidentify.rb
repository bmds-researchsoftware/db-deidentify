# Entry point for deidentifying the live temporary db. Called from main.rb
def deidentify!
  # Make sure that tmp_db looks like a db created by this tool
  hex_32_str = /\A[0-9a-f]{32}\z/
  unless hex_32_str.match(TMP_DB)
    raise ArgumentError.new("Refusing to deidentify database named #{TMP_DB}")
    return
  end

	puts TMP_DB
end
