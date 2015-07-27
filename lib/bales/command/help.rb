##
# Prints help text for a given namespace
class Bales::Command::Help < Bales::Command
  summary "Print this help text"
  action do |*args, **opts|
    target = ''
    if args.empty?
      target = basename
    elsif command?(args[0])
      target = args[0].gsub('_','-').split('-').map { |p| p.capitalize }.join
      target = eval "#{rootname}::Command::#{target}"
    else
      target = basename
    end

    print_summary(target)
    print_options(target)
    print_commands(target)
  end

  private

  def self.basename(constant=self)
    eval constant.name.split('::')[0..-2].join('::')
  end

  def self.rootname(constant=self)
    eval constant.name.split('::').first
  end

  def self.command?(name)
    test = name.gsub('_','-').split('-').map { |p| p.capitalize }.join
    test = "#{rootname}::Command::#{test}"
    eval("defined? #{test}") == "constant"
  end

  def self.commands(ns)
    unless eval("defined? #{ns}") == "constant"
      raise ArgumentError, "expected a constant, but got a #{ns.class}"
    end

    ns.constants
      .select { |c| ns.const_defined? "#{ns}::#{c}" }
      .select { |c| eval("#{ns}::#{c}").class == Class }
      .select { |c| eval("#{ns}::#{c}") <= Bales::Command }
      .map { |c| eval "#{ns}::#{c}" }
  end

  def self.format_option(name, opts, width=72)
    long = "#{opts[:long_form]}"
    if opts[:type] <= TrueClass or opts[:type] <= FalseClass
      if opts[:required]
        long << " #{opts[:arg]}"
      else
        long << " [#{opts[:arg]}]"
      end
    end

    output = "#{name} (#{opts[:type]}): "
    output << "#{opts[:short_form]} / " if opts[:short_form]
    output << long
    output << "\n"
    output << opts[:description]
    output
  end

  def self.print_options(command)
    optstrings = command.options.map do |opt|
      opt = opt[1]
      result = ""
      result += "#{opt[:short_form]}, " unless opt[:short_form].nil?
      result += "#{opt[:long_form]}"
      result += "=[#{opt[:arg]}]" unless opt[:arg].nil?
      result
    end

    unless optstrings.none?
      max_length = optstrings.max_by(&:length).length

      puts "Options:"

      pairs = command.options.zip optstrings

      pairs.each do |pair|
        opt, string = *pair
        opt = opt[1]
        printf "%-#{max_length}s : %s\n", string, squeeze_text(
                 opt[:description],
                 width: ENV['COLUMNS'].to_i - max_length - 3,
                 offset: max_length,
                 indent_first_line: false
               )
      end

      print "\n"
    end
  end

  def self.print_summary(command)
    if command.name == "#{rootname}::Command"
      # TODO: allow this to be overridden somewhere (or otherwise make
      # #command_name smarter)
      name = rootname
    else
      name = command.command_name
    end

    print "#{name}: #{command.summary}\n\n"
    print "Description:\n#{command.description}\n\n"
  end

  def self.print_commands(namespace)
    cmds = commands(namespace)

    unless cmds.none?
      max_length = cmds.map { |c| c.command_name }.max_by(&:length).length

      puts "Subcommands:"

      cmds.each do |command|
        printf "%-#{max_length}s : %s\n", command.command_name, squeeze_text(
                 command.summary,
                 width: ENV['COLUMNS'].to_i - max_length - 3,
                 offset: max_length,
                 indent_first_line: false
               )
      end

      print "\n"
    end
  end

  def self.squeeze_text(*strings, **opts)
    text = strings.join('..')
    result = ""
    opts[:indent_with] ||= ' '

    # wrap
    text.split("\n").map! do |line|
      if line.length > opts[:width]
        line.gsub(/(.{1,#{opts[:width]}})(\s+|$)/, "\\1\n").strip
      else
        line
      end
    end

    # indent
    text.split("\n").map! do |line|
      indent = opts[:indent_with] * opts[:offset]
      (indent + line).sub(/[\s]+$/,'')
    end

    if opts[:indent_first_line]
      return text
    else
      return text.strip
    end
  end
end
