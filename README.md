TerminalPoint lets you create beautifully minimalist slides presentations for display in a terminal, with `less -r`.  The configuration language is a simple Ruby DSL.

# Usage

```
./terminalpoint presentation.tpt | less -r
./terminalpoint --config
./terminalpoint --colors
```

Then just use normal `less` hotkeys to page through the presentation:
 - PgDown or Space advances
 - PgUp goes back a slide
 - `g` goes to the beginning
 - `G` goes to the end

# Requirements

Ruby

# Examples

```
slide
	title "Learn to use TerminalPoint"
	bullet "It's easier than you think!"
	bullet "Simple markdown works: `backticks`, **bold**, *italic*, _underlined_, and __also bold__"
	bullet "Very long lines are automatically wrapped."
```

See the examples directory for more detailed examples of layout, styles, in-line diagrams, and tables.

# Command reference

* `slide` begins a new slide
* `title "Text"` adds a title entry to a slide
* `bullet "Text"` adds a bullet entry to a slide
* `build` pauses display of the current slide.  Hit PgDown or Space to advance.
* `pre "Text"` displays an inline string or diagram, one line or several.  Use it with a Ruby here document:
```
pre <<-'EOF'
 /----------------\
 | draw pictures! |
 \----------------/
EOF
```
* `pre center "Text"` displays an inline string or diagram, centered horizontally.
* `table [ [ "a", "b" ], [ "c", "d" ] ]` adds a table to the current slide.  It's OK to declare your rows across several lines of the `.tpt` file.
* `config "key", value` alters a configuration value, for layout and styling.
* `color "key", value` adds a new custom color to the COLOR array, to be used by `fmt`.  The key can be any name (no spaces), and the value is a space-separated list of existing style names or six-digit hex colors.  For example: `color "pink", "#ff8899"`.
* `fmt "style", "text"` applies styles to a string of text.  Each style is a key from the COLOR array (as listed by `./terminalpoint --colors`) or a six-digit hex color.  Multiple styles are allowed, separated by spaces.  This can be used anywhere a text string is expected, or interpolated into a text string.  For example, `bullet "My favorite gourd is a #{fmt 'orange', 'pumpkin'}."`
