import os
from pathlib import Path

# Get sample names from folders in results/pangenome
samples = [d.name for d in Path("/group/ctbrowngrp2/amhorst/2025-pangenome/results/pangenome").iterdir() if d.is_dir()]

# Output directory
output_dir = "/group/ctbrowngrp2/amhorst/2025-pangenome/results/gene_output"

# Rule: default target
rule all:
    input:
        expand(f"{output_dir}/gene_presence_absence.{{sample}}.tsv", sample=samples),
        expand(f"{output_dir}/Widb.{{sample}}.csv", sample=samples)

# Rule: rename gene_presence_absence.Rtab
rule rename_rtab:
    input:
        rtab="/group/ctbrowngrp2/amhorst/2025-pangenome/results/pangenome/{sample}/roary/gene_presence_absence.Rtab"
    output:
        renamed=f"{output_dir}/gene_presence_absence.{{sample}}.tsv"
    shell:
        "cp {input.rtab} {output.renamed}"

# Rule: rename Widb.csv
rule rename_widb:
    input:
        widb="/group/ctbrowngrp2/amhorst/2025-pangenome/results/pangenome/{sample}/drep_all/data_tables/Widb.csv"
    output:
        renamed=f"{output_dir}/Widb.{{sample}}.csv"
    shell:
        "cp {input.widb} {output.renamed}"
