import QtQuick
import QtQuick3D

Node {
    id: node
    property alias node1: node1
    property alias node2: node2
    property alias node3: node3
    property alias node4: node4
    property alias node5: node5
    property alias node6: node6
    property alias node7: node7
    property alias node8: node8
    property alias node9: node9
    property alias node10: node10
    property alias node11: node11
    property alias node12: node12
    property alias node13: node13
    property alias node14: node14
    property alias node15: node15
    property alias node16: node16
    property alias node17: node17
    property alias node18: node18
    property alias node19: node19
    property alias node20: node20
    property alias node21: node21
    property alias node22: node22
    property alias node23: node23
    property alias node24: node24
    property alias node25: node25
    property alias node26: node26
    property alias rubikNode: rubik

    // Resources
    PrincipledMaterial {
        id: green_material
        objectName: "Green"
        baseColor: "#ff5fe729"
        cullMode: PrincipledMaterial.NoCulling
        alphaMode: PrincipledMaterial.Opaque
    }
    PrincipledMaterial {
        id: orange_material
        objectName: "Orange"
        baseColor: "#ffd38100"
        metalness: 0.7009299397468567
        cullMode: PrincipledMaterial.NoCulling
        alphaMode: PrincipledMaterial.Opaque
    }
    PrincipledMaterial {
        id: yellow_material
        objectName: "Yellow"
        baseColor: "#ffe7c600"
        cullMode: PrincipledMaterial.NoCulling
        alphaMode: PrincipledMaterial.Opaque
    }
    PrincipledMaterial {
        id: blue_material
        objectName: "Blue"
        baseColor: "#ff0075ce"
        cullMode: PrincipledMaterial.NoCulling
        alphaMode: PrincipledMaterial.Opaque
    }
    PrincipledMaterial {
        id: black_material
        objectName: "Black"
        baseColor: "#ff191919"
        roughness: 0.3781122863292694
        cullMode: PrincipledMaterial.NoCulling
        alphaMode: PrincipledMaterial.Opaque
    }
    PrincipledMaterial {
        id: material_001_material
        objectName: "Material.001"
        baseColor: "#ff000000"
        roughness: 1
        cullMode: PrincipledMaterial.NoCulling
        alphaMode: PrincipledMaterial.Opaque
    }
    PrincipledMaterial {
        id: white_material
        objectName: "White"
        cullMode: PrincipledMaterial.NoCulling
        alphaMode: PrincipledMaterial.Opaque
    }
    PrincipledMaterial {
        id: material_material
        objectName: "material"
        baseColor: "#ffa60d00"
        cullMode: PrincipledMaterial.NoCulling
        alphaMode: PrincipledMaterial.Opaque
    }

    // Nodes:
    Node {
        id: sketchfab_model
        objectName: "Sketchfab_model"
        rotation: Qt.quaternion(0.707107, -0.707107, 0, 0)
        Node {
            id: rubik_fbx
            objectName: "Rubik.fbx"
            rotation: Qt.quaternion(0.707107, 0.707107, 0, 0)
            Node {
                id: rootNode
                objectName: "RootNode"
                Node {
                    id: root
                    objectName: "Root"
                    rotation: Qt.quaternion(0.707107, -0.707107, 0, 0)
                    scale: Qt.vector3d(201.057, 201.057, 201.057)
                    Node {
                        id: rubik
                        objectName: "Rubik"
                        scale: Qt.vector3d(0.208714, 0.208714, 0.208714)
                        Model {
                            id: rubik_Material_001_0
                            objectName: "Rubik_Material.001_0"
                            source: "meshes/rubik_Material_001_0_mesh.mesh"
                            materials: [
                                material_001_material
                            ]
                        }
                        Node {
                            id: node1
                            objectName: "1"
                            scale: Qt.vector3d(2.38304, 2.38304, 2.38304)
                            Model {
                                id: node1_Black_0
                                objectName: "1_Black_0"
                                source: "meshes/node1_Black_0_mesh.mesh"
                                materials: [
                                    black_material
                                ]
                            }
                            Model {
                                id: node1_Blue_0
                                objectName: "1_Blue_0"
                                source: "meshes/node1_Blue_0_mesh.mesh"
                                materials: [
                                    blue_material
                                ]
                            }
                            Model {
                                id: node1_Yellow_0
                                objectName: "1_Yellow_0"
                                source: "meshes/node1_Yellow_0_mesh.mesh"
                                materials: [
                                    yellow_material
                                ]
                            }
                            Model {
                                id: node1_Orange_0
                                objectName: "1_Orange_0"
                                source: "meshes/node1_Orange_0_mesh.mesh"
                                materials: [
                                    orange_material
                                ]
                            }
                        }
                        Node {
                            id: node2
                            objectName: "2"
                            scale: Qt.vector3d(2.38304, 2.38304, 2.38304)
                            Model {
                                id: node2_Black_0
                                objectName: "2_Black_0"
                                source: "meshes/node2_Black_0_mesh.mesh"
                                materials: [
                                    black_material
                                ]
                            }
                            Model {
                                id: node2_Yellow_0
                                objectName: "2_Yellow_0"
                                source: "meshes/node2_Yellow_0_mesh.mesh"
                                materials: [
                                    yellow_material
                                ]
                            }
                            Model {
                                id: node2_Orange_0
                                objectName: "2_Orange_0"
                                source: "meshes/node2_Orange_0_mesh.mesh"
                                materials: [
                                    orange_material
                                ]
                            }
                        }
                        Node {
                            id: node3
                            objectName: "3"
                            scale: Qt.vector3d(2.38304, 2.38304, 2.38304)
                            Model {
                                id: node3_Black_0
                                objectName: "3_Black_0"
                                source: "meshes/node3_Black_0_mesh.mesh"
                                materials: [
                                    black_material
                                ]
                            }
                            Model {
                                id: node3_Green_0
                                objectName: "3_Green_0"
                                source: "meshes/node3_Green_0_mesh.mesh"
                                materials: [
                                    green_material
                                ]
                            }
                            Model {
                                id: node3_Orange_0
                                objectName: "3_Orange_0"
                                source: "meshes/node3_Orange_0_mesh.mesh"
                                materials: [
                                    orange_material
                                ]
                            }
                            Model {
                                id: node3_Yellow_0
                                objectName: "3_Yellow_0"
                                source: "meshes/node3_Yellow_0_mesh.mesh"
                                materials: [
                                    yellow_material
                                ]
                            }
                        }
                        Node {
                            id: node4
                            objectName: "4"
                            scale: Qt.vector3d(2.38304, 2.38304, 2.38304)
                            Model {
                                id: node4_Black_0
                                objectName: "4_Black_0"
                                source: "meshes/node4_Black_0_mesh.mesh"
                                materials: [
                                    black_material
                                ]
                            }
                            Model {
                                id: node4_Blue_0
                                objectName: "4_Blue_0"
                                source: "meshes/node4_Blue_0_mesh.mesh"
                                materials: [
                                    blue_material
                                ]
                            }
                            Model {
                                id: node4_Yellow_0
                                objectName: "4_Yellow_0"
                                source: "meshes/node4_Yellow_0_mesh.mesh"
                                materials: [
                                    yellow_material
                                ]
                            }
                        }
                        Node {
                            id: node5
                            objectName: "5"
                            scale: Qt.vector3d(2.38304, 2.38304, 2.38304)
                            Model {
                                id: node5_Black_0
                                objectName: "5_Black_0"
                                source: "meshes/node5_Black_0_mesh.mesh"
                                materials: [
                                    black_material
                                ]
                            }
                            Model {
                                id: node5_Green_0
                                objectName: "5_Green_0"
                                source: "meshes/node5_Green_0_mesh.mesh"
                                materials: [
                                    green_material
                                ]
                            }
                            Model {
                                id: node5_Yellow_0
                                objectName: "5_Yellow_0"
                                source: "meshes/node5_Yellow_0_mesh.mesh"
                                materials: [
                                    yellow_material
                                ]
                            }
                        }
                        Node {
                            id: node6
                            objectName: "6"
                            scale: Qt.vector3d(2.38304, 2.38304, 2.38304)
                            Model {
                                id: node6_Red_0
                                objectName: "6_Red_0"
                                source: "meshes/node6_Red_0_mesh.mesh"
                                materials: [
                                    material_material
                                ]
                            }
                            Model {
                                id: node6_Black_0
                                objectName: "6_Black_0"
                                source: "meshes/node6_Black_0_mesh.mesh"
                                materials: [
                                    black_material
                                ]
                            }
                            Model {
                                id: node6_Green_0
                                objectName: "6_Green_0"
                                source: "meshes/node6_Green_0_mesh.mesh"
                                materials: [
                                    green_material
                                ]
                            }
                            Model {
                                id: node6_Yellow_0
                                objectName: "6_Yellow_0"
                                source: "meshes/node6_Yellow_0_mesh.mesh"
                                materials: [
                                    yellow_material
                                ]
                            }
                        }
                        Node {
                            id: node7
                            objectName: "7"
                            scale: Qt.vector3d(2.38304, 2.38304, 2.38304)
                            Model {
                                id: node7_Red_0
                                objectName: "7_Red_0"
                                source: "meshes/node7_Red_0_mesh.mesh"
                                materials: [
                                    material_material
                                ]
                            }
                            Model {
                                id: node7_Black_0
                                objectName: "7_Black_0"
                                source: "meshes/node7_Black_0_mesh.mesh"
                                materials: [
                                    black_material
                                ]
                            }
                            Model {
                                id: node7_Blue_0
                                objectName: "7_Blue_0"
                                source: "meshes/node7_Blue_0_mesh.mesh"
                                materials: [
                                    blue_material
                                ]
                            }
                            Model {
                                id: node7_Yellow_0
                                objectName: "7_Yellow_0"
                                source: "meshes/node7_Yellow_0_mesh.mesh"
                                materials: [
                                    yellow_material
                                ]
                            }
                        }
                        Node {
                            id: node8
                            objectName: "8"
                            scale: Qt.vector3d(2.38304, 2.38304, 2.38304)
                            Model {
                                id: node8_Yellow_0
                                objectName: "8_Yellow_0"
                                source: "meshes/node8_Yellow_0_mesh.mesh"
                                materials: [
                                    yellow_material
                                ]
                            }
                            Model {
                                id: node8_Black_0
                                objectName: "8_Black_0"
                                source: "meshes/node8_Black_0_mesh.mesh"
                                materials: [
                                    black_material
                                ]
                            }
                            Model {
                                id: node8_Red_0
                                objectName: "8_Red_0"
                                source: "meshes/node8_Red_0_mesh.mesh"
                                materials: [
                                    material_material
                                ]
                            }
                        }
                        Node {
                            id: node9
                            objectName: "9"
                            scale: Qt.vector3d(2.38304, 2.38304, 2.38304)
                            Model {
                                id: node9_Yellow_0
                                objectName: "9_Yellow_0"
                                source: "meshes/node9_Yellow_0_mesh.mesh"
                                materials: [
                                    yellow_material
                                ]
                            }
                            Model {
                                id: node9_Black_0
                                objectName: "9_Black_0"
                                source: "meshes/node9_Black_0_mesh.mesh"
                                materials: [
                                    black_material
                                ]
                            }
                        }
                        Node {
                            id: node10
                            objectName: "10"
                            scale: Qt.vector3d(2.38304, 2.38304, 2.38304)
                            Model {
                                id: node10_Black_0
                                objectName: "10_Black_0"
                                source: "meshes/node10_Black_0_mesh.mesh"
                                materials: [
                                    black_material
                                ]
                            }
                            Model {
                                id: node10_White_0
                                objectName: "10_White_0"
                                source: "meshes/node10_White_0_mesh.mesh"
                                materials: [
                                    white_material
                                ]
                            }
                            Model {
                                id: node10_Red_0
                                objectName: "10_Red_0"
                                source: "meshes/node10_Red_0_mesh.mesh"
                                materials: [
                                    material_material
                                ]
                            }
                        }
                        Node {
                            id: node11
                            objectName: "11"
                            scale: Qt.vector3d(2.38304, 2.38304, 2.38304)
                            Model {
                                id: node11_Black_0
                                objectName: "11_Black_0"
                                source: "meshes/node11_Black_0_mesh.mesh"
                                materials: [
                                    black_material
                                ]
                            }
                            Model {
                                id: node11_Green_0
                                objectName: "11_Green_0"
                                source: "meshes/node11_Green_0_mesh.mesh"
                                materials: [
                                    green_material
                                ]
                            }
                            Model {
                                id: node11_White_0
                                objectName: "11_White_0"
                                source: "meshes/node11_White_0_mesh.mesh"
                                materials: [
                                    white_material
                                ]
                            }
                            Model {
                                id: node11_Red_0
                                objectName: "11_Red_0"
                                source: "meshes/node11_Red_0_mesh.mesh"
                                materials: [
                                    material_material
                                ]
                            }
                        }
                        Node {
                            id: node12
                            objectName: "12"
                            scale: Qt.vector3d(2.38304, 2.38304, 2.38304)
                            Model {
                                id: node12_Black_0
                                objectName: "12_Black_0"
                                source: "meshes/node12_Black_0_mesh.mesh"
                                materials: [
                                    black_material
                                ]
                            }
                            Model {
                                id: node12_Blue_0
                                objectName: "12_Blue_0"
                                source: "meshes/node12_Blue_0_mesh.mesh"
                                materials: [
                                    blue_material
                                ]
                            }
                            Model {
                                id: node12_White_0
                                objectName: "12_White_0"
                                source: "meshes/node12_White_0_mesh.mesh"
                                materials: [
                                    white_material
                                ]
                            }
                            Model {
                                id: node12_Orange_0
                                objectName: "12_Orange_0"
                                source: "meshes/node12_Orange_0_mesh.mesh"
                                materials: [
                                    orange_material
                                ]
                            }
                        }
                        Node {
                            id: node13
                            objectName: "13"
                            scale: Qt.vector3d(2.38304, 2.38304, 2.38304)
                            Model {
                                id: node13_Black_0
                                objectName: "13_Black_0"
                                source: "meshes/node13_Black_0_mesh.mesh"
                                materials: [
                                    black_material
                                ]
                            }
                            Model {
                                id: node13_White_0
                                objectName: "13_White_0"
                                source: "meshes/node13_White_0_mesh.mesh"
                                materials: [
                                    white_material
                                ]
                            }
                            Model {
                                id: node13_Orange_0
                                objectName: "13_Orange_0"
                                source: "meshes/node13_Orange_0_mesh.mesh"
                                materials: [
                                    orange_material
                                ]
                            }
                        }
                        Node {
                            id: node14
                            objectName: "14"
                            scale: Qt.vector3d(2.38304, 2.38304, 2.38304)
                            Model {
                                id: node14_Black_0
                                objectName: "14_Black_0"
                                source: "meshes/node14_Black_0_mesh.mesh"
                                materials: [
                                    black_material
                                ]
                            }
                            Model {
                                id: node14_Green_0
                                objectName: "14_Green_0"
                                source: "meshes/node14_Green_0_mesh.mesh"
                                materials: [
                                    green_material
                                ]
                            }
                            Model {
                                id: node14_Orange_0
                                objectName: "14_Orange_0"
                                source: "meshes/node14_Orange_0_mesh.mesh"
                                materials: [
                                    orange_material
                                ]
                            }
                            Model {
                                id: node14_White_0
                                objectName: "14_White_0"
                                source: "meshes/node14_White_0_mesh.mesh"
                                materials: [
                                    white_material
                                ]
                            }
                        }
                        Node {
                            id: node15
                            objectName: "15"
                            scale: Qt.vector3d(2.38304, 2.38304, 2.38304)
                            Model {
                                id: node15_Black_0
                                objectName: "15_Black_0"
                                source: "meshes/node15_Black_0_mesh.mesh"
                                materials: [
                                    black_material
                                ]
                            }
                            Model {
                                id: node15_Blue_0
                                objectName: "15_Blue_0"
                                source: "meshes/node15_Blue_0_mesh.mesh"
                                materials: [
                                    blue_material
                                ]
                            }
                            Model {
                                id: node15_White_0
                                objectName: "15_White_0"
                                source: "meshes/node15_White_0_mesh.mesh"
                                materials: [
                                    white_material
                                ]
                            }
                        }
                        Node {
                            id: node16
                            objectName: "16"
                            scale: Qt.vector3d(2.38304, 2.38304, 2.38304)
                            Model {
                                id: node16_Black_0
                                objectName: "16_Black_0"
                                source: "meshes/node16_Black_0_mesh.mesh"
                                materials: [
                                    black_material
                                ]
                            }
                            Model {
                                id: node16_Blue_0
                                objectName: "16_Blue_0"
                                source: "meshes/node16_Blue_0_mesh.mesh"
                                materials: [
                                    blue_material
                                ]
                            }
                        }
                        Node {
                            id: node17
                            objectName: "17"
                            scale: Qt.vector3d(2.38304, 2.38304, 2.38304)
                            Model {
                                id: node17_Red_0
                                objectName: "17_Red_0"
                                source: "meshes/node17_Red_0_mesh.mesh"
                                materials: [
                                    material_material
                                ]
                            }
                            Model {
                                id: node17_Black_0
                                objectName: "17_Black_0"
                                source: "meshes/node17_Black_0_mesh.mesh"
                                materials: [
                                    black_material
                                ]
                            }
                            Model {
                                id: node17_Blue_0
                                objectName: "17_Blue_0"
                                source: "meshes/node17_Blue_0_mesh.mesh"
                                materials: [
                                    blue_material
                                ]
                            }
                            Model {
                                id: node17_White_0
                                objectName: "17_White_0"
                                source: "meshes/node17_White_0_mesh.mesh"
                                materials: [
                                    white_material
                                ]
                            }
                        }
                        Node {
                            id: node18
                            objectName: "18"
                            scale: Qt.vector3d(2.38304, 2.38304, 2.38304)
                            Model {
                                id: node18_Green_0
                                objectName: "18_Green_0"
                                source: "meshes/node18_Green_0_mesh.mesh"
                                materials: [
                                    green_material
                                ]
                            }
                            Model {
                                id: node18_Black_0
                                objectName: "18_Black_0"
                                source: "meshes/node18_Black_0_mesh.mesh"
                                materials: [
                                    black_material
                                ]
                            }
                            Model {
                                id: node18_White_0
                                objectName: "18_White_0"
                                source: "meshes/node18_White_0_mesh.mesh"
                                materials: [
                                    white_material
                                ]
                            }
                        }
                        Node {
                            id: node19
                            objectName: "19"
                            scale: Qt.vector3d(2.38304, 2.38304, 2.38304)
                            Model {
                                id: node19_Black_0
                                objectName: "19_Black_0"
                                source: "meshes/node19_Black_0_mesh.mesh"
                                materials: [
                                    black_material
                                ]
                            }
                            Model {
                                id: node19_White_0
                                objectName: "19_White_0"
                                source: "meshes/node19_White_0_mesh.mesh"
                                materials: [
                                    white_material
                                ]
                            }
                        }
                        Node {
                            id: node20
                            objectName: "20"
                            scale: Qt.vector3d(2.38304, 2.38304, 2.38304)
                            Model {
                                id: node20_Black_0
                                objectName: "20_Black_0"
                                source: "meshes/node20_Black_0_mesh.mesh"
                                materials: [
                                    black_material
                                ]
                            }
                            Model {
                                id: node20_Red_0
                                objectName: "20_Red_0"
                                source: "meshes/node20_Red_0_mesh.mesh"
                                materials: [
                                    material_material
                                ]
                            }
                        }
                        Node {
                            id: node21
                            objectName: "21"
                            scale: Qt.vector3d(2.38304, 2.38304, 2.38304)
                            Model {
                                id: node21_Green_0
                                objectName: "21_Green_0"
                                source: "meshes/node21_Green_0_mesh.mesh"
                                materials: [
                                    green_material
                                ]
                            }
                            Model {
                                id: node21_Black_0
                                objectName: "21_Black_0"
                                source: "meshes/node21_Black_0_mesh.mesh"
                                materials: [
                                    black_material
                                ]
                            }
                        }
                        Node {
                            id: node22
                            objectName: "22"
                            scale: Qt.vector3d(2.38304, 2.38304, 2.38304)
                            Model {
                                id: node22_Black_0
                                objectName: "22_Black_0"
                                source: "meshes/node22_Black_0_mesh.mesh"
                                materials: [
                                    black_material
                                ]
                            }
                            Model {
                                id: node22_Orange_0
                                objectName: "22_Orange_0"
                                source: "meshes/node22_Orange_0_mesh.mesh"
                                materials: [
                                    orange_material
                                ]
                            }
                        }
                        Node {
                            id: node23
                            objectName: "23"
                            scale: Qt.vector3d(2.38304, 2.38304, 2.38304)
                            Model {
                                id: node23_Red_0
                                objectName: "23_Red_0"
                                source: "meshes/node23_Red_0_mesh.mesh"
                                materials: [
                                    material_material
                                ]
                            }
                            Model {
                                id: node23_Black_0
                                objectName: "23_Black_0"
                                source: "meshes/node23_Black_0_mesh.mesh"
                                materials: [
                                    black_material
                                ]
                            }
                            Model {
                                id: node23_Blue_0
                                objectName: "23_Blue_0"
                                source: "meshes/node23_Blue_0_mesh.mesh"
                                materials: [
                                    blue_material
                                ]
                            }
                        }
                        Node {
                            id: node24
                            objectName: "24"
                            scale: Qt.vector3d(2.38304, 2.38304, 2.38304)
                            Model {
                                id: node24_Black_0
                                objectName: "24_Black_0"
                                source: "meshes/node24_Black_0_mesh.mesh"
                                materials: [
                                    black_material
                                ]
                            }
                            Model {
                                id: node24_Blue_0
                                objectName: "24_Blue_0"
                                source: "meshes/node24_Blue_0_mesh.mesh"
                                materials: [
                                    blue_material
                                ]
                            }
                            Model {
                                id: node24_Orange_0
                                objectName: "24_Orange_0"
                                source: "meshes/node24_Orange_0_mesh.mesh"
                                materials: [
                                    orange_material
                                ]
                            }
                        }
                        Node {
                            id: node25
                            objectName: "25"
                            scale: Qt.vector3d(2.38304, 2.38304, 2.38304)
                            Model {
                                id: node25_Black_0
                                objectName: "25_Black_0"
                                source: "meshes/node25_Black_0_mesh.mesh"
                                materials: [
                                    black_material
                                ]
                            }
                            Model {
                                id: node25_Red_0
                                objectName: "25_Red_0"
                                source: "meshes/node25_Red_0_mesh.mesh"
                                materials: [
                                    material_material
                                ]
                            }
                            Model {
                                id: node25_Green_0
                                objectName: "25_Green_0"
                                source: "meshes/node25_Green_0_mesh.mesh"
                                materials: [
                                    green_material
                                ]
                            }
                        }
                        Node {
                            id: node26
                            objectName: "26"
                            scale: Qt.vector3d(2.38304, 2.38304, 2.38304)
                            Model {
                                id: node26_Orange_0
                                objectName: "26_Orange_0"
                                source: "meshes/node26_Orange_0_mesh.mesh"
                                materials: [
                                    orange_material
                                ]
                            }
                            Model {
                                id: node26_Black_0
                                objectName: "26_Black_0"
                                source: "meshes/node26_Black_0_mesh.mesh"
                                materials: [
                                    black_material
                                ]
                            }
                            Model {
                                id: node26_Green_0
                                objectName: "26_Green_0"
                                source: "meshes/node26_Green_0_mesh.mesh"
                                materials: [
                                    green_material
                                ]
                            }
                        }
                    }
                }
            }
        }
    }

    // Animations:
}
