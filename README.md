# Ruby on Bales

![bales](https://upload.wikimedia.org/wikipedia/commons/2/2c/DavidBrown-Verdon.jpg)

## What is it?

It's a framework for writing command-line applications.

## What does it look like?

Why, like this!

```ruby
#!/usr/bin/env ruby
# /usr/local/bin/simple-app
require 'bales'

module SimpleApp
  class Application < Bales::Application
    version "0.0.1"
    description "Sample app"
    
    # Default action
    option :recipient,
           long_form: '--to',
           short_form: '-2',
           type: String
           
    action do |recipient: "world"|
      puts "Hello, #{recipient}!"
    end
    
    # Subcommand
    command "smack" do
      option :weapon,
             type: String,
             description: "Thing to smack with",
             short_form: '-w',
             long_form: '--with'
             
      action do |*victims, weapon: nil|
        suffix = weapon ? " with a #{weapon}" : ""
        
        if victims.none?
          puts "You have been smacked#{suffix}."
        else
          victims.each {|v| puts "#{v} has been smacked#{suffix}."}
        end
      end
    end
    
    # Specify subcommand's parent class
    command "help", parent: Bales::Command::Help
    
    # Subsubcommands!
    command "smack with" do
      action do |weapon, *victims|
        SimpleApp::Command::Smack.run(*victims, weapon: weapon)
      end
    end
    
    # This is what makes the app actually run!
    parse_and_run
  end
end

SimpleApp::Application.parse_and_run
```

And like this (assuming the above script lives in
`/usr/local/bin/simple-app`)!

```
$ simple-app
Hello, world!
$ simple-app -2 Bruce
Hello, Bruce!
$ simple-app --to Bruce
Hello, Bruce!
$ simple-app smack
You have been smacked.
$ simple-app smack Bruce
Bruce has been smacked.
$ simple-app smack Bruce Bruce
Bruce has been smacked.
Bruce has been smacked.
$ simple-app smack Bruce --with fish
Bruce has been smacked with a fish.
$ simple-app smack with fish Bruce
Bruce has been smacked with a fish.
```

## So how does it work?

* Come up with a name for your app, like `MyApp`

* Create an `Application` class under that namespace which inherits
  from `Bales::Application`

* Use the DSL (or define classes manually, if that's your thing)

Basically, a Bales app is just a bunch of classes with some fairy dust
that turns them into runnable commands.  Bales will check the
namespace that your subclass of `Bales::Application` lives in for a
`Command` namespace, then search there for available commands.

The application has a few available DSL-ish functions for you to play with.

* `version`: sets your app's version number.  If you use semantic
  versioning, you can query this with the `major_version`,
  `minor_version`, and `patch_level` class methods.

* `command "foo" { ... }`: defines a subcommand called "foo", which
  turns into a class called `MyApp::Command::Foo` (if you picked the
  name `MyApp` above).  If you provide a block, said block will be
  evaluated in the class' context (see below for things you can do in
  said context).

Meanwhile, commands *also* have some DSL-ish functions to play around with.

* `option`: defines a command-line option, like `--verbose` or `-f` or
  something.  It takes the name of the option (which becomes a key in
  your command's options hash) and some named parameters:

  * `:type`: a valid Ruby class, like `String`.  For a boolean, you
    should provide either `TrueClass` or `FalseClass`, which - when
    set - will set the option in question to `true` or `false`
    (respectively).
  
  * `:short_form`: a short flag, like `'-v'`.  You must specify this
    if you want a short flag.
  
  * `:long_form`: a long flag, like `'--verbose'`.  This will be
    created from the option's name if you don't override it here.
  
  * `:description`: a quick description of the option, like `"Whether
    or not to be verbose"`.
  
* `action`: defines what the command should do when it's called.  This
  is provided in the form of a block.  Said block should accept two
  arguments (an array of arguments and a hash of options), though you
  don't *have* to name them with pipes and stuff if you know that your
  command won't take any arguments or options.

* `description`: sets a long description of what your command does.
  Should be a string.

* `summary`: sets a short description of what your command does.
  Should be a string.  Should also be shorter than `:description`,
  though this isn't strictly necessary.

Some of the command functions (`option`, `action`, `description`,
`summary`) can also be used from within the application class; doing
so will define and configure a "root command", which is what is run if
you run your app without any arguments.

## What can this thing already do?

* Create a working command-line app

* Automatically produce subcommands (recursively, in fact) based on
  the namespaces of the corresponding `Bales::Command` subclasses

* Provide a DSL defining commands and options

## What might this thing someday do in the future?

* Provide some helpers to wrap things like HighLine, curses, etc.

* Provide some additional flexibility in how options are specified
  without requiring users to completely reimplement a command's option
  parsing functions

## What kind of a silly name is "Bales", anyway?

It's shamelessly stolen^H^H^H^H^H^Hborrowed from Jason R. Clark's
"Testing the Multiverse" talk at Ruby on Ales 2015 (which, if you
haven't watched, you [totally
should](http://confreaks.tv/videos/roa2015-testing-the-multiverse)).
Sorry, Jason.  Hope you don't mind.

Ironically enough, despite ripping off the name from a talk about Ruby
testing, Bales currently lacks any formal test suite.  Hm...

## What's the license?

MIT License; see COPYING for details.
