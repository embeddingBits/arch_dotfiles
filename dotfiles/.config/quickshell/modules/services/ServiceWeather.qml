pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import qs.modules.utils
import qs.modules.settings

Singleton {
    id: root

    property string location: SettingsConfig.weather.location
    property bool useMetric: SettingsConfig.weather.useMetric ?? true
    property int refreshInterval: (SettingsConfig.weather.refreshInterval ?? 15) * 60000
    property bool isLoading: false
    property bool hasError: false
    property var lastUpdated: null

    // Weather data properties
    property var currentCondition: null
    property var locationData: null
    property var astronomy: null
    property var hourlyForecast: []
    property var forecastDays: []

    // Convenient properties
    readonly property string temperature: currentCondition ?
        (useMetric ? currentCondition.temp_C + "°" : currentCondition.temp_F + "°") : "0°"
    readonly property string feelsLike: currentCondition ?
        (useMetric ? currentCondition.FeelsLikeC + "°" : currentCondition.FeelsLikeF + "°") : "N/A"
    readonly property real humidity: currentCondition ? currentCondition.humidity : 0
    readonly property string description: currentCondition ? currentCondition.weatherDesc[0].value : "No data"
    readonly property string weatherCode: currentCondition ? currentCondition.weatherCode : "113"
    readonly property string cityName: locationData ? locationData.areaName[0].value : "Unknown"
    readonly property string windSpeed: currentCondition ? currentCondition.windspeedKmph + " km/h" : "N/A"
    readonly property real windDegree: currentCondition ? currentCondition.winddirDegree : 0
    readonly property string windDirection: currentCondition ? currentCondition.winddir16Point : "N/A"
    readonly property string cloudcover: currentCondition ? currentCondition.cloudcover + "%" : "N/A"
    readonly property string uvindex: currentCondition ? currentCondition.uvIndex : "N/A"
    readonly property string visibility: currentCondition ? currentCondition.visibility : "N/A"
    readonly property string precipitation: currentCondition ? currentCondition.precipInches : "N/A"
    readonly property real currentPressure: currentCondition ? currentCondition.pressure : min_pressure
    readonly property string pressureInches: currentCondition ? currentCondition.pressureInches : "N/A"

    readonly property real min_pressure: 960
    readonly property real max_pressure: 1060

    // progress 0.0 → 1.0
    readonly property real pressure: (currentPressure - min_pressure) / (max_pressure - min_pressure)

    function mapHourly(h) {
        return {
            time:          formatHourlyTime(h.time),
            tempC:         h.tempC + "°",
            tempF:         h.tempF + "°",
            feelsLikeC:    h.FeelsLikeC + "°",
            feelsLikeF:    h.FeelsLikeF + "°",
            humidity:      h.humidity,
            weatherCode:   h.weatherCode,
            description:   h.weatherDesc[0].value.trim(),
            chanceofrain:  h.chanceofrain,
            windspeedKmph: h.windspeedKmph,
            uvIndex:       h.uvIndex
        }
    }

    function getHourlyForDay(dayIndex) {
        if (!forecastDays || forecastDays.length <= dayIndex) return []
        const day = forecastDays[dayIndex]
        if (!day || !day.hourly) return []

        const now = new Date()
        const currentTotalMinutes = now.getHours() * 60 + now.getMinutes()

        const filtered = day.hourly
            .filter(h => {
                const hours = Math.floor(parseInt(h.time) / 100)
                return dayIndex > 0 || (hours * 60) >= currentTotalMinutes
            })
            .map(mapHourly)

        if (dayIndex === 0 && currentCondition) {
            const current = {
                time:          "Now",
                tempC:         currentCondition.temp_C + "°",
                tempF:         currentCondition.temp_F + "°",
                feelsLikeC:    currentCondition.FeelsLikeC + "°",
                feelsLikeF:    currentCondition.FeelsLikeF + "°",
                humidity:      currentCondition.humidity,
                weatherCode:   currentCondition.weatherCode,
                description:   currentCondition.weatherDesc[0].value.trim(),
                chanceofrain:  currentCondition.chanceofrain ?? "0",
                windspeedKmph: currentCondition.windspeedKmph,
                uvIndex:       currentCondition.uvIndex
            }

            const combined = [current].concat(filtered)

            if (combined.length < 8 && forecastDays.length > 1) {
                const nextDay = forecastDays[1]
                if (nextDay && nextDay.hourly) {
                    const needed = 8 - combined.length
                    const nextDaySlots = nextDay.hourly.slice(0, needed).map(mapHourly)
                    return combined.concat(nextDaySlots)
                }
            }

            return combined
        }

        // For dayIndex > 0, pad from next day if under 8
        if (filtered.length < 8 && forecastDays.length > dayIndex + 1) {
            const nextDay = forecastDays[dayIndex + 1]
            if (nextDay && nextDay.hourly) {
                const needed = 8 - filtered.length
                const nextDaySlots = nextDay.hourly.slice(0, needed).map(mapHourly)
                return filtered.concat(nextDaySlots)
            }
        }

        return filtered
    }

    // Converts wttr "time" field (0, 300, 600 ... 2100) to readable "12 AM" format
    function formatHourlyTime(timeVal) {
        const t = parseInt(timeVal)
        const hours = Math.floor(t / 100)
        const ampm = hours >= 12 ? "PM" : "AM"
        const h12 = hours % 12 === 0 ? 12 : hours % 12
        return h12 + " " + ampm
    }

    readonly property var todayHourly: getHourlyForDay(0)
    readonly property var tomorrowHourly: getHourlyForDay(1)

    Timer {
        id: refreshTimer
        interval: root.refreshInterval
        running: true
        repeat: true
        onTriggered: root.fetchWeather()
        Component.onCompleted: root.fetchWeather()
    }

    function refresh() {
        if (root.isLoading) return
        refreshTimer.restart()
        fetchWeather()
    }

    function fetchWeather() {
        root.isLoading = true
        root.hasError = false
        weatherProcess.command[2] = `curl -s wttr.in/${location}?format=j1`
        weatherProcess.running = true
    }

    Process {
        id: weatherProcess
        command: ["bash", "-c", ""]

        stdout: StdioCollector {
            onStreamFinished: {
                root.isLoading = false
                root.lastUpdated = new Date()
                if (text.length === 0) {
                    root.hasError = true
                    return
                }

                try {
                    const data = JSON.parse(text)

                    if (data.current_condition && data.current_condition.length > 0) {
                        root.currentCondition = data.current_condition[0]
                    }
                    if (data.nearest_area && data.nearest_area.length > 0) {
                        root.locationData = data.nearest_area[0]
                    }
                    if (data.weather && data.weather.length > 0) {
                        if (data.weather[0].astronomy) {
                            root.astronomy = data.weather[0].astronomy[0]
                        }
                        root.forecastDays = data.weather
                        root.hourlyForecast = data.weather[0].hourly
                    }

                    root.hasError = false
                } catch (e) {
                    root.hasError = true
                    console.error("Weather data parse error:", e.message)
                }
            }
        }

        stderr: StdioCollector {
            onStreamFinished: {
                if (text.length > 0) root.hasError = true
            }
        }
    }

    function isNightTime() {
        if (!astronomy || !astronomy.sunrise || !astronomy.sunset) {
            const hour = new Date().getHours()
            return hour < 6 || hour >= 18
        }

        const now = new Date()
        const currentTime = now.getHours() * 60 + now.getMinutes()

        function parseTime(str) {
            const m = str.match(/(\d{1,2}):(\d{2})\s*(AM|PM)/i)
            if (!m) return null
            let h = parseInt(m[1])
            const min = parseInt(m[2])
            const ap = m[3].toUpperCase()
            if (ap === "PM" && h !== 12) h += 12
            if (ap === "AM" && h === 12) h = 0
            return h * 60 + min
        }

        const sunriseTime = parseTime(astronomy.sunrise)
        const sunsetTime  = parseTime(astronomy.sunset)

        if (sunriseTime === null || sunsetTime === null) {
            const hour = now.getHours()
            return hour < 6 || hour >= 18
        }

        return currentTime < sunriseTime || currentTime >= sunsetTime
    }

    function getWeatherIcon(code) {
        const isNight = isNightTime()

        const dayIconMap = {
            "113": { icon: "clear_day",           svg: "sunny" },
            "116": { icon: "partly_cloudy_day",   svg: "sunny_with_cloudy" },
            "119": { icon: "cloud",               svg: "cloudy" },
            "122": { icon: "cloud",               svg: "cloudy" },
            "143": { icon: "foggy",               svg: "cloudy" },
            "176": { icon: "rainy_light",         svg: "cloudy_with_rain" },
            "179": { icon: "weather_snowy",       svg: "cloudy_with_snow" },
            "182": { icon: "cloudy_snowing",      svg: "rain_with_snow" },
            "185": { icon: "cloudy_snowing",      svg: "rain_with_snow" },
            "200": { icon: "thunderstorm",        svg: "thunderstorms" },
            "227": { icon: "weather_snowy",       svg: "blowing_snow" },
            "230": { icon: "weather_snowy",       svg: "blizzard" },
            "248": { icon: "foggy",               svg: "cloudy" },
            "260": { icon: "foggy",               svg: "cloudy" },
            "263": { icon: "grain",               svg: "drizzle" },
            "266": { icon: "grain",               svg: "drizzle" },
            "281": { icon: "grain",               svg: "drizzle" },
            "284": { icon: "rainy",               svg: "cloudy_with_rain" },
            "293": { icon: "rainy_light",         svg: "cloudy_with_rain" },
            "296": { icon: "rainy_light",         svg: "cloudy_with_rain" },
            "299": { icon: "rainy",               svg: "rain_with_cloudy" },
            "302": { icon: "rainy",               svg: "rain_with_cloudy" },
            "305": { icon: "rainy_heavy",         svg: "heavy_rain" },
            "308": { icon: "rainy_heavy",         svg: "heavy_rain" },
            "311": { icon: "cloudy_snowing",      svg: "sleet_hail" },
            "314": { icon: "cloudy_snowing",      svg: "sleet_hail" },
            "317": { icon: "cloudy_snowing",      svg: "rain_with_snow" },
            "320": { icon: "cloudy_snowing",      svg: "rain_with_snow" },
            "323": { icon: "weather_snowy",       svg: "cloudy_with_snow" },
            "326": { icon: "weather_snowy",       svg: "cloudy_with_snow" },
            "329": { icon: "weather_snowy",       svg: "heavy_snow" },
            "332": { icon: "weather_snowy",       svg: "heavy_snow" },
            "335": { icon: "ac_unit",             svg: "blizzard" },
            "338": { icon: "ac_unit",             svg: "blizzard" },
            "350": { icon: "ac_unit",             svg: "sleet_hail" },
            "353": { icon: "rainy_light",         svg: "drizzle" },
            "356": { icon: "rainy",               svg: "rain_with_cloudy" },
            "359": { icon: "rainy_heavy",         svg: "heavy_rain" },
            "362": { icon: "cloudy_snowing",      svg: "rain_with_snow" },
            "365": { icon: "cloudy_snowing",      svg: "rain_with_snow" },
            "368": { icon: "weather_snowy",       svg: "flurries" },
            "371": { icon: "ac_unit",             svg: "heavy_snow" },
            "374": { icon: "ac_unit",             svg: "sleet_hail" },
            "377": { icon: "ac_unit",             svg: "sleet_hail" },
            "386": { icon: "thunderstorm",        svg: "strong_thunderstorms" },
            "389": { icon: "thunderstorm",        svg: "strong_thunderstorms" },
            "392": { icon: "thunderstorm",        svg: "thunderstorms" },
            "395": { icon: "thunderstorm",        svg: "blizzard" }
        }

        const nightIconMap = {
            "113": { icon: "clear_night",           svg: "clear_night" },
            "116": { icon: "partly_cloudy_night",   svg: "cloudy_with_sunny" },
            "119": { icon: "cloud",                 svg: "cloudy" },
            "122": { icon: "cloud",                 svg: "cloudy" },
            "143": { icon: "foggy",                 svg: "cloudy" },
            "176": { icon: "rainy_light",           svg: "cloudy_with_rain" },
            "179": { icon: "weather_snowy",         svg: "cloudy_with_snow" },
            "182": { icon: "cloudy_snowing",        svg: "rain_with_snow" },
            "185": { icon: "cloudy_snowing",        svg: "rain_with_snow" },
            "200": { icon: "thunderstorm",          svg: "thunderstorms" },
            "227": { icon: "weather_snowy",         svg: "blowing_snow" },
            "230": { icon: "weather_snowy",         svg: "blizzard" },
            "248": { icon: "foggy",                 svg: "cloudy" },
            "260": { icon: "foggy",                 svg: "cloudy" },
            "263": { icon: "grain",                 svg: "drizzle" },
            "266": { icon: "grain",                 svg: "drizzle" },
            "281": { icon: "grain",                 svg: "drizzle" },
            "284": { icon: "rainy",                 svg: "cloudy_with_rain" },
            "293": { icon: "rainy_light",           svg: "cloudy_with_rain" },
            "296": { icon: "rainy_light",           svg: "cloudy_with_rain" },
            "299": { icon: "rainy",                 svg: "rain_with_cloudy" },
            "302": { icon: "rainy",                 svg: "rain_with_cloudy" },
            "305": { icon: "rainy_heavy",           svg: "heavy_rain" },
            "308": { icon: "rainy_heavy",           svg: "heavy_rain" },
            "311": { icon: "cloudy_snowing",        svg: "sleet_hail" },
            "314": { icon: "cloudy_snowing",        svg: "sleet_hail" },
            "317": { icon: "cloudy_snowing",        svg: "rain_with_snow" },
            "320": { icon: "cloudy_snowing",        svg: "rain_with_snow" },
            "323": { icon: "weather_snowy",         svg: "cloudy_with_snow" },
            "326": { icon: "weather_snowy",         svg: "cloudy_with_snow" },
            "329": { icon: "weather_snowy",         svg: "heavy_snow" },
            "332": { icon: "weather_snowy",         svg: "heavy_snow" },
            "335": { icon: "ac_unit",               svg: "blizzard" },
            "338": { icon: "ac_unit",               svg: "blizzard" },
            "350": { icon: "ac_unit",               svg: "sleet_hail" },
            "353": { icon: "rainy_light",           svg: "drizzle" },
            "356": { icon: "rainy",                 svg: "rain_with_cloudy" },
            "359": { icon: "rainy_heavy",           svg: "heavy_rain" },
            "362": { icon: "cloudy_snowing",        svg: "rain_with_snow" },
            "365": { icon: "cloudy_snowing",        svg: "rain_with_snow" },
            "368": { icon: "weather_snowy",         svg: "flurries" },
            "371": { icon: "ac_unit",               svg: "heavy_snow" },
            "374": { icon: "ac_unit",               svg: "sleet_hail" },
            "377": { icon: "ac_unit",               svg: "sleet_hail" },
            "386": { icon: "thunderstorm",          svg: "strong_thunderstorms" },
            "389": { icon: "thunderstorm",          svg: "strong_thunderstorms" },
            "392": { icon: "thunderstorm",          svg: "thunderstorms" },
            "395": { icon: "thunderstorm",          svg: "blizzard" }
        }

        const iconMap = isNight ? nightIconMap : dayIconMap
        return iconMap[code] || (isNight
            ? { icon: "clear_night", svg: "clear_night" }
            : { icon: "clear_day",   svg: "sunny" }
        )
    }

    readonly property var weatherIconPath: getWeatherIcon(weatherCode)
}
