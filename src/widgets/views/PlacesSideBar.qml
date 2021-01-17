// Copyright 2018-2020 Camilo Higuita <milo.h@aol.com>
// Copyright 2018-2020 Nitrux Latinoamericana S.C.
//
// SPDX-License-Identifier: GPL-3.0-or-later


import QtQuick 2.14
import QtQuick.Controls 2.14
import QtQuick.Layouts 1.3
import org.kde.mauikit 1.2 as Maui
import org.kde.kirigami 2.6 as Kirigami

Maui.SideBar
{
    id: control

    property alias list : placesList

    signal placeClicked (string path)

    padding: 0
    collapsible: true
    collapsed : !root.isWide
    preferredWidth: Math.min(Kirigami.Units.gridUnit * (Maui.Handy.isWindows ?  15 : 11), root.width)

    onPlaceClicked:
    {
        currentBrowser.openFolder(path)
        if(placesSidebar.collapsed)
            placesSidebar.collapse()
    }

    listView.flickable.header: Maui.ToolBar
    {
        background: null
        width: parent.width
        rightContent: ToolButton
        {
            id: _optionsButton
            icon.name: "overflow-menu"
            enabled: root.currentBrowser && root.currentBrowser.currentFMList.pathType !== Maui.FMList.TAGS_PATH && root.currentBrowser.currentFMList.pathType !== Maui.FMList.TRASH_PATH && root.currentBrowser.currentFMList.pathType !== Maui.FMList.APPS_PATH
            onClicked:
            {
                if(currentBrowser.browserMenu.visible)
                    currentBrowser.browserMenu.close()
                else
                    currentBrowser.browserMenu.show(_optionsButton, 0, height)
            }
            checked: currentBrowser.browserMenu.visible
            checkable: false
        }

        farLeftContent:  MouseArea
        {
            id: _handle
            visible: placesSidebar.position == 0 || placesSidebar.collapsed
            Layout.preferredWidth: Maui.Style.iconSizes.big
            Layout.fillHeight: true
            Layout.alignment: Qt.AlignBottom
            hoverEnabled: true
            preventStealing: true
            propagateComposedEvents: false

            ToolTip.delay: 1000
            ToolTip.timeout: 5000
            ToolTip.visible: _handle.containsMouse || _handle.containsPress
            ToolTip.text: i18n("Toogle SideBar")

            Rectangle
            {
                anchors.centerIn: parent
                radius: 2
                height: 18
                width: 16

                color: _handle.containsMouse || _handle.containsPress  ?  Kirigami.Theme.highlightColor : Kirigami.Theme.textColor
                border.color: Qt.darker(color, 1.2)

                Rectangle
                {
                    radius: 1
                    height: 10
                    width: 3

                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.margins: 4

                    color: _handle.containsMouse || _handle.containsPress ?  Kirigami.Theme.highlightedTextColor : Kirigami.Theme.backgroundColor
                }
            }

            onClicked: placesSidebar.visible = !placesSidebar.visible
        }


    }

    model: Maui.BaseModel
    {
        list: Maui.PlacesList
        {
            id: placesList

            groups: [
                Maui.FMList.QUICK_PATH,
                Maui.FMList.PLACES_PATH,
                Maui.FMList.REMOTE_PATH,
                Maui.FMList.REMOVABLE_PATH,
                Maui.FMList.DRIVES_PATH]

            onBookmarksChanged:
            {
                syncSidebar(currentPath)
            }
        }
    }

    delegate: Maui.ListDelegate
    {
        width: ListView.view.width
        implicitHeight: Maui.Style.rowHeight * 1.2
        iconSize: Maui.Style.iconSizes.small
        label: model.label
        count: model.count > 0 ? model.count : ""
        iconName: model.icon +  (Qt.platform.os == "android" || Qt.platform.os == "osx" ? ("-sidebar") : "")
        iconVisible: true

        onClicked:
        {
            control.currentIndex = index
            placesList.clearBadgeCount(index)

            placeClicked(model.path)
            if(control.collapsed)
                control.close()
        }

        onRightClicked:
        {
            control.currentIndex = index
            _menu.popup()
        }

        onPressAndHold:
        {
            control.currentIndex = index
            _menu.popup()
        }
    }

    section.property: "type"
    section.criteria: ViewSection.FullString
    section.delegate: Maui.LabelDelegate
    {
        id: delegate
        width: control.width
        label: section
        labelTxt.font.pointSize: 16
        labelTxt.font.bold: true
        isSection: true
        height: Maui.Style.toolBarHeightAlt
    }

    onContentDropped:
    {
        placesList.addPlace(drop.text)
    }

    Menu
    {
        id: _menu

        MenuItem
        {
            text: i18n("Open in new tab")
            icon.name: "tab-new"
            onTriggered: openTab(control.model.get(placesSidebar.currentIndex).path)
        }

        MenuItem
        {
            visible: root.currentTab.count === 1 && settings.supportSplit
            text: i18n("Open in split view")
            icon.name: "view-split-left-right"
            onTriggered: currentTab.split(control.model.get(placesSidebar.currentIndex).path, Qt.Horizontal)
        }

        MenuSeparator{}

        MenuItem
        {
            text: i18n("Remove")
            Kirigami.Theme.textColor: Kirigami.Theme.negativeTextColor
            onTriggered: list.removePlace(control.currentIndex)
        }
    }
}
