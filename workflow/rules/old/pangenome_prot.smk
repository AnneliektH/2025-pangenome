# result directory
OUTPUT_DIR ="/group/ctbrowngrp2/amhorst/2025-pangenome/results/pangenome"

# set configfile
configfile: "../config/config.yaml"
pangenome_species = config["pang_org"]
pang_name_out = config["pang_folder"]

ksize = [21, 31]
k_prot = [12,15,18,21]
scaled = [10]

SIG, = glob_wildcards("../results/pangenome/l_amylovorus/test_params/concat/{signature}.zip")

# final output 
rule all:
    input:
        #expand(f"{OUTPUT_DIR}/{pang_name_out}/test_params/{{signature}}.rankt.{{ksize}}.{{scaled}}.csv", ksize=k_prot, scaled=scaled, signature=SIG),
        expand(f"{OUTPUT_DIR}/{pang_name_out}/test_params/{{signature}}.rankt.{{ksize}}.{{scaled}}.csv", ksize=ksize, scaled=scaled, signature=SIG),


rule pangenome_merge:
    input: 
        sig = "../results/pangenome/l_amylovorus/test_params/concat/{signature}.zip"
    output: 
        pang = f"{OUTPUT_DIR}/{pang_name_out}/test_params/{{signature}}.pang.{{k_prot}}.{{scaled}}.zip",
        rankt = f"{OUTPUT_DIR}/{pang_name_out}/test_params/{{signature}}.rankt.{{k_prot}}.{{scaled}}.csv"
    conda: 
        "pangenomics_dev"
    threads: 1
    shell:
        """ 
        sourmash scripts pangenome_merge {input.sig} -k {wildcards.k_prot} \
        -o {output.pang} --scaled {wildcards.scaled} --dayhoff --no-dna && \
        sourmash scripts pangenome_ranktable {output.pang} -o {output.rankt} \
        -k {wildcards.k_prot} --scaled {wildcards.scaled} --dayhoff --no-dna
        """

rule pangenome_merge_dna:
    input: 
        sig = "../results/pangenome/l_amylovorus/test_params/concat/{signature}.zip"
    output: 
        pang = f"{OUTPUT_DIR}/{pang_name_out}/test_params/{{signature}}.pang.{{ksize}}.{{scaled}}.zip",
        rankt = f"{OUTPUT_DIR}/{pang_name_out}/test_params/{{signature}}.rankt.{{ksize}}.{{scaled}}.csv"
    conda: 
        "pangenomics_dev"
    threads: 1
    shell:
        """ 
        sourmash scripts pangenome_merge {input.sig} -k {wildcards.ksize} \
        -o {output.pang} --scaled {wildcards.scaled} && \
        sourmash scripts pangenome_ranktable {output.pang} -o {output.rankt} \
        -k {wildcards.ksize} --scaled {wildcards.scaled}
        """
# # sourmash pangenome
# rule sourmash_faa:
#     input: 
#         sig_gtdb = f"{OUTPUT_DIR}/{pang_name_out}/sourmash/protein/{pang_name_out}.prot.zip"
#     output: 
#         scaled_sig = f"{OUTPUT_DIR}/{pang_name_out}/sourmash/{pang_name_out}.{{k_prot}}.{{scaled}}.prot.zip",
#         pang = f"{OUTPUT_DIR}/{pang_name_out}/sourmash/{pang_name_out}.pang.{{k_prot}}.{{scaled}}.prot.zip",
#         rankt = f"{OUTPUT_DIR}/{pang_name_out}/sourmash/{pang_name_out}.rankt.{{k_prot}}.{{scaled}}.prot.csv"
#     conda: 
#         "pangenomics_dev"
#     threads: 1
#     shell:
#         """ 
#         sourmash sig downsample {input.sig_gtdb} -k {wildcards.k_prot} --protein \
#         --scaled {wildcards.scaled} -o {output.scaled_sig} && \
#         sourmash scripts pangenome_merge {output.scaled_sig} -k {wildcards.k_prot} \
#         -o {output.pang} --scaled {wildcards.scaled} --protein --no-dna && \
#         sourmash scripts pangenome_ranktable {output.pang} -o {output.rankt} \
#         -k {wildcards.k_prot} --scaled {wildcards.scaled} --protein --no-dna
#         """

# # sourmash pangenome
# rule sourmash_fna:
#     input: 
#         sig_gtdb = f"{OUTPUT_DIR}/{pang_name_out}/sourmash/transcript/{pang_name_out}.fna.zip"
#     output: 
#         scaled_sig = f"{OUTPUT_DIR}/{pang_name_out}/sourmash/{pang_name_out}.{{ksize}}.{{scaled}}.fna.zip",
#         pang = f"{OUTPUT_DIR}/{pang_name_out}/sourmash/{pang_name_out}.pang.{{ksize}}.{{scaled}}.fna.zip",
#         rankt = f"{OUTPUT_DIR}/{pang_name_out}/sourmash/{pang_name_out}.rankt.{{ksize}}.{{scaled}}.fna.csv"
#     conda: 
#         "pangenomics_dev"
#     threads: 1
#     shell:
#         """ 
#         sourmash sig downsample {input.sig_gtdb} -k {wildcards.ksize} \
#         --scaled {wildcards.scaled} -o {output.scaled_sig} && \
#         sourmash scripts pangenome_merge {output.scaled_sig} -k {wildcards.ksize} \
#         -o {output.pang} --scaled {wildcards.scaled} && \
#         sourmash scripts pangenome_ranktable {output.pang} -o {output.rankt} \
#         -k {wildcards.ksize} --scaled {wildcards.scaled}
#         """
