#import "@preview/bookly:3.1.0": *

#let abs = [
  Wireless communication is the enabling technology of mobile and cyber-physical
  systems: it liberates devices from the physical constraints of wired
  connections, allowing sensors, actuators, and mobile hosts to participate in
  networked systems wherever they are deployed. This chapter examines wireless
  networking from the physical foundations of radio propagation through the
  medium access control challenges that distinguish wireless from wired
  environments, and concludes with the IEEE 802.11 (Wi-Fi) standard as a
  detailed case study of how these challenges are addressed in practice. The
  physical characteristics of radio channels---path loss, multipath propagation,
  interference, and the signal-to-noise ratio trade-off---directly determine the
  design of MAC protocols. The hidden terminal and exposed terminal problems,
  which arise from the asymmetric radio range relationships among nodes, render
  the collision detection approach of wired CSMA/CD inapplicable; the chapter
  traces the evolution from MACA to MACAW to the CSMA/CA protocol used in IEEE
  802.11, explaining how each mechanism addresses a specific failure mode of its
  predecessor. The recurring tension throughout is the asymmetry between the
  transmitter's perspective and the receiver's perspective: in wireless
  networks, what matters is interference at the receiver, not at the sender, and
  this simple observation has profound consequences for every aspect of MAC
  protocol design.
]

#chapter(
  title: "Wireless Networks",
  abstract: abs,
  toc: true,
)[

  == Why Wireless Networks?

  The motivation for wireless networking in the context of cyber-physical
  systems is both practical and conceptual. At the practical level, wired
  connections constrain the placement of devices to locations where cables can
  be run---a requirement that is simply incompatible with the aspiration of
  embedding computation into any physical object or environment. Sensors
  embedded in soil, mounted on rotating machinery, worn on the body, or deployed
  across a city cannot be connected by wires without defeating the purpose of
  embedding them. Wireless communication replaces the signal cable; battery
  power replaces the power cable. Together, they enable devices that are truly
  autonomous and freely placeable.

  At the conceptual level, the shift from wired to wireless communication
  introduces a qualitatively different set of engineering problems. A wired link
  is a private, point-to-point medium: only the two endpoints share it, and the
  physical channel is well-characterized and stable. A wireless link is a
  shared, broadcast medium: any device within radio range can receive
  transmissions, the channel quality varies with distance, obstacles, and
  interference, and the set of mutually reachable devices is determined by
  geometry rather than by cabling decisions. These differences demand new
  mechanisms at every layer of the protocol stack, from modulation at the
  physical layer to routing at the network layer.

  == Elements of a Wireless Network

  A wireless network consists of _wireless hosts_---laptops, smartphones, sensors,
  embedded controllers, vehicles---that communicate through _wireless links_.
  Wireless hosts run applications and are typically mobile, though wireless
  connectivity does not require mobility; a stationary sensor node with a
  wireless radio is a wireless host regardless of whether it moves. Links carry
  data at varying rates and across varying ranges, from short-range Bluetooth
  Personal Area Networks to wide-area cellular networks spanning kilometers.

  Two architectural modes are distinguished by whether a fixed infrastructure
  participates in communication. In _infrastructure mode_, wireless hosts
  communicate with a _base station_ (also called an access point in the 802.11
  context), which is connected to a wired network and relays traffic between
  wireless hosts and the broader internet. Traditional services---address
  assignment, authentication, routing---are provided by the wired infrastructure.
  When a wireless host moves out of the range of one base station and into the
  range of another, a _handoff_ occurs: the host associates with the new base
  station, which then becomes the relay for its traffic. Infrastructure mode
  includes cellular networks (where base stations are cell towers), Wi-Fi
  networks (where base stations are access points), and WiMAX systems.

  In _ad hoc_ (or infrastructure-less) mode, no base station is present. Nodes
  communicate directly with any other node within radio range, and to reach
  nodes beyond direct range, traffic must be relayed through intermediate
  nodes---a mode called _multi-hop_ or _mesh_ networking. ZigBee mesh networks,
  vehicular ad hoc networks (VANETs), and mobile ad hoc networks (MANETs) all
  instantiate this architecture. Routing in multi-hop ad hoc networks is
  particularly challenging because the network topology changes as nodes move,
  and no centralized coordinator maintains a global view of connectivity.

  A useful taxonomy organizes wireless networks along two dimensions:
  infrastructure versus infrastructure-less, and single-hop versus multi-hop.
  Infrastructure single-hop networks (conventional Wi-Fi, cellular) connect each
  host to the internet via a single wireless link to a base station.
  Infrastructure multi-hop networks (Wi-Fi Mesh, public safety radio) relay
  traffic through multiple wireless hops before reaching a base station.
  Infrastructure-less single-hop networks (classic Bluetooth) allow direct
  peer-to-peer communication without routing. Infrastructure-less multi-hop
  networks (ZigBee, MANETs, VANETs) relay traffic through multiple peer nodes
  with no base station.

  Modern wireless devices typically implement multiple radio interfaces to
  participate in several of these network types simultaneously. A contemporary
  smartphone contains radios for five cellular frequency bands, Wi-Fi,
  Bluetooth, Ultra-Wideband (UWB) for precise ranging, Near-Field Communication
  (NFC) for proximity interactions, satellite GPS for positioning, and
  others---each optimized for a different combination of range, throughput, power
  consumption, and latency.

  == Radio Channel Characteristics

  === Electromagnetic Waves and Modulation

  Wireless communication relies on electromagnetic waves: oscillating electric
  and magnetic fields that propagate through space at the speed of light. A
  radio transmitter drives a current through an antenna at a specific frequency,
  creating an oscillating electromagnetic field that propagates outward as a
  wave. A receiver antenna converts the arriving wave back into a current that
  carries the transmitted information.

  The fundamental parameters of a radio wave are its frequency (the number of
  oscillations per second, measured in Hz) and its wavelength (the distance
  between successive wave peaks, equal to the speed of light divided by
  frequency). The _phase_ of a periodic signal describes its position within a
  cycle at a given moment; by modulating the phase of a carrier wave---shifting it
  among discrete values corresponding to different bit patterns---information can
  be encoded without changing the carrier frequency. Other modulation schemes
  vary amplitude (ASK), frequency (FSK), or combinations thereof; more advanced
  schemes such as QAM (Quadrature Amplitude Modulation) encode multiple bits per
  symbol by varying both amplitude and phase simultaneously.

  === Signal Power, Bandwidth, and SNR

  _Power_ is the energy delivered per unit time by the radio signal, measured in
  watts or milliwatts, or on a logarithmic scale in decibels relative to one
  milliwatt (dBm): $P_"dBm" = 10 log_10(P_"mW" / 1"mW")$. A typical mobile
  device transmits at up to 250 mW (approximately 24 dBm). Signal power at the
  receiver decreases as the signal propagates outward from the transmitter, a
  phenomenon discussed below under path loss.

  _Bandwidth_ is the width of the frequency range occupied by a radio signal,
  measured in Hz. A Wi-Fi channel in the 2.4 GHz band, for example, occupies 22
  MHz of spectrum centered on a carrier frequency. Bandwidth is a scarce
  resource: spectrum is divided into licensed and unlicensed bands by regulatory
  bodies, and multiple technologies share the same bands. The 2.4 GHz ISM
  (Industrial, Scientific, and Medical) band is occupied simultaneously by
  Wi-Fi, Bluetooth, ZigBee, microwave ovens, cordless phones, baby monitors, and
  other devices, all of which interfere with each other.

  The _signal-to-noise ratio_ (SNR) is the ratio of received signal power to
  noise power, expressed in decibels. Noise arises from two sources: thermal
  noise in the receiver's electronics (unavoidable, proportional to bandwidth
  and temperature) and interference from other transmitters in the same
  frequency band. SNR is the fundamental determinant of channel quality: a high
  SNR allows reliable decoding of a received signal; a low SNR makes it
  difficult or impossible to separate the signal from noise. The lower limit for
  usable SNR is approximately -10 to -6 dB for cellular systems and around 20 dB
  for Wi-Fi.

  The theoretical maximum data rate achievable on a channel of bandwidth $B$ Hz
  with signal-to-noise ratio SNR is given by the Shannon-Hartley theorem:

  $ C = B log_2(1 + "SNR") $

  where $C$ is capacity in bits per second and SNR is measured as a
  dimensionless power ratio (not in dB). This result, derived by Claude Shannon
  in 1948, establishes that capacity scales linearly with bandwidth and
  logarithmically with SNR. The logarithmic dependence on SNR has an important
  practical implication: once SNR is high enough to support reliable
  communication, increasing transmit power yields rapidly diminishing returns,
  while increasing bandwidth yields proportional capacity gains.

  === Path Loss and Fading

  A transmitted radio signal loses power as it propagates outward from the
  antenna---a phenomenon called _path loss_ or fading. In free space, the power
  density of an electromagnetic wave decreases with the square of the distance
  from the transmitter, because the same total radiated power is spread over a
  sphere of increasing area. In real environments, additional
  factors---reflection, diffraction, scattering, and absorption by obstacles---cause
  power to decrease more steeply: the generalized path loss model gives signal
  power proportional to $(f d)^{-n}$, where $f$ is frequency, $d$ is distance,
  and the path loss exponent $n$ takes values of approximately 2 in free space,
  2.7 to 3.5 in urban outdoor environments, and 3 to 6 inside buildings.

  _Multipath propagation_ arises because radio waves reflect off
  surfaces---ground, walls, buildings, vehicles---and reach the receiver via
  multiple paths with different lengths and hence different travel times. The
  received signal is the superposition of the direct (line-of-sight) copy and
  one or more delayed reflected copies. If these copies arrive with similar
  amplitudes but shifted phases, they may interfere destructively---a phenomenon
  called multipath fading that can dramatically reduce received signal strength
  even at short distances. The minimum time spacing between successive
  transmissions that avoids overlap between the direct copy and its reflections
  is called the _coherence time_, which is inversely proportional to the carrier
  frequency and to the receiver's velocity. The coherence time constrains the
  maximum symbol rate the channel can support without inter-symbol interference.

  These channel impairments collectively make wireless communication far more
  variable and unpredictable than wired communication. A receiver observes a
  signal whose strength fluctuates with position, time, and environmental
  changes; the channel quality that justified a given modulation choice a moment
  ago may be invalid the next moment. Adaptive modulation---selecting among
  modulation schemes based on current SNR, as illustrated by the relationship
  between BPSK (1 Mbps, robust at low SNR), QAM16 (4 Mbps, requires moderate
  SNR), and QAM256 (8 Mbps, requires high SNR) in 802.11---responds to this
  variability by trading off throughput for reliability based on measured
  channel conditions.

  == MAC Challenges: Hidden and Exposed Terminals

  === Why CSMA/CD Fails in Wireless Networks

  In wired Ethernet, Carrier Sense Multiple Access with Collision Detection
  (CSMA/CD) provides efficient medium access. A station listens to the channel
  before transmitting; if the channel is busy, it waits; if idle, it transmits.
  If a collision occurs---detected because the received signal differs from the
  transmitted signal---all stations abort and retry after a random backoff. This
  mechanism works in wired networks for two reasons: all stations on the same
  segment can hear each other, and the signal strength of a transmitter's own
  transmission is comparable to the received signal from a distant collider.

  Neither assumption holds in wireless networks. The signal strength of a
  station's own transmission at its own antenna is enormously larger than any
  signal arriving from a distant transmitter; the local self-signal drowns out
  any collision signature. Furthermore, the wireless channel conditions at the
  transmitter differ from those at the receiver: a collision that is not
  detectable at the sender may be catastrophic at the receiver. The conclusion
  is direct: what matters in wireless communication is interference at the
  receiver, not at the sender, and a sender cannot reliably determine by
  monitoring its own channel what a receiver is experiencing.

  Path loss causes two distinct anomalies in carrier sensing that compound this
  fundamental problem.

  === The Hidden Terminal Problem

  Consider three stations A, B, and C arranged so that A and B are within radio
  range of each other, B and C are within range of each other, but A and C are
  out of range of each other. If A is transmitting to B, C senses the channel,
  hears nothing (A is out of range), concludes the channel is idle, and begins
  transmitting---either to B or to another destination. If C's transmission
  reaches B, it collides with A's ongoing transmission at B. Neither A nor C
  detects the collision: A cannot hear C, and C cannot hear A.

  C is said to be _hidden_ with respect to the communication from A to B,
  because it is hidden from A's radio range. The hidden terminal problem arises
  whenever two or more stations that are out of range of each other transmit
  simultaneously to a common receiver. The collision occurs entirely at the
  receiver, where neither sender can observe it, and neither sender's carrier
  sensing provides any protection. The problem is not merely theoretical: in any
  reasonably dense wireless deployment, hidden terminal relationships are
  common, and they can severely degrade throughput.

  === The Exposed Terminal Problem

  A complementary problem arises in the opposite direction. Consider B
  transmitting to A, and C wishing to transmit to D, where D is out of range of
  B. C senses the channel, hears B's transmission, and concludes it cannot
  transmit---incorrectly. C's transmission to D would not interfere with B's
  transmission to A, because D is far from B and A is far from C; the two
  communications would not collide at either receiver. But C's carrier sensing
  has exposed it to B's transmission and prevented a perfectly valid parallel
  communication.

  C is said to be _exposed_ with respect to the communication from B to A. The
  exposed terminal problem causes unnecessary channel underutilization: a
  station refrains from transmitting when it could do so without causing
  interference. The exposed terminal problem is less damaging than the hidden
  terminal problem---it wastes capacity rather than corrupting transmissions---but
  both problems reflect the same underlying issue: a station's carrier sensing
  does not accurately reflect the interference conditions at its intended
  receiver.

  The asymmetry between the two problems points toward the same general
  solution: a protocol that explicitly coordinates not just the sender's intent
  but the receiver's readiness and the silence of potential interferers near the
  receiver.

  == MACA and the RTS/CTS Mechanism

  === Basic MACA

  The MACA (Multiple Access with Collision Avoidance) protocol, proposed by Karn
  in 1990, addresses the hidden and exposed terminal problems through a short
  handshake before data transmission. Rather than relying on the sender to sense
  the channel and infer receiver conditions, MACA stimulates the receiver into
  broadcasting a short acknowledgement, which nearby nodes can hear to learn
  that they must stay silent.

  When station A wishes to transmit to B, it first sends a short _Request to
  Send_ (RTS) frame. The RTS contains the identifiers of both source (A) and
  destination (B) and the length of the data frame that will follow. All
  stations within radio range of A receive the RTS. Station B, if ready to
  receive, replies with a _Clear to Send_ (CTS) frame, also containing the data
  length. All stations within range of B receive the CTS.

  The protocol behavior for each station is determined by which control frames
  it can and cannot receive. A station that hears the CTS but not the RTS (such
  as a hidden terminal near B) knows that B is about to receive a transmission
  from some unheard sender; it must remain silent for the duration of the data
  transmission. A station that hears the RTS but not the CTS (such as an exposed
  terminal near A) knows that a neighbor is trying to transmit but cannot yet
  determine whether the receiver is ready; it can transmit to other destinations
  without interfering with the exchange between A and B, since its transmission
  will not reach B.

  Collisions can still occur between RTS frames: if two stations simultaneously
  send RTS packets to the same recipient, neither will receive a CTS, and both
  will retry after a random backoff following the Binary Exponential Backoff
  algorithm. RTS packets are short (typically 20 bytes), so collisions among
  them consume little channel time relative to collisions among full data
  frames.

  === MACAW and CSMA/CA

  MACAW (MACA for Wireless networks), developed by Bharghavan et al. in 1994,
  refines MACA with several improvements. It adds an ACK frame to confirm
  successful data reception, closing the reliability loop. It introduces
  mechanisms for stations to exchange backoff counters, enabling fairer
  bandwidth allocation among competing senders. IEEE 802.11's CSMA/CA protocol
  is based on MACAW, adding carrier sensing before RTS transmission to avoid
  initiating exchanges when the channel is clearly busy.

  == IEEE 802.11 Architecture and Protocol

  === Architecture

  IEEE 802.11 is the dominant wireless LAN standard, commonly known as Wi-Fi. It
  is developed and maintained by the IEEE 802 Working Group, whose 802 project
  family covers a range of network technologies sharing a common Logical Link
  Control (LLC) sublayer while differentiating their MAC and physical layers.
  The 802.11 family includes multiple generations, each offering progressively
  higher throughput: 802.11b (11 Mbps at 2.4 GHz, 1999), 802.11g (54 Mbps at 2.4
  GHz, 2003), 802.11n/Wi-Fi 4 (up to 600 Mbps at 2.4/5 GHz, 2009),
  802.11ac/Wi-Fi 5 (up to 3.47 Gbps at 5 GHz, 2013), and 802.11ax/Wi-Fi 6 (up to
  14 Gbps at 2.4/5/6 GHz, 2019). All generations use CSMA/CA for multiple access
  and support both infrastructure and ad hoc modes.

  The fundamental organizational unit is the _Basic Service Set_ (BSS): a group
  of stations that communicate with each other, with or without an access point.
  Without an AP, the BSS forms an ad hoc network where stations communicate
  directly. With an AP, all traffic is channeled through the AP; a station
  communicating with another station in the same BSS sends its frames to the AP,
  which relays them. Multiple BSSs can be interconnected through a _Distribution
  System_ (DS)---typically a wired Ethernet backbone---forming an _Extended Service
  Set_ (ESS) in which stations can roam between BSSs while maintaining network
  connectivity.

  === Association and Scanning

  Before a host can use an 802.11 network, it must _associate_ with an AP. The
  802.11 spectrum is divided into channels at different center frequencies; in
  the 2.4 GHz band, 13 channels of 22 MHz bandwidth are defined, separated by 5
  MHz, though adjacent channels overlap significantly and only three
  non-overlapping channels (1, 6, and 11) can be used simultaneously without
  interference. An AP is configured to operate on a specific channel and
  identifies its network by a _Service Set Identifier_ (SSID), a human-readable
  name.

  A host discovers available networks through scanning, which can be passive or
  active. In _passive scanning_, the host listens on each channel for _beacon
  frames_ periodically broadcast by APs; each beacon contains the AP's SSID and
  BSSID (MAC address). The host selects an AP---typically the one whose beacon is
  received with highest signal strength---and sends an Association Request frame,
  which the AP acknowledges with an Association Response. In _active scanning_,
  the host broadcasts a Probe Request on each channel; all APs that hear it
  respond with a Probe Response, and the host then selects and associates as in
  the passive case. After association, the host typically runs DHCP to obtain an
  IP address in the AP's subnet.

  === The MAC Protocol: DCF and CSMA/CA

  The standard MAC protocol in IEEE 802.11 is the _Distributed Coordination
  Function_ (DCF), which implements CSMA/CA. An optional _Point Coordination
  Function_ (PCF) provides contention-free access for delay-sensitive traffic
  but is rarely used in practice.

  DCF uses two forms of carrier sensing in combination. _Physical carrier
  sensing_ directly monitors the radio channel for energy above a detection
  threshold, indicating an ongoing transmission by any source. _Virtual carrier
  sensing_ exploits duration fields embedded in RTS, CTS, and data frame
  headers: each frame specifies how long the channel will remain busy (covering
  the remaining data, plus the ACK). Every station that receives such a frame
  updates its _Network Allocation Vector_ (NAV), a countdown timer indicating
  how long the channel is virtually busy. A station defers transmission if
  either physical or virtual carrier sensing indicates the channel is busy. The
  NAV mechanism extends the reach of channel reservation beyond the carrier
  sensing range of any individual station.

  Priority between different types of transmissions is controlled through
  _interframe spacing_ (IFS): mandatory idle periods that a station must observe
  before transmitting. The _Distributed IFS_ (DIFS), the waiting time before a
  data transmission or RTS, is longer than the _Short IFS_ (SIFS), the waiting
  time before an ACK or CTS. Because a station waiting only SIFS can respond
  before any station waiting DIFS can initiate a new transmission, ACKs and CTSs
  have implicit priority over new data frames.

  The basic DCF access procedure, when the channel is detected idle for a full
  DIFS period, allows the station to begin transmitting. Other stations that
  receive the first bytes of the frame (which contain the duration field) update
  their NAVs and defer until the duration expires. After a successful frame
  reception, the receiver waits SIFS and transmits an ACK. The sending station
  waits for the ACK; if none arrives---because the frame was lost to a collision
  or channel error---it applies binary exponential backoff before retrying. After
  a collision, the backoff window doubles: after the first collision, the
  station waits 0 or 1 backoff slots; after the $i$-th collision, it waits a
  random number of slots uniformly drawn from $[0, 2^i - 1]$. Unlike wired
  CSMA/CD, a station in 802.11 cannot detect a collision mid-frame; it must
  transmit the entire frame and infer failure from the absence of an ACK,
  wasting channel time on frames that were colliding.

  === RTS/CTS in IEEE 802.11

  IEEE 802.11 incorporates the RTS/CTS mechanism as an optional enhancement,
  configurable on a per-frame basis through the RTS Threshold parameter. When
  RTS/CTS is used, the exchange proceeds as follows: the sender transmits an RTS
  (approximately 20 bytes) using CSMA/CA with DIFS; the AP (acting as the relay
  for infrastructure mode) responds with a CTS (approximately 14 bytes) after a
  SIFS interval; the sender transmits the data frame after another SIFS; the
  receiver transmits an ACK after another SIFS.

  Stations that overhear the RTS update their NAV for the full duration
  specified in the RTS (covering the CTS, data, and ACK). Stations that overhear
  the CTS---which includes hidden terminals near the AP---update their NAV for the
  duration in the CTS (covering the data and ACK) and refrain from transmitting
  for that duration. The RTS/CTS exchange thus alerts both neighbors of the
  sender and neighbors of the receiver, effectively solving the hidden terminal
  problem at the cost of the overhead of two additional short frames per data
  frame.

  Three usage policies are supported. When channel load is light, the overhead
  of RTS/CTS is not justified and it is omitted. For long frames---those exceeding
  the RTS Threshold---RTS/CTS protects expensive transmissions from hidden
  terminal interference. When load is heavy and hidden terminal problems are
  frequent, always using RTS/CTS may improve overall throughput despite its
  overhead by preventing costly data frame collisions.

  == Open Challenges and Deployment Considerations

  The mechanisms described in this chapter address the core MAC challenges of
  wireless networks, but several complications arise in real deployments.
  Interference management in dense environments---where many access points and
  devices share the same 2.4 GHz band---requires careful channel planning, and the
  limited number of non-overlapping channels at 2.4 GHz (three) severely
  constrains the density of co-located networks. The 5 GHz and 6 GHz bands, with
  more available spectrum and fewer competing devices, are increasingly
  preferred for high-density deployments.

  Mobility introduces the _handoff_ problem: when a host moves from the range of
  one AP to another, it must detect the degradation in its current association,
  scan for a better AP, and re-associate without losing the packets in flight or
  disrupting ongoing connections. Fast handoff is critical for real-time
  applications such as voice calls and video streams; 802.11r and related
  standards address this with pre-authentication and fast transition protocols
  that reduce interruption during handoff.

  Power management is particularly important for battery-powered IoT devices
  that use 802.11 as their radio interface. 802.11's Power Save Mode (PSM)
  allows a station to notify the AP that it is entering sleep, buffer frames at
  the AP during sleep, and wake periodically to check the AP's beacon for
  pending frame announcements---a polling mechanism that trades latency for energy
  savings. More aggressive power management is available in newer 802.11
  versions (Target Wake Time in 802.11ax), which allow finer-grained
  coordination between devices and APs about when each device will be awake,
  enabling much lower average power consumption in dense IoT deployments that
  share a Wi-Fi infrastructure.

]
