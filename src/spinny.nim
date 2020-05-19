import std/[os, terminal, locks, times, monotimes, sequtils]

import spinny/[colorize, spinners]

export colorize
export SpinnerKind, Spinner, makeSpinner

type
  Spinny = ref object
    t: Thread[Spinny]
    lock: Lock
    text: string
    running: bool
    frames: seq[string]
    frame: string
    interval: int
    customSymbol: bool
    trackTime: bool
    startTime: MonoTime

  EventKind = enum
    Stop, StopSuccess, StopError,
    SymbolChange, TextChange,

  SpinnyEvent = object
    kind: EventKind
    payload: string

var spinnyChannel: Channel[SpinnyEvent]

proc newSpinny*(text: string, s: Spinner, time = false): Spinny =
  result = Spinny(
    text: text,
    running: true,
    frames: s.frames,
    customSymbol: false,
    interval: s.interval,
    trackTime: time
  )

proc newSpinny*(text: string, spinType: SpinnerKind, time = false): Spinny =
  newSpinny(text, Spinners[spinType], time)

proc setSymbolColor*(spinny: Spinny, color: proc(x: string): string) =
  spinny.frames = mapIt(spinny.frames, color(it))

proc setSymbol*(spinny: Spinny, symbol: string) =
  spinnyChannel.send(SpinnyEvent(kind: SymbolChange, payload: symbol))

proc setText*(spinny: Spinny, text: string) =
  spinnyChannel.send(SpinnyEvent(kind: TextChange, payload: text))

proc handleEvent(spinny: Spinny, eventData: SpinnyEvent): bool =
  result = true
  case eventData.kind
  of Stop:
    result = false
  of SymbolChange:
    spinny.customSymbol = true
    spinny.frame = eventData.payload
  of TextChange:
    spinny.text = eventData.payload
  of StopSuccess:
    spinny.customSymbol = true
    spinny.frame = "✔".bold.fgGreen
    spinny.text = eventData.payload.bold.fgGreen
  of StopError:
    spinny.customSymbol = true
    spinny.frame = "✖".bold.fgRed
    spinny.text = eventData.payload.bold.fgRed

proc timeDiff(d: Duration): string =
  # TODO: Handle hours?
  let minutes = d.inMinutes()
  let seconds = d.inSeconds()
  result.add if minutes > 9: $minutes
  else: "0" & $minutes
  result.add ":"
  result.add if seconds > 9: $seconds
  else: "0" & $seconds

proc spinnyLoop(spinny: Spinny) {.thread.} =
  var frameCounter = 0
  # Store the starting time here
  spinny.startTime = getMonoTime()

  while spinny.running:
    let data = spinnyChannel.tryRecv()
    if data.dataAvailable:
      # If we received a Stop event
      if not spinny.handleEvent(data.msg):
        spinnyChannel.close()
        # This is required so we can reopen the same channel more than once
        # See https://github.com/nim-lang/Nim/issues/6369
        spinnyChannel = default(typeof(spinnyChannel))
        # TODO: Do we need spinny.running at all?
        spinny.running = false
        break

    stdout.flushFile()
    if not spinny.customSymbol:
      spinny.frame = spinny.frames[frameCounter]
    var text = spinny.text
    if spinny.trackTime:
      text = timeDiff(getMonoTime() - spinny.startTime) & " " & text

    withLock spinny.lock:
      eraseLine()
      stdout.write(spinny.frame & " " & text)
      stdout.flushFile()

    sleep(spinny.interval)

    if frameCounter >= spinny.frames.len - 1:
      frameCounter = 0
    else:
      frameCounter += 1

proc start*(spinny: Spinny) =
  initLock(spinny.lock)
  spinnyChannel.open()
  createThread(spinny.t, spinnyLoop, spinny)

proc stop(spinny: Spinny, kind: EventKind, payload = "") =
  spinnyChannel.send(SpinnyEvent(kind: kind, payload: payload))
  spinnyChannel.send(SpinnyEvent(kind: Stop))
  joinThread(spinny.t)
  # We need to output a newline at the end
  echo ""

proc stop*(spinny: Spinny) =
  spinny.stop(Stop)

proc success*(spinny: Spinny, msg: string) =
  spinny.stop(StopSuccess, msg)

proc error*(spinny: Spinny, msg: string) =
  spinny.stop(StopError, msg)
