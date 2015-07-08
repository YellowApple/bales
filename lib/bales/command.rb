require 'optparse'

##
# Base class for all Bales commands.  Subclass this class to create your
# own command, like so:
#
# ```ruby
# class MyApp::Command::Hello < Bales::Command
#   def self.run(*args, **opts)
#     puts "Hello, world!"
#   end
# end  # produces a `my-app hello` command that prints "Hello, world!"
# ```
#
# Note that the above will accept any number of arguments (including none
# at all!).  If you want to change this behavior, change `self.run`'s
# signature, like so:
#
# ```ruby
# class MyApp::Command::Smack < Bales::Command
#   def self.run(target, **opts)
#     puts "#{target} has been smacked with a large trout"
#   end
# end
# ```
#
# Subcommands are automatically derived from namespacing, like so:
#
# ```ruby
# class MyApp::Command::Foo::Bar < Bales::Command
#   def self.run(*args, **opts)
#     # ...
#   end
# end  # produces `my-app foo bar`
# ```
#
# Camel-cased command classes can be accessed using either hyphenation or
# underscores, like so:
#
# ```ruby
# class MyApp::Command::FooBarBaz < Bales::Command
#   # ...
# end
# # valid result: "my-app foo-bar-baz"
# # also valid: "my-app foo_bar_baz"
# ```
module Bales
  class Command
    def self.options
      @options ||= {}
      @options
    end
    def self.options=(new)
      @options = new
    end

    ##
    # Assigns an action to this command.  Said action is represented as a
    # block, which should accept an array of arguments and a hash of options.
    # For example:
    #
    # ```ruby
    # class MyApp::Hello < Bales::Command
    #   action do |args, opts|
    #     puts "Hello, world!"
    #   end
    # end
    # ```
    def self.action(&code)
      @action = code
    end

    def self.run(*args, **opts)
      @action.call(args, opts) unless @action.nil?
    end

    ##
    # Defines a named option that the command will accept, along with some
    # named arguments:
    #
    # `:short_form` (optional)
    # : A shorthand flag to use for the option (like `-v`).  This should be a
    #   string, like `"-v"`.
    #
    # `:long_form` (optional)
    # : A longhand flag to use for the option (like `--verbose`).  This is
    #   derived from the name of the option if not specified.  This should be
    #   a string, like `"--verbose"`
    #
    # `:type` (optional)
    # : The type that this option represents.  Defaults to `TrueClass`.
    #   Should be a valid class name, like `String` or `Integer`
    #
    #   A special note on boolean options: if you want your boolean to
    #   default to `true`, set `:type` to `TrueClass`.  Likewise, if you want
    #   it to default to `false`, set `:type` to `FalseClass`.
    #
    # `:arg` (optional)
    # : The name of the argument this option accepts.  This should be a
    #   symbol (like :level) or `false` (if the option is a boolean flag).
    #   Defaults to the name of the option or (if the option's `:type` is
    #   `TrueClass` or `FalseClass`) `false`.
    #
    #   If this is an array, and `:type` is set to `Enumerable` or some
    #   subclass thereof, this will instead be interpreted as a list of
    #   sample arguments during option parsing.  It's recommended you set
    #   this accordingly if `:type` is `Enumerable` or any of its subclasses.
    #
    # `:required` (optional)
    # : Whether or not the option is required.  This should be a boolean
    #   (`true` or `false`).  Default is `false`.
    #
    # Aside from the hash of option-options, `option` takes a single `name`
    # argument, which should be a symbol representing the name of the option
    # to be set, like `:verbose`.
    def self.option(name, **opts)
      name = name.to_sym
      opts[:long_form] ||= "--#{name.to_s}".gsub("_","-")

      opts[:type] = String if opts[:type].nil?

      unless opts[:type].is_a? Class
        raise ArgumentError, ":type option should be a valid class"
      end

      if (opts[:type].ancestors & [TrueClass, FalseClass]).empty?
        opts[:arg] ||= name
      end

      opts[:default] = false if opts[:type].ancestors.include? TrueClass
      opts[:default] = true if opts[:type].ancestors.include? FalseClass

      result = options
      result[name] = opts
      options = result
    end

    ##
    # Takes an ARGV-like array and returns a hash of options and what's left
    # of the original array.  This is rarely needed for normal use, but is
    # an integral part of how a Bales::Application parses the ARGV it
    # receives.
    #
    # Normally, this should be perfectly fine to leave alone, but if you
    # prefer to define your own parsing method (e.g. if you want to specify
    # an alternative format for command-line options, or you are otherwise
    # dissatisfied with the default approach of wrapping OptionParser), this
    # is the method you'd want to override.
    def self.parse_opts(argv)
      optparser = OptionParser.new
      result = {}
      options.each do |name, opts|
        result[name] = opts[:default]
        parser_args = []
        parser_args.push opts[:short_form] if opts[:short_form]
        if (opts[:type].ancestors & [TrueClass,FalseClass]).empty?
          argstring = opts[:arg].to_s.upcase
          if opts[:required]
            parser_args.push "#{opts[:long_form]} #{argstring}"
          else
            parser_args.push "#{opts[:long_form]} [#{argstring}]"
          end
          parser_args.push opts[:type]
        else
          parser_args.push opts[:long_form]
        end
        parser_args.push opts[:description]

        if opts[:type].ancestors.include? FalseClass
          optparser.on(*parser_args) do
            result[name] = false
          end
        elsif opts[:type].ancestors.include? TrueClass
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

##
# Default help command.  You'll probably use your own...
class Bales::Command::Help < Bales::Command
  action do |args, opts|
    puts "This will someday output some help text"
  end
end