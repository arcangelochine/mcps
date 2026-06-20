#import "@preview/bookly:3.1.0": *

#let abs = [
  Mobile cellular networks have evolved from analog voice systems to the all-IP,
  virtualized, service-differentiated infrastructure of 5G, each generation
  introducing architectural innovations driven by the demands of new
  applications and the limitations of its predecessor. This chapter traces the
  evolution from first-generation analog systems through 4G LTE and 5G,
  examining the architectural components of each generation and the principles
  that guided their design. Particular attention is given to the 4G Long-Term
  Evolution (LTE) architecture---its radio access network, evolved packet core,
  control and data plane separation, and tunneling mechanisms---and to the ways
  in which 5G both inherits from and departs from this foundation through its
  Service-Based Architecture and cloud-native design. The second half of the
  chapter addresses mobility management: the problem of maintaining continuous
  service to a device as it moves through a network of cells, changes base
  stations, or roams into foreign networks. Indirect routing via the home
  network, direct routing via location lookup, the 4G handover protocol, and the
  Authentication and Key Agreement (AKA) security procedure are all examined in
  depth. The chapter closes with the impact of wireless links and mobility on
  higher-layer protocols, particularly TCP. The recurring tension throughout is
  between _transparency_ and _efficiency_: mobility management that is fully
  transparent to the correspondent and the application is simplest to deploy but
  incurs routing inefficiencies, while approaches that optimize routing paths
  require more coordination and expose mobility to higher layers.
]

#chapter(
  title: "Mobile Networks",
  abstract: abs,
  toc: true,
)[

  == From 1G to 5G: A Brief History

  The evolution of mobile cellular networks spans four decades and five
  generations, each defined by a distinct combination of radio technology,
  switching architecture, and service model. First-generation (1G) systems,
  deployed in the 1980s, carried analog voice using Frequency Division Multiple
  Access (FDMA), in which each call occupied an exclusive frequency channel for
  its duration. Coverage was limited, security was essentially absent (calls
  could be intercepted with a radio scanner), and the system was designed
  entirely around circuit-switched voice.

  Second-generation (2G) systems, exemplified by GSM and CDMA, digitized voice
  using a combination of Time Division Multiplexing and Frequency Division
  Multiplexing, enabling more efficient spectrum use, rudimentary security, and
  Short Message Service (SMS). The addition of General Packet Radio Service
  (GPRS) in what is sometimes called 2.5G introduced packet-based data alongside
  circuit-switched voice---an early acknowledgement that mobile devices would
  carry data, not just voice.

  Third-generation (3G) systems maintained the circuit-switched voice core of 2G
  while adding a parallel packet-switched data network, enabling mobile internet
  access at tens to hundreds of kilobits per second. The coexistence of circuit
  and packet switching in 3G reflected a transitional moment: voice remained the
  primary service, and the data infrastructure was grafted onto an architecture
  designed for telephony.

  Fourth-generation (4G) LTE marked a clean break: the core network became fully
  IP-based, carrying both voice and data as IP packets. The separation between
  voice and data traffic that had characterized earlier generations disappeared;
  voice became just another application carried over the IP infrastructure. The
  architecture introduced an explicit separation between the control plane
  (which manages device authentication, mobility tracking, session
  establishment, and network state) and the data plane (which forwards user
  packets), a principle that would be further developed in 5G. The third column
  of this evolution is 5G: an enhanced all-IP core built on a Service-Based
  Architecture in which network functions are independent software components
  communicating over standardized REST interfaces, combined with network slicing
  to serve radically different application classes on shared physical
  infrastructure, and support for millimeter-wave spectrum to achieve the
  multi-gigabit data rates required by enhanced broadband applications.

  == 4G LTE Architecture

  === Overview

  The 4G LTE network is organized into two major subsystems. The _Radio Access
  Network_ (RAN) is a distributed collection of base stations that manage the
  radio spectrum and communicate with mobile devices over the wireless link. The
  _Mobile Core_, called the Evolved Packet Core (EPC) in 4G, provides IP
  connectivity for both data and voice services, enforces quality of service
  requirements, tracks device mobility, and handles billing and charging. The
  RAN and EPC are interconnected by the _backhaul network_, typically a wired
  fiber-optic infrastructure, though emerging Integrated Access Backhaul (IAB)
  solutions allow wireless backhaul using the same spectrum as the access link.

  === Radio Access Network Elements

  The mobile device, called _User Equipment_ (UE) in LTE terminology, is any
  device with a 4G LTE radio interface---smartphone, tablet, laptop, IoT sensor.
  Each UE is identified by a 64-bit _International Mobile Subscriber Identity_
  (IMSI) stored on a SIM (Subscriber Identity Module) card. The IMSI encodes the
  subscriber's country, home cellular carrier, and unique identifier, enabling
  roaming services across international carrier boundaries. The UE implements a
  full five-layer Internet protocol stack, treating the cellular link as a
  wireless data link layer.

  The _base station_, called _eNode-B_ (evolved Node-B) in LTE, manages all
  wireless communication resources within its coverage area (a cell). Unlike a
  Wi-Fi access point, which is essentially a passive relay, the eNode-B takes an
  active role in mobility: it coordinates with neighboring base stations to
  minimize inter-cell interference, manages handovers as devices move between
  cells, and creates device-specific IP tunnels from the UE to the gateways of
  the EPC. Adjacent eNode-Bs communicate directly with each other over the X2
  interface to optimize radio resource management and coordinate handover
  decisions.

  === Evolved Packet Core Elements

  The _Home Subscriber Server_ (HSS) is a database that stores all
  subscriber-related information: the subscriber's IMSI, service subscription
  profile, current location, and authentication credentials. The HSS is the
  authoritative source of identity information for the carrier's subscriber
  base. When a device roams into a visited network, the visited network's
  control plane contacts the device's home HSS to verify identity and retrieve
  service authorization.

  The _Mobility Management Entity_ (MME) is the primary control-plane element of
  the EPC. It authenticates devices (working with the HSS), manages the
  lifecycle of device sessions, tracks device location (including when the
  device is in a light sleep state and must be paged), coordinates handovers
  between base stations, and establishes the tunneling paths that will carry
  user-plane traffic from the device to the internet.

  User-plane traffic traverses two gateways in tandem. The _Serving Gateway_
  (S-GW) is the local mobility anchor within the EPC: it forwards IP packets
  between the RAN and the rest of the core, and when a device moves from one
  eNode-B to another within the same network, only the tunnel endpoint on the
  RAN side changes---the S-GW remains constant, preserving continuity of the
  data path. The _PDN Gateway_ (P-GW) is the boundary between the 4G core and
  the public internet or private enterprise networks. It appears to the rest of
  the internet as a conventional gateway router, while providing NAT services,
  policy enforcement, traffic shaping, and charging functions specific to the
  cellular context. The S-GW and P-GW can be co-located on the same physical
  node in smaller deployments, and a single MME/P-GW pair may serve an entire
  metropolitan area while S-GWs are distributed across edge sites, each serving
  on the order of a hundred base stations.

  === Control and Data Plane Separation

  The 4G architecture enforces a strict separation between control-plane and
  data-plane functions, reflecting the broader Software-Defined Networking
  philosophy that was emerging in parallel. Control-plane
  signaling---authentication, registration, mobility tracking, tunnel setup---is
  carried over SCTP/IP, using the Stream Control Transmission Protocol, an
  alternative to TCP specifically designed for telephony signaling that provides
  message-boundary preservation and multi-homing support. User-plane data is
  carried over GTP/UDP/IP, using the GPRS Tunneling Protocol to encapsulate the
  user's IP datagram inside a UDP datagram addressed to the next tunnel
  endpoint.

  The tunneling architecture is the key mechanism that makes mobility
  transparent to the application layer. The user's datagram is encapsulated in
  GTP and sent through a sequence of tunnels: first from the UE to the eNode-B
  over the wireless link (using LTE-specific link layer protocols), then from
  the eNode-B to the S-GW through a GTP tunnel, and finally from the S-GW to the
  P-GW through a second GTP tunnel. Each tunnel is identified by a _Tunnel
  Endpoint Identifier_ (TEID). When the mobile device moves and the eNode-B
  changes, only the TEID of the first tunnel segment changes---the rest of the
  data path is preserved. From the perspective of the internet-side
  correspondent, the mobile device always appears to have the same IP address
  (the one assigned by the P-GW), regardless of its current physical location.

  === LTE Link Layer Protocols

  The wireless link between the UE and the eNode-B uses a stack of LTE-specific
  link-layer protocols. The _Packet Data Convergence Protocol_ (PDCP) performs
  header compression (reducing the per-packet overhead of IP, TCP, and UDP
  headers) and encryption of user-plane data. The _Radio Link Control_ (RLC)
  protocol handles fragmentation and reassembly of IP packets to fit within the
  variable-length radio frames allocated by the scheduler, and provides
  link-layer reliable data transfer through ACK/NACK mechanisms. The _Medium
  Access Control_ (MAC) sublayer manages the allocation of radio transmission
  slots to active devices and performs error detection and correction. The radio
  channel itself uses OFDM (Orthogonal Frequency Division Multiplexing) in the
  downstream direction, dividing the available spectrum into orthogonal
  subcarriers that minimize inter-channel interference. Each active mobile
  device is allocated time-frequency slots by a scheduler that is not
  standardized---operators implement their own scheduling algorithms---enabling
  data rates of hundreds of megabits per second per device under favorable
  channel conditions.

  === Sleep Modes

  Battery-powered mobile devices manage energy consumption by sleeping when
  inactive, using mechanisms analogous to those discussed for IoT devices in
  earlier chapters but at the scale and latency requirements of a consumer
  cellular network. In _light sleep_ mode, activated after hundreds of
  milliseconds of inactivity, the UE powers down its radio and wakes
  periodically (every few hundred milliseconds) to check for incoming data
  indications. In _deep sleep_ mode, activated after five to ten seconds of
  inactivity, the device may move between cells while sleeping and must
  re-establish its base station association upon waking to check for paging
  messages. When an incoming call or message arrives for a sleeping device, the
  MME broadcasts a _paging_ message to the base stations in the area where the
  device was last known to be located, alerting it to wake up and establish a
  connection.

  == The 5G Architecture

  === Design Principles

  5G targets a tenfold increase in peak data rate and a tenfold decrease in
  latency compared to 4G, as well as a hundredfold increase in traffic
  capacity---ambitious goals that require architectural changes, not merely
  radio improvements. The 5G radio, called 5G NR (New Radio), operates across
  two frequency ranges: FR1 (450 MHz to 6 GHz, overlapping with and extending 4G
  frequencies) and FR2 (24 GHz to 52 GHz, the millimeter-wave band).
  Millimeter-wave frequencies support much higher data rates than sub-6 GHz
  frequencies but propagate over shorter distances and are more susceptible to
  blockage, requiring dense deployment of small cells with diameters of 10 to
  100 meters and extensive use of directional MIMO antennas.

  The 5G core is designed around three principles that distinguish it from the
  4G EPC. The first is a _Service-Based Architecture_ (SBA): rather than
  defining fixed point-to-point interfaces between named functional entities, 5G
  organizes its control plane as a collection of independent Network Functions
  (NFs), each exposing its capabilities through a standardized REST interface
  using HTTP/2, and each potentially implemented as a software microservice. The
  second principle is complete _control and user plane separation_, with the
  user-plane function (UPF) designed to be deployed flexibly at edge locations
  as well as in the core, enabling Multi-Access Edge Computing (MEC). The third
  principle is _cloud-native design_: all 5G core functions are designed to run
  as containers or VMs on commodity hardware, with stateless service functions
  supported by dedicated data storage services (SDSF for structured data, UDSF
  for unstructured data) that allow compute functions to be restarted, scaled,
  or migrated without carrying session state.

  === 5G Core Functions

  The 5G core reorganizes the 4G EPC functions and introduces new ones. The
  _User Plane Function_ (UPF) combines the S-GW and P-GW of 4G, forwarding
  traffic between the RAN and the internet while performing packet inspection,
  QoS management, and usage reporting; multiple UPFs may be chained for
  optimized routing. The _Access and Mobility Management Function_ (AMF),
  derived from the 4G MME, handles connection and mobility management but not
  session management. The _Session Management Function_ (SMF), also derived from
  the MME and the control aspects of the 4G P-GW, manages the establishment,
  modification, and release of user data sessions and performs IP address
  management.

  Authentication is handled by two specialized functions: the _Authentication
  Server Function_ (AUSF) executes authentication procedures for 5G subscribers
  by retrieving credentials from the _Unified Data Management_ function (UDM),
  which manages subscription data and user identities, replacing the 4G HSS.
  Several new support functions have no direct 4G counterpart: the _NF
  Repository Function_ (NRF) enables dynamic service discovery among network
  functions; the _Network Exposure Function_ (NEF) provides controlled access to
  5G capabilities for third-party services; and the _Network Slicing Selection
  Function_ (NSSF) selects the appropriate network slice to serve a given UE.

  === Network Slicing and 5G Use Cases

  5G's defining service differentiation is its support for three qualitatively
  distinct application classes. _Enhanced Mobile Broadband_ (eMBB) serves
  applications requiring very high data rates---mobile augmented and virtual
  reality, 4K and 360-degree video streaming---with multi-gigabit peak rates and
  more than 100 Mbps sustained throughput. _Ultra-Reliable Low-Latency
  Communication_ (URLLC) serves mission-critical applications such as factory
  automation and autonomous driving, with end-to-end latencies as low as 1
  millisecond and availability exceeding five nines (99.999%). _Massive
  Machine-Type Communication_ (mMTC) serves dense deployments of IoT sensors and
  actuators with extremely low per-device energy consumption (enabling
  decade-long battery life), low data rates (tens of bits per second per
  device), and densities of up to one million nodes per square kilometer.

  These use cases have incompatible requirements that cannot all be optimized
  simultaneously on a single network configuration. Network slicing---the
  creation of multiple virtual networks on shared physical infrastructure, each
  configured with its own chain of VNFs tailored to its use case's
  requirements---is the architectural mechanism that allows one physical
  infrastructure to serve all three simultaneously.

  === 5G Deployment Options

  5G base stations (gNB, or next-generation Node-B) can be deployed in several
  configurations relative to the existing 4G infrastructure. In _Standalone_
  (SA) mode, the 5G RAN connects to the 5G core (NG-Core) independently. In
  _Non-Standalone_ (NSA) mode, 5G base stations are deployed alongside 4G base
  stations and share the 4G EPC, with 5G providing additional data-plane
  capacity while 4G handles control-plane signaling. NSA deployment is the more
  common early-5G configuration because it leverages existing 4G infrastructure,
  but it does not deliver the full latency and slicing benefits of 5G SA.
  Standalone 5G deployment varies significantly by geography: as of early 2025,
  China leads with approximately 80% SA penetration, while European deployments
  lag at around 2%.

  == Authentication in 4G LTE

  === The AKA Protocol

  Authentication in 4G LTE uses the _Authentication and Key Agreement_ (AKA)
  protocol, defined by 3GPP. AKA is a challenge-response protocol based on a
  symmetric secret key $K_{"HSS-M"}$ shared between the subscriber (stored on
  the SIM card) and the home network's HSS. The protocol achieves mutual
  authentication---the network authenticates the device, and the device
  authenticates the network---and derives session keys for encrypting both
  signaling and user-plane traffic.

  The AKA exchange involves three parties: the mobile device (UE), the Mobility
  Management Entity (MME) in the visited network, and the Home Subscriber Server
  (HSS) in the home network. The flow proceeds in five steps.

  First, the UE sends an attach message containing its IMSI. The base station
  relays this to the MME, which forwards the IMSI along with visited network
  information to the home HSS.

  Second, the HSS uses the shared key $K_{"HSS-M"}$ to compute two values: an
  _authentication token_ (auth_token) that proves to the UE that the HSS knows
  the shared key, and an expected authentication response (xres_HSS) that the
  HSS will use to verify the UE's response. The HSS sends both, plus derived
  session keys, to the MME. The MME retains xres_HSS for later verification.

  Third, the UE receives the auth_token and uses its own copy of $K_{"HSS-M"}$
  to verify that the token was produced by the home network---if the decryption
  succeeds, the UE has authenticated the network. The UE then computes its own
  response value $"res"_M$ using $K_{"HSS-M"}$ and the same cryptographic
  function the HSS used to compute xres_HSS.

  Fourth, the UE sends $"res"_M$ to the MME, which compares it to the
  HSS-computed xres_HSS. If they match, the MME concludes that the UE possesses
  the shared key and is therefore the legitimate subscriber---the device is
  authenticated.

  Fifth, using the session keys received from the HSS, the MME and the UE derive
  keys for encrypting the wireless link (using AES or another cipher),
  completing the mutual authentication and key establishment.

  The 4G architecture delegates the authentication decision to the MME in the
  visited network, which acts on the xres_HSS value received from the home
  network but makes the final comparison itself. A significant security
  difference in 5G is that the home network retakes direct control of the
  authentication decision, reducing the trust that must be placed in the visited
  network's MME. Additionally, 4G transmits the IMSI in cleartext during the
  initial attach, enabling passive surveillance of device identities; 5G
  encrypts the IMSI using the home network's public key, preventing
  eavesdroppers from learning which subscriber is attaching.

  == Mobility Management

  === The Nature of Mobility

  Mobility in cellular networks spans a spectrum from trivial to challenging
  depending on the scale and continuity requirements of the movement. At one
  extreme, a device that powers off in one location and powers on in another has
  no ongoing connections to maintain and can simply re-register in its new
  location. At the other extreme, a device in a video call or active data
  session that moves between cells, between carrier networks, or between
  countries requires its data path to be continuously maintained without
  interruption visible to the application.

  The fundamental question is one of indirection: when a correspondent wants to
  send packets to a mobile device, how does it find where the device currently
  is? Two broad strategies exist: letting the network (routers and routing
  protocols) handle location transparently, or letting end systems handle it by
  consulting a location service.

  The routing-table approach---advertising the mobile's current location as a
  host route, updated whenever the device moves---would work in principle with
  standard IP routing but is impractical at scale: propagating per-device
  routing updates to the global internet for billions of mobile devices would
  overwhelm routing infrastructure. Instead, cellular networks use an
  _end-system approach_ in which location information is maintained in the home
  network's subscriber database (the HSS) and the data path is managed through
  tunneling.

  === Home and Visited Networks

  Every mobile subscriber belongs to a _home network_---the carrier with which
  they have a service contract, whose HSS stores their IMSI, service profile,
  and current location. When a device operates outside its home network, it is
  in a _visited network_, which it can use through a _roaming_ agreement between
  the visited carrier and the home carrier. The home network serves as the
  permanent reference point for any correspondent wishing to reach the device:
  correspondence is addressed to the device's permanent home-network IP address,
  and the home network is responsible for forwarding traffic to wherever the
  device currently is.

  When a device enters a visited network, a registration procedure updates the
  home HSS with the device's current location. The visited network assigns the
  device a transient network address (its address within the visited network),
  and the home HSS records this association. Correspondents addressing the
  device at its permanent home address will have their packets intercepted by
  the home gateway and forwarded to the current visited network.

  === Indirect Routing

  _Indirect routing_ is the approach used in 4G LTE and in the Mobile IP
  standard. A correspondent always addresses packets to the mobile device's
  permanent home-network address. The home network's gateway intercepts these
  packets and tunnels them to the visited network's gateway, which decapsulates
  and delivers them to the device. Replies from the mobile device can either
  return via the home network (maintaining the triangle) or be sent directly to
  the correspondent.

  The term "triangle routing" captures the inefficiency of this approach: even
  when the correspondent and the mobile device are physically co-located in the
  same visited network, data must travel to the home network and back before
  reaching the device. This can add significant latency for geographically
  separated home and visited networks. However, indirect routing has a
  significant operational advantage: it is completely transparent to the
  correspondent and to the application. The correspondent uses the same address
  regardless of where the device is; all location tracking is handled within the
  network infrastructure; and when the device moves to a new visited network,
  the correspondent's data path is automatically updated without any
  notification to the application.

  === Direct Routing

  _Direct routing_ overcomes the triangle routing inefficiency by having the
  correspondent query the home HSS for the device's current visited-network
  address at the beginning of a communication session, then send subsequent
  packets directly to that address. This eliminates the detour through the home
  network, reducing latency particularly when correspondent and mobile are
  geographically close.

  The cost of direct routing is transparency: the correspondent must participate
  in the location lookup process, which requires an interface between the
  correspondent's network and the home HSS that does not exist in standard
  internet protocols. More significantly, if the device moves while a session is
  in progress, the correspondent's cached care-of address becomes stale.
  Indirect routing handles this gracefully---new tunneling endpoints are
  configured transparently when the device moves---but direct routing requires
  additional mechanisms to handle mid-session mobility, adding complexity.

  === Mobility Management in 4G: The Four Steps

  Mobility management in 4G LTE involves four coordinated tasks when a device
  enters or moves within a network.

  _Base station association_ is the first step: the device scans for base
  stations by listening for primary and secondary synchronization signals
  broadcast by each eNode-B every five milliseconds. Having identified a base
  station, the device learns the carrier's network configuration and associates
  with its preferred BS (typically the one with the strongest signal from the
  device's home carrier).

  _Control-plane configuration_ establishes the device's identity and service
  context in the visited network. The device communicates with the MME via the
  BS's control-plane channel; the MME contacts the home HSS to retrieve
  authentication credentials and service authorization; and the AKA protocol
  authenticates the device. After authentication, the BS and device negotiate
  radio channel parameters.

  _Data-plane configuration_ establishes the tunneling paths that will carry the
  device's user-plane traffic. The MME directs the establishment of two GTP
  tunnels: one from the S-GW to the BS (the first hop of the user-plane path),
  and one from the S-GW to the home P-GW (implementing indirect routing). All
  traffic to and from the device is encapsulated in GTP and traverses these
  tunnels.

  _Handover_ occurs when the device moves from one eNode-B to another. The
  source eNode-B detects deteriorating signal quality or excessive cell load and
  selects a target eNode-B, sending it a Handover Request message. The target BS
  pre-allocates radio slots and acknowledges with a Handover Request ACK
  containing the radio parameters the device will use. The source BS signals the
  device to switch to the target BS; the device transitions, and the source BS
  forwards any buffered datagrams to the target BS during the transition. The
  target BS informs the MME, which updates the S-GW's tunnel endpoint to point
  to the new BS. The source BS is released once the handover is confirmed
  complete, and the device's datagrams now flow through a new first-hop tunnel
  from the target BS to the S-GW.

  This handover protocol is notable for what it minimizes: in-flight packet
  loss. The source BS continues buffering and forwarding packets to the target
  BS during the transition, so that packets in flight at the moment of the
  decision are not simply dropped. A few packets may still be delivered
  out-of-order or lost at the boundary, but ongoing TCP or application-layer
  connections survive the handover with minimal disruption.

  == Mobile IP

  The Mobile IP standard (RFC 5944), developed approximately two decades before
  widespread 4G deployment, implements a similar architecture for IP mobility
  outside the cellular context. The _home agent_ in the mobile's home network
  combines the functions of the 4G HSS and home P-GW; the _foreign agent_ in the
  visited network combines the functions of the MME and S-GW. Mobile IP uses
  ICMP extensions for agent discovery and registration, allowing a roaming
  device to discover the nearest foreign agent and register its current location
  with the home agent.

  Mobile IP did not achieve significant deployment, partly because the
  combination of Wi-Fi for data and 2G/3G voice over dedicated circuit-switched
  infrastructure was adequate for the applications of the time, and partly
  because the deployment complexity of maintaining a home agent infrastructure
  was substantial. The architectural lessons of Mobile IP were incorporated into
  4G and 5G design, where the separation between home and visited network
  functions, indirect routing via home gateways, and tunneling-based mobility
  transparency are all present, now embedded in carrier infrastructure rather
  than in general internet protocols.

  == Impact of Wireless and Mobility on Higher-Layer Protocols

  The combination of wireless link characteristics and mobility creates
  performance challenges for higher-layer protocols, particularly TCP, that
  assume a wired internet model. At the logical level, the impact should be
  minimal: the best-effort delivery model of IP is unchanged, and TCP and UDP
  both operate correctly over wireless and mobile networks. At the performance
  level, however, several effects are significant.

  Wireless links have substantially higher bit error rates than wired links, and
  error recovery at the link layer (through RLC retransmissions in LTE)
  introduces variable delay that appears to TCP as network delay variation. More
  critically, TCP interprets packet loss as evidence of network congestion and
  responds by reducing its congestion window---the amount of data in
  flight---triggering the congestion avoidance mechanism and reducing
  throughput. When the loss is due to wireless bit errors or a handover rather
  than genuine congestion, this response is counterproductive: the network is
  not congested, but TCP has reduced its sending rate unnecessarily. Handover
  events cause brief but real packet losses that trigger this response;
  depending on handover duration and TCP's current congestion window, recovery
  can take several round-trip times, causing a measurable throughput reduction.

  Real-time traffic---voice, video conferencing, live streaming---is
  additionally affected by the delay variability introduced by wireless links
  and handovers. Jitter buffers at the receiver can absorb some variability, but
  handover delays that exceed the jitter buffer depth cause audible or visible
  glitches. As 5G's URLLC slice targets end-to-end latencies of one millisecond
  precisely to address these limitations for mission-critical applications, the
  path from physical radio performance through protocol behavior to application
  experience illustrates how deeply coupled the layers of a mobile network are.

]
