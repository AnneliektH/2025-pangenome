# Snakefile
import os
import pandas as pd

# Define samples
# define permanent things
KSIZE = 21
# gtdb or pig specific
GENOME_TYPE = 'pig'
PANGENOME_TYPE = 'cloud'
configfile: "../config/config.yaml"

# Set samples for human and pig and microbe species
metadata_human = pd.read_csv(config['human_SRA'], usecols=['acc'])
metadata_pig = pd.read_csv(config['pig_SRA'], usecols=['acc'])

# Create a list of run ids
samples_human = metadata_human['acc'].tolist()
samples_pig = metadata_pig['acc'].tolist()

# Define samples
HUMAN_METAG = config.get('samples', samples_human)
PIG_METAG = config.get('samples', samples_pig)
PANG_SPECIES = 'g_qucibialis'



# for creatong the dmp files
# we want all signatures of metaGs x one microbial species
def calc_hash_input_human(wildcards):
    files = expand("/group/ctbrowngrp/irber/data/wort-data/wort-sra/sigs/{metag}.sig", metag=HUMAN_METAG)
    with open("input_files_human.txt", "w") as f:
        for file in files:
            f.write(f"{file}\n")
    return "input_files_human.txt"

def calc_hash_input_pig(wildcards):
    files = expand("/group/ctbrowngrp2/amhorst/2025-pigparadigm/results/metag_signatures/{metag}.zip", metag=PIG_METAG)
    with open("input_files_pig.txt", "w") as f:
        for file in files:
            f.write(f"{file}\n")
    return "input_files_pig.txt"

# Get input for signatures, either human or pig
# Human are in wort data, pig are in own sketch files
def get_input_file_path(metag):
    if metag in samples_human:
        return "/group/ctbrowngrp/irber/data/wort-data/wort-sra/sigs/{metag}.sig"
    elif metag in samples_pig:
        return "/group/ctbrowngrp2/amhorst/2025-pigparadigm/results/metag_signatures/{metag}.zip"
    else:
        raise ValueError(f"Unknown sample type: {metag}")

# Function to determine the output directory based on the sample type
def get_output_dir(metag):
    if metag in samples_human:
        return "compare_human"
    elif metag in samples_pig:
        return "compare_pig"
    else:
        raise ValueError(f"Unknown sample type: {metag}")


rule all: 
    input:
        expand("../results/metag.x.pang/dmp/{species}.{GENOME_TYPE}.{PANGENOME_TYPE}.cmp.tsv", 
        species=PANG_SPECIES, GENOME_TYPE=GENOME_TYPE, PANGENOME_TYPE=PANGENOME_TYPE),
        expand("../results/metag.x.pang/dmp_human/{species}.{GENOME_TYPE}.x.human.{PANGENOME_TYPE}.dump", 
        species=PANG_SPECIES, GENOME_TYPE=GENOME_TYPE,PANGENOME_TYPE=PANGENOME_TYPE),
        # expand("../results/metag.x.pang/dmp/{species}.{GENOME_TYPE}.cmp.tsv", 
        # species=PANG_SPECIES, GENOME_TYPE=GENOME_TYPE),


# calculate hash presence
rule calc_hash_presence_h:
    input:
       rankt = "/group/ctbrowngrp2/amhorst/2025-pangenome/results/pangenome/{species}/roary/roary_{GENOME_TYPE}/{PANGENOME_TYPE}.rank.csv",
       sig = calc_hash_input_human
    output:
        dmp = "../results/metag.x.pang/dmp_human/{species}.{GENOME_TYPE}.x.human.{PANGENOME_TYPE}.dump",
    conda: 
        "branchwater-skipmer"
    threads: 1 
    shell:
        """ 
        python scripts/calc-hash-presence.py \
        {input.rankt} {input.sig} --scaled=1000 -k {KSIZE} -o {output.dmp}
        """

rule calc_hash_presence_p:
    input:
       rankt = "/group/ctbrowngrp2/amhorst/2025-pangenome/results/metag.x.pang/{GENOME_TYPE}_genes/{PANGENOME_TYPE}.rank.csv",
       sig = calc_hash_input_pig
    output:
        dmp = "../results/metag.x.pang/dmp_pig/{species}.{GENOME_TYPE}.x.pig.{PANGENOME_TYPE}.dump",
    conda: 
        "branchwater-skipmer"
    threads: 1
    shell:
        """ 
        python scripts/calc-hash-presence.py \
        {input.rankt} {input.sig} --scaled=1000 -k {KSIZE} -o {output.dmp}
        """

## Compare dmp files
rule compare_dmp:
    input:
       dmp1 = "../results/metag.x.pang/dmp_human/{species}.{GENOME_TYPE}.x.human.{PANGENOME_TYPE}.dump",
       dmp2 = '../results/metag.x.pang/dmp_pig/{species}.{GENOME_TYPE}.x.pig.{PANGENOME_TYPE}.dump'
    output:
        cmp = "../results/metag.x.pang/dmp/{species}.{GENOME_TYPE}.{PANGENOME_TYPE}.cmp.tsv",
    conda: 
        "branchwater-skipmer"
    threads: 1
    shell:
        """ 
        python scripts/parse-dump.py \
        --dump-files-1 {input.dmp1} \
        --dump-files-2 {input.dmp2} > {output.cmp}
        """
