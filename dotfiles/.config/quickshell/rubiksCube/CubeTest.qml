import Quickshell
import Quickshell.Wayland
import QtQuick
import QtQuick3D
import QtQuick3D.AssetUtils
import QtQuick3D.Helpers

FloatingWindow {
    id: root
    width: 500
    height: 500
    color: "transparent"

    property quaternion camQuat: Qt.quaternion(1, 0, 0, 0)

    // Animation state
    property bool animating: false
    property var animNodes: []
    property int animFaceAxis: 0
    property bool animPosCW: true
    property var animCubieIndices: []
    property var moveQueue: []
    property real animAngle: 0   // target angle in degrees, stored so onRotationFinished can compute exact quat

    // cubies: array of { node, pos: [x, y, z] }
    property var cubies: []

    // faceAxis: logical axis index for position tracking (0=X, 1=Y, 2=Z)
    // rotAxis: visual quaternion rotation axis
    // quatSignCW: +1 or -1 for CW rotation angle sign
    // posCW: direction for rotatePos matching CW visual rotation
    property var faces: ({
        "U": { faceAxis: 2, axis: 2, val:  1, rotAxis: Qt.vector3d(0,0,1), quatSignCW: -1, posCW: true  },
        "D": { faceAxis: 2, axis: 2, val: -1, rotAxis: Qt.vector3d(0,0,1), quatSignCW:  1, posCW: false },
        "R": { faceAxis: 0, axis: 0, val:  1, rotAxis: Qt.vector3d(1,0,0), quatSignCW: -1, posCW: true  },
        "L": { faceAxis: 0, axis: 0, val: -1, rotAxis: Qt.vector3d(1,0,0), quatSignCW:  1, posCW: false },
        "F": { faceAxis: 1, axis: 1, val:  1, rotAxis: Qt.vector3d(0,1,0), quatSignCW:  1, posCW: true  },
        "B": { faceAxis: 1, axis: 1, val: -1, rotAxis: Qt.vector3d(0,1,0), quatSignCW: -1, posCW: false }
    })

    property var initialPositions: [
        [ 1,-1, 1], [ 0,-1, 1], [-1,-1, 1],
        [ 1, 0, 1], [-1, 0, 1], [-1, 1, 1],
        [ 1, 1, 1], [ 0, 1, 1], [ 0, 0, 1],
        [ 0, 1,-1], [-1, 1,-1], [ 1,-1,-1],
        [ 0,-1,-1], [-1,-1,-1], [ 1, 0,-1],
        [ 1, 0, 0], [ 1, 1,-1], [-1, 0,-1],
        [ 0, 0,-1], [ 0, 1, 0], [-1, 0, 0],
        [ 0,-1, 0], [ 1, 1, 0], [ 1,-1, 0],
        [-1, 1, 0], [-1,-1, 0]
    ]

    function rotatePos(pos, axis, cw) {
        var x = pos[0], y = pos[1], z = pos[2];
        if (axis === 2) return cw ? [ y, -x,  z] : [-y,  x,  z];
        if (axis === 0) return cw ? [ x,  z, -y] : [ x, -z,  y];
        if (axis === 1) return cw ? [ z,  y, -x] : [-z,  y,  x];
        return pos;
    }

    function axisAngleToQuat(ax, ay, az, deg) {
        var r = deg * Math.PI / 360.0;
        var s = Math.sin(r), c = Math.cos(r);
        return Qt.quaternion(c, ax*s, ay*s, az*s);
    }

    function quatMul(a, b) {
        return Qt.quaternion(
            a.scalar*b.scalar - a.x*b.x - a.y*b.y - a.z*b.z,
            a.scalar*b.x + a.x*b.scalar + a.y*b.z - a.z*b.y,
            a.scalar*b.y - a.x*b.z + a.y*b.scalar + a.z*b.x,
            a.scalar*b.z + a.x*b.y - a.y*b.x + a.z*b.scalar
        );
    }

    function snapQuat(q) {
        var targets = [0, 0.5, -0.5, 1, -1, 0.7071067811865476, -0.7071067811865476];
        var v = [q.scalar, q.x, q.y, q.z], s = [];
        for (var i = 0; i < 4; i++) {
            var best = targets[0], bd = 999;
            for (var j = 0; j < targets.length; j++) {
                var d = Math.abs(v[i] - targets[j]);
                if (d < bd) { bd = d; best = targets[j]; }
            }
            s.push(best);
        }
        var len = Math.sqrt(s[0]*s[0]+s[1]*s[1]+s[2]*s[2]+s[3]*s[3]);
        return len < 0.001 ? Qt.quaternion(1,0,0,0)
                           : Qt.quaternion(s[0]/len, s[1]/len, s[2]/len, s[3]/len);
    }

    function executeFaceRotation(face, clockwise) {
        if (animating) {
            moveQueue.push({ face: face, cw: clockwise });
            return;
        }

        var f = faces[face];

        animCubieIndices = [];
        animNodes = [];
        for (var i = 0; i < cubies.length; i++) {
            if (cubies[i].pos[f.axis] === f.val) {
                animCubieIndices.push(i);
                animNodes.push(cubies[i].node);
            }
        }

        animFaceAxis = f.faceAxis;
        animPosCW = clockwise ? f.posCW : !f.posCW;

        // Reparent face cubies to pivot
        for (var i = 0; i < animNodes.length; i++)
            animNodes[i].parent = pivot;

        // Compute rotation angle
        var angle = 90 * (clockwise ? f.quatSignCW : -f.quatSignCW);
        animAngle = angle;

        // Pick the right axis animation
        pivot.eulerRotation = Qt.vector3d(0, 0, 0);
        animating = true;

        if (f.faceAxis === 0) {
            pivotAnimX.from = 0; pivotAnimX.to = angle; pivotAnimX.restart();
        } else if (f.faceAxis === 1) {
            pivotAnimY.from = 0; pivotAnimY.to = angle; pivotAnimY.restart();
        } else {
            pivotAnimZ.from = 0; pivotAnimZ.to = angle; pivotAnimZ.restart();
        }
    }

    function onRotationFinished() {
        // Compute the pivot quaternion directly from the stored axis+angle — do NOT read
        // pivot.rotation, because eulerRotation→rotation sync in QtQuick3D is not
        // guaranteed to be complete when onFinished fires.
        var pivotQuat;
        if (animFaceAxis === 0)      pivotQuat = axisAngleToQuat(1, 0, 0, animAngle);
        else if (animFaceAxis === 1) pivotQuat = axisAngleToQuat(0, 1, 0, animAngle);
        else                         pivotQuat = axisAngleToQuat(0, 0, 1, animAngle);

        // Reparent back to rubik and apply combined rotation
        for (var i = 0; i < animNodes.length; i++) {
            var finalRot = snapQuat(quatMul(pivotQuat, animNodes[i].rotation));
            animNodes[i].parent = rubiksCube.rubikNode;
            animNodes[i].rotation = finalRot;
        }

        // Reset pivot
        pivot.eulerRotation = Qt.vector3d(0, 0, 0);

        // Update position tracking
        var faceAxis = animFaceAxis;
        var newCubies = [];
        for (var i = 0; i < cubies.length; i++)
            newCubies.push({ node: cubies[i].node, pos: cubies[i].pos.slice() });
        for (var i = 0; i < animCubieIndices.length; i++) {
            var idx = animCubieIndices[i];
            newCubies[idx].pos = rotatePos(newCubies[idx].pos, faceAxis, animPosCW);
        }
        cubies = newCubies;

        animating = false;

        if (moveQueue.length > 0) {
            var next = moveQueue.shift();
            executeFaceRotation(next.face, next.cw);
        }
    }

    function quatRotateVec(q, v) {
        var vq = Qt.quaternion(0, v.x, v.y, v.z);
        var qconj = Qt.quaternion(q.scalar, -q.x, -q.y, -q.z);
        var r = quatMul(quatMul(q, vq), qconj);
        return Qt.vector3d(r.x, r.y, r.z);
    }

    // Resolve a viewer-relative face name to the actual cube face given current camQuat.
    // Camera sits at Z+, Y is screen-up, X is screen-right.
    //
    // The rubik node sits inside a chain of rotations that compose to -90° around X
    // (sketchfab_model Q1=-90°X, rubik_fbx Q2=+90°X, root Q3=-90°X → net -90°X).
    // So world_normal = camQuat * R_internal * local_normal, meaning we must apply
    // R_internal^(-1) = +90°X after inv(camQuat) to land in cube-local space.
    function resolveViewFace(viewFaceName) {
        var viewDirMap = {
            "U": Qt.vector3d( 0,  1,  0),
            "D": Qt.vector3d( 0, -1,  0),
            "F": Qt.vector3d( 0,  0,  1),
            "B": Qt.vector3d( 0,  0, -1),
            "R": Qt.vector3d( 1,  0,  0),
            "L": Qt.vector3d(-1,  0,  0)
        };
        var wd = viewDirMap[viewFaceName];

        // Step 1: undo camQuat
        var invCamQ = Qt.quaternion(camQuat.scalar, -camQuat.x, -camQuat.y, -camQuat.z);
        var temp = quatRotateVec(invCamQ, wd);

        // Step 2: undo internal model rotation (-90°X), so apply +90°X
        var rIntInv = Qt.quaternion(0.707107, 0.707107, 0.0, 0.0); // +90° around X
        var ld = quatRotateVec(rIntInv, temp);

        // Cube face outward normals in rubik-local space
        var faceNormals = [
            { name: "U", n: Qt.vector3d( 0,  0,  1) },
            { name: "D", n: Qt.vector3d( 0,  0, -1) },
            { name: "R", n: Qt.vector3d( 1,  0,  0) },
            { name: "L", n: Qt.vector3d(-1,  0,  0) },
            { name: "F", n: Qt.vector3d( 0,  1,  0) },
            { name: "B", n: Qt.vector3d( 0, -1,  0) }
        ];
        var best = "U", bestDot = -999;
        for (var i = 0; i < faceNormals.length; i++) {
            var fn = faceNormals[i];
            var dot = fn.n.x*ld.x + fn.n.y*ld.y + fn.n.z*ld.z;
            if (dot > bestDot) { bestDot = dot; best = fn.name; }
        }
        return best;
    }

    function executeDynamicFaceRotation(viewFaceName, clockwise) {
        executeFaceRotation(resolveViewFace(viewFaceName), clockwise);
    }

    function scramble() {
        var ff = ["U","D","R","L","F","B"];
        for (var i = 0; i < 20; i++)
            executeFaceRotation(ff[Math.floor(Math.random()*6)], Math.random() > 0.5);
    }

    function initCubies() {
        var nodes = [
            rubiksCube.node1,  rubiksCube.node2,  rubiksCube.node3,
            rubiksCube.node4,  rubiksCube.node5,  rubiksCube.node6,
            rubiksCube.node7,  rubiksCube.node8,  rubiksCube.node9,
            rubiksCube.node10, rubiksCube.node11, rubiksCube.node12,
            rubiksCube.node13, rubiksCube.node14, rubiksCube.node15,
            rubiksCube.node16, rubiksCube.node17, rubiksCube.node18,
            rubiksCube.node19, rubiksCube.node20, rubiksCube.node21,
            rubiksCube.node22, rubiksCube.node23, rubiksCube.node24,
            rubiksCube.node25, rubiksCube.node26
        ];
        var arr = [];
        for (var i = 0; i < 26; i++)
            arr.push({ node: nodes[i], pos: initialPositions[i].slice() });
        cubies = arr;
    }

    function resetCube() {
        moveQueue = [];
        pivotAnimX.stop(); pivotAnimY.stop(); pivotAnimZ.stop();
        animating = false;
        pivot.eulerRotation = Qt.vector3d(0, 0, 0);
        for (var i = 0; i < cubies.length; i++) {
            cubies[i].node.parent = rubiksCube.rubikNode;
            cubies[i].node.rotation = Qt.quaternion(1, 0, 0, 0);
        }
        initCubies();
    }

    // Background gradient
    Rectangle {
        anchors.fill: parent
        gradient: Gradient {
            GradientStop { position: 0.0; color: "#0f0c29" }
            GradientStop { position: 0.5; color: "#1a1a3e" }
            GradientStop { position: 1.0; color: "#24243e" }
        }
    }

    View3D {
        anchors.fill: parent
        environment: SceneEnvironment {
            clearColor: "transparent"
            backgroundMode: SceneEnvironment.Transparent
            antialiasingMode: SceneEnvironment.MSAA
            antialiasingQuality: SceneEnvironment.High
        }
        PerspectiveCamera {
            id: camera
            position: Qt.vector3d(0, 0, 580)
        }

        // Key light — warm, strong, from upper-right-front
        DirectionalLight {
            eulerRotation: Qt.vector3d(-35, -30, 0)
            brightness: 1.8
            color: "#fff5e6"
            castsShadow: true
            shadowMapQuality: Light.ShadowMapQualityHigh
        }
        // Fill light — cool, softer, from left
        DirectionalLight {
            eulerRotation: Qt.vector3d(10, 120, 0)
            brightness: 0.6
            color: "#ccd5ff"
        }
        // Rim light — subtle, from behind-below
        DirectionalLight {
            eulerRotation: Qt.vector3d(50, 180, 0)
            brightness: 0.3
            color: "#e0d0ff"
        }

        Rubiks_cube {
            id: rubiksCube
            scale: Qt.vector3d(2, 2, 2)
            rotation: root.camQuat
        }
    }

    // Pivot node for face rotation — lives inside the rubik node
    Node {
        id: pivot
        parent: rubiksCube.rubikNode
    }

    NumberAnimation {
        id: pivotAnimX; target: pivot; property: "eulerRotation.x"
        duration: 300; easing.type: Easing.InOutCubic
        onFinished: root.onRotationFinished()
    }
    NumberAnimation {
        id: pivotAnimY; target: pivot; property: "eulerRotation.y"
        duration: 300; easing.type: Easing.InOutCubic
        onFinished: root.onRotationFinished()
    }
    NumberAnimation {
        id: pivotAnimZ; target: pivot; property: "eulerRotation.z"
        duration: 300; easing.type: Easing.InOutCubic
        onFinished: root.onRotationFinished()
    }

    function screenToSphere(mx, my) {
        var size = Math.min(width, height);
        var x = (2.0 * mx - width) / size;
        var y = (height - 2.0 * my) / size;
        var r2 = x * x + y * y;
        if (r2 > 1.0) {
            var r = Math.sqrt(r2);
            return Qt.vector3d(x / r, y / r, 0);
        }
        return Qt.vector3d(x, y, Math.sqrt(1.0 - r2));
    }

    function arcballRotation(from, to) {
        // Cross product = rotation axis
        var ax = from.y * to.z - from.z * to.y;
        var ay = from.z * to.x - from.x * to.z;
        var az = from.x * to.y - from.y * to.x;
        // Dot product = cos(angle)
        var dot = from.x * to.x + from.y * to.y + from.z * to.z;
        dot = Math.max(-1, Math.min(1, dot));
        var len = Math.sqrt(ax * ax + ay * ay + az * az);
        if (len < 0.0001) return Qt.quaternion(1, 0, 0, 0);
        ax /= len; ay /= len; az /= len;
        var angle = Math.acos(dot) * 180 / Math.PI;
        return axisAngleToQuat(ax, ay, az, angle);
    }

    MouseArea {
        id: dragArea
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton
        property vector3d lastSphere: Qt.vector3d(0, 0, 1)
        property quaternion dragStartQuat: Qt.quaternion(1, 0, 0, 0)
        property vector3d dragStartSphere: Qt.vector3d(0, 0, 1)
        property real lastVx: 0
        property real lastVy: 0
        property real lastMx: 0
        property real lastMy: 0

        onPressed: mouse => {
            momentumTimer.stop();
            dragStartQuat = root.camQuat;
            dragStartSphere = root.screenToSphere(mouse.x, mouse.y);
            lastSphere = dragStartSphere;
            lastVx = 0; lastVy = 0;
            lastMx = mouse.x; lastMy = mouse.y;
            keyTarget.forceActiveFocus();
        }
        onPositionChanged: mouse => {
            if (!pressed) return;
            var cur = root.screenToSphere(mouse.x, mouse.y);
            var q = root.arcballRotation(dragStartSphere, cur);
            root.camQuat = root.quatMul(q, dragStartQuat);
            lastVx = mouse.x - lastMx;
            lastVy = mouse.y - lastMy;
            lastMx = mouse.x; lastMy = mouse.y;
            lastSphere = cur;
        }
        onReleased: {
            if (Math.abs(lastVx) > 1 || Math.abs(lastVy) > 1)
                momentumTimer.start();
        }
    }

    Timer {
        id: momentumTimer
        interval: 16; repeat: true
        property real vx: 0
        property real vy: 0
        onTriggered: {
            if (vx === 0 && vy === 0) { vx = dragArea.lastVx; vy = dragArea.lastVy; }
            vx *= 0.95;
            vy *= 0.95;
            var qy = root.axisAngleToQuat(0, 1, 0, vx * 0.3);
            var qx = root.axisAngleToQuat(1, 0, 0, -vy * 0.3);
            root.camQuat = root.quatMul(root.quatMul(qy, qx), root.camQuat);
            if (Math.abs(vx) < 0.1 && Math.abs(vy) < 0.1) {
                vx = 0; vy = 0;
                stop();
            }
        }
    }

    // Camera snap animation
    property quaternion camTarget: Qt.quaternion(1, 0, 0, 0)
    property quaternion camStart: Qt.quaternion(1, 0, 0, 0)
    property real camAnimT: 1

    function quatSlerp(a, b, t) {
        var dot = a.scalar*b.scalar + a.x*b.x + a.y*b.y + a.z*b.z;
        if (dot < 0) { b = Qt.quaternion(-b.scalar, -b.x, -b.y, -b.z); dot = -dot; }
        if (dot > 0.9995) {
            var w = a.scalar + t*(b.scalar - a.scalar);
            var x = a.x + t*(b.x - a.x);
            var y = a.y + t*(b.y - a.y);
            var z = a.z + t*(b.z - a.z);
            var len = Math.sqrt(w*w + x*x + y*y + z*z);
            return Qt.quaternion(w/len, x/len, y/len, z/len);
        }
        var theta = Math.acos(dot);
        var sinT = Math.sin(theta);
        var wa = Math.sin((1 - t) * theta) / sinT;
        var wb = Math.sin(t * theta) / sinT;
        return Qt.quaternion(wa*a.scalar + wb*b.scalar, wa*a.x + wb*b.x, wa*a.y + wb*b.y, wa*a.z + wb*b.z);
    }

    function snapCameraTo(q) {
        momentumTimer.stop();
        camStart = camQuat;
        camTarget = q;
        camAnimT = 0;
        camSnapAnim.restart();
    }

    NumberAnimation {
        id: camSnapAnim
        target: root; property: "camAnimT"
        from: 0; to: 1; duration: 400
        easing.type: Easing.InOutQuad
    }

    onCamAnimTChanged: {
        if (camAnimT > 0 && camAnimT <= 1)
            camQuat = quatSlerp(camStart, camTarget, camAnimT);
    }

    // View presets
    function viewQuat(yawDeg, pitchDeg) {
        var qy = axisAngleToQuat(0, 1, 0, yawDeg);
        var qx = axisAngleToQuat(1, 0, 0, pitchDeg);
        return quatMul(qy, qx);
    }

    Column {
        anchors.left: parent.left; anchors.verticalCenter: parent.verticalCenter
        anchors.leftMargin: 6; spacing: 4
        Repeater {
            model: [
                { l: "⌂",  yaw: -35,  pitch: 25,  c: "#555" },
                { l: "F",  yaw: 0,    pitch: 0,   c: "#a60d00" },
                { l: "B",  yaw: 180,  pitch: 0,   c: "#d38100" },
                { l: "U",  yaw: 0,    pitch: 90,  c: "#e7c600" },
                { l: "D",  yaw: 0,    pitch: -90, c: "#aaaaaa" },
                { l: "R",  yaw: -90,  pitch: 0,   c: "#0075ce" },
                { l: "L",  yaw: 90,   pitch: 0,   c: "#5fe729" }
            ]
            Rectangle {
                required property var modelData
                width: 28; height: 28; radius: 5
                color: modelData.c; opacity: 0.85
                Text {
                    text: parent.modelData.l; anchors.centerIn: parent
                    font.pixelSize: 12; font.bold: true
                    color: parent.modelData.c === "#aaaaaa" ? "#222" : "white"
                }
                MouseArea {
                    anchors.fill: parent
                    onClicked: root.snapCameraTo(root.viewQuat(parent.modelData.yaw, parent.modelData.pitch))
                }
            }
        }
    }

    Item {
        id: keyTarget
        focus: true
        Keys.onPressed: event => {
            var map = {};
            map[Qt.Key_U]="U"; map[Qt.Key_D]="D"; map[Qt.Key_F]="F";
            map[Qt.Key_B]="B"; map[Qt.Key_R]="R"; map[Qt.Key_L]="L";
            if (event.key in map) {
                root.executeDynamicFaceRotation(map[event.key], !(event.modifiers & Qt.ShiftModifier));
                event.accepted = true;
            }
        }
    }

    // Move buttons
    Row {
        anchors.bottom: parent.bottom
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottomMargin: 8
        spacing: 3
        Repeater {
            model: [
                {l:"U",  f:"U", cw:true,  c:"#e7c600"}, {l:"U'", f:"U", cw:false, c:"#e7c600"},
                {l:"D",  f:"D", cw:true,  c:"#dddddd"}, {l:"D'", f:"D", cw:false, c:"#dddddd"},
                {l:"F",  f:"F", cw:true,  c:"#a60d00"}, {l:"F'", f:"F", cw:false, c:"#a60d00"},
                {l:"B",  f:"B", cw:true,  c:"#d38100"}, {l:"B'", f:"B", cw:false, c:"#d38100"},
                {l:"R",  f:"R", cw:true,  c:"#0075ce"}, {l:"R'", f:"R", cw:false, c:"#0075ce"},
                {l:"L",  f:"L", cw:true,  c:"#5fe729"}, {l:"L'", f:"L", cw:false, c:"#5fe729"}
            ]
            Rectangle {
                required property var modelData
                width: 34; height: 28; radius: 5
                color: modelData.c; opacity: 0.85
                Text {
                    text: parent.modelData.l; anchors.centerIn: parent
                    font.pixelSize: 11; font.bold: true
                    color: parent.modelData.c === "#dddddd" ? "#222" : "white"
                }
                MouseArea {
                    anchors.fill: parent
                    onClicked: root.executeDynamicFaceRotation(parent.modelData.f, parent.modelData.cw)
                }
            }
        }
    }

    // Scramble + Reset
    Row {
        anchors.top: parent.top; anchors.right: parent.right; anchors.margins: 8; spacing: 5
        Rectangle {
            width: 65; height: 28; radius: 5; color: "#444"
            Text { text: "Scramble"; anchors.centerIn: parent; color: "white"; font.pixelSize: 11 }
            MouseArea { anchors.fill: parent; onClicked: root.scramble() }
        }
        Rectangle {
            width: 50; height: 28; radius: 5; color: "#666"
            Text { text: "Reset"; anchors.centerIn: parent; color: "white"; font.pixelSize: 11 }
            MouseArea { anchors.fill: parent; onClicked: root.resetCube() }
        }
    }

    Component.onCompleted: {
        // Set initial camera angle (~25° pitch, ~-35° yaw)
        var qy = axisAngleToQuat(0, 1, 0, -35);
        var qx = axisAngleToQuat(1, 0, 0, 25);
        camQuat = quatMul(qy, qx);
        initCubies();
    }
}
