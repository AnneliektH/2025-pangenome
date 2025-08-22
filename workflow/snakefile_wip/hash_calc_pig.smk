OUTPUT_DIR = "/group/ctbrowngrp2/amhorst/2025-pangenome/results/pangenome"

# Load config
configfile: "../config/config.yaml"
pangenome_species = config["pang_org"]
pang_name_out = config["pang_folder"]
 
 # try 1 first
fasta_files = glob_wildcards(f"{OUTPUT_DIR}/{pang_name_out}/fasta/{{fasta}}.fa").fasta


rule all:
    input:
        expand(f"{OUTPUT_DIR}/{pang_name_out}/sourmash/cmp/{{fasta}}.cmp.csv", fasta=fasta_files),


rule calc_hash_presence_dna:
    input:
        metags_pig = "/group/ctbrowngrp2/amhorst/2025-pangenome/resources/species_per_metag/l_amylovorus_samples.test.txt",
        rankt=f"{OUTPUT_DIR}/{pang_name_out}/sourmash/{{fasta}}.rankt.csv"
    output:
        pig=temp(f"{OUTPUT_DIR}/{pang_name_out}/sourmash/{{fasta}}.x.pig.dmp"),
    shell:
        """
        python scripts/calc-hash-presence.py {input.rankt} {input.metags_pig} --scaled=1000 -k 21 -o {output.pig}
        """

rule parse_dmp:
    input:
        pig=f"{OUTPUT_DIR}/{pang_name_out}/sourmash/{{fasta}}.x.pig.dmp",
    output:
        parsed=f"{OUTPUT_DIR}/{pang_name_out}/sourmash/cmp/{{fasta}}.cmp.csv",
    shell:
        """
        python scripts/parse-dmp.singular.py \
        --dump-files-1 {input.pig} > {output.parsed} 
        """