import os
import pandas as pd
import glob


OUTPUT_DIR ="/group/ctbrowngrp2/amhorst/2025-pangenome/results/test_pipeline"

# set configfile
configfile: "../config/config.yaml"
pangenome_species = config["pang_org"]
pang_name_out = config["pang_folder"]

# set list of fasta files
genomes = glob_wildcards(f"{OUTPUT_DIR}/{pang_name_out}/MAGs/{{sample}}.fasta").sample

# final output 
rule all:
    input:
        expand(f"{OUTPUT_DIR}/{pang_name_out}/check/{{genome}}.prokka.done", genome=genomes),
        expand(f"{OUTPUT_DIR}/{pang_name_out}/check/drep.check",),
        expand(f"{OUTPUT_DIR}/{pang_name_out}/check/drep_all.check",),


# run prokka on all of them 
rule prokka_all:
    input:
        sig = f"{OUTPUT_DIR}/{pang_name_out}/sourmash/{pang_name_out}.gtdb.zip",
        check = f"{OUTPUT_DIR}/{pang_name_out}/check/symlink.check",
        genomes= f"{OUTPUT_DIR}/{pang_name_out}/MAGs/{{genome}}.fasta",
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
        --norrna --notrna --prefix {wildcards.genome} --force \
        --locustag {wildcards.genome} {input.genomes} && touch {output.check}
        """

# dereplicate MAGs
rule drep_reference:
    input:
        sig = f"{OUTPUT_DIR}/{pang_name_out}/sourmash/{pang_name_out}.gtdb.zip",
    output:
        check = f"{OUTPUT_DIR}/{pang_name_out}/check/drep.check",
    conda: 
        "drep"
    threads: 24
    params:
        input_folder=f"{OUTPUT_DIR}/{pang_name_out}/MAGs",
        output_folder=f"{OUTPUT_DIR}/{pang_name_out}/drep_ref"
    shell:
        """ 
        dRep dereplicate {params.output_folder} -p {threads} \
        --ignoreGenomeQuality -pa 0.99 -sa 0.99 -nc 0.30 -cm larger \
        -g {params.input_folder}/*genomic.fasta && \
        touch {output.check}
        """

rule drep_all:
    input:
        sig = f"{OUTPUT_DIR}/{pang_name_out}/sourmash/{pang_name_out}.gtdb.zip",
        check =  f"{OUTPUT_DIR}/{pang_name_out}/check/symlink.check",
    output:
        check = f"{OUTPUT_DIR}/{pang_name_out}/check/drep_all.check",
    conda: 
        "drep"
    threads: 24
    params:
        input_folder=f"{OUTPUT_DIR}/{pang_name_out}/MAGs",
        output_folder=f"{OUTPUT_DIR}/{pang_name_out}/drep_all"
    shell:
        """ 
        dRep dereplicate {params.output_folder} -p {threads} \
        --ignoreGenomeQuality -pa 0.99 -sa 0.99 -nc 0.30 -cm larger \
        -g {params.input_folder}/*.fasta && \
        touch {output.check}
        """