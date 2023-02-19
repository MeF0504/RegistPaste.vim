# RegistPaste.vim

Vim plugin to paste text from registered.
<img src=images/registpaste.gif width="70%">

## Usage
The function `registpaste#enable()` starts collecting the yanked strings
and overwrites p/P map.  
If you want to disable this plugin please call `registpaste#disable()`.
This function stops all functions and resets p/P map if `mapset()` callable.

Currently
- support block-paste (block register shows [b] mark in the list.)
- support . repeat by using [vim-repeat](https://github.com/tpope/vim-repeat)
- support `]p`, `[p`, and `zp`.

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
- `g:registpaste_is_filter` (number)  
    If set 1, remove the duplicated item in the registered list.  
    Note that this only checks the string; regtype is not checked.  
    default: 1
- `g:registpaste_used_register` (character)  
    Set the register name used to store the selected string.  
    default: '"'
- `g:registpaste_use_clipboard` (number)  
    If set 1, this plugin also refers to the "*" or "+" register when pasting.  
    `g:registpaste_is_filter = 1` is required.
    default: 1
- `g:registpaste_max_width (number)  
    Set the max width of popup/floating window.  
    default: &columns*2/3
- `g:registpaste_maps` (dict)  
    Control the mapping of this plugin.
    Keys of this dict are selected from `p, P, zp, zP, [p, [P, ]p, ]P`.
    Value of this dict is the overwriting mapping of the function of the key;
    mean `nnoremap {value} {key}`.  
    default:`{'p':'p', 'P':'P', 'zp':'zp', 'zP':'zP', '[p':'[p', '[P':'[P', ']P':']P', ']p':']p'}`

## License
[MIT](https://github.com/MeF0504/RegistPaste.vim/blob/main/LICENSE)

## Author
[MeF0504](https://github.com/MeF0504)

## TODO
- Support clipboard sharing?  
    Specifications are not fixed. This may take time...
- Become selectable the pasting text from locally stored list or registers.  
    Currently there is no motivation to do this. Please put an issue if you want.
