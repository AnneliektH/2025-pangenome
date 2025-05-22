# after roary: use script to get genes of interest
# run roary
rule roary_split:
    input:
        check = f"{OUTPUT_DIR}/{pang_name_out}/check/{pang_name_out}.roary.done"
    output:
        csv = f"{OUTPUT_DIR}/{pang_name_out}/sourmash/{pang_name_out}.generanks.csv",
    conda: 
        "branchwater-skipmer"
    threads: 1
    params:
        roary_folder = f"{OUTPUT_DIR}/{pang_name_out}/roary",
    shell:
        """ 
        python scripts/count_genes.py {params.roary_folder}/gene_presence_absence.Rtab \
        {output.csv} 
        """

rule split_fasta:
    input:
        check = f"{OUTPUT_DIR}/{pang_name_out}/sourmash/{pang_name_out}.generanks.csv",
    output:
         core_fa = f"{OUTPUT_DIR}/{pang_name_out}/sourmash/{pang_name_out}.core.fa",
         cloud_fa = f"{OUTPUT_DIR}/{pang_name_out}/sourmash/{pang_name_out}.cloud.fa",
    conda: 
        "seqkit"
    threads: 1
    params:
        roary_folder = f"{OUTPUT_DIR}/{pang_name_out}/roary",
    shell:
        """ 
        seqkit grep -n -r -f {params.roary_folder}/hard_core.txt \
        {params.roary_folder}/pan_genome_reference.fa -o {output.core_fa} && \
        seqkit grep -n -r -f {params.roary_folder}/cloud.txt \
        {params.roary_folder}/pan_genome_reference.fa -o {output.cloud_fa} 
        """


