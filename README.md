A simple, unopinionated asset pipline / static site generator / whatever.

I use it for [my blog](http://github.com/dashkb/dashkb.github.io/tree/source).

##### Features

* Compiles LESS/HAMLC/CoffeeScript/Markdown into a static site
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

I'm working on publishing to NPM; hopefully getting ownership of `fetool`.  Until
then, we'll install from GH.

* `npm install -g git://github.com/dashkb/fetool`
* `npm install -g bower`
* `mkdir project-folder`
* `cd project-folder`
* `bower install --save jquery bootstrap font-awesome`
* `mkdir fe/`


Then create some files:

`fe/fe.coffee`
```coffeescript
$ = require 'jquery'

$ ->
  console.log 'The DOM is loaded!'
```

`fe/fe.less`
```css
@import 'bootstrap/less/bootstrap';
@import 'font-awesome/less/font-awesome';

body {
  styles: awesome;
}
```

`fe/fe.hamlc`
```haml
!!! 5
%html
  %head
    %title= @page.title
...
```

`fe/index.md`
```markdown
---
title: Amazing Site
slug: index
---

Some *markdown* content.
```

And run the tool

* `fetool`

You'll see the output in `public`.

Run `fetool dev` to recompile on changes, and start a static webserver.

#### Configuring

The tool accepts some options.  Run `fetool help` to see the defaults.

* `--bowerDir` You can `require('package-installed-with-bower')` from your front-end code.  If you have your `bower_components` somewhere non-standard (i.e. not `project-root/bower_components`) specify it here.
* `--srcDir, -s` The directory your front-end source (coffee/less/md) lives
* `--buildDir, -b` The directory your compiled, static site lives
* `--tmpDir` A temporary directory for compilation artifacts, safe to delete at any time
* `--mainScript, -m` The name of your main coffeescript file
* `--mainTemplate` The name of your main template (hamlc) file
* `--compress` True to uglify/compress your js/css output
* `--verbose, -v` Enable debugging output.  Specify more v's for more output.
* `--quiet, -q` Disable all output

#### dotfe file

Put a `.fe` file in your project root to override the default for any option.  We'll
auto detect the format of your file (json, yaml, and dotfile format are supported).
Be sure to use camelCased, long-option-form of the options.  Run `fetool help` to
see your settings; it will reflect the settings from your `.fe` file.
