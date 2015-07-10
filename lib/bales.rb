# :main: README.md

require 'bales/application'
require 'bales/command'
require 'bales/command/help'

##
# Ruby on Bales (or just "Bales" for short) is to command-line apps what
# Ruby on Rails (or just "Rails" for short) is to websites/webapps.
#
# The name (and concept) was shamelessly stolen from Jason R. Clark's
# "Testing the Multiverse" talk at Ruby on Ales 2015.  Here's to hoping that
# we, as a Ruby programming community, can get a headstart on a command-line
# app framework *before* the Puma-Unicorn Wars ravage the Earth.
module Bales
end

# Helper stuff; please ignore
class String
  def underscore
    self.
      gsub(/::/, '/').
      gsub(/([A-Z]+)([A-Z][a-z])/, '\1_\2').
      gsub(/([a-z\d])([A-Z])/, '\1_\2').
      tr('-', '_').
      downcase
  end
end
