require 'colorize'

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
  cputs "Established SSH session with #{host}"
  connection
end

# "Project file" returns a path for the passed-in project-specific file
def pf(fname)
  "#{@project_path}/#{fname}"
end
