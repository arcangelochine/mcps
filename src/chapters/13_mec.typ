#import "@preview/bookly:3.1.0": *

#let abs = [
  Multi-Access Edge Computing (MEC) extends the cloud computing paradigm to the
  periphery of the network, placing computational resources in close physical
  and topological proximity to end users and their devices. This chapter
  examines why this proximity matters---quantifying its effect on TCP throughput
  through the Mathis equation and on observed latency through empirical
  measurements---and surveys the ETSI MEC standard that provides the dominant
  architectural framework for realizing edge computing in access-agnostic
  deployments. The MEC host, platform, and application architecture is
  described, followed by a survey of the standardized service APIs through which
  MEC applications access radio, location, and connectivity information from the
  underlying network. Particular attention is given to the Multi-Access Traffic
  Steering API, which allows applications to exploit multiple heterogeneous
  wireless links simultaneously for improved throughput, reliability, or cost
  efficiency. The chapter closes with a worked exercise applying MTS API
  concepts to a multi-technology indoor environment with heterogeneous
  application requirements. The recurring tension is between the classical cloud
  model's economies of scale through centralization and the edge model's
  performance advantages through distribution: the edge reduces latency and
  enables local data processing, but at the cost of managing a distributed,
  heterogeneous infrastructure that is harder to operate and scale than a
  centralized data center.
]

#chapter(
  title: "Multi-Access Edge Computing",
  abstract: abs,
  toc: true,
)[

  == From Cloud to Edge: Motivation

  Cloud computing achieved its dominance through consolidation: by concentrating
  computation, storage, and network resources in large, geographically
  centralized data centers, providers achieved economies of scale, simplified
  management, and high resource utilization. The model works well for
  applications that are tolerant of the round-trip time between the end user and
  a data center that may be hundreds or thousands of kilometers away. It works
  poorly for applications where that round-trip time---typically tens to
  hundreds of milliseconds---is the binding constraint on performance or user
  experience.

  Edge computing extends the cloud paradigm toward the network periphery. Rather
  than terminating user traffic at a central data center, edge computing deploys
  computational resources at or near the network's point of contact with the end
  user---at base stations, Wi-Fi access points, aggregation sites, or micro-data
  centers at central offices---so that user traffic is processed locally. The
  result is a better end-to-end performance environment characterized by lower
  latency and higher throughput on the path between user and computation.

  === The Mathis Equation and TCP Throughput

  The performance benefit of edge proximity is not merely intuitive; it is
  quantifiable through the Mathis equation, which characterizes the maximum
  achievable throughput of a TCP connection under realistic network conditions.
  For small packet loss rates (below approximately one percent), the maximum TCP
  throughput is bounded by:

  $ "Throughput" <= frac(C dot "MSS", "RTT" dot sqrt(p)) $

  where $C$ is a constant near 1, MSS is the maximum segment size in bytes, RTT
  is the round-trip time in seconds, and $p$ is the packet loss rate. Two
  observations follow directly. First, throughput scales inversely with RTT:
  halving the round-trip time doubles the achievable throughput, all else being
  equal. Placing computation at the network edge, reducing RTT from 100 ms (a
  typical cloud round-trip) to 5 ms (a local edge deployment), can yield a
  twentyfold throughput increase before any improvement in bandwidth. Second,
  throughput scales inversely with the square root of the loss rate: reducing
  packet loss from $10^{-2}$ to $10^{-3}$ yields roughly a threefold throughput
  improvement. This motivates not only proximity but also quality of service
  mechanisms at the edge---traffic flow processing that reduces packet loss
  improves TCP performance multiplicatively.

  Empirical measurements reinforce the theoretical picture. Observations of
  latency and upload bandwidth over a one-week period between three homes within
  a one-square-mile area served by two different ISPs revealed that end-to-end
  latency does not correlate with geographical distance. Homes served by
  different ISPs experienced substantially higher latency and lower bandwidth
  than homes served by the same ISP, despite physical proximity. This
  demonstrates that the relevant distance for performance is topological---the
  path through the network---not geographical, and that edge deployments within
  a single carrier's infrastructure can circumvent the inter-ISP performance
  degradation that affects traffic transiting network boundaries.

  == The ETSI MEC Standard

  Multi-Access Edge Computing is standardized by ETSI's Industry Specification
  Group for MEC, which serves as the leading international standard in this
  area. The ETSI definition captures the essential value proposition: MEC offers
  application developers and content providers cloud-computing capabilities and
  an IT service environment at the edge of the network. Two terms in this
  definition deserve unpacking.

  "Multi-access" signals that MEC is designed to be access-technology agnostic:
  the standard applies in principle to 4G, 5G, Wi-Fi, and fixed access networks
  without modification. The MEC platform abstracts over the specific radio
  access technology, presenting a uniform interface to application developers
  regardless of whether their users connect over LTE, 5G NR, or 802.11ax. This
  agnosticism is essential for deployments that serve users across heterogeneous
  access technologies simultaneously.

  "Edge of the network" is deliberately left loosely defined in the standard.
  Rather than mandating a specific topological position, ETSI MEC accommodates a
  range of deployment options suited to different requirements: base stations
  and access points at the radio edge, micro-data centers at central office or
  aggregation sites, larger edge data centers at carrier hotels, and computation
  co-located with customer premises equipment. The appropriate deployment point
  depends on the trade-off between latency (which favors deployment closer to
  the radio), cost (which favors sharing resources across more users, hence
  deployment further from the radio), and the specific application's
  requirements.

  The practical "core business" of the ETSI MEC standard is the definition of
  APIs---the interfaces through which MEC applications access network
  information and services. Standards for physical infrastructure are
  necessarily dependent on vendor implementation choices, but API
  standardization ensures that an application written to the ETSI MEC APIs can
  run on any MEC platform from any compliant vendor without modification.

  == MEC System Architecture

  === Components

  A MEC system consists of MEC hosts and the management infrastructure required
  to operate MEC applications within an operator network.

  A _MEC host_ is the physical server that hosts both the MEC platform and the
  MEC applications. It includes a _virtualization infrastructure_ that provides
  compute, storage, and network resources---the hardware and hypervisor or
  container runtime that forms the execution environment---and a _MEC platform_
  that sits above the virtualization layer and provides the essential
  functionality required to run MEC applications. The MEC platform is the
  middleware layer that implements the MEC service APIs, routes traffic between
  applications and the access network, and enforces policies. MEC applications
  themselves run as VMs or containers on the virtualization infrastructure,
  interacting with the MEC platform to consume services (such as location
  information or radio network conditions) and potentially to offer services to
  other applications.

  _MEC management_ operates at two levels. Host-level management handles the
  lifecycle of MEC applications on a specific MEC host---instantiation,
  configuration, scaling, and termination. System-level management (the MEC
  orchestrator) coordinates across multiple MEC hosts, handling decisions such
  as where to deploy a new application instance and how to migrate applications
  when users move.

  External entities---user equipment, third-party application servers, and other
  network elements---interact with the MEC system through defined interfaces.
  Notably, the device side is not restricted to cellular UEs: the architecture
  explicitly accommodates terminals connected via Wi-Fi or fixed access,
  consistent with the multi-access philosophy.

  === Use Cases

  MEC use cases fall into three broad categories. _Consumer-oriented services_
  include cognitive assistance (running real-time inference on sensor data from
  a user's device), augmented reality (processing camera frames and overlaying
  information with sub-10 ms latency), cloud gaming (executing game physics
  locally rather than in a distant data center), and computation offloading from
  devices with limited processing capability. _Operator and third-party
  services_ include active device location tracking, video analytics service
  chaining, connected vehicle coordination, and security functions. _Network
  performance and QoE improvement_ encompasses DNS and content caching, TCP
  performance optimization, and video throughput acceleration.

  The video analytics use case illustrates the edge's unique advantages
  concisely. A city-wide vehicle license plate recognition system based on
  camera feeds would, in a pure cloud architecture, require transmitting
  continuous high-definition video streams from hundreds of cameras to a central
  data center---enormous bandwidth, high latency, and significant privacy
  implications. With MEC, video analytics runs on a MEC host co-located with or
  near the cameras. Only the extracted results---license plate strings and
  timestamps---are transmitted to the application server. Bandwidth consumption
  decreases by orders of magnitude, latency falls from hundreds of milliseconds
  to tens, and the raw video frames never traverse the core network, reducing
  both cost and privacy exposure.

  == MEC Service APIs

  The ETSI MEC standard defines a set of APIs that allow MEC applications to
  access network and user information from the local node. These APIs are the
  primary differentiator between a generic cloud deployment and a MEC
  deployment: a cloud application running on a distant server cannot access
  real-time radio conditions or precise UE location without MEC's proximity and
  network integration. The full and current list is maintained at the ETSI MEC
  forge; the most important APIs are described here.

  === Radio Network Information API

  The Radio Network Information API (RNIS) exposes real-time radio and network
  conditions to MEC applications. Available information includes current cell
  identifiers and signal strength measurements, measurement information related
  to the user plane based on 3GPP specifications, context information about UEs
  currently connected to the radio node(s) associated with the MEC host, and the
  radio access bearers those UEs are using. This information, updated in
  near-real time, enables applications to make decisions that respond to actual
  channel conditions rather than assuming a static or average channel quality.

  A video streaming application, for example, can use RNIS to query the current
  downlink channel quality for a specific UE and adapt the video encoding
  bitrate accordingly---reducing quality when channel conditions deteriorate to
  prevent buffering, and increasing quality when conditions improve. Without
  RNIS, the application would rely on end-to-end feedback (TCP congestion
  signals or DASH adaptive bitrate algorithms) that are slower to respond and
  less precise. The MEC platform itself can also use RNIS to optimize mobility
  procedures---anticipating handovers and pre-migrating application state before
  the radio link switches---supporting service continuity during handover.

  === Location API

  The Location API provides location information about UEs served by the radio
  nodes associated with the MEC host. Queries can request the current location
  of a specific UE, a list of all UEs in a specified geographic area,
  notifications when UEs enter or leave a defined area, and the locations of the
  radio nodes themselves. Location can be expressed as geolocation (geographic
  coordinates, potentially with accuracy bounds) or as logical location (cell ID
  or sector identifier), the latter being immediately available from radio
  network information without requiring GPS or triangulation.

  The distinction between geolocation and logical location reflects a practical
  trade-off: logical location is available instantaneously and with certainty
  from the network's own radio management data, while geolocation requires
  either device-reported GPS coordinates (with associated privacy implications
  and battery cost) or network-side positioning calculations (with latency and
  accuracy trade-offs). For many MEC applications---particularly those that need
  to know which cell a device is in rather than its precise
  coordinates---logical location is sufficient and preferable.

  === Multi-Access Traffic Steering API

  The Multi-Access Traffic Steering (MTS) API addresses a fundamental limitation
  of single-link wireless communication: no single radio access technology can
  simultaneously maximize throughput, minimize latency, ensure reliability, and
  minimize cost. A 5G mmWave link offers very high throughput but is fragile in
  the face of obstacles and mobility; a Wi-Fi link offers high throughput at low
  cost in indoor environments but may have higher packet loss; an LTE link
  offers reliable wide-area coverage but at metered cost and with throughput
  limitations.

  When multiple wireless links are simultaneously available---as is increasingly
  common for devices that support both cellular and Wi-Fi---MTS allows a MEC
  application or the MEC platform to steer traffic across links based on
  application requirements. MTS operations include four modes. _Low-cost
  steering_ routes traffic over unmetered connections (typically Wi-Fi) whenever
  available, falling back to cellular only when Wi-Fi is absent. _Low-latency
  steering_ selects the link with the lowest current latency for delay-sensitive
  traffic. _High-throughput steering_ aggregates traffic across multiple links
  simultaneously using bandwidth bonding, or selects the highest-throughput
  available link. _Redundancy steering_ duplicates packets over multiple links
  simultaneously, so that the first copy to arrive at the receiver is used and
  loss on any single link does not cause application-layer packet loss.

  The redundancy mode deserves particular attention because it achieves
  reliability improvement that is qualitatively different from what any single
  link can provide. If two independent links each have a packet loss rate $p$,
  and packets are duplicated over both, the probability that a packet is lost on
  both links simultaneously is $p^2$---a quadratic reduction. For $p = 10^{-2}$,
  redundancy steering achieves an effective loss rate of $10^{-4}$, a
  hundredfold improvement. This comes at the cost of doubled bandwidth
  consumption and can coexist with other steering modes only if sufficient
  capacity is available on all links.

  === Other APIs

  The _UE Identity API_ allows applications to securely identify users without
  requiring the application to implement its own authentication infrastructure.
  The _Bandwidth Management API_ allows applications to request and reserve
  bandwidth on the access link, supporting QoS differentiation for traffic
  classes with different requirements. The _Service Discovery API_ allows
  applications to find other MEC services available in the platform. The
  _Mobility API_ supports application-level mobility management, allowing state
  to be migrated between MEC hosts as users move. The _App Lifecycle Management
  API_ provides interfaces for deploying, updating, and terminating MEC
  application instances.

  == Worked Example: MTS API in a Multi-Technology Environment

  To make the MTS API concepts concrete, consider an indoor deployment where
  both Wi-Fi and cellular connectivity are available, with the following
  measured characteristics.

  Wi-Fi offers a packet loss rate below $10^{-2}$, latency below 10 ms, a
  downlink data rate of 40 Mbps, and an uplink data rate of 20 Mbps. Cellular
  offers a packet loss rate below $10^{-3}$, latency below 5 ms, a downlink data
  rate of 20 Mbps, and an uplink data rate of 10 Mbps. Three applications with
  distinct requirements must be supported simultaneously.

  Application A requires a packet loss rate below $10^{-5}$, latency below 10
  ms, and 5 Mbps in each direction. Neither Wi-Fi ($10^{-2}$ loss) nor cellular
  ($10^{-3}$ loss) individually meets the loss requirement. However, using
  redundancy steering over both links simultaneously achieves an effective loss
  rate of $10^{-2} times 10^{-3} = 10^{-5}$, exactly meeting the requirement.
  Latency is determined by whichever copy arrives first, so the effective
  latency is $min(10, 5) = 5$ ms, comfortably within the 10 ms bound. The 5 Mbps
  throughput requirement is well within the capacity of either link. Application
  A is therefore supported using redundancy steering over both Wi-Fi and
  cellular.

  Application B requires a packet loss rate below $10^{-3}$, latency below 5 ms,
  and 5 Mbps in each direction. Cellular alone meets all three requirements:
  loss $10^{-3}$, latency below 5 ms, and throughput 20/10 Mbps. Wi-Fi meets the
  loss and throughput requirements but not the latency requirement. Application
  B is therefore served over cellular using low-latency steering.

  Application C requires a packet loss rate below $10^{-2}$, latency below 20
  ms, a downlink rate of 40 Mbps, and an uplink rate of 10 Mbps. Both links meet
  the loss and latency requirements individually. The downlink requirement of 40
  Mbps matches exactly the Wi-Fi downlink capacity; cellular alone offers only
  20 Mbps downlink, which is insufficient. Wi-Fi alone provides 40 Mbps downlink
  and 20 Mbps uplink---both sufficient. Application C can therefore be served
  over Wi-Fi alone using low-cost steering (preferring the unmetered link), or
  with high-throughput steering aggregating both links for additional downlink
  margin.

  This example illustrates that MTS API decisions are not made globally for all
  applications but per-application, based on each application's specific QoS
  requirements and the current measured capabilities of each available link.

  == Deployment and the Edge Ecosystem

  Major cloud and telecommunications vendors have developed MEC offerings that
  instantiate the ETSI architecture on commercial infrastructure. AWS Wavelength
  embeds AWS compute and storage services within telecommunications carriers'
  data centers, allowing applications deployed on Wavelength to serve end users
  with single-digit millisecond latency over 5G networks. Microsoft Azure
  Private MEC combines Azure compute with private 5G network capabilities. Nokia
  and Ericsson both offer private 5G solutions that integrate MEC hosts with
  their radio infrastructure, targeting enterprise deployments in factories,
  campuses, and ports.

  The ETSI MEC Sandbox (accessible at try-mec.etsi.org) provides an interactive
  environment for developers to experiment with MEC service APIs without
  requiring access to physical infrastructure---an important tool for the
  application developer community that ETSI MEC explicitly targets as one of its
  primary stakeholders.

  The relationship between MEC and NFV is close: the MEC host's virtualization
  infrastructure is an instance of NFV infrastructure (NFVI), and MEC
  applications are in effect a specialized class of VNF optimized for
  low-latency user-facing services rather than network function processing. The
  MEC orchestrator coordinates with the NFV MANO to deploy and manage
  application instances. MEC and NFV together form the software and
  virtualization substrate on which 5G's diverse service requirements---eMBB,
  URLLC, and mMTC---are realized in practice.

]
