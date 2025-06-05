OUTPUT_DIR = "/group/ctbrowngrp2/amhorst/2025-pangenome/results/test_pipeline"

# Load config
configfile: "../config/config.yaml"
pangenome_species = config["pang_org"]
pang_name_out = config["pang_folder"]
 
fasta_files = glob_wildcards(f"{OUTPUT_DIR}/{pang_name_out}/fasta/{{fasta}}.fa").fasta


rule all:
    input:
        expand(f"{OUTPUT_DIR}/{pang_name_out}/sourmash/cmp/{{fasta}}.prot.cmp.csv", fasta=fasta_files),


rule calc_hash_presence_dna:
    input:
        metags_pig = "/group/ctbrowngrp2/amhorst/2025-pangenome/config/pig_sra.txt",
        metags_human = "/group/ctbrowngrp2/amhorst/2025-pangenome/config/human_sra.txt",
        rankt=f"{OUTPUT_DIR}/{pang_name_out}/sourmash/{{fasta}}.rankt.csv"
    output:
        pig=f"{OUTPUT_DIR}/{pang_name_out}/sourmash/{{fasta}}.x.pig.dmp",
        human=f"{OUTPUT_DIR}/{pang_name_out}/sourmash/{{fasta}}.x.human.dmp"
    shell:
        """
        python scripts/calc-hash-presence.py {input.rankt} {input.metags_pig} --scaled=1000 -k 21 -o {output.pig} && \
        python scripts/calc-hash-presence.py {input.rankt} {input.metags_human} --scaled=1000 -k 21 -o {output.human}
        """


rule calc_hash_presence_prot:
    input:
        metags_pig = "/group/ctbrowngrp2/amhorst/2025-pangenome/config/pig_sra_prot.txt",
        metags_human = "/group/ctbrowngrp2/amhorst/2025-pangenome/config/human_sra_prot.txt",
        rankt=f"{OUTPUT_DIR}/{pang_name_out}/sourmash/{{fasta}}.rankt.prot.csv"
    output:
        pig=f"{OUTPUT_DIR}/{pang_name_out}/sourmash/{{fasta}}.prot.x.pig.dmp",
        human=f"{OUTPUT_DIR}/{pang_name_out}/sourmash/{{fasta}}.prot.x.human.dmp"
    shell:
        """
        python scripts/calc-hash-presence.py {input.rankt} {input.metags_pig} --scaled=500 --protein --no-dna -k 10 -o {output.pig} && \
        python scripts/calc-hash-presence.py {input.rankt} {input.metags_human} --scaled=500 --protein --no-dna -k 10 -o {output.human}
        """

rule parse_dmp:
    input:
        pig=f"{OUTPUT_DIR}/{pang_name_out}/sourmash/{{fasta}}.x.pig.dmp",
        human=f"{OUTPUT_DIR}/{pang_name_out}/sourmash/{{fasta}}.x.human.dmp",
        pig_prot=f"{OUTPUT_DIR}/{pang_name_out}/sourmash/{{fasta}}.prot.x.pig.dmp",
        human_prot=f"{OUTPUT_DIR}/{pang_name_out}/sourmash/{{fasta}}.prot.x.human.dmp"
    output:
        parsed=f"{OUTPUT_DIR}/{pang_name_out}/sourmash/cmp/{{fasta}}.cmp.csv",
        parsed_prot=f"{OUTPUT_DIR}/{pang_name_out}/sourmash/cmp/{{fasta}}.prot.cmp.csv",
    shell:
        """
        python scripts/parse-dump.py \
        --dump-files-1 {input.human} \
        --dump-files-2 {input.pig} > {output.parsed} && \
        python scripts/parse-dump.py \
        --dump-files-1 {input.human_prot} \
        --dump-files-2 {input.pig_prot} > {output.parsed_prot}
        """