import os
import pandas as pd
import glob

OUTPUT_DIR ="/group/ctbrowngrp2/amhorst/2025-pangenome/results/pangenome"

# set configfile
#configfile: "../config/config.yaml"
pangenome_species = config["pang_org"]
pang_name_out = config["pang_folder"]

rule all:
    input:
        expand(f"{OUTPUT_DIR}/{pang_name_out}/sourmash/{pang_name_out}.generanks.csv",),
        expand(f"{OUTPUT_DIR}/{pang_name_out}/fasta/{pang_name_out}.core.fa",),

# after roary: use script to get genes of interest
# run roary
rule roary_split:
    input:
        check = f"{OUTPUT_DIR}/{pang_name_out}/check/{pang_name_out}.roary.done",
    output:
        csv = f"{OUTPUT_DIR}/{pang_name_out}/sourmash/{pang_name_out}.generanks.csv",
    conda: 
        "branchwater-skipmer"
    threads: 1
    params:
        roary_folder = f"{OUTPUT_DIR}/{pang_name_out}/roary",
    shell:
        """ 
        python scripts/count_genes.py {params.roary_folder}/gene_presence_absence.Rtab \
        {output.csv} {params.roary_folder}/ 
        """

rule split_fasta:
    input:
        check = f"{OUTPUT_DIR}/{pang_name_out}/sourmash/{pang_name_out}.generanks.csv",
        csv_all = f"{OUTPUT_DIR}/{pang_name_out}/sourmash/{pang_name_out}.generanks.csv",
    output:
         core_fa = f"{OUTPUT_DIR}/{pang_name_out}/fasta/{pang_name_out}.core.fa",
         shell_fa = f"{OUTPUT_DIR}/{pang_name_out}/fasta/{pang_name_out}.shell.fa",
         cloud_fa = f"{OUTPUT_DIR}/{pang_name_out}/fasta/{pang_name_out}.cloud.fa",
         soft_core_fa = f"{OUTPUT_DIR}/{pang_name_out}/fasta/{pang_name_out}.soft_core.fa",

    conda: 
        "seqkit"
    threads: 1 
    params:
        roary_folder = f"{OUTPUT_DIR}/{pang_name_out}/roary",
    shell:
        """ 
        seqkit grep -n -r -f {params.roary_folder}/core.txt \
        {params.roary_folder}/pan_genome_reference.fa -o {output.core_fa} && \
        seqkit grep -n -r -f {params.roary_folder}/soft_core.txt \
        {params.roary_folder}/pan_genome_reference.fa -o {output.soft_core_fa} && \
        seqkit grep -n -r -f {params.roary_folder}/shell.txt \
        {params.roary_folder}/pan_genome_reference.fa -o {output.shell_fa} && \
        seqkit grep -n -r -f {params.roary_folder}/cloud.txt \
        {params.roary_folder}/pan_genome_reference.fa -o {output.cloud_fa} 
        """


