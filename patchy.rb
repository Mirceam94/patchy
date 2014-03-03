require "trollop"
require_relative "lib/architecture.rb"
require_relative "lib/tools/assembler.rb"

opts = Trollop::options do
  opt :info, "Display all available info"
  opt :instructions, "Display instruction set"
  opt :arch, "Display architecture description"
  opt :assemble, "Assemble source", :type => :string
  opt :out, "Output file", :type => :string, :default => "out.bin"
  opt :debug, "Verbose debug logging"
end

if opts.info
  opts[:arch] = true
  opts[:instructions] = true
end

arch = Patchy::Architecture.new

if opts.instructions
  puts arch.instructions_s
elsif opts.assemble

  # TODO: Move arch into virtual machine, since the assembler needs access
  assembler = Patchy::Assembler.new
  assembler.debug = opts.debug

  bin = assembler.assemble File.open(opts.assemble, "r")
end
