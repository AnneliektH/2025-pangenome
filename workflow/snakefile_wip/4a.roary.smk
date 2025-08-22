import os
import pandas as pd
import glob

OUTPUT_DIR ="/group/ctbrowngrp2/amhorst/2025-pangenome/results/pangenome"

# set configfile
# configfile: "../config/config.yaml"
# pangenome_species = config["pang_org"]
# pang_name_out = config["pang_folder"]

#
#pangenome_species = config["pang_org"]
pang_name_out ="Catenibacterium_mitsuokai" 


# final output 
rule all:
    input:
        #expand(f"{OUTPUT_DIR}/{pang_name_out}/check/{pang_name_out}.roary.done",),
        expand(f"{OUTPUT_DIR}/{pang_name_out}/check/{pang_name_out}.roary.done",),

# run roary on all MAGs
rule roary_all:
    output:
        check = f"{OUTPUT_DIR}/{pang_name_out}/check/{pang_name_out}.roary.done"
    conda: 
        "roary"
    threads: 32
    params:
        prokka_folder = f"{OUTPUT_DIR}/{pang_name_out}/prokka",
        gff_folder = f"{OUTPUT_DIR}/{pang_name_out}/prokka/gff_all",
        output_folder=f"{OUTPUT_DIR}/{pang_name_out}/roary"
    shell:
        """ 
        mkdir -p {params.gff_folder} && \
        cp {params.prokka_folder}/*/*.gff {params.gff_folder} && \
        roary -p {threads} -f {params.output_folder} \
        -e -n -v {params.gff_folder}/*.gff && touch {output.check}
        """

# # reference roary
# rule roary_reference:
#     output:
#         check = f"{OUTPUT_DIR}/{pang_name_out}/check/{pang_name_out}.roary.nd.done"
#     conda: 
#         "roary"
#     threads: 30
#     params:
#         prokka_folder = f"{OUTPUT_DIR}/{pang_name_out}/prokka",
#         gff_folder = f"{OUTPUT_DIR}/{pang_name_out}/prokka/gff_ref",
#         output_folder=f"{OUTPUT_DIR}/{pang_name_out}/roary_ref_nd"
#     shell:
#         """ 
#         mkdir -p {params.gff_folder} && \
#         cp {params.prokka_folder}/*genomic/*.gff {params.gff_folder} && \
#         roary -p {threads} -f {params.output_folder} \
#         -e -n -v {params.gff_folder}/*.gff && touch {output.check}
#         """