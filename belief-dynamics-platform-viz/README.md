# Belief Dynamics Visualization Toolkit (Research Project A)

This branch provides the standard visualization module for the Belief System Dynamics project.
All group members must output their simulation in a unified format, so everyone can use the same visualization without modification.

The toolkit renders publication-quality network snapshots (e.g., t = 1, 5, 100) using:

- Belief evolution matrix X_series  
- Influence matrix W  
- Node coordinates coords  

Node colors encode belief values (−1 = Anti, +1 = Pro).

---

## 1. Required Simulation Output Format

Every simulation must save a .mat file named:

    my_simulation_output.mat

It must contain exactly these variables:

| Variable | Size | Description |
|----------|-------|-------------|
| X_series | n × T | Belief values of agent i at time t. Must be within [-1, 1]. |
| W        | n × n | Influence matrix. Should be row-normalized. |
| coords   | n × 2 or [] | Optional node layout. If empty, layout will be auto-generated. |

Save example:

```matlab
save('my_simulation_output.mat','X_series','W','coords');
```

## 2. Folder Structure
```matlab
viz/
├── demo/
│   ├── demo_generate_example.m     % minimal example: simulate + save .mat
│   └── demo_plot_only.m            % load .mat + run visualization
└── src/
    ├── plot_belief_network_evolution.m   % main plotting function (a–c)
    ├── generate_layout.m                 % stable node layout generator
    ├── redblue.m                         % blue–white–red colormap
    └── wattsStrogatz.m                   % (optional) small-world generator
```

## 3. How to Run the Visualization
Step 1 — Add path
```matlab
addpath('viz');
addpath('viz/src');
```

Step 2 — Load simulation output
```matlab
load('my_simulation_output.mat');
```

Step 3 — Generate layout (if coords is empty)
```matlab
if isempty(coords)
    coords = generate_layout(W);
end
```
Step 4 — Produce the visualization (3-panel a–c)
```matlab
plot_belief_network_evolution(X_series, W, coords, [1 5 100], {'a','b','c'});
```

📌 Detailed Explanation of Each File

✔ plot_belief_network_evolution.m

The core visualization function.
Input:
```matlab
plot_belief_network_evolution(X_series, W, coords, timepoints, labels);
```
	•	X_series → beliefs across time
	•	W → adjacency
	•	coords → node positions (if missing → call generate_layout)
	•	timepoints → e.g. [1 5 100]
	•	labels → e.g. {'a','b','c'}

This function will:
	•	create 1 row × 3 column figure
	•	apply consistent color scale
	•	apply clean layout and styling
	•	label each panel with a, b, c
	•	write t = ... below each subplot
	•	attach a vertical colorbar

✔ generate_layout.m

Stable force-directed layout:
```matlab
function coords = generate_layout(W, seed)
    if nargin < 2, seed = 42; end
    rng(seed);
    G = graph(W>0);
    p = plot(G);
    layout(p,'force');
    coords = [p.XData(:), p.YData(:)];
    close(gcf);
end
```
Produces consistent plotting positions across runs.

✔ redblue.m

Color map from −1 (blue) → 0 (white) → +1 (red).
Used internally; no modification required.


✔ wattsStrogatz.m

Optional helper for anyone who wants WS networks.
Not required unless your simulation uses it.

