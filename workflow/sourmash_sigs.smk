import pandas as pd
import glob, os


GTDB = '/group/ctbrowngrp/sourmash-db/gtdb-rs226/gtdb-rs226.k31.sig.zip'
GTDB_TAX  = '/group/ctbrowngrp/sourmash-db/gtdb-rs226/gtdb-rs226.lineages.csv'
NEW_MAG_TAX = '../resources/250703_mag_taxonomy.tsv'
OWN_MAG_SIG = '/group/ctbrowngrp2/amhorst/2025-pigparadigm/results/sketches/MAGs.all_k31.rocksdb'
KSIZE = 31 
SCALED = 1000
OUTPUT_DIR = "/group/ctbrowngrp2/amhorst/2025-pangenome/results/pangenome"
MAG_LOCATION = "/group/ctbrowngrp2/amhorst/2025-pigparadigm/results/MAGs/all_genomes"

# Load pang_org list
pang_df = pd.read_csv("../resources/pang_list.csv")  # Only needs 'pang_org' column

# Create pang_folder by replacing spaces with underscores
pang_df["pang_folder"] = pang_df["pang_org"].str.replace(" ", "_")

pang_folders = pang_df["pang_folder"].tolist()

def get_species(pang_folder):
    return pang_df.loc[pang_df["pang_folder"] == pang_folder, "pang_org"].item()


rule all:
    input:
        expand(f"{OUTPUT_DIR}/{{pang_folder}}/sourmash/{{pang_folder}}.subtract.zip", pang_folder=pang_folders),
        # expand(f"{OUTPUT_DIR}/{{pang_folder}}/sourmash/{{pang_folder}}.gtdb.zip", pang_folder=pang_folders),
        # expand(f"{OUTPUT_DIR}/{{pang_folder}}/sourmash/{{pang_folder}}.sramags.zip", pang_folder=pang_folders), 



rule sketch_own_mags:
    input:
        tsv = f"{OUTPUT_DIR}/{{pang_folder}}/{{pang_folder}}xownmags.tsv"
    output:
        sig = f"{OUTPUT_DIR}/{{pang_folder}}/sourmash/{{pang_folder}}.sramags.zip"
    conda: "branchwater-skipmer"
    threads: 1
    params:
        in_folder=lambda w: f"{OUTPUT_DIR}/{w.pang_folder}/MAGs"
    shell:
        """
        sourmash sketch dna {params.in_folder}/AtH*.fasta \
        -p k=21,k=31,scaled=1000 \
        -o {output.sig}
        """

# merge signatures
rule merge:
    input:
        sigsra = f"{OUTPUT_DIR}/{{pang_folder}}/sourmash/{{pang_folder}}.sramags.zip",
        siggtdb = f"{OUTPUT_DIR}/{{pang_folder}}/sourmash/{{pang_folder}}.gtdb.zip"
    output:
        sigsra = f"{OUTPUT_DIR}/{{pang_folder}}/sourmash/{{pang_folder}}.sramags.merge.zip",
        siggtdb = f"{OUTPUT_DIR}/{{pang_folder}}/sourmash/{{pang_folder}}.gtdb.merge.zip",
        siggtdb1k = f"{OUTPUT_DIR}/{{pang_folder}}/sourmash/{{pang_folder}}.gtdb.merge1k.zip"
    conda: "branchwater-skipmer"
    threads: 1
    shell:
        """
        sourmash sig merge --flatten -k {KSIZE} {input.sigsra} -o {output.sigsra} && \
        sourmash sig merge --flatten -k {KSIZE} {input.siggtdb} -o {output.siggtdb} && \
        sourmash sig downsample {output.siggtdb} -k {KSIZE} --scaled {SCALED} -o {output.siggtdb1k}
        """

rule subtract:
    input:
        sigsra = f"{OUTPUT_DIR}/{{pang_folder}}/sourmash/{{pang_folder}}.sramags.merge.zip",
        siggtdb = f"{OUTPUT_DIR}/{{pang_folder}}/sourmash/{{pang_folder}}.gtdb.merge1k.zip"
    output:
        sigsubt = f"{OUTPUT_DIR}/{{pang_folder}}/sourmash/{{pang_folder}}.subtract.zip",
    conda: "branchwater-skipmer"
    threads: 1
    shell:
        """
        sourmash sig subtract {input.sigsra} {input.siggtdb} -k {KSIZE} -o {output.sigsubt}  
        """
