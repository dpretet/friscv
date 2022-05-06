# distributed under the mit license
# https://opensource.org/licenses/mit-license.php

.section .text

#-------------------------------------------------------------
# Export functions' symbols for C call
#-------------------------------------------------------------

.global break_exe
.type break_exe, @function


#-------------------------------------------------------------
# Stop the processor with EBREAK
#-------------------------------------------------------------
break_exe:
    ebreak
