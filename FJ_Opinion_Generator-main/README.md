# 🧠 FJ Opinion Generator (MATLAB)

*A lightweight and modular opinion initialization tool for the Friedkin–Johnsen (FJ) social influence model.*

---

## 🚀 Overview

This MATLAB toolkit generates an initial opinion matrix **X₀**, which serves as the input for **Friedkin–Johnsen (FJ)** or related social influence models.
It provides interactive parameter setup, dynamic Beta-distribution sampling, automatic summary generation, and full visualization (histograms, boxplots, and correlation heatmaps).

From v1.1 onward, the toolkit also supports **multi-seed generation** for robustness analysis:
you can generate many independent X₀ samples and compare empirical statistics against the theoretical Beta model.

---

## 🔧 Key Features

* 🧮 **Interactive parameter input**
  Configurable: `n`, `m`, `μ`, `κ`, `scale`, `corr` (and `seed_count` in multi-seed mode).
* 🧠 **Dynamic μ / κ generation**
  Defaults automatically adapt to the number of topics `m`.
* 📊 **Comprehensive visualization (single-seed)**
  Beta PDFs, boxplots, and cross-topic correlations.
* 📊 **Multi-seed robustness analysis (new)**
  Aggregated histograms vs Beta PDFs, per-seed topic-mean boxplots, mean ± std vs theoretical μ, and KS goodness-of-fit tests.
* 💾 **Timestamped CSV export**
  Reproducible and versioned opinion datasets and summaries.
* 🔁 **Deterministic sampling**
  Multi-seed mode uses a fixed sequence of seeds (1..seed_count) for strict reproducibility.
* 🧱 **Modular design**
  Each file handles one clear task (generation, visualization, analysis).

---

## 📁 Project Structure

```text
FJ_Opinion_Generator/
│
├── src/
│   ├── run_generate_X0.m              # Main interactive script (single-seed X₀)
│   ├── run_generate_X0_multi_seed.m   # Multi-seed robustness script (new)
│   ├── generate_X0_core.m             # Core Beta distribution generator
│   ├── plot_X0_distributions.m        # Single-seed visualization (histogram, boxplot, heatmap)
│   └── plot_X0_multi_seed.m           # Multi-seed visualization & KS analysis (new)
│
├── data/                              # Example output files
│   ├── X0_output_2025-11-12_23-59.csv      # Single-seed opinion matrix (n × m)
│   ├── X0_summary_2025-11-12_23-59.csv     # Single-seed summary (mean, variance, extremes)
│   ├── X0_seed_001_2025-11-14_21-30.csv    # Example multi-seed X₀ (per seed)
│   └── X0_multi_summary_2025-11-14_21-30.csv # Multi-seed topic-level summary (new)
│
└── README.md                          # Documentation (this file)
```

---

## 🧩 How to Use

### 1️⃣ Single-seed mode (interactive X₀ generator)

In MATLAB Command Window:

```matlab
run_generate_X0
```

Then follow the dialog prompts to input parameters:

| Parameter     | Description                              |
| ------------- | ---------------------------------------- |
| **n**         | Number of individuals (rows in X₀)       |
| **m**         | Number of topics (columns in X₀)         |
| **μ (mu)**    | Mean opinion tendency per topic          |
| **κ (kappa)** | Concentration (higher = more consensus)  |
| **scale**     | `'prob'` → [0,1]; `'att'` → [-1,1]       |
| **corr**      | Cross-topic correlation (0–1)            |
| **seed**      | Optional random seed for reproducibility |

💡 When you enter `m`, default μ and κ vectors auto-adjust (e.g. `[0.5 0.5 0.5]`).

#### Visualization (single-seed)

The tool automatically displays:

* Histogram + theoretical Beta PDF (per topic)
* Boxplot of all topics
* Cross-topic correlation heatmap

> *Note: Small nonzero sample correlations when `corr = 0` are expected due to finite-sample noise.*

#### Export (single-seed)

After generation, you can save:

* **`X0_output_YYYY-MM-DD_HH-MM.csv`** → opinion matrix (n × m)
* **`X0_summary_YYYY-MM-DD_HH-MM.csv`** → descriptive statistics (mean, variance, extremes)

---

### 2️⃣ Multi-seed mode (robustness / stability analysis) 🆕

Use this mode when you want to check **how stable your initialization scheme is** across many random draws.

In MATLAB Command Window:

```matlab
run_generate_X0_multi_seed
```

You will first be asked for `n` and `m`, then for the full parameter set:

| Parameter      | Description                                  |
| -------------- | -------------------------------------------- |
| **n**          | Number of individuals (rows in each X₀)      |
| **m**          | Number of topics (columns in each X₀)        |
| **μ (mu)**     | Mean opinion tendency per topic              |
| **κ (kappa)**  | Concentration (higher = more consensus)      |
| **scale**      | `'prob'` → [0,1]; `'att'` → [-1,1]           |
| **corr**       | Cross-topic correlation (0–1)                |
| **seed_count** | Number of independent X₀ samples to generate |

Internally, the script uses:

```matlab
rng(s, 'twister');   % s = 1, 2, ..., seed_count
```

so that:

* **X₀⁽¹⁾** always corresponds to seed = 1
* **X₀⁽²⁾** always corresponds to seed = 2
* …
  This guarantees **full reproducibility** given `n`, `m`, `μ`, `κ`, `scale`, `corr`, and `seed_count`.

#### Visualization (multi-seed)

`plot_X0_multi_seed.m` produces a single consolidated figure:

1. **Row 1 — Empirical vs theoretical Beta (per topic)**

   * All samples from all seeds for each topic are pooled.
   * A histogram is plotted and overlaid with the theoretical Beta PDF implied by (μ, κ).

2. **Row 2 — Boxplot of per-seed topic means**

   * For each topic, the mean across individuals is computed for each seed.
   * The boxplot shows the variability of these means across seeds.

3. **Row 3 — Mean ± std across seeds vs theoretical μ**

   * Topic-level mean of the per-seed means
   * Error bars show standard deviation across seeds
   * Red dashed line = theoretical μ

4. **KS-test summary (command window)**

   * For each topic, a Kolmogorov–Smirnov test compares the pooled empirical distribution to the Beta(μ·κ, (1−μ)·κ) model.
   * Output: `h` (0 = fail to reject, 1 = reject) and `p`-value.

This gives a compact yet powerful overview of whether your **X₀ generator truly behaves like a Beta prior** and how sensitive it is to random initialization.

#### Export (multi-seed)

At the end, you will be asked:

1. **“Export individual X₀ matrices for each seed?”**

   * If *Yes*, the script writes one CSV per seed:
     `X0_seed_001_TIMESTAMP.csv`, …, `X0_seed_N_TIMESTAMP.csv`.

2. **“Export summary statistics across seeds?”**

   * If *Yes* and `seed_count > 1`, a topic-level summary is written:
     `X0_multi_summary_TIMESTAMP.csv` containing, for each topic:

     * theoretical `μ` and `κ`
     * empirical mean and standard deviation across seeds
     * KS-test `p`-value and decision flag

When `seed_count = 1`, the script gracefully falls back to the same behavior as the single-seed mode (single X₀ visualization + single summary table).

---

## 🧠 Integration Example

### MATLAB

```matlab
% Load a generated X₀ (single-seed example)
X0 = readmatrix('data/X0_output_2025-11-12_23-59.csv');

% Example integration into an FJ update model
X_next = A * W * X0 * C' + (eye(size(A)) - A) * X0;
```

For multi-seed experiments, you can loop over all `X0_seed_*.csv` files and run the full FJ dynamics for each initial condition.

---

## 📊 Example Output Summary (single-seed)

| Topic | Mean | Variance | P(X>0.9) | P(X<0.1) |
| :---- | :--: | :------: | :------: | :------: |
| 1     | 0.52 |   0.021  |   0.05   |   0.06   |
| 2     | 0.50 |   0.023  |   0.04   |   0.05   |
| 3     | 0.51 |   0.024  |   0.05   |   0.04   |

In multi-seed mode, an additional summary table is produced with **mean over seeds**, **std over seeds**, and **KS-test results** for each topic.

---

## 💡 Tips

* Larger `n` (e.g., 10,000) → smoother Beta PDFs and smaller sampling noise.
* Smaller `κ` → more diverse opinions (less initial consensus).
* Use `seed_count > 1` to verify that your conclusions are not driven by a single random draw of X₀.
* Timestamped filenames make it easy to track different experimental configurations.

---

## 📜 License

Released under the **MIT License** — free for academic and research use.

---

## 👨‍💻 Author

Developed by **Yongwen**
Data Science / Research Project A
*University of Adelaide, 2025*
