#import "@preview/bookly:3.1.0": *

#let abs = [
  Medium access control in IoT networks carries a dual responsibility absent
  from conventional wireless systems: beyond arbitrating access to the shared
  channel, MAC protocols must actively manage the energy consumption of every
  node by coordinating when radios may sleep and when they must listen. This
  chapter examines the design space of energy-efficient MAC protocols for
  low-power wireless networks, organized around three fundamental strategies:
  node synchronization, preamble sampling, and polling. The synchronization
  approach, exemplified by S-MAC, establishes coordinated sleep schedules among
  neighboring nodes, trading protocol complexity and potential latency for
  disciplined duty cycling. The preamble sampling approach, exemplified by B-MAC
  and its descendants X-MAC and BoX-MAC, avoids explicit synchronization by
  having senders prepend a long preamble to each transmission and receivers wake
  briefly and periodically to detect it, trading transmission overhead for
  receiver simplicity. The polling approach, used by IEEE 802.15.4 and
  Bluetooth, delegates sleep management to a master node that buffers messages
  and notifies sleeping slaves via beacons. A quantitative lifetime model for
  B-MAC is developed that expresses transmitter and receiver lifetime as
  functions of the preamble sampling interval and data transmission frequency,
  revealing the existence of an optimal check interval that maximizes device
  longevity. The recurring tension throughout is between the energy spent
  transmitting---which is bounded and predictable---and the energy spent
  listening or sampling for incoming messages---which accumulates continuously
  and ultimately dominates lifetime in most deployments.
]

#chapter(
  title: "MAC Protocols for Energy-Efficient IoT Networks",
  abstract: abs,
  toc: true,
)[

  == Design Objectives and the Three Strategies

  The previous chapter established that the radio transceiver is the dominant
  energy consumer in a typical IoT node, and that the listening state consumes
  nearly as much power as the active receive state. The implication for network
  protocol design is clear: a radio that is powered on but idle---listening for
  transmissions that may never arrive---dissipates energy at a rate approaching
  its peak, with no productive output. Any MAC protocol that aspires to extend
  device lifetime must therefore minimize idle listening, not merely collisions.

  This requirement introduces a tension that does not arise in conventional
  wireless networking. In a standard Wi-Fi or cellular network, devices are
  assumed to be continuously powered and the MAC protocol's sole concern is
  channel efficiency: preventing simultaneous transmissions from interfering
  with each other and allocating bandwidth fairly among competing senders. In a
  battery-powered IoT network, channel efficiency is a secondary concern; the
  primary goal is to minimize the total time each radio spends powered on,
  subject to the constraint that the network remains connected and messages are
  delivered with acceptable latency. These two objectives conflict: a radio that
  is off cannot receive messages, and a radio that is almost always off
  introduces delays proportional to its sleep period.

  Three broad strategies have been developed to navigate this conflict. _Node
  synchronization_ protocols, of which S-MAC is the canonical example, establish
  a shared schedule among neighboring nodes so that all radios wake
  simultaneously at known times, communicate during the shared active window,
  and sleep together between windows. _Preamble sampling_ protocols, of which
  B-MAC is the canonical example, avoid synchronization by having senders
  prepend a long preamble to each frame and receivers wake briefly and
  periodically to detect whether a preamble is present. _Polling_ protocols,
  employed by IEEE 802.15.4 and Bluetooth, use an asymmetric master-slave
  organization in which a master node buffers messages for sleeping slave nodes
  and notifies them of pending traffic via beacons. Each strategy represents a
  different allocation of energy cost between sender and receiver, and between
  communication latency and protocol overhead.

  == Synchronization: S-MAC

  === Operating Principle

  S-MAC (Sensor MAC), developed for TinyOS and the Mica family of mote-class
  devices, is a synchronization-based MAC protocol designed for multi-hop
  wireless sensor networks. Its central insight is that if neighboring nodes
  share a common periodic schedule---alternating between a listen period and a
  sleep period---then the radio can be powered off during the sleep period
  without losing connectivity, because all neighbors are also asleep and no
  transmissions will be missed. The duty cycle of the network is determined by
  the ratio of the listen period to the total cycle period, and can be made very
  small.

  Synchronization in S-MAC is local rather than global: a node synchronizes only
  with its immediate neighbors, not with the entire network. This is a
  deliberate design choice that avoids the complexity and energy cost of global
  time synchronization and makes S-MAC robust to network partitions and topology
  changes. Global synchronization would require a centralized time source and
  precision clocks; local synchronization requires only that neighbors agree on
  a common schedule.

  === Schedule Advertisement and Adoption

  Each node periodically broadcasts a _SYNC frame_ that announces its current
  schedule: specifically, the timing of its next listen period relative to the
  current time. A new node that joins the network first listens for SYNC frames
  from its neighbors. If it detects neighbors operating on a pre-existing
  schedule, it adopts that schedule and begins broadcasting SYNC frames with the
  same timing. If no existing schedule is detected, the node chooses its own
  schedule and begins advertising it; it may later revert to a neighbor's
  schedule if its self-chosen schedule is not adopted by anyone else. This
  negotiation converges, in the absence of conflicting pre-existing schedules,
  to a locally consistent assignment in which neighboring nodes share listen
  periods.

  A node receives frames from its neighbors only during its own listen period,
  which means that to send a frame to node B, node A must transmit during B's
  listen period. Node A may therefore need to keep its radio on outside its own
  listen period, which requires A to know the schedules of all its neighbors.
  This schedule table is built up at startup by listening to SYNC frames, and is
  maintained by periodic re-synchronization as clock drift accumulates over
  time.

  === Transmission and Collision Avoidance

  Transmissions in S-MAC occur during the listen period of the intended
  receiver. Before transmitting, a node performs carrier sensing; if the channel
  is busy, the transmission is deferred to the next listen period. Collision
  avoidance employs the RTS/CTS (Request to Send / Clear to Send) mechanism
  familiar from IEEE 802.11: the sender first issues an RTS, the receiver
  responds with a CTS if it is free, and only then does the data frame follow.
  This sequence prevents the hidden terminal problem---the situation where two
  nodes are both in range of the receiver but not of each other, and cannot
  detect each other's carrier---which would otherwise cause collisions at the
  receiver.

  An adaptive optimization called _adaptive duty cycle_ further reduces energy
  waste: if a node overhears an RTS or CTS addressed to a neighbor, it infers
  that it may be the next hop in an ongoing multi-hop transmission and keeps its
  radio on until the current exchange completes, rather than returning to sleep.
  This speculative listening trades a small energy cost against the latency that
  would otherwise result from waiting for the next listen period to begin
  relaying.

  === Latency in Multi-Hop Networks

  S-MAC's most significant limitation is its impact on end-to-end latency in
  multi-hop networks. Consider a frame that must traverse a path of $k$ hops. At
  each intermediate node, the frame must wait until the next listen period
  before it can be forwarded, and in the worst case---when the frame arrives
  just after the listen period has ended---it waits for nearly a full cycle
  period at each hop. The worst-case end-to-end latency thus scales as $k$ times
  the cycle period, which can be substantial when cycle periods are measured in
  seconds or tens of seconds.

  This latency is mitigated, but not eliminated, by the convergence of
  neighboring nodes toward shared schedules: if consecutive hops happen to share
  listen periods, a frame can be forwarded immediately within the same listen
  window. However, this convergence is not guaranteed; nodes that serve as
  bridges between two subnetworks with different inherited schedules face the
  conflict that they cannot simultaneously be in both schedules' listen periods,
  and the worst-case latency per hop remains bounded by the cycle period.
  Empirical measurements confirm a roughly linear increase in mean latency per
  hop as the duty cycle decreases.

  === Practical Challenges

  Clock drift is an unavoidable physical reality that degrades synchronization
  over time. Quartz oscillators in microcontrollers drift by tens to hundreds of
  parts per million, which at low duty cycles can accumulate to meaningful
  fractions of a listen period within minutes or hours. S-MAC addresses this by
  including drift correction in its SYNC protocol: nodes continuously update
  their schedule estimates based on received SYNC frames, and may decide to
  shift to a different schedule if a significant majority of their neighbors
  have converged to one. In dense networks, synchronization maintenance is a
  non-trivial ongoing cost that must be factored into the protocol's energy
  budget.

  Additionally, some topological configurations make it impossible for a node to
  maintain a single listen period compatible with all its neighbors---for
  example, a bridge node between two clusters that have independently converged
  to different schedules. S-MAC handles this by allowing a node to maintain
  multiple schedules, waking during the listen periods of each of its neighbor
  groups, which naturally increases the duty cycle of that node beyond the
  minimum.

  == Preamble Sampling: B-MAC

  === Operating Principle

  B-MAC (Berkeley MAC) takes an entirely different approach to energy
  efficiency, one that requires no explicit synchronization between nodes. In
  B-MAC, a sender transmits whenever it has data to send; the receiver does not
  need to be awake at any particular time. Instead, the sender prepends a very
  long _preamble_ to every data frame---a preamble long enough that any receiver
  who wakes up at any point during the transmission will observe the preamble in
  progress. The receiver, meanwhile, wakes up briefly and periodically to
  perform _preamble sampling_: it powers on its radio, checks whether a carrier
  or preamble signal is present on the channel, and either powers off again
  immediately (if nothing is detected) or remains awake to receive the incoming
  frame (if a preamble is detected). This activity is called _Low-Power
  Listening_ (LPL).

  The key design constraint is that the preamble must be longer than the sleep
  period of the receiver. If the receiver's sampling interval is $t_"check"$
  seconds, the preamble must last at least $t_"check"$ seconds, so that any
  receiver sampling at any point within the interval will find the preamble
  still in progress. A receiver that detects the preamble keeps its radio on to
  receive the subsequent data frame; one that detects nothing powers off again
  immediately, having spent only the brief check time.

  The trade-off is explicit and quantifiable: the sender spends more energy than
  strictly necessary for a single transmission because it must prepend a long
  preamble to every frame. But the receiver saves energy because its sampling
  activity is brief and infrequent, and because it only expends full receive
  energy for frames actually addressed to it. The overall energy balance depends
  on the relative rates of transmission and sampling and on the specific power
  levels of the radio hardware.

  === Energy Model

  A formal model of B-MAC's energy consumption illuminates the trade-offs and
  enables lifetime optimization. Consider a single transmitter-receiver pair.
  Define $f_"data"$ as the frequency at which the transmitter sends data frames
  (in frames per second) and $f_"check"$ as the frequency at which the receiver
  samples for preambles (in samples per second). Let $t_"preamble"$, $t_"data"$,
  and $t_"check"$ denote the durations of a preamble transmission, a data frame
  transmission, and a single preamble check, respectively, and let $p_"tx"$,
  $p_"rx"$, and $p_"sleep"$ denote the radio power consumption in transmit,
  receive, and sleep modes.

  At the transmitter, the radio is active in two regimes: during preamble
  transmission and during data frame transmission. The duty cycle of
  transmission activity is:

  $ "DC"_"tx" = f_"data" dot (t_"preamble" + t_"data") $

  The remaining fraction of time, the transmitter's radio is idle. The energy
  consumed by the transmitter per unit time is therefore:

  $ E_T (1) = p_"tx" dot "DC"_"tx" + p_"sleep" dot (1 - "DC"_"tx") $

  At the receiver, two activities consume energy: the periodic preamble check
  and the reception of data frames when a preamble is detected. The duty cycle
  of check activity is:

  $ "DC"_"check" = f_"check" dot t_"check" $

  The duty cycle of data reception is approximately half the transmitter's
  transmission duty cycle (since the receiver only encounters the preamble at a
  random point within its duration):

  $ "DC"_"rec" = f_"data" dot frac(1, 2) (t_"preamble" + t_"data") $

  The energy consumed by the receiver per unit time is:

  $
    E_R (1) = p_"rx" dot "DC"_"rec" + p_"rx" dot "DC"_"check" + p_"sleep" dot (1 - "DC"_"rec" - "DC"_"check")
  $

  Given a battery with initial charge $B_"charge"$ (in joules), the lifetime of
  the transmitter is $B_"charge" \/ E_T(1)$ and the lifetime of the receiver is
  $B_"charge" \/ E_R(1)$.

  === Optimal Check Interval

  The model reveals a non-obvious optimization opportunity at the receiver. As
  the check interval $t_"check" = 1 \/ f_"check"$ increases (the receiver
  samples less frequently), the duty cycle of sampling $"DC"_"check"$
  decreases---saving energy. However, a longer check interval requires a longer
  preamble to guarantee detection, which increases $"DC"_"rec"$ (the receiver
  must spend more time in receive mode for the fraction of checks that detect an
  incoming frame). The optimal check interval is the value that minimizes total
  receiver energy consumption by balancing these two competing effects.

  Empirical results from the original B-MAC paper, using the CC1000 radio
  datasheet values ($p_"tx" = 60$ mW, $p_"rx" = 45$ mW, $p_"sleep" = 0.09$ mW,
  preamble length of 271 bytes, data frame length of 36 bytes, byte duration
  approximately $4.16 times 10^(-4)$ s), show that the optimal check interval
  lies in the range of hundreds of milliseconds, and that the resulting device
  lifetime with a 3000 mAh battery exceeds several years for low-rate
  applications such as one sample per ten minutes. Critically, the lifetime
  curves are concave functions of the check interval with a clear maximum,
  confirming that both very short and very long check intervals are suboptimal
  and that the optimal point must be found empirically or analytically for each
  application's traffic rate.

  When multiple transmitters share a common receiver---as in a star network
  topology---the traffic seen by the receiver increases proportionally to the
  number of transmitters, increasing $"DC"_"rec"$ and reducing receiver
  lifetime. Simulation results confirm that receiver lifetime decreases with the
  number of transmitters, while transmitter lifetime is largely unaffected by
  the number of peers. This asymmetry has practical implications for network
  architecture: in deployments where receiver lifetime is the bottleneck,
  recharging or replacing the receiver more frequently than the transmitters may
  be the most cost-effective operational strategy.

  === Strengths and Limitations

  B-MAC's primary strength is its architectural simplicity. It requires no
  network organization protocol, no time synchronization infrastructure, and no
  coordination between sender and receiver beyond the shared preamble duration
  convention. The entire protocol is controlled by a single parameter---the
  check interval---which can be tuned independently on each node without
  coordination. It is transparent to higher layers, which can treat the MAC as a
  black box providing best-effort frame delivery. These properties make B-MAC
  straightforward to implement, deploy, and debug.

  The primary limitation is the long preamble required by low-frequency
  sampling. A check interval of one second requires a preamble lasting at least
  one second; at the CC1000 data rate, this corresponds to a preamble of
  approximately 240 bytes, which dwarfs the data payload of a typical sensor
  reading. In networks with low traffic but low desired latency, the preamble
  length requirement forces a choice between energy efficiency (long check
  interval, long preamble) and latency (short check interval, short preamble).
  Additionally, as network traffic increases, the cumulative preamble overhead
  grows proportionally, and B-MAC can become more expensive than
  synchronization-based approaches.

  == X-MAC and BoX-MAC: Reducing Preamble Overhead

  === X-MAC

  X-MAC (Extended MAC) is a direct response to B-MAC's preamble overhead
  problem. The key innovation is to allow the receiver to interrupt the preamble
  early by sending an early acknowledgement, rather than requiring the sender to
  transmit the full preamble duration regardless of when the receiver wakes up.
  To enable this, the X-MAC preamble contains the identifier of the intended
  receiver in each preamble packet. A receiver that wakes up, detects preamble
  activity, and recognizes its own identifier in the preamble can immediately
  send a short acknowledgement to the sender, which then stops transmitting the
  preamble and proceeds directly to the data frame.

  The benefit is substantial: on average, the receiver wakes up at the midpoint
  of the preamble interval, so the expected preamble transmission time is halved
  compared to B-MAC. In the best case (the receiver wakes up at the very
  beginning of the preamble), the preamble is shortened to a single packet. In
  the worst case (the receiver wakes up at the very end), the preamble duration
  is the same as in B-MAC. The average energy savings in transmission are
  therefore close to 50%, at the cost of embedding the receiver's address in the
  preamble (which prevents preamble broadcasting to multiple receivers) and
  implementing the early-termination handshake.

  === BoX-MAC

  BoX-MAC (Box-casting MAC) carries the X-MAC idea further. Rather than using a
  dedicated preamble sequence followed by a data frame, BoX-MAC uses a repeated
  sequence of the actual data frame itself as the "preamble." The receiver that
  wakes up, recognizes it is the intended recipient of the repeated frame, and
  receives a complete copy of the data can send an acknowledgement to stop the
  repetition immediately---it has already received the frame and does not need
  to wait for the "official" data phase.

  This design is particularly advantageous for short data frames: if the data
  payload fits in a single packet, BoX-MAC eliminates the preamble as a separate
  entity entirely, replacing it with useful redundancy. The receiver may benefit
  from receiving multiple copies if signal quality is poor (increasing
  reliability), or may stop the transmission after the first successful
  reception (saving transmitter energy). The protocol inherits X-MAC's
  early-termination mechanism and adds the benefit that no transmission energy
  is wasted on a content-free preamble---every bit transmitted is part of the
  actual data frame.

  == Polling: IEEE 802.15.4 and Bluetooth

  Polling represents a third architectural philosophy for sleep management, one
  that establishes a structural asymmetry between a master node and slave nodes.
  In a polling-based MAC, a master node emits periodic beacon frames that serve
  two purposes: they establish a time reference for synchronization, and they
  advertise the list of slave nodes for which the master has buffered pending
  messages.

  Slave nodes can keep their radios off for extended periods. When a slave wakes
  up---on its own schedule, without coordination with the master---it listens
  for the next beacon. If the beacon indicates pending traffic for that slave,
  the slave issues a request to the master, which delivers the buffered frame.
  If the beacon indicates no pending traffic, the slave returns to sleep
  immediately. This design places the energy burden for continuous availability
  on the master (which must always be reachable to receive incoming messages for
  slaves) while allowing slaves to achieve very low duty cycles.

  IEEE 802.15.4 combines polling with beacon-based synchronization through its
  _superframe_ structure: the beacon defines the start of a superframe divided
  into an active period (during which contention-based access and guaranteed
  time slots are available) and an inactive period (during which all devices may
  sleep). Devices that choose to use polling within this structure can
  synchronize their wake-ups to the beacon timing, reducing the uncertainty
  about when to listen. Bluetooth's piconet architecture similarly uses a master
  node that orchestrates when each slave may transmit, allowing slaves to sleep
  during all other intervals.

  Polling is particularly well-suited to deployments where traffic is
  predominantly downlink (from master to slave) or where a natural master
  node---a gateway, base station, or access point---is available and can be
  continuously powered. It is less suitable for ad-hoc networks without a
  designated master or for applications where upstream sensor data must be
  delivered with low latency despite the slave's sleeping schedule.

  == Comparative Analysis and Design Guidance

  The three strategies differ in where they place energy cost and protocol
  complexity. Synchronization-based protocols (S-MAC) achieve precise duty cycle
  control at the cost of synchronization overhead, schedule maintenance, and
  multi-hop latency that scales with the cycle period. Preamble sampling
  protocols (B-MAC, X-MAC, BoX-MAC) eliminate synchronization complexity at the
  cost of longer preambles---overhead that grows with the desired check interval
  and with network traffic density. Polling protocols eliminate the receiver's
  need to independently manage its sleep schedule at the cost of requiring a
  continuously available master and introducing indirection in message delivery.

  No single strategy dominates across all deployment scenarios. For sparse,
  low-traffic networks where nodes communicate rarely and message latency is not
  critical, B-MAC or BoX-MAC offer the simplest implementation and acceptable
  energy efficiency. For denser networks with more frequent communication, or
  where predictable latency is required, S-MAC's synchronization overhead is
  justified by its more disciplined duty cycle control. For networks with a
  natural master-slave topology---a building automation system with a central
  controller, for example---polling avoids the synchronization overhead of S-MAC
  while providing the master with full control over slave sleep schedules.

  A practical consideration that cuts across all three strategies is the energy
  cost of radio state transitions. Powering a radio on from sleep mode is not
  instantaneous: initialization and configuration take finite time and energy.
  The CC1000 radio, for example, requires a startup sequence involving timer
  interrupt handling, radio initialization, entry into receive mode, signal
  detection, frame decoding, and radio shutdown---a sequence that consumes
  meaningful energy relative to the check itself. This transition cost sets a
  floor on the useful check interval: sampling more frequently than the
  transition cost warrants wastes energy on initialization overhead rather than
  saving it through reduced preamble exposure.

  The duty cycle management strategies discussed in this chapter operate at the
  MAC layer, but their effects propagate upward through the protocol stack. A
  MAC layer that introduces variable and potentially large delays---because a
  sleeping node must wait for its next active period before relaying a
  frame---affects the throughput and latency seen by the application layer.
  Protocol designs at higher layers must account for this variability; for
  example, MQTT's persistent session mechanism and message queuing at the broker
  explicitly accommodate the intermittent availability that energy-efficient MAC
  protocols impose on IoT nodes. The energy-performance trade-off is therefore
  not a decision made once at the MAC layer but a constraint that shapes system
  design from the physical radio up to the application.

]
