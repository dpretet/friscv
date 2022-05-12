# distributed under the mit license
# https://opensource.org/licenses/mit-license.php

.section .text

#-------------------------------------------------------------
# Export functions' symbols for C call
#-------------------------------------------------------------

.global shutdown
.type shutdown, @function


#-------------------------------------------------------------
# Stop the processor with EBREAK
#-------------------------------------------------------------
shutdown:
    ebreak
