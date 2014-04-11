terminal-status
===============

## Usage
Just press `shift-enter`

## Screenshot

Open multiple terminal.

![A screenshot of terminal-status package](http://guileen.github.io/img/terminal-status/screenshot-1.1.0.gif)

Fancy ls.

![A screenshot of terminal-status package](http://guileen.github.io/img/terminal-status/screenshot-ls.gif)

## Feature

* multiple terminal
* colorful status icon
* kill long live process
* fancy ls

## Hotkeys

* `shift-enter` toggle current terminal
* `command-shift-t` new terminal
* `command-shift-j` next terminal
* `command-shift-k` prev terminal

## Changelog

* 1.3.4
  * use `child_process.exec` instead of `child_process.spawn`, support pipe like command

* 1.3.3
  * source ~/.profile and /etc/profile for environment variables.

* 1.3.2
  * fix PATH of /usr/local/bin
  * support ~
