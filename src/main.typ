#import "@preview/bookly:3.1.0": *

#show: bookly.with(
  title: [Mobile &\ Cyber-Physical Systems],
  author: "",
  lang: "en",
  theme: orly,
  colors: (
    primary: rgb(55, 170, 92),
  ),
  title-page: book-title-page(
    series: emph("講義ノート"),
    subtitle: none,
    institution: none,
    edition: "Draft",
    cover: image("figures/orso.png", width: 100%),
    logo: image("figures/sula_logo.svg"),
  ),
)

#show heading.where(level: 3): set heading(numbering: none, outlined: false)

#set ref(supplement: auto)

#show: main-matter

#tableofcontents

#part("Part 1")

#include "chapters/01_iot.typ"
#include "chapters/02_iot_design.typ"
#include "chapters/03_harvesting.typ"
#include "chapters/04_ieee.typ"
#include "chapters/05_mac.typ"
#include "chapters/06_zigbee.typ"
#include "chapters/07_mqtt.typ"
#include "chapters/08_arduino.typ"
