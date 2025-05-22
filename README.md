# Rocket-Bike

🚴‍♂️💨 A small-scale propulsion experiment built around the idea of strapping a pressurized air tank and nozzle system to a bicycle. This project explores the physics of thrust, choked flow, and acceleration in a controlled (yet ridiculous) testbed.

## Overview

The Rocket-Bike is a team-built experimental platform designed to evaluate the performance of compressed-air propulsion on a lightweight vehicle. It simulates basic rocketry principles—thrust generation via expanding gases—but keeps things grounded (literally).

The core simulation models pressurized air exiting a nozzle, accounting for choked vs. non-choked flow, pressure drop, mass flow rate, and resulting acceleration. The system includes logging for thrust, acceleration, velocity, and distance traveled.

### Features

- 📐 Adjustable tank pressure and nozzle diameter
- 🔬 Models choked vs. non-choked flow regimes
- 📊 Outputs total impulse, peak thrust, delta-v, burn duration, and peak Gs
- 🧠 Safety-focused: designed to stay within human-tolerable limits (e.g. < 1g acceleration)
- 📦 CSV export of thrust curve for further analysis

## Current Configuration (example)

- Tank pressure: 800 psi
- Nozzle diameter: 3/8 inch
- Tank volume: 10 liters
- Vehicle mass (rider + bike): 81.65 kg
- Starting speed: ~10 mph
- Goal: ~10 mph delta-v with peak acceleration under 1g

## Limitations

- Assumes ideal gas behavior and isothermal flow conditions
- Horizontal tank orientation makes liquid propellant (like water) unfeasible
- Nozzle thrust direction must be consistent for clean acceleration—requires mounting precision
- No real-time control or steering yet—this is a straight-line demo system

## Team Notes

We explored adding water to the tank to increase thrust via higher expelled mass, but ruled it out. In a horizontal tank, the water doesn't pool near the nozzle like in a bottle rocket, so the expulsion would be unpredictable and unsafe. We’ve opted to stick with air-only systems for now to ensure reliable, directional thrust.

## Usage

Run the simulation script in MATLAB. Adjust parameters in the `CONFIGURABLE PARAMETERS` section. Key metrics are displayed in the command window and optionally saved as CSV.

```matlab
% Run simulation
rocket_bike_sim.m
