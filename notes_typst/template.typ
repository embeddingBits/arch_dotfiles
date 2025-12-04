#set text(14pt)
#set heading(numbering: "1.") 

#align(center+horizon)[
  #set text(3em)
  #text(80pt)[*Subject*]
]

#pagebreak()

#set page(numbering: "1")

#let module(title, body) = [
  #set page(
    header: [
    #title
    #h(1fr)
  Chapter 
    #line(length: 100%)
  ],
  )
  = #title
  #v(10pt)
  #body
]

#outline()

#pagebreak()

#module("Module 1")[
  #lorem(1000)
]

#module("Module 2")[
  #lorem(1000)
]


