require 'bales/command'

##
# Base class for Bales apps.  Your command-line program should create
# a subclass of this, then call said subclass' +#parse_and_run+
# instance method, like so:
#
#   class MyApp::Application < Bales::Application
#     # insert customizations here
#   end
#
#   MyApp::Application.parse_and_run
module Bales
  class Application
    def self.inherited(child) # :nodoc:
      child
        .base_name
        .const_set("Command", Class.new(Bales::Command))
        .const_set("Help", Class.new(Bales::Command::Help))
    end

    ##
    # Set or retrieve the application's version number.
    def self.version(v=nil)
      const_set("VERSION", v) unless v.nil?
      const_set("VERSION", "0.0.0") if const_get("VERSION").nil?
      const_get("VERSION")
    end

    ##
    # Define a command (specifically, a subclass of +Bales::Command+).
    # Command should be a string corresponding to how the command will
    # be invoked on the command-line; thus, a command with the class
    # name +FooBar::Baz+ should be passed as "foo-bar baz".
    def self.command(name, parent: Bales::Command, &code)
      const_name = "#{base_name.name}::Command"

      if eval("defined? #{const_name}") == "constant"
        base = eval(const_name)
      else
        base = base_name.const_set('Command', Class.new(parent))
      end

      base.command(name, parent: parent, base: base, &code)
    end

    ##
    # Set or retrieve the application's banner
    def self.banner(text=nil)
      root_command.banner(text) unless text.nil?
      root_command.banner
    end

    ##
    # Set or retrieve the application's description
    def self.description(text=nil)
      root_command.description(text) unless text.nil?
      root_command.description
    end

    ##
    # Alias for +description+
    def self.desc(text=nil)
      self.description(text)
    end

    ##
    # Set or retrieve the application's summary
    def self.summary(text=nil)
      root_command.summary(text) unless text.nil?
      root_command.summary
    end

    ##
    # Major version number.  Assumes semantic versioning, but will
    # work with any versioning scheme with at least major and minor
    # version numbers.
    def self.major_version
      version.split('.')[0]
    end

    ##
    # Minor version number.  Assumes semantic versioning, but will
    # work with any versioning scheme with at least major and minor
    # version numbers.
    def self.minor_version
      version.split('.')[1]
    end

    ##
    # Patch level.  Assumes semantic versioning.
    def self.patch_level
      version.split('.')[2]
    end

    ##
    # Set an application-level option.  See +Bales::Command+'s
    # +option+ method for more details.
    def self.option(name, **opts)
      root_command.option(name, **opts)
    end

    ##
    # Set an application-level action.  See +Bales::Command+'s
    # +action+ method for more details.
    def self.action(&code)
      root_command.action(&code)
    end

    ##
    # Runs the specified command (should be a valid class; preferably,
    # should be a subclass of +Bales::Command+, or should otherwise
    # have a +.run+ class method that accepts a list of args and a
    # hash of opts).  Takes a list of positional args followed by
    # named options.
    def self.run(command, *args, **opts)
      if opts.none?
        command.run *args
      else
        command.run *args, **opts
      end
    end

    ##
    # Parses ARGV (or some other array if you specify one), returning
    # the class of the identified command, a hash containing the
    # passed-in options, and a list of any remaining arguments
    def self.parse(argv=ARGV)
      command, result = parse_command_name argv.dup
      command ||= default_command
      opts, args = command.parse_opts result
      return command, args, opts
    rescue OptionParser::MissingArgument
      flag = $!.message.gsub("missing argument: ", '')
      puts "#{$0}: error: option needs an argument (#{flag})"
      puts "Usage: #{command.usage}"
      exit!
    rescue OptionParser::InvalidOption
      flag = $!.message.gsub("invalid option: ", '')
      puts "#{$0}: error: unknown option (#{flag})"
      puts "Usage: #{command.usage}"
      exit!
    rescue ArgumentError
      raise unless $!.message.match(/wrong number of arguments/)
      received, expected = $!
                             .message
                             .gsub("wrong number of arguments (", '')
                             .gsub(")", '')
                             .split(" for ")
      puts "#{$0}: error: expected #{expected} args but got #{received}"
      puts "Usage: #{command.usage}"
      exit!
    end

    ##
    # Parses ARGV (or some other array if you specify one) for a
    # command to run and its arguments/options, then runs the command.
    def self.parse_and_run(argv=ARGV)
      command, args, opts = parse argv
      # OptionParser includes nil values for missing options, so we
      # need to make sure those don't clobber the command's defaults.
      command.method(:run).parameters.select {|p| p[0] == :key}.map do |p|
        opts.delete p[1] if opts[p[1]].nil?
      end
      run command, *args, **opts
    end

    private

    def self.parse_command_name(argv)
      const = base_name::Command
      depth = 0

      argv.each do |arg|
          part = arg
                 .downcase
                 .gsub('_','-')
                 .split('-')
                 .map { |p| p.capitalize }
                 .join
          name = "#{const}::#{part}"
          begin
            if const.const_defined? name
              const = eval(name)
              depth += 1
            else
              break
            end
          rescue NameError
            break
          end
        end

      argv.shift depth
      return const, argv
    end

    def self.base_name
      result = self.name.split('::') - ["Application"]
      eval result.join('::')
    end

    def self.root_command
      unless eval("defined? #{base_name}::Command") == "constant"
        base_name.const_set "Command", Class.new(Bales::Command)
      end
      eval "#{base_name}::Command"
    end

    def self.constant_to_args(constant)
      constant.name.split('::').map { |e| e.gsub!(/(.)([A-Z])/,'\1_\2') }
    end

    def self.args_to_constant(argv)
      result = argv.dup
      result.map! do |arg|
        arg
          .capitalize
          .gsub('-','_')
          .gsub(/\W/,'')
          .split('_')
          .map { |e| e.capitalize}
          .join
      end
      eval result.join('::')
    end
  end
end
