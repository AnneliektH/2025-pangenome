import sys
import os
import pandas as pd

input_file = sys.argv[1]
output_file = sys.argv[2]
category_dir = sys.argv[3]  # new argument for output directory

# Ensure the output directory exists
os.makedirs(category_dir, exist_ok=True)

df = pd.read_csv(input_file, sep="\t", index_col=0)
num_columns = df.shape[1]

output_df = pd.DataFrame({
    "gene_name": df.index,
    "num_found": df.sum(axis=1),
    "perc_genomes": df.sum(axis=1) / num_columns
})

def classify_type(p):
    if 0.95 <= p <= 1.0:
        return "core"
    elif 0.90 <= p < 0.95:
        return "soft_core"
    elif 0.15 <= p < 0.95:
        return "shell"
    else:
        return "cloud"

output_df["type"] = output_df["perc_genomes"].apply(classify_type)

output_df.to_csv(output_file, index=False)

# Save category-specific gene name lists in the specified directory
for category in ["core", "soft_core", "shell", "cloud"]:
    df_genes = output_df[output_df["type"] == category]["gene_name"]
    df_genes.to_csv(os.path.join(category_dir, f"{category}.txt"), index=False, header=False)
