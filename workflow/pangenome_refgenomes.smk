import os
import pandas as pd
import glob

# set dbs and other params
GTDB = '/group/ctbrowngrp/sourmash-db/gtdb-rs220/gtdb-reps-rs220-k21.zip'
GTDB_TAX  = '/group/ctbrowngrp/sourmash-db/gtdb-rs220/gtdb-rs220.lineages.csv'
ksize = [21]
scaled =[100]
#scaled = [1,10,50,100,1000]

# result directory
OUTPUT_DIR ="/group/ctbrowngrp2/amhorst/2025-pangenome/results/pangenome"

# set configfile
configfile: "../config/config.yaml"
pangenome_species = config["pang_org"]
pang_name_out = config["pang_folder"]

# set the fasta files
fasta_gtdb = glob_wildcards(f"{OUTPUT_DIR}/{pang_name_out}/MAGs/{{sample}}.fna.gz").sample

# final output 
rule all:
    input:
        # expand(f"{OUTPUT_DIR}/{pang_name_out}/sourmash/{pang_name_out}.rankt.{{ksize}}.{{scaled}}.csv", ksize=ksize, scaled=scaled),
        expand(f"{OUTPUT_DIR}/{pang_name_out}/check/{pang_name_out}.roary.done"),

# get lists of MAGs that are org of interest
rule get_mags_of_interest:
    output:
        csv_temp = temp(f"{OUTPUT_DIR}/{pang_name_out}/{pang_name_out}xgtdb_temp.csv"),
        csv = f"{OUTPUT_DIR}/{pang_name_out}/{pang_name_out}xgtdb.csv"
    conda: 
        "branchwater-skipmer"
    threads: 1
    shell:
        """
        (head -n 1 {GTDB_TAX} && grep -e "{pangenome_species}" {GTDB_TAX}) > {output.csv_temp} && \
        python scripts/create_acc.py {output.csv_temp} {output.csv}
        """

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
        sourmash scripts gbsketch --keep-fasta --genomes-only \
        {input.csv} -o {output.sig} -p dna,k=21,k=31,scaled=1,abund \
        -f {params.output_folder} -k -c {threads} \
        --failed {output.failed_test} -r 1 --checksum-fail {output.fail_checksum}
        """

# run prokka on the gtdb sequences (can i put these rules together?)
rule prokka_gtdb:
    input:
        fa_gtdb = f"{OUTPUT_DIR}/{pang_name_out}/MAGs/{{genome}}.fna.gz",
    output:
        check = f"{OUTPUT_DIR}/{pang_name_out}/check/{{genome}}.prokka.done",
    conda: 
        "prokka"
    threads: 1
    params:
        output_folder=f"{OUTPUT_DIR}/{pang_name_out}/prokka/{{genome}}"
    shell:
        """ 
        prokka --kingdom Bacteria --outdir {params.output_folder} \
        --norrna --notrna --prefix {wildcards.genome} \
        --locustag {wildcards.genome} {input.fa_gtdb} && touch {output.check}
        """

# run roary
rule roary:
    input:
        expand(f"{OUTPUT_DIR}/{pang_name_out}/check/{{genome}}.prokka.done", genome=fasta_gtdb),
        sig = f"{OUTPUT_DIR}/{pang_name_out}/sourmash/{pang_name_out}.gtdb.zip",
    output:
        check = f"{OUTPUT_DIR}/{pang_name_out}/check/{pang_name_out}.roary.done",
    conda: 
        "roary"
    threads: 24
    params:
        prokka_folder = f"{OUTPUT_DIR}/{pang_name_out}/prokka",
        gff_folder = f"{OUTPUT_DIR}/{pang_name_out}/prokka/gff",
        output_folder=f"{OUTPUT_DIR}/{pang_name_out}/roary"
    shell:
        """ 
        mkdir -p {params.gff_folder} && \
        cp {params.prokka_folder}/*/*.gff {params.gff_folder} && \
        roary -p {threads} -f {params.output_folder} \
        -e -n -v {params.gff_folder}/*.gff && touch {output.check}
        """


# sourmash pangenome
rule sourmash_pangenome:
    input: 
        sig_gtdb = f"{OUTPUT_DIR}/{pang_name_out}/sourmash/{pang_name_out}.gtdb.zip"
    output: 
        scaled_sig = f"{OUTPUT_DIR}/{pang_name_out}/sourmash/{pang_name_out}.{{ksize}}.{{scaled}}.zip",
        pang = f"{OUTPUT_DIR}/{pang_name_out}/sourmash/{pang_name_out}.pang.{{ksize}}.{{scaled}}.zip",
        rankt = f"{OUTPUT_DIR}/{pang_name_out}/sourmash/{pang_name_out}.rankt.{{ksize}}.{{scaled}}.csv"
    conda: 
        "pangenomics_dev"
    threads: 1
    shell:
        """ 
        sourmash sig downsample {input.sig_gtdb} -k {wildcards.ksize} \
        --scaled {wildcards.scaled} -o {output.scaled_sig} && \
        sourmash scripts pangenome_merge {output.scaled_sig} -k {wildcards.ksize} \
        -o {output.pang} --scaled {wildcards.scaled} && \
        sourmash scripts pangenome_ranktable {output.pang} -o {output.rankt} \
        -k {wildcards.ksize} --scaled {wildcards.scaled}
        """

