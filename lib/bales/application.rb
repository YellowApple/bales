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
      @version = v unless v.nil?
      @version = "0.0.0" if @version.nil?
      @version
    end

    ##
    # Define a command (specifically, a subclass of +Bales::Command+).
    # Command should be a string corresponding to how the command will
    # be invoked on the command-line; thus, a command with the class
    # name +FooBar::Baz+ should be passed as "foo-bar baz".
    def self.command(name=nil, **opts, &code)
      const_name = "#{base_name.name}::Command"
      opts[:parent] ||= Bales::Command

      if eval("defined? #{const_name}") == "constant"
        const = eval(const_name)
      else
        const = base_name.const_set('Command', Class.new(opts[:parent]))
      end

      unless name.nil?
        name
          .to_s
          .split(' ')
          .map { |p| p
                 .downcase
                 .gsub('_','-')
                 .split('-')
                 .map { |pp| pp.capitalize }
                 .join }
          .each do |part|
          name = "#{const.name}::#{part}"
          if const.const_defined? name
            const = eval(name)
          else
            const = const.const_set(part, Class.new(opts[:parent]))
          end
        end
      end

      const.instance_eval(&code) if block_given?
    end

    ##
    # Set or retrieve the application's banner.
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
    end

    ##
    # Parses ARGV (or some other array if you specify one) for a
    # command to run and its arguments/options, then runs the command.
    def self.parse_and_run(argv=ARGV)
      command, args, opts = parse argv
      run command, *args, **opts
    rescue OptionParser::MissingArgument
      flag = $!.message.gsub("missing argument: ", '')
      puts "#{$0}: error: option needs an argument (#{flag})"
      exit!
    rescue OptionParser::InvalidOption
      flag = $!.message.gsub("invalid option: ", '')
      puts "#{$0}: error: unknown option (#{flag})"
      exit!
    rescue ArgumentError
      received, expected = $!
                             .message
                             .gsub("wrong number of arguments (", '')
                             .gsub(")", '')
                             .split(" for ")
      puts "#{$0}: error: expected #{expected} args but got #{received}"
      exit!
    end

    private

    def self.parse_command_name(argv)
      command_name_parts = [*constant_to_args(base_name), "command"]
      depth = 0
      catch(:end) do
        argv.each_with_index do |arg, i|
          throw(:end) if arg.match(/^-/)
          begin
            test = args_to_constant [*command_name_parts, arg]
          rescue NameError
            throw(:end)
          end

          if eval("defined? #{test}") == "constant"
            command_name_parts.push arg
            depth += 1
          else
            throw(:end)
          end
        end
      end
      command = args_to_constant [*command_name_parts]
      argv.shift depth
      return command, argv
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
