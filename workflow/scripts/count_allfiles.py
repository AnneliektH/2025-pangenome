import pandas as pd
import sys
import os

folder_path = sys.argv[1]  # Provide the folder path as a command-line argument
output_path = sys.argv[2] 
all_counts = {}

for file in os.listdir(folder_path):
    if file.endswith(".csv"):
        file_path = os.path.join(folder_path, file)
        df = pd.read_csv(file_path)
        counts = df['pangenome_classification'].value_counts().sort_index()
        all_counts[file] = counts

result_df = pd.DataFrame(all_counts).fillna(0).astype(int)
 # Provide the output file path as the second argument
result_df.to_csv(output_path)
