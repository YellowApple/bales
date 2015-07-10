#!/usr/bin/env ruby

$LOAD_PATH.unshift File.expand_path(File.join(
                                     File.dirname(__FILE__),
                                     '../../lib'
                                   ))

require 'bales'

module ComplexApp
  class Application < Bales::Application
    version "0.0.2"
  end

  class Command < Bales::Command
    action do |args, opts|
      Bales::Command::Help.run(args, opts)
    end

    class Say < Command
      option :recipient,
             type: String,
             description: "Recipient",
             long_form: '--to'
      action do |args, opts|
        if opts[:recipient]
          puts "Message for #{opts[:recipient]}: #{args.first}"
        else
          puts "Message for you: #{args.first}"
        end
      end

      class To < Command
        action do |args, opts|
          recipient = args.shift
          message = args.shift
          raise ArgumentError, "too many arguments" unless args.none?
          puts "Message for #{recipient}: #{message}"
        end
      end
    end
  end
end

ComplexApp::Application.parse_and_run
