import pandas as pd

# set list of samples
METAG = pd.read_csv("../config/sra.txt", usecols=[0], header=None).squeeze().tolist()

rule all:
    input:
        expand('../results/metag_signatures/{sample}.zip', sample=METAG,),


# Download SRA files
rule download_sra:
    output:
        sra = temporary("../results/test_pipeline/protein_space/sra/{sample}")
    log:
        "../results/logs/prefetch.{sample}.log"
    conda:
        "sra"
    shell:
        """
        mkdir -p ../results/test_pipeline/protein_space/sra/
        if [ ! -f "../results/check/{wildcards.sample}_fasterqdump.check" ] && [ ! -f "{output.sra}" ]; then
            aws s3 cp --quiet --no-sign-request s3://sra-pub-run-odp/sra/{wildcards.sample}/{wildcards.sample} {output.sra}
        fi &> {log}
        """
        

# Download the whole thing, including smaller reads, as atlas will quality trim
rule fasterq_dump:
    input:
        sra_file = "../results/test_pipeline/protein_space/sra/{sample}"
    output:
        check = "../results/check/{sample}_fasterqdump.check"
    log:
        "../results/logs/fasterq_dump.{sample}.log"
    conda: 
        "sra"
    benchmark: "../results/logs/fasterq_dump.{sample}.benchmark"
    threads: 12
    shell:
        """
        fasterq-dump {input.sra_file} --threads {threads} \
        -O ../results/test_pipeline/protein_space/fasterq/{wildcards.sample} --skip-technical \
        --bufsize 1000MB --curcache 10000MB && \
        pigz -f -p {threads} ../results/test_pipeline/protein_space/fasterq/{wildcards.sample}/*.fastq && \
        touch {output.check}
        """

rule singlesketch:
    input:
        read_one="/group/ctbrowngrp2/amhorst/2025-pangenome/results/test_pipeline/protein_space/fasterq/{sample}/{sample}_1.fastq.gz",
        read_two="/group/ctbrowngrp2/amhorst/2025-pangenome/results/test_pipeline/protein_space/fasterq/{sample}/{sample}_2.fastq.gz",
    output:
        sig = "../results/metag_signatures/{sample}.zip",
    conda: 
        "branchwater-skipmer"
    threads: 1
    shell: 
        """
        sourmash sketch protein {input.read_one} {input.read_two} \
        -p k=10,scaled=500,abund \
        --name {wildcards.sample} -o {output.sig}
        """