.comment
example: start                          my first SIC program!
begin:   lda four
         add one
         sta area, x
         rsub
four:    word 4
area:    resb 4
one:     word 2                         could be an error!
         end begin
