import os
import pandas as pd
import glob

OUTPUT_DIR ="/group/ctbrowngrp2/amhorst/2025-pangenome/results/pangenome"

# set configfile
configfile: "../config/config.yaml"
pangenome_species = config["pang_org"]
pang_name_out = config["pang_folder"]

rule all:
    input:
        expand(f"{OUTPUT_DIR}/{pang_name_out}/check/{pang_name_out}.generanks.drep.done",),
        expand(f"{OUTPUT_DIR}/{pang_name_out}/fasta/{pang_name_out}.core.drep.fa",),

# after roary: use script to get genes of interest
# run roary
rule roary_split:
    input:
        csv = f"{OUTPUT_DIR}/{pang_name_out}/sourmash/{pang_name_out}.generanks.drep.csv",
    output:
        check = f"{OUTPUT_DIR}/{pang_name_out}/check/{pang_name_out}.generanks.drep.done",
    conda: 
        "branchwater-skipmer"
    threads: 1
    params:
        roary_folder = f"{OUTPUT_DIR}/{pang_name_out}/roary",
    shell:
        """ 
        python scripts/drep_genes_subset.py {input.csv} \
        {params.roary_folder}/ && touch {output.check}
        """

rule split_fasta:
    input:
        check = f"{OUTPUT_DIR}/{pang_name_out}/check/{pang_name_out}.generanks.drep.done",
    output:
         core_fa = f"{OUTPUT_DIR}/{pang_name_out}/fasta/{pang_name_out}.core.drep.fa",
         shell_fa = f"{OUTPUT_DIR}/{pang_name_out}/fasta/{pang_name_out}.shell.drep.fa",
         cloud_fa = f"{OUTPUT_DIR}/{pang_name_out}/fasta/{pang_name_out}.cloud.drep.fa",
         soft_core_fa = f"{OUTPUT_DIR}/{pang_name_out}/fasta/{pang_name_out}.soft_core.drep.fa",
    conda: 
        "seqkit"
    threads: 1 
    params:
        roary_folder = f"{OUTPUT_DIR}/{pang_name_out}/roary",
    shell:
        """ 
        seqkit grep -n -r -f {params.roary_folder}/core_drep.txt \
        {params.roary_folder}/pan_genome_reference.fa -o {output.core_fa} && \
        seqkit grep -n -r -f {params.roary_folder}/soft_core_drep.txt \
        {params.roary_folder}/pan_genome_reference.fa -o {output.soft_core_fa} && \
        seqkit grep -n -r -f {params.roary_folder}/shell_drep.txt \
        {params.roary_folder}/pan_genome_reference.fa -o {output.shell_fa} && \
        seqkit grep -n -r -f {params.roary_folder}/cloud_drep.txt \
        {params.roary_folder}/pan_genome_reference.fa -o {output.cloud_fa} 
        """


