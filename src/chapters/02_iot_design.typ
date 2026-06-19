#import "@preview/bookly:3.1.0": *

#let abs = [
  The central engineering challenge of Internet of Things devices is not
  communication or computation in isolation, but the management of a finite
  energy budget shared among all subsystems over a deployment lifetime that may
  span years. This chapter examines energy efficiency as the primary design
  constraint that distinguishes IoT development from conventional embedded
  systems engineering. Beginning with the hardware characteristics of typical
  IoT nodes and the limitations of Moore's Law as a remedy for resource
  constraints, the discussion moves to a quantitative treatment of energy
  consumption across the major subsystems---processor, radio, flash storage, and
  sensors---and introduces the _duty cycle_ as the principal mechanism by which
  IoT devices extend battery life without sacrificing functionality. A formal
  energy model is developed that allows device lifetime to be expressed as a
  closed-form function of duty cycle parameters, battery capacity, and per-cycle
  energy expenditure. The chapter closes by connecting duty cycle management to
  the MAC layer protocols that coordinate sleep schedules across a network,
  establishing the bridge between device-level energy management and
  network-level coordination. The recurring tension is the trade-off between
  _availability_ and _longevity_: a device that is always on is always reachable
  but quickly exhausts its battery, while a device that sleeps most of the time
  may last years but introduces latency, missed events, and synchronization
  complexity.
]

#chapter(
  title: "IoT Design Aspects",
  abstract: abs,
  toc: true,
)[

  == Characteristics and Constraints of IoT Devices

  An IoT device is, at its core, a small autonomous system designed to observe
  or act upon the physical world with minimal human oversight. A typical node
  integrates a microprocessor, program and data memory, a wireless radio
  transceiver, one or more sensing elements (for physical quantities such as
  acceleration, pressure, humidity, light, acoustic signals, temperature, or
  magnetic field), and optionally actuators. Power is supplied by a battery, a
  solar cell, or an energy harvesting element. The device is expected to operate
  correctly for months or years without maintenance, in physical environments
  that may be inaccessible, hostile, or simply inconvenient for human
  intervention.

  These characteristics define a set of design constraints that interact in
  non-trivial ways. Low cost is demanded by the scale at which IoT systems are
  deployed: a building with thousands of sensors cannot tolerate per-unit costs
  that would be unremarkable for a single specialized instrument. Small physical
  size limits the battery capacity and the heat dissipation available to the
  processor. Autonomy requires that the device manage its own energy budget
  without relying on an external power source or human recharging cycles. And
  wireless communication, while essential for deployment flexibility, is among
  the most energy-intensive operations a node performs.

  The result is a design space governed by simultaneous constraints on
  processing power, memory, communication bandwidth, and energy---constraints
  that are tightly coupled and cannot be relaxed independently. Improving
  communication range, for example, requires higher transmit power; running more
  sophisticated algorithms requires more processor cycles; storing more data
  locally requires more flash write operations. Each of these choices draws from
  the same finite energy reservoir.

  == Moore's Law and Its Limits for IoT

  A natural question is whether the historical trajectory of semiconductor
  technology, summarized in Moore's Law, will eventually dissolve these
  constraints. Moore's Law states that the number of transistors that can be
  economically integrated on a chip approximately doubles every two years. The
  Intel 4004 of 1971 contained approximately 2,300 transistors and ran at 740
  kHz; a contemporary high-performance processor integrates 1.8 billion
  transistors and operates at 4.4 GHz. The associated reduction in feature size
  has driven parallel improvements in energy efficiency per operation.

  For IoT, Moore's Law admits three distinct interpretations, each of which is
  simultaneously true and simultaneously insufficient. First, performance
  doubles at constant cost: this benefits IoT nodes that require more
  sophisticated on-device computation, such as running machine learning
  inference on sensor streams. Second, chip area and energy consumption halve at
  constant performance: this reduces the power draw of a given computational
  task, extending battery life. Third, cost halves at constant performance and
  area: this enables larger deployments at fixed budget. All three effects are
  real and materially improve IoT hardware generation over generation.

  Yet Moore's Law does not solve the fundamental problem. Battery energy density
  has improved at a far slower rate than transistor density---roughly three to
  four percent per year over recent decades, compared to the roughly forty
  percent annual improvement in transistor count. The gap between computation
  capability and energy storage has therefore widened over time rather than
  narrowed. Furthermore, IoT deployments are not primarily bottlenecked by raw
  processing power; they are bottlenecked by the energy required to keep a radio
  transceiver operational. The radio dominates the energy budget of most sensor
  nodes, and radio energy consumption does not benefit from Moore's Law at the
  same rate as logic circuits. The practical conclusion is that Moore's Law
  makes IoT devices smaller and cheaper, but it does not eliminate the need for
  careful energy management. Protocol and system design must carry the burden
  that hardware scaling cannot.

  == Energy Consumption Across IoT Subsystems

  To reason quantitatively about energy management, one must first understand
  where energy goes within a typical IoT node. The distribution differs
  substantially from that of a laptop or smartphone. In a laptop, the screen
  dominates energy consumption at roughly 48%, followed by the chipset at 23%,
  the processor at 10%, graphics at 9%, and the hard drive and network interface
  each consuming less than 10%. The processor, though computationally central,
  is a minority consumer.

  In a wireless sensor node, the distribution is entirely different. The
  wireless network interface accounts for approximately 40% of total energy, the
  processor and chipset consume another 40%, and sensing and analog-to-digital
  conversion account for the remaining 20%. This distribution has a critical
  implication: optimizing only the processor has limited impact; the radio and
  processor must both be aggressively managed.

  The energy consumption of the radio subsystem is particularly important to
  understand in detail, because it varies significantly across operating modes
  and exhibits a counterintuitive pattern. A typical WiFi interface draws
  approximately 10 mA in sleep mode, 180 mA while listening for incoming
  transmissions, 200 mA while actively receiving, and 280 mA while transmitting.
  For a sensor-class radio (as found in a mote-class IoT node), the figures are
  lower in absolute terms but structurally similar: sleep mode consumes
  approximately 0.016 mW, while listen, receive, and transmit modes each consume
  roughly 12-18 mW. Two observations follow. First, the energy cost of listening
  for transmissions that may never arrive is almost as large as the cost of
  actively receiving a packet---because in both cases the RF front-end, the
  analog-to-digital converter, and the demodulation circuitry are all powered
  and running. Second, in some radio configurations, the transmit power is less
  than or equal to the receive power, because a lower-power transmitter may
  consume less than the full receive chain. Both observations support the same
  conclusion: the radio should be powered off whenever no communication is
  imminent.

  The processor presents an analogous situation. In a mote-class device such as
  one based on the ATmega128L microcontroller, full operation draws
  approximately 8 mA, while a sleep state reduces this to 15 µA---a reduction of
  over two orders of magnitude. The transition between active and sleep states
  is not free: waking the processor or the radio requires a finite time and a
  finite energy expenditure, which sets a lower bound on the duration of active
  periods below which the overhead of state transitions outweighs the savings
  from sleeping.

  == The Duty Cycle

  The central energy management technique in IoT systems is the _duty cycle_:
  the fraction of a periodic operating cycle during which a component or system
  is in its active state. If a device operates with period $T$ and is active for
  duration $T_"active"$ within each period, its duty cycle is
  $"dc" = T_"active" / T$, commonly expressed as a percentage. A duty cycle of
  100% means the device is always active and never sleeps; a duty cycle of 1%
  means it is active for one hundredth of each period.

  The duty cycle concept is meaningful precisely because IoT device activity is
  repetitive and periodic. A sensor node that measures temperature and transmits
  the measurement every 400 milliseconds performs the same sequence of
  operations in each cycle: power on the sensor, acquire an analog sample and
  convert it digitally (approximately 4 ms), perform any computation on the
  sample (approximately 1 ms), power on the radio and transmit the result
  (approximately 15 ms), then idle until the next cycle (approximately 380 ms).
  Different subsystems have different duty cycles within the same device cycle:
  in this example, the sensor board is active for 4 ms out of 400 ms (1% duty
  cycle), the processor is active for 20 ms out of 400 ms (5% duty cycle), and
  the radio is active for 15 ms out of 400 ms (3.75% duty cycle).

  An implementation that naively leaves all subsystems powered throughout the
  cycle wastes the energy that could be saved by sleeping. Correct energy
  management requires turning off each subsystem as soon as it is no longer
  needed, invoking a low-power sleep or idle state for the processor between
  active phases, and tracking the energy cost of transitions. In a system where
  the processor, radio, flash logger, and sensor board each have independently
  controllable power states, the effective energy consumption per cycle is the
  sum of the energy consumed by each subsystem across all its states during that
  cycle.

  === Per-Subsystem Energy Modeling

  It is useful to formalize these observations into an energy model that enables
  quantitative lifetime estimation. For each subsystem, the energy consumed per
  duty cycle is the weighted sum of the energy costs in each operating mode,
  where the weights are the fractions of the cycle spent in each mode.

  For the microprocessor, let $C_"full"^mu$ denote the energy cost per cycle in
  full-operation mode and $C_"idle"^mu$ the cost in idle (sleep) mode. If the
  processor operates at full power for a fraction $"dc"^mu$ of the duty cycle
  and idles for the remaining fraction, the expected energy cost per duty cycle
  is:

  $ E^mu = "dc"^mu dot C_"full"^mu + (1 - "dc"^mu) dot C_"idle"^mu $

  For the radio, three operating modes must be distinguished: transmit, receive,
  and sleep. Let $"dc"_T^rho$ and $"dc"_R^rho$ denote the fractions of the duty
  cycle spent transmitting and receiving, respectively, with the remainder in
  sleep. The energy per duty cycle is:

  $
    E^rho = "dc"_T^rho dot C_T^rho + "dc"_R^rho dot C_R^rho + (1 - "dc"_T^rho - "dc"_R^rho) dot C_"idle"^rho
  $

  Analogous expressions apply to the flash logger (with write, read, and sleep
  modes) and the sensor board (with active and sleep modes). The total energy
  consumed per duty cycle is the sum across all subsystems:

  $ E = E^mu + E^rho + E^lambda + E^sigma $

  where $E^lambda$ and $E^sigma$ denote the contributions of the logger and
  sensor board, respectively.

  === Battery Lifetime Estimation

  Given the per-cycle energy consumption $E$, the device lifetime can be
  estimated from the battery's initial charge and its self-discharge
  characteristics. Batteries lose charge even when the device draws no
  current---a phenomenon called _self-discharge_ or _battery leakage_---and this
  loss must be accounted for over long deployment periods.

  Let $B_0$ denote the initial battery charge (in milliampere-hours or an
  equivalent energy unit) and $epsilon$ the fraction of remaining charge lost
  per duty cycle due to leakage. The battery charge after $n$ cycles evolves
  according to the recurrence:

  $ B_n = B_(n-1) dot (1 - epsilon) - E $

  Each cycle, the remaining charge is first reduced by the leakage fraction and
  then reduced by the active energy expenditure $E$. Solving this recurrence
  yields:

  $ B_n = B_0 dot (1 - epsilon)^n + E dot frac((1 - epsilon)^n - 1, epsilon) $

  The device lifetime in cycles is the value of $n$ at which $B_n$ falls to zero
  (or, in practice, to the minimum operating voltage of the device, below which
  the processor or radio ceases to function reliably). This expression makes
  quantitative the intuition that lifetime improves with larger $B_0$, smaller
  $E$, and smaller $epsilon$, and it enables designers to evaluate the impact of
  specific duty cycle choices before committing to hardware.

  Empirical results from simulations with realistic mote-class parameters
  confirm the dramatic sensitivity of lifetime to duty cycle. Moving from 100%
  duty cycle (always active) to 5% duty cycle can extend device lifetime from a
  few weeks to several months for a given battery capacity, and the effect
  compounds across the battery capacity range: a 2000 mAh battery at 5% duty
  cycle may outlast a 3000 mAh battery at 100% duty cycle by a factor of
  several. These results underscore that energy management through duty cycling
  is not a minor optimization but the primary determinant of whether a
  deployment is practically viable.

  == Duty Cycle Management and MAC Protocols

  Managing the duty cycle of a single device in isolation is straightforward:
  the device follows a fixed periodic schedule and sleeps between active phases.
  The challenge arises when many devices must communicate with each other,
  because communication requires two devices to be simultaneously awake---at
  least momentarily. If devices sleep on independent, unsynchronized schedules,
  a sender may be awake and ready to transmit while all its potential receivers
  are asleep, resulting in the packet being lost.

  This coordination problem is the domain of _MAC (Medium Access Control)
  protocols_, the low-level communication layer responsible for arbitrating
  access to the shared wireless channel. In conventional wireless networks, MAC
  protocols are designed primarily to prevent collisions between simultaneous
  transmissions and to achieve high channel utilization. In IoT networks, MAC
  protocols carry an additional and equally important responsibility:
  synchronizing the sleep schedules of neighboring devices so that senders and
  receivers are awake at the same time, without requiring either party to remain
  awake continuously.

  The design tension here is fundamental. A MAC protocol that achieves perfect
  sleep coordination---every device is awake only when it has something to send
  or receive---maximizes energy efficiency but requires precise time
  synchronization and may introduce latency when a device must wait for the next
  scheduled wake-up before it can communicate. A MAC protocol that keeps all
  devices awake continuously eliminates latency and synchronization complexity
  but wastes energy proportional to the fraction of time the channel is idle.
  Real MAC protocols for IoT negotiate this trade-off through a variety of
  mechanisms: beacon-based scheduling (as in the IEEE 802.15.4 superframe
  structure, used by ZigBee), preamble sampling (as in the B-MAC and X-MAC
  protocols used in research sensor networks), and receiver-initiated
  communication (as in RI-MAC), each with different implications for latency,
  synchronization overhead, and achievable duty cycle.

  Turning off the radio excludes a device from the network for the duration of
  its sleep period, which means that messages addressed to it during that time
  must be buffered by an intermediate node (such as a ZigBee router or a MQTT
  broker) until the device wakes and retrieves them. This is not merely a
  protocol detail but a fundamental property of IoT network architecture: the
  abstraction of persistent connectivity provided by higher-layer protocols like
  MQTT sits above a physical layer where connectivity is inherently
  intermittent. The design of duty-cycled MAC protocols is thus inseparable from
  the design of buffering and retransmission strategies at higher layers.

  == Implications for System Design

  The energy analysis developed in this chapter has direct consequences for how
  IoT systems should be designed and evaluated. Several principles emerge from
  the quantitative treatment.

  The radio dominates the energy budget, and the listen state is nearly as
  expensive as the active receive state. This means that a device that keeps its
  radio on while waiting for incoming messages---a pattern natural in
  conventional networking---dissipates energy at nearly the full receive rate
  even when nothing is happening. Any viable energy management strategy must
  either turn the radio off during idle periods (requiring synchronization) or
  use a low-power wake-up receiver that consumes negligible energy and activates
  the main radio only when a signal arrives.

  Subsystem duty cycles must be matched to actual activity patterns. A sensor
  that is queried every 400 milliseconds does not benefit from a flash logger
  that writes at 100% duty cycle; the logger should write only when there is
  data to store and sleep otherwise. Mismatched duty cycles---where a subsystem
  remains active longer than necessary---waste energy without improving
  functionality.

  The transition cost between active and sleep states must be factored into duty
  cycle calculations. If the radio requires 5 ms to initialize from sleep and a
  transmission takes only 2 ms, cycling the radio on and off for each packet is
  counterproductive; the device should batch packets or use a lower wake-up
  frequency. This introduces a coupling between application-layer design (how
  often data is sampled and transmitted) and MAC-layer design (how often the
  radio is activated).

  Finally, battery leakage is not negligible over long deployments. A sensor
  node intended to operate for two years must account for the fact that a
  typical alkaline battery loses approximately 3% of its charge per year even
  without any load. Over a two-year deployment, this represents a 6% reduction
  in usable capacity before the first byte of data is ever transmitted---a
  non-trivial factor in lifetime calculations that must be included in any
  serious energy budget.

]
