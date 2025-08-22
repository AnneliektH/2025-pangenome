import sys
import os
import pandas as pd

# Inputs
input_file = sys.argv[1]      # The CSV file with gene classifications
category_dir = sys.argv[2]    # Output directory for category txt files

# Ensure the output directory exists
os.makedirs(category_dir, exist_ok=True)

# Load the gene classification CSV
df = pd.read_csv(input_file)

# Write gene_name lists for each category
for category in ["core", "soft_core", "shell", "cloud"]:
    df_genes = df[df["type"] == category]["gene_name"]
    df_genes.to_csv(os.path.join(category_dir, f"{category}_drep.txt"), index=False, header=False)
