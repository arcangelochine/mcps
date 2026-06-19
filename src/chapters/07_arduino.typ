#import "@preview/bookly:3.1.0": *

#let abs = [
  Embedded systems are computer systems designed to perform a single dedicated
  function, tightly integrated with the hardware and mechanical environment they
  control. Programming them differs fundamentally from programming
  general-purpose computers: memory is scarce, user interfaces are absent or
  minimal, operating systems are optional or radically simplified, and timing
  correctness is as important as functional correctness. This chapter examines
  the architecture and programming model of embedded systems, contrasting two
  representative approaches to the fundamental problem of hardware interaction
  under severe memory constraints: the synchronous event loop of Arduino and the
  event-driven task model of TinyOS. The Arduino platform is then examined in
  depth as a concrete and widely used case study, covering its sketch structure,
  external interrupt interface, and sleep mode mechanisms for energy management.
  The recurring tension throughout is the conflict between _simplicity_ and
  _responsiveness_: the synchronous loop model is easy to reason about and
  requires minimal runtime support, but it cannot respond to hardware events
  without polling; the interrupt-driven model enables immediate response to
  asynchronous events but introduces shared-state hazards and demands careful
  design of handler boundaries.
]

#chapter(
  title: "Arduino",
  abstract: abs,
  toc: true,
)[

  == What Is an Embedded System?

  An embedded system is a computer system designed and built to perform a
  single, dedicated function—or a tightly scoped set of related functions—rather
  than serving as a general-purpose computing platform. The defining
  characteristic is that the hardware and software are co-designed: unlike a PC,
  which runs arbitrary software written after the hardware was manufactured, an
  embedded system's hardware is chosen or designed specifically for the software
  that will run on it, and the software is written specifically for that
  hardware. This _hardware-software co-design_ philosophy pervades every aspect
  of embedded development, from the choice of processor and memory capacity to
  the organization of the software and the strategies used to manage energy.

  Embedded systems typically take the form of a _microcontroller_—a single chip
  that integrates a microprocessor, program memory (usually flash), data memory
  (usually SRAM), and a collection of input/output interfaces on a single piece
  of silicon, optimized for controlling I/O rather than for general computation.
  The microcontroller is embedded within a larger electro-mechanical device—a
  sensor node, a motor controller, a medical instrument, a household
  appliance—to which it provides computational intelligence and control. Because
  the device being controlled operates in the physical world, embedded systems
  often face _real-time constraints_: the software must produce its outputs
  within specified time bounds, not merely produce correct outputs eventually.

  Microcontrollers span a wide spectrum of capability. Some are general-purpose
  devices adaptable to many applications; others are _Application-Specific
  Integrated Circuits_ (ASICs) designed for a particular product or function.
  The term _System on a Chip_ (SoC) is used for highly integrated devices that
  may incorporate processors, memory, radios, and other peripherals; though the
  term is broader and less precise than "microcontroller," it often describes
  the chips at the heart of smartphones and more powerful IoT gateways. Popular
  development platforms in the educational and prototyping ecosystem include
  Arduino (based on Atmel AVR microcontrollers) and Raspberry Pi (a full
  single-board computer running Linux), which sit at very different points on
  the capability spectrum.

  == Programming Challenges for Embedded Systems

  Several characteristics of embedded platforms make programming them
  qualitatively different from programming desktop or server software, and
  understanding these differences is necessary before examining any specific
  platform.

  === Memory Constraints

  The most immediately striking difference is the radical scarcity of memory. A
  typical Arduino Uno has 32 KB of flash memory for program storage, 2 KB of
  SRAM for runtime data (variables, buffers, stack), and 1 KB of EEPROM for
  persistent user data. By comparison, a contemporary desktop system measures
  its memory in gigabytes. These constraints are not incidental: they reflect
  the cost, power, and area requirements of the target application. More memory
  means more cost per unit, and at the scale at which IoT devices are
  deployed—thousands or millions of units—per-unit cost differences of cents
  matter. Programming within these constraints demands unusual creativity:
  algorithms must be chosen for code size as well as correctness, data
  structures must be minimal, and memory reuse must be explicit and aggressive.

  === Timing Correctness

  In embedded control systems, _timing correctness_ is as important as
  functional correctness, and for safety-critical applications it may be the
  more important of the two. A GPS navigation system that correctly identifies
  waypoints but reports them too late for the driver to respond is functionally
  correct but useless. A medical infusion pump that delivers the correct dosage
  but does so outside the specified timing window may harm the patient. This
  requirement for temporal precision influences the choice of operating system
  (or lack thereof), the structure of the software, and the use of hardware
  timers and interrupts.

  === Reliability and Debuggability

  Many embedded systems are deployed in hostile or inaccessible environments and
  must operate without maintenance for months or years. High reliability
  requirements—expressed in terms of availability, mean time between failures,
  or maximum allowable downtime—must be met in the presence of unpredictable
  environmental disturbances: temperature extremes, vibration, electromagnetic
  interference, and unexpected input sequences. At the same time, embedded
  systems are notoriously difficult to debug. They cannot run a conventional
  debugger: there is no display on which to observe variable values, no keyboard
  through which to issue commands, and no file system in which to write log
  entries. Defects must be detected and diagnosed through minimal output
  mechanisms—serial communication, LED indicators, oscilloscope traces—making
  correctness-by-construction more important than in desktop development.

  === Power Management

  Energy consumption is a first-class design constraint for battery-powered
  embedded systems. The previous chapters established that the duty cycle of
  each subsystem—processor, radio, sensors—determines device lifetime, and that
  lifetime can vary by orders of magnitude between a well-managed and a
  poorly-managed duty cycle. Embedded software must therefore include explicit
  mechanisms to reduce power consumption during idle periods, switching each
  subsystem to its lowest-power state as soon as its current task is complete.

  == Operating System Strategies for Embedded Systems

  The role of the operating system in an embedded platform depends strongly on
  the device's memory and processing capacity. At one extreme, the most
  constrained microcontrollers run in _bare-metal_ mode: a single application
  runs directly on the hardware, managing all peripherals and interrupt handlers
  itself, with no OS between the application and the hardware. Libraries may
  provide abstractions for common operations (UART communication, ADC reading,
  timer management), but these are statically linked into the application
  binary; there is no dynamic loading, no process isolation, and no system call
  interface. The `main` function, provided by the runtime support library,
  performs hardware initialization and then either enters a perpetual loop or
  activates the application's tasks.

  More capable embedded platforms support lightweight operating systems
  specifically designed for the constraints of the domain. Such an OS has a
  small memory footprint, minimal runtime overhead, real-time scheduling
  features (deterministic response to hardware events), and often no filesystem.
  Development requires a _cross-compilation_ toolchain: code is written and
  compiled on a general-purpose host computer (typically a laptop or
  workstation) using a compiler that targets the embedded processor's
  instruction set, not the host's. The resulting binary is then uploaded to the
  device's flash memory over a programming interface (USB, UART, or a dedicated
  programming bus such as JTAG). This separation between development host and
  execution target complicates debugging, since the two environments are
  physically distinct.

  == Two Programming Models: Arduino and TinyOS

  The fundamental challenge that all low-memory embedded programming models must
  address is how to handle hardware interactions—which are inherently
  asynchronous—without maintaining multiple threads, each of which requires its
  own stack and context storage. In a conventional OS, a thread that initiates
  an I/O operation is suspended until the operation completes, with its entire
  execution context (registers, program counter, stack) saved in memory so it
  can be resumed. On a device with 2 KB of total SRAM, maintaining even a few
  thread contexts of this kind consumes a significant fraction of available
  memory. Two different design philosophies have emerged in response.

  === The Arduino Synchronous Loop Model

  Arduino's programming model organizes all device behavior into two functions.
  The `setup()` function runs once at startup and performs hardware
  initialization—configuring pin directions, initializing communication
  interfaces, setting interrupt handlers. The `loop()` function runs repeatedly
  and indefinitely thereafter, implementing the device's main activity in a
  single thread. There is no preemptive multitasking, no blocking wait that
  suspends the thread, and no stack-switching: if an I/O operation takes time to
  complete, the single thread simply waits in place until it does.

  This model is extremely simple to understand and implement. It maps naturally
  onto the duty cycle structure of sensing and control applications: read from a
  transducer, process the reading, control an actuator, optionally communicate
  with another device, then repeat. Because there is only one thread, there are
  no race conditions between concurrent threads, no need for mutual exclusion
  primitives, and no risk of stack overflow from multiple
  simultaneously-suspended contexts. The `loop()` function can call other
  functions freely; the call stack grows and shrinks as those functions execute,
  but it never accumulates the stacked contexts of multiple suspended threads.

  The limitation is responsiveness. A device executing a long delay—waiting for
  a sensor to stabilize, pausing between measurements, sleeping for a fixed
  interval—cannot respond to external events during that time unless it checks
  for them explicitly at each iteration. The synchronous model couples the
  response latency to asynchronous events to the duration of a loop iteration,
  which may be unacceptably long for events that require immediate attention.

  === The TinyOS Event-Driven Model

  TinyOS, developed at UC Berkeley for the Mica family of mote-class sensor
  nodes, addresses the responsiveness problem with a different programming model
  organized around _events_, _commands_, and _tasks_. Commands are function
  calls that initiate hardware operations; rather than blocking until the
  operation completes, a command returns immediately and the hardware operation
  proceeds asynchronously. When the hardware operation finishes, it generates an
  _event_—conceptually an upcall into the application—which invokes a handler
  function registered by the programmer. Events can preempt running tasks,
  ensuring immediate response to hardware activity, but tasks cannot preempt
  each other.

  _Tasks_ are the units of deferred computation: event handlers that need to
  perform substantial processing beyond what is appropriate in an interrupt
  context post a task to a queue; the runtime support dequeues and executes
  tasks sequentially in a non-preemptive fashion. Because tasks are
  non-preemptive, no context-switching between tasks is needed—a task runs to
  completion, then the next task begins. This eliminates the stack-per-thread
  overhead of conventional threading while preserving the ability to respond
  immediately to hardware events (through event handlers) and to defer longer
  computations safely (through tasks).

  The discipline imposed on event handlers is important: they must be short. An
  event handler that takes a long time to execute delays the delivery of
  subsequent events, potentially missing time-sensitive signals. The canonical
  pattern is for an event handler to update a data structure (recording that
  some hardware event occurred) and post a task to process the data, then return
  immediately. The task then executes the processing at lower priority, after
  all pending event handlers have completed. This separation of immediate
  response (event handler) from subsequent processing (task) is a recurring
  idiom in real-time and embedded programming.

  The TinyOS flow of execution illustrates the pattern concretely. A timer
  fires, triggering a timer event handler that sets a timer for the next period
  and posts a data-collection task. The task initiates a sensor read command.
  When the sensor read completes, a read-done event handler fires, stores the
  reading, and posts a transmission task. The transmission task initiates a
  radio send command. When the send completes, a send-done handler fires,
  potentially posting further tasks. At no point does any handler or task block
  waiting for I/O; the processor is continuously productive, moving between
  event handlers and tasks with no idle time.

  == Arduino: Platform and Programming

  === Hardware Overview

  Arduino is an open-source electronics prototyping platform that combines
  accessible hardware with a simplified software environment, making
  microcontroller programming approachable to non-specialists while remaining
  capable enough for serious embedded development. The core of the Arduino
  concept is the integration of a hardware board, an integrated development
  environment (IDE), and an active community that provides libraries and
  support.

  The Arduino Uno, the most widely used variant, is based on the Atmel
  ATmega328P microcontroller. Its memory specifications are representative of
  the constraints discussed above: 32 KB of flash for program storage, 2 KB of
  SRAM for runtime data, and 1 KB of EEPROM for persistent configuration. The
  board exposes the microcontroller's I/O pins through standardized connectors,
  allowing _shields_—add-on boards providing specific capabilities such as
  wireless communication, motor control, or GPS—to be stacked on top of the base
  board. The ATmega328P's I/O capabilities include both digital pins (reading
  and writing HIGH/LOW binary values) and analog input pins (reading values in
  the range 0–1023 via an on-chip analog-to-digital converter).

  === Sketch Structure and Language

  An Arduino program—called a _sketch_—is written in a C-like language compiled
  with the avr-gcc cross-compiler toolchain, which produces ATmega machine code
  from the source. Every sketch must define at least two functions: `setup()`,
  which runs once when the device powers on or resets and performs all
  initialization, and `loop()`, which runs repeatedly thereafter and implements
  the device's main behavior. The runtime support library provides the `main()`
  entry point, which calls `setup()` once and then calls `loop()` in an infinite
  loop; the programmer never writes `main()` directly.

  The Arduino standard library provides functions covering the major categories
  of embedded I/O: digital I/O (`pinMode()`, `digitalRead()`, `digitalWrite()`),
  analog I/O (`analogRead()`, `analogWrite()` for PWM output), advanced I/O
  (`tone()` for frequency generation, `shiftOut()` and `shiftIn()` for serial
  shifting), timing (`millis()` for elapsed milliseconds, `delay()` for fixed
  pauses), mathematical operations, random number generation, and communication
  (the `Serial` object for UART communication with a host computer). The library
  ecosystem is extensive, covering virtually every common sensor, actuator,
  display, and communication peripheral.

  A representative sketch illustrates the programming model clearly. In
  `setup()`, the serial communication interface is initialized at 9600 baud, and
  the relevant pins are configured as inputs or outputs via `pinMode()`. In
  `loop()`, the digital state of an input pin is read with `digitalRead()`, and
  if a button is pressed, an analog voltage is measured with `analogRead()`,
  converted to a floating-point voltage value, and transmitted over the serial
  interface with `Serial.println()`. The entire sensing, computing, and
  communicating sequence occupies a single iteration of the loop, with no
  threading, no callbacks, and no asynchronous coordination.

  === External Interrupts

  The synchronous polling model is convenient but insufficient for applications
  that must respond to external events with minimal latency. Arduino provides an
  interrupt interface that brings the TinyOS-style event-driven pattern into the
  Arduino context. External interrupts allow a hardware signal transition on a
  specific input pin to trigger an immediate call to a user-defined handler
  function, preempting whatever the `loop()` was doing at the time.

  On the Arduino Uno, two external interrupt pins are available: INT0 mapped to
  digital pin 2, and INT1 mapped to digital pin 3. An interrupt is registered
  with the `attachInterrupt()` function, which takes three arguments: the
  interrupt number (0 or 1 on the Uno), the name of the handler function to
  invoke, and the trigger mode. Four trigger modes are defined. `RISING` fires
  when the pin transitions from LOW to HIGH. `FALLING` fires on the HIGH-to-LOW
  transition. `CHANGE` fires on any transition. `LOW` fires continuously while
  the pin remains in the LOW state (not only on the transition), and similarly
  `HIGH` fires continuously while the pin is HIGH—making both level-triggered
  modes suitable for detecting sustained conditions rather than transient edges.

  Interrupt handlers must be short. Certain operations are forbidden inside an
  interrupt handler: `delay()` does not work (because `delay()` depends on the
  timer interrupt, which is itself suspended while a handler runs), and
  `millis()` does not increment for the same reason. Communication with the
  handler from the rest of the program requires variables declared with the
  `volatile` keyword, which instructs the compiler to always read the variable
  from RAM rather than from a cached register value—without `volatile`, the
  compiler may optimize away repeated reads of a variable it believes cannot
  have changed, missing updates made by the interrupt handler. All variables
  shared between `loop()` and an interrupt handler must be declared `volatile`.

  The `detachInterrupt()` function cancels a previously registered interrupt.
  The `interrupts()` and `noInterrupts()` functions globally enable or disable
  interrupt processing, useful for protecting critical sections in which the
  main code must modify a shared data structure atomically with respect to
  interrupt handlers.

  == Energy Management in Arduino

  Arduino's synchronous polling model as described so far leaves all subsystems
  active throughout every loop iteration, including the delays during which the
  processor merely waits. The `delay()` function pauses execution but does not
  reduce power consumption; the processor and all peripherals remain fully
  powered. To implement the duty cycle management discussed in the previous
  chapter, Arduino must be explicitly configured to enter a low-power sleep
  state during idle periods.

  The ATmega328P provides six sleep modes that offer a spectrum of power
  reduction versus wake-up capability. _Idle_ mode stops the CPU clock and flash
  clock but leaves the SPI, I2C, USART, watchdog, counters, and analog
  comparator active; the device wakes from any internal or external interrupt.
  _ADC Noise Reduction_ mode additionally stops the I/O clock, reducing
  electrical noise during analog-to-digital conversions; it can wake from
  external reset, USART activity, and certain interrupts. _Power-Down_ mode
  stops all generated clocks and disables the external oscillator, leaving only
  the 2-wire serial interface (I2C), watchdog timer, and external interrupt
  circuitry active; it achieves the lowest power consumption but cannot wake
  from timer overflow. _Power-Save_ mode is similar to Power-Down but allows a
  running timer to continue, enabling timer-based wake-up. _Standby_ mode
  resembles Power-Down but keeps the external oscillator running, reducing the
  wake-up time at slightly higher quiescent current. _Extended Standby_ adds a
  running timer to Standby, combining faster wake-up with timer-based
  activation.

  In practice, the LowPower library (available at
  `github.com/rocketscream/Low-Power`) provides a clean interface to these
  modes. A call such as:

  ```cpp
  LowPower.idle(SLEEP_8S, ADC_OFF, TIMER2_OFF, TIMER1_OFF,
                TIMER0_OFF, SPI_OFF, USART0_OFF, TWI_OFF);
  ```

  puts the processor into Idle mode for eight seconds, with the ADC, all timers,
  SPI, USART, and I2C interfaces all powered down, then wakes the device
  automatically at the end of the interval. Predefined sleep durations range
  from 15 ms to 8 s, with a `SLEEP_FOREVER` option that causes the device to
  sleep until interrupted by an external event.

  The power-down mode is the most aggressive sleep option and is appropriate
  when the device does not need any internal periodic activity during sleep. It
  can be combined with external interrupts to wake on demand:

  ```cpp
  attachInterrupt(0, wakeUp, LOW);
  LowPower.powerDown(SLEEP_FOREVER, ADC_OFF, BOD_OFF);
  detachInterrupt(0);
  ```

  This sequence registers an interrupt on pin 2 that will wake the device when
  the pin goes LOW, puts the processor into Power-Down mode indefinitely,
  and—after the device wakes—deregisters the interrupt before proceeding with
  the loop body. The Brown-Out Detection (BOD) circuit, which monitors the
  supply voltage and resets the processor if it falls below a threshold, is also
  disabled (`BOD_OFF`) to save additional current. The device is therefore in
  its lowest-power state, consuming only the microamperes drawn by the watchdog
  and interrupt circuitry, until a physical signal arrives on the interrupt pin.

  This pattern—sleep until interrupted, process the event, sleep again—is the
  embedded realization of the duty cycle concept developed in the previous
  chapter. The Arduino interrupt and sleep APIs together implement, at the
  software level, the energy management strategy that the MAC protocol chapter
  addressed at the network level: minimize the time each subsystem spends
  powered on, activate precisely when needed, and return to the lowest
  appropriate power state as soon as the immediate task is complete.

]
