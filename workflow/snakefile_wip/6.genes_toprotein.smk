import os
import pandas as pd
import glob

OUTPUT_DIR ="/group/ctbrowngrp2/amhorst/2025-pangenome/results/test_pipeline"

# set configfile
configfile: "../config/config.yaml"
pangenome_species = config["pang_org"]
pang_name_out = config["pang_folder"]

# Discover input FASTA files
fasta_files = glob_wildcards(f"{OUTPUT_DIR}/{pang_name_out}/fasta/{{fasta}}.fa").fasta

# Rule all
rule all:
    input:
        expand(f"{OUTPUT_DIR}/{pang_name_out}/check/{{fasta}}.prokka.done", fasta=fasta_files),
        expand(f"{OUTPUT_DIR}/{pang_name_out}/sourmash/{{fasta}}.zip", fasta=fasta_files),
        expand(f"{OUTPUT_DIR}/{pang_name_out}/sourmash/{{fasta}}.prot.zip", fasta=fasta_files),
        expand(f"{OUTPUT_DIR}/{pang_name_out}/sourmash/{{fasta}}.rankt.prot.csv", fasta=fasta_files),
        expand(f"{OUTPUT_DIR}/{pang_name_out}/sourmash/{{fasta}}.rankt.csv", fasta=fasta_files)

         
rule prokka:
    input:
        fasta = f"{OUTPUT_DIR}/{pang_name_out}/fasta/{{fasta}}.fa"
    output:
        check = f"{OUTPUT_DIR}/{pang_name_out}/check/{{fasta}}.prokka.done",
    conda: 
        "prokka"
    threads: 1
    params:
        output_folder=f"{OUTPUT_DIR}/{pang_name_out}/prokka/{{fasta}}"
    shell:
        """ 
        prokka --kingdom Bacteria --outdir {params.output_folder} \
        --norrna --notrna --prefix {wildcards.fasta} --force \
        --locustag {wildcards.fasta} {input.fasta} && touch {output.check}
        """

rule sketch_dna:
    input:
         fa = f"{OUTPUT_DIR}/{pang_name_out}/fasta/{{fasta}}.fa",
    output:
        sig = f"{OUTPUT_DIR}/{pang_name_out}/sourmash/{{fasta}}.zip"
    conda: 
        "branchwater-skipmer"
    threads: 1
    shell:
        """ 
        sourmash sketch dna {input.fa} -o {output.sig} -p k=21,scaled=1000 
        """

rule sketch_protein:
    input:
         fa = f"{OUTPUT_DIR}/{pang_name_out}/fasta/{{fasta}}.fa",
         check = f"{OUTPUT_DIR}/{pang_name_out}/check/{{fasta}}.prokka.done",
    output:
        sig = f"{OUTPUT_DIR}/{pang_name_out}/sourmash/{{fasta}}.prot.zip"
    conda: 
        "branchwater-skipmer"
    threads: 1
    params:
        prokka_folder = f"{OUTPUT_DIR}/{pang_name_out}/prokka",
    shell:
        """ 
        sourmash sketch protein {params.prokka_folder}/{wildcards.fasta}/{wildcards.fasta}.faa \
        -o {output.sig} -p k=10,scaled=500 
        """

rule pangenome_merge:
    input:
        sig=f"{OUTPUT_DIR}/{pang_name_out}/sourmash/{{fasta}}.zip"
    output:
        merged=f"{OUTPUT_DIR}/{pang_name_out}/sourmash/{{fasta}}.pang.zip",
        rankt = f"{OUTPUT_DIR}/{pang_name_out}/sourmash/{{fasta}}.rankt.csv"
    shell:
        """
        sourmash scripts pangenome_merge {input.sig} -k 21 \
        -o {output.merged} --scaled 1000 && \
        sourmash scripts pangenome_ranktable {output.merged} -k 21 \
        -o {output.rankt} --scaled 1000

        """
rule pangenome_merge_prot:
    input:
        sig=f"{OUTPUT_DIR}/{pang_name_out}/sourmash/{{fasta}}.prot.zip"
    output:
        merged=f"{OUTPUT_DIR}/{pang_name_out}/sourmash/{{fasta}}.pang.prot.zip",
        rankt = f"{OUTPUT_DIR}/{pang_name_out}/sourmash/{{fasta}}.rankt.prot.csv"
    shell:
        """
        sourmash scripts pangenome_merge {input.sig} -k 10 \
        -o {output.merged} --protein --scaled 500 --no-dna && \
        sourmash scripts pangenome_ranktable {output.merged} -k 10 \
        -o {output.rankt} --protein --scaled 500 --no-dna
        """
