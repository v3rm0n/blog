---
layout: post
title:  "Twilio based alarm arm/disarm for Home Assistant"
tags: homeassistant twilio software javascript
---

I have a homemade alarm system in my summerhouse based on [Home Assistant][ha]
, [Konnected][konnected] and some [PIR sensors][pir].

Home Assistant has an [integration][ha-twilio] with [Twilio][twilio] which enables the automation
system to call be in case the alarm system has been triggered. This is pretty useful compared to
notifications since I always put my phone on "Do Not Disturb" mode when I sleep so the notifications
or most calls do not get through, but the alarm system number is in my favourites, so it will always
get through even on DnD.

FYI since then, iOS 12 has been released, and it has support
for [critical notifications][ha-critical]
which would probably work as well as the call.

One problem I've been having though is that while it's pretty easy for me to arm/disarm the alarm
using the Home Assistant app or Apple Home, but it's harder for family/friends whenever they need to
visit the summerhouse without me.

## Twilio to the rescue

Since I already had a Twilio account I decided to use it to allow people to call a number, enter a
pin and arm/disarm the alarm.

For that to work, I needed to:

- Have a number in Twilio which can accept calls
- Add a [webhook][ha-webhook] to Home Assistant
- Write a function in Twilio that is run when a call is coming in
- When PIN is valid the function will call the webhook
- The webhook needs to be configured to arm/disarm the alarm

Since I already had a number the next step was to add a webhook to Home Assistant:

```yaml
automation:
  - alias: 'Alarm webhook: turn off when armed'
    trigger:
      - platform: webhook
        webhook_id: alarm-webhook-randomid
    condition: [ ]
    action:
      - service: alarm_control_panel.alarm_disarm
        data: { }
        target:
          entity_id: alarm_control_panel.alarm
    mode: single
  - alias: 'Alarm webhook: turn on when disarmed'
    trigger:
      - platform: webhook
        webhook_id: alarm-webhook-turn-on-when-disarmed-randomid
    condition:
      - condition: state
        entity_id: alarm_control_panel.alarm
        state: disarmed
    action:
      - service: alarm_control_panel.alarm_arm_home
        data: { }
        target:
          entity_id: alarm_control_panel.alarm
```

So one webhook for arming and another for disarming. I didn't find a good way how to do toggling of
the alarm with webhooks. If you know how then please let me know :)

Then I needed to write a Twilio function:

```javascript
const fetch = (...args) => import('node-fetch').then(({default: fetch}) => fetch(...args));

exports.handler = async (context, event, callback) => {
  const twiml = new Twilio.twiml.VoiceResponse();
  if (event.Digits) {
    if (event.Digits == '1234') {
      const response = await fetch(
        'https://homeassistant.example.com/api/webhook/alarm-webhook-randomid',
        {
          method: 'POST'
        });
      if (response.status == 200) {
        twiml.say('Correct, alarm has been disarmed.');
      } else {
        twiml.say('OMG, something went wrong!');
      }
    } else if (event.Digits == '4321') {
      const response = await fetch(
        'https://homeassistant.example.com/api/webhook/alarm-webhook-turn-on-when-disarmed-randomid',
        {
          method: 'POST'
        });
      if (response.status == 200) {
        twiml.say('Correct, alarm has been armed.');
      } else {
        twiml.say('OMG, something went wrong!');
      }
    } else {
      twiml.say('Incorrect, get the fuck out.');
    }
  } else {
    const gather = twiml.gather({numDigits: 4, timeout: 20});
    gather.say(
      `Hi ${fromName(event)}, this is the summer house, please enter the code on your keyboard.`);
  }
  callback(null, twiml);
};

function fromName(event) {
  switch (event.From) {
    case '+37212345678':
      return 'Maido';
    default:
      return 'Stranger';
  }
}

```

When you first call there are no digits (except if you call with a special number with the PIN
already included, then you can bypass this manual pin entry phase) so it goes to the else block and
asks you for the digits. When you enter 4 digits it will compare and either arm/disarm or rudely
tell you to go away. There is also a nice greeting by name when you are calling from a known number.

## Security

It's not ideal from a security standpoint because there is some relying on obscurity. If
somebody would for some reason try to target the summerhouse they could either:

- Try to find out the webhook ID since it's the only thing that secures the webhook
- Try to find out the Twilio number and then just enumerate PINs

I think the security level is reasonable for my small summerhouse though.

[ha]: https://www.home-assistant.io

[ha-webhook]: https://www.home-assistant.io/docs/automation/trigger/#webhook-trigger

[ha-twilio]: https://www.home-assistant.io/integrations/twilio_call/

[ha-critical]: https://companion.home-assistant.io/docs/notifications/critical-notifications

[twilio]: https://www.twilio.com

[konnected]: https://konnected.io

[pir]: https://en.wikipedia.org/wiki/Passive_infrared_sensor
