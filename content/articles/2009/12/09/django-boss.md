--- 
kind: article
created_at: 2009-12-09
title: "Fixing Django Management Commands"
---

At the moment, writing a management command for Django is an unenjoyable
process. Django is supposed to encourage [DRY][], simple code, yet the
boilerplate required for a management command sticks out like a sore thumb in an
otherwise elegant and reusable app.

  [DRY]: http://en.wikipedia.org/wiki/Don't_repeat_yourself

### The *status quo*

Here’s how we go about creating a management command at the moment.

Our app starts off like this:

    myapp/
    |-- __init__.py
    |-- admin.py
    |-- models.py
    `-- views.py

We then need to add a boilerplate filesystem structure:

    myapp/
    |-- management/
    |   |-- commands/
    |   |   `-- __init__.py
    |   `-- __init__.py
    |-- __init__.py
    |-- admin.py
    |-- models.py
    `-- views.py

Those `__init__.py` files are empty; they tell Python that a directory is a
package, allowing Django to do stuff like `import myapp.management.commands`. Of
course, we don’t actually have any commands yet.

Let’s start off simple. `./manage.py hello` should print the text `Hello,
World!` to the console. First, we create a `myapp.management.commands.hello`
module:

    myapp/
    |-- management/
    |   |-- commands/
    |   |   |-- __init__.py
    |   |   `-- hello.py
    |   `-- __init__.py
    |-- __init__.py
    |-- admin.py
    |-- models.py
    `-- views.py

Now we need to write the command. Open up `hello.py` in your favourite editor
and add the following text:

    from django.core.management.base import NoArgsCommand
    
    class Command(NoArgsCommand):
        help = "Print a cliche to the console."
        
        def handle_noargs(self, **options):
            print "Hello, World!"

Now, from the project where `myapp` is installed, we can run `./manage.py hello`
and the text will be printed to the screen.

But we want to write a command which accepts arguments, right?

    # file: myapp/management/commands/echo.py
    # example: ./manage.py echo some words here
    #   => some words here
    from optparse import make_option
    from django.core.management.base import BaseCommand
    
    class Command(BaseCommand):
        help = "Echo all positional arguments."
        
        option_list = BaseCommand.option_list + [
            make_option('-n', dest='no_newline', action='store_true',
                        default=False, help="Don't print a newline afterwards.")
        ]
        
        def handle(self, *args, **options):
            if options.get('no_newline', False):
                print ' '.join(args), # the comma is significant.
            else:
                print ' '.join(args)

### What’s wrong with this picture?

Everything.

*   The `management/commands/` layout is repeated within every application, with
    no apparent benefits over a simple top-level `commands.py` file in the app
    directory.

*   One module per command is just unwieldy, and rather pointless.

*   You have to use a different superclass depending on whether or not you want
    arguments, or what type of arguments you want to consume (app labels, model
    names, et cetera).

*   You have to override different methods depending on the superclass.

*   `option_list = BaseCommand.option_list + [...]` is horrible.

### I’m not just a critic.

The first step to solving the whole issue is to fix command-line option parsing.
Django uses the stdlib’s `optparse`, which is OK for smaller projects, but is
getting a little long in the tooth. The far-superior [argparse][] offers a much
cleaner all-round experience, as well as the ability to process positional
arguments, variadic arguments and sub-parsers.

  [argparse]: http://code.google.com/p/argparse/

Let’s write a speculative example of how we would *like* to write management
commands. In the file `myapp/commands.py`:

    from django.core.management.commands import *
    
    @command
    def hello(args):
        """Print a cliche to the console."""
        
        print "Hello, World!"
    
    @command
    @argument('-n', '--no-newline', action='store_true',
              help="Don't print a newline afterwards.")
    @argument('words', nargs='*')
    def echo(args):
        """Echo all positional arguments."""
        
        if args.no_newline:
            print ' '.join(args.words),
        else:
            print ' '.join(args.words)

There are a few things to note about this example:

*   The easy case is easy.

*   There's no need to specify a `help` attribute, because that can (and should)
    be gleamed from the docstring itself.

*   Commands are functions. This is Python, not Java.

*   There’s no boilerplate.

*   The `echo()` command’s `words` argument shows how `argparse` can handle
    variadic positional arguments with ease.

*   Decorators are used throughout, but this need not be the case. A
    decorator-less example:

            def echo(args):
            """Echo all positional arguments."""
            
            if args.no_newline:
                print ' '.join(args.words),
            else:
                print ' '.join(args.words)
        
        echo = Command(echo)
        echo.add_argument('-n', '--no-newline', action='store_true',
                          help="Don't print a newline afterwards.")
        echo.add_argument('words', nargs='*')
    
    The `Command` class would wrap the function and provide the `add_argument()`
    method.

### How feasible is this?

This might seem like a difficult feat to pull off. Luckily, `argparse` handles a
lot of it for us. It supports the notion of *sub-parsers*; these are essentially
branches in the parser that allow a multi-tiered structure. The top-level
command has an `ArgumentParser` instance, which has a set of options, followed
by a ‘subparsers’ branch point. To this branch point, multiple `ArgumentParser`
instances are attached. When `argparse` starts processing arguments from the
command line and it hits this branch point, it decides what subparser to use and
then gives all the unparsed arguments to it.

The creation of sub-parsers and their registration on the top-level parser is
all handled by the `@command` decorator and `Command` class. The `@argument`
decorator and `Command.add_argument()` method will be basic wrappers around the
sub-parser’s `add_argument()` method. The decorators will also have to employ a
little behind-the-scenes shuffling to make sure that arguments are added in the
right order, since decorators are applied in reverse order.

It actually takes fewer lines of Python than lines of English to explain
sub-parsers. For an example of the concept in practice, take a look at the [CLI
code][] for my project [Markdoc][].

  [cli code]: http://bitbucket.org/zacharyvoase/markdoc/src/tip/src/markdoc/cli/
  [markdoc]: http://markdoc.org/

In Django, the `manage` command would go through the `INSTALLED_APPS` list,
attempting to import a `commands` submodule from each app. Nothing else would be
necessary, since `@command`/`Command` would automatically register each command
upon import.

### Special argument types

The current system allows you to write commands that take the names of apps and
models as arguments; it deals with resolving the names to the modules/classes in
question, and knows what to do if a non-existent app/model is specified.

Such cases warrant special attention when you’re using `optparse`, because the
library can only handle the `--keyword value` type of argument. However,
`argparse`’s support for positional arguments and custom types mitigates this
problem. If custom `app_label` and `model_name` types were implemented by
Django, code could look like this:

    from django.core.management.commands import *
    
    @command
    @argument('app', type=app_label)
    def models(args):
        """List the models and table names for the specified app."""
        
        from django.db.models import Model
        
        print "Name\tDB Table"
        print '-' * 20
        for name, model in vars(args.app.models).items():
            if isinstance(model, type) and issubclass(model, Model):
                print model.__name__ + '\t' + model._meta.db_table
    
    @command
    @argument('model', type=model_name)
    def fields(args):
        """List the fields for the specified model."""
        
        for field in args.model._meta.fields:
            print field.name

Implementing a custom type just involves writing a function that takes a string
and either returns an object or raises an exception. Furthermore, commands could
take multiple apps/models as arguments (keyword *or* positional).

### Wrap-up

I think all of this could be quite quickly and easily implemented as a
third-party reusable app, so I’m going to do it. In future, I’d like it to be
included in Django proper, but that would have to wait until at least v1.3.

I’m going to go ahead and get started right now; I’d appreciate any comments,
suggestions or criticism.
