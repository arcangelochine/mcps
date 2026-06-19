#import "@preview/bookly:3.1.0": *

#let abs = [
  IEEE 802.15.4 specifies the physical and medium access control layers for
  low-rate, infrastructure-less wireless personal area networks, providing the
  foundation upon which higher-level IoT protocol stacks such as ZigBee are
  built. This chapter traces the standard from the radio physics of its three
  licence-free frequency bands through the frame structure of the physical
  layer, and then examines the MAC layer in depth: its device taxonomy of
  full-function and reduced-function devices, the superframe mechanism that
  enables coordinated sleep scheduling, the two channel access
  strategies---contention-based CSMA-CA and contention-free Guaranteed Time
  Slots---and the three data transfer modes that accommodate different network
  topologies. The association protocol, which governs how a new device joins an
  existing personal area network, is examined in detail as an illustration of
  how the standard's service primitive model orchestrates multi-party
  interactions across the network and MAC layers. The chapter closes with the
  MAC layer's security services, which provide access control, encryption,
  integrity, and freshness as configurable building blocks for higher-layer
  security policies. The recurring tension throughout is between _generality_
  and _energy efficiency_: the superframe structure achieves disciplined sleep
  coordination at the cost of synchronization overhead and reduced flexibility,
  while the non-beacon mode achieves flexibility at the cost of requiring
  coordinators to remain continuously active.
]

#chapter(
  title: "The IEEE 802.15.4 Standard",
  abstract: abs,
  toc: true,
)[

  == Overview and Scope

  IEEE 802.15.4 occupies a specific and deliberate niche in the wireless
  standards landscape. Where IEEE 802.11 (Wi-Fi) targets high-throughput local
  area networking and IEEE 802.15.1 (Bluetooth) targets personal device
  connectivity, 802.15.4 targets the class of applications that require low data
  rates, very low power consumption, low cost, and operation in the licence-free
  spectrum---characteristics that collectively define the sensing and actuation
  layer of the Internet of Things. The standard specifies only the two lowest
  layers of the protocol stack: the physical (PHY) layer, responsible for radio
  transmission and reception, and the medium access control (MAC) layer,
  responsible for channel access, synchronization, and device management.
  Higher-layer functionality---routing, addressing, application semantics---is
  deliberately left to standards built on top of 802.15.4, of which ZigBee is
  the most prominent.

  Three licence-free frequency bands are supported. The 868-868.6 MHz band, used
  primarily in Europe, supports a single channel at 20 kbps. The 902-928 MHz
  band, used in North America, supports ten channels at 40 kbps. The 2400-2483.5
  MHz band, available worldwide, supports sixteen channels spaced 5 MHz apart at
  250 kbps and is the most widely used. The physical layer is designed to
  coexist with IEEE 802.11 and Bluetooth in the 2.4 GHz band, which it shares
  with both. The standard was first published in 2003 and revised in 2006; it
  forms the physical and MAC foundation of ZigBee, which appeared shortly after
  the first revision.

  == The Physical Layer

  === Services and Functions

  The physical layer of IEEE 802.15.4 provides two categories of service to the
  MAC layer above it. The _data service_ handles the transmission and reception
  of PHY Protocol Data Units (PPDUs) through the radio medium, reporting success
  or failure to the MAC layer. Transmission failures can arise from the
  transceiver being in the wrong state---in receive mode rather than transmit
  mode, busy with a prior transmission, or out of order. The _management
  service_ covers a broader set of functions: activating and deactivating the
  radio transceiver to implement energy-saving policies; performing energy
  detection; assessing link quality; selecting operating channels; and
  maintaining the PHY PAN Information Base (PHY-PIB), a set of configurable
  parameters that describe the current physical layer configuration.

  _Energy Detection_ (ED) is a measurement of the received signal power in the
  current channel, averaged over an interval of eight symbol periods. Its
  primary uses are channel selection during network formation (choosing a
  channel with low ambient energy) and carrier sense in the CSMA-CA protocol.
  The detection threshold is set at 10 dB above the receiver's sensitivity
  floor, and the result is reported as a single byte to the MAC layer. _Link
  Quality Indication_ (LQI) is a per-packet quality metric assessed each time a
  frame is received, based on the received signal energy, the signal-to-noise
  ratio, or both. LQI must provide at least eight distinct levels and is
  forwarded to the network and application layers, where it is used for
  multi-hop routing decisions---routers that implement ZigBee's AODV-based mesh
  routing use LQI to estimate per-link path costs.

  _Clear Channel Assessment_ (CCA) determines whether the channel is currently
  occupied before a node attempts to transmit. Three CCA modes are defined: Mode
  1 uses energy detection and declares the channel busy if the received energy
  exceeds the detection threshold; Mode 2 uses carrier sense and declares the
  channel busy only if the detected signal has the modulation characteristics of
  an IEEE 802.15.4 transmission (distinguishing 802.15.4 traffic from other 2.4
  GHz sources); Mode 3 combines Modes 1 and 2 using logical AND or OR.

  === Frame Structure

  The PPDU, the unit of data transferred between the PHY layer and the radio
  medium, has three fields. The _Synchronization Header_ (SHR) contains the
  preamble sequence and the Start-of-Frame Delimiter (SFD), which the receiver
  uses to synchronize and detect the beginning of a frame. The _PHY Header_
  (PHR) encodes the length of the PHY payload in seven bits, with a reserved
  bit. The _PHY Payload_, also called the PHY Service Data Unit (PSDU), carries
  the MAC frame. The maximum PSDU length is 127 bytes for standard data frames
  and 5 bytes for MAC acknowledgement frames. The SHR is transmitted first,
  followed by the PHR, followed by the payload---an ordering that allows the
  receiver to synchronize before it needs to parse frame metadata.

  The physical layer's performance at 868 MHz is designed for robustness in low
  signal-to-noise ratio environments, reflecting deployments where nodes are
  separated by walls, floors, or other obstructions, and where the relatively
  low carrier frequency provides better penetration than 2.4 GHz at the cost of
  lower available bandwidth.

  == The MAC Layer

  === Services

  The MAC layer provides three categories of service. The _data service_ handles
  transmission and reception of MAC frames (MPDUs) across the physical layer
  interface, including optional acknowledgement of received frames. The
  _management service_ provides synchronization, channel access control,
  management of Guaranteed Time Slots, and association and disassociation of
  devices from personal area networks. The _security service_ provides data
  encryption, access control, frame integrity, and sequential freshness, all
  based on symmetric-key cryptography; keys are supplied by higher layers, and
  security features are optional and selectively enabled by the application.

  === Device Types

  IEEE 802.15.4 defines two device types that differ in their MAC layer
  implementation and network role. _Full Function Devices_ (FFDs) implement the
  complete MAC layer specification and can act as the PAN coordinator---the node
  that establishes and manages the network---or as generic coordinators that
  manage a set of associated devices. The PAN coordinator selects the PAN
  identifier, manages the superframe structure, and arbitrates associations and
  disassociations. _Reduced Function Devices_ (RFDs) implement a subset of the
  MAC layer sufficient for simple end-device operation: they can associate with
  an existing network, transmit and receive data, and follow the superframe
  schedule, but they cannot act as coordinators or route traffic on behalf of
  others. A single RFD can be associated with at most one FFD at any time. RFDs
  are intended for the simplest sensing and actuation devices---light switches,
  temperature sensors, binary detectors---where the cost and energy savings of a
  minimal implementation outweigh the loss of routing capability.

  === Network Topologies

  IEEE 802.15.4 supports two logical topologies. In the _star_ topology, one FFD
  acts as the PAN coordinator and all other nodes---whether FFDs or
  RFDs---communicate only with the coordinator. Routers in ZigBee star
  deployments behave as RFDs with respect to the 802.15.4 MAC, forwarding
  traffic upward to the coordinator rather than routing between peers. In the
  _peer-to-peer_ topology, each FFD can communicate directly with any other
  device within its radio range; the PAN coordinator is still present but does
  not mediate all traffic. RFDs in a peer-to-peer topology remain leaf nodes
  connected to one FFD parent. Different personal area networks are identified
  by distinct PAN identifiers and are independent of each other.

  == Channel Access

  === Superframe Structure

  The superframe is IEEE 802.15.4's primary mechanism for coordinating channel
  access and enabling sleep scheduling. It is used in star topologies and in
  peer-to-peer topologies organized as trees, and provides the synchronization
  infrastructure upon which ZigBee's beacon-enabled network mode is built.

  Each superframe begins with a _beacon frame_ transmitted by the PAN
  coordinator. The beacon serves three purposes: it identifies the PAN and its
  parameters, it synchronizes all associated devices to a common time reference,
  and it communicates the structure of the superframe that follows. The
  superframe is divided into an _active period_ of up to sixteen equally-sized
  time slots and an _inactive period_ during which the coordinator and
  associated devices may enter low-power sleep mode. All communication occurs
  during the active period; the inactive period is entirely idle from a network
  perspective, allowing devices to reduce their radio duty cycle to the fraction
  represented by the active period's duration.

  The active period is further divided into a _Contention Access Period_ (CAP)
  and an optional _Contention Free Period_ (CFP). The CAP occupies the initial
  time slots of the active period, up to a maximum of fifteen, and uses a
  slotted CSMA-CA protocol for channel access: before transmitting, a device
  waits for a random number of slots (the random backoff), checks whether the
  channel is clear using CCA, and transmits if idle. If the channel is found
  busy, the device waits another random number of slots before retrying. Once a
  transmission begins, the node retains the medium for the duration of its
  frame. The slotted nature of the CSMA-CA protocol---where all backoff periods
  are aligned to slot boundaries---reduces the probability of mid-transmission
  collisions compared to unslotted CSMA-CA.

  The CFP, when present, occupies the final time slots of the active period and
  is divided into _Guaranteed Time Slots_ (GTSs), each allocated by the PAN
  coordinator to a specific application. A GTS may span one or more consecutive
  time slots, and up to seven GTSs may exist within a single CFP. Devices that
  have been allocated a GTS may transmit during their slot without
  competition---no CSMA-CA, no random backoff, no collision risk. This provides
  bounded latency and guaranteed bandwidth to applications with real-time or
  quality-of-service requirements. The CAP always precedes the CFP, and all
  contention-based management traffic---including GTS allocation requests and
  association messages---must complete before the CFP begins. A device
  transmitting in a GTS must complete its transmission within its allocated
  slots; it may not overflow into the next GTS or into the CAP of the following
  superframe.

  In peer-to-peer networks that use the superframe structure, all routers within
  a PAN use the same superframe parameters chosen by the coordinator; each
  router initiates its own superframe by sending a beacon, but all beacons
  conform to the shared parameters. The active periods of all superframes in the
  PAN therefore have the same length, and devices can synchronize to multiple
  coordinators consistently.

  === Channel Access Without Superframe

  The PAN coordinator may choose not to use the superframe structure at all,
  operating in what the standard calls a _non-beacon-enabled_ mode. In this
  mode, no beacons are sent, no time slots exist, and channel access is based on
  unslotted CSMA-CA: a device wishing to transmit checks the channel once and
  transmits if clear, or backs off randomly and retries if busy. There is no
  sleep coordination at the MAC level; coordinators and routers must remain
  continuously active and ready to receive from end-devices at any time.

  Data transfer from a coordinator or router to an end-device in non-beacon mode
  is poll-based: the end-device periodically wakes up and sends a data request
  to its coordinator using unslotted CSMA-CA. The coordinator acknowledges the
  request and transmits any pending messages, or sends an empty response if
  nothing is queued. This model places the sleep scheduling decision entirely
  with the end-device, which independently determines its wake-up frequency; the
  coordinator cannot proactively notify a sleeping end-device that a message has
  arrived.

  The trade-off between beacon-enabled and non-beacon-enabled modes reflects the
  fundamental tension identified throughout this part of the course. The
  superframe structure achieves disciplined, coordinated sleep scheduling that
  can reduce network-wide duty cycle in a predictable and uniform way, but it
  requires synchronization overhead, periodic beacon transmissions, and the
  constraint that the active period structure fits the timing requirements of
  all associated devices. The non-beacon mode is more general and imposes fewer
  constraints on device behavior, but it requires coordinators to remain
  continuously powered and lacks the MAC-level sleep coordination that reduces
  energy consumption in dense deployments.

  == Data Transfer Modes

  IEEE 802.15.4 defines three data transfer modes that correspond to three
  directions of communication within a network. The specific procedures for each
  mode differ between beacon-enabled and non-beacon-enabled networks.

  In the first mode, _end-device to coordinator_, the end-device transmits its
  data frame to the coordinator. In a beacon-enabled network, the end-device
  first synchronizes with the superframe by waiting for the next beacon, then
  either transmits in its allocated GTS (if one has been assigned) or uses
  slotted CSMA-CA in the CAP. The coordinator may optionally send an
  acknowledgement frame in a subsequent slot. In a non-beacon network, the
  end-device uses unslotted CSMA-CA to transmit directly, and the coordinator,
  which is always on, acknowledges optionally.

  In the second mode, _coordinator to end-device_, the coordinator buffers the
  message and signals its availability in the beacon (beacon-enabled) or waits
  for the end-device to poll (non-beacon). In the beacon-enabled case, the
  end-device notices the pending-message indication in the beacon during one of
  its periodic wake-ups, requests the message during the CAP, receives an
  acknowledgement and then the data frame itself in a subsequent slot, and sends
  a final mandatory acknowledgement. In the non-beacon case, the end-device
  sends an unsolicited data request using unslotted CSMA-CA; the coordinator
  acknowledges and sends any pending messages, or an empty response if none are
  queued.

  The third mode, _peer-to-peer_, covers direct communication between two
  devices that are within radio range of each other. In star topologies,
  peer-to-peer transfers between end-devices are not supported directly; all
  traffic passes through the coordinator. In peer-to-peer topologies, any pair
  of devices within radio range may communicate. In beacon-enabled peer-to-peer
  networks, a sending device must first synchronize with the receiver's beacon
  before transmitting, effectively acting as an end-device with respect to the
  receiver's coordinator role. The standard does not specify how two
  coordinators synchronize their beacons with each other; this is left to
  higher-layer protocols such as ZigBee.

  == The Association Protocol

  The association protocol governs how a new device joins an existing personal
  area network. It exemplifies how the service primitive model orchestrates a
  coordinated interaction across the MAC and network layers of both the joining
  device and the coordinator.

  The joining device first executes the SCAN management service, which scans for
  active beacons on available channels and builds a list of candidate PANs and
  their parameters. After selecting a PAN, the device invokes the
  ASSOCIATE.request management primitive, providing the PAN identifier, the
  coordinator's address, and its own 64-bit extended IEEE MAC address. The MAC
  layer constructs an association request command frame and transmits it to the
  coordinator using the slotted CSMA-CA protocol within the CAP of the next
  superframe. The coordinator's MAC layer acknowledges receipt of the request
  immediately---this acknowledgement confirms only that the frame was received,
  not that the request has been granted.

  The coordinator's MAC layer passes the request to the network layer via the
  ASSOCIATE.indication primitive. The network layer---in ZigBee, this is the
  ZDO---decides whether to accept or reject the request and, if accepting,
  selects a 16-bit short address for the new device. This short address will
  replace the 64-bit IEEE address in all subsequent network-layer communication,
  reducing header overhead. The network layer invokes the ASSOCIATE.response
  primitive, providing the 64-bit address of the joining device, its assigned
  16-bit short address, and a status code. The MAC layer uses _indirect
  transmission_ to deliver the association response: the response is queued in
  the coordinator and delivered when the joining device issues a data request,
  since the device cannot yet receive direct-addressed frames (its short address
  has not been established).

  After a pre-defined waiting time (during which the coordinator is preparing
  the response), the joining device's MAC layer sends a data request command to
  the coordinator, receives an acknowledgement, and then receives the
  association response frame. The joining device's MAC layer reports the outcome
  to the network layer via the ASSOCIATE.confirm primitive, conveying either the
  assigned short address (on success) or an error code (on failure).
  Simultaneously, the coordinator's MAC layer issues a COMM-STATUS.indication
  primitive to its network layer, confirming that the association transaction
  has concluded.

  This multi-step, multi-primitive exchange---involving request,
  acknowledgement, queuing, polling, delivery, and status reporting on both
  sides---illustrates the care with which 802.15.4 handles the bootstrapping
  problem of adding a new device to a network before that device has a network
  identity. The use of the 64-bit IEEE address for the initial exchange ensures
  globally unique identification even before a short address is assigned; the
  transition to the short address afterward reduces the per-frame overhead for
  all subsequent communication.

  == Security Services

  The MAC layer provides a set of symmetric-key security services that establish
  a baseline of protection for MAC frames. These services are optional and
  selectively configurable; the choice of which services to enable, and the
  management of cryptographic keys, are delegated to higher layers. The security
  architecture is intentionally minimal at the MAC level, consistent with the
  standard's philosophy of leaving advanced functionality to higher-layer
  specifications.

  _Access control_ is implemented through an Access Control List (ACL)
  maintained by each device, enumerating the other devices with which it is
  authorized to communicate. Frames received from devices not on the ACL are
  discarded without processing, providing a coarse filter against unsolicited
  communication.

  _Data encryption_ applies symmetric encryption to the payload of data frames,
  command frames, and beacon payloads. The encryption key may be a _group key_
  shared by all devices in the network or a _link key_ shared exclusively by a
  pair of devices. Group keys are operationally simpler but provide weaker
  isolation: compromise of any one device exposes the key for the entire
  network. Link keys are more secure but require $O(n^2)$ key pairs for $n$
  devices, which may be impractical for large networks.

  _Frame integrity_ protects against tampering with frame contents by parties
  who do not possess the cryptographic key. A Message Integrity Code (MIC) is
  computed over the frame data using the same key as encryption, and appended to
  the frame. A receiver that recomputes the MIC and finds it inconsistent with
  the received value discards the frame. Frame integrity may be applied
  independently of encryption or in combination with it, allowing scenarios
  where data must be authenticated but not kept confidential.

  _Sequential freshness_ provides protection against replay attacks, in which an
  adversary captures a valid frame and retransmits it later. The standard
  requires that incoming frames be ordered by sequence number, and frames that
  are not more recent than the last accepted frame are discarded. This ensures
  that a replayed frame---which carries an old sequence number---is rejected
  even if its integrity check passes.

  These four services form composable building blocks: a specific deployment may
  enable all four, or only integrity and freshness without encryption (for cases
  where confidentiality is not required but authenticity is), or only access
  control (for the most resource-constrained devices). The keys themselves are
  provided by higher-layer security protocols; in ZigBee, the Trust Center
  distributes and manages keys via the APS security layer, which in turn makes
  them available to the MAC layer when needed.

]
