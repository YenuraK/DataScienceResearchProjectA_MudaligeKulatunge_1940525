# Creation of Influential Network

## 1. Function to Create Initial **W** Matrix

We focus only on **Barabási–Albert (BA)** Networks and **Watts–Strogatz (WS)** Networks.
### Function Input Format
W = create_initial_W_matrix(n, d, p, m, seed, network)

### Watts–Strogatz (WS) Networks
Parameters:
- **n** – number of agents  
- **d** – number of nearest nodes (**must be an even number**)  
- **p** – probability of rewiring  

### Barabási–Albert (BA) Networks
Parameters:
- **n** – number of agents  
- **m** – initial existing agents  

**Note: if d is not needed for Barabási–Albert networks, set d=[]. Similarly, if m is not needed for Watts–Strogatz network, set m=[]**

## 2. Function to plot the network
For simplicity, we only plot undirected graph.<br>
The node size is corresponding to its number of neighbours.

