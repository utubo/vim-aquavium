vim9script

var INTERVAL = 0.2
const CONCENTRATION = 0.03
const FISH_TYPES = [
  { type: 'F', char: '🐟', hi: 'B', dx: [-3, -4, -5], dy: [-1, 0, 1]},
  { type: 'C', char: '🦀', hi: 'R', dx: [-4, -3, 3, 4], dy: '$' },
  # So many fish dazzle my eyes.
  # { type: 'E', char: '🐠', hi: 'Y', dx: [-3, -4], dy: [-1, 1]},
  # { type: 'O', char: '🐙', hi: 'R', dx: [-1, 1], dy: [-1, 1] },
]

# Color {{{
def ColorScheme()
  hi Aquarium  guibg=#0096db ctermbg=39
  hi AquariumB guibg=#0096db ctermbg=39 guifg=#005fd7 ctermfg=26
  hi AquariumR guibg=#0096db ctermbg=39 guifg=#af0000 ctermfg=124
  # hi AquariumY ctermbg=39 ctermfg=221
enddef

ColorScheme()

augroup aquavium
  autocmd!
  autocmd ColorScheme * ColorScheme()
augroup END
# }}}

# Timer {{{
var winids = []
def Timer(_: number)
  if !!tabp_cache
    redrawtabpanel
  endif
  for w in winids->copy()
    UpdateWindow(w)
  endfor
enddef

const timer = get(g:, 'aquavium_timer', 0)
if !!timer
  timer_stop(timer)
endif

g:aquavium_timer = timer_start(
  float2nr(INTERVAL * 1000),
  Timer,
  { repeat: -1 }
)
# }}}

# Main {{{
def InitParams(options: dict<any> = {}): dict<any>
  return {
    initialized: true,
    fish: [],
  }->extend(options)
enddef

def Rendar(bufnr: number, options: dict<any> = {}): list<string>
  var params = {
    width: &columns,
    height: &lines,
    fish: [],
    tabpane: 0,
  }->extend(options)
  params.max_y = params.height - 1
  Spawn(params)
  MoveFish(params)
  options->extend(params)
  var tank = [' '->repeat(params.width)]->repeat(params.height)
  for fish in params.fish
    tank[fish.y] = tank[fish.y]
      ->substitute($'\%{fish.x}v.\+\%{fish.x + fish.w}v', fish.char, '')
  endfor
  const tranc = $'\%{params.width + 1}v.*'
  for i in tank->len()->range()
    tank[i] = tank[i]
      ->substitute(tranc, '', '')
    if bufnr !=# -1
      setbufline(bufnr, i + 1, tank[i])
    endif
  endfor
  return tank
enddef

def Spawn(params: dict<any>)
  const c = get(params, 'concentration', CONCENTRATION)
  if params.width * params.height * c < params.fish->len()
    return
  endif
  const t = FISH_TYPES[rand() % FISH_TYPES->len()]
  var fish = t->copy()->extend({
    x: (t.dx ==# [-1] ? 1 : rand() % 2) * params.width,
    y: rand() % params.height,
    w: strdisplaywidth(t.char),
    id: rand(),
  })
  if !Collide(fish, params.fish)
    fish.to_x = fish.x
    fish.to_y = fish.y
    params.fish->add(fish)
  endif
enddef

def MoveFish(params: dict<any>)
  var newlist = []
  for fish in params.fish
    MoveOneFish(fish, params)
    if fish.x < 1 || params.width < fish.x
      continue
    endif
    newlist->add(fish)
  endfor
  params.fish = newlist
enddef

def MoveOneFish(fish: dict<any>, params: dict<any>)
  var old_x = fish.x
  var old_y = fish.y
  if fish.x !=# fish.to_x || fish.y !=# fish.to_y
    fish.x += Sign(fish.to_x - fish.x)
    fish.y += Sign(fish.to_y - fish.y)
  elseif rand() % 3 ==# 0
    SetNextXY(fish, params)
  endif
  if fish.dy[0]->type() !=# v:t_number
    fish.y = params.max_y
    fish.to_y = fish.y
  endif
  if Collide(fish, params.fish)
    fish.x = old_x
    fish.y = old_y
    SetNextXY(fish, params)
  endif
enddef

def SetNextXY(fish: dict<any>, params: dict<any>)
  fish.to_x = fish.x + Pick(fish.dx)
  if fish.dy[0]->type() ==# v:t_number
    fish.to_y = (fish.y + Pick(fish.dy))->InRange(0, params.max_y)
  endif
enddef

def Collide(fish: dict<any>, all: list<any>): bool
  for f in all
    if f.id ==# fish.id
      continue
    endif
    if f.y !=# fish.y
      continue
    endif
    if fish.x + fish.w < f.x
      continue
    endif
    if f.x + f.w < fish.x
      continue
    endif
    return true
  endfor
  return false
enddef

def Sign(a: number): number
  return a < 0 ? -1 : a > 0 ? 1 : 0
enddef

def InRange(a: number, b: number, c: number): number
  return [a, b, c]->sort('n')[1]
enddef

def Pick(l: list<any>): any
  return l[rand() % l->len()]
enddef
# }}}

# Show in window {{{
export def Show(options: dict<any> = {})
  const w = win_getid()
  const is_popup = popup_list()->index(w) !=# -1
  var b = 0
  var params = InitParams(options)
  if is_popup
    b = winbufnr(w)
  else
    b = bufadd($'aquavium-{rand()}')
    execute 'buffer' b
  endif
  params.bufnr = b
  ColorWindow(w)
  setwinvar(w, 'aquavium', params)
  UpdateWindow(w)
  winids->add(w)
enddef

def ColorWindow(winid: number)
  win_execute(winid, 'syntax match Aquarium / /')
  for t in FISH_TYPES
    win_execute(winid, $'syntax keyword Aquarium{t.hi} {t.char}')
  endfor
  win_execute(winid, 'setlocal nolist nocursorline nocursorcolumn')
enddef

def UpdateWindow(w: number)
  const infos = getwininfo(w)
  if infos->empty()
    silent! winids->remove(winids->index(w))
    return
  endif
  const info = infos[0]
  var params = getwinvar(w, 'aquavium', {})
  if params->empty()
    return
  endif
  if info.bufnr !=# params.bufnr
    return
  endif
  params.width = info.width
  params.height = info.height
  const tank = Rendar(-1, params)
  var i = 0
  for t in tank
    i += 1
    setbufline(info.bufnr, i, t)
  endfor
  win_execute(w, 'setlocal nomodified')
enddef
# }}}

# Show in tabPanel {{{
var tabp_params = {}
var tabp_cache = ''
var tabp_tick = reltime()

export def TabPanel(options: dict<any> = {}): string
  if g:actual_curtabpage ==# 1
    return TabPanelPart(options)
  else
    return ''
  endif
enddef

export def TabPanelPart(options: dict<any> = {}): string
  try
    if !tabp_params->empty()
      const tick = reltime(tabp_tick)->reltimefloat()
      if tick < INTERVAL
        return tabp_cache
      endif
    endif
    tabp_tick = reltime()
    const width = TabPanelWidth()
    const height = get(options, 'height', 0) ?? &lines - &cmdheight
    if tabp_params->empty()
      tabp_params = InitParams(options)
    endif
    var params = tabp_params
    params.width = width
    params.height = height
    const tank = Rendar(-1, params)
    tabp_cache = tank
      ->ColoredForTabPanel()
      ->join("\n")
  catch
    return $'{v:exception}'
  endtry
  return tabp_cache
enddef

export def TabPanelReset()
  tabp_params = {}
enddef

def TabPanelWidth(): number
  const c = &tabpanelopt
    ->matchstr('\(columns:\)\@<=\d\+') ?? '20'
  return c->str2nr()
enddef

def ColoredForTabPanel(src: list<string>): list<string>
  var colored = []
  for s in src
    var c = s
      ->substitute("^", '%#Aquarium#', '')
    for t in FISH_TYPES
      c = c->substitute(
        t.char,
        $'%#Aquarium{t.hi}#{t.char}%#Aquarium#',
        'g'
      )
    endfor
    colored->add(c)
  endfor
  return colored
enddef
# }}}

