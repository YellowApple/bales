require 'optparse'

##
# Base class for all Bales commands.  Subclass this class to create your
# own command, like so:
#
#   class MyApp::Command::Hello < Bales::Command
#     def self.run(*args, **opts)
#       puts "Hello, world!"
#     end
#   end  # produces a `my-app hello` command that prints "Hello, world!"
#
# Note that the above will accept any number of arguments (including none
# at all!).  If you want to change this behavior, change `self.run`'s
# signature, like so:
#
#   class MyApp::Command::Smack < Bales::Command
#     def self.run(target, **opts)
#       puts "#{target} has been smacked with a large trout"
#     end
#   end
#
# Subcommands are automatically derived from namespacing, like so:
#
#   class MyApp::Command::Foo::Bar < Bales::Command
#     def self.run(*args, **opts)
#       # ...
#     end
#   end  # produces `my-app foo bar`
#
# Camel-cased command classes can be accessed using either hyphenation or
# underscores, like so:
#
#   class MyApp::Command::FooBarBaz < Bales::Command
#     # ...
#   end
#   # valid result: "my-app foo-bar-baz"
#   # also valid: "my-app foo_bar_baz"
#
module Bales
  class Command
    ##
    # Accessor for the options hash generated by +#option+.
    def self.options
      const_get "OPTIONS"
    rescue NameError
      const_set("OPTIONS", {})
    end
    def self.options=(new) # :nodoc:
      const_set("OPTIONS", new)
    end

    ##
    # Get the command's description, or set it if a string is passed
    # to it.
    def self.description(text=nil)
      const_set "DESCRIPTION", text unless text.nil?
      const_get "DESCRIPTION"
    rescue NameError
      const_set "DESCRIPTION", "(no description)"
    end

    ##
    # Get the command's summary, or set it if a string is passed to
    # it.
    def self.summary(text=nil)
      const_set "SUMMARY", text unless text.nil?
      const_get "SUMMARY"
    rescue NameError
      const_set "SUMMARY", "(no summary)"
    end

    ##
    # Translates the command's class name to the corresponding name
    # passed on the command line.
    def self.command_name
      name = self
             .name
             .split('::')
             .last
             .gsub(/(.)([A-Z])/, '\1-\2')
             .downcase
      if name == "command"
        $0
      else
        name
      end
    end

    ##
    # Creates a new subcommand of the current command.  Identical in
    # usage to +Bales::Application.command+, the only significant
    # difference being that +Bales::Command.command+ defines a command
    # on its own scope instead of that of the application's root
    # command.  +Bales::Command.command+ also defaults to making
    # subcommands' classes descendants of itself (unlike the
    # application-level equivalent, which defaults to +Bales::Command+
    # as the new subcommand's parent).
    def self.command(name, parent: self, base: self, &code)
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
        if base.const_defined? "#{base.name}::#{part}"
          base = eval("#{base.name}::#{part}")
        else
          base = base.const_set(part, Class.new(parent))
        end
      end

      base.instance_eval(&code) if block_given?
    end

    ##
    # Assigns an action to this command.  Said action is represented
    # as a block, which should accept an array of arguments and a hash
    # of options.  For example:
    #
    #   class MyApp::Hello < Bales::Command
    #     action do |args, opts|
    #       puts "Hello, world!"
    #     end
    #   end
    def self.action(&code)
      singleton_class.instance_eval do
        define_method :run, &code
      end
    end

    ##
    # Primary entry point for a +Bales::Command+.  Generally a good
    # idea to set this with +.action+, but it's possible to override
    # this manually should you choose to do so.
    def self.run(*args, **opts)
      my_help_class_name = "#{self.name}::Help"
      root_help_class_name = "#{self.to_s.split('::').first}::Command::Help"
      if eval("defined? #{my_help_class_name}")
        eval(my_help_class_name).run *args, **opts
      elsif eval("defined? #{root_help_class_name}")
        eval(root_help_class_name).run *args, **opts
      else
        Bales::Command::Help.run *args, **opts
      end
    end

    ##
    # Defines a named option that the command will accept, along with
    # some named arguments:
    #
    # [+:short_form+ (optional)]
    #
    #     A shorthand flag to use for the option (like +-v+).  This
    #     should be a string, like +"-v"+.
    #
    # [+:long_form+ (optional)]
    #
    #     A longhand flag to use for the option (like +--verbose+).
    #     This is derived from the name of the option if not
    #     specified.  This should be a string, like +"--verbose"+
    #
    # [+:type+ (optional)]
    #
    #     The type that this option represents.  Defaults to
    #     +TrueClass+.  Should be a valid class name, like +String+ or
    #     +Integer+
    #
    #     A special note on boolean options: if you want your boolean
    #     to default to `true`, set +:type+ to +TrueClass+.  Likewise,
    #     if you want it to default to +false+, set +:type+ to
    #     +FalseClass+.
    #
    # [+:arg+ (optional)]
    #
    #     The name of the argument this option accepts.  This should
    #     be a symbol (like :level) or +false+ (if the option is a
    #     boolean flag).  Defaults to the name of the option or (if
    #     the option's +:type+ is +TrueClass+ or +FalseClass+)
    #     +false+.
    #
    # Aside from the hash of option-options, +option+ takes a single
    # +name+ argument, which should be a symbol representing the name
    # of the option to be set, like +:verbose+.
    def self.option(name, **opts)
      name = name.to_sym
      opts[:long_form] ||= "--#{name.to_s}".gsub("_","-")

      opts[:type] = String if opts[:type].nil?

      unless opts[:type].is_a? Class
        raise ArgumentError, ":type option should be a valid class"
      end

      unless opts[:type] <= TrueClass or opts[:type] <= FalseClass
        opts[:arg] ||= name
      end

      opts[:default] = false if opts[:type] <= TrueClass
      opts[:default] = true if opts[:type] <= FalseClass

      result = options
      result[name] = opts
      options = result
    end

    ##
    # Takes an ARGV-like array and returns a hash of options and
    # what's left of the original array.  This is rarely needed for
    # normal use, but is an integral part of how a
    # +Bales::Application+ parses the ARGV it receives.
    #
    # Normally, this should be perfectly fine to leave alone, but if
    # you prefer to define your own parsing method (e.g. if you want
    # to specify an alternative format for command-line options, or
    # you are otherwise dissatisfied with the default approach of
    # wrapping OptionParser), this is the method you'd want to
    # override.
    def self.parse_opts(argv)
      optparser = OptionParser.new
      result = {}
      options.each do |name, opts|
        result[name] = opts[:default]
        parser_args = []
        if opts[:type] <= TrueClass or opts[:type] <= FalseClass
          parser_args.push opts[:short_form] if opts[:short_form]
          parser_args.push opts[:long_form]
        else
          argstring = opts[:arg].to_s.upcase
          if opts[:short_form]
            parser_args.push "#{opts[:short_form]} #{argstring}"
          end
          parser_args.push "#{opts[:long_form]} #{argstring}"
          parser_args.push opts[:type]
        end
        parser_args.push opts[:description] if opts[:description]

        if opts[:type] <= FalseClass
          optparser.on(*parser_args) do
            result[name] = false
          end
        elsif opts[:type] <= TrueClass
          optparser.on(*parser_args) do
            result[name] = true
          end
        else
          optparser.on(*parser_args) do |value|
            result[name] = value
          end
        end
      end

      optparser.parse! argv
      return result, argv
    end
  end
end
