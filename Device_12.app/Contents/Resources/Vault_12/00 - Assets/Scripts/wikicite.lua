-- wikicite.lua

local cite_mode = "NormalCitation"
function Link(el)
  local txt = pandoc.utils.stringify(el.content)
  if txt:match("^@[%w%p]+") then
    local key = txt:match("^@([^|]+)")
    return pandoc.Cite(el.content, { pandoc.Citation(key, cite_mode) })
  end
  return el
end

function Pandoc(doc)
  -- 1) insert a page break
  table.insert(doc.blocks,
    pandoc.RawBlock("latex", "\\clearpage"))
  -- 2) insert a level‑1 heading “References”
  table.insert(doc.blocks,
    pandoc.Header(1, { pandoc.Str("References") }))
  -- 3) insert the citeproc placeholder div
  table.insert(doc.blocks,
    pandoc.Div({}, pandoc.Attr("refs", {"references"})))
  return doc
end
