#import "@preview/bookly:3.1.0": *

#let abs = [
  Battery-powered IoT devices face a fundamental constraint: finite energy
  reserves impose a finite operational lifetime, and extending that lifetime
  through low-power design reduces computational and communication capability.
  Energy harvesting offers an alternative by converting ambient energy---solar
  radiation, wind, vibration, thermal gradients, radio frequency fields---into
  electrical power, potentially enabling devices to operate indefinitely. This
  chapter examines the architectures and analytical frameworks that arise when
  IoT systems harvest energy from the environment. Beginning with the two
  canonical harvesting architectures---harvest-use and harvest-store-use---and
  their formal energy models, the discussion progresses through the properties
  of real energy sources and storage technologies, the concept of _energy
  neutrality_ as an operational objective distinct from lifetime maximization,
  and two progressively richer models for achieving it: Kansal's duty-cycle
  adaptation framework and a task-based generalization that models discrete
  implementation alternatives with distinct energy costs and utility values. The
  chapter closes with a dynamic programming scheduler that solves the resulting
  task assignment problem optimally within practical complexity bounds. The
  recurring tension is between _predictability and control_: energy harvesting
  sources are often uncontrollable, and the designer must match a variable,
  uncertain energy supply to a load that can be modulated but not reduced to
  zero.
]

#chapter(
  title: "Energy Harvesting IoT",
  abstract: abs,
  toc: true,
)[

  == Motivations: Beyond the Finite Battery

  The preceding chapters established that duty cycling is the principal
  mechanism by which battery-powered IoT devices extend their operational
  lifetime. Low-power processor modes, coordinated MAC sleep schedules, and
  careful subsystem management can reduce per-cycle energy expenditure by one or
  two orders of magnitude relative to always-on operation. These savings are
  real and significant, but they do not change the fundamental character of the
  problem: the battery is a finite reservoir, and every cycle of operation draws
  it closer to exhaustion.

  The consequences of this finiteness are multifaceted. A device with a small
  battery may be lightweight and inexpensive, but it requires frequent battery
  replacement---a cost that, multiplied over thousands of deployed sensors, can
  dominate the total cost of ownership of an IoT deployment. Large batteries
  reduce replacement frequency but increase size, weight, and per-unit cost.
  Low-power design extends lifetime but at the cost of reduced computational
  capability, shorter radio range, and lower communication throughput. These
  trade-offs are unavoidable within the paradigm of battery-only operation.

  _Energy harvesting_ offers a qualitatively different approach: extracting
  energy from the device's physical environment and using it to supplement or
  replace battery power. If the harvested energy is large enough and available
  continuously or periodically, a device can operate indefinitely without
  battery replacement. If the harvesting source is predictable, the device can
  adapt its behavior to the expected energy availability, achieving higher
  performance during periods of abundance and conserving energy during scarcity.
  The potential benefits are substantial, but so are the engineering challenges:
  harvested energy is typically variable, intermittent, and outside the
  designer's direct control.

  == Harvesting Architectures

  === Harvest-Use

  The simplest harvesting architecture connects the energy harvester directly to
  the device load, with no energy storage. The device operates whenever the
  instantaneous harvested power $P_s (t)$ meets or exceeds the instantaneous
  load $P_c (t)$; it shuts off whenever the harvested power falls below the
  minimum operating threshold. Examples of this architecture include passive
  RFID tags, which derive all their power from the electromagnetic field emitted
  by a reader, and some piezo-electric systems that generate power only during
  mechanical deformation.

  The energy dynamics of harvest-use systems are straightforward: there is no
  buffer to store surplus energy, so any excess production
  $P_s (t) - P_c (t) > 0$ is wasted. Conversely, any deficit $P_s (t) < P_c (t)$
  causes the device to switch off. The device's operational availability is
  therefore entirely determined by the temporal coincidence of harvested power
  and load---a coincidence that is not guaranteed in environments where the
  harvesting source is intermittent or fluctuating. Abrupt variations in source
  power can cause the device to oscillate rapidly between on and off states,
  which is particularly harmful for systems that require initialization time
  after each power-on.

  === Harvest-Store-Use

  The practical remedy for the limitations of harvest-use is an energy
  buffer---a rechargeable battery or supercapacitor---interposed between
  harvester and load. In the _harvest-store-use_ architecture, harvested energy
  is used immediately to power the device when available, and any surplus
  charges the buffer. When harvested power is insufficient, the buffer
  discharges to make up the deficit. A DC-to-DC converter regulates the voltage
  presented to the load, decoupling the load from the voltage variations of both
  the harvester output and the buffer charge state.

  This architecture eliminates the direct coupling between instantaneous
  harvested power and device operation, allowing the device to operate
  continuously as long as the buffer retains charge. With an ideal buffer---one
  with infinite capacity, no leakage, and a charging efficiency of
  $eta = 1$---the device can operate for any time interval $[0, T]$ as long as
  the cumulative energy consumed does not exceed the cumulative energy harvested
  plus the initial buffer charge:

  $
    integral_0^T P_c (t) d t <= integral_0^T P_s (t) d t + B_0 quad forall T in (0, infinity)
  $

  Real buffers, however, are characterized by three imperfections that must be
  incorporated into any serious analysis. First, they have a _finite capacity_
  $B_"max"$: energy cannot be stored beyond this limit, and surplus production
  beyond it is wasted. Second, they have a _charging efficiency_ $eta < 1$: only
  a fraction of the energy delivered to the buffer is actually stored; the
  remainder is dissipated as heat. Third, they exhibit _self-discharge_ or
  leakage: stored energy decreases over time even when the device draws no
  current, at a leakage power $P_"leak" (t)$.

  The energy conservation equation for a non-ideal buffer with initial charge
  $B_0$ and current charge $B_T$ at time $T$ is:

  $
    B_T = B_0 + eta integral_0^T (P_s (t) - P_c (t))^+ d t - integral_0^T (P_c (t) - P_s (t))^+ d t - integral_0^T P_"leak" (t) d t >= 0
  $

  where the notation $(x)^+ = max(x, 0)$ is the rectifier function that extracts
  only the positive part of its argument. The first integral represents energy
  harvested in excess of load and stored in the buffer (reduced by charging
  efficiency); the second represents energy drawn from the buffer when harvested
  power is insufficient; the third represents buffer leakage losses. The device
  can operate as long as $B_T >= 0$ for all $T$. The buffer capacity constraint
  adds the requirement that $B_T <= B_"max"$ for all $T$---any surplus that
  would exceed capacity is wasted---which is a sufficient but not necessary
  condition for energy conservation.

  == Energy Sources and Storage Technologies

  === Classification of Energy Sources

  Energy harvesting sources span an enormous range of physical phenomena. Solar
  cells convert photovoltaic energy, generating up to 15 mW/cm² under direct
  sunlight with approximately 15% conversion efficiency. Wind turbines and
  rotors convert kinetic energy of air movement, with production ranging from
  under a milliwatt for micro-scale turbines in gentle indoor air currents to
  kilowatts for larger installations. Piezo-electric materials (both flexible
  PVDF films and rigid PZT ceramics) generate electricity when mechanically
  deformed, making them suitable for harvesting energy from vibration, human
  motion, and pressure events such as button presses. Thermoelectric generators
  exploit temperature differentials to produce power through the Seebeck effect;
  human body heat can yield roughly 30 µW/cm² in typical indoor environments.
  Radio-frequency harvesters extract energy from ambient electromagnetic fields,
  with passive RFID tags representing the most widely deployed example---the
  antenna coil of a passive tag generates enough current from the reader's RF
  field to power the tag's circuitry and send a reply, all without any internal
  battery.

  Sources differ along two important dimensions that profoundly affect system
  design: _controllability_ and _predictability_. Fully controllable sources can
  produce energy on demand (a hand-cranked generator, a piezo push-button);
  partially controllable sources can be influenced but not fully determined by
  design (RF energy from a deliberately placed transmitter in a room, where
  actual per-tag power depends on propagation). Uncontrollable sources operate
  independently of designer intent. Among uncontrollable sources, a critical
  further distinction is predictability: solar energy is uncontrollable but
  highly predictable through astronomical models and weather forecasts, while
  vibration from seismic or industrial sources of unknown character may be both
  uncontrollable and unpredictable. This taxonomy directly determines what
  analytical and operational strategies are applicable.

  === Storage Technologies

  The most commonly used storage technologies for IoT energy harvesting are
  rechargeable batteries and supercapacitors. Among rechargeable batteries,
  Lithium-ion (Li-ion) chemistry offers the most attractive combination of
  properties for IoT: high energy density (165 Wh/kg), very low self-discharge
  (less than 10% per month), no memory effect, and high charging efficiency
  approaching 99.9%. Sealed Lead Acid (SLA) batteries offer lower energy density
  (26 Wh/kg) and higher self-discharge (20% per month) but can sustain more
  charge-discharge cycles at lower cost. NiMH batteries offer intermediate
  characteristics.

  Supercapacitors occupy a different point in the design space. Their energy
  density is far lower than batteries (approximately 5 Wh/kg), but they offer
  charging efficiencies of 97-98%, effectively infinite recharge cycles, and
  very low internal resistance that allows rapid charge and discharge.
  Self-discharge is significant (approximately 5.9% per day), making
  supercapacitors unsuitable for long-term energy storage but excellent as
  buffers for jittery or pulsed harvesting sources that produce short bursts of
  energy. In practice, many harvesting systems combine a supercapacitor as an
  immediate buffer (smoothing output fluctuations from the harvester) with a
  battery for longer-term storage.

  === Measuring Battery Charge

  All power management strategies in energy harvesting systems require accurate
  knowledge of the current battery charge. Battery charge is related to terminal
  voltage in a way that is approximately linear over the operational range for
  many chemistries, though the exact relationship depends on the battery
  technology and operating temperature. A device can estimate its battery charge
  by measuring the terminal voltage with an analog-to-digital converter (ADC)
  and applying a linear mapping.

  Specifically, if the battery's minimum charge $B_"min"$ corresponds to voltage
  $v_"min"$ and maximum charge $B_"max"$ corresponds to voltage $v_"max"$, and
  the ADC has $d$ bits of resolution, the ADC output values $x_"min"$ and
  $x_"max"$ corresponding to these voltages are:

  $ x_"max" = 2^d - 1 $
  $ x_"min" = ceil(v_"min" / v_"max" dot (2^d - 1)) $

  For a measured ADC output $x$, the estimated battery charge is:

  $ B = B_"min" + frac(B_"max" - B_"min", x_"max" - x_"min") dot (x - x_"min") $

  This estimation has finite quantization error determined by the ADC
  resolution. For a 10-bit ADC with a Raspberry Pi (voltage range 3.5-5 V and
  battery range 0-3000 mAh), successive charge levels differ by approximately
  2.9 mAh; for a Tmote Sky (voltage range 1.8-3 V, 12-bit ADC), the quantization
  step is approximately 0.7 mAh, providing finer resolution that benefits more
  granular scheduling algorithms.

  The energy production of the harvester can be estimated indirectly from
  consecutive battery charge measurements combined with knowledge of the load:

  $ E_e = integral_(t_1)^(t_2) (p_c (t))^+ d t + E_b (t_2) - E_b (t_1) $

  where $E_b (t)$ denotes the battery charge measured at time $t$ and $p_c (t)$
  is the known power consumption. This indirect method accumulates errors from
  both the ADC quantization and the uncertainty in $p_c (t)$; dedicated energy
  metering hardware provides more accurate results at the cost of additional
  circuit complexity.

  == Energy Neutrality

  The conventional objective in IoT energy management is to maximize device
  lifetime---to keep the device operational for as long as possible given a
  fixed energy reserve. Energy harvesting enables a qualitatively different
  objective: _energy neutrality_, the condition in which a device can maintain a
  desired performance level indefinitely. An energy-neutral device neither
  depletes its battery over time nor operates below its minimum useful
  performance level; it operates within the bounds set by the available
  harvested energy, adapting its performance to match energy availability.

  The distinction matters because maximizing lifetime and maximizing performance
  under energy neutrality lead to different system designs. A
  lifetime-maximizing design reduces energy consumption as far as possible,
  which may mean operating below any useful performance threshold. An
  energy-neutral design aims to maximize the performance that can be sustained
  indefinitely given the harvesting environment---a higher and more useful
  target. Consider a network of sensors monitoring a patient's location in an
  assisted-living home: the goal is not to keep the sensors alive as long as
  possible at minimal function, but to provide the highest sustained
  localization accuracy that the available solar or thermal energy can support.

  Energy neutrality in a system of multiple distributed devices introduces an
  additional dimension: performance depends not only on the energy available at
  each individual node but on how energy is distributed and used across the
  network to deliver collective functionality. A node that harvests abundant
  energy but uses it inefficiently may bottleneck network-wide performance just
  as much as a node with scarce harvesting.

  == Kansal's Framework for Energy-Neutral Operation

  === Conditions for Energy Neutrality

  Kansal's framework, developed for predictable but uncontrollable sources such
  as solar energy, addresses the question: given a harvesting environment
  characterized by statistical properties of energy production, what conditions
  must the load satisfy to guarantee energy neutrality?

  The framework models energy production $E_T = integral_0^T P_s (t) d t$ over
  any interval $[0, T]$ as satisfying a linear bounding constraint: there exist
  real numbers $rho_s$ (the long-run average production rate) and $sigma$ (a
  burstiness parameter) such that:

  $ rho_s dot T - sigma <= E_T <= rho_s dot T + sigma quad forall T $

  Similarly, the energy load $L_T = integral_0^T P_c (t) d t$ is modeled as
  satisfying:

  $ 0 <= L_T <= rho_c dot T + delta $

  for long-run average consumption rate $rho_c$ and burst parameter $delta$.

  Under these assumptions, Kansal's theorem states that a sufficient condition
  for energy neutrality is the simultaneous satisfaction of three inequalities.
  First, the effective production rate (after charging efficiency loss) must
  exceed the sum of load rate and leakage rate:
  $eta rho_s >= rho_c + rho_"leak"$. Second, the initial battery charge must be
  sufficient to handle the worst-case mismatch between production and
  consumption: $B_0 >= eta sigma + delta$. Third, the required initial charge
  must be admissible: $B_0 <= B_"max"$. These conditions are sufficient but not
  necessary: a system may achieve energy neutrality with a smaller battery if
  the actual production and load profiles are better matched than the worst-case
  bounds suggest.

  === Duty Cycle Adaptation and Utility

  Kansal's operational approach satisfies the load condition by dynamically
  adjusting the device's duty cycle. Reducing the duty cycle reduces power
  consumption approximately linearly, trading performance for energy savings.
  The framework captures the value of performance through a _utility function_
  $u("dc")$ that maps duty cycle to application-level utility.

  The utility function is piecewise linear: below a minimum duty cycle
  $"dc"_"min"$, the application is inoperative and utility is zero; between
  $"dc"_"min"$ and a maximum duty cycle $"dc"_"max"$, utility increases linearly
  with duty cycle (with slope $alpha$ and intercept $beta$); above $"dc"_"max"$,
  additional duty cycle yields no further benefit and utility is capped at
  $u_M$. For example, in a location-tracking application, sampling below
  $"dc"_"min"$ is too infrequent to track the person's movement; sampling above
  $"dc"_"max"$ exceeds the person's maximum movement speed and adds no
  information.

  Kansal's algorithm maximizes total utility over a day by assigning a duty
  cycle to each time slot, given weather-forecast-based estimates of energy
  production in each slot. Time is divided into $k$ slots (typically 24, one per
  hour), and the algorithm assigns the maximum duty cycle to _sun slots_ (slots
  where estimated production exceeds maximum load) and the minimum duty cycle to
  _dark slots_ (slots where production is below maximum load). Starting from
  this initial assignment, surplus energy (case 1: overproduction) is
  redistributed by upgrading dark slots to higher duty cycles, one at a time in
  order, until the surplus is exhausted. If energy is insufficient for the
  initial assignment (case 2: underproduction), sun slots are downgraded
  uniformly until energy balance is restored; if this still leaves a deficit, no
  admissible solution exists.

  The algorithm's optimality follows from the linearity of the
  utility-duty-cycle relationship: upgrading dark slots by as much as possible
  before downgrading sun slots maximizes total utility. The algorithm runs in
  $O(k)$ time and does not require a linear programming solver, making it
  implementable on low-power microcontrollers.

  Energy production estimates are generated by an _exponentially weighted moving
  average_ (EWMA) filter. The estimated production in slot $i$ for day $j+1$ is:

  $ hat(p)_s^(j+1) (i) = alpha dot hat(p)_s^j (i) + (1 - alpha) dot p_s^j (i) $

  where $p_s^j (i)$ is the measured production in slot $i$ of day $j$ and
  $alpha < 1$ is a smoothing parameter. The EWMA filter assumes day-to-day
  production in the same slot is correlated (as is the case for solar energy),
  giving more weight to the most recent observation while retaining historical
  context. The parameter $alpha$ can be tuned based on observed forecast errors,
  or dynamically adjusted if actual production deviates significantly from
  forecasts---triggering a re-optimization of the remaining slots in the current
  day.

  == A Task-Based Model for Load Modulation

  === From Duty Cycles to Tasks

  Kansal's framework models load modulation exclusively through duty cycle
  adjustment, treating the relationship between duty cycle and performance as
  smooth and linear. Many real IoT applications, however, offer qualitatively
  different implementation alternatives: a sensing task might use a precision
  accelerometer or a simpler inertial sensor; a processing task might apply a
  full signal processing pipeline or only threshold detection; a communication
  task might transmit raw data or compressed summaries. Each alternative has a
  distinct energy cost and a distinct utility that cannot be captured by a
  single duty cycle parameter.

  A _task-based model_ generalizes Kansal's framework to accommodate these
  discrete alternatives. The application cycle is decomposed into $n$
  alternative tasks $T_0, T_1, dots, T_(n-1)$, each characterized by a power
  consumption $c_j$ per slot and an application utility $u_j$. A scheduler
  assigns exactly one task to each time slot, subject to energy and battery
  constraints, maximizing total utility over the scheduling horizon.

  The battery charge at the end of slot $i$ evolves as:

  $
    B(i+1) = min(B_"max", B(i) + eta dot (p_s (i) - p_c (i))^+ - (p_c (i) - p_s (i))^+)
  $

  where $p_c (i)$ is the power consumption of the task assigned to slot $i$ and
  $p_s (i)$ is the estimated harvested power in that slot. The battery charge is
  capped at $B_"max"$ (excess production is wasted once the buffer is full) and
  must remain above $B_"min"$ at all times (the minimum operating voltage). The
  energy neutrality constraint requires that the battery charge at the end of
  the day be at least as high as at the beginning: $B(k+1) >= B(1)$.

  === Optimization Problem

  The task assignment problem can be stated as an integer program: maximize the
  sum of utilities $sum_(i=1)^k sum_(j=0)^(n-1) x_(i,j) dot u_j$ subject to the
  constraint that exactly one task is assigned to each slot ($sum_j x_(i,j) = 1$
  for all $i$), the battery never falls below $B_"min"$, and energy neutrality
  is maintained. The binary variables $x_(i,j)$ indicate whether task $j$ is
  assigned to slot $i$.

  This problem is NP-hard in general, reducible to a variant of the knapsack
  problem. However, a pseudo-polynomial dynamic programming algorithm solves it
  optimally in $O(k dot |"BatteryLevels"|)$ time, where the number of distinct
  battery levels is determined by the ADC resolution. In practice, a 10-bit ADC
  measuring a battery in the range 3.4-4.2 V yields at most 1024 distinct
  levels, and with $k = 24$ slots per day, the algorithm completes in
  milliseconds even on an Arduino Uno---a result confirmed by empirical
  measurements showing execution times under one second for relevant hardware
  configurations.

  The dynamic programming recursion operates backward from the last slot. For
  the last slot $k$, the optimal utility is:

  $ "opt"(k, b) = max { u_j : b + eta dot (p_s^+ (k) - p_c^- (k)) >= B(1) } $

  where the maximization is over all tasks $j = 0, dots, n-1$ that leave the
  battery in a state satisfying energy neutrality, and $p_s^+ (k)$ and
  $p_c^- (k)$ denote the surplus production and deficit consumption for that
  task assignment. For earlier slots:

  $
    "opt"(i, b) = max_(j = 0, dots, n-1) { u_j + "opt"(i+1, B_j (i+1)) : B_j (i+1) >= B_"min" }
  $

  where $B_j (i+1)$ is the battery level at the end of slot $i$ if task $T_j$ is
  assigned to that slot and the battery level at the start is $b$.

  The memory complexity of the algorithm is $O(|"BatteryLevels"|)$ when
  implemented with careful memoization---only one row of the dynamic programming
  table needs to be retained at each step. This modest memory footprint,
  combined with the polynomial time complexity in the ADC resolution, makes the
  algorithm deployable on microcontroller-class hardware. Simulation results
  across Arduino Uno, Tmote Sky, and Raspberry Pi platforms, using a KL-SUN3W
  solar panel and a 2000 mAh battery over scheduling horizons of 24 to 288
  slots, confirm that the algorithm consistently achieves high utility while
  maintaining energy neutrality across months of simulated operation including
  seasonal variation.

  == Limitations and Open Challenges

  Energy harvesting systems, even with the sophisticated models and algorithms
  described in this chapter, face limitations that deserve explicit
  acknowledgment. The most fundamental is that energy harvesting does not
  guarantee continuous operation. A solar-powered sensor with a 2000 mAh battery
  and no wind harvesting may deplete its battery during a windless night
  following an overcast day, and recover only after sunrise. The Kansal
  framework provides conditions under which energy neutrality is maintained _on
  average_ over a scheduling period, but rare adverse conditions can violate
  those conditions.

  The accuracy of energy production forecasts is a second critical limitation.
  EWMA filtering assumes day-to-day stationarity that may not hold during
  weather transitions, seasonal changes, or anomalous events. The Kansal
  algorithm includes a dynamic adaptation mechanism that re-optimizes remaining
  slots when actual production deviates significantly from forecast, but this
  adaptation is reactive rather than anticipatory. More sophisticated
  forecasting methods---incorporating weather APIs, multiple-day horizon
  planning, or machine learning models trained on site-specific historical
  data---can improve forecast accuracy at the cost of greater computational
  complexity.

  The task-based model assumes discrete, well-characterized implementation
  alternatives with known and stable energy costs. In practice, energy costs
  depend on environmental conditions (radio propagation distance affects
  transmit power; temperature affects sensor calibration time), and utility is
  difficult to quantify precisely. The framework's linearity
  assumptions---between duty cycle and power consumption, and between duty cycle
  and utility---are approximations that may not hold for all application types.
  Extensions of the task-based model to richer utility representations,
  multi-device joint optimization, and non-stationary harvesting environments
  remain active areas of research.

]
