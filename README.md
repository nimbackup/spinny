Spinny
============

Spinny is a tiny terminal spinner package for [Nim Programming Language](https://nim-lang.org).

## Getting Started

You can use Nimble to install the package by running:
```
nimble install spinny
```

This library uses threads for running in the background, so you must compile your application
(or add to your ``nim.cfg`` or ``config.nims``):
```
--threads:on
```


## Usage

Spinny is quite easy to use. You can set the color, text or symbol of an already running spinner.
Spinny also optinally supports showing passed time (in seconds and hours).

Be aware that you can only have **one** active spinner at any given moment!

```nim
import spinny, os

var spinner1 = newSpinny("Loading file..".fgWhite, skDots)
spinner1.setSymbolColor(fgBlue)
spinner1.start()

# do some work here
for x in countup(5, 10):
  sleep(500)

spinner1.success("File was loaded successfully.")

# Also show time
var spinner2 = newSpinny("Downloading files..".fgBlue, skDots5, time = true)
spinner2.setSymbolColor(fgLightBlue)
spinner2.start()

# do some work here
for x in countup(5, 10):
  sleep(500)

spinner2.error("Sorry, something went wrong during downloading!")
```

You can even use custom spinners if predefined ones aren't suitable for your needs.

```nim
import spinny, os

# makeSpinner accepts two arguments - the interval between different frames,
# and frames themselves as an array or a sequence of strings
var spinner3 = newSpinny("I'm custom.", makeSpinner(100, ["x", "y"]))
spinner3.setSymbolColor(fgGreen)
spinner3.start()

# do some magnificent work here
for x in countup(1, 5):
  sleep(500)

spinner3.success("Looks like it's working!")
```

Spinny embeds the [colorize](http://github.com/molnarmark/colorize) library for terminal colors.
For spinners to use, take a look at the ``src/spinners.nim`` file. (Credit goes to [sindresorhus](https://github.com/sindresorhus/cli-spinners))


## API Reference

The following procs are available on a `Spinny` object:

* `setSymbolColor*(spinny: Spinny, color: proc(x: string): string)`
* `setSymbol*(spinny: Spinny, symbol: string)`
* `setText*(spinny: Spinny, text: string)`
* `start*(spinny: Spinny)`
* `stop*(spinny: Spinny)`
* `success*(spinny: Spinny, msg: string)`
* `error*(spinny: Spinny, msg: string)`