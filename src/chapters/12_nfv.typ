#import "@preview/bookly:3.1.0": *

#let abs = [
  Traditional telecommunications networks are built by assembling proprietary
  physical appliances---firewalls, load balancers, intrusion detection systems,
  media gateways---into rigid, function-specific chains that are expensive to
  deploy, slow to evolve, and difficult to scale. Network Function
  Virtualization (NFV) proposes a fundamental architectural shift: decoupling
  network functions from the dedicated hardware on which they have historically
  run and reimplementing them as software that executes on standard virtualized
  infrastructure. This chapter examines the motivations for this transition, the
  conceptual and architectural framework that NFV introduces, and the
  engineering challenges that arise from virtualization. Beginning with the
  economic and operational pressures that drove major operators to initiate NFV
  standardization in 2012, the discussion proceeds through the concept of
  Virtualized Network Functions (VNFs) and their composition into network
  services via forwarding graphs, the three-tier NFV architectural framework of
  infrastructure, functions, and management and orchestration, and the specific
  challenges of VNF placement across heterogeneous physical substrates. The
  recurring tension throughout is between _flexibility_ and _performance_:
  software running on general-purpose hardware can be deployed, moved, and
  scaled dynamically, but it may not match the throughput, latency, or energy
  efficiency of purpose-built dedicated appliances, and closing this gap drives
  much of the ongoing research and engineering in the field.
]

#chapter(
  title: "Network Function Virtualization",
  abstract: abs,
  toc: true,
)[

  == The Problem with Traditional Network Architectures

  To understand why Network Function Virtualization emerged as a major industry
  initiative, it is useful to examine the architecture it seeks to replace. A
  large enterprise or carrier network is not simply a collection of routers and
  switches. A detailed study of one large enterprise network with over 80,000
  users across tens of sites found 636 middleboxes---network devices that
  perform functions beyond simple packet forwarding---alongside approximately
  900 routers. These middleboxes included 166 firewalls, 127 network intrusion
  detection systems (NIDS), 110 media gateways, 67 load balancers, 66 proxies,
  45 VPN gateways, 44 WAN optimizers, and 11 voice gateways. The middlebox count
  approached the router count; in terms of diversity and management complexity,
  the middleboxes arguably dominated.

  Each category of middlebox represents a distinct hardware appliance from a
  specialized vendor, running proprietary software on proprietary hardware, with
  its own management interface and operational procedures. Deploying a new
  service requires identifying which functions are needed, procuring the
  corresponding hardware, physically installing it, cabling it into the network,
  and configuring both the devices and the network topology to enforce the
  correct ordering of functions---because the _service chain_ (the sequence in
  which a packet must be processed by successive functions) must be reflected in
  the physical network topology. A firewall-then-load-balancer chain, for
  example, requires that all traffic physically traverse the firewall appliance
  before reaching the load balancer.

  This model exhibits several deeply problematic properties for modern network
  operators. _Product cycles_ are long: specifying, procuring, testing, and
  deploying a new hardware appliance can take months or years. _Service agility_
  is extremely low: responding to changing traffic conditions, security threats,
  or customer requirements requires physical hardware changes. _Hardware
  dependence_ is total: each function is inseparable from its dedicated
  hardware, which cannot be repurposed when load shifts. The cost structure is
  correspondingly unfavorable: capital expenditure (CAPEX) for hardware
  procurement and operational expenditure (OPEX) for power, cooling,
  maintenance, and staff grow with each new service, while revenues may not grow
  proportionally.

  Users and operators increasingly demand diverse, short-lived
  services---temporary security overlays for major events, rapidly deployed
  enterprise VPNs, on-demand video transcoding for live streaming---that are
  incompatible with the slow provisioning cycles of hardware-based deployment.
  The question that major operators began asking around 2010 was not whether to
  change this model but how: could the software-defined, virtualization-based
  approach that had transformed data center computing be applied to networking?

  == The NFV Concept

  === Decoupling Functions from Hardware

  Network Function Virtualization, launched as a formal initiative in 2012 by
  major telecommunications operators including AT&T, Telefónica, and Verizon
  under the auspices of the European Telecommunications Standards Institute
  (ETSI), proposes a single core idea: implement network functions as software
  rather than as dedicated hardware appliances, and run that software on
  standard virtualized infrastructure---virtual machines (VMs) or containers on
  commodity servers.

  A _Virtualized Network Function_ (VNF) is a software implementation of a
  network function that was previously carried out by dedicated hardware. A VNF
  firewall, for example, performs the same packet inspection and filtering as a
  hardware firewall, but executes as a software process on a general-purpose
  server, separated from the hardware by a virtualization layer. The VNF can be
  instantiated, configured, moved, scaled, or terminated through software
  control, without any physical intervention.

  The separation between function and hardware is the source of all of NFV's
  benefits. A VNF can be deployed on any compatible server in the
  infrastructure, regardless of its physical location; moved if the load
  distribution changes; scaled up by launching additional instances; scaled down
  by terminating instances; and replaced by a new version without hardware
  procurement. The velocity of change shifts from the timescales of hardware
  procurement (months) to those of software deployment (minutes).

  === Use Cases

  The scope of NFV is broad. In the data plane, VNFs encompass traffic analysis
  functions (deep packet inspection, quality of experience measurement),
  application-level optimization (caching servers, load balancers, application
  accelerators), and security functions (firewalls, virus scanners, intrusion
  detection systems, spam protection, IPsec and SSL VPN gateways). In mobile
  networks, the core network functions of an LTE or 5G system---the Home
  Subscriber Server (HSS), Mobility Management Entity (MME), Serving Gateway
  (SGW), Packet Data Network Gateway (PGW), and eNodeB baseband processing---are
  all candidates for virtualization, collectively enabling the concept of a
  _Cloud RAN_ (C-RAN) in which baseband processing is centralized on shared
  infrastructure rather than co-located with each antenna. Control and
  management functions such as authentication, authorization, and accounting
  (AAA) servers, policy control systems, and charging platforms are also within
  scope.

  == From Functions to Network Services

  === Service Chaining

  A single network function in isolation is rarely sufficient to constitute a
  useful service. Real services require multiple functions applied in sequence,
  with different traffic classes potentially following different paths through
  the function chain. A residential broadband service might require traffic to
  pass through a carrier-grade NAT, then a firewall, then a traffic shaper. An
  enterprise VPN service might add IPsec gateway processing and deep packet
  inspection. A video delivery service might route traffic through a transcoder
  and a content cache. The _service chain_---the ordered sequence of functions
  through which traffic must pass---is therefore the natural unit of service
  description.

  In a traditional network, service chains are encoded in the physical network
  topology: routers and switches are configured to forward traffic along paths
  that happen to traverse the required appliances in the required order.
  Changing the service chain requires reconfiguring the network. NFV decouples
  the logical service chain from its physical realization: the chain is defined
  abstractly, as a sequence of function types, and the infrastructure is
  responsible for ensuring that traffic flows through the appropriate VNF
  instances regardless of where those instances happen to be running.

  === Network Function Forwarding Graphs

  The formal NFV concept for service chain description is the _Network Function
  Forwarding Graph_ (NF-FG). An end-to-end network service is represented as a
  directed graph in which nodes are either VNFs or endpoint terminals
  (representing the source or destination of traffic), and edges represent
  logical links through which traffic flows from one function to the next. A
  simple service might involve a single path from endpoint A through VNF1 and
  VNF2 to endpoint B; a more complex service might involve branching paths where
  different traffic classes are directed to different function sequences.

  The forwarding graph captures the logical definition of the service---_what_
  is to be done to traffic and in what order---completely independently of
  _where_ it is done. The logical links in the graph are realized by physical
  paths through one or more infrastructure networks; a single logical link might
  traverse multiple physical switches and routers. This separation of logical
  service definition from physical realization is the NFV counterpart of the
  separation of concerns that software engineering has long advocated for
  application design: the service specification is expressed at a level of
  abstraction that is independent of hardware details, and the mapping to
  physical resources is handled by the management and orchestration layer.

  Forwarding graphs can be nested: a VNF-FG may contain a sub-graph (a nested
  VNF-FG) that itself consists of multiple VNFs. This composability allows
  complex services to be built from simpler, reusable components. All VNFs in
  the graph ultimately run on physical servers at _Points of Presence_
  (PoPs)---physical locations in the network where NFV infrastructure resources
  are deployed.

  == NFV Architectural Framework

  The ETSI NFV architectural framework organizes the NFV system into three main
  components: the NFV Infrastructure (NFVI), the collection of VNFs, and the NFV
  Management and Orchestration (NFV-MANO) system. Understanding the role and
  responsibilities of each component is essential for understanding how a
  network service is deployed and operated.

  === NFV Infrastructure

  The _NFV Infrastructure_ (NFVI) comprises all hardware and software components
  that constitute the environment in which VNFs are deployed, managed, and
  executed. The NFVI virtualizes physical computing, storage, and networking
  resources and presents them as pools from which VNF instances can draw.

  The NFVI is organized into three logical domains. The _compute domain_
  provides commercial off-the-shelf (COTS) high-volume servers and storage---the
  standard rack-mount servers and storage arrays found in modern data centers,
  rather than proprietary telecommunications equipment. The _hypervisor domain_
  mediates between physical resources and virtual machines through a
  virtualization layer; historically this meant hypervisors running VMs, but
  increasingly VNFs are deployed as containers (including the Cloud Native
  Function pattern), which share the host operating system kernel and offer
  faster startup times and lower overhead than full VMs at the cost of somewhat
  weaker isolation. The _infrastructure network domain_ comprises generic
  high-volume switches interconnected to provide network connectivity within and
  between NFVI-PoPs.

  NFVI resources may be distributed across multiple physical locations. An
  _NFVI-PoP_ (Point of Presence) is a physical location where NFV infrastructure
  resources are deployed. Two types of network interconnect PoPs: the _PoP
  network_ connects compute and storage resources within a single PoP, and the
  _transport network_ interconnects different PoPs, enabling VNFs at different
  physical locations to communicate as required by a service's forwarding graph.

  Within a PoP, VMs and containers are connected through _virtual switches_
  (vSwitches)---software programs that emulate Layer 2 network devices,
  providing connectivity between virtual network interfaces on co-located VMs
  and between those VMs and physical network interfaces. The Open vSwitch (OVS)
  is the most widely deployed example; it is a software-defined networking
  virtual switch that supports the OpenFlow protocol and can interoperate with
  physical switches using standard Layer 2 features. The vSwitch is a critical
  component because it determines the network performance that VNFs experience:
  poorly implemented virtual switching can introduce significant latency and
  throughput limitations relative to hardware switching.

  === VNFs and Their Descriptors

  Each VNF is described by a _VNF Descriptor_ (VNFD), a structured document that
  specifies the VNF's deployment and operational requirements: the virtual
  machine image or container image to use, the computing resources required
  (CPU, memory, storage), the virtual network interfaces and their connectivity
  requirements, configuration parameters, and lifecycle event handlers (scripts
  to execute at instantiation, scaling, or termination). Similarly, a complete
  network service is described by a _Network Service Descriptor_ (NSD), which
  specifies the VNFs composing the service, the virtual links connecting them,
  and the dependency relationships among VNFs (for example, a client VNF that
  requires the IP address of a server VNF before it can be configured).

  === NFV Management and Orchestration

  The _NFV Management and Orchestration_ (NFV-MANO) framework encompasses all
  the management and orchestration functions required to provision, configure,
  monitor, and terminate VNFs and the network services they compose. MANO is
  organized into three functional layers, each with a distinct scope of
  responsibility.

  The _NFV Orchestrator_ (NFVO) is the top-level component, responsible for
  lifecycle management of network services as a whole. It receives service
  requests, interprets NSDs, coordinates the instantiation of the required VNFs,
  manages the overall resource allocation across the infrastructure, and ensures
  that the VNF forwarding graph is correctly implemented. Open-source
  implementations include OSM MANO (developed by ETSI) and ONAP (Open Network
  Automation Platform).

  The _VNF Manager_ (VNFM) oversees the lifecycle management of individual VNF
  instances. For each VNF, the VNFM handles instantiation (launching the VM or
  container and applying initial configuration), scaling (adding or removing
  instances in response to load changes), healing (detecting and recovering from
  failures), monitoring (collecting performance metrics), and termination.
  Multiple VNFMs may exist in a MANO deployment, each managing a subset of VNFs.

  The _Virtualized Infrastructure Manager_ (VIM) controls and manages the
  physical and virtual infrastructure resources within a single operator domain:
  compute, storage, and network resources at one or more NFVI-PoPs. The VIM is
  responsible for allocating virtual resources (launching VMs, provisioning
  virtual storage, configuring virtual network interfaces) in response to
  requests from the VNFM and NFVO. Infrastructure-as-a-Service (IaaS) cloud
  platforms such as OpenStack are commonly deployed as VIMs; they provide the
  resource management APIs through which the MANO layer creates and destroys
  virtual resources.

  The MANO framework also maintains several _repositories_: a VNF catalog
  (database of all available VNFDs), a network services catalog (database of all
  available NSDs and the services they define), an NFVI resources inventory
  (current allocation of physical and virtual resources), and an NFV instances
  repository (current running VNF and network service instances with their
  configurations and state).

  == VNF Placement: A Central Engineering Challenge

  === The Placement Problem

  Deciding where to deploy each VNF in a network service---the _VNF placement_
  or _VNF chain placement_ problem---is one of the most important and
  technically difficult problems in NFV. Given a network service described as an
  ordered chain of VNFs, and a physical infrastructure consisting of servers
  with computing capacity and links with bandwidth, the placement problem asks:
  which server should host each VNF instance, and which physical paths should
  carry the traffic between consecutive VNFs?

  The placement decision has multiple, often conflicting optimization
  objectives. Minimizing end-to-end latency for the service requires placing
  VNFs close to each other and close to the traffic sources and destinations,
  but this may conflict with minimizing deployment cost (which favors
  concentrating VNFs at a small number of locations for better resource sharing)
  or maximizing energy efficiency (which favors turning off underutilized
  servers). The available decisions are constrained by server computing capacity
  (each server can host only as many VNF instances as its CPU, memory, and
  storage allow), link bandwidth (the traffic flowing between consecutive VNFs
  must fit within the capacity of the physical paths between their hosting
  servers), and QoS requirements (maximum acceptable end-to-end latency, minimum
  acceptable bandwidth).

  In 5G networks, VNF placement is closely related to _network slicing_: the
  creation of multiple virtual networks (slices) on a shared physical
  infrastructure, each with its own chain of VNFs configured to meet the
  requirements of a specific service class (enhanced mobile broadband,
  ultra-reliable low-latency communication, or massive machine-type
  communication). Each slice requires a tailored VNF chain, and the placement of
  these chains across the infrastructure must respect the isolation requirements
  between slices while optimizing resource utilization.

  === Solving the Placement Problem

  The VNF placement problem is NP-hard in the general case, reducible to a
  variant of the bin-packing problem. Practical approaches fall into several
  categories. _Exact methods_ based on Integer Linear Programming (ILP) or
  Mixed-Integer Linear Programming (MILP) formulate the placement as an
  optimization problem and solve it to global optimality, but their
  computational complexity makes them tractable only for small instances.
  _Heuristics_ apply domain-specific rules to construct good solutions quickly
  without optimality guarantees. _Metaheuristics_ such as genetic algorithms
  explore the solution space stochastically, often finding near-optimal
  solutions for medium-scale instances. _Deep Reinforcement Learning_ approaches
  train agents to make placement decisions through interaction with a simulated
  or real environment, potentially capturing complex patterns that explicit
  optimization formulations miss.

  The heterogeneity of available computational substrates adds an additional
  dimension to the placement problem. Network functions can be placed on
  conventional servers (flexible but with latency in the 1-10 µs per packet
  range), programmable network switches (very high throughput and latency around
  1-2 µs per packet, but limited in the complexity of operations they can
  perform), or SmartNICs---network interface cards with programmable processing
  capabilities offering intermediate performance and flexibility in the 10-100
  µs range. Deciding not only which server hosts which VNF but also which type
  of computational substrate to use for each function is an active area of
  research.

  == Challenges and Limitations

  NFV's benefits are real and substantial, but they come with significant
  challenges. _Performance_ is the most immediate concern: a firewall
  implemented in software on a general-purpose server may achieve lower
  throughput and higher per-packet latency than a purpose-built hardware
  appliance, particularly for high-speed data plane functions. Closing this
  performance gap requires careful co-design of VNF software (to exploit
  hardware offload features and minimize memory copies), hypervisor or container
  configuration (to reduce virtualization overhead), and network fabric design
  (to minimize virtual switching latency).

  _Reliability_ in a virtualized environment differs from reliability in a
  hardware environment. Hardware appliances fail rarely and predictably;
  software VNFs can fail due to software bugs, configuration errors, resource
  exhaustion, or underlying hardware failure. The MANO framework provides
  automated failure detection and healing (restarting failed VNF instances), but
  the recovery time and the complexity of maintaining state consistency across
  failover events are non-trivial engineering problems.

  _Security_ is more complex in a virtualized environment because multiple VNF
  instances from different operators or services may share the same physical
  server, creating potential for side-channel attacks and requiring careful
  isolation through the hypervisor or container runtime. The NFV management
  plane itself---the interfaces between NFVO, VNFM, VIM, and VNFs---is a
  significant attack surface that must be secured.

  Finally, _management complexity_ does not disappear with NFV; it transforms.
  The physical complexity of cabling and device management is replaced by the
  logical complexity of orchestrating hundreds or thousands of VNF instances
  across a distributed infrastructure, managing their lifecycle, monitoring
  their performance, and debugging failures that can originate at any layer of
  the software stack from the application to the hypervisor to the physical
  hardware.

]
