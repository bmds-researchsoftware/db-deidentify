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

def ssh_connect(host, username)
  begin
    connection = Net::SSH.start(host, username)
  rescue => error
    cputs "Unable to connect to #{host}"
    cputs error
    nil
  end
  cputs "Established SSH session with #{host} for user #{username}"
  connection
end

# "Project file" returns a path for the passed-in project-specific file
def pf(fname)
  "#{@project_path}/#{fname}"
end
