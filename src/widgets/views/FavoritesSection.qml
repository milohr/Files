// Copyright 2018-2020 Camilo Higuita <milo.h@aol.com>
// Copyright 2018-2020 Slike Latinoamericana S.C.
//
// SPDX-License-Identifier: GPL-3.0-or-later


import QtQuick 2.14
import QtQuick.Controls 2.14
import QtQuick.Layouts 1.3
import org.kde.mauikit 1.3 as Maui
import org.kde.kirigami 2.14 as Kirigami

import TagsList 1.0

ColumnLayout
{
    id: control

    Maui.SectionDropDown
    {
        id: _dropDown
        Layout.fillWidth: true
        label1.text: i18n("Favorite files")

        label2.text: i18n("Your files marked as favorites")
        checked: true
    }

    Maui.GridView
    {
        id: _favsGrid
        Layout.fillWidth: true
        visible: _dropDown.checked
        enableLassoSelection: true

        itemSize: Math.min(width * 0.3, 180)
        itemHeight: 180

        model: Maui.BaseModel
        {
            list: Maui.FMList
            {
                path: "tags:///fav"
            }
        }

        delegate: Item
        {
            property bool isCurrentItem : GridView.isCurrentItem
            width: _favsGrid.cellWidth
            height: _favsGrid.itemHeight

            Maui.GridBrowserDelegate
            {
                anchors.fill: parent
                anchors.margins: Maui.Style.space.medium
                label1.text: model.label
                iconSource: model.icon
                imageSource: model.thumbnail
                template.fillMode: Image.PreserveAspectFit
                iconSizeHint: height * 0.5
                checkable: selectionMode

                onClicked:
                {
                    _previewer.show(_favsGrid.model, index)
                }

                template.content: Label
                {
                    visible: parent.height > 100
                    opacity: 0.5
                    color: Kirigami.Theme.textColor
                    font.pointSize: Maui.Style.fontSizes.tiny
                    horizontalAlignment: Qt.AlignHCenter
                    Layout.fillWidth: true
                    text: model.mime ? (model.mime === "inode/directory" ? (model.count ? model.count + i18n(" items") : "") : Maui.FM.formatSize(model.size)) : ""
                }
            }
        }
    }
}
