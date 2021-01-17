// Copyright 2018-2020 Camilo Higuita <milo.h@aol.com>
// Copyright 2018-2020 Nitrux Latinoamericana S.C.
//
// SPDX-License-Identifier: GPL-3.0-or-later

import QtQuick 2.13
import QtQuick.Controls 2.13
import QtQuick.Layouts 1.3

import Qt.labs.settings 1.0
import QtQml.Models 2.3

import org.kde.kirigami 2.14 as Kirigami
import org.kde.mauikit 1.3 as Maui

import org.maui.index 1.0 as Index

import "widgets"
import "widgets/views"
import "widgets/previewer"

Maui.ApplicationWindow
{
    id: root
    title: currentTab ? currentTab.title : ""

    readonly property url currentPath : currentBrowser ?  currentBrowser.currentPath : ""
    readonly property Maui.FileBrowser currentBrowser : currentTab && currentTab.browser ? currentTab.browser : null

    property alias dialog : dialogLoader.item
    property alias selectionBar : _browserView.selectionBar
    property alias openWithDialog : _openWithDialog
    property alias tagsDialog : _tagsDialog
    property alias currentTabIndex : _browserView.currentTabIndex
    property alias currentTab : _browserView.currentTab
    property alias viewTypeGroup : _viewTypeGroup
    property alias appSettings : settings

    property bool selectionMode: false

    Settings
    {
        id: settings
        category: "Browser"
        property bool showHiddenFiles: false
        property bool showThumbnails: true
        property bool singleClick : Kirigami.Settings.isMobile ? true : Maui.Handy.singleClick
        property bool previewFiles : Kirigami.Settings.isMobile
        property bool restoreSession:  false
        property bool supportSplit : !Kirigami.Settings.isMobile

        property int viewType : Maui.FMList.LIST_VIEW
        property int listSize : 1 // s-m-x-xl
        property int gridSize : 1 // s-m-x-xl

        property var lastSession : [[({'path': Maui.FM.homePath(), 'viewType': 1})]]
        property int lastTabIndex : 0
    }

    Settings
    {
        id: sortSettings
        category: "Sorting"
        property bool foldersFirst: true
        property int sortBy:  Maui.FMList.MODIFIED
        property int sortOrder : Qt.AscendingOrder
        property bool group : false
        property bool globalSorting: Kirigami.Settings.isMobile
    }

    onCurrentPathChanged:
    {
        syncSidebar(currentBrowser.currentPath)
    }

    onClosing:
    {
        close.accepted = !settings.restoreSession
        var tabs = []

        for(var i = 0; i <tabsObjectModel.count; i ++)
        {
            const tab = tabsObjectModel.get(i)
            var tabPaths = []

            for(var j = 0; j < tab.model.count; j++)
            {
                const browser = tab.model.get(j)
                const tabMap = {'path': browser.currentPath, 'viewType': browser.settings.viewType}
                tabPaths.push(tabMap)

                console.log("saving tabs", browser.currentPath, browser.settings.viewType)

            }

            tabs.push(tabPaths)
        }

        console.log("saving tabs", tabs.length)

        settings.lastSession = tabs
        settings.lastTabIndex = currentTabIndex

        close.accepted = true
    }

    floatingHeader: false
    flickable: currentBrowser.flickable
    mainMenu: [Action
        {
            text: i18n("Settings")
            icon.name: "settings-configure"
            onTriggered: openConfigDialog()
        }]

    Maui.TagsDialog
    {
        id: _tagsDialog
        taglist.strict: false

        onTagsReady:
        {
            composerList.updateToUrls(tags)
        }
    }

    Maui.OpenWithDialog {id: _openWithDialog}

    Component
    {
        id: _configDialogComponent
        SettingsDialog {}
    }

    Component
    {
        id: _extractDialogComponent

        Maui.Dialog
        {
            id: _extractDialog
            title: i18n("Extract")
            message: i18n("Extract the content of the compressed file into a new or existing subdirectory or inside the current directory.")
            entryField: true
            page.margins: Maui.Style.space.big

            onAccepted:
            {
                _compressedFile.extract(currentPath, textEntry.text)
                _extractDialog.close()
            }
        }
    }

    Component
    {
        id: _compressDialogComponent

        Maui.FileListingDialog
        {
            id: _compressDialog

            title: i18np("Compress %1 file", "Compress %1 files", urls.length)
            message: i18n("Compress selected files into a new file.")

            textEntry.placeholderText: i18n("Archive name...")
            entryField: true

            function clear()
            {
                textEntry.clear()
                compressType.currentIndex = 0
                urls = []
                _showCompressedFiles.checked = false
            }

            Maui.ToolActions
            {
                id: compressType
                autoExclusive: true
                expanded: true
                currentIndex: 0

                Action
                {
                    text: ".ZIP"
                }

                Action
                {
                    text: ".TAR"
                }

                Action
                {
                    text: ".7ZIP"
                }

                Action
                {
                    text: ".AR"
                }
            }

            onRejected:
            {
                //                _compressDialog.clear()
                _compressDialog.close()
            }

            onAccepted:
            {
                var error = _compressedFile.compress(urls, currentPath, textEntry.text, compressType.currentIndex)

                if(error)
                {
                    root.notify("","Compress Error", "Some error occurs. Maybe current user does not have permission for writing in this directory.")
                }
                else
                {
                    _compressDialog.close()
                }

            }
        }
    }


    Index.CompressedFile
    {
        id: _compressedFile
    }

    headBar.visible: false
    headBar.implicitHeight: 0

    Loader
    {
        id: dialogLoader
    }

    sideBar: PlacesSideBar
    {
        id: placesSidebar
        visible: _stackView.depth === 1
    }

    ObjectModel { id: tabsObjectModel }

    Component
    {
        id: _homeViewComponent
        HomeView { }
    }

    StackView
    {
        id: _stackView
        anchors.fill: parent
        initialItem: Maui.Page
        {
            title: currentBrowser.title

            headBar.leftContent: [

                Button
                {
                    text: i18n("Previous")
                    icon.name: "go-previous"
                    onClicked : currentBrowser.goBack()
                    flat: true
                }
            ]

            headBar.rightContent: [
                ToolButton
                {
                    icon.name: "folder-new"
                    onClicked : currentBrowser.newItem()
                    flat: true
                },

                Maui.ToolButtonMenu
                {
                    id: _viewTypeGroup
//                    flat: true
                    icon.name: "view-list-icons"
//                    Binding on currentIndex
//                    {
//                        value: currentBrowser ? currentBrowser.settings.viewType : -1
//                        //                    restoreMode: Binding.RestoreBinding
//                        delayed: true
//                    }

                    //                    display: ToolButton.TextBesideIcon
//                    onCurrentIndexChanged:
//                    {
//                        if(currentBrowser)
//                        currentBrowser.settings.viewType = currentIndex
//                        settings.viewType = currentIndex
//                    }

                    MenuItem
                    {
                        autoExclusive: true
                        checkable: true
                        checked: currentBrowser.settings.viewType === 0
                        icon.name: "view-list-icons"
                        text: i18n("Grid")
                        onTriggered:  currentBrowser.settings.viewType = 0
                    }

                    MenuItem
                    {
                        autoExclusive: true
                        checkable: true
                        checked: currentBrowser.settings.viewType === 1
                        icon.name: "view-list-details"
                        text: i18n("List")
                        onTriggered:  currentBrowser.settings.viewType = 1
                    }

                    MenuItem
                    {
                        autoExclusive: true
                        checkable: true
                        checked: currentBrowser.settings.viewType === 2
                        icon.name: "view-file-columns"
                        text: i18n("Columns")
                        onTriggered:  currentBrowser.settings.viewType = 2
                    }

                    MenuSeparator {}

                    MenuItem
                    {
                        text: i18n("Show Folders First")
                        checked: currentBrowser.settings.foldersFirst
                        checkable: true
                        onTriggered: currentBrowser.settings.foldersFirst = !currentBrowser.settings.foldersFirst
                    }

                    MenuSeparator {}

                    MenuItem
                    {
                        text: i18n("Type")
                        checked: currentBrowser.settings.sortBy === Maui.FMList.MIME
                        checkable: true
                        onTriggered: currentBrowser.settings.sortBy = Maui.FMList.MIME
                        autoExclusive: true
                    }

                    MenuItem
                    {
                        text: i18n("Date")
                        checked:currentBrowser.settings.sortBy === Maui.FMList.DATE
                        checkable: true
                        onTriggered: currentBrowser.settings.sortBy = Maui.FMList.DATE
                        autoExclusive: true
                    }

                    MenuItem
                    {
                        text: i18n("Modified")
                        checkable: true
                        checked: currentBrowser.settings.sortBy === Maui.FMList.MODIFIED
                        onTriggered: currentBrowser.settings.sortBy = Maui.FMList.MODIFIED
                        autoExclusive: true
                    }

                    MenuItem
                    {
                        text: i18n("Size")
                        checkable: true
                        checked: currentBrowser.settings.sortBy === Maui.FMList.SIZE
                        onTriggered: currentBrowser.settings.sortBy = Maui.FMList.SIZE
                        autoExclusive: true
                    }

                    MenuItem
                    {
                        text: i18n("Name")
                        checkable: true
                        checked: currentBrowser.settings.sortBy === Maui.FMList.LABEL
                        onTriggered: currentBrowser.settings.sortBy = Maui.FMList.LABEL
                        autoExclusive: true
                    }

                    MenuSeparator{}

                    MenuItem
                    {
                        id: groupAction
                        text: i18n("Group")
                        checkable: true
                        checked: currentBrowser.settings.group
                        onTriggered:
                        {
                            currentBrowser.settings.group = !currentBrowser.settings.group
                        }
                    }
                },


                Button
                {
                    text: i18n("Select")
                    flat: true
                    onClicked: root.selectionMode = !root.selectionMode
                }

            ]
            BrowserView
            {
                id: _browserView
                anchors.fill: parent

            }
        }
    }

    Connections
    {
        target: inx
        function onOpenPath(paths)
        {
            for(var index in paths)
                root.openTab(paths[index])
        }
    }

    Component.onCompleted:
    {
        const tabs = settings.lastSession

        if(settings.restoreSession && tabs.length)
        {
            console.log("restore", tabs.length)

            for(var i = 0; i < tabs.length; i++ )
            {
                const tab = tabs[i]

                root.openTab(tab[0].path)
                currentBrowser.settings.viewType = tab[0].viewType

                if(tab.length === 2)
                {
                    currentTab.split(tab[1].path, Qt.Horizontal)
                    currentBrowser.settings.viewType = tab[1].viewType
                }
            }

            currentTabIndex = settings.lastTabIndex

        }else
        {
            root.openTab(Maui.FM.homePath())
            currentBrowser.settings.viewType = settings.viewType
        }

    }

    //     onThumbnailsSizeChanged:
    //     {
    //         if(settings.trackChanges && settings.saveDirProps)
    //             Maui.FM.setDirConf(currentPath+"/.directory", "MAUIFM", "IconSize", thumbnailsSize)
    //             else
    //                 Maui.FM.saveSettings("IconSize", thumbnailsSize, "SETTINGS")
    //
    //                 if(browserView.viewType === Maui.FMList.ICON_VIEW)
    //                     browserView.currentView.adaptGrid()
    //     }

    function syncSidebar(path)
    {
        placesSidebar.currentIndex = -1

        for(var i = 0; i < placesSidebar.count; i++)
        {
            if(String(path) === placesSidebar.model.get(i).path)
            {
                placesSidebar.currentIndex = i
                return;
            }
        }
    }

    function toogleSplitView()
    {
        if(currentTab.count == 2)
            currentTab.pop()
        else
            currentTab.split(root.currentPath, Qt.Horizontal)
    }

    function openConfigDialog()
    {
        dialogLoader.sourceComponent = _configDialogComponent
        dialog.open()
    }

    function closeTab(index)
    {
        var item = tabsObjectModel.get(index)
        item.destroy()
        tabsObjectModel.remove(index)
    }

    function openTab(path)
    {
        if(path)
        {
            if(_stackView.depth === 2)
                _stackView.pop(StackView.Immediate)

            const component = Qt.createComponent("qrc:/widgets/views/BrowserLayout.qml");

            if (component.status === Component.Ready)
            {
                const object = component.createObject(tabsObjectModel, {'path': path});
                tabsObjectModel.append(object)
                currentTabIndex = tabsObjectModel.count - 1
            }
        }
    }

    function tagFiles(urls)
    {
        if(urls.length <= 0)
        {
            return
        }
        tagsDialog.composerList.urls = urls
        tagsDialog.open()
    }

    /**
     * For this to work the implementation needs to have passed a selectionBar
     **/
    function openWith(urls)
    {
        if(urls.length <= 0)
        {
            return
        }

        openWithDialog.urls = urls
        openWithDialog.open()
    }

    /**
      *
      **/
    function shareFiles(urls)
    {
        if(urls.length <= 0)
        {
            return
        }

        Maui.Platform.shareFiles(urls)
    }
}
