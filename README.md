# Zobáčik for macOS

Zobáčik is a tiny native menu-bar utility for transforming text on the macOS
clipboard. It is inspired by the classic Slovak Windows program from the days
of email quoting, web forums, SMS gateways, and temperamental text encodings.

Copy text, let Zobáčik change it, then paste it wherever it belongs. There is no
editor window and no setup: the whole app lives behind a small `>` in the menu
bar.

## What it does

### Remove Diacritics

Converts Central European text to a plain Latin representation while preserving
letter case and punctuation.

```text
Příliš žluťoučký kůň. → Prilis zlutoucky kun.
Zażółć gęślą jaźń.    → Zazolc gesla jazn.
```

### Quote Lines

Adds the traditional email and forum quote marker to every line.

```text
Hello
How are you?
```

becomes:

```text
> Hello
> How are you?
```

Blank lines become `>` and a final newline remains a final newline.

### Unquote Lines

Removes one leading `>` from each quoted line and trims spaces or tabs directly
after it. Nested quotations therefore lose only one level; unquoted lines remain
unchanged.

```text
> Hello
>> An older reply
```

becomes:

```text
Hello
> An older reply
```

### Undo

**Undo Last Transformation** restores the clipboard text that existed before
the most recent successful action.

## How to use it

1. Copy some text in any application.
2. Click `>` in the menu bar.
3. Choose a transformation.
4. Paste the result.

The `>` briefly changes to `✓` when the clipboard is updated. Zobáčik beeps if
the clipboard does not contain text or the chosen action would make no change.

## Shortcuts

| Action | Shortcut |
| --- | --- |
| Remove Diacritics | `⌥⌘D` |
| Quote Lines | `⌥⌘Q` |
| Unquote Lines | `⌥⌘U` |
| Undo Last Transformation | `⌘Z` |
| Quit Zobáčik | `⌘Q` |

These are menu shortcuts rather than system-wide hotkeys. Click `>` to open the
Zobáčik menu, then use the shortcut.

## Why the name?

The `>` used to quote replies looks a little like a beak—a *zobáčik*. In long
email chains and forum threads, rows of those little beaks showed who had said
what, and how many replies ago they had said it.

## Credits

The original Zobáčik for Windows was created by **Robert Vašíček**. A
[contemporary Živé.sk article](https://zive.aktuality.sk/clanok/16441/ako-odstranit-diakritiku-ci-uzivatelsky-formatovat-text-nielen-v-e-mailoch/)
from 2004 preserves its story and describes version 1.5.

This macOS edition was created by **Jakub Petrik with OpenAI Codex**.

## A small poem for the old web

> When forums hummed through modem nights,<br>
> and email crossed in borrowed bytes,<br>
> the accents—mäkčeň, dĺžeň—lost their way,<br>
> so č became c to save the day.
>
> Each quoted voice wore `>` with pride,<br>
> old conversations nested inside.<br>
> The web grew quick; those days went by—<br>
> Zobáčik kept each thread nearby.
>
> Now Unicode can carry all,<br>
> yet sometimes older habits call.<br>
> One little beak, one useful trick:<br>
> long live the tiny Zobáčik.

## Build and run

Zobáčik requires macOS 13 or newer and the Xcode command-line tools.

```sh
make test
make app
open "build/Zobáčik.app"
```

The finished app is written in AppKit with no third-party dependencies. It has
no Dock icon, windows, preferences, analytics, network access, or background
helper. It reads the clipboard only when you choose an action.
