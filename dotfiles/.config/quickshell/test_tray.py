#!/usr/bin/env python3
"""
Test System Tray Application
Creates a system tray icon with various menu types for testing
"""

import sys
from PyQt6.QtWidgets import QApplication, QSystemTrayIcon, QMenu
from PyQt6.QtGui import QIcon, QAction
from PyQt6.QtCore import Qt

class TestTrayApp:
    def __init__(self):
        self.app = QApplication(sys.argv)
        self.app.setQuitOnLastWindowClosed(False)

        # Create system tray icon
        self.tray = QSystemTrayIcon()

        # Create an icon (using a standard icon as fallback)
        icon = QIcon.fromTheme("applications-system")
        if icon.isNull():
            # Fallback if theme icon not available
            icon = self.app.style().standardIcon(self.app.style().StandardPixmap.SP_ComputerIcon)
        self.tray.setIcon(icon)

        # Create menu
        self.menu = QMenu()
        self.create_menu()

        self.tray.setContextMenu(self.menu)
        self.tray.show()

        print("System tray icon created. Right-click to see menu.")
        print("Menu includes: regular items, checkboxes, submenus, and separators")

    def create_menu(self):
        # Regular item
        action1 = QAction("Open Application", self.menu)
        action1.triggered.connect(lambda: print("Open Application clicked"))
        self.menu.addAction(action1)

        # Separator
        self.menu.addSeparator()

        # Checkable items
        check1 = QAction("Enable Notifications", self.menu)
        check1.setCheckable(True)
        check1.setChecked(True)
        check1.triggered.connect(lambda checked: print(f"Notifications: {checked}"))
        self.menu.addAction(check1)

        check2 = QAction("Auto Start", self.menu)
        check2.setCheckable(True)
        check2.setChecked(False)
        check2.triggered.connect(lambda checked: print(f"Auto Start: {checked}"))
        self.menu.addAction(check2)

        check3 = QAction("Show in Dock", self.menu)
        check3.setCheckable(True)
        check3.setChecked(True)
        check3.triggered.connect(lambda checked: print(f"Show in Dock: {checked}"))
        self.menu.addAction(check3)

        # Separator
        self.menu.addSeparator()

        # Submenu with items
        settings_menu = QMenu("Settings", self.menu)

        pref1 = QAction("Preferences", settings_menu)
        pref1.triggered.connect(lambda: print("Preferences clicked"))
        settings_menu.addAction(pref1)

        pref2 = QAction("Advanced Settings", settings_menu)
        pref2.triggered.connect(lambda: print("Advanced Settings clicked"))
        settings_menu.addAction(pref2)

        settings_menu.addSeparator()

        # Nested submenu
        theme_menu = QMenu("Theme", settings_menu)

        theme1 = QAction("Light", theme_menu)
        theme1.setCheckable(True)
        theme1.triggered.connect(lambda: print("Light theme selected"))
        theme_menu.addAction(theme1)

        theme2 = QAction("Dark", theme_menu)
        theme2.setCheckable(True)
        theme2.setChecked(True)
        theme2.triggered.connect(lambda: print("Dark theme selected"))
        theme_menu.addAction(theme2)

        theme3 = QAction("Auto", theme_menu)
        theme3.setCheckable(True)
        theme3.triggered.connect(lambda: print("Auto theme selected"))
        theme_menu.addAction(theme3)

        settings_menu.addMenu(theme_menu)

        self.menu.addMenu(settings_menu)

        # Another submenu
        help_menu = QMenu("Help", self.menu)

        help1 = QAction("Documentation", help_menu)
        help1.triggered.connect(lambda: print("Documentation clicked"))
        help_menu.addAction(help1)

        help2 = QAction("About", help_menu)
        help2.triggered.connect(lambda: print("About clicked"))
        help_menu.addAction(help2)

        self.menu.addMenu(help_menu)

        # Separator
        self.menu.addSeparator()

        # Regular items
        refresh = QAction("Refresh", self.menu)
        refresh.triggered.connect(lambda: print("Refresh clicked"))
        self.menu.addAction(refresh)

        # Separator
        self.menu.addSeparator()

        # Quit action
        quit_action = QAction("Quit", self.menu)
        quit_action.triggered.connect(self.quit)
        self.menu.addAction(quit_action)

    def quit(self):
        print("Quitting...")
        self.tray.hide()
        self.app.quit()

    def run(self):
        return self.app.exec()

if __name__ == "__main__":
    app = TestTrayApp()
    sys.exit(app.run())
