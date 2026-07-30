import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.Mpris
import qs.Commons
import qs.Ui

Panel {
  id: root
  moduleName: "m4teo.omaspotify"
  ipcTarget: "m4teo.omaspotify"

  property var player: {
    for (var i = 0; i < Mpris.players.values.length; i++) {
      var p = Mpris.players.values[i]
      if (p.identity === "Spotify" || p.desktopEntry === "spotify") return p
    }
    return null
  }

  property bool playing: player && player.playbackState === MprisPlaybackState.Playing
  property real progress: player && player.length > 0 ? player.position / player.length : 0

  readonly property string artUrl: player ? (player.artUrl || "") : ""
  readonly property string artistName: player ? (player.trackArtists && player.trackArtists.length > 0 ? player.trackArtists[0] : "") : ""
  readonly property string trackTitle: player ? (player.trackTitle || "") : ""

  readonly property color contentForeground: bar ? bar.foreground : Color.foreground
  readonly property string contentFontFamily: bar ? bar.fontFamily : Style.font.family

  implicitWidth: button.implicitWidth
  implicitHeight: button.implicitHeight

  Timer {
    interval: 1000
    running: root.playing
    repeat: true
    onTriggered: if (root.player) root.player.positionChanged()
  }

  BarIconButton {
    id: button
    anchors.fill: parent
    bar: root.bar
    text: "\uf1bc"
    active: root.playing

    onPressed: function(b) {
      if (b === Qt.MiddleButton && root.player) {
        root.player.togglePlaying()
      } else {
        root.toggle()
      }
    }
  }

  KeyboardPanel {
    id: panel
    anchorItem: button
    owner: root
    bar: root.bar
    open: root.opened
    centerOnBar: true
    focusTarget: keyCatcher
    contentWidth: panel.fittedContentWidth(Style.space(340))
    contentHeight: panel.fittedContentHeight(contentColumn.implicitHeight + Style.space(24))

    PanelKeyCatcher {
      id: keyCatcher
      anchors.fill: parent

      onMoveRequested: function(dx, dy) {
        if (dx > 0 && root.player && root.player.canGoNext) root.player.next()
        else if (dx < 0 && root.player && root.player.canGoPrevious) root.player.previous()
      }

      onActivateRequested: {
        if (root.player) root.player.togglePlaying()
      }

      onCloseRequested: root.close()

      onTabRequested: function(direction) {
        root.switchPanel(direction)
      }

      onTextKey: function(t) {
        if (t === " " && root.player) root.player.togglePlaying()
        else if (t === "n" && root.player && root.player.canGoNext) root.player.next()
        else if (t === "p" && root.player && root.player.canGoPrevious) root.player.previous()
      }

      Column {
        id: contentColumn
        width: parent.width - Style.space(24)
        anchors.horizontalCenter: parent.horizontalCenter
        spacing: Style.space(12)

        Item {
          width: parent.width
          height: root.player ? artRect.height : noPlayerLabel.height

          Rectangle {
            id: artRect
            visible: root.player !== null
            anchors.horizontalCenter: parent.horizontalCenter
            width: parent.width
            height: width
            radius: Style.cornerRadius
            color: Color.menu.border
            clip: true

            Image {
              anchors.fill: parent
              visible: root.artUrl.length > 0
              source: root.artUrl
              fillMode: Image.PreserveAspectCrop
              asynchronous: true
            }

            Rectangle {
              anchors.fill: parent
              visible: root.artUrl.length === 0
              color: Color.menu.border

              Text {
                anchors.centerIn: parent
                text: "\uf1bc"
                color: Color.accent
                opacity: 0.5
                font.family: root.contentFontFamily
                font.pixelSize: 48
              }
            }
          }

          Column {
            id: noPlayerLabel
            visible: root.player === null
            anchors.centerIn: parent
            spacing: Style.space(6)

            Text {
              anchors.horizontalCenter: parent.horizontalCenter
              text: "\uf1bc"
              color: root.contentForeground
              opacity: 0.35
              font.family: root.contentFontFamily
              font.pixelSize: 32
            }

            Text {
              anchors.horizontalCenter: parent.horizontalCenter
              text: "Spotify no está reproduciendo"
              color: root.contentForeground
              opacity: 0.6
              font.family: root.contentFontFamily
              font.pixelSize: Style.font.bodySmall
            }
          }
        }

        Column {
          visible: root.player !== null
          width: parent.width
          spacing: Style.space(2)

          Text {
            width: parent.width
            text: root.trackTitle || "—"
            color: root.contentForeground
            font.family: root.contentFontFamily
            font.pixelSize: Style.font.title
            font.bold: true
            elide: Text.ElideRight
            maximumLineCount: 1
          }

          Text {
            width: parent.width
            text: root.artistName
            color: root.contentForeground
            opacity: 0.65
            font.family: root.contentFontFamily
            font.pixelSize: Style.font.bodySmall
            elide: Text.ElideRight
            maximumLineCount: 1
          }
        }

        Column {
          visible: root.player !== null
          width: parent.width
          spacing: Style.space(4)

          Rectangle {
            id: trackBar
            width: parent.width
            height: 5
            radius: Math.round(height / 2)
            color: Qt.rgba(root.contentForeground.r, root.contentForeground.g, root.contentForeground.b, 0.12)

            Rectangle {
              width: trackBar.width * root.progress
              height: parent.height
              radius: parent.radius
              color: Color.accent

              Behavior on width {
                NumberAnimation { duration: 160; easing.type: Easing.OutCubic }
              }
            }

            MouseArea {
              anchors.fill: parent
              anchors.margins: -6
              cursorShape: Qt.PointingHandCursor

              onClicked: function(mouse) {
                if (!root.player || root.player.length <= 0) return
                var ratio = Math.max(0, Math.min(1, mouse.x / trackBar.width))
                root.player.position = ratio * root.player.length
              }
            }
          }

          RowLayout {
            width: parent.width
            spacing: 0

            Text {
              text: root.player ? formatTime(root.player.position) : "0:00"
              color: root.contentForeground
              opacity: 0.55
              font.family: root.contentFontFamily
              font.pixelSize: Style.font.caption
            }

            Item { Layout.fillWidth: true }

            Text {
              text: root.player ? formatTime(root.player.length) : "0:00"
              color: root.contentForeground
              opacity: 0.55
              font.family: root.contentFontFamily
              font.pixelSize: Style.font.caption
            }
          }
        }

        RowLayout {
          visible: root.player !== null
          width: parent.width
          spacing: Style.space(16)
          Layout.alignment: Qt.AlignHCenter

          Item { Layout.fillWidth: true }

          PanelActionButton {
            iconText: "\uf048"
            tooltipText: "Previous"
            foreground: root.contentForeground
            fontFamily: root.contentFontFamily
            enabled: root.player && root.player.canGoPrevious
            onClicked: if (root.player) root.player.previous()
          }

          PanelActionButton {
            iconText: root.playing ? "\uf04c" : "\uf04b"
            tooltipText: root.playing ? "Pause" : "Play"
            foreground: root.contentForeground
            fontFamily: root.contentFontFamily
            enabled: root.player && root.player.canControl
            onClicked: if (root.player) root.player.togglePlaying()
          }

          PanelActionButton {
            iconText: "\uf051"
            tooltipText: "Next"
            foreground: root.contentForeground
            fontFamily: root.contentFontFamily
            enabled: root.player && root.player.canGoNext
            onClicked: if (root.player) root.player.next()
          }

          Item { Layout.fillWidth: true }
        }

        Item {
          visible: root.player !== null
          width: parent.width
          height: Style.space(4)
        }
      }
    }
  }

  function formatTime(us) {
    if (!us || us <= 0) return "0:00"
    var totalSec = Math.floor(us / 1000000)
    var min = Math.floor(totalSec / 60)
    var sec = totalSec % 60
    return min + ":" + (sec < 10 ? "0" : "") + sec
  }
}
