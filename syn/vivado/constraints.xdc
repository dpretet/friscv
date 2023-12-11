# Set up timing constraints
create_clock -period 10 -waveform {0 5} [get_ports aclk]
