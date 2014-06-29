A simple, unopinionated asset pipline / static site generator / whatever.

I use it for [my blog](http://github.com/dashkb/dashkb.github.io/tree/source).

##### Features

* Compiles (LESS|SASS)/HAMLC/CoffeeScript/Markdown into a static site
* Built with Browserify/Coffeeify/Debowerify
    * `$ = require('jquery')` (really)
* Site structure is available to all templates during rendering
    * Build-Your-Own article index, post listing, etc
* Can deploy to GitHub pages (docs soon)

##### Philosophy

My favorite tools for making web sites are Markdown, CoffeeScript, HAML, and LESS.  For the
most part, I just want all the things compiled and spit out into a folder I can
serve statically.  This does that, and just that.  If you need more, you're a programmer,
and this tool will support you without getting in your way.

Convention or configuration?  I like a healthy combination of sensible defaults and
flexible configuration options.


#### Quick Start

* `npm install -g fec bower`
* `mkdir project-folder`
* `cd project-folder`
* `fec new`
* `fec dev`
    * watches the created directory for changes and recompiles
    * runs a webserver

Browse to <localhost:8080> to see the default site.  Hack away.

#### Anatomy of the created directory

The tool works on directories of scripts, styles, templates, and markdown files.
You may create any directory structure you'd like; but `css`, `js`, `images`, and `fonts`
are reserved by the system.

* **Scripts** are written in javascript or coffeescript.
    * Only the `mainScript` is compiled (`fe.coffee` by default).  Anything you want in the compiled JS must be required from this file.  (This behavior ~~may~~ will be changing soon.)
    * You can `require` anything you install with `npm` or `bower`, or local scripts
* **Styles** are written in less (default) or sass
    * All of your stylesheets are concatenated and processed.  You are responsible for handling load order.
* **Templates** are HAML/Coffeescript templates.  The template's context (`this`) is extended with some useful properties:
    * `@page` - this page's metadata
    * `@page.html` - this page's rendered content
    * `@site` - the other pages' metadata
    * `@JST` - all the templates, as javascript functions
* **Markdown** is where the static content lives
    * They are compiled into html pages in the `buildDir`
    * They are configurable with YAML front-matter
        * `title`: the page's title
        * `slug`: the filename of the compiled file (defaults to slugified title)
        * `template`: a template to wrap the content (optional; output will still be rendered by the main template)
        * Your own data!  It's all available at compile-time to your templates

#### Configuring

The tool accepts some options.  Run `fec help` to see the defaults.

* `--bowerDir` You can `require('package-installed-with-bower')` from your front-end code.  If you have your `bower_components` somewhere non-standard (i.e. not `project-root/bower_components`) specify it here.
* `--srcDir, -s` The directory your front-end source (coffee/less/md) lives
* `--buildDir, -b` The directory your compiled, static site lives
* `--tmpDir` A temporary directory for compilation artifacts, safe to delete at any time
* `--mainScript, -m` The name of your main coffeescript file
* `--mainTemplate` The name of your main template (hamlc) file
* `--mainStylesheet` The name of your main stylesheet file
* `--cssPreprocessor` The preprocessor you'd like to use.  Currently supported: less, sass
* `--compress` True to uglify/compress your js/css output
* `--verbose, -v` Enable debugging output.  Specify more v's for more output.
* `--quiet, -q` Disable all output

#### dotfe file

Put a `.fe` file in your project root to override the default for any option.  We'll
auto detect the format of your file (json, yaml, and dotfile format are supported).
Be sure to use camelCased, long-option-form of the options.  Run `fec help` to
see your settings; it will reflect the settings from your `.fe` file.
