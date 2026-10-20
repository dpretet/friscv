# v1.4.0

This release has been initiated to boost performance by reworking the control and the block fetch
stage. Result: CPI passed from 3.67 to 3.57. Not as good as expected but future cache enhance
will improve more.

Control:
- front-end read data channel can be removed now
- the sequencer FSM has been simplified and now avoid RELOAD state. Request can be issued
  without stall time and reboot faster
- the FSM has been splitted, CSR management is done in a dedicated process
- flush_reqs is asserted along a new request
- flush_reqs deactivated makes the performance very bad

iCache block fetcher:
- FSM has been simplified and replaced by a simpler logic
- Front-end FIFO has been first removed then put back because it really enhances the performance
- Less OR if front-end FIFO is removed enhance the performance
- latency is lower by 1 cycle. Flow-thru option is better and can balance performance
- a FIFO has been placed on read data channel to increase performance. Drasticaly better when
  control data path FIFO is removed
- flush_reqs reboots the circuit but a request can be served along this assertion
- cache miss fetch stage has been moved to a dedicated module. To enhance later to increase
  performance

CSR:
- CSR is always ready and instruction executed in one cycle
- new custom register to measure performance

Processing
- Allow multiple instruction in parallel if no hazards occur
- Memfy: enhance outstanding request performance
