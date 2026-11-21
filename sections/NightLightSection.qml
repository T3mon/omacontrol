import QtQuick
import qs.Commons
import qs.Ui
import "../ui" as Ui

Ui.SectionBody {
  id: page
  property var app: null

  readonly property var schedule: app.nightlightSchedule
  readonly property bool scheduled: schedule.enabled === true

  function times(current) {
    var out = []
    for (var m = 0; m < 24 * 60; m += 30) {
      var h = Math.floor(m / 60)
      var label = (h < 10 ? "0" : "") + h + ":" + (m % 60 === 0 ? "00" : "30")
      out.push(label)
    }
    if (current && out.indexOf(current) === -1) {
      out.push(current)
      out.sort()
    }
    return out
  }

  Ui.SettingGroup {
    Ui.SwitchRow {
      label: "On now"
      description: "Warms the screen now. The schedule takes over again at its next change."
      checked: page.app.nightlightOn
      onRequested: function(next) { page.app.set("nightlight", next ? "true" : "false") }
    }
  }

  Ui.SettingGroup {
    title: "Schedule"

    Ui.SwitchRow {
      label: "Turn on automatically"
      checked: page.scheduled
      onRequested: function(next) { page.app.set("nightlight-schedule", next ? "true" : "false") }
      changed: page.app.isChanged("nightlight-schedule")
      onResetRequested: page.app.resetSetting("nightlight-schedule")
    }

    Ui.PickerRow {
      label: "Turn on at"
      enabled: page.scheduled
      value: page.schedule.on !== undefined ? page.schedule.on : "20:00"
      options: page.times(value)
      onPicked: function(next) { page.app.set("nightlight-on", next) }
      changed: page.app.isChanged("nightlight-on")
      onResetRequested: page.app.resetSetting("nightlight-on")
    }

    Ui.PickerRow {
      label: "Turn off at"
      enabled: page.scheduled
      value: page.schedule.off !== undefined ? page.schedule.off : "07:00"
      options: page.times(value)
      onPicked: function(next) { page.app.set("nightlight-off", next) }
      changed: page.app.isChanged("nightlight-off")
      onResetRequested: page.app.resetSetting("nightlight-off")
    }

    Ui.NumberRow {
      label: "Warmth"
      description: "Lower is warmer. The manual switch always uses 4000 K."
      enabled: page.scheduled
      value: page.schedule.temperature !== undefined ? Number(page.schedule.temperature) : 4000
      from: 2500
      to: 6000
      step: 100
      suffix: " K"
      onCommitted: function(next) { page.app.set("nightlight-temp", next) }
      changed: page.app.isChanged("nightlight-temp")
      onResetRequested: page.app.resetSetting("nightlight-temp")
    }
  }
}
