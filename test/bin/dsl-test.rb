#!/usr/bin/env ruby

$LOAD_PATH.unshift(File.expand_path(File.join(
                                     File.dirname(__FILE__),
                                     '../../lib'
                                   )))
require 'bales'

module SimpleApp
  class Application < Bales::Application
    version "0.0.1"
    description "Test implementation of a simple Bales app"

    action do
      puts "Hello, world!"
    end

    command "smack" do
      option :weapon,
             type: String,
             description: "Thing to smack with",
             short_form: '-w',
             long_form: '--with'

      action do |*victims, weapon:nil|
        suffix = weapon ? " with a #{weapon}" : ""

        if victims.none?
          puts "You have been smacked#{suffix}."
        else
          victims.each do |victim|
            puts "#{victim} has been smacked#{suffix}."
          end
        end
      end
    end

    command "smack with" do
      action do |weapon, *victims, **opts|
        SimpleApp::Command::Smack.run(*victims, weapon: weapon)
      end
    end

    parse_and_run
  end
end
