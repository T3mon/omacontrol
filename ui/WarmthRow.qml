import QtQuick
import qs.Commons
import "." as Local
import "warmth.js" as Warmth

Local.SettingRow {
  id: warmthRow
  property int value: 4000
  property int from: 2000
  property int to: 6500
  property int step: 100
  signal committed(int next)

  property int pending: value
  property bool stepping: false
  property bool dragging: false
  property int dragValue: value
  readonly property int shown: dragging ? dragValue : (stepping ? pending : value)

  onValueChanged: if (stepping && value === pending) stepping = false

  navKeys: [{ key: "←→", label: "Warmer / cooler" }]

  function snap(v) {
    var s = Math.round(v / warmthRow.step) * warmthRow.step
    return Math.max(warmthRow.from, Math.min(warmthRow.to, s))
  }

  function commit(next) {
    var wanted = warmthRow.snap(next)
    if (wanted === warmthRow.shown && !warmthRow.dragging) return
    warmthRow.pending = wanted
    warmthRow.stepping = true
    warmthRow.committed(wanted)
  }

  function fraction(k) { return (k - warmthRow.from) / (warmthRow.to - warmthRow.from) }

  function tint(k) {
    var c = Warmth.rgb(k)
    return Qt.rgba(c.r, c.g, c.b, 1)
  }

  onNavStep: function(delta) { warmthRow.commit(warmthRow.shown + delta * warmthRow.step) }

  Row {
    width: parent.width
    spacing: Style.space(14)

    Item {
      id: trackArea
      width: parent.width - readout.width - parent.spacing
      height: Style.space(34)
      anchors.verticalCenter: parent.verticalCenter
      opacity: warmthRow.enabled ? 1 : 0.35

      Rectangle {
        id: track
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        height: Style.space(10)
        radius: height / 2
        gradient: Gradient {
          orientation: Gradient.Horizontal
          GradientStop { position: 0.0; color: warmthRow.tint(warmthRow.from) }
          GradientStop { position: warmthRow.fraction(3000); color: warmthRow.tint(3000) }
          GradientStop { position: warmthRow.fraction(4000); color: warmthRow.tint(4000) }
          GradientStop { position: warmthRow.fraction(5000); color: warmthRow.tint(5000) }
          GradientStop { position: 1.0; color: warmthRow.tint(warmthRow.to) }
        }
      }

      Rectangle {
        id: knob
        width: Style.space(20)
        height: width
        radius: width / 2
        x: warmthRow.fraction(warmthRow.shown) * (trackArea.width - width)
        anchors.verticalCenter: track.verticalCenter
        color: warmthRow.tint(warmthRow.shown)
        border.width: Style.space(3)
        border.color: Local.Palette.foreground
      }

      Text {
        textFormat: Text.PlainText
        anchors.left: parent.left
        anchors.bottom: parent.bottom
        text: "← warmer"
        color: Local.Palette.muted
        font.family: Local.Palette.fontFamily
        font.pixelSize: Style.font.caption
      }

      Text {
        textFormat: Text.PlainText
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        text: "cooler →"
        color: Local.Palette.muted
        font.family: Local.Palette.fontFamily
        font.pixelSize: Style.font.caption
      }

      MouseArea {
        anchors.fill: parent
        enabled: warmthRow.enabled
        cursorShape: Qt.PointingHandCursor
        function at(mx) {
          var f = Math.max(0, Math.min(1, (mx - knob.width / 2) / (trackArea.width - knob.width)))
          return warmthRow.snap(warmthRow.from + f * (warmthRow.to - warmthRow.from))
        }
        onPressed: function(mouse) { warmthRow.dragValue = at(mouse.x); warmthRow.dragging = true }
        onPositionChanged: function(mouse) { if (pressed) warmthRow.dragValue = at(mouse.x) }
        onReleased: function(mouse) {
          var v = at(mouse.x)
          warmthRow.dragging = false
          warmthRow.commit(v)
        }
        onCanceled: warmthRow.dragging = false
      }
    }

    Row {
      id: readout
      spacing: Style.space(8)
      anchors.verticalCenter: parent.verticalCenter
      width: Style.space(132)

      Rectangle {
        width: Style.space(14)
        height: width
        radius: width / 2
        anchors.verticalCenter: parent.verticalCenter
        color: warmthRow.tint(warmthRow.shown)
      }

      Column {
        anchors.verticalCenter: parent.verticalCenter
        Text {
          textFormat: Text.PlainText
          text: Warmth.name(warmthRow.shown)
          color: Local.Palette.foreground
          font.family: Local.Palette.fontFamily
          font.pixelSize: Style.font.body
        }
        Text {
          textFormat: Text.PlainText
          text: warmthRow.shown + " K"
          color: Local.Palette.muted
          font.family: Local.Palette.fontFamily
          font.pixelSize: Style.font.caption
        }
      }
    }
  }
}
