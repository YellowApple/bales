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
  end

  class Command < Bales::Command
    action do
      Bales::Command::Help.run
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
```

And like this (assuming the above script lives in `/usr/local/bin/simple-app`)!

```
$ simple-app smack
You have been smacked.
$ simple-app smack foo
foo has been smacked.
$ simple-app Fred Wilma
Fred has been smacked.
Wilma has been smacked.
$ simple-app smack John -w fish
John has been smacked with a fish.
$ simple-app smack John --with fish
John has been smacked with a fish.
$ simple-app smack John --with=fish
John has been smacked with a fish.
```

## So how does it work?

A Bales app is basically a collection of classes: one class representing the application itself (`SimpleApp::Application` in the above example) and one or more classes representing the application's commands (`SimpleApp::Command` and its children in the above example).

The application has (or *will* have, more precisely; I don't have a whole lot for you on this front just yet) a few available DSL-ish functions for you to play with.

* `version`: sets your app's version number.  If you use semantic versioning, you can query this with the `major_version`, `minor_version`, and `patch_level` class methods.

## What kind of a silly names is "Bales", anyway?

It's shamelessly stolen^H^H^H^H^H^Hborrowed from Jason R. Clark's "Testing the Multiverse" talk at Ruby on Ales 2015 (which, if you haven't watched, you [totally should](http://confreaks.tv/videos/roa2015-testing-the-multiverse)).  Sorry, Jason.  Hope you don't mind.