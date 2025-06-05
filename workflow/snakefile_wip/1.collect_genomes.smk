import os
import pandas as pd
import glob

# set dbs and other params
GTDB = '/group/ctbrowngrp/sourmash-db/gtdb-rs226/gtdb-rs226.k21.sig.zip'
GTDB_TAX  = '/group/ctbrowngrp/sourmash-db/gtdb-rs226/gtdb-rs226.lineages.csv'
NEW_MAG_TAX = '../resources/250411_mag_taxonomy.tsv'
OWN_MAG_SIG = '/group/ctbrowngrp2/amhorst/2025-pigparadigm/results/sketches/MAGs.99.zip'
KSIZE = 21 
SCALED = 1000

OUTPUT_DIR ="/group/ctbrowngrp2/amhorst/2025-pangenome/results/test_pipeline"
MAG_LOCATION = "/group/ctbrowngrp2/amhorst/2025-pigparadigm/results/drep/drep.99/dereplicated_genomes"

# set configfile
configfile: "../config/config.yaml"
pangenome_species = config["pang_org"]
pang_name_out = config["pang_folder"]

# set list of fasta files
genomes = glob_wildcards(f"{OUTPUT_DIR}/{pang_name_out}/MAGs/{{sample}}_genomic.fasta").sample
genomes_all = glob_wildcards(f"{OUTPUT_DIR}/{pang_name_out}/MAGs/{{sample}}.fasta").sample

# # include snakefiles
# include: "rules/1_collect_genomes.smk"
# include: "rules/2_roary.smk"
# include: "rules/2a_roary_all.smk"
# include: "rules/3_genes_to_hash.smk"


# final output 
rule all:
    input:
        # output files we need from drep (do these first)
        expand(f"{OUTPUT_DIR}/{pang_name_out}/sourmash/{pang_name_out}.gtdb.zip",),
        expand(f"{OUTPUT_DIR}/{pang_name_out}/check/symlink.check",),

# get lists of MAGs that are org of interest
# 2 lists, one for GTDB and one for own MAGs
rule get_mags_of_interest:
    output:
        tsv = f"{OUTPUT_DIR}/{pang_name_out}/{pang_name_out}xownmags.tsv",
        csv_temp = temp(f"{OUTPUT_DIR}/{pang_name_out}/{pang_name_out}xgtdb_temp.csv"),
        csv = f"{OUTPUT_DIR}/{pang_name_out}/{pang_name_out}xgtdb.csv"
    conda: 
        "branchwater-skipmer"
    threads: 1
    shell:
        """ 
        (head -n 1 {NEW_MAG_TAX} && grep -e "{pangenome_species}" {NEW_MAG_TAX}) > {output.tsv} && \
        (head -n 1 {GTDB_TAX} && grep -e "{pangenome_species}" {GTDB_TAX}) > {output.csv_temp} && \
        python scripts/create_acc.py {output.csv_temp} {output.csv}
        """

# Now create 2 folders, for the MAGs. Once for only reference, one for all
# download MAGs from NCBI with directsketch
rule directsketch:
    input:
        csv = f"{OUTPUT_DIR}/{pang_name_out}/{pang_name_out}xgtdb.csv",
    output:
        sig = f"{OUTPUT_DIR}/{pang_name_out}/sourmash/{pang_name_out}.gtdb.zip",
        failed_test = f"{OUTPUT_DIR}/{pang_name_out}/check/{pang_name_out}.failed.csv",
        fail_checksum= f"{OUTPUT_DIR}/{pang_name_out}/check/{pang_name_out}.checksum.failed.csv",
    conda: 
        "branchwater-skipmer"
    threads: 10
    params:
        output_folder=f"{OUTPUT_DIR}/{pang_name_out}/MAGs"
    shell:
        """ 
        sourmash scripts gbsketch  --keep-fasta --genomes-only \
        {input.csv} -o {output.sig} -p dna,k=21,k=31,scaled=100,abund \
        -f {params.output_folder} -k -c {threads} \
        --failed {output.failed_test} -r 1 --checksum-fail {output.fail_checksum}
        for f in {params.output_folder}/*.fna.gz; do
            mv "$f" "${{f%.fna.gz}}.fasta"
        done
        """

# symlink pig-specific MAGs
rule symlink_MAGs:
    input:
        tsv = f"{OUTPUT_DIR}/{pang_name_out}/{pang_name_out}xownmags.tsv",
        #pangenome_species = pangenome_species,
    output:
        check = f"{OUTPUT_DIR}/{pang_name_out}/check/symlink.check",
    conda: 
        "branchwater-skipmer"
    threads: 1
    params:
        output_folder=f"{OUTPUT_DIR}/{pang_name_out}/MAGs"
    shell:
        """ 
        python scripts/create_symlink_args.py {input.tsv} {MAG_LOCATION} {params.output_folder} && \
        touch {output.check}
        """


