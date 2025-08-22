SIGS = sorted(glob_wildcards("../results/hash_count_metag/flatten/{sample}.zip").sample)
INPUT_CSVS = {
    "all": "/group/ctbrowngrp2/amhorst/2025-check-8000/results/hash_count_metag/MAGs.all_sub_99.rankt.csv",
    "99": "/group/ctbrowngrp2/amhorst/2025-check-8000/results/hash_count_metag/MAGs.99_sub_95.rankt.csv",
    "95": "/group/ctbrowngrp2/amhorst/2025-check-8000/results/hash_count_metag/MAGs.95.rankt.csv"
}

rule all:
    input:
        [
            f"../results/hash_count_metag/presence/{label}/{sample}.parsed.tsv"
            for label in INPUT_CSVS
            for sample in SIGS
        ]
# In your Snakefile temporarily
 

rule calc_hash_presence:
    input:
        zipfile = "../results/hash_count_metag/flatten/{sample}.zip",
        csvfile = lambda wildcards: INPUT_CSVS[wildcards.label]
    output:
        dmp = temp("../results/hash_count_metag/presence/{label}/{sample}.dmp")
    params:
        scaled = 1000,
        ksize = 21
    shell:
        "python ../scripts/pangenome_db/calc-hash-presence.py {input.csvfile} {input.zipfile} "
        "--scaled={params.scaled} -k {params.ksize} -o {output.dmp}"

rule parse_dump:
    input:
        "../results/hash_count_metag/presence/{label}/{sample}.dmp"
    output:
        parsed = "../results/hash_count_metag/presence/{label}/{sample}.parsed.tsv"
    shell:
        "python ../scripts/pangenome_db/parse-dmp.singular.py --dump-files-1 {input} > {output.parsed}"
