import QtQuick
import qs.Commons
import qs.Ui
import "../ui" as Ui
import "../ui/warmth.js" as Warmth

Ui.SectionBody {
  id: page
  property var app: null

  readonly property var schedule: app.nightlightSchedule
  readonly property bool scheduled: schedule.enabled === true
  readonly property bool gradual: schedule.gradual === true
  readonly property string onAt: schedule.on !== undefined ? schedule.on : "20:00"
  readonly property string offAt: schedule.off !== undefined ? schedule.off : "07:00"
  readonly property int startKelvin: schedule.temperature !== undefined ? Number(schedule.temperature) : 4000
  readonly property int deepKelvin: schedule.deep !== undefined ? Number(schedule.deep) : 3000
  readonly property int ramp: schedule.ramp !== undefined ? Number(schedule.ramp) : 180
  readonly property int window: {
    var w = (Warmth.minutes(page.offAt) - Warmth.minutes(page.onAt) + 1440) % 1440
    return w === 0 ? 1440 : w
  }
  readonly property string warmestAt: Warmth.clock(Warmth.minutes(page.onAt) + Math.min(page.ramp, page.window - 10))

  property int nowMinutes: -1
  function tick() {
    var d = new Date()
    page.nowMinutes = d.getHours() * 60 + d.getMinutes()
  }
  Component.onCompleted: page.tick()
  Timer {
    interval: 30000
    running: true
    repeat: true
    onTriggered: page.tick()
  }

  function describe(k) { return Warmth.name(k) + " (" + k + " K)" }

  readonly property string summary: {
    if (!page.scheduled)
      return "The schedule is off. Turn it on and the screen warms up by itself every evening."
    if (!page.gradual)
      return "Every night from " + page.onAt + " to " + page.offAt + " the screen stays "
        + page.describe(page.startKelvin) + "."
    return "From " + page.onAt + " the screen starts " + page.describe(page.startKelvin)
      + ", grows warmer until it is " + page.describe(page.deepKelvin) + " at " + page.warmestAt
      + ", and goes back to normal at " + page.offAt + "."
  }

  function times(current) {
    var out = []
    for (var m = 0; m < 1440; m += 30) out.push(Warmth.clock(m))
    if (current && out.indexOf(current) === -1) {
      out.push(current)
      out.sort()
    }
    return out
  }

  readonly property var warmestOptions: {
    var out = []
    var start = Warmth.minutes(page.onAt)
    for (var d = 30; d <= page.window - 10; d += 30) out.push({ value: String(d), label: Warmth.clock(start + d) })
    var current = Math.min(page.ramp, page.window - 10)
    if (current > 0 && current % 30 !== 0) {
      out.push({ value: String(current), label: Warmth.clock(start + current) })
      out.sort(function(a, b) { return Number(a.value) - Number(b.value) })
    }
    return out
  }

  Ui.SettingGroup {
    framed: true

    Ui.NightTimeline {
      active: page.scheduled
      on: page.onAt
      off: page.offAt
      startKelvin: page.startKelvin
      deepKelvin: page.deepKelvin
      gradual: page.gradual
      ramp: page.ramp
      summary: page.summary
      nowMinutes: page.nowMinutes
    }
  }

  Ui.SettingGroup {
    title: "Schedule"

    Ui.SwitchRow {
      label: "Turn on every night"
      checked: page.scheduled
      onRequested: function(next) { page.app.set("nightlight-schedule", next ? "true" : "false") }
      changed: page.app.isChanged("nightlight-schedule")
      onResetRequested: page.app.resetSetting("nightlight-schedule")
    }

    Ui.PickerRow {
      label: "Turn on at"
      enabled: page.scheduled
      value: page.onAt
      options: page.times(value)
      onPicked: function(next) { page.app.set("nightlight-on", next) }
      changed: page.app.isChanged("nightlight-on")
      onResetRequested: page.app.resetSetting("nightlight-on")
    }

    Ui.PickerRow {
      label: "Back to normal at"
      enabled: page.scheduled
      value: page.offAt
      options: page.times(value)
      onPicked: function(next) { page.app.set("nightlight-off", next) }
      changed: page.app.isChanged("nightlight-off")
      onResetRequested: page.app.resetSetting("nightlight-off")
    }
  }

  Ui.SettingGroup {
    title: "Warmth"

    Ui.ChoiceRow {
      label: "Through the night"
      enabled: page.scheduled
      value: page.gradual ? "true" : "false"
      options: [{ value: "false", label: "Stay the same" }, { value: "true", label: "Get warmer" }]
      onPicked: function(next) { page.app.set("nightlight-gradual", next) }
      changed: page.app.isChanged("nightlight-gradual")
      onResetRequested: page.app.resetSetting("nightlight-gradual")
    }

    Ui.WarmthRow {
      label: page.gradual ? "At first" : "Warmth"
      enabled: page.scheduled
      value: page.startKelvin
      onCommitted: function(next) { page.app.set("nightlight-temp", next) }
      changed: page.app.isChanged("nightlight-temp")
      onResetRequested: page.app.resetSetting("nightlight-temp")
    }

    Ui.WarmthRow {
      visible: !searchHidden && page.gradual
      label: "At its warmest"
      enabled: page.scheduled
      value: page.deepKelvin
      onCommitted: function(next) { page.app.set("nightlight-deep", next) }
      changed: page.app.isChanged("nightlight-deep")
      onResetRequested: page.app.resetSetting("nightlight-deep")
    }

    Ui.PickerRow {
      visible: !searchHidden && page.gradual
      label: "Warmest by"
      enabled: page.scheduled
      value: String(Math.min(page.ramp, page.window - 10))
      options: page.warmestOptions
      onPicked: function(next) { page.app.set("nightlight-ramp", next) }
      changed: page.app.isChanged("nightlight-ramp")
      onResetRequested: page.app.resetSetting("nightlight-ramp")
    }
  }

  Ui.SettingGroup {
    title: "Right now"

    Ui.SwitchRow {
      label: "Night light on"
      description: "Warm from this moment until the schedule's next change."
      checked: page.app.nightlightOn
      onRequested: function(next) { page.app.set("nightlight", next ? "true" : "false") }
    }
  }
}
