import os
import pandas as pd
import glob

OUTPUT_DIR ="/group/ctbrowngrp2/amhorst/2025-pangenome/results/test_pipeline"

# set configfile
configfile: "../config/config.yaml"
pangenome_species = config["pang_org"]
pang_name_out = config["pang_folder"]

rule all:
    input:
        expand(f"{OUTPUT_DIR}/{pang_name_out}/sourmash/{pang_name_out}.generanks.csv",),
        expand(f"{OUTPUT_DIR}/{pang_name_out}/fasta/{pang_name_out}.core.gtdb.fa",),

# after roary: use script to get genes of interest
# run roary
rule roary_split:
    input:
        check = f"{OUTPUT_DIR}/{pang_name_out}/check/{pang_name_out}.roary.done",
        check_all = f"{OUTPUT_DIR}/{pang_name_out}/check/{pang_name_out}.roary.all.done",
    output:
        csv = f"{OUTPUT_DIR}/{pang_name_out}/sourmash/{pang_name_out}.generanks.csv",
        csv_all = f"{OUTPUT_DIR}/{pang_name_out}/sourmash/{pang_name_out}.generanks_all.csv",
    conda: 
        "branchwater-skipmer"
    threads: 1
    params:
        roary_folder = f"{OUTPUT_DIR}/{pang_name_out}/roary_ref",
        roary_all_folder = f"{OUTPUT_DIR}/{pang_name_out}/roary_all",
    shell:
        """ 
        python scripts/count_genes.py {params.roary_folder}/gene_presence_absence.Rtab \
        {output.csv} {params.roary_folder}/ && \
        python scripts/count_genes.py {params.roary_all_folder}/gene_presence_absence.Rtab \
        {output.csv_all} {params.roary_all_folder}/
        """

rule split_fasta:
    input:
        check = f"{OUTPUT_DIR}/{pang_name_out}/sourmash/{pang_name_out}.generanks.csv",
        csv_all = f"{OUTPUT_DIR}/{pang_name_out}/sourmash/{pang_name_out}.generanks_all.csv",
    output:
         core_fa = f"{OUTPUT_DIR}/{pang_name_out}/fasta/{pang_name_out}.core.gtdb.fa",
         shell_fa = f"{OUTPUT_DIR}/{pang_name_out}/fasta/{pang_name_out}.shell.gtdb.fa",
         cloud_fa = f"{OUTPUT_DIR}/{pang_name_out}/fasta/{pang_name_out}.cloud.gtdb.fa",
         core_fa_all = f"{OUTPUT_DIR}/{pang_name_out}/fasta/{pang_name_out}.core.all.fa",
         shell_fa_all = f"{OUTPUT_DIR}/{pang_name_out}/fasta/{pang_name_out}.shell.all.fa",
         cloud_fa_all = f"{OUTPUT_DIR}/{pang_name_out}/fasta/{pang_name_out}.cloud.all.fa",
    conda: 
        "seqkit"
    threads: 1
    params:
        roary_folder = f"{OUTPUT_DIR}/{pang_name_out}/roary_ref",
        roary_all_folder = f"{OUTPUT_DIR}/{pang_name_out}/roary_all",
    shell:
        """ 
        seqkit grep -n -r -f {params.roary_folder}/core.txt \
        {params.roary_folder}/pan_genome_reference.fa -o {output.core_fa} && \
        seqkit grep -n -r -f {params.roary_folder}/shell.txt \
        {params.roary_folder}/pan_genome_reference.fa -o {output.shell_fa} && \
        seqkit grep -n -r -f {params.roary_folder}/cloud.txt \
        {params.roary_folder}/pan_genome_reference.fa -o {output.cloud_fa} && \
        seqkit grep -n -r -f {params.roary_all_folder}/core.txt \
        {params.roary_all_folder}/pan_genome_reference.fa -o {output.core_fa_all} && \
        seqkit grep -n -r -f {params.roary_all_folder}/cloud.txt \
        {params.roary_all_folder}/pan_genome_reference.fa -o {output.cloud_fa_all} 
        seqkit grep -n -r -f {params.roary_all_folder}/shell.txt \
        {params.roary_all_folder}/pan_genome_reference.fa -o {output.shell_fa_all} 
        """


