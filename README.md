# Turbulent Flow in Crude Oil Pipelines: DNS-Validated Design

Graduate turbulence project (MAE 741, 2026): validated the Colebrook–White 
friction model against DNS channel-flow data from the Johns Hopkins 
Turbulence Database (Re_τ = 1000), then applied the validated physics 
to a 50 km crude oil pipeline.

## Key Results
- Friction factor: f = 0.0188
- Pressure drop: 4.87 MPa over 50 km
- Pumping power: 3.32 MW electrical
- 20-year operating cost: $66M
- Temperature optimization: $4.8M NPV swing

## Tools
MATLAB · JHTDB · Colebrook–White · Darcy–Weisbach · Andrade viscosity model

## How to run
1. Get a JHTDB authentication token at turbulence.pha.jhu.edu
2. Open `getData.m` and replace `YOUR_JHTDB_TOKEN_HERE` with your token
3. Run the main analysis script in MATLAB
