-- coursebook.lua - den enda delen av designen som TeX-makron inte klarar rent.
--
-- \code{...} sätter kod exakt som den är skriven. \detokenize kommer nästan hela vägen, men
-- lämnar två artefakter: den dubblar varje #, så att #include skulle skrivas ut som ##include,
-- och den lägger ett mellanslag efter varje kontrollord, så att "\n" skulle bli "\n ". Båda
-- ogörs här, och en radbrytning tillåts efter :: och efter ett kommatecken utan mellanslag, så
-- att ett namn som driver::can::ByteTransport kan brytas i stället för att gå ut i marginalen.

local catcode_other = -2

function coursebook_code(s)
  s = s:gsub("#+", "#")
  s = s:gsub("(\\%a+) ", "%1")
  -- \%, \{ och \} är hur ett procenttecken eller en obalanserad klammer måste skrivas inuti ett
  -- TeX-argument, \# hur ett # måste skrivas i en rubrik, och \\ ett ensamt bakstreck.
  s = s:gsub("\\([%%{}#\\])", "%1")
  local start = 1
  while true do
    local i, j = s:find("::", start, true)
    local k = s:find(",[^ ]", start)
    if k and (not i or k < i) then i, j = k, k end
    if not i then break end
    tex.sprint(catcode_other, s:sub(start, j))
    tex.sprint("\\penalty100 ")
    start = j + 1
  end
  tex.sprint(catcode_other, s:sub(start))
end
