# RegistPaste.vim

Vim plugin to paste text from registered.
<img src=images/registpaste.gif width="70%">

## Usage
The function `registpaste#enable()` starts collecting the yanked strings
and overwrites p/P map.  
If you want to disable this plugin please call `registpaste#disable()`.
This function stops all functions and resets p/P map if `mapset()` callable.

## Requirements
- popup/floating window  
    `has('popupwin') || exists('*nvim_open_win')`
- TextYankPost event  
    `exists('##TextYankPost')`
- win_execute function  
    `exists('*win_execute')`
- and more...? (please let me know if you have any problem.)

## Installation

For [vim-plug](https://github.com/junegunn/vim-plug) plugin manager:

```
Plug 'MeF0504/RegistPaste.vim'
```

## Options

- `g:registpaste_auto_enable` (number)  
    If set 1, run `registpaste#enable()` when vim starts.  
    default: 1
- `g:registpaste_max_reg` (number)  
    Set the max holding number of yanked strings.  
    default: 10
- `g:registpaste_max_width (number)  
    Set the max width of popup/floating window.
    default: &columns*2/3

## License
[MIT](https://github.com/MeF0504/RegistPaste.vim/blob/main/LICENSE)

## Author
[MeF0504](https://github.com/MeF0504)

## TODO
- Support `]p`, `[p`, and `zp`.
- Support '.' repeat.
