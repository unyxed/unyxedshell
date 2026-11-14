import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects
import Quickshell
import Quickshell.Io

MouseArea {
    id: root
    property int columns: Config.options.wallpaperSelector.columns || 4
    property real previewCellAspectRatio: 4 / 3
    property bool useDarkMode: Appearance.m3colors.darkmode
    property bool shown: true
    property bool showControls: false
    readonly property bool toolbarVisible: root.showControls || Config.options.wallpaperSelector.showSearchbar
    readonly property string targetDesktopId: Wallpapers.selectorDesktopId
    readonly property string targetDesktopWallpaper: Wallpapers.desktopWallpaperFor(root.targetDesktopId)
    readonly property string currentTargetPath: root.targetDesktopWallpaper || Config.options.background.wallpaperPath
    readonly property bool targetShown: root.targetDesktopId === Wallpapers.currentDesktopId
        || (root.targetDesktopId === "" && Wallpapers.currentDesktopWallpaper === "")

    property var quickDirs: [
        {
            icon: "home",
            name: "Home",
            path: Directories.home,
            visible: Config.options.wallpaperSelector.showHomePath
        },
        {
            icon: "docs",
            name: "Documents",
            path: Directories.documents,
            visible: true
        },
        {
            icon: "download",
            name: "Downloads",
            path: Directories.downloads,
            visible: true
        },
        {
            icon: "image",
            name: "Pictures",
            path: Directories.pictures,
            visible: true
        },
        {
            icon: "movie",
            name: "Videos",
            path: Directories.videos,
            visible: true
        },
        {
            icon: "",
            name: "---",
            path: "INTENTIONALLY_INVALID_DIR",
            visible: true
        },
        {
            icon: "wallpaper",
            name: "Wallpapers",
            path: `${Directories.pictures}/Wallpapers`,
            visible: true
        },
        ...(Config.options.wallpaperSelector.userPath?.trim().length > 0 ? [
                                                                               {
                                                                                   icon: "folder_open",
                                                                                   name: Config.options.wallpaperSelector.userPath.split(
                                                                                             "/").filter(s
                                                                                                         => s.length
                                                                                                            > 0).pop()
                                                                                         || "Custom",
                                                                                   path: Config.options.wallpaperSelector.userPath,
                                                                                   visible: true
                                                                               }
                                                                           ] : []),]

    function updateThumbnails() {
        const totalImageMargin = (Appearance.sizes.wallpaperSelectorItemMargins
                                  + Appearance.sizes.wallpaperSelectorItemPadding) * 2;
        const thumbnailSizeName = Images.thumbnailSizeNameForDimensions(grid.cellWidth - totalImageMargin,
                                                                        grid.cellHeight - totalImageMargin);
        Wallpapers.generateThumbnail(thumbnailSizeName);
    }

    Connections {
        target: Wallpapers
        function onDirectoryChanged() {
            Wallpapers.stopPreview();
            if (root.shown)
                root.updateThumbnails();
        }
    }

    onShownChanged: {
        if (root.shown)
            root.updateThumbnails();
    }

    function handleFilePasting(event) {
        const currentClipboardEntry = Cliphist.entries[0];
        if (/^\d+\tfile:\/\/\S+/.test(currentClipboardEntry)) {
            const url = StringUtils.cleanCliphistEntry(currentClipboardEntry);
            Wallpapers.setDirectory(FileUtils.trimFileProtocol(decodeURIComponent(url)));
            event.accepted = true;
        } else {
            event.accepted = false; // No image, let text pasting proceed
        }
    }

    function selectWallpaperPath(filePath, isDirectory) {
        if (!filePath || filePath.length === 0)
            return;
        previewTimer.stop();
        if (!isDirectory && GlobalStates.wallpaperSelectorTarget === "lockWall") {
            Wallpapers.setLockWallpaper(filePath);
            filterField.text = "";
            GlobalStates.wallpaperSelectorOpen = false;
            return;
        }
        Wallpapers.select(filePath, isDirectory, root.useDarkMode);
        if (!isDirectory)
            Wallpapers.stopPreview();
        filterField.text = "";
    }

    function queuePreview() {
        if (!Config.options.background.enableWallpaperPreview || GlobalStates.wallpaperSelectorTarget === "lockWall"
            || !root.targetShown)
            return;
        previewTimer.restart();
    }

    function previewCurrent() {
        if (!GlobalStates.wallpaperSelectorOpen)
            return;
        const model = Wallpapers.folderModel;
        const index = grid.currentIndex;
        if (index < 0 || index >= model.count || model.get(index, "fileIsDir"))
            return;
        Wallpapers.startPreview(model.get(index, "filePath"));
    }

    Timer {
        id: previewTimer
        interval: 300
        onTriggered: root.previewCurrent()
    }

    acceptedButtons: Qt.BackButton | Qt.ForwardButton
    onPressed: event => {
        if (event.button === Qt.BackButton) {
            Wallpapers.navigateBack();
        } else if (event.button === Qt.ForwardButton) {
            Wallpapers.navigateForward();
        }
    }

    Keys.onPressed: event => {
        if (event.key === Qt.Key_Escape) {
            GlobalStates.wallpaperSelectorOpen = false;
            event.accepted = true;
        } else if ((event.modifiers & Qt.ControlModifier) && event.key
                   === Qt.Key_V) {

            root.handleFilePasting(event);
        } else if ((event.modifiers & Qt.ControlModifier) && event.key === Qt.Key_F) {
            if (Config.options.wallpaperSelector.showSearchbar) {
                Config.options.wallpaperSelector.showSearchbar = false;
                root.showControls = false;
            } else {
                root.showControls = !root.showControls;
            }
            event.accepted = true;
        } else if (event.modifiers & Qt.AltModifier && event.key === Qt.Key_Up) {
            Wallpapers.navigateUp();
            event.accepted = true;
        } else if (event.modifiers & Qt.AltModifier && event.key === Qt.Key_Left) {
            Wallpapers.navigateBack();
            event.accepted = true;
        } else if (event.modifiers & Qt.AltModifier && event.key === Qt.Key_Right) {
            Wallpapers.navigateForward();
            event.accepted = true;
        } else if (event.key === Qt.Key_Left) {
            grid.moveSelection(-1);
            event.accepted = true;
        } else if (event.key === Qt.Key_Right) {
            grid.moveSelection(1);
            event.accepted = true;
        } else if (event.key === Qt.Key_Up) {
            grid.moveSelection(-grid.columns);
            event.accepted = true;
        } else if (event.key === Qt.Key_Down) {
            grid.moveSelection(grid.columns);
            event.accepted = true;
        } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
            grid.activateCurrent();
            event.accepted = true;
        } else if (event.key === Qt.Key_Backspace) {
            if (filterField.text.length > 0) {
                filterField.text = filterField.text.substring(0, filterField.text.length - 1);
            }
            filterField.forceActiveFocus();
            event.accepted = true;
        } else if (event.modifiers & Qt.ControlModifier && event.key === Qt.Key_L) {
            addressBar.focusBreadcrumb();
            event.accepted = true;
        } else if (event.key === Qt.Key_Slash) {
            filterField.forceActiveFocus();
            event.accepted = true;
        } else {
            if (event.text.length > 0) {
                filterField.text += event.text;
                filterField.cursorPosition = filterField.text.length;
                filterField.forceActiveFocus();
            }
            event.accepted = true;
        }
    }

    implicitHeight: mainLayout.implicitHeight
    implicitWidth: mainLayout.implicitWidth

    StyledRectangularShadow {
        target: wallpaperGridBackground
    }
    Rectangle {
        id: wallpaperGridBackground
        anchors {
            fill: parent
            margins: Appearance.sizes.elevationMargin
        }
        focus: true
        border.width: 1
        border.color: Appearance.colors.colLayer0Border
        color: Appearance.colors.colUiBackground
        radius: Appearance.rounding.screenRounding - Appearance.sizes.hyprlandGapsOut + 1

        property int calculatedRows: Math.ceil(grid.count / grid.columns)

        implicitWidth: gridColumnLayout.implicitWidth
        implicitHeight: gridColumnLayout.implicitHeight

        Item {
            anchors {
                fill: parent
                margins: 8
            }
            z: 0

            Rectangle {
                anchors.fill: parent
                radius: wallpaperGridBackground.radius - 4
                color: Appearance.colors.colLayer2
                visible: !Config.options.wallpaperSelector.showBlurBackground
            }

            StyledImage {
                id: wallpaperBgImage
                anchors.fill: parent
                visible: Config.options.wallpaperSelector.showBlurBackground
                fillMode: Image.PreserveAspectCrop
                source: Config.options.wallpaperSelector.showBlurBackground
                        ? Wallpapers.stillPath : ""
                sourceSize: Qt.size(480, 480)
                layer.enabled: true
                layer.effect: OpacityMask {
                    maskSource: Rectangle {
                        width: wallpaperGridBackground.width - 16
                        height: wallpaperGridBackground.height - 16
                        radius: wallpaperGridBackground.radius - 4
                    }
                }
            }

            FastBlur {
                anchors.fill: parent
                z: 0
                visible: Config.options.wallpaperSelector.showBlurBackground
                source: wallpaperBgImage
                radius: 48
                layer.enabled: visible
                layer.effect: OpacityMask {
                    maskSource: Rectangle {
                        width: wallpaperGridBackground.width - 16
                        height: wallpaperGridBackground.height - 16
                        radius: wallpaperGridBackground.radius - 4
                    }
                }
            }
        }

        RowLayout {
            id: mainLayout
            anchors.fill: parent
            spacing: -4
            z: 1

            Rectangle {
                Layout.fillHeight: true
                Layout.margins: 4
                implicitWidth: quickDirColumnLayout.implicitWidth
                implicitHeight: quickDirColumnLayout.implicitHeight
                color: Appearance.colors.colLayer1
                radius: wallpaperGridBackground.radius - Layout.margins

                ColumnLayout {
                    id: quickDirColumnLayout
                    anchors.fill: parent
                    spacing: 0

                    StyledText {
                        Layout.margins: 12
                        font {
                            pixelSize: Appearance.font.pixelSize.normal
                            weight: Font.Medium
                        }
                        text: Translation.tr("Pick a wallpaper")
                    }
                    ListView {
                        // Quick dirs
                        Layout.fillHeight: true
                        Layout.margins: 4
                        implicitWidth: 140
                        clip: true
                        model: root.quickDirs.filter(d => d.visible)
                        delegate: RippleButton {
                            id: quickDirButton
                            required property var modelData
                            anchors {
                                left: parent.left
                                right: parent.right
                            }
                            onClicked: Wallpapers.setDirectory(quickDirButton.modelData.path)
                            enabled: modelData.icon.length > 0
                            toggled: Wallpapers.normalizedPath(Wallpapers.effectiveDirectory) === Wallpapers.normalizedPath(modelData.path)
                            colBackgroundToggled: Appearance.colors.colSecondaryContainer
                            colBackgroundToggledHover: Appearance.colors.colSecondaryContainerHover
                            colRippleToggled: Appearance.colors.colSecondaryContainerActive
                            buttonRadius: height / 2
                            implicitHeight: 38

                            contentItem: RowLayout {
                                MaterialSymbol {
                                    color: quickDirButton.toggled ? Appearance.colors.colOnSecondaryContainer :
                                                                    Appearance.colors.colOnLayer1
                                    opacity: quickDirButton.enabled ? 1 : 0.4
                                    iconSize: Appearance.font.pixelSize.larger
                                    text: quickDirButton.modelData.icon
                                    fill: quickDirButton.toggled ? 1 : 0
                                }
                                StyledText {
                                    Layout.fillWidth: true
                                    horizontalAlignment: Text.AlignLeft
                                    opacity: quickDirButton.enabled ? 1 : 0.4
                                    color: quickDirButton.toggled ? Appearance.colors.colOnSecondaryContainer :
                                                                    Appearance.colors.colOnLayer1
                                    text: Translation.tr(quickDirButton.modelData.name)
                                }
                            }
                        }
                    }
                }
            }

            ColumnLayout {
                id: gridColumnLayout
                Layout.fillWidth: true
                Layout.fillHeight: true

                RowLayout {
                    Layout.margins: 4
                    Layout.fillWidth: true
                    Layout.fillHeight: false
                    spacing: 6

                    AddressBar {
                        id: addressBar
                        Layout.fillWidth: true
                        directory: Wallpapers.effectiveDirectory
                        onNavigateToDirectory: path => {
                            Wallpapers.setDirectory(path.length == 0 ? "/" : path);
                        }
                        radius: wallpaperGridBackground.radius - 4
                    }

                }

                Item {
                    id: gridDisplayRegion
                    Layout.fillWidth: true
                    Layout.fillHeight: true

                    Item {
                        id: localGridArea
                        anchors.fill: parent

                        StyledIndeterminateProgressBar {
                            id: indeterminateProgressBar
                            visible: Wallpapers.thumbnailGenerationRunning && value == 0
                            anchors {
                                bottom: parent.top
                                left: parent.left
                                right: parent.right
                                leftMargin: 4
                                rightMargin: 4
                            }
                        }

                        StyledProgressBar {
                            visible: Wallpapers.thumbnailGenerationRunning && value > 0
                            value: Wallpapers.thumbnailGenerationProgress
                            anchors.fill: indeterminateProgressBar
                        }

                        Item {
                            id: localGridBlurWrapper
                            anchors.fill: parent

                            GridView {
                                id: grid
                                visible: Wallpapers.folderModel.count > 0

                                readonly property int columns: root.columns
                                readonly property int rows: Math.max(1, Math.ceil(count / columns))
                                property int currentIndex: 0

                                anchors.fill: parent
                                cellWidth: width / root.columns
                                cellHeight: cellWidth / root.previewCellAspectRatio
                                interactive: true
                                clip: true
                                keyNavigationWraps: true
                                boundsBehavior: Flickable.StopAtBounds
                                bottomMargin: extraOptions.implicitHeight
                                ScrollBar.vertical: StyledScrollBar {}

                                Component.onCompleted: {
                                    root.updateThumbnails();
                                }

                                function moveSelection(delta) {
                                    currentIndex = Math.max(0, Math.min(grid.model.count - 1, currentIndex
                                                                        + delta));
                                    positionViewAtIndex(currentIndex, GridView.Contain);
                                    root.queuePreview();
                                }

                                function activateCurrent() {
                                    const filePath = grid.model.get(currentIndex, "filePath");
                                    const isDirectory = grid.model.get(currentIndex, "fileIsDir");
                                    root.selectWallpaperPath(filePath, isDirectory);
                                }

                                model: Wallpapers.folderModel
                                onModelChanged: currentIndex = 0
                                delegate: WallpaperDirectoryItem {
                                    required property var modelData
                                    required property int index
                                    fileModelData: modelData
                                    width: grid.cellWidth
                                    height: grid.cellHeight
                                    colBackground: (index === grid?.currentIndex || containsMouse)
                                                   ? Appearance.colors.colPrimary : (fileModelData.filePath
                                                                                     === root.currentTargetPath)
                                                     ? Appearance.colors.colSecondaryContainer :
                                                       ColorUtils.transparentize(
                                                           Appearance.colors.colPrimaryContainer)
                                    colText: (index === grid.currentIndex || containsMouse)
                                             ? Appearance.colors.colOnPrimary : (fileModelData.filePath
                                                                                 === root.currentTargetPath)
                                               ? Appearance.colors.colOnSecondaryContainer :
                                                 Appearance.colors.colOnLayer0

                                    onEntered: {
                                        grid.currentIndex = index;
                                        root.queuePreview();
                                    }

                                    onActivated: {
                                        root.selectWallpaperPath(fileModelData.filePath,
                                                                 fileModelData.fileIsDir);
                                    }
                                }

                                layer.enabled: !Platform.isWindows
                                layer.effect: OpacityMask {
                                    maskSource: Rectangle {
                                        width: gridDisplayRegion.width
                                        height: gridDisplayRegion.height
                                        radius: wallpaperGridBackground.radius
                                    }
                                }
                            }
                        }

                    }

                    Row {
                        id: extraOptions
                        anchors {
                            bottom: parent.bottom
                            horizontalCenter: parent.horizontalCenter
                            bottomMargin: 8
                        }
                        spacing: 6

                        Toolbar {
                            visible: root.targetDesktopId !== ""

                            MaterialSymbol {
                                Layout.leftMargin: 8
                                text: "desktop_windows"
                                iconSize: 20
                                color: Appearance.colors.colOnSurfaceVariant
                            }

                            StyledText {
                                Layout.rightMargin: root.targetDesktopWallpaper !== "" ? 0 : 8
                                text: Translation.tr("Only for %1").arg(Wallpapers.desktopLabel(root.targetDesktopId))
                                font.pixelSize: Appearance.font.pixelSize.small
                                color: Appearance.colors.colOnSurfaceVariant
                            }

                            IconToolbarButton {
                                implicitWidth: height
                                visible: root.targetDesktopWallpaper !== ""
                                text: "layers_clear"
                                onClicked: Wallpapers.clearDesktopWallpaper(root.targetDesktopId)
                                StyledToolTip {
                                    text: Translation.tr("Use the main wallpaper on this desktop")
                                }
                            }
                        }

                        Toolbar {

                            IconToolbarButton {
                                implicitWidth: height
                                onClicked: {
                                    Wallpapers.openFallbackPicker(root.useDarkMode);
                                    GlobalStates.wallpaperSelectorOpen = false;
                                }
                                altAction: () => {
                                    Wallpapers.openFallbackPicker(root.useDarkMode);
                                    GlobalStates.wallpaperSelectorOpen = false;
                                    Config.options.wallpaperSelector.useSystemFileDialog = true;
                                }
                                text: "open_in_new"
                                StyledToolTip {
                                    text: Translation.tr(
                                              "Use the system file picker instead\nRight-click to make this the default behavior")
                                }
                            }

                            IconToolbarButton {
                                implicitWidth: height
                                onClicked: {
                                    Wallpapers.randomFromCurrentFolder();
                                }
                                text: "ifl"
                                StyledToolTip {
                                    text: Translation.tr("Pick random from this folder")
                                }
                            }

                            IconToolbarButton {
                                implicitWidth: height
                                onClicked: root.useDarkMode = !root.useDarkMode
                                text: root.useDarkMode ? "dark_mode" : "light_mode"
                                StyledToolTip {
                                    text: Translation.tr(
                                              "Click to toggle light/dark mode\n(applied when wallpaper is chosen)")
                                }
                            }

                            StyledComboBox {
                                id: sortCombo
                                implicitWidth: 170
                                buttonIcon: "sort"
                                model: [
                                    {
                                        value: "time",
                                        displayName: Translation.tr("Date added (newest first)")
                                    },
                                    {
                                        value: "time_rev",
                                        displayName: Translation.tr("Date added (oldest first)")
                                    },
                                    {
                                        value: "name",
                                        displayName: Translation.tr("Name (A to Z)")
                                    },
                                    {
                                        value: "name_rev",
                                        displayName: Translation.tr("Name (Z to A)")
                                    },
                                    {
                                        value: "size",
                                        displayName: Translation.tr("Size (largest first)")
                                    },
                                    {
                                        value: "size_rev",
                                        displayName: Translation.tr("Size (smallest first)")
                                    },
                                ]
                                textRole: "displayName"
                                Component.onCompleted: {
                                    const i = model.findIndex(m => m.value === Wallpapers.sortMode);
                                    if (i >= 0)
                                        currentIndex = i;
                                }
                                onCurrentIndexChanged: {
                                    if (currentIndex < 0)
                                        return;
                                    Wallpapers.setSortMode(model[currentIndex].value);
                                }
                                StyledToolTip {
                                    text: Translation.tr("Sort wallpapers")
                                }
                            }

                            ToolbarTextField {
                                id: filterField
                                visible: root.toolbarVisible
                                placeholderText: focus ? Translation.tr("Search wallpapers") : Translation.tr(
                                                             "Hit \"/\" to search")

                                // Style
                                clip: true
                                font.pixelSize: Appearance.font.pixelSize.small

                                // Search
                                onTextChanged: {
                                    Wallpapers.searchQuery = text;
                                }

                                Keys.onPressed: event => {
                                    if ((event.modifiers & Qt.ControlModifier) && event.key
                                            === Qt.Key_V) {

                                        root.handleFilePasting(event);
                                        return;
                                    } else if (text.length !== 0) {
                                        // No filtering, just navigate grid
                                        if (event.key === Qt.Key_Down) {
                                            grid.moveSelection(grid.columns);
                                            event.accepted = true;
                                            return;
                                        }
                                        if (event.key === Qt.Key_Up) {
                                            grid.moveSelection(-grid.columns);
                                            event.accepted = true;
                                            return;
                                        }
                                    }
                                    event.accepted = false;
                                }
                            }
                        }

                        ToolbarPairedFab {
                            iconText: "close"
                            onClicked: GlobalStates.wallpaperSelectorOpen = false
                            StyledToolTip {
                                text: Translation.tr("Cancel wallpaper selection")
                            }
                        }
                    }
                }
            }
        }
    }

    Connections {
        target: GlobalStates
        function onWallpaperSelectorOpenChanged() {
            if (GlobalStates.wallpaperSelectorOpen && monitorIsFocused) {
                filterField.forceActiveFocus();
            } else if (!GlobalStates.wallpaperSelectorOpen) {
                previewTimer.stop();
                Wallpapers.stopPreview();
                GlobalStates.wallpaperSelectorTarget = "wallpaper";
            }
        }
    }

    Connections {
        target: Wallpapers
        function onChanged() {
            if (Config.options.wallpaperSelector.closeAfterSelection)
                GlobalStates.wallpaperSelectorOpen = false;
        }
    }
}
