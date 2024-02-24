# viper-osic-docker-analog
An open-source integrated circuit (OSIC) analog design environment Docker 
image containing all the tools necessary to do schematic-level analog design. 
It is meant to be as light weight as possible to keep compute requirements low.
This enables  

This Docker image also has an associated devcontainer which allows it to be 
used with GitHub codespaces.  It can also be ran with VS Code locally, or on a
remote server.

## Tools

The tools are selected to enable the definition of circuit schematics, simulate
them, and post-process the results.

- xschem: Schematic entry and netlisting tool
- ngspice: Spice simulator

TODO: Add the following tools
- Xyce: Simulator from Sandia national lab
- Xyce-xdm: netlist conversion tool

## SKY130 PDK

The SKY130 PDK is installed with a minimal setup.