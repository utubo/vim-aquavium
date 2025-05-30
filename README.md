# vim-aquavium

(Requirements Vim9.1 and +tabpanel)

## Show 🐟 in current window!
![image](https://github.com/user-attachments/assets/5960e264-6475-4415-91dc-398c22eb0957)

```vim
packadd vim-aquavium
call aquavium#Show()
```

The tank is a buffer, so you can close aquavium with `:q` or `:bd %` or, among others.

Also you can see 🐟 in popup window.

```vim
vim9script
const winid = popup_create('', { minwidth: 20, minheight: 10 })
win_execute(winid, 'call aquavium#Show()')
```
![image](https://github.com/user-attachments/assets/8e7e83b2-3990-473b-a5ef-986d41be69b7)

And in tabpanel.

```vim
set tabpanel=%!aquavium#TabPanel()
set showtabpanel=2
```
![image](https://github.com/user-attachments/assets/a404d444-8276-4af2-aaa7-ed9f46f6e451)


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

