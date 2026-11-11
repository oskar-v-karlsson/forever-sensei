-- Modules/Guide.lua: the /sensei window. The spec's text tabs come first (the class pack lists them in spec.tabs,
-- for example role, healing, damage, totems and manners) and show their sources; the core's tabs show the skill list,
-- the key layout, the talent order, the translation review and settings. Without a class pack only the translation
-- review and settings are there.
local _, ns = ...
local Guide = {}
ns.Guide = Guide
local UI = ns.UI
local Spells = ns.Spells

local TABS = { "skills", "layout", "talents", "review", "settings" }
local IDLE_TABS = { "review", "settings" }
local WIDTH = 548 -- the scroll area is 550 wide (760 - 176 - 34)
local REVIEW_PAGE = 5

local win, current
local tabFrames = {}

-- Reusable widgets per tab: pool(frame, "kind", i, factory)
local function pool(frame, kind, i, factory)
  frame.pools = frame.pools or {}
  frame.pools[kind] = frame.pools[kind] or {}
  local list = frame.pools[kind]
  if not list[i] then list[i] = factory() end
  list[i]:Show()
  return list[i]
end

local function hidePools(frame)
  if not frame.pools then return end
  for _, list in pairs(frame.pools) do
    for _, w in pairs(list) do w:Hide() end
  end
end

-- Paragraph with a report button on the right. → height
local function paragraph(frame, i, y, id, size, color)
  local row = pool(frame, "para", i, function()
    local r = CreateFrame("Frame", nil, frame)
    r.text = UI.Text(r, 13)
    r.text:SetPoint("TOPLEFT")
    r.text:SetWidth(WIDTH - 60)
    r.report = UI.ReportButton(r, function() return r.id end)
    r.report:SetPoint("TOPRIGHT", 0, 0)
    return r
  end)
  row.id = id
  ns.Font.Apply(row.text, size or 13)
  local c = UI.COLORS[color or "white"]
  row.text:SetTextColor(c[1], c[2], c[3])
  row.text:SetText(ns.T(id))
  local h = math.max(row.text:GetStringHeight(), 18)
  row:ClearAllPoints()
  row:SetPoint("TOPLEFT", 0, -y)
  row:SetSize(WIDTH, h)
  return h
end

local function label(frame, i, y, text, size, color, width)
  local fs = pool(frame, "label", i, function() return UI.Text(frame, 12) end)
  ns.Font.Apply(fs, size or 12)
  local c = UI.COLORS[color or "white"]
  fs:SetTextColor(c[1], c[2], c[3])
  fs:SetWidth(width or WIDTH)
  fs:ClearAllPoints()
  fs:SetPoint("TOPLEFT", 0, -y)
  fs:SetText(text)
  return fs:GetStringHeight()
end

local function button(frame, i, x, y, text, width, onClick)
  local b = pool(frame, "button", i, function() return UI.Button(frame, "", width, 22) end)
  b:SetWidth(width)
  b:SetLabel(text)
  b:ClearAllPoints()
  b:SetPoint("TOPLEFT", x, -y)
  b:SetScript("OnClick", onClick)
  return b
end

-- entry: a spell entry, or a string item kind (potion and elixir slots of the layout).
local function icon(frame, i, x, y, size, entry)
  local b = pool(frame, "icon", i, function()
    local ic = UI.SpellIcon(frame, size)
    ic:SetScript("OnClick", function(self) if self.entry then ns.NewSkill.ShowCard(self.entry, true) end end)
    return ic
  end)
  b:SetSize(size, size)
  b:ClearAllPoints()
  b:SetPoint("TOPLEFT", x, -y)
  if entry == false then
    b:SetEmpty()
  elseif type(entry) == "string" then
    b:SetItemKind(entry)
  else
    b:SetSpell(entry)
  end
  return b
end

local function sourcesText(section)
  local seen, list = {}, {}
  for _, p in ipairs(section.paragraphs) do
    for _, key in ipairs(p.src) do
      if not seen[key] then
        seen[key] = true
        local s = ns.Sources[key]
        if key == "wh_spell" then s = s .. "<id>" end
        table.insert(list, "・" .. s)
      end
    end
  end
  return ns.T("ui.guide.sources") .. "\n" .. table.concat(list, "\n") .. "\n" .. ns.T("ui.guide.verified", { date = section.verified })
end

local renderers = {}

-- The tabs of this character, top to bottom.
local function tabs()
  if not ns.spec then return IDLE_TABS end
  local list = {}
  for _, id in ipairs(ns.spec.tabs) do table.insert(list, id) end
  for _, id in ipairs(TABS) do table.insert(list, id) end
  return list
end

local function hasTab(id)
  for _, t in ipairs(tabs()) do
    if t == id then return true end
  end
  return false
end

local function guideSection(id)
  for _, s in ipairs(ns.spec and ns.spec.guide or {}) do
    if s.id == id then return s end
  end
end

local function textTab(id)
  return function(frame)
    local section = guideSection(id)
    local y = 0
    for i = 1, #section.paragraphs do
      y = y + paragraph(frame, i, y, "guide." .. id .. ".p" .. i) + 12
    end
    y = y + 6
    y = y + label(frame, 1, y, sourcesText(section), 10, "grey")
    return y + 10
  end
end
local function renderer(id)
  if renderers[id] then return renderers[id] end
  if guideSection(id) then
    renderers[id] = textTab(id)
    return renderers[id]
  end
end

renderers.skills = function(frame)
  local y = paragraph(frame, 1, 0, "ui.skills.intro") + 10
  local level = Spells.PlayerLevel()
  local list = {}
  for _, e in ipairs(Spells.List()) do table.insert(list, e) end
  table.sort(list, function(a, b)
    if a.level ~= b.level then return a.level < b.level end
    return a.name < b.name
  end)
  for i, e in ipairs(list) do
    icon(frame, i, 0, y, 26, e)
    local status
    if Spells.IsKnown(e) then
      status = "|cff59f273" .. ns.T("ui.skills.known") .. "|r"
    elseif e.level <= level then
      status = "|cffffd100" .. ns.T(e.talent and "ui.skills.talent" or "ui.skills.trainer") .. "|r"
    else
      status = "|cffa6a6a6" .. ns.T("ui.skills.later") .. "|r"
    end
    local c = UI.COLORS[e.role]
    local role = string.format("|cff%02x%02x%02x%s|r", c[1] * 255, c[2] * 255, c[3] * 255, ns.T("ui.role." .. e.role))
    local text = string.format("Lv%d  %s  %s  %s\n|cffa6a6a6%s|r", e.level, e.name, role, status, Spells.WhereText(e))
    local fs = pool(frame, "label", i, function() return UI.Text(frame, 12) end)
    ns.Font.Apply(fs, 12)
    fs:SetTextColor(1, 1, 1)
    fs:SetWidth(WIDTH - 34 - 90)
    fs:ClearAllPoints()
    fs:SetPoint("TOPLEFT", 34, -y)
    fs:SetText(text)
    button(frame, i, WIDTH - 80, y + 2, ns.T("ui.btn.card"), 80, function() ns.NewSkill.ShowCard(e, true) end)
    y = y + math.max(30, fs:GetStringHeight()) + 6
  end
  return y
end

renderers.layout = function(frame)
  local layout = ns.spec.layout
  local y = paragraph(frame, 1, 0, "ui.layout.intro") + 8
  y = y + paragraph(frame, 5, y, "ui.layout.intro2") + 12
  local n = 0
  for bi, bar in ipairs(layout.bars) do
    y = y + label(frame, bi, y, ns.T("ui.bar." .. bar.id), 13, "gold") + 4
    -- Action Bar 3: the clicked buttons (1-6), then the mouse keys (7-12, long labels like "Shift+Mouse 4") in a
    -- second row. Keyed bars show all 12 buttons, empty ones (spare keys, the player's 5) as dark squares with their
    -- key, so the plain, Shift and Ctrl rows line up key by key.
    local twoRows = bar.id == "bar3"
    local byButton = {}
    for _, s in ipairs(layout.slots) do
      if s.bar == bar.id then byButton[s.button] = s end
    end
    for i = 1, 12 do
      local s = byButton[i]
      local key = s and s.key or (bar.keys and bar.keys[i]) or nil
      if s or key then
        n = n + 1
        local second = twoRows and i > 6
        local step = second and 80 or 46
        local x = ((second and i - 6 or i) - 1) * step
        local rowY = second and y + 58 or y
        local e = s and s.spell and Spells.Get(s.spell)
        if e and s.standIn and not Spells.IsKnown(e) then e = Spells.Get(s.standIn) end
        if s and s.combo then e = Spells.Get(layout.combos[s.combo].needs) end
        icon(frame, n, x + (step - 46) / 2, rowY, 38, s and (s.item or e) or false)
        local keyText = pool(frame, "key", n, function() return UI.Text(frame, 10, "gold") end)
        keyText:SetWidth(step)
        keyText:SetJustifyH("CENTER")
        keyText:ClearAllPoints()
        keyText:SetPoint("TOPLEFT", x - 4, -(rowY + 40))
        keyText:SetText(key and ns.KeyLabel(key) or "")
      end
    end
    y = y + (twoRows and 116 or 58)
  end
  -- Keys the spec leaves on their game default (the paladin's Ctrl+1-4 = auras on the stance bar).
  for i, id in ipairs(layout.keyNotes or {}) do
    y = y + label(frame, 15 + i, y, ns.T(id), 12, "grey") + 4
  end
  -- Spells without a bar slot, one line per kind the spec lists (noSlotLines: { kind, text }).
  for i, line in ipairs(layout.noSlotLines or {}) do
    local names = {}
    for key, kind in pairs(layout.noSlot) do
      if kind == line.kind then table.insert(names, Spells.Get(key).name) end
    end
    table.sort(names)
    if #names > 0 then
      y = y + label(frame, 9 + i, y, ns.T(line.text, { names = table.concat(names, ", ") }), 12, "grey") + 4
    end
  end
  y = y + 4
  y = y + paragraph(frame, 4, y, "ui.layout.items") + 12

  button(frame, 1, 0, y, ns.T("ui.btn.applyall"), 200, function() ns.Layout.Preview() end)
  local undo = button(frame, 2, 210, y, ns.T("ui.btn.undo"), 140, function() ns.Layout.Undo() end)
  if undo.SetEnabled then undo:SetEnabled(ns.Layout.CanUndo() and true or false) end
  button(frame, 5, 360, y, ns.T("ui.btn.clean"), 180, function() ns.Layout.Clean() end)
  y = y + 34
  y = y + paragraph(frame, 6, y, "ui.layout.clean") + 8

  y = y + paragraph(frame, 2, y, "ui.layout.targeting") + 8
  local mode = ns.settings.targeting
  button(frame, 3, 0, y, (mode == "mouseover" and "● " or "○ ") .. ns.T("ui.targeting.mouseover"), 230, function()
    ns.Layout.SetTargeting("mouseover")
  end)
  button(frame, 4, 240, y, (mode == "click" and "● " or "○ ") .. ns.T("ui.targeting.click"), 230, function()
    ns.Layout.SetTargeting("click")
  end)
  y = y + 32
  y = y + paragraph(frame, 3, y, mode == "mouseover" and "ui.targeting.mouseover.help" or "ui.targeting.click.help") + 8
  return y
end

renderers.talents = function(frame)
  local T = ns.spec.talents
  local state = ns.Talents.State()
  local y = paragraph(frame, 1, 0, "ui.talents.intro") + 8
  if not state.readable then y = y + paragraph(frame, 2, y, "ui.talent.unreadable") + 8 end
  local li, pi = 0, 2
  for _, step in ipairs(T.path) do
    local key, first, last = step[1], step[2], step[3]
    local t = T.byKey[key]
    local endRank = 0
    for _, o in ipairs(T.order) do
      if o.key == key and o.level <= last then endRank = o.rank end
    end
    local done = state.ranks and (state.ranks[t.name] or 0) >= endRank
    local mark = done and "|cff59f273●|r" or "○"
    local levels = first == last and ("Lv" .. first) or ("Lv" .. first .. "-" .. last)
    li = li + 1
    y = y + label(frame, li, y, ns.T("ui.talents.line", { mark = mark, levels = levels, name = t.name, tree = t.tree, rank = endRank, max = t.max }), 13) + 4
  end
  y = y + 10
  li = li + 1
  y = y + label(frame, li, y, ns.T("ui.talents.why"), 13, "gold") + 6
  for _, t in ipairs(T.list) do
    li = li + 1
    y = y + label(frame, li, y, t.name, 12, "gold") + 2
    pi = pi + 1
    y = y + paragraph(frame, pi, y, "talent." .. t.key .. ".why") + 8
  end
  li = li + 1
  y = y + label(frame, li, y, ns.T("ui.talents.notes"), 13, "gold") + 6
  for _, id in ipairs(T.notes or {}) do
    pi = pi + 1
    y = y + paragraph(frame, pi, y, id) + 8
  end
  li = li + 1
  local src = {}
  for _, key in ipairs(T.sources or {}) do table.insert(src, "\n・" .. ns.Sources[key]) end
  y = y + label(frame, li, y, ns.T("ui.guide.sources") .. table.concat(src) .. "\n"
    .. ns.T("ui.guide.verified", { date = T.pathSource.verified }), 10, "grey")
  return y + 10
end

local reviewPage = 1
renderers.review = function(frame)
  local ids = ns.TextIds()
  local done = 0
  for _, id in ipairs(ids) do
    if ns.db.review[id] then done = done + 1 end
  end
  local pages = math.max(1, math.ceil(#ids / REVIEW_PAGE))
  if reviewPage > pages then reviewPage = pages end
  local y = paragraph(frame, 1, 0, "ui.review.intro") + 6
  y = y + label(frame, 1, y, ns.T("ui.review.progress", { done = done, total = #ids, page = reviewPage, pages = pages }), 12, "gold") + 8
  button(frame, 1, 0, y, ns.T("ui.btn.prev"), 100, function()
    reviewPage = math.max(1, reviewPage - 1)
    Guide.Refresh()
  end)
  button(frame, 2, 110, y, ns.T("ui.btn.next"), 100, function()
    reviewPage = math.min(pages, reviewPage + 1)
    Guide.Refresh()
  end)
  button(frame, 3, 220, y, ns.T("ui.btn.unchecked"), 180, function()
    for i, id in ipairs(ids) do
      if not ns.db.review[id] then
        reviewPage = math.ceil(i / REVIEW_PAGE)
        break
      end
    end
    Guide.Refresh()
  end)
  y = y + 32
  local first = (reviewPage - 1) * REVIEW_PAGE + 1
  local bi, li = 3, 1
  for i = first, math.min(#ids, first + REVIEW_PAGE - 1) do
    local id = ids[i]
    local status = ns.db.review[id]
    local mark = status == "ok" and "|cff59f273● OK|r" or status == "reported" and "|cffffd100● " .. ns.T("ui.review.reported") .. "|r" or "○"
    li = li + 1
    y = y + label(frame, li, y, mark .. "  |cffa6a6a6" .. id .. "|r", 10) + 2
    li = li + 1
    y = y + label(frame, li, y, ns.Raw(id, "ja"), 13) + 2
    li = li + 1
    y = y + label(frame, li, y, ns.Raw(id, "en"), 10, "grey") + 4
    bi = bi + 1
    button(frame, bi, 0, y, "OK", 80, function()
      ns.db.review[id] = "ok"
      Guide.Refresh()
    end)
    bi = bi + 1
    button(frame, bi, 90, y, ns.T("ui.report.button"), 80, function() ns.Feedback.Open(id) end)
    y = y + 34
  end
  return y
end

renderers.settings = function(frame)
  local s = ns.settings
  local y = 0
  local bi, li = 0, 0
  if ns.packNote then
    li = li + 1
    y = y + label(frame, li, y, ns.PackNoteText(), 13, "gold") + 12
  end
  local function toggle(textId, on, onClick)
    bi = bi + 1
    button(frame, bi, 0, y, (on and "● " or "○ ") .. ns.T(textId), 320, function()
      onClick()
      Guide.Refresh()
    end)
    y = y + 30
  end
  li = li + 1
  y = y + label(frame, li, y, ns.T("ui.settings.language"), 13, "gold") + 6
  toggle("ui.settings.ja", s.language == "ja", function() ns.SetLanguage("ja") end)
  toggle("ui.settings.en", s.language == "en", function() ns.SetLanguage("en") end)
  y = y + 8
  li = li + 1
  y = y + label(frame, li, y, ns.T("ui.settings.show"), 13, "gold") + 6
  toggle("ui.settings.cards", s.showCards, function() s.showCards = not s.showCards end)
  toggle("ui.settings.talents", s.showTalentHints, function() s.showTalentHints = not s.showTalentHints end)
  toggle("ui.settings.ranks", s.autoRanks, function() s.autoRanks = not s.autoRanks end)
  toggle("ui.settings.minimap", s.minimap, function()
    s.minimap = not s.minimap
    if ns.Minimap then ns.Minimap.Update() end
  end)
  if ns.Active() then
    y = y + 8
    li = li + 1
    y = y + label(frame, li, y, ns.T("ui.settings.more"), 12, "grey") + 8
    bi = bi + 1
    button(frame, bi, 0, y, ns.T("ui.btn.trainer"), 220, function() ns.NewSkill.ShowTrainer() end)
    bi = bi + 1
    button(frame, bi, 230, y, ns.T("ui.btn.talents.hint"), 220, function() ns.Talents.ShowHint(true) end)
    y = y + 30
  end
  li = li + 1
  y = y + label(frame, li, y, "ForeverSensei v" .. ns.VERSION .. "  (/sensei help, /sensei verify)", 10, "grey") + 4
  return y
end

local function build()
  win = UI.Window("ForeverSenseiGuide", 760, 580, ns.T("ui.guide.title"))
  win.tabs = {}
  for i, id in ipairs(tabs()) do
    local b = UI.Button(win, ns.T("ui.tab." .. id), 150, 26, function() Guide.Open(id) end)
    b:SetPoint("TOPLEFT", 14, -40 - (i - 1) * 30)
    win.tabs[id] = b
  end
  win.sf = CreateFrame("ScrollFrame", nil, win, "UIPanelScrollFrameTemplate")
  win.sf:SetPoint("TOPLEFT", 176, -42)
  win.sf:SetPoint("BOTTOMRIGHT", -34, 52)
  win.send = UI.Button(win, "", 200, 24, function() ns.Feedback.Send() end)
  win.send:SetPoint("BOTTOMRIGHT", -16, 14)
  win.version = UI.Text(win, 10, "grey")
  win.version:SetPoint("BOTTOMLEFT", 16, 20)
  win.version:SetText("v" .. ns.VERSION)
end

function Guide.RefreshFooter()
  if not win then return end
  win.send:SetLabel(ns.T("ui.btn.send", { n = #ns.db.reports }))
end

function Guide.Refresh()
  -- Bar changes call this, so an open skill card updates its "already placed" line too.
  if ns.NewSkill and ns.NewSkill.RefreshCard then ns.NewSkill.RefreshCard() end
  if not win or not win:IsShown() or not current then return end
  local frame = tabFrames[current]
  if not frame then
    frame = CreateFrame("Frame", nil, win.sf)
    frame:SetWidth(WIDTH)
    tabFrames[current] = frame
  end
  for id, f in pairs(tabFrames) do
    if id ~= current then f:Hide() end
  end
  hidePools(frame)
  local h = renderer(current)(frame)
  frame:SetHeight(math.max(h, 10))
  frame:Show()
  win.sf:SetScrollChild(frame)
  for id, b in pairs(win.tabs) do
    b:SetLabel((id == current and "→ " or "") .. ns.T("ui.tab." .. id))
  end
  Guide.RefreshFooter()
end

-- Language change: the title is the only text set once; Refresh sets the rest.
ns.OnLanguage(function()
  if not win then return end
  win.title:SetText(ns.T("ui.guide.title"))
  Guide.Refresh()
end)

function Guide.Open(tab)
  if not win then build() end
  if tab and hasTab(tab) then current = tab end
  if not current or not hasTab(current) then current = tabs()[1] end
  if win.sf.SetVerticalScroll then win.sf:SetVerticalScroll(0) end
  win:Show()
  Guide.Refresh()
end

function Guide.Current()
  return current
end

-- The tab ids of this character (the spec's text tabs, then the core's; without a class pack: review and settings).
Guide.Tabs = tabs

function Guide.Toggle()
  if win and win:IsShown() then win:Hide() else Guide.Open() end
end

ns.Command("", function() Guide.Toggle() end)
ns.Command("guide", function() Guide.Open() end)
ns.Command("skills", function() Guide.Open("skills") end)
ns.Command("layout", function() Guide.Open("layout") end)
ns.Command("order", function() Guide.Open("talents") end)
ns.Command("review", function() Guide.Open("review") end)
ns.Command("settings", function() Guide.Open("settings") end)
