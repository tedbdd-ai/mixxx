import QtQuick
import "ShelfLogic.mjs" as Logic

// Das Cover einer Platte: das echte Bild aus Mixxx, sonst eine erzeugte Hülle.
Item {
    id: root

    property var rec: null

    onRecChanged: sleeve.requestPaint()
    onWidthChanged: sleeve.requestPaint()

    Canvas {
        id: sleeve

        anchors.fill: parent
        visible: image.status !== Image.Ready

        onPaint: {
            const ctx = getContext("2d");
            ctx.reset();
            if (root.rec)
                Logic.drawSleeve(ctx, root.rec, width);
        }
    }
    Image {
        id: image

        anchors.fill: parent
        asynchronous: true
        fillMode: Image.PreserveAspectCrop
        source: root.rec && root.rec.cover ? root.rec.cover : ""
        sourceSize.height: 512
        sourceSize.width: 512
    }
}
