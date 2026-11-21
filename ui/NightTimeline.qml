import QtQuick
import qs.Commons
import "." as Local
import "warmth.js" as Warmth

Item {
  id: timeline

  property bool active: true
  property string on: "20:00"
  property string off: "07:00"
  property int startKelvin: 4000
  property int deepKelvin: 3000
  property bool gradual: false
  property int ramp: 180
  property string summary: ""
  property int nowMinutes: -1

  readonly property int onMin: Warmth.minutes(on)
  readonly property int window: {
    var w = (Warmth.minutes(off) - onMin + 1440) % 1440
    return w === 0 ? 1440 : w
  }
  readonly property real rampFraction: gradual ? Math.max(0.02, Math.min(1, Math.min(ramp, window - 10) / window)) : 0
  readonly property real nowFraction: {
    if (nowMinutes < 0) return -1
    var d = (nowMinutes - onMin + 1440) % 1440
    return d < window ? d / window : -1
  }
  readonly property int nowKelvin: {
    if (nowFraction < 0) return 0
    if (!gradual || nowFraction >= rampFraction) return gradual ? deepKelvin : startKelvin
    return Math.round(startKelvin + (deepKelvin - startKelvin) * nowFraction / rampFraction)
  }

  function tint(k) {
    var c = Warmth.rgb(k)
    return Qt.rgba(c.r, c.g, c.b, 1)
  }

  width: parent ? parent.width : 0
  implicitHeight: body.implicitHeight

  Column {
    id: body
    width: parent.width
    spacing: Style.space(14)

    Text {
      textFormat: Text.PlainText
      width: parent.width
      wrapMode: Text.WordWrap
      text: timeline.summary
      color: Local.Palette.foreground
      font.family: Local.Palette.fontFamily
      font.pixelSize: Style.font.body
    }

    Item {
      width: parent.width
      height: Style.space(84)
      opacity: timeline.active ? 1 : 0.3

      Text {
        visible: timeline.nowFraction >= 0
        textFormat: Text.PlainText
        x: Math.max(0, Math.min(parent.width - width, timeline.nowFraction * parent.width - width / 2))
        anchors.top: parent.top
        text: "now"
        color: Local.Palette.foreground
        font.family: Local.Palette.fontFamily
        font.pixelSize: Style.font.caption
      }

      Rectangle {
        id: bar
        anchors.left: parent.left
        anchors.right: parent.right
        y: Style.space(20)
        height: Style.space(40)
        radius: Local.Palette.cardRadius
        gradient: Gradient {
          orientation: Gradient.Horizontal
          GradientStop { position: 0.0; color: timeline.tint(timeline.startKelvin) }
          GradientStop { position: timeline.gradual ? timeline.rampFraction : 0.5; color: timeline.tint(timeline.gradual ? timeline.deepKelvin : timeline.startKelvin) }
          GradientStop { position: 1.0; color: timeline.tint(timeline.gradual ? timeline.deepKelvin : timeline.startKelvin) }
        }

        Text {
          textFormat: Text.PlainText
          anchors.left: parent.left
          anchors.leftMargin: Style.space(12)
          anchors.verticalCenter: parent.verticalCenter
          text: ""
          color: Qt.rgba(0, 0, 0, 0.6)
          font.pixelSize: Style.font.body
        }

        Text {
          textFormat: Text.PlainText
          anchors.right: parent.right
          anchors.rightMargin: Style.space(12)
          anchors.verticalCenter: parent.verticalCenter
          text: ""
          color: Qt.rgba(0, 0, 0, 0.6)
          font.pixelSize: Style.font.body
        }

        Rectangle {
          visible: timeline.nowFraction >= 0
          x: timeline.nowFraction * bar.width - width / 2
          width: Style.space(3)
          height: bar.height + Style.space(8)
          anchors.verticalCenter: parent.verticalCenter
          radius: width / 2
          color: Local.Palette.foreground
        }
      }

      Text {
        id: onLabel
        textFormat: Text.PlainText
        anchors.left: parent.left
        anchors.top: bar.bottom
        anchors.topMargin: Style.space(6)
        text: timeline.on + "\n" + Warmth.name(timeline.startKelvin)
        color: Local.Palette.muted
        font.family: Local.Palette.fontFamily
        font.pixelSize: Style.font.caption
      }

      Text {
        visible: timeline.gradual && timeline.rampFraction < 0.85
        textFormat: Text.PlainText
        x: Math.max(onLabel.width + Style.space(12), timeline.rampFraction * parent.width - width / 2)
        anchors.top: bar.bottom
        anchors.topMargin: Style.space(6)
        horizontalAlignment: Text.AlignHCenter
        text: Warmth.clock(timeline.onMin + Math.min(timeline.ramp, timeline.window - 10)) + "\n" + Warmth.name(timeline.deepKelvin)
        color: Local.Palette.muted
        font.family: Local.Palette.fontFamily
        font.pixelSize: Style.font.caption
      }

      Text {
        textFormat: Text.PlainText
        anchors.right: parent.right
        anchors.top: bar.bottom
        anchors.topMargin: Style.space(6)
        horizontalAlignment: Text.AlignRight
        text: timeline.off + "\nNormal"
        color: Local.Palette.muted
        font.family: Local.Palette.fontFamily
        font.pixelSize: Style.font.caption
      }
    }
  }
}
