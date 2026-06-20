#import "@preview/bookly:3.1.0": *

#let abs = [
  Every wireless network, every digital sensor, and every audio or video codec
  rests on a foundation of signal theory—the mathematical framework that
  describes how physical quantities vary over time, how they can be decomposed
  into frequency components, and how they can be converted between analog and
  digital forms without losing essential information. This chapter develops that
  foundation from first principles. Beginning with a taxonomy of signals and
  their mathematical representations, the discussion moves to the Fourier series
  as the tool for decomposing periodic signals into harmonic sinusoids, then
  generalizes to the Continuous Fourier Transform for non-periodic signals and
  the Discrete Fourier Transform for sampled data. The sampling theorem and the
  phenomenon of aliasing are examined in depth, with particular attention to
  what the Nyquist criterion actually guarantees—and what it does not. The
  chapter is grounded throughout in applications relevant to mobile and
  cyber-physical systems: OFDM in 4G/5G networks, multipath fading in wireless
  channels, analog-to-digital conversion in sensors, and spectral analysis in
  digital receivers. The recurring tension is between the continuous, infinite
  world of physical signals and the discrete, finite world of digital systems:
  every step from transduction through sampling through spectral analysis is an
  approximation, and understanding what information is lost—and what can be
  recovered—is the essence of signal theory.
]

#chapter(
  title: "Signal Theory",
  abstract: abs,
  toc: true,
)[

  == Signals as the Foundation of Digital Systems

  Modern computing and communication systems are, at their deepest level,
  systems for representing, transmitting, and processing signals. A signal is a
  variation of a physical quantity that carries information—electrical voltage
  and current in circuits, acoustic pressure waves in air, electromagnetic field
  intensity in space, or mechanical displacement in a sensor. Every practical
  system that interacts with the physical world must at some point convert a
  physical quantity into a signal, process that signal, and convert it back into
  a physical effect or a digital representation.

  The pervasiveness of signal processing in the systems studied in this course
  is worth making explicit. The 4G and 5G radio protocols discussed in earlier
  chapters use Orthogonal Frequency Division Multiplexing (OFDM), a technique
  that splits a data stream across hundreds or thousands of narrowband frequency
  channels—an operation entirely defined in terms of frequency-domain signal
  decomposition. The multipath fading that degrades wireless channel quality,
  and the equalization algorithms that compensate for it, are understood through
  the channel's frequency response. The sensors at the heart of every IoT node
  convert physical quantities into analog voltages; an analog-to-digital
  converter (ADC) samples and quantizes these voltages into digital values; the
  resulting digital signal is processed by firmware that may apply filtering,
  averaging, or pattern recognition. Each of these operations is a concrete
  instantiation of concepts from signal theory.

  Why, then, study signal theory as a unified subject rather than encountering
  each technique in its application context? Because the underlying mathematical
  framework—the decomposition of signals into frequency components—is the same
  in all these cases, and understanding it at the abstract level reveals
  connections and principles that would be invisible if each application were
  treated in isolation.

  == Classification of Signals

  === What Is a Signal?

  A _signal_ is a function of one or more independent variables that describes
  how a measurable physical quantity varies. We restrict attention to
  one-dimensional signals in which the independent variable is time, $t$. A
  signal $s(t)$ maps a domain $DD$ to a codomain $CC$: $s: DD -> CC$. Both the
  domain and codomain can be the set of real numbers $RR$, the integers $ZZ$,
  the complex numbers $CC$, or a finite discrete set.

  We focus on _deterministic_ signals—signals that are known before they are
  produced and can be expressed as explicit mathematical functions. The
  complementary class of _random_ signals is analyzed using probabilistic
  methods and statistics; many real-world signals are random, but understanding
  the deterministic case provides the vocabulary and tools needed to address the
  random case.

  === The Four Signal Classes

  Signals are classified according to whether their domain (time) and codomain
  (amplitude) are continuous or discrete.

  An _analog signal_ is both continuous in time (domain $RR$) and continuous in
  amplitude (codomain $RR$). The voltage output of a microphone as a function of
  time is a prototypical analog signal: it can take any value within a range and
  varies continuously without discrete steps. Analog signals are the natural
  description of physical quantities in the world.

  A signal that is continuous in time but discrete in amplitude—sometimes called
  a _quantized_ analog signal—takes values only from a countable set (such as
  $ZZ$) even though it is defined at every instant. Such signals are less common
  in practice but arise in certain modulation schemes.

  A _discrete-time_ signal has a domain that is a subset of the integers,
  $ZZ_T = {n T : n in ZZ, T in RR}$, where $T$ is the sampling period. The
  signal is defined only at regularly spaced instants. The amplitude of a
  discrete-time signal can still be continuous, as when an ADC produces
  floating-point output, or it can be discrete.

  A _digital signal_ is both discrete in time and discrete in amplitude, taking
  values from a finite set of symbols. When the symbol set is the binary
  alphabet ${0, 1}$, a digital signal is a binary sequence—the standard
  representation of information in computers and communication systems. Text is
  a digital signal (a sequence of characters from a finite alphabet); after
  encoding each character in bits, it becomes a binary sequence. A digital
  signal is also called a _symbolic sequence_.

  The _bitrate_ of a digital source links these representations quantitatively.
  If a source emits symbols from an alphabet of $S$ elements at a rate of $r$
  symbols per second, and each symbol is encoded in $M = ceil(log_2 S)$ bits,
  the resulting bitrate is $r dot M$ bits per second. A source with an 8-symbol
  alphabet ($S = 8$, so $M = 3$ bits per symbol) operating at 10 symbols per
  second produces 30 bps.

  === Transmission and Channel Effects

  Information-bearing signals are transmitted through physical
  channels—electromagnetic media for radio, optical fibers for guided light,
  acoustic media for sound. A channel is not an ideal conduit: it modifies the
  signal in ways that degrade the information it carries.

  _Attenuation_ is the gradual loss of signal strength as the wave propagates
  through the medium. In wireless channels, attenuation follows a power-law
  relationship with distance: the received power decays as $(f d)^{-n}$, where
  $f$ is the carrier frequency, $d$ is the distance, and the path loss exponent
  $n$ ranges from 2 in free space to 6 in heavily obstructed indoor
  environments. Crucially, attenuation is not uniform across frequencies: a
  channel may attenuate high frequencies more than low frequencies, distorting
  the spectral composition of the received signal.

  _Multipath propagation_ occurs when the transmitted signal reaches the
  receiver via multiple paths—direct line-of-sight, ground reflection, building
  reflections—each with a different path length and hence a different
  propagation delay. The received signal is the superposition of these delayed
  and attenuated copies. If copies arrive with similar amplitudes but shifted
  phases, they may interfere destructively, producing deep signal fades at
  specific frequencies.

  _Noise_ is any unwanted signal that is superimposed on the information-bearing
  signal. External noise arises from interference from other transmitters and
  from industrial equipment; internal (thermal) noise is generated within the
  receiver circuitry by the random thermal motion of electrons and is
  unavoidable. The _signal-to-noise ratio_ (SNR) quantifies the relative
  strength of signal and noise:

  $ "SNR" ("dB") = 10 log_10 frac(P_"signal", P_"noise") $

  A higher SNR indicates a cleaner channel and enables higher information rates.
  The Shannon-Hartley theorem, introduced in the wireless networks chapter,
  expresses this precisely: channel capacity grows logarithmically with SNR.

  Understanding these channel effects motivates the frequency-domain analysis
  developed in the rest of this chapter. Because channels attenuate different
  frequencies differently, analyzing a signal's spectral content—how its energy
  is distributed across frequencies—is essential for designing systems that can
  detect and compensate for these distortions.

  == Periodic Signals and the Fourier Series

  === Sinusoids as Building Blocks

  A sinusoidal signal $A cos(2 pi f t + phi)$ is characterized by its amplitude
  $A$, frequency $f$ (in Hz), and phase $phi$. Sinusoids are the natural basis
  functions for signal analysis because they are the eigenfunctions of linear
  time-invariant systems: a sinusoid at frequency $f$ passing through any linear
  time-invariant channel emerges as a sinusoid at the same frequency $f$,
  possibly with changed amplitude and phase, but not with different frequencies.
  This property—that sinusoids are preserved by the type of systems that
  channels and filters implement—is the deepest reason why frequency-domain
  analysis is the right tool for understanding signal transmission.

  The frequencies present in a signal and their relative amplitudes constitute
  the signal's _spectrum_. Understanding the spectrum allows us to ask which
  frequencies are attenuated by the channel, which are amplified, and which fall
  in bands occupied by interference—questions that are central to the design of
  every radio, sensor interface, and audio processing system.

  === The Fourier Series

  For a periodic signal with period $T$, the _Fourier series_ expresses the
  signal as a sum of sinusoidal _harmonics_—sinusoids at the fundamental
  frequency $F = 1/T$ and its integer multiples $n F$. Using the real-valued
  form, a signal $s(t)$ periodic on $[-pi, pi]$ is represented as:

  $ s(t) = a_0/2 + sum_(n=1)^infinity (a_n cos(n t) + b_n sin(n t)) $

  The Fourier coefficients are computed by projection onto each harmonic:

  $
    a_n = 1/pi integral_(-pi)^pi s(t) cos(n t) d t, quad b_n = 1/pi integral_(-pi)^pi s(t) sin(n t) d t
  $

  The coefficient $a_0 / 2$ is the mean value (DC component) of the signal. Each
  pair $(a_n, b_n)$ determines the amplitude and phase of the $n$-th harmonic,
  which oscillates at frequency $n F = n/T$.

  For signals with period $T$ (rather than $2pi$), the substitution
  $y = 2pi t / T$ converts the general case to the standard form, yielding
  harmonics at frequencies $n/T$ and coefficients computed by integrals over
  $[-T/2, T/2]$.

  === Complex Fourier Coefficients and the Spectrum

  An equivalent and often more compact representation uses complex exponentials.
  By Euler's identity, $e^(j theta) = cos theta + j sin theta$, a sinusoid at
  frequency $n F$ can be written as a complex exponential. The complex Fourier
  coefficient $S_n$ combines the cosine and sine components:

  $ S_n = 1/T integral_(-T/2)^(T/2) s(t) e^(-j 2 pi n t / T) d t $

  The amplitude $|S_n|$ gives the strength of the $n$-th harmonic; the phase
  $angle S_n$ gives its timing offset. The _amplitude spectrum_ is the plot of
  $|S_n|$ against $n$ (or equivalently against frequency $n F$); the _phase
  spectrum_ is the plot of $angle S_n$. Together they completely characterize
  the frequency content of the signal.

  The Gibbs phenomenon is a notable feature of Fourier series approximations of
  discontinuous signals. When a partial sum of $N$ harmonics is used to
  approximate a signal with a jump discontinuity—such as a square wave—the
  approximation exhibits overshoot near the discontinuity that does not diminish
  as $N$ increases: it converges to approximately 9% of the jump height
  regardless of how many harmonics are included. This overshoot is not an
  artifact of poor approximation; it is a fundamental property of the Fourier
  series at discontinuities. In practice, it limits how accurately a
  band-limited (finite number of harmonics) representation can capture signals
  with sharp edges.

  == The Continuous Fourier Transform

  === Extension to Non-Periodic Signals

  The Fourier series applies to periodic signals. Real signals—a speech
  utterance, a radar pulse, a sensor event—are not periodic; they have finite
  duration and do not repeat. To handle non-periodic signals, we take the limit
  of the Fourier series as the period $T -> infinity$. As $T$ grows, the
  fundamental frequency $F = 1/T$ shrinks, the harmonics $n F$ become more
  densely packed, the discrete set of Fourier coefficients becomes a continuous
  function, and the summation over harmonics becomes an integral.

  In this limit, the _Continuous Fourier Transform_ (CFT) of a non-periodic
  signal $s(t)$ is:

  $ S(f) = integral_(-infinity)^(infinity) s(t) e^(-j 2 pi f t) d t $

  where $f$ is the continuous frequency variable, and $S(f)$ is the _spectral
  density_ of $s(t)$ at frequency $f$—a complex-valued function that encodes the
  amplitude and phase of each infinitesimal frequency component. The inverse
  transform reconstructs the original signal:

  $ s(t) = integral_(-infinity)^(infinity) S(f) e^(j 2 pi f t) d f $

  The CFT is the appropriate tool for signals that occur once in
  time—transients, pulses, finite-length recordings—rather than repeating
  indefinitely. As a concrete example, the CFT of a rectangular pulse of
  duration $T$ and unit amplitude is the sinc function:

  $ S(f) = T dot "sinc"(pi f T) = frac(sin(pi f T), pi f) $

  This result has an important qualitative implication: a signal that is narrow
  in time (small $T$) has a wide spectrum (the sinc function spreads across many
  frequencies); a signal that is wide in time (large $T$) has a narrow spectrum.
  This time-bandwidth duality is a fundamental property of the Fourier
  transform: you cannot simultaneously localize a signal in both time and
  frequency. Shorter pulses require more bandwidth—a principle that underlies
  the design of radar systems, spread-spectrum communications, and compressed
  sensing.

  === Filtering in the Frequency Domain

  The spectrum of a real signal in general extends across all frequencies, but
  not all frequency components are equally important or desirable. A filter is a
  system that selectively passes some frequency components while attenuating
  others. A _low-pass filter_ with cutoff frequency $B$ passes all components
  with $|f| < B$ and attenuates components above $B$. A _high-pass filter_
  passes components above its cutoff. A _band-pass filter_ passes a range
  $[f_1, f_2]$.

  Applying a low-pass filter to a signal removes high-frequency components—which
  may correspond to noise, interference, or fine detail that is not needed—while
  preserving the low-frequency components that carry the primary information.
  Applying a high-pass filter removes the DC component and low-frequency drift.
  The practical consequence for communication systems is that filtering is used
  to limit the bandwidth of a transmitted signal to fit within an allocated
  frequency channel, and at the receiver to separate the desired signal from
  out-of-band interference.

  The relationship between filtering and the bandwidth of a signal is the link
  between the CFT and the channel capacity framework introduced in earlier
  chapters. A channel of bandwidth $B$ Hz can pass frequency components up to
  $B$ Hz; the Shannon capacity formula $C = B log_2(1 + "SNR")$ expresses the
  information rate that can be achieved within that bandwidth.

  == From Analog to Digital: Sampling and Quantization

  === The Need for Digitization

  Physical signals are analog; digital systems can only process, store, and
  transmit discrete numerical values. Converting an analog signal into digital
  form—_analog-to-digital conversion_ (ADC)—is the fundamental operation that
  connects the continuous physical world to the discrete computational world. It
  is also an operation that, if performed incorrectly, irreversibly destroys
  information. Understanding when and how digitization can be done without loss
  is therefore essential for anyone designing systems that interface with
  physical signals.

  ADC comprises two operations: _sampling_ and _quantization_. Sampling extracts
  values of the continuous signal at discrete time instants. Quantization rounds
  each sample to the nearest value in a finite set of representable numbers.
  Both operations introduce error, but the errors are of different characters:
  sampling error can be eliminated by sampling fast enough (as the Nyquist
  theorem specifies), while quantization error is irreducible and depends on the
  number of bits used to represent each sample.

  The bitrate of a digitized signal is determined by both choices: a source that
  samples at $f_s$ samples per second and quantizes each sample to $M$ bits
  produces a bitrate of $f_s dot M$ bits per second. For a telephone-quality
  voice signal sampled at 8 kHz with 8-bit quantization, the bitrate is 64
  kbps—the standard rate of a single voice channel in the public switched
  telephone network.

  === The Sampling Theorem

  The _Nyquist-Shannon Sampling Theorem_ is the fundamental result that governs
  the minimum sampling rate needed to represent a band-limited signal without
  loss. Its statement is precise:

  _If a signal $s(t)$ has a spectrum that is zero for all frequencies above
  $f_M$ (a band-limited signal), then $s(t)$ is completely determined by its
  samples taken at regular intervals $T_s <= 1/(2 f_M)$. The minimum sampling
  frequency $f_s = 2 f_M$ is called the Nyquist rate._

  The theorem further guarantees that $s(t)$ can be exactly reconstructed from
  its samples using sinc interpolation:

  $
    s(t) = sum_(n=-infinity)^(infinity) s(n T_s) dot frac(sin(pi f_s (t - n T_s)), pi f_s (t - n T_s))
  $

  The intuition behind this result comes from the frequency-domain picture of
  sampling. When a signal is sampled at frequency $f_s$, the spectrum of the
  sampled signal consists of infinite shifted copies of the original spectrum
  $S(f)$, centered at integer multiples of $f_s$. If the original signal is
  band-limited to $[-f_M, f_M]$ and $f_s >= 2 f_M$, these copies do not
  overlap—each replica occupies the interval $[k f_s - f_M, k f_s + f_M]$, and
  these intervals are disjoint when $f_s >= 2 f_M$. A low-pass filter with
  cutoff $f_M$ then perfectly selects the $k = 0$ replica, recovering $S(f)$ and
  hence $s(t)$.

  === Aliasing

  _Aliasing_ is the distortion that occurs when the sampling rate is
  insufficient—when $f_s < 2 f_M$. In this case, the spectral replicas of $S(f)$
  overlap, mixing the frequency components of the original signal. A frequency
  component at $f$ in the original signal appears in the sampled signal as a
  component at $f - k f_s$ for some integer $k$—it is "folded" to a different
  apparent frequency. Two signals at different frequencies become
  indistinguishable from each other in the sampled representation, making
  reconstruction impossible.

  A concrete example: a 45 Hz sinusoid sampled at 50 Hz (below the Nyquist rate
  of 90 Hz) appears in the sampled data as a 5 Hz sinusoid, because
  $45 - 50 = -5$ Hz. The high-frequency component has been aliased to a low
  frequency that was not present in the original signal.

  The frequency $f_s / 2$ is called the _Nyquist frequency_: all frequencies
  above it are folded back into the range $[0, f_s/2]$ and cannot be
  distinguished from components within that range. Reliable spectral analysis of
  sampled signals requires that all frequency components of interest lie below
  $f_s / 2$.

  === What Nyquist Did Not Say

  The Nyquist theorem is widely misunderstood, and the misunderstanding leads to
  practical errors. A careful statement of what the theorem does and does not
  guarantee is essential.

  The theorem requires that $s(t)$ be _strictly band-limited_: its spectrum must
  be identically zero above $f_M$. No real physical signal satisfies this
  requirement exactly, because a strictly band-limited signal must extend
  infinitely in time—it cannot start or stop at any finite moment. Every real
  signal has some energy at all frequencies; the question is whether energy
  above a chosen cutoff $f_M$ is negligible for the application at hand.

  The theorem also requires an _infinite_ number of samples to exactly
  reconstruct the signal. In practice, we have a finite number of samples taken
  over a finite observation interval, which introduces reconstruction error even
  when the sampling rate is adequate. The theorem tells us what is possible in
  principle, not what is achievable in a finite-duration measurement.

  These limitations have practical consequences. A system designer who declares
  "I am sampling a 60 Hz power line signal, so I need to sample at 120 Hz"
  misapplies the theorem: the power line signal, while nominally at 60 Hz,
  contains harmonic distortion at 120 Hz, 180 Hz, 240 Hz, and beyond due to
  nonlinear loads. Sampling at 120 Hz aliases these harmonics onto lower
  frequencies, corrupting the measurement. The correct approach is to determine
  the highest frequency component that is significant for the measurement
  purpose, not the nominal frequency of the signal.

  Similarly, the existence of an anti-aliasing filter does not solve the problem
  by itself: real filters have finite roll-off and pass some energy above their
  stated cutoff frequency. A 4 kHz cutoff filter does not eliminate all energy
  above 4 kHz; it attenuates it. If a system samples at 8 kHz (Nyquist rate for
  a 4 kHz cutoff), energy leaking above 4 kHz will still be aliased. The
  practical remedies are to use a steeper filter (more complex and expensive) or
  to oversample—sample at a rate well above $2 f_M$—so that the transition band
  of the anti-aliasing filter falls in the oversampled region and the aliased
  energy is small.

  Paradoxically, there are also situations where _downsampling below_ the
  Nyquist rate is acceptable or even beneficial. If a signal is periodic and
  stationary—it repeats indefinitely with a fixed frequency—then sampling at a
  rate slightly below the signal's frequency causes the sampling phase to shift
  gradually relative to the signal's phase. Over time, samples are collected at
  all phases of the waveform, allowing reconstruction even though no individual
  sample interval captures a complete period. This technique, called
  _undersampling_ or _subsampling_, is used in oscilloscopes and certain
  communications receivers that need to capture high-frequency periodic signals
  without a proportionally fast ADC.

  == The Discrete Fourier Transform

  === From Continuous to Discrete Spectral Analysis

  The Fourier series and Continuous Fourier Transform apply to continuous-time
  signals. In digital signal processing, we have access only to a finite
  sequence of $N$ sampled values $s_0, s_1, ..., s_(N-1)$, obtained by sampling
  a continuous signal at frequency $f_s$ over a total observation period
  $T = N / f_s$. A Fourier analysis tool adapted to this setting is required.

  The _Discrete Fourier Transform_ (DFT) is defined for a finite sequence $s_k$
  with $k = 0, 1, ..., N-1$:

  $ S_n = sum_(k=0)^(N-1) s_k e^(-j 2 pi n k / N), quad n = 0, 1, ..., N-1 $

  The inverse DFT recovers the samples:

  $ s_k = 1/N sum_(n=0)^(N-1) S_n e^(j 2 pi n k / N) $

  The DFT can be derived by treating the $N$ samples as one period of a periodic
  signal and applying the Fourier series formula, approximating the integral by
  a Riemann sum over the $N$ sample points. The resulting complex coefficients
  $S_n$ represent the signal's spectral content at frequencies
  $f_n = n f_s / N = n / T$, for $n = 0, 1, ..., N-1$.

  === Frequency Resolution and the Bin Structure

  The DFT has $N$ frequency bins, spaced by $Delta f = f_s / N = 1/T$ Hz. This
  _frequency resolution_ is determined by the observation interval $T$, not the
  sampling rate: a longer observation period yields finer frequency resolution,
  while a shorter period yields coarser resolution. To double the frequency
  resolution, one must double the observation time (keep twice as many samples),
  not double the sampling rate.

  A practical consequence of the bin structure is that the DFT can only resolve
  signal components that fall exactly on bin frequencies. If a sinusoidal
  component lies between two bins—at $f$ where $f != n f_s / N$ for any integer
  $n$—its energy spreads across multiple adjacent bins, a phenomenon called
  _spectral leakage_. The apparent amplitude of the component is distributed
  among neighboring bins, reducing the accuracy with which its frequency can be
  identified.

  As a concrete example: a 45 Hz sinusoid sampled at $f_s = 200$ Hz with
  $N = 20$ samples has $Delta f = 200/20 = 10$ Hz, placing bins at 0, 10, 20,
  30, 40, 50 Hz. Since 45 Hz falls between the 40 Hz and 50 Hz bins, the DFT
  cannot accurately localize this component. Increasing $N$ to 40 samples gives
  $Delta f = 200/40 = 5$ Hz, with bins at 0, 5, 10, ..., 40, 45, 50 Hz. Now 45
  Hz coincides exactly with a bin, and the DFT accurately identifies the
  component.

  The Nyquist constraint applies to the DFT as well: components above $f_s / 2$
  are aliased and appear at frequencies within $[0, f_s/2]$. For a DFT with $N$
  points, the $N/2$ bins from index 0 to $N/2 - 1$ correspond to frequencies
  $[0, f_s/2]$; the remaining bins represent negative frequencies (which are
  complex conjugates of the positive bins for real-valued signals) or,
  equivalently, aliased components above $f_s/2$.

  === The Fast Fourier Transform

  Computing the DFT naively requires $N^2$ complex multiplications (one for each
  $(n, k)$ pair). The _Fast Fourier Transform_ (FFT) is an algorithm that
  exploits the symmetry and periodicity of the complex exponentials
  $e^(-j 2 pi n k / N)$ to reduce the computation to $O(N log_2 N)$ operations.
  For $N = 1024$, this is a reduction from approximately one million operations
  to ten thousand—a factor of 100 improvement. The FFT made real-time spectral
  analysis practical for digital signal processing and is the algorithm
  underlying OFDM modulation in 4G and 5G, digital audio processing, radar
  signal processing, and virtually every other practical application of the DFT.

  == Summary: The Fourier Analysis Toolkit

  The tools developed in this chapter form a coherent progression from
  continuous-time periodic signals to digitized finite-duration measurements.

  The _Fourier series_ decomposes a periodic continuous-time signal of period
  $T$ into a discrete set of harmonics at frequencies $n/T$. The complex
  coefficients $S_n$ give the amplitude and phase of each harmonic. The series
  converges to the original signal everywhere it is continuous, with Gibbs
  overshoot at discontinuities.

  The _Continuous Fourier Transform_ extends spectral analysis to non-periodic
  signals by taking the limit $T -> infinity$. The spectrum becomes a continuous
  function $S(f)$ of frequency, and both the forward and inverse transforms are
  integrals. The time-bandwidth duality—shorter signals have wider spectra and
  vice versa—is a fundamental consequence of this transform.

  The _Sampling Theorem_ specifies that a band-limited signal with maximum
  frequency $f_M$ can be exactly reconstructed from samples taken at rate
  $f_s >= 2 f_M$. Sampling below the Nyquist rate causes aliasing—irreversible
  confusion between frequency components. In practice, no signal is perfectly
  band-limited, and anti-aliasing filters and oversampling are the engineering
  tools that make the theorem's requirements approximately satisfiable.

  The _Discrete Fourier Transform_ applies Fourier analysis to finite sequences
  of samples. Its $N$ frequency bins are spaced $Delta f = f_s / N$ Hz apart;
  finer resolution requires longer observation intervals. The FFT algorithm
  makes DFT computation tractable for large $N$, enabling real-time spectral
  analysis in devices from smartphones to base stations.

  Together, these tools allow a system designer to ask and answer the questions
  that underlie all of wireless communication and sensor processing: what
  frequencies are present in a signal, how does a channel modify those
  frequencies, how much bandwidth is needed to represent the signal, and at what
  rate must it be sampled to capture its content faithfully?

]
