# Hypersonic Flight Dynamics & Trajectory Analysis Suite

A staged MATLAB engineering tool for conceptual hypersonic trajectory simulation, flight-dynamics analysis, vehicle trade studies, and visualization.

This project models how launch conditions, vehicle geometry, aerodynamic assumptions, atmospheric variation, stability characteristics, and uncertainty affect hypersonic flight performance from launch through impact. The tool was built in stages, starting from a simple 2D drag model and expanding into higher-fidelity trajectory analysis, vehicle comparison, Monte Carlo simulation, Pareto trade studies, and an interactive MATLAB app interface.

---

## Project Purpose

The goal of this project is to build a modular aerospace analysis tool that can evaluate conceptual hypersonic vehicle performance across multiple levels of fidelity.

The suite can be used to estimate and compare:

* Downrange distance
* Maximum altitude
* Impact velocity
* Mach number history
* Dynamic pressure
* Stagnation temperature
* Aerodynamic lift and drag effects
* Ballistic coefficient
* Static margin and trim behavior
* Environmental sensitivity
* Vehicle configuration tradeoffs
* Monte Carlo uncertainty effects

This project is intended for conceptual analysis, engineering learning, and portfolio demonstration. It is not a validated weapons-design tool, CFD solver, or flight-certified simulation environment.

---

## Key Features

* 2D trajectory simulation with drag and gravity
* Variable atmosphere and variable gravity modeling
* Mach-dependent aerodynamic behavior
* Dynamic pressure and stagnation temperature tracking
* Vehicle geometry and reference-area modeling
* Lift, drag, and lift-to-drag ratio calculations
* Earth curvature and rotation effects
* Launch angle and mission sweeps
* Vehicle variant comparison
* Ballistic coefficient analysis
* Static margin, trim, and maneuverability checks
* Environmental sensitivity studies
* Simplified 6-DOF flight dynamics baseline
* Physics diagnostics comparing vacuum, drag-only, and full-aero models
* Monte Carlo uncertainty analysis
* Pareto trade-space visualization
* Interactive MATLAB app interface for running and viewing results

---

## Modeling Stages

### Stage 1 — Baseline 2D Trajectory Model

Created a basic 2D projectile trajectory simulation with constant gravity, exponential atmosphere, and drag.

### Stage 2 — Variable Atmosphere and Flight Environment

Added variable gravity, altitude-dependent atmosphere, Mach number, dynamic pressure, and stagnation temperature calculations.

### Stage 3 — Vehicle Geometry and Aerodynamics

Introduced vehicle body parameters, reference area, lift and drag modeling, angle of attack, and lift-to-drag tracking.

### Stage 4 — Earth Curvature and Rotation

Expanded the trajectory model to include spherical Earth assumptions and Earth-rotation effects.

### Stage 5 — Mission Sweep Analysis

Added launch angle sweeps and mission-level performance comparisons to identify best-performing trajectories.

### Stage 6 — Vehicle Variant and Ballistic Coefficient Studies

Compared multiple vehicle configurations to evaluate range, altitude, dynamic pressure, lift-to-drag ratio, and ballistic coefficient effects.

### Stage 7 — Thermal and Stability Extensions

Added supporting analysis for thermal and stability-related flight behavior.

### Stage 8 — Trim, Static Margin, and Maneuverability

Evaluated static margin, center-of-gravity and center-of-pressure relationships, trim angle of attack, and normal acceleration capability.

### Stage 9 — Environmental Sensitivity

Tested vehicle performance across different atmospheric and wind conditions, including hot, cold, dense, thin-air, high-altitude, headwind, tailwind, and crosswind cases.

### Stage 10 — Simplified 6-DOF Baseline

Implemented a simplified 6-degree-of-freedom model including pitch, yaw, roll rates, inertia properties, and basic rotational response.

### Stage 11 — Physics Diagnostics

Added model-comparison tools to evaluate vacuum, drag-only, and full-aerodynamic trajectory behavior.

### Stage 12 — Angle Sweep and Model Comparison

Compared launch angle performance across different physics models and evaluated how drag and lift shift the optimal trajectory.

### Stage 13 — Pareto and Monte Carlo Analysis

Added uncertainty analysis and trade-space visualization to study how input variation affects trajectory outcomes.

### Stage 14 — MATLAB App Interface

Built an interactive MATLAB app interface for running cases, viewing plots, comparing configurations, and exploring results more efficiently.

---

## Example Outputs

The analysis suite can generate outputs such as:

* Altitude vs. time
* Downrange distance vs. time
* Velocity vs. time
* Mach number history
* Dynamic pressure history
* Stagnation temperature history
* Lift and drag histories
* Angle sweep comparison plots
* Vehicle configuration comparison plots
* Monte Carlo result distributions
* Pareto trade-space plots
* Summary tables of key flight metrics

---

## Project Structure

```text
hypersonic-flight-analysis-suite/
├── main.m
├── Stage1/
├── Stage2/
├── Stage3/
├── Stage4/
├── Stage5/
├── Stage6/
├── Stage7/
├── Stage8/
├── Stage9/
├── Stage10/
├── Stage11/
├── Stage12/
├── Stage13/
├── Stage14/
├── Shared/
├── README.md
└── .gitignore
```

The project is organized by development stage so each level of added physics and analysis capability can be reviewed independently.

---

## How to Run

1. Open MATLAB.
2. Navigate to the project folder.
3. Open `main.m`.
4. Select the desired analysis stage inside the script.
5. Run the script.

Example:

```matlab
stage = 14;
```

Then run:

```matlab
main
```

Some stages may produce plots, printed summaries, exported data, or app-based visualizations depending on the selected configuration.

---

## Requirements

This project was developed in MATLAB and primarily uses built-in MATLAB functionality.

Recommended environment:

* MATLAB R2023a or newer
* Basic MATLAB plotting support
* App Designer support for the interactive interface stage

No external toolbox requirements are assumed unless noted in a specific stage file.

---

## Engineering Concepts Used

This project applies concepts from:

* Flight mechanics
* Hypersonic aerodynamics
* Atmospheric modeling
* Compressible flow
* Projectile motion
* Stability and control
* Dynamic pressure analysis
* Stagnation temperature analysis
* Vehicle geometry modeling
* Ballistic coefficient analysis
* Numerical integration
* Monte Carlo simulation
* Design-space exploration
* MATLAB visualization and app development

---

## Assumptions and Limitations

This project is a conceptual engineering analysis tool. Several simplifying assumptions are used depending on the stage, including:

* Simplified aerodynamic coefficient models
* Simplified vehicle geometry
* No CFD-based aerodynamic database
* No propulsion system modeling
* No ablation or detailed thermal protection modeling
* No structural deformation modeling
* No validated control-law implementation
* Simplified 6-DOF rotational dynamics
* Idealized or approximate atmospheric and environmental models

The results should be interpreted as conceptual trade-study outputs, not flight-test predictions.

---

## Future Improvements

Potential future additions include:

* Higher-fidelity aerodynamic coefficient tables
* Control surface and guidance modeling
* Improved 6-DOF rigid-body dynamics
* More advanced thermal protection analysis
* Material temperature-limit checks
* Trajectory optimization
* Additional vehicle presets
* Exportable engineering reports
* Improved MATLAB app visualization
* Automated validation test cases
* Comparison against published benchmark trajectories

---

## Author

Luke Arnold
Aerospace Engineering Student
Purdue University

---

## Disclaimer

This project is for educational, conceptual, and portfolio purposes only. It does not contain proprietary company information, controlled technical data, or validated flight vehicle designs.
