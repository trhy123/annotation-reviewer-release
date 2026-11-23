-- 只变更排版，不改写正文。基于 Pandoc 的 GFM 解析器。
local first_header = true
local navigation_labels = {['Return to the main contents']=true, ['Return to the main index']=true}
local heading_contents = {}
local symbols = {['⊠']=true, ['★']=true, ['↶']=true, ['↷']=true, ['↔']=true, ['↗']=true}
local function latex_escape(s)
  local chars = {['\\']='\\textbackslash{}',['{']='\\{',['}']='\\}',
    ['%']='\\%',['#']='\\#',['&']='\\&',['_']='\\_',
    ['$']='\\$',['~']='\\textasciitilde{}',['^']='\\textasciicircum{}'}
  return (s:gsub('[\\{}%%#&_$~^]', chars))
end
local function breakable(text)
  local out, run = {}, 0
  for _, cp in utf8.codes(text) do
    local ch = utf8.char(cp)
    out[#out+1] = symbols[ch] and ('{\\symbolfont '..ch..'}') or latex_escape(ch)
    run = ch:match('[A-Za-z0-9]') and run + 1 or 0
    if ch:match('[_/%.%-%:,=]') or run >= 8 then
      out[#out+1] = '\\allowbreak{}'; run = 0
    end
  end
  return table.concat(out)
end
local function code_inline(el)
  return pandoc.RawInline('latex', '\\texttt{' .. breakable(el.text) .. '}')
end
local function header(el)
  if first_header then first_header = false; return {} end
  el.content = pandoc.walk_block(el, {Code=function(c) return pandoc.Str(c.text) end}).content
  heading_contents[el.identifier] = el.content
  return el
end
-- 五号正文、180 mm 版心、每侧 5 pt 单元格内边距。
-- 用字体近似字宽估计折行，在 1% 列宽网格上动态规划，最小化所有单元格的额外行数。
local font_size, text_width, cell_padding = 10.5, 510.24, 10
local function char_width(ch, mono)
  if mono then return .6 * font_size end
  if ch:match('[ilI.,:;!|\']') then return .28 * font_size end
  if ch:match('[mwMW@]') then return .83 * font_size end
  if ch:match('[A-Z]') then return .67 * font_size end
  if ch:match('%d') then return .5 * font_size end
  return .48 * font_size
end
local function cell_tokens(cell)
  local tokens = {}
  local function add_text(s, mono)
    local word_width, run = 0, 0
    local function flush()
      if word_width > 0 then tokens[#tokens+1] = {width=word_width}; word_width, run = 0, 0 end
    end
    for _, cp in utf8.codes(s) do
      local ch = utf8.char(cp)
      if cp > 255 then
        flush(); tokens[#tokens+1] = {width=font_size}
      elseif ch:match('%s') then
        flush(); tokens[#tokens+1] = {width=(mono and .6 or .25)*font_size, space=true}
      else
        word_width = word_width + char_width(ch, mono); run = run + 1
        if ch:match('[/%-]') or (mono and (ch:match('[_%.%:,=]') or run >= 8)) then flush() end
      end
    end
    flush()
  end
  local function inlines(items)
    for _, item in ipairs(items) do
      if item.t == 'Str' or item.t == 'Code' or item.t == 'Math' then
        add_text(item.text, item.t == 'Code')
      elseif item.t == 'LineBreak' or (item.t == 'RawInline' and item.text:match('^<br')) then
        tokens[#tokens+1] = {hard=true}
      elseif item.t == 'Space' or item.t == 'SoftBreak' then
        tokens[#tokens+1] = {width=.25*font_size, space=true}
      elseif item.content then inlines(item.content) end
    end
  end
  for i, block in ipairs(cell.contents) do
    if i > 1 then tokens[#tokens+1] = {hard=true} end
    if block.content then inlines(block.content) else add_text(pandoc.utils.stringify(block), false) end
  end
  return tokens
end
local function line_count(tokens, width)
  local lines, used, space = 1, 0, 0
  for _, token in ipairs(tokens) do
    if token.hard then lines, used, space = lines+1, 0, 0
    elseif token.space then space = used > 0 and token.width or 0
    else
      if used > 0 and used + space + token.width > width + .01 then lines, used = lines+1, token.width
      else used = used + space + token.width end
      space = 0
    end
  end
  return lines, used
end
local function automatic_widths(columns, available)
  local minima, loads, longest_tokens, scores, costs = {}, {}, {}, {}, {}
  local total_min, total_load, total_score = 0, 0, 0
  local trial_width = available / #columns
  for i, cells in ipairs(columns) do
    local longest, header_min, max_natural, total_natural, area = 0, 0, 0, 0, 0
    for _, tokens in ipairs(cells) do
      local natural = 0
      for _, token in ipairs(tokens) do
        natural = natural + (token.width or 0)
        if not token.space then longest = math.max(longest, token.width or 0) end
      end
      max_natural = math.max(max_natural, natural); total_natural = total_natural + natural
      if tokens.header then header_min = math.max(header_min, math.min(natural * 1.08, trial_width)) end
      local lines, last_width = line_count(tokens, trial_width)
      area = area + (lines-1)*trial_width + last_width
    end
    longest_tokens[i] = math.max(longest, header_min)
    loads[i] = math.sqrt(area); total_load = total_load + loads[i]
    scores[i] = 8 + .65*total_natural/math.max(#cells,1) + .35*math.min(max_natural,420)
    total_score = total_score + scores[i]
  end
  for i = 1, #columns do
    -- 内容量按“已换行行数×试算列宽＋末行已用宽度”估计；长内容列提高最低宽度。
    local content_minimum = .5 * available * loads[i] / math.max(total_load, 1)
    minima[i] = math.max(1, math.ceil(math.max(longest_tokens[i], content_minimum) / available * 100))
    total_min = total_min + minima[i]
  end
  assert(total_min <= 100, 'Unbreakable table content exceeds the available page width.')
  for i, cells in ipairs(columns) do
    costs[i] = {}
    for units = minima[i], 100-total_min+minima[i] do
      local wraps = 0
      for _, tokens in ipairs(cells) do wraps = wraps + line_count(tokens, available*units/100)-1 end
      -- 相同换行数时，选择更接近内容长度比例的列宽。
      costs[i][units] = wraps*1000000 + (units-100*scores[i]/total_score)^2
    end
  end
  local best, choices = {[0]=0}, {}
  for i = 1, #columns do
    local next_best = {}; choices[i] = {}
    for used, prior in pairs(best) do
      for units, cost in pairs(costs[i]) do
        local sum = used+units
        if sum <= 100 and (not next_best[sum] or prior+cost < next_best[sum]) then
          next_best[sum], choices[i][sum] = prior+cost, units
        end
      end
    end
    best = next_best
  end
  local widths, sum = {}, 100
  for i = #columns, 1, -1 do widths[i] = choices[i][sum]; sum = sum-widths[i] end
  return widths
end
local function table_layout(el)
  local cols = #el.colspecs
  local columns = {}
  for i = 1, cols do columns[i] = {} end
  local function rows(rs, is_header)
    for _, row in ipairs(rs) do
      for i, cell in ipairs(row.cells or row[2]) do
        if i <= cols then
          local tokens = cell_tokens(cell); tokens.header = is_header
          columns[i][#columns[i]+1] = tokens
        end
      end
    end
  end
  local head_rows = el.head.rows or el.head[2]
  rows(head_rows, true)
  for _, body in ipairs(el.bodies) do rows(body.head, true); rows(body.body) end
  rows(el.foot.rows or el.foot[2])
  local units = automatic_widths(columns, text_width-cell_padding*cols)
  for i = 1, cols do el.colspecs[i] = {pandoc.AlignLeft, units[i] / 100} end
  for _, row in ipairs(head_rows) do
    for _, cell in ipairs(row.cells or row[2]) do
      for _, block in ipairs(cell.contents) do
        if block.t == 'Plain' or block.t == 'Para' then
          local plain = pandoc.walk_block(block, {
            Code=function(c) return pandoc.Str(c.text) end,
            Emph=function(c) return c.content end,
            Strong=function(c) return c.content end,
          })
          block.content = {pandoc.RawInline('latex', '{\\rmfamily\\tableheaderfont\\bfseries ')}
          for _, inline in ipairs(plain.content) do block.content[#block.content+1] = inline end
          block.content[#block.content+1] = pandoc.RawInline('latex', '}')
        end
      end
    end
  end
  return el
end
local function code_block(el)
  return pandoc.RawBlock('latex', '\\begin{Verbatim}[breaklines=true,breakanywhere=true,breaksymbolleft={},breaksymbolright={},breakanywheresymbolpre={},breakanywheresymbolpost={}]\n' .. el.text .. '\n\\end{Verbatim}')
end
local function document(el)
  local blocks = {}
  for i, block in ipairs(el.blocks) do
    if block.t == 'Header' and block.level > 1 then
      local previous = el.blocks[i-1]
      if not previous or previous.t ~= 'Header' then
        local count, j = 1, i+1
        while el.blocks[j] and el.blocks[j].t == 'Header' do count=count+1; j=j+1 end
        blocks[#blocks+1] = pandoc.RawBlock('latex', '\\Needspace{'..(6+3*(count-1))..'\\baselineskip}')
      else
        blocks[#blocks+1] = pandoc.RawBlock('latex', '\\nopagebreak[4]')
      end
    end
    blocks[#blocks+1] = block
  end
  el.blocks = blocks
  return el
end
local function symbol_text(el)
  local special = false
  if el.text:find('_', 1, true) then special = true end
  for ch in pairs(symbols) do if el.text:find(ch, 1, true) then special = true end end
  for token in el.text:gmatch('[%w_/.%-]+') do if #token > 24 then special = true end end
  if special then
    return pandoc.RawInline('latex', breakable(el.text))
  end
end
local function html_break(el)
  if el.format == 'html' and el.text:lower():match('^<br%s*/?>$') then return pandoc.LineBreak() end
end
local function compact_navigation(el)
  if navigation_labels[pandoc.utils.stringify(el)] then
    return {pandoc.RawBlock('latex', '{\\setlength{\\parskip}{0pt}\\fontsize{10.5}{11}\\selectfont'),
      el, pandoc.RawBlock('latex', '\\par}\\vspace{-2pt}')}
  end
end
local function navigation_link(el)
  if navigation_labels[pandoc.utils.stringify(el.content)] then el.target = '#manual-contents'; return el end
end
local function restore_heading(el)
  -- 让 Pandoc 用原始标题生成完整的 PDF 书签文字，避免 RawInline 被丢弃。
  el.content = heading_contents[el.identifier]
  return pandoc.walk_block(el, {Str=function(word)
    if word.text:find('↔', 1, true) then
      return pandoc.RawInline('latex', latex_escape(word.text):gsub('↔', '\\texorpdfstring{{\\symbolfont ↔}}{↔}'))
    end
  end})
end
return {
  {Header=header, Table=table_layout, HorizontalRule=function() return {} end, Pandoc=document},
  {Header=restore_heading, Str=symbol_text, Code=code_inline, CodeBlock=code_block, RawInline=html_break, Para=compact_navigation, Link=navigation_link},
}
