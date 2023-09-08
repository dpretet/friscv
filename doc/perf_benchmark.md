# 2023-03-27 - Initial architecture with caches

hash: 98c12b38889758

Tb clock a 2 ns

Nb iterations = 10

CPI = 3.78


Reporting:
- Start time: 9338
- End time: 5419593
- Total elapsed time: 5410255 cycles
- Instret start: 2176
- Instret end: 1434224
- Retired instructions: 1432048
- cycle/instruction: ~3.1114111
- Chacha20 execution: 1018145 cycles
- Matrix execution: 156943 cycles
- Printf execution: 781657 cycles
- Xoshiro128++ execution: 385153 cycles
- Pool Arena execution: 3067589 cycles

eb6a2e53c3f83edf80dc08e163c41df74eee66d8

Reporting:
- Start time: 5501312
- End time: 10905894
- Total elapsed time: 5404582 cycles
- Instret start: 1452570
- Instret end: 2883613
- Retired instructions: 1431043
- cycle/instruction: ~3.1111453
- Chacha20 execution: 1017585 cycles
- Matrix execution: 156483 cycles
- Printf execution: 781220 cycles
- Xoshiro128++ execution: 385129 cycles
- Pool Arena execution: 3063485 cycles

2d23ea20f5e0d84ca3c9ff611f2fd10f8b1d5aba

Reporting:
- Start time: 9347
- End time: 5407474
- Total elapsed time: 5398127 cycles
- Instret start: 2153
- Instret end: 1433196
- Retired instructions: 1431043
- cycle/instruction: ~3.1104998
- Chacha20 execution: 977935 cycles
- Matrix execution: 157522 cycles
- Printf execution: 793497 cycles
- Xoshiro128++ execution: 372862 cycles
- Pool Arena execution: 3095563 cycles

# 230415

CPI = 3.77

General statistics:
  - Start time: 9345
  - End time: 5407545
  - Total elapsed time: 5398200 cycles
  - Instret start: 2153
  - Instret end: 1433232
  - Retired instructions: 1431079

Instruction Request Bus:
  - active cycles: 3699134
  - sleep cycles: 0
  - stall cycles: 1540843

Instruction Completion Bus
  - active cycles: 2669364
  - sleep cycles: 321947
  - stall cycles: 2406408

Processing bus:
  - active cycles: 1219044
  - sleep cycles: 2445340
  - stall cycles: 1583999

Algorithms:
- Chacha20 execution: 977903 cycles
- Matrix execution: 157533 cycles
- Printf execution: 793484 cycles
- Xoshiro128++ execution: 372855 cycles
- Pool Arena execution: 3095579 cycles

# 230416 - Block Fetcher flow-thru mode activated

CPI = 3.45

General statistics:
  - Start time: 9340
  - End time: 5119249
  - Total elapsed time: 5109909 cycles
  - Instret start: 2243
  - Instret end: 1433322
  - Retired instructions: 1431079

Instruction Bus Request:
  - active cycles: 3603536
  - sleep cycles: 0
  - stall cycles: 1348150

Inst Bus Completion:
  - active cycles: 2665547
  - sleep cycles: 321970
  - stall cycles: 2121998

Processing Bus:
  - active cycles: 1219044
  - sleep cycles: 2372728
  - stall cycles: 1385283

Algorithms:
- Chacha20 execution: 899747 cycles
- Matrix execution: 146781 cycles
- Printf execution: 750617 cycles
- Xoshiro128++ execution: 360582 cycles
- Pool Arena execution: 2951343 cycles


# 23/05/02 - iCache update, step 1

CPI = 4.51

General statistics:
  - Start time: 6463580
  - End time: 12746291
  - Total elapsed time: 6282711 cycles
  - Instret start: 1465911
  - Instret end: 2896990
  - Retired instructions: 1431079

Instruction Bus Request:
  - active cycles: 3724323
  - sleep cycles: 20221
  - stall cycles: 2400165

Inst Bus Completion:
  - active cycles: 3724324
  - sleep cycles: 2723
  - stall cycles: 2555586

Processing Bus:
  - active cycles: 1219044
  - sleep cycles: 3251294
  - stall cycles: 1661356

Algorithms:
- Chacha20 execution: 1048608 cycles
- Matrix execution: 172941 cycles
- Printf execution: 930233 cycles
- Xoshiro128++ execution: 418865 cycles
- Pool Arena execution: 3711268 cycles

# 26/06/2023 - Final icache + control update

CPI = 3.67

General statistics:
  - Start time: 9375
  - End time: 5269169
  - Total elapsed time: 5259794 cycles
  - Instret start: 2243
  - Instret end: 1433322
  - Retired instructions: 1431079


Instruction Bus Request:
  - active cycles: 2498260
  - sleep cycles: 0
  - stall cycles: 2761536

Inst Bus Completion:
  - active cycles: 1589275
  - sleep cycles: 160809
  - stall cycles: 3509119

Processing Bus:
  - active cycles: 1219044
  - sleep cycles: 2226461
  - stall cycles: 1653291

Algorithms:
- Chacha20 execution: 989507 cycles
- Matrix execution: 155513 cycles
- Printf execution: 766667 cycles
- Xoshiro128++ execution: 370791 cycles
- Pool Arena execution: 2976411 cycles


# 05/07/2023 - Misc. Updates

CPI = 3.05

dCache:
- Bypass CPL if no IO request
- No back-pressure on block Fetcher
- fixed AXI ID in OoO
- prefetcher now always load ADDR + CACHE_BLOCK_W

General statistics:
  - Start time: 8078
  - End time: 4372164
  - Total elapsed time: 4364086 cycles
  - Instret start: 2220
  - Instret end: 1433299
  - Retired instructions: 1431079

Instruction Bus Request:
  - active cycles: 3340831
  - sleep cycles: 0
  - stall cycles: 1023257

Inst Bus Completion:
  - active cycles: 1589274
  - sleep cycles: 160754
  - stall cycles: 2613729

Processing Bus:
  - active cycles: 1219044
  - sleep cycles: 1918548
  - stall cycles: 1117491

Algorithms:
- Chacha20 execution: 774498 cycles
- Matrix execution: 127361 cycles
- Printf execution: 638013 cycles
- Xoshiro128++ execution: 321654 cycles
- Pool Arena execution: 2501780 cycles

# 19/7/23 C907019

First:
Restore BackPressure because found a bug
Pas de FFD sur RD dans memfy
Pending read/write reduce by 1 cycle if or==1 & valid

-> CPI = 2920000/980746 = 2.95

Then:
Save a 1 cycle on cache write
Fixes on Block-Fetcher

CPI = 2686107/980746 = 2.738

General statistics:
  - Start time: 7846
  - End time: 2693953
  - Total elapsed time: 2686107 cycles
  - Instret start: 2128
  - Instret end: 982874
  - Retired instructions: 980746

Instruction Bus Request:
  - active cycles: 2423159
  - sleep cycles: 0
  - stall cycles: 262950

Inst Bus Completion:
  - active cycles: 1106004
  - sleep cycles: 127445
  - stall cycles: 1452279

Processing Bus:
  - active cycles: 815637
  - sleep cycles: 1155628
  - stall cycles: 659677

Algorithms:
- Chacha20 execution: 79777 cycles
- Matrix execution: 13548 cycles
- Printf execution: 66973 cycles
- Xoshiro128++ execution: 295050 cycles
- Pool Arena execution: 2229932 cycles


# 27/7/2023

Enhance OoO completion stage, now bypass RAM if possible

CPI 2036191/980746 = 2.07

General statistics:
  - Start time: 6536
  - End time: 2042827
  - Total elapsed time: 2036291 cycles
  - Instret start: 2128
  - Instret end: 982874
  - Retired instructions: 980746

Instruction Bus Request:
  - active cycles: 1948157
  - sleep cycles: 0
  - stall cycles: 88136

Inst Bus Completion:
  - active cycles: 1105999
  - sleep cycles: 128082
  - stall cycles: 801871

Processing Bus:
  - active cycles: 815637
  - sleep cycles: 858362
  - stall cycles: 335619

Algorithms:
- Chacha20 execution: 55526 cycles
- Matrix execution: 10696 cycles
- Printf execution: 51919 cycles
- Xoshiro128++ execution: 241840 cycles
- Pool Arena execution: 1675539 cycles

# 230908: 1.5.1

JAL doesn't wait for anymore processing to be ready

General statistics:
  - Start time: 6493
  - End time: 1999898
  - Total elapsed time: 1993405 cycles
  - Instret start: 2174
  - Instret end: 982920
  - Retired instructions: 980746

Instruction Bus Request:
  - active cycles: 1908226
  - sleep cycles: 0
  - stall cycles: 85181

Inst Bus Completion:
  - active cycles: 1102166
  - sleep cycles: 128389
  - stall cycles: 762521

Processing Bus:
  - active cycles: 815637
  - sleep cycles: 815252
  - stall cycles: 335831

Algorithms:
- Chacha20 execution: 55154 cycles
- Matrix execution: 10596 cycles
- Printf execution: 49904 cycles
- Xoshiro128++ execution: 236723 cycles
- Pool Arena execution: 1640273 cycles
