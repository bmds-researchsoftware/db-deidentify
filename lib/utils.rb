require 'colorize'

class Array
  def remove!(*keys)
    self.delete_if {|e| keys.include? e.keys.first}
  end
end

def cputs(str)
  puts "    #{str}".green
end

def eputs(str)
  puts "    #{str}".red
end

def debug(thing)
  puts "Debug:\n#{thing.inspect}\n".yellow
end

def ssh_connect!
  host = DB_CONFIG['host']
  user = DB_CONFIG['user']
  begin
    connection = Net::SSH.start(host, user)
  rescue => error
    cputs "Unable to connect to #{host}"
    cputs error
    nil
  end
  cputs "Established SSH session with #{host}"
  connection
end

def scp_upload!(local_path, remote_path)
  Net::SCP.upload!(
    DB_CONFIG['host'],
    DB_CONFIG['user'],
    local_path,
    remote_path
  )
end

def scp_download!(remote_path, local_path)
  Net::SCP.download!(
    DB_CONFIG['host'],
    DB_CONFIG['user'],
    remote_path,
    local_path
  )
end

# Returns a path for the passed-in project-specific file
def project_file(fname)
  "#{@project_path}/#{fname}"
end
