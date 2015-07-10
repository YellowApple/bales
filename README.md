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
$ simple-app smack Fred Wilma
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

* Come up with a name for your app, like `MyApp`
* Create an `Application` class under that namespace which inherits from `Bales::Application`
* Create a `Command` class under that namespace which inherits from `Bales::Command`
* Give that `Command` an `action`, which will be what your application does by default if no valid subcommands are passed to it
* (Optional) Create one or more classes under the `MyApp::Command` namespace, inheriting from some subclass of `Bales::Command` (including the base command you defined previously), if you want some git-style or rails-style subcommands.

Basically, a Bales app is just a bunch of classes with some fairy dust that turns them into runnable commands.  Bales will check the namespace that your subclass of `Bales::Application` lives in for a `Command` namespace, then search there for available commands.

The application has (or *will* have, more precisely; I don't have a whole lot for you on this front just yet) a few available DSL-ish functions for you to play with.

* `version`: sets your app's version number.  If you use semantic versioning, you can query this with the `major_version`, `minor_version`, and `patch_level` class methods.

Meanwhile, commands *also* have some DSL-ish functions to play around with.

* `option`: defines a command-line option, like `--verbose` or `-f` or something.  It takes the name of the option (which becomes a key in your command's options hash) and some named parameters:
  * `:type`: a valid Ruby class, like `String`.  For a boolean, you should provide either `TrueClass` or `FalseClass`, which - when set - will set the option in question to `true` or `false` (respectively).
  * `:short_form`: a short flag, like `'-v'`.  You must specify this if you want a short flag.
  * `:long_form`: a long flag, like `'--verbose'`.  This will be created from the option's name if you don't override it here.
  * `:description`: a quick description of the option, like `"Whether or not to be verbose"`.
* `action`: defines what the command should do when it's called.  This is provided in the form of a block.  Said block should accept two arguments (an array of arguments and a hash of options), though you don't *have* to name them with pipes and stuff if you know that your command won't take any arguments or options.

## What kind of a silly names is "Bales", anyway?

It's shamelessly stolen^H^H^H^H^H^Hborrowed from Jason R. Clark's "Testing the Multiverse" talk at Ruby on Ales 2015 (which, if you haven't watched, you [totally should](http://confreaks.tv/videos/roa2015-testing-the-multiverse)).  Sorry, Jason.  Hope you don't mind.

## What's the license?

MIT License

Copyright (c) 2015 Ryan S. Northrup

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.