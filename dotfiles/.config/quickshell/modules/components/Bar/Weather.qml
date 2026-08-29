import Quickshell
import Quickshell.Widgets
import QtQuick
import QtQuick.Layouts
import qs.modules.utils
import qs.modules.settings
import qs.modules.services
import qs.modules.customComponents

Rectangle{
    id: root
    radius: 10
    color: Colors.surfaceContainerHigh
    implicitWidth: row.implicitWidth + 20
    signal clicked

    // Loader{
    //     active: root.isWeatherPanelClicked
    //     visible: active
    //     sourceComponent: WeatherPanel{
    //         onClose: root.isWeatherPanelClicked = false
    //     }
    // }

    RowLayout{
        id: row
        anchors.fill: parent 
        spacing: 10
        anchors.leftMargin: 10
        anchors.rightMargin: 10
        // CustomIconImage{
        //     icon: ServiceWeather.weatherIconPath
        //     size: 14
        //     bright: 1
        // }
        // MaterialIconSymbol{
        //     content: ServiceWeather.weatherIconPath.icon
        //     iconSize: 16
        // }
        Image{
            width: 16
            height: 16
            sourceSize.width: 16
            sourceSize.height: 16
            source: IconUtil.getSystemIcon(ServiceWeather.weatherIconPath.svg)
        }

        CustomText{
            content: ServiceWeather.temperature
            size: 12
        }
    }

    CustomMouseArea{
        radius: parent.radius
        cursorShape: Qt.PointingHandCursor
        onClicked:root.clicked()
    }
}
