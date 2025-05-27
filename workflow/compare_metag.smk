OUTPUT_DIR = "/group/ctbrowngrp2/amhorst/2025-pangenome/results/test_pipeline"

# Load config
configfile: "../config/config.yaml"
pangenome_species = config["pang_org"]
pang = config["pang_folder"]

rule all:
    input:
        expand("{output_dir}/{pang}/sourmash/{pang}.{type}.{label}.x.human.dmp",
               output_dir=OUTPUT_DIR,
               pang=pang,
               type=["core", "cloud"],
               label=["gtdb", "all"]),
        expand("{output_dir}/{pang}/sourmash/{pang}.{type}.{label}.tr.x.human.dmp",
               output_dir=OUTPUT_DIR,
               pang=pang,
               type=["core", "cloud"],
               label=["gtdb", "all"])

rule pangenome_merge_dna:
    input:
        sig="{output_dir}/{pang}/sourmash/{pang}.{type}.{label}.zip"
    output:
        merged="{output_dir}/{pang}/sourmash/{pang}.{type}.{label}.pang.k21.zip"
    params:
        output_dir=OUTPUT_DIR
    shell:
        """
        sourmash scripts pangenome_merge {input.sig} -k 21 \
        -o {output.merged} --scaled 1000
        """

rule pangenome_rank_dna:
    input:
        sig="{output_dir}/{pang}/sourmash/{pang}.{type}.{label}.pang.k21.zip"
    output:
        csv="{output_dir}/{pang}/sourmash/{pang}.{type}.{label}.rankt.k21.csv"
    params:
        output_dir=OUTPUT_DIR
    shell:
        """
        sourmash scripts pangenome_ranktable {input.sig} -k 21 \
        -o {output.csv} --scaled 1000
        """


rule pangenome_merge_tr:
    input:
        sig="{output_dir}/{pang}/sourmash/{pang}.{type}.tr.{label}.zip"
    output:
        merged="{output_dir}/{pang}/sourmash/{pang}.{type}.tr.{label}.pang.k10.zip"
    params:
        output_dir=OUTPUT_DIR
    shell:
        """
        sourmash scripts pangenome_merge {input.sig} -k 10 \
        -o {output.merged} --protein --scaled 500 --no-dna
        """
rule pangenome_rank_tr:
    input:
        sig="{output_dir}/{pang}/sourmash/{pang}.{type}.tr.{label}.pang.k10.zip"
    output:
        csv="{output_dir}/{pang}/sourmash/{pang}.{type}.tr.{label}.rankt.k10.csv"
    params:
        output_dir=OUTPUT_DIR
    shell:
        """
        sourmash scripts pangenome_ranktable {input.sig} -k 10 \
        -o {output.csv} --protein --scaled 500 --no-dna
        """

rule calc_hash_presence_dna:
    input:
        metags_pig = "/group/ctbrowngrp2/amhorst/2025-pangenome/config/pig_sra.txt",
        metags_human = "/group/ctbrowngrp2/amhorst/2025-pangenome/config/human_sra.txt",
        rankt="{output_dir}/{pang}/sourmash/{pang}.{type}.{label}.rankt.k21.csv"
    output:
        pig="{output_dir}/{pang}/sourmash/{pang}.{type}.{label}.x.pig.dmp",
        human="{output_dir}/{pang}/sourmash/{pang}.{type}.{label}.x.human.dmp"
    params:
        output_dir=OUTPUT_DIR
    shell:
        """
        python scripts/calc-hash-presence.py {input.rankt} {input.metags_pig} --scaled=1000 -k 21 -o {output.pig} && \
        python scripts/calc-hash-presence.py {input.rankt} {input.metags_human} --scaled=1000 -k 21 -o {output.human}
        """


rule calc_hash_presence_tr:
    input:
        metags_pig = "/group/ctbrowngrp2/amhorst/2025-pangenome/config/pig_sra_prot.txt",
        metags_human = "/group/ctbrowngrp2/amhorst/2025-pangenome/config/human_sra_prot.txt",
        rankt="{output_dir}/{pang}/sourmash/{pang}.{type}.tr.{label}.rankt.k10.csv"
    output:
        pig="{output_dir}/{pang}/sourmash/{pang}.{type}.{label}.tr.x.pig.dmp",
        human="{output_dir}/{pang}/sourmash/{pang}.{type}.{label}.tr.x.human.dmp"
    params:
        output_dir=OUTPUT_DIR
    shell:
        """
        python scripts/calc-hash-presence.py {input.rankt} {input.metags_pig} --scaled=500 --protein --no-dna -k 10 -o {output.pig} && \
        python scripts/calc-hash-presence.py {input.rankt} {input.metags_human} --scaled=500 --protein --no-dna -k 10 -o {output.human}
        """

rule parse_dmp:
    input:
        pig="{output_dir}/{pang}/sourmash/{pang}.{type}.{label}.x.pig.dmp",
        human="{output_dir}/{pang}/sourmash/{pang}.{type}.{label}.x.human.dmp",
        pig_tr="{output_dir}/{pang}/sourmash/{pang}.{type}.{label}.tr.x.pig.dmp",
        human_tr="{output_dir}/{pang}/sourmash/{pang}.{type}.{label}.tr.x.human.dmp"
    output:
        parsed="{output_dir}/{pang}/sourmash/{pang}.{type}.{label}.cmp.csv",
        parsed_tr="{output_dir}/{pang}/sourmash/{pang}.{type}.{label}.tr.cmp.csv"
    params:
        output_dir=OUTPUT_DIR
    shell:
        """
        python scripts/parse-dump.py \
        --dump-files-1 {input.human} \
        --dump-files-2 {input.pig} > {output.parsed} && \
        python scripts/parse-dump.py \
        --dump-files-1 {input.human_tr} \
        --dump-files-2 {input.pig_tr} > {output.parsed_tr}
        """