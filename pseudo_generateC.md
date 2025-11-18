# Pseudocode — Logic Matrix Generator (generateC.m)
### Multidimensional DeGroot Model (Ye et al., 2020 Compatible)

---

## 1. Overview

The function `generateC.m` produces the logic matrices C_i for each agent i.
Each C_i is an m × m matrix describing that agent's internal belief-system
dependencies between m topics.

The generator supports:
- irreducible logic (strongly connected topics)
- cascade structure (lower block-triangular)
- competing logical interdependencies
- heterogeneous or homogeneous agents
- signed or unsigned dependencies (negative or positive topic links)
- toolbox-free random sampling

---

## 2. Main Function Structure

FUNCTION generateC(n, m, options):

1. Set default values:
       type     ← "heterogeneous"
       pattern  ← "random"
       signed   ← false
       blocks   ← empty
       seed     ← empty
       alpha, beta ← shape parameters for Beta sampling

2. Parse user options:
       If 'seed' provided:
            set random seed
       Override defaults where applicable

3. Allocate memory:
       Create C_matrices of size (m × m × n)

4. For each agent i from 1 to n:
       If pattern == "irreducible":
            C_i ← makeIrreducibleMatrix(m, signed)

       Else if pattern == "cascade":
            C_i ← makeCascadeMatrix(blocks, signed)

       Else if pattern == "competing":
            C_i ← makeCompetingMatrix(m)

       Else:  (pattern == "random")
            C_i ← makeRandomMatrix(m, alpha, beta, signed)

       Normalize rows of C_i:
            For each row r:
                C_i(r,:) = C_i(r,:) / sum(abs(C_i(r,:)))

       Store C_i into C_matrices(:,:,i)

5. If type == "homogeneous":
       For all i > 1:
            C(:,:,i) = C(:,:,1)

6. Return C_matrices

---

## 3. Subfunctions

### A. makeRandomMatrix(m, α, β, signed)
Purpose: generate a random logic matrix using a Beta-like distribution.

1. For each entry (i,j):
       Sample Beta(α, β) using gamma-ratio method:
           g1 = sum of α exponential random variables
           g2 = sum of β exponential random variables
           beta_sample = g1 / (g1 + g2)

       Assign C(i,j) = beta_sample

2. If signed == true:
       Map values to [-1, 1]:
           C = 2*C - 1

3. Return C

---

### B. makeIrreducibleMatrix(m, signed)
Purpose: strongly connected logic matrix (all topics interdependent)

1. Create dense random matrix of size m × m
2. If signed == true:
       Randomly assign positive or negative signs
3. Return matrix

---

### C. makeCascadeMatrix(blocks, signed)
Purpose: block-lower-triangular (cascade) logic structure

1. Determine block boundaries from "blocks" vector

2. For each block:
       Fill diagonal block with random values
       Ensure entries above the block diagonal = 0

3. If signed == true:
       Randomly assign signs within allowed positions

4. Return matrix

---

### D. makeCompetingMatrix(m)
Purpose: introduce competing logical interdependencies

1. Generate random positive matrix
2. Select a random column j
3. Multiply column j by -1 (flip signs)
4. Return matrix

---

## 4. Row Normalization

All C matrices must satisfy:

   sum(abs(row)) = 1

Normalization procedure:

For each row r:
    If row is all zeros → replace with ones
    Normalize:
        row = row / sum(abs(row))

Return normalized matrix

---

## 5. Pattern Summary

| Pattern       | Meaning                           | Expected Behavior |
|---------------|-----------------------------------|-------------------|
| irreducible   | fully connected topics            | full consensus    |
| cascade       | hierarchical topic structure      | partial consensus |
| competing     | opposite topic logic              | disagreement      |
| random        | no imposed structure              | baseline case     |

---

## 6. Output

The function returns:

C_matrices   (m × m × n)

where C(:,:,i) is the logic matrix for agent i.

