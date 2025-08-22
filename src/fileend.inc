import_end:

import_rva   equ import_desc_msvcrt - section_start + 0x1000
import_size  equ import_end  - import_desc_msvcrt

;---------------------------------------------------
pad_align FILEALIGN
