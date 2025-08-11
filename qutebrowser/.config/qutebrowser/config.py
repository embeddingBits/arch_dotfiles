#  |||||||||||     ||||||||     |\\       ||  ||||||||||||
# ||||           ||||||||||||   ||\\      ||  ||
#|||            ||||      ||||  || \\     ||  ||
#||             |||        |||  ||  \\    ||  ||
#||             |||        |||  ||   \\   ||  ||||||||
#||             |||        |||  ||    \\  ||  ||
#||             |||        |||  ||     \\ ||  ||
#|||            ||||      ||||  ||      \\||  ||
# ||||           ||||||||||||   ||       \||  ||
#  |||||||||||     ||||||||     ||        \|  ||


nord = {
    'base03': '#3b4252',
    'base02': '#434c5e',
    'base01': '#e5e9f0',
    'base00': '#d8dee9',
    'base0': '#4c566a',
    'base1': '#5e81ac',
    'base2': '#eee8d5',
    'base3': '#eceff4',
    'yellow': '#ebcb8b',
    'orange': '#ebcb8b',
    'red': '#bf616a',
    'magenta': '#b48ead',
    'violet': '#8fbcbb',
    'blue': '#5e81ac',
    'cyan': '#81a1c1',
    'green': '#a3be8c'
}

c.fonts.default_family = 'JetBrainsMono Nerd Font'
c.fonts.default_size = '12pt'
c.fonts.web.family.standard = "JetBrainsMono Nerd Font"
c.fonts.web.family.fixed = "JetBrainsMono Nerd Font"
c.fonts.web.family.serif = "JetBrainsMono Nerd Font"
c.fonts.web.family.sans_serif = "JetBrainsMono Nerd Font"
c.fonts.web.size.default = 16
c.fonts.web.size.default_fixed = 14
c.fonts.web.size.minimum = 8


## Background color of the completion widget category headers.
## Type: QssColor
c.colors.completion.category.bg = nord['base03']

## Bottom border color of the completion widget category headers.
## Type: QssColor
c.colors.completion.category.border.bottom = nord['base03']

## Top border color of the completion widget category headers.
## Type: QssColor
c.colors.completion.category.border.top = nord['base03']

## Foreground color of completion widget category headers.
## Type: QtColor
c.colors.completion.category.fg = nord['base3']

## Background color of the completion widget for even rows.
## Type: QssColor
c.colors.completion.even.bg = nord['base02']

## Text color of the completion widget.
## Type: QtColor
c.colors.completion.fg = nord['base3']

## Background color of the selected completion item.
## Type: QssColor
c.colors.completion.item.selected.bg = nord['violet']

## Bottom border color of the selected completion item.
## Type: QssColor
c.colors.completion.item.selected.border.bottom = nord['violet']

## Top border color of the completion widget category headers.
## Type: QssColor
c.colors.completion.item.selected.border.top = nord['violet']

## Foreground color of the selected completion item.
## Type: QtColor
c.colors.completion.item.selected.fg = nord['base3']

## Foreground color of the matched text in the completion.
## Type: QssColor
c.colors.completion.match.fg = nord['base2']

## Background color of the completion widget for odd rows.
## Type: QssColor
c.colors.completion.odd.bg = nord['base02']

## Color of the scrollbar in completion view
## Type: QssColor
c.colors.completion.scrollbar.bg = nord['base0']

## Color of the scrollbar handle in completion view.
## Type: QssColor
c.colors.completion.scrollbar.fg = nord['base2']

## Background color for the download bar.
## Type: QssColor
c.colors.downloads.bar.bg = nord['base03']

## Background color for downloads with errors.
## Type: QtColor
c.colors.downloads.error.bg = nord['red']

## Foreground color for downloads with errors.
## Type: QtColor
c.colors.downloads.error.fg = nord['base3']

## Color gradient start for download backgrounds.
## Type: QtColor
# c.colors.downloads.start.bg = '#0000aa'

## Color gradient start for download text.
## Type: QtColor
c.colors.downloads.start.fg = nord['base3']

## Color gradient stop for download backgrounds.
## Type: QtColor
# c.colors.downloads.stop.bg = '#00aa00'

## Color gradient end for download text.
## Type: QtColor
# c.colors.downloads.stop.fg = nord['base3']

## Color gradient interpolation system for download backgrounds.
## Type: ColorSystem
## Valid values:
##   - rgb: Interpolate in the RGB color system.
##   - hsv: Interpolate in the HSV color system.
##   - hsl: Interpolate in the HSL color system.
##   - none: Don't show a gradient.
# c.colors.downloads.system.bg = 'rgb'

## Color gradient interpolation system for download text.
## Type: ColorSystem
## Valid values:
##   - rgb: Interpolate in the RGB color system.
##   - hsv: Interpolate in the HSV color system.
##   - hsl: Interpolate in the HSL color system.
##   - none: Don't show a gradient.
# c.colors.downloads.system.fg = 'rgb'

## Background color for hints. Note that you can use a `rgba(...)` value
## for transparency.
## Type: QssColor
c.colors.hints.bg = nord['violet']

## Font color for hints.
## Type: QssColor
c.colors.hints.fg = nord['base3']

## Font color for the matched part of hints.
## Type: QssColor
c.colors.hints.match.fg = nord['base2']

## Background color of the keyhint widget.
## Type: QssColor
# c.colors.keyhint.bg = 'rgba(0, 0, 0, 80%)'

## Text color for the keyhint widget.
## Type: QssColor
c.colors.keyhint.fg = nord['base3']

## Highlight color for keys to complete the current keychain.
## Type: QssColor
c.colors.keyhint.suffix.fg = nord['yellow']

## Background color of an error message.
## Type: QssColor
c.colors.messages.error.bg = nord['red']

## Border color of an error message.
## Type: QssColor
c.colors.messages.error.border = nord['red']

## Foreground color of an error message.
## Type: QssColor
c.colors.messages.error.fg = nord['base3']

## Background color of an info message.
## Type: QssColor
c.colors.messages.info.bg = nord['base03']

## Border color of an info message.
## Type: QssColor
c.colors.messages.info.border = nord['base03']

## Foreground color an info message.
## Type: QssColor
c.colors.messages.info.fg = nord['base3']

## Background color of a warning message.
## Type: QssColor
c.colors.messages.warning.bg = nord['orange']

## Border color of a warning message.
## Type: QssColor
c.colors.messages.warning.border = nord['orange']

## Foreground color a warning message.
## Type: QssColor
c.colors.messages.warning.fg = nord['base3']

## Background color for prompts.
## Type: QssColor
c.colors.prompts.bg = nord['base02']

## Border used around UI elements in prompts.
## Type: String
c.colors.prompts.border = '1px solid ' + nord['base3']

## Foreground color for prompts.
## Type: QssColor
c.colors.prompts.fg = nord['base3']

## Background color for the selected item in filename prompts.
## Type: QssColor
c.colors.prompts.selected.bg = nord['base01']

## Background color of the statusbar in caret mode.
## Type: QssColor
c.colors.statusbar.caret.bg = nord['blue']

## Foreground color of the statusbar in caret mode.
## Type: QssColor
c.colors.statusbar.caret.fg = nord['base3']

## Background color of the statusbar in caret mode with a selection.
## Type: QssColor
c.colors.statusbar.caret.selection.bg = nord['violet']

## Foreground color of the statusbar in caret mode with a selection.
## Type: QssColor
c.colors.statusbar.caret.selection.fg = nord['base3']

## Background color of the statusbar in command mode.
## Type: QssColor
c.colors.statusbar.command.bg = nord['base03']

## Foreground color of the statusbar in command mode.
## Type: QssColor
c.colors.statusbar.command.fg = nord['base3']

## Background color of the statusbar in private browsing + command mode.
## Type: QssColor
c.colors.statusbar.command.private.bg = nord['base01']

## Foreground color of the statusbar in private browsing + command mode.
## Type: QssColor
c.colors.statusbar.command.private.fg = nord['base3']

## Background color of the statusbar in insert mode.
## Type: QssColor
c.colors.statusbar.insert.bg = nord['green']

## Foreground color of the statusbar in insert mode.
## Type: QssColor
c.colors.statusbar.insert.fg = nord['base3']

## Background color of the statusbar.
## Type: QssColor
c.colors.statusbar.normal.bg = nord['base03']

## Foreground color of the statusbar.
## Type: QssColor
c.colors.statusbar.normal.fg = nord['base3']

## Background color of the statusbar in passthrough mode.
## Type: QssColor
c.colors.statusbar.passthrough.bg = nord['magenta']

## Foreground color of the statusbar in passthrough mode.
## Type: QssColor
c.colors.statusbar.passthrough.fg = nord['base3']

## Background color of the statusbar in private browsing mode.
## Type: QssColor
c.colors.statusbar.private.bg = nord['base01']

## Foreground color of the statusbar in private browsing mode.
## Type: QssColor
c.colors.statusbar.private.fg = nord['base3']

## Background color of the progress bar.
## Type: QssColor
c.colors.statusbar.progress.bg = nord['base3']

## Foreground color of the URL in the statusbar on error.
## Type: QssColor
c.colors.statusbar.url.error.fg = nord['red']

## Default foreground color of the URL in the statusbar.
## Type: QssColor
c.colors.statusbar.url.fg = nord['base3']

## Foreground color of the URL in the statusbar for hovered links.
## Type: QssColor
c.colors.statusbar.url.hover.fg = nord['base2']

## Foreground color of the URL in the statusbar on successful load
## (http).
## Type: QssColor
c.colors.statusbar.url.success.http.fg = nord['base3']

## Foreground color of the URL in the statusbar on successful load
## (https).
## Type: QssColor
c.colors.statusbar.url.success.https.fg = nord['base3']

## Foreground color of the URL in the statusbar when there's a warning.
## Type: QssColor
c.colors.statusbar.url.warn.fg = nord['yellow']

## Background color of the tab bar.
## Type: QtColor
# c.colors.tabs.bar.bg = '#555555'

## Background color of unselected even tabs.
## Type: QtColor
c.colors.tabs.even.bg = nord['base01']

## Foreground color of unselected even tabs.
## Type: QtColor
c.colors.tabs.even.fg = nord['base2']

## Color for the tab indicator on errors.
## Type: QtColor
c.colors.tabs.indicator.error = nord['red']

## Color gradient start for the tab indicator.
## Type: QtColor
c.colors.tabs.indicator.start = nord['violet']

## Color gradient end for the tab indicator.
## Type: QtColor
c.colors.tabs.indicator.stop = nord['orange']

## Color gradient interpolation system for the tab indicator.
## Type: ColorSystem
## Valid values:
##   - rgb: Interpolate in the RGB color system.
##   - hsv: Interpolate in the HSV color system.
##   - hsl: Interpolate in the HSL color system.
##   - none: Don't show a gradient.
# c.colors.tabs.indicator.system = 'rgb'

## Background color of unselected odd tabs.
## Type: QtColor
c.colors.tabs.odd.bg = nord['base01']

## Foreground color of unselected odd tabs.
## Type: QtColor
c.colors.tabs.odd.fg = nord['base2']

## Background color of selected even tabs.
## Type: QtColor
c.colors.tabs.selected.even.bg = nord['base03']

## Foreground color of selected even tabs.
## Type: QtColor
c.colors.tabs.selected.even.fg = nord['base3']

## Background color of selected odd tabs.
## Type: QtColor
c.colors.tabs.selected.odd.bg = nord['base03']

## Foreground color of selected odd tabs.
## Type: QtColor
c.colors.tabs.selected.odd.fg = nord['base3']

config.load_autoconfig()
## Background color for webpages if unset (or empty to use the theme's
## color)
## Type: QtColor
# c.colors.webpage.bg = 'white'
