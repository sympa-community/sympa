(TeX-add-style-hook "pocket"
 (function
  (lambda ()
    (LaTeX-add-index-entries
     "#1"
     "#1@#2"
     "#1@\\texttt {#2} #3"))))

