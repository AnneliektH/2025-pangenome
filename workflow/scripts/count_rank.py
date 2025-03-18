import pandas as pd
import sys

file_path = sys.argv[1]  # Provide the CSV file path as a command-line argument

df = pd.read_csv(file_path)
counts = df['pangenome_classification'].value_counts().sort_index()

print(counts)
