---
layout: post
title:  "Greenhouse window opener over Wi-Fi"
tags:  hardware digital esphome
---

I have a summerhouse, but it's a bit of a drive from where I live. On the grounds there is a
greenhouse. When the temperature in the greenhouse gets too high you need to open a window. Since I
recently added power to the greenhouse I decided to build an automatic opener that I can control
from a distance.

## Components

We need something to physically move the window and something that enables you to control it from a
distance. Simple.

I ordered the following components:

- [Linear actuator][linear-actuator] to physically move the window
- [Brackets][brackets] to attach the actuator to the window
- [Motor controller][motor-controller] to control the actuator
- [Wemos D1 Mini][wemos-d1-mini] to control the controller from a distance

## The build

For the build we need to connect the hardware to the electronics and program the D1 Mini to control
the controller.

### Hardware

Connecting the linear actuator to the brackets and the controller is pretty straightforward.
Fortunately for us the controller takes in 12V, but it has a 5V voltage regulator on board which
means we can use it to power our D1 Mini. This was actually one of the reasons I went with D1 Mini
and not a more generic [ESP8266][esp8266] chip: simpler chips work only with 3.3V levels.

I found the voltage regulator output pin and a ground pin on the controller and soldered the D1 Mini
power pins to them. Then I need to control the onboard relays from the D1 without disconnecting the
buttons of the controller: I wanted to keep the local control option as well.

This was a bit harder because of my lack of electronics knowledge. I burnt one D1 Mini when I just
connected the output pins to the relay connector. I do have some idea about how transistors work, so
instead I added two transistors and controlled those from the D1 Mini instead.

I don't have a schematic for that because it was pretty straightforward.

### Software

I have a [Home Assistant][hass] instance running in the summerhouse. I decided to control the
greenhouse window opener through that using the [esphome][esphome] project.

The code looked something like this:

```yaml
esphome:
  name: kasvuhoone-aken

esp8266:
  board: d1_mini

# Enable logging
logger:

# Enable Home Assistant API
api:
  password: "SuperSecret"

ota:
  password: "SuperSecret"

# Use multiple ssids to set up at home and then seamlessly move to the summerhouse
wifi:
  networks:
    - ssid: "Home"
      password: "SuperSecret"
    - ssid: "Summerhouse"
      password: "SuperSecret"
  domain: '.lan'

  # Enable fallback hotspot (captive portal) in case wifi connection fails
  ap:
    ssid: "Kasvuhoone Aken Fallback Hotspot"
    password: "SuperSecret"

captive_portal:

switch:
  - platform: gpio
    pin:
      number: D1
      mode:
        output: true
    name: "Kasvuhoone aken lahti" # Open
    id: relay1
    on_turn_on:
      - delay: 7000ms
      - switch.turn_off: relay1
    interlock: [ relay2 ]
  - platform: gpio
    pin:
      number: D2
      mode:
        output: true
    name: "Kasvuhoone aken kinni" # Close
    id: relay2
    on_turn_on:
      - delay: 7000ms
      - switch.turn_off: relay2
    interlock: [ relay1 ]

```

There are two relays on the motor controller. One relay moves the actuator up the other one down. To
make it work properly I had to interlock the relays so that it would not be possible to trigger both
of the relays as the same time and add a delay so that after the relay has done its job it should
turn off. The motor controller lets you choose the speed of the actuator movement as well, so it's
not deterministic, but I found that 7 seconds is enough to open/close the window at any speed.

## Case

When everything was working properly, I printed a case and jammed all the electronics in there and
of course breaking a bunch of wires that were soldered to the controller buttons, so I needed to open
it up again and rewire it :)

## Conclusion

This is what it looks like before assembly:

![Ready product](/assets/images/greenhouse/ready.webp)

I haven't installed it yet, so I don't know how well it works.

[linear-actuator]: https://www.aliexpress.com/item/4000849922418.html

[motor-controller]: https://www.aliexpress.com/item/4001361732892.html

[brackets]: https://www.aliexpress.com/item/1005002284542332.html

[wemos-d1-mini]: https://www.wemos.cc/en/latest/d1/d1_mini.html

[esp8266]: https://en.wikipedia.org/wiki/ESP8266

[hass]: https://www.home-assistant.io

[esphome]: https://esphome.io
