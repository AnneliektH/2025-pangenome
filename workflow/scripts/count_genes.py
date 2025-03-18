import sys
import pandas as pd

df = pd.read_csv(sys.argv[1], sep="\t", index_col=0)
output_file = sys.argv[2]
num_columns = df.shape[1]

output_df = pd.DataFrame({
    "gene_name": df.index,
    "num_found": df.sum(axis=1),
    "perc_genomes": df.sum(axis=1) / num_columns
})

def classify_type(p):
    if 0.99 <= p <= 1.0:
        return "hard_core"
    elif 0.95 <= p < 0.99:
        return "soft_core"
    elif 0.15 <= p < 0.95:
        return "shell"
    else:
        return "cloud"

output_df["type"] = output_df["perc_genomes"].apply(classify_type)

output_df.to_csv(output_file, index=False)

import sys
import pandas as pd

input_file = sys.argv[1]
output_file = sys.argv[2]

df = pd.read_csv(input_file, sep="\t", index_col=0)
num_columns = df.shape[1]

output_df = pd.DataFrame({
    "gene_name": df.index,
    "num_found": df.sum(axis=1),
    "perc_genomes": df.sum(axis=1) / num_columns
})

def classify_type(p):
    if 0.99 <= p <= 1.0:
        return "hard_core"
    elif 0.95 <= p < 0.99:
        return "soft_core"
    elif 0.15 <= p < 0.95:
        return "shell"
    else:
        return "cloud"

output_df["type"] = output_df["perc_genomes"].apply(classify_type)

output_df.to_csv(output_file, index=False)

# Create text files for each category
for category in ["hard_core", "soft_core", "shell", "cloud"]:
    df_genes = output_df[output_df["type"] == category]["gene_name"]
    df_genes.to_csv(f"{category}.txt", index=False, header=False)
