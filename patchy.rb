$LOAD_PATH.unshift "."

require "trollop"

require "lib/cpu"
require "lib/tools/assembler"

# Setup/parse arguments
p = Trollop::Parser.new do
  opt :info, "Display all available info"
  opt :instructions, "Display instruction set"
  opt :assemble, "Assemble source", :type => :string
  opt :showprog, "Show assembled source"
  opt :run, "Run assembled source without writing"
  opt :headless, "Don't attempt to spawn a GL window"
  opt :out, "Output file", :type => :string, :default => "out.bin"
  opt :debug, "Verbose debug logging"
end

opts = Trollop::with_standard_exception_handling p do
  raise Trollop::HelpNeeded if ARGV.empty?
  p.parse ARGV
end

if opts.info
  opts[:instructions] = true
end

patchy = Patchy::CPU.new
rom_bin = nil

trap "SIGINT" do
  patchy.dump_core
  exit 130
end

# Print out instruction/arch info
if opts.instructions
  puts patchy.instructions_s

# Assemble
elsif opts.assemble
  assembler = Patchy::Assembler.new opts.debug
  rom_bin = assembler.assemble(File.open(opts.assemble, "r"))

  assembler.display_summary(rom_bin)

  if !opts.run
    out_file = File.open(opts.out, "w")
    rom_bin.each {|i| i.write(out_file)}
    puts "  Wrote to #{opts.out}\n\n"
  end

# Load binary file directly
else
  begin
    rom_bin = File.open(ARGV.first, "r")
  rescue
    puts "Failed to read #{ARGV.first}"
  end
end

return if !rom_bin

# List the program after assembling/before running if requested
if opts.showprog
  puts "Assembled program:\n\n"

  rom_bin.each_with_index do |instruction, i|
    puts "  0x#{i.to_s(16)} #{patchy.gen_debug_instruction_string(instruction)}"
  end

  puts "\n"
end

# Renderer runs on the main thread, CPU on another
# Originally it was the other way around, but Gosu segfaults on exit if not main
renderer_messenger = nil

# messenger used to communicate between threads
unless opts.headless 
  require "lib/renderer_messenger"

  renderer_messenger = Patchy::RendererMessenger.new
end

# Start the processor
cpu_thread = Thread.new do
  sleep 0.1 unless opts.headless # Let the renderer start up

  patchy.set_renderer_messenger(renderer_messenger) unless opts.headless
  patchy.load_instructions(rom_bin)
  patchy.run

  unless opts.headless
    puts "Press enter to exit"
    gets.chomp!
  end

  # Execution done, kill the renderer
  # TODO: Add option to keep it open for viewing results
  renderer_messenger.close if renderer_messenger
end

cpu_thread.abort_on_exception = true

# Start the renderer
unless opts.headless
  require "gosu"
  require "thread"
  require "lib/renderer"

  renderer = Patchy::Renderer.new(renderer_messenger)
  renderer.show
end

cpu_thread.join if cpu_thread
