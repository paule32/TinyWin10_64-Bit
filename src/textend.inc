section_end:

text_size      equ section_end - section_start        ; reale Länge
text_raw_size  equ ((text_size + FILEALIGN - 1) / FILEALIGN) * FILEALIGN ; gerundet
