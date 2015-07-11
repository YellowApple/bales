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
    class Help < Bales::Command::Help; end

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
