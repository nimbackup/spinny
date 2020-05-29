import os, spinny

proc main = 
  # Use the default terminal colour for text
  var spinner1 = newSpinny("Loading file..", skDots)
  spinner1.setSymbolColor(fgBlue)
  spinner1.start()

  for x in countup(5, 10):
    sleep(500)

  spinner1.success("File was loaded successfully.")

  # Also show time
  var spinner2 = newSpinny("Downloading files..".fgBlue, skDots5, time = true)
  spinner2.setSymbolColor(fgLightBlue)
  spinner2.start()

  for x in countup(5, 10):
    sleep(500)

  spinner2.error("Sorry, something went wrong during downloading!")

  var spinner3 = newSpinny("I'm custom.", makeSpinner(100, ["x", "y"]))
  spinner3.setSymbolColor(fgGreen)
  spinner3.start()

  for x in countup(1, 5):
    sleep(500)

  spinner3.success("Looks like it's working!")

main()