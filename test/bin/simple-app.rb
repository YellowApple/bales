#!/usr/bin/env ruby

$LOAD_PATH.unshift(File.expand_path(File.join(
                                     File.dirname(__FILE__),
                                     '../../lib'
                                   )))
require 'bales'

module SimpleApp
  class Application < Bales::Application
    version "0.0.1"
  end

  class Command < Bales::Command
    action do |args, opts|
      # Bales::Command::Help.run(args, opts)
      Help.run(args, opts)
    end

    class Help < Bales::Command::Help
      action do |args, opts|
        puts "Custom help command"
        super(args, opts)
      end
    end

    class Smack < Command
      option :weapon,
             type: String,
             description: "Thing to smack with",
             short_form: '-w',
             long_form: '--with'

      action do |victims, opts|
        suffix = opts[:weapon] ? " with a #{opts[:weapon]}" : ""

        if victims.none?
          puts "You have been smacked#{suffix}."
        else
          victims.each do |victim|
            puts "#{victim} has been smacked#{suffix}."
          end
        end
      end
    end
  end
end

SimpleApp::Application.parse_and_run
