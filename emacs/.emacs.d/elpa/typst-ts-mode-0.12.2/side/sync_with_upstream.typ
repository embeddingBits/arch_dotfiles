#import "@preview/cheq:0.1.0": unchecked-sym, checked-sym

#let cross-sym(fill: white, stroke: rgb("#616161"), radius: .1em) = move(
    dy: -.08em,
    box(
        stroke: .05em + stroke,
        fill: stroke,
        height: .8em,
        width: .8em,
        radius: radius,
        {
            // Draw the first diagonal line of the cross
            box(move(dy: 0.38em, dx: 0.1em, rotate(45deg, line(length: 0.64em, stroke: fill + .1em))))
            // Draw the second diagonal line of the cross
            box(move(dy: -0.28em, dx: 0.1em, rotate(-45deg, line(length: 0.64em, stroke: fill + .1em))))
        },
    ),
)

#let yes = checked-sym(fill: luma(95%), stroke: blue, radius: .2em)
#let todo = unchecked-sym(fill: luma(95%), stroke: blue, radius: .2em)
#let no = cross-sym(fill: luma(95%), stroke: red, radius: 0.2em)

#let cyan = rgb("EAF2F5")
#set table(fill: (_, y) => if y == 0 { cyan })
#let tableSep(content) = table.cell(fill: cyan, colspan: 2, text(content))



#link("https://github.com/uben0/tree-sitter-typst?tab=readme-ov-file")[tree-sitter-typst]

Grammar File Path: `/queries/typst/highlights.scm`

Corresponding Commit: `4610172f312e8ce5184e6882be5ad1a1cd800fbe`

Use `git diff` or `git blame` to get the grammar change.

#table(
    columns: 2,
    table.header[*Rule*][*Status*],
    [`(call item: (ident) @function)`]                       , yes,
    [`(call item: (field field: (ident) @function.method))`] , yes,
    [`(tagged field: (ident) @tag)`]                         , yes,
    [`(field field: (ident) @tag)`]                          , yes,
    [`(comment) @comment`]                                   , yes,

    tableSep([_Control_]),
    [`(let "let" @keyword.storage.type)`]                   , yes,
    [`(branch ["if" "else"] @keyword.control.conditional)`] , yes,
    [`(while "while" @keyword.control.repeat)`]             , yes,
    [`(for ["for" "in"] @keyword.control.repeat)`]          , yes,
    [`(import "import" @keyword.control.import)`]           , yes,
    [`(as "as" @keyword.operator)`]                         , yes,
    [`(include "include" @keyword.control.import)`]         , yes,
    [`(show "show" @keyword.control)`]                      , yes,
    [`(set "set" @keyword.control)`]                        , yes,
    [`(return "return" @keyword.control)`]                  , yes,
    [`(flow ["break" "continue"] @keyword.control)`]        , yes,

    tableSep([_OPERATOR_]),
    [`(in ["in" "not"] @keyword.operator)`]           , yes,
    [`(context "context" @keyword.control)`]          , yes,
    [`(and "and" @keyword.operator)`]                 , yes,
    [`(or "or" @keyword.operator)`]                   , yes,
    [`(not "not" @keyword.operator)`]                 , yes,
    [`(sign ["+" "-"] @operator)`]                    , yes,
    [`(add "+" @operator)`]                           , yes,
    [`(sub "-" @operator)`]                           , yes,
    [`(mul "*" @operator)`]                           , yes,
    [`(div "/" @operator)`]                           , yes,
    [`(cmp ["==" "<=" ">=" "!=" "<" ">"] @operator)`] , yes,
    [`(fraction "/" @operator)`]                      , yes,
    [`(fac "!" @operator)`]                           , yes,
    [`(attach ["^" "_"] @operator)`]                  , yes,
    [`(wildcard) @operator`]                          , yes,

    tableSep([_VALUE_]),
    [#raw("(raw_blck \"```\" @operator) @markup.raw.block")] , yes,
    [```(raw_span "`" @operator) @markup.raw.block```]       , yes,
    [`(raw_blck lang: (ident) @tag)`]                        , yes,
    [`(label) @tag`]                                         , yes,
    [`(ref) @tag`]                                           , yes,
    [`(number) @constant.numeric`]                           , yes,
    [`(string) @string`]                                     , yes,
    [`(content ["[" "]"] @operator)`]                        , yes,
    [`(bool) @constant.builtin.boolean`]                     , yes,
    [`(none) @constant.builtin`]                             , yes,
    [`(auto) @constant.builtin`]                             , yes,
    
    tableSep([_MARKUP_]),
    [`(item "-" @markup.list)`]                                     , yes,
    [`(term ["/" ":"] @markup.list)`]                               , yes,
    [`(heading "=" @markup.heading.marker) @markup.heading.1`]      , yes,
    [`(heading "==" @markup.heading.marker) @markup.heading.2`]     , yes,
    [`(heading "===" @markup.heading.marker) @markup.heading.3`]    , yes,
    [`(heading "====" @markup.heading.marker) @markup.heading.4`]   , yes,
    [`(heading "=====" @markup.heading.marker) @markup.heading.5`]  , yes,
    [`(heading "======" @markup.heading.marker) @markup.heading.6`] , yes,
    [`(url) @tag`]                                                  , yes,
    [`(emph) @markup.italic`]                                       , yes,
    [`(strong) @markup.bold`]                                       , yes,
    [`(symbol) @constant.character`]                                , yes,
    [`(shorthand) @constant.builtin`]                               , yes,
    [`(quote) @markup.quote`]                                       , yes,
    [`(align) @operator`]                                           , yes,
    [`(letter) @constant.character`]                                , yes,
    [`(linebreak) @constant.builtin`]                               , yes,

    tableSep([_MATH_]),
    [`(math "$" @operator)`] , yes,
    [`"#" @operator`]        , yes,
    [`"end" @operator`]      , [ HAVEN'T ADDED since it isn't visual (for highlighting) and doesn't affect indentation ],

    tableSep([ _MISCELLANEOUS_ ]),
    [`(escape) @constant.character.escape`]    , yes,
    [`["(" ")" "{" "}"] @punctuation.bracket`] , yes,
    [`["," ";" ".." ":" "sep"] @punctuation.delimiter`], yes,
    [`"assign" @punctuation`]                  , yes,
    [`(field "." @punctuation)`]               , yes,

    tableSep([ Node not included in `/queries/typst/highlights.scm` ]),
    [ `(code)` ], [ HAVEN'T ADDED since it isn't visual (for highlighting) and doesn't affect indentation ]
)
