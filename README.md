# vim-aquavium

(Requirements Vim9.1 and +tabpanel)

## Show 🐟 in current window!

```vim
packadd vim-aquavium
call aquavium#Show()
```

The tank is a buffer, so you can close aquavium with `:q` or `:bd %` or, among others.

Also you can see 🐟 in popup window.

```vim
vim9script
const winid = popup_create('', { width: 20, height: 10 })
win_execute(winid, 'call aquavium#Show()')
```

And in tabpanel.

```vim
set tabpanel=#!aquavium#TabPanel()
set showtabpanel=2
```

You can use `aquavium#TabPanelPart()` in your tabpanel.

e.g.

```vim
vim9script
def! g:YourTabPanel(): string
  var label = gettabbuflist(g:actual_curtabpage)[0]->bufname()
  if g:actual_curtabpage ==# 1
    label = $"{TabPanelPart({ height: 5 })}\n{label}"
  endif
  return label
enddef
set tabpanel=#!g:YourTabPanel()
set showtabpanel=2
```

## License

[NYSL 0.9982](https://www.kmonos.net/nysl/)

