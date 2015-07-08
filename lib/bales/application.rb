require 'bales/command'

##
# Base class for Bales apps.  Your command-line program should create a
# subclass of this, then call said subclass' #parse_and_run instance
# method, like so:
#
# ```ruby
# class MyApp::Application < Bales::Application
#   # insert customizations here
# end
#
# MyApp::Application.parse_and_run
# ```
module Bales
  class Application
    def self.default_command
      @default_command ||= Bales::Command::Help
      @default_command
    end
    def self.default_command=(command)
      @default_command = command
    end

    ##
    # Set or retrieve the application's version number.  Defaults to "0.0.0".
    def self.version(v="0.0.0")
      @version ||= v
      @version
    end

    ##
    # Major version number.  Assumes semantic versioning, but will work with
    # any versioning scheme with at least major and minor version numbers.
    def self.major_version
      version.split('.')[0]
    end

    ##
    # Minor version number.  Assumes semantic versioning, but will work with
    # any versioning scheme with at least major and minor version numbers.
    def self.minor_version
      version.split('.')[1]
    end

    ##
    # Patch level.  Assumes semantic versioning.
    def self.patch_level
      version.split('.')[2]
    end

    ##
    # Runs the specified command (should be a valid class; preferably, should
    # be a subclass of Bales::Command).  Takes a list of positional args
    # followed by named options.
    def self.run(command, *args, **opts)
      command.run *args, **opts
    end

    ##
    # Parses ARGV (or some other array if you specify one), returning the
    # class of the identified command, a hash containing the passed-in
    # options, and a list of any remaining arguments
    def self.parse(argv=ARGV)
      command, result = parse_command_name argv.dup
      command ||= default_command
      opts, args = command.parse_opts result
      return command, args, opts
    end

    ##
    # Parses ARGV (or some other array if you specify one) for a command to
    # run and its arguments/options, then runs the command.
    def self.parse_and_run(argv=ARGV)
      command, args, opts = parse argv
      run command, *args, **opts
    end

    private

    # def self.parse_command_name(argv)
    #   command_name_parts = [*constant_to_args(base_name), "command"]
    #   puts command_name_parts
    #   argv.each do |arg|
    #     break if arg.match(/^-/)
    #     begin
    #       test = args_to_constant [*command_name_parts, arg]
    #     rescue NameError
    #       break
    #     end
    #     if eval("defined? #{test}") == "constant"
    #       command_name_parts.push argv.shift
    #     else
    #       break
    #     end
    #   end
    #   command = args_to_constant [*command_name_parts]
    #   return command, argv
    # end

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

    def self.constant_to_args(constant)
      constant.name.split('::').map { |e| e.gsub!(/(.)([A-Z])/,'\1_\2') }
    end

    def self.args_to_constant(argv)
      result = argv.dup
      result.map! do |arg|
        arg.capitalize
        arg.gsub('-','_').split('_').map { |e| e.capitalize}.join
      end
      eval result.join('::')
    end
  end
end
