#import "@preview/bookly:3.1.0": *

#let abs = [
  Connecting billions of resource-constrained devices to the internet requires
  rethinking the assumptions embedded in the conventional TCP/IP protocol suite,
  which was designed for resource-rich machines communicating over reliable,
  high-bandwidth links. This chapter examines how the Internet of Things departs
  from that assumption and surveys the protocol landscape that has emerged in
  response. The central subject is the _Message Queuing Telemetry Transport_
  (MQTT) protocol: its publish/subscribe interaction model, its connection
  lifecycle, its Quality of Service guarantees, and its advanced features
  including retained messages, persistent sessions, and the Last Will mechanism.
  The recurring tension throughout the chapter is the trade-off between
  reliability and overhead---every design choice in MQTT reflects a deliberate
  judgment about how much protocol machinery an IoT device can afford to run.
  The chapter closes with a comparative analysis of MQTT and CoAP, two protocols
  that embody complementary philosophies for constrained networking, and
  examines how each aligns with different classes of IoT deployment.
]

#chapter(
  title: "IoT Protocol Stacks and MQTT",
  abstract: abs,
  toc: true,
)[

  == Why the Conventional Internet Stack Is Insufficient for IoT

  The internet protocol suite---IP for addressing and routing, TCP or UDP at the
  transport layer, HTTP at the application layer---is one of the great engineering
  achievements of the twentieth century. It was designed, however, with a
  particular kind of device in mind: a general-purpose computer with abundant
  memory, a reliable power supply, and a stable, high-bandwidth network
  connection. Internet of Things devices share almost none of these
  characteristics. A temperature sensor node running on two AA batteries,
  communicating over a lossy radio link, with eight kilobytes of RAM and no
  human operator, cannot afford the state machines, handshakes, and verbose
  headers that HTTP and TCP require. Yet such devices must communicate---that is
  precisely what makes them "things" in the IoT sense, rather than merely
  embedded systems.

  The mismatch between the conventional internet stack and IoT requirements runs
  across multiple dimensions. At the device level, IoT nodes are low-power,
  battery-operated, and memory-constrained, which demands small code footprints
  and minimal computation during the critical path of message processing. At the
  network level, IoT deployments frequently involve lossy links, intermittent
  connectivity, and multi-hop communication across wireless mesh topologies; the
  TCP assumption of a reliable, ordered, full-duplex byte stream is often simply
  false. At the application level, IoT communication patterns differ
  structurally from the client-server request-response model that HTTP embodies:
  a sensor does not wait to be queried but publishes data when it has something
  to report, and there may be many consumers for that data, not just one.

  These requirements translate directly into design criteria for IoT-appropriate
  protocols: scalability to large numbers of devices through multi-hop and mesh
  networking; configurable security that can be downgraded for devices too
  constrained to run cryptography; lightweight addressing with low-overhead
  protocol headers; low-duty-cycle operation that permits devices to sleep most
  of the time; and small protocol implementations that fit in the constrained
  memory of microcontrollers.

  == The Publish/Subscribe Paradigm

  Before examining MQTT in detail, it is worth understanding the interaction
  model that gives MQTT its distinctive character. The classical client/server
  paradigm, instantiated in HTTP, involves a client that knows the address of a
  server and sends it requests, receiving responses in return. This model is
  fundamentally bilateral and synchronous: two parties must be simultaneously
  available, and each interaction is point-to-point.

  _Publish/subscribe_ (pub/sub) is an alternative interaction schema that
  decouples message producers from message consumers in three distinct ways. In
  _space decoupling_, publishers and subscribers do not need to know each
  other's network addresses, and indeed do not need to know how many peers they
  have. In _time decoupling_, publisher and subscriber do not need to be active
  simultaneously; a message published while a subscriber is offline can be
  delivered when the subscriber reconnects. In _synchronization decoupling_,
  neither publisher nor subscriber blocks while the other party processes a
  message; both operate asynchronously relative to each other.

  The central actor in any pub/sub system is the _broker_ (also called the event
  service), which is the only entity that both publishers and subscribers know
  about directly. Publishers send all messages to the broker; the broker filters
  and distributes them to subscribers. Subscribers register their interest with
  the broker, not with individual publishers. The broker performs three
  essential functions: it receives all incoming messages from publishers,
  applies filtering logic to determine which subscribers should receive each
  message, and delivers matched messages to those subscribers. It also manages
  the subscription and unsubscription requests that define the ongoing interests
  of each subscriber.

  Message filtering at the broker can operate on several bases. _Subject-based_
  (or _topic-based_) filtering, which MQTT uses, embeds a topic label in each
  message; subscribers declare interest in a topic, and the broker forwards all
  messages bearing that topic to matching subscribers. _Content-based_ filtering
  allows subscribers to specify a predicate query---for example, "temperature
  greater than 30°C"---and receive only messages whose payload satisfies it; this
  requires the broker to inspect message contents and precludes end-to-end
  encryption. _Type-based_ filtering, common in object-oriented middleware,
  routes messages based on the type or class of the data they carry.

  An important practical implication of the pub/sub model is that a publisher
  cannot assume any subscriber is listening. The broker delivers messages to
  whoever has subscribed at delivery time, but the publisher has no visibility
  into this. This asymmetry is deliberate: it allows sensors to publish data
  continuously without coordinating with consumers, and it allows consumers to
  appear and disappear without affecting producers. The obligation that falls on
  both parties is agreement on topics before deployment, and knowledge of the
  broker's hostname and port.

  == MQTT: Overview and Position in the Protocol Stack

  _Message Queuing Telemetry Transport_ (MQTT) was created in 1999 by Andy
  Stanford-Clark of IBM and Arlen Nipper of Arcom, originally to monitor oil
  pipelines over satellite links---a context that explains many of its design
  choices. It is now an OASIS open standard and enjoys broad adoption in IoT
  platforms including Microsoft Azure IoT, Amazon AWS IoT, and Google Cloud IoT.

  MQTT is a lightweight, reliable, publish/subscribe messaging transport
  protocol. Its lightness manifests in three ways: a small code footprint
  suitable for microcontrollers, low network bandwidth consumption, and minimal
  packet overhead---all of which yield better communication efficiency than HTTP
  for small, frequent messages. It builds on TCP/IP, operating on port 1883 in
  plaintext and port 8883 over SSL/TLS, though the latter adds significant
  overhead and may be impractical for the most constrained devices. MQTT
  occupies levels five and six of the ISO/OSI model, sitting above TCP at level
  four.

  The protocol is _data agnostic_: the payload of an MQTT message can be any
  byte sequence---binary data, plain text, JSON, XML---and the broker treats it as
  opaque. This agnosticism simplifies the protocol but transfers the burden of
  data format agreement to the application layer. MQTT is also explicitly
  designed to shift complexity to the broker: client-side implementation is
  intentionally simple, which is why it suits low-power devices, while the
  broker handles subscription management, message routing, persistence, and
  quality-of-service guarantees.

  == Connection Establishment and Lifecycle

  Every MQTT interaction begins with a client connecting to the broker via a
  CONNECT message. This message carries several fields that establish the terms
  of the session. The _Client ID_ is a string uniquely identifying the client to
  the broker; if left empty, the broker assigns one and does not maintain state
  for the client, in which case the CleanSession flag must be set to true. The
  _CleanSession_ flag is a boolean that controls session persistence: when
  false, the broker stores all subscriptions and undelivered messages for the
  client across disconnections, resuming the previous session if one exists;
  when true, any prior session state is discarded at connect time.

  The _Username_ and _Password_ fields provide optional authentication, though
  without transport-layer security these credentials are transmitted in
  plaintext and offer limited protection. The _Will flags_ encode the Last Will
  and Testament feature, described in detail below. Finally, the _KeepAlive_
  value, expressed as a 16-bit integer in seconds, commits the client to sending
  at least one control packet---either a PINGREQ heartbeat or any regular
  message---to the broker within that interval. The broker uses this commitment to
  detect ungraceful disconnections: if the interval expires without any packet
  from the client, the broker closes the connection and triggers the client's
  Last Will message. Setting KeepAlive to zero disables the mechanism entirely.

  The broker responds to a CONNECT with a CONNACK message that reports whether
  the connection was accepted or refused (due to protocol violations, identifier
  rejection, or bad credentials) and whether a persistent session from a prior
  connection was found and resumed.

  == Topics and Their Hierarchy

  Every MQTT message carries a _topic_---a UTF-8 string that the broker uses to
  route the message to matching subscribers. Topics are organized into a
  hierarchy of levels separated by the forward-slash character, enabling
  semantically structured namespaces. A sensor reporting presence in a bedroom
  on the first floor of a house might publish to the topic
  `home/firstfloor/bedroom/presence`. This hierarchical structure is not merely
  organizational: subscribers can use _wildcards_ to express interest in entire
  subtopics. The single-level wildcard `+` matches exactly one level anywhere in
  the hierarchy, so `home/firstfloor/+/presence` matches presence sensors in any
  room on the first floor. The multi-level wildcard `#` matches any number of
  remaining levels and must appear at the end of the topic string, so
  `home/firstfloor/#` matches every sensor on the first floor, regardless of
  room or measurement type.

  Topics beginning with the dollar sign `$` are reserved for internal broker
  statistics and cannot be published to by clients. Common examples from the
  HiveMQ broker include `$SYS/broker/clients/connected` and
  `$SYS/broker/uptime`. There is no standardization of these system topics
  across brokers.

  Good topic design requires careful planning because topic structure, once
  deployed, is difficult to change without breaking existing subscribers. Best
  practices include avoiding a leading slash (which creates an empty first
  level), keeping topic strings short to minimize header overhead, using only
  ASCII characters, avoiding spaces, and embedding a device identifier in the
  topic where per-device granularity is required. Specific topics
  (`home/livingroom/temperature`, `home/livingroom/humidity`) are generally
  preferable to generic aggregates (`home/livingroom/sensors`) because they give
  subscribers fine-grained control over what they receive. Subscribing to the
  catch-all `#` wildcard should be used sparingly---only for administrative
  purposes such as logging all messages to a database---because the resulting
  message volume can overwhelm both the subscriber and the network.

  == Quality of Service

  The _Quality of Service_ (QoS) level is an agreement between a sender and a
  receiver about the delivery guarantees that apply to a particular message. In
  MQTT, QoS operates independently on each of the two legs of message delivery:
  between publisher and broker, and between broker and subscriber. It is
  therefore possible---and sometimes desirable---for the QoS level used on the
  publisher-to-broker leg to differ from that used on the broker-to-subscriber
  leg.

  _QoS level 0_, "at most once," is a best-effort delivery with no
  acknowledgement. The sender transmits the message once and does not retain a
  copy; if the message is lost in transit, it is simply lost. This level
  provides the same guarantee as the underlying TCP connection: delivery is
  assured only as long as the connection remains active. When the connection
  drops, any in-flight QoS 0 messages are gone. Level 0 is appropriate when the
  connection is stable and reliable, when individual messages are not critically
  important, or when measurement updates are so frequent that missing one or two
  is inconsequential.

  _QoS level 1_, "at least once," guarantees that the message arrives at the
  receiver but permits duplicates. The sender stores the message and retransmits
  it periodically until it receives a PUBACK acknowledgement. The receiver must
  therefore be prepared to handle the same message arriving more than once. The
  PUBLISH packet carries a packet identifier that allows the receiver to
  correlate acknowledgements. Level 1 is the right choice when all messages must
  be received and the recipient can tolerate---or deduplicate---duplicates.

  _QoS level 2_, "exactly once," is the highest and most expensive level. It
  guarantees that each message is received exactly once through a double two-way
  handshake involving four packets: PUBLISH, PUBREC (publish received), PUBREL
  (publish release), and PUBCOMP (publish complete). The rationale for this
  elaborate exchange is subtle. A single acknowledgement (PUBREC alone) is
  insufficient, because if PUBREC is lost in transit, the sender will retransmit
  the PUBLISH, resulting in a duplicate. The second handshake, initiated by
  PUBREL, allows both parties to agree on when they may safely discard the state
  associated with the message---the broker holds a reference to the message until
  PUBREL arrives, confirming that the sender knows the message was received, at
  which point duplicates can be detected and discarded. Level 2 is appropriate
  when messages must be received exactly once and duplicates are unacceptable,
  but its four-packet overhead makes it significantly slower and more
  energy-intensive than levels 0 or 1.

  Packet identifiers for QoS 1 and 2 messages are 16-bit integers that are
  unique per client, not globally unique. Different clients delivering the same
  logical message to a broker therefore use different packet identifiers, and
  the broker manages these namespaces independently. Messages sent at QoS levels
  1 and 2 are always stored for offline clients that have established persistent
  sessions, allowing delivery upon reconnection.

  == Advanced Features: Persistent Sessions, Retained Messages, and Last Will

  === Persistent Sessions

  By default, when a client disconnects from a broker, all session
  state---subscriptions, pending messages, partial QoS handshake records---is
  discarded. A client that reconnects must re-subscribe to all its topics and
  will miss any messages published during the disconnection. _Persistent
  sessions_ change this behavior: by setting the CleanSession flag to false at
  connect time, the client instructs the broker to store the session state
  across disconnections, keyed to the client's identifier. The stored state
  includes all subscriptions, all QoS 1 and 2 messages that arrived while the
  client was offline, and all QoS 1 and 2 messages that were sent to the client
  but not yet fully acknowledged. The client itself must also store state for
  persistent sessions: specifically, any outgoing QoS 1 and 2 messages not yet
  acknowledged by the broker, and any incoming QoS 2 messages not yet confirmed.

  Persistent sessions are valuable for subscribers that cannot afford to miss
  messages but are expected to be intermittently offline---a sensor-data logger
  that wakes periodically to retrieve accumulated readings, for example. They
  should be avoided for publish-only clients using QoS 0, and for any client
  where old messages are stale and irrelevant.

  === Retained Messages

  A subtler problem arises even when a client is continuously connected. When a
  subscriber connects and subscribes to a topic, it has no guarantee of when the
  next message on that topic will arrive: a device that publishes its status
  infrequently might not publish again for hours. A new subscriber could wait
  indefinitely before learning the current state of the system.

  _Retained messages_ solve this problem. A retained message is an ordinary
  PUBLISH message with the retain flag set to true. The broker stores the last
  retained message for each topic. When any client subsequently subscribes to
  that topic---whether using an exact match or a wildcard---the broker immediately
  delivers the retained message, giving the new subscriber an instantaneous view
  of the topic's last known state. Only one retained message is kept per topic
  at any time; publishing a new retained message replaces the previous one.
  Publishing a retained message with an empty payload deletes the stored
  retained message for that topic.

  Retained messages are particularly useful for device status topics. Consider a
  device that publishes `ON` to `home/devices/device1/status` when it starts.
  With retention enabled, any subscriber that connects later immediately learns
  the device is on, without waiting for the next status update.

  === Last Will and Testament

  Retained messages handle the happy-path scenario: a device that publishes its
  status cleanly. But what happens when a device crashes without publishing a
  final status update? The broker cannot distinguish between a device that is
  alive and silent and one that has failed ungracefully.

  The _Last Will and Testament_ (LWT) mechanism addresses this. At connection
  time, a client can register a "last will" with the broker: a normal MQTT
  message with a topic, QoS level, retain flag, and payload. The broker stores
  this message and delivers it to all subscribers of the specified topic if and
  when the client disconnects abruptly---due to a network I/O error, a KeepAlive
  timeout, or a connection closure without a proper DISCONNECT packet. If the
  client disconnects gracefully by sending DISCONNECT, the stored last will is
  discarded.

  The canonical use case combines LWT with retained messages. A device publishes
  `ON` as a retained message to its status topic on startup, and registers a
  retained `OFF` message as its last will on the same topic. If the device
  crashes, the broker publishes the retained `OFF` last will, and any current or
  future subscriber immediately learns that the device is offline. This pattern
  provides automatic fault visibility without any polling or timeout logic in
  the application layer.

  == Packet Format

  MQTT control packets share a common binary format that reflects the protocol's
  emphasis on compactness. Every packet begins with a two-byte fixed header. The
  first byte encodes the control packet type in the upper four bits (with values
  ranging from 1 for CONNECT to 14 for DISCONNECT) and packet-type-specific
  flags in the lower four bits. For PUBLISH packets, these flags encode the DUP
  flag indicating a retransmission, the two-bit QoS level, and the retain flag.
  For most other packet types, the lower four bits are reserved and must be set
  to defined values. The second byte (and potentially additional bytes, using a
  variable-length encoding with the most significant bit as a continuation flag)
  encodes the remaining length of the packet.

  Following the fixed header, a variable header carries packet-type-specific
  information including the packet identifier for QoS 1 and 2 messages, the
  topic name for PUBLISH packets, and protocol-level fields for CONNECT packets.
  The payload carries the actual message content; its presence and meaning
  depend on the packet type. CONNECT payloads include the client identifier,
  optional will topic and message, and optional credentials. PUBLISH payloads
  carry application data in any format. Many packet types---PUBACK, PUBREC,
  PUBCOMP, PINGREQ, PINGRESP, DISCONNECT---carry no payload at all.

  This compact encoding results in dramatically smaller packets than HTTP: an
  MQTT PUBLISH message with a short payload and topic can fit in a handful of
  bytes, whereas an equivalent HTTP POST request carries tens to hundreds of
  bytes of headers before any payload.

  == MQTT in Practice: the Arduino Client Library

  The PubSubClient library for Arduino exemplifies how MQTT's client-side
  simplicity enables implementation on severely constrained hardware. The
  library implements only the core MQTT features---QoS levels 0 and 1 (not 2), no
  SSL/TLS, and a payload limit of 128 bytes---which is appropriate for
  microcontroller-class devices where RAM and flash are measured in kilobytes.
  Its API exposes the essential operations: `connect()` with optional last will
  parameters, `disconnect()`, `publish()` with topic, payload, length, and
  retain flag, `subscribe()` and `unsubscribe()` with optional QoS, and `loop()`
  which must be called regularly to send KeepAlive messages and invoke the
  message callback. The callback function, registered at construction time, is
  invoked by `loop()` whenever a message arrives for a subscribed topic,
  allowing asynchronous, event-driven programming without threads.

  Broker implementations vary in capability and deployment model. Mosquitto is a
  widely used open-source broker compliant with MQTT 3.1 and 3.1.1, suitable for
  embedded deployments. Mosca is a Node.js-based broker supporting the same
  versions. HiveMQ is an enterprise broker with additional management and
  scalability features. All three support the full QoS spectrum and persistent
  sessions.

  == MQTT versus CoAP: Two Philosophies for Constrained Networking

  MQTT is not the only application-layer protocol designed for IoT. The
  _Constrained Application Protocol_ (CoAP), standardized in RFC 7252, embodies
  a different set of design choices that make it complementary rather than
  competitive in many scenarios.

  Where MQTT adopts a publish/subscribe model with a centralized broker, CoAP
  adopts a client/server REST model in which sensors and actuators act as
  servers, exposing their data as resources accessible via URLs, and
  applications act as clients issuing GET, PUT, POST, and DELETE requests. This
  makes CoAP conceptually similar to HTTP but adapted for constrained
  environments in several important ways. CoAP builds on UDP rather than TCP,
  which dramatically reduces connection overhead and is more appropriate for
  networks with high packet error rates and low throughput---such as IPv6 over
  Low-Power Wireless Personal Area Networks (6LoWPANs). CoAP headers are compact
  binary encodings, unlike HTTP's verbose text headers. CoAP includes a resource
  discovery mechanism through a resource directory. And CoAP embeds strong
  security using Datagram TLS (DTLS), offering security equivalent to 3072-bit
  RSA without the overhead of a full TLS session on top of TCP.

  The structural differences between the two protocols align with different
  deployment scenarios. MQTT's publish/subscribe model provides complete
  producer-consumer decoupling, which is architecturally elegant for large-scale
  telemetry where many sensors publish data and many consumers subscribe to it,
  without any consumer needing to know where the sensors are. Its broker,
  however, is a single point of failure and a potential scalability bottleneck;
  as the network scales, the broker's capacity to handle subscriptions and route
  messages may become the limiting factor. MQTT's dependence on TCP also imposes
  costs in connection establishment time and state maintenance that may be
  prohibitive for devices that spend most of their time sleeping.

  CoAP's 1:1 client-server model is better suited to command-and-control
  applications---where a specific actuator must respond to a specific request---than
  to broadcast telemetry. Its native UDP support makes it more energy-efficient
  for devices that wake briefly to respond to a query and then sleep again. CoAP
  also supports multicast, enabling one-to-many communication without a broker.
  Its relative immaturity compared to MQTT means that tooling and deployment
  experience are less developed, and its message reliability mechanisms, while
  functional, are not as sophisticated as MQTT's three-level QoS system.

  The practical choice between MQTT and CoAP depends on deployment topology,
  device capability, and communication pattern. Highly constrained devices in
  ad-hoc or mesh topologies without reliable infrastructure lean toward CoAP.
  Large-scale telemetry deployments with cloud backends and intermittently
  connected subscribers lean toward MQTT. In heterogeneous deployments, protocol
  gateways that translate between the two protocols can bridge segments of the
  network that use different protocols, at the cost of additional integration
  complexity.

  == Open Issues and the Limits of Lightweight Protocols

  The adaptations that make MQTT suitable for constrained IoT deployments also
  introduce vulnerabilities and limitations that deserve acknowledgement. The
  most significant is security. MQTT's transport-layer security is optional and
  expensive; without it, credentials, topic names, and all message payloads are
  transmitted in plaintext. The broker, as the central routing point for all
  messages, is a high-value target whose compromise exposes the entire system.
  Content-based filtering, which requires the broker to inspect payloads, is
  incompatible with end-to-end encryption. Designing MQTT deployments that are
  both functional and secure requires careful attention to which capabilities
  can be enabled on which devices.

  The broker as single point of failure is a structural limitation that becomes
  acute in safety-critical or high-availability applications. Broker clustering
  and replication mitigate but do not eliminate this risk. For applications that
  require genuine decentralization---peer-to-peer IoT communication without
  infrastructure---neither MQTT nor CoAP in its standard form is sufficient, and
  more radical architectural departures are necessary.

  Finally, the lightweight nature of MQTT means that semantic
  interoperability---agreement on what topic `home/livingroom/temperature`
  actually means, in what units, with what precision, at what sampling rate---is
  entirely outside the protocol. Two deployments from different vendors may use
  identically structured topic hierarchies while being semantically
  incompatible. Addressing this gap is the domain of higher-level standards and
  platform-level semantic frameworks, which remain an active area of development
  in the IoT ecosystem.

]
