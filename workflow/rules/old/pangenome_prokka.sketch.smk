import os
import pandas as pd
import glob

# set dbs and other params
ksize = [21, 31]
k_prot = [12,15,18]
scaled = [10]


# result directory
OUTPUT_DIR ="/group/ctbrowngrp2/amhorst/2025-pangenome/results/pangenome"

# set configfile
configfile: "../config/config.yaml"
pangenome_species = config["pang_org"]
pang_name_out = config["pang_folder"]


# set the fasta files
fasta_gtdb = glob_wildcards(f"{OUTPUT_DIR}/{pang_name_out}/MAGs/{{sample}}.fna.gz").sample
fa_transcript = glob_wildcards(f"{OUTPUT_DIR}/{pang_name_out}/prokka/{{sample}}/{{sample}}.ffn").sample
fa_prot = glob_wildcards(f"{OUTPUT_DIR}/{pang_name_out}/prokka/{{sample}}/{{sample}}.faa").sample
# FASTA, = glob_wildcards('../results/pangenome/l_amylovorus/prokka/ffn/{fasta}.ffn')
# PROTFASTA, = glob_wildcards('../results/pangenome/l_amylovorus/prokka/faa/{fasta}.faa')

rule all:
    input:
        expand(f"{OUTPUT_DIR}/{pang_name_out}/test_params/protein_dayhoff/{{genome}}.prot.zip", genome=fasta_gtdb),
        expand(f"{OUTPUT_DIR}/{pang_name_out}/test_params/transcript_dayhoff/{{genome}}.ffn.zip", genome=fasta_gtdb),
        expand(f"{OUTPUT_DIR}/{pang_name_out}/test_params/transcript/{{genome}}.ffn.zip", genome=fasta_gtdb),

# sketch proteins  
rule sketch_protein:
    input:
        fa = f"{OUTPUT_DIR}/{pang_name_out}/prokka/{{genome}}/{{genome}}.faa"
    output:
        sig = f"{OUTPUT_DIR}/{pang_name_out}/test_params/protein/{{genome}}.prot.zip",
        sig_dayhoff = f"{OUTPUT_DIR}/{pang_name_out}/test_params/protein_dayhoff/{{genome}}.prot.zip"
    conda: 
        "branchwater-skipmer"
    threads: 1
    shell:
        """
        sourmash sketch protein {input.fa} \
        -p k=12,k=15,k=18,k=21,scaled=10,abund \
        --name {wildcards.genome} -o {output.sig} && \
        sourmash sketch protein {input.fa} \
        -p k=12,k=15,k=18,k=21,scaled=10,abund --dayhoff \
        --name {wildcards.genome} -o {output.sig_dayhoff}
        """
# sketch dna 
rule sketch_transcript:
    input:
        fna = f"{OUTPUT_DIR}/{pang_name_out}/prokka/{{genome}}/{{genome}}.ffn"
    output:
        sig = f"{OUTPUT_DIR}/{pang_name_out}/test_params/transcript/{{genome}}.ffn.zip",
    conda: 
        "branchwater-skipmer"
    threads: 1
    shell:
        """
        sourmash sketch dna {input.fna} \
        -p k=21,k=31,scaled=10,abund \
        --name {wildcards.genome} -o {output.sig}
        """
rule sketch_transcript_translate:
    input:
        fna = f"{OUTPUT_DIR}/{pang_name_out}/prokka/{{genome}}/{{genome}}.ffn"
    output:
        sig = f"{OUTPUT_DIR}/{pang_name_out}/test_params/transcript_tr/{{genome}}.ffn.zip",
        sig_dayhoff = f"{OUTPUT_DIR}/{pang_name_out}/test_params/transcript_dayhoff/{{genome}}.ffn.zip",
    conda: 
        "branchwater-skipmer"
    threads: 1
    shell:
        """
        sourmash sketch translate {input.fna} \
        -p k=12,k=15,k=18,k=21,scaled=10,abund \
        --name {wildcards.genome} -o {output.sig} && \
        sourmash sketch translate {input.fna} \
        -p k=12,k=15,k=18,k=21,scaled=10,abund --dayhoff \
        --name {wildcards.genome} -o {output.sig_dayhoff} 
        """

# rule cat_sigs_pangenome:
#     input:
#         sigs = expand(f"{OUTPUT_DIR}/{pang_name_out}/sourmash/transcript/{{genome}}.fna.zip", genome=fasta_gtdb)
#     output:
#         sig = f"{OUTPUT_DIR}/{pang_name_out}/sourmash/transcript/{pang_name_out}.fna.zip",
#         scaled_sig = f"{OUTPUT_DIR}/{pang_name_out}/sourmash/transcript/{pang_name_out}.{{ksize}}.{{scaled}}.fna.zip",
#         pang = f"{OUTPUT_DIR}/{pang_name_out}/sourmash/transcript/{pang_name_out}.pang.{{ksize}}.{{scaled}}.fna.zip",
#         rankt = f"{OUTPUT_DIR}/{pang_name_out}/sourmash/transcript/{pang_name_out}.rankt.{{ksize}}.{{scaled}}.fna.csv"
#     conda: 
#         "pangenomics_dev"
#     threads: 1
#     shell:
#         """
#         sourmash sig cat {input.sigs} -o {output.sig} && \
#         sourmash sig downsample {output.sig} -k {wildcards.ksize} \
#         --scaled {wildcards.scaled} -o {output.scaled_sig}
#         sourmash scripts pangenome_merge {output.scaled_sig} -k {wildcards.ksize} \
#         -o {output.pang} --scaled {wildcards.scaled} && \
#         sourmash scripts pangenome_ranktable {output.pang} -o {output.rankt} \
#         -k {wildcards.ksize} --scaled {wildcards.scaled}
#         """
