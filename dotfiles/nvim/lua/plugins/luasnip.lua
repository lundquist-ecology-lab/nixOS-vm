local ls = require("luasnip")
local s = ls.snippet
local sn = ls.snippet_node
local t = ls.text_node
local i = ls.insert_node
local f = ls.function_node
local c = ls.choice_node
local d = ls.dynamic_node
local r = ls.restore_node
local fmt = require("luasnip.extras.fmt").fmt
local fmta = require("luasnip.extras.fmt").fmta
local rep = require("luasnip.extras").rep

-- Load friendly snippets
local present, friendly_snippets = pcall(require, 'luasnip.loaders.from_vscode')
if present then
  friendly_snippets.load()
end

-- Basic LuaSnip configuration
ls.config.set_config({
  history = true,
  updateevents = "TextChanged,TextChangedI",
  enable_autosnippets = true,
  ext_opts = {
    [require("luasnip.util.types").choiceNode] = {
      active = {
        virt_text = { { "●", "GruvboxOrange" } },
      },
    },
  },
})

-- Key mappings for snippet navigation
vim.keymap.set({"i", "s"}, "<C-k>", function()
  if ls.expand_or_jumpable() then
    ls.expand_or_jump()
  end
end, { silent = true })

vim.keymap.set({"i", "s"}, "<C-j>", function()
  if ls.jumpable(-1) then
    ls.jump(-1)
  end
end, { silent = true })

vim.keymap.set("i", "<C-l>", function()
  if ls.choice_active() then
    ls.change_choice(1)
  end
end)

-- LaTeX Snippets
local tex = {}

-- Document structure
tex.documentclass = s("documentclass", fmta(
  [[
    \documentclass[<>]{<>}

    <>

    \begin{document}

    <>

    \end{document}
  ]],
  {
    i(1, "12pt"),
    c(2, {t("article"), t("report"), t("book"), t("beamer")}),
    i(3, "% Preamble"),
    i(0),
  }
))

tex.usepackage = s("usepackage", fmt("\\usepackage{{{}}}", { i(1, "package") }))
tex.begin = s("begin", fmta(
  [[
    \begin{<>}
      <>
    \end{<>}
  ]],
  {
    i(1, "environment"),
    i(0),
    rep(1),
  }
))

-- Sections
tex.section = s("sec", fmt("\\section{{{}}}\n{}", { i(1, "Section"), i(0) }))
tex.subsection = s("subsec", fmt("\\subsection{{{}}}\n{}", { i(1, "Subsection"), i(0) }))
tex.subsubsection = s("subsubsec", fmt("\\subsubsection{{{}}}\n{}", { i(1, "Subsubsection"), i(0) }))

-- Text formatting
tex.textbf = s("bf", fmt("\\textbf{{{}}}{}", { i(1), i(0) }))
tex.textit = s("it", fmt("\\textit{{{}}}{}", { i(1), i(0) }))
tex.underline = s("ul", fmt("\\underline{{{}}}{}", { i(1), i(0) }))
tex.emph = s("em", fmt("\\emph{{{}}}{}", { i(1), i(0) }))

-- Math environments
tex.equation = s("eq", fmta(
  [[
    \begin{equation}
      <>
    \end{equation}<>
  ]],
  { i(1), i(0) }
))

tex.align = s("align", fmta(
  [[
    \begin{align}
      <>
    \end{align}<>
  ]],
  { i(1), i(0) }
))

tex.inline_math = s("mm", fmt("${}${}", { i(1), i(0) }))
tex.display_math = s("dm", fmta(
  [[
    \[
      <>
    \]<>
  ]],
  { i(1), i(0) }
))

-- Fractions and common math
tex.frac = s("frac", fmt("\\frac{{{}}}{{{}}}{}", { i(1, "numerator"), i(2, "denominator"), i(0) }))
tex.sqrt = s("sqrt", fmt("\\sqrt{{{}}}{}", { i(1), i(0) }))
tex.sum = s("sum", fmt("\\sum_{{{} = {}}}^{{{}}} {}", { i(1, "i"), i(2, "1"), i(3, "n"), i(0) }))
tex.int = s("int", fmt("\\int_{{{}}}^{{{}}} {} \\, d{}", { i(1, "a"), i(2, "b"), i(3), i(4, "x") }))
tex.lim = s("lim", fmt("\\lim_{{{} \\to {}}} {}", { i(1, "x"), i(2, "\\infty"), i(0) }))

-- Greek letters (common ones)
tex.alpha = s("alpha", t("\\alpha"))
tex.beta = s("beta", t("\\beta"))
tex.gamma = s("gamma", t("\\gamma"))
tex.delta = s("delta", t("\\delta"))
tex.epsilon = s("epsilon", t("\\epsilon"))
tex.theta = s("theta", t("\\theta"))
tex.lambda = s("lambda", t("\\lambda"))
tex.mu = s("mu", t("\\mu"))
tex.pi = s("pi", t("\\pi"))
tex.sigma = s("sigma", t("\\sigma"))
tex.phi = s("phi", t("\\phi"))
tex.omega = s("omega", t("\\omega"))

-- Environments
tex.itemize = s("itemize", fmta(
  [[
    \begin{itemize}
      \item <>
    \end{itemize}<>
  ]],
  { i(1), i(0) }
))

tex.enumerate = s("enumerate", fmta(
  [[
    \begin{enumerate}
      \item <>
    \end{enumerate}<>
  ]],
  { i(1), i(0) }
))

tex.item = s("item", fmt("\\item {}", { i(0) }))

tex.figure = s("figure", fmta(
  [[
    \begin{figure}[<>]
      \centering
      \includegraphics[width=<>\textwidth]{<>}
      \caption{<>}
      \label{fig:<>}
    \end{figure}<>
  ]],
  {
    i(1, "htbp"),
    i(2, "0.8"),
    i(3, "image"),
    i(4, "caption"),
    i(5, "label"),
    i(0),
  }
))

tex.table = s("table", fmta(
  [[
    \begin{table}[<>]
      \centering
      \caption{<>}
      \label{tab:<>}
      \begin{tabular}{<>}
        \hline
        <>
        \hline
      \end{tabular}
    \end{table}<>
  ]],
  {
    i(1, "htbp"),
    i(2, "caption"),
    i(3, "label"),
    i(4, "c|c|c"),
    i(5),
    i(0),
  }
))

-- References and citations
tex.label = s("label", fmt("\\label{{{}}}", { i(1) }))
tex.ref = s("ref", fmt("\\ref{{{}}}", { i(1) }))
tex.cite = s("cite", fmt("\\cite{{{}}}", { i(1) }))
tex.footnote = s("footnote", fmt("\\footnote{{{}}}", { i(1) }))

-- Matrix
tex.matrix = s("matrix", fmta(
  [[
    \begin{<>matrix}
      <>
    \end{<>matrix}<>
  ]],
  {
    c(1, {t(""), t("p"), t("b"), t("B"), t("v"), t("V")}),
    i(2),
    rep(1),
    i(0),
  }
))

-- Add all LaTeX snippets
ls.add_snippets("tex", vim.tbl_values(tex))

-- Also enable for latex filetype
ls.add_snippets("latex", vim.tbl_values(tex))
